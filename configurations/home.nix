# configurations/home.nix
# Home-manager specific configuration settings
{ config, lib, pkgs, username, email, system, ... }:

let
  # Import common configurations
  common = import ./default.nix { inherit pkgs system; };
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  # Merge common environment with home-manager specific
  environment = common.environment // {
    # Home-manager specific environment variables
    HOME_MANAGER_CONFIG = "$HOME/.config/home-manager/home.nix";
    HOME_MANAGER_BACKUP_EXT = "backup";

    # User-specific paths
    PATH = "$HOME/.local/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:$PATH";

    # macOS specific
    HOMEBREW_NO_ANALYTICS = if isDarwin then "1" else null;
    HOMEBREW_NO_AUTO_UPDATE = if isDarwin then "1" else null;
  };

  # Starship prompt configuration
  starship = {
    format = ''
      [╭─](bold green)$username$hostname$directory$git_branch$git_status$cmd_duration
      [╰─](bold green)$character
    '';

    username = {
      show_always = true;
      format = "[$user]($style) in ";
      style_user = "bold bright-cyan";
      style_root = "bold bright-red";
    };

    hostname = {
      ssh_only = false;
      format = "[@$hostname]($style) ";
      style = "bold bright-blue";
      disabled = false;
    };

    directory = {
      format = "[$path]($style)[$read_only]($read_only_style) ";
      style = "bold bright-green";
      truncation_length = 3;
      truncate_to_repo = false;
      truncation_symbol = "…/";
      home_symbol = "~";
      read_only = " 🔒";
      read_only_style = "red";
    };

    character = {
      success_symbol = "[➜](bold bright-purple)";
      error_symbol = "[✗](bold bright-red)";
      vicmd_symbol = "[V](bold bright-yellow)";
    };

    git_branch = {
      format = "on [$symbol$branch]($style) ";
      symbol = " ";
      style = "bold bright-magenta";
    };

    git_status = {
      format = "([$all_status$ahead_behind]($style)) ";
      style = "bold bright-yellow";
      conflicted = "🏳";
      ahead = "⇡\${count}";
      behind = "⇣\${count}";
      diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
      untracked = "🤷";
      stashed = "📦";
      modified = "📝";
      staged = '[++\($count\)](green)';
      renamed = "👅";
      deleted = "🗑";
    };

    cmd_duration = {
      min_time = 500;
      format = "took [$duration]($style) ";
      style = "bold bright-yellow";
      show_milliseconds = false;
      disabled = false;
    };

    # Language modules
    rust = {
      format = "via [$symbol($version )]($style)";
      symbol = "🦀 ";
      style = "bold red";
    };

    golang = {
      format = "via [$symbol($version )]($style)";
      symbol = "🐹 ";
      style = "bold cyan";
    };

    python = {
      format = "via [\${symbol}\${pyenv_prefix}(\${version} )(\($virtualenv\) )]($style)";
      symbol = "🐍 ";
      style = "yellow bold";
      pyenv_version_name = false;
      python_binary = ["python3" "python"];
    };

    nodejs = {
      format = "via [$symbol($version )]($style)";
      symbol = "⬢ ";
      style = "bold green";
    };

    package = {
      format = "via [$symbol$version]($style) ";
      symbol = "📦 ";
      style = "208 bold";
    };

    # Other useful modules
    battery = {
      full_symbol = "🔋 ";
      charging_symbol = "⚡️ ";
      discharging_symbol = "💀 ";
      display = [
        { threshold = 10; style = "bold red"; }
        { threshold = 30; style = "bold yellow"; }
      ];
    };

    time = {
      disabled = false;
      format = "🕙[$time]($style) ";
      style = "bold bright-white";
      use_12hr = false;
    };

    status = {
      style = "bg:blue";
      symbol = "🔴";
      format = "[$symbol $common_meaning$signal_name$maybe_int]($style) ";
      map_symbol = true;
      disabled = false;
    };

    memory_usage = {
      disabled = true;
      threshold = 75;
      format = "via $symbol [$ram_pct]($style) ";
      symbol = "🐏";
      style = "bold dimmed white";
    };
  };

  # Zsh specific configuration
  zsh = {
    # Oh-My-Zsh configuration
    oh-my-zsh = {
      enable = false; # We're using our own configuration
      theme = "robbyrussell";
      plugins = [
        "git"
        "docker"
        "kubectl"
        "npm"
        "python"
        "rust"
        "golang"
      ];
    };

    # History configuration
    history = {
      size = 10000;
      save = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      extended = true;
      share = true;
    };

    # Completion settings
    completion = {
      enable = true;
      autoMenu = true;
      menuSelect = true;
      completeInWord = true;
      matcher = "m:{a-zA-Z}={A-Za-z}"; # Case insensitive completion
    };

    # Directory navigation
    dirHashes = {
      docs = "$HOME/Documents";
      dl = "$HOME/Downloads";
      proj = "$HOME/Projects";
      cfg = "$HOME/.config";
      nix = "$HOME/.config/nixpkgs";
    };

    # Zsh options
    options = {
      # History
      EXTENDED_HISTORY = true;
      HIST_EXPIRE_DUPS_FIRST = true;
      HIST_IGNORE_DUPS = true;
      HIST_IGNORE_SPACE = true;
      HIST_VERIFY = true;
      SHARE_HISTORY = true;

      # Completion
      COMPLETE_IN_WORD = true;
      ALWAYS_TO_END = true;
      PATH_DIRS = true;
      AUTO_MENU = true;
      AUTO_LIST = true;
      AUTO_PARAM_SLASH = true;
      EXTENDED_GLOB = true;

      # Directory
      AUTO_CD = true;
      AUTO_PUSHD = true;
      PUSHD_IGNORE_DUPS = true;
      PUSHDMINUS = true;

      # Jobs
      NOTIFY = true;
      LONG_LIST_JOBS = true;
      INTERACTIVE_COMMENTS = true;

      # Other
      CORRECT = true;
      CORRECT_ALL = false;
      IGNORE_EOF = true;
    };
  };

  # Neovim configuration
  neovim = {
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;

    # Basic settings
    settings = {
      number = true;
      relativenumber = true;
      autoindent = true;
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      smarttab = true;
      mouse = "a";
      clipboard = "unnamedplus";
      termguicolors = true;
      cursorline = true;
      showmatch = true;
      incsearch = true;
      hlsearch = true;
      ignorecase = true;
      smartcase = true;
      wildmenu = true;
      wildmode = "longest:full,full";
      wrap = false;
      scrolloff = 8;
      sidescrolloff = 8;
      splitbelow = true;
      splitright = true;
      hidden = true;
      backup = false;
      writebackup = false;
      swapfile = false;
      undofile = true;
      undodir = "$HOME/.vim/undodir";
      updatetime = 50;
      timeoutlen = 500;
      encoding = "utf-8";
      fileencoding = "utf-8";
    };

    # Plugin configuration would go here
    plugins = {
      # Example structure:
      # telescope.enable = true;
      # nvim-tree.enable = true;
      # lsp.enable = true;
    };
  };

  # Bat (better cat) configuration
  bat = {
    theme = "TwoDark";
    style = "numbers,changes,header";
    italic-text = "always";
    tabs = "2";
    wrap = "never";
    pager = "less -FR";

    # Custom themes can be added
    themes = {
      snazzy = {
        src = pkgs.fetchFromGitHub {
          owner = "connorholyday";
          repo = "nord-bat";
          rev = "master";
          sha256 = ""; # Would need actual hash
        };
      };
    };
  };

  # Alacritty terminal configuration (if used)
  alacritty = {
    fontSize = 13;
    fontFamily = "MesloLGS NF";

    theme = "snazzy";

    window = {
      opacity = 0.98;
      padding = {
        x = 10;
        y = 10;
      };
      dynamic_title = true;
    };

    cursor = {
      style = "Block";
      blinking = "On";
    };

    scrollback = {
      lines = 10000;
      multiplier = 3;
    };

    selection = {
      semantic_escape_chars = ",│`|:\"' ()[]{}<>\t";
      save_to_clipboard = true;
    };
  };

  # iTerm2 configuration (macOS)
  iterm2 = lib.optionalAttrs isDarwin {
    profile = "Snazzy";

    settings = {
      # Font
      "Normal Font" = "MesloLGS-NF-Regular 13";
      "Non Ascii Font" = "MesloLGS-NF-Regular 13";
      "Use Non-ASCII Font" = true;
      "Vertical Spacing" = 1.1;
      "Use Bold Font" = true;
      "ASCII Ligatures" = true;
      "Non-ASCII Ligatures" = true;

      # Window
      "Window Type" = 12; # No title bar
      "Transparency" = 0.02;
      "Blur" = false;
      "Blur Radius" = 30;

      # Terminal
      "Scrollback Lines" = 10000;
      "Unlimited Scrollback" = false;
      "Close Sessions On End" = true;
      "Prompt Before Closing 2" = 0;

      # Behavior
      "Option Key Sends" = 2; # Meta
      "Right Option Key Sends" = 2;
      "Application Keypad Allowed" = true;
      "Send Code When Idle" = false;
      "Silence Bell" = true;
      "Visual Bell" = false;
      "Flashing Bell" = false;

      # Session
      "Custom Command" = "No";
      "Initial Text" = "";
      "Working Directory" = "/Users/${username}";

      # Keys
      "Hotkey" = true;
      "HotkeyChar" = 32; # Space
      "HotkeyCode" = 49;
      "HotkeyModifiers" = 524288; # Cmd
    };
  };

  # Home Manager settings
  home = {
    stateVersion = "24.05";

    # Session variables
    sessionVariables = common.environment // {
      WELCOME_MSG = "Welcome home, ${username}!";
    };

    # Session path
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.cargo/bin"
      "$HOME/go/bin"
      "$HOME/.npm-global/bin"
    ];

    # Activation scripts
    activation = {
      # Create common directories
      createDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p $HOME/{Projects,Downloads,Documents,Pictures,Videos,Music}
        $DRY_RUN_CMD mkdir -p $HOME/.local/{bin,share,state}
        $DRY_RUN_CMD mkdir -p $HOME/.config
        $DRY_RUN_CMD mkdir -p $HOME/.cache
      '';

      # Setup development directories
      setupDev = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p $HOME/Projects/{personal,work,learning,experiments}
        $DRY_RUN_CMD mkdir -p $HOME/.config/git
      '';
    };
  };

  # File associations
  xdg = {
    enable = true;

    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/plain" = ["nvim.desktop"];
        "text/markdown" = ["nvim.desktop"];
        "text/x-python" = ["nvim.desktop"];
        "text/x-rust" = ["nvim.desktop"];
        "text/x-go" = ["nvim.desktop"];
        "text/javascript" = ["nvim.desktop"];
        "text/typescript" = ["nvim.desktop"];
        "application/json" = ["nvim.desktop"];
        "application/xml" = ["nvim.desktop"];
        "application/x-yaml" = ["nvim.desktop"];
      };
    };
  };
}
