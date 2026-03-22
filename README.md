# ...s(3dots)

[![Nix CI](https://github.com/1eedaegon/...s/actions/workflows/nix-ci.yml/badge.svg)](https://github.com/1eedaegon/...s/actions/workflows/nix-ci.yml)
[![NixOS](https://img.shields.io/badge/NixOS-24.05-blue.svg?logo=nixos)](https://nixos.org)
[![Flakes](https://img.shields.io/badge/Nix-Flakes-informational.svg?logo=nixos)](https://nixos.wiki/wiki/Flakes)
[![License](https://img.shields.io/github/license/1eedaegon/...s)](LICENSE)

> Just build own dotfiles

## Module preview
```
┌────────────────────────────────────────────────────────────┐
│                     User Commands                          │
└────────────────────────────────────────────────────────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │   flake.nix     │
                   └─────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
    ╔══════════════════════════════════════════════╗
    ║           Module Loading & Composition       ║
    ╠═══════════════╦═══════════════╦══════════════╣
    ║ installations ║  executions   ║configurations║
    ╠═══════════════╬═══════════════╬══════════════╣
    ║   Packages    ║   Shell Cmds  ║   Settings   ║
    ║               ║   Aliases     ║   Env Vars   ║
    ║   Programs    ║   Functions   ║   Configs    ║
    ║               ║               ║              ║
    ╚═══════════════╩═══════════════╩══════════════╝
```

## TL;DR

```bash
# Install Nix + apply everything in one shot
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
nix run github:1eedaegon/...s --impure

# Or just grab a devShell (no install, no fork needed)
nix develop github:1eedaegon/...s#rust
```

## Quick Start

### 1. Install Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 2. Set your identity

Fork this repo, then edit `flake.nix` — replace the `userRegistry` with your own:

```nix
userRegistry = {
  # Remove existing entries and add yours:
  "your-username" = { serviceUsername = "your-service-name"; email = "you@example.com"; };
};
```

This single table drives all configurations (home-manager, NixOS, nix-darwin, Doom Emacs).
No other files need user-specific changes.

### 3. (Optional) Customize Doom Emacs

Edit `doom.d/init.el` to select modules, `doom.d/config.el` for settings, `doom.d/packages.el` for extra packages. User identity is auto-injected from `userRegistry`.

### 4. Apply

```bash
# macOS (nix-darwin + home-manager)
nix run . --impure

# Linux (home-manager only)
nix run . --impure
```

## DevShells (no install required)

Use language-specific development environments without installing anything globally:

```bash
nix develop github:1eedaegon/...s          # default
nix develop github:1eedaegon/...s#rust     # rust + sccache + trunk (wasm)
nix develop github:1eedaegon/...s#go       # go + gopls + protobuf
nix develop github:1eedaegon/...s#py       # python + uv + ruff
nix develop github:1eedaegon/...s#node     # node + pnpm + turbo
nix develop github:1eedaegon/...s#java     # jdk + maven + gradle + mvnd
```

Or in a project directory with direnv:

```bash
echo 'use flake github:1eedaegon/...s#rust' > .envrc
direnv allow
```

## What's included

### Common packages (all platforms)

| Category | Packages |
|----------|----------|
| Cloud CLI | awscli2, google-cloud-sdk, azure-cli |
| Cloudflare | cloudflared, wrangler, flarectl, cf-terraforming |
| Kubernetes | kubectl, helm, k9s, kubectx, stern, kustomize |
| Editor | neovim, Doom Emacs (nix-managed) |
| Build cache | ccache (C/C++) |
| IaC | opentofu |
| VPN | tailscale |
| Formal verification | TLA+, z3, Isabelle, cvc5 |

### Per-language build cache

| Language | Tool | Location |
|----------|------|----------|
| Rust | sccache | devShell `#rust` |
| Node.js | turbo (Turborepo) | devShell `#node` |
| Java | mvnd (Maven Daemon) | devShell `#java` |
| C/C++ | ccache | common (all shells) |
| Go | built-in `$GOCACHE` | n/a |

### Platform support

| Platform | devShell | home-manager | nix-darwin | NixOS |
|----------|----------|-------------|------------|-------|
| aarch64-darwin (Apple Silicon) | O | O | O | - |
| x86_64-darwin | O | O | O | - |
| x86_64-linux | O | O | - | O |
| aarch64-linux | O | O | - | O |

## Uninstall

```bash
# 1. Clean devshells
nix-collect-garbage

# 2. Clean home-manager
nix run home-manager -- uninstall

# 3. Remove all profiles
nix profile remove --all

# 4. Or remove specific profile
nix profile list
nix profile remove [NAME]
```
