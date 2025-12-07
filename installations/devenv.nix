# installations/devenv.nix
# Development environment specific packages and configurations
{ pkgs, system }:

let
  # Import rust-overlay if needed
  rust-bin = pkgs.rust-bin or null;
in
{
  # Development environment specific packages
  environments = {
    # Rust development environment
    rust = {
      packages = with pkgs; [
        # Rust toolchain
        (if rust-bin != null then
          rust-bin.stable.latest.default.override
            {
              extensions = [
                "rust-src"
                "rust-analyzer"
                "clippy"
                "rustfmt"
              ];
            }
        else
          rustc
        )

        # Rust installer
        rustup

        # Rust development tools
        pkg-config
        openssl.dev
        libiconv
        cargo-edit
        cargo-watch
        cargo-expand
        lldb

        # Protocol buffers
        protobuf
      ];

      programs = {
        # Rust-specific program configurations can go here
      };
    };

    # Go development environment
    go = {
      packages = with pkgs; [
        # Go toolchain
        go

        # Go development tools
        gopls
        gotools
        go-outline
        gopkgs
        godef
        golint
        golangci-lint
        gotestsum

        # Protocol buffers
        protobuf
        protoc-gen-go
        protoc-gen-go-grpc

        # Kubernetes tools
        kind
        kubectl
      ];

      programs = {
        # Go-specific program configurations can go here
      };
    };

    # Python development environment
    py = {
      packages = with pkgs; [
        # Python package manager
        uv

        # Python interpreter
        python312

        # Python development tools
        ruff
        black
        mypy
        poetry

        # Jupyter
        jupyter

        # CUDA & MPI
        openmpi
        cudaPackages.cudatoolkit
        cudaPackages.cuda_nvcc
        cudaPackages.cuda_cudart
      ];

      programs = {
        # Python-specific program configurations can go here
      };
    };

    # Node.js development environment
    node = {
      packages = with pkgs; [
        # Node.js runtime
        nodejs_24

        # Package managers
        pnpm
        yarn

        # Development tools
        typescript
        typescript-language-server
        eslint
        prettier

        # Build tools
        webpack-cli
      ];

      programs = {
        # Node-specific program configurations can go here
      };
    };

    # Java development environment
    java = {
      packages = with pkgs; [
        # OpenJDK
        jdk
        # Build tools
        maven
        gradle
      ];

      programs = {
        # Java-specific program configurations can go here
      };
    };

    # Docker/Container development environment
    docker = {
      packages = with pkgs; [
        docker
        docker-compose
        dive
        lazydocker
        hadolint
        dockerfile-language-server-nodejs
      ];

      programs = {
        # Docker-specific program configurations can go here
      };
    };

    # Kubernetes development environment
    k8s = {
      packages = with pkgs; [
        kubectl
        kubernetes-helm
        k9s
        kind
        minikube
        stern
        kubectx
        kustomize
      ];

      programs = {
        # K8s-specific program configurations can go here
      };
    };

    # Infrastructure as Code environment
    iac = {
      packages = with pkgs; [
        terraform
        terragrunt
        ansible
        packer
        vault
        pulumi
      ];

      programs = {
        # IaC-specific program configurations can go here
      };
    };

    # Database tools environment
    database = {
      packages = with pkgs; [
        postgresql
        mysql
        sqlite
        redis
        mongosh
        pgcli
        mycli
        litecli
      ];

      programs = {
        # Database-specific program configurations can go here
      };
    };

    # Default development environment (empty, uses only common packages)
    default = {
      packages = [ ];
      programs = { };
    };
  };
}
