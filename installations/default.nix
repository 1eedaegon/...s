# installations/default.nix
# 모든 환경에서 공통으로 사용되는 패키지 목록
{ pkgs, system }:

let
  # Jetson 디바이스 감지 (환경 변수 또는 시스템 설정으로 제어)
  isJetson = builtins.getEnv "IS_JETSON" == "1" || builtins.pathExists "/etc/nv_tegra_release";

  # CUDA 패키지 선택
  cudaPackages =
    if isJetson then [
      # Jetson용 JetPack (anduril/jetpack-nixos overlay 사용)
      # 환경 변수 설정: export IS_JETSON=1
      pkgs.cudaPackages.cudatoolkit # JetPack CUDA toolkit
      pkgs.cudaPackages.tensorrt # TensorRT for Jetson
    ] else [
      # 일반 CUDA toolkit (x86_64 GPU)
      pkgs.cudaPackages.cuda_nvcc
      pkgs.cudaPackages.cuda_cudart
      pkgs.cudaPackages.cudatoolkit
      pkgs.nvtopPackages.nvidia
    ];
in

{
  # 공통 패키지 목록
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

    # Terminal improvements
    lsd # better ls
    bat # better cat
    ripgrep # better grep
    fzf # fuzzy finder
    zoxide # better cd
    starship # prompt
    fastfetch # system info

    # Essential tools
    curl
    wget
    htop
    jq # JSON processor
    yq # YAML processor

    # Build tools
    gnumake

    # Development tools
    nodejs_24 # full stack web
    jdk # OpenJDK
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
    # Note: Don't add standalone gcc on macOS - use stdenv.cc instead
    # gcc breaks SDK sysroot detection for cargo/cc-rs builds
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

    # Python package manager 
    uv

    # ML tools 
    (python313.withPackages (ps: with ps; [
      marimo # Reactive Python notebook
      wandb # Weights & Biases ML tracking
      huggingface-hub # HuggingFace CLI & Hub
    ]))

    # Docker CLI
    docker
    docker-compose

    # Verify systems
    tlaplus
    tlaps

    # Prover
    z3
    spass

    # Proof assistant
    isabelle

    # Based SMT Solver
    cvc5
    veriT
    yices

    # TLAPM compatibility wrappers (isabelle-process, cvc4)
    (pkgs.writeShellScriptBin "isabelle-process" ''
      exec ${pkgs.isabelle}/bin/isabelle process "$@"
    '')
    (pkgs.writeShellScriptBin "cvc4" ''
      exec ${pkgs.cvc5}/bin/cvc5 "$@"
    '')

  ] ++ (if system == "x86_64-darwin" then [
    # x86_64-darwin specific packages
    coreutils
    macpm
    gdb
    pkgs.nvtopPackages.full
    # devenv: x86_64-darwin에서 nix-util 빌드 실패, 별도 설치 필요: nix profile install nixpkgs#devenv
    # Zed, Claude Code: nix-darwin의 homebrew 모듈로 관리
  ] else if system == "aarch64-darwin" then [
    # aarch64-darwin (Apple Silicon) specific packages
    coreutils
    macpm
    gdb
    pkgs.nvtopPackages.full
    devenv
    # Zed, Claude Code: use nix-darwin
  ] else if system == "x86_64-linux" then [
    # x86_64-linux specific packages
    systemd
    net-tools
    nmap
    libgcc
    valgrind
    zed-editor
    code-cursor # Cursor AI editor
  ] else if system == "aarch64-linux" then [
    # aarch64-linux specific packages
    systemd
    net-tools
    nmap
    libgcc
    valgrind
    devenv
    zed-editor
    code-cursor
  ] else [ ]);

  # 공통 프로그램 설정 (programs.*.enable)
  programs = {
    # Enable these programs with default settings
    # tailscale.enable = true; # is not exist :[
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
