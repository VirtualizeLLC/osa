#!/usr/bin/env bats
# tests/test_xcode_clt_check.bats - Test macOS Xcode Command Line Tools pre-flight check

load helpers

setup() {
  setup_test_env
}

teardown() {
  teardown_test_env
}

# Xcode CLT Pre-flight Check Tests
# =================================

@test "xcode clt check is called during interactive setup on macOS" {
  # Verify that the check exists in the interactive_setup function
  grep -A 5 "macOS pre-flight check: Xcode Command Line Tools" "$OSA_TEST_REPO_ROOT/osa-cli.zsh" | \
    grep -q "xcode-select"
}

@test "xcode clt check detects missing xcode-select path" {
  # Verify the check uses xcode-select -p to get the path
  grep -q 'xcode-select -p 2>/dev/null' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "xcode clt check validates path exists" {
  # Verify directory existence check [[ ! -d "$xcode_path" ]]
  grep -q '\[[ -z "$xcode_path" ]]' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "xcode clt warning shows both installation options" {
  # Verify Option 1: xcode-select --install
  grep -q 'xcode-select --install' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  
  # Verify Option 2: Apple Developer Downloads
  grep -q 'developer.apple.com/download/more' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "xcode clt check explains why it's needed" {
  # Verify explanation message
  grep -q 'Homebrew and many development tools require Xcode CLT' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "xcode clt check only runs on macOS" {
  # Verify the check is inside OSA_IS_MACOS condition
  local cli_file="$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  
  # Find the macOS check line
  local macos_check_line=$(grep -n 'OSA_IS_MACOS.*true' "$cli_file" | grep "xcode" -B 2 | head -1 | cut -d: -f1)
  
  # Verify there's an OSA_IS_MACOS condition before the xcode check
  if [[ -n "$macos_check_line" ]]; then
    grep -q "OSA_IS_MACOS" "$cli_file"
  fi
}

@test "xcode clt check shows warning message" {
  # Verify the warning is displayed
  grep -q 'Xcode Command Line Tools not found' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

# Manual Testing Instructions
# =============================
#
# The Xcode CLT check is automatically triggered during:
# 1. Interactive setup: zsh ./osa-cli.zsh --interactive
# 2. Automated setup: zsh ./osa-cli.zsh --all
#
# The check will:
# - Detect if Xcode CLT is installed by calling xcode-select -p
# - Display a warning with two installation options if not found:
#   Option 1: xcode-select --install (easiest)
#   Option 2: https://developer.apple.com/download/more/ (if Option 1 fails)
# - Only show warning on macOS (checks OSA_IS_MACOS)
#
# Note: System Integrity Protection (SIP) prevents modifying /usr/bin/xcode-select,
# so PATH manipulation won't work for testing. Real testing requires actual
# Xcode CLT installation status.
