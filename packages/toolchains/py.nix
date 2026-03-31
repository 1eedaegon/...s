# packages/toolchains/py.nix
{ pkgs }:

{
  packages = with pkgs; [
    uv
    (python312.withPackages (ps: with ps; [
      marimo
      wandb
    ]))
    ruff
    black
    mypy
    poetry
    gh
    kaggle
    openmpi
  ];
}
