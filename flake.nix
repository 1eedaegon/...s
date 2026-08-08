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
    gstack = {
      url = "github:garrytan/gstack";
      flake = false;
    };
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
    nixpkgs-grok-build.url = "github:1eedaegon/nixpkgs/grok-build-intel-mac-release-26.05";

    # x86_64-darwin lifeline: nixpkgs unstable (26.11-pre) hard-dropped intel
    # macs. 26.05 is the last supporting release (security fixes until end of
    # 2026), so that system gets a matched 26.05 channel set; everything else
    # keeps tracking unstable. Selection happens in `channelsFor` below.
    nixpkgs-2605-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    home-manager-2605 = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-2605-darwin";
    };
    nix-darwin-2605 = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-2605-darwin";
    };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, nix-darwin, nix-homebrew, rust-overlay, jetpack, everything-claude-code, gstack, nix-doom-emacs-unstraightened, nixpkgs-python, nixpkgs-grok-build, nixpkgs-2605-darwin, home-manager-2605, nix-darwin-2605, ... }:
    let
      lib = nixpkgs.lib;

      # ── User config (EDIT THIS) ──
      userRegistry = {
        "leedaegon" = { serviceUsername = "1eedaegon"; email = "d8726243@gmail.com"; };
        "1eedaegon" = { serviceUsername = "1eedaegon"; email = "d8726243@gmail.com"; };
      };

      # Exact toolchain pins -> #go1_25_6 #py3_13_5 #rust1_96_0 (assembly in lib/version-shells.nix)
      toolchainVersions = {
        go = [ "1.23.5" "1.25.6" ];
        rust = [ "1.96.0" ];
        python = [ "3.11.5" "3.13.5" ];
      };

      # ── Channel selection ──
      # x86_64-darwin rides the 26.05 channel set (unstable dropped intel mac);
      # every other system tracks unstable. home-manager/nix-darwin must match
      # their nixpkgs, so the whole trio is swapped together.
      channelsFor = system:
        if system == "x86_64-darwin" then {
          nixpkgs = nixpkgs-2605-darwin;
          home-manager = home-manager-2605;
          nix-darwin = nix-darwin-2605;
        } else {
          inherit nixpkgs home-manager nix-darwin;
        };
      # For impure host-targeting outputs (darwinConfigurations, homeConfigurations)
      currentChannels = channelsFor (builtins.currentSystem or "x86_64-linux");

      # ── Lib ──
      identity = import ./lib/identity.nix { inherit lib userRegistry; };
      overlaysLib = import ./lib/overlays.nix { inherit rust-overlay jetpack nixpkgs-grok-build; };

      homeLib = import ./lib/mk-home.nix {
        nixpkgs = currentChannels.nixpkgs;
        home-manager = currentChannels.home-manager;
        inherit nix-doom-emacs-unstraightened everything-claude-code gstack identity overlaysLib;
      };
      darwinLib = import ./lib/mk-darwin.nix {
        nixpkgs = currentChannels.nixpkgs;
        nix-darwin = currentChannels.nix-darwin;
        home-manager = currentChannels.home-manager;
        inherit nix-homebrew nix-doom-emacs-unstraightened everything-claude-code gstack identity overlaysLib;
      };
      nixosLib = import ./lib/mk-nixos.nix {
        inherit nixpkgs home-manager nix-doom-emacs-unstraightened everything-claude-code gstack identity overlaysLib;
      };

      # ── NixOS profiles (data only) ──
      nixosSystemConfigs =
        let
          currentSystem = builtins.currentSystem or "x86_64-linux";
          nixosSystem =
            if builtins.match ".*darwin.*" currentSystem != null
            then "x86_64-linux"
            else currentSystem;
        in
        {
          "desktop" = { system = nixosSystem; hostname = "1eedaegon"; users = identity.registeredUsers; modules = [ ./nixos/desktop.nix ]; };
          "workstation" = { system = "x86_64-linux"; hostname = "workstation"; users = identity.registeredUsers; modules = [ ./nixos/workstation.nix ]; };
          "jetson" = { system = "aarch64-linux"; hostname = "jetson"; users = identity.registeredUsers; modules = [ ./nixos/jetson.nix ]; };
          "sbc" = { system = "aarch64-linux"; hostname = "sbc"; users = identity.registeredUsers; modules = [ ./nixos/sbc.nix ]; };
        };

    in
    (flake-utils.lib.eachDefaultSystem (system:
      let
        # jetpack overlay only on aarch64-linux (Jetson). No devShell package
        # needs CUDA/TensorRT, so applying it elsewhere is dead weight + a footgun.
        overlays = overlaysLib.mkOverlays { includeJetpack = system == "aarch64-linux"; inherit system; };
        pkgs = overlaysLib.mkPkgs { nixpkgs = (channelsFor system).nixpkgs; inherit system overlays; cudaSupport = false; };

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
        # Version-postfixed shells (#go1_25_6, #py3_13_5, #node22, #java21, #rust1_96_0)
        versionShells = import ./lib/version-shells.nix {
          inherit pkgs lib;
          pythonPkgs = nixpkgs-python.packages.${system};
          versions = toolchainVersions;
        };
        # Combination packages
        combinations = {
          fullstack = import ./packages/combinations/fullstack.nix { inherit pkgs; };
          ml = import ./packages/combinations/ml.nix { inherit pkgs; };
          infra = import ./packages/combinations/infra.nix { inherit pkgs; };
          research = import ./packages/combinations/research.nix { inherit pkgs; };
          security = import ./packages/combinations/security.nix { inherit pkgs; };
        };
      in
      {
        devShells = {
          # Toolchains (independent, each includes base)
          default = mkEnv { name = "default"; };
          rust = mkEnv { name = "rust"; };
          go = mkEnv { name = "go"; };
          py = mkEnv { name = "py"; };
          node = mkEnv { name = "node"; };
          java = mkEnv { name = "java"; };

          # Combinations (compose toolchains, each includes base)
          fullstack = mkEnv { name = "fullstack"; extraPackages = combinations.fullstack.packages; };
          ml = mkEnv { name = "ml"; extraPackages = combinations.ml.packages; };
          infra = mkEnv { name = "infra"; extraPackages = combinations.infra.packages; };
          research = mkEnv { name = "research"; extraPackages = combinations.research.packages; };
          security = mkEnv { name = "security"; extraPackages = combinations.security.packages; };

          # Custom example
          custom = mkEnv { name = "default"; extraPackages = with pkgs; [ docker kubectl ]; extraShellHook = "echo 'Custom environment loaded'"; };
        } // versionShells;

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
              ${(channelsFor system).home-manager.packages.${system}.home-manager}/bin/home-manager switch --flake ${self}#default --impure -b backup "$@"
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
        "x86_64" = darwinLib.mkDarwin { system = "x86_64-darwin"; username = "leedaegon"; };
      };
    };
}
