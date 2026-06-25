# lib/overlays.nix
# Overlay factory — eliminates 3x duplication across devShell/home/darwin
{ rust-overlay, jetpack }:

{
  # Build overlay list based on context
  # devShells/home: includeJetpack=false (true only on aarch64-linux Jetson)
  # darwin:         includeJetpack=false
  mkOverlays = { includeJetpack ? false, system ? null }:
    [ (import rust-overlay) ]
    ++ (if includeJetpack then [ jetpack.overlays.default ] else [ ])
    ++ [
      (final: prev: {
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
      })
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
