{ pkgs, mkEnv }:

mkEnv {
  name = "monitoring";
  pkgList = with pkgs; [
    grafana-loki
    prometheus
    alertmanager
    elasticsearch
    kibana
    telegraf
    influxdb
    jq
    httpie
  ];
  shell = ''
    echo "Monitoring Operations Environment"
    
    # 유용한 alias
    alias http='httpie'
    
    # 기본 포트 설정
    export PROMETHEUS_PORT=9090
    export GRAFANA_PORT=3000
    export LOKI_PORT=3100
    
    echo "Monitoring tools are available"
    jq --version
  '';
}
