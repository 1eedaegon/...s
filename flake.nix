{
  description = "On-boarding NixOS";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.gomod2nix.url = "github:nix-community/gomod2nix";

  outputs = { self, nixpkgs, flake-utils, gomod2nix }:
    flake-utils.lib.eachDefaultSystem (system:
     let
       overlays = [ gomod2nix.overlays.default ];
       pkgs = import nixpkgs {
         inherit system overlays;
       };
       nativeBuildInputs = with pkgs; [ ];
       buildInputs = with pkgs; [ 
         go
         gopls
         gotools
         go-tools
         gomod2nix.packages.${system}.default
       ];
     in
     with pkgs;
     {
       devShells.default = mkShell {
         inherit buildInputs nativeBuildInputs;
       };
       devShells.mini = mkShell {
         inherit buildInputs;
       };
     }
    );
}
