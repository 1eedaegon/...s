# lib/identity.nix
# User identity resolution — single source of truth
# userRegistry is passed in from flake.nix (data stays in flake, logic stays here)
{ lib, userRegistry }:

let
  lastResortEmail = "test@localhost";

  # First non-empty value among the named environment variables.
  # builtins.getEnv returns "" under pure evaluation, so this degrades to the
  # supplied default instead of failing the build.
  envOr = names: default:
    let hit = lib.findFirst (v: v != "") "" (map builtins.getEnv names);
    in if hit != "" then hit else default;
in
{
  inherit userRegistry;

  # Registered accounts resolve from the registry — it is the declared source
  # of truth and env vars must not silently override it. Everyone else falls
  # back to the environment (git's own identity vars) before the placeholders,
  # so an unregistered user still gets usable commit attribution without
  # having to fork and hardcode their login name.
  lookupUser = user:
    if userRegistry ? ${user} then
      let entry = userRegistry.${user};
      in {
        serviceUsername = if entry.serviceUsername != null then entry.serviceUsername else user;
        email = entry.email;
      }
    else {
      serviceUsername = envOr [ "GIT_AUTHOR_NAME" "GIT_COMMITTER_NAME" ] user;
      email = envOr [ "EMAIL" "GIT_AUTHOR_EMAIL" "GIT_COMMITTER_EMAIL" ] lastResortEmail;
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
