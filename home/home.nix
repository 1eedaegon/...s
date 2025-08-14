# TODO: migrate to home-manager
# home/home.nix
{ config, lib, pkgs, username,  email, system, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
in
{

  home.username = username;
  home.stateVersion = "24.05";

  imports = [
    ./default.nix
  ];
  home.packages = with pkgs; [
    # Desktop Editor
    # zed-editor

    # Fonts
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    nerd-fonts.hack
    nerd-fonts.roboto-mono

    # Terminal tools
    starship
    eza
    lsd
    bat
    fzf
    ripgrep
    zoxide
  ] ++ lib.optionals isDarwin [
    iterm2 # Default terminal mac
    mas    # Mac App Store CLI
  ];
  programs.git = {
    enable = true;
    userName = username;
    userEmail = email;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

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
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls = "lsd";
      l  = "lsd -l";
      la = "lsd -a";
      ll = "lsd -la";
      lt = "lsd --tree";
      cat = "bat";
      cd = "z";
      iterm-restart = "osascript -e 'quit app \"iTerm\"' && sleep 2 && open -a iTerm";

      z = "zed";
      zhere = "zed .";
    };

    initContent = ''
      # zoxide
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"

      # fzf
      source "${pkgs.fzf}/share/fzf/key-bindings.zsh"
      source "${pkgs.fzf}/share/fzf/completion.zsh"

      # snazzy colors
      export FZF_DEFAULT_OPTS='
        --color=fg:#eff0eb,bg:#282a36,hl:#bd93f9
        --color=fg+:#eff0eb,bg+:#3d3f49,hl+:#bd93f9
        --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6
        --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4
      '
      # neofetch
      fastfetch --logo-color-1 magenta --logo-color-2 cyan
      echo "$WELCOME_MSG"
    '';
  };
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";  # Like Snazzy
      italic-text = "always";
    };
  };

  home.file = lib.mkIf isDarwin {
    # "Library/Application Support/Zed/settings.json".text = builtins.toJSON {
    #   # Theme
    #   theme = "Catppuccin Macchiato";
    #   ui_font_size = 14;
    #   buffer_font_size = 14;

    #   # Font
    #   buffer_font_family = "JetBrainsMono Nerd Font";
    #   buffer_font_features = {
    #     calt = true;  # Ligatures
    #   };

    #   # Terminal
    #   terminal = {
    #     font_family = "MesloLGM Nerd Font";
    #     font_size = 14;
    #     line_height = 1.2;
    #     shell = {
    #       program = "zsh";
    #     };
    #     theme = {
    #       mode = "system";
    #       light = "Catppuccin Macchiato";
    #       dark = "Catppuccin Macchiato";
    #     };
    #     # 터미널 설정
    #     blinking = "terminal_controlled";
    #     copy_on_select = true;
    #     dock = "bottom";
    #     default_width = 640;
    #     default_height = 480;
    #     detect_venv = true;
    #     button = true;
    #   };

    #   show_line_numbers = true;
    #   relative_line_numbers = false;
    #   cursor_blink = true;
    #   hover_popover_enabled = true;
    #   show_completions_on_input = true;
    #   show_inline_completions = true;
    #   show_whitespaces = "selection";
    #   soft_wrap = "editor_width";

    #   # 탭 설정
    #   tab_size = 2;
    #   hard_tabs = false;

    #   # 포맷팅
    #   format_on_save = "on";
    #   formatter = "auto";

    #   # Git 설정
    #   git = {
    #     git_gutter = "tracked_files";
    #     inline_blame = {
    #       enabled = false;
    #     };
    #   };

    #   # LSP
    #   lsp = {
    #     rust_analyzer = {
    #       binary = {
    #         path_lookup = true;
    #       };
    #     };
    #   };

    #   # Vim
    #   vim_mode = false;

    #   # autosave
    #   autosave = {
    #     after_delay = {
    #       milliseconds = 1000;
    #     };
    #   };

    #   # telemetry off
    #   telemetry = {
    #     diagnostics = false;
    #     metrics = false;
    #   };
    # };
    # iTerm2 Snazzy Dynamic Profile
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

        # Snazzy ANSI Colors
        "Ansi 0 Color" = {  # Black
          "Red Component" = 0.157;
          "Green Component" = 0.165;
          "Blue Component" = 0.212;
        };
        "Ansi 1 Color" = {  # Red
          "Red Component" = 1.0;
          "Green Component" = 0.333;
          "Blue Component" = 0.333;
        };
        "Ansi 2 Color" = {  # Green
          "Red Component" = 0.314;
          "Green Component" = 0.98;
          "Blue Component" = 0.439;
        };
        "Ansi 3 Color" = {  # Yellow
          "Red Component" = 0.957;
          "Green Component" = 0.965;
          "Blue Component" = 0.482;
        };
        "Ansi 4 Color" = {  # Blue
          "Red Component" = 0.341;
          "Green Component" = 0.714;
          "Blue Component" = 1.0;
        };
        "Ansi 5 Color" = {  # Magenta
          "Red Component" = 1.0;
          "Green Component" = 0.475;
          "Blue Component" = 0.776;
        };
        "Ansi 6 Color" = {  # Cyan
          "Red Component" = 0.541;
          "Green Component" = 0.914;
          "Blue Component" = 0.992;
        };
        "Ansi 7 Color" = {  # White
          "Red Component" = 0.937;
          "Green Component" = 0.941;
          "Blue Component" = 0.921;
        };
        "Ansi 8 Color" = {  # Bright Black
          "Red Component" = 0.424;
          "Green Component" = 0.447;
          "Blue Component" = 0.537;
        };
        "Ansi 9 Color" = {  # Bright Red
          "Red Component" = 1.0;
          "Green Component" = 0.333;
          "Blue Component" = 0.333;
        };
        "Ansi 10 Color" = {  # Bright Green
          "Red Component" = 0.314;
          "Green Component" = 0.98;
          "Blue Component" = 0.439;
        };
        "Ansi 11 Color" = {  # Bright Yellow
          "Red Component" = 0.957;
          "Green Component" = 0.965;
          "Blue Component" = 0.482;
        };
        "Ansi 12 Color" = {  # Bright Blue
          "Red Component" = 0.341;
          "Green Component" = 0.714;
          "Blue Component" = 1.0;
        };
        "Ansi 13 Color" = {  # Bright Magenta
          "Red Component" = 1.0;
          "Green Component" = 0.475;
          "Blue Component" = 0.776;
        };
        "Ansi 14 Color" = {  # Bright Cyan
          "Red Component" = 0.541;
          "Green Component" = 0.914;
          "Blue Component" = 0.992;
        };
        "Ansi 15 Color" = {  # Bright White
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
        "Cursor Type" = 1;  # Box cursor
        "Minimum Contrast" = 0;
      }];
    };
  };
  home.activation = lib.mkIf isDarwin {
    setupIterm = lib.hm.dag.entryAfter ["writeBoundary"] ''
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

        setupZed = lib.hm.dag.entryAfter ["writeBoundary"] ''
          echo "Setting up Zed editor..."

          # Zed CLI
          if [ -d "/Applications/Zed.app" ] || [ -d "$HOME/Applications/Zed.app" ]; then
            # Zed CLI symlink
            ZED_CLI="/Applications/Zed.app/Contents/MacOS/cli"
            LOCAL_BIN="/usr/local/bin"

            if [ -f "$ZED_CLI" ]; then
              if [ ! -d "$LOCAL_BIN" ]; then
                echo "Creating /usr/local/bin directory..."
                $DRY_RUN_CMD sudo mkdir -p "$LOCAL_BIN" || true
              fi
              if [ ! -f "$LOCAL_BIN/zed" ]; then
                echo "Creating zed CLI symlink..."
                $DRY_RUN_CMD sudo ln -sf "$ZED_CLI" "$LOCAL_BIN/zed" 2>/dev/null || \
                $DRY_RUN_CMD ln -sf "$ZED_CLI" "$HOME/.local/bin/zed" 2>/dev/null || \
                echo "   Note: Could not create zed symlink. You may need to do it manually."
              fi
            fi

            echo "Zed editor has been configured with Nerd Fonts!"
            echo "Terminal font: MesloLGM Nerd Font"
            echo "Editor font: JetBrainsMono Nerd Font"
          else
            echo "Zed is not installed. Skipping Zed setup."
          fi
        '';
  };
}
