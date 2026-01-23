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
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, nix-darwin, nix-homebrew, rust-overlay, jetpack, everything-claude-code, ... }:
    let
      getHomeDirectory = system: username:
        if builtins.match ".*darwin.*" system != null then
          "/Users/${username}"
        else if username == "root" then
          "/root"
        else
          "/home/${username}";

      # For NixOS Global profile
      nixosSystemConfigs =
        let
          currentSystem = builtins.currentSystem or "x86_64-linux";
          # NixOS support only Linux
          nixosSystem =
            if builtins.match ".*darwin.*" currentSystem != null then
              "x86_64-linux"  # darwin, use x86_64-linux
            else
              currentSystem; # linux
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

    in
    (flake-utils.lib.eachDefaultSystem (system:
      let
        # CUDA only supported on Linux
        isLinux = system == "x86_64-linux" || system == "aarch64-linux";

        overlays = [
          (import rust-overlay)
          jetpack.overlays.default
          (final: prev: {
            nix = prev.nix.overrideAttrs (old: {
              doCheck = false;
              doInstallCheck = false;
            });
          })
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
          config.cudaSupport = isLinux;
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

          # Custom environments
          custom = mkEnv {
            name = "default";
            extraPackages = with pkgs; [ docker kubectl ];
            extraShellHook = ''
              echo "Custom environment loaded"
            '';
          };
        };

        # nix run . 으로 darwin-rebuild 또는 home-manager switch 실행
        apps.default = {
          type = "app";
          program = "${pkgs.writeShellScript "nix-switch" ''
            if [[ "$(uname)" == "Darwin" ]]; then
              # macOS: use nix-darwin
              if command -v darwin-rebuild &> /dev/null; then
                darwin-rebuild switch --flake ${self}#default --impure "$@"
              else
                echo "Installing nix-darwin for the first time..."
                nix run nix-darwin -- switch --flake ${self}#default --impure "$@"
              fi
            else
              # Linux: use home-manager
              ${home-manager.packages.${system}.home-manager}/bin/home-manager switch --flake ${self}#default --impure -b backup "$@"
            fi
          ''}";
        };

        # Export modules for debugging/testing
        inherit modules;
      }
    )) //
    {
      homeConfigurations = {
        default =
          let
            # 런타임 감지 (--impure 필요)
            currentUser = builtins.getEnv "USER";
            currentSystem = builtins.currentSystem;

            # 환경변수에서 email 가져오기
            envEmail = builtins.getEnv "EMAIL";

            # 기본값 처리
            user = if currentUser == "" then "nobody" else currentUser;

            # 서비스 유저명 및 이메일 매핑
            serviceUsername = if user == "leedaegon" then "1eedaegon" else user;
            email =
              if envEmail != "" then envEmail
              else if user == "leedaegon" || user == "1eedaegon" then "d8726243@gmail.com"
              else "test@localhost";

            # 현재 호스트 시스템 사용
            system = currentSystem;

            overlays = [
              (import rust-overlay)
              jetpack.overlays.default
              (final: prev: {
                nix = prev.nix.overrideAttrs (old: {
                  doCheck = false;
                  doInstallCheck = false;
                });
              })
            ];
            # CUDA는 Linux에서만 지원
            isCudaSupported = builtins.match ".*linux.*" system != null;

            pkgs = import nixpkgs {
              inherit system overlays;
              config.allowUnfree = true;
              config.cudaSupport = isCudaSupported;
            };
          in
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {
              systemUsername = user;
              username = serviceUsername;
              inherit email system everything-claude-code;
            };
            modules = [
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
                nixpkgs.overlays = [
                  (import rust-overlay)
                  jetpack.overlays.default
                ];
                nixpkgs.config.allowUnfree = true;
                nixpkgs.config.cudaSupport = true;

                users.users = builtins.listToAttrs (
                  map
                    (username: {
                      name = username;
                      value = {
                        isNormalUser = true;
                        description = username;
                        home = getHomeDirectory config.system username;
                        extraGroups = [ "networkmanager" "wheel" "docker" ];
                      };
                    })
                    config.users
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
                  map
                    (username: {
                      name = username;
                      value = self.homeManagerModules.${config.system}.${username};
                    })
                    config.users
                );
              }
            ] ++ config.modules;
          })
        nixosSystemConfigs;

      # darwinConfigurations for macOS
      darwinConfigurations =
        let
          mkDarwinConfig = { system, username }:
            let
              serviceUsername = if username == "leedaegon" then "1eedaegon" else username;
              email =
                if username == "leedaegon" || username == "1eedaegon" then "d8726243@gmail.com"
                else "test@localhost";

              overlays = [
                (import rust-overlay)
                (final: prev: {
                  nix = prev.nix.overrideAttrs (old: {
                    doCheck = false;
                    doInstallCheck = false;
                  });
                })
              ];

              pkgs = import nixpkgs {
                inherit system overlays;
                config.allowUnfree = true;
              };
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
          # Default darwin configuration (auto-detect current user)
          default = mkDarwinConfig {
            system = builtins.currentSystem;
            username = builtins.getEnv "USER";
          };

          # Explicit configurations
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
