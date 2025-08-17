# executions/home.nix
# Home-manager specific shell commands, aliases, and initialization
{ config, lib, pkgs, username, system, ... }:

let
  # Import common executions
  common = import ./default.nix { inherit pkgs system; };
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  # Merge common aliases with home-manager specific ones
  aliases = common.aliases // {
    # Home-manager specific aliases
    hm = "home-manager";
    hms = "home-manager switch";
    hmb = "home-manager build";
    hmn = "home-manager news";
    hme = "home-manager edit";
    hmg = "home-manager generations";

    # Editor shortcuts
    v = "nvim";
    vi = "nvim";
    vim = "nvim";

    # Zed editor (if on macOS)
    zhere = if isDarwin then "zed ." else "code .";

    # iTerm restart (macOS only)
    iterm-restart = if isDarwin then
      "osascript -e 'quit app \"iTerm\"' && sleep 2 && open -a iTerm"
    else "";

    # System specific
    update = if isDarwin then
      "darwin-rebuild switch --flake .#$(hostname)"
    else
      "nixos-rebuild switch --flake .#$(hostname)";

    # Quick edits
    ezsh = "nvim ~/.zshrc";
    ebash = "nvim ~/.bashrc";
    envim = "nvim ~/.config/nvim/init.lua";
    ehm = "nvim ~/.config/home-manager/home.nix";

    # System info
    sysinfo = "fastfetch";

    # Trash management (if trash-cli is installed)
    rm = "trash";

    # Better defaults
    cp = "cp -iv";
    mv = "mv -iv";
    mkdir = "mkdir -pv";

    # Network
    myip = "curl -s https://ipinfo.io/ip";
    localip = if isDarwin then
      "ipconfig getifaddr en0"
    else
      "ip -4 addr show | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}'";

    # Process management
    top = "htop";

    # Quick navigation to common directories
    cdh = "cd ~";
    cdd = "cd ~/Downloads";
    cdp = "cd ~/Projects";
    cdc = "cd ~/.config";
    cdn = "cd ~/.config/nixpkgs";
  };

  # Zsh specific configuration
  zshConfig = {
    initExtra = ''
      ${common.initScript}
      ${common.functions}

      # Home-manager specific initialization

      # Set up history
      HISTFILE=~/.zsh_history
      HISTSIZE=10000
      SAVEHIST=10000
      setopt EXTENDED_HISTORY
      setopt HIST_EXPIRE_DUPS_FIRST
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_SPACE
      setopt HIST_VERIFY
      setopt SHARE_HISTORY

      # Better completion
      setopt COMPLETE_IN_WORD
      setopt ALWAYS_TO_END
      setopt PATH_DIRS
      setopt AUTO_MENU
      setopt AUTO_LIST
      setopt AUTO_PARAM_SLASH
      setopt EXTENDED_GLOB
      unsetopt MENU_COMPLETE
      unsetopt FLOW_CONTROL

      # Better directory navigation
      setopt AUTO_CD
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS
      setopt PUSHDMINUS

      # Better job control
      setopt NOTIFY
      setopt LONG_LIST_JOBS
      setopt INTERACTIVE_COMMENTS

      # Vi mode
      bindkey -v
      export KEYTIMEOUT=1

      # Better searching
      bindkey '^R' history-incremental-search-backward
      bindkey '^S' history-incremental-search-forward
      bindkey '^P' history-search-backward
      bindkey '^N' history-search-forward

      # Edit command line in editor
      autoload -z edit-command-line
      zle -N edit-command-line
      bindkey '^X^E' edit-command-line

      # Custom functions for home environment

      # Update all the things
      update-all() {
        echo "Updating Nix channels..."
        nix-channel --update

        echo "Updating home-manager..."
        home-manager switch

        if [[ "$OSTYPE" == "darwin"* ]]; then
          echo "Updating Homebrew..."
          brew update && brew upgrade

          echo "Updating Mac App Store apps..."
          mas upgrade
        fi

        echo "Update complete!"
      }

      # Cleanup system
      cleanup() {
        echo "Cleaning up Nix store..."
        nix-collect-garbage -d

        echo "Optimizing Nix store..."
        nix-store --optimise

        if [[ "$OSTYPE" == "darwin"* ]]; then
          echo "Cleaning up Homebrew..."
          brew cleanup -s
          brew doctor
        fi

        echo "Cleanup complete!"
      }

      # Quick project setup
      project() {
        local name="$1"
        local type="''${2:-default}"

        if [ -z "$name" ]; then
          echo "Usage: project <name> [type]"
          echo "Types: rust, go, python, node, default"
          return 1
        fi

        mkdir -p ~/Projects/"$name"
        cd ~/Projects/"$name"

        # Initialize git
        git init

        # Create flake.nix with specified devshell
        echo "Creating flake.nix with $type environment..."
        echo "use flake .#$type" > .envrc
        direnv allow

        # Initialize based on type
        case "$type" in
          rust)
            cargo init
            ;;
          go)
            go mod init "github.com/$username/$name"
            ;;
          python)
            uv init
            ;;
          node)
            npm init -y
            ;;
        esac

        echo "Project $name created with $type environment!"
      }

      # Show weather
      weather() {
        local location="''${1:-}"
        curl -s "wttr.in/''${location}?format=3"
      }

      # Colorful man pages
      man() {
        LESS_TERMCAP_md=$'\e[01;31m' \
        LESS_TERMCAP_me=$'\e[0m' \
        LESS_TERMCAP_se=$'\e[0m' \
        LESS_TERMCAP_so=$'\e[01;44;33m' \
        LESS_TERMCAP_ue=$'\e[0m' \
        LESS_TERMCAP_us=$'\e[01;32m' \
        command man "$@"
      }

      # Welcome message
      if [ -z "$WELCOME_MSG_SHOWN" ]; then
        export WELCOME_MSG_SHOWN=1
        echo ""
        echo "Welcome back, $USER!"
        echo "Today is $(date '+%A, %B %d, %Y')"
        weather
        echo ""
      fi
    '';
  };

  # Bash specific configuration
  bashConfig = {
    initExtra = ''
      ${common.initScript}
      ${common.functions}

      # Bash specific settings
      shopt -s histappend
      shopt -s checkwinsize
      shopt -s globstar
      shopt -s nocaseglob
      shopt -s cdspell
      shopt -s dirspell

      # History settings
      export HISTCONTROL=ignoreboth:erasedups
      export HISTSIZE=10000
      export HISTFILESIZE=20000

      # Better tab completion
      bind "set completion-ignore-case on"
      bind "set show-all-if-ambiguous on"
      bind "set mark-symlinked-directories on"
    '';
  };

  # Fish specific configuration (if needed)
  fishConfig = {
    interactiveShellInit = ''
      ${common.initScript}

      # Fish specific settings
      set fish_greeting ""

      # Set up direnv
      if type -q direnv
        direnv hook fish | source
      end
    '';
  };
}
