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
        # Note: starship, zoxide, and fzf initialization are handled by home-manager's automatic integration
        # for bash and zsh (via enableBashIntegration/enableZshIntegration/enableFzfIntegration)
        # This script is mainly for additional display and custom settings

        # Display system info (skip in nix develop to avoid library conflicts)
        # Lean module set: de/wm/wmtheme/poweradapter add ~150ms of macOS API calls
        # for no useful output. The packages count comes from our own cache below:
        # fastfetch's built-in cache validates by running `nix-store --query --hash`
        # per profile (~550ms even on a hit), whereas comparing profile symlink
        # targets via readlink detects generation changes in ~1ms. Only the first
        # shell after a system switch pays the full recount.
        if [ -z "$IN_NIX_SHELL" ] && command -v fastfetch >/dev/null 2>&1; then
          __ff_cache="''${XDG_CACHE_HOME:-$HOME/.cache}/fastfetch-packages-line"
          __ff_key="$(readlink -f /run/current-system 2>/dev/null):$(readlink -f /nix/var/nix/profiles/default 2>/dev/null):$(readlink -f "$HOME/.nix-profile" 2>/dev/null):$(ls /usr/local/Caskroom 2>/dev/null | wc -l | tr -d ' ')"
          if [ -f "$__ff_cache" ] && [ "$(head -n 1 "$__ff_cache" 2>/dev/null)" = "$__ff_key" ]; then
            __ff_pkgs="$(tail -n +2 "$__ff_cache")"
          else
            __ff_pkgs="$(fastfetch --logo none --pipe --structure packages | sed 's/^Packages: //')"
            mkdir -p "$(dirname "$__ff_cache")"
            printf '%s\n%s\n' "$__ff_key" "$__ff_pkgs" > "$__ff_cache"
          fi
          fastfetch --config - <<FFEOF
    {
      "logo": { "color": { "1": "magenta", "2": "cyan" } },
      "modules": [
        "title", "separator", "os", "host", "kernel", "uptime",
        { "type": "custom", "key": "Packages", "format": "$__ff_pkgs" },
        "shell", "display", "terminal", "cpu", "gpu", "memory", "swap", "disk", "localip", "battery", "locale", "break", "colors"
      ]
    }
    FFEOF
          unset __ff_cache __ff_key __ff_pkgs
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
    # Note: Do NOT source hm-session-vars.sh in nix develop
    # It can cause library conflicts between Nix and system binaries
    # The devShell already provides all necessary environment setup
    :
  '';
}
