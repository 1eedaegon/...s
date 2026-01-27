# lib/mkenv.nix
# Pure function that receives all dependencies as arguments
{ pkgs, system, modules }:

let
  # Extract modules from arguments
  inherit (modules) commonInstalls commonExec devInstalls devExec devConfig;

  # Import unified LD_LIBRARY_PATH configuration
  ldConfig = import ./ld-library-path.nix { inherit pkgs system; };

  # Base environment builder
  buildEnv = { name, packages ? [ ], aliases ? { }, environment ? { }, shellHook ? "" }:
    let
      # Convert aliases to shell commands
      aliasesStr = builtins.concatStringsSep "\n" (
        builtins.attrValues (
          builtins.mapAttrs (n: value: "alias ${n}='${value}'") aliases
        )
      );

      # Set environment variables
      envVarsStr = builtins.concatStringsSep "\n" (
        builtins.attrValues (
          builtins.mapAttrs (n: value: "export ${n}='${toString value}'") environment
        )
      );
    in
    pkgs.mkShell {
      inherit name;
      buildInputs = packages;
      nativeBuildInputs = with pkgs; [
        pkg-config
        zlib.dev
      ];

      shellHook = ''
        # CUDA/environment setup (from lib/ld-library-path.nix)
        ${ldConfig.shellHook}
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
