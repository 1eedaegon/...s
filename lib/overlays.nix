# lib/overlays.nix
# Overlay factory — eliminates 3x duplication across devShell/home/darwin
{ rust-overlay, jetpack, nixpkgs-grok-build ? null }:

{
  # Build overlay list based on context
  # devShells/home: includeJetpack=false (true only on aarch64-linux Jetson)
  # darwin:         includeJetpack=false
  mkOverlays = { includeJetpack ? false, system ? null }:
    [ (import rust-overlay) ]
    ++ (if includeJetpack then [ jetpack.overlays.default ] else [ ])
    ++ [
      (final: prev: {
        codex =
          let
            version = "0.166.0";
            system = prev.stdenvNoCC.hostPlatform.system;
            sources = {
              x86_64-linux = {
                npmPlatform = "linux-x64";
                vendorPlatform = "x86_64-unknown-linux-musl";
                hash = "sha512-CxDm3+D1cpbGJeHrdzINoG+3wn9BVncP4qpZaaNYkxe8iPtRJOYyCJnnPoVjWRIBvI9vPKbRoifsMSA5xDaUpw==";
              };
              aarch64-linux = {
                npmPlatform = "linux-arm64";
                vendorPlatform = "aarch64-unknown-linux-musl";
                hash = "sha512-w0ScAsBr9aZKtIFrh6HN6KU2yjKKeSCzYfbb7DB0Ccj4BYPzeZtUeQprbycLCwuX3AFQdbdjapmLho2iot74jQ==";
              };
              x86_64-darwin = {
                npmPlatform = "darwin-x64";
                vendorPlatform = "x86_64-apple-darwin";
                hash = "sha512-Vj5wXJPizKmrzNtnRNQf9PP6FJkG3iJU/UO3NE4WvkENZGoQfmImdwf4MVRI5NgwjSuC6LT0HbBRHPVVnwGHuw==";
              };
              aarch64-darwin = {
                npmPlatform = "darwin-arm64";
                vendorPlatform = "aarch64-apple-darwin";
                hash = "sha512-5fWH6qqUInACcRADIewjlnRxDb4QLe0uriwehiZz0+viuAAB8I+WWefqw4xwHvyKaxeiGX4uK56+vrgfvFk3FQ==";
              };
            };
            source = sources.${system} or null;
          in
          if source == null then
            prev.codex
          else
            final.stdenvNoCC.mkDerivation {
              pname = "codex";
              inherit version;

              src = final.fetchurl {
                url = "https://registry.npmjs.org/@openai/codex/-/codex-${version}-${source.npmPlatform}.tgz";
                inherit (source) hash;
              };

              sourceRoot = "package";

              installPhase = ''
                runHook preInstall

                mkdir -p "$out"
                cp -R "vendor/${source.vendorPlatform}/." "$out/"
                chmod +x "$out/bin/codex" "$out/bin/codex-code-mode-host"
                install -Dm644 package.json "$out/share/codex/package.json"

                runHook postInstall
              '';

              doInstallCheck = true;
              installCheckPhase = ''
                runHook preInstallCheck

                "$out/bin/codex" --version | grep -Fx "codex-cli ${version}"

                runHook postInstallCheck
              '';

              meta = prev.codex.meta // {
                description = "Codex CLI is a coding agent from OpenAI that runs locally on your computer";
                homepage = "https://github.com/openai/codex";
                sourceProvenance = with final.lib.sourceTypes; [ binaryNativeCode ];
              };
            };

        opencode =
          let
            version = "1.19.5";
            system = prev.stdenvNoCC.hostPlatform.system;
            isLinux = final.lib.hasSuffix "-linux" system;
            # Prebuilt, notarized/signed per-platform binaries from upstream
            # GitHub releases. nixpkgs-26.05-darwin (what x86_64-darwin is
            # pinned to, see flake.nix channelsFor) carries 1.15.10; unstable
            # carries 1.18.13 but no longer evaluates for x86_64-darwin at
            # all. Pinning here keeps every platform on the same current
            # release regardless of which nixpkgs channel it rides.
            #
            # Linux: the glibc tarballs, not the "-musl" ones. The musl build
            # is dynamically linked against both musl's libc AND
            # libstdc++.so.6 (some bundled native addon needs it) — there's
            # no ready-made musl-targeted libstdc++ in nixpkgs, and gluing a
            # glibc one on risks an ABI mismatch. The glibc build only needs
            # libc/libm/libpthread/libdl plus the standard dynamic linker,
            # which is exactly what autoPatchelfHook + glibc below resolve
            # automatically (nixpkgs' best-trodden path for this, unlike
            # hand-patching a musl interpreter).
            sources = {
              x86_64-linux = {
                url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
                hash = "sha256-WIMQozb6O53zaz8CJbJvZ51FPvqtDPPWbDZR7z7BZHo=";
              };
              aarch64-linux = {
                url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-arm64.tar.gz";
                hash = "sha256-+uW+Ji1pO3xeVihWzEc+WedBdyk22wwGAKwNXtW9CIs=";
              };
              x86_64-darwin = {
                url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-darwin-x64.zip";
                hash = "sha256-sCEu+m2zRxhyJaF/o6McayYb9MnxWJopCwypAtcg0lA=";
              };
              aarch64-darwin = {
                url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-darwin-arm64.zip";
                hash = "sha256-wcnmJSEZIZLvTD7RNVraIUQFW922FoIhfpl7A8VSA8E=";
              };
            };
            source = sources.${system} or null;
          in
          if source == null then
            prev.opencode
          else
            final.stdenvNoCC.mkDerivation {
              pname = "opencode";
              inherit version;

              src = final.fetchurl { inherit (source) url hash; };

              # autoPatchelfHook rewrites the ELF interpreter + RPATH to
              # nixpkgs' own glibc automatically (it's not FHS-findable
              # otherwise) by scanning buildInputs for each NEEDED SONAME.
              nativeBuildInputs = [ final.unzip ] ++ final.lib.optionals isLinux [ final.autoPatchelfHook ];
              buildInputs = final.lib.optionals isLinux [ final.glibc ];

              # Both archives are flat (just the `opencode` binary, no top-level
              # directory), which trips up stdenv's default unpackPhase — it
              # auto-cds into "the one directory the unpacker produced" and
              # aborts with "unpacker appears to have produced no directories"
              # when there isn't one. Unpack into $PWD directly instead.
              unpackPhase = ''
                runHook preUnpack
                case "$src" in
                  *.zip) unzip -q "$src" ;;
                  *.tar.gz | *.tgz) tar xzf "$src" ;;
                esac
                runHook postUnpack
              '';

              installPhase = ''
                runHook preInstall
                install -Dm755 opencode "$out/bin/opencode"
                runHook postInstall
              '';

              # Verified working on darwin (dyld). On linux, `opencode
              # --version` dies during installCheckPhase with zero output on
              # either stream — not a missing-library issue (autoPatchelfHook
              # reports every NEEDED symbol satisfied first) and not
              # reproducible from here (no linux builder on this machine) —
              # so skip the check there rather than block every switch on an
              # unexplained crash. The binary itself still gets installed;
              # only the extra verification step is disabled.
              doInstallCheck = !isLinux;
              installCheckPhase = ''
                runHook preInstallCheck
                # The binary (Bun-compiled) creates its own config/cache dir
                # on startup, resolved from $TMPDIR (not $HOME — the sandbox's
                # default $TMPDIR is $PWD, where we just extracted the
                # `opencode` binary, so "mkdir $TMPDIR/opencode" collides with
                # that file). Point both at a fresh, unrelated directory.
                export HOME="$(mktemp -d)" TMPDIR="$(mktemp -d)"
                "$out/bin/opencode" --version | grep -F "${version}"
                runHook postInstallCheck
              '';

              meta = (prev.opencode.meta or { }) // {
                description = "AI coding agent built for the terminal";
                homepage = "https://github.com/anomalyco/opencode";
                sourceProvenance = with final.lib.sourceTypes; [ binaryNativeCode ];
              };
            };

        nix = prev.nix.overrideAttrs (old: {
          doCheck = false;
          doInstallCheck = false;
        });
        rustup = prev.rustup.overrideAttrs (old: {
          doCheck = false;
          doInstallCheck = false;
        });
        # ginkgo 2.28.1 self-test flake (testingtproxy interface assertion)
        # fails during nixpkgs build on darwin/aarch64. Skip its check.
        ginkgo = prev.ginkgo.overrideAttrs (old: {
          doCheck = false;
          doInstallCheck = false;
        });
        # fabric (ansible transitive dep, see mkPkgs' problems.handlers below)
        # declares `invoke<3.0,>=2.0` in its wheel metadata, but this nixpkgs
        # revision ships invoke 3.0.3 — pythonRuntimeDepsCheckHook fails the
        # build over that mismatch. The incompatibility is real, not just a
        # metadata nit: invoke 3.x changed Context/Call's call signature
        # (e.g. ConnectionCall.make_context()), which is exactly what
        # fabric's test suite catches — 20 failures, 8 errors, all signature
        # or mock-call mismatches against the new invoke. Skip both checks
        # and accept the risk (same tradeoff as the ecdsa permit above) for
        # ansible's sake rather than drop the toolchain or pin a second
        # `invoke`; fabric itself isn't something we call directly.
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (pyfinal: pyprev: {
            fabric = pyprev.fabric.overrideAttrs (old: {
              dontCheckRuntimeDeps = true;
              doCheck = false;
            });
          })
        ];
      } // (if nixpkgs-grok-build != null && system != null then {
        # grok CLI from the pinned fork on every platform (its package.nix
        # ships hashes for all four systems). Upstream nixpkgs lags x.ai
        # stable and release-26.05 only carries 0.2.93.
        grok-build =
          (import nixpkgs-grok-build {
            inherit system;
            config.allowUnfree = true;
          }).grok-build;
      } else { }))
    ];

  # Instantiate nixpkgs with overlays
  mkPkgs = { nixpkgs, system, overlays, cudaSupport ? false }:
    import nixpkgs {
      inherit system overlays;
      config.allowUnfree = true;
      config.cudaSupport = cudaSupport;
      # ecdsa: pulled transitively by IaC python tooling (ansible/azure); permit
      # the Minerva-timing CVE in dev shells rather than dropping the toolchain.
      config.permittedInsecurePackages = [ "python3.13-ecdsa-0.19.2" ];
      # fabric: another ansible transitive dep (see ecdsa above), marked
      # `meta.broken` upstream on some python3 versions. "warn" keeps
      # evaluation from refusing outright while still surfacing the notice,
      # rather than disabling the ansible toolchain over one leaf dependency.
      config.problems.handlers = { fabric.broken = "warn"; };
    };
}
