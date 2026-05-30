# home/claude-code.nix
# Claude Code installation and everything-claude-code configuration
{ config, lib, pkgs, everything-claude-code, gstack, ... }:

let
  # Shared skill-merge helper (open Agent Skills standard)
  mergeSkills = import ./skills-merge.nix { inherit pkgs everything-claude-code gstack; };

  # Setup everything-claude-code configs
  setupClaudeConfigs = pkgs.writeShellScript "setup-claude-configs" ''
    CLAUDE_DIR="$HOME/.claude"
    REPO_DIR="${everything-claude-code}"

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

    # skills/: merge ECC + gstack skills into ~/.claude/skills via shared helper
    ${mergeSkills} "$CLAUDE_DIR/skills"

    echo "Claude Code configs setup complete"
  '';

in
{
  # Packages needed for Claude Code (claude-code pinned via nixpkgs/flake.lock)
  packages = with pkgs; [
    claude-code
    curl
    jq
  ];

  # Home-manager activation script
  activation = {
    setupClaudeConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${setupClaudeConfigs}
    '';
  };

  # claude-code is pinned via nixpkgs (flake.lock); disable the self-updater so it
  # doesn't fight the read-only Nix store. Bump the version with `just update`.
  sessionVariables = {
    DISABLE_AUTOUPDATER = "1";
  };

  # Shell aliases
  aliases = {
    cc = "claude";
  };
}
