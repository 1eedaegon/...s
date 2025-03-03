{ pkgs, system }: args:

let
  
  channel = args.channel or "stable";
  version = args.version or "latest";
  
  rustPkg = 
    if version == "latest" then
      pkgs.rust-bin.${channel}.latest.default.override {
        extensions = [ "rust-src" "rust-analyzer" ];
      }
    else
      # 특정 버전 사용 (해당 버전이 있는 경우)
      (if builtins.hasAttr version pkgs.rust-bin.${channel} then
        pkgs.rust-bin.${channel}.${version}.default.override {
          extensions = [ "rust-src" "rust-analyzer" ];
        }
      else 
        pkgs.rust-bin.${channel}.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" ];
        }
      );
  
  # 기본 Rust 패키지
  basePackages = [
    rustPkg
  ];
  
  commonTools = with pkgs; [
    cargo-edit
    cargo-watch
    cargo-expand
    cargo-audit
    cargo-flamegraph
  ];
  
  
  systemTools = with pkgs; [
    # pkg-config
    # openssl.dev
    # gcc
    # gdb
  ];
  
in {
  packages = basePackages ++ commonTools ++ systemTools;
  
  shellHook = ''
    echo "Rust Enabled!"
    echo "Rust $(rustc --version)"
    echo "Cargo $(cargo --version)"
    export RUST_BACKTRACE=1
  '';
}