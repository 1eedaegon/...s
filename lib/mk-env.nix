# lib/mkenv.nix
# Pure function that receives all dependencies as arguments
{ pkgs, system, modules }:

let
  # Extract modules from arguments: 구조 분해를 좀 더 명확하게 한거긴 한데...
  inherit (modules) commonInstalls commonExec devInstalls devExec devConfig;

  # Platform detection
  isLinux = system == "x86_64-linux" || system == "aarch64-linux";

  # NVIDIA library paths (dynamically detected at shell init)
  nvidiaPaths = [
    "/usr/lib/x86_64-linux-gnu"      # Ubuntu/Debian
    "/usr/lib64"                      # RHEL/Fedora
    "/usr/lib/nvidia"                 # Some distros
    "/opt/cuda/lib64"                 # Manual CUDA install
  ];

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

      # LD_LIBRARY_PATH: Default + NVIDIA + ...
      ldLibPathHook = ''
        # Preserve existing system LD_LIBRARY_PATH
        _SYSTEM_LD_LIBRARY_PATH="''${LD_LIBRARY_PATH:-}"

        # Dynamic NVIDIA library detection (Linux only)
        _NVIDIA_LD_PATH=""
        ${pkgs.lib.optionalString isLinux ''
          # Check for NVIDIA driver
          if command -v nvidia-smi &>/dev/null || [ -d /proc/driver/nvidia ]; then
            for _nv_path in ${builtins.concatStringsSep " " nvidiaPaths}; do
              if [ -d "$_nv_path" ] && ls "$_nv_path"/libcuda* &>/dev/null 2>&1; then
                _NVIDIA_LD_PATH="$_nv_path''${_NVIDIA_LD_PATH:+:$_NVIDIA_LD_PATH}"
              fi
            done
            # Also check ldconfig cache for nvidia libs
            if command -v ldconfig &>/dev/null; then
              _nv_from_ldconfig="$(ldconfig -p 2>/dev/null | grep -oP '/[^\s]+(?=/libcuda\.so)' | head -1)"
              if [ -n "$_nv_from_ldconfig" ] && [ -d "$_nv_from_ldconfig" ]; then
                case ":$_NVIDIA_LD_PATH:" in
                  *":$_nv_from_ldconfig:"*) ;;
                  *) _NVIDIA_LD_PATH="$_nv_from_ldconfig''${_NVIDIA_LD_PATH:+:$_NVIDIA_LD_PATH}" ;;
                esac
              fi
            fi
          fi
        ''}

        # Build final LD_LIBRARY_PATH: extra + nvidia + system
        _FINAL_LD_PATH=""
        ${pkgs.lib.optionalString (extraLibPath != "") ''
          _FINAL_LD_PATH="${extraLibPath}"
        ''}
        if [ -n "$_NVIDIA_LD_PATH" ]; then
          _FINAL_LD_PATH="''${_FINAL_LD_PATH:+$_FINAL_LD_PATH:}$_NVIDIA_LD_PATH"
        fi
        if [ -n "$_SYSTEM_LD_LIBRARY_PATH" ]; then
          _FINAL_LD_PATH="''${_FINAL_LD_PATH:+$_FINAL_LD_PATH:}$_SYSTEM_LD_LIBRARY_PATH"
        fi

        export LD_LIBRARY_PATH="$_FINAL_LD_PATH"
        unset _SYSTEM_LD_LIBRARY_PATH _NVIDIA_LD_PATH _FINAL_LD_PATH _nv_path _nv_from_ldconfig
      '';
    in
    pkgs.mkShell {
      inherit name;
      buildInputs = packages;
      # Native build inputs
      nativeBuildInputs = with pkgs; [
        pkg-config
        stdenv.cc.cc.lib
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
