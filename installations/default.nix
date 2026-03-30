# installations/default.nix
# Compatibility shim — delegates to packages/common.nix + packages/platform/
{ pkgs, system }:

let
  common = import ../packages/common.nix { inherit pkgs; };
  platformFile = ../packages/platform/${system}.nix;
  platform =
    if builtins.pathExists platformFile
    then import platformFile { inherit pkgs; }
    else { packages = [ ]; };
in
{
  packages = common.packages ++ platform.packages;
  programs = common.programs;
}
