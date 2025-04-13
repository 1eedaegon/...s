{ pkgs, mkEnv }:

mkEnv {
  name = "go";
  pkgList = with pkgs; [
    go
    gopls
    gotools
    go-outline
    gopkgs
    godef
    golint
  ];
  shell = ''
    echo "Go Development Environment"
    export GOPATH="$HOME/go"
    export PATH="$GOPATH/bin:$PATH"
    mkdir -p $GOPATH
    go version
  '';
}