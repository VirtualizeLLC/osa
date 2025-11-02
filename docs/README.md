# OSA Documentation Index

Welcome to the OSA (Open Source Automation) documentation! This directory contains detailed guides and references for using and developing OSA.

## Quick Links

### Getting Started
- **[Setup Guide](setup-guide.md)** - First-time setup, CLI commands, troubleshooting
- **[Configurations](configurations.md)** - Security model, recommended apps, workspace benefits

### Intermediate Guides
- **[Constructors](constructors.md)** - Machine-specific overrides, secrets management, initialization
- **[MPC CLI](mpc-cli.md)** - OSA helper commands (mpc setup, mpc update, etc.)

### Platform-Specific
- **[WSL & Docksal](wsl-docksal.md)** - Windows Subsystem for Linux and Docksal setup
- **[PhpStorm Plugins](phpstorm-plugins.md)** - IDE plugin recommendations

### Development & Operations
- **[Release Management](release-management.md)** - Versioning, changelogs, automated releases
- **[Remote Config Testing](remote-config-testing.md)** - Testing and validating remote configurations
- **[Security Testing](security-testing.md)** - Security validation and vulnerability prevention

## Documentation Structure

### User Documentation
- **Setup Guide** (`setup-guide.md`)
  - First-time setup instructions
  - Interactive vs automated setup
  - Mise runtime manager
  - Troubleshooting and recovery

- **Configurations** (`configurations.md`)
  - Security model explanation
  - Why OSA is safer than traditional dotfiles
  - Recommended applications and workflows
  - Real-world usage scenarios

### Developer Documentation
- **Constructors** (`constructors.md`)
  - How to add machine-specific configuration
  - Where to store secrets safely
  - Init vs final constructors
  - .gitignore patterns for secrets

- **MPC CLI** (`mpc-cli.md`)
  - Helper command overview
  - Available commands
  - Usage examples

### Platform-Specific Guides
- **WSL & Docksal** (`wsl-docksal.md`)
  - WSL 2 setup instructions
  - Docksal containerization
  - Platform-specific considerations

- **PhpStorm Plugins** (`phpstorm-plugins.md`)
  - Recommended IDE plugins
  - Configuration tips
  - Development environment setup

### Development & Operations Guides
- **Release Management** (`release-management.md`)
  - Semantic versioning workflow
  - Automated releases via GitHub Actions
  - Changelog generation

- **Remote Config Testing** (`remote-config-testing.md`)
  - Testing remote configurations
  - Security considerations
  - Team workflow examples

## Community & Contributions

### OSA Scripts
**[OSA Scripts Repository](https://github.com/VirtualizeLLC/osa-scripts)** - Community-contributed shell helpers and productivity functions.

- **Automatically installed** during OSA setup as a core component
- Located at `src/zsh/snippets/` (in the repo, tracked in `.gitignore`)
- Contains productivity helpers, utility functions, and shell shortcuts
- Optional - can be disabled with `--disable-osa-snippets` flag
- Customize source with `SNIPPETS_REPO` environment variable during setup

Want to contribute? See the [osa-scripts repository](https://github.com/VirtualizeLLC/osa-scripts) for guidelines.

### Contributing to OSA
- **Code contributions**: See [CONTRIBUTING.md](../CONTRIBUTING.md)
- **Helper functions**: Submit to [osa-scripts](https://github.com/VirtualizeLLC/osa-scripts)
- **Bug reports**: Open an issue on GitHub
- **Documentation**: Submit PR with improvements



1. Start with the **[Setup Guide](setup-guide.md)**
2. Run: `./osa-cli.zsh --interactive`
3. Read **[Configurations](configurations.md)** to understand the security model
4. Check **[Constructors](constructors.md)** if you need machine-specific settings

## For Developers

1. Read **[CONTRIBUTING.md](../CONTRIBUTING.md)** in the root directory for code standards
2. Check **[Constructors](constructors.md)** for adding configuration
3. See **[MPC CLI](mpc-cli.md)** for helper commands
4. Review test documentation: `tests/README.md`

## Using These Docs

Each guide includes:
- **Purpose**: What the guide covers
- **Quick Start**: Getting started quickly
- **Examples**: Real-world usage examples
- **Troubleshooting**: Common issues and solutions
- **References**: Related documentation

## Documentation Standards

All documentation should:
- Use clear, concise language
- Include examples where relevant
- Link to related documents
- Provide troubleshooting steps
- Stay up-to-date with code changes

## Feedback

If documentation is unclear or outdated:
- Open an issue on GitHub
- Submit a pull request with improvements
- Ask in discussions

## Quick Reference

### Most Common Tasks

**First-time setup:**
```bash
./osa-cli.zsh --interactive
```

**Use saved configuration:**
```bash
./osa-cli.zsh --auto
```

**Clean and reinstall:**
```bash
./osa-cli.zsh --clean --minimal
```

**Check installation health:**
```bash
./osa-cli.zsh --doctor
```

**See all available commands:**
```bash
./osa-cli.zsh --help
```

**Manage runtime versions:**
```bash
mise install                # Install all runtimes from .mise.toml
mise use node@20           # Switch Node.js version
mise list                  # Show installed versions
```

## Navigation

- 📁 Root: [README.md](../README.md), [CONTRIBUTING.md](../CONTRIBUTING.md)
- 📁 Tests: [tests/README.md](../tests/README.md)
- 📁 Source: [src/](../src/)
- 📁 Configs: [configs/](../configs/)
- 📁 Scripts: [cleanup-symlinks.zsh](../cleanup-symlinks.zsh), [osa-cli.zsh](../osa-cli.zsh)

---

**Last Updated:** November 2, 2025
