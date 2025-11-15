#!/usr/bin/env bats
# tests/test_plugin_android_sdk.bats - Verify android-sdk plugin init behavior

load helpers

setup() {
  export TEST_TEMP_DIR=$(mktemp -d)
  export HOME="$TEST_TEMP_DIR/home"
  mkdir -p "$HOME"
  # Ensure OSA_REPO_PATH is available to helpers
  export OSA_REPO_PATH="$OSA_TEST_REPO_ROOT"
}

teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

@test "android-sdk plugin informs user when Android SDK cmdline-tools missing" {
  run bash -c ". '$OSA_TEST_REPO_ROOT/src/zsh/plugin-init/android-sdk.zsh'"
  # The plugin should not error; it should print an informative message about missing cmdline-tools
  [[ "$status" -eq 0 ]]
  [[ "$output" =~ "Android cmdline-tools not found" ]] || [[ "$output" =~ "Available cmdline-tools directories" ]]
}

@test "android-sdk plugin suggests symlink when cmdline-tools present but 'latest' missing" {
  # Create a fake cmdline-tools/version directory but not 'latest'
  mkdir -p "$HOME/Library/Android/sdk/cmdline-tools/5.0"

  run bash -c ". '$OSA_TEST_REPO_ROOT/src/zsh/plugin-init/android-sdk.zsh'"
  [[ "$status" -eq 0 ]]
  # Should list available cmdline-tools directories and suggest creating a 'latest' symlink
  [[ "$output" =~ "Available cmdline-tools directories" ]]
  [[ "$output" =~ "create a 'latest' symlink" ]] || [[ "$output" =~ "ln -s" ]]
}
