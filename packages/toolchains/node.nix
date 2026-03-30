# packages/toolchains/node.nix
{ pkgs }:

{
  packages = with pkgs; [
    nodejs_24
    pnpm
    yarn
    typescript
    typescript-language-server
    eslint
    prettier
    webpack-cli
    turbo-unwrapped
  ];
}
