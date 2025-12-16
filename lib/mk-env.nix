# lib/mkenv.nix
# Pure function that receives all dependencies as arguments
{ pkgs, system, modules }:

let
  # Extract modules from arguments: 구조 분해를 좀 더 명확하게 한거긴 한데...
  inherit (modules) commonInstalls commonExec devInstalls devExec devConfig;

  # Platform detection
  isLinux = system == "x86_64-linux" || system == "aarch64-linux";

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

      # LD_LIBRARY_PATH: Preserve system paths only
      # Note: Dynamic NVIDIA detection removed to avoid library conflicts
      # NVIDIA paths should be set by the system/driver, not by nix shell
      ldLibPathHook = ''
        # Just preserve existing system LD_LIBRARY_PATH, don't run external commands
        # Running ls/grep/etc here can cause glibc conflicts on some systems
        :
      '';
    in
    pkgs.mkShell {
      inherit name;
      buildInputs = packages;
      # Native build inputs
      nativeBuildInputs = with pkgs; [
        pkg-config
        # Note: stdenv.cc.cc.lib removed - it causes glibc conflicts on Linux
        # ("__vdso_gettimeofday: invalid mode for dlopen()" errors)
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
