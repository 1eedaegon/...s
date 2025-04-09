{ config, pkgs, ... }:
{
  fonts.fontconfig.enable = true;  # 폰트 설정 활성화
  home.packages = with pkgs; [
    nerd-fonts.symbols-only
    nerd-fonts.fira-code
  ];
}