{
  description = "...s(Three dots) repository is a dotenv that provides instant dev and ops environments using Nix Flakes.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system;
          inherit overlays;
        };

        # CLI Binary derivation 가져오기
        # myCliBinary = import ./cli-derivation.nix { inherit pkgs system; };
        # hasBinary = myCliBinary ? package && myCliBinary.package != null;

        # 공통 패키지 (모든 환경에서 사용)
        commonPackages = with pkgs; [
          oh-my-zsh
          # emacs
        ] ++ (if stdenv.isWindows then [ pkgs.chocolatey ] else []);

        # 바이너리 경고 메시지
        binaryWarningHook = if hasBinary then "" else ''
          echo "WARNING: CLI binary not available for platform ${system}, skipping..."
        '';

        # 개발 환경 구성
        devEnv = import ./mode_dev {
          inherit pkgs system commonPackages;
          cliBinary = if hasBinary then myCliBinary.package else null;
          hasBinary = hasBinary;
          binaryWarningHook = binaryWarningHook;
        };

        # 운영 환경 구성
        opsEnv = import ./mode_ops {
          inherit pkgs system commonPackages;
          cliBinary = if hasBinary then myCliBinary.package else null;
          hasBinary = hasBinary;
          binaryWarningHook = binaryWarningHook;
        };

      in {
        # 개발 셸 정의
        devShells = {
          # 기본 환경
          mode_dev = devEnv.default;
          mode_ops = opsEnv.default;
          default = devEnv.default;

          # 특화 개발 환경
          mode_dev_node = devEnv.node;
          mode_dev_py = devEnv.py;
          mode_dev_ml = devEnv.ml;
          mode_dev_rust = devEnv.rust;
          mode_dev_go = devEnv.go;

          # 특화 운영 환경
          mode_ops_cloud = opsEnv.cloud;
          mode_ops_k8s = opsEnv.k8s;
        };
      }
    );
}