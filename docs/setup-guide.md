# OSA Setup - Quick Start Guide

## What Changed?

OSA now has a **smart CLI** that:
- ✅ Auto-detects your platform (macOS, Linux, WSL)
- ✅ Lets you choose which components to install
- ✅ Saves your preferences for future runs
- ✅ Prevents circular symlinks and broken installations
- ✅ Provides clear error messages and recovery options

## First Time Setup

### Step 1: Clean Up (if you had issues before)

If you previously tried to set up OSA and encountered symlink errors:

```bash
chmod +x ./cleanup-symlinks.zsh
./cleanup-symlinks.zsh
```

### Step 2: Run Setup

**Interactive Setup (Recommended for first-time users):**
```bash
chmod +x ./osa-cli.zsh
./osa-cli.zsh --interactive
```

This will:
1. Show your platform information
2. Ask which components you want to install
3. Save your choices for future runs
4. Install the selected components

**Quick Minimal Setup:**
```bash
./osa-cli.zsh --minimal
```

Installs only core components:
- Symlinks for repo and .zshrc
- Homebrew (macOS only)
- Oh My Zsh
- Zsh plugins

**Install Everything:**
```bash
./osa-cli.zsh --all
```

Installs all available components for your platform.

## Quick Start with Interactive Setup (Recommended)

The new interactive setup asks you exactly what you need:

```bash
./osa-cli.zsh --interactive
```

**Flow:**
1. ✅ Confirms required components (symlinks, oh-my-zsh, zsh-plugins)
2. 💡 Asks to install mise
3. 🎯 If you choose mise, it asks which runtimes you want:
   - Node.js? (Choose: 20, 22, 24)
   - Python? (Choose: 3.11, 3.12, 3.13)
   - Ruby? (Choose: 3.2.0, 3.3.0, 3.4.0)
   - Java? (Choose: openjdk-11, openjdk-17, openjdk-21)
   - Rust? (Yes/No - uses stable)
   - Go? (Choose: 1.21, 1.22, 1.23)
4. 🚀 Saves your choices to `~/.osaconfig` and `.mise.toml`
5. ⚡ Installs everything automatically

**After setup:**
```bash
source ~/.zshrc        # Reload shell
mise list              # See installed versions
mise current           # Show active versions
```

## Using Mise (Recommended)

Mise is a polyglot runtime manager that replaces individual version managers like nvm, rbenv, jenv, etc.

### Why Mise?
- ✅ Single tool for all languages
- ✅ Faster than individual managers
- ✅ Configuration in `.mise.toml` (version controlled)
- ✅ Automatic version switching based on project
- ✅ Works on macOS, Linux, and WSL

### Common Mise Commands

```bash
# Install a specific version
mise use --global node@20
mise use --global ruby@3.3.0
mise use --global java@openjdk-21

# List available versions
mise ls-remote node

# Install everything from .mise.toml
mise install

# Show what's installed
mise list

# Update to latest version
mise upgrade node

# Remove a tool
mise remove node
```

### Editing `.mise.toml`

Edit versions in the `.mise.toml` file at the repo root:

```toml
[tools]
node = "20"          # Node.js 20.x
ruby = "3.3.0"       # Ruby 3.3.0 (exact version)
java = "openjdk-21"  # OpenJDK 21
python = "3.11"      # Python 3.11
go = "1.21"          # Go 1.21
rust = "stable"      # Rust stable
```

Then run `mise install` to activate all versions.

### Migration from Old Managers

If you were using individual managers, you can now use mise instead:

| Old | New |
|-----|-----|
| `nvm` / `fnm` | `mise use node@VERSION` |
| `rbenv` | `mise use ruby@VERSION` |
| `jenv` | `mise use java@VERSION` |
| `.nvmrc` | `.mise.toml` |
| `.ruby-version` | `.mise.toml` |

## Available Components

### Required (Always Installed)
- **symlinks** - Creates symlinks for ~/.osa and ~/.zshrc (REQUIRED for everything to work)
- **oh-my-zsh** - Oh My Zsh framework (REQUIRED)
- **zsh-plugins** - Syntax highlighting, evalcache, etc. (REQUIRED)
- **homebrew** - Homebrew package manager on macOS (REQUIRED for other tools)

### Recommended (Highly Suggested)
- **mise** (Recommended) - Polyglot runtime manager for Node, Ruby, Java, Python, Go, Rust, etc.
  - Manages versions via `.mise.toml`
  - Can replace rbenv, jenv, fnm, and other version managers
  - Much cleaner and faster than individual tools
  
### Optional (Language Managers - legacy, use mise instead)
- **git** - Git configuration
- **nodejs** - Node.js via fnm (use mise instead)
- **rbenv** - Ruby version manager (use mise instead)
- **jenv** - Java version manager (use mise instead)
- **java** - Java installation via Homebrew (use mise instead)
- **yarn** - Yarn package manager
- **cocoapods** - CocoaPods for iOS development

