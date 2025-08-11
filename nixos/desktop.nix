# For desktop environment
{ config, pkgs, lib, hostname, ... }:

{
  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Network
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  # Time zone
  time.timeZone = "Asia/Seoul";

  # Internationalization
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ko_KR.UTF-8";
    LC_IDENTIFICATION = "ko_KR.UTF-8";
    LC_MEASUREMENT = "ko_KR.UTF-8";
    LC_MONETARY = "ko_KR.UTF-8";
    LC_NAME = "ko_KR.UTF-8";
    LC_NUMERIC = "ko_KR.UTF-8";
    LC_PAPER = "ko_KR.UTF-8";
    LC_TELEPHONE = "ko_KR.UTF-8";
    LC_TIME = "ko_KR.UTF-8";
  };

  # Enable the X11 windowing system
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.variant = "";
  };

  # Desktop Environment - GNOME
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Exclude some GNOME applications
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gnome-music
    gnome-connections
    simple-scan
    epiphany # web browser
    geary # email reader
    evince # document viewer
  ]) ++ (with pkgs.gnome; [
    cheese # webcam tool
    gnome-terminal
    gnome-calendar
    gnome-contacts
    gnome-maps
    gnome-weather
  ]);

  # Audio
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Printing
  services.printing.enable = true;

  # Hardware acceleration
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Steam (gaming)
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    # Web browsers
    firefox
    chromium

    # Editors
    vim
    neovim
    vscode

    # Communication
    discord
    slack

    # Media
    vlc
    gimp
    obs-studio

    # Development tools
    git
    wget
    curl
    tree
    htop
    btop
    unzip
    zip

    # Terminal emulator
    alacritty

    # File manager
    nautilus

    # System monitoring
    gnome.gnome-system-monitor

    # Screenshot tool
    gnome.gnome-screenshot
    flameshot
  ];

  # Enable touchpad support
  services.xserver.libinput.enable = true;

  # Enable CUPS to print documents
  services.printing.enable = true;

  # Services
  services.openssh.enable = true;
  services.flatpak.enable = true;

  # Virtualization
  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Security
  security.sudo.wheelNeedsPassword = false;

  # Auto upgrade
  system.autoUpgrade = {
    enable = true;
    channel = "https://nixos.org/channels/nixos-unstable";
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
}
