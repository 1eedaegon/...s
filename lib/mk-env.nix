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
      # LD_LIBRARY_PATH 처리
      extraLibPath = environment.LD_LIBRARY_PATH or "";
      envWithoutLdPath = builtins.removeAttrs environment [ "LD_LIBRARY_PATH" ];

      # Convert aliases to shell commands
      aliasesStr = builtins.concatStringsSep "\n" (
        builtins.attrValues (
          builtins.mapAttrs (n: value: "alias ${n}='${value}'") aliases
        )
      );

      # Set environment variables (LD_LIBRARY_PATH 제외)
      envVarsStr = builtins.concatStringsSep "\n" (
        builtins.attrValues (
          builtins.mapAttrs (n: value: "export ${n}='${toString value}'") envWithoutLdPath
        )
      );

      # LD_LIBRARY_PATH: Use unified configuration + any extra paths
      ldLibPathHook = ''
        # Extra LD_LIBRARY_PATH from environment override
        ${if extraLibPath != "" then ''
          export LD_LIBRARY_PATH="${extraLibPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        '' else ""}

        # Unified LD_LIBRARY_PATH setup (from lib/ld-library-path.nix)
        ${ldConfig.shellHook}
      '';
    in
    pkgs.mkShell {
      inherit name;
      buildInputs = packages;
      # Native build inputs
      nativeBuildInputs = with pkgs; [
        pkg-config
        # Note: stdenv.cc.cc.lib is NOT in nativeBuildInputs - it causes glibc conflicts
        # ("__vdso_gettimeofday: invalid mode for dlopen()" errors)
        # Instead, we add its lib path to LD_LIBRARY_PATH in ldLibPathHook for Linux
        # C/C++ zlib libraries (dev packages for headers)
        zlib.dev
      ];

      shellHook = ''
        ${ldLibPathHook}
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
