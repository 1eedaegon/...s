{ pkgs, mkEnv, environments }:

mkEnv {
  name = "fullstack";
  pkgList = with pkgs; [
    nodejs
    yarn
    postgresql
  ];
  shell = ''
    echo "풀스택 개발 환경 (Node stakc)"
  '';
  combine = [
    environments.py
    environments.go
    environments.rust
  ];
}