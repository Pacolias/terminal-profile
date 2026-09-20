# Pixegami Terminal Profile

![terminal](./terminal_screenshot.png)

This is my profile for UNIX (MacOS/Linux) terminals. For Ubuntu, I just use the default terminal
app. For MacOS, I use [iTerm2](https://iterm2.com/).

> In the MacOS case, I have successfully installed this theme once before, but most of the terminal commands
> will be different. You'll just have to open the `.sh` files and figure out how to adapt it to MacOS
> until I can prepare MacOS commands.

These commands target Ubuntu 26.04.1 LTS (GNOME desktop). They were originally written for
Ubuntu 20 back in May 2022 and have since been updated for changes in newer Ubuntu releases:
Debian/Ubuntu now refuses unmanaged `pip install` calls (PEP 668), the Oh My Zsh installer moved
to a new URL, and `neofetch` (mentioned below) is no longer packaged.

# Prerequisites

For the scripts to work, I think these are the bare minimum requirements.

```bash
# Update your software repositories.
sudo apt-get update
sudo apt-get upgrade

# Install Git.
sudo apt-get install -y git

# Install Vim.
sudo apt-get install -y vim
```

# Installation

### Powerline (and fonts)

First, we'll install the font (RobotoMono for Powerline). I'll also install it into VIM, since that
is my built-in editor of choice (but you don't have to use it).

The Powerline fonts also include special characters (like Git branches) that we will use later in
the terminal profile theme.

```bash
./install_powerline.sh
```

> Since Ubuntu 23.04, `pip install` refuses to touch system-managed Python packages unless you pass
> `--break-system-packages` (this script already does that for you). If you ever run the
> `powerline-status` install by hand, you'll need to add that flag too.

### ZSH, OhMyZSH and Plugins

The shell that I use is "ZSH", with the OhMyZSH upgrade on top of that. To install all of that stuff,
you can run the helper script (and may need to restart after).

```bash
./install_terminal.sh
```

After this, the terminal should look a bit different, but we need to do the next step to have the
entire theme.

### Profile (plugins, theme, font and color)

This script will first make sure GNOME Terminal and `dconf-cli` are installed (not guaranteed on a
fresh Ubuntu 26.04.1 desktop), then install two plugins that I like to use: auto-complete and color
highlighting (it skips the clone if a plugin folder is already there, so it's safe to re-run).

```bash
# You don't need to execute this - it's part of the script already.
(cd ~/.oh-my-zsh/custom/plugins && git clone https://github.com/zsh-users/zsh-syntax-highlighting)
(cd ~/.oh-my-zsh/custom/plugins && git clone https://github.com/zsh-users/zsh-autosuggestions)
```

It will also copy over the `.zshrc` and `pixegami-agnoster.zsh-theme` files for the
terminal to use (which will wire up the plugins and the theme).

The last command is to create a terminal profile that will set the colors and also set the font
to be the Powerline one we installed earlier (required for the theme to display correctly).

```bash
./install_profile.sh
```

> You can also change the font to any of the other [Powerline Patched Fonts](https://github.com/powerline/fonts) too if you don't like RobotoMono.

If it looks funky after this command, then you might need to wait until the theme is updated with a
Powerline font (the next step), and may need to also restart your machine.

> **Important:** run all three scripts as yourself, never with `sudo ./install_*.sh` in front. Each
> script already calls `sudo` internally wherever it actually needs root (the `apt-get` installs) and
> will prompt for your password at that point — that's expected. Running the whole script as root
> instead makes `~`/`$HOME` resolve to `/root`, so Oh My Zsh, the plugins, `.zshrc` and this terminal
> profile all get installed for the `root` account instead of you, and `install_profile.sh`'s `dconf`
> step will fail outright with `Failed to execute child process "dbus-launch"` (root has no graphical
> D-Bus session to talk to). The scripts refuse to run as root for this reason. Also make sure you run
> `install_profile.sh` from a terminal opened inside your actual GNOME desktop session (not over SSH or
> from a bare TTY), since `dconf` needs that session's D-Bus bus.
>
> After `install_profile.sh` finishes, close every open terminal window and open a brand-new one — an
> already-open window keeps whatever profile it started with.

## Notes

How to dump current terminal profiles.

```bash
dconf dump /org/gnome/terminal/legacy/profiles:/ > gnome-terminal-profiles.dconf
```

How to display terminal information. I used to use [Neofetch](https://github.com/dylanaraps/neofetch),
but that project is unmaintained and was dropped from Ubuntu's repositories, so this now uses its
actively-maintained replacement, [fastfetch](https://github.com/fastfetch-cli/fastfetch).

```bash
sudo apt-get install fastfetch

# Display the profile.
# fastfetch's color flags aren't a 1:1 match for neofetch's; run
# `fastfetch --help color` to see the current options for recoloring the logo.
fastfetch
```

## How do I reset the changes back to the old terminal?

There's two main modifications being done to the terminal. The terminal theme, and the shell itself.

For the theme, here's a thread I found on the internet on how to reset it to the default: https://askubuntu.com/questions/14487/how-to-reset-the-terminal-properties-and-preferences

For the terminal shell itself, we actually installed a new terminal (zsh) alongside the default bash. Bash itself wasn't removed, but we just set the default shell to `zsh`. Here is a thread on how to uninstall zsh and default back to bash: https://askubuntu.com/questions/958120/remove-zsh-from-ubuntu-16-04

## Sources

Here are some of the main resources I used as part of this terminal setup.

[Oh My Zsh!](https://medium.com/wearetheledger/oh-my-zsh-made-for-cli-lovers-installation-guide-3131ca5491fb) | [Oh My Zsh (ohmyzsh/ohmyzsh)](https://github.com/ohmyzsh/ohmyzsh) | [Install Powerline](https://askubuntu.com/questions/283908/how-can-i-install-and-use-powerline-plugin) | [Powerline Patched Fonts](https://github.com/powerline/fonts)
| [Agnoster Theme](https://gist.github.com/3712874)

