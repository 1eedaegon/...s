# home/shared-agents-md.nix
# Generates a single AGENTS.md from everything-claude-code rules/common/*.md.
# Shared by every tool that reads the open AGENTS.md convention (Codex,
# OpenCode, ...) but has no subagent registry of its own, so Claude-specific
# rule files are excluded and a platform note explains how to read the rest.
{ pkgs, everything-claude-code }:

let
  # agents.md is a Claude-Code subagent registry; tools without subagents
  # have no use for it and would hunt for nonexistent "rust-reviewer" etc.
  excludeRules = [ "agents.md" ];
in
pkgs.runCommand "shared-agents-md" { } ''
  {
    echo "# Agent Instructions (shared rules)"
    echo
    echo "> Generated from everything-claude-code rules/common via Nix. Do not edit by hand."
    echo
    echo "> Platform note: named agents below (planner, code-reviewer, rust-reviewer,"
    echo "> security-reviewer, …) are Claude Code subagents. This tool has no"
    echo "> subagents — when a rule says \"use the X agent\", apply that role's"
    echo "> criteria inline. Do not look for an X skill or file."
    for f in ${everything-claude-code}/rules/common/*.md; do
      case " ${pkgs.lib.concatStringsSep " " excludeRules} " in
        *" $(basename "$f") "*) continue ;;
      esac
      echo
      echo "<!-- source: rules/common/$(basename "$f") -->"
      cat "$f"
      echo
    done
  } > "$out"
''
