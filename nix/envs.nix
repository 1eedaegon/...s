
# {
#     envToPackages = { flakePkgs, envAttrs }: with flakePkgs; 
#     {
#         packages = eachAttrs (name: value: { inherit value; } ) envAttrs;
#     };

#     goDev = [ 
#         go
#         gopls
#         gotools
#         go-tools
#     ];
#     default = [
#         go
#         gopls
#         gotools
#         go-tools
#     ];
# }