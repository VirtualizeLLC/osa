# Changelog

All notable changes to OSA (Open Source Automation) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## Unreleased

### ✨ Features & Enhancements
- Added secure credential management system with platform-agnostic secret storage
- Introduced `osa-secret-set` and `osa-secret-get` helpers for safe credential handling
- Added `--scan-secrets` command to detect hardcoded credentials
- Added `--migrate-secrets` wizard for moving secrets to secure storage
- Added `--setup-git-hook` to install pre-commit hook for secret detection
- Automated release workflow with PR label-based triggers
- Comprehensive changelog generation for major/minor releases

### 🔒 Security
- Created comprehensive secret scanning system to prevent credential leaks
- Integrated with macOS Keychain, GNOME Keyring, pass, and GPG fallback
- Pre-commit hook blocks commits containing potential secrets

### 📚 Documentation
- Added `init.zsh.example` showing safe credential patterns
- Updated security best practices in constructor templates
- Created comprehensive release management documentation
- Added PR template with release label guidance

### 🔧 Maintenance
- Standardized file extensions to `.zsh` for zsh-specific scripts
- Improved GitHub Actions release workflow with comprehensive changelog generation
- Automated CHANGELOG.md updates on releases
- Added `release:major` and `release:minor` label support for auto-releases

---

## [0.1.0] - Initial Release

### ✨ Features
- Cross-platform shell setup automation (macOS, Linux, WSL)
- Oh My Zsh integration with custom plugins
- Mise-based polyglot runtime manager support
- Platform-specific constructors for machine customization
- Homebrew package management integration
- Git configuration automation
- VSCode, iTerm2, and IDE integrations
- Android development setup tools
- Comprehensive CLI with interactive and automated modes

### 📦 Components
- Core: symlinks, oh-my-zsh, zsh-plugins
- Runtimes: Node.js, Python, Ruby, Java, Go, Rust, Deno, Elixir, Erlang
- Tools: git, cocoapods, rbenv, jenv, fnm
- Apps: VSCode, iTerm2, Android Studio, PHPStorm

---

[0.1.0]: https://github.com/FrederickEngelhardt/one-setup-anywhere/releases/tag/v0.1.0
