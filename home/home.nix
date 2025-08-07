# TODO: migrate to home-manager
# home/home.nix
{ config, lib, pkgs, username,  email, ... }: {
  home.username = username;
  home.homeDirectory = config.users.users.${username}.home or "/home/${username}";
  home.stateVersion = "24.05";

  imports = [
    ./default.nix
  ];

  programs.git = {
    enable = true;
    userName = username;
    userEmail = email;
  };

  home.sessionVariables.WELCOME_MSG = "Welcome, ${username}. You are in ⌬ nix together";
  programs.zsh.initExtra = "echo $WELCOME_MSG";
}
