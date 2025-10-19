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


## Install Nix

Install determinate systems nix

Use `install-determinate-nix.sh`

Or

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

- Download nix tar file & Make temp dir
- Make dir /nix
- Move to /nix
- Creating 32 build-user-group [Build user group?](https://nixos.org/manual/nix/stable/installation/multi-user#setting-up-the-build-users)
- Creating default nix profile
- Set flag experimental-feature to /etc/nix/nix.conf & Some others
- Setting shell profile
- Regist nix daemon to systemd
- Clean temp dir

## Make subshell

default

`❯ nix develop github:1eedaegon/...s`

language specific(e.g rust)

`❯ nix develop github:1eedaegon/...s#rust`

## Global Settings using home-manager

Normally

`> nix run home-manager -- switch --flake github:1eedaegon/...s#[user].[platform]`

With Backup

`> nix run home-manager -- switch --flake github:1eedaegon/...s#[user].[platform] -b [backup name]`

e.g) `nix run home-manager -- switch --flake github:1eedaegon/...s#default.aarch64-darwin -b backup`
```bash
lrwxr-xr-x leedaegon staff  70 B  Thu Aug 14 23:04:33 2025 .zshenv ⇒ /nix/store/zpmjydbkq6p6hrz35380nlirs19kn0fl-home-manager-files/.zshenv
.rw-r--r-- leedaegon staff  21 B  Thu May 30 10:54:40 2024 .zshenv.backup
lrwxr-xr-x leedaegon staff  69 B  Thu Aug 14 23:04:33 2025 .zshrc ⇒ /nix/store/zpmjydbkq6p6hrz35380nlirs19kn0fl-home-manager-files/.zshrc
```


## Uninstall

1. Clean devshells

`❯ nix-collect-garbage`

2. Clean home-manager

`❯ nix run home-manager -- uninstall`

3. Clean profile

`> nix profie remove --all`

4. Search profile

`❯ nix profile list`

```bash
❯ nix profile list
Name:               git+file:///Users/leedaegon/workspace/...s#packages.aarch64-darwin.default
Flake attribute:    packages.aarch64-darwin.default
Original flake URL: git+file:///Users/leedaegon/workspace/...s
Locked flake URL:   git+file:///Users/leedaegon/workspace/...s
Store paths:        /nix/store/ggcd2k0fxjnyfc0qvc3s9bnqdyshz7rx-default
...
# And other profiles...
```

5. Remove specific profile

`❯ nix profile remove [NAME]`

```bash

❯ nix profile remove git+file:///Users/leedaegon/workspace/...s#packages.aarch64-darwin.default

```

