# dev/go.nix
{ pkgs, system }:
let
  langModuleTemplate = import ../lib/language-template.nix { inherit pkgs system; };
in
langModuleTemplate {
  name = "go";
  commonPkgs = with pkgs; [];
  commonConfig = {
    shellHook = '''';
  };
  versions = {
    "latest" = {
      pkg = pkgs.go;  # Go 패키지만 지정
      includePkgs = with pkgs; [ golangci-lint delve ];  # 추가 패키지
      excludePkgs = [];
      shellHook = ''
        echo "Go latest development environment"
      '';
    };
  };
}