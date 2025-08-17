# lib/module-loader.nix
{ pkgs, system }:
{
  # Load all modules at once
  loadModules = {
    installations = {
      common = import ../installations/default.nix { inherit pkgs system; };
      home = import ../installations/home.nix { inherit pkgs system; };
      dev = import ../installations/devenv.nix { inherit pkgs system; };
    };
    executions = {
      common = import ../executions/default.nix { inherit pkgs system; };
      home = import ../executions/home.nix { inherit pkgs system; };
      dev = import ../executions/devenv.nix { inherit pkgs system; };
    };
    configurations = {
      common = import ../configurations/default.nix { inherit pkgs system; };
      home = import ../configurations/home.nix { inherit pkgs system; };
      dev = import ../configurations/devenv.nix { inherit pkgs system; };
    };
  };
}
