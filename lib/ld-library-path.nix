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

  # Get the full shell hook for environment setup
  # NOTE: Do NOT set LD_LIBRARY_PATH globally!
  # Nix binaries use rpath to find their libraries. Setting LD_LIBRARY_PATH
  # overrides rpath and causes "Illegal instruction" crashes on Tegra/Jetson
  # when system libraries (built for specific CPU extensions) are loaded by
  # generic aarch64 Nix binaries.
  #
  # Only CUDA_HOME/CUDA_PATH are set for applications that need them.
  shellHook = ''
    # CUDA environment variables (without LD_LIBRARY_PATH)
    for cuda_path in ${builtins.concatStringsSep " " cudaPaths}; do
      if [[ -d "$cuda_path" ]]; then
        if [[ -z "$CUDA_HOME" ]]; then
          export CUDA_HOME="$(dirname "$cuda_path")"
          export CUDA_PATH="$CUDA_HOME"
        fi
        break
      fi
    done
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
