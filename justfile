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
    token="$(gh auth token 2>/dev/null || true)"
    if [[ -n "$token" ]]; then
      export NIX_CONFIG="access-tokens = github.com=$token"
    else
      unset NIX_CONFIG
    fi
    if [[ "$(uname)" == "Darwin" ]]; then
      target='.#darwinConfigurations.default.system'
    else
      target='.#homeConfigurations.default.activationPackage'
    fi
    nix build "$target" --impure \
      || { echo "build failed → reverting flake.lock"; git checkout flake.lock; exit 1; }

# Update all flake inputs (nixpkgs, shared skills, toolchains, ...) and apply
update:
    #!/usr/bin/env bash
    set -euo pipefail
    token="$(gh auth token 2>/dev/null || true)"
    if [[ -n "$token" ]]; then
      export NIX_CONFIG="access-tokens = github.com=$token"
    else
      unset NIX_CONFIG
    fi
    echo "Updating flake inputs..."
    nix flake update
    just _build-or-revert
    echo "Build OK — applying configuration..."
    nix run .#default

# Update agent-related inputs and apply
update-agents:
    #!/usr/bin/env bash
    set -euo pipefail
    # Codex is pinned separately in lib/overlays.nix so it can move
    # independently of nixpkgs on x86_64-darwin.
    token="$(gh auth token 2>/dev/null || true)"
    if [[ -n "$token" ]]; then
      export NIX_CONFIG="access-tokens = github.com=$token"
    else
      unset NIX_CONFIG
    fi
    inputs=(everything-claude-code gstack)
    if [[ "$(uname)" == "Darwin" && "$(uname -m)" == "x86_64" ]]; then
      echo "Skipping nixpkgs update: current nixos-unstable has dropped x86_64-darwin support."
      echo "Updating ECC + gstack..."
    else
      inputs=(nixpkgs "${inputs[@]}")
      echo "Updating nixpkgs (claude-code) + ECC + gstack..."
    fi
    nix flake update "${inputs[@]}"
    just _build-or-revert
    echo "Build OK — applying configuration..."
    nix run .#default

# Show this help
help:
    @just --list
