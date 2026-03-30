# packages/combinations/research.nix
# Rust + Python (distributed systems research + formal verification)
{ pkgs }:

let
  rust = import ../toolchains/rust.nix { inherit pkgs; };
  py = import ../toolchains/py.nix { inherit pkgs; };
in
{
  packages = rust.packages ++ py.packages;
}
