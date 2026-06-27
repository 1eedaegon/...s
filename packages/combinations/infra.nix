# packages/combinations/infra.nix
# Go + Node.js + IaC tooling (terraform/opentofu side-by-side, helm, nats cli, vault)
{ pkgs }:

let
  inherit (pkgs) lib stdenv;
  go = import ../toolchains/go.nix { inherit pkgs; };
  node = import ../toolchains/node.nix { inherit pkgs; };
  security = import ./security.nix { inherit pkgs; };

  # mycli pulls sqlglot → duckdb → pyarrow → arrow-cpp, which nixpkgs marks
  # broken on x86_64-darwin only (isDarwin && isx86_64). Drop the autocomplete
  # wrapper there; the plain `mariadb` mysql client below still ships.
  isBrokenArrowPlatform = stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isx86_64;
in
{
  # security.iacSubset: IaC/cloud-relevant scanners only (Go/Rust, aarch64-clean).
  # The full security suite (incl. python SAST/pentest) lives in the `security` shell.
  packages = go.packages ++ node.packages ++ security.iacSubset ++ (with pkgs; [
    # IaC (terraform + opentofu side-by-side)
    terraform
    opentofu
    terragrunt
    vault-bin # prebuilt binary; source `vault` is uncached on darwin → multi-GB Go build
    ansible
    packer
    pulumi

    # Kubernetes (kubectl/k9s/kubectx/stern/kustomize come from common.nix;
    # kind comes from go toolchain)
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
    minikube

    # Messaging / Queue CLIs
    natscli
    kcat # kafka producer/consumer CLI (formerly kafkacat)

    # Database CLIs
    postgresql # psql
    pgcli # psql with autocomplete
    mariadb # mysql client (mysql-client replaced by mariadb.client upstream)
    sqlite
    litecli # sqlite with autocomplete
    redis # redis-cli
    mongosh # mongodb shell
  ]) ++ lib.optionals (!isBrokenArrowPlatform) (with pkgs; [
    mycli # mysql with autocomplete (skipped on x86_64-darwin; see above)
  ]);
}
