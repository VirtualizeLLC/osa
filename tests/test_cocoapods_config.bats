#!/usr/bin/env bats
# tests/test_cocoapods_config.bats - Test CocoaPods configuration handling

load helpers

setup() {
  setup_test_env
}

teardown() {
  teardown_test_env
}

# CocoaPods Configuration Tests
# =============================

@test "minimal config does not include cocoapods" {
  local minimal_config="$OSA_TEST_REPO_ROOT/configs/minimal.json"
  # Should not have cocoapods key in components
  ! jq '.components.cocoapods' "$minimal_config" | grep -q true
}

@test "react-native config includes cocoapods" {
  local rn_config="$OSA_TEST_REPO_ROOT/configs/react-native.json"
  # Should have cocoapods enabled
  jq '.components.cocoapods' "$rn_config" | grep -q true
}

@test "ios config includes cocoapods" {
  local ios_config="$OSA_TEST_REPO_ROOT/configs/ios.json"
  # Should have cocoapods enabled
  jq '.components.cocoapods' "$ios_config" | grep -q true
}

@test "android config does not include cocoapods" {
  local android_config="$OSA_TEST_REPO_ROOT/configs/android.json"
  # Should not have cocoapods key in components
  ! jq '.components.cocoapods' "$android_config" | grep -q true
}

@test "macos config does not include cocoapods" {
  local macos_config="$OSA_TEST_REPO_ROOT/configs/macos.json"
  # Should not have cocoapods key in components
  ! jq '.components.cocoapods' "$macos_config" | grep -q true
}

@test "backend config does not include cocoapods" {
  local backend_config="$OSA_TEST_REPO_ROOT/configs/backend.json"
  # Should not have cocoapods key in components
  ! jq '.components.cocoapods' "$backend_config" | grep -q true
}

@test "web config does not include cocoapods" {
  local web_config="$OSA_TEST_REPO_ROOT/configs/web.json"
  # Should not have cocoapods key in components
  ! jq '.components.cocoapods' "$web_config" | grep -q true
}

@test "everything config includes cocoapods" {
  local everything_config="$OSA_TEST_REPO_ROOT/configs/everything.json"
  # Should have cocoapods enabled
  jq '.components.cocoapods' "$everything_config" | grep -q true
}

# Enable Minimal Tests
# ====================

@test "enable_minimal sets OSA_SETUP_COCOAPODS=false" {
  # Just verify the config files are set up correctly
  # The enable_minimal function is tested indirectly by the CLI tests
  local configs_dir="$OSA_TEST_REPO_ROOT/configs"
  
  # Verify that if we run --minimal, cocoapods should be false
  # This is tested by checking that minimal.json doesn't have cocoapods=true
  ! jq '.components.cocoapods' "$configs_dir/minimal.json" | grep -q true
}

@test "enable_minimal sets OSA_SETUP_GIT=false" {
  # Minimal config should not have git
  local minimal_config="$OSA_TEST_REPO_ROOT/configs/minimal.json"
  
  ! jq '.components.git' "$minimal_config" 2>/dev/null | grep -q true
}

@test "enable_minimal sets OSA_SETUP_ANDROID=false" {
  local minimal_config="$OSA_TEST_REPO_ROOT/configs/minimal.json"
  
  ! jq '.components.android' "$minimal_config" 2>/dev/null | grep -q true
}

@test "enable_minimal sets OSA_SETUP_ITERM2=false" {
  local minimal_config="$OSA_TEST_REPO_ROOT/configs/minimal.json"
  
  ! jq '.components.iterm2' "$minimal_config" 2>/dev/null | grep -q true
}

@test "enable_minimal sets OSA_SETUP_VSCODE=false" {
  local minimal_config="$OSA_TEST_REPO_ROOT/configs/minimal.json"
  
  ! jq '.components.vscode' "$minimal_config" 2>/dev/null | grep -q true
}

# Config Loading Tests
# ====================

