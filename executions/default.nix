# executions/default.nix
# Common shell commands, aliases, and hooks for all environments
{ pkgs, system }:

{
  # Common aliases for all environments
  aliases = {
    # Enhanced ls commands
    ls = "lsd";
    l = "lsd -l";
    la = "lsd -a";
    ll = "lsd -la";
    lt = "lsd --tree";

    # Enhanced cat
    cat = "bat";

    # Enhanced cd (using zoxide)
    cd = "z";

    # Nix shortcuts
    nd = "nix develop";
    ndi = "nix develop --impure";
    nds = "nix develop --impure .#";
    np = "nix profile";
    npl = "nix profile list";
    npi = "nix profile install";
    npr = "nix profile remove";
    ncg = "nix-collect-garbage";
    ncgd = "nix-collect-garbage -d";

    # Git shortcuts
    g = "git";
    gs = "git status";
    ga = "git add";
    gaa = "git add --all";
    gc = "git commit";
    gcm = "git commit -m";
    gp = "git push";
    gpl = "git pull";
    gco = "git checkout";
    gcb = "git checkout -b";
    gb = "git branch";
    gl = "git log --oneline --graph";
    gd = "git diff";
    gds = "git diff --staged";

    # Docker shortcuts
    d = "docker";
    dc = "docker-compose";
    dps = "docker ps";
    dpsa = "docker ps -a";
    dimg = "docker images";

    # Kubernetes shortcuts
    k = "kubectl";
    kgp = "kubectl get pods";
    kgs = "kubectl get svc";
    kgd = "kubectl get deployment";
    kaf = "kubectl apply -f";
    kdel = "kubectl delete";
    klog = "kubectl logs";
    kexec = "kubectl exec -it";

    # Common shortcuts
    c = "clear";
    h = "history";
    e = "exit";
    reload = "source ~/.zshrc";

    # Directory navigation
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "....." = "cd ../../../..";
  };

  # Common shell initialization script
  initScript = ''
    # Set up shell prompt and tools
    # Initialize starship prompt if available
    if command -v starship >/dev/null 2>&1; then
      # Detect actual running shell, not $SHELL variable
      if [ -n "$ZSH_VERSION" ]; then
        eval "$(starship init zsh)"
      elif [ -n "$BASH_VERSION" ]; then
        eval "$(starship init bash)"
      fi
    fi

    # Initialize zoxide if available
    if command -v zoxide >/dev/null 2>&1; then
      # Detect actual running shell, not $SHELL variable
      if [ -n "$ZSH_VERSION" ]; then
        eval "$(zoxide init zsh)"
      elif [ -n "$BASH_VERSION" ]; then
        eval "$(zoxide init bash)"
      fi
    fi

    # Initialize fzf if available
    if [ -n "$ZSH_VERSION" ]; then
      if [ -f "${pkgs.fzf}/share/fzf/key-bindings.zsh" ]; then
        source "${pkgs.fzf}/share/fzf/key-bindings.zsh"
      fi
      if [ -f "${pkgs.fzf}/share/fzf/completion.zsh" ]; then
        source "${pkgs.fzf}/share/fzf/completion.zsh"
      fi
    elif [ -n "$BASH_VERSION" ]; then
      if [ -f "${pkgs.fzf}/share/fzf/key-bindings.bash" ]; then
        source "${pkgs.fzf}/share/fzf/key-bindings.bash"
      fi
      if [ -f "${pkgs.fzf}/share/fzf/completion.bash" ]; then
        source "${pkgs.fzf}/share/fzf/completion.bash"
      fi
    fi

    # Display system info
    if command -v fastfetch >/dev/null 2>&1; then
      fastfetch --logo-color-1 magenta --logo-color-2 cyan
    fi

    # Display font test
    echo -e "font check(branch): \uf126 \ue0a0 \uf121"
  '';

  # Common functions
  functions = ''
    # Create directory and cd into it
    mkcd() {
      mkdir -p "$1" && cd "$1"
    }

    # Git add, commit, and push in one command
    gacp() {
      git add .
      git commit -m "$1"
      git push
    }

    # Find process by name
    findproc() {
      ps aux | grep -v grep | grep -i "$1"
    }

    # Kill process by name
    killproc() {
      kill $(ps aux | grep -v grep | grep -i "$1" | awk '{print $2}')
    }

    # Extract various archive formats
    extract() {
      if [ -f "$1" ]; then
        case "$1" in
          *.tar.bz2)   tar xjf "$1"     ;;
          *.tar.gz)    tar xzf "$1"     ;;
          *.bz2)       bunzip2 "$1"     ;;
          *.rar)       unrar e "$1"     ;;
          *.gz)        gunzip "$1"      ;;
          *.tar)       tar xf "$1"      ;;
          *.tbz2)      tar xjf "$1"     ;;
          *.tgz)       tar xzf "$1"     ;;
          *.zip)       unzip "$1"       ;;
          *.Z)         uncompress "$1"  ;;
          *.7z)        7z x "$1"        ;;
          *)           echo "'$1' cannot be extracted" ;;
        esac
      else
        echo "'$1' is not a valid file"
      fi
    }

    # Quick backup of a file
    backup() {
      cp "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
    }

    # Show directory tree with hidden files
    tree() {
      lsd --tree --all "$@"
    }
  '';

  # Shell hook for preserving environment
  preserveEnvHook = ''
    # Preserve home-manager environment when entering devshell
    if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
      source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    fi

    # Preserve existing PATH
    export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:$PATH"
  '';
}
