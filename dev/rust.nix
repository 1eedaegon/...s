{ pkgs, mkEnv, rust-bin }:

mkEnv {
  name = "rust";
  pkgList = with pkgs; [
    (rust-bin.stable.latest.default.override {
      extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
    })
    pkg-config
    openssl.dev
    libiconv
    cargo-edit
    cargo-watch
    cargo-expand
    lldb
  ];
  shell = ''
    echo "Rust Development Environment"
    export RUST_BACKTRACE=1
    export RUST_LOG=debug
    export CARGO_HOME="$HOME/.cargo"
    mkdir -p $CARGO_HOME
    alias cb='cargo build'
    alias ct='cargo test'
    alias cr='cargo run'
    rustc --version
  '';
}