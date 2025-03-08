# lib/language-template.nix 
{ pkgs, system }:

langModule = { name, commonPkgs, commonConfig, versions }:
let
  # Field validation
  _ = assert builtins.isString name || builtins.abort "name must be a string";
  _ = assert builtins.isList commonPkgs || builtins.abort "commonPkgs must be a list";
  _ = assert builtins.isAttrs commonConfig || builtins.abort "commonConfig must be an attribute set";
  _ = assert builtins.isAttrs versions || builtins.abort "versions must be an attribute set";
  _ = assert commonConfig ? shellHook || builtins.abort "commonConfig must have a shellHook attribute";
  _ = assert builtins.hasAttr "latest" versions || builtins.abort "versions must have a 'latest' entry";
  
  # Version config validation
  checkVersionConfig = version: config:
    assert config ? pkg || builtins.abort "${name} module's ${version} version is missing the pkg field";
    assert builtins.isAttrs config || builtins.abort "${name} module's ${version} version config must be an attribute set";
    assert (!config ? includePkgs) || builtins.isList config.includePkgs || builtins.abort "${name} module's ${version} version's includePkgs must be a list";
    assert (!config ? excludePkgs) || builtins.isList config.excludePkgs || builtins.abort "${name} module's ${version} version's excludePkgs must be a list";
    true;
  
  _ = builtins.all (v: checkVersionConfig v versions.${v}) (builtins.attrNames versions);
  
  # Filter common packages by name (fixed version)
  getFilteredCommonPkgs = version:
    let
      excludeNames = versions.${version}.excludePkgs or [];
    in
    builtins.filter (pkg: 
      let 
        pkgName = pkg.pname or (pkg.name or "unknown");
      in 
        !(builtins.elem pkgName excludeNames)
    ) commonPkgs;
  
  # Create shells for each version
  mkVersionShell = version: config:
    pkgs.mkShell {
      name = "${name}-${version}";
      buildInputs = [ config.pkg ] ++ (config.includePkgs or []) ++ (getFilteredCommonPkgs version);
      shellHook = commonConfig.shellHook + "\n" + (config.shellHook or "");
    };
in
{
  # Return each shell with language name as prefix
  shells = builtins.mapAttrs (version: config: mkVersionShell version config) versions;
}