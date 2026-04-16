# lib/overlays.nix
# Overlay factory — eliminates 3x duplication across devShell/home/darwin
{ rust-overlay, jetpack, cursor-arm }:

{
  # Build overlay list based on context
  # devShells:  includeJetpack=true,  includeCursorArm=true
  # home:       includeJetpack=false, includeCursorArm=true
  # darwin:     includeJetpack=false, includeCursorArm=false
  mkOverlays = { includeJetpack ? false, includeCursorArm ? false, system ? null }:
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
      } // (if includeCursorArm && system != null then {
        cursor-arm = cursor-arm.packages.${system}.default or null;
      } else { }))
    ];

  # Instantiate nixpkgs with overlays
  mkPkgs = { nixpkgs, system, overlays, cudaSupport ? false }:
    import nixpkgs {
      inherit system overlays;
      config.allowUnfree = true;
      config.cudaSupport = cudaSupport;
    };
}
