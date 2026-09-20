#!/usr/bin/env bash

# Fail on any command.
set -euo pipefail

# Install Powerline for VIM.
sudo apt-get update
sudo apt-get install -y python3-pip fonts-powerline

# Ubuntu 23.04+ (and therefore 26.04) refuses unmanaged `pip install` calls
# (PEP 668 "externally-managed-environment"). --break-system-packages opts
# this user-level install back in, matching the old pre-23.04 behaviour.
pip3 install --user --break-system-packages powerline-status

# Copy into the invoking user's home directory (no sudo: that would create
# root-owned dotfiles under $HOME that the user can no longer edit/delete).
cp configs/.vimrc ~/.vimrc

# Install the patched Powerline font. Delegates to fonts/install.sh, which
# installs to the XDG-standard ~/.local/share/fonts on Linux.
script_dir="$(cd "$(dirname "$0")" && pwd)"
"$script_dir/fonts/install.sh"
