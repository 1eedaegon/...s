#!/bin/bash

# Langauage: Korean
# What does determinate nix do? :
 
# 1. nix tar파일 다운로드, temp디렉토리 생성
# 2. /nix 디렉토리 생성
# 3. /nix 디렉토리로 nix 이동
# 4. 32개 build-user-group 생성, [빌드 유저 그룹](https://nixos.org/manual/nix/stable/installation/multi-user#setting-up-the-build-users)
# 5. default nix profile 생성
# 6. /etc/nix/nix.conf 에 experimental-feature 포함해서 필요하지만 세팅하기 어려운 설정 해줌
# 7. shell profile 설정
# 8. nix daemon을 systemd에 등록
# 9. temp 디렉토리 삭제

curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
