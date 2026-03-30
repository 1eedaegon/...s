# installations/devenv.nix
# Compatibility shim — delegates to packages/toolchains/
{ pkgs, system }:

let
  mkToolchain = file:
    if builtins.pathExists file
    then (import file { inherit pkgs; }) // { programs = (import file { inherit pkgs; }).programs or { }; }
    else { packages = [ ]; programs = { }; };
in
{
  environments = {
    rust = mkToolchain ../packages/toolchains/rust.nix;
    go = mkToolchain ../packages/toolchains/go.nix;
    py = mkToolchain ../packages/toolchains/py.nix;
    node = mkToolchain ../packages/toolchains/node.nix;
    java = mkToolchain ../packages/toolchains/java.nix;

    # These remain inline for now (not in devShells)
    docker = {
      packages = with pkgs; [ docker docker-compose dive lazydocker hadolint dockerfile-language-server-nodejs ];
      programs = { };
    };
    k8s = {
      packages = with pkgs; [ kubectl kubernetes-helm k9s kind minikube stern kubectx kustomize ];
      programs = { };
    };
    iac = {
      packages = with pkgs; [ terraform terragrunt ansible packer vault pulumi ];
      programs = { };
    };
    database = {
      packages = with pkgs; [ postgresql mysql sqlite redis mongosh pgcli mycli litecli ];
      programs = { };
    };

    default = {
      packages = [ ];
      programs = { };
    };
  };
}
