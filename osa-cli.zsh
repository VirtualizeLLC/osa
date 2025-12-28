#!/usr/bin/env zsh
# OSA (Open Source Automation) CLI
# Interactive setup tool with platform detection and component opt-in

# Get script directory (absolute path to directory)
OSA_CLI_DIR="$(cd "$(dirname "$0")" && pwd)"

# Export repo path for use in setup scripts
export OSA_REPO_PATH="$OSA_CLI_DIR"

# Source required modules
source "$OSA_CLI_DIR/src/zsh/constants/paths.zsh" || { echo "Failed to source paths.zsh"; exit 1; }
source "$OSA_CLI_DIR/src/zsh/constants/versions.zsh" || { echo "Failed to source versions.zsh"; exit 1; }
source "$OSA_CLI_DIR/src/zsh/helpers/detect-platform.zsh" || { echo "Failed to source detect-platform.zsh"; exit 1; }
source "$OSA_CLI_DIR/src/zsh/helpers/system-report.zsh" || { echo "Failed to source system-report.zsh"; exit 1; }

# Colors for output (use direct escape codes in zsh)
COLOR_RESET=$'\033[0m'
COLOR_BOLD=$'\033[1m'
COLOR_GREEN=$'\033[0;32m'
COLOR_YELLOW=$'\033[0;33m'
COLOR_BLUE=$'\033[0;34m'
COLOR_RED=$'\033[0;31m'
COLOR_CYAN=$'\033[0;36m'

# Configuration file
OSA_CONFIG_FILE="$HOME/.osa-config"

# Verbose mode flag (export so scripts can use it)
export OSA_VERBOSE=false

# Mise global setup flag (export so scripts can use it)
export OSA_SKIP_MISE_GLOBAL=false

# OSA Snippets flag (enabled by default, can be disabled with --disable-osa-snippets)
export OSA_SKIP_SNIPPETS=false

# Git configuration flag (can be disabled with --disable-git)
export OSA_SKIP_GIT_CONFIG=false

# CocoaPods flag (can be disabled with --skip-cocoapods for testing)
export OSA_SKIP_COCOAPODS=false

# Setup profile name (tracks which preset was used: minimal, react-native, etc.)
export OSA_SETUP_PROFILE="everything"

# Helper function to normalize component key to valid variable name
# Replaces hyphens with underscores and converts to uppercase
normalize_key() {
  echo "${1:gs/-/_/:u}"
}

# Flatten nested YAML structure into flat OSA_CONFIG_* environment variables
# Examples:
#   components.symlinks=true  →  OSA_CONFIG_COMPONENTS_SYMLINKS=true
#   runtimes.node.version=22  →  OSA_CONFIG_RUNTIMES_NODE_VERSION=22
#   snippets.osasnippets.enabled=true  →  OSA_CONFIG_SNIPPETS_OSASNIPPETS_ENABLED=true
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
  
  typeset -gx "OSA_CONFIG_PROFILE=$profile"
  
  # Flatten components section - get ALL keys dynamically
  local all_component_keys=$(yq eval '.components | keys | .[]' "$resolved_path" 2>/dev/null)
  
  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    local value=$(yq eval ".components.${key}" "$resolved_path" 2>/dev/null)
    local var_name="OSA_CONFIG_COMPONENTS_$(echo $key | tr a-z A-Z | tr '-' '_')"
    typeset -gx "$var_name=$value"
  done <<< "$all_component_keys"
  
  # Flatten runtimes section
  local -a runtime_keys=(node python ruby java rust go deno elixir erlang)
  for runtime in "${runtime_keys[@]}"; do
    local enabled=$(yq eval ".runtimes.${runtime}.enabled // false" "$resolved_path" 2>/dev/null)
    local version=$(yq eval ".runtimes.${runtime}.version // \"latest\"" "$resolved_path" 2>/dev/null)
    
    local enabled_var="OSA_CONFIG_RUNTIMES_$(echo $runtime | tr a-z A-Z)_ENABLED"
    local version_var="OSA_CONFIG_RUNTIMES_$(echo $runtime | tr a-z A-Z)_VERSION"
    
    typeset -gx "$enabled_var=$enabled"
    typeset -gx "$version_var=$version"
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
      typeset -gx "$enabled_var=$enabled"
      
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
        typeset -gx "$feature_var=true"
      done <<< "$feature_list"
    done <<< "$snippet_repos"
  fi
  
  return 0
}

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

# Load configuration from JSON file
# Usage: load_json_config "minimal" or load_json_config "configs/minimal.yaml" or load_json_config "/full/path/config.yaml"
load_json_config() {
  local json_file="$1"
  local resolved_path=""
  
  # Auto-resolve config name to configs/ directory
  if [[ ! "$json_file" =~ "/" ]]; then
    # No path separator - try configs/ directory with and without .yaml extension
    if [[ -f "$OSA_CLI_DIR/configs/${json_file}.yaml" ]]; then
      resolved_path="$OSA_CLI_DIR/configs/${json_file}.yaml"
    elif [[ -f "$OSA_CLI_DIR/configs/$json_file" ]]; then
      resolved_path="$OSA_CLI_DIR/configs/$json_file"
    else
      echo -e "${COLOR_RED}Error: Config not found: $json_file${COLOR_RESET}"
      echo -e "${COLOR_YELLOW}Available configs:${COLOR_RESET}"
      list_configs 2>/dev/null | head -20
      return 1
    fi
  elif [[ "$json_file" =~ ^/ ]]; then
    # Absolute path - use as-is
    resolved_path="$json_file"
  else
    # Relative path - resolve relative to repo root
    resolved_path="$OSA_CLI_DIR/$json_file"
  fi
  
  if [[ ! -f "$resolved_path" ]]; then
    echo -e "${COLOR_RED}Error: Config file not found: $resolved_path${COLOR_RESET}"
    return 1
  fi
  
  # Check if yq is available
  if ! command -v yq &> /dev/null; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} yq not found - required for YAML config parsing"
    echo ""
    echo "Install with:"
    if [[ "$OSA_IS_MACOS" == "true" ]]; then
      echo "  brew install yq"
    else
      echo "  apt-get install yq    (Ubuntu/Debian)"
      echo "  yum install yq        (RHEL/CentOS)"
      echo "  pacman -S yq          (Arch)"
    fi
    echo ""
    echo "Or run './osa-cli.zsh --interactive' instead (no yq needed)"
    return 1
  fi
  
  # Flatten YAML to env vars (populates OSA_CONFIG_* variables)
  if ! flatten_yaml_to_env_vars "$resolved_path"; then
    return 1
  fi
  
  # For backward compatibility during installation, also set OSA_SETUP_* variables
  # These are used by run_component() to determine what to install
  local -a component_keys=(symlinks oh_my_zsh zsh_plugins homebrew mise osa_snippets git android iterm2 vscode cocoapods depot_tools)
  
  for key in "${component_keys[@]}"; do
    local enabled=$(yq eval ".components.${key} // false" "$resolved_path" 2>/dev/null)
    local var_name="OSA_SETUP_$(normalize_key "$key")"
    
    if [[ "$enabled" == "true" ]]; then
      typeset -g "$var_name=true"
    else
      typeset -g "$var_name=false"
    fi
  done
  
  # Load runtimes into MISE_*_VERSION for runtime installation
  local -a runtime_keys=(node python ruby java rust go deno elixir erlang)
  
  for runtime in "${runtime_keys[@]}"; do
    local enabled=$(yq eval ".runtimes.${runtime}.enabled // false" "$resolved_path" 2>/dev/null)
    local version=$(yq eval ".runtimes.${runtime}.version // \"latest\"" "$resolved_path" 2>/dev/null)
    
    if [[ "$enabled" == "true" ]]; then
      # Validate version string contains only safe characters
      if ! validate_version_string "$version" "$runtime"; then
        return 1
      fi
      local var_name="MISE_$(echo $runtime | tr a-z A-Z)_VERSION"
      # Safe assignment without eval
      typeset -g "$var_name=$version"
    fi
  done
  
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} Configuration loaded from: $resolved_path"
  return 0
}

