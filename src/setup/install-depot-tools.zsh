#!/usr/bin/env zsh
# Install/update depot_tools - Chromium development utilities
# https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html

# Platform detection
local os_type=$(uname -s)

# Check if running on macOS
if [[ "$os_type" == "Darwin" ]]; then
  echo "⚠️  depot_tools is primarily designed for Linux development (especially Chromium builds)"
  echo ""
  echo "⚠️  macOS Support: Limited and not recommended"
  echo "   - depot_tools works better on Linux for Chromium development"
  echo "   - Consider using a Linux machine or WSL 2 for optimal Chromium development"
  echo "   - If you need depot_tools on macOS for specific workflows, run on Linux instead"
  echo ""
  echo "To continue with Chromium development on this macOS machine:"
  echo "  1. Set up a Linux VM or use WSL 2 (recommended)"
  echo "  2. Run depot_tools installation on that Linux environment"
  echo ""
  echo "For more information on Chromium development:"
  echo "  https://chromium.googlesource.com/chromium/src/+/refs/heads/main/docs/mac_build_instructions.md"
  echo ""
  return 0
fi

echo "Installing depot_tools (Chromium development utilities)..."

# Configuration - install to external-libs like other tools
DEPOT_TOOLS_REPO="${DEPOT_TOOLS_REPO:-https://chromium.googlesource.com/chromium/tools/depot_tools.git}"
DEPOT_TOOLS_DIR="${DEPOT_TOOLS_DIR:-$OSA_REPO_PATH/external-libs/depot_tools}"

# Create parent directory if needed
mkdir -p "$(dirname "$DEPOT_TOOLS_DIR")"

# Check if depot_tools is already installed
if [[ -d "$DEPOT_TOOLS_DIR/.git" ]]; then
  echo "Updating depot_tools..."
  cd "$DEPOT_TOOLS_DIR"
  if ! git pull --rebase; then
    echo "✗ Failed to update depot_tools via git pull"
    return 1
  fi
  cd - > /dev/null
else
  # Clone depot_tools if not already present
  echo "Cloning depot_tools from $DEPOT_TOOLS_REPO..."
  
  if ! git clone "$DEPOT_TOOLS_REPO" "$DEPOT_TOOLS_DIR"; then
    echo "✗ Failed to clone depot_tools from $DEPOT_TOOLS_REPO"
    echo "Ensure git is installed and you have internet access"
    return 1
  fi
fi

# Note: depot_tools will be added to PATH via plugin-init/depot-tools.zsh
# which sources the symlink created by initialize-repo-symlinks.zsh

echo "✓ depot_tools installed at: $DEPOT_TOOLS_DIR"
echo ""
echo "To complete setup:"
echo "  1. Restart your shell or run: source ~/.zshrc"
echo "  2. Verify installation: gclient --version"
echo ""
echo "For Chromium development, run:"
echo "  cd ~/chromium_workspace"
echo "  fetch chromium"
echo ""
