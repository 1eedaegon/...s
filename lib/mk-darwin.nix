# lib/mk-darwin.nix
# Builds darwinConfigurations
{ nixpkgs, nix-darwin, nix-homebrew, home-manager, nix-doom-emacs-unstraightened, everything-claude-code, identity, overlaysLib }:

{
  mkDarwin = { system, username }:
    let
      ident = identity.lookupUser username;
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
            inherit email system everything-claude-code;
          };
          home-manager.sharedModules = [
            nix-doom-emacs-unstraightened.homeModule
          ];
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
