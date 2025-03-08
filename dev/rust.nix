# dev/rust.nix
{ pkgs, system }:

let
  langModuleTemplate = import ../lib/language-template.nix { inherit pkgs system; };
in
langModuleTemplate {
  name = "rust";
  commonPkgs = with pkgs; [
    pkg-config
    openssl.dev
    libiconv
    cargo-edit
    cargo-watch
    cargo-expand
    gdb
    lldb
  ];
  commonConfig = {
    shellHook = ''
      # Rust develop log
      export RUST_BACKTRACE=1
      export RUST_LOG=debug
      
      # Cargo cache
      export CARGO_HOME="$HOME/.cargo"
      mkdir -p $CARGO_HOME
      
      # Cargo alias
      alias cb='cargo build'
      alias ct='cargo test'
      alias cr='cargo run'
    '';
  };
  versions = {
    "latest" = {
      pkg = pkgs.rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
      };
      includePkgs = with pkgs; [];
      excludePkgs = [];
      shellHook = '''';
    };
    "1.84.0" = {
      pkg = pkgs.rust-bin.stable."1.70.0".default.override {
        extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
      };
      includePkgs = with pkgs; [];
      excludePkgs = [];
      shellHook = '''';
    };
  };
}