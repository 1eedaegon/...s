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
  # Lossless line-based normalizer: only rewrites single-line `description:`
  # values (quote colons, truncate >1024); every other byte is preserved.
  # Lossless line-based normalizer: only rewrites single-line `description:`
  # values (quote colons, truncate over the limit); every other byte preserved.
  maxDescLen = 1024; # Codex's hard frontmatter description limit
  patcher = pkgs.writeText "patch-skill.py" ''
    import sys, re

    MAX_DESC = ${toString maxDescLen}
    TARGET = MAX_DESC - 4         # truncate values longer than this (quote headroom)
    ELLIPSIS = '...'
    FENCE = '---'
    BLOCK_MARKERS = ('>', '>-', '|', '|-', '>+', '|+')

    content = open(sys.argv[1], encoding='utf-8').read()
    lines = content.split('\n')
    if not lines or lines[0].strip() != FENCE:
        sys.stdout.write(content); sys.exit(0)
    close = next((i for i in range(1, len(lines)) if lines[i].strip() == FENCE), None)
    if close is None:
        sys.stdout.write(content); sys.exit(0)

    for i in range(1, close):
        m = re.match(r'^(description:[ \t]*)(.*)$', lines[i])
        if not m:
            continue
        prefix, v = m.group(1), m.group(2).strip()
        if not v or v in BLOCK_MARKERS:
            continue
        if i + 1 < close and re.match(r'^[ \t]+\S', lines[i + 1]):
            continue  # multi-line plain scalar — already valid
        if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
            if len(v) <= TARGET + 2:
                continue
            v = v[1:-1]
        if len(v) > TARGET:
            v = v[:TARGET - len(ELLIPSIS)] + ELLIPSIS
        lines[i] = prefix + '"' + v.replace('\\', '\\\\').replace('"', '\\"') + '"'

    sys.stdout.write('\n'.join(lines))
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
