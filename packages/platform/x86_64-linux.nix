# packages/platform/x86_64-linux.nix
{ pkgs }:

{
  packages = with pkgs; [
    systemd
    net-tools
    nmap
    libgcc
    valgrind
    zed-editor
    code-cursor
  ];
}
