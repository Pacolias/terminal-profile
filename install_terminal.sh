#!/usr/bin/env bash

# Fail on any command.
set -euo pipefail

# Install ZSH
sudo apt-get update
sudo apt-get install -y git zsh curl

# Install Oh My Zsh, unattended:
# - RUNZSH=no  stops the installer from dropping you into a new zsh shell,
#              which would otherwise pause this script until you exit it.
# - CHSH=no    skips the installer's own shell change; install_profile.sh
#              does that once the theme/plugins are in place.
# The upstream project moved from robbyrussell/oh-my-zsh to ohmyzsh/ohmyzsh
# (raw.github.com no longer redirects reliably), so this uses the current URL.
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
