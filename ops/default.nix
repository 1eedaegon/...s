{ pkgs, mkEnv, baseEnv }:

let
  # 개별 운영 환경 모듈
  environments = {
    # 기본 운영 환경
    aws = import ./aws.nix { inherit pkgs mkEnv; };
    k8s = import ./k8s.nix { inherit pkgs mkEnv; };
    monitoring = import ./monitoring.nix { inherit pkgs mkEnv; };
    
    # 조합 환경들 - 이제 같은 수준에 평면적으로 배치
    cloud = import ./cloud.nix { 
      inherit pkgs mkEnv; 
      environments = self; # 재귀적 참조를 위한 self 전달
    };
  };
  
  # 재귀적 참조를 위한 self 정의
  self = environments;
in
  # 모든 환경 반환
  environments