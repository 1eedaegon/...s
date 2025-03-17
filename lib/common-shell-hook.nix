# 기본 shll 설정을 위한 shellHook
{ pkgs ? import  {} }:
''
  eval "$(starship init bash)"
  alias l="ls -lah"
''