# Load remote configuration from URL
# Usage: load_remote_config "https://example.com/config.yaml"
load_remote_config() {
  local url="$1"
  local temp_config="/tmp/osa-remote-config-$$.yaml"
  
  # Validate URL is HTTPS only (security: prevent HTTP MITM attacks)
  if [[ ! "$url" =~ ^https:// ]]; then
    echo -e "${COLOR_RED}Error: Only HTTPS URLs are supported for security${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Provided: $url${COLOR_RESET}"
    return 1
  fi
  
  echo -e "${COLOR_CYAN}Downloading remote configuration...${COLOR_RESET}"
  echo -e "${COLOR_CYAN}URL: $url${COLOR_RESET}"
  echo ""
  
  # Try curl first, then wget
  if command -v curl &> /dev/null; then
    if ! curl -fsSL "$url" -o "$temp_config" 2>/dev/null; then
      echo -e "${COLOR_RED}Error: Failed to download config from: $url${COLOR_RESET}"
      rm -f "$temp_config"
      return 1
    fi
  elif command -v wget &> /dev/null; then
    if ! wget -q "$url" -O "$temp_config" 2>/dev/null; then
      echo -e "${COLOR_RED}Error: Failed to download config from: $url${COLOR_RESET}"
      rm -f "$temp_config"
      return 1
    fi
  else
    echo -e "${COLOR_RED}Error: Neither curl nor wget found. Install one to use remote configs.${COLOR_RESET}"
    return 1
  fi
  
  # Validate it's a YAML file
  if ! command -v yq &> /dev/null; then
    echo -e "${COLOR_RED}Error: yq is required to parse remote configs. Install with: brew install yq${COLOR_RESET}"
    rm -f "$temp_config"
    return 1
  fi
  
  if ! yq eval '.' "$temp_config" > /dev/null 2>&1; then
    echo -e "${COLOR_RED}Error: Downloaded file is not valid YAML${COLOR_RESET}"
    rm -f "$temp_config"
    return 1
  fi
  
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} Downloaded configuration"
  echo ""
  
  # Show preview of what will be installed
  echo -e "${COLOR_BOLD}Configuration Preview:${COLOR_RESET}"
  local description=$(yq eval '.description // "No description"' "$temp_config" 2>/dev/null)
  echo "  Description: $description"
  echo ""
  
  # Ask for confirmation unless in dry-run mode
  if [[ "$OSA_DRY_RUN" != "true" ]]; then
    echo -n -e "${COLOR_YELLOW}?${COLOR_RESET} Do you want to proceed with this remote configuration? [y/N] "
    read response
    if [[ ! "$response" =~ ^[Yy] ]]; then
      echo -e "${COLOR_YELLOW}Cancelled${COLOR_RESET}"
      rm -f "$temp_config"
      return 1
    fi
    echo ""
  fi
  
  # Load the config
  load_json_config "$temp_config"
  local result=$?
  
  # Clean up temp file
  rm -f "$temp_config"
  
  return $result
}

# Setup components registry
declare -A SETUP_COMPONENTS
declare -A COMPONENT_DESCRIPTIONS
declare -A COMPONENT_PLATFORMS

# Register setup components
register_component() {
  local key="$1"
  local description="$2"
  local platforms="$3"  # comma-separated: macos,linux,wsl or "all"
  local script_path="$4"
  
  SETUP_COMPONENTS[$key]="$script_path"
  COMPONENT_DESCRIPTIONS[$key]="$description"
  COMPONENT_PLATFORMS[$key]="$platforms"
}

# Initialize components
init_components() {
  # Core setup components (REQUIRED - have installation scripts)
  register_component "symlinks" "Create symlinks for zshrc and repo" "all" "src/setup/initialize-repo-symlinks.zsh"
  register_component "homebrew" "Install Homebrew package manager" "macos" "src/setup/install-brew.zsh"
  register_component "oh-my-zsh" "Install Oh My Zsh framework" "all" "src/setup/oh-my-zsh.zsh"
  register_component "zsh-plugins" "Install zsh plugins (syntax highlighting, etc)" "all" "src/setup/install-oh-my-zsh-plugins.zsh"
  
  # Runtime/Version managers (RECOMMENDED - mise-based)
  register_component "mise" "Install mise (polyglot runtime manager)" "all" "src/setup/install-mise.zsh"
  
  # Community scripts and helpers
  register_component "osa-snippets" "Clone osa-snippets repo (community shell functions/helpers)" "all" "src/setup/install-osa-snippets.zsh"
  
  # Development tools with install scripts
  register_component "git" "Configure Git (version control)" "all" "src/setup/git.zsh"
  register_component "cocoapods" "Install CocoaPods for iOS development" "macos" "src/setup/install-cocoapods.zsh"
  register_component "depot-tools" "Install depot_tools (Chromium development utilities)" "all" "src/setup/install-depot-tools.zsh"
}

# Check if component is available for current platform
is_component_available() {
  local key="$1"
  local platforms="${COMPONENT_PLATFORMS[$key]}"
  
  if [[ "$platforms" == "all" ]]; then
    return 0
  fi
  
  # Check if current platform is in the list
  if [[ ",$platforms," == *",$OSA_OS,"* ]]; then
    return 0
  fi
  
  return 1
}

# Load configuration from file
# Sources ~/.osa-config which contains flattened OSA_CONFIG_* variables
load_config() {
  if [[ -f "$OSA_CONFIG_FILE" ]]; then
    # Source config file (contains flattened OSA_CONFIG_* variables)
    source "$OSA_CONFIG_FILE" 2>/dev/null
    return 0
  fi
  return 1
}

# NOTE FOR TESTS: Do NOT call load_config here automatically during script startup
# This prevents stale user configuration from affecting test runs or interactive
# invocation. Tests look for the exact marker string: "Do NOT call load_config here"


# Save configuration to file in flattened format
save_config() {
  local temp_file="/tmp/osa-config-$$.tmp"
  
  {
    echo "# OSA Configuration"
    echo "# Generated on $(date)"
    echo "# Profile: ${OSA_CONFIG_PROFILE:-${OSA_SETUP_PROFILE:-custom}}"
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
    echo "OSA_CONFIG_PROFILE='${OSA_CONFIG_PROFILE:-${OSA_SETUP_PROFILE:-everything}}'"
    echo ""
    
    # Export all OSA_CONFIG_* variables that were set during config loading
    # Use a more robust method than compgen
    local all_vars=(${(k)parameters})
    for var in $all_vars; do
      if [[ $var == OSA_CONFIG_* ]]; then
        local value="${(P)var}"
        # Escape single quotes in values
        value="${value//\'/\'\\\'\'}"
        echo "${var}='${value}'"
      fi
    done
    
    # If no OSA_CONFIG_* variables exist (interactive mode), convert OSA_SETUP_* to OSA_CONFIG_*
    if [[ -z "$(echo $all_vars | grep '^OSA_CONFIG_')" ]]; then
      # Convert OSA_SETUP_* component flags to OSA_CONFIG_COMPONENTS_*
      local -a component_keys=(symlinks homebrew oh_my_zsh zsh_plugins mise osa_snippets git android iterm2 vscode cocoapods depot_tools)
      for key in "${component_keys[@]}"; do
        local var_name="OSA_SETUP_$(echo $key | tr a-z A-Z | tr '-' '_')"
        local value="${(P)var_name}"
        local config_name="OSA_CONFIG_COMPONENTS_$(echo $key | tr a-z A-Z | tr '-' '_')"
        echo "${config_name}='${value:-false}'"
      done
      
      # Export runtimes (from OSA_SETUP_RUNTIME_* or OSA_SETUP_RUNTIMES_*)
      local -a runtime_keys=(node python ruby java rust go deno elixir erlang)
      for runtime in "${runtime_keys[@]}"; do
        local enabled_var="OSA_SETUP_RUNTIME_$(echo $runtime | tr a-z A-Z)_ENABLED"
        local version_var="OSA_SETUP_RUNTIME_$(echo $runtime | tr a-z A-Z)_VERSION"
        local enabled="${(P)enabled_var}"
        local version="${(P)version_var}"
        
        echo "OSA_CONFIG_RUNTIMES_$(echo $runtime | tr a-z A-Z)_ENABLED='${enabled:-false}'"
        echo "OSA_CONFIG_RUNTIMES_$(echo $runtime | tr a-z A-Z)_VERSION='${version:-latest}'"
      done
    fi
  } > "$temp_file"
  
  # Move temp file to final location
  mv "$temp_file" "$OSA_CONFIG_FILE"
  
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} Configuration saved to $OSA_CONFIG_FILE"
}

# Ask user yes/no question
ask_yes_no() {
  local question="$1"
  local default="${2:-n}"
  
  local prompt
  if [[ "$default" == "y" ]]; then
    prompt="[Y/n]"
  else
    prompt="[y/N]"
  fi
  
  echo -n -e "${COLOR_CYAN}?${COLOR_RESET} $question $prompt "
  read response
  
  response="${response:-$default}"
  if [[ "$response" =~ ^[Yy] ]]; then
    return 0
  else
    return 1
  fi
}

