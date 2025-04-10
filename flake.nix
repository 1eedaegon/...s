# flake.nix
{
  description = "gg";
  
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
  # TODO: Define packages and apps for default environment
  outputs = { self, nixpkgs, flake-utils, home-manager, rust-overlay, ... }:
     flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { 
          inherit system overlays; 
          config.allowUnfree = true; 
        };
        commonPkgs = with pkgs; [
          nerd-fonts.fira-code
          starship
        ];
        defaultPkgs = with pkgs; [
          nerd-fonts.symbols-only
          nerd-fonts.fira-code
          starship
          bat
          git
          curl
          asciinema
          fontconfig
          direnv
          uv
          gcc
          gnumake
        ];
        commonShellHooks = import ./lib/common-shell-hook.nix { inherit pkgs; };
        

        # Not yet: https://github.com/NixOS/nix/pull/8901 
        # ++ (if stdenv.isWindows then [ chocolatey ] else []);
        
        # CLI 바이너리 처리
        # myCliBinary = import ./cli-derivation.nix { inherit pkgs system; };
        # hasBinary = myCliBinary ? package && myCliBinary.package != null;
        # cliBinary = if hasBinary then [ myCliBinary.package ] else [];
        
        # Rust dev latest
        rustPkgs = with pkgs; [
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
          ]++ commonPkgs;
        rustShellHook = commonShellHooks + ''
            # Log level
            declare -x name="rust"
            export RUST_BACKTRACE=1
            export RUST_LOG=debug
            
            # Cargo cache
            export CARGO_HOME="$HOME/.cargo"
            mkdir -p $CARGO_HOME
            
            # Cargo alias
            alias cb='cargo build'
            alias ct='cargo test'
            alias cr='cargo run'
            
            rustc --version
          '';
        rustShell = pkgs.mkShell {
          name = "rust";
          buildInputs = rustPkgs;
          shellHook = rustShellHook;
        };
        rustBuildEnv = pkgs.buildEnv {
          name = "rust";
          paths = rustPkgs;
        };
        # Rust 1.70.0
        rust170Pkgs = with pkgs; [
          (rust-bin.stable."1.70.0".default.override {
            extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
          })
          pkg-config
          openssl.dev
          libiconv
          cargo-edit
          cargo-watch
          cargo-expand
          lldb
        ]++ commonPkgs;
        rust170ShellHook = commonShellHooks + ''
            # Rust 로그
            export RUST_BACKTRACE=1
            export RUST_LOG=debug
            
            # Cargo 캐시
            export CARGO_HOME="$HOME/.cargo"
            mkdir -p $CARGO_HOME
            
            # Cargo alias
            alias cb='cargo build'
            alias ct='cargo test'
            alias cr='cargo run'
            
            # Version
            rustc --version
          '';
        
        rust170 = pkgs.mkShell {
          name = "rust-1.70.0";
          buildInputs = rust170Pkgs;
          shellHook = rust170ShellHook;
        };
        
        # Go Dev
        goPkgs = with pkgs; [
          go
          gopls
          gotools
          go-outline
          gopkgs
          godef
          golint
        ]++ commonPkgs; 
        goShellHook = ''
          # Go 환경 설정
          export GOPATH="$HOME/go"
          export PATH="$GOPATH/bin:$PATH"
          mkdir -p $GOPATH

          # Version
          go version
        ''+ commonShellHooks;
        goShell = pkgs.mkShell {
          name = "go";
          buildInputs = goPkgs;
          shellHook = goShellHook;
        };
        goBuildEnv = pkgs.buildEnv {
          name = "go";
          paths = goPkgs;
        };
        
        # Python Dev
        pyPkgs = with pkgs; [
          uv
        ] ++ commonPkgs;
        pyShellHook =  ''
          # Version
          uv version
        '' + commonShellHooks;
        pyShell = pkgs.mkShell {
          name = "py";
          buildInputs = pyPkgs;
          shellHook = pyShellHook;
        };
        pyBuildEnv = pkgs.buildEnv {
            name = "py";
            paths = pyPkgs;
        };

        defaultBuildEnv = pkgs.buildEnv {
            name = "dev";
            paths = defaultPkgs ++ commonPkgs;
        };
        # Default, 
        devBuildEnv = pkgs.buildEnv {
            name = "dev";
            paths = defaultPkgs ++ pyPkgs ++ rustPkgs ++ goPkgs;
        };
      
      in {
        # homeConfigurations."1eedaegon-${system}" =   home-manager.lib.homeManagerConfiguration {
        #     modules = [
        #       {
        #         home.username = "1eedaegon";
        #         home.homeDirectory = "/home/1eedaegon";
        #         home.stateVersion = "22.11";
        #         programs.home-manager.enable = true;
        #       }
        #     ];
        #   };
        # packages = {
        #   dev = mkShell {
        #     # name = "dev";
        #     buildInputs = commonPkgs ++ py.buildInputs;
        #     shellHook = ''''+commonShellHooks + rustShellHook + goShellHook + pyShellHook;
        #   };
        #   inherit py rust rust170 go;
        # };
        # devShells = {
        #   inherit pyShell;
        # };
        # TODO: Make generate func for buildEnv, mkShell using pkgs and shellHook
        packages = {
          default = defaultBuildEnv;
          dev = devBuildEnv;
          py = pyBuildEnv;
          go = goBuildEnv;
          rust = rustBuildEnv;
        };
      }
    );
}
