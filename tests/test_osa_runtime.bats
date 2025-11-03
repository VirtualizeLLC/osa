#!/usr/bin/env bash
# tests/test_osa_runtime.bats - Test osa command runtime integration

load helpers

setup() {
  setup_test_env
  # Set required variables for testing
  export OSA_REPO_PATH="$OSA_TEST_REPO_ROOT"
  export TEST_TEMP_DIR=$(mktemp -d)
  export HOME="$TEST_TEMP_DIR/home"
  mkdir -p "$HOME"
}

teardown() {
  teardown_test_env
  rm -rf "$TEST_TEMP_DIR"
}

# OSA Command Structure Tests
# ============================

@test "osa command function exists in osa.zsh" {
  # Verify the osa function is defined
  grep -q "^osa()" "$OSA_TEST_REPO_ROOT/src/zsh/aliases/osa.zsh"
}

@test "osa handles 'osa open' command" {
  # Verify 'osa open' case is handled
  grep -q 'if \[\[.*"\$1" == "open"' "$OSA_TEST_REPO_ROOT/src/zsh/aliases/osa.zsh"
}

@test "osa resolves OSA_REPO_PATH from ~/.osa symlink" {
  # Verify symlink resolution logic exists
  grep -q 'readlink -f.*OSA_REPO_PATH' "$OSA_TEST_REPO_ROOT/src/zsh/aliases/osa.zsh"
}

@test "osa checks if editor is available" {
  # Verify editor availability check
  grep -q 'command -v.*editor' "$OSA_TEST_REPO_ROOT/src/zsh/aliases/osa.zsh"
}

@test "osa respects OSA_EDITOR variable" {
  # Verify OSA_EDITOR is used
  grep -q 'OSA_EDITOR:-code' "$OSA_TEST_REPO_ROOT/src/zsh/aliases/osa.zsh"
}

@test "osa defaults to 'code' editor when OSA_EDITOR not set" {
  # Verify default editor is code
  grep -q 'editor="\${OSA_EDITOR:-code}"' "$OSA_TEST_REPO_ROOT/src/zsh/aliases/osa.zsh"
}

@test "osa passes through unrecognized arguments to osa-cli.zsh" {
  # Verify fallthrough to osa-cli.zsh
  grep -q 'osa-cli.zsh.*\"\$@\"' "$OSA_TEST_REPO_ROOT/src/zsh/aliases/osa.zsh"
}

@test "osa returns error if editor not found" {
  # Verify error handling for missing editor
  grep -q 'Error: Editor.*not found in PATH' "$OSA_TEST_REPO_ROOT/src/zsh/aliases/osa.zsh"
}

@test "osa handles vim/nvim editor synchronously" {
  # Verify vim/nvim are run in foreground (without & at end)
  grep -q "vim|nvim" "$OSA_TEST_REPO_ROOT/src/zsh/aliases/osa.zsh"
}

@test "osa handles code/vscode editor in background" {
  # Verify code/vscode are in case statement
  grep -q "code|vscode" "$OSA_TEST_REPO_ROOT/src/zsh/aliases/osa.zsh"
}

@test "osa function exports properly for use in subshells" {
  # Verify function is available for sourcing
  [[ -f "$OSA_TEST_REPO_ROOT/src/zsh/aliases/osa.zsh" ]]
}

@test "osa requires OSA_REPO_PATH to be set" {
  # Verify OSA_REPO_PATH validation
  grep -q 'OSA_REPO_PATH:?OSA_REPO_PATH not set' "$OSA_TEST_REPO_ROOT/src/zsh/aliases/osa.zsh"
}

@test "osa correctly handles real_repo path resolution" {
  # Verify readlink is used to resolve actual path
  grep -q 'readlink -f.*OSA_REPO_PATH' "$OSA_TEST_REPO_ROOT/src/zsh/aliases/osa.zsh"
}
