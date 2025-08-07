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

        # User configuration
        userConfiguration = {
          "1eedaegon" = {
            homeDirectory = "/home/1eedaegon";
            email = "d8726243@gmail.com";
            module = ./home/home.nix;
          };
        };

        # Default environment definition
        commonPackages = import ./packages/packages.nix { inherit pkgs system; };
        commonShellHooks = import ./lib/common-shell-hook.nix { inherit pkgs system; };

        mkEnv = { name, pkgList ? [], shellHook ? "" }:
          pkgs.mkShell {
            inherit name;
            buildInputs = commonPackages ++ pkgList;
            shellHook = commonShellHooks + shellHook;
          };

      in {
        # --- 💻 devShells 출력 ---
        # 프로젝트별 개발 환경은 그대로 유지됩니다.
        devShells = {
          default = mkEnv { name = "default"; };
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
            shellHook = ''
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
            shellHook = ''
              echo "Enabled[Golang]: $(go version)"
              export GOPATH="$HOME/go"
              export PATH="$GOPATH/bin:$PATH"
              mkdir -p $GOPATH
            '';
          };

          # Python
          py = mkEnv {
            name = "py";
            pkgList = with pkgs; [
              uv
            ];
            shellHook = ''
              echo "Enabled[Python(uv)]: $(uv --version)"
              export PYTHONPATH="$PWD:$PYTHONPATH"
            '';
          };

          # Node.js
          node = mkEnv {
            name = "node";
            pkgList = with pkgs; [
              nodejs
            ];
            shellHook = ''
              echo "Enabled[Node.js(nvm)]: $(nvm --version)"
            '';
          };
        };

        # --- 🏠 Home Manager 출력 ---
        # 1. 일반 Linux / macOS 용
        homeConfigurations = builtins.mapAttrs
          (name: value:
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = { # 모듈에 전달할 특별 인자
                username = name;
                email = value.email;
              };
              modules = [ value.module ];
            })
          userConfiguration;

        # 2. NixOS 용
        homeManagerModules = builtins.mapAttrs'
          (name: value: {
            # `imports = [ my-flake.homeManagerModules.1eedaegon ];` 형태로 사용
            inherit name;
            value = {
              imports = [ value.module ];
              _module.args = {
                username = name;
                email = value.email;
              };
            };
          })
          userConfiguration;

       #  devShells = (mergeOutputsBy "devShells") // {
       #     default = pkgs.mkShell {
       #       name = "default-shell";
       #       buildInputs = commonPackages; # 공통 패키지 목록 사용
       #       shellHook = commonShellHooks;
       #     };
       #   };

       #   # --- ✨ Home Manager 설정 (더욱 독립적으로 변경) ---
       #   # extraSpecialArgs에서 defaultEnv 전달 부분을 제거합니다.
       #   homeConfigurations = builtins.mapAttrs
       #     (name: value:
       #       home-manager.lib.homeManagerConfiguration {
       #         inherit pkgs;
       #         extraSpecialArgs = { username = name; }; # username만 전달
       #         modules = [ value.module ];
       #       })
       #     userConfigurations;

       #   # NixOS 모듈도 동일하게 수정
       #   homeManagerModules = builtins.mapAttrs'
       #     (name: value: {
       #       name = name;
       #       value = {
       #         imports = [ value.module ];
       #         _module.args = { username = name; };
       #       };
       #     })
       #     userConfigurations;
       # });
        # packages = mergeOutputsBy "packages";
        # devShells = mergeOutputsBy "devShells";
        # # For Other OS
        # homeConfigurations = builtins.mapAttrs
        #   (name: value: home-manager.lib.homeManagerConfiguration {
        #     pkgs = pkgs;
        #     extraSpecialArgs = {
        #       inherit defaultEnv;
        #       username = name;
        #     };
        #     modules = [ value.module ];
        #   })
        #   userConfiguration;

        # # For NixOS
        # homeManagerModules = builtins.mapAttrs
        #   (name: value: {
        #     name = name
        #     value = {
        #     import [ value.module ];
        #     _module.args = {
        #       inherit defaultEnv;
        #       username = name;
        #     }
        #     }
        #   });
        # userConfiguration;
      }
    );
}
