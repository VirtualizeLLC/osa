#!/usr/bin/env zsh
# Install/update depot_tools - Chromium development utilities
# https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html

echo "Installing depot_tools (Chromium development utilities)..."

# Configuration
DEPOT_TOOLS_REPO="${DEPOT_TOOLS_REPO:-https://chromium.googlesource.com/chromium/tools/depot_tools.git}"
DEPOT_TOOLS_DIR="${DEPOT_TOOLS_DIR:-$HOME/.depot_tools}"

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

# Add depot_tools to PATH via shell configuration
# This should be sourced during shell initialization
export PATH="$DEPOT_TOOLS_DIR:$PATH"

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
