# installations/claude-code.nix
# Claude Code installation and everything-claude-code configuration
{ config, lib, pkgs, everything-claude-code, ... }:

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
    link_dir "skills"

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
