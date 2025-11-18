# configurations/devenv.nix
# Development environment specific configuration settings
{ pkgs, system }:

let
  # Import common configurations
  common = import ./default.nix { inherit pkgs system; };
in
rec {
  # Development environment specific configurations
  environments = {
    # Rust development environment configuration
    rust = {
      environment = common.environment // {
        # Rust specific environment variables
        RUST_BACKTRACE = "1";
        RUST_LOG = "debug";
        RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

        # Cargo configuration
        CARGO_TARGET_DIR = "target";
        CARGO_INCREMENTAL = "1";
        CARGO_NET_RETRY = "10";
        CARGO_BUILD_JOBS = "8";

        # Rust analyzer
        RUST_ANALYZER_CARGO_TARGET_DIR = "target/rust-analyzer";
      };

      # Cargo configuration
      cargo = {
        # Build settings
        build = {
          target-dir = "target";
          jobs = 8;
          incremental = true;
        };

        # Network settings
        net = {
          retry = 10;
          git-fetch-with-cli = true;
        };

        # Registry settings
        registries = {
          crates-io = {
            protocol = "sparse";
          };
        };

        # Profile settings
        profile = {
          dev = {
            opt-level = 0;
            debug = true;
            split-debuginfo = "unpacked";
          };

          release = {
            opt-level = 3;
            lto = true;
            codegen-units = 1;
            strip = "symbols";
          };

          bench = {
            opt-level = 3;
            lto = true;
          };
        };
      };

      # Rust-analyzer settings
      rustAnalyzer = {
        assist = {
          importGranularity = "module";
          importPrefix = "self";
        };

        cargo = {
          allFeatures = true;
          loadOutDirsFromCheck = true;
          runBuildScripts = true;
        };

        checkOnSave = {
          allFeatures = true;
          allTargets = true;
          command = "clippy";
          extraArgs = [ "--" "-W" "clippy::all" ];
        };

        inlayHints = {
          chainingHints = true;
          typeHints = true;
          parameterHints = true;
        };

        procMacro = {
          enable = true;
          attributes.enable = true;
        };
      };
    };

    # Go development environment configuration
    go = {
      environment = common.environment // {
        # Go specific environment variables
        # Note: GOBIN and GOMODCACHE are set in executions/devenv.nix shellHook
        # to properly reference $GOPATH at runtime
        GO111MODULE = "on";
        GOPROXY = "https://proxy.golang.org,direct";
        GOSUMDB = "sum.golang.org";
        # GOPRIVATE = "github.com/${username}/*";

        # Go build settings
        CGO_ENABLED = "1";
        GOOS =
          if system == "x86_64-darwin" || system == "aarch64-darwin" then "darwin"
          else if system == "x86_64-linux" || system == "aarch64-linux" then "linux"
          else "linux";
        GOARCH =
          if system == "x86_64-darwin" || system == "x86_64-linux" then "amd64"
          else if system == "aarch64-darwin" || system == "aarch64-linux" then "arm64"
          else "amd64";
      };

      # Go tools configuration
      gopls = {
        # Build settings
        build = {
          buildFlags = [ "-tags=" ];
          env = {
            GOFLAGS = "-mod=readonly";
          };
          directoryFilters = [ "-node_modules" "-vendor" ];
          expandWorkspaceToModule = true;
        };

        # UI settings
        ui = {
          completion = {
            usePlaceholders = true;
            completionBudget = "100ms";
            matcher = "fuzzy";
          };

          diagnostic = {
            staticcheck = true;
            annotations = {
              bounds = true;
              escape = true;
              inline = true;
              nil = true;
            };
          };

          codelenses = {
            gc_details = true;
            regenerate_cgo = true;
            run_govulncheck = true;
            test = true;
            tidy = true;
            upgrade_dependency = true;
            vendor = true;
          };

          inlayHint = {
            assignVariableTypes = true;
            compositeLiteralFields = true;
            compositeLiteralTypes = true;
            constantValues = true;
            functionTypeParameters = true;
            parameterNames = true;
            rangeVariableTypes = true;
          };
        };

        # Formatting
        formatting = {
          gofumpt = true;
          # local = "github.com/${username}";
        };
      };

      # Golangci-lint configuration
      golangciLint = {
        run = {
          timeout = "5m";
          tests = false;
          skip-dirs = [ "vendor" "third_party" ];
        };

        linters = {
          enable = [
            "gofmt"
            "goimports"
            "golint"
            "govet"
            "errcheck"
            "staticcheck"
            "unused"
            "gosimple"
            "structcheck"
            "varcheck"
            "ineffassign"
            "deadcode"
            "typecheck"
            "gosec"
            "megacheck"
            "misspell"
            "unparam"
            "prealloc"
            "scopelint"
            "gocritic"
            "gochecknoinits"
            "gochecknoglobals"
          ];
        };
      };
    };

    # Python development environment configuration
    py = {
      environment = common.environment // {
        # Python specific environment variables
        PYTHONPATH = "$PWD:$PYTHONPATH";
        PYTHONDONTWRITEBYTECODE = "1";
        PYTHONUNBUFFERED = "1";
        PYTHONIOENCODING = "utf-8";
        PIP_DISABLE_PIP_VERSION_CHECK = "1";
        PIP_NO_CACHE_DIR = "false";

        # Virtual environment
        VIRTUAL_ENV_DISABLE_PROMPT = "1";
        CUDA_PATH = "${pkgs.cudaPackages.cuda_cudart}";
        CUDA_HOME = "${pkgs.cudaPackages.cuda_cudart}";
        LD_LIBRARY_PATH = "${pkgs.cudaPackages.cuda_cudart}/lib:${pkgs.cudaPackages.cuda_nvcc}/lib";
      };

      # Python tools configuration
      ruff = {
        # Linting rules
        select = [
          "E" # pycodestyle errors
          "W" # pycodestyle warnings
          "F" # pyflakes
          "I" # isort
          "B" # flake8-bugbear
          "C4" # flake8-comprehensions
          "UP" # pyupgrade
          "ARG" # flake8-unused-arguments
          "SIM" # flake8-simplify
        ];

        ignore = [
          "E501" # line too long
          "B008" # do not perform function calls in argument defaults
        ];

        # Formatting
        line-length = 88;
        indent-width = 4;

        # Per-file ignores
        per-file-ignores = {
          "__init__.py" = [ "F401" ];
          "tests/*" = [ "S101" ];
        };

        # Auto-fix
        fixable = [ "ALL" ];
        unfixable = [ ];
      };

      # Black formatter configuration
      black = {
        line-length = 88;
        target-version = [ "py311" "py312" ];
        include = "\\.pyi?$";
        extend-exclude = ''
          /(
            \.git
            | \.hg
            | \.mypy_cache
            | \.tox
            | \.venv
            | _build
            | buck-out
            | build
            | dist
          )/
        '';
      };

      # Mypy configuration
      mypy = {
        python_version = "3.12";
        warn_return_any = true;
        warn_unused_configs = true;
        disallow_untyped_defs = true;
        disallow_any_unimported = false;
        no_implicit_optional = true;
        warn_redundant_casts = true;
        warn_unused_ignores = true;
        warn_no_return = true;
        warn_unreachable = true;
        strict_equality = true;
      };

      # Pytest configuration
      pytest = {
        minversion = "6.0";
        addopts = "-ra -q --strict-markers";
        testpaths = [ "tests" ];
        python_files = [ "test_*.py" "*_test.py" ];
        python_classes = [ "Test*" ];
        python_functions = [ "test_*" ];
      };

      # IPython configuration
      ipython = {
        colors = "Linux";
        confirm_exit = false;
        deep_reload = true;
        editor = "vim";
        xmode = "Context";
      };
    };

    # Node.js development environment configuration
    node = {
      environment = common.environment // {
        # Node.js specific environment variables
        NODE_ENV = "development";
        NODE_OPTIONS = "--max-old-space-size=4096";

        # Build tools
        VITE_HOST = "0.0.0.0";
        NEXT_TELEMETRY_DISABLED = "1";

      };

      # NPM configuration
      npm = {
        loglevel = "warn";
        progress = true;
        # init-author-name = "${username}";
        init-license = "MIT";
      };

      # ESLint configuration
      eslint = {
        extends = [
          "eslint:recommended"
        ];

        env = {
          browser = true;
          es2021 = true;
          node = true;
        };

        parserOptions = {
          ecmaVersion = 2021;
          sourceType = "module";
          ecmaFeatures = {
            jsx = true;
          };
        };

        rules = {
          "indent" = [ "error" 2 ];
          "linebreak-style" = [ "error" "unix" ];
          "quotes" = [ "error" "single" ];
          "semi" = [ "error" "always" ];
          "no-unused-vars" = "warn";
          "no-console" = "off";
        };
      };

      # Prettier configuration
      prettier = {
        printWidth = 100;
        tabWidth = 2;
        useTabs = false;
        semi = true;
        singleQuote = true;
        quoteProps = "as-needed";
        jsxSingleQuote = false;
        trailingComma = "es5";
        bracketSpacing = true;
        jsxBracketSameLine = false;
        arrowParens = "always";
        proseWrap = "preserve";
        htmlWhitespaceSensitivity = "css";
        endOfLine = "lf";
      };

      # TypeScript configuration
      typescript = {
        compilerOptions = {
          target = "ES2021";
          module = "commonjs";
          lib = [ "ES2021" ];
          jsx = "react";
          strict = true;
          esModuleInterop = true;
          skipLibCheck = true;
          forceConsistentCasingInFileNames = true;
          resolveJsonModule = true;
          declaration = true;
          declarationMap = true;
          sourceMap = true;
          noUnusedLocals = true;
          noUnusedParameters = true;
          noImplicitReturns = true;
          noFallthroughCasesInSwitch = true;
        };
      };

      # Package.json scripts templates
      scripts = {
        dev = "vite dev";
        build = "vite build";
        preview = "vite preview";
        test = "vitest";
        "test:ui" = "vitest --ui";
        "test:coverage" = "vitest --coverage";
        lint = "eslint . --ext .js,.jsx,.ts,.tsx";
        "lint:fix" = "eslint . --ext .js,.jsx,.ts,.tsx --fix";
        format = "prettier --write .";
        "format:check" = "prettier --check .";
        typecheck = "tsc --noEmit";
        clean = "rm -rf dist node_modules .turbo .next out";
      };
    };
    java = {
      environment = common.environment // {
        JAVA_HOME = "${pkgs.jdk}";
        # PATH = "${JAVA_HOME}/bin:${PATH}";
      };
    }

    # Docker/Container development environment configuration
    docker = {
      environment = common.environment // {
        DOCKER_BUILDKIT = "1";
        COMPOSE_DOCKER_CLI_BUILD = "1";
        DOCKER_SCAN_SUGGEST = "false";
      };

      # Docker daemon configuration
      daemon = {
        features = {
          buildkit = true;
        };
        experimental = false;
        debug = false;
        log-level = "info";
      };
    };

    # Kubernetes development environment configuration
    k8s = {
      environment = common.environment // {
        KUBECONFIG = "$HOME/.kube/config";
        KUBECTL_EXTERNAL_DIFF = "diff -u";
        KUBE_EDITOR = "vim";
      };

      # kubectl configuration
      kubectl = {
        context = "default";
        namespace = "default";
      };

      # k9s configuration
      k9s = {
        refreshRate = 5;
        maxConnRetry = 5;
        enableMouse = true;
        headless = false;
        logoless = false;
        crumbsless = false;
        readOnly = false;
        noExitOnCtrlC = false;
      };
    };

    # Default development environment configuration
    default = {
      environment = common.environment // {
        # Additional development environment variables
        DEVELOPMENT = "true";
      };
    };
  };

  # Helper function to get environment config for a specific dev environment
  getEnvironmentConfig = envName:
    if builtins.hasAttr envName environments then
      environments.${envName}
    else
      environments.default;
}
