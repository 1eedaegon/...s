# lib/version-shells.nix
# Generates version-postfixed devShells: `nix develop <flake>#go1_25`,
# `#py3_13`, `#node22`, `#java21`, `#rust1_75_0`.
#
# Granularity per language:
#   go     minor pins from nixpkgs `go_1_*`  -> go1_25, go1_26
#          exact pins via Go's GOTOOLCHAIN   -> go1_23_5  (fetched on demand)
#   python from nixpkgs `python3*`           -> py3_13, py3_14
#   node   from nixpkgs `nodejs_*`           -> node22, node24
#   java   from nixpkgs `jdk*`               -> java21, java23
#   rust   exact pins from rust-overlay      -> rust1_75_0  (reproducible)
#
# Flake fragments must be static; exact lists (`goExact`, `rustExact`) are the
# curated versions to expose. EOL/removed attrs are throwing tombstones in
# nixpkgs, so every candidate is guarded with tryEval and silently skipped.
{ pkgs, lib }:

let
  # ---- curated exact pins (declarative: add one line to expose a shell) ---
  goExact = [ "1.23.5" "1.25.6" ];   # -> #go1_23_5 #go1_25_6 (GOTOOLCHAIN fetches the patch)
  rustExact = [ "1.75.0" ];          # -> #rust1_75_0 (rust-overlay, reproducible)

  # ---- helpers ------------------------------------------------------------
  # Matrix-aware: a candidate is kept only if it evaluates AND is actually
  # available on this system's platform (respects meta.platforms / badPlatforms
  # / broken). Without the availability check a shell could appear on a platform
  # where its toolchain doesn't build.
  availOn = p:
    let r = builtins.tryEval (lib.meta.availableOn pkgs.stdenv.hostPlatform p);
    in r.success && r.value;
  evals = p: let r = builtins.tryEval (builtins.seq (p.outPath or p.version) true);
             in r.success && r.value;
  okPkg = p: (let r = builtins.tryEval (evals p && availOn p); in r.success && r.value);
  okAttr = n: builtins.hasAttr n pkgs && okPkg pkgs.${n};

  mkShell' = { label, packages, gotoolchain ? null }:
    pkgs.mkShell {
      inherit packages;
      shellHook = lib.optionalString (gotoolchain != null) ''
        export GOTOOLCHAIN=${gotoolchain}
      '' + ''
        echo "[${label}] ready"
      '';
    };

  # Generate { name -> shell } from nixpkgs attrs matching `regex`.
  fromNixpkgs = { regex, nameFn, toolingFor }:
    builtins.listToAttrs (map
      (attr: { name = nameFn attr; value = mkShell' { label = nameFn attr; packages = toolingFor attr; }; })
      (builtins.filter (n: builtins.match regex n != null && okAttr n) (builtins.attrNames pkgs)));

  # ---- go -----------------------------------------------------------------
  goTooling = goPkg: [ goPkg ] ++ (with pkgs; [ gopls gotools delve golangci-lint gofumpt gotestsum ]);
  goMinor = fromNixpkgs {
    regex = "go_1_[0-9]+";
    nameFn = attr: "go" + lib.removePrefix "go_" attr;          # go_1_25 -> go1_25
    toolingFor = attr: goTooling pkgs.${attr};
  };
  goExactShells = builtins.listToAttrs (map
    (v: {
      name = "go" + builtins.concatStringsSep "_" (lib.splitString "." v);  # 1.23.5 -> go1_23_5
      value = mkShell' { label = "go${v}"; packages = goTooling pkgs.go; gotoolchain = "go${v}"; };
    })
    goExact);

  # ---- python -------------------------------------------------------------
  pyMinor = fromNixpkgs {
    regex = "python3[0-9]+";
    nameFn = attr: "py3_" + (builtins.head (builtins.match "python3([0-9]+)" attr));  # python313 -> py3_13
    toolingFor = attr: [ pkgs.${attr} pkgs.uv ];
  };

  # ---- node ---------------------------------------------------------------
  nodeMinor = fromNixpkgs {
    regex = "nodejs_[0-9]+";
    nameFn = attr: "node" + lib.removePrefix "nodejs_" attr;     # nodejs_22 -> node22
    toolingFor = attr: [ pkgs.${attr} ];
  };

  # ---- java ---------------------------------------------------------------
  javaMinor = fromNixpkgs {
    regex = "jdk[0-9]+";
    nameFn = attr: "java" + lib.removePrefix "jdk" attr;         # jdk21 -> java21
    toolingFor = attr: [ pkgs.${attr} pkgs.maven pkgs.gradle ];
  };

  # ---- rust (rust-overlay gives exact patches) ----------------------------
  rustShells =
    if pkgs ? rust-bin then
      builtins.listToAttrs (lib.filter (x: x != null) (map
        (v:
          let toolchain = pkgs.rust-bin.stable.${v}.default or null;
          in if toolchain != null && okPkg toolchain then {
            name = "rust" + builtins.concatStringsSep "_" (lib.splitString "." v);  # 1.75.0 -> rust1_75_0
            value = mkShell' { label = "rust${v}"; packages = [ toolchain pkgs.rust-analyzer ]; };
          } else null)
        rustExact))
    else { };
in
goMinor // goExactShells // pyMinor // nodeMinor // javaMinor // rustShells
