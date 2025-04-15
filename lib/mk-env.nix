# lib/mk-env.nix
{ pkgs }:

# mkEnv: Generate packages and devShells
# Args:
# - name: Environment name
# - pkgList: Package list (default: [])
# - shell: Shell script (default: "")
# - combine: Combine environment list (default: [])
{ name, pkgList ? [], shell ? "", combine ? [] }: 
let 
  # Combine Pkgs
  combinedPkgList = if combine != [] 
    then pkgList ++ builtins.concatMap (env: env.pkgList) combine
    else pkgList;

  # Combine Shell
  combinedShell = if combine != []
    then shell + "\n" + builtins.concatStringsSep "\n" (builtins.map (env: env.shell) combine)
    else shell;
  
in {
  inherit name;
  pkgList = combinedPkgList;
  shell = combinedShell;
  
  # Generate packages and devShells
  # baseEnv: Default environment (packages and shell script are added)
  toOutputs = baseEnv: {
    packages = {
      "${name}" = pkgs.buildEnv {
        name = "${name}";
        paths = combinedPkgList;
      };
    };
    devShells = {
      "${name}" = pkgs.mkShell {
        name = "${name}";
        buildInputs = combinedPkgList ++ baseEnv.pkgList;
        shellHook = baseEnv.shell + "\n" + combinedShell;
      };
    };
  };
}