# ...s(3dots)

> Just

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

minimal

`❯ nix develop github:1eedaegon/...s#mini`

User globally

`❯ nix profile install github:1eedaegon/...s`

## Uninstall

1. Clean devshells

`❯ nix-collect-garbage`

2. Clean profile
