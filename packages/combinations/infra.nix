# packages/combinations/infra.nix
# Go + Node.js (infrastructure tooling)
{ pkgs }:

let
  go = import ../toolchains/go.nix { inherit pkgs; };
  node = import ../toolchains/node.nix { inherit pkgs; };
in
{
  packages = go.packages ++ node.packages;
}
