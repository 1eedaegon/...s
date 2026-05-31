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

Doom Emacs is installed via `nix-doom-emacs-unstraightened`. After `nix run .`:

- `~/.doom.d/` — Doom config (init.el, config.el, packages.el)
- Knowledge base directory — auto-created with folder structure + `git init`

**Set your knowledge base directory** — edit one line in `~/.doom.d/config.el`:

```elisp
(defvar knowledge-base (expand-file-name "~/your-knowledge-base"))
```

All paths (org-roam, citar, agenda, journal) are derived from this single variable. The directory is auto-created on first `nix run .` with this structure:

```
~/your-knowledge-base/       ← git initialized
├── inbox/                   ← Quick capture
├── papers/reading/          ← Paper notes (org-roam)
├── concepts/                ← Concept notes (Zettelkasten)
├── pe/topics/               ← Study topic notes
├── pe/mock-answers/         ← Daily writing practice (org-journal)
├── review/                  ← Paper review notes
├── weekly/                  ← Weekly review logs
├── shutdown.org             ← Daily checklist (org-agenda)
├── references.bib           ← Zotero auto-export (citar)
└── .gitignore               ← PDF/binary excluded
```

Key shortcuts:

| Key | Action |
|-----|--------|
| `SPC n r f` | Find/create org-roam note |
| `SPC n r c` | Capture with template (paper/concept/review) |
| `SPC n r i` | Insert link to another note |
| `SPC n j` | Open today's journal |
| `SPC o a` | Open agenda (shutdown checklist) |
| `SPC @` | Search Zotero bibliography |
| `SPC g g` | Git (Magit) |

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

### Version-pinned toolchains

Append a `[lang][version]` postfix to pin an exact toolchain:

```bash
nix develop github:1eedaegon/...s#go1_25      # Go 1.25 (latest patch in nixpkgs)
nix develop github:1eedaegon/...s#go1_23_5    # Go 1.23.5 exactly (via GOTOOLCHAIN)
nix develop github:1eedaegon/...s#py3_13      # Python 3.13
nix develop github:1eedaegon/...s#node22      # Node.js 22
nix develop github:1eedaegon/...s#java21      # JDK 21
nix develop github:1eedaegon/...s#rust1_75_0  # Rust 1.75.0 exactly (rust-overlay)
```

- Minor pins (`go1_25`, `py3_13`, `node22`, `java21`) track the latest patch nixpkgs ships.
- Exact pins are curated in `lib/version-shells.nix` (`goExact`, `rustExact`). Go fetches any patch via `GOTOOLCHAIN`; Rust pins reproducibly via rust-overlay.
- Use `_`, not `.` — the `#` fragment splits on dots. Run `nix flake show` to list every generated shell.

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
| Cloudflare | cloudflared, flarectl, cf-terraforming |
| Kubernetes | kubectl, helm, k9s, kubectx, stern, kustomize |
| Editor | neovim, Doom Emacs (nix-managed) |
| AI agents | Claude Code + Codex (nix-pinned, shared skills/rules) |
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
