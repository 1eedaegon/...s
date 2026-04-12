# home/claude-code.nix
# Claude Code installation and everything-claude-code configuration
{ config, lib, pkgs, everything-claude-code, gstack, ... }:

let
  # Claude Code native installer script
  installClaudeCode = pkgs.writeShellScript "install-claude-code" ''
    export PATH="${pkgs.curl}/bin:${pkgs.coreutils}/bin:${pkgs.bash}/bin:${pkgs.perl}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:$PATH"

    if ! command -v claude &> /dev/null; then
      echo "Installing Claude Code via native installer..."
      ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | ${pkgs.bash}/bin/bash
    else
      echo "Claude Code already installed: $(claude --version 2>/dev/null || echo 'unknown')"
    fi
  '';

  # Setup everything-claude-code configs
  setupClaudeConfigs = pkgs.writeShellScript "setup-claude-configs" ''
    CLAUDE_DIR="$HOME/.claude"
    REPO_DIR="${everything-claude-code}"
    GSTACK_DIR="${gstack}"

    mkdir -p "$CLAUDE_DIR"

    # Link directories if they don't exist or are symlinks (can be updated)
    link_dir() {
      local name="$1"
      local target="$CLAUDE_DIR/$name"
      local source="$REPO_DIR/$name"

      if [ -d "$source" ]; then
        if [ -L "$target" ]; then
          rm "$target"
        elif [ -d "$target" ]; then
          echo "Skipping $name: directory exists (backup or remove manually)"
          return
        fi
        ln -sf "$source" "$target"
        echo "Linked $name -> $source"
      fi
    }

    link_dir "agents"
    link_dir "commands"
    link_dir "contexts"
    link_dir "hooks"
    link_dir "mcp-configs"
    link_dir "plugins"
    link_dir "rules"

    # skills/: merge ECC skills + gstack skills (prefixed "gstack-") into a real dir.
    # gstack top-level skill dirs with SKILL.md collide with ECC entries
    # (checkpoint, learn, benchmark), so we prefix all gstack entries.
    SKILLS_TARGET="$CLAUDE_DIR/skills"
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

    echo "Claude Code configs setup complete"
  '';

in
{
  # Packages needed for Claude Code
  packages = with pkgs; [
    curl
    jq
  ];

  # Home-manager activation script
  activation = {
    installClaudeCode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${installClaudeCode}
    '';

    setupClaudeConfigs = lib.hm.dag.entryAfter [ "installClaudeCode" ] ''
      run ${setupClaudeConfigs}
    '';
  };

  # Shell aliases
  aliases = {
    cc = "claude";
    ccu = "claude update";
  };
}
