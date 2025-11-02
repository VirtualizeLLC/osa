#!/usr/bin/env zsh

# OSA Git Setup
# ============
# This script:
# 1. Ensures git binary is installed (required for OSA to function)
# 2. Optionally configures git global settings (can be skipped with --disable-git):
#    - init.defaultBranch: Set to 'main' (customizable via GIT_DEFAULT_BRANCH env var)
#    - core.excludesFile: Set to OSA's .gitignore_global (respects existing config)
#
# Use --disable-git to skip all configuration while still ensuring git is installed

# Ensure git is installed (always, regardless of OSA_SKIP_GIT_CONFIG)
# This is needed for basic OSA operations like cloning repos
if [[ "$OSA_IS_MACOS" == "true" ]] && [[ $(command -v git) != "/usr/local/bin/git" ]]; then 
  echo "Installing latest git with brew..."
  brew install git
fi

# Skip git configuration if disabled
# This only skips setting default branch and global gitignore
if [[ "$OSA_SKIP_GIT_CONFIG" == "true" ]]; then
  echo "⊘ Git configuration skipped (--disable-git)"
  echo "  Git binary is still installed/updated"
  return 0
fi

echo "Configuring Git..."
echo ""

# Configure git - respect user's existing config
echo "Setting default branch to '${GIT_DEFAULT_BRANCH:-main}'..."
git config --global init.defaultBranch "${GIT_DEFAULT_BRANCH:-main}"
echo "  ✓ init.defaultBranch = ${GIT_DEFAULT_BRANCH:-main}"

# Configure global gitignore (only if not already set)
if [[ -z "$(git config --global core.excludesFile)" ]] && [[ -d "$OSA_CONFIG" ]]; then
  git config --global core.excludesFile "$OSA_CONFIG/.gitignore_global"
  echo "  ✓ core.excludesFile = $OSA_CONFIG/.gitignore_global (OSA's global ignore patterns)"
elif [[ -d "$OSA_CONFIG" ]]; then
  current_ignore=$(git config --global core.excludesFile)
  if [[ "$current_ignore" != "$OSA_CONFIG/.gitignore_global" ]]; then
    echo "  ℹ core.excludesFile already configured: $current_ignore"
    echo "    (To use OSA's: git config --global core.excludesFile $OSA_CONFIG/.gitignore_global)"
  else
    echo "  ✓ core.excludesFile = $OSA_CONFIG/.gitignore_global"
  fi
fi

echo ""
echo "✓ Git configuration complete"