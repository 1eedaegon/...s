{ pkgs, system }: args:
let
  # Default version: latest
  version = args.version or "latest";
  
  nodePkg = 
    if version == "latest" then pkgs.nodejs
    else if version == "20" then pkgs.nodejs_20
    else if version == "18" then pkgs.nodejs_18
    else if version == "16" then pkgs.nodejs_16
    else pkgs.nodejs; 
  
  # Default nodejs packages
  basePackages = [
    nodePkg
  ];
  
  # Version Specific
  versionSpecificPackages = with pkgs.nodePackages;
    if version == "16" then [
    #   node-gyp
    #   npm
    ]
    else if version == "18" then [
    #   yarn
    # node-gyp
    ]
    else [
      npm
      pnpm
      vite
    ];
    
  # Common
  commonPackages = with pkgs; [
    yarn
    typescript
    prettier
  ];
  
in {
  packages = basePackages ++ versionSpecificPackages ++ commonPackages;
  
  shellHook = ''
    echo "Node.js Enabled"
    echo "Node.js $(node --version)"
    export PATH="$PWD/node_modules/.bin:$PATH"
  '';
}