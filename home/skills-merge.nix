# home/skills-merge.nix
# Shared skill-merge script for the open Agent Skills standard (SKILL.md).
# Links ECC + gstack skills into a target directory via per-entry symlinks so
# the same source feeds multiple agents (Claude Code: ~/.claude/skills,
# Codex + cross-vendor: ~/.agents/skills).
#
# Usage in an activation script: ${mergeSkills} "<target-skills-dir>"
{ pkgs, everything-claude-code, gstack }:

pkgs.writeShellScript "merge-skills" ''
  REPO_DIR="${everything-claude-code}"
  GSTACK_DIR="${gstack}"
  SKILLS_TARGET="$1"

  if [ -z "$SKILLS_TARGET" ]; then
    echo "merge-skills: missing target dir argument" >&2
    exit 1
  fi

  # Replace a legacy whole-dir symlink with a real directory
  if [ -L "$SKILLS_TARGET" ]; then
    rm "$SKILLS_TARGET"
  fi
  mkdir -p "$SKILLS_TARGET"

  # ECC skills: per-entry symlink (idempotent, allows coexistence)
  if [ -d "$REPO_DIR/skills" ]; then
    for src in "$REPO_DIR/skills"/*; do
      [ -e "$src" ] || continue
      name="$(basename "$src")"
      dst="$SKILLS_TARGET/$name"
      if [ -L "$dst" ] || [ ! -e "$dst" ]; then
        ln -sfn "$src" "$dst"
      fi
    done
  fi

  # gstack skills: only subdirs containing SKILL.md, prefixed "gstack-"
  # (gstack top-level dirs collide with ECC entries like checkpoint/learn/benchmark)
  if [ -d "$GSTACK_DIR" ]; then
    for src in "$GSTACK_DIR"/*/; do
      src="''${src%/}"
      [ -f "$src/SKILL.md" ] || continue
      name="gstack-$(basename "$src")"
      dst="$SKILLS_TARGET/$name"
      if [ -L "$dst" ] || [ ! -e "$dst" ]; then
        ln -sfn "$src" "$dst"
      fi
    done
    # Also expose gstack root for reference (ETHOS.md, README, etc.)
    if [ -L "$SKILLS_TARGET/gstack" ] || [ ! -e "$SKILLS_TARGET/gstack" ]; then
      ln -sfn "$GSTACK_DIR" "$SKILLS_TARGET/gstack"
    fi
  fi

  echo "Skills merged into $SKILLS_TARGET"
''
