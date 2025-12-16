# home/home.nix
{ config, lib, pkgs, username, systemUsername, email, system, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;

  # Import new module structures
  homeInstalls = import ../installations/home.nix {
    inherit config lib pkgs email system;
    inherit systemUsername username;
  };
  homeExec = import ../executions/home.nix {
    inherit config lib pkgs system;
    inherit systemUsername username;
  };
  homeConfig = import ../configurations/home.nix {
    inherit config lib pkgs email system;
    inherit systemUsername username;
  };
  commonExec = import ../executions/default.nix { inherit pkgs system; };
in
{
  home.username = systemUsername;
  home.stateVersion = "24.05";

  home.packages = homeInstalls.packages;

  programs = lib.recursiveUpdate homeInstalls.programs {
    # Git
    git = homeInstalls.programs.git // homeConfig.git;

    # Starship
    starship = homeInstalls.programs.starship // homeConfig.starship;

    # Zsh
    zsh = homeInstalls.programs.zsh // homeConfig.zsh // {
      shellAliases = homeExec.aliases // {
        # Noglob settings for nix commands (prevents "no matches found" errors with .#flake syntax)
        nix = "noglob nix";
      };
      initContent = homeExec.zshConfig.initExtra;
    };

    # Bash
    bash = homeInstalls.programs.bash // {
      shellAliases = homeExec.aliases;
    };

    # Bat configuration
    bat = homeInstalls.programs.bat // homeConfig.bat;

  };

  # Set session variables from configuration module
  home.sessionVariables = homeConfig.environment;
}
