#!/usr/bin/env zsh
# Install Java via mise (preferred) or jenv (fallback)

JAVA_VERSION="${JAVA_DEFAULT_VERSION:-openjdk-11}"

echo "Installing Java $JAVA_VERSION..."

# First, try using mise if available
if command -v mise &>/dev/null; then
  echo "Installing Java $JAVA_VERSION via mise..."
  mise use --global "java@$JAVA_VERSION"
  
  if [[ $? -eq 0 ]]; then
    echo "✓ Java $JAVA_VERSION installed via mise"
    return 0
  fi
fi

# Fallback to jenv if mise isn't available
echo "Installing Java via jenv..."

if ! command -v jenv &>/dev/null; then
  echo "Installing jenv (Java version manager)..."
  
  if command -v brew &>/dev/null; then
    brew install jenv
  else
    echo "✗ Homebrew required to install jenv"
    return 1
  fi
  
  export PATH="$HOME/.jenv/bin:$PATH"
  eval "$(jenv init -)"
  echo "✓ jenv installed"
else
  echo "✓ jenv already installed"
  export PATH="$HOME/.jenv/bin:$PATH"
  eval "$(jenv init -)"
fi

echo "Note: You may need to add Java installations to jenv manually:"
echo "  jenv add /path/to/java/installation"
