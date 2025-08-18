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

    # Bat configuration
    bat = homeInstalls.programs.bat // homeConfig.bat;

  };

  # Set session variables from configuration module
  home.sessionVariables = homeConfig.environment;

  # Keep existing iTerm2 configuration for macOS
  home.file = lib.mkIf isDarwin {
    "Library/Application Support/iTerm2/DynamicProfiles/snazzy.json".text = builtins.toJSON {
      Profiles = [{
        Name = "Snazzy";
        Guid = "5D5F9F9F-9F9F-9F9F-9F9F-9F9F9F9F9F9F";
        "Normal Font" = "MesloLGS-NF-Regular 13";
        "Non Ascii Font" = "MesloLGS-NF-Regular 13";
        "Use Non-ASCII Font" = true;
        "Vertical Spacing" = 1.1;
        "Use Bold Font" = true;
        "ASCII Ligatures" = true;
        "Non-ASCII Ligatures" = true;

        # Snazzy Colors
        "Foreground Color" = {
          "Red Component" = 0.937;
          "Green Component" = 0.941;
          "Blue Component" = 0.921;
        };
        "Background Color" = {
          "Red Component" = 0.157;
          "Green Component" = 0.165;
          "Blue Component" = 0.212;
        };
        "Bold Color" = {
          "Red Component" = 1.0;
          "Green Component" = 1.0;
          "Blue Component" = 1.0;
        };
        "Cursor Color" = {
          "Red Component" = 0.973;
          "Green Component" = 0.973;
          "Blue Component" = 0.973;
        };
        "Cursor Text Color" = {
          "Red Component" = 0.157;
          "Green Component" = 0.165;
          "Blue Component" = 0.212;
        };
        "Selection Color" = {
          "Red Component" = 0.239;
          "Green Component" = 0.247;
          "Blue Component" = 0.286;
        };

        # Snazzy ANSI Colors (기존 유지)
        "Ansi 0 Color" = {
          # Black
          "Red Component" = 0.157;
          "Green Component" = 0.165;
          "Blue Component" = 0.212;
        };
        "Ansi 1 Color" = {
          # Red
          "Red Component" = 1.0;
          "Green Component" = 0.333;
          "Blue Component" = 0.333;
        };
        "Ansi 2 Color" = {
          # Green
          "Red Component" = 0.314;
          "Green Component" = 0.98;
          "Blue Component" = 0.439;
        };
        "Ansi 3 Color" = {
          # Yellow
          "Red Component" = 0.957;
          "Green Component" = 0.965;
          "Blue Component" = 0.482;
        };
        "Ansi 4 Color" = {
          # Blue
          "Red Component" = 0.341;
          "Green Component" = 0.714;
          "Blue Component" = 1.0;
        };
        "Ansi 5 Color" = {
          # Magenta
          "Red Component" = 1.0;
          "Green Component" = 0.475;
          "Blue Component" = 0.776;
        };
        "Ansi 6 Color" = {
          # Cyan
          "Red Component" = 0.541;
          "Green Component" = 0.914;
          "Blue Component" = 0.992;
        };
        "Ansi 7 Color" = {
          # White
          "Red Component" = 0.937;
          "Green Component" = 0.941;
          "Blue Component" = 0.921;
        };
        "Ansi 8 Color" = {
          # Bright Black
          "Red Component" = 0.424;
          "Green Component" = 0.447;
          "Blue Component" = 0.537;
        };
        "Ansi 9 Color" = {
          # Bright Red
          "Red Component" = 1.0;
          "Green Component" = 0.333;
          "Blue Component" = 0.333;
        };
        "Ansi 10 Color" = {
          # Bright Green
          "Red Component" = 0.314;
          "Green Component" = 0.98;
          "Blue Component" = 0.439;
        };
        "Ansi 11 Color" = {
          # Bright Yellow
          "Red Component" = 0.957;
          "Green Component" = 0.965;
          "Blue Component" = 0.482;
        };
        "Ansi 12 Color" = {
          # Bright Blue
          "Red Component" = 0.341;
          "Green Component" = 0.714;
          "Blue Component" = 1.0;
        };
        "Ansi 13 Color" = {
          # Bright Magenta
          "Red Component" = 1.0;
          "Green Component" = 0.475;
          "Blue Component" = 0.776;
        };
        "Ansi 14 Color" = {
          # Bright Cyan
          "Red Component" = 0.541;
          "Green Component" = 0.914;
          "Blue Component" = 0.992;
        };
        "Ansi 15 Color" = {
          # Bright White
          "Red Component" = 1.0;
          "Green Component" = 1.0;
          "Blue Component" = 1.0;
        };

        # Other Settings
        "Custom Command" = "No";
        "Working Directory" = "/Users/${username}";
        "Prompt Before Closing 2" = 0;
        "Scrollback Lines" = 10000;
        "Unlimited Scrollback" = false;
        "Close Sessions On End" = true;
        "Blur" = false;
        "Blur Radius" = 30;
        "Transparency" = 0;
        "Initial Text" = "";
        "Use Italic Font" = true;
        "Blinking Cursor" = true;
        "Cursor Type" = 1; # Box cursor
        "Minimum Contrast" = 0;
      }];
    };
  };

  # Keep existing activation scripts for macOS
  home.activation = lib.mkIf isDarwin {
    setupIterm = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Setting up iTerm2 with Snazzy theme..."

      DEFAULTS="/usr/bin/defaults"
      if [ -d "/Applications/iTerm.app" ] || [ -d "$HOME/Applications/iTerm.app" ]; then
        if [ -x "$DEFAULTS" ]; then
          $DRY_RUN_CMD $DEFAULTS write com.googlecode.iterm2 "Default Bookmark Guid" -string "SNAZZY-NERD-FONT-PROFILE"
          $DRY_RUN_CMD $DEFAULTS write com.googlecode.iterm2 "New Bookmarks" -array-add "SNAZZY-NERD-FONT-PROFILE"
          $DRY_RUN_CMD $DEFAULTS write com.googlecode.iterm2 "OpenArrangementAtStartup" -bool false
          $DRY_RUN_CMD $DEFAULTS write com.googlecode.iterm2 "OpenNoWindowsAtStartup" -bool false

          $DRY_RUN_CMD $DEFAULTS write com.googlecode.iterm2 "PromptOnQuit" -bool false
          $DRY_RUN_CMD $DEFAULTS write com.googlecode.iterm2 "HideMenuBarInFullscreen" -bool true

          $DRY_RUN_CMD $DEFAULTS write com.googlecode.iterm2 "Hotkey" -bool true
          $DRY_RUN_CMD $DEFAULTS write com.googlecode.iterm2 "HotkeyChar" -int 32
          $DRY_RUN_CMD $DEFAULTS write com.googlecode.iterm2 "HotkeyCode" -int 49
          $DRY_RUN_CMD $DEFAULTS write com.googlecode.iterm2 "HotkeyModifiers" -int 524288

          echo "iTerm2 Snazzy theme has been set as default!"
        else
          echo "defaults command not found. Skipping iTerm2 preferences setup."
          echo "But the Snazzy profile has been created and can be selected manually."
        fi
      else
        echo "iTerm2 is not installed. Skipping iTerm2 setup."
      fi
    '';
  };
}
