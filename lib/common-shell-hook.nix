# 기본 shell 설정을 위한 shellHook
{ pkgs, system }:
''
  eval "$(starship init bash)"
  if [ ! -f ~/.config/starship.toml ]; then
    starship preset nerd-font-symbols -o ~/.config/starship.toml
  fi
  alias l="ls -lah"
  alias nd="nix devleop"
  alias k="kubectl"
  echo -e "font check(branch): \uf126 \ue0a0 \uf121"

''
