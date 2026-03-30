# packages/platform/aarch64-darwin.nix
{ pkgs }:

{
  packages = with pkgs; [
    coreutils
    macpm
    pkgs.nvtopPackages.full
    devenv
  ];
}
