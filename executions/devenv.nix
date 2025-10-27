# executions/devenv.nix
# Development environment specific shell commands, aliases, and hooks
{ pkgs, system }:

let
  # Import common executions
  common = import ./default.nix { inherit pkgs system; };
in
{
  # Development environment specific configurations
  environments = {
    # Rust development environment
    rust = {
      aliases = {
        # Cargo shortcuts
        cb = "cargo build";
        cbr = "cargo build --release";
        cr = "cargo run";
        crr = "cargo run --release";
        ct = "cargo test";
        ctv = "cargo test -- --nocapture";
        cc = "cargo check";
        ccl = "cargo clippy";
        cf = "cargo fmt";
        cfc = "cargo fmt --check";
        cw = "cargo watch";
        cwt = "cargo watch -x test";
        cwr = "cargo watch -x run";
        cwc = "cargo watch -x check";

        # Cargo tools
        ca = "cargo add";
        crm = "cargo rm";
        cu = "cargo update";
        ci = "cargo install";
        cun = "cargo uninstall";
        cs = "cargo search";

        # Rust tools
        rsfmt = "rustfmt";
        rsup = "rustup update";
        rsdoc = "rustdoc";

        # Common patterns
        cclean = "cargo clean";
        cbench = "cargo bench";
        cdoc = "cargo doc --open";
        cpub = "cargo publish";
        ctree = "cargo tree";
      };

      shellHook = ''
        ${common.preserveEnvHook}

        echo "🦀 Rust development environment activated"
        echo "   Rust version: $(rustc --version)"
        echo "   Cargo version: $(cargo --version)"

        # Set Rust environment variables
        export RUST_BACKTRACE=1
        export RUST_LOG=debug
        export CARGO_HOME="$HOME/.cargo"
        export PATH="$CARGO_HOME/bin:$PATH"

        # Rust-specific functions
        cargo-new() {
          cargo new "$1" && cd "$1"
        }

        cargo-init-lib() {
          cargo init --lib
        }

        # Show most recent cargo build errors in readable format
        cargo-errors() {
          cargo build 2>&1 | grep -E "^error" -A 5
        }
      '';
    };

    # Go development environment
    go = {
      aliases = {
        # Go shortcuts
        gb = "go build";
        gr = "go run";
        gt = "go test";
        gtv = "go test -v";
        gtc = "go test -cover";
        gf = "go fmt";
        gv = "go vet";
        gi = "go install";
        gg = "go get";
        ggu = "go get -u";
        gm = "go mod";
        gmi = "go mod init";
        gmt = "go mod tidy";
        gmd = "go mod download";
        gmv = "go mod vendor";
        gw = "go work";

        # Go tools
        gdoc = "go doc";
        ggen = "go generate";
        glen = "golangci-lint run";

        # Common patterns
        gta = "go test ./...";
        gba = "go build ./...";
        gclean = "go clean";
        gcover = "go test -coverprofile=coverage.out && go tool cover -html=coverage.out";
      };

      shellHook = ''
        ${common.preserveEnvHook}

        echo "🐹 Go development environment activated"
        echo "   Go version: $(go version)"

        # Set Go environment variables
        export GOPATH="$HOME/go"
        export GOBIN="$GOPATH/bin"
        export GOMODCACHE="$GOPATH/pkg/mod"
        export GO111MODULE=on
        export GOPROXY=https://proxy.golang.org,direct
        export PATH="$GOBIN:$PATH"
        mkdir -p "$GOPATH" "$GOBIN" "$GOMODCACHE"

        # Go-specific functions
        go-new() {
          local name="$1"
          mkdir -p "$name" && cd "$name"
          go mod init "github.com/$(git config user.name)/$name"
        }

        # Run go tests with color output
        gotest() {
          go test -v ./...
        }

        # Quick benchmark
        gobench() {
          go test -bench=. -benchmem
        }
      '';
    };

    # Python development environment
    py = {
      aliases = {
        # Python shortcuts
        py = "python";
        py3 = "python3";
        pip = "uv pip";

        # Virtual environment
        venv = "uv venv";
        va = "source .venv/bin/activate";
        vd = "deactivate";

        # Python tools
        pf = "ruff format";
        pl = "ruff check";
        pfc = "ruff format --check";
        pt = "pytest";
        ptv = "pytest -v";
        ptc = "pytest --cov";

        # Jupyter
        jn = "jupyter notebook";
        jl = "jupyter lab";

        # Package management
        pipi = "uv pip install";
        pipu = "uv pip install --upgrade";
        pipr = "uv pip uninstall";
        pipl = "uv pip list";
        pipf = "uv pip freeze";

        # Common patterns
        pyrun = "python -m";
        pyserve = "python -m http.server";
        pyclean = "find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null";
      };

      shellHook = ''
        ${common.preserveEnvHook}

        echo "🐍 Python development environment activated"
        echo "   Python version: $(python --version)"
        echo "   uv version: $(uv --version)"

        # Set Python environment variables
        export PYTHONPATH="$PWD:$PYTHONPATH"
        export PYTHONDONTWRITEBYTECODE=1
        export PYTHONUNBUFFERED=1

        # Auto-activate venv if it exists
        if [ -d ".venv" ]; then
          source .venv/bin/activate
          echo "   Virtual environment activated"
        fi

        # Python-specific functions
        py-new() {
          local name="$1"
          mkdir -p "$name" && cd "$name"
          uv init
          uv venv
          source .venv/bin/activate
        }

        # Create and activate virtual environment
        venv-create() {
          uv venv
          source .venv/bin/activate
          echo "Virtual environment created and activated"
        }

        # Install requirements
        req-install() {
          if [ -f "requirements.txt" ]; then
            uv pip install -r requirements.txt
          elif [ -f "pyproject.toml" ]; then
            uv pip install -e .
          else
            echo "No requirements.txt or pyproject.toml found"
          fi
        }
      '';
    };

    # Node.js development environment
    node = {
      aliases = {
        # npm shortcuts
        ni = "npm install";
        nis = "npm install --save";
        nid = "npm install --save-dev";
        nig = "npm install -g";
        nu = "npm uninstall";
        nup = "npm update";
        nr = "npm run";
        ns = "npm start";
        nt = "npm test";
        nb = "npm run build";
        nd = "npm run dev";
        nl = "npm list";

        # pnpm shortcuts
        pni = "pnpm install";
        pna = "pnpm add";
        pnr = "pnpm remove";
        pnx = "pnpm dlx";
        pnrun = "pnpm run";

        # yarn shortcuts
        yi = "yarn install";
        ya = "yarn add";
        yad = "yarn add --dev";
        yr = "yarn remove";
        yrun = "yarn run";

        # Node tools
        tsc = "npx tsc";
        tsx = "npx tsx";
        vite = "npx vite";
        next = "npx next";

        # Common patterns
        nclean = "rm -rf node_modules package-lock.json";
        pclean = "rm -rf node_modules pnpm-lock.yaml";
        yclean = "rm -rf node_modules yarn.lock";
        nreinstall = "rm -rf node_modules package-lock.json && npm install";
      };

      shellHook = ''
        ${common.preserveEnvHook}

        echo "📦 Node.js development environment activated"
        echo "   Node version: $(node --version)"
        echo "   npm version: $(npm --version)"

        # Check for package managers
        command -v pnpm >/dev/null 2>&1 && echo "   pnpm version: $(pnpm --version)"
        command -v yarn >/dev/null 2>&1 && echo "   yarn version: $(yarn --version)"

        # Set Node environment variables
        export NODE_ENV="development"
        export PATH="./node_modules/.bin:\$PATH"

        # Node-specific functions
        node-new() {
          local name="$1"
          local template="''${2:-}"

          mkdir -p "$name" && cd "$name"

          if [ -n "$template" ]; then
            case "$template" in
              vite)
                npm create vite@latest . -- --template react-ts
                ;;
              next)
                npx create-next-app@latest . --typescript --tailwind --app
                ;;
              express)
                npm init -y
                npm install express
                npm install -D @types/node @types/express typescript nodemon
                ;;
              *)
                npm init -y
                ;;
            esac
          else
            npm init -y
          fi
        }

        # Quick script runner
        nrs() {
          if [ -f "package.json" ]; then
            npm run "$@"
          else
            echo "No package.json found"
          fi
        }

        # List available scripts
        scripts() {
          if [ -f "package.json" ]; then
            echo "Available scripts:"
            cat package.json | jq '.scripts' | grep -v '{' | grep -v '}'
          else
            echo "No package.json found"
          fi
        }
      '';
    };

    # Default/base development environment
    default = {
      aliases = { };

      shellHook = ''
        ${common.preserveEnvHook}

        echo "🚀 Development environment activated"
        echo "   Available environments: rust, go, python, node"
        echo "   Use 'nix develop .#<env>' to activate a specific environment"

        # Show current directory info
        echo ""
        echo "📁 Current directory: $PWD"
        if [ -d ".git" ]; then
          echo "   Git branch: $(git branch --show-current)"
        fi

        # Check for common project files
        [ -f "Cargo.toml" ] && echo "   Rust project detected"
        [ -f "go.mod" ] && echo "   Go project detected"
        [ -f "package.json" ] && echo "   Node.js project detected"
        [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] && echo "   Python project detected"
      '';
    };
  };

  # Helper function to get merged aliases for an environment
  getMergedAliases = env:
    common.aliases // (env.aliases or { });

  # Helper function to get complete shell hook for an environment
  getCompleteShellHook = env:
    ''
      ${common.functions}
      ${env.shellHook or ""}
    '';
}
