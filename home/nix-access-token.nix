# home/nix-access-token.nix
# Make `nix develop github:...` work without a NIX_CONFIG prefix by registering a
# GitHub access token in the user nix.conf (leedaegon is a trusted-user, so it's
# honored). Token is read fresh from gh each switch and kept in a 600 side file —
# never committed to the repo. This nix lacks `!include?`, so we use `!include`
# and always keep the side file present so the include never dangles.
{ lib, pkgs }:

let
  setup = pkgs.writeShellScript "setup-nix-access-token" ''
    set -u
    dir="$HOME/.config/nix"; conf="$dir/nix.conf"; inc="$dir/access-tokens.conf"
    mkdir -p "$dir"

    tok="$(${pkgs.gh}/bin/gh auth token 2>/dev/null || true)"
    if [ -n "$tok" ]; then
      ( umask 077; printf 'access-tokens = github.com=%s\n' "$tok" > "$inc" )
    elif [ ! -e "$inc" ]; then
      # gh unavailable and no prior token: keep a harmless file so !include resolves
      ( umask 077; printf '# no gh token at activation\n' > "$inc" )
    fi
    # else: gh failed but a good token file exists — leave it untouched

    if [ ! -e "$conf" ]; then
      printf '!include access-tokens.conf\n' > "$conf"
    elif ! grep -q '^!include access-tokens.conf' "$conf"; then
      printf '\n!include access-tokens.conf\n' >> "$conf"
    fi
  '';
in
{
  activation.setupNixAccessToken = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${setup}
  '';
}
