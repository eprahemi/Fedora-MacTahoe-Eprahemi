# Fedora MacTahoe — Eprahemi Edition

Complete Fedora desktop transformation — macOS-style theme, icons, sounds, fonts, extensions, and apps. Fully offline — no external downloads during install (except MacTahoe GTK repo for GDM theming).

## One-click Install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh)"
```

## What You Get

| Category | Details |
|---|---|
| **GTK Theme** | MacTahoe-Dark-Eprahemi (gnome-shell, gtk-3.0, gtk-4.0, metacity, cinnamon, plank) |
| **Icons** | MacTahoe-dark-Eprahemi (28K symlinks, 1624+ status icons), MacTahoe-Eprahemi base |
| **Custom Icons** | 21 macOS-style app PNGs (Discord, Chrome, Spotify, VS Code, etc.) |
| **Fonts** | SF Pro Display |
| **Sounds** | macOS Big Sur (46 system sounds) |
| **Desktop Entries** | 38 macOS-style app renames |
| **GDM Login** | Themed with wallpaper (via MacTahoe tweaks.sh) |
| **Wallpapers** | Pre-blurred desktop + login screen |
| **Terminal** | Kitty (renamed to "Terminal" in app grid) |
| **Shell** | Fish with custom functions, starship prompt |
| **Configs** | Kitty, fish, starship, GTK 3.0/4.0, fastfetch |
| **Extensions** | 14 GNOME Shell extensions with full dconf settings |
| **Apps** | Chrome, Edge, VS Code, Spotify, Discord, Obsidian, Proton VPN, VLC, Kdenlive, HandBrake, Celluloid, and more |
| **Keybindings** | Super+T → kitty, Super+E → nautilus, Ctrl+Shift+Esc → system-monitor, Ctrl+Alt+V → pavucontrol |

## Requirements

- Fedora 41+ (tested on Fedora 44, GNOME Shell 50)
- Normal user with sudo access (no root)
- Internet connection (first run only — downloads RPMs, flatpaks, extensions)

## Manual Install

If you already cloned the repo:

```bash
cd Fedora-MacTahoe-Eprahemi
bash install.sh
```

## Notes

- All theme names include "Eprahemi" suffix (e.g., MacTahoe-Dark-Eprahemi) to avoid conflicts with upstream themes
- Backward-compatible symlinks are NOT created by this script — designed for fresh installs
- The bundle is 233MB, ~4000 files tracked in git. Large icon PNG directories are gitignored
- GDM theming clones [vinceliuice/MacTahoe-gtk-theme](https://github.com/vinceliuice/MacTahoe-gtk-theme) for `tweaks.sh`
