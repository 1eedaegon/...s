# packages/platform/aarch64-linux.nix
{ pkgs }:

{
  packages = with pkgs; [
    systemd
    net-tools
    nmap
    libgcc
    valgrind
    devenv
    zed-editor
    pkgs.cursor-arm
  ];
}
