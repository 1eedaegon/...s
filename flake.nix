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
    let
       # For PC Global profile
       userConfigurations = {
         "1eedaegon" = {
           name = "leedaegon";
           email = "d8726243@gmail.com";
           module = ./home/home.nix;
         };
         "default" = {
           name = "leedaegon";
           email = "d8726243@gmail.com";
           module = ./home/home.nix;
          };
       };
       getHomeDirectory = system: username:
         if builtins.match ".*darwin.*" system != null then
           "/Users/${username}"
         else
           "/home/${username}";

       # For NixOS Global profile
       nixosSystemConfigs =
         let
           currentSystem = builtins.currentSystem or "x86_64-linux";
           # NixOS support only Linux
           nixosSystem = if builtins.match ".*darwin.*" currentSystem != null then
             "x86_64-linux"  # darwin, use x86_64-linux
           else
             currentSystem;   # linux
         in

         {
           "desktop" = {
             system = nixosSystem;
             hostname = "1eedaegon";
             users = [ "1eedaegon" ];
             modules = [
               ./nixos/desktop.nix
             ];
           };
         };

       mkAllHomeConfigurations =
         let
         # Platform suffix mapping
         platformSuffixes = {
           "x86_64-linux" = "linux";
           "aarch64-linux" = "aarch64-linux";
           "x86_64-darwin" = "darwin";
           "aarch64-darwin" = "aarch64-darwin";
         };

         # Generate configurations for a specific system
         mkSystemConfigs = system:
         let
         overlays = [ (import rust-overlay) ];
         pkgs = import nixpkgs {
           inherit system overlays;
           config.allowUnfree = true;
         };
         in
         builtins.mapAttrs (name: config:
           home-manager.lib.homeManagerConfiguration {
             inherit pkgs;
             extraSpecialArgs = {
               username = config.name;
               email = config.email;
               inherit system;
             };
             modules = [
               config.module
               {
                 home.username = config.name;
                 home.homeDirectory = getHomeDirectory system config.name;
                 home.stateVersion = "24.05";
                 programs.home-manager.enable = true;
               }
             ];
           }
         ) userConfigurations;

         # Generate all user.platform combinations
         allConfigs = builtins.foldl' (acc: system:
           let
           suffix = platformSuffixes.${system};
           systemConfigs = mkSystemConfigs system;

           # Create user.platform entries
           namedConfigs = builtins.listToAttrs (
             map (userName: {
               name = "${userName}.${suffix}";
               value = systemConfigs.${userName};
             }) (builtins.attrNames systemConfigs)
           );
           in
           acc // namedConfigs
         ) {} (builtins.attrNames platformSuffixes);
        in
        allConfigs;
     in
    (flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
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
        devShells = {
          default = mkEnv { name = "default"; };
          # Rust
          rust = mkEnv {
            name = "rust";
            pkgList = with pkgs; [
              (rust-bin.stable.latest.default.override {
                extensions = [
                  "rust-src"
                  "rust-analyzer"
                  "clippy"
                  "rustfmt"
                ];
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
              echo "Enabled[Node.js]: $(nvm --version)"
            '';
          };
        };
      }
    )) //
    {
      homeConfigurations = mkAllHomeConfigurations;
      # nixosConfigurations
      nixosConfigurations = builtins.mapAttrs
        (hostName: config:
          nixpkgs.lib.nixosSystem {
            system = config.system;
            specialArgs = {
              inherit home-manager;
              hostname = config.hostname;
            };
            modules = [
              {
                system.stateVersion = "24.05";
                networking.hostName = config.hostname;
                nix.settings.experimental-features = [ "nix-command" "flakes" ];
                nixpkgs.overlays = [ (import rust-overlay) ];
                nixpkgs.config.allowUnfree = true;

                users.users = builtins.listToAttrs (
                  map (username: {
                    name = username;
                    value = {
                      isNormalUser = true;
                      description = username;
                      home = getHomeDirectory config.system username;
                      extraGroups = [ "networkmanager" "wheel" "docker" ];
                    };
                  }) config.users
                );

                programs.zsh.enable = true;
                programs.git.enable = true;
                services.openssh.enable = true;
                virtualisation.docker.enable = true;
              }

              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "backup";

                home-manager.users = builtins.listToAttrs (
                  map (username: {
                    name = username;
                    value = self.homeManagerModules.${config.system}.${username};
                  }) config.users
                );
              }
            ] ++ config.modules;
          })
        nixosSystemConfigs;
    };
}
