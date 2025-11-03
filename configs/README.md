# OSA Configuration Files

JSON configuration files allow you to automate the setup process without interactive prompts. Download a preset or customize one for your needs.

## Quick Reference

| What You Want | Command |
|---------------|---------|
| **Interactive setup** (choose components) | `./osa-cli.zsh --interactive` |
| **Fast setup** (shell + mise) | `./osa-cli.zsh --minimal` |
| **Use a preset config** (e.g., React Native) | `./osa-cli.zsh --config react-native` |
| **Preview before installing** | `./osa-cli.zsh --config web --dry-run` |
| **Download team config from URL** | `./osa-cli.zsh --config-url https://...` |
| **List available presets** | `./osa-cli.zsh --list-configs` |
| **See all CLI options** | `./osa-cli.zsh --help` |
| **Install everything** | `./osa-cli.zsh --all` |
| **Reproduce saved setup** | `./osa-cli.zsh --auto` |

## Quick Start

```bash
# List all available presets
./osa-cli.zsh --list-configs

# Use a preset configuration (local file)
./osa-cli.zsh --config-file configs/react-native.json

# Use a remote configuration (URL)
./osa-cli.zsh --config-url https://raw.githubusercontent.com/user/repo/main/config.json

# Test without actually installing (dry-run)
./osa-cli.zsh --config-file configs/react-native.json --dry-run
./osa-cli.zsh --config-url https://example.com/config.json --dry-run

# Create a custom config based on example
cp configs/example-config.json my-setup.json
# Edit my-setup.json
./osa-cli.zsh --config-file my-setup.json
```

## Available Presets

### `minimal.json`
Shell-only setup (no development tools):
- **Components**: Only required items (symlinks, oh-my-zsh, zsh-plugins, osa-snippets)
- **Runtimes**: None
- **Best for**: System administrators, lightweight setups, servers

```bash
./osa-cli.zsh --config-file configs/minimal.json
```

### `example-config.json`
Basic web development setup:
- **Components**: Core + homebrew, mise, git, VSCode
- **Runtimes**: Node.js 22 only
- **Best for**: Getting started, simple web projects, customization template

```bash
./osa-cli.zsh --config-file configs/example-config.json
```

### `web.json`
Complete frontend web developer environment:
- **Components**: Core + homebrew, mise, git, vscode, direnv, compression
- **Runtimes**: Node.js 22, Python 3.13, Rust stable, Deno latest
- **Best for**: React, Vue, Next.js, Svelte, web development

```bash
./osa-cli.zsh --config-file configs/web.json
```

### `backend.json`
Complete backend/polyglot environment:
- **Components**: Core + homebrew, mise, git, vscode, direnv, compression
- **Runtimes**: Node.js 22, Python 3.13, Ruby 3.4.0, Java OpenJDK 21, Rust stable, Go 1.23, Elixir, Erlang
- **Best for**: Full-stack, microservices, API development, polyglot developers

```bash
./osa-cli.zsh --config-file configs/backend.json
```

### `macos.json`
General macOS development environment (no mobile platforms):
- **Components**: Core + homebrew, mise, git, vscode, direnv, keychain, mac-tools, compression
- **Runtimes**: Node.js 22, Python 3.13, Ruby 3.4.0, Java OpenJDK 21, Go 1.23
- **Best for**: macOS-only development, avoiding iOS/CocoaPods, general development

```bash
./osa-cli.zsh --config-file configs/macos.json
```

### `android.json`
Android development setup:
- **Components**: Core + homebrew, mise, git, vscode + android tools
- **Runtimes**: Node.js 22, Python 3.13, Ruby 3.4.0, Java OpenJDK 17 (required for Android)
- **Best for**: Android app development, React Native (Android only)

```bash
./osa-cli.zsh --config-file configs/android.json
```

### `ios.json`
iOS development setup:
- **Components**: Core + homebrew, mise, git, vscode + cocoapods, xcode, keychain
- **Runtimes**: Node.js 22, Python 3.13, Ruby 3.4.0 (required for CocoaPods)
- **Best for**: iOS app development, React Native (iOS only)

