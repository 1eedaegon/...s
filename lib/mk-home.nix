# lib/mk-home.nix
# Builds homeConfigurations
{ nixpkgs, home-manager, nix-doom-emacs-unstraightened, everything-claude-code, gstack, identity, overlaysLib }:

{
  mkHome = { currentUser, currentSystem, envEmail }:
    let
      user = if currentUser == "" then "nobody" else currentUser;
      ident = identity.lookupUser user;
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
        inherit email system everything-claude-code gstack;
      };
      modules = [
        nix-doom-emacs-unstraightened.homeModule
        ../home/home.nix
        {
          home.username = user;
          home.homeDirectory = identity.getHomeDirectory system user;
          home.stateVersion = "24.05";
          programs.home-manager.enable = true;
        }
      ];
    };
}
