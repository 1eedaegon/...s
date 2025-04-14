# 기본 shll 설정을 위한 shellHook
{ pkgs }:
''
  eval "$(starship init bash)"
  if [ ! -f ~/.config/starship.toml ]; then
    starship preset pastel-powerline -o ~/.config/starship.toml
    
  fi
  alias l="ls -lah"
  echo -e "font check(branch): \uf126 \ue0a0 \uf121"

''
