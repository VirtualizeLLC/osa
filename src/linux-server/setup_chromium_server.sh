#!/usr/bin/env bash
set -euo pipefail

echo "== Chromium Android + Linux server setup =="

# -------- config --------
CHROMIUM_DIR="$HOME/chromium"
DEPOT_TOOLS_DIR="$HOME/depot_tools"
ZSHRC="$HOME/.zshrc"
JOBS="$(nproc)"
# ------------------------

echo "== Updating system =="
sudo apt update
sudo apt upgrade -y

echo "== Installing base packages =="
sudo apt install -y \
  git curl wget ca-certificates \
  python3 python3-pip \
  build-essential pkg-config \
  clang lld ninja-build \
  zip unzip tar \
  openjdk-17-jdk \
  tmux

echo "== Installing depot_tools =="
if [ ! -d "$DEPOT_TOOLS_DIR" ]; then
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "$DEPOT_TOOLS_DIR"
else
  cd "$DEPOT_TOOLS_DIR"
  git pull
fi

echo "== Ensuring depot_tools is in ~/.zshrc =="
if ! grep -q 'chromium depot_tools' "$ZSHRC"; then
  cat <<'ZEOF' >> "$ZSHRC"

# >>> chromium depot_tools >>>
if [ -d "$HOME/depot_tools" ]; then
  export PATH="$HOME/depot_tools:$PATH"
fi
# <<< chromium depot_tools <<<
ZEOF
fi

export PATH="$DEPOT_TOOLS_DIR:$PATH"

echo "== Verifying depot_tools =="
which gclient gn autoninja || true

echo "== Creating chromium workspace =="
mkdir -p "$CHROMIUM_DIR"
cd "$CHROMIUM_DIR"

if [ ! -d "$CHROMIUM_DIR/src" ]; then
  echo "== Fetching Chromium (this takes a long time) =="
  fetch chromium
else
  echo "== Chromium already fetched =="
fi

cd "$CHROMIUM_DIR/src"

echo "== Syncing dependencies (this also takes a long time) =="
gclient sync

echo "== Installing Linux build dependencies =="
sudo env "PATH=$PATH" build/install-build-deps.sh

echo "== Installing Android build dependencies =="
sudo env "PATH=$PATH" build/install-build-deps-android.sh

echo "== Generating GN configs =="

echo "  -> Android (arm64)"
gn gen out/Android --args='
target_os="android"
target_cpu="arm64"
is_debug=false
is_component_build=false
symbol_level=0
'

echo "  -> Linux"
gn gen out/Linux --args='
is_debug=false
is_component_build=false
symbol_level=0
'

cat <<EOM

====================================================
SETUP COMPLETE 🎉

Next steps (run inside tmux):

  tmux new -s chromium

Build Android:
  cd ~/chromium/src
  ninja -C out/Android chrome_public_apk

Build Linux:
  cd ~/chromium/src
  ninja -C out/Linux chrome

APK:
  out/Android/apks/ChromePublic.apk

Binary:
  out/Linux/chrome

Restart your shell or run:
  source ~/.zshrc
====================================================

EOM