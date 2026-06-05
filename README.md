# 🍎 Fedora MacTahoe — Eprahemi Edition

Make your Fedora look like a Mac — the fun way. GTK theme, icon themes, SF Pro font,
Big Sur sounds, GNOME extensions, custom keybindings, a terminal that actually looks
good, and a pre-configured dev environment — all in one portable bundle.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh)"
```

> [!WARNING]
> Built for **Fedora Linux with GNOME**. Uses `dnf`, RPM Fusion, GNOME Shell APIs, and
> systemd stuff that doesn't exist on Debian, Arch, Ubuntu, or non-GNOME desktops.
> **It won't work there.** Don't try.

---

## What You Get

| Category | Details |
|---|---|
| **GTK Theme** | MacTahoe-Dark — compiled fresh for your GNOME version |
| **Icon Themes** | MacTahoe (light), MacTahoe-dark (dark) |
| **Custom Icons** | 25+ macOS-style app icons (native + Flatpak aliases) |
| **Font** | SF Pro Display |
| **Sounds** | macOS Big Sur — 45 system event sounds |
| **Terminal** | Kitty — default, maximized on launch, GPU-accelerated |
| **Shell** | Fish — 17 custom functions + Starship prompt |
| **Extensions** | 14 GNOME Shell extensions (Blur My Shell, Dash2Dock Lite, Coverflow Alt+Tab, and more) |
| **GDM** | Themed login screen + Fedora logo hidden via dconf override |
| **Flatpak** | org.gtk.Gtk3theme.MacTahoe-Dark runtime built automatically |
| **Wallpapers** | 31 custom wallpapers installed, all stock Fedora/GNOME backgrounds wiped |
| **Avatars** | 16 custom profile pictures (512×512), all stock avatars replaced |
| **Media** | Bonus videos silently copied to `~/Downloads/` |
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

The script walks through **22 steps** — everything from RPM Fusion + codecs to NVIDIA
drivers (auto-detected), apps, theme compilation, wallpaper/avatar replacement, GNOME config, extensions, and shell
setup. It pauses with clear prompts at key points, so nothing happens
without you saying "go."

### Terminal notes

- **Kitty** is the recommended terminal — GPU rendering, true colors, blur,
  and a tab bar that actually belongs. The installer recommends it but
  doesn't force it.
- **Ptyxis** is blocked — the installer removes it. Run from Kitty or any
  other terminal (GNOME Terminal, Alacritty, etc.) and you're fine.
- Works from **bash, fish, zsh** — just run `bash install.sh` or the one-liner.
  The shebang is `#!/usr/bin/env bash`, no assumptions about your interactive shell.

### Post-Install — Firefox

Firefox can't be themed headless. After first login:

1. Launch Firefox once to create a profile
2. Re-run `bash install.sh` — the Firefox macOS theme step will complete

## Idempotency

Safe to re-run whenever you want. Each step handles existing state:

- Already-installed packages get skipped
- Theme directories get purged and rebuilt
- Stock wallpapers + stock XML definitions get wiped every run, replaced with custom set
- Stock avatars get wiped every run, replaced with 16 custom 512×512 faces
- GNOME settings get re-applied
- Fish shell is detected and left alone if it's already your default

## Portability

Every path and username is dynamic. Works on any Fedora machine, any username —
zero hardcoded `/home/` or hardcoded user names in sight.

## License

Free and open source. Use it, copy it, modify it, share it — just keep the
original copyright notice around.

## Copyright

© 2026 Eprahemi. Made on Fedora, for Fedora.
