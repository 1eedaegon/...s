# dev/default.nix
{ pkgs, system }:

let
  rustShells = import ./rust.nix { inherit pkgs system; };
  goShells = import ./go.nix { inherit pkgs system; };
  
  # Get the latest versions of each shell
  rustLatest = rustShells.shells."latest";
  goLatest = goShells.shells."latest";
  
  # Common system packages
  # 아직 이맥스를 안쓰고, windows support는 기다려야됨
  commonPkgs = with pkgs; [
    # oh-my-zsh
    # emacs
  ] ++ (if stdenv.isWindows then [ chocolatey ] else []);
  
  # Binary settings (if needed)
  myCliBinary = import ../cli-derivation.nix { inherit pkgs system; };
  hasBinary = myCliBinary ? package && myCliBinary.package != null;
  cliBinary = if hasBinary then myCliBinary.package else null;
in

pkgs.mkShell {
  name = "Develop common";
  
  # Combine all packages
  buildInputs = 
    commonPkgs ++
    rustLatest.buildInputs ++
    goLatest.buildInputs ++
    (if hasBinary then [ cliBinary ] else []);
  
  # Combine shell hooks
  shellHook = ''
    echo "Entering combined development environment"
    ${rustLatest.shellHook}
    ${goLatest.shellHook}
    ${if hasBinary then "" else "echo 'WARNING: CLI binary not available for this platform'"}
  '';
}