{
  description = "On-boarding NixOS";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
     let
       pkgs = import nixpkgs {
         inherit system overlays;
       };
      # Utils function을 바로 불러오는 것은 안되고 derivation을 만드는 것이 편함.
      # TODO: 대다수 공식문서가 home-manager를 이야기하니 home-manager를 보자
      # utils = import ./utils.nix;
      default = with pkgs; [
        nix
        git
        curl
        wget
        bat
        gitmoji
        asciinema
        neovim

      ];

      goDev = with pkgs; [ 
        go
        gopls
        gotools
        go-tools
      ];
     in
     with pkgs; 
     {
      /**
      Provide attribute set
      */
      packages.default = mkShell {
         inherit default goDev;
       };
      packages.mini = mkShell {
        inherit default;
      };
     };
    );
}
