# home/codex.nix
# OpenAI Codex CLI install + skill sharing via the open Agent Skills standard.
#
# Skills use the SKILL.md format (Anthropic open standard, adopted by Codex and
# 30+ other tools). Codex reads ~/.agents/skills as its primary user-level skill
# dir — the cross-vendor "universal bus" — so we feed it the same ECC + gstack
# skills that Claude Code gets at ~/.claude/skills (see home/claude-code.nix).
{ config, lib, pkgs, everything-claude-code, gstack, ... }:

let
  # Shared skill-merge helper (same source as Claude Code)
  mergeSkills = import ./skills-merge.nix { inherit pkgs everything-claude-code gstack; };

  # Canonical source for always-follow rules = ECC rules/common/*.md (the same
  # content Claude loads from rules/). Codex has no rules-dir loader; it reads a
  # single ~/.codex/AGENTS.md globally, so we assemble those rule files into one
  # generated AGENTS.md. Single source -> no drift between Claude and Codex.
  # (Shared with OpenCode, which reads the same AGENTS.md convention — see
  # home/shared-agents-md.nix and home/opencode.nix.)
  sharedAgentsMd = import ./shared-agents-md.nix { inherit pkgs everything-claude-code; };

  setupCodex = pkgs.writeShellScript "setup-codex" ''
    # ~/.agents/skills: cross-vendor canonical location (Codex primary user dir).
    # "agents" also exposes Claude agents as skills (Codex has no subagents).
    ${mergeSkills} "$HOME/.agents/skills" agents

    # Global instructions: Codex reads ~/.codex/AGENTS.md. Link the generated,
    # rules-derived file. Skip only if a real (non-symlink) file already exists.
    mkdir -p "$HOME/.codex"
    target="$HOME/.codex/AGENTS.md"
    if [ -L "$target" ] || [ ! -e "$target" ]; then
      ln -sfn "${sharedAgentsMd}" "$target"
      echo "Linked Codex AGENTS.md (shared rules)"
    else
      echo "Skipping Codex AGENTS.md: real file exists (remove it to manage via Nix)"
    fi

    echo "Codex configs setup complete"
  '';
in
{
  # Agent CLIs from pkgs. lib/overlays.nix pins Codex to OpenAI's prebuilt
  # platform tarball and grok-build to the pinned fork input on every
  # platform (upstream nixpkgs lags x.ai stable).
  packages = with pkgs; [ codex ] ++ lib.optionals (pkgs ? grok-build) [ grok-build ];

  activation = {
    setupCodex = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${setupCodex}
    '';
  };

  aliases = {
    cx = "codex";
  } // lib.optionalAttrs (pkgs ? grok-build) {
    # Not "gb" — executions/default.nix already binds that to `git branch`,
    # and home.nix merges codex.aliases after it, so "gb" would silently
    # shadow the git alias on any host with grok-build installed.
    gk = "grok";
  };
}
