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
      # ── User identity mapping (single source of truth) ──
      # Replace with your own identity. All configurations derive from this table.
      # Example:
      #   "john" = { serviceUsername = "johndoe"; email = "john@example.com"; };
      userRegistry = {
        "leedaegon" = { serviceUsername = "1eedaegon"; email = "d8726243@gmail.com"; };
        "1eedaegon" = { serviceUsername = "1eedaegon"; email = "d8726243@gmail.com"; };
      };
      defaultIdentity = { serviceUsername = null; email = "test@localhost"; };

      # Lookup helpers
      lookupUser = user:
        let entry = userRegistry.${user} or defaultIdentity;
        in {
          serviceUsername = if entry.serviceUsername != null then entry.serviceUsername else user;
          email = entry.email;
        };

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
        # CUDA disabled: libcusparse_lt is broken on x86_64-linux in nixpkgs
        # Enable manually if needed with allowUnsupportedSystem
        overlays = [
          (import rust-overlay)
          jetpack.overlays.default
          (final: prev: {
            nix = prev.nix.overrideAttrs (old: {
              doCheck = false;
              doInstallCheck = false;
            });
            rustup = prev.rustup.overrideAttrs (old: {
              doCheck = false;
              doInstallCheck = false;
            });
            # cursor-arm for aarch64-linux
            cursor-arm = cursor-arm.packages.${system}.default or null;
          })
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
          config.cudaSupport = false;
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
              # macOS: use nix-darwin (requires sudo)
              # Use sudo -H to reset HOME to root, avoiding "$HOME is not owned by you" warning
              if command -v darwin-rebuild &> /dev/null; then
                sudo -H darwin-rebuild switch --flake ${self}#default --impure "$@"
              else
                echo "Installing nix-darwin for the first time..."
                sudo -H nix run nix-darwin -- switch --flake ${self}#default --impure "$@"
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
            identity = lookupUser user;

            # 서비스 유저명 및 이메일 매핑 (userRegistry에서 조회)
            serviceUsername = identity.serviceUsername;
            email =
              if envEmail != "" then envEmail
              else identity.email;

            # 현재 호스트 시스템 사용
            system = currentSystem;

            overlays = [
              (import rust-overlay)
              # jetpack overlay는 devShell/nixos 전용 (CUDA/Jetson)
              # homeConfigurations에서는 불필요하며 평가 시간을 대폭 증가시킴
              (final: prev: {
                nix = prev.nix.overrideAttrs (old: {
                  doCheck = false;
                  doInstallCheck = false;
                });
                rustup = prev.rustup.overrideAttrs (old: {
                  doCheck = false;
                  doInstallCheck = false;
                });
                # cursor-arm for aarch64-linux
                cursor-arm = cursor-arm.packages.${system}.default or null;
              })
            ];
            pkgs = import nixpkgs {
              inherit system overlays;
              config.allowUnfree = true;
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
                # CUDA disabled by default; enable per-host if needed
                nixpkgs.config.cudaSupport = false;

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

                home-manager.extraSpecialArgs =
                  let
                    u = builtins.elemAt config.users 0;
                    identity = lookupUser u;
                  in
                  {
                    systemUsername = u;
                    username = identity.serviceUsername;
                    email = identity.email;
                    system = config.system;
                    inherit everything-claude-code;
                  };
                home-manager.sharedModules = [
                  nix-doom-emacs-unstraightened.homeModule
                ];

                home-manager.users = builtins.listToAttrs (
                  map
                    (username: {
                      name = username;
                      value = import ./home/home.nix;
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
              identity = lookupUser username;
              serviceUsername = identity.serviceUsername;
              email = identity.email;

              overlays = [
                (import rust-overlay)
                (final: prev: {
                  nix = prev.nix.overrideAttrs (old: {
                    doCheck = false;
                    doInstallCheck = false;
                  });
                  rustup = prev.rustup.overrideAttrs (old: {
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
          # Default darwin configuration (auto-detect current user)
          # SUDO_USER is set when running with sudo, fallback to USER
          default = mkDarwinConfig {
            system = builtins.currentSystem;
            username =
              let
                sudoUser = builtins.getEnv "SUDO_USER";
                user = builtins.getEnv "USER";
              in
              if sudoUser != "" then sudoUser else user;
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
