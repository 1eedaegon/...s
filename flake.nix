# flake.nix
{
  description = "...s(3dots) with nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jetpack = {
      url = "github:anduril/jetpack-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    everything-claude-code = {
      url = "github:affaan-m/everything-claude-code";
      flake = false;
    };
    cursor-arm = {
      url = "github:coder/cursor-arm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, nix-darwin, nix-homebrew, rust-overlay, jetpack, everything-claude-code, cursor-arm, nix-doom-emacs-unstraightened, ... }:
    let
      lib = nixpkgs.lib;

      # ── User config (EDIT THIS) ──
      userRegistry = {
        "leedaegon"  = { serviceUsername = "1eedaegon"; email = "d8726243@gmail.com"; };
        "1eedaegon"  = { serviceUsername = "1eedaegon"; email = "d8726243@gmail.com"; };
      };

      # ── Lib imports ──
      identity = import ./lib/identity.nix { inherit lib userRegistry; };
      overlaysLib = import ./lib/overlays.nix { inherit rust-overlay jetpack cursor-arm; };

      inherit (identity) lookupUser registeredUsers getHomeDirectory;

      # ── NixOS profiles (data only) ──
      nixosSystemConfigs =
        let
          currentSystem = builtins.currentSystem or "x86_64-linux";
          nixosSystem =
            if builtins.match ".*darwin.*" currentSystem != null then
              "x86_64-linux"
            else
              currentSystem;
        in
        {
          "desktop" = {
            system = nixosSystem;
            hostname = "1eedaegon";
            users = registeredUsers;
            modules = [ ./nixos/desktop.nix ];
          };
          "workstation" = {
            system = "x86_64-linux";
            hostname = "workstation";
            users = registeredUsers;
            modules = [ ./nixos/workstation.nix ];
          };
          "jetson" = {
            system = "aarch64-linux";
            hostname = "jetson";
            users = registeredUsers;
            modules = [ ./nixos/jetson.nix ];
          };
          "sbc" = {
            system = "aarch64-linux";
            hostname = "sbc";
            users = registeredUsers;
            modules = [ ./nixos/sbc.nix ];
          };
        };

    in
    (flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = overlaysLib.mkOverlays {
          includeJetpack = true;
          includeCursorArm = true;
          inherit system;
        };
        pkgs = overlaysLib.mkPkgs {
          inherit nixpkgs system overlays;
          cudaSupport = false;
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
      in
      {
        devShells = {
          default = mkEnv { name = "default"; };
          rust = mkEnv { name = "rust"; };
          go = mkEnv { name = "go"; };
          py = mkEnv { name = "py"; };
          node = mkEnv { name = "node"; };
          java = mkEnv { name = "java"; };
          custom = mkEnv {
            name = "default";
            extraPackages = with pkgs; [ docker kubectl ];
            extraShellHook = ''
              echo "Custom environment loaded"
            '';
          };
        };

        apps.default = {
          type = "app";
          program = "${pkgs.writeShellScript "nix-switch" ''
            if [[ "$(uname)" == "Darwin" ]]; then
              if command -v darwin-rebuild &> /dev/null; then
                sudo -H darwin-rebuild switch --flake ${self}#default --impure "$@"
              else
                echo "Installing nix-darwin for the first time..."
                sudo -H nix run nix-darwin -- switch --flake ${self}#default --impure "$@"
              fi
            else
              ${home-manager.packages.${system}.home-manager}/bin/home-manager switch --flake ${self}#default --impure -b backup "$@"
            fi
          ''}";
        };

        inherit modules;
      }
    )) //
    {
      # ── homeConfigurations ──
      homeConfigurations = {
        default =
          let
            currentUser = builtins.getEnv "USER";
            currentSystem = builtins.currentSystem;
            envEmail = builtins.getEnv "EMAIL";

            user = if currentUser == "" then "nobody" else currentUser;
            ident = lookupUser user;
            serviceUsername = ident.serviceUsername;
            email = if envEmail != "" then envEmail else ident.email;
            system = currentSystem;

            overlays = overlaysLib.mkOverlays {
              includeCursorArm = true;
              inherit system;
            };
            pkgs = overlaysLib.mkPkgs { inherit nixpkgs system overlays; };
          in
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {
              systemUsername = user;
              username = serviceUsername;
              inherit email system everything-claude-code;
            };
            modules = [
              nix-doom-emacs-unstraightened.homeModule
              ./home/home.nix
              {
                home.username = user;
                home.homeDirectory = getHomeDirectory system user;
                home.stateVersion = "24.05";
                programs.home-manager.enable = true;
              }
            ];
          };
      };

      # ── nixosConfigurations ──
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
                nixpkgs.overlays = overlaysLib.mkOverlays {
                  includeJetpack = true;
                  system = config.system;
                };
                nixpkgs.config.allowUnfree = true;
                nixpkgs.config.cudaSupport = false;

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

                home-manager.extraSpecialArgs =
                  let
                    u = builtins.elemAt config.users 0;
                    ident = lookupUser u;
                  in {
                    systemUsername = u;
                    username = ident.serviceUsername;
                    email = ident.email;
                    system = config.system;
                    inherit everything-claude-code;
                  };
                home-manager.sharedModules = [
                  nix-doom-emacs-unstraightened.homeModule
                ];

                home-manager.users = builtins.listToAttrs (
                  map (username: {
                    name = username;
                    value = import ./home/home.nix;
                  }) config.users
                );
              }
            ] ++ config.modules;
          })
        nixosSystemConfigs;

      # ── darwinConfigurations ──
      darwinConfigurations =
        let
          mkDarwinConfig = { system, username }:
            let
              ident = lookupUser username;
              serviceUsername = ident.serviceUsername;
              email = ident.email;

              overlays = overlaysLib.mkOverlays { inherit system; };
              pkgs = overlaysLib.mkPkgs { inherit nixpkgs system overlays; };
            in
            nix-darwin.lib.darwinSystem {
              inherit system;
              specialArgs = {
                inherit email;
                systemUsername = username;
                username = serviceUsername;
              };
              modules = [
                ./darwin/default.nix
                nix-homebrew.darwinModules.nix-homebrew
                {
                  nix-homebrew = {
                    enable = true;
                    enableRosetta = system == "aarch64-darwin";
                    user = username;
                    autoMigrate = true;
                  };
                }
                home-manager.darwinModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.backupFileExtension = "backup";
                  home-manager.extraSpecialArgs = {
                    systemUsername = username;
                    username = serviceUsername;
                    inherit email system everything-claude-code;
                  };
                  home-manager.sharedModules = [
                    nix-doom-emacs-unstraightened.homeModule
                  ];
                  home-manager.users.${username} = import ./home/home.nix;
                }
                {
                  users.users.${username} = {
                    name = username;
                    home = getHomeDirectory system username;
                  };
                }
              ];
            };
        in
        {
          default = mkDarwinConfig {
            system = builtins.currentSystem;
            username =
              let
                sudoUser = builtins.getEnv "SUDO_USER";
                user = builtins.getEnv "USER";
              in
              if sudoUser != "" then sudoUser else user;
          };
          "aarch64" = mkDarwinConfig {
            system = "aarch64-darwin";
            username = "leedaegon";
          };
          "x86_64" = mkDarwinConfig {
            system = "x86_64-darwin";
            username = "leedaegon";
          };
        };
    };
}
