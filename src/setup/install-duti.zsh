#!/usr/bin/env zsh
# Install duti - macOS default application manager
# https://github.com/moretension/duti
# 
# duti allows you to set default applications for file types and URL schemes
# from the command line. This is useful for automation and reproducible setups.
#
# Configuration: Custom duti overrides are loaded from the YAML config file
# in the 'duti' section and applied during setup.

echo "Installing duti - macOS default application manager..."

# Check if Homebrew is available
if ! command -v brew &>/dev/null; then
  echo "✗ Homebrew is required but not installed"
  echo "Install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  return 1
fi

# Install duti via Homebrew
if ! brew install duti 2>&1; then
  echo "✗ Failed to install duti via Homebrew"
  return 1
fi

echo "✓ duti installed successfully"
echo ""

# Verify duti is available
if ! command -v duti &>/dev/null; then
  echo "✗ duti command not found after installation"
  return 1
fi

echo "duti is now available. Default app overrides will be applied based on"
echo "your configuration file (duti section)."
echo ""

# Now apply duti configuration overrides if any are defined
configure_script="$(dirname "${(%):-%x}")/../configure-duti.zsh"
if [[ -f "$configure_script" ]]; then
  source "$configure_script"
else
  echo "⚠ configure-duti.zsh not found at $configure_script"
fi

return 0
