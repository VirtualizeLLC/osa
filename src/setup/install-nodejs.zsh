#!/usr/bin/env zsh
# Install Node.js via mise (preferred) or fnm (fallback)

get-node-version(){
  # If DEFAULT_NODE_VERSION is set, prefer it as the source of truth
  if [ -n "$DEFAULT_NODE_VERSION" ] ; then
    echo "$DEFAULT_NODE_VERSION"
    return 0
  fi

  # Otherwise, if the repo provides a .node-version file, use it
  if [ -f "$OSA_CONFIG/.node-version" ]; then
    cat "$OSA_CONFIG/.node-version"
  else
    echo "18"
  fi
}

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

# Fallback to fnm if mise isn't available
echo "Installing Node.js $NODE_VERSION via fnm..."

# Install perl if not present (required by some Node modules)
if ! command -v perl &>/dev/null; then
  if command -v brew &>/dev/null; then
    brew install perl
  else
    echo "Warning: perl not found and Homebrew not available to install it"
  fi
fi

# FNM install
# Its 40x faster than NVM
# https://github.com/Schniz/fnm
if ! command -v fnm &>/dev/null; then
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir $HOME/.fnm --skip-shell
  eval "$(fnm env)"
  fnm install "$NODE_VERSION"
  echo "✓ Node.js $NODE_VERSION installed via fnm"
else
  echo "✓ fnm already installed"
  fnm install "$NODE_VERSION"
fi

