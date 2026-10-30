# home/nix-lazy-trees.nix
# Determinate Nix's lazy-trees leaves drvs referencing virtual source trees;
# a later re-evaluation (after local source edits) can then keep resolving
# to a stale derivation instead of picking up the change — see
# darwin/default.nix's own note on "stale drv recreation errors". That fix
# only runs on darwin (nix-darwin's activation script, system-wide). This
# does the same at the user level so it also covers plain Linux installs
# (no NixOS module system) and NixOS hosts, which have no equivalent hook.
{ lib, pkgs }:

let
  setup = pkgs.writeShellScript "setup-nix-lazy-trees" ''
    set -u
    dir="$HOME/.config/nix"; conf="$dir/nix.conf"
    mkdir -p "$dir"

    if [ ! -e "$conf" ] || ! grep -q "lazy-trees" "$conf" 2>/dev/null; then
      printf 'lazy-trees = false\n' >> "$conf"
    fi
  '';
in
{
  activation.setupNixLazyTrees = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${setup}
  '';
}
