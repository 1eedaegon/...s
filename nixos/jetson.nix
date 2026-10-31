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
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "nvme"
  ];
  boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" ];

  # Filesystem
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # CUDA / GPU — enabled via jetpack overlay (set in flake.nix)
  # IS_JETSON=1 environment variable activates jetpack CUDA packages
  #
  # jetpack-nixos' overlay on its own leaves pkgs.cudaPackages at upstream's
  # default of cudaPackages_11 (CUDA 11.4 = JetPack 5), and nixpkgs marks that
  # release badPlatforms on aarch64-linux — its aarch64 CUDA redist is SBSA
  # (server), not Tegra. So the moment cudaSupport actually took effect,
  # `cuda11.4-cuda_nvml_dev` refused to evaluate. Orin and Thor are JetPack 6+,
  # so pin 12.6; this is exactly what jetpack-nixos' README prescribes for an
  # overlay-without-the-module setup. Verified to evaluate on aarch64-linux.
  #
  # The better fix is `hardware.nvidia-jetpack.enable = true`, which picks
  # cudaPackages from majorVersion by itself AND provides the driver (see
  # suppressNvidiaDriverAssertion below — that flag is only needed because
  # nothing here currently provides one). It also takes over the kernel,
  # bootloader and flash/firmware story, which collides with the hand-rolled
  # boot.loader and kernelPackages above, so it wants real hardware to land.
  # lib.mkAfter is load-bearing: jetpack's own overlay is the one setting
  # cudaPackages = cudaPackages_11, and it arrives via lib/mk-nixos.nix. A
  # plain list here landed *before* it and lost silently (still resolved to
  # cuda11.4) — overlays are applied in list order, so this has to be last.
  nixpkgs.overlays = lib.mkAfter [
    (final: _: { cudaPackages = final.cudaPackages_12_6; })
  ];

  # cudaSupport is NOT set here. `nixpkgs.config` is one option, and
  # lib/mk-nixos.nix already defines it for every host from
  # overlaysLib.nixpkgsConfig; a second definition of the same key doesn't
  # merge per-key — mk-nixos.nix's just won, so the `cudaSupport = true` that
  # used to live on this line evaluated to false and this profile silently
  # built without CUDA. It now comes from the profile table in flake.nix,
  # which is the single definition site.

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
    nvtopPackages.nvidia # GPU monitoring
    usbutils
    pciutils
    lm_sensors
    iotop
  ];

  # Docker — for ML container workflows
  virtualisation.docker = {
    enable = true;
    enableNvidia = true; # nvidia-container-toolkit
  };

  # nvidia-container-toolkit asserts that an NVIDIA driver is configured and
  # only recognises two sources: hardware.nvidia.datacenter.enable, or "nvidia"
  # in services.xserver.videoDrivers. On a Jetson neither applies — the driver
  # ships with jetpack-nixos/L4T, and this host is headless (xserver disabled
  # above), so the assertion fires on a box that does have a working GPU. This
  # suppression flag is upstream's documented escape hatch for exactly that
  # case ("the driver is provided by another NixOS module").
  hardware.nvidia-container-toolkit.suppressNvidiaDriverAssertion = true;

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
