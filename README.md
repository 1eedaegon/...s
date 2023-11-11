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

Search profile

`❯ nix profile list`

```bash
❯ nix profile list
Index:              0
Flake attribute:    packages.x86_64-linux.mini
Original flake URL: github:1eedaegon/...s
Locked flake URL:   github:1eedaegon/...s/08d4e10ad40ad6de1ae0a3688b1cb7464be78933
Store paths:        /nix/store/ijc616y513f3zz4dv42mfa8kba3h9ad1-nix-shell
...
# And other profiles...
```

Remove specific profile

`❯ nix profile remove [INDEX]`

```bash

❯ nix profile remove 4
warning: '4' is not a valid index
warning: Use 'nix profile list' to see the current profile.
warning: not including '/nix/store/4kiyp2azbmdalklpa4w2wi7mzwxbc251-nix-shell' in the user environment because it's not a directory
warning: not including '/nix/store/ijc616y513f3zz4dv42mfa8kba3h9ad1-nix-shell' in the user environment because it's not a directory
```
