# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal terminal setup for Ubuntu/Linux (bash/zsh scripts + config files) that installs Powerline
fonts, Oh My Zsh, and a customized Agnoster theme with a GNOME Terminal color profile. There is no
build system, package manager, linter, or test suite — this repo is a set of installer shell scripts
plus the dotfiles/config assets they copy into place. Scripts target Ubuntu 26.04.1 LTS.

## Running the installers

There's no single entrypoint; the three top-level scripts are meant to be run in order from the repo
root (each does `sudo apt-get install` / copies files into `$HOME`, so they mutate the local machine):

```bash
./install_powerline.sh   # Powerline fonts + VIM Powerline config (installs configs/.vimrc to ~/.vimrc)
./install_terminal.sh    # Installs ZSH + Oh My Zsh (unattended: RUNZSH=no CHSH=no)
./install_profile.sh     # Installs zsh plugins, theme, .zshrc, dconf terminal profile; switches default shell to zsh
```

`fonts/install.sh` is a standalone, more portable font-installer (handles both macOS `~/Library/Fonts`
and Linux `~/.local/share/fonts`) that `install_powerline.sh` delegates to directly (no argument, so it
copies every patched font under `fonts/`) instead of duplicating the copy/`fc-cache` logic.

All three top-level scripts use `#!/usr/bin/env bash` + `set -euo pipefail`, so they print every
command before running it and abort on the first failure. None of them use `sudo` to write into the
invoking user's `$HOME` (that would leave root-owned dotfiles behind) — `sudo` is reserved for
`apt-get` and `chsh`.

## Ubuntu-version-sensitive details

These are things that broke (or would break) on current Ubuntu vs. the Ubuntu 20 the scripts were
originally written for — keep them in mind if bumping the target OS again:

- `pip3 install --user powerline-status` needs `--break-system-packages` on Ubuntu 23.04+ (PEP 668
  "externally-managed-environment"); `install_powerline.sh` already passes it.
- `configs/.vimrc` no longer hardcodes a `python3.8` path for the Powerline vim binding — it globs
  `~/.local/lib/python3*/site-packages/...` so it keeps working as Ubuntu's default Python 3 version
  changes across releases.
- Oh My Zsh's installer now lives at `ohmyzsh/ohmyzsh` on GitHub, not `robbyrussell/oh-my-zsh`
  (`raw.github.com` no longer redirects reliably); `install_terminal.sh` uses the current URL and runs
  it with `RUNZSH=no CHSH=no` so it doesn't drop into an interactive shell mid-script.
- `neofetch` (README "Notes" section) was dropped from Debian/Ubuntu's repositories after the upstream
  project was archived; the README now points at `fastfetch` instead, whose color flags are not a
  drop-in match for neofetch's.
- `install_profile.sh` now installs `gnome-terminal dconf-cli` itself before touching the terminal's
  dconf schema, since a fresh Ubuntu desktop image isn't guaranteed to have both preinstalled.

## Architecture / how the pieces fit together

- `configs/.zshrc` sets `ZSH_THEME="pixegami-agnoster"` — this only works after `install_profile.sh`
  copies `configs/pixegami-agnoster.zsh-theme` into `~/.oh-my-zsh/themes/`. The theme file and the
  zshrc are coupled; changing the theme name in one requires updating the other.
- `configs/terminal_profile.dconf` is loaded into a **hardcoded GNOME Terminal profile UUID**
  (`fb358fc9-49ea-4252-ad34-1d25c649e633`) by `install_profile.sh`, which then registers that same
  UUID in the terminal's profile list and sets it as default via `dconf write`. If you regenerate the
  dconf dump (see README "Notes" section: `dconf dump /org/gnome/terminal/legacy/profiles:/ > ...`),
  the UUID embedded in the dumped file and the UUID hardcoded in `install_profile.sh` must match.
- `install_profile.sh` clones `zsh-syntax-highlighting` and `zsh-autosuggestions` into
  `~/.oh-my-zsh/custom/plugins`, but only if each folder isn't already there, so re-running the script
  is safe.
- macOS is not really supported yet: the README notes the terminal commands differ and macOS users
  need to manually adapt the `.sh` files. Only `fonts/install.sh` has explicit macOS (`Darwin`) handling.

## Key hardcoded values to keep in sync when editing

- GNOME profile UUID `fb358fc9-49ea-4252-ad34-1d25c649e633` — appears in both `install_profile.sh`
  and `configs/terminal_profile.dconf`.
- `ZSH_THEME="pixegami-agnoster"` in `configs/.zshrc` — must match the filename copied in
  `install_profile.sh` (`pixegami-agnoster.zsh-theme`).
