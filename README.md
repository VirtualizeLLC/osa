# Open Source Automation (OSA)

**Also known as: One Setup Anywhere**

**Bootstrap any machine with a complete development environment in minutes, not hours.**

OSA is a shell-first, interactive CLI tool that automates the tedious setup of developer tools across platforms. Instead of spending 2-4 hours manually installing and configuring tools, run one command and get back to coding in ~15-30 minutes.

## Why OSA?

**For Developers, By Developers**

- ⚡ **Fast Setup**: 15-30 minutes vs 2-4 hours of manual installation
- 🎯 **Interactive CLI**: Choose exactly what you need, skip what you don't
- 🔄 **Reproducible**: Save your config and reproduce your setup on any machine
- 🛠️ **Shell-First**: No npm, pip, or other runtime dependencies to bootstrap
- 🔐 **Extensible**: Keep secrets and machine-specific configs out of git via constructors
- 📦 **Modern Tooling**: Built-in support for mise (replaces nvm/rbenv/pyenv/jenv)

### Why OSA When Mise Exists?

**Mise is great for runtime management, but OSA solves the whole setup problem:**

Mise only handles runtime versions (Node, Python, Ruby, etc.). OSA handles **everything**:

| Task | Mise | OSA |
|------|------|-----|
| **Runtime versions** (Node, Python, Ruby) | ✅ Yes | ✅ Yes (via mise) |
| **Homebrew packages** (git, ripgrep, etc.) | ❌ No | ✅ Yes |
| **Oh My Zsh + plugins** | ❌ No | ✅ Yes |
| **Shell configuration** | ❌ No | ✅ Yes |
| **Git config** (user, aliases, ignores) | ❌ No | ✅ Yes |
| **IDE settings** (VS Code, PhpStorm) | ❌ No | ✅ Yes |
| **Mobile dev tools** (CocoaPods, Android SDK) | ❌ No | ✅ Yes |
| **Security model** (secrets isolation) | ❌ No | ✅ Yes |
| **Team consistency** (shared configs) | ❌ No | ✅ Yes |

**TL;DR:** Mise is one tool. OSA is an orchestrator that brings together mise + shell + package manager + IDE + security best practices into one unified setup experience.

## Tested Platforms

<ul>
  <li>✅ <strong>macOS</strong> (Primary - extensively tested)</li>
  <li>✅ <strong>Linux</strong> (Ubuntu/Debian - most commands work)</li>
  <li>✅ <strong>WSL 2</strong> (Windows Subsystem for Linux - most commands work)</li>
  <li>⚠️ <strong>Windows Native</strong> (Limited - requires manual setup, see <a href="#windows-native-setup">Windows section</a>)</li>
</ul>

## Quick Start

**Clone and run:**

```bash
git clone https://github.com/VirtualizeLLC/osa.git ~/osa
cd ~/osa
zsh ./osa-cli.zsh --interactive
```

**Note:** If you get "permission denied", try: `chmod +x ./osa-cli.zsh && zsh ./osa-cli.zsh --interactive`

After setup completes, the `osa` command will be available globally from any directory:
```bash
osa --interactive   # Works from anywhere
osa --help          # Try it out
```

That's it. The CLI will guide you through the rest.

### Setup Instructions by Platform

<table>
  <thead>
    <tr>
      <th>Platform</th>
      <th>Setup Command</th>
      <th>Dependencies</th>
      <th>Status</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>macOS</strong></td>
      <td>
        <code>git clone https://github.com/VirtualizeLLC/osa.git ~/osa && cd ~/osa && brew bundle && zsh ./osa-cli.zsh --interactive</code>
      </td>
      <td>Git, Zsh, Homebrew</td>
      <td>✅ Fully Tested</td>
    </tr>
    <tr>
      <td><strong>Linux (Ubuntu/Debian)</strong></td>
      <td>
        <code>git clone https://github.com/VirtualizeLLC/osa.git ~/osa && cd ~/osa && sudo apt-get install -y git zsh jq && zsh ./osa-cli.zsh --interactive</code>
      </td>
      <td>Git, Zsh, jq</td>
      <td>✅ Supported</td>
    </tr>
    <tr>
      <td><strong>WSL 2 (Windows)</strong></td>
      <td>
        <code>git clone https://github.com/VirtualizeLLC/osa.git ~/osa && cd ~/osa && sudo apt-get install -y git zsh jq && zsh ./osa-cli.zsh --interactive</code>
      </td>
      <td>Git, Zsh, jq</td>
      <td>✅ Supported</td>
    </tr>
    <tr>
      <td><strong>Android (Termux)</strong></td>
      <td>
        <code>pkg install git zsh openssh && git clone https://github.com/VirtualizeLLC/osa.git ~/osa && cd ~/osa && zsh ./osa-cli.zsh --interactive</code>
      </td>
      <td>Git, Zsh, OpenSSH</td>
      <td>⚠️ Experimental</td>
    </tr>
    <tr>
      <td><strong>Windows (Native)</strong></td>
      <td>Use <strong>WSL 2</strong> (recommended) or see <a href="#windows-native-setup">manual setup</a></td>
      <td>WSL 2 or manual config</td>
      <td>⚠️ Limited</td>
    </tr>
  </tbody>