```bash
./osa-cli.zsh --config-file configs/ios.json
```

### `react-native.json` ⭐
Complete React Native mobile development environment (iOS and Android):
- **Components**: All + android tools, cocoapods, xcode, keychain
- **Runtimes**: Node.js 22, Python 3.13, Ruby 3.4.0, Java OpenJDK 17
- **Best for**: iOS and Android mobile app development with React Native

```bash
./osa-cli.zsh --config-file configs/react-native.json
```

### `everything.json` ⭐
Install absolutely everything OSA supports:
- **Components**: All available components and snippets flags
- **Runtimes**: All runtimes (Node, Python, Ruby, Java, Rust, Go, Deno, Elixir, Erlang)
- **Best for**: Maximum compatibility, experimentation, kitchen sink setups

```bash
./osa-cli.zsh --config-file configs/everything.json
```

## Configuration Schema

Each JSON config file has this structure:

```json
{
  "version": "1.0",
  "description": "Your setup description",
  "profile": "web",
  "components": {
    "symlinks": true,
    "oh_my_zsh": true,
    "zsh_plugins": true,
    "homebrew": true,
    "mise": true,
    "osa_snippets": true,
    "git": true,
    "vscode": false,
    "cocoapods": false
  },
  "runtimes": {
    "node": { "enabled": true, "version": "22" },
    "python": { "enabled": true, "version": "3.13" },
    "ruby": { "enabled": false, "version": "3.4.0" },
    "java": { "enabled": false, "version": "openjdk-21" },
    "rust": { "enabled": false, "version": "stable" },
    "go": { "enabled": false, "version": "1.23" },
    "deno": { "enabled": false, "version": "latest" },
    "elixir": { "enabled": false, "version": "latest" },
    "erlang": { "enabled": false, "version": "latest" }
  }
}
```

### Components Section

The `components` object controls:
1. **Setup components** (install scripts during `./osa-cli.zsh --config-file`):
   - `symlinks` - Create ~/.osa symlinks
   - `oh_my_zsh` - Install Oh My Zsh framework
   - `zsh_plugins` - Install zsh plugins (syntax highlighting, evalcache, etc)
   - `homebrew` - Install Homebrew (macOS only)
   - `mise` - Install mise runtime manager
   - `osa_snippets` - Download osa-snippets community helpers
   - `git` - Configure Git settings
   - `cocoapods` - Install CocoaPods (iOS development, macOS only)

2. **Snippets runtime flags** (control what loads from entry.zsh at shell startup):
   - `android` - Android development aliases and tools
   - `react_native` - React Native utilities
   - `vscode` - VS Code integration
   - `direnv` - Direnv environment switching
   - `keychain` - Keychain utilities
   - `ngrok` - Ngrok tunneling
   - `mac_tools` - macOS utilities (browsers, deletion commands)
   - `xcode` - Xcode command-line utilities
   - `egpu` - eGPU management
   - `compression` - Compression utilities
   - And version manager flags: `node`, `python`, `ruby`, `java`, `nvm`, `fnm`

All flags are saved to `~/.osa-config` and exported to the shell environment, making them available when entry.zsh sources snippets at shell startup.

## Creating a Custom Config

1. **Copy a template**:
   ```bash
   cp configs/example-config.json my-custom-setup.json
   ```

2. **Edit the file** to enable/disable components and runtimes:
   ```json
   {
     "version": "1.0",
     "description": "My custom setup",
     "components": {
       "symlinks": true,
       "oh_my_zsh": true,
       "zsh_plugins": true,
       "homebrew": true,
       "mise": true,
       "iterm2": false,
       "vscode": true
     },
     "runtimes": {
       "node": { "enabled": true, "version": "20" },
       "python": { "enabled": true, "version": "3.12" },
       "ruby": { "enabled": false, "version": "3.4.0" }
     }
   }
   ```

3. **Run the setup**:
   ```bash
   ./osa-cli.zsh --config-file my-custom-setup.json
   ```

4. **Test first with dry-run** (recommended):
   ```bash
   ./osa-cli.zsh --config-file my-custom-setup.json --dry-run
   ```

