# home/default.nix
{ pkgs, system ? builtins.currentSystem, ... }:
let
  commonPackages = import ../packages/packages.nix { inherit pkgs system; };
in
{
  home.packages = commonPackages;

  programs.zsh.enable = true;
  # Drain direnv integration from fish for others
  programs.fish = {
    enable = true;
    shellInit = ''
      # direnv hook
      # if status --is-interactive
      #   eval (direnv hook fish)
      # end
  '';
  };
  programs.starship.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.git.enable = true;
  programs.bat.enable = true;
  home.sessionVariables = {
    EDITOR = "nvim";
    LANG = "en_US.UTF-8";
  };
  programs.home-manager.enable = true;
  programs.fastfetch.enable = true;
}
