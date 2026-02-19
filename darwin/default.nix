# darwin/default.nix
# nix-darwin configuration for macOS
{ config, pkgs, lib, systemUsername, username, email, ... }:

{
  # Disable nix-darwin's Nix management (using Determinate Nix)
  nix.enable = false;

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
      cleanup = "uninstall"; # "zap" requires Full Disk Access
    };

    # Homebrew taps
    taps = [
    ];

    # CLI packages (brew install)
    brews = [
    ];

    # GUI applications (brew install --cask)
    casks = [
      "zed" # Zed editor
      "cursor" # Cursor AI editor
      # Claude Code: native installer로 설치 (자동 업데이트 지원)
    ];

    # Mac App Store apps (requires mas CLI)
    masApps = {
      # "App Name" = App_ID;
    };
  };

  # Nix trusted-users (Determinate Nix uses nix.custom.conf)
  system.activationScripts.postActivation.text = ''
    CONF="/etc/nix/nix.custom.conf"
    if ! grep -q "trusted-users" "$CONF" 2>/dev/null; then
      echo "trusted-users = root ${systemUsername}" >> "$CONF"
      launchctl kickstart -k system/systems.determinate.nix-daemon 2>/dev/null || true
    fi
  '';

  # Enable zsh (default shell on macOS)
  programs.zsh.enable = true;

  # Security settings
  security.pam.services.sudo_local.touchIdAuth = true;
}
