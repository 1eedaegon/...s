# Utilities
/**
- system: For nix profile each architecture
- pkgs: For flake devShells
- envName: Each system/pkgs env name
- args: Each package names
*/
/**
# How to use map
lib.map (x: x + 2) numbers
let
  myAttrs = {
    name = "John";
    age = 30;
    city = "New York";
  };
in
  lib.eachAttrs (name: value:
    name + ": " + builtins.toString value) myAttrs
Env schema
{   
    default = [ pkgs... ]
    mini = [ pkgs... ]
}
*/
{
    envToPackages = {flakePkgs, envAttrs}: with flakePkgs; 
    {
        packages = eachAttrs (name: value: { inherit value } ) envAttrs
    };
}
# map (
# ) envList
# envList: flakePkgs: with flakePkgs {
#     packages = {

#     }
# }
/**
with pkgs
{   
    default = [ pkgs... ]
    mini = [ pkgs... ]
}
in {
    packages.mini = mkShell {
        inherit pkgs...;
    }  
    packages.mini = mkShell {
            inherit pkgs...;
    };
};

*/
