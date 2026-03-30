# packages/toolchains/py.nix
{ pkgs }:

{
  packages = with pkgs; [
    uv
    python312
    ruff
    black
    mypy
    poetry
    marimo
    gh
    kaggle
    openmpi
  ];
}
