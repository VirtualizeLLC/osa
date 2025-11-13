#!/usr/bin/env zsh
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools


# Only add cmdline-tools 'latest' to PATH if it exists (prevents broken PATH entries)
if [[ -d "$ANDROID_HOME/cmdline-tools/latest/bin" ]]; then
	export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
else
	# If cmdline-tools exists, list available versions and suggest creating a 'latest' symlink
	if [[ -d "$ANDROID_HOME/cmdline-tools" ]]; then
		echo "Note: Android cmdline-tools 'latest' not found at: $ANDROID_HOME/cmdline-tools/latest"
		echo "Available cmdline-tools directories:" 
		# List entries in the cmdline-tools directory
		ls -1 "$ANDROID_HOME/cmdline-tools" 2>/dev/null | sed 's/^/  - /'
		echo ""
		echo "You can create a 'latest' symlink to one of the above versions, for example:"
		echo "  ln -s \"$ANDROID_HOME/cmdline-tools/<version>\" \"$ANDROID_HOME/cmdline-tools/latest\""
		echo "After creating the symlink, re-open your shell to pick up the new PATH entry."
	else
		# cmdline-tools directory is missing entirely
		echo "Android cmdline-tools not found under: $ANDROID_HOME/cmdline-tools"
		echo "Install the Android SDK Command-line Tools (via Android Studio's SDK Manager), or run:"
		echo "  sdkmanager --install \"cmdline-tools;latest\""
		echo "Once installed, ensure the cmdline-tools are located at: $ANDROID_HOME/cmdline-tools/latest/bin"
	fi
fi
