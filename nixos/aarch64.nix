{ config, pkgs, lib, ... }:

{

  # ARM64
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  boot.kernelPackages = pkgs.linuxPackages_latest;
  environment.systemPackages = with pkgs; [
    # ARM supported
    htop
    btop
  ];

  # Steam needs x86_64 emulation
  # programs.steam.enable = false;

  # power manager
  powerManagement.enable = true;
  powerManagement.powertop.enable = true;
}
