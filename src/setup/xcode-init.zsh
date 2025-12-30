#!/usr/bin/env zsh
# Initialize Xcode after installation
# This script runs the first-launch setup for Xcode and accepts the license
#
# Requirements: Full Xcode must be installed (not just Command Line Tools)
#               This can be done via:
#               - App Store (search for Xcode)
#               - Mac App Store automation: mas install 497799835 (requires 'mas' tool)
#               - Manual download from https://developer.apple.com/download/
#
# This script tracks initialization state in ~/.osa/.xcode-initialized
# to prevent re-running the expensive -runFirstLaunch operation

set -e

echo "Initializing Xcode..."
echo ""

# Check if Xcode is installed
if ! xcode-select -p &>/dev/null; then
  echo "✗ Xcode Command Line Tools not found"
  echo ""
  echo "Install Xcode CLT with:"
  echo "  xcode-select --install"
  return 1
fi

# Verify full Xcode is installed (not just CLT)
if [[ ! -d "/Applications/Xcode.app" ]]; then
  echo "⚠ Full Xcode.app not found in /Applications"
  echo ""
  echo "Only Xcode Command Line Tools are installed. To install full Xcode:"
  echo ""
  echo "Option 1: App Store (recommended)"
  echo "  1. Open App Store"
  echo "  2. Search for 'Xcode'"
  echo "  3. Click Install"
  echo ""
  echo "Option 2: Automated with 'mas' (Mac App Store CLI)"
  echo "  brew install mas"
  echo "  mas install 497799835  # Xcode App Store ID"
  echo ""
  echo "Option 3: Manual download"
  echo "  https://developer.apple.com/download/"
  echo ""
  echo "For now, using Xcode Command Line Tools only..."
  return 0
fi

echo "✓ Xcode.app found"
echo ""

# Initialize tracking
XCODE_INIT_MARKER="$HOME/.osa/.xcode-initialized"
if [[ -f "$XCODE_INIT_MARKER" ]]; then
  echo "✓ Xcode already initialized (tracked in $XCODE_INIT_MARKER)"
  echo ""
  return 0
fi

echo "Running Xcode first-launch initialization..."
echo "This may take several minutes on first run..."
echo ""

# Accept Xcode license agreement
echo "Accepting Xcode license..."
if ! sudo xcodebuild -license accept 2>&1 | tail -5; then
  echo "⚠ License acceptance may have failed, but continuing..."
fi

echo ""

# Run first launch setup
# This downloads additional components and may take 5-15 minutes
echo "Running Xcode -runFirstLaunch (this may take a while)..."
if ! sudo xcodebuild -runFirstLaunch 2>&1 | tail -10; then
  echo "✗ Xcode first-launch setup failed"
  return 1
fi

echo ""
echo "✓ Xcode initialization complete"
echo ""

# Create marker to track initialization
mkdir -p "$HOME/.osa"
touch "$XCODE_INIT_MARKER"
echo "Initialization tracked in: $XCODE_INIT_MARKER"
echo ""

# Verify xcodebuild works
echo "Verifying xcodebuild..."
if xcodebuild -version &>/dev/null; then
  echo "✓ xcodebuild is functional"
  xcodebuild -version
else
  echo "⚠ xcodebuild verification failed"
fi

echo ""

return 0
