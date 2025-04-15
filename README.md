# ...s(3dots)

> Just build own dotfiles

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

User globally

`❯ nix profile install github:1eedaegon/...s`

## Uninstall

1. Clean devshells

`❯ nix-collect-garbage`

2. Clean profile

`> nix profie remove --all`

3. Search profile

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

Remove specific profile

`❯ nix profile remove [NAME]`

```bash

❯ nix profile remove git+file:///Users/leedaegon/workspace/...s#packages.aarch64-darwin.default

```
