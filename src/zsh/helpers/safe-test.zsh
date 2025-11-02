#!/usr/bin/env zsh
# src/zsh/helpers/safe-test.zsh - Safe test mode for running commands with approval

# Approved safe modes - only --help and --dry-run allowed without manual review
declare -A APPROVED_SAFE_MODES=(
  [--help]=true
  [--dry-run]=true
  [--list-configs]=true
  [--list]=true
  [--info]=true
  [--config]=true
  [--report]=true
  [--report-json]=true
  [--report-url]=true
  [--doctor]=true
  [--scan-secrets]=true
)

# Check if command is safe to run (contains only approved flags)
is_safe_command() {
  local -a args=("$@")
  
  # No args is safe
  if [[ ${#args[@]} -eq 0 ]]; then
    return 0
  fi
  
  # Check each argument
  for arg in "${args[@]}"; do
    # Extract the flag part (before = if present)
    local flag="${arg%%=*}"
    
    # Skip positional arguments that don't start with --
    if [[ ! "$flag" =~ ^- ]]; then
      continue
    fi
    
    # Check if this flag is approved
    if [[ -z "${APPROVED_SAFE_MODES[$flag]}" ]]; then
      return 1  # Not approved
    fi
  done
  
  return 0  # All flags are approved
}

# Warn user about dangerous commands
warn_dangerous_command() {
  local -a args=("$@")
  
  echo -e "${COLOR_BOLD}${COLOR_YELLOW}⚠  WARNING: This command will make system changes${COLOR_RESET}\n"
  
  echo "Command: ./osa-cli.zsh ${args[*]}"
  echo ""
  echo "This will:"
  
  if [[ " ${args[@]} " =~ " --interactive " ]] || [[ " ${args[@]} " =~ " -i " ]]; then
    echo "  • Start interactive setup mode"
    echo "  • Ask you to select components"
    echo "  • Install selected software"
  fi
  
  if [[ " ${args[@]} " =~ " --auto " ]] || [[ " ${args[@]} " =~ " -a " ]]; then
    echo "  • Run automated setup using saved configuration"
    echo "  • Install all enabled components"
  fi
  
  if [[ " ${args[@]} " =~ " --clean " ]]; then
    echo "  • Remove all OSA symlinks and configuration"
    echo "  • This cannot be undone"
  fi
  
  if [[ " ${args[@]} " =~ " --minimal " ]]; then
    echo "  • Install core + mise"
    echo "  • Create symlinks and configure shell"
  fi
  
  if [[ " ${args[@]} " =~ " --all " ]]; then
    echo "  • Install ALL available components"
    echo "  • This may take a long time"
  fi
  
  echo ""
  echo "To preview without installing:"
  echo "  ./osa-cli.zsh ${args[*]} --dry-run"
  echo ""
  
  # Prompt for confirmation
  echo -n "Are you sure? (type 'yes' to continue, or anything else to cancel): "
  read -r confirmation
  
  if [[ "$confirmation" != "yes" ]]; then
    echo -e "${COLOR_YELLOW}Cancelled.${COLOR_RESET}"
    return 1
  fi
  
  return 0
}

# Suggest safe alternative
suggest_safe_alternative() {
  local -a args=("$@")
  
  echo -e "${COLOR_CYAN}Tip: To see what would happen without making changes:${COLOR_RESET}"
  echo "  ./osa-cli.zsh ${args[*]} --dry-run"
  echo ""
  echo -e "${COLOR_CYAN}Safe read-only commands:${COLOR_RESET}"
  echo "  ./osa-cli.zsh --help        # Show help"
  echo "  ./osa-cli.zsh --info        # Show platform info"
  echo "  ./osa-cli.zsh --list        # List components"
  echo "  ./osa-cli.zsh --list-configs # List available configs"
  echo "  ./osa-cli.zsh --config      # Show current config"
  echo "  ./osa-cli.zsh --doctor      # Check installation health"
  echo "  ./osa-cli.zsh --report      # Generate system report"
}
