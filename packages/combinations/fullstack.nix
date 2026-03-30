# packages/combinations/fullstack.nix
# Rust + Node.js + Python
{ pkgs }:

let
  rust = import ../toolchains/rust.nix { inherit pkgs; };
  node = import ../toolchains/node.nix { inherit pkgs; };
  py = import ../toolchains/py.nix { inherit pkgs; };
in
{
  packages = rust.packages ++ node.packages ++ py.packages;
}
