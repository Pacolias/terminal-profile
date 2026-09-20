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
`apt-get` and `chsh`. Each script also refuses to run as root/`sudo` itself (`id -u -eq 0` guard) since
that would resolve `~`/`$HOME` to `/root` instead of the real user, and `install_profile.sh` additionally
requires a real D-Bus session (`DBUS_SESSION_BUS_ADDRESS`/`XDG_RUNTIME_DIR`) since its `dconf`
calls need the GNOME desktop session's bus — running it as root or over SSH fails with
`Failed to execute child process "dbus-launch"`.

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
  project was archived; the README now points at `fastfetch` instead, themed via
  `configs/fastfetch-config.jsonc` (see below) rather than neofetch's `--ascii_colors`/`--colors` flags.
- **Ubuntu 26.04.1 ships [Ptyxis](https://gitlab.gnome.org/chergert/ptyxis) as the default terminal
  app, not GNOME Terminal** — confirmed by actually testing on Ubuntu 26.04.1 ("resolute" in apt), where
  the foreground process of the terminal window is `ptyxis-agent` even though `gnome-terminal` was also
  installed and configured correctly. GNOME Terminal's dconf schema has zero effect on Ptyxis. See
  "Ptyxis theming" below for how `install_profile.sh` now handles this.
- `install_profile.sh` installs `dconf-cli` (for GNOME Terminal's `dconf`) and `libglib2.0-bin` (for
  Ptyxis's `gsettings`) itself, since a fresh Ubuntu desktop image isn't guaranteed to have either. It
  no longer force-installs `gnome-terminal` — Ptyxis is what's actually present by default now.

## Ptyxis theming (reverse-engineered, undocumented)

Ptyxis has no per-profile raw-RGB color keys like GNOME Terminal (`gsettings list-keys
org.gnome.Ptyxis.Profile` has no `background-color`/`foreground-color`). Instead each profile has a
single `palette` string key naming a palette, resolved either from ~200 palettes bundled as GResources
inside the `ptyxis` binary itself (`gresource list /usr/bin/ptyxis`, no separate `.gresource` file) or
from user-imported ones.

- **Custom palette format**: an INI/keyfile with a `[Palette]` section (`Name=...` required) and one or
  both of `[Light]`/`[Dark]` sections, each with `Foreground`, `Background`, `Cursor`, `Color0`..`Color15`
  as `#RRGGBB` hex. `configs/Pixegami.palette` is ours, adapted from the original
  `configs/terminal_profile.dconf` colors, with the *same* colors in both `[Light]` and `[Dark]` so it
  looks identical regardless of `gsettings get org.gnome.Ptyxis interface-style`.
- **Both sections are apparently required**: every bundled palette we inspected (including
  single-tone ones like `dracula.palette`) ships both `[Light]` and `[Dark]`; a hand-tested palette with
  only `[Dark]` didn't show up in Preferences' palette picker at all (even under "Show All Palettes"),
  though the underlying `palette` GSettings key still accepted the string silently.
- **Import via `ptyxis --import-palette <file>` only** — this is the one documented, working way to
  register a custom palette (copies it to `~/.local/share/org.gnome.Ptyxis/palettes/`). It **refuses to
  overwrite** an existing file of the same name ("already exists. Please remove it first."), and
  **hand-editing the copy in `~/.local/share/org.gnome.Ptyxis/palettes/` gets silently reverted** back to
  what was last imported the next time Ptyxis restarts (observed directly: added a `[Light]` section by
  hand, restarted Ptyxis, the file was back to `[Dark]`-only). So `install_profile.sh` always does
  `rm -f` the existing copy, then re-imports fresh — never edits in place.
- **Selecting it**: `uuid=$(gsettings get org.gnome.Ptyxis default-profile-uuid | tr -d "'")` then
  `gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/$uuid/" palette 'Pixegami'` (the
  palette's `Name=` value is also its id for lookup purposes). Ptyxis applies this live via a
  `notify::palette` binding — no new window/restart needed, unlike GNOME Terminal.
- `dpkg -L ptyxis` lists no loose `.palette`/`.gresource` files — everything bundled is compiled
  directly into the ELF binary; `gresource list /usr/bin/ptyxis` / `gresource extract` work on it
  directly since GResource supports introspecting resources embedded in any binary, not just standalone
  `.gresource` files.

## fastfetch theming

`configs/fastfetch-config.jsonc` (copy to `~/.config/fastfetch/config.jsonc`) is the equivalent of the
old `neofetch --ascii_colors 6 7 --colors 2 2 2 2` invocation, adapted to fastfetch's JSON config
(`logo.color."1".."9"` for the ASCII logo, `display.color.keys`/`display.color.title` for text —
[schema](https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json), color syntax
incl. `#RRGGBB` hex documented at the
[Color Format Specification wiki page](https://github.com/fastfetch-cli/fastfetch/wiki/Color-Format-Specification)).
Colors were picked directly from `configs/Pixegami.palette`'s ANSI slots for consistency, not from the
original neofetch ANSI indices 6/7/2 — those indices pointed at *different* actual colors under the old
custom GNOME Terminal palette (index 6 was a teal `#16A085`, not literal cyan; index 7 was light gray
`#BDC3C7`, not white) than what their names suggest, which is why matching the reference screenshot
required picking the palette's real hex values rather than passing `--color cyan` style names.

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
- `Name=Pixegami` in `configs/Pixegami.palette` — must match the literal `'Pixegami'` string
  `install_profile.sh` passes to `gsettings set ... palette`, and the filename must keep its
  `.palette` suffix (Ptyxis's importer rejects anything else).
