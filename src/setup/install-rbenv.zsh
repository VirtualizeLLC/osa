#!/usr/bin/env zsh
# Install Ruby via mise (preferred) or rbenv (fallback)

RUBY_VERSION="${RUBY_DEFAULT_VERSION:-3.2.2}"

echo "Installing Ruby $RUBY_VERSION..."

# First, try using mise if available
if command -v mise &>/dev/null; then
  echo "Installing Ruby $RUBY_VERSION via mise..."
  mise use --global "ruby@$RUBY_VERSION"
  
  if [[ $? -eq 0 ]]; then
    echo "✓ Ruby $RUBY_VERSION installed via mise"
    return 0
  fi
fi

# Fallback to rbenv if mise isn't available
echo "Installing Ruby via rbenv..."

if ! command -v rbenv &>/dev/null; then
  echo "Installing rbenv (Ruby version manager)..."
  
  if command -v brew &>/dev/null; then
    brew install rbenv ruby-build
  else
    echo "✗ Homebrew required to install rbenv"
    return 1
  fi
  
  rbenv init
  echo "✓ rbenv installed"
fi

# Install the specified Ruby version
echo "Installing Ruby $RUBY_VERSION with rbenv..."
rbenv install "$RUBY_VERSION"
rbenv global "$RUBY_VERSION"
echo "✓ Ruby $RUBY_VERSION set as global"
