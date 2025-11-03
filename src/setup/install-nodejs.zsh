#!/usr/bin/env zsh
# Install Node.js via mise (preferred) or fnm (fallback)
source "$OSA_SCRIPTS_ROOT/src/zsh/helpers/get-node-version.zsh"

NODE_VERSION=$(get-node-version)

# First, try using mise if available
if command -v mise &>/dev/null; then
  echo "Installing Node.js $NODE_VERSION via mise..."
  mise use --global "node@$NODE_VERSION"
  
  if [[ $? -eq 0 ]]; then
    echo "✓ Node.js $NODE_VERSION installed via mise"
    return 0
  fi
fi
