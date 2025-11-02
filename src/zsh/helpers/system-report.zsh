#!/usr/bin/env zsh
# system-report.zsh - Collect system and environment info for GitHub issue reporting

# Generate a system report for debugging
generate_system_report() {
  local report_format="${1:-text}"  # text, json, or url
  
  # Collect system information
  local os="$OSA_OS"
  local os_version="$OSA_OS_VERSION"
  local arch="$OSA_ARCH"
  local shell_version="$ZSH_VERSION"
  local zsh_path="$(which zsh)"
  
  # Collect OSA info
  local osa_version=""
  if [[ -d "$OSA_REPO_PATH/.git" ]]; then
    osa_version=$(cd "$OSA_REPO_PATH" && git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  else
    osa_version="unknown"
  fi
  
  # Check VM status
  local is_vm="no"
  local vm_type=""
  
  detect_vm_environment
  if [[ "$OSA_IN_VM" == "true" ]]; then
    is_vm="yes"
    vm_type="$OSA_VM_TYPE"
  fi
  
  # Collect installed tools info
  local homebrew_version=""
  if command -v brew &>/dev/null; then
    homebrew_version=$(brew --version 2>/dev/null | head -1)
  fi
  
  local mise_version=""
  if command -v mise &>/dev/null; then
    mise_version=$(mise --version 2>/dev/null)
  fi
  
  local oh_my_zsh_version=""
  if [[ -d "$HOME/.osa/external-libs/oh-my-zsh" ]]; then
    oh_my_zsh_version="installed"
  fi
  
  local git_version=""
  if command -v git &>/dev/null; then
    git_version=$(git --version 2>/dev/null)
  fi
  
  # Collect installed runtimes (if mise is available)
  local node_version=""
  local python_version=""
  local ruby_version=""
  
  if command -v node &>/dev/null; then
    node_version=$(node --version 2>/dev/null)
  fi
  if command -v python &>/dev/null; then
    python_version=$(python --version 2>/dev/null)
  fi
  if command -v ruby &>/dev/null; then
    ruby_version=$(ruby --version 2>/dev/null)
  fi
  
  # Configuration status
  local config_exists="no"
  if [[ -f "$OSA_CONFIG_FILE" ]]; then
    config_exists="yes"
  fi
  
  local symlinks_exist="no"
  if [[ -L "$HOME/.osa" ]]; then
    symlinks_exist="yes"
  fi
  
  case "$report_format" in
    text)
      generate_text_report "$os" "$os_version" "$arch" "$shell_version" "$zsh_path" "$osa_version" "$is_vm" "$vm_type" "$homebrew_version" "$mise_version" "$oh_my_zsh_version" "$git_version" "$node_version" "$python_version" "$ruby_version" "$config_exists" "$symlinks_exist"
      ;;
    json)
      generate_json_report "$os" "$os_version" "$arch" "$shell_version" "$zsh_path" "$osa_version" "$is_vm" "$vm_type" "$homebrew_version" "$mise_version" "$oh_my_zsh_version" "$git_version" "$node_version" "$python_version" "$ruby_version" "$config_exists" "$symlinks_exist"
      ;;
    url)
      generate_url_report "$os" "$os_version" "$arch" "$shell_version" "$zsh_path" "$osa_version" "$is_vm" "$vm_type" "$homebrew_version" "$mise_version" "$oh_my_zsh_version" "$git_version" "$node_version" "$python_version" "$ruby_version" "$config_exists" "$symlinks_exist"
      ;;
    *)
      echo "Unknown format: $report_format" >&2
      return 1
      ;;
  esac
}

# Generate text-format report
generate_text_report() {
  local os="$1" os_version="$2" arch="$3" shell_version="$4" zsh_path="$5"
  local osa_version="$6" is_vm="$7" vm_type="$8"
  local homebrew_version="$9" mise_version="${10}" oh_my_zsh_version="${11}"
  local git_version="${12}" node_version="${13}" python_version="${14}"
  local ruby_version="${15}" config_exists="${16}" symlinks_exist="${17}"
  
  cat << EOF
========================================
OSA System Report
========================================

## Environment
- Platform: $os
- OS Version: $os_version
- Architecture: $arch
- Running in VM: $is_vm
$(if [[ "$is_vm" == "yes" ]]; then echo "- VM Type: $vm_type"; fi)

## Shell
- Shell: zsh
- Version: $shell_version
- Path: $zsh_path

## OSA
- OSA Version: $osa_version
- Repository: $OSA_REPO_PATH
- Config Exists: $config_exists
- Symlinks Exist: $symlinks_exist

## Tools
$(if [[ -n "$homebrew_version" ]]; then echo "- Homebrew: $homebrew_version"; fi)
$(if [[ -n "$git_version" ]]; then echo "- Git: $git_version"; fi)
$(if [[ -n "$mise_version" ]]; then echo "- Mise: $mise_version"; fi)
$(if [[ -n "$oh_my_zsh_version" ]]; then echo "- Oh My Zsh: $oh_my_zsh_version"; fi)

## Runtimes
$(if [[ -n "$node_version" ]]; then echo "- Node.js: $node_version"; fi)
$(if [[ -n "$python_version" ]]; then echo "- Python: $python_version"; fi)
$(if [[ -n "$ruby_version" ]]; then echo "- Ruby: $ruby_version"; fi)

========================================
EOF
}

