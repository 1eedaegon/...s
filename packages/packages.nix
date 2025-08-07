# packages.nix
{ pkgs, system }:

with pkgs; [
  nerd-fonts.symbols-only
  nerd-fonts.fira-code
  starship
  lsd # https://github.com/lsd-rs/lsd
  bat
  git
  gh
  htop
  curl
  asciinema
  fontconfig
  direnv
  gcc
  gnumake
  just
  act
  #  knope: not yet
] ++ (if system == "x86_64-darwin" || system == "aarch64-darwin" then [
  # macOS-only
  coreutils
  asitop
] else if system == "x86_64-linux" then [
  # Linux-only
  systemd
] else []
)
