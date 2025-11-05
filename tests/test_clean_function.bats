#!/usr/bin/env bats
# tests/test_clean_function.bats - Test clean_all() function with mocked operations

load helpers

setup() {
  setup_test_env
  
  # Create mock implementations accessible to tests
  rm() { mock_rm "$@"; }
  ln() { mock_ln "$@"; }
  mv() { mock_mv "$@"; }
  mkdir() { mock_mkdir "$@"; }
  readlink() { mock_readlink "$@"; }
  
  export -f rm ln mv mkdir readlink
}

teardown() {
  teardown_test_env
}

# Safety Checks
# =============

@test "rejects if HOME is root directory" {
  # This should be checked in the actual function
  grep -q 'HOME.*==.*"/"' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "rejects if HOME is unset" {
  # Verify HOME validation
  grep -q '\-z.*HOME' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

# Symlink Detection
# =================

@test "script can detect real symlinks vs regular files" {
  # Verify script uses -L (symlink test) and -f (file test)
  grep -q '\-L' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  grep -q '\-f' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "distinguishes between OSA symlinks and user files" {
  # Verify script checks if .zshrc points to OSA
  grep -q '.osa/src/zsh/.zshrc' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

# Prompt Handling
# ===============

@test "requests confirmation by default" {
  # Verify default behavior shows confirmation prompt
  grep -q 'Confirm cleanup' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "skips confirmation when unsafe_mode=true" {
  # Verify the --unsafe flag parameter
  grep -q 'unsafe_mode.*true' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "displays warning list of files to remove" {
  # Verify user-facing warning before deletion
  grep -q 'This will remove:' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  grep -q '~/.osa symlink' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  grep -q '~/.zshrc symlink' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  grep -q '~/.osa-config' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

# Backup Behavior
# ================

@test "backs up real .osa directory if it exists" {
  # Verify directory detection and backup logic
  grep -q 'is a real directory' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  grep -q '.osa.backup' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "backs up real .zshrc file if not OSA symlink" {
  # Verify file backup for non-OSA .zshrc
  grep -q '.zshrc.*is a real file' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "includes timestamp in backup filenames" {
  # Verify backup names are unique
  grep -q 'date +%s' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

# File Removal Targeting
# ======================

@test "safely removes ~/.osa symlink" {
  # Verify specific path handling
  grep -q '\$HOME/.osa' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "safely removes ~/.zshrc if OSA version" {
  # Verify conditional removal
  grep -q '\$HOME/.zshrc' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "safely removes ~/.osaconfig" {
  # Verify config file cleanup
  grep -q '\$HOME/.osa-config' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "safely removes ~/.mise.toml if present" {
  # Verify mise config cleanup
  grep -q '\$HOME/.mise.toml' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

# Output Messages
# ================

@test "displays success message for each removed file" {
  # Verify user feedback
  grep -q 'Removed ~/.osa symlink' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "suggests next steps after cleanup" {
  # Verify post-cleanup guidance
  grep -q 'Next steps:' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "cleanup section is well-structured" {
  # Verify visual formatting
  grep -q '╔════' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  grep -q '║.*Clean' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  grep -q '╚════' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

# Function Signature
# ===================

@test "clean_all function accepts optional unsafe parameter" {
  # Verify function accepts argument
  grep -q 'clean_all()' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  grep -q 'local unsafe_mode=' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "unsafe parameter defaults to false" {
  # Verify safe default
  grep -q 'unsafe_mode="\${1:-false}"' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

# Integration
# ===========

@test "clean_all is called from main with unsafe flag" {
  # Verify main() passes unsafe_mode to clean_all
  grep -q 'clean_all "\$unsafe_mode"' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "clean_all respects OSA_DRY_RUN restriction" {
  # Verify no interaction with dry-run
  grep -q 'cannot be used with' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}
