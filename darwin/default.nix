# darwin/default.nix
# nix-darwin configuration for macOS
{ config, pkgs, lib, systemUsername, username, email, ... }:

{
  # Nix configuration
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  # System configuration
  system.stateVersion = 5;
  system.primaryUser = systemUsername;

  # Homebrew configuration (managed by nix-homebrew)
  homebrew = {
    enable = true;

    # Homebrew update/upgrade behavior
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap"; # Remove unlisted packages
    };

    # Homebrew taps
    taps = [
      "homebrew/bundle"
    ];

    # CLI packages (brew install)
    brews = [
    ];

    # GUI applications (brew install --cask)
    casks = [
      "zed" # Zed editor
      # Claude Code: native installer로 설치 (자동 업데이트 지원)
    ];

    # Mac App Store apps (requires mas CLI)
    masApps = {
      # "App Name" = App_ID;
    };
  };

  # Enable zsh (default shell on macOS)
  programs.zsh.enable = true;

  # Security settings
  security.pam.services.sudo_local.touchIdAuth = true;
}
