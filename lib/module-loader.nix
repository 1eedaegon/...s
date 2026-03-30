# lib/module-loader.nix
# Loads all modules from packages/, executions/, configurations/
{ pkgs, system }:

let
  platformFile = ../packages/platform/${system}.nix;
  platformPkgs =
    if builtins.pathExists platformFile
    then import platformFile { inherit pkgs; }
    else { packages = [ ]; };
in
{
  loadModules = {
    installations = {
      common = {
        packages = (import ../packages/common.nix { inherit pkgs; }).packages ++ platformPkgs.packages;
        programs = (import ../packages/common.nix { inherit pkgs; }).programs;
      };
      dev = import ../installations/devenv.nix { inherit pkgs system; }; # shim: maps toolchain names for executions/configurations
    };
    executions = {
      common = import ../executions/default.nix { inherit pkgs system; };
      dev = import ../executions/devenv.nix { inherit pkgs system; };
    };
    configurations = {
      common = import ../configurations/default.nix { inherit pkgs system; };
      dev = import ../configurations/devenv.nix { inherit pkgs system; };
    };
  };
}