## Component Reference

| Component | Type | Description | Platforms | Notes |
|-----------|------|-------------|-----------|-------|
| `symlinks` | Setup | Create ~/.osa symlinks | macOS, Linux, WSL | **Required** |
| `oh_my_zsh` | Setup | Install oh-my-zsh framework | macOS, Linux, WSL | **Required** |
| `zsh_plugins` | Setup | Install zsh plugins (syntax highlighting, evalcache) | macOS, Linux, WSL | **Required** |
| `osa_snippets` | Setup | Clone osa-snippets repo (community helpers) | macOS, Linux, WSL | **Required** |
| `homebrew` | Setup | Install Homebrew package manager | macOS | Recommended |
| `mise` | Setup | Install mise (polyglot runtime manager) | macOS, Linux, WSL | Recommended |
| `git` | Setup | Configure Git settings | macOS, Linux, WSL | Recommended |
| `cocoapods` | Setup | Install CocoaPods for iOS | macOS | Optional, iOS only |
| `android` | Snippets | Android development aliases/tools | macOS, Linux, WSL | Optional |
| `react_native` | Snippets | React Native utilities | macOS, Linux, WSL | Optional |
| `vscode` | Snippets | VS Code integration | macOS, Linux, WSL | Optional |
| `direnv` | Snippets | Direnv environment switching | macOS, Linux, WSL | Optional |
| `keychain` | Snippets | Keychain utilities | macOS | Optional |
| `ngrok` | Snippets | Ngrok tunneling | macOS, Linux, WSL | Optional |
| `mac_tools` | Snippets | macOS utilities (browsers, deletion) | macOS | Optional |
| `xcode` | Snippets | Xcode command-line utilities | macOS | Optional |
| `egpu` | Snippets | eGPU management | macOS | Optional |
| `compression` | Snippets | Compression utilities (pbzip2) | macOS, Linux, WSL | Optional |
| `node` | Snippets | Node.js aliases (if not using mise) | macOS, Linux, WSL | Optional |
| `python` | Snippets | Python aliases (if not using mise) | macOS, Linux, WSL | Optional |
| `ruby` | Snippets | Ruby aliases (if not using mise) | macOS, Linux, WSL | Optional |
| `java` | Snippets | Java aliases (if not using mise) | macOS, Linux, WSL | Optional |
| `nvm` | Snippets | Node Version Manager support | macOS, Linux, WSL | Optional |
| `fnm` | Snippets | Fast Node Manager support | macOS, Linux, WSL | Optional |

## Runtime Versions

### Node.js
- `20` (LTS)
- `22` (LTS)
- `24` (Latest)

### Python
- `3.11`
- `3.12`
- `3.13`

### Ruby
- `3.2.0`
- `3.3.0`
- `3.4.0`

### Java
- `openjdk-11`
- `openjdk-17`
- `openjdk-21`

### Rust
- `stable`

### Go
- `1.21`
- `1.22`
- `1.23`

### Deno, Elixir, Erlang
- `latest`

## Tips & Troubleshooting

**Q: Can I combine multiple configs?**
A: Not directly, but you can copy and merge JSON files manually.

**Q: Which config should I use?**
A: Start with `example-config.json` for minimal setup, or pick the role that matches yours (frontend-dev, backend-dev, etc.).

**Q: Can I update versions later?**
A: Yes! Edit your `.mise.toml` file and run `mise install` again.

**Q: Why is jq required?**
A: We use `jq` to parse JSON configs. If it's not installed, run: `brew install jq`

**Q: Can I version control my config?**
A: Absolutely! Commit your custom config to git and share it with your team.

### CocoaPods & Ruby Gem Installation Issues

**Q: Why do I get "readonly" errors when installing CocoaPods?**
A: When `gem install cocoapods` runs, it tries to write to Ruby's gem directory. If you see permission errors:

```
ERROR: While executing gem ... (Gem::FilePermissionError)
  You don't have write permissions
```

**Solutions (in order of preference):**

