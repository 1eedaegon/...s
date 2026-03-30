# nixos/jetson.nix
# NVIDIA Jetson (Orin, Thor) — GPU acceleration + ML inference
# Uses jetpack-nixos overlay for CUDA/TensorRT
{ config, pkgs, lib, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # Boot — Jetson uses UEFI (NVIDIA's L4T bootloader)
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Jetson-specific kernel modules
  boot.initrd.availableKernelModules = [
    "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "nvme"
  ];
  boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" ];

  # Filesystem
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # CUDA / GPU — enabled via jetpack overlay (set in flake.nix)
  # IS_JETSON=1 environment variable activates jetpack CUDA packages
  nixpkgs.config.cudaSupport = true;

  # Network
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 8080 ];
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };

  # No desktop GUI by default (headless ML inference)
  services.xserver.enable = false;

  # System packages — ML inference + monitoring
  environment.systemPackages = with pkgs; [
    htop
    btop
    nvtopPackages.nvidia    # GPU monitoring
    usbutils
    pciutils
    lm_sensors
    iotop
  ];

  # Docker — for ML container workflows
  virtualisation.docker = {
    enable = true;
    enableNvidia = true;    # nvidia-container-toolkit
  };

  # Power management — Jetson power modes
  powerManagement.enable = true;

  # GC — moderate, keep some generations for rollback
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.settings.auto-optimise-store = true;
}
