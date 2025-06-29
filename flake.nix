# flake.nix
{
  description = "...s(3dots) with nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };

        crossTarget = "x86_64-unknown-linux-gnu";
        pkgs_x86_64 = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        commonShellHooks = import ./lib/common-shell-hook.nix { inherit pkgs system; };

        # Default environment definition
        defaultEnv = {
          name = "default";
          pkgList = with pkgs; [
            nerd-fonts.symbols-only
            nerd-fonts.fira-code
            starship
            bat
            git
            gh
            htop
            curl
            asciinema
            fontconfig
            direnv
            gcc
            gnumake
            htop
            just
            act
          #  knope: not yet
          ] ++ (if system == "x86_64-darwin" || system == "aarch64-darwin" then [
            # macOS-only packages
            coreutils
            asitop
            # (import ./lib/iterm2-settings.nix { inherit pkgs system; })
          ] else if system == "x86_64-linux" then [
            # Linux-only packages
            systemd
          ] else []);
          shell = commonShellHooks;
        };

        mkEnv =
          { name, pkgList ? [], shell ? "", combine ? [] }:
          let
            # Combine Pkgs
            combinedPkgList = if combine != []
              then pkgList ++ builtins.concatMap (env: env.pkgList) combine
              else pkgList;

            # Combine Shell
            combinedShell = if combine != []
              then shell + builtins.concatStringsSep "\n" (builtins.map (env: env.shell) combine)
              else shell;
          in {
            inherit name;
            pkgList = combinedPkgList;
            shell = combinedShell;

            # Generate buildEnv and mkShell
            toOutputs = baseEnv: {
              packages = {
                "${name}" = pkgs.buildEnv {
                  name = "${name}";
                  paths = combinedPkgList;
                };
              };
              devShells = {
                "${name}" = pkgs.mkShell {
                  name = "${name}";
                  buildInputs = combinedPkgList ++ baseEnv.pkgList;
                  shellHook = baseEnv.shell + combinedShell;
                };
              };
            };
          };

        environments = {
          default = defaultEnv // {
            toOutputs = _: {
              packages = {
                "default" = pkgs.buildEnv {
                  name = "default";
                  paths = defaultEnv.pkgList;
                };
              };
              devShells = {
                "default" = pkgs.mkShell {
                  name = "default";
                  buildInputs = defaultEnv.pkgList;
                  shellHook = defaultEnv.shell;
                };
              };
            };
          };

          # Rust
          rust = mkEnv {
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
              protobuf
            ];
            shell = ''
              echo "Enabled[Rust]: $(rustc --version)"
              export RUST_BACKTRACE=1
              export RUST_LOG=debug
              export CARGO_HOME="$HOME/.cargo"
              mkdir -p $CARGO_HOME
              alias cb='cargo build'
              alias ct='cargo test'
              alias cr='cargo run'
            '';
          };

          rust-cross-x86 = mkEnv {
            name = "rust-cross-x86";
            pkgList = with pkgs; [
              (rust-bin.stable.latest.default.override {
                targets = [ crossTarget ];
                extensions = [ "rust-src" "clippy" "rustfmt" ];
              })
              pkgsCross.gnu64.binutils-unwrapped
              pkgsCross.gnu64.gcc
              pkgsCross.gnu64.stdenv.cc.libc.dev
              pkgsCross.gnu64.openssl.dev
              pkgs_x86_64.stdenv.cc.libc.dev
              #pkgs_x86_64.openssl.dev
              pkg-config

            ];
            shell = ''
              echo "Enabled[Rust x86-64 Compile]: ${crossTarget}"

              # Compiler
              export CC_x86_64_unknown_linux_gnu="${crossTarget}-gcc"
              export AR_x86_64_unknown_linux_gnu="${crossTarget}-ar"

              # Linker
              export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="${crossTarget}-gcc"

              # Header
              export NIX_CFLAGS_COMPILE="-isystem ${pkgs_x86_64.stdenv.cc.libc.dev}/include"

              # pkg-config
              export PKG_CONFIG_PATH="${pkgs_x86_64.openssl.dev}/lib/pkgconfig"
              export OPENSSL_DIR="${pkgs_x86_64.openssl.dev}"
            '';
          };

          # Go
          go = mkEnv {
            name = "go";
            pkgList = with pkgs; [
              go
              gopls
              gotools
              go-outline
              gopkgs
              godef
              golint
              golangci-lint
              gotestsum
              protobuf
              protoc-gen-go
              protoc-gen-go-grpc
              kind
            ];
            shell = ''
              echo "Enabled[Golang]: $(go version)"
              export GOPATH="$HOME/go"
              export PATH="$GOPATH/bin:$PATH"
              mkdir -p $GOPATH
            '';
          };

          # Python
          # TODO: UV가 대신해줄 수 있을것같다.
          py = mkEnv {
            name = "py";
            pkgList = with pkgs; [
              uv
            ];
            shell = ''
              echo "Enabled[Python(uv)]: $(uv --version)"
              export PYTHONPATH="$PWD:$PYTHONPATH"
            '';
          };


          dev = mkEnv {
            name = "dev";
            shell = ''
              echo "###############"
              echo "# DEV Enabled #"
              echo "###############"
              echo "               "
            '';
            combine = [
              environments.py
              environments.go
              environments.rust
            ];
          };
        };

        # Generate outputs for all environments
        allOutputs = builtins.mapAttrs
          (name: env: env.toOutputs defaultEnv)
          environments;

        # packages and devShells merge
        mergeOutputsBy = attr:
          builtins.foldl'
            (acc: outputs: acc // outputs.${attr})
            {}
            (builtins.attrValues allOutputs);

      in {
        packages = mergeOutputsBy "packages";
        devShells = mergeOutputsBy "devShells";
      }
    );
}