1. **Use user-install mode** (automatic in OSA):
   ```bash
   gem install cocoapods --user-install
   ```
   This installs gems to `~/.gem` which is always writable.

2. **Set GEM_HOME** to a user directory:
   ```bash
   export GEM_HOME="$HOME/.gem"
   export PATH="$GEM_HOME/bin:$PATH"
   gem install cocoapods
   ```

3. **Use sudo** (last resort):
   ```bash
   sudo gem install cocoapods
   ```
   ⚠️ Only use this if other methods fail. Installing gems as root is not recommended.

**Q: Why does CocoaPods need a specific Ruby version?**
A: CocoaPods has Ruby version requirements:
- **CocoaPods 1.14+**: Requires Ruby 3.0+
- **CocoaPods 1.13**: Requires Ruby 2.7+
- **CocoaPods 1.12**: Requires Ruby 2.7+

OSA handles version compatibility automatically and warns you if there's a mismatch.

**Q: Can I skip CocoaPods installation?**
A: Yes, CocoaPods is optional. During interactive setup, answer "No" when asked. You can install it later manually:
```bash
./osa-cli.zsh --enable cocoapods --auto
```

## Security

### Remote Configuration Security

When using `--config-url`, OSA implements multiple security layers:

1. **HTTPS Only**: HTTP URLs are rejected to prevent man-in-the-middle attacks
2. **Input Validation**: Version strings must match `^[a-zA-Z0-9._-]+$` (prevents command injection)
3. **No eval()**: Uses `typeset -g` instead of `eval` for safe variable assignment
4. **JSON Parsing Only**: Uses `jq` to parse configs (no shell script execution)
5. **User Confirmation**: Shows preview and requires explicit approval before installation
6. **Temp File Isolation**: Downloads to `/tmp` with PID-based unique names

**Example of blocked malicious config:**
```json
{
  "runtimes": {
    "node": {
      "version": "22; rm -rf ~/*"  // ❌ BLOCKED - invalid characters
    }
  }
}
```

**Safe version formats:**
- ✅ `22`, `3.13`, `openjdk-21`, `stable`, `latest`
- ❌ `22; rm -rf`, `$(whoami)`, `` `ls` ``

### Best Practices

- Only load configs from **trusted sources** (your org's repos, verified gists)
- Review configs before sharing them with your team
- Use `--dry-run` first when testing new remote configs
- Pin to specific git tags/branches for production setups

## Distribution

Share your setup configuration with others using these methods:

### Local File Distribution
```bash
# Create a gist or GitHub repo with your config file
# Others can download and use it:
curl -o my-config.json https://raw.github.com/.../my-setup.json
./osa-cli.zsh --config-file my-config.json
```

### Remote Configuration (Direct URL) ⭐
OSA can download and execute configurations directly from URLs:

```bash
# GitHub raw file
./osa-cli.zsh --config-url https://raw.githubusercontent.com/yourorg/configs/main/team-setup.json

# GitHub gist
./osa-cli.zsh --config-url https://gist.githubusercontent.com/user/abc123/raw/config.json

# Any HTTPS URL
./osa-cli.zsh --config-url https://yourcompany.com/osa/standard-config.json
```

**Security Note**: OSA will:
1. Download the configuration to a temporary file
2. Show a preview of what will be installed (components and runtimes)
3. Ask for confirmation before proceeding
4. Only load from trusted HTTPS sources

**Team Workflow Example**:
```bash
# 1. Create a team config in your org's repo
git clone https://github.com/yourorg/osa-configs
cd osa-configs
vim team-frontend.json  # Customize for your team

# 2. Commit and push
git add team-frontend.json
git commit -m "Add frontend team config"
git push

# 3. Share the command with your team
# New team members can run:
./osa-cli.zsh --config-url https://raw.githubusercontent.com/yourorg/osa-configs/main/team-frontend.json
```

**Best Practices for Remote Configs**:
- Always use HTTPS URLs (HTTP is not supported)
- Host configs in version-controlled repositories
- Use semantic versions in URLs for stable configs
- Test with `--dry-run` first
- Include a clear "description" field in your JSON
