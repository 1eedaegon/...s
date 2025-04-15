{ pkgs, system }:
let
  iterm2-settings = pkgs.stdenv.mkDerivation {
    name = "iterm2-settings";
    version = "1.0.0";
    
    buildCommand = ''
      # Nix store에 설정 디렉토리 생성
      mkdir -p $out/share/iterm2
      
      # 컬러 스키마 다운로드
      ${pkgs.curl}/bin/curl --cacert ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt -L https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/schemes/Snazzy.itermcolors -o $out/share/iterm2/Snazzy.itermcolors
      
      # 설정 스크립트 생성
      mkdir -p $out/bin
      cat > $out/bin/setup-iterm2 << EOF
      #!/bin/sh
      
      # iTerm2 설정 디렉토리
      ITERM2_DIR="\$HOME/Library/Application Support/iTerm2"
      mkdir -p "\$ITERM2_DIR"
      
      # 컬러 스키마 복사
      ln -sf $out/share/iterm2/Snazzy.itermcolors "\$ITERM2_DIR/"
      
      # 폰트 설정 (폰트가 설치되어 있는지 확인)
      if [ -f "\$HOME/Library/Fonts/Hack Regular Nerd Font Complete.ttf" ]; then
        # New Bookmarks 설정
        defaults write com.googlecode.iterm2 "New Bookmarks" -array-add '{
          "Name" = "Default";
          "Guid" = "Snazzy";
          "Normal Font" = "Hack Nerd Font 14";
          "Non Ascii Font" = "Hack Nerd Font 14";
          "Use Non-ASCII Font" = 0;
          "Horizontal Spacing" = 1;
          "Vertical Spacing" = 1;
          "Use Bold Font" = 1;
          "Use Italic Font" = 1;
          "ASCII Anti Aliased" = 1;
          "Non-ASCII Anti Aliased" = 1;
          "Unlimited Scrollback" = 1;
          "Custom Directory" = "Recycle";
          "Default Bookmark" = "Yes";
        }'
        
        # 기본 북마크 설정
        defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "Snazzy"
      else
        echo "Warning: Hack Nerd Font not found. Please install it first."
      fi
      
      # 설정 완료 표시
      touch "\$ITERM2_DIR/.nix-setup"
      
      echo "iTerm2 설정이 완료되었습니다."
      echo "iTerm2를 재시작하면 설정이 적용됩니다."
      EOF
      chmod +x $out/bin/setup-iterm2

      # 제거 스크립트 생성
      cat > $out/bin/remove-iterm2 << EOF
      #!/bin/sh
      
      # iTerm2 설정 디렉토리
      ITERM2_DIR="\$HOME/Library/Application Support/iTerm2"
      
      # Nix로 설정된 파일들 제거
      if [ -f "\$ITERM2_DIR/.nix-setup" ]; then
        rm -f "\$ITERM2_DIR/Snazzy.itermcolors"
        rm -f "\$ITERM2_DIR/.nix-setup"
        
        # 기본 설정으로 복원
        defaults delete com.googlecode.iterm2 "New Bookmarks"
        defaults delete com.googlecode.iterm2 "Default Bookmark Guid"
        
        echo "iTerm2 설정이 제거되었습니다."
        echo "iTerm2를 재시작하면 설정이 초기화됩니다."
      fi
      EOF
      chmod +x $out/bin/remove-iterm2
    '';

    # postInstall hook: 설정 자동 적용
    postInstall = ''
      mkdir -p $out/etc/profile.d
      cat > $out/etc/profile.d/iterm2-setup.sh << EOF
      #!/bin/sh
      if [ ! -f "\$HOME/Library/Application Support/iTerm2/.nix-setup" ]; then
        $out/bin/setup-iterm2
      fi
      EOF
      chmod +x $out/etc/profile.d/iterm2-setup.sh
    '';

    # postRemove hook: 설정 자동 제거
    postRemove = ''
      $out/bin/remove-iterm2
    '';
  };
in
  if system == "x86_64-darwin" || system == "aarch64-darwin" then iterm2-settings else null