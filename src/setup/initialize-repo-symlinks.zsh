#!/usr/bin/env zsh

# symlink the entire repo to the root user for easy file access
# Needs to be run in the root of this directory

# CRITICAL: Get the actual repo path, not symlink resolutions
# We detect it by finding where THIS script actually lives
detect_repo_path() {
    # First priority: use OSA_REPO_PATH if already set (from CLI)
    if [[ -n "$OSA_REPO_PATH" ]]; then
        # Validate it looks like the OSA repo
        if [[ -f "$OSA_REPO_PATH/.mise.toml" && -d "$OSA_REPO_PATH/src/setup" ]]; then
            echo "$OSA_REPO_PATH"
            return 0
        else
            echo "ERROR: OSA_REPO_PATH is set but doesn't look like OSA repo: $OSA_REPO_PATH" >&2
            echo "  Looking for: $OSA_REPO_PATH/.mise.toml and $OSA_REPO_PATH/src/setup" >&2
            return 1
        fi
    fi
    
    # Second priority: detect from script location
    # Use ZSH-specific array for sourced script path
    local script_file="${(%):-%x}"
    
    # Fallback to $0 if that doesn't work
    if [[ -z "$script_file" || "$script_file" == "zsh" || "$script_file" == "-" ]]; then
        script_file="$0"
    fi
    
    # If still not set, we're stuck
    if [[ -z "$script_file" || "$script_file" == "-" || "$script_file" == "zsh" ]]; then
        echo "ERROR: Cannot determine script location and OSA_REPO_PATH not set" >&2
        echo "  Please run from osa-cli.zsh or set OSA_REPO_PATH manually" >&2
        return 1
    fi
    
    # Resolve to absolute path if relative
    if [[ "$script_file" != /* ]]; then
        script_file="$(cd "$(dirname "$script_file")" && pwd -P)/$(basename "$script_file")"
    fi
    
    # Get the directory where this script is located
    local script_dir
    script_dir="$(cd "$(dirname "$script_file")" && pwd -P)"
    
    # Navigate up two levels: src/setup -> src -> (repo root)
    local repo_root
    repo_root="$(cd "$script_dir/../.." && pwd -P)"
    
    # Verify we're in the right place
    if [[ ! -f "$repo_root/.mise.toml" || ! -d "$repo_root/src/setup" ]]; then
        echo "ERROR: Detected path doesn't look like OSA repo: $repo_root" >&2
        echo "  Looking for: $repo_root/.mise.toml and $repo_root/src/setup" >&2
        return 1
    fi
    
    echo "$repo_root"
    return 0
}

# Determine the repo path (with fallback to detection if OSA_REPO_PATH not provided)
if [[ -z "$OSA_REPO_PATH" ]]; then
    DETECTED_REPO_PATH="$(detect_repo_path)"
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    export OSA_REPO_PATH="$DETECTED_REPO_PATH"
else
    # Validate the provided OSA_REPO_PATH
    DETECTED_REPO_PATH="$(detect_repo_path)"
    if [[ $? -ne 0 ]]; then
        return 1
    fi
fi

# Set environment variables for this session if not already set
export OSA_CONFIG="${OSA_CONFIG:-$HOME/.osa}"
export OSA_EXTERNAL_LIBS="$OSA_CONFIG/external-libs"
export OSA_ZSH_CONSTRUCTORS="$OSA_CONFIG/src/zsh/constructors"
export OSA_ZSH_PLUGINS="$OSA_CONFIG/src/zsh/plugins"
export OSA_ZSH_CONSTANTS="$OSA_CONFIG/src/zsh/constants"
export OSA_CONFIG_APPS="$OSA_CONFIG/src/apps"
export OSA_ZSHRC="$OSA_CONFIG/src/zsh/.zshrc"

echo "Detected repo path: $OSA_REPO_PATH"
echo "Symlink target: $OSA_CONFIG"
echo ""

# symlink the entire repo to the root user for easy file access
handleRepoLink(){
    local FOLDER="$OSA_CONFIG"
    local REPO_PATH="$OSA_REPO_PATH"
    
    # Validation
    if [[ -z "$FOLDER" ]] || [[ -z "$REPO_PATH" ]]; then
        echo "ERROR: FOLDER or REPO_PATH not set"
        echo "  FOLDER=$FOLDER"
        echo "  REPO_PATH=$REPO_PATH"
        return 1
    fi
    
    # Sanity check: ensure repo path is NOT the same as symlink target
    if [[ "$FOLDER" == "$REPO_PATH" ]]; then
        echo "ERROR: FOLDER and REPO_PATH are the same! This would create a circular symlink."
        echo "  FOLDER=$FOLDER"
        echo "  REPO_PATH=$REPO_PATH"
        return 1
    fi
    
    # If the symlink already exists and points to the current repo, we're good
    if test -L "$FOLDER"; then
        local current_target=$(readlink "$FOLDER")
        if [[ "$current_target" == "$REPO_PATH" ]]; then
            echo "✓ Symlink $FOLDER already points to $REPO_PATH"
            handleNodeVersionLink
            return 0
        else
            echo "⚠ Symlink $FOLDER points to wrong location: $current_target"
            echo "  Expected: $REPO_PATH"
            echo "  Removing old symlink..."
            rm "$FOLDER" || {
                echo "ERROR: Failed to remove $FOLDER"
                return 1
            }
        fi
    elif test -e "$FOLDER"; then
        echo "ERROR: $FOLDER exists but is not a symlink."
        echo "Please backup and remove it manually, then re-run setup:"
        echo "  mv $FOLDER ${FOLDER}.backup"
        return 1
    fi

    echo "Creating symlink: $REPO_PATH -> $FOLDER"
    ln -s "$REPO_PATH" "$FOLDER" || {
        echo "ERROR: Failed to create symlink"
        return 1
    }

    if ! test -L "$FOLDER"; then
        echo "ERROR: Symlink creation failed or symlink doesn't exist at $FOLDER"
        return 1
    fi

    echo "✓ Repository symlinked successfully: $FOLDER -> $REPO_PATH"

    # Ensure .nvmrc is linked to .node-version so both come from same file
    handleNodeVersionLink
}

handleNodeVersionLink(){
    # Ensure the repo's .nvmrc is a symlink to .node-version (source of truth)
    # Uses $OSA_CONFIG (same as FOLDER above)
    local REPO_ROOT="$OSA_CONFIG"
    local TARGET="$REPO_ROOT/.node-version"
    local LINK="$REPO_ROOT/.nvmrc"

    # Only act if repo root exists
    if ! test -d "$REPO_ROOT"; then
        return 0
    fi

    # If there's no .node-version, nothing to link to
    if ! test -f "$TARGET"; then
        return 0
    fi

    # If link exists and already points to .node-version, nothing to do
    if test -L "$LINK"; then
        local current
        current=$(readlink "$LINK")
        if [ "$current" = ".node-version" ] || [ "$current" = "$TARGET" ]; then
            return 0
        else
            rm "$LINK"
        fi
    fi

    # If .nvmrc exists as a regular file, back it up then create symlink
    if test -f "$LINK"; then
        mv "$LINK" "$LINK.bak"
    fi

    # Create relative symlink so repo stays relocatable
    (cd "$REPO_ROOT" && ln -sfn .node-version .nvmrc)
    echo "✓ Linked $LINK -> .node-version"
}

# Link .zshrc file
handleZshrcLink(){
    local FILE=$HOME/.zshrc
    local TARGET=$OSA_ZSHRC

    # Validation
    if [[ -z "$TARGET" ]]; then
        echo "ERROR: OSA_ZSHRC not set"
        return 1
    fi
    
    # Ensure target exists before symlinking
    if ! test -f "$TARGET"; then
        echo "ERROR: Target .zshrc not found at $TARGET"
        return 1
    fi

    # Check if symlink already exists and points to correct target
    if test -L "$FILE"; then
        local current_target=$(readlink "$FILE")
        if [[ "$current_target" == "$TARGET" ]]; then
            echo "✓ .zshrc already linked correctly"
            # Still set permissions on the target
            if test -f "$TARGET"; then
                chmod 444 "$TARGET" 2>/dev/null || true
            fi
            return 0
        else
            echo "⚠ $FILE is a symlink pointing to wrong location"
            echo "  Current: $current_target"
            echo "  Expected: $TARGET"
            echo "  Removing old symlink..."
            rm "$FILE" || {
                echo "ERROR: Failed to remove $FILE"
                return 1
            }
        fi
    elif test -f "$FILE"; then
        echo "⚠ $FILE exists as regular file. Backing up to .zshrc_pre_osa"

        if test -f $HOME/.zshrc_pre_osa; then
            rm $HOME/.zshrc_pre_osa
        fi

        mv "$FILE" $HOME/.zshrc_pre_osa
    fi

    echo "Creating symlink: $TARGET -> $FILE"
    ln -s "$TARGET" "$FILE" || {
        echo "ERROR: Failed to create .zshrc symlink"
        return 1
    }

    # Verify symlink was created
    if ! test -L "$FILE"; then
        echo "ERROR: .zshrc symlink creation failed"
        return 1
    fi

    # set .zshrc to read only preventing scripts from breaking it.
    chmod 444 "$TARGET" 2>/dev/null || true
    echo "✓ .zshrc symlink created and target set to read-only"
}

# required for oh-my-zsh-plugins to work
handleOhMyZshPluginIntegration(){
    local omz_custom_themes="$OSA_EXTERNAL_LIBS/oh-my-zsh/custom/themes"
    local omz_custom_plugins="$OSA_EXTERNAL_LIBS/oh-my-zsh/custom/plugins"
    
    # Ensure custom directories exist
    mkdir -p "$omz_custom_themes" 2>/dev/null || true
    mkdir -p "$omz_custom_plugins" 2>/dev/null || true
    
    # Link powerlevel10k
    if test -d "$OSA_EXTERNAL_LIBS/powerlevel10k"; then
        local p10k_link="$omz_custom_themes/powerlevel10k"
        if test -L "$p10k_link"; then
            echo "✓ powerlevel10k already linked"
        elif test -e "$p10k_link"; then
            echo "⚠ $p10k_link exists but is not a symlink, skipping"
        else
            echo "Linking powerlevel10k to oh-my-zsh custom theme folder"
            ln -s "$OSA_EXTERNAL_LIBS/powerlevel10k" "$p10k_link" && echo "✓ powerlevel10k linked"
        fi
    fi

    # Link zsh-syntax-highlighting
    if test -d "$OSA_EXTERNAL_LIBS/zsh-syntax-highlighting"; then
        local zsh_hl_link="$omz_custom_plugins/zsh-syntax-highlighting"
        if test -L "$zsh_hl_link"; then
            echo "✓ zsh-syntax-highlighting already linked"
        elif test -e "$zsh_hl_link"; then
            echo "⚠ $zsh_hl_link exists but is not a symlink, skipping"
        else
            echo "Linking oh-my-zsh-plugin: zsh-syntax-highlighting"
            ln -s "$OSA_EXTERNAL_LIBS/zsh-syntax-highlighting" "$zsh_hl_link" && echo "✓ zsh-syntax-highlighting linked"
        fi
    fi

    # Link evalcache
    if test -d "$OSA_EXTERNAL_LIBS/evalcache"; then
        local evalcache_link="$omz_custom_plugins/evalcache"
        if test -L "$evalcache_link"; then
            echo "✓ evalcache already linked"
        elif test -e "$evalcache_link"; then
            echo "⚠ $evalcache_link exists but is not a symlink, skipping"
        else
            echo "Linking oh-my-zsh-plugin: evalcache"
            ln -s "$OSA_EXTERNAL_LIBS/evalcache" "$evalcache_link" && echo "✓ evalcache linked"
        fi
    fi
}

# Execute all symlink setup functions
echo "Setting up symlinks..."
echo "─────────────────────────────────────────"

handleRepoLink || exit 1
handleZshrcLink || exit 1

echo "─────────────────────────────────────────"
echo "✓ Core symlinks created successfully"