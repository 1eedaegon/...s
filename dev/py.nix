{ pkgs, mkEnv }:

mkEnv {
  name = "py";
  pkgList = with pkgs; [
    python3
    python3Packages.pip
    python3Packages.ipython
    python3Packages.black
    python3Packages.pylint
    python3Packages.pytest
    python3Packages.virtualenv
    uv
  ];
  shell = ''
    echo "Python Development Environment"
    
    # virtualenv 설정
    if [ ! -d ".venv" ]; then
      echo "Creating virtual environment..."
      python -m venv .venv
    fi
    
    # 환경 변수 설정
    export PYTHONPATH="$PWD:$PYTHONPATH"
    
    # 유용한 alias
    alias py='python'
    alias ipy='ipython'
    alias pytest='python -m pytest'
    
    python --version
    pip --version
    uv version
  '';
}