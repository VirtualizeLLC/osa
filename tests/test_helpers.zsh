#!/usr/bin/env zsh
# Helper to load flatten_yaml_to_env_vars and related functions without dependencies

export OSA_CLI_DIR="${OSA_CLI_DIR:-.}"
export OSA_IS_MACOS="${OSA_IS_MACOS:-true}"

# Colors for output
export COLOR_RESET=$'\033[0m'
export COLOR_BOLD=$'\033[1m'
export COLOR_GREEN=$'\033[0;32m'
export COLOR_YELLOW=$'\033[0;33m'
export COLOR_BLUE=$'\033[0;34m'
export COLOR_RED=$'\033[0;31m'
export COLOR_CYAN=$'\033[0;36m'

# Configuration file
export OSA_CONFIG_FILE="${OSA_CONFIG_FILE:-$HOME/.osa-config}"

# Validate runtime version string (security: prevent command injection)
validate_version_string() {
  local version="$1"
  local runtime_name="$2"
  
  # Only allow: alphanumeric, dots, dashes, underscores
  # Block: semicolons, pipes, backticks, $(), spaces, etc.
  if [[ ! "$version" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo -e "${COLOR_RED}✗ Invalid version format for ${runtime_name}: $version${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Version must contain only: a-z A-Z 0-9 . _ -${COLOR_RESET}"
    return 1
  fi
  
  # Length limit (prevent buffer overflow / DoS)
  if [[ ${#version} -gt 50 ]]; then
    echo -e "${COLOR_RED}✗ Version string too long for ${runtime_name}: $version${COLOR_RESET}"
    return 1
  fi
  
  return 0
}

# Flatten nested YAML structure into flat OSA_CONFIG_* environment variables
flatten_yaml_to_env_vars() {
  local resolved_path="$1"
  
  if [[ ! -f "$resolved_path" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Config file not found: $resolved_path"
    return 1
  fi
  
  # Parse profile name
  local profile=$(yq eval '.profile' "$resolved_path" 2>/dev/null)
  if [[ -z "$profile" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Config missing 'profile' field"
    return 1
  fi

  # Use eval+export for dynamic variable names (bash-friendly)
  OSA_CONFIG_PROFILE="$profile"
  export OSA_CONFIG_PROFILE
  
  # Flatten components section
  local -a component_keys=(symlinks oh_my_zsh zsh_plugins homebrew mise osa_snippets git android iterm2 vscode cocoapods)
  for key in "${component_keys[@]}"; do
  local value=$(yq eval ".components.${key} // false" "$resolved_path" 2>/dev/null)
  local var_name="OSA_CONFIG_COMPONENTS_$(echo $key | tr a-z A-Z | tr '-' '_')"
  # Assign and export dynamic variable name in a bash-compatible way
  eval "${var_name}='${value}'"
  eval "export ${var_name}"
  done
  
  # Flatten runtimes section
  local -a runtime_keys=(node python ruby java rust go deno elixir erlang)
  for runtime in "${runtime_keys[@]}"; do
    local enabled=$(yq eval ".runtimes.${runtime}.enabled // false" "$resolved_path" 2>/dev/null)
    local version=$(yq eval ".runtimes.${runtime}.version // \"latest\"" "$resolved_path" 2>/dev/null)
    
  local enabled_var="OSA_CONFIG_RUNTIMES_$(echo $runtime | tr a-z A-Z)_ENABLED"
  local version_var="OSA_CONFIG_RUNTIMES_$(echo $runtime | tr a-z A-Z)_VERSION"

  eval "${enabled_var}='${enabled}'"
  eval "export ${enabled_var}"
  eval "${version_var}='${version}'"
  eval "export ${version_var}"
  done
  
  # Flatten snippets section
  # Get list of snippet repo names
  local snippet_repos=$(yq eval '.snippets | keys | .[]' "$resolved_path" 2>/dev/null)
  
  if [[ -n "$snippet_repos" ]]; then
    while IFS= read -r repo; do
      [[ -z "$repo" ]] && continue
      
      local repo_upper=$(echo "$repo" | tr a-z A-Z | tr '-' '_')
      local enabled=$(yq eval ".snippets.${repo}.enabled" "$resolved_path" 2>/dev/null)
  local enabled_var="OSA_CONFIG_SNIPPETS_${repo_upper}_ENABLED"
  eval "${enabled_var}='${enabled}'"
  eval "export ${enabled_var}"
      
      # Get features array
      local features=$(yq eval ".snippets.${repo}.features" "$resolved_path" 2>/dev/null)
      
      # If features is not a list/null, continue
      if [[ "$features" == "null" || -z "$features" ]]; then
        continue
      fi
      
      # Parse each feature from the list
      local feature_list=$(yq eval ".snippets.${repo}.features | .[]" "$resolved_path" 2>/dev/null)
      while IFS= read -r feature; do
        [[ -z "$feature" ]] && continue
        local feature_upper=$(echo "$feature" | tr a-z A-Z | tr '-' '_')
  local feature_var="OSA_CONFIG_SNIPPETS_${repo_upper}_${feature_upper}"
  eval "${feature_var}=true"
  eval "export ${feature_var}"
      done <<< "$feature_list"
    done <<< "$snippet_repos"
  fi
  
  return 0
}

# Load configuration from file
load_config() {
  if [[ -f "$OSA_CONFIG_FILE" ]]; then
    # Source config file (contains flattened OSA_CONFIG_* variables)
    source "$OSA_CONFIG_FILE" 2>/dev/null
    return 0
  fi
  return 1
}

# Save configuration to file in flattened format
save_config() {
  {
    echo "# OSA Configuration"
    echo "# Generated on $(date)"
    echo "# Profile: ${OSA_CONFIG_PROFILE:-custom}"
    echo "#"
    echo "# This file contains flattened configuration variables from YAML"
    echo "# Format: OSA_CONFIG_<SECTION>_<KEY>=<VALUE>"
    echo "#"
    echo "# Component flags (setup components to install):"
    echo "#   OSA_CONFIG_COMPONENTS_<NAME>=true|false"
    echo "#"
    echo "# Runtime versions (installed via mise):"
    echo "#   OSA_CONFIG_RUNTIMES_<NAME>_ENABLED=true|false"
    echo "#   OSA_CONFIG_RUNTIMES_<NAME>_VERSION=<version>"
    echo "#"
    echo "# Snippets features (loaded from snippet repos):"
    echo "#   OSA_CONFIG_SNIPPETS_<REPO>_ENABLED=true|false"
    echo "#   OSA_CONFIG_SNIPPETS_<REPO>_<FEATURE>=true"
    echo "#"
    echo ""
    
    # Export OSA_CONFIG_PROFILE
    echo "OSA_CONFIG_PROFILE='${OSA_CONFIG_PROFILE:-everything}'"
    echo ""
    
    # Export all OSA_CONFIG_* variables
    local config_vars=$(compgen -v | grep '^OSA_CONFIG_')
    for var in $config_vars; do
      local value=$(eval echo "\$$var")
      # Escape single quotes in values
      value="${value//\'/\'\\\'\'}"
      echo "${var}='${value}'"
    done
  } > "$OSA_CONFIG_FILE"
  
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} Configuration saved to $OSA_CONFIG_FILE"
}
