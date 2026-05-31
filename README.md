# Fedora MacTahoe — Eprahemi Edition

Complete Fedora desktop transformation — macOS-style GTK theme, icon themes, SF Pro font, Big Sur sounds, GNOME extensions, custom keybindings, and apps. Fully self-contained bundle.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh)"
```

## What You Get

| Category | Details |
|---|---|
| **GTK Theme** | MacTahoe-Dark-Eprahemi (gnome-shell, gtk-3.0, gtk-4.0, metacity, cinnamon) |
| **Icon Themes** | MacTahoe-Eprahemi (base, 143MB), MacTahoe-dark-Eprahemi (dark variant, 76MB) |
| **Custom Icons** | 21 macOS-style app PNGs |
| **Font** | SF Pro Display |
| **Sounds** | macOS Big Sur (45 system sounds) |
| **Terminal** | Kitty (default, replaces ptyxis) |
| **Shell** | Fish (default) with 17 custom functions + starship prompt |
| **Extensions** | 14 GNOME Shell extensions (Blur My Shell, Dash2Dock Lite, Coverflow Alt+Tab, etc.) |
| **Apps** | Chrome, Edge, VS Code, Spotify, Discord, Obsidian, Proton VPN, VLC, Kdenlive, HandBrake, Celluloid, and more |
| **Keybindings** | Super+T → kitty, Super+E → nautilus, Ctrl+Shift+Esc → system-monitor, Ctrl+Alt+V → pavucontrol, Super+1-9 → workspace switch |

## Requirements

- Fedora 41+ (tested on Fedora 44, GNOME Shell 50)
- Normal user with sudo access
- Internet connection

## Manual Install

```bash
git clone https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git
cd Fedora-MacTahoe-Eprahemi
bash install.sh
```

## Repository

- **48,146 files**, 147MB
- No git-lfs required
- Dynamic username — works on any machine
