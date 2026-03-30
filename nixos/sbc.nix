# nixos/sbc.nix
# Lightweight ARM Single Board Computers (Odroid, RPi4/5)
# Headless server, minimal footprint
{ config, pkgs, lib, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # Boot — most SBCs use U-Boot or extlinux
  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.consoleLogLevel = 7;

  # Minimal initrd for embedded
  boot.initrd.availableKernelModules = [
    "usbhid" "usb_storage" "sd_mod" "mmc_block"
  ];

  # Filesystem — SD card / eMMC
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Network — headless SSH access
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };

  # No GUI — headless
  services.xserver.enable = false;

  # Power management
  powerManagement.enable = true;
  powerManagement.powertop.enable = true;

  # Swap — SBCs have limited RAM
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 2048; # 2GB
  }];

  # Minimal system packages
  environment.systemPackages = with pkgs; [
    htop
    btop
    lm_sensors
    usbutils
    pciutils
  ];

  # Automatic GC — disk space is precious on SBCs
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };
  nix.settings.auto-optimise-store = true;
}
