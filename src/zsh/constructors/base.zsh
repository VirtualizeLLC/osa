#!/usr/bin/env zsh

# Safe source function - fails loudly if file doesn't exist
safe_source() {
  if [[ ! -f "$1" ]]; then
    echo "ERROR: Failed to source '$1' - file not found" >&2
    return 1
  fi
  source "$1"
}

# Load OSA configuration (component enablement flags from setup)
# Skip during setup - use the config that was just loaded instead
if [[ -f "$HOME/.osa-config" ]] && [[ "$OSA_SKIP_CONFIG_LOAD" != "true" ]]; then
  source "$HOME/.osa-config"
fi

# Mise - polyglot runtime manager (MUST BE FIRST for proper precedence)
# Add local binaries to PATH if the directory exists (mise and any other tools installed there)
if [[ -d "$HOME/.local/bin" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

HAS_MISE=$(command -v mise &>/dev/null)
HAS_DIRENV=$(command -v direnv &>/dev/null)

if $HAS_MISE; then
  eval "$(mise activate zsh)" || true
fi

# direnv - environment manager (env vars, secrets, .envrc execution)
if $HAS_DIRENV; then
  eval "$(direnv hook zsh)" || true
fi

safe_source "$OSA_ZSH_PLUGINS/brew.zsh"

# oh-my-zsh
safe_source  "$OSA_ZSH_PLUGINS/oh-my-zsh-config.zsh"

# Android development setup (required for react-native and android development)
# MUST load before react-native since react-native aliases depend on adb being in PATH

# Must be loaded first to set ANDROID_HOME and PATH

if [[ "${OSA_CONFIG_COMPONENTS_ANDROID}" == "true" ]]; then
  safe_source "$OSA_ZSH_PLUGINS/android-sdk.zsh"
fi

# Depot tools for Chromium development
safe_source "$OSA_ZSH_PLUGINS/depot-tools.zsh"

# OSA CLI runtime - exposes 'osa-setup' command for quick access
# Noting that `osa` CLI is installed via osa-scripts repo and can run osa-setup by doing `osa setup`
safe_source "$OSA_ZSH_ALIASES/osa-setup.zsh"

# Set OSA_CONFIG to the OSA installation directory
OSA_CONFIG="${0:A:h:h:h:h}"

# Define OSA paths
export OSA_ZSH_PLUGINS=$OSA_CONFIG/src/zsh/plugin-init
export OSA_ZSH_ALIASES=$OSA_CONFIG/src/zsh/aliases

# Snippets - community shell helpers
if [[ ! $OSA_SKIP_SNIPPETS ]] ; then
  SNIPPETS_ENTRY="$OSA_CONFIG/src/zsh/snippets/entry.zsh"
  if [[ -f "$SNIPPETS_ENTRY" ]]; then
    source "$SNIPPETS_ENTRY" 2>/dev/null || {
      echo "WARNING: Failed to source osa-snippets from $SNIPPETS_ENTRY" >&2
    }
  else
    echo "WARNING: osa-snippets not found at $SNIPPETS_ENTRY" >&2
    echo "         Run './osa-cli.zsh --setup' to install it" >&2
  fi
fi