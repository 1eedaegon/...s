# home/home.nix
{ config, lib, pkgs, username, systemUsername, email, system, everything-claude-code, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;

  # Import new module structures
  homeInstalls = import ./packages.nix {
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
  claudeCode = import ./claude-code.nix {
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

  # Knowledge base directory (read from doom.d/config.el default)
  kbDir = "${homeDirectory}/research-git";

  # Activation script: init doom config + knowledge base directory
  doomActivationScript = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Doom config
    if [ ! -d "${userDoomDir}" ]; then
      echo "Initializing Doom Emacs config at ${userDoomDir}..."
      mkdir -p "${userDoomDir}"
      cp "${defaultDoomDir}"/init.el "${userDoomDir}/init.el"
      cp "${defaultDoomDir}"/packages.el "${userDoomDir}/packages.el"
      cp "${defaultDoomDir}"/config.el "${userDoomDir}/config.el"
      chmod -R u+w "${userDoomDir}"
      echo "Done. Edit files in ${userDoomDir} to customize Doom Emacs."
    fi

    # Knowledge base directory structure + git init
    if [ ! -d "${kbDir}" ]; then
      echo "Initializing knowledge base at ${kbDir}..."
      mkdir -p "${kbDir}"/{inbox,concepts,weekly,blog-drafts}
      mkdir -p "${kbDir}"/papers/{reading,done}
      mkdir -p "${kbDir}"/projects/{research,saas,work}
      mkdir -p "${kbDir}"/pe/{topics,keywords,mock-answers,answer-templates}
      mkdir -p "${kbDir}"/review/{protein,multimodal}

      cat > "${kbDir}/shutdown.org" << 'SHUTDOWN'
    #+title: Shutdown

    * Daily checklist
    - [ ] Anki cards created
    - [ ] inbox cleared
    - [ ] Tomorrow's paper ready
    - [ ] Deep Block goal written

    ** Tomorrow's goal

    SHUTDOWN

      cat > "${kbDir}/.gitignore" << 'GITIGNORE'
    .DS_Store
    *.elc
    .org-id-locations
    .org-roam.db
    .#*
    \#*\#
    *.pdf
    *.epub
    GITIGNORE

      cd "${kbDir}" && ${pkgs.git}/bin/git init
      echo "Done. Knowledge base initialized at ${kbDir}"
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
