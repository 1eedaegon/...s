{ config, pkgs, lib, ... }:

{
  # x86_64
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # hardware acceleration
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  environment.systemPackages = with pkgs; [
    intel-gpu-tools
    vscode
    chromium
  ];

  # x86_64 virtualisation
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  programs.steam.enable = true;  # 게임은 주로 x86_64에서
}
