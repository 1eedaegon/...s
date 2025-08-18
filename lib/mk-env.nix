# lib/mkenv.nix
# Pure function that receives all dependencies as arguments
{ pkgs, system, modules }:

let
  # Extract modules from arguments: 구조 분해를 좀 더 명확하게 한거긴 한데...
  inherit (modules) commonInstalls commonExec devInstalls devExec devConfig;

  # Base environment builder
  buildEnv = { name, packages ? [ ], aliases ? { }, environment ? { }, shellHook ? "" }:
    let
      # Convert aliases to shell commands
      aliasesStr = builtins.concatStringsSep "\n" (
        builtins.attrValues (
          builtins.mapAttrs (name: value: "alias ${name}='${value}'") aliases
        )
      );

      # Set environment variables
      envVarsStr = builtins.concatStringsSep "\n" (
        builtins.attrValues (
          builtins.mapAttrs (name: value: "export ${name}='${toString value}'") environment
        )
      );
    in
    pkgs.mkShell {
      inherit name;
      buildInputs = packages;

      shellHook = ''
        ${envVarsStr}
        ${aliasesStr}
        ${shellHook}
      '';
    };
in
{
  # Main environment creation function
  mkEnv = { name, extraPackages ? [ ], extraShellHook ? "", overrides ? { } }:
    let
      # Get environment-specific settings
      envPackages =
        if name != "default" && devInstalls.environments ? ${name}
        then devInstalls.environments.${name}.packages
        else [ ];

      envConfig = devConfig.getEnvironmentConfig name;

      envExec =
        if name != "default" && devExec.environments ? ${name}
        then devExec.environments.${name}
        else { aliases = { }; shellHook = ""; };

      # Apply overrides
      appliedPackages = commonInstalls.packages ++ envPackages ++ extraPackages ++ (overrides.packages or [ ]);
      appliedAliases = commonExec.aliases // envExec.aliases // (overrides.aliases or { });
      appliedEnvironment = (envConfig.environment or { }) // (overrides.environment or { }) // { NIX_DEV_ENV = name; };
      appliedShellHook = ''
        ${commonExec.initScript}
        ${commonExec.functions}
        ${commonExec.preserveEnvHook}
        ${envExec.shellHook or ""}
        ${extraShellHook}
        ${overrides.shellHook or ""}
      '';
    in
    buildEnv {
      inherit name;
      packages = appliedPackages;
      aliases = appliedAliases;
      environment = appliedEnvironment;
      shellHook = appliedShellHook;
    };

}
