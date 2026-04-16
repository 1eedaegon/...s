# packages/toolchains/go.nix
{ pkgs }:

{
  packages = with pkgs; [
    # Core
    go
    gopls
    gotools
    go-outline
    gopkgs
    godef

    # Lint / static analysis (for contributing to Terraform-style projects)
    golint
    golangci-lint
    revive
    go-tools # includes staticcheck
    errcheck
    gofumpt

    # Test tooling
    gotestsum # test runner with nice output
    richgo # colorized go test output
    ginkgo # BDD framework (k8s/operator-style)
    gotests # generate table-driven tests from source
    gocover-cobertura # coverage XML for CI
    delve # debugger

    # Code generation / refactor
    gomodifytags # struct tag editor
    impl # interface method stubs
    mockgen # gomock generator
    go-mockery # testify-style mocks

    # Release / ops
    goreleaser
    goreman

    # Protobuf
    protobuf
    protoc-gen-go
    protoc-gen-go-grpc

    # Cluster testing (kubectl/k9s come from common.nix)
    kind

    # Terraform (for contributing to terraform / provider plugins)
    terraform
    terraform-ls
    tflint
  ];
}
