{ pkgs, system }:

# 인자를 받는 함수로 설계
args:

let
  # Python 버전 설정 (기본값: "3")
  version = args.version or "3";
  
  # 버전에 따른 Python 패키지 선택
  pythonPkg = 
    if version == "3" || version == "latest" then pkgs.python3
    else if version == "311" then pkgs.python311
    else if version == "310" then pkgs.python310
    else if version == "39" then pkgs.python39
    else pkgs.python3; # 기본값
  
  # Python 환경 생성 (특정 버전에 호환되는 패키지들)
  pythonEnv = pythonPkg.withPackages (ps: with ps; [
    # 기본 패키지
    pip
    setuptools
    wheel
    virtualenv
    
    # 웹 개발
    flask
    requests
    
    # 데이터 처리
    numpy
    pandas
    
    # 개발 도구
    pytest
    black
    mypy
    
    # 버전에 따른 추가 패키지
    (if version == "311" || version == "3" || version == "latest" 
      then fastapi else flask)
  ]);
  
  # 버전과 무관한 유틸리티
  utilityPackages = with pkgs; [
    git
    gnumake
  ];
  
in {
  packages = [
    pythonEnv
  ] ++ utilityPackages;
  
  shellHook = ''
    echo "Python Enabled!"
    echo "Python $(python --version)"
    
    # 가상 환경 도우미 함수
    setup_venv() {
      echo "가상 환경 생성 중..."
      python -m venv .venv
      source .venv/bin/activate
      echo "가상 환경이 활성화되었습니다."
    }
    
    # 가상 환경 있는지 확인하고 활성화
    if [ -d ".venv" ]; then
      echo "기존 가상 환경 활성화..."
      source .venv/bin/activate
    else
      echo "가상 환경을 생성하려면 'setup_venv' 명령어를 실행하세요."
    fi
  '';
}