#!/usr/bin/env bash
set -euo pipefail

# Re-runnable Chromium bootstrap for Linux server (Android + Linux builds)
# - zsh + oh-my-zsh friendly: ensures depot_tools PATH in ~/.zshrc
# - resumable: safe to re-run after disconnects
#
# Usage:
#   ./chromium_bootstrap.sh setup
#   ./chromium_bootstrap.sh fetch
#   ./chromium_bootstrap.sh sync
#   ./chromium_bootstrap.sh gen
#   ./chromium_bootstrap.sh build-android
#   ./chromium_bootstrap.sh build-linux
#   ./chromium_bootstrap.sh all
#
# Optional env:
#   CHROMIUM_DIR=~/chromium
#   ANDROID_OUT=out/Android
#   LINUX_OUT=out/Linux
#   ANDROID_CPU=arm64|arm|x64
#   ANDROID_DEBUG=0|1
#   LINUX_DEBUG=0|1
#   JOBS=32

CHROMIUM_DIR="${CHROMIUM_DIR:-$HOME/chromium}"
DEPOT_TOOLS_DIR="${DEPOT_TOOLS_DIR:-$HOME/depot_tools}"
ZSHRC="${ZSHRC:-$HOME/.zshrc}"

ANDROID_OUT="${ANDROID_OUT:-out/Android}"
LINUX_OUT="${LINUX_OUT:-out/Linux}"

ANDROID_CPU="${ANDROID_CPU:-arm64}"
ANDROID_DEBUG="${ANDROID_DEBUG:-0}"
LINUX_DEBUG="${LINUX_DEBUG:-0}"

JOBS="${JOBS:-$(nproc)}"

log() { printf "\n\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m[warn]\033[0m %s\n" "$*"; }
die() { printf "\n\033[1;31m[err]\033[0m %s\n" "$*"; exit 1; }

ensure_depot_tools() {
  log "Ensuring depot_tools in $DEPOT_TOOLS_DIR"
  if [ ! -d "$DEPOT_TOOLS_DIR" ]; then
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "$DEPOT_TOOLS_DIR"
  else
    (cd "$DEPOT_TOOLS_DIR" && git pull --ff-only) || true
  fi

  log "Ensuring depot_tools PATH in $ZSHRC (idempotent)"
  if ! grep -q '>>> chromium depot_tools >>>' "$ZSHRC" 2>/dev/null; then
    cat <<'ZEOF' >> "$ZSHRC"

# >>> chromium depot_tools >>>
if [ -d "$HOME/depot_tools" ]; then
  export PATH="$HOME/depot_tools:$PATH"
fi
# <<< chromium depot_tools <<<
ZEOF
  fi

  export PATH="$DEPOT_TOOLS_DIR:$PATH"
}

install_os_deps() {
  log "Installing OS deps (Ubuntu/Debian)"
  sudo apt update
  sudo apt upgrade -y
  sudo apt install -y \
    git curl wget ca-certificates \
    python3 python3-pip \
    build-essential pkg-config \
    clang lld ninja-build \
    zip unzip tar \
    openjdk-17-jdk \
    tmux
}

fetch_chromium() {
  ensure_depot_tools
  log "Fetching chromium into $CHROMIUM_DIR (resumable)"
  mkdir -p "$CHROMIUM_DIR"
  cd "$CHROMIUM_DIR"
  if [ -d "$CHROMIUM_DIR/src/.git" ]; then
    log "Chromium already present (src/.git exists). Skipping fetch."
    return 0
  fi
  fetch chromium
}

sync_chromium() {
  ensure_depot_tools
  log "Syncing (gclient sync) in $CHROMIUM_DIR/src"
  cd "$CHROMIUM_DIR/src"
  gclient sync
}

install_chromium_build_deps() {
  ensure_depot_tools
  log "Installing Chromium Linux build deps"
  cd "$CHROMIUM_DIR/src"
  sudo env "PATH=$PATH" build/install-build-deps.sh

  log "Installing Chromium Android build deps"
  sudo env "PATH=$PATH" build/install-build-deps-android.sh
}

gen_gn() {
  ensure_depot_tools
  cd "$CHROMIUM_DIR/src"

  local android_is_debug="false"
  local linux_is_debug="false"
  if [ "$ANDROID_DEBUG" = "1" ]; then android_is_debug="true"; fi
  if [ "$LINUX_DEBUG" = "1" ]; then linux_is_debug="true"; fi

  log "GN gen: Android ($ANDROID_CPU) -> $ANDROID_OUT"
  gn gen "$ANDROID_OUT" --args="
target_os=\"android\"
target_cpu=\"$ANDROID_CPU\"
is_debug=$android_is_debug
is_component_build=false
symbol_level=0
"

  log "GN gen: Linux -> $LINUX_OUT"
  gn gen "$LINUX_OUT" --args="
is_debug=$linux_is_debug
is_component_build=false
symbol_level=0
"
}

build_android() {
  ensure_depot_tools
  cd "$CHROMIUM_DIR/src"
  log "Building Android APK (chrome_public_apk) with -j $JOBS"
  ninja -C "$ANDROID_OUT" -j "$JOBS" chrome_public_apk
  log "APK should be at: $CHROMIUM_DIR/src/$ANDROID_OUT/apks/ChromePublic.apk"
}

build_linux() {
  ensure_depot_tools
  cd "$CHROMIUM_DIR/src"
  log "Building Linux chrome with -j $JOBS"
  ninja -C "$LINUX_OUT" -j "$JOBS" chrome
  log "Binary should be at: $CHROMIUM_DIR/src/$LINUX_OUT/chrome"
}

print_help() {
  cat <<EOM
chromium_bootstrap.sh - repeatable Chromium setup/build helper

Commands:
  setup         Install OS deps + depot_tools PATH hook
  fetch         fetch chromium (creates ~/chromium/src)
  sync          gclient sync
  deps          run install-build-deps.sh + install-build-deps-android.sh
  gen           gn gen out dirs (Android + Linux)
  build-android ninja chrome_public_apk
  build-linux   ninja chrome
  all           setup + fetch + sync + deps + gen

Env overrides:
  CHROMIUM_DIR, DEPOT_TOOLS_DIR, ANDROID_OUT, LINUX_OUT,
  ANDROID_CPU (arm64|arm|x64), ANDROID_DEBUG (0|1), LINUX_DEBUG (0|1), JOBS

Examples:
  ./chromium_bootstrap.sh all
  ./chromium_bootstrap.sh build-android
  ANDROID_DEBUG=1 ./chromium_bootstrap.sh gen
EOM
}

cmd="${1:-help}"
case "$cmd" in
  setup)
    install_os_deps
    ensure_depot_tools
    log "Done. Run: source ~/.zshrc"
    ;;
  fetch)
    fetch_chromium
    ;;
  sync)
    sync_chromium
    ;;
  deps)
    install_chromium_build_deps
    ;;
  gen)
    gen_gn
    ;;
  build-android)
    build_android
    ;;
  build-linux)
    build_linux
    ;;
  all)
    install_os_deps
    ensure_depot_tools
    fetch_chromium
    sync_chromium
    install_chromium_build_deps
    gen_gn
    log "All done. Next: ./chromium_bootstrap.sh build-android  (or build-linux)"
    ;;
  help|-h|--help|"")
    print_help
    ;;
  *)
    die "Unknown command: $cmd (run with 'help')"
    ;;
esac