# home/skills-merge.nix
# Shared skill-merge script for the open Agent Skills standard (SKILL.md).
# Links ECC + gstack skills into a target directory via per-entry symlinks so
# the same source feeds multiple agents (Claude Code: ~/.claude/skills,
# Codex + cross-vendor: ~/.agents/skills).
#
# Codex enforces stricter SKILL.md frontmatter than Claude (unquoted colons in
# `description:` break its YAML parser; descriptions over 1024 chars are
# rejected). To avoid drift between agents we normalize SKILL.md at build time
# via a tiny Python patcher and symlink the patched mirrors instead of the
# upstream sources. Idempotent: well-formed skills pass through unchanged.
{ pkgs, everything-claude-code, gstack }:

let
  patcher = pkgs.writeText "patch-skill.py" ''
    import sys, re

    src = sys.argv[1]
    with open(src, 'r', encoding='utf-8') as f:
        content = f.read()

    parts = content.split('---', 2)
    if len(parts) < 3:
        sys.stdout.write(content)
        sys.exit(0)
    pre, fm, body = parts[0], parts[1], parts[2]

    out_lines = []
    for line in fm.splitlines():
        m = re.match(r'^(description:\s*)(.*)$', line)
        if not m:
            out_lines.append(line)
            continue
        prefix, val = m.group(1), m.group(2)
        v = val.strip()

        # Multi-line markers — don't touch.
        if v in ('>', '>-', '|', '|-', '>+', '|+', ""):
            out_lines.append(line)
            continue

        is_quoted = (
            (v.startswith('"') and v.endswith('"'))
            or (v.startswith("'") and v.endswith("'"))
        )
        if is_quoted:
            inner = v[1:-1]
            if len(line) <= 1024:
                out_lines.append(line)
                continue
            v = inner

        if len(v) > 1020:
            v = v[:1017] + '...'

        escaped = v.replace('\\', '\\\\').replace('"', '\\"')
        out_lines.append(f'{prefix}"{escaped}"')

    sys.stdout.write(pre + '---' + '\n'.join(out_lines) + '---' + body)
  '';

  # Mirror a skills root: for every subdir that contains SKILL.md, rebuild the
  # entry with a patched SKILL.md and per-file symlinks for everything else.
  # Non-skill entries (loose files, dirs without SKILL.md) pass through as
  # plain symlinks to preserve the current merge surface.
  mkPatchedMirror = name: skillsRoot: pkgs.runCommand "patched-${name}" { } ''
    mkdir -p $out
    for entry in ${skillsRoot}/*; do
      [ -e "$entry" ] || continue
      bn=$(basename "$entry")
      if [ -d "$entry" ] && [ -f "$entry/SKILL.md" ]; then
        mkdir -p "$out/$bn"
        for f in "$entry"/*; do
          [ -e "$f" ] || continue
          fbn=$(basename "$f")
          if [ "$fbn" = "SKILL.md" ]; then
            ${pkgs.python3}/bin/python3 ${patcher} "$f" > "$out/$bn/SKILL.md"
          else
            ln -sfn "$f" "$out/$bn/$fbn"
          fi
        done
      else
        ln -sfn "$entry" "$out/$bn"
      fi
    done
  '';

  patchedECC = mkPatchedMirror "ecc-skills" "${everything-claude-code}/skills";
  patchedGstack = mkPatchedMirror "gstack-skills" "${gstack}";
in
pkgs.writeShellScript "merge-skills" ''
  PATCHED_ECC="${patchedECC}"
  PATCHED_GSTACK="${patchedGstack}"
  # GSTACK="${gstack}"
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

  # ECC skills (from patched mirror): per-entry symlink (idempotent, allows coexistence)
  if [ -d "$PATCHED_ECC" ]; then
    for src in "$PATCHED_ECC"/*; do
      [ -e "$src" ] || continue
      name="$(basename "$src")"
      dst="$SKILLS_TARGET/$name"
      if [ -L "$dst" ] || [ ! -e "$dst" ]; then
        ln -sfn "$src" "$dst"
      fi
    done
  fi

  # gstack skills (from patched mirror): only subdirs containing SKILL.md, prefixed "gstack-"
  # (gstack top-level dirs collide with ECC entries like checkpoint/learn/benchmark)
  if [ -d "$PATCHED_GSTACK" ]; then
    for src in "$PATCHED_GSTACK"/*/; do
      src="''${src%/}"
      [ -f "$src/SKILL.md" ] || continue
      name="gstack-$(basename "$src")"
      dst="$SKILLS_TARGET/$name"
      if [ -L "$dst" ] || [ ! -e "$dst" ]; then
        ln -sfn "$src" "$dst"
      fi
    done
    # Expose the PATCHED gstack root for reference. It carries both patched
    # skill dirs and pass-through symlinks for non-skill entries (ETHOS.md,
    # README, etc.), so Codex re-scanning $SKILLS_TARGET/gstack/* won't hit
    # the unpatched upstream sources via this second path.
    if [ -L "$SKILLS_TARGET/gstack" ] || [ ! -e "$SKILLS_TARGET/gstack" ]; then
      ln -sfn "$PATCHED_GSTACK" "$SKILLS_TARGET/gstack"
    fi
  fi

  echo "Skills merged into $SKILLS_TARGET"
''
