# installations/home.nix
# Home-manager specific packages and programs configuration
{ config, lib, pkgs, username, email, system, ... }:

let
  # Import common packages and programs
  common = import ./default.nix { inherit pkgs system; };
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  # Merge common packages with home-manager specific packages
  packages = common.packages ++ (with pkgs; [
    eza
    lazygit
  ]);

  # Programs configuration for home-manager
  programs = lib.recursiveUpdate common.programs {
    # Git configuration
    git = {
      enable = true;
      userName = username;
      userEmail = email;
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        core.editor = "nvim";
      };
    };

    # Starship prompt configuration
    starship = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    # Zsh configuration
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
    };

    # Bat configuration
    bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        italic-text = "always";
      };
    };

    # FZF configuration
    fzf = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    # Zoxide configuration
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    # FastFetch configuration
    fastfetch = {
      enable = true;
    };

    # Home-manager itself
    home-manager.enable = true;
  };
}
