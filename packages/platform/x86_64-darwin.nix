# packages/platform/x86_64-darwin.nix
{ pkgs }:

{
  packages = with pkgs; [
    coreutils
    pkgs.nvtopPackages.full
    # devenv: x86_64-darwin에서 nix-util 빌드 실패, 별도 설치: nix profile install nixpkgs#devenv
  ];
}
