# home/opencode.nix
# OpenCode CLI install + skill/rules sharing via the open Agent Skills and
# AGENTS.md standards (same standards OpenCode itself helped popularize).
{ config, lib, pkgs, everything-claude-code, gstack, ... }:

let
  # Shared skill-merge helper (same source as Claude Code and Codex)
  mergeSkills = import ./skills-merge.nix { inherit pkgs everything-claude-code gstack; };

  # Same generated rules file Codex uses (see home/shared-agents-md.nix) —
  # single source, no drift between tools.
  sharedAgentsMd = import ./shared-agents-md.nix { inherit pkgs everything-claude-code; };

  setupOpencode = pkgs.writeShellScript "setup-opencode" ''
    # OpenCode's own global skills dir (it also falls back to ~/.claude/skills
    # for Claude Code compat, but populating its native dir directly doesn't
    # depend on that fallback staying supported across OpenCode versions).
    ${mergeSkills} "$HOME/.config/opencode/skills" agents

    # Global instructions: OpenCode reads ~/.config/opencode/AGENTS.md.
    mkdir -p "$HOME/.config/opencode"
    target="$HOME/.config/opencode/AGENTS.md"
    if [ -L "$target" ] || [ ! -e "$target" ]; then
      ln -sfn "${sharedAgentsMd}" "$target"
      echo "Linked OpenCode AGENTS.md (shared rules)"
    else
      echo "Skipping OpenCode AGENTS.md: real file exists (remove it to manage via Nix)"
    fi

    echo "OpenCode configs setup complete"
  '';
in
{
  # OpenCode CLI, pinned to the latest upstream release via lib/overlays.nix
  # (nixpkgs-26.05-darwin, what x86_64-darwin rides, lags several versions
  # behind upstream — same reason codex/grok-build are overlay-pinned).
  packages = with pkgs; [ opencode ];

  activation = {
    setupOpencode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${setupOpencode}
    '';
  };

  aliases = {
    oc = "opencode";
  };
}
