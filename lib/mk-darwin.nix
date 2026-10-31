# lib/mk-darwin.nix
# Builds darwinConfigurations
{ nixpkgs, nix-darwin, nix-homebrew, home-manager, everything-claude-code, gstack, identity, overlaysLib }:

{
  mkDarwin = { system, username }:
    let
      ident = identity.lookupUser username;
      serviceUsername = ident.serviceUsername;
      email = ident.email;

      overlays = overlaysLib.mkOverlays { inherit system; };
    in
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit email;
        systemUsername = username;
        username = serviceUsername;
      };
      modules = [
        {
          nixpkgs.overlays = overlays;
          # nix-darwin imports nixpkgs itself, so this path never goes through
          # overlaysLib.mkPkgs and has to be handed the shared config directly.
          nixpkgs.config = overlaysLib.nixpkgsConfig { };
        }
        ../darwin/default.nix
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
            inherit email system everything-claude-code gstack;
          };
          home-manager.users.${username} = import ../home/home.nix;
        }
        {
          users.users.${username} = {
            name = username;
            home = identity.getHomeDirectory system username;
          };
        }
      ];
    };
}
