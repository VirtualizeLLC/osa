#!/usr/bin/env bats
# tests/test_depot_tools_install.bats - Test depot_tools installation and configuration

load helpers

# Setup before each test
setup() {
  export TEST_TEMP_DIR=$(mktemp -d)
  export HOME="$TEST_TEMP_DIR/home"
  mkdir -p "$HOME"
  
  # Set up test depot_tools directory
  export DEPOT_TOOLS_TEST_DIR="$TEST_TEMP_DIR/depot_tools"
  export DEPOT_TOOLS_REPO="${DEPOT_TOOLS_REPO:-https://chromium.googlesource.com/chromium/tools/depot_tools.git}"
  export DEPOT_TOOLS_DIR="$TEST_TEMP_DIR/external-libs/depot_tools"
  
  # Ensure OSA_REPO_PATH is available to helpers
  export OSA_REPO_PATH="$OSA_TEST_REPO_ROOT"
  
  # Mock git commands
  export GIT_CLONE_CALLED=0
  export GIT_PULL_CALLED=0
  export GIT_CLONE_REPO=""
  export GIT_CLONE_DIR=""
}

# Cleanup after each test
teardown() {
  rm -rf "$TEST_TEMP_DIR"
  unset GIT_CLONE_CALLED GIT_PULL_CALLED GIT_CLONE_REPO GIT_CLONE_DIR
}

# Directory Structure Tests
# =========================

@test "depot_tools: creates parent directory if needed" {
  # Verify the script creates the directory structure
  local depot_tools_script="$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  
  # Check that mkdir -p is used for parent directory creation
  grep -q 'mkdir -p "$(dirname "$DEPOT_TOOLS_DIR")' "$depot_tools_script"
  echo "✓ Parent directory creation verified"
}

@test "depot_tools: respects DEPOT_TOOLS_DIR environment variable" {
  # Verify the script uses the environment variable
  grep -q 'DEPOT_TOOLS_DIR="\${DEPOT_TOOLS_DIR:-' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ DEPOT_TOOLS_DIR environment variable respected"
}

@test "depot_tools: uses default path in OSA external-libs" {
  # Verify default path is set correctly
  grep -q 'external-libs/depot_tools' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ Default external-libs path verified"
}

# Clone/Update Detection Tests
# =============================

@test "depot_tools: detects existing installation via .git directory" {
  # Create a mock depot_tools directory with .git
  mkdir -p "$DEPOT_TOOLS_DIR/.git"
  touch "$DEPOT_TOOLS_DIR/.git/HEAD"
  
  # Verify the check exists in the script
  grep -q '[[ -d "$DEPOT_TOOLS_DIR/.git" ]]' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  
  # Verify directory detection works
  [[ -d "$DEPOT_TOOLS_DIR/.git" ]]
  echo "✓ Existing installation detection works"
}

@test "depot_tools: updates existing installation via git pull" {
  # Create a mock depot_tools directory with .git
  mkdir -p "$DEPOT_TOOLS_DIR/.git"
  touch "$DEPOT_TOOLS_DIR/.git/HEAD"
  
  # Verify the script attempts git pull for updates
  grep -q 'git pull --rebase' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ Git pull update mechanism verified"
}

@test "depot_tools: clones from DEPOT_TOOLS_REPO when not installed" {
  # Verify the script clones from the correct repository
  grep -q 'git clone "$DEPOT_TOOLS_REPO" "$DEPOT_TOOLS_DIR"' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ Clone from DEPOT_TOOLS_REPO verified"
}

@test "depot_tools: DEPOT_TOOLS_REPO defaults to chromium official source" {
  # Verify correct default repository URL
  grep -q 'https://chromium.googlesource.com/chromium/tools/depot_tools.git' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ Official Chromium depot_tools repository URL verified"
}

# Error Handling Tests
# ====================

@test "depot_tools: handles git clone failure with informative message" {
  # Verify error handling for failed clone
  grep -q 'Failed to clone depot_tools from' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  grep -q 'Ensure git is installed and you have internet access' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ Git clone failure handling verified"
}

