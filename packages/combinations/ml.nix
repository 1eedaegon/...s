# packages/combinations/ml.nix
# Python + Rust + ML packages (wandb, marimo, huggingface-hub)
{ pkgs }:

let
  py = import ../toolchains/py.nix { inherit pkgs; };
  rust = import ../toolchains/rust.nix { inherit pkgs; };

  mlPackages = [
    (pkgs.python312.withPackages (ps: with ps; [
      marimo
      wandb
      huggingface-hub
    ]))
  ];
in
{
  packages = py.packages ++ rust.packages ++ mlPackages;
}
