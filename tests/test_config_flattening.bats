#!/usr/bin/env bats
# tests/test_config_flattening.bats - Tests for flat OSA_CONFIG_* environment variables

setup() {
  export OSA_CLI_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export OSA_CONFIG_FILE="/tmp/test-osaconfig-$$"
  
  # Source helper which loads functions without calling main
  source "$OSA_CLI_DIR/tests/test_helpers.zsh"
}

teardown() {
  rm -f "$OSA_CONFIG_FILE"
  # Unset all OSA_CONFIG_* variables
  unset $(compgen -v | grep '^OSA_CONFIG_')
}

@test "flatten_yaml_to_env_vars creates OSA_CONFIG_PROFILE" {
  flatten_yaml_to_env_vars "$OSA_CLI_DIR/configs/minimal.yaml"
  [[ -n "$OSA_CONFIG_PROFILE" ]]
  [[ "$OSA_CONFIG_PROFILE" == "minimal" ]]
}

@test "flatten_yaml_to_env_vars creates OSA_CONFIG_COMPONENTS_* variables" {
  flatten_yaml_to_env_vars "$OSA_CLI_DIR/configs/minimal.yaml"
  
  # Check a few key component variables
  [[ "$OSA_CONFIG_COMPONENTS_SYMLINKS" == "true" ]]
  [[ "$OSA_CONFIG_COMPONENTS_OH_MY_ZSH" == "true" ]]
  [[ "$OSA_CONFIG_COMPONENTS_COCOAPODS" == "false" ]]
}

@test "flatten_yaml_to_env_vars creates OSA_CONFIG_RUNTIMES_* variables" {
  flatten_yaml_to_env_vars "$OSA_CLI_DIR/configs/minimal.yaml"
  
  # Node should be enabled with version 22
  [[ "$OSA_CONFIG_RUNTIMES_NODE_ENABLED" == "true" ]]
  [[ "$OSA_CONFIG_RUNTIMES_NODE_VERSION" == "22" ]]
  
  # Python should be disabled
  [[ "$OSA_CONFIG_RUNTIMES_PYTHON_ENABLED" == "false" ]]
}

@test "flatten_yaml_to_env_vars creates OSA_CONFIG_SNIPPETS_* variables" {
  flatten_yaml_to_env_vars "$OSA_CLI_DIR/configs/minimal.yaml"
  
  # osasnippets should be enabled (minimal has empty features list)
  [[ "$OSA_CONFIG_SNIPPETS_OSASNIPPETS_ENABLED" == "true" ]]
}

@test "flatten_yaml_to_env_vars creates feature-specific snippet variables" {
  flatten_yaml_to_env_vars "$OSA_CLI_DIR/configs/web.yaml"
  
  # web config has direnv and vscode features
  [[ "$OSA_CONFIG_SNIPPETS_OSASNIPPETS_DIRENV" == "true" ]]
  [[ "$OSA_CONFIG_SNIPPETS_OSASNIPPETS_VSCODE" == "true" ]]
}

@test "save_config writes all OSA_CONFIG_* variables to file" {
  flatten_yaml_to_env_vars "$OSA_CLI_DIR/configs/minimal.yaml"
  save_config
  
  [[ -f "$OSA_CONFIG_FILE" ]]
  grep -q "OSA_CONFIG_PROFILE='minimal'" "$OSA_CONFIG_FILE"
  grep -q "OSA_CONFIG_COMPONENTS_SYMLINKS='true'" "$OSA_CONFIG_FILE"
  grep -q "OSA_CONFIG_RUNTIMES_NODE_VERSION='22'" "$OSA_CONFIG_FILE"
}

@test "load_config sources saved configuration variables" {
  # Setup: create and save config
  flatten_yaml_to_env_vars "$OSA_CLI_DIR/configs/minimal.yaml"
  save_config
  
  # Unset all OSA_CONFIG variables
  compgen -v | grep '^OSA_CONFIG_' | while read var; do unset "$var"; done
  
  # Verify they're unset (in subshell after unset loop)
  unset OSA_CONFIG_PROFILE OSA_CONFIG_COMPONENTS_SYMLINKS OSA_CONFIG_RUNTIMES_NODE_VERSION
  [[ -z "$OSA_CONFIG_PROFILE" ]]
  
  # Load config
  source "$OSA_CONFIG_FILE"
  
  # Verify they're restored
  [[ "$OSA_CONFIG_PROFILE" == "minimal" ]]
  [[ "$OSA_CONFIG_COMPONENTS_SYMLINKS" == "true" ]]
  [[ "$OSA_CONFIG_RUNTIMES_NODE_VERSION" == "22" ]]
}

@test "config flattening preserves all component flags across profiles" {
  local profiles=(minimal android ios react-native web backend macos everything)
  local required_flags=(symlinks oh_my_zsh zsh_plugins)
  
  for profile in "${profiles[@]}"; do
    flatten_yaml_to_env_vars "$OSA_CLI_DIR/configs/${profile}.yaml"
    
    for flag in "${required_flags[@]}"; do
      local var_name="OSA_CONFIG_COMPONENTS_$(echo $flag | tr a-z A-Z | tr '-' '_')"
      local value=$(eval echo "\$$var_name")
      [[ "$value" == "true" ]] || {
        echo "Profile $profile: $flag not enabled"
        return 1
      }
    done
    
    # Unset for next iteration
    unset $(compgen -v | grep '^OSA_CONFIG_')
  done
}

@test "android profile creates correct snippet variables" {
  flatten_yaml_to_env_vars "$OSA_CLI_DIR/configs/android.yaml"
  
  [[ "$OSA_CONFIG_SNIPPETS_OSASNIPPETS_ANDROID" == "true" ]]
  [[ "$OSA_CONFIG_SNIPPETS_OSASNIPPETS_KEYCHAIN" == "true" ]]  # Enabled for keychain features in android
}

@test "web profile has multiple feature flags" {
  flatten_yaml_to_env_vars "$OSA_CLI_DIR/configs/web.yaml"
  
  [[ "$OSA_CONFIG_SNIPPETS_OSASNIPPETS_DIRENV" == "true" ]]
  [[ "$OSA_CONFIG_SNIPPETS_OSASNIPPETS_VSCODE" == "true" ]]
}

@test "everything profile has all features enabled" {
  flatten_yaml_to_env_vars "$OSA_CLI_DIR/configs/everything.yaml"
  
  local features=(keychain xcode react_native android mac_tools direnv vscode)
  for feature in "${features[@]}"; do
    local var_name="OSA_CONFIG_SNIPPETS_OSASNIPPETS_$(echo $feature | tr a-z A-Z | tr '-' '_')"
    local value=$(eval echo "\$$var_name")
    [[ "$value" == "true" ]] || {
      echo "Feature $feature not found in everything profile (var=$var_name, value=$value)"
      return 1
    }
  done
}
