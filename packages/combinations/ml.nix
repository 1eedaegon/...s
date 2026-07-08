# packages/combinations/ml.nix
# Python + Rust + ML packages (wandb, marimo, huggingface-hub)
{ pkgs }:

let
  py = import ../toolchains/py.nix { inherit pkgs; };
  rust = import ../toolchains/rust.nix { inherit pkgs; };

  mlPackages = [
    # Default python set — non-default sets (python312.*) are not built by
    # Hydra, so pinning one forces the whole closure to build from source.
    (pkgs.python3.withPackages (ps: with ps; [
      marimo
      wandb
      huggingface-hub
    ]))
  ];
in
{
  packages = py.packages ++ rust.packages ++ mlPackages;
}
