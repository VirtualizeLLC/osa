#!/usr/bin/env zsh

# Install oh-my-zsh plugins and create symlinks immediately after each install
# Use OSA_REPO_PATH if set, otherwise detect it

if [[ -z "$OSA_REPO_PATH" ]]; then
    # Detect repo path from script location
    local script_dir="$(cd "$(dirname "${(%):-%x}")" && pwd -P)"
    export OSA_REPO_PATH="$(cd "$script_dir/../.." && pwd -P)"
fi

echo "Installing oh-my-zsh plugins..."

# Install each plugin and symlink it immediately

# 1. Powerlevel10k
echo ""
echo "Installing Powerlevel10k..."
source "$OSA_REPO_PATH/src/setup/oh-my-zsh-plugins/powerlevel10k.zsh"
if [[ -d "$OSA_EXTERNAL_LIBS/powerlevel10k" ]]; then
    local p10k_link="$OSA_EXTERNAL_LIBS/oh-my-zsh/custom/themes/powerlevel10k"
    if [[ ! -L "$p10k_link" && ! -e "$p10k_link" ]]; then
        echo "  Linking powerlevel10k to oh-my-zsh themes folder"
        ln -s "$OSA_EXTERNAL_LIBS/powerlevel10k" "$p10k_link" && echo "  ✓ powerlevel10k linked"
    else
        echo "  ✓ powerlevel10k already linked"
    fi
fi

# 2. Zsh Syntax Highlighting
echo ""
echo "Installing zsh-syntax-highlighting..."
source "$OSA_REPO_PATH/src/setup/oh-my-zsh-plugins/zsh-syntax-highlighting.zsh"
if [[ -d "$OSA_EXTERNAL_LIBS/zsh-syntax-highlighting" ]]; then
    local zsh_hl_link="$OSA_EXTERNAL_LIBS/oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    if [[ ! -L "$zsh_hl_link" && ! -e "$zsh_hl_link" ]]; then
        echo "  Linking zsh-syntax-highlighting to oh-my-zsh plugins folder"
        ln -s "$OSA_EXTERNAL_LIBS/zsh-syntax-highlighting" "$zsh_hl_link" && echo "  ✓ zsh-syntax-highlighting linked"
    else
        echo "  ✓ zsh-syntax-highlighting already linked"
    fi
fi

# 3. Evalcache
echo ""
echo "Installing evalcache..."
source "$OSA_REPO_PATH/src/setup/oh-my-zsh-plugins/evalcache.zsh"
if [[ -d "$OSA_EXTERNAL_LIBS/evalcache" ]]; then
    local evalcache_link="$OSA_EXTERNAL_LIBS/oh-my-zsh/custom/plugins/evalcache"
    if [[ ! -L "$evalcache_link" && ! -e "$evalcache_link" ]]; then
        echo "  Linking evalcache to oh-my-zsh plugins folder"
        ln -s "$OSA_EXTERNAL_LIBS/evalcache" "$evalcache_link" && echo "  ✓ evalcache linked"
    else
        echo "  ✓ evalcache already linked"
    fi
fi

echo ""
echo "✓ All oh-my-zsh plugins installed and linked"