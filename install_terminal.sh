#!/usr/bin/env bash

# Fail on any command.
set -euo pipefail

# Run as yourself, not via sudo/root: this installs Oh My Zsh into `~`, which
# must be your real home directory, not /root. The apt-get call below already
# uses sudo internally and will prompt for your password when it needs it.
if [ "$(id -u)" -eq 0 ]; then
	echo "error: do not run this script with sudo/as root." >&2
	echo "       run it as yourself, e.g.: ./install_terminal.sh" >&2
	exit 1
fi

# Install ZSH
sudo apt-get update
sudo apt-get install -y git zsh curl

# Install Oh My Zsh, unless it's already there (its installer refuses to run
# again over an existing ~/.oh-my-zsh, so re-running this script would
# otherwise fail with a confusing "$ZSH folder already exists" message).
if [ -d ~/.oh-my-zsh ]; then
	echo "Oh My Zsh is already installed at ~/.oh-my-zsh, skipping installer."
else
	# Unattended:
	# - RUNZSH=no  stops the installer from dropping you into a new zsh shell,
	#              which would otherwise pause this script until you exit it.
	# - CHSH=no    skips the installer's own shell change; install_profile.sh
	#              does that once the theme/plugins are in place.
	# The upstream project moved from robbyrussell/oh-my-zsh to ohmyzsh/ohmyzsh
	# (raw.github.com no longer redirects reliably), so this uses the current URL.
	RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
