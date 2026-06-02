# Fedora MacTahoe — Eprahemi Edition

A complete, automated Fedora desktop transformation. macOS-style GTK theme, icon themes,
SF Pro font, Big Sur sounds, GNOME extensions, custom keybindings, and a pre-configured
development environment — all in one portable bundle.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh)"
```

> [!WARNING]
> This installer is purpose-built for **Fedora Linux with the GNOME desktop environment**. It relies on Fedora-specific package managers (`dnf`, RPM Fusion), GNOME Shell extension APIs, and systemd integration points that are not present on other distributions or desktop environments. **It will not function correctly on Debian, Arch, Ubuntu, or any non-GNOME desktop.**

---

## Features

| Category | Details |
|---|---|
| **GTK Theme** | MacTahoe-Dark — compiled from upstream source for your GNOME version |
| **Icon Themes** | MacTahoe (light, 143 MB), MacTahoe-dark (dark, 76 MB) |
| **Custom Icons** | 21 macOS-style application icons (native + Flatpak aliases) |
| **Font** | SF Pro Display |
| **Sounds** | macOS Big Sur (45 system event sounds) |
| **Terminal** | Kitty — set as default, always opens maximized |
| **Shell** | Fish — with 17 custom functions and Starship prompt |
| **Extensions** | 14 GNOME Shell extensions (Blur My Shell, Dash2Dock Lite, Coverflow Alt+Tab, and more) |
| **GDM** | Themed login screen with custom wallpaper |
| **Flatpak** | org.gtk.Gtk3theme.MacTahoe-Dark runtime built automatically |
| **Keybindings** | Super+T → kitty · Super+E → nautilus · Ctrl+Shift+Esc → system monitor · Ctrl+Alt+V → volume control · Super+1-9 → workspace switch |
| **Apps** | Firefox, Chrome, Edge, VS Code, Spotify, Discord, Obsidian, Proton VPN, VLC, Kdenlive, HandBrake, Celluloid, LibreOffice, and more |

## Requirements

- **Fedora 41+** (tested on Fedora 44, GNOME Shell 50)
- **GNOME desktop environment**
- A normal user account with sudo access
- An active internet connection

## Installation

**One-liner (recommended):**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh)"
```

**Manual:**

```bash
git clone https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git
cd Fedora-MacTahoe-Eprahemi
bash install.sh
```

The script walks through 21 steps and handles everything: RPM Fusion, multimedia codecs,
NVIDIA drivers (auto-detected), RPM and Flatpak applications, theme compilation, GNOME
configuration, extensions, and shell setup.

### Post-Install — Firefox

Firefox cannot be themed headless. After first login:

1. Launch Firefox once to create a profile
2. Re-run `bash install.sh` — the Firefox macOS theme step will complete

## Idempotency

The script is safe to re-run. Each step handles existing state gracefully:
- Already-installed packages are skipped
- Theme directories are purged and rebuilt
- GNOME settings are re-applied
- Fish shell is detected and left unchanged if already active

## Portability

Every path and username is dynamic. The bundle works on any Fedora machine with any
username — no hardcoded `/home/` references, no hardcoded user names.

## License

This project is free and open source. You are permitted to use, copy, modify, merge,
publish, and distribute this software, in whole or in part, for any purpose, without
restriction, provided that the original copyright notice is included.

## Copyright

© 2026 Eprahemi. All rights reserved.
