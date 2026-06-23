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

    # rustup intentionally omitted: rust-bin above already provides a complete
    # Nix-managed toolchain (rustc/cargo/clippy/rustfmt/rust-analyzer/rust-src),
    # so rustup is redundant and its shims conflict in PATH. It also fails to
    # build at 1.29.0 in nixpkgs (empty ~/.rustup/settings.toml → "missing field
    # version" during shell-completion generation). Pin toolchains via the
    # version shells (#rust1_75_0) instead of rustup.
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