# Generate JSON-format report
generate_json_report() {
  local os="$1" os_version="$2" arch="$3" shell_version="$4" zsh_path="$5"
  local osa_version="$6" is_vm="$7" vm_type="$8"
  local homebrew_version="$9" mise_version="${10}" oh_my_zsh_version="${11}"
  local git_version="${12}" node_version="${13}" python_version="${14}"
  local ruby_version="${15}" config_exists="${16}" symlinks_exist="${17}"
  
  # Check if jq is available
  if ! command -v jq &>/dev/null; then
    echo "Error: jq is required for JSON output. Install with: brew install jq" >&2
    return 1
  fi
  
  # Build JSON structure
  local json=$(cat <<'JSONEOF'
{
  "environment": {
    "platform": "",
    "os_version": "",
    "architecture": "",
    "in_vm": "",
    "vm_type": ""
  },
  "shell": {
    "type": "zsh",
    "version": "",
    "path": ""
  },
  "osa": {
    "version": "",
    "repository": "",
    "config_exists": "",
    "symlinks_exist": ""
  },
  "tools": {
    "homebrew": "",
    "git": "",
    "mise": "",
    "oh_my_zsh": ""
  },
  "runtimes": {
    "node": "",
    "python": "",
    "ruby": ""
  }
}
JSONEOF
)
  
  # Populate JSON with values
  json=$(echo "$json" | jq \
    --arg os "$os" \
    --arg os_ver "$os_version" \
    --arg arch "$arch" \
    --arg in_vm "$is_vm" \
    --arg vm_type "$vm_type" \
    --arg shell_ver "$shell_version" \
    --arg zsh_p "$zsh_path" \
    --arg osa_ver "$osa_version" \
    --arg repo "$OSA_REPO_PATH" \
    --arg cfg "$config_exists" \
    --arg sym "$symlinks_exist" \
    --arg brew "$homebrew_version" \
    --arg git "$git_version" \
    --arg mise "$mise_version" \
    --arg omz "$oh_my_zsh_version" \
    --arg node "$node_version" \
    --arg python "$python_version" \
    --arg ruby "$ruby_version" \
    '.environment.platform = $os |
     .environment.os_version = $os_ver |
     .environment.architecture = $arch |
     .environment.in_vm = $in_vm |
     .environment.vm_type = $vm_type |
     .shell.version = $shell_ver |
     .shell.path = $zsh_p |
     .osa.version = $osa_ver |
     .osa.repository = $repo |
     .osa.config_exists = $cfg |
     .osa.symlinks_exist = $sym |
     .tools.homebrew = $brew |
     .tools.git = $git |
     .tools.mise = $mise |
     .tools.oh_my_zsh = $omz |
     .runtimes.node = $node |
     .runtimes.python = $python |
     .runtimes.ruby = $ruby')
  
  echo "$json"
}

# Generate GitHub issue URL with pre-filled environment info
generate_url_report() {
  local os="$1" os_version="$2" arch="$3" shell_version="$4" zsh_path="$5"
  local osa_version="$6" is_vm="$7" vm_type="$8"
  local homebrew_version="$9" mise_version="${10}" oh_my_zsh_version="${11}"
  local git_version="${12}" node_version="${13}" python_version="${14}"
  local ruby_version="${15}" config_exists="${16}" symlinks_exist="${17}"
  
  # Build the issue body with system info
  local issue_body="
## Environment
- **Platform**: $os
- **OS Version**: $os_version
- **Architecture**: $arch
- **Running in VM**: $is_vm
$(if [[ "$is_vm" == "yes" ]]; then echo "- **VM Type**: $vm_type"; fi)

## Shell
- **Shell**: zsh $shell_version
- **Path**: $zsh_path

## OSA
- **OSA Version**: $osa_version
- **Repository**: $OSA_REPO_PATH
- **Config Exists**: $config_exists
- **Symlinks Exist**: $symlinks_exist

## Tools Installed
$(if [[ -n "$homebrew_version" ]]; then echo "- Homebrew: $homebrew_version"; fi)
$(if [[ -n "$git_version" ]]; then echo "- Git: $git_version"; fi)
$(if [[ -n "$mise_version" ]]; then echo "- Mise: $mise_version"; fi)
$(if [[ -n "$oh_my_zsh_version" ]]; then echo "- Oh My Zsh: $oh_my_zsh_version"; fi)

## Runtimes Detected
$(if [[ -n "$node_version" ]]; then echo "- Node.js: $node_version"; fi)
$(if [[ -n "$python_version" ]]; then echo "- Python: $python_version"; fi)
$(if [[ -n "$ruby_version" ]]; then echo "- Ruby: $ruby_version"; fi)

---

## Issue Description
[Describe the issue here]

## Steps to Reproduce
1. 
2. 
3. 

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Error Output
\`\`\`
[Paste any error messages or logs here]
\`\`\`
"
  
  # URL encode the issue body
  local encoded_body=$(echo "$issue_body" | jq -sRr @uri)
  
  # GitHub new issue URL
  local github_url="https://github.com/FrederickEngelhardt/one-setup-anywhere/issues/new?body=$encoded_body&title=%5BBUG%5D%20"
  
  echo "GitHub Issue Template URL (open this in your browser):"
  echo ""
  echo "$github_url"
  echo ""
  echo "System information has been pre-filled. Just add your issue title and details."
  echo ""
  echo "Or copy this text directly into a new GitHub issue:"
  echo "$issue_body"
}

# Detect if running in a virtual machine
detect_vm_environment() {
  export OSA_IN_VM=false
  export OSA_VM_TYPE="unknown"
  
  # Check for common VM indicators
  local vm_indicators=()
  
  # Check for hypervisor info
  if command -v system_profiler &>/dev/null; then
    # macOS
    local vm_info=$(system_profiler SPHardwareDataType 2>/dev/null | grep -i "virtual\|vm\|hypervisor" || true)
    if [[ -n "$vm_info" ]]; then
      OSA_IN_VM=true
      # Try to detect specific VM type
      if [[ "$vm_info" == *"Parallels"* ]]; then
        OSA_VM_TYPE="Parallels"
      elif [[ "$vm_info" == *"VMware"* ]]; then
        OSA_VM_TYPE="VMware"
      elif [[ "$vm_info" == *"VirtualBox"* ]]; then
        OSA_VM_TYPE="VirtualBox"
      else
        OSA_VM_TYPE="Virtual Machine"
      fi
      return
    fi
  fi
  
  # Check for common VM environment variables and files
  if [[ -n "${VMTYPE}" ]]; then
    OSA_IN_VM=true
    OSA_VM_TYPE="$VMTYPE"
    return
  fi
  
  # Check /proc/cpuinfo for hypervisor info (Linux)
  if [[ -f "/proc/cpuinfo" ]]; then
    local hypervisor=$(grep -i "hypervisor" /proc/cpuinfo 2>/dev/null || true)
    if [[ -n "$hypervisor" ]]; then
      OSA_IN_VM=true
      if [[ "$hypervisor" == *"KVM"* ]]; then
        OSA_VM_TYPE="KVM"
      elif [[ "$hypervisor" == *"Xen"* ]]; then
        OSA_VM_TYPE="Xen"
      elif [[ "$hypervisor" == *"VMware"* ]]; then
        OSA_VM_TYPE="VMware"
      elif [[ "$hypervisor" == *"VirtualBox"* ]]; then
        OSA_VM_TYPE="VirtualBox"
      elif [[ "$hypervisor" == *"Hyper-V"* ]]; then
        OSA_VM_TYPE="Hyper-V"
      else
        OSA_VM_TYPE="Virtual Machine"
      fi
      return
    fi
  fi
  
  # Check for dmidecode info (Linux)
  if command -v dmidecode &>/dev/null; then
    local dmi=$(sudo dmidecode -s system-manufacturer 2>/dev/null || dmidecode -s system-manufacturer 2>/dev/null || true)
    if [[ -n "$dmi" ]]; then
      case "$dmi" in
        *"VMware"*)
          OSA_IN_VM=true
          OSA_VM_TYPE="VMware"
          ;;
        *"VirtualBox"*)
          OSA_IN_VM=true
          OSA_VM_TYPE="VirtualBox"
          ;;
        *"QEMU"*|*"KVM"*)
          OSA_IN_VM=true
          OSA_VM_TYPE="KVM"
          ;;
        *"Xen"*)
          OSA_IN_VM=true
          OSA_VM_TYPE="Xen"
          ;;
      esac
    fi
  fi
}