# Ask user to select from a list of options with scrollable menu
select_from_list() {
  local prompt="$1"
  shift
  local -a options=("$@")
  local selection=""
  local i
  
  echo -e "${COLOR_CYAN}?${COLOR_RESET} $prompt" >&2
  
  for ((i=1; i<=${#options[@]}; i++)); do
    echo "  $i) ${options[$i]}" >&2
  done
  
  echo -n -e "Select option [1]: " >&2
  read selection
  
  selection=${selection:-1}
  
  if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le ${#options[@]} ]]; then
    echo "${options[$selection]}"
    return 0
  else
    echo "Invalid selection, using default: ${options[1]}" >&2
    echo "${options[1]}"
    return 1
  fi
}

# Interactive menu to select multiple runtimes for mise
select_runtimes_for_mise() {
  local all_runtimes
  all_runtimes=(node python ruby java rust go deno elixir erlang)
  
  echo -e "${COLOR_BOLD}Select runtimes to install with mise:${COLOR_RESET}"
  echo ""
  echo "Available runtimes:"
  
  # Display all runtimes with numbers (1-indexed)
  local i=1
  for runtime in "${all_runtimes[@]}"; do
    echo "  $i. $runtime"
    ((i++))
  done
  
  echo ""
  echo "Enter runtime numbers to install (space-separated, or enter for Node.js only)"
  echo "Example: 1 2 4   (installs Node, Python, Java)"
  echo -n "> "
  read -r selection
  
  # Parse selections (default to node if empty)
  selection="${selection:-1}"
  
  echo ""
  echo -e "${COLOR_BOLD}Configuring selected runtimes:${COLOR_RESET}"
  echo ""
  
  # Process each selected index
  for idx in $selection; do
    if [[ "$idx" =~ ^[0-9]+$ ]] && [[ "$idx" -ge 1 ]] && [[ "$idx" -le ${#all_runtimes[@]} ]]; then
      local runtime_idx=$((idx - 1))
      local runtime="${all_runtimes[$runtime_idx]}"
      
      case "$runtime" in
        node)
          echo "Node.js versions available: 20 (LTS), 22 (LTS), 24 (Latest)"
          echo -n "Select Node version [22]: "
          read -r node_version
          node_version="${node_version:-22}"
          if ! validate_version_string "$node_version" "Node.js"; then
            echo "Skipping Node.js installation due to invalid version"
            continue
          fi
          export MISE_NODE_VERSION="$node_version"
          echo "  ✓ Node.js: $node_version"
          ;;
        python)
          echo "Python versions available: 3.11, 3.12, 3.13"
          echo -n "Select Python version [3.13]: "
          read -r python_version
          python_version="${python_version:-3.13}"
          if ! validate_version_string "$python_version" "Python"; then
            echo "Skipping Python installation due to invalid version"
            continue
          fi
          export MISE_PYTHON_VERSION="$python_version"
          echo "  ✓ Python: $python_version"
          ;;
        ruby)
          echo "Ruby versions available: 3.2.0, 3.3.0, 3.4.0"
          echo -n "Select Ruby version [3.4.0]: "
          read -r ruby_version
          ruby_version="${ruby_version:-3.4.0}"
          if ! validate_version_string "$ruby_version" "Ruby"; then
            echo "Skipping Ruby installation due to invalid version"
            continue
          fi
          export MISE_RUBY_VERSION="$ruby_version"
          echo "  ✓ Ruby: $ruby_version"
          ;;
        java)
          echo "Java versions available: zulu-17 zulu-17, zulu-21, zulu zulu-23"
          echo -n "Select Java version [zulu-17]: "
          read -r java_version
          java_version="${java_version:-zulu-17}"
          if ! validate_version_string "$java_version" "Java"; then
            echo "Skipping Java installation due to invalid version"
            continue
          fi
          export MISE_JAVA_VERSION="$java_version"
          echo "  ✓ Java: $java_version"
          ;;
        rust)
          export MISE_RUST_VERSION="stable"
          echo "  ✓ Rust: stable"
          ;;
        go)
          echo "Go versions available: 1.21, 1.22, 1.23"
          echo -n "Select Go version [1.23]: "
          read -r go_version
          go_version="${go_version:-1.23}"
          if ! validate_version_string "$go_version" "Go"; then
            echo "Skipping Go installation due to invalid version"
            continue
          fi
          export MISE_GO_VERSION="$go_version"
          echo "  ✓ Go: $go_version"
          ;;
        deno)
          export MISE_DENO_VERSION="latest"
          echo "  ✓ Deno: latest"
          ;;
        elixir)
          export MISE_ELIXIR_VERSION="latest"
          echo "  ✓ Elixir: latest"
          ;;
        erlang)
          export MISE_ERLANG_VERSION="latest"
          echo "  ✓ Erlang: latest"
          ;;
      esac
    fi
  done
  
  echo ""
}

# Validate a configuration file for syntax errors and show what would be loaded
validate_config() {
  local config_path="$1"
  
  if [[ -z "$config_path" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Config path required"
    return 1
  fi
  
  # Resolve config path
  local resolved_path=""
  if [[ ! "$config_path" =~ "/" ]]; then
    # No path separator - try configs/ directory
    if [[ -f "$OSA_CLI_DIR/configs/${config_path}.yaml" ]]; then
      resolved_path="$OSA_CLI_DIR/configs/${config_path}.yaml"
    elif [[ -f "$OSA_CLI_DIR/configs/$config_path" ]]; then
      resolved_path="$OSA_CLI_DIR/configs/$config_path"
    else
      echo -e "${COLOR_RED}✗${COLOR_RESET} Config not found: $config_path"
      echo -e "${COLOR_YELLOW}Available configs:${COLOR_RESET}"
      list_configs 2>/dev/null | head -20
      return 1
    fi
  elif [[ "$config_path" =~ ^/ ]]; then
    resolved_path="$config_path"
  else
    resolved_path="$OSA_CLI_DIR/$config_path"
  fi
  
  if [[ ! -f "$resolved_path" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Config file not found: $resolved_path"
    return 1
  fi
  
  # Check if yq is available
  if ! command -v yq &> /dev/null; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} yq not found - required to validate YAML config"
    echo ""
    echo "Install with:"
    if [[ "$OSA_IS_MACOS" == "true" ]]; then
      echo "  brew install yq"
    else
      echo "  apt-get install yq    (Ubuntu/Debian)"
      echo "  yum install yq        (RHEL/CentOS)"
      echo "  pacman -S yq          (Arch)"
    fi
    return 1
  fi
  
  echo -e "${COLOR_BOLD}${COLOR_CYAN}▶ Validating configuration: $(basename "$resolved_path")${COLOR_RESET}"
  echo ""
  
  # Test YAML syntax
  if ! yq eval '.' "$resolved_path" > /dev/null 2>&1; then
    echo -e "${COLOR_RED}✗ YAML syntax error:${COLOR_RESET}"
    yq eval '.' "$resolved_path" 2>&1 | head -20
    return 1
  fi
  
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} YAML syntax is valid"
  echo ""
  
  # Show what will be loaded
  echo -e "${COLOR_BOLD}Configuration Summary:${COLOR_RESET}"
  echo ""
  
  local profile=$(yq eval '.profile' "$resolved_path" 2>/dev/null)
  local description=$(yq eval '.description' "$resolved_path" 2>/dev/null)
  echo "  Profile: ${COLOR_CYAN}${profile}${COLOR_RESET}"
  echo "  Description: $description"
  echo ""
  
  # Show enabled components
  echo -e "${COLOR_BOLD}Setup Components (to be installed):${COLOR_RESET}"
  local -a component_keys=(symlinks oh_my_zsh zsh_plugins homebrew mise osa_snippets git cocoapods depot_tools)
  for key in "${component_keys[@]}"; do
    local enabled=$(yq eval ".components.${key} // false" "$resolved_path" 2>/dev/null)
    if [[ "$enabled" == "true" ]]; then
      echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} $key"
    fi
  done
  echo ""
  
  # Show enabled runtimes
  echo -e "${COLOR_BOLD}Runtimes (installed via mise):${COLOR_RESET}"
  local -a runtime_keys=(node python ruby java rust go deno elixir erlang)
  local any_enabled=false
  for runtime in "${runtime_keys[@]}"; do
    local enabled=$(yq eval ".runtimes.${runtime}.enabled // false" "$resolved_path" 2>/dev/null)
    if [[ "$enabled" == "true" ]]; then
      local version=$(yq eval ".runtimes.${runtime}.version // \"latest\"" "$resolved_path" 2>/dev/null)
      echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} $runtime (${COLOR_CYAN}${version}${COLOR_RESET})"
      any_enabled=true
    fi
  done
  if [[ "$any_enabled" != "true" ]]; then
    echo "  (none enabled)"
  fi
  echo ""
  
  # Show snippet repos
  echo -e "${COLOR_BOLD}Snippet Repositories:${COLOR_RESET}"
  local snippet_repos=$(yq eval '.snippets | keys | .[]' "$resolved_path" 2>/dev/null)
  if [[ -n "$snippet_repos" ]]; then
    while IFS= read -r repo; do
      [[ -z "$repo" ]] && continue
      local enabled=$(yq eval ".snippets.${repo}.enabled" "$resolved_path" 2>/dev/null)
      if [[ "$enabled" == "true" ]]; then
        local features=$(yq eval ".snippets.${repo}.features | .[]" "$resolved_path" 2>/dev/null)
        if [[ -n "$features" ]]; then
          echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} $repo"
          while IFS= read -r feature; do
            [[ -z "$feature" ]] && continue
            echo -e "      • ${COLOR_CYAN}${feature}${COLOR_RESET}"
          done <<< "$features"
        else
          echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} $repo (no specific features)"
        fi
      fi
    done <<< "$snippet_repos"
  else
    echo "  (none)"
  fi
  echo ""
  
  echo -e "${COLOR_GREEN}✓ Configuration is valid and ready to use${COLOR_RESET}"
  echo ""
  echo -e "${COLOR_BOLD}To apply this configuration, run:${COLOR_RESET}"
  echo "  ${COLOR_CYAN}./osa-cli.zsh --config ${profile}${COLOR_RESET}"
  echo "  ${COLOR_CYAN}./osa-cli.zsh --config ${profile} --dry-run${COLOR_RESET} (preview without installing)"
  echo ""
  
  return 0
}

# Global flag for dry-run mode
OSA_DRY_RUN=false

