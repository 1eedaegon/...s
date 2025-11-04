# configurations/default.nix
# Common configuration settings for all environments
{ pkgs, system }:

{
  # Common environment variables
  environment = {
    # Editor settings
    EDITOR = "vim";
    VISUAL = "vim";

    # Locale settings
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";

    # Terminal settings
    TERM = "xterm-256color";
    COLORTERM = "truecolor";

    # Pager settings
    PAGER = "less";
    LESS = "-FRX";
    LESSANSIENDCHARS = "mK";
    # LESSHISTFILE = "-"; # Don't save less history

    # Man page colors
    # LESS_TERMCAP_mb = "$(printf '%b' '[1;31m')"; # begin blinking
    # LESS_TERMCAP_md = "$(printf '%b' '[1;36m')"; # begin bold
    # LESS_TERMCAP_me = "$(printf '%b' '[0m')"; # end mode
    # LESS_TERMCAP_so = "$(printf '%b' '[01;44;33m')"; # begin standout-mode
    # LESS_TERMCAP_se = "$(printf '%b' '[0m')"; # end standout-mode
    # LESS_TERMCAP_us = "$(printf '%b' '[1;32m')"; # begin underline
    # LESS_TERMCAP_ue = "$(printf '%b' '[0m')"; # end underline

    # FZF configuration
    FZF_DEFAULT_OPTS = ''
      --height 40%
      --layout=reverse
      --border
      --inline-info
      --color=fg:#eff0eb,bg:#282a36,hl:#bd93f9
      --color=fg+:#eff0eb,bg+:#3d3f49,hl+:#bd93f9
      --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6
      --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4
      --preview-window=:hidden
      --bind='ctrl-/:toggle-preview'
    '';

    FZF_DEFAULT_COMMAND = "rg --files --hidden --follow --glob '!.git/*'";
    FZF_CTRL_T_COMMAND = "$FZF_DEFAULT_COMMAND";
    FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git";

    HISTCONTROL = "ignoreboth:erasedups";
    HISTIGNORE = "ls:cd:cd -:pwd:exit:date:* --help";


    # Nix settings
    NIX_SHELL_PRESERVE_PROMPT = "1";

  };

  # Git global configuration
  git = {
    core = {
      editor = "vim";
      whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
      pager = "less -FRX --RAW-CONTROL-CHARS";
      autocrlf = "input";
    };
    color = {
      ui = "auto";
      branch = "auto";
      diff = "auto";
      interactive = "auto";
      status = "auto";
    };

    push = {
      default = "current";
      autoSetupRemote = true;
    };

    pull = {
      rebase = true;
    };

    fetch = {
      prune = true;
    };

    diff = {
      colorMoved = "default";
    };

    merge = {
      conflictstyle = "diff3";
    };

    rerere = {
      enabled = true;
    };

    alias = {
      # Shortcuts
      co = "checkout";
      br = "branch";
      ci = "commit";
      st = "status";

      # Useful aliases
      last = "log -1 HEAD";
      unstage = "reset HEAD --";
      amend = "commit --amend --reuse-message=HEAD";
      contrib = "shortlog --summary --numbered";

      # Pretty logs
      lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      graph = "log --graph --oneline --decorate --all";
    };
  };

  # SSH configuration
  ssh = {
    compression = true;
    serverAliveInterval = 60;
    serverAliveCountMax = 2;
    hashKnownHosts = false;

    # Common SSH shortcuts can be added here
    hosts = {
      # Example:
      # "myserver" = {
      #   hostname = "example.com";
      #   user = "myuser";
      #   port = 22;
      # };
    };
  };

  # Tmux configuration
  tmux = {
    baseIndex = 1;
    clock24 = true;
    escapeTime = 0;
    historyLimit = 10000;
    keyMode = "vi";
    mouseMode = true;

    plugins = [
      "sensible"
      "yank"
      "copycat"
      "open"
      "pain-control"
      "sessionist"
    ];
  };

  # Directory colors (for ls/lsd)
  dircolors = {
    # File types
    ".tar" = "01;31";
    ".tgz" = "01;31";
    ".zip" = "01;31";
    ".gz" = "01;31";
    ".bz2" = "01;31";
    ".7z" = "01;31";

    # Media
    ".jpg" = "01;35";
    ".jpeg" = "01;35";
    ".png" = "01;35";
    ".gif" = "01;35";
    ".bmp" = "01;35";
    ".svg" = "01;35";
    ".mp4" = "01;35";
    ".mkv" = "01;35";
    ".avi" = "01;35";
    ".mp3" = "00;36";
    ".flac" = "00;36";
    ".wav" = "00;36";

    # Documents
    ".pdf" = "00;32";
    ".doc" = "00;32";
    ".docx" = "00;32";
    ".xls" = "00;32";
    ".xlsx" = "00;32";
    ".ppt" = "00;32";
    ".pptx" = "00;32";

    # Code
    ".py" = "00;33";
    ".js" = "00;33";
    ".ts" = "00;33";
    ".rs" = "00;33";
    ".go" = "00;33";
    ".c" = "00;33";
    ".cpp" = "00;33";
    ".h" = "00;33";
    ".hpp" = "00;33";
    ".nix" = "00;34";
    ".md" = "00;37";
    ".json" = "00;37";
    ".yaml" = "00;37";
    ".yml" = "00;37";
    ".toml" = "00;37";
    ".xml" = "00;37";
    ".html" = "00;37";
    ".css" = "00;37";
  };

  # Terminal features
  terminal = {
    # Enable true color support
    truecolor = true;

    # Enable unicode support
    unicode = true;

    # Enable mouse support where applicable
    mouse = true;

    # Default terminal title format
    titleFormat = "%n@%m: %s";
  };

  # Security settings
  security = {
    # SSH agent
    enableSSHAgent = true;

    # GPG agent
    enableGPGAgent = true;

    # Keychain integration
    enableKeychain = true;
  };

  # Performance settings
  performance = {
    # Enable parallel operations where possible
    parallel = true;

    # Number of cores to use (null = auto-detect)
    cores = null;

    # Enable caching where applicable
    enableCache = true;
  };
}
