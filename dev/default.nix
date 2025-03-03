{ pkgs, system, commonPackages, cliBinary, hasBinary, binaryWarningHook }:

let
  # 각 언어별 오버레이 모듈 가져오기
  node = import ./node.nix { inherit pkgs system; };
  py = import ./py.nix { inherit pkgs system; };
  ml = import ./ml.nix { inherit pkgs system; };
  rust = import ./rust.nix { inherit pkgs system; };
  go = import ./go.nix { inherit pkgs system; };

  # 기본 개발 환경 패키지 (Go, Rust, Node)
  defaultDevPackages = 
    (node {}).packages ++
    (rust {}).packages ++
    (go {}).packages;

  # 기본 개발 환경 쉘훅
  defaultDevShellHook = ''
    echo "All develop packages are enabled"
    
    ${(rust {}).shellHook}
    ${(node {}).shellHook}
    ${(py {}).shellHook}
    ${(go {}).shellHook}
    ${(ml {}).shellHook}
    
    ${binaryWarningHook}
  '';

  # 특정 환경을 위한 셸 생성 함수
  makeShell = name: packages: shellHook:
    pkgs.mkShell {
      name = name;
      buildInputs = commonPackages ++ packages ++ 
        (if hasBinary then [ cliBinary ] else []);
      
      shellHook = shellHook;
    };

in {
  # 기본 개발 환경 (Go, Rust, Node)
  default = makeShell "dev" defaultDevPackages defaultDevShellHook;
  
  # 특화 환경 노출
  node = makeShell "node" 
    (node {}).packages 
    ''
      ${(node {}).shellHook}
      ${binaryWarningHook}
    '';
    
  py = makeShell "py" 
    (py {}).packages 
    ''
      ${(py {}).shellHook}
      ${binaryWarningHook}
    '';
    
  ml = makeShell "ml" 
    (ml {}).packages 
    ''
      ${(ml {}).shellHook}
      ${binaryWarningHook}
    '';
    
  rust = makeShell "rust" 
    (rust {}).packages 
    ''
      ${(rust {}).shellHook}
      ${binaryWarningHook}
    '';
    
  go = makeShell "go" 
    (go {}).packages 
    ''
      ${(go {}).shellHook}
      ${binaryWarningHook}
    '';
}