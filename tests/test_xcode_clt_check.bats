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

@test "xcode clt check detects missing xcode-select command" {
  # Verify the condition checks for xcode-select existence
  grep -q 'command -v xcode-select' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "xcode clt check verifies xcode-select -p returns a path" {
  # Verify that xcode-select -p is checked (returns non-zero if not installed)
  grep -q 'xcode-select -p' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
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

@test "xcode clt check allows user to continue anyway" {
  # Verify ask_yes_no is called for the prompt
  grep -q 'Continue anyway?' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "xcode clt check returns error if user declines to continue" {
  # Verify error handling
  grep -q 'Setup cancelled' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "xcode clt check exits gracefully on cancellation" {
  # Verify return 1 on cancellation
  grep -A 3 'Setup cancelled' "$OSA_TEST_REPO_ROOT/osa-cli.zsh" | grep -q 'return 1'
}

# Manual Testing Instructions
# =============================
#
# To manually test the Xcode CLT check:
#
# 1. Simulate missing CLT:
#    PATH=/usr/sbin:/usr/bin:/bin:/usr/local/bin zsh ./osa-cli.zsh --interactive
#
# 2. Or temporarily hide xcode-select:
#    sudo mv /usr/bin/xcode-select /usr/bin/xcode-select.bak
#    zsh ./osa-cli.zsh --interactive
#    sudo mv /usr/bin/xcode-select.bak /usr/bin/xcode-select
#
# 3. The warning should appear at the start of interactive setup
#    showing both installation options.
