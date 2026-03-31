# packages/toolchains/rust.nix
{ pkgs }:

let
  rust-bin = pkgs.rust-bin or null;
in
{
  packages = with pkgs; [
    (if rust-bin != null then
      rust-bin.stable.latest.default.override
        {
          extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
        }
    else rustc)

    rustup
    sccache
    pkg-config
    openssl.dev
    libiconv
    cargo-edit
    cargo-watch
    cargo-expand
    lldb
    trunk
    protobuf
  ];
}
