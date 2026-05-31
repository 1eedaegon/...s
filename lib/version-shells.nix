# lib/version-shells.nix
# Assembly only — exact version pins live in flake.nix (`toolchainVersions`).
# Each shell inherits `base`; language tooling layers on top.
#
#   go     #go1_25_6   GOTOOLCHAIN        rust   #rust1_75_0  rust-overlay
#   python #py3_13_5   nixpkgs-python     node   #node22      nixpkgs minor
#   java   #java21     nixpkgs minor
{ pkgs, lib, pythonPkgs, versions }:

let
  # Shared deps inherited by every version shell.
  base = with pkgs; [ git ripgrep ];

  okPkg = p:
    let r = builtins.tryEval
      (lib.meta.availableOn pkgs.stdenv.hostPlatform p && builtins.seq (p.outPath or p.version) true);
    in r.success && r.value;
  okAttr = n: builtins.hasAttr n pkgs && okPkg pkgs.${n};

  dropDots = v: builtins.concatStringsSep "_" (lib.splitString "." v);

  # name = lang+version (e.g. go1_25_6). Drives the starship `#<env>` badge
  # (env_var.NIX_DEV_ENV) and is re-exported to strip the `-env` suffix that
  # `nix develop` adds to $name.
  mk = { name, packages, gotoolchain ? null }:
    pkgs.mkShell {
      inherit name;
      NIX_DEV_ENV = name;
      packages = base ++ packages;
      shellHook = lib.optionalString (gotoolchain != null) "export GOTOOLCHAIN=${gotoolchain}\n"
        + ''
          export name=${name}
          echo "[${name}] ready"
        '';
    };

  fromAttrs = { regex, nameFn, toolingFor }:
    builtins.listToAttrs (map
      (a: let nm = nameFn a; in { name = nm; value = mk { name = nm; packages = toolingFor a; }; })
      (builtins.filter (n: builtins.match regex n != null && okAttr n) (builtins.attrNames pkgs)));

  fromList = { list, pkgFor, nameFor, toolingFor, gotoolchainFor ? (_: null) }:
    builtins.listToAttrs (lib.filter (x: x != null) (map
      (v: let p = pkgFor v; nm = nameFor v; in if p != null && okPkg p
        then { name = nm; value = mk { name = nm; packages = toolingFor p; gotoolchain = gotoolchainFor v; }; }
        else null)
      list));

  goTooling = g: [ g ] ++ (with pkgs; [ gopls gotools delve golangci-lint gofumpt gotestsum ]);

  goMinor = fromAttrs {
    regex = "go_1_[0-9]+";
    nameFn = a: "go" + lib.removePrefix "go_" a;
    toolingFor = a: goTooling pkgs.${a};
  };
  goExact = fromList {
    list = versions.go;
    pkgFor = _: pkgs.go;
    nameFor = v: "go${dropDots v}";
    toolingFor = _: goTooling pkgs.go;
    gotoolchainFor = v: "go${v}";
  };

  pyMinor = fromAttrs {
    regex = "python3[0-9]+";
    nameFn = a: "py3_" + builtins.head (builtins.match "python3([0-9]+)" a);
    toolingFor = a: [ pkgs.${a} pkgs.uv ];
  };
  pyExact = fromList {
    list = versions.python;
    pkgFor = v: pythonPkgs.${v} or null;
    nameFor = v: "py${dropDots v}";
    toolingFor = p: [ p pkgs.uv ];
  };

  nodeMinor = fromAttrs {
    regex = "nodejs_[0-9]+";
    nameFn = a: "node" + lib.removePrefix "nodejs_" a;
    toolingFor = a: [ pkgs.${a} ];
  };

  javaMinor = fromAttrs {
    regex = "jdk[0-9]+";
    nameFn = a: "java" + lib.removePrefix "jdk" a;
    toolingFor = a: [ pkgs.${a} pkgs.maven pkgs.gradle ];
  };

  rustExact =
    if pkgs ? rust-bin then fromList {
      list = versions.rust;
      pkgFor = v: pkgs.rust-bin.stable.${v}.default or null;
      nameFor = v: "rust${dropDots v}";
      toolingFor = t: [ t pkgs.rust-analyzer ];
    } else { };
in
goMinor // goExact // pyMinor // pyExact // nodeMinor // javaMinor // rustExact
