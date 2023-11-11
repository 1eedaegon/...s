{
  description = "On-boarding NixOS";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
     let
       overlays = [ ];
       pkgs = import nixpkgs {
         inherit system overlays;
       };
       nativeBuildInputs = with pkgs; [ ];
       goDev = with pkgs; [ 
         go
         gopls
         gotools
         go-tools
       ];
     in
     with pkgs; 
     {
      packages.system.goDev = buildInputs {
        paths = goDev
      };
       devShells.default = mkShell {
         inherit goDev nativeBuildInputs;
       };
       devShells.mini = mkShell {
         inherit goDev;
       };
       devShells.mini2 = mkShell {
         inherit goDev;
       };
     }
    );
}
