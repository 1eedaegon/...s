# packages/combinations/ml.nix
# Python + Rust (ML inference + native extensions)
{ pkgs }:

let
  py = import ../toolchains/py.nix { inherit pkgs; };
  rust = import ../toolchains/rust.nix { inherit pkgs; };
in
{
  packages = py.packages ++ rust.packages;
}
