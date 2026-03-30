# lib/identity.nix
# User identity resolution — single source of truth
# userRegistry is passed in from flake.nix (data stays in flake, logic stays here)
{ lib, userRegistry }:

let
  defaultIdentity = { serviceUsername = null; email = "test@localhost"; };
in
{
  inherit userRegistry;

  lookupUser = user:
    let entry = userRegistry.${user} or defaultIdentity;
    in {
      serviceUsername = if entry.serviceUsername != null then entry.serviceUsername else user;
      email = entry.email;
    };

  # All unique serviceUsernames from registry (for NixOS user creation)
  registeredUsers = lib.unique (
    lib.mapAttrsToList (_: v: v.serviceUsername) userRegistry
  );

  getHomeDirectory = system: username:
    if builtins.match ".*darwin.*" system != null then
      "/Users/${username}"
    else if username == "root" then
      "/root"
    else
      "/home/${username}";
}
