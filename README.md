# Fedora MacTahoe — Eprahemi Edition

Complete Fedora desktop transformation — macOS-style GTK theme, icon themes, SF Pro font, Big Sur sounds, GNOME extensions, custom keybindings, and apps. Fully self-contained bundle — zero external asset downloads during install (except GDM theming).

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh)"
```

## What You Get

| Category | Details |
|---|---|
| **GTK Theme** | MacTahoe-Dark-Eprahemi (gnome-shell, gtk-3.0, gtk-4.0, metacity, cinnamon) |
| **Icon Themes** | MacTahoe-Eprahemi (base, 143MB), MacTahoe-dark-Eprahemi (dark variant, 76MB) |
| **Custom Icons** | 21 macOS-style app PNGs (Discord, Chrome, Spotify, VS Code, etc.) |
| **Font** | SF Pro Display |
| **Sounds** | macOS Big Sur (45 system sounds) |
| **Desktop Entries** | macOS-style app renames |
| **GDM Login** | Themed with wallpaper (via MacTahoe tweaks.sh) |
| **Wallpapers** | Desktop + login screen |
| **Terminal** | Kitty (set as default, replaces ptyxis) |
| **Shell** | Fish with custom functions + starship prompt |
| **Configs** | Kitty, fish, starship, GTK 3.0/4.0, fastfetch |
| **Extensions** | 14 GNOME Shell extensions with full dconf settings |
| **Apps** | Chrome, Edge, VS Code, Spotify, Discord, Obsidian, Proton VPN, VLC, Kdenlive, HandBrake, Celluloid, Flatseal, Gear Lever, Extension Manager, Mousam, ZapZap |
| **Keybindings** | Super+T → kitty, Super+E → nautilus, Ctrl+Shift+Esc → system-monitor, Ctrl+Alt+V → pavucontrol, Super+1-9 → workspace switch |

## Repository

- **48,146 files** tracked across 11 commits
- **147MB** on disk (icons, themes, configs, sounds, fonts)
- **No git-lfs required** — all files under 100MB each

## Requirements

- Fedora 41+ (tested on Fedora 44, GNOME Shell 50)
- Normal user with sudo access (do NOT run as root)
- Internet connection (first run — downloads RPMs, flatpaks, extensions)

## Manual Install

```bash
git clone https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git
cd Fedora-MacTahoe-Eprahemi
bash install.sh
```

## Changelog

### `3963a3b` — fix: testdrive basename crash
- `df` failed on nonexistent benchmark file → `$dev_name` was empty
- `basename ""` errored → showed usage message
- **Fix:** `touch $test_file` before `df`, capture `basename` to variable with `2>/dev/null`

### `416bc17` — feat: dynamic username (portable to any machine)
- `fastfetch/config.jsonc` used hardcoded `/home/eprahemi/...` path
- `fish_greeting.fish` had `figlet "eprahemi"` hardcoded
- `config.fish` had `/home/eprahemi/.opencode/bin`
- `refresh.fish` had hardcoded `/home/eprahemi/...` paths
- `testdrive.fish` had `eprahemi_test_bin` + `USER: EPRAHEMI`
- **Fix:** all paths use `$HOME`, usernames use `(whoami)` / `$USER`
- `PLACEHOLDER_USER_HOME` in config.jsonc → `sed`-substituted at install time

### `dbe6520` — fix: settings.ini re-apply + fc-cache protection
- GNOME settings daemon overwrites `settings.ini` after gsettings changes
- Flatpak apps couldn't see theme (no gtk-theme-name in settings.ini)
- `fc-cache -fv 2>/dev/null` was unprotected under `set -e`
- **Fix:** re-copy settings.ini after `apply_dconf` step; add `|| true` to fc-cache

### `c92d259` — fix: include all 44K icon theme files
- `.gitignore` excluded `actions/`, `status/`, `apps/`, `categories/`, `devices/`, `emblems/`, `mimes/`, `places/`, `animations/`, `emotes/`, `preferences/` for both icon themes
- GitHub had only 8MB of empty symlink shells — icons didn't work
- **Fix:** removed all icon `.gitignore` entries, tracked 44,004 new files

### `25c3605` — fix: `cp -a` for icon themes (preserves @2x symlinks)
- `cp -r` broke @2x retina symlinks in icon themes
- **Fix:** use `cp -a` instead of `cp -r`

### `d8a1d25` — fix: icon theme dead symlinks + cursor.theme name
- `cp -rL` broke dark-theme symlinks to base theme
- `cursor.theme` had wrong `Inherits` reference
- **Fix:** use `cp -a`, correct cursor.theme

### `096b2c8` — fix: bootstrap always fresh clone
- Bootstrap used cached clone — stale data on re-run
- **Fix:** `rm -rf` cache dir before each clone

### `19df969` — fix: sudo for system theme purge
- `rm -rf /usr/share/themes/MacTahoe-*` failed without sudo
- **Fix:** use `sudo rm -rf`

### `99ac59c` — fix: purge upstream, fix index.theme refs
- Upstream MacTahoe-Dark conflicted with Eprahemi variant
- Theme names in index.theme didn't include "Eprahemi" suffix
- **Fix:** purge upstream themes, rename all theme names

### `434306e` — hotfix: 34 broken `2>/dev/null` redirects
- All `2>/dev/null` were missing the `>` character (written as `2/dev/null`)
- **Fix:** correct all redirects

### `42cba37` — fix: guard ALL gsettings/dconf/ln with `|| true`
- `set -euo pipefail` aborted on first failure
- gsettings/dconf/ln commands fail on first run (no schema loaded)
- **Fix:** append `2>/dev/null || true` to all 82+ commands
