#!/usr/bin/env zsh
# src/setup/install-cocoapods.zsh - Install CocoaPods with Ruby version compatibility

# CocoaPods version compatibility matrix
# Each CocoaPods version requires a minimum Ruby version
declare -A COCOAPODS_RUBY_COMPAT=(
  ["1.14"]="3.0"   # CocoaPods 1.14+ requires Ruby 3.0+
  ["1.13"]="2.7"   # CocoaPods 1.13 requires Ruby 2.7+
  ["1.12"]="2.7"   # CocoaPods 1.12 requires Ruby 2.7+
  ["1.11"]="2.6"   # CocoaPods 1.11 requires Ruby 2.6+
)

# Ask user if they want to install CocoaPods
ask_install_cocoapods() {
  echo -e "${COLOR_BOLD}iOS Development with CocoaPods${COLOR_RESET}"
  echo ""
  echo "CocoaPods requires Ruby and is used for iOS dependency management."
  echo ""
  
  if ask_yes_no "Do you want to install CocoaPods?" "n"; then
    select_cocoapods_version
    return 0
  else
    echo -e "${COLOR_YELLOW}⊘${COLOR_RESET} Skipping CocoaPods installation"
    OSA_SETUP_COCOAPODS=false
    return 0
  fi
}

# Prompt for CocoaPods version selection
select_cocoapods_version() {
  echo ""
  echo -e "${COLOR_BOLD}Select CocoaPods version:${COLOR_RESET}"
  echo ""
  echo "  1. Latest stable (recommended)"
  echo "  2. 1.14.x (requires Ruby 3.0+)"
  echo "  3. 1.13.x (requires Ruby 2.7+)"
  echo "  4. 1.12.x (requires Ruby 2.7+)"
  echo ""
  echo -n "Select version [1]: "
  read -r version_choice
  version_choice="${version_choice:-1}"
  
  case "$version_choice" in
    1)
      export COCOAPODS_VERSION="latest"
      select_ruby_for_cocoapods "latest"
      ;;
    2)
      export COCOAPODS_VERSION="1.14"
      select_ruby_for_cocoapods "1.14"
      ;;
    3)
      export COCOAPODS_VERSION="1.13"
      select_ruby_for_cocoapods "1.13"
      ;;
    4)
      export COCOAPODS_VERSION="1.12"
      select_ruby_for_cocoapods "1.12"
      ;;
    *)
      echo -e "${COLOR_YELLOW}Invalid selection. Using latest.${COLOR_RESET}"
      export COCOAPODS_VERSION="latest"
      select_ruby_for_cocoapods "latest"
      ;;
  esac
  
  OSA_SETUP_COCOAPODS=true
}

# Select compatible Ruby version for CocoaPods
select_ruby_for_cocoapods() {
  local cocoapods_ver="$1"
  
  echo ""
  echo -e "${COLOR_BOLD}Select Ruby version for CocoaPods ${cocoapods_ver}:${COLOR_RESET}"
  echo ""
  echo "Compatible versions (any Ruby 2.7.5+ works):"
  echo "  1. Ruby 3.4.0 (latest - recommended)"
  echo "  2. Ruby 3.3.0 (stable)"
  echo "  3. Ruby 3.2.2 (current)"
  echo "  4. Ruby 3.2.0 (older stable)"
  echo "  5. Ruby 2.7.8 (legacy support)"
  echo ""
  echo -n "Select Ruby version [1]: "
  read -r ruby_choice
  ruby_choice="${ruby_choice:-1}"
  
  case "$ruby_choice" in
    1)
      export MISE_RUBY_VERSION="3.4.0"
      echo -e "${COLOR_GREEN}✓${COLOR_RESET} Selected Ruby 3.4.0 + CocoaPods ${cocoapods_ver}"
      ;;
    2)
      export MISE_RUBY_VERSION="3.3.0"
      echo -e "${COLOR_GREEN}✓${COLOR_RESET} Selected Ruby 3.3.0 + CocoaPods ${cocoapods_ver}"
      ;;
    3)
      export MISE_RUBY_VERSION="3.2.2"
      echo -e "${COLOR_GREEN}✓${COLOR_RESET} Selected Ruby 3.2.2 + CocoaPods ${cocoapods_ver}"
      ;;
    4)
      export MISE_RUBY_VERSION="3.2.0"
      echo -e "${COLOR_GREEN}✓${COLOR_RESET} Selected Ruby 3.2.0 + CocoaPods ${cocoapods_ver}"
      ;;
    5)
      export MISE_RUBY_VERSION="2.7.8"
      echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} Ruby 2.7 is end-of-life. Selected Ruby 2.7.8 + CocoaPods ${cocoapods_ver}"
      ;;
    *)
      echo -e "${COLOR_YELLOW}Invalid selection. Using Ruby 3.4.0.${COLOR_RESET}"
      export MISE_RUBY_VERSION="3.4.0"
      ;;
  esac
  
  echo ""
}

