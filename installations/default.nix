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
    ];
in

{
  # 공통 패키지 목록
  packages = with pkgs; [
    # pkg config
    pkg-config

    # Encoding
    libiconv

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
    gcc
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
    devenv
    devcontainer

    # VPN
    tailscale

    # Common C Modules
    gcc
    libgcc
    gnumake
    cmake
    extra-cmake-modules


    # Zip
    p7zip

    # KVM Switch
    # barrier
  ] ++ (if system == "x86_64-darwin" || system == "aarch64-darwin" then [
    # macOS-specific packages
    coreutils
    asitop
    gdb
  ] else if system == "x86_64-linux" || system == "aarch64-linux" then [
    # Linux-specific packages
    systemd
    net-tools
    nmap
  ] ++ cudaPackages  # CUDA 패키지 추가 (Jetson or 일반 CUDA)
  else [ ]);

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
