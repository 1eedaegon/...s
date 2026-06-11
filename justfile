# Format all Nix files
format:
    @echo "Formatting Nix files..."
    @nix run nixpkgs#nixpkgs-fmt -- .

# Run formatter in check mode
format-check:
    @echo "Checking Nix files formatting..."
    @nix run nixpkgs#nixpkgs-fmt -- --check .

# Authenticated GitHub access for nix (avoids api.github.com 60/h rate-limit 403).
# Token is read fresh from gh each run — never stored in the repo.
_gh := 'github.com=$(gh auth token 2>/dev/null)'

# Build the system; on failure revert flake.lock so a broken bump never half-applies
_build-or-revert:
    nix build .#darwinConfigurations.default.system --impure --option access-tokens "{{_gh}}" \
      || { echo "build failed → reverting flake.lock"; git checkout flake.lock; exit 1; }

# Update all flake inputs (codex, claude-code via nixpkgs, ECC, gstack, ...) and apply
update:
    @echo "Updating flake inputs..."
    nix flake update --option access-tokens "{{_gh}}"
    @just _build-or-revert
    @echo "Build OK — applying configuration..."
    nix run .#default

# Update only the agent toolchain inputs (codex/claude-code source + shared skills) and apply
update-agents:
    @echo "Updating nixpkgs (codex, claude-code) + ECC + gstack..."
    nix flake update nixpkgs everything-claude-code gstack --option access-tokens "{{_gh}}"
    @just _build-or-revert
    @echo "Build OK — applying configuration..."
    nix run .#default

# Show this help
help:
    @just --list
