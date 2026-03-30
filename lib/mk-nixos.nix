# lib/mk-nixos.nix
# Builds nixosConfigurations from profile table
{ nixpkgs, home-manager, nix-doom-emacs-unstraightened, everything-claude-code, identity, overlaysLib }:

{
  mkNixOS = nixosSystemConfigs:
    builtins.mapAttrs
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
                    home = identity.getHomeDirectory config.system username;
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
                  ident = identity.lookupUser u;
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
                  value = import ../home/home.nix;
                }) config.users
              );
            }
          ] ++ config.modules;
        })
      nixosSystemConfigs;
}
