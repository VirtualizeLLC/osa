#!/usr/bin/env zsh
# Install CocoaPods
# Works with any Ruby 2.7.5 or higher (e.g. 3.2.2, 3.3.0, 3.4.0, etc)

echo "Installing CocoaPods..."

# Set up GEM_HOME to user directory to avoid permission issues
# This ensures gem install writes to ~/.gem instead of system directories
export GEM_HOME="$HOME/.gem"
export PATH="$GEM_HOME/bin:$PATH"

# Create gem directories if they don't exist
mkdir -p "$GEM_HOME/bin" "$GEM_HOME/specs" 2>/dev/null || true

# Try installing with --user-install flag first (avoids permission issues)
if gem install cocoapods --user-install 2>&1; then
  echo "✓ CocoaPods $(pod --version) installed successfully"
  exit 0
else
  # Fallback to standard install
  echo "⚠ Standard gem install attempt..."
  if gem install cocoapods 2>&1; then
    if command -v pod &>/dev/null; then
      echo "✓ CocoaPods $(pod --version) installed successfully"
      exit 0
    else
      echo "✗ CocoaPods installation verification failed"
      exit 1
    fi
  else
    echo "✗ Failed to install CocoaPods"
    echo "→ This usually means the gem directory doesn't have write permissions"
    echo "→ Try running: sudo gem install cocoapods"
    exit 1
  fi
fi