## CLI Commands

### Setup Commands
```bash
# Interactive component selection
./osa-cli.zsh --interactive

# Use saved configuration
./osa-cli.zsh --auto

# Show platform info
./osa-cli.zsh --info

# List all components
./osa-cli.zsh --list
```

### Configuration Commands
```bash
# Show current configuration
./osa-cli.zsh --config

# Enable a specific component
./osa-cli.zsh --enable nodejs

# Disable a component
./osa-cli.zsh --disable java

# Enable minimal components
./osa-cli.zsh --minimal

# Enable all components
./osa-cli.zsh --all
```

### Get Help
```bash
./osa-cli.zsh --help
```

## Configuration File

Your choices are saved to `~/.osaconfig`. Example:

```bash
# OSA Configuration
# Generated on Fri Nov  1 12:00:00 PDT 2025

OSA_SETUP_SYMLINKS=true
OSA_SETUP_HOMEBREW=true
OSA_SETUP_OH_MY_ZSH=true
OSA_SETUP_ZSH_PLUGINS=true
OSA_SETUP_GIT=true
OSA_SETUP_JAVA=false
OSA_SETUP_JENV=false
OSA_SETUP_RBENV=false
OSA_SETUP_NODEJS=true
OSA_SETUP_YARN=true
OSA_SETUP_COCOAPODS=false
```

You can edit this file manually or use the CLI commands.

## Legacy Setup Script

The old `run-setup.zsh` still works but will delegate to the new CLI:

```bash
chmod +x ./run-setup.zsh
./run-setup.zsh
```

## Troubleshooting

### Circular Symlink Errors

If you see "Too many levels of symbolic links":

```bash
./cleanup-symlinks.zsh
```

Then re-run setup.

### Permission Errors

If you get permission errors:

```bash
chmod +x ./osa-cli.zsh ./cleanup-symlinks.zsh
```

### Component Failed to Install

The CLI will continue with other components if one fails. Check the error message and:

1. Fix the issue (e.g., install Xcode Command Line Tools)
2. Re-enable the component: `./osa-cli.zsh --enable <component>`
3. Run setup again: `./osa-cli.zsh --auto`

### Reset Everything

To start fresh:

```bash
# Backup your current config
cp ~/.osaconfig ~/.osaconfig.backup

# Remove symlinks
rm -f ~/.osa ~/.zshrc

# Restore original zshrc if you have a backup
mv ~/.zshrc_pre_osa ~/.zshrc

# Run setup again
./osa-cli.zsh --interactive
```

## Platform Detection

The CLI automatically detects:

- **macOS**: Version, chip type (Apple Silicon / Intel)
- **Linux**: Distribution (Ubuntu, Debian, etc.)
- **WSL**: Version 1 or 2, underlying Linux distro

View your platform info:
```bash
./osa-cli.zsh --info
```

## Next Steps After Setup

1. **Restart your terminal** or run: `source ~/.zshrc`

2. **Explore Community Scripts**: Check out [osa-scripts](https://github.com/VirtualizeLLC/osa-scripts) for productivity helpers and shell functions that are automatically installed at `~/.osa/snippets/`

3. **Configure Runtime Versions** (if you installed mise):
   
   Edit `.mise.toml` in the repo root to customize Node, Ruby, Java versions:
   ```toml
   [tools]
   node = "20"      # Change Node.js version
   ruby = "3.3.0"   # Change Ruby version
   java = "openjdk-21"  # Change Java version
   ```
   
   Then activate:
   ```bash
   mise install
   ```

4. **Use the mpc command** (if installed):
   ```bash
   mpc        # Show help
   mpc setup  # Re-run setup
   mpc update # Update repo from git
   mpc open   # cd to repo directory
   mpc edit   # Open repo in editor
   ```

5. **Customize with constructors**: Edit files in `src/zsh/constructors/` for machine-specific config

6. **Review docs**:
   - `docs/constructors.md` - Machine-specific overrides
   - `docs/mpc-cli.md` - MPC command details
   - `docs/configurations.md` - Configuration options
   - [osa-scripts](https://github.com/VirtualizeLLC/osa-scripts) - Community helpers

## Migration from Old Setup

If you were using OSA before this update:

1. **Your existing .osaconfig will be respected** - the new CLI reads your saved preferences
2. **No need to reinstall everything** - run `./osa-cli.zsh --auto` to use your existing config
3. **New components available** - run `./osa-cli.zsh --list` to see what's new

## Contributing

To add a new component:

1. Create the setup script in `src/setup/`
2. Register it in `osa-cli.zsh` in the `init_components()` function
3. Test with `./osa-cli.zsh --interactive`

See the existing components for examples.
