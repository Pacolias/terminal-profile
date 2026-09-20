#!/usr/bin/env bash

# Fail on any command.
set -euo pipefail

# GNOME Terminal and its dconf CLI aren't guaranteed to be preinstalled on a
# fresh Ubuntu 26.04.1 LTS desktop image, so make sure both are present
# before touching their dconf schema below.
sudo apt-get update
sudo apt-get install -y gnome-terminal dconf-cli

# Install plug-ins (skip re-cloning if they're already there, e.g. if you
# run this script again; you can git-pull inside each folder to update them).
plugins_dir=~/.oh-my-zsh/custom/plugins
if [ ! -d "$plugins_dir/zsh-syntax-highlighting" ]; then
	git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugins_dir/zsh-syntax-highlighting"
fi
if [ ! -d "$plugins_dir/zsh-autosuggestions" ]; then
	git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
fi

# Replace the configs with the saved one.
# (no sudo: this must be owned by the invoking user, not root)
cp configs/.zshrc ~/.zshrc

# Copy the modified Agnoster Theme
cp configs/pixegami-agnoster.zsh-theme ~/.oh-my-zsh/themes/pixegami-agnoster.zsh-theme

# Color Theme
profile_id=fb358fc9-49ea-4252-ad34-1d25c649e633
dconf load "/org/gnome/terminal/legacy/profiles:/:$profile_id/" < configs/terminal_profile.dconf

# Add it to the default list in the terminal
old_list=$(dconf read /org/gnome/terminal/legacy/profiles:/list | tr -d "]")

if [ -z "$old_list" ]
then
	front_list="["
else
	front_list="$old_list, "
fi

new_list="$front_list'$profile_id']"
dconf write /org/gnome/terminal/legacy/profiles:/list "$new_list"
dconf write /org/gnome/terminal/legacy/profiles:/default "'$profile_id'"

# Switch the shell.
chsh -s "$(which zsh)"
