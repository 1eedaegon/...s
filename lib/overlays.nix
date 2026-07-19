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
      } // (if system == "x86_64-darwin" && nixpkgs-grok-build != null then {
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
