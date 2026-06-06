# packages/toolchains/py.nix
# Lightweight Python toolchain — ML packages (wandb, marimo) are in combinations/ml.nix
{ pkgs }:

{
  packages = with pkgs; [
    uv
    python3 # nixpkgs default (latest stable); pin a version via #py3_13 / #py3_13_5
    ruff
    black
    mypy
    poetry
    gh
    kaggle
    openmpi
  ];
}
