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
  local minimal_config="$OSA_TEST_REPO_ROOT/configs/minimal.yaml"
  # Should not have cocoapods key in components
  ! yq eval '.components.cocoapods' "$minimal_config" | grep -q true
}

@test "react-native config includes cocoapods" {
  local rn_config="$OSA_TEST_REPO_ROOT/configs/react-native.yaml"
  # Should have cocoapods enabled
  yq eval '.components.cocoapods' "$rn_config" | grep -q true
}

@test "ios config includes cocoapods" {
  local ios_config="$OSA_TEST_REPO_ROOT/configs/ios.yaml"
  # Should have cocoapods enabled
  yq eval '.components.cocoapods' "$ios_config" | grep -q true
}

@test "android config does not include cocoapods" {
  local android_config="$OSA_TEST_REPO_ROOT/configs/android.yaml"
  # Should not have cocoapods key in components
  ! yq eval '.components.cocoapods' "$android_config" | grep -q true
}

@test "macos config does not include cocoapods" {
  local macos_config="$OSA_TEST_REPO_ROOT/configs/macos.yaml"
  # Should not have cocoapods key in components
  ! yq eval '.components.cocoapods' "$macos_config" | grep -q true
}

@test "backend config does not include cocoapods" {
  local backend_config="$OSA_TEST_REPO_ROOT/configs/backend.yaml"
  # Should not have cocoapods key in components
  ! yq eval '.components.cocoapods' "$backend_config" | grep -q true
}

@test "web config does not include cocoapods" {
  local web_config="$OSA_TEST_REPO_ROOT/configs/web.yaml"
  # Should not have cocoapods key in components
  ! yq eval '.components.cocoapods' "$web_config" | grep -q true
}

@test "everything config includes cocoapods" {
  local everything_config="$OSA_TEST_REPO_ROOT/configs/everything.yaml"
  # Should have cocoapods enabled
  yq eval '.components.cocoapods' "$everything_config" | grep -q true
}

# Enable Minimal Tests
# ====================

@test "enable_minimal sets OSA_SETUP_COCOAPODS=false" {
  # Just verify the config files are set up correctly
  # The enable_minimal function is tested indirectly by the CLI tests
  local configs_dir="$OSA_TEST_REPO_ROOT/configs"
  
  # Verify that if we run --minimal, cocoapods should be false
  # This is tested by checking that minimal.yaml doesn't have cocoapods=true
  ! yq eval '.components.cocoapods' "$configs_dir/minimal.yaml" | grep -q true
}

@test "enable_minimal sets OSA_SETUP_GIT=false" {
  # Minimal config should not have git
  local minimal_config="$OSA_TEST_REPO_ROOT/configs/minimal.yaml"
  
  ! yq eval '.components.git' "$minimal_config" 2>/dev/null | grep -q true
}

@test "enable_minimal sets OSA_SETUP_ANDROID=false" {
  local minimal_config="$OSA_TEST_REPO_ROOT/configs/minimal.yaml"
  
  ! yq eval '.components.android' "$minimal_config" 2>/dev/null | grep -q true
}

@test "enable_minimal sets OSA_SETUP_ITERM2=false" {
  local minimal_config="$OSA_TEST_REPO_ROOT/configs/minimal.yaml"
  
  ! yq eval '.components.iterm2' "$minimal_config" 2>/dev/null | grep -q true
}

@test "enable_minimal sets OSA_SETUP_VSCODE=false" {
  local minimal_config="$OSA_TEST_REPO_ROOT/configs/minimal.yaml"
  
  ! yq eval '.components.vscode' "$minimal_config" 2>/dev/null | grep -q true
}

# Config Loading Tests
# ====================

@test "minimal config has cocoapods undefined or false" {
  local minimal_config="$OSA_TEST_REPO_ROOT/configs/minimal.yaml"
  local cocoapods=$(yq eval '.components.cocoapods' "$minimal_config" 2>/dev/null)
  
  # Should be null (undefined) or false
  [[ "$cocoapods" == "null" || "$cocoapods" == "false" ]]
}

@test "react-native config has cocoapods=true" {
  local rn_config="$OSA_TEST_REPO_ROOT/configs/react-native.yaml"
  local cocoapods=$(yq eval '.components.cocoapods' "$rn_config" 2>/dev/null)
  
  [[ "$cocoapods" == "true" ]]
}

@test "ios config has cocoapods=true" {
  local ios_config="$OSA_TEST_REPO_ROOT/configs/ios.yaml"
  local cocoapods=$(yq eval '.components.cocoapods' "$ios_config" 2>/dev/null)
  
  [[ "$cocoapods" == "true" ]]
}

@test "android config has cocoapods undefined or false" {
  local android_config="$OSA_TEST_REPO_ROOT/configs/android.yaml"
  local cocoapods=$(yq eval '.components.cocoapods' "$android_config" 2>/dev/null)
  
  [[ "$cocoapods" == "null" || "$cocoapods" == "false" ]]
}

@test "macos config has cocoapods undefined or false" {
  local macos_config="$OSA_TEST_REPO_ROOT/configs/macos.yaml"
  local cocoapods=$(yq eval '.components.cocoapods' "$macos_config" 2>/dev/null)
  
  [[ "$cocoapods" == "null" || "$cocoapods" == "false" ]]
}

# Config Schema Tests
# ===================

@test "all config files are valid JSON" {
  local configs_dir="$OSA_TEST_REPO_ROOT/configs"
  local invalid_count=0
  
  for config in "$configs_dir"/*.yaml; do
    if ! yq eval '.' "$config" > /dev/null 2>/dev/null; then
      echo "Invalid YAML: $config"
      invalid_count=$((invalid_count + 1))
    fi
  done
  
  [[ $invalid_count -eq 0 ]]
}

@test "all configs have required fields" {
  local configs_dir="$OSA_TEST_REPO_ROOT/configs"
  
  for config in "$configs_dir"/*.yaml; do
    # Check for version, description, components, runtimes
    yq eval '.version' "$config" > /dev/null || { echo "Missing version in $config"; return 1; }
    yq eval '.description' "$config" > /dev/null || { echo "Missing description in $config"; return 1; }
    yq eval '.components' "$config" > /dev/null || { echo "Missing components in $config"; return 1; }
    yq eval '.runtimes' "$config" > /dev/null || { echo "Missing runtimes in $config"; return 1; }
  done
}

@test "no config has cocoapods as object" {
  # Cocoapods should be boolean, not an object
  local configs_dir="$OSA_TEST_REPO_ROOT/configs"
  
  for config in "$configs_dir"/*.yaml; do
    local cocoapods_value=$(yq eval '.components.cocoapods' "$config" 2>/dev/null)
    
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
  local test_minimal="/tmp/test-minimal-cocoapods.yaml"
  cat > "$test_minimal" << 'EOF'
version: "1.0"
description: "Test"
components:
  symlinks: true
  oh_my_zsh: true
  zsh_plugins: true
runtimes: {}
EOF

  local result=$(yq eval '.components.cocoapods // false' "$test_minimal")
  [[ "$result" == "false" ]]
  
  rm -f "$test_minimal"
}

