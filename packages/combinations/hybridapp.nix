# packages/combinations/hybridapp.nix
# Tauri v2 hybrid apps: macOS / Windows / Android / iOS, system-webview frontend.
# Rust (with mobile/windows cross targets) + Node.js + per-platform tooling.
#
# Not nix-packageable, install natively and export:
#   Xcode (iOS)          -> xcode-select / App Store
#   Android SDK/NDK      -> Android Studio sdkmanager; set ANDROID_HOME, NDK_HOME
{ pkgs }:

let
  inherit (pkgs) lib stdenv;

  # Std targets for `cargo tauri android|ios build` and cargo-xwin windows
  # cross builds. iOS triples only on darwin hosts (linking/signing needs Xcode).
  androidTargets = [
    "aarch64-linux-android"
    "armv7-linux-androideabi"
    "i686-linux-android"
    "x86_64-linux-android"
  ];
  iosTargets = lib.optionals stdenv.isDarwin [
    "aarch64-apple-ios"
    "aarch64-apple-ios-sim"
    "x86_64-apple-ios"
  ];
  windowsTargets = [ "x86_64-pc-windows-msvc" ];

  rust = import ../toolchains/rust.nix {
    inherit pkgs;
    targets = androidTargets ++ iosTargets ++ windowsTargets;
  };
  node = import ../toolchains/node.nix { inherit pkgs; };

  # Tauri v2 android needs JDK 17+ and gradle; SDK/NDK come from Android Studio.
  androidTooling = with pkgs; [
    jdk17
    gradle
    kotlin
    android-tools # adb / fastboot
  ];

  # Xcode itself cannot be nix-packaged; cocoapods is the nix-side iOS dep.
  iosTooling = lib.optionals stdenv.isDarwin (with pkgs; [ cocoapods ]);

  # Linux hosts run tauri dev against the GTK/WebKit system webview.
  linuxWebview = lib.optionals stdenv.isLinux (with pkgs; [
    webkitgtk_4_1
    gtk3
    libsoup_3
    librsvg
    glib
    dbus
  ]);
in
{
  packages = rust.packages ++ node.packages ++ androidTooling ++ iosTooling ++ linuxWebview
    ++ (with pkgs; [
    cargo-tauri # tauri CLI v2 (`cargo tauri dev|build|android|ios`)
    cargo-xwin # windows msvc cross builds without a windows box
  ]);

  shellHook = ''
    export JAVA_HOME='${pkgs.jdk17.home}'
    if [ -z "''${ANDROID_HOME:-}" ]; then
      echo "[hybridapp] ANDROID_HOME unset — install SDK/NDK via Android Studio, then export ANDROID_HOME/NDK_HOME for 'cargo tauri android'"
    fi
    if [ "$(uname)" = "Darwin" ] && ! xcode-select -p >/dev/null 2>&1; then
      echo "[hybridapp] Xcode not found — required for 'cargo tauri ios'"
    fi
  '';
}