# Validate Ruby and CocoaPods compatibility
validate_cocoapods_ruby_compat() {
  local cocoapods_ver="${COCOAPODS_VERSION:-latest}"
  local ruby_ver="${MISE_RUBY_VERSION:-3.4.0}"
  
  # Extract major version only
  local ruby_major="${ruby_ver%%.*}"
  
  echo -e "${COLOR_CYAN}Validating Ruby ${ruby_ver} compatibility with CocoaPods ${cocoapods_ver}...${COLOR_RESET}"
  
  # CocoaPods latest typically requires Ruby 3.0+
  if [[ "$cocoapods_ver" == "latest" ]]; then
    if (( ruby_major < 3 )); then
      echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} Latest CocoaPods works best with Ruby 3.0+, but Ruby ${ruby_ver} selected"
      echo -e "${COLOR_CYAN}→${COLOR_RESET} You can try installing, but may encounter issues"
      return 0  # Allow user to proceed anyway
    fi
  else
    # For specific versions, check minimum requirement
    case "$cocoapods_ver" in
      1.14|1.13|1.12)
        # These require Ruby 2.7+ (or 3.0+ for 1.14)
        if (( ruby_major < 2 )); then
          echo -e "${COLOR_RED}✗${COLOR_RESET} CocoaPods ${cocoapods_ver} requires Ruby 2.7+, but Ruby ${ruby_ver} selected"
          return 1
        fi
        ;;
    esac
  fi
  
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} Compatible: Ruby ${ruby_ver} with CocoaPods ${cocoapods_ver}"
  return 0
}

# Main install function
install_cocoapods() {
  echo -e "${COLOR_BLUE}▶${COLOR_RESET} Installing CocoaPods"
  echo ""
  
  # Validate compatibility first
  if ! validate_cocoapods_ruby_compat; then
    echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} Installation skipped due to version incompatibility"
    return 1
  fi
  
  echo ""
  echo -e "${COLOR_BOLD}Installation plan:${COLOR_RESET}"
  echo "  1. Ensure Ruby ${MISE_RUBY_VERSION} is installed via mise"
  echo "  2. Install CocoaPods ${COCOAPODS_VERSION} gem"
  echo "  3. Verify installation"
  echo ""
  
  if [[ "$OSA_VERBOSE" == "true" ]]; then
    echo -e "${COLOR_CYAN}ℹ${COLOR_RESET} Verbose mode: showing detailed output"
    echo ""
  fi
  
  if [[ "$OSA_DRY_RUN" == "true" ]]; then
    echo -e "${COLOR_CYAN}[DRY-RUN]${COLOR_RESET} Would run:"
    echo "  • mise use ruby@${MISE_RUBY_VERSION}"
    echo "  • gem install cocoapods --version ${COCOAPODS_VERSION}"
    echo "  • pod repo update"
    echo "  • pod setup"
    return 0
  fi
  
  # Check if Ruby is available via mise
  if ! command -v mise &>/dev/null; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} mise is required but not installed"
    echo -e "${COLOR_CYAN}→${COLOR_RESET} Install mise first: ./osa-cli.zsh --enable mise --auto"
    return 1
  fi
  
  # Activate Ruby version
  echo -e "${COLOR_CYAN}Setting Ruby version to ${MISE_RUBY_VERSION}...${COLOR_RESET}"
  mise use ruby@"${MISE_RUBY_VERSION}" 2>/dev/null || {
    echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} Ruby ${MISE_RUBY_VERSION} not installed. Installing..."
    mise install ruby@"${MISE_RUBY_VERSION}" || {
      echo -e "${COLOR_RED}✗${COLOR_RESET} Failed to install Ruby ${MISE_RUBY_VERSION}"
      return 1
    }
  }
  
  # Install CocoaPods
  echo -e "${COLOR_CYAN}Installing CocoaPods ${COCOAPODS_VERSION}...${COLOR_RESET}"
  if [[ "$COCOAPODS_VERSION" == "latest" ]]; then
    gem install cocoapods || {
      echo -e "${COLOR_RED}✗${COLOR_RESET} Failed to install CocoaPods"
      return 1
    }
  else
    gem install cocoapods --version "${COCOAPODS_VERSION}" || {
      echo -e "${COLOR_RED}✗${COLOR_RESET} Failed to install CocoaPods ${COCOAPODS_VERSION}"
      return 1
    }
  fi
  
  # Verify installation
  echo -e "${COLOR_CYAN}Verifying CocoaPods installation...${COLOR_RESET}"
  local pod_version=$(pod --version 2>/dev/null)
  if [[ -n "$pod_version" ]]; then
    echo -e "${COLOR_GREEN}✓${COLOR_RESET} CocoaPods ${pod_version} installed successfully"
  else
    echo -e "${COLOR_RED}✗${COLOR_RESET} CocoaPods installation verification failed"
    return 1
  fi
  
  echo ""
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} CocoaPods setup complete!"
  echo ""
  echo -e "${COLOR_BOLD}Next steps:${COLOR_RESET}"
  echo "  1. Run: pod repo update (updates the specs repository)"
  echo "  2. In your iOS project directory: pod install"
  echo "  3. Open the generated .xcworkspace file"
}

# Export functions
export -f ask_install_cocoapods
export -f select_cocoapods_version
export -f select_ruby_for_cocoapods
export -f validate_cocoapods_ruby_compat
export -f install_cocoapods
