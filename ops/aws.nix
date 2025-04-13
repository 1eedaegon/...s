{ pkgs, mkEnv }:

mkEnv {
  name = "aws";
  pkgList = with pkgs; [
    awscli2
    ssm-session-manager-plugin
    terraform
    terragrunt
    python3
    python3Packages.boto3
    jq
  ];
  shell = ''
    echo "AWS Operations Environment"
    
    # AWS 설정
    export AWS_PAGER=""
    
    # 유용한 alias
    alias tf='terraform'
    alias tg='terragrunt'
    
    aws --version
    terraform --version
  '';
}