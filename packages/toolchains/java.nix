# packages/toolchains/java.nix
{ pkgs }:

{
  packages = with pkgs; [
    jdk
    maven
    gradle
    mvnd
  ];
}