</table>

### Detailed Setup by Platform

#### macOS
```bash
git clone https://github.com/VirtualizeLLC/osa.git ~/osa
cd ~/osa
brew bundle              # Install dependencies (optional but recommended)
zsh ./osa-cli.zsh --interactive
```

#### Linux (Ubuntu/Debian)
```bash
git clone https://github.com/VirtualizeLLC/osa.git ~/osa
cd ~/osa
sudo apt-get install -y git zsh jq  # Install dependencies
zsh ./osa-cli.zsh --interactive
```

#### WSL 2 (Windows Subsystem for Linux)
```bash
# In WSL terminal
git clone https://github.com/VirtualizeLLC/osa.git ~/osa
cd ~/osa
sudo apt-get install -y git zsh jq  # Install dependencies
zsh ./osa-cli.zsh --interactive
```

#### Android (Termux)
```bash
# In Termux terminal
pkg install git zsh openssh
git clone https://github.com/VirtualizeLLC/osa.git ~/osa
cd ~/osa
zsh ./osa-cli.zsh --interactive
```

#### Windows (Native)
Use **WSL 2** for best experience (see WSL 2 section above).

For manual setup, see [Windows Native Setup](#windows-native-setup) section.

### Alternative Setup Methods

**Minimal Setup** (core tools only + mise):
```bash
zsh ./osa-cli.zsh --minimal
```

**Use a Preset Config** (no prompts):
```bash
zsh ./osa-cli.zsh --config-file configs/frontend-dev.json
```

**Install Everything**:
```bash
zsh ./osa-cli.zsh --all
```

## What Gets Installed

### Core Components (Always)
- ✅ Zsh configuration and symlinks
- ✅ Oh My Zsh framework
- ✅ Powerlevel10k theme
- ✅ Zsh plugins (syntax highlighting, evalcache)
- ✅ Homebrew (macOS/Linux)
- ✅ **osa-scripts** - Community shell helpers and productivity functions (installed automatically)

### Optional Components (Your Choice)
- 🔧 **mise**: Polyglot runtime manager (Node, Python, Ruby, Java, Go, Rust, etc.)
- 🔧 **Git configuration**: Global git config and aliases
- 🔧 **CocoaPods**: For iOS development (macOS only)
- 🔧 **iTerm2 config**: Terminal configuration
- 🔧 **VS Code settings**: Editor configuration

### Available Runtimes (via mise)
- Node.js (20, 22, 24)
- Python (3.11, 3.12, 3.13)
- Ruby (3.2, 3.3, 3.4)
- Java (OpenJDK 11, 17, 21)
- Go (1.21, 1.22, 1.23)
- Rust (stable)
- Deno, Elixir, Erlang (latest)

## About Mise

**[Mise](https://mise.jdx.dev/)** is a polyglot runtime manager that replaces nvm, rbenv, pyenv, jenv, and similar tools.

### Why Mise?

- ✅ **Single tool** for all languages (no more nvm + rbenv + pyenv juggling)
- ✅ **Fast**: Cached, optimized binaries (much faster than building from source)
- ✅ **Per-project versions**: Automatic switching via `.mise.toml` files
- ✅ **Team consistency**: Everyone uses the same runtime versions
- ✅ **Easy updates**: `mise install` from `.mise.toml`

### Quick Start with Mise

After OSA setup, mise is ready to use:

```bash
# Install runtimes from .mise.toml
mise install

# Check installed versions
mise list

# Switch versions
mise use node@20

# Show what's available
mise list-all node
```

### Per-Project Setup

Create `.mise.toml` in your project:

```toml
[tools]
node = "20.11.0"
python = "3.12"
ruby = "3.3.0"
```

When you `cd` into the directory, mise automatically activates those versions. No more shell aliasing or version switching scripts!

**Learn more:** [Mise Documentation](https://mise.jdx.dev/) | [GitHub](https://github.com/jdx/mise)

## Security Model: Why It Matters

OSA's workspace-based approach is fundamentally different from traditional dotfile management:

### ✅ What OSA Protects

| Problem | Traditional Approach | OSA Solution |
|---------|----------------------|-------------|
| **Installer Corruption** | Any tool can modify `.zshrc` | Your `.zshrc` is read-only symlink |
| **Credential Leaks** | Easy to accidentally commit secrets | Secrets isolated in `.gitignore`d constructors |
| **Silent Changes** | Tools append code without review | All changes require git commits with history |
| **Configuration Drift** | Everyone's setup diverges | Base config identical across team |
| **Debugging** | "What broke my shell?" | Full `git log` audit trail |
| **Rollback** | Manual file restoration | `git revert` instant rollback |

### How It Works

```bash
# Your actual .zshrc is protected (read-only symlink)
~/.zshrc -> ~/osa/src/zsh/.zshrc

# Machine-specific secrets never leave your machine (never committed)
~/osa/src/zsh/constructors/init.zsh     # Loaded first (env vars, tokens)
~/osa/src/zsh/constructors/final.zsh    # Loaded last (aliases, functions)
~/osa/src/zsh/constructors/__local__*   # Machine overrides
```

### Real-World Impact

**Scenario 1: Rogue Installer**
```bash
# Without OSA: Installer silently appends to ~/.zshrc
curl -fsSL https://sketchy-tool.com/install.sh | sh
# Now your shell startup includes tracking code

# With OSA: Installation fails (read-only file)
# You notice the error and investigate before proceeding
```

**Scenario 2: Accidentally Committing Secrets**
```bash
# Without OSA: Easy mistake
echo "export API_KEY=secret123" >> ~/.zshrc
git add .
git push  # Oops, secret is now in git history forever

# With OSA: Impossible
echo "export API_KEY=secret123" >> ~/osa/src/zsh/constructors/init.zsh
git status
# init.zsh is .gitignore'd - cannot be committed
```

**Scenario 3: Team Consistency**
```bash
# Without OSA: Everyone's setup is different
# Dev A uses nvm, Dev B uses fnm, Dev C uses mise
# "Works on my machine" is a daily problem

# With OSA: Everyone runs the same base config
# Machine-specific customizations go in constructors
# Team debugging is faster (identical shell behavior)
```

For detailed security architecture, see **[Configuration & Security Guide](docs/configurations.md)**.

## Documentation

All documentation is organized in the **[docs/](docs/)** directory. See **[docs/README.md](docs/README.md)** for the complete index.

## Community Scripts & Helpers

**[OSA Scripts](https://github.com/VirtualizeLLC/osa-scripts)** - Productivity helpers and shell functions installed automatically during setup.

- 🎯 Community-contributed shell functions and helpers
- 🔧 Utilities for common development tasks
- 📦 Installed to `src/zsh/snippets/` (repo-local, tracked in git config)
- ✅ Installed by default, disable with `--disable-osa-snippets` flag
- 🔗 Customize source with `SNIPPETS_REPO` environment variable

Check out the **[osa-scripts repository](https://github.com/VirtualizeLLC/osa-scripts)** to contribute your own helpers and functions!

### Quick Links
- 📖 **[Setup Guide](docs/setup-guide.md)** - First-time setup, troubleshooting, best practices
- 📖 **[CLI Reference](#cli-commands)** - All CLI commands and options (see below)
- 📖 **[Configurations](docs/configurations.md)** - Security model, recommended apps, workspace benefits
- 📖 **[Constructors](docs/constructors.md)** - Machine-specific config and secrets management
- 📖 **[WSL & Docksal](docs/wsl-docksal.md)** - Windows Subsystem for Linux setup
- 📖 **[PhpStorm Plugins](docs/phpstorm-plugins.md)** - IDE recommendations

### For Contributors
- 📖 **[CONTRIBUTING.md](CONTRIBUTING.md)** - Code standards, testing, development workflow
- 📖 **[tests/README.md](tests/README.md)** - Testing framework and test writing guide

## Windows Native Setup

Windows doesn't have native bash/zsh support, so you'll need to manually configure scripts and tools. OSA primarily targets Unix-like environments, but we include some Windows utilities:

**Windows-Specific Files**:

### AutoHotkey Scripts (Automation)
- `src/apps/autohotkey/autoclicker.ahk` - Auto-clicking utility
- `src/apps/autohotkey/disable_windows_key.ahk` - Disable Windows key
- `src/apps/autohotkey/windows-terminal.ahk` - Windows Terminal shortcuts

### Windows Terminal Configuration
- `src/apps/windows-terminal/settings.json` - Copy to `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json`

### WSL Integration Scripts
- `src/apps/wsl/wslbridge.ps1` - PowerShell bridge for WSL
- `src/apps/wsl/WSL-remap-ports-task-schedule.xml` - Port forwarding task scheduler
- `src/apps/wsl/fix-snap.sh` - Fix snap in WSL

### Android Studio (WSL)
- `src/apps/android-studio/android-wsl.vbs` - Launch Android Studio from WSL

**Recommendation**: Use WSL 2 instead of native Windows for the best OSA experience.

## Key Features

### Constructors - Machine-Specific Config

Constructors let you add machine-specific configuration without committing secrets to git:

```bash
# Example: src/zsh/constructors/final.zsh
export GITHUB_TOKEN="your-secret-token"
alias work='cd ~/work/my-company-project'

# Custom function
deploy() {
  cd ~/projects/$1 && git push heroku main
}
```

See [docs/constructors.md](docs/constructors.md) for details.

### Per-Project Runtime Versions

Use `.mise.toml` files to automatically switch runtime versions per project:

```toml
# .mise.toml in your project directory
[tools]
node = "20.11.0"
python = "3.12"
ruby = "3.3.0"
```

When you `cd` into the directory, mise automatically activates those versions.

### JSON-Based Presets

Share team configurations via JSON files (local or remote):

```bash
# List available presets
./osa-cli.zsh --list-configs

# Use a local preset
./osa-cli.zsh --config-file configs/frontend-dev.json

# Use a remote configuration via URL
./osa-cli.zsh --config-url https://raw.githubusercontent.com/yourorg/configs/main/team-setup.json

# Create your own
cp configs/example-config.json my-team.json
# Edit my-team.json
./osa-cli.zsh --config-file my-team.json
```

See [configs/README.md](configs/README.md) for available presets and remote configuration guide.

## CLI Commands

After installation, use the `osa` command from your shell. For detailed commands, see [Setup Guide](docs/setup-guide.md).

**Most Common:**
```bash
zsh ./osa-cli.zsh --interactive  # Choose what to install
zsh ./osa-cli.zsh --minimal      # Core + mise only
zsh ./osa-cli.zsh --config-file configs/react-native.json  # Use preset
zsh ./osa-cli.zsh --auto         # Use saved configuration
```

For complete command reference, see: **[Setup Guide - CLI Commands](docs/setup-guide.md#cli-commands)**

## Troubleshooting & Help

Common issues and solutions: **[Setup Guide - Troubleshooting](docs/setup-guide.md#troubleshooting)**

- Symlink errors, missing dependencies, platform-specific issues
- See detailed troubleshooting guide in docs/

## Project Structure

See [Project Tree](#) in docs/ for full structure. Quick overview:

```
osa/
├── osa-cli.zsh          # Main entry point
├── configs/             # JSON preset configurations
├── src/apps/            # App-specific configurations
├── src/setup/           # Installation scripts
├── src/zsh/             # Zsh configuration and constructors
└── docs/                # Full documentation
```

## Dependencies

**Required:** zsh shell  
**Auto-Installed:** Homebrew, Oh My Zsh, Powerlevel10k  
**Optional:** mise, jq, git  

See [Configurations Guide](docs/configurations.md) for detailed tool recommendations.

## Related Projects

OSA integrates with these tools:

- **[oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)** - Zsh framework
- **[powerlevel10k](https://github.com/romkatv/powerlevel10k)** - Zsh theme
- **[mise](https://mise.jdx.dev/)** - Runtime manager (nvm/rbenv/pyenv replacement)
- **[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)** - Command highlighting

**Alternative approaches:** [chezmoi](https://www.chezmoi.io/) (templated dotfiles) vs [yadm](https://yadm.io/) (encrypted sync)

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for:

- 📝 **Code Standards**: zsh-only, `.zsh` extension, naming conventions
- 🧪 **Testing Requirements**: How to write and run tests with BATS
- ✅ **Pull Request Checklist**: What we look for before merging
- 🛠️ **Development Workflow**: Step-by-step guide for contributors
- 🏗️ **Architecture Guidelines**: Component-based design, safety model

**Quick PR Requirements**:
- ✅ All code uses `.zsh` extension with zsh syntax
- ✅ Tests pass: `./tests/run-tests.zsh`
- ✅ Scripts are syntactically valid: `bash -n script.zsh`
- ✅ Safety checks for destructive operations
- ✅ Documentation updated
- ✅ Add `release:major` or `release:minor` label for automatic releases

GitHub Actions will automatically run tests on all pull requests.

### Release Management

OSA uses automated semantic versioning:

- **Major releases** (breaking changes): Add `release:major` label to PR
- **Minor releases** (new features): Add `release:minor` label to PR  
- **Patch releases** (bug fixes): Manual release via GitHub Actions

See [Release Management Guide](docs/release-management.md) for details on:
- 📦 How automatic releases work
- 📝 Changelog generation
- 🏷️ Using release labels
- 📋 Commit message conventions

## License

MIT License - See [LICENSE](LICENSE) file for details.

---

**Built by developers, for developers.** Get back to coding faster.
