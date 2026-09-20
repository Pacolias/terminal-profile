#!/usr/bin/env bash

# Fail on any command.
set -euo pipefail

# This script must run as your normal desktop user, NOT via sudo/root:
# - `~`/$HOME below need to point at *your* home directory, not /root.
# - dconf/gsettings need your graphical session's D-Bus session bus; root has
#   none, so dconf tries to spawn one via `dbus-launch`, which recent Ubuntu
#   no longer ships by default, and dies with "Failed to execute child
#   process dbus-launch". (The apt-get calls below still use sudo internally
#   and will prompt for your password when they need it.)
if [ "$(id -u)" -eq 0 ]; then
	echo "error: do not run this script with sudo/as root." >&2
	echo "       run it as yourself, e.g.: ./install_profile.sh" >&2
	exit 1
fi

# dconf/gsettings also need an active D-Bus session bus (i.e. you're in a
# real GNOME desktop session, not a bare TTY or an SSH shell with no session
# forwarded).
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -z "${XDG_RUNTIME_DIR:-}" ]; then
	echo "error: no D-Bus session bus detected (DBUS_SESSION_BUS_ADDRESS/XDG_RUNTIME_DIR unset)." >&2
	echo "       run this from a terminal opened inside your actual GNOME desktop session." >&2
	exit 1
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"

# dconf-cli gives us `dconf` (GNOME Terminal); libglib2.0-bin gives us
# `gsettings` (Ptyxis, the default terminal on Ubuntu 26.04.1 - see
# CLAUDE.md). Installing gnome-terminal itself is no longer forced here:
# Ubuntu 26.04.1 ships Ptyxis by default, and `gnome-terminal` may not even
# be installed. Whichever of the two is actually present gets configured
# below.
sudo apt-get update
sudo apt-get install -y dconf-cli libglib2.0-bin

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
cp "$script_dir/configs/.zshrc" ~/.zshrc

# Copy the modified Agnoster Theme
cp "$script_dir/configs/pixegami-agnoster.zsh-theme" ~/.oh-my-zsh/themes/pixegami-agnoster.zsh-theme

# --- Ptyxis: the default terminal on Ubuntu 26.04.1 ---
# Ptyxis doesn't take raw RGB per profile like GNOME Terminal; it picks a
# named/imported "palette" (a .palette keyfile with [Light] and [Dark]
# sections - `ptyxis --import-palette` is the only supported way to add
# one). It refuses to import over an existing file of the same name, and
# editing an already-imported file in place gets silently reverted, so we
# always remove any previous copy and reimport fresh instead.
if command -v ptyxis >/dev/null 2>&1; then
	echo "Configuring Ptyxis color palette..."
	rm -f ~/.local/share/org.gnome.Ptyxis/palettes/Pixegami.palette
	ptyxis --import-palette "$script_dir/configs/Pixegami.palette"

	ptyxis_uuid=$(gsettings get org.gnome.Ptyxis default-profile-uuid | tr -d "'")
	gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/$ptyxis_uuid/" palette 'Pixegami'
fi

# --- GNOME Terminal: kept as a fallback for setups that still use it ---
if command -v gnome-terminal >/dev/null 2>&1; then
	echo "Configuring GNOME Terminal color profile..."
	profile_id=fb358fc9-49ea-4252-ad34-1d25c649e633
	dconf load "/org/gnome/terminal/legacy/profiles:/:$profile_id/" < "$script_dir/configs/terminal_profile.dconf"

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
fi

# Switch the shell.
chsh -s "$(which zsh)"