# Run a setup component
run_component() {
  local key="$1"
  local script_path="${SETUP_COMPONENTS[$key]}"
  
  if [[ -z "$script_path" && "$key" != "android" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Unknown component: $key"
    return 1
  fi
  
  if ! is_component_available "$key"; then
    echo -e "${COLOR_YELLOW}⊘${COLOR_RESET} Component '$key' not available for $OSA_OS"
    return 0
  fi
  
  # Special handling for Android (configuration-only component)
  if [[ "$key" == "android" ]]; then
    if [[ "$OSA_DRY_RUN" == "true" ]]; then
      echo -e "${COLOR_CYAN}[DRY-RUN]${COLOR_RESET} Would enable: ${COMPONENT_DESCRIPTIONS[$key]}"
      echo -e "${COLOR_CYAN}[DRY-RUN]${COLOR_RESET}   Sets: OSA_SETUP_ANDROID=true"
      return 0
    fi
    
    echo -e "${COLOR_BLUE}▶${COLOR_RESET} Enabling: ${COMPONENT_DESCRIPTIONS[$key]}"
    echo -e "${COLOR_GREEN}✓${COLOR_RESET} Android support enabled (requires ANDROID_HOME to be set)"
    return 0
  fi
  
  local full_path="$OSA_CLI_DIR/$script_path"
  if [[ ! -f "$full_path" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Script not found: $full_path"
    return 1
  fi
  
  if [[ "$OSA_DRY_RUN" == "true" ]]; then
    echo -e "${COLOR_CYAN}[DRY-RUN]${COLOR_RESET} Would run: ${COMPONENT_DESCRIPTIONS[$key]}"
    echo -e "${COLOR_CYAN}[DRY-RUN]${COLOR_RESET}   Script: $script_path"
    return 0
  fi
  
  echo -e "${COLOR_BLUE}▶${COLOR_RESET} Running: ${COMPONENT_DESCRIPTIONS[$key]}"
  
  # Source the script (most setup scripts are meant to be sourced)
  if source "$full_path"; then
    echo -e "${COLOR_GREEN}✓${COLOR_RESET} Completed: $key"
    return 0
  else
    echo -e "${COLOR_RED}✗${COLOR_RESET} Failed: $key"
    return 1
  fi
}

# Interactive setup mode
interactive_setup() {
  echo -e "${COLOR_BOLD}${COLOR_CYAN}"
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║          Open Source Automation (OSA) - Interactive Setup      ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo -e "${COLOR_RESET}"
  
  print_platform_info
  
  if ! is_platform_supported; then
    echo -e "${COLOR_RED}✗ Platform '$OSA_OS' is not currently supported${COLOR_RESET}"
    exit 1
  fi
  
  # macOS pre-flight check: Xcode Command Line Tools
  if [[ "$OSA_IS_MACOS" == "true" ]]; then
    # Check if xcode-select returns a valid path (CLT is installed)
    # xcode-select -p returns the path to CLT, or fails if not installed
    local xcode_path=$(xcode-select -p 2>/dev/null)
    if [[ -z "$xcode_path" ]] || [[ ! -d "$xcode_path" ]]; then
      echo -e "${COLOR_YELLOW}⚠️  Xcode Command Line Tools not found${COLOR_RESET}"
      echo ""
      echo "Homebrew and many development tools require Xcode CLT."
      echo "Install from Apple Developer:"
      echo "  ${COLOR_BOLD}https://developer.apple.com/download/more/${COLOR_RESET}"
      echo ""
      echo "Or try: ${COLOR_BOLD}xcode-select --install${COLOR_RESET}"
      echo ""
    fi
  fi
  
  echo -e "${COLOR_BOLD}Select components to install:${COLOR_RESET}\n"
  
  # CRITICAL: Always include required components IN CORRECT ORDER
  # Order matters! Symlinks must be first, then platform tools, then shell setup
  local -a selected_components
  
  # 1. SYMLINKS FIRST (creates ~/.osa directory structure)
  selected_components+=("symlinks")
  OSA_SETUP_SYMLINKS=true
  
  # 2. HOMEBREW (if on macOS - needed before installing other tools)
  if [[ "$OSA_IS_MACOS" == "true" ]]; then
    selected_components+=("homebrew")
    OSA_SETUP_HOMEBREW=true
  fi
  
  # 3. OH-MY-ZSH (depends on ~/.osa existing)
  selected_components+=("oh-my-zsh")
  OSA_SETUP_OH_MY_ZSH=true
  
  # 4. ZSH PLUGINS (depends on oh-my-zsh being installed)
  selected_components+=("zsh-plugins")
  OSA_SETUP_ZSH_PLUGINS=true
  
  echo -e "${COLOR_GREEN}Core components (required):${COLOR_RESET}"
  echo "  ✓ Symlinks (repo, .zshrc)"
  echo "  ✓ Oh My Zsh framework"
  echo "  ✓ Zsh plugins (syntax highlighting, evalcache)"
  if [[ "$OSA_IS_MACOS" == "true" ]]; then
    echo "  ✓ Homebrew"
  fi
  echo ""
  echo -e "${COLOR_BOLD}Recommended: Install Mise first${COLOR_RESET}"
  if ask_yes_no "Install mise (polyglot runtime manager for Node, Ruby, Java, Python, Go, Rust, etc)?" "y"; then
    selected_components+=("mise")
    OSA_SETUP_MISE=true
    
    echo ""
    select_runtimes_for_mise
    echo ""
  else
    OSA_SETUP_MISE=false
  fi
  
  echo ""
  echo -e "${COLOR_BOLD}Core Productivity Tools${COLOR_RESET}"
  if ask_yes_no "Install osa-scripts (community helpers and productivity functions)?" "y"; then
    selected_components+=("osa-snippets")
    OSA_SETUP_OSA_SNIPPETS=true
  else
    OSA_SETUP_OSA_SNIPPETS=false
  fi
  echo ""
  
  # Ask about optional development tools
  echo -e "${COLOR_BOLD}Optional components:${COLOR_RESET}\n"
  
  # Skip the required components and mise (already handled above), ask about everything else
  for key in "${(@k)SETUP_COMPONENTS}"; do
    # Skip required components, mise, and osa-snippets (which are handled specially)
    if [[ "$key" == "symlinks" ]] || [[ "$key" == "oh-my-zsh" ]] || [[ "$key" == "zsh-plugins" ]] || [[ "$key" == "homebrew" ]] || [[ "$key" == "mise" ]] || [[ "$key" == "osa-snippets" ]]; then
      continue
    fi
    
    # Special handling for CocoaPods - ask with version selection (unless --skip-cocoapods)
    if [[ "$key" == "cocoapods" ]]; then
      if [[ "$OSA_SKIP_COCOAPODS" == "true" ]]; then
        echo -e "${COLOR_YELLOW}⊘${COLOR_RESET} Skipping CocoaPods (--skip-cocoapods flag set)"
        continue
      fi
      if is_component_available "$key"; then
        # Source the interactive CocoaPods setup
        if source "$OSA_CLI_DIR/src/setup/install-cocoapods-interactive.zsh"; then
          if ask_install_cocoapods; then
            selected_components+=("$key")
            # Already set OSA_SETUP_COCOAPODS in the function
          fi
        fi
      fi
      continue
    fi
    
    if is_component_available "$key"; then
      local desc="${COMPONENT_DESCRIPTIONS[$key]}"
      if ask_yes_no "Install $desc?" "n"; then
        selected_components+=("$key")
        # Set config variable (safe assignment without eval)
        local var_name="OSA_SETUP_$(normalize_key "$key")"
        typeset -g "$var_name=true"
      else
        local var_name="OSA_SETUP_$(normalize_key "$key")"
        typeset -g "$var_name=false"
      fi
    fi
  done
  
  echo ""
  
  if [[ ${#selected_components[@]} -eq 0 ]]; then
    echo -e "${COLOR_YELLOW}No components selected. Exiting.${COLOR_RESET}"
    return 0
  fi
  
  # Confirm and save config
  if ask_yes_no "Save this configuration for future runs?" "y"; then
    save_config
  fi
  
  echo -e "\n${COLOR_BOLD}Starting installation...${COLOR_RESET}\n"
  
  # Run selected components
  local failed=0
  for key in "${selected_components[@]}"; do
    if ! run_component "$key"; then
      failed=$((failed + 1))
    fi
    echo ""
  done
  
  # Summary
  echo -e "${COLOR_BOLD}═══════════════════════════════════════${COLOR_RESET}"
  if [[ $failed -eq 0 ]]; then
    echo -e "${COLOR_GREEN}✓ All components installed successfully!${COLOR_RESET}"
  else
    echo -e "${COLOR_YELLOW}⚠ Completed with $failed failed component(s)${COLOR_RESET}"
  fi
  echo -e "${COLOR_BOLD}═══════════════════════════════════════${COLOR_RESET}\n"
  
  # Post-installation instructions
  echo -e "${COLOR_CYAN}Next steps:${COLOR_RESET}"
  echo "  1. Restart your terminal or run: ${COLOR_BOLD}source ~/.zshrc${COLOR_RESET}"
  
  # Special note for mise
  if [[ " ${selected_components[@]} " =~ " mise " ]]; then
    echo "  2. Run: ${COLOR_BOLD}mise install${COLOR_RESET} (or restart terminal to auto-activate)"
    echo "  3. Verify runtimes with: ${COLOR_BOLD}mise --version${COLOR_RESET} and ${COLOR_BOLD}node --version${COLOR_RESET}"
  fi
  
  echo "  4. Run 'osa' to see available commands"
  echo "  5. Edit constructors in src/zsh/constructors/ for machine-specific config"
}

# Automated setup using saved config
automated_setup() {
  echo -e "${COLOR_BOLD}${COLOR_CYAN}▶ OSA Setup in progress...${COLOR_RESET}\n"
  
  print_platform_info
  
  # macOS pre-flight check: Xcode Command Line Tools
  if [[ "$OSA_IS_MACOS" == "true" ]]; then
    # Check if xcode-select returns a valid path (CLT is installed)
    # xcode-select -p returns the path to CLT, or fails if not installed
    local xcode_path=$(xcode-select -p 2>/dev/null)
    if [[ -z "$xcode_path" ]] || [[ ! -d "$xcode_path" ]]; then
      echo -e "${COLOR_YELLOW}⚠️  Xcode Command Line Tools not found${COLOR_RESET}"
      echo ""
      echo "Homebrew and many development tools require Xcode CLT."
      echo "Install from Apple Developer:"
      echo "  ${COLOR_BOLD}https://developer.apple.com/download/more/${COLOR_RESET}"
      echo ""
      echo "Or try: ${COLOR_BOLD}xcode-select --install${COLOR_RESET}"
      echo ""
    fi
  fi
  
  # Build components in the REQUIRED ORDER (array order matters!)
  local -a selected_components
  
  # Always check in this order - symlinks must be first!
  if [[ "$OSA_SETUP_SYMLINKS" == "true" ]]; then
    selected_components+=("symlinks")
  fi
  
  if [[ "$OSA_SETUP_HOMEBREW" == "true" ]] && is_component_available "homebrew"; then
    selected_components+=("homebrew")
  fi
  
  if [[ "$OSA_SETUP_OH_MY_ZSH" == "true" ]]; then
    selected_components+=("oh-my-zsh")
  fi
  
  if [[ "$OSA_SETUP_ZSH_PLUGINS" == "true" ]]; then
    selected_components+=("zsh-plugins")
  fi
  
  if [[ "$OSA_SETUP_MISE" == "true" ]]; then
    selected_components+=("mise")
  fi
  
  if [[ "$OSA_SETUP_OSA_SNIPPETS" == "true" ]]; then
    selected_components+=("osa-snippets")
  fi
  
  if [[ "$OSA_SETUP_GIT" == "true" ]]; then
    selected_components+=("git")
  fi
  
  if [[ "$OSA_SETUP_COCOAPODS" == "true" ]] && [[ "$OSA_SKIP_COCOAPODS" != "true" ]] && is_component_available "cocoapods"; then
    selected_components+=("cocoapods")
  fi
  
  if [[ ${#selected_components[@]} -eq 0 ]]; then
    echo -e "${COLOR_YELLOW}No components enabled in configuration.${COLOR_RESET}"
    echo "Run with --interactive to select components."
    return 1
  fi
  
  echo -e "Installing ${#selected_components[@]} component(s)...\n"
  
  local failed=0
  for key in "${selected_components[@]}"; do
    if ! run_component "$key"; then
      failed=$((failed + 1))
    fi
    echo ""
  done
  
  if [[ $failed -eq 0 ]]; then
    echo -e "${COLOR_GREEN}✓ Setup completed successfully!${COLOR_RESET}"
  else
    echo -e "${COLOR_YELLOW}⚠ Setup completed with $failed error(s)${COLOR_RESET}"
  fi
  
  # Save the configuration for future runs
  save_config
  
  # Auto-source the new shell configuration (but skip config loading during setup)
  echo ""
  echo -e "${COLOR_CYAN}Sourcing your new shell configuration...${COLOR_RESET}"
  OSA_SKIP_CONFIG_LOAD=true source "$HOME/.zshrc"
  unset OSA_SKIP_CONFIG_LOAD
  echo -e "${COLOR_GREEN}✨ Shell updated! You're ready to go.${COLOR_RESET}"
  
  # Show next steps
  echo ""
  echo -e "${COLOR_BOLD}${COLOR_CYAN}Next steps:${COLOR_RESET}"
  echo "  1. Try it out: ${COLOR_BOLD}mise --version${COLOR_RESET}"
  echo "  2. Test in a new terminal (recommended): ${COLOR_BOLD}zsh${COLOR_RESET}"
  echo "  3. Happy coding! 🚀"
  
  echo ""
  echo -e "${COLOR_BOLD}${COLOR_GREEN}✓ OSA setup completed successfully${COLOR_RESET}"
}

# Show help
show_help() {
  cat << EOF
${COLOR_BOLD}OSA (Open Source Automation) CLI${COLOR_RESET}

${COLOR_BOLD}USAGE:${COLOR_RESET}
  ./osa-cli.zsh [options]

${COLOR_BOLD}OPTIONS:${COLOR_RESET}
  -h, --help              Show this help message
  -i, --interactive       Run interactive setup (select components)
  -a, --auto              Run automated setup using saved config
  -v, --verbose           Show detailed output from installers (git, oh-my-zsh, etc.)
  --config FILE           Use JSON config file (auto-resolved from configs/), or show current config if no FILE
  --config-url URL        Use JSON config from URL (supports GitHub raw, gists, etc.)
  --list-configs          List all available preset configurations
  -l, --list              List all available components
  --info                  Show platform information
  --status                Show current configuration
  --enable COMPONENT      Enable a specific component
  --disable COMPONENT     Disable a specific component
  --all                   Enable all components (use with care)
  --minimal               Install core + mise (recommended for most users)
  --dry-run               Show what would be installed without running scripts
  --clean                 Remove all OSA data (can combine with --minimal or --all for clean install)
  --unsafe                Skip confirmation prompts for destructive operations (e.g., --clean)
  --clean-symlinks        Remove all OSA symlinks (interactive confirmation)
  --clean-oh-my-zsh       Remove oh-my-zsh plugin symlinks only
  --local                 Skip global mise setup (only setup local configs)
  --disable-osa-snippets  Skip osa-snippets installation (enabled by default)
  --disable-git           Skip Git configuration (default: configure git)
  --skip-cocoapods        Skip CocoaPods installation (useful for testing)
  --doctor                Validate installation health (no changes made)
                          Usage: ./osa-cli.zsh --doctor [optional: config name]
                          ./osa-cli.zsh --doctor              # Check installation
                          ./osa-cli.zsh --doctor minimal      # Validate minimal.yaml
  --report                Generate system report for bug reporting
  --report-json           Generate system report in JSON format
  --report-url            Generate GitHub issue URL with pre-filled environment info

${COLOR_BOLD}SECURITY:${COLOR_RESET}
  --scan-secrets          Scan constructors for hardcoded secrets/credentials
  --migrate-secrets       Interactive wizard to move secrets to secure storage
  --setup-git-hook        Install pre-commit hook to prevent secret commits

${COLOR_BOLD}RUNTIME COMMANDS (available as 'osa' in shell):${COLOR_RESET}
  osa open                Open OSA repository in editor (default: VS Code)
  osa --help              Show this help
  osa --info              Show platform information
  osa --config NAME       Load and run configuration
  (all CLI commands work with 'osa' shortcut)

${COLOR_BOLD}EDITOR OVERRIDE:${COLOR_RESET}
  Set OSA_EDITOR to override the default editor:
  export OSA_EDITOR=vim
  osa open                # Now opens with vim instead of VS Code

${COLOR_BOLD}WHAT'S REQUIRED vs OPTIONAL:${COLOR_RESET}
  REQUIRED: symlinks, oh-my-zsh, zsh-plugins (automatically installed)
  RECOMMENDED: mise (polyglot runtime manager - asks during setup)
  OPTIONAL: git, cocoapods, etc.

${COLOR_BOLD}JSON CONFIG:${COLOR_RESET}
  Create a config file based on configs/example-config.yaml and run:
  ./osa-cli.zsh --config minimal [--dry-run]
  
  Or use a remote configuration via URL:
  ./osa-cli.zsh --config-url https://raw.githubusercontent.com/user/repo/main/config.yaml
  
  View available presets:
  ./osa-cli.zsh --list-configs
  
  This will use all settings from the JSON file without interactive prompts.

${COLOR_BOLD}TROUBLESHOOTING:${COLOR_RESET}
  If symlinks get corrupted:
    ./osa-cli.zsh --clean-symlinks        # Remove all symlinks
    ./osa-cli.zsh --interactive           # Recreate them
  
  If oh-my-zsh plugins are broken:
    ./osa-cli.zsh --clean-oh-my-zsh       # Remove plugin symlinks only
  
  For a complete fresh install:
    ./osa-cli.zsh --clean --minimal       # Remove all OSA data and reinstall
  
  For automated clean without prompts:
    ./osa-cli.zsh --clean --unsafe --minimal  # Skip confirmation, clean and reinstall

${COLOR_BOLD}EXAMPLES:${COLOR_RESET}
  ./osa-cli.zsh --interactive                     # Interactive component selection
  ./osa-cli.zsh --list-configs                    # See available presets
  ./osa-cli.zsh --config react-native             # Use React Native preset
  ./osa-cli.zsh --auto                            # Run with saved configuration
  ./osa-cli.zsh --minimal                         # Install core + mise (recommended)
  ./osa-cli.zsh --all                             # Install everything
  ./osa-cli.zsh --config=/full/path/config.yaml --dry-run # Test with custom config
  ./osa-cli.zsh --clean --minimal      # Clean fresh install (interactive)
  ./osa-cli.zsh --clean --unsafe --minimal # Clean and install (no prompts)
  ./osa-cli.zsh --doctor               # Check installation health

${COLOR_BOLD}QUICK START:${COLOR_RESET}
  1. ./osa-cli.zsh --interactive       # Choose what you want
  2. mise install                      # Install runtimes from .mise.toml
  3. source ~/.zshrc                   # Reload shell

${COLOR_BOLD}COMPONENTS:${COLOR_RESET}
EOF

  for key in "${(@k)SETUP_COMPONENTS}"; do
    local desc="${COMPONENT_DESCRIPTIONS[$key]}"
    local platforms="${COMPONENT_PLATFORMS[$key]}"
    local available=""
    
    if is_component_available "$key"; then
      available="${COLOR_GREEN}✓${COLOR_RESET}"
    else
      available="${COLOR_YELLOW}⊘${COLOR_RESET}"
    fi
    
    printf "  %-15s %s %s ${COLOR_RESET}(${platforms})${COLOR_RESET}\n" "$key" "$available" "$desc"
  done
}

# List components
list_components() {
  echo -e "${COLOR_BOLD}Available Components:${COLOR_RESET}\n"
  
  for key in "${(@k)SETUP_COMPONENTS}"; do
    local desc="${COMPONENT_DESCRIPTIONS[$key]}"
    local platforms="${COMPONENT_PLATFORMS[$key]}"
    local var_name="OSA_SETUP_$(normalize_key "$key")"
    local enabled="${(P)var_name}"
    
    local comp_status
    if ! is_component_available "$key"; then
      comp_status="${COLOR_YELLOW}[unavailable]${COLOR_RESET}"
    elif [[ "$enabled" == "true" ]]; then
      comp_status="${COLOR_GREEN}[enabled]${COLOR_RESET}"
    else
      comp_status="${COLOR_RESET}[disabled]${COLOR_RESET}"
    fi
    
    printf "  %-15s %s %s (${platforms})\n" "$key" "$comp_status" "$desc"
  done
}

# List available configuration files
list_configs() {
  echo -e "${COLOR_BOLD}Available Configuration Presets:${COLOR_RESET}\n"
  
  local configs_dir="$OSA_CLI_DIR/configs"
  
  if [[ ! -d "$configs_dir" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Configs directory not found: $configs_dir"
    return 1
  fi
  
  for config_file in "$configs_dir"/*.yaml; do
    if [[ ! -f "$config_file" ]]; then
      continue
    fi
    
    local filename=$(basename "$config_file")
    local description=""
    
    if command -v yq &> /dev/null; then
      description=$(yq eval '.description // "No description"' "$config_file" 2>/dev/null)
    else
      description="(Install yq to see descriptions)"
    fi
    
    printf "  ${COLOR_CYAN}%-30s${COLOR_RESET} %s\n" "$filename" "$description"
  done
  
  echo ""
  echo -e "${COLOR_BOLD}Usage:${COLOR_RESET}"
  echo "  ./osa-cli.zsh --config react-native"
  echo ""
  echo -e "${COLOR_BOLD}Preview without installing:${COLOR_RESET}"
  echo "  ./osa-cli.zsh --config react-native --dry-run"
}

# Show current config
show_config() {
  echo -e "${COLOR_BOLD}Current Configuration:${COLOR_RESET}\n"
  
  if [[ -f "$OSA_CONFIG_FILE" ]]; then
    echo "Config file: $OSA_CONFIG_FILE"
    echo ""
    cat "$OSA_CONFIG_FILE"
  else
    echo "No configuration file found at: $OSA_CONFIG_FILE"
    echo "Run with --interactive to create one."
  fi
}

# Enable minimal components
enable_minimal() {
  OSA_SETUP_SYMLINKS=true
  OSA_SETUP_OH_MY_ZSH=true
  OSA_SETUP_ZSH_PLUGINS=true
  OSA_SETUP_MISE=true
  
  # Disable all optional components
  OSA_SETUP_GIT=false
  OSA_SETUP_ANDROID=false
  OSA_SETUP_COCOAPODS=false
  OSA_SETUP_ITERM2=false
  OSA_SETUP_VSCODE=false
  OSA_SETUP_OSA_SNIPPETS=false
  
  # Enable homebrew on macOS
  if [[ "$OSA_IS_MACOS" == "true" ]]; then
    OSA_SETUP_HOMEBREW=true
  fi
  
  save_config
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} Minimal configuration enabled (including mise)"
}

# Enable all components
enable_all() {
  for key in "${(@k)SETUP_COMPONENTS}"; do
    if is_component_available "$key"; then
      local var_name="OSA_SETUP_$(normalize_key "$key")"
      typeset -g "$var_name=true"
    fi
  done
  
  save_config
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} All available components enabled"
}

# Enable specific component
enable_component() {
  local key="$1"
  
  # Check if component exists (script_path can be empty for config-only components like android)
  if [[ -z "${COMPONENT_DESCRIPTIONS[$key]}" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Unknown component: $key"
    return 1
  fi
  
  local var_name="OSA_SETUP_$(normalize_key "$key")"
  typeset -g "$var_name=true"
  
  save_config
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} Component '$key' enabled"
}

# Disable specific component
disable_component() {
  local key="$1"
  
  # Check if component exists (script_path can be empty for config-only components like android)
  if [[ -z "${COMPONENT_DESCRIPTIONS[$key]}" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Unknown component: $key"
    return 1
  fi
  
  local var_name="OSA_SETUP_$(normalize_key "$key")"
  typeset -g "$var_name=false"
  
  save_config
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} Component '$key' disabled"
}

# Clean oh-my-zsh plugin symlinks
clean_oh_my_zsh() {
  local script_path="$OSA_CLI_DIR/src/setup/cleanup-oh-my-zsh-plugins.zsh"
  
  if [[ ! -f "$script_path" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Cleanup script not found: $script_path"
    return 1
  fi
  
  echo -e "${COLOR_CYAN}▶${COLOR_RESET} Cleaning oh-my-zsh plugin symlinks"
  source "$script_path"
}

# Clean all symlinks
clean_all_symlinks() {
  local script_path="$OSA_CLI_DIR/src/setup/cleanup-symlinks.zsh"
  
  if [[ ! -f "$script_path" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Cleanup script not found: $script_path"
    return 1
  fi
  
  echo -e "${COLOR_CYAN}▶${COLOR_RESET} Cleaning all OSA symlinks"
  source "$script_path"
}

# Validate symlinks
validate_symlinks() {
  local script_path="$OSA_CLI_DIR/src/setup/validate-symlinks.zsh"
  
  if [[ ! -f "$script_path" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Validation script not found: $script_path"
    return 1
  fi
  
  echo -e "${COLOR_CYAN}▶${COLOR_RESET} Validating OSA symlinks"
  source "$script_path"
}

# Clean all OSA data and prepare for fresh install
clean_all() {
  local unsafe_mode="${1:-false}"
  
  echo -e "${COLOR_BOLD}${COLOR_CYAN}"
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║          OSA Clean - Remove All OSA Data                   ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo -e "${COLOR_RESET}\n"
  
  echo -e "${COLOR_YELLOW}⚠${COLOR_RESET}  ${COLOR_BOLD}This will remove:${COLOR_RESET}"
  echo "   • ~/.osa symlink → $OSA_REPO_PATH"
  echo "   • ~/.zshrc symlink → ~/.osa/src/zsh/.zshrc"
  echo "   • ~/.osa-config (saved configuration)"
  echo "   • ~/.mise.toml (runtime versions)"
  echo ""
  
  # Safety check: ensure we're not deleting home directory or root
  if [[ "$HOME" == "/" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Safety check failed: \$HOME is root directory"
    return 1
  fi
  
  if [[ -z "$HOME" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Safety check failed: \$HOME is not set"
    return 1
  fi
  
  # Ask for confirmation unless --unsafe flag is provided
  if [[ "$unsafe_mode" != "true" ]]; then
    echo -e "${COLOR_BOLD}Confirm cleanup? This cannot be undone. (type 'yes' to continue)${COLOR_RESET}"
    echo -n "> "
    read -r confirmation
    
    if [[ "$confirmation" != "yes" ]]; then
      echo -e "${COLOR_YELLOW}✗${COLOR_RESET} Cleanup cancelled"
      return 0
    fi
  else
    echo -e "${COLOR_YELLOW}⚠${COLOR_RESET}  ${COLOR_BOLD}Unsafe mode: skipping confirmation prompt${COLOR_RESET}"
  fi
  
  echo ""
  echo -e "${COLOR_CYAN}Removing OSA files...${COLOR_RESET}"
  
  local removed_count=0
  local backup_suffix=".osa.backup.$(date +%s)"
  
  # Remove ~/.osa symlink
  if [[ -L "$HOME/.osa" ]]; then
    rm -f "$HOME/.osa"
    echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} Removed ~/.osa symlink"
    ((removed_count++))
  elif [[ -d "$HOME/.osa" && ! -L "$HOME/.osa" ]]; then
    # If it's a real directory (shouldn't happen, but safety check)
    echo -e "  ${COLOR_YELLOW}⚠${COLOR_RESET}  ~/.osa is a real directory (not a symlink), backing up..."
    mv "$HOME/.osa" "$HOME/.osa.backup.$(date +%s)"
    echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} Backed up to: $HOME/.osa.backup.*"
    ((removed_count++))
  fi
  
  # Remove ~/.zshrc symlink
  if [[ -L "$HOME/.zshrc" ]]; then
    # Check if it points to OSA
    local target=$(readlink "$HOME/.zshrc")
    if [[ "$target" == *".osa/src/zsh/.zshrc" ]]; then
      rm -f "$HOME/.zshrc"
      echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} Removed ~/.zshrc symlink (OSA version)"
      ((removed_count++))
    else
      echo -e "  ${COLOR_YELLOW}⊘${COLOR_RESET}  ~/.zshrc points to non-OSA location, skipping: $target"
    fi
  elif [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    # If it's a real file (user's custom .zshrc), back it up
    echo -e "  ${COLOR_YELLOW}⚠${COLOR_RESET}  ~/.zshrc is a real file (not OSA symlink), backing up..."
    mv "$HOME/.zshrc" "$HOME/.zshrc${backup_suffix}"
    echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} Backed up to: ~/.zshrc${backup_suffix}"
    ((removed_count++))
  fi
  
  # Remove ~/.osa-config
  if [[ -f "$HOME/.osa-config" ]]; then
    rm -f "$HOME/.osa-config"
    echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} Removed ~/.osa-config"
    ((removed_count++))
  fi
  
  # Remove ~/.mise.toml (user's mise config in home)
  if [[ -f "$HOME/.mise.toml" ]]; then
    echo -e "  ${COLOR_YELLOW}⚠${COLOR_RESET}  ~/.mise.toml found (user config), backing up..."
    mv "$HOME/.mise.toml" "$HOME/.mise.toml${backup_suffix}"
    echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} Backed up to: ~/.mise.toml${backup_suffix}"
    ((removed_count++))
  fi
  
  echo ""
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} Cleanup complete ($removed_count items removed)"
  echo ""
  echo -e "${COLOR_BOLD}Next steps:${COLOR_RESET}"
  echo "  1. ./osa-cli.zsh --interactive     # Choose components interactively"
  echo "  2. ./osa-cli.zsh --minimal         # Quick setup (core + mise)"
  echo "  3. source ~/.zshrc                 # Reload shell"
  echo ""
  
  return 0
}

# Doctor: Validate and repair OSA installation
# Doctor: Validate installation or specific config file
doctor() {
  local config_to_validate="$1"
  
  # If a config is provided, validate it instead of checking installation
  if [[ -n "$config_to_validate" ]]; then
    validate_config "$config_to_validate"
    return $?
  fi
  
  # Otherwise, run standard installation validation
  echo -e "${COLOR_BOLD}${COLOR_CYAN}"
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║              OSA Doctor - Validate & Repair                ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo -e "${COLOR_RESET}\n"
  
  local issues=0
  local warnings=0
  
  # 1. Check OSA_REPO_PATH
  echo -e "${COLOR_BOLD}[1/7] Checking repository path...${COLOR_RESET}"
  if [[ -z "$OSA_REPO_PATH" ]]; then
    echo -e "  ${COLOR_RED}✗${COLOR_RESET} OSA_REPO_PATH not set"
    ((issues++))
  elif [[ ! -d "$OSA_REPO_PATH" ]]; then
    echo -e "  ${COLOR_RED}✗${COLOR_RESET} OSA_REPO_PATH points to non-existent directory: $OSA_REPO_PATH"
    ((issues++))
  elif [[ ! -f "$OSA_REPO_PATH/.mise.toml" ]]; then
    echo -e "  ${COLOR_YELLOW}⚠${COLOR_RESET} .mise.toml missing in repo"
    ((warnings++))
  else
    echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} Repository path valid: $OSA_REPO_PATH"
  fi
  
  # 2. Check ~/.osa symlink
  echo -e "\n${COLOR_BOLD}[2/7] Checking ~/.osa symlink...${COLOR_RESET}"
  if [[ ! -e "$HOME/.osa" ]]; then
    echo -e "  ${COLOR_RED}✗${COLOR_RESET} ~/.osa does not exist"
    echo -e "  ${COLOR_CYAN}→${COLOR_RESET} Fix: Run './osa-cli.zsh --enable symlinks && ./osa-cli.zsh --auto'"
    ((issues++))
  elif [[ ! -L "$HOME/.osa" ]]; then
    echo -e "  ${COLOR_RED}✗${COLOR_RESET} ~/.osa exists but is not a symlink"
    echo -e "  ${COLOR_CYAN}→${COLOR_RESET} Fix: Run './osa-cli.zsh --clean-symlinks' then './osa-cli.zsh --minimal'"
    ((issues++))
  else
    local target=$(readlink "$HOME/.osa")
    if [[ "$target" == "$OSA_REPO_PATH" ]]; then
      echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} ~/.osa → $target"
    else
      echo -e "  ${COLOR_YELLOW}⚠${COLOR_RESET} ~/.osa points to wrong location"
      echo -e "    Current: $target"
      echo -e "    Expected: $OSA_REPO_PATH"
      echo -e "  ${COLOR_CYAN}→${COLOR_RESET} Fix: Run './osa-cli.zsh --clean-symlinks' then './osa-cli.zsh --minimal'"
      ((issues++))
    fi
  fi
  
  # 3. Check ~/.zshrc symlink
  echo -e "\n${COLOR_BOLD}[3/7] Checking ~/.zshrc symlink...${COLOR_RESET}"
  if [[ ! -e "$HOME/.zshrc" ]]; then
    echo -e "  ${COLOR_RED}✗${COLOR_RESET} ~/.zshrc does not exist"
    echo -e "  ${COLOR_CYAN}→${COLOR_RESET} Fix: Run './osa-cli.zsh --enable symlinks && ./osa-cli.zsh --auto'"
    ((issues++))
  elif [[ ! -L "$HOME/.zshrc" ]]; then
    echo -e "  ${COLOR_YELLOW}⚠${COLOR_RESET} ~/.zshrc exists but is not a symlink (backup at ~/.zshrc_pre_osa)"
    ((warnings++))
  else
    local target=$(readlink "$HOME/.zshrc")
    local expected="$HOME/.osa/src/zsh/.zshrc"
    if [[ "$target" == "$expected" || "$target" == "$OSA_REPO_PATH/src/zsh/.zshrc" ]]; then
      echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} ~/.zshrc → $target"
    else
      echo -e "  ${COLOR_YELLOW}⚠${COLOR_RESET} ~/.zshrc points to unexpected location: $target"
      ((warnings++))
    fi
  fi
  
  # 4. Check oh-my-zsh installation
  echo -e "\n${COLOR_BOLD}[4/7] Checking oh-my-zsh installation...${COLOR_RESET}"
  local omz_path="$HOME/.osa/external-libs/oh-my-zsh"
  if [[ ! -d "$omz_path" ]]; then
    echo -e "  ${COLOR_RED}✗${COLOR_RESET} oh-my-zsh not installed at $omz_path"
    echo -e "  ${COLOR_CYAN}→${COLOR_RESET} Fix: Run './osa-cli.zsh --enable oh-my-zsh && ./osa-cli.zsh --auto'"
    ((issues++))
  elif [[ ! -f "$omz_path/oh-my-zsh.sh" ]]; then
    echo -e "  ${COLOR_RED}✗${COLOR_RESET} oh-my-zsh partially installed (missing oh-my-zsh.sh)"
    echo -e "  ${COLOR_CYAN}→${COLOR_RESET} Fix: Run 'rm -rf $omz_path' then './osa-cli.zsh --enable oh-my-zsh && ./osa-cli.zsh --auto'"
    ((issues++))
  else
    echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} oh-my-zsh installed at $omz_path"
  fi
  
  # 5. Check plugin symlinks
  echo -e "\n${COLOR_BOLD}[5/7] Checking plugin symlinks...${COLOR_RESET}"
  local plugins=(
    "powerlevel10k:custom/themes/powerlevel10k"
    "zsh-syntax-highlighting:custom/plugins/zsh-syntax-highlighting"
    "evalcache:custom/plugins/evalcache"
  )
  
  local plugin_issues=0
  for plugin_info in "${plugins[@]}"; do
    local plugin="${plugin_info%%:*}"
    local link_path="${plugin_info##*:}"
    local full_link="$omz_path/$link_path"
    
    if [[ ! -L "$full_link" ]]; then
      echo -e "  ${COLOR_YELLOW}⚠${COLOR_RESET} $plugin not linked"
      ((plugin_issues++))
    else
      echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} $plugin linked"
    fi
  done
  
  if [[ $plugin_issues -gt 0 ]]; then
    echo -e "  ${COLOR_CYAN}→${COLOR_RESET} Fix: Run './osa-cli.zsh --enable zsh-plugins && ./osa-cli.zsh --auto'"
    ((warnings+=plugin_issues))
  fi
  
  # 6. Check mise installation
  echo -e "\n${COLOR_BOLD}[6/7] Checking mise installation...${COLOR_RESET}"
  if command -v mise &> /dev/null; then
    local mise_version=$(mise --version 2>/dev/null | head -1)
    echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} mise installed: $mise_version"
  else
    echo -e "  ${COLOR_YELLOW}⚠${COLOR_RESET} mise not installed (optional)"
    echo -e "  ${COLOR_CYAN}→${COLOR_RESET} Install: Run './osa-cli.zsh --enable mise && ./osa-cli.zsh --auto'"
    ((warnings++))
  fi
  
  # 7. Check for broken symlinks
  echo -e "\n${COLOR_BOLD}[7/7] Checking for broken symlinks...${COLOR_RESET}"
  local broken_symlinks=$(find "$HOME/.osa" -type l ! -exec test -e {} \; -print 2>/dev/null)
  if [[ -n "$broken_symlinks" ]]; then
    echo -e "  ${COLOR_YELLOW}⚠${COLOR_RESET} Found broken symlinks:"
    echo "$broken_symlinks" | while read -r link; do
      echo -e "    • $link"
    done
    echo -e "  ${COLOR_CYAN}→${COLOR_RESET} Fix: Run './osa-cli.zsh --clean-symlinks' then './osa-cli.zsh --minimal'"
    ((warnings++))
  else
    echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} No broken symlinks found"
  fi
  
  # Summary
  echo -e "\n${COLOR_BOLD}═══════════════════════════════════════${COLOR_RESET}"
  if [[ $issues -eq 0 && $warnings -eq 0 ]]; then
    echo -e "${COLOR_GREEN}✓ OSA installation is healthy!${COLOR_RESET}"
    return 0
  elif [[ $issues -eq 0 ]]; then
    echo -e "${COLOR_YELLOW}⚠ OSA is functional but has $warnings warning(s)${COLOR_RESET}"
    return 0
  else
    echo -e "${COLOR_RED}✗ Found $issues critical issue(s) and $warnings warning(s)${COLOR_RESET}"
    echo -e "\n${COLOR_CYAN}Quick fix:${COLOR_RESET}"
    echo -e "  ./osa-cli.zsh --clean-symlinks  # Remove broken symlinks"
    echo -e "  ./osa-cli.zsh --minimal         # Reinstall core components"
    echo -e "\n${COLOR_CYAN}Or to validate and repair symlinks:${COLOR_RESET}"
    echo -e "  source src/setup/validate-symlinks.zsh  # Check and repair"
    return 1
  fi
}

# Scan constructors for hardcoded secrets
scan_for_secrets() {
  echo -e "${COLOR_YELLOW}Scanning constructors for hardcoded secrets...${COLOR_RESET}"
  echo ""
  
  local script_path="$OSA_CLI_DIR/scripts/check-secrets.zsh"
  
  if [[ ! -f "$script_path" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Secret scanner not found: $script_path"
    return 1
  fi
  
  # Run the scanner
  source "$script_path"
  return $?
}

# Migrate secrets wizard
migrate_secrets() {
  echo -e "${COLOR_CYAN}Starting secret migration wizard...${COLOR_RESET}"
  echo ""
  
  local secrets_helper="$OSA_CLI_DIR/src/zsh/helpers/secrets.zsh"
  
  if [[ ! -f "$secrets_helper" ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} Secrets helper not found: $secrets_helper"
    return 1
  fi
  
  # Load the secrets helper
  source "$secrets_helper"
  
  # Run the interactive wizard
  osa_secrets_wizard
  
  echo ""
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} Secret stored securely!"
  echo ""
  echo -e "${COLOR_CYAN}Next steps:${COLOR_RESET}"
  echo "  1. Update your constructor files to use: export VAR=\"\$(osa-secret-get service account)\""
  echo "  2. Remove any hardcoded secrets from constructor files"
  echo "  3. Run: ./osa-cli.zsh --scan-secrets to verify"
}

# Setup git pre-commit hook for secret detection
setup_git_hook() {
  local git_dir="$OSA_CLI_DIR/.git"
  
  if [[ ! -d "$git_dir" ]]; then
    echo -e "${COLOR_YELLOW}Not in a git repository. Skipping hook installation.${COLOR_RESET}"
    return 0
  fi
  
  local hook_path="$git_dir/hooks/pre-commit"
  local scanner_path="$OSA_CLI_DIR/scripts/check-secrets.zsh"
  
  # Create hooks directory if it doesn't exist
  mkdir -p "$git_dir/hooks"
  
  # Create or update pre-commit hook
  cat > "$hook_path" << 'HOOK_EOF'
#!/usr/bin/env zsh
# OSA Pre-commit Hook - Prevent Secret Commits

REPO_ROOT="$(git rev-parse --show-toplevel)"
SCANNER="$REPO_ROOT/scripts/check-secrets.zsh"

if [[ -f "$SCANNER" ]]; then
  source "$SCANNER"
  exit $?
else
  echo "Warning: Secret scanner not found at $SCANNER"
  exit 0
fi
HOOK_EOF
  
  chmod +x "$hook_path"
  
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} Git pre-commit hook installed at: $hook_path"
  echo ""
  echo "This hook will:"
  echo "  • Scan staged files for hardcoded secrets before each commit"
  echo "  • Block commits containing potential credentials"
  echo "  • Guide you to use OSA's secure credential storage instead"
}

# Main CLI logic
main() {
  init_components
  
  # Parse arguments
  if [[ $# -eq 0 ]]; then
    show_help
    exit 0
  fi
  
  # Check for --help first and bail immediately
  for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
      show_help
      exit 0
    fi
  done
  
  # First pass: collect flags and identify primary action
  local should_clean=false
  local unsafe_mode=false
  local primary_action=""
  local action_arg=""
  local temp_args=()
  
  while [[ $# -gt 0 ]]; do
    # Handle --option=value format
    if [[ "$1" =~ ^--[a-z-]+= ]]; then
      local option="${1%%=*}"
      local value="${1#*=}"
      
      case "$option" in
        --config|--config-file|--config-json|--config-url|--enable|--disable)
          if [[ -z "$primary_action" ]]; then
            primary_action="$option"
            action_arg="$value"
          fi
          shift
          continue
          ;;
        *)
          echo -e "${COLOR_RED}✗${COLOR_RESET} Unknown option: $option"
          echo "Run with --help to see available options"
          exit 1
          ;;
      esac
    fi
    
    case "$1" in
      --clean)
        should_clean=true
        shift
        ;;
      --unsafe)
        unsafe_mode=true
        shift
        ;;
      -v|--verbose)
        OSA_VERBOSE=true
        export OSA_VERBOSE
        echo -e "${COLOR_CYAN}ℹ${COLOR_RESET} Verbose mode enabled"
        shift
        ;;
      --dry-run)
        OSA_DRY_RUN=true
        echo -e "${COLOR_YELLOW}[DRY-RUN MODE]${COLOR_RESET} No scripts will be executed"
        echo ""
        shift
        ;;
      # Primary actions (first one wins) - Note: --config is special, it can take optional arg
      -i|--interactive|-a|--auto|-l|--list|--list-configs|--info|--scan-secrets|--migrate-secrets|--setup-git-hook|--clean-symlinks|--clean-oh-my-zsh|--minimal|--all|--report|--report-json|--report-url)
        if [[ -z "$primary_action" ]]; then
          primary_action="$1"
        fi
        shift
        ;;
      # Modifier flags (can be combined with other options)
      --local)
        export OSA_SKIP_MISE_GLOBAL=true
        shift
        ;;
      --disable-osa-snippets)
        export OSA_SKIP_SNIPPETS=true
        shift
        ;;
      --disable-git)
        export OSA_SKIP_GIT_CONFIG=true
        shift
        ;;
      --skip-cocoapods)
        export OSA_SKIP_COCOAPODS=true
        shift
        ;;
      # Options that take arguments
      --config|--config-file|--config-json|--config-url|--enable|--disable|--doctor)
        if [[ -z "$primary_action" ]]; then
          primary_action="$1"
          shift
          # For --config and --doctor, argument is optional. Peek ahead to see if next arg looks like a value
          if [[ "$primary_action" == "--config" || "$primary_action" == "--doctor" ]]; then
            # Check if next arg exists and doesn't start with - (i.e., is a value, not a flag)
            if [[ -n "$1" && ! "$1" =~ ^- ]]; then
              action_arg="$1"
              shift  # consume the argument
            fi
          else
            # For other options that take arguments, the argument is required
            if [[ -z "$1" ]]; then
              echo -e "${COLOR_RED}✗${COLOR_RESET} $primary_action requires an argument"
              exit 1
            fi
            action_arg="$1"
            shift  # consume the argument
          fi
        fi
        ;;
      *)
        echo -e "${COLOR_RED}✗${COLOR_RESET} Unknown option: $1"
        echo "Run with --help to see available options"
        exit 1
        ;;
    esac
  done
  
  # Run --clean first if requested
  if [[ "$should_clean" == "true" ]]; then
    if [[ "$OSA_DRY_RUN" == "true" ]]; then
      echo -e "${COLOR_RED}✗${COLOR_RESET} --clean cannot be used with --dry-run"
      echo "   --clean is a destructive operation and must run for real or not at all"
      exit 1
    fi
    clean_all "$unsafe_mode" || exit $?
  fi
  
  # Now run the primary action
  case "$primary_action" in
    "")
      # No action specified, show help
      show_help
      exit 0
      ;;
    -l|--list)
      list_components
      exit 0
      ;;
    --list-configs)
      list_configs
      exit 0
      ;;
    --info)
      print_platform_info
      exit 0
      ;;
    --config)
      # If action_arg is set, load config file; otherwise show current config
      if [[ -n "$action_arg" ]]; then
        load_json_config "$action_arg"
        if [[ $? -eq 0 ]]; then
          automated_setup
          exit $?
        else
          exit 1
        fi
      else
        show_config
        exit 0
      fi
      ;;
    --config-file|--config-json)
      load_json_config "$action_arg"
      if [[ $? -eq 0 ]]; then
        automated_setup
        exit $?
      else
        exit 1
      fi
      ;;
    --config-url)
      load_remote_config "$action_arg"
      if [[ $? -eq 0 ]]; then
        automated_setup
        exit $?
      else
        exit 1
      fi
      ;;
    -i|--interactive)
      interactive_setup
      exit $?
      ;;
    -a|--auto)
      # Load saved config for auto mode
      load_config
      automated_setup
      exit $?
      ;;
    --minimal)
      enable_minimal
      automated_setup
      exit $?
      ;;
    --all)
      enable_all
      automated_setup
      exit $?
      ;;
    --enable)
      enable_component "$action_arg"
      exit $?
      ;;
    --disable)
      disable_component "$action_arg"
      exit $?
      ;;
    --clean-symlinks)
      clean_all_symlinks
      exit $?
      ;;
    --clean-oh-my-zsh)
      clean_oh_my_zsh
      exit $?
      ;;
    --doctor)
      doctor "$action_arg"
      exit $?
      ;;
    --scan-secrets)
      scan_for_secrets
      exit $?
      ;;
    --migrate-secrets)
      migrate_secrets
      exit $?
      ;;
    --setup-git-hook)
      setup_git_hook
      exit $?
      ;;
    --report)
      detect_platform
      generate_system_report "text"
      exit 0
      ;;
    --report-json)
      detect_platform
      generate_system_report "json"
      exit 0
      ;;
    --report-url)
      detect_platform
      generate_system_report "url"
      exit 0
      ;;
    *)
      echo -e "${COLOR_RED}✗${COLOR_RESET} Unknown action: $primary_action"
      exit 1
      ;;
  esac
}

# Run main
main "$@"
