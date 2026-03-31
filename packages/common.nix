# packages/common.nix
# Cross-platform packages included in ALL environments
{ pkgs }:

{
  packages = with pkgs; [
    # pkg config
    pkg-config
    openssl.dev

    # Encoding
    libxml2
    libxslt
    libiconv
    libffi

    # Version Control
    git
    gh

    # Nix tools
    cachix

    # Terminal improvements
    lsd
    bat
    ripgrep
    fzf
    zoxide
    starship
    fastfetch

    # Essential tools
    curl
    wget
    htop
    jq
    yq

    # Build tools
    gnumake

    # Development tools
    nodejs_24
    jdk
    just
    act
    asciinema
    protobuf

    # Fonts
    nerd-fonts.symbols-only
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    nerd-fonts.hack
    nerd-fonts.roboto-mono

    # Editor
    neovim

    # Doom Emacs system dependencies
    fd
    sqlite
    graphviz
    shellcheck
    editorconfig-core-c
    nixfmt

    # Debuggers
    lldb

    # System utilities
    fontconfig

    # Dynamic dev toolset
    mise
    devcontainer

    # VPN
    tailscale

    # Common C Modules
    ccache
    gnumake
    cmake
    extra-cmake-modules

    # Zip and Compression
    p7zip
    zlib
    zlib.dev
    zstd

    # Cloud CLI
    awscli2
    google-cloud-sdk
    azure-cli

    # Cloudflare
    cloudflared
    wrangler
    flarectl

    # Infrastructure as Code
    opentofu
    cf-terraforming

    # Python package manager
    uv

    # Python (lightweight — ML packages are in toolchains/py.nix)
    (python313.withPackages (ps: with ps; [
      huggingface-hub
    ]))

    # Docker CLI
    docker
    docker-compose

    # Kubernetes CLI
    kubectl
    kubernetes-helm
    k9s
    kubectx
    stern
    kustomize

    # Verify systems
    tlaplus
    tlaps

    # Prover
    z3
    spass

    # Proof assistant
    isabelle

    # SMT Solver
    cvc5
    veriT
    yices

    # TLAPM compatibility wrappers
    (pkgs.writeShellScriptBin "isabelle-process" ''
      exec ${pkgs.isabelle}/bin/isabelle process "$@"
    '')
    (pkgs.writeShellScriptBin "cvc4" ''
      exec ${pkgs.cvc5}/bin/cvc5 "$@"
    '')
  ];

  programs = {
    git.enable = true;
    starship.enable = true;
    zsh.enable = true;
    bash.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    bat.enable = true;
    fzf.enable = true;
    zoxide.enable = true;
  };
}
