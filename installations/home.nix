# installations/home.nix
# Home-manager specific packages and programs configuration
{ config, lib, pkgs, username, email, system, ... }:

let
  # Import common packages and programs
  common = import ./default.nix { inherit pkgs system; };
  # Import common executions (aliases, functions, initScript)
  executions = import ../executions/default.nix { inherit pkgs system; };
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  # Merge common packages with home-manager specific packages
  packages = common.packages ++ (with pkgs; [
    eza
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

    # Bash configuration
    bash = {
      enable = true;
      enableCompletion = false;  # Disable to prevent early loading - we'll load it manually after bash switch
      historySize = 10000;
      historyFileSize = 100000;
      historyControl = [ "ignoredups" "ignorespace" ];
      shellOptions = [
        "histappend"
        "checkwinsize"
        "extglob"
        "globstar"
        "checkjobs"
      ];
      # bashrcExtra runs BEFORE everything else (even before interactive check)
      bashrcExtra = ''
        # ABSOLUTE FIRST: Mark that bashrc is being loaded
        echo "====== BASHRC LOADING ======"
        echo "Current bash: $BASH_VERSION"

        # FIRST THING: Switch to bash 5.3 if we're on old bash
        # Note: Must do this BEFORE setting other variables since exec replaces the process
        if [ -n "$BASH_VERSION" ]; then
          case "$BASH_VERSION" in
            3.*|4.0.*|4.1.*)
              # Load session vars first
              if [ -f ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
                source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
              fi

              # Determine which bash to use - always use hardcoded path to be sure
              NEW_BASH="/nix/store/w6y2cw4j0x2vwfg5pbcdvs5777f9g6af-bash-interactive-5.3p0/bin/bash"

              # Debug: Show what we're about to do
              echo "DEBUG: Old bash detected ($BASH_VERSION)"
              echo "DEBUG: Switching to: $NEW_BASH"
              echo "DEBUG: Checking if executable..."

              # Switch immediately - this prevents all the errors below
              if [ -x "$NEW_BASH" ]; then
                export BASH_SILENCE_DEPRECATION_WARNING=1
                # Preserve TERM_PROGRAM through exec (for Zed detection)
                export TERM_PROGRAM
                export TERM_PROGRAM_VERSION
                echo "DEBUG: About to exec... if bashrc loads again, exec worked!"
                exec "$NEW_BASH"
                # This line should NEVER be reached if exec succeeds
                echo "DEBUG: FATAL - exec failed! Still here after exec"
                exit 1
              else
                echo "DEBUG: ERROR - $NEW_BASH is not executable!"
                ls -la "$NEW_BASH" 2>&1
              fi
              ;;
          esac
        fi

        # Zed terminal workaround: Disable readline escapes for better compatibility
        # The issue is that something (possibly direnv or Zed itself) strips content
        # between \[ and \], leaving only empty markers
        # This must be set AFTER the bash version check/exec above
        if [[ "$TERM_PROGRAM" == "zed" ]]; then
          # For Zed, we'll use a simpler prompt without readline escapes
          # This will be set after starship init
          export ZED_PROMPT_FIX=1
        fi
      '';
      profileExtra = ''
        # Switch to Nix bash-interactive if we're running old bash
        if [ -n "$BASH_VERSION" ]; then
          case "$BASH_VERSION" in
            3.*|4.0.*|4.1.*)
              # We're running an old bash (< 4.2), switch to Nix bash-interactive
              if [ -f ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
                source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
              fi

              # Use SHELL variable or fallback to bash-interactive path
              NEW_BASH="$SHELL"
              if [ -z "$NEW_BASH" ] || [ "$NEW_BASH" = "$BASH" ] || [[ "$NEW_BASH" == *"/zsh"* ]]; then
                # If SHELL is not set, same as current, or pointing to zsh, use bash-interactive directly
                NEW_BASH="/nix/store/w6y2cw4j0x2vwfg5pbcdvs5777f9g6af-bash-interactive-5.3p0/bin/bash"
              fi

              if [ -n "$NEW_BASH" ] && [ -x "$NEW_BASH" ]; then
                export BASH_SILENCE_DEPRECATION_WARNING=1
                exec "$NEW_BASH" -l
              fi
              ;;
          esac
        fi
      '';
      initExtra = ''
        # Bash-specific initialization (only runs if we're on bash 5.3+)
        # If we're still on bash 3.2, the bashrcExtra above would have exec'd to bash 5.3

        # Only load bash-completion if 'complete' builtin exists
        # (i.e., bash was compiled with programmable completion support)
        if type complete >/dev/null 2>&1; then
          if [[ ! -v BASH_COMPLETION_VERSINFO ]]; then
            if [ -f "${pkgs.bash-completion}/etc/profile.d/bash_completion.sh" ]; then
              source "${pkgs.bash-completion}/etc/profile.d/bash_completion.sh"
            fi
          fi
        fi

        # Load common initialization script (starship, zoxide, fzf, etc.)
        ${executions.initScript}

        # Load common shell functions
        ${executions.functions}

        # Zed terminal prompt fix
        if [ -n "$ZED_PROMPT_FIX" ]; then
          # Override starship_precmd to strip readline escapes for Zed
          if type starship_precmd &>/dev/null; then
            _original_starship_precmd="$(declare -f starship_precmd)"
            eval "''${_original_starship_precmd/starship_precmd/_starship_precmd_original}"

            starship_precmd() {
              _starship_precmd_original
              # Strip readline escape markers \[ and \] from PS1
              PS1="''${PS1//\\[/}"
              PS1="''${PS1//\\]/}"
            }
          fi
        fi
      '';
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

    # GnuPG
    gpg = {
      enable = true;
    };

    # Home-manager itself
    home-manager.enable = true;
  };
}
