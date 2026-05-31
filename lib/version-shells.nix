# lib/version-shells.nix
# Version-postfixed devShells. Each shell inherits `base`; language tooling
# layers on top.
#
# Applicable versions:
#   go      any patch          e.g. #go1_25_6   (GOTOOLCHAIN)
#   rust    rust-overlay patch e.g. #rust1_75_0 (reproducible)
#   python  nixpkgs-python     e.g. #py3_13_5   (reproducible)
#   node    nixpkgs minor      e.g. #node22     (auto)
#   java    nixpkgs minor      e.g. #java21     (auto)
{ pkgs, lib, pythonPkgs }:

let
  versions = {
    go = [ "1.23.5" "1.25.6" ];
    rust = [ "1.75.0" ];
    python = [ "3.11.5" "3.13.5" ];
  };

  # Shared deps inherited by every version shell.
  base = with pkgs; [ git ripgrep ];

  okPkg = p:
    let r = builtins.tryEval
      (lib.meta.availableOn pkgs.stdenv.hostPlatform p && builtins.seq (p.outPath or p.version) true);
    in r.success && r.value;
  okAttr = n: builtins.hasAttr n pkgs && okPkg pkgs.${n};

  dropDots = v: builtins.concatStringsSep "_" (lib.splitString "." v);

  mk = { label, packages, gotoolchain ? null }:
    pkgs.mkShell {
      packages = base ++ packages;
      shellHook = lib.optionalString (gotoolchain != null) "export GOTOOLCHAIN=${gotoolchain}\n"
        + ''echo "[${label}] ready"'';
    };

  fromAttrs = { regex, nameFn, toolingFor }:
    builtins.listToAttrs (map
      (a: { name = nameFn a; value = mk { label = nameFn a; packages = toolingFor a; }; })
      (builtins.filter (n: builtins.match regex n != null && okAttr n) (builtins.attrNames pkgs)));

  fromList = { list, pkgFor, nameFor, labelFor, toolingFor }:
    builtins.listToAttrs (lib.filter (x: x != null) (map
      (v: let p = pkgFor v; in if p != null && okPkg p
        then { name = nameFor v; value = mk { label = labelFor v; packages = toolingFor p; }; }
        else null)
      list));

  goTooling = g: [ g ] ++ (with pkgs; [ gopls gotools delve golangci-lint gofumpt gotestsum ]);

  goMinor = fromAttrs {
    regex = "go_1_[0-9]+";
    nameFn = a: "go" + lib.removePrefix "go_" a;
    toolingFor = a: goTooling pkgs.${a};
  };
  goExact = builtins.listToAttrs (map
    (v: { name = "go${dropDots v}"; value = mk { label = "go${v}"; packages = goTooling pkgs.go; gotoolchain = "go${v}"; }; })
    versions.go);

  pyMinor = fromAttrs {
    regex = "python3[0-9]+";
    nameFn = a: "py3_" + builtins.head (builtins.match "python3([0-9]+)" a);
    toolingFor = a: [ pkgs.${a} pkgs.uv ];
  };
  pyExact = fromList {
    list = versions.python;
    pkgFor = v: pythonPkgs.${v} or null;
    nameFor = v: "py${dropDots v}";
    labelFor = v: "py${v}";
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
      labelFor = v: "rust${v}";
      toolingFor = t: [ t pkgs.rust-analyzer ];
    } else { };
in
goMinor // goExact // pyMinor // pyExact // nodeMinor // javaMinor // rustExact