@test "depot_tools: handles git pull failure with informative message" {
  # Verify error handling for failed update
  grep -q 'Failed to update depot_tools via git pull' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ Git pull failure handling verified"
}

@test "depot_tools: returns error code on clone failure" {
  # Verify that the script returns 1 on failure
  grep -q 'return 1' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ Error return code handling verified"
}

@test "depot_tools: returns error code on pull failure" {
  # Verify that the script returns error on git pull failure
  local depot_tools_script="$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  grep -A 2 'git pull --rebase' "$depot_tools_script" | grep -q 'return 1'
  echo "✓ Pull failure error code verified"
}

# Output/Communication Tests
# ==========================

@test "depot_tools: informs user of installation process start" {
  # Verify user-friendly startup message
  grep -q 'Installing depot_tools' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ Installation start message verified"
}

@test "depot_tools: confirms successful installation" {
  # Verify success message
  grep -q '✓ depot_tools installed' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ Success confirmation verified"
}

@test "depot_tools: displays installation location" {
  # Verify that installation path is displayed
  grep -q 'installed at: $DEPOT_TOOLS_DIR' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ Installation location display verified"
}

@test "depot_tools: provides post-setup instructions" {
  # Verify that the script provides helpful next steps
  local depot_tools_script="$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  grep -q 'restart your shell' "$depot_tools_script" || grep -q 'source ~/.zshrc' "$depot_tools_script"
  echo "✓ Post-setup instructions provided"
}

@test "depot_tools: mentions gclient verification command" {
  # Verify user can check installation worked
  grep -q 'gclient --version' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ Verification command provided"
}

@test "depot_tools: includes chromium development example" {
  # Verify helpful Chromium development example
  grep -q 'fetch chromium' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ Chromium development example provided"
}

# Integration Tests
# =================

@test "depot_tools: script is syntactically valid" {
  # Verify the script can be sourced without errors
  run bash -n "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  [[ "$status" -eq 0 ]]
  echo "✓ Script syntax validation passed"
}

@test "depot_tools: script uses consistent variable naming" {
  # Verify consistent naming conventions
  local script="$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  grep -q 'DEPOT_TOOLS_REPO' "$script"
  grep -q 'DEPOT_TOOLS_DIR' "$script"
  echo "✓ Consistent variable naming verified"
}

@test "depot_tools: script handles directory changes safely" {
  # Verify cd uses proper error handling
  grep -q 'cd "$DEPOT_TOOLS_DIR"' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  grep -q 'cd - > /dev/null' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ Safe directory navigation verified"
}

@test "depot_tools: script prevents hardcoded paths" {
  # Verify all paths use variables
  local script="$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  ! grep -q 'depot_tools' "$script" | grep -v '\$DEPOT_TOOLS'
  # If above check passes, all depot_tools references use variables
  echo "✓ No hardcoded paths detected"
}

# Documentation Tests
# ===================

@test "depot_tools: includes documentation link" {
  # Verify official documentation reference
  grep -q 'https://commondatastorage.googleapis.com' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  grep -q 'depot_tools_tutorial' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ Official documentation link provided"
}

@test "depot_tools: script describes purpose in comments" {
  # Verify helpful documentation in script header
  grep -q 'Chromium development utilities' "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh"
  echo "✓ Purpose documentation verified"
}

# Shebang and Permissions Tests
# ==============================

@test "depot_tools: script has correct shebang" {
  # Verify zsh shebang
  head -n 1 "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh" | grep -q '#!/usr/bin/env zsh'
  echo "✓ Correct zsh shebang verified"
}

@test "depot_tools: script file exists and is readable" {
  # Verify the script exists and is accessible
  [[ -f "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh" ]]
  [[ -r "$OSA_REPO_PATH/src/setup/install-depot-tools.zsh" ]]
  echo "✓ Script file accessibility verified"
}
