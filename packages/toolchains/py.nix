# packages/toolchains/py.nix
# Lightweight Python toolchain — ML packages (wandb, marimo) are in combinations/ml.nix
{ pkgs }:

{
  packages = with pkgs; [
    uv
    python312
    ruff
    black
    mypy
    poetry
    gh
    kaggle
    openmpi
  ];
}
