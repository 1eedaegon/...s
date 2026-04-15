# packages/combinations/infra.nix
# Go + Node.js + IaC tooling (terraform/opentofu side-by-side, helm, nats cli, vault)
{ pkgs }:

let
  go = import ../toolchains/go.nix { inherit pkgs; };
  node = import ../toolchains/node.nix { inherit pkgs; };
in
{
  packages = go.packages ++ node.packages ++ (with pkgs; [
    # IaC (terraform + opentofu side-by-side)
    terraform
    opentofu
    terragrunt
    vault
    ansible
    packer
    pulumi

    # Kubernetes
    kubectl
    (wrapHelm kubernetes-helm {
      plugins = with kubernetes-helmPlugins; [
        helm-diff # required by helmfile
        helm-secrets # sops-encrypted values
        helm-git # git:// chart sources
        helm-s3 # s3 chart repos
        helm-unittest # chart unit tests
      ];
    })
    helmfile
    k9s
    kind
    minikube
    stern
    kubectx
    kustomize

    # Messaging / Queue CLIs
    natscli
    kcat # kafka producer/consumer CLI (formerly kafkacat)

    # Database CLIs
    postgresql # psql
    pgcli # psql with autocomplete
    mariadb # mysql client (mysql-client replaced by mariadb.client upstream)
    mycli # mysql with autocomplete
    sqlite
    litecli # sqlite with autocomplete
    redis # redis-cli
    mongosh # mongodb shell
  ]);
}