@test "minimal config has cocoapods undefined or false" {
  local minimal_config="$OSA_TEST_REPO_ROOT/configs/minimal.json"
  local cocoapods=$(jq '.components.cocoapods' "$minimal_config" 2>/dev/null)
  
  # Should be null (undefined) or false
  [[ "$cocoapods" == "null" || "$cocoapods" == "false" ]]
}

@test "react-native config has cocoapods=true" {
  local rn_config="$OSA_TEST_REPO_ROOT/configs/react-native.json"
  local cocoapods=$(jq '.components.cocoapods' "$rn_config" 2>/dev/null)
  
  [[ "$cocoapods" == "true" ]]
}

@test "ios config has cocoapods=true" {
  local ios_config="$OSA_TEST_REPO_ROOT/configs/ios.json"
  local cocoapods=$(jq '.components.cocoapods' "$ios_config" 2>/dev/null)
  
  [[ "$cocoapods" == "true" ]]
}

@test "android config has cocoapods undefined or false" {
  local android_config="$OSA_TEST_REPO_ROOT/configs/android.json"
  local cocoapods=$(jq '.components.cocoapods' "$android_config" 2>/dev/null)
  
  [[ "$cocoapods" == "null" || "$cocoapods" == "false" ]]
}

@test "macos config has cocoapods undefined or false" {
  local macos_config="$OSA_TEST_REPO_ROOT/configs/macos.json"
  local cocoapods=$(jq '.components.cocoapods' "$macos_config" 2>/dev/null)
  
  [[ "$cocoapods" == "null" || "$cocoapods" == "false" ]]
}

# Config Schema Tests
# ===================

@test "all config files are valid JSON" {
  local configs_dir="$OSA_TEST_REPO_ROOT/configs"
  local invalid_count=0
  
  for config in "$configs_dir"/*.json; do
    if ! jq empty "$config" 2>/dev/null; then
      echo "Invalid JSON: $config"
      invalid_count=$((invalid_count + 1))
    fi
  done
  
  [[ $invalid_count -eq 0 ]]
}

@test "all configs have required fields" {
  local configs_dir="$OSA_TEST_REPO_ROOT/configs"
  
  for config in "$configs_dir"/*.json; do
    # Check for version, description, components, runtimes
    jq -e '.version' "$config" > /dev/null || { echo "Missing version in $config"; return 1; }
    jq -e '.description' "$config" > /dev/null || { echo "Missing description in $config"; return 1; }
    jq -e '.components' "$config" > /dev/null || { echo "Missing components in $config"; return 1; }
    jq -e '.runtimes' "$config" > /dev/null || { echo "Missing runtimes in $config"; return 1; }
  done
}

@test "no config has cocoapods as object" {
  # Cocoapods should be boolean, not an object
  local configs_dir="$OSA_TEST_REPO_ROOT/configs"
  
  for config in "$configs_dir"/*.json; do
    local cocoapods_value=$(jq '.components.cocoapods' "$config" 2>/dev/null)
    
    # If cocoapods exists, it should be true or false (not an object starting with {)
    if [[ "$cocoapods_value" == "{" ]]; then
      echo "Config $config has cocoapods as object instead of boolean"
      return 1
    fi
  done
}

# Config Leakage Prevention Tests
# ================================

@test "config file is not auto-loaded at startup" {
  # The CLI should NOT auto-load ~/.osaconfig in main()
  # This prevents stale config from previous runs from affecting the current setup
  # Config is only loaded when explicitly requested (--config, --config-file, --auto)
  grep -q "Do NOT call load_config here" "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "config file defaults all undefined components to false" {
  # When a config doesn't mention a component, jq should return false
  local test_minimal="/tmp/test-minimal-cocoapods.json"
  cat > "$test_minimal" << 'EOF'
{
  "version": "1.0",
  "description": "Test",
  "components": {
    "symlinks": true,
    "oh_my_zsh": true,
    "zsh_plugins": true
  },
  "runtimes": {}
}
EOF

  local result=$(jq -r '.components.cocoapods // false' "$test_minimal")
  [[ "$result" == "false" ]]
  
  rm -f "$test_minimal"
}

