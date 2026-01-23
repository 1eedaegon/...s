# lib/ld-library-path.nix
# Unified LD_LIBRARY_PATH configuration for all platforms
# Supports: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin
{ pkgs, system }:

let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
  isAarch64 = system == "aarch64-linux" || system == "aarch64-darwin";
  isX86_64 = system == "x86_64-linux" || system == "x86_64-darwin";

  # Nix library paths (works on all platforms)
  nixLibPaths = [
    "${pkgs.stdenv.cc.cc.lib}/lib"
    "${pkgs.zlib}/lib"
  ];

  # Linux-specific system library paths
  linuxSystemPaths = {
    # x86_64-linux paths
    x86_64 = [
      "/usr/lib/x86_64-linux-gnu"
      "/usr/lib64"
    ];
    # aarch64-linux paths (Jetson, Raspberry Pi, etc.)
    aarch64 = [
      "/usr/lib/aarch64-linux-gnu"
      "/usr/lib64"
    ];
  };

  # CUDA paths (Linux only)
  cudaPaths = [
    "/usr/local/cuda/lib64"
    "/usr/local/cuda-12/lib64"
    "/usr/local/cuda-11/lib64"
  ];

  # Jetson/Tegra paths (aarch64-linux)
  tegraPaths = [
    "/usr/lib/aarch64-linux-gnu/tegra"
    "/usr/lib/aarch64-linux-gnu/tegra-egl"
  ];

  # NVIDIA driver paths
  nvidiaPaths = {
    x86_64 = [ "/usr/lib/x86_64-linux-gnu/nvidia" "/usr/lib64/nvidia" ];
    aarch64 = [ "/usr/lib/aarch64-linux-gnu/nvidia" ];
  };

in
{
  # Get Nix store library paths as a list
  nixPaths = nixLibPaths;

  # Get the full shell hook for LD_LIBRARY_PATH setup
  # This is the main export - use this in shell initialization
  shellHook =
    if isDarwin then ''
      # macOS: Generally not needed, Nix handles via rpath
      # But set DYLD_LIBRARY_PATH for edge cases with non-Nix binaries
      :
    '' else ''
      # ============================================================
      # LD_LIBRARY_PATH setup for Linux (x86_64 & aarch64)
      # ============================================================

      # 1. Nix store libraries (libstdc++, zlib, etc.)
      ${builtins.concatStringsSep "\n" (map (p: ''
        export LD_LIBRARY_PATH="${p}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      '') nixLibPaths)}

      # 2. System library paths (architecture-specific)
      ${if isAarch64 then ''
        # aarch64-linux system paths
        for p in ${builtins.concatStringsSep " " linuxSystemPaths.aarch64}; do
          [[ -d "$p" ]] && export LD_LIBRARY_PATH="$p''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        done
      '' else ''
        # x86_64-linux system paths
        for p in ${builtins.concatStringsSep " " linuxSystemPaths.x86_64}; do
          [[ -d "$p" ]] && export LD_LIBRARY_PATH="$p''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        done
      ''}

      # 3. CUDA paths (if available)
      for cuda_path in ${builtins.concatStringsSep " " cudaPaths}; do
        if [[ -d "$cuda_path" ]]; then
          export LD_LIBRARY_PATH="$cuda_path''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          # Set CUDA environment variables from the first found CUDA
          if [[ -z "$CUDA_HOME" ]]; then
            export CUDA_HOME="$(dirname "$cuda_path")"
            export CUDA_PATH="$CUDA_HOME"
          fi
          break
        fi
      done

      # 4. Jetson/Tegra paths (aarch64 only)
      ${if isAarch64 then ''
        for tegra_path in ${builtins.concatStringsSep " " tegraPaths}; do
          [[ -d "$tegra_path" ]] && export LD_LIBRARY_PATH="$tegra_path''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        done
      '' else ""}

      # 5. NVIDIA driver paths (if GPU present)
      if [[ -e "/dev/nvidia0" ]] || [[ -d "/usr/lib/aarch64-linux-gnu/tegra" ]]; then
        ${if isAarch64 then ''
          for nvidia_path in ${builtins.concatStringsSep " " nvidiaPaths.aarch64}; do
            [[ -d "$nvidia_path" ]] && export LD_LIBRARY_PATH="$nvidia_path''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          done
        '' else ''
          for nvidia_path in ${builtins.concatStringsSep " " nvidiaPaths.x86_64}; do
            [[ -d "$nvidia_path" ]] && export LD_LIBRARY_PATH="$nvidia_path''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          done
        ''}
      fi
    '';

  # Nix-only paths as colon-separated string (for sessionVariables)
  nixPathsString = builtins.concatStringsSep ":" nixLibPaths;

  # For debugging: show what will be set
  debug = {
    inherit isLinux isDarwin isAarch64 isX86_64;
    inherit nixLibPaths cudaPaths tegraPaths;
    linuxSystemPaths = if isAarch64 then linuxSystemPaths.aarch64 else linuxSystemPaths.x86_64;
    nvidiaPaths = if isAarch64 then nvidiaPaths.aarch64 else nvidiaPaths.x86_64;
  };
}
