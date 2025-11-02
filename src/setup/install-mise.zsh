#!/usr/bin/env zsh
# Install mise - a polyglot runtime manager
# https://mise.jdx.dev/
# 
# NOTE: We prevent mise from modifying shell config files because we manage
# shell initialization ourselves via our .zshrc symlink and constructors

echo "Installing mise (polyglot runtime manager)..."

if command -v mise &>/dev/null; then
  echo "✓ mise already installed at $(command -v mise)"
  
  # Update existing installation
  if [[ "$OSA_VERBOSE" == "true" ]]; then
    echo "Updating mise..."
    mise self-update || true
  else
    mise self-update > /dev/null 2>&1 || true
  fi
else
  # Install mise with MISE_QUIET to skip interactive prompts
  # Use --no-modify-path to prevent modifying shell configs
  if [[ "$OSA_VERBOSE" == "true" ]]; then
    MISE_QUIET=1 MISE_NO_SHELLRC_UPDATE=1 curl -fsSL https://mise.run | sh
  else
    MISE_QUIET=1 MISE_NO_SHELLRC_UPDATE=1 curl -fsSL https://mise.run | sh > /dev/null 2>&1
  fi
  
  # Add mise to PATH for current session
  export PATH="$HOME/.local/bin:$PATH"
  
  if command -v mise &>/dev/null; then
    echo "✓ mise installed successfully"
  else
    echo "✗ mise installation failed"
    return 1
  fi
fi

# Activate mise shims for current session
export PATH="$HOME/.local/bin:$PATH"

# Ensure mise is in PATH and ready
if ! command -v mise &>/dev/null; then
  echo "✗ mise not found in PATH after installation"
  return 1
fi

echo "✓ mise ready to use"

# Configure runtimes in .mise.toml if environment variables are set
if [[ -n "$MISE_NODE_VERSION" ]] || [[ -n "$MISE_PYTHON_VERSION" ]] || [[ -n "$MISE_RUBY_VERSION" ]] || [[ -n "$MISE_JAVA_VERSION" ]] || [[ -n "$MISE_GO_VERSION" ]] || [[ -n "$MISE_RUST_VERSION" ]] || [[ -n "$MISE_DENO_VERSION" ]] || [[ -n "$MISE_ELIXIR_VERSION" ]] || [[ -n "$MISE_ERLANG_VERSION" ]]; then
  
  if [[ -z "$OSA_REPO_PATH" ]]; then
    echo "✗ Error: OSA_REPO_PATH not set"
    return 1
  fi
  
  MISE_TOML="$OSA_REPO_PATH/.mise.toml"
  
  echo ""
  echo "Configuring .mise.toml with selected runtimes..."
  
  # Create a temporary file with the new config
  local temp_toml=$(mktemp)
  cp "$MISE_TOML" "$temp_toml"
  
  # Update each runtime in .mise.toml if set
  if [[ -n "$MISE_NODE_VERSION" ]]; then
    echo "  → Node.js: $MISE_NODE_VERSION"
    sed -i '' 's/^node = .*/node = "'$MISE_NODE_VERSION'"/' "$temp_toml"
  fi
  
  if [[ -n "$MISE_PYTHON_VERSION" ]]; then
    echo "  → Python: $MISE_PYTHON_VERSION"
    sed -i '' 's/^# python = .*/python = "'$MISE_PYTHON_VERSION'"/' "$temp_toml"
    sed -i '' 's/^python = "3.11".*/python = "'$MISE_PYTHON_VERSION'"/' "$temp_toml"
  fi
  
  if [[ -n "$MISE_RUBY_VERSION" ]]; then
    echo "  → Ruby: $MISE_RUBY_VERSION"
    sed -i '' 's/^# ruby = .*/ruby = "'$MISE_RUBY_VERSION'"/' "$temp_toml"
  fi
  
  if [[ -n "$MISE_JAVA_VERSION" ]]; then
    echo "  → Java: $MISE_JAVA_VERSION"
    sed -i '' 's/^# java = .*/java = "'$MISE_JAVA_VERSION'"/' "$temp_toml"
  fi
  
  if [[ -n "$MISE_GO_VERSION" ]]; then
    echo "  → Go: $MISE_GO_VERSION"
    sed -i '' 's/^# go = .*/go = "'$MISE_GO_VERSION'"/' "$temp_toml"
  fi
  
  if [[ -n "$MISE_RUST_VERSION" ]]; then
    echo "  → Rust: $MISE_RUST_VERSION"
    sed -i '' 's/^# rust = .*/rust = "'$MISE_RUST_VERSION'"/' "$temp_toml"
  fi
  
  if [[ -n "$MISE_DENO_VERSION" ]]; then
    echo "  → Deno: $MISE_DENO_VERSION"
    sed -i '' 's/^# deno = .*/deno = "'$MISE_DENO_VERSION'"/' "$temp_toml"
  fi
  
  if [[ -n "$MISE_ELIXIR_VERSION" ]]; then
    echo "  → Elixir: $MISE_ELIXIR_VERSION"
    sed -i '' 's/^# elixir = .*/elixir = "'$MISE_ELIXIR_VERSION'"/' "$temp_toml"
  fi
  
  if [[ -n "$MISE_ERLANG_VERSION" ]]; then
    echo "  → Erlang: $MISE_ERLANG_VERSION"
    sed -i '' 's/^# erlang = .*/erlang = "'$MISE_ERLANG_VERSION'"/' "$temp_toml"
  fi
  
  # Replace the original file with updated version
  mv "$temp_toml" "$MISE_TOML"
  
  echo ""
  echo "Installing configured runtimes..."
  cd "$OSA_REPO_PATH" && mise install || {
    echo "⚠ Warning: mise install had issues, but continuing..."
  }
  
  # Setup global mise context (unless --local flag is set)
  if [[ "$OSA_SKIP_MISE_GLOBAL" != "true" ]]; then
    echo ""
    echo "Setting up mise for OSA repository..."
    
    cd "$OSA_REPO_PATH"
    
    # Simply use the local .mise.toml - no need for global config
    # Mise will automatically pick it up when entering the directory
    echo "✓ Mise configured - run 'cd $OSA_REPO_PATH' to activate"
  fi
  
  echo ""
  echo "✓ Mise installation complete"
else
  echo "No specific runtimes selected, skipping .mise.toml configuration"
fi

