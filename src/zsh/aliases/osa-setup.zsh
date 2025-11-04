#!/usr/bin/env zsh
# src/zsh/aliases/osa.zsh - OSA CLI wrapper

# Infer OSA_REPO_PATH from ~/.osa symlink if not already set
if [[ -z "$OSA_REPO_PATH" ]]; then
  if [[ -L "$HOME/.osa" ]]; then
    export OSA_REPO_PATH=$(readlink -f "$HOME/.osa")
  elif [[ -d "$HOME/.osa" ]]; then
    export OSA_REPO_PATH="$HOME/.osa"
  fi
fi

# Create osa wrapper function that handles 'osa open' specially
osa-setup() {
  # Handle 'osa-setup open' to open repo in editor
  if [[ "$1" == "open" ]]; then
    local real_repo=$(readlink -f "${OSA_REPO_PATH:?OSA_REPO_PATH not set}")
    local editor="${OSA_EDITOR:-code}"
    
    # Check if editor is available
    if ! command -v "$editor" &>/dev/null; then
      echo "Error: Editor '$editor' not found in PATH" >&2
      echo "Set OSA_EDITOR to an available editor (vim, nvim, code, etc.)" >&2
      return 1
    fi
    
    case "$editor" in
      code|vscode)
        $editor "$real_repo" &>/dev/null &
        ;;
      vim|nvim)
        $editor "$real_repo"
        ;;
      *)
        $editor "$real_repo" &>/dev/null &
        ;;
    esac
    return $?
  fi
  
  # Pass all other arguments directly to osa-cli.zsh
  "${OSA_REPO_PATH:?OSA_REPO_PATH not set}/osa-cli.zsh" "$@"
}
