# Format all Nix files
format:
    @echo "Formatting Nix files..."
    @nix run nixpkgs#nixpkgs-fmt -- .

# Run formatter in check mode
format-check:
    @echo "Checking Nix files formatting..."
    @nix run nixpkgs#nixpkgs-fmt -- --check .

# Authenticated GitHub access for nix (avoids api.github.com 60/h rate-limit 403).
# Token is exported via NIX_CONFIG (read fresh from gh, never stored in the repo).
# NIX_CONFIG keeps the token OUT of the process argv, so `ps`/`pgrep` and shell
# logs never expose it — unlike `--option access-tokens "$(gh auth token)"`, which
# puts the secret on the command line for any local user to read.
# (nix has no `access-tokens-file` option; NIX_CONFIG is the off-argv equivalent.)

# Build the system; on failure revert flake.lock so a broken bump never half-applies.
# Target matches what `nix run .#default` (apps.default) applies on this host:
#   macOS → darwinConfigurations.default.system
#   Linux → homeConfigurations.default.activationPackage  (e.g. aarch64 Jetson)
_build-or-revert:
    #!/usr/bin/env bash
    set -euo pipefail
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null)"
    if [[ "$(uname)" == "Darwin" ]]; then
      target='.#darwinConfigurations.default.system'
    else
      target='.#homeConfigurations.default.activationPackage'
    fi
    nix build "$target" --impure \
      || { echo "build failed → reverting flake.lock"; git checkout flake.lock; exit 1; }

# Update all flake inputs (codex, claude-code via nixpkgs, ECC, gstack, ...) and apply
update:
    #!/usr/bin/env bash
    set -euo pipefail
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null)"
    echo "Updating flake inputs..."
    nix flake update
    just _build-or-revert
    echo "Build OK — applying configuration..."
    nix run .#default

# Update only the agent toolchain inputs (codex/claude-code source + shared skills) and apply
update-agents:
    #!/usr/bin/env bash
    set -euo pipefail
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null)"
    echo "Updating nixpkgs (codex, claude-code) + ECC + gstack..."
    nix flake update nixpkgs everything-claude-code gstack
    just _build-or-revert
    echo "Build OK — applying configuration..."
    nix run .#default

# Show this help
help:
    @just --list
