#!/usr/bin/env zsh
# tests/helpers.zsh - Shared test utilities and mocks for OSA CLI tests

# Get the repo root (parent of tests directory)
OSA_TEST_REPO_ROOT="$(cd "$(dirname "${0}")/.." && pwd)"

# Create a temporary test directory for each test
export TEST_TEMP_DIR=""
export TEST_LOG=""
export MOCK_HOME=""

# Setup test environment
setup_test_env() {
  TEST_TEMP_DIR=$(mktemp -d)
  TEST_LOG="$TEST_TEMP_DIR/test.log"
  MOCK_HOME="$TEST_TEMP_DIR/home"
  
  mkdir -p "$MOCK_HOME"
  
  # Export for use in subshells
  export TEST_TEMP_DIR TEST_LOG MOCK_HOME
}

# Cleanup test environment
teardown_test_env() {
  if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# Mock implementations
# ==================

# Mock rm - logs operations instead of deleting
mock_rm() {
  {
    echo "MOCK_RM: rm $@"
    for arg in "$@"; do
      if [[ ! "$arg" =~ ^- ]]; then
        echo "  removed: $arg"
      fi
    done
  } >> "$TEST_LOG"
  return 0
}

# Mock ln - logs symlink creation
mock_ln() {
  {
    echo "MOCK_LN: ln $@"
    # Parse symlink creation
    if [[ "$@" =~ -s.*\ ([^ ]+)\ ([^ ]+)$ ]]; then
      echo "  symlink: ${BASH_REMATCH[2]} -> ${BASH_REMATCH[1]}"
    fi
  } >> "$TEST_LOG"
  return 0
}

# Mock mv - logs move operations
mock_mv() {
  {
    echo "MOCK_MV: mv $@"
    # Parse move: mv source dest
    local source="${@: -2:1}"
    local dest="${@: -1:1}"
    echo "  moved: $source -> $dest"
  } >> "$TEST_LOG"
  return 0
}

# Mock mkdir - logs directory creation
mock_mkdir() {
  {
    echo "MOCK_MKDIR: mkdir $@"
    for arg in "$@"; do
      if [[ ! "$arg" =~ ^- ]]; then
        echo "  created: $arg"
      fi
    done
  } >> "$TEST_LOG"
  return 0
}

# Mock readlink - returns test symlink targets
mock_readlink() {
  local link="$1"
  local test_links=(
    "$MOCK_HOME/.zshrc:$MOCK_HOME/.osa/src/zsh/.zshrc"
    "$MOCK_HOME/.osa:$OSA_TEST_REPO_ROOT"
  )
  
  for mapping in "${test_links[@]}"; do
    if [[ "$mapping" == "$link:"* ]]; then
      echo "${mapping#*:}"
      return 0
    fi
  done
  
  # If not a test symlink, return error
  {
    echo "MOCK_READLINK: readlink $link (not found)"
  } >> "$TEST_LOG"
  return 1
}

# Test assertion helpers
# ======================

# Assert that a string matches a pattern
assert_match() {
  local pattern="$1"
  local string="$2"
  local message="${3:-Expected match: $pattern in $string}"
  
  if [[ ! "$string" =~ $pattern ]]; then
    echo "FAIL: $message"
    echo "  Pattern: $pattern"
    echo "  Got: $string"
    return 1
  fi
}

# Assert that output contains a substring
assert_output_contains() {
  local expected="$1"
  local output="$2"
  
  if [[ ! "$output" =~ $expected ]]; then
    echo "FAIL: Expected output to contain: $expected"
    echo "Got: $output"
    return 1
  fi
}

# Assert that mock log contains a call
assert_mock_called() {
  local mock_call="$1"
  
  if ! grep -q "$mock_call" "$TEST_LOG" 2>/dev/null; then
    echo "FAIL: Expected mock call: $mock_call"
    echo "Mock log contents:"
    cat "$TEST_LOG" || echo "(log file doesn't exist)"
    return 1
  fi
}

# Assert that mock log does NOT contain a call
assert_mock_not_called() {
  local mock_call="$1"
  
  if grep -q "$mock_call" "$TEST_LOG" 2>/dev/null; then
    echo "FAIL: Unexpected mock call: $mock_call"
    return 1
  fi
}

# Get mock call count
get_mock_call_count() {
  local pattern="$1"
  grep -c "$pattern" "$TEST_LOG" 2>/dev/null || echo "0"
}

# Load OSA CLI functions for testing
load_osa_cli() {
  # Source the main CLI script to get access to functions
  # Use subshell to avoid polluting test environment
  source "$OSA_TEST_REPO_ROOT/osa-cli.zsh" 2>/dev/null || true
}

# Create test symlinks in mock environment
create_test_symlink() {
  local target="$1"
  local name="$2"
  local link_path="$MOCK_HOME/$name"
  
  mkdir -p "$(dirname "$link_path")"
  ln -s "$target" "$link_path"
}

# Create test config file
create_test_config() {
  local config_content="$1"
  local config_path="${2:-$MOCK_HOME/.osa-config}"
  
  mkdir -p "$(dirname "$config_path")"
  echo "$config_content" > "$config_path"
}

# Get test log contents
get_test_log() {
  cat "$TEST_LOG" 2>/dev/null || echo ""
}

# Clear test log
clear_test_log() {
  : > "$TEST_LOG"
}

# Print test environment info (useful for debugging)
print_test_env() {
  echo "=== Test Environment ==="
  echo "OSA_TEST_REPO_ROOT: $OSA_TEST_REPO_ROOT"
  echo "TEST_TEMP_DIR: $TEST_TEMP_DIR"
  echo "MOCK_HOME: $MOCK_HOME"
  echo "TEST_LOG: $TEST_LOG"
  echo "=== Mock Log ==="
  cat "$TEST_LOG" 2>/dev/null || echo "(empty)"
}

# Export all functions for use in bats tests
export -f setup_test_env teardown_test_env
export -f mock_rm mock_ln mock_mv mock_mkdir mock_readlink
export -f assert_match assert_output_contains assert_mock_called assert_mock_not_called
export -f get_mock_call_count load_osa_cli create_test_symlink create_test_config
export -f get_test_log clear_test_log print_test_env
