# 기본 shll 설정을 위한 shellHook
{ pkgs }:
''
  eval "$(starship init bash)"
  alias l="ls -lah"
  echo -e "font check(branch): \ue0a0 \uf126 \ue0a0 \uf121"

''
