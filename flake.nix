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
             name = "leedaegon"; # For system user
             username = "1eedaegon"; # For service user
             email = "d8726243@gmail.com";
             module = ./home/home.nix;
           };
           "default" = {
             name = "leedaegon"; # For system user
             username = "1eedaegon"; # For service user
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
                 systemUsername = config.name;
                 username = config.username;
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

          moduleLoader = import ./lib/module-loader.nix { inherit pkgs system; };
          modules = moduleLoader.loadModules;

          envLib = import ./lib/mk-env.nix {
            inherit pkgs system;
            modules = {
              commonInstalls = modules.installations.common;
              commonExec = modules.executions.common;
              devInstalls = modules.installations.dev;
              devExec = modules.executions.dev;
              devConfig = modules.configurations.dev;
            };
          };
          mkEnv = envLib.mkEnv;

        in {
          devShells = {
            default = mkEnv { name = "default"; };
            rust = mkEnv { name = "rust"; };
            go = mkEnv { name = "go"; };
            py = mkEnv { name = "python"; };
            node = mkEnv { name = "node"; };

            # Custom environments
            custom = mkEnv {
              name = "default";
              extraPackages = with pkgs; [ docker kubectl ];
              extraShellHook = ''
                echo "Custom environment loaded"
              '';
            };
          };

          # Export modules for debugging/testing
          inherit modules;
        }
      )) //
      {
        homeConfigurations = mkAllHomeConfigurations;
        # nixosConfigurations (기존 유지)
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
