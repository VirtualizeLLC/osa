#!/usr/bin/env zsh
# WSL (Windows Subsystem for Linux) Platform Configuration
# This is a template for WSL-specific setup. Customize for your environment.

# ============================================================================
# Optional: Restore previous working directory across WSL sessions
# ============================================================================
# Uncomment to enable:
# if [[ -f ~/wsl-paths.zsh ]]; then
#   source ~/wsl-paths.zsh
#   if [[ $SAVED_PWD != $PWD ]]; then
#     cd $SAVED_PWD
#   fi
# fi
#
# saveCWD(){
#   echo "export SAVED_PWD=\"$(pwd)\"" > ~/wsl-paths.zsh
# }

# ============================================================================
# Homebrew WSL Setup
# ============================================================================
# Uncomment and adjust path if using Linuxbrew:
# eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

# ============================================================================
# SSH and Keychain Setup
# ============================================================================
# Uncomment if using keychain plugin:
# safe_source $OSA_ZSH_PLUGINS/keychain.zsh

# ============================================================================
# Windows Integration
# ============================================================================
# Set your Windows username here if needed for cross-platform paths
# Example: export WINDOWS_USERNAME="your_username"
# export WINDOWS_USERNAME="your_username"

# Alias explorer.exe to open (similar to macOS open command)
# alias open="explorer.exe"

# Drive navigation
# alias C="cd /mnt/c"
# alias D="cd /mnt/d"

# Quick CD aliases for Windows projects
# Example: alias myproject="cd /mnt/c/Users/your_username/Documents/my-project"

# ============================================================================
# Java Configuration
# ============================================================================
# Set JAVA_HOME based on your installed JDK
# Linuxbrew examples:
# export JAVA_HOME=/home/linuxbrew/.linuxbrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home
# 
# Linux system examples:
# export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
# export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# For multiple Java versions:
# export JAVA_11_HOME=/usr/lib/jvm/java-11-openjdk-amd64
# export JAVA_17_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# ============================================================================
# Android Development Setup
# ============================================================================
# WSL-side Android setup (for compilation)
# export ANDROID_HOME=$HOME/Android
# export PATH=$PATH:$ANDROID_HOME/emulator
# export PATH=$PATH:$ANDROID_HOME/tools
# export PATH=$PATH:$ANDROID_HOME/tools/bin
# export PATH=$PATH:$ANDROID_HOME/platform-tools

# Windows-side Android setup (for emulator drivers - if needed)
# Requires both WSL paths (for compilation) and Windows paths (for emulator)
# export WIN_ANDROID_PATH=/mnt/c/Users/$WINDOWS_USERNAME/AppData/Local/Android/Sdk
# export PATH=$PATH:$WIN_ANDROID_PATH/platform-tools
# alias adb="adb.exe"
# alias emulator="emulator.exe"

# React Native WSL hosting fix
# export WSL_HOST_IP="$(tail -1 /etc/resolv.conf | cut -d' ' -f2)"
# export ADB_SERVER_SOCKET=tcp:$WSL_HOST_IP:5037

# ============================================================================
# Custom Tool Paths
# ============================================================================
# Add custom binary paths as needed
# export PATH="$HOME/external-binaries/custom-tool:$PATH"

# ============================================================================
# Custom Aliases
# ============================================================================
# Add environment-specific aliases here
# Example: alias mydb="cd /path/to/database && custom-client"

# Windows/WSL-specific aliases for Android development
# alias emulator="emulator.exe"
# alias adb="adb.exe"
# 
# # Emulator convenience aliases (adjust device names as needed)
# # Run 'emulator -list-avds' to see available emulators
# alias pixel5="emulator -avd Pixel_5_API_31"
# alias pixel6="emulator -avd Pixel_6_API_32"
# alias device="emulator -avd your_device_name"
#
# # Quick project navigation
# alias myproject="cd /mnt/c/Users/your_username/Documents/my-project"
# alias work="cd /mnt/c/Users/your_username/Work"

# ============================================================================
# PowerShell Execution Policy
# ============================================================================
# To enable PowerShell scripts in WSL:
# Open PowerShell in administrator mode and run:
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# Reference: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy

# ============================================================================
# References and Resources
# ============================================================================
# - Share environment variables between WSL and Windows:
#   https://devblogs.microsoft.com/commandline/share-environment-vars-between-wsl-and-windows/
# - WSL Documentation: https://docs.microsoft.com/en-us/windows/wsl/
