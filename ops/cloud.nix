{ pkgs, mkEnv, environments }:

mkEnv {
  name = "cloud";
  pkgList = with pkgs; [
    # 추가 클라우드 전용 패키지
    docker-compose
    docker-client
    awscli2
    eksctl
    krew
  ];
  shell = ''
    echo "클라우드 운영 환경 (AWS + Kubernetes)"
    echo "클라우드 및 컨테이너 관련 도구가 통합되어 있습니다."
  '';
  combine = [
    environments.aws
    environments.k8s
  ];
}