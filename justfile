# Format all Nix files
format:
    @echo "Formatting Nix files..."
    @nix run nixpkgs#nixpkgs-fmt -- .

# Run formatter in check mode
format-check:
    @echo "Checking Nix files formatting..."
    @nix run nixpkgs#nixpkgs-fmt -- --check .

# Update all flake inputs (codex, claude-code via nixpkgs, ECC, gstack, ...) and apply
update:
    @echo "Updating flake inputs..."
    nix flake update
    @echo "Applying configuration..."
    nix run .#default

# Update only the agent toolchain inputs (codex/claude-code source + shared skills) and apply
update-agents:
    @echo "Updating nixpkgs (codex, claude-code) + ECC + gstack..."
    nix flake update nixpkgs everything-claude-code gstack
    @echo "Applying configuration..."
    nix run .#default

# Show this help
help:
    @just --list
