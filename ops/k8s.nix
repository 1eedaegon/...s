{ pkgs, mkEnv }:

mkEnv {
  name = "k8s";
  pkgList = with pkgs; [
    kubectl
    kubernetes-helm
    k9s
    kubectx
    kustomize
    stern
    argocd
  ];
  shell = ''
    echo "Kubernetes Operations Environment"
    
    # 유용한 alias
    alias k='kubectl'
    alias kctx='kubectx'
    alias kns='kubens'
    
    kubectl version --client
    helm version --short
  '';
}