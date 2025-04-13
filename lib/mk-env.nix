# lib/mk-env.nix
{ pkgs }:

# mkEnv 함수: 환경 생성 및 조합
# 인자:
# - name: 환경 이름
# - pkgList: 패키지 목록 (기본값: [])
# - shell: 쉘 스크립트 (기본값: "")
# - combine: 조합할 환경 목록 (기본값: [])
{ name, pkgList ? [], shell ? "", combine ? [] }: 
let 
  # 조합할 환경이 있으면 패키지 목록 병합
  combinedPkgList = if combine != [] 
    then pkgList ++ builtins.concatMap (env: env.pkgList) combine
    else pkgList;
    
  # 조합할 환경이 있으면 쉘 스크립트 병합
  combinedShell = if combine != []
    then shell + "\n" + builtins.concatStringsSep "\n" (builtins.map (env: env.shell) combine)
    else shell;
in {
  inherit name;
  pkgList = combinedPkgList;
  shell = combinedShell;
  
  # packages 및 devShells 생성 함수
  # baseEnv: 기본 환경 (패키지 및 쉘 스크립트가 추가됨)
  toOutputs = baseEnv: {
    packages = {
      "${name}" = pkgs.buildEnv {
        name = "${name}";
        paths = combinedPkgList;
      };
    };
    devShells = {
      "${name}" = pkgs.mkShell {
        name = "${name}";
        buildInputs = combinedPkgList ++ baseEnv.pkgList;
        shellHook = baseEnv.shell + "\n" + combinedShell;
      };
    };
  };
}