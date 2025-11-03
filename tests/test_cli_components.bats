#!/usr/bin/env bats
# tests/test_cli_components.bats - Tests for all OSA_SETUP_* flags in configs

setup() {
  export OSA_CLI_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export OSA_CONFIG_FILE="/tmp/test-osaconfig-$$"
  
  # Verify yq is available
  if ! command -v yq &> /dev/null; then
    skip "yq is required to run these tests"
  fi
}

teardown() {
  rm -f "$OSA_CONFIG_FILE"
}

# Test all config files have all expected snippets flags
@test "minimal.yaml has all snippets flags defined" {
  local config="$OSA_CLI_DIR/configs/minimal.yaml"
  [[ -f "$config" ]]
  
  # Check for setup components
  yq eval '.components.symlinks' "$config" | grep -q true
  yq eval '.components.oh_my_zsh' "$config" | grep -q true
  
  # Check snippets flags exist (should be defined, value may be true/false)
  yq eval '.components.git' "$config" | grep -qE 'true|false'
  yq eval '.components.vscode' "$config" | grep -qE 'true|false'
  yq eval '.components.cocoapods' "$config" | grep -qE 'true|false'
  yq eval '.components.android' "$config" | grep -qE 'true|false'
}

@test "android.yaml has android flag enabled" {
  local config="$OSA_CLI_DIR/configs/android.yaml"
  [[ -f "$config" ]]
  
  yq eval '.components.android' "$config" | grep -q true
  yq eval '.components.cocoapods' "$config" | grep -q false
  yq eval '.components.react_native' "$config" | grep -q false
}

@test "ios.yaml has cocoapods and iOS flags enabled" {
  local config="$OSA_CLI_DIR/configs/ios.yaml"
  [[ -f "$config" ]]
  
  yq eval '.components.cocoapods' "$config" | grep -q true
  yq eval '.components.android' "$config" | grep -q false
  yq eval '.components.keychain' "$config" | grep -q true
  yq eval '.components.xcode' "$config" | grep -q true
}

@test "react-native.yaml enables both android and cocoapods" {
  local config="$OSA_CLI_DIR/configs/react-native.yaml"
  [[ -f "$config" ]]
  
  yq eval '.components.android' "$config" | grep -q true
  yq eval '.components.cocoapods' "$config" | grep -q true
  yq eval '.components.react_native' "$config" | grep -q true
}

@test "web.yaml disables mobile/native flags" {
  local config="$OSA_CLI_DIR/configs/web.yaml"
  [[ -f "$config" ]]
  
  yq eval '.components.cocoapods' "$config" | grep -q false
  yq eval '.components.android' "$config" | grep -q false
  yq eval '.components.react_native' "$config" | grep -q false
  yq eval '.components.direnv' "$config" | grep -q true
}

@test "backend.yaml disables mobile flags" {
  local config="$OSA_CLI_DIR/configs/backend.yaml"
  [[ -f "$config" ]]
  
  yq eval '.components.cocoapods' "$config" | grep -q false
  yq eval '.components.android' "$config" | grep -q false
}

@test "macos.yaml enables mac-specific flags" {
  local config="$OSA_CLI_DIR/configs/macos.yaml"
  [[ -f "$config" ]]
  
  yq eval '.components.cocoapods' "$config" | grep -q false
  yq eval '.components.mac_tools' "$config" | grep -q true
  yq eval '.components.keychain' "$config" | grep -q true
}

@test "everything.yaml enables all flags" {
  local config="$OSA_CLI_DIR/configs/everything.yaml"
  [[ -f "$config" ]]
  
  yq eval '.components.cocoapods' "$config" | grep -q true
  yq eval '.components.android' "$config" | grep -q true
  yq eval '.components.vscode' "$config" | grep -q true
  yq eval '.components.egpu' "$config" | grep -q true
  yq eval '.components.ngrok' "$config" | grep -q true
}

@test "example-config.yaml has all flags defined" {
  local config="$OSA_CLI_DIR/configs/example-config.yaml"
  [[ -f "$config" ]]
  
  yq eval '.components.symlinks' "$config" | grep -q true
  yq eval '.components.vscode' "$config" | grep -q true
  yq eval '.components.direnv' "$config" | grep -q false
}

# Test all required config structure
@test "all configs have required schema: version, description, profile, components, runtimes" {
  for config in "$OSA_CLI_DIR"/configs/*.yaml; do
    [[ "$config" == *README* ]] && continue
    yq eval '.version' "$config" | grep -q '1.0'
    yq eval '.description' "$config" | grep -q '.'
    yq eval '.profile' "$config" | grep -q '.'
    yq eval '.components' "$config" | grep -q 'true\|false'
    yq eval '.runtimes' "$config" | grep -q 'enabled'
  done
}

# Test all expected flags exist in configs
@test "all configs define all snippets flags" {
  local required_flags=(
    "symlinks" "oh_my_zsh" "zsh_plugins" "homebrew" "mise" "osa_snippets"
    "git" "android" "react_native" "cocoapods"
    "node" "python" "ruby" "java" "nvm" "fnm"
    "vscode" "direnv" "keychain" "ngrok" "mac_tools" "xcode" "egpu" "compression"
  )
  
  for config in "$OSA_CLI_DIR"/configs/{minimal,android,ios,react-native,web,backend,macos,everything,example-config}.yaml; do
    [[ -f "$config" ]] || continue
    
    for flag in "${required_flags[@]}"; do
      local value=$(yq eval ".components.${flag}" "$config" 2>/dev/null)
      [[ "$value" =~ ^(true|false)$ ]] || {
        echo "Flag '$flag' missing or invalid in $(basename $config): $value"
        return 1
      }
    done
  done
}

# Test cocoapods only in iOS/React Native
@test "cocoapods is only enabled in iOS-related profiles" {
  local minimal=$(yq eval '.components.cocoapods' "$OSA_CLI_DIR/configs/minimal.yaml")
  local android=$(yq eval '.components.cocoapods' "$OSA_CLI_DIR/configs/android.yaml")
  local ios=$(yq eval '.components.cocoapods' "$OSA_CLI_DIR/configs/ios.yaml")
  local react_native=$(yq eval '.components.cocoapods' "$OSA_CLI_DIR/configs/react-native.yaml")
  local web=$(yq eval '.components.cocoapods' "$OSA_CLI_DIR/configs/web.yaml")
  local backend=$(yq eval '.components.cocoapods' "$OSA_CLI_DIR/configs/backend.yaml")
  
  [[ "$minimal" == "false" ]]
  [[ "$android" == "false" ]]
  [[ "$ios" == "true" ]]
  [[ "$react_native" == "true" ]]
  [[ "$web" == "false" ]]
  [[ "$backend" == "false" ]]
}

# Test android only in Android/React Native
@test "android is only enabled in Android-related profiles" {
  local minimal=$(yq eval '.components.android' "$OSA_CLI_DIR/configs/minimal.yaml")
  local android=$(yq eval '.components.android' "$OSA_CLI_DIR/configs/android.yaml")
  local ios=$(yq eval '.components.android' "$OSA_CLI_DIR/configs/ios.yaml")
  local react_native=$(yq eval '.components.android' "$OSA_CLI_DIR/configs/react-native.yaml")
  
  [[ "$minimal" == "false" ]]
  [[ "$android" == "true" ]]
  [[ "$ios" == "false" ]]
  [[ "$react_native" == "true" ]]
}

# Test all YAML files are valid
@test "all config files are valid YAML" {
  for config in "$OSA_CLI_DIR"/configs/*.yaml; do
    yq eval '.' "$config" > /dev/null || {
      echo "Invalid YAML in: $(basename $config)"
      return 1
    }
  done
}

# Test profile names match filenames
@test "profile names match config filenames" {
  local profiles=(
    "minimal:minimal"
    "android:android"
    "ios:ios"
    "react-native:react-native"
    "web:web"
    "backend:backend"
    "macos:macos"
    "everything:everything"
  )
  
  for pair in "${profiles[@]}"; do
    local filename="${pair%:*}"
    local expected_profile="${pair#*:}"
    local actual_profile=$(yq eval '.profile' "$OSA_CLI_DIR/configs/${filename}.yaml")
    [[ "$actual_profile" == "$expected_profile" ]] || {
      echo "Profile mismatch in $filename.yaml: expected '$expected_profile', got '$actual_profile'"
      return 1
    }
  done
}

# Test required setup components are always enabled
@test "required setup components are always true in all configs" {
  local configs=(
    "minimal" "android" "ios" "react-native" "web" "backend" "macos" "everything"
  )
  
  for config_name in "${configs[@]}"; do
    local config="$OSA_CLI_DIR/configs/${config_name}.yaml"
    
    # Required components should always be true
    [[ $(yq eval '.components.symlinks' "$config") == "true" ]] || {
      echo "$config_name: symlinks should be true"
      return 1
    }
    [[ $(yq eval '.components.oh_my_zsh' "$config") == "true" ]] || {
      echo "$config_name: oh_my_zsh should be true"
      return 1
    }
    [[ $(yq eval '.components.zsh_plugins' "$config") == "true" ]] || {
      echo "$config_name: zsh_plugins should be true"
      return 1
    }
  done
}

