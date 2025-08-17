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
    # Additional terminal tools for home environment
    eza

    # Additional development tools
    lazygit

  ]) ++ lib.optionals isDarwin [
    # macOS specific applications
    iterm2
    mas  # Mac App Store CLI
  ];

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
      settings = {
        format = ''
          [> $username$hostname$directory$git_branch$git_status$cmd_duration$line_break](bold bright-purple)
        '';

        username = {
          show_always = true;
          format = "[$user]($style)";
          style_user = "bold bright-cyan";
        };

        hostname = {
          ssh_only = false;
          format = "[@$hostname]($style) ";
          style = "bold bright-blue";
        };

        directory = {
          truncation_length = 3;
          truncate_to_repo = false;
          style = "bold bright-green";
        };

        character = {
          success_symbol = "[➜](bold bright-purple)";
          error_symbol = "[✗](bold bright-red)";
          vicmd_symbol = "[V](bold bright-yellow)";
        };

        git_branch = {
          format = "[$symbol$branch]($style) ";
          style = "bold bright-magenta";
        };

        git_status = {
          format = "([\\[$all_status$ahead_behind\\]]($style) )";
          style = "bold bright-yellow";
        };

        cmd_duration = {
          min_time = 500;
          format = "took [$duration]($style) ";
          style = "bold bright-yellow";
        };
      };
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
