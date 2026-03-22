# home/home.nix
{ config, lib, pkgs, username, systemUsername, email, system, everything-claude-code, ... }:
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

  # Claude Code configuration
  claudeCode = import ../installations/claude-code.nix {
    inherit config lib pkgs everything-claude-code;
  };

  # Doom Emacs: user-editable config directory
  homeDirectory = config.home.homeDirectory;
  userDoomDir = "${homeDirectory}/.doom.d";
  userDoomDirExists = builtins.pathExists (builtins.toPath userDoomDir);

  # Default doom config (from repo) with user identity injected
  defaultDoomDir = pkgs.symlinkJoin {
    name = "doom.d";
    paths = [
      (pkgs.writeTextDir "init.el" (builtins.readFile ../doom.d/init.el))
      (pkgs.writeTextDir "packages.el" (builtins.readFile ../doom.d/packages.el))
      (pkgs.writeTextDir "config.el" ''
        ;;; config.el -*- lexical-binding: t; -*-
        ;; User identity (injected from flake)
        (setq user-full-name "${username}"
              user-mail-address "${email}")

        ${builtins.readFile ../doom.d/config.el}
      '')
    ];
  };

  # Activation script: copy defaults to ~/.doom.d/ only if not exists
  doomActivationScript = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "${userDoomDir}" ]; then
      echo "Initializing Doom Emacs config at ${userDoomDir}..."
      mkdir -p "${userDoomDir}"
      cp "${defaultDoomDir}"/init.el "${userDoomDir}/init.el"
      cp "${defaultDoomDir}"/packages.el "${userDoomDir}/packages.el"
      cp "${defaultDoomDir}"/config.el "${userDoomDir}/config.el"
      chmod -R u+w "${userDoomDir}"
      echo "Done. Edit files in ${userDoomDir} to customize Doom Emacs."
    fi
  '';
in
{
  home.username = systemUsername;
  home.stateVersion = "24.05";

  # Disable manual generation to avoid "builtins.toFile options.json" warning
  # See: https://github.com/nix-community/home-manager/issues/7935
  manual.manpages.enable = false;
  manual.html.enable = false;
  manual.json.enable = false;

  home.packages = homeInstalls.packages ++ claudeCode.packages;

  # Activation scripts: Claude Code + Doom Emacs default config
  home.activation = claudeCode.activation // {
    initDoomConfig = doomActivationScript;
  };

  programs = lib.recursiveUpdate homeInstalls.programs {
    # Doom Emacs (via nix-doom-emacs-unstraightened)
    # Uses ~/.doom.d/ if it exists (user-editable), otherwise repo defaults
    doom-emacs = {
      enable = true;
      doomDir =
        if userDoomDirExists
        then builtins.toPath userDoomDir
        else defaultDoomDir;
    };

    # Git
    git = homeInstalls.programs.git // homeConfig.git;

    # Starship
    starship = homeInstalls.programs.starship // homeConfig.starship;

    # Zsh
    zsh = homeInstalls.programs.zsh // homeConfig.zsh // {
      shellAliases = homeExec.aliases // claudeCode.aliases // {
        # Noglob settings for nix commands (prevents "no matches found" errors with .#flake syntax)
        nix = "noglob nix";
      };
      initContent = homeExec.zshConfig.initExtra;
    };

    # Bash
    bash = homeInstalls.programs.bash // {
      shellAliases = homeExec.aliases // claudeCode.aliases;
      initExtra = homeExec.bashConfig.initExtra;
    };

    # Bat configuration
    bat = homeInstalls.programs.bat // homeConfig.bat;

  };

  # Set session variables from configuration module
  home.sessionVariables = homeConfig.environment;
}
