# packages/toolchains/go.nix
{ pkgs }:

{
  packages = with pkgs; [
    go
    gopls
    gotools
    go-outline
    gopkgs
    godef
    golint
    golangci-lint
    gotestsum
    protobuf
    protoc-gen-go
    protoc-gen-go-grpc
    kind
    kubectl
  ];
}
