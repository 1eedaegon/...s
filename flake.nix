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
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
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

      # ── Lib ──
      identity = import ./lib/identity.nix { inherit lib userRegistry; };
      overlaysLib = import ./lib/overlays.nix { inherit rust-overlay jetpack cursor-arm; };

      homeLib = import ./lib/mk-home.nix {
        inherit nixpkgs home-manager nix-doom-emacs-unstraightened everything-claude-code identity overlaysLib;
      };
      darwinLib = import ./lib/mk-darwin.nix {
        inherit nixpkgs nix-darwin nix-homebrew home-manager nix-doom-emacs-unstraightened everything-claude-code identity overlaysLib;
      };
      nixosLib = import ./lib/mk-nixos.nix {
        inherit nixpkgs home-manager nix-doom-emacs-unstraightened everything-claude-code identity overlaysLib;
      };

      # ── NixOS profiles (data only) ──
      nixosSystemConfigs =
        let
          currentSystem = builtins.currentSystem or "x86_64-linux";
          nixosSystem =
            if builtins.match ".*darwin.*" currentSystem != null
            then "x86_64-linux"
            else currentSystem;
        in {
          "desktop"     = { system = nixosSystem;      hostname = "1eedaegon";   users = identity.registeredUsers; modules = [ ./nixos/desktop.nix ]; };
          "workstation" = { system = "x86_64-linux";   hostname = "workstation"; users = identity.registeredUsers; modules = [ ./nixos/workstation.nix ]; };
          "jetson"      = { system = "aarch64-linux";  hostname = "jetson";      users = identity.registeredUsers; modules = [ ./nixos/jetson.nix ]; };
          "sbc"         = { system = "aarch64-linux";  hostname = "sbc";         users = identity.registeredUsers; modules = [ ./nixos/sbc.nix ]; };
        };

    in
    (flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = overlaysLib.mkOverlays { includeJetpack = true; includeCursorArm = true; inherit system; };
        pkgs = overlaysLib.mkPkgs { inherit nixpkgs system overlays; cudaSupport = false; };

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
          rust    = mkEnv { name = "rust"; };
          go      = mkEnv { name = "go"; };
          py      = mkEnv { name = "py"; };
          node    = mkEnv { name = "node"; };
          java    = mkEnv { name = "java"; };
          custom  = mkEnv { name = "default"; extraPackages = with pkgs; [ docker kubectl ]; extraShellHook = "echo 'Custom environment loaded'"; };
        };

        apps.default = {
          type = "app";
          program = "${pkgs.writeShellScript "nix-switch" ''
            if [[ "$(uname)" == "Darwin" ]]; then
              if command -v darwin-rebuild &> /dev/null; then
                sudo -H darwin-rebuild switch --flake ${self}#default --impure "$@"
              else
                sudo -H nix run nix-darwin -- switch --flake ${self}#default --impure "$@"
              fi
            else
              ${home-manager.packages.${system}.home-manager}/bin/home-manager switch --flake ${self}#default --impure -b backup "$@"
            fi
          ''}";
        };

        inherit modules;
      }
    )) // {
      homeConfigurations.default = homeLib.mkHome {
        currentUser = builtins.getEnv "USER";
        currentSystem = builtins.currentSystem;
        envEmail = builtins.getEnv "EMAIL";
      };

      nixosConfigurations = nixosLib.mkNixOS nixosSystemConfigs;

      darwinConfigurations = {
        default = darwinLib.mkDarwin {
          system = builtins.currentSystem;
          username = let su = builtins.getEnv "SUDO_USER"; u = builtins.getEnv "USER"; in if su != "" then su else u;
        };
        "aarch64" = darwinLib.mkDarwin { system = "aarch64-darwin"; username = "leedaegon"; };
        "x86_64"  = darwinLib.mkDarwin { system = "x86_64-darwin";  username = "leedaegon"; };
      };
    };
}
