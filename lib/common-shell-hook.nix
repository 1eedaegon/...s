{ pkgs ? import  {} }:

{
  # 기본 shll 설정을 위한 shellHook
  starshipHook = ''
    eval "$(starship init bash)"

  '';

  # nodeAndGitHook = ''
  #   export EDITOR=vim
  #   export PATH=$PATH:$PWD/node_modules/.bin

  #   git config --local core.editor vim
  #   echo "Current dir: $(pwd)"
  # '';
  
}