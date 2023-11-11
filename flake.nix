{
  description = "On-boarding NixOS";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.utils.url = "./utils.nix";
  inputs.envs.url = "./envs.nix";

  outputs = { self, nixpkgs, flake-utils, utils }:
    flake-utils.lib.eachDefaultSystem (system:
     let
       pkgs = import nixpkgs {
         inherit system;
       };
       envs = import ./envs.nix;
     in
     {
      utils.envToPackages { flakePkgs=pkgs; envAttrs=envs; }
     }
    );
}
