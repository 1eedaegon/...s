# 기본 shell 설정을 위한 shellHook
{ pkgs, system }:
''
  eval "$(starship init bash)"
  if [ ! -f ~/.config/starship.toml ]; then
    starship preset nerd-font-symbols -o ~/.config/starship.toml
  fi
  alias l="ls -lah"
  
  # Nix alias
  alias nd="nix develop"
  alias np="nix profile"
  alias ncg="nix-collect-garbage"

  # Kube alias
  alias k="kubectl"
  echo -e "font check(branch): \uf126 \ue0a0 \uf121"

''
