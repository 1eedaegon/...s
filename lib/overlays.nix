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
            version = "0.144.6";
            system = prev.stdenvNoCC.hostPlatform.system;
            sources = {
              x86_64-linux = {
                npmPlatform = "linux-x64";
                vendorPlatform = "x86_64-unknown-linux-musl";
                hash = "sha512-4E7EnzCg0OnBxCyYnwJ+qnZwWHYe0YScr5ucKWbngE9u4+0XrpWELqq2Kn9jl5GZK8MDjU7PrJwFIwusHOHjuw==";
              };
              aarch64-linux = {
                npmPlatform = "linux-arm64";
                vendorPlatform = "aarch64-unknown-linux-musl";
                hash = "sha512-PGiLXMN+2IQRkf7tOLi64dMInjU1pRLbz0Rwfj/yt2Y97SZQqAjFQoi2wmswmqtqMDnfwCPTC1DRXVQkvU6T6Q==";
              };
              x86_64-darwin = {
                npmPlatform = "darwin-x64";
                vendorPlatform = "x86_64-apple-darwin";
                hash = "sha512-THRyPG0zSU6M8NQAge1LHEHsJDnoH4BpKsfJHB/qe3Fm+Wf6zqAmWJFlOKzBm27m0K2Hq3za4Ac2I5p5i4yp/A==";
              };
              aarch64-darwin = {
                npmPlatform = "darwin-arm64";
                vendorPlatform = "aarch64-apple-darwin";
                hash = "sha512-6zgvh70MzBNSeT17HEhSOrmmGGZGAKzSC7x6JAq+edkJkdPYA9P0I1tG7aJ49GlBkBxuC+MKBH1qm6+2Cghcww==";
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
            # Prebuilt, notarized/signed per-platform binaries from upstream
            # GitHub releases. nixpkgs-26.05-darwin (what x86_64-darwin is
            # pinned to, see flake.nix channelsFor) carries 1.15.10; unstable
            # carries 1.18.13 but no longer evaluates for x86_64-darwin at
            # all. Pinning here keeps every platform on the same current
            # release regardless of which nixpkgs channel it rides.
            sources = {
              x86_64-linux = {
                url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64-musl.tar.gz";
                hash = "sha256-6NW+I7+PP2m8MgbzMRIVwEkynNavp8BtczmHzC0ztWg=";
              };
              aarch64-linux = {
                url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-arm64-musl.tar.gz";
                hash = "sha256-NSLsyv0w2EotdwtypW1Id8V2uQcrNqWp6g+jDtgriW4=";
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

              nativeBuildInputs = [ final.unzip ];

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

              doInstallCheck = true;
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
    };
}
