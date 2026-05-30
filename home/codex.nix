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
  sharedAgentsMd = pkgs.runCommand "codex-agents-md" { } ''
    {
      echo "# Agent Instructions (shared rules)"
      echo
      echo "> Generated from everything-claude-code rules/common via Nix. Do not edit by hand."
      for f in ${everything-claude-code}/rules/common/*.md; do
        echo
        echo "<!-- source: rules/common/$(basename "$f") -->"
        cat "$f"
        echo
      done
    } > "$out"
  '';

  setupCodex = pkgs.writeShellScript "setup-codex" ''
    # ~/.agents/skills: cross-vendor canonical location (Codex primary user dir)
    ${mergeSkills} "$HOME/.agents/skills"

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
  # Codex CLI from nixpkgs (reproducible; bump via flake.lock update)
  packages = with pkgs; [
    codex
  ];

  activation = {
    setupCodex = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${setupCodex}
    '';
  };

  aliases = {
    cx = "codex";
  };
}
