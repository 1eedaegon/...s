# home/default.nix
{ pkgs, ... }:
let
  commonPackages = import ../packages.nix { inherit pkgs; };
in
{
  home.packages = commonPackages;

  programs.zsh = {
    enable = true;
    shellAliases = {
      ls = "lsd";
      l  = "lsd -l";
      la = "lsd -a";
      ll = "lsd -la";
      lt = "lsd --tree";
    };
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
}
