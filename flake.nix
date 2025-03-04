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

        # Import CLI Binary derivation 
        # myCliBinary = import ./cli-derivation.nix { inherit pkgs system; };
        # hasBinary = myCliBinary ? package && myCliBinary.package != null;

        # Common pakcages
        commonPackages = with pkgs; [
          oh-my-zsh
          # emacs
        ] ++ (if stdenv.isWindows then [ pkgs.chocolatey ] else []);

        # Warning hook for binary on not supported cpu platform
        binaryWarningHook = if hasBinary then "" else ''
          echo "WARNING: CLI binary not available for platform ${system}, skipping..."
        '';

        # Develop
        devEnv = import ./mode_dev {
          inherit pkgs system commonPackages;
          cliBinary = if hasBinary then myCliBinary.package else null;
          hasBinary = hasBinary;
          binaryWarningHook = binaryWarningHook;
        };

        # Ops
        opsEnv = import ./mode_ops {
          inherit pkgs system commonPackages;
          cliBinary = if hasBinary then myCliBinary.package else null;
          hasBinary = hasBinary;
          binaryWarningHook = binaryWarningHook;
        };

      in {
        # Shell for each modes
        devShells = {
          mode_dev = devEnv.default;
          mode_ops = opsEnv.default;
          default = devEnv.default;

          mode_dev_node = devEnv.node;
          mode_dev_py = devEnv.py;
          mode_dev_ml = devEnv.ml;
          mode_dev_rust = devEnv.rust;
          mode_dev_go = devEnv.go;

          mode_ops_cloud = opsEnv.cloud;
          mode_ops_k8s = opsEnv.k8s;
        };
      }
    );
}