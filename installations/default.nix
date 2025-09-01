# installations/default.nix
# 모든 환경에서 공통으로 사용되는 패키지 목록
{ pkgs, system }:

{
  # 공통 패키지 목록
  packages = with pkgs; [
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
    nodejs # full stack web
    just
    act
    asciinema

    # Fonts
    nerd-fonts.symbols-only
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    nerd-fonts.hack
    nerd-fonts.roboto-mono

    # Editor
    neovim

    # System utilities
    fontconfig

    # Dynamic dev toolset
    mise
    devenv
    devcontainer

  ] ++ (if system == "x86_64-darwin" || system == "aarch64-darwin" then [
    # macOS-specific packages
    coreutils
    asitop
  ] else if system == "x86_64-linux" || system == "aarch64-linux" then [
    # Linux-specific packages
    systemd
  ] else [ ]);

  # 공통 프로그램 설정 (programs.*.enable)
  programs = {
    # Enable these programs with default settings
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
