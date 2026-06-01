
<p align="center">
  <pre>
  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗
  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║
  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║
  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║
  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║
  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝
  </pre>
</p>

<h1 align="center">🍎 Fedora MacTahoe — Eprahemi Edition 🍎</h1>
<h3 align="center">Technical Architecture & Engineering Reference</h3>

<p align="center">
  <strong>Version:</strong> 1.0 &nbsp;·&nbsp;
  <strong>Script:</strong> 877 lines · 21 steps · Zero hardcoded paths &nbsp;·&nbsp;
  <strong>License:</strong> Open Source
</p>

---

<p align="center">
  <strong>Table of Contents</strong>
</p>

<p align="center">
  <a href="#1-architecture-overview">📐 Overview</a> ·
  <a href="#2-installation-flow">⚡ Flow</a> ·
  <a href="#3-theme-compilation-step-7">🎨 Theme</a> ·
  <a href="#4-custom-application-icons">🖼️ Icons</a> ·
  <a href="#5-fish-shell-functions">🐟 Shell</a> ·
  <a href="#6-gnome-extension-management-step-9">🧩 Extensions</a> ·
  <a href="#7-gnome-dconf-settings-step-12">⚙️ dconf</a> ·
  <a href="#8-firefox-theming-step-15">🦊 Firefox</a> ·
  <a href="#9-flatpak-gtk-runtime-step-16">📦 Flatpak</a> ·
  <a href="#10-maximized-window-wrappers-steps-18-19">🪟 Wrappers</a> ·
  <a href="#11-gdm-login-screen-step-14">🔐 GDM</a> ·
  <a href="#12-sound-theme-step-17">🔊 Sounds</a> ·
  <a href="#13-portability--idempotency">🧹 Portability</a> ·
  <a href="#14-file-structure">📁 Structure</a>
</p>

---

<a name="1-architecture-overview"></a>

## 1. 📐 Architecture Overview

> **What this project is:** A single `install.sh` script that transforms a stock Fedora
> Workstation into a polished macOS-inspired desktop environment. Every dependency is
> either bundled locally or pulled from authoritative upstream sources at install time.

### 🎯 Core Design Principles

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   🎯 Principle                 │  How It's Achieved                         │
│  ──────────────────────────────┼─────────────────────────────────────────── │
│   GNOME-version agnostic       │  Theme compiled from source per Shell ver  │
│   Portable to any user         │  Zero hardcoded paths/usernames — dynamic  │
│   Safe to re-run               │  Every step checks existing state first    │
│   Self-contained bundle        │  Icons, fonts, sounds, configs all local   │
│   No left-behind artifacts     │  All temp files/caches/builds cleaned      │
│   Headless-friendly            │  Firefox degrades gracefully w/o display   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🔗 Full Dependency Graph

```
┌═════════════════════════════════════════════════════════════════════════════┐
║                           BOOTSTRAP LAYER                                   ║
║  ┌──────────────────────────────────────────────────────────────────────┐  ║
║  │  bootstrap.sh                                                         │  ║
║  │  ┌────────────────────────────────────────────────────────────────┐  │  ║
║  │  │  curl -fsSL <url> | bash                                       │  │  ║
║  │  │  → git clone https://github.com/eprahemi/fedora-mactahoe.git   │  │  ║
║  │  │  → cd fedora-mactahoe && bash install.sh                       │  │  ║
║  │  └────────────────────────────────────────────────────────────────┘  │  ║
║  └──────────────────────────────────────────────────────────────────────┘  ║
╚═════════════════════════════════════════════════════════════════════════════╝
                                      │
                                      ▼
┌═════════════════════════════════════════════════════════════════════════════┐
║                            install.sh  (877 lines)                         ║
║                                                                             ║
║  ┌──────────────────────────────────────────────────────────────────────┐  ║
║  │  PHASE 1: SYSTEM PREPARATION (Steps 1-3)                             │  ║
║  │  ┌──────────────┐   ┌──────────────────┐   ┌─────────────────────┐  │  ║
║  │  │  🔍 Preflight │──▶│  📦 RPM Fusion   │──▶│  🎮 NVIDIA Drivers  │  │  ║
║  │  │   Checks      │   │  + Codecs        │   │  (auto-detect)     │  │  ║
║  │  └──────────────┘   └──────────────────┘   └─────────────────────┘  │  ║
║  └──────────────────────────────────────────────────────────────────────┘  ║
║                                      │                                      ║
║  ┌──────────────────────────────────────────────────────────────────────┐  ║
║  │  PHASE 2: PACKAGE INSTALLATION (Steps 4-6)                           │  ║
║  │  ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐  │  ║
║  │  │  📥 RPM Packages  │──▶│  🌐 Browsers     │──▶│  📱 Flatpak Apps │  │  ║
║  │  │  44+ tools        │   │  Firefox, Chrome │   │  Spotify, Discord│  │  ║
║  │  │  fish, kitty, vlc │   │  Edge, VS Code   │   │  Obsidian, …     │  │  ║
║  │  └──────────────────┘   └──────────────────┘   └──────────────────┘  │  ║
║  └──────────────────────────────────────────────────────────────────────┘  ║
║                                      │                                      ║
║  ┌──────────────────────────────────────────────────────────────────────┐  ║
║  │  PHASE 3: THEMING ENGINE (Steps 7-9)                                 │  ║
║  │  ┌──────────────────────┐   ┌────────────────┐   ┌────────────────┐  │  ║
║  │  │  🎨 Compile MacTahoe │──▶│  🔤 SF Pro Font│──▶│  🧩 14 GNOME   │  │  ║
║  │  │  from upstream src  │   │  system-wide   │   │  Extensions    │  │  ║
║  │  └──────────────────────┘   └────────────────┘   └────────────────┘  │  ║
║  └──────────────────────────────────────────────────────────────────────┘  ║
║                                      │                                      ║
║  ┌──────────────────────────────────────────────────────────────────────┐  ║
║  │  PHASE 4: CONFIGURATION (Steps 10-13)                                │  ║
║  │  ┌───────────────┐   ┌───────────────┐   ┌──────────────┐   ┌─────┐ │  ║
║  │  │  🏷️ Desktop   │──▶│  ⚙️ Configs    │──▶│  🎛️ 75+ dconf│──▶│ 🖼️  │ │  ║
║  │  │  Entries      │   │  Fish/Kitty/  │   │  Settings    │   │ Wall│ │  ║
║  │  │  (re-names)   │   │  Starship/GTK │   │              │   │ pap.│ │  ║
║  │  └───────────────┘   └───────────────┘   └──────────────┘   └─────┘ │  ║
║  └──────────────────────────────────────────────────────────────────────┘  ║
║                                      │                                      ║
║  ┌──────────────────────────────────────────────────────────────────────┐  ║
║  │  PHASE 5: ENHANCEMENT LAYER (Steps 14-17)                            │  ║
║  │  ┌────────────┐   ┌──────────────┐   ┌──────────────┐   ┌─────────┐ │  ║
║  │  │  🔐 GDM    │──▶│  🦊 Firefox  │──▶│  📦 Flatpak  │──▶│  🔊 Big │ │  ║
║  │  │  Login     │   │  userChrome  │   │  GTK Runtime │   │  Sur    │ │  ║
║  │  │  Screen    │   │  (if display)│   │  Build       │   │  Sounds │ │  ║
║  │  └────────────┘   └──────────────┘   └──────────────┘   └─────────┘ │  ║
║  └──────────────────────────────────────────────────────────────────────┘  ║
║                                      │                                      ║
║  ┌──────────────────────────────────────────────────────────────────────┐  ║
║  │  PHASE 6: SHELL & FINALIZATION (Steps 18-21)                         │  ║
║  │  ┌──────────────────┐   ┌────────────────┐   ┌───────────────┐      │  ║
║  │  │  🖥️ Kitty as     │──▶│  📁 Nautilus   │──▶│  🐟 Fish as  │──▶   │  ║
║  │  │  Default + Max'd │   │  Always Max'd  │   │  Default Shell│     │  ║
║  │  └──────────────────┘   └────────────────┘   └───────┬───────┘      │  ║
║  │                                                       │              │  ║
║  │                                          ┌────────────▼──────────┐  │  ║
║  │                                          │  🧹 Cleanup & Reboot  │  │  ║
║  │                                          │  Temp files → rm -rf  │  │  ║
║  │                                          │  Cache → dnf clean    │  │  ║
║  │                                          └───────────────────────┘  │  ║
║  └──────────────────────────────────────────────────────────────────────┘  ║
╚═════════════════════════════════════════════════════════════════════════════╝
```

### 📊 Phase Summary

| Phase | Steps | Description | Approx Time |
|-------|-------|-------------|-------------|
| 🖥️ System Prep | 1–3 | Preflight, RPM Fusion, NVIDIA | 2–5 min |
| 📦 Packages | 4–6 | RPMs, Browsers, Flatpaks | 5–15 min |
| 🎨 Theming | 7–9 | Theme compile, Font, Extensions | 5–10 min |
| ⚙️ Config | 10–13 | Entries, Configs, dconf, Wallpaper | ~2 min |
| ✨ Enhancement | 14–17 | GDM, Firefox, Flatpak runtime, Sounds | 3–8 min |
| 🐚 Shell | 18–21 | Kitty/Nautilus max, Fish default, Clean | ~1 min |
| **Total** | **21** | **Full transformation** | **15–45 min** |

---

<a name="2-installation-flow"></a>

## 2. ⚡ Installation Flow

> **Estimated runtime:** 15–45 minutes depending on network speed and hardware.
> Every step is idempotent — re-running is safe and fast.

### 🚦 Interactive Progress Map

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│  STEP  [ 1/21]  🔍  Preflight checks               ──────── ■■■■■■■■■■ 100%│
│  STEP  [ 2/21]  📦  RPM Fusion + Codecs            ──────── ■■■■■■■■■■ 100%│
│  STEP  [ 3/21]  🎮  NVIDIA Drivers                 ──────── ■■■■□□□□□□  40%│
│  STEP  [ 4/21]  📥  RPM Packages (44+ tools)       ──────── ■■■■■■■■■■ 100%│
│  STEP  [ 5/21]  🌐  Browsers (FF, Chrome, Edge, VS)──────── ■■■■■■■■■■ 100%│
│  STEP  [ 6/21]  📱  Flatpak Apps (Spotify, Discord…) ──────── ■■■■■■■■■□  90%│
│  STEP  [ 7/21]  🎨  MacTahoe GTK Theme (compile)   ──────── ■■■■■■■■■■ 100%│
│  STEP  [ 8/21]  🔤  SF Pro Font                    ──────── ■■■■■■■■■■ 100%│
│  STEP  [ 9/21]  🧩  14 GNOME Extensions            ──────── ■■■■■■■■■■ 100%│
│  STEP  [10/21]  🏷️  Desktop Entry Overrides        ──────── ■■■■■■■■■■ 100%│
│  STEP  [11/21]  ⚙️  Config Files (Kitty, Fish, …)  ──────── ■■■■■■■■■■ 100%│
│  STEP  [12/21]  🎛️  75+ dconf/gsettings Settings   ──────── ■■■■■■■■■■ 100%│
│  STEP  [13/21]  🖼️  Wallpaper + Login Bg           ──────── ■■■■■■■■■■ 100%│
│  STEP  [14/21]  🔐  GDM Login Screen Theme         ──────── ■■■■■■■■■■ 100%│
│  STEP  [15/21]  🦊  Firefox userChrome.css         ──────── ■■■■□□□□□□  40%│
│  STEP  [16/21]  📦  Flatpak GTK Runtime Build      ──────── ■■■■■■■■■■ 100%│
│  STEP  [17/21]  🔊  macOS Big Sur Sounds           ──────── ■■■■■■■■■■ 100%│
│  STEP  [18/21]  🖥️  Kitty → Default + Max'd       ──────── ■■■■■■■■■■ 100%│
│  STEP  [19/21]  📁  Nautilus → Always Maximized    ──────── ■■■■■■■■■■ 100%│
│  STEP  [20/21]  🐟  Fish → Default Shell           ──────── ■■■■■■■■■■ 100%│
│  STEP  [21/21]  🧹  Cleanup & Reboot Prompt        ──────── ■■■■■■■■■■ 100%│
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  OVERALL PROGRESS:  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  95% │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 📋 Step Detail Table

| Step | Action | Key Command(s) | Fallback | Idempotent |
|:----:|--------|----------------|----------|:----------:|
| 1 | 🔍 Preflight | `grep ^ID= /etc/os-release`, `ping -c1` | Exit with error | ✅ |
| 2 | 📦 RPM Fusion | `dnf install --nogpgcheck` URLs | Skip & warn | ✅ |
| 3 | 🎮 NVIDIA | `lspci -nn \| grep -i nvidia` | Auto-skip | ✅ |
| 4 | 📥 RPMs | `dnf install -y <44+ packages>` | DNF handles it | ✅ |
| 5 | 🌐 Browsers | `dnf install -y <browser>` | Skip per selection | ✅ |
| 6 | 📱 Flatpaks | `flatpak install -y <apps>` | Skip per app | ✅ |
| 7 | 🎨 Theme | `git clone + ./install.sh -t all -b -l` | Bundled theme | ✅ |
| 8 | 🔤 Font | `cp fonts/*.otf ~/.local/share/fonts/` | Skip if present | ✅ |
| 9 | 🧩 Extensions | EGO API → zip → `gnome-extensions install` | Skip if installed | ✅ |
| 10 | 🏷️ Entries | `cp desktop/*.desktop ~/.local/share/applications/` | Overwrite old | ✅ |
| 11 | ⚙️ Configs | `cp configs/* ~/.config/` | Overwrite old | ✅ |
| 12 | 🎛️ dconf | `gsettings set <schema> <key> <value>` | Overwrite safe | ✅ |
| 13 | 🖼️ Wallpaper | `gsettings set org.gnome.desktop.background` | Skip if missing | ✅ |
| 14 | 🔐 GDM | `sudo ./tweaks.sh -g -nb -nd -b $wallpaper` | Skip & warn | ✅ |
| 15 | 🦊 Firefox | `killall firefox; ./tweaks.sh -f` | Warn → manual | ✅ |
| 16 | 📦 Flatpak Runtime | `ostree init → build → bundle → install` | Skip if exists | ✅ |
| 17 | 🔊 Sounds | `cp -r sounds/ ~/.local/share/sounds/` | Clone from git | ✅ |
| 18 | 🖥️ Kitty Max'd | D-Bus wrapper → `/usr/local/bin/kitty-maximized` | wtype fallback | ✅ |
| 19 | 📁 Nautilus Max'd | D-Bus wrapper → `/usr/local/bin/nautilus-maximized` | wtype fallback | ✅ |
| 20 | 🐟 Fish Default | `chsh -s $(which fish)` | Skip if fish | ✅ |
| 21 | 🧹 Cleanup | `rm -rf /tmp/mactahoe* ~/.cache/pakitheme/` | Always safe | ✅ |

---

<a name="3-theme-compilation-step-7"></a>

## 3. 🎨 Theme Compilation (Step 7)

### 🧠 The Core Problem

> The MacTahoe GTK theme generates **different CSS** for each GNOME Shell version.
> Bundling a pre-compiled theme means it only works on the GNOME version it was
> built for. On Fedora 42 → theme works. On Fedora 44 → broken or misaligned
> elements. The solution: **compile from source at install time**.

### 🔧 Compilation Pipeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          THEME COMPILATION PIPELINE                         │
│                                                                             │
│  ┌──────────────┐                                                          │
│  │  DETECT      │                                                          │
│  │  GNOME VER   │  ─────────────────────────────────────────────────────┐  │
│  │  via:        │                                                       │  │
│  │  gnome-shell │  ┌─────────────────────────────────────────────────┐  │  │
│  │  --version   │  │  git clone                                      │  │  │
│  └──────┬───────┘  │  vinceliuice/MacTahoe-gtk-theme.git             │  │  │
│         │          │  → /tmp/mactahoe-theme/                         │  │  │
│         │          └──────────────────────┬──────────────────────────┘  │  │
│         │                                 │                             │  │
│         │          ┌──────────────────────▼──────────────────────────┐  │  │
│         └─────────▶│  ./install.sh -t all -b -l                      │  │  │
│                    │                                                │  │  │
│                    │  Flags:                                        │  │  │
│                    │    -t all  → All variants                      │  │  │
│                    │    -b      → Blur effect (transparent panel)   │  │  │
│                    │    -l      → Libadwaita (GTK4) support         │  │  │
│                    └──────────────────────┬──────────────────────────┘  │  │
│                                           │                             │  │
│              ┌────────────────────────────▼────────────────────────┐    │  │
│              │  COMPILED OUTPUT                                     │    │  │
│              │  ┌─────────────────────────────────────────────────┐ │    │  │
│              │  │  ~/.themes/MacTahoe-Dark/                       │ │    │  │
│              │  │  ├── gnome-shell/     ← GNOME Shell CSS        │ │    │  │
│              │  │  ├── gtk-3.0/         ← GTK3 assets/CSS        │ │    │  │
│              │  │  ├── gtk-4.0/         ← GTK4 assets/CSS        │ │    │  │
│              │  │  ├── metacity-1/      ← Window decorations     │ │    │  │
│              │  │  ├── unity/           ← Unity support          │ │    │  │
│              │  │  ├── xfwm4/           ← XFCE support           │ │    │  │
│              │  │  ├── cinnamon/        ← Cinnamon support       │ │    │  │
│              │  │  └── plank/           ← Plank dock theme       │ │    │  │
│              │  └─────────────────────────────────────────────────┘ │    │  │
│              │                                                       │    │  │
│              │  Copied to: ~/.local/share/themes/ (XDG compat)      │    │  │
│              │  Libadwaita: ~/.config/gtk-4.0/ (via -l flag)        │    │  │
│              └───────────────────────────────────────────────────────┘    │  │
│                                                                           │  │
└───────────────────────────────────────────────────────────────────────────┘  │
```

### 🛡️ Fallback Chain

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        FALLBACK CHAIN                                       │
│                                                                             │
│  1.  PRIMARY: Clone upstream + compile                                     │
│      ├── git clone https://github.com/vinceliuice/MacTahoe-gtk-theme.git  │
│      ├── cd MacTahoe-gtk-theme                                            │
│      ├── ./install.sh -t all -b -l                                         │
│      └── ✓ MacTahoe-Dark → ~/.themes/ + ~/.local/share/themes/            │
│                                                                             │
│  2.  FALLBACK: If git clone fails (no network, repo down)                  │
│      ├── Source: themes/MacTahoe-Dark/ (bundled in repo)                  │
│      ├── cp -r → ~/.themes/ + ~/.local/share/themes/                      │
│      └── cp gtk-4.0 assets → ~/.config/gtk-4.0/                          │
│                                                                             │
│  3.  LAST RESORT: Pre-compiled MacTahoe-Dark from repo bundle              │
│      ├── May not match current GNOME Shell version                         │
│      └── Will still look mostly correct (GTK3/GTK4 are stable)            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🏷️ Name Normalization History

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      NAME NORMALIZATION                                     │
│                                                                             │
│  The bundled theme was originally named after the creator's username:       │
│                                                                             │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  BEFORE:                      │  AFTER:                          │    │
│  │  ─────────────────────────────┼────────────────────────────────── │    │
│  │  Folder: MacTahoe-Dark-       │  Folder: MacTahoe-Dark            │    │
│  │          Eprahemi             │                                   │    │
│  │  Name:   MacTahoe-Dark-       │  Name:   MacTahoe-Dark            │    │
│  │          Eprahemi             │                                   │    │
│  │  GtkTheme: MacTahoe-Dark-     │  GtkTheme: MacTahoe-Dark          │    │
│  │            Eprahemi           │                                   │    │
│  │  MetacityTheme: MacTahoe-     │  MetacityTheme: MacTahoe-Dark     │    │
│  │                Dark-Eprahemi  │                                   │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
│  ⓘ  The old and new directories are BYTE-IDENTICAL — only the folder      │
│      name and index.theme metadata differ.                                 │
│                                                                             │
│  Reason: Upstream ./install.sh produces "MacTahoe-Dark" — the custom      │
│  suffix caused gsettings lookups to fail silently.                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🎯 Icon Themes (Always Bundled)

The icon themes `MacTahoe-Eprahemi` and `MacTahoe-dark-Eprahemi` are **never compiled**
from upstream. They contain hand-curated icon replacements representing hundreds of
hours of manual customization:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│               ICON THEME STRUCTURE                                          │
│                                                                             │
│  MacTahoe-dark-Eprahemi/    (Dark variant — primary)                       │
│  └── apps/                                                                 │
│      ├── scalable/          ← Symlinked raster icons                      │
│      └── 256x256/           ← Hand-curated PNGs                          │
│                                                                             │
│  MacTahoe-Eprahemi/         (Light variant — for light themes)             │
│  └── apps/                                                                 │
│      ├── scalable/          ← Same symlink structure                      │
│      └── 256x256/                                                         │
│                                                                             │
│  ⓘ  Every raster icon retimed and recolored for macOS aesthetic           │
│  ⓘ  Symlink structure preserved (actions@2x → actions, apps@2x → apps)     │
│  ⓘ  Icon caches regenerated with gtk-update-icon-cache after install       │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🖥️ Theme Layer Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     HOW THE THEME RENDERS ON SCREEN                         │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  🖥️  GNOME SHELL (Top Bar, Activities Overview, Dash)                │  │
│  │  ├── Theme source: MacTahoe-Dark/gnome-shell/                       │  │
│  │  ├── Applied via: user-theme GNOME extension                         │  │
│  │  └── Effect: macOS-style top bar, rounded corners, blur             │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  🪟  GTK3 APPLICATIONS (Firefox, Nautilus, Gedit, etc.)              │  │
│  │  ├── Theme source: MacTahoe-Dark/gtk-3.0/                          │  │
│  │  ├── Applied via: gsettings org.gnome.desktop.interface gtk-theme   │  │
│  │  └── Effect: Dark window borders, styled scrollbars, buttons       │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  🏠  GTK4/LIBADWAITA (GNOME Text, Software, Settings)                │  │
│  │  ├── Theme source: ~/.config/gtk-4.0/gtk.css (copied by -l flag)   │  │
│  │  ├── Applied via: XDG_CONFIG_HOME override                          │  │
│  │  └── Effect: Dark-themed settings, text editor, software center    │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  📦  FLATPAK APPLICATIONS (Spotify, Discord, Obsidian)               │  │
│  │  ├── Theme source: org.gtk.Gtk3theme.MacTahoe-Dark runtime          │  │
│  │  ├── Applied via: Flatpak runtime system (Step 16)                  │  │
│  │  └── Effect: Same macOS theme inside sandboxed apps                 │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

<a name="4-custom-application-icons"></a>

## 4. 🖼️ Custom Application Icons

### 🗺️ Full Icon Pipeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ICON PROCESSING & DEPLOYMENT                        │
│                                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────────────┐  │
│  │  SOURCE PNG  │    │  IMAGEMAGICK  │    │  TRIAGE ENGINE              │  │
│  │              │    │  PROCESSING   │    │                              │  │
│  │  icons/      │───▶│              │───▶│  ┌────────────────────────┐ │  │
│  │  256x256/    │    │  magick:     │    │  │  Has Flatpak ID name?  │ │  │
│  │              │    │  -trim       │    │  │  ┌───Yes──┐  ┌───No──┐│ │  │
│  │  21 PNGs     │    │  -resize     │    │  │  │ Copy   │  │ Lookup││ │  │
│  │  total       │    │  -gravity    │    │  │  │ direct │  │ alias ││ │  │
│  │              │    │  -extent     │    │  │  └────────┘  │ map   ││ │  │
│  └──────────────┘    └──────────────┘    │  │              └───┬────┘│ │  │
│                                          │  └──────────────────┼─────┘  │  │
│                                          └─────────────────────┼────────┘  │
│                                                                │          │
│                                        ┌───────────────────────▼────────┐ │
│                                        │  DEPLOY TO 3 TARGET DIRECTORIES │ │
│                                        │                                │ │
│                                        │  Target 1: MacTahoe-dark-      │ │
│                                        │            Eprahemi/apps/      │ │
│                                        │            scalable/           │ │
│                                        │                                │ │
│                                        │  Target 2: MacTahoe-Eprahemi/  │ │
│                                        │            apps/scalable/      │ │
│                                        │                                │ │
│                                        │  Target 3: hicolor/256x256/    │ │
│                                        │            apps/               │ │
│                                        └────────────────┬───────────────┘ │
│                                                         │                 │
│                                        ┌─────────────────▼──────────────┐ │
│                                        │  gtk-update-icon-cache        │ │
│                                        │  → Regenerate icon theme caches│ │
│                                        └────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 📸 Complete Icon Catalog

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  ICON                      │ FLATPAK ALIAS        │ TYPE      │ SIZE       │
│  ──────────────────────────┼──────────────────────┼───────────┼─────────── │
│  code.png                  │ com.visualstudio.    │ Raster    │ 256×256    │
│                            │   code.png           │           │            │
│  com.github.tchx84.        │ (none — native ID)   │ Raster    │ 256×256    │
│    Flatseal.png            │                      │           │            │
│  com.protonvpn.www.png     │ (none — native ID)   │ Raster    │ 256×256    │
│  discord.png               │ com.discordapp.      │ Raster    │ 256×256    │
│                            │   Discord.png        │           │            │
│  fr.handbrake.ghb.png      │ (none — native ID)   │ Raster    │ 256×256    │
│  google-chrome.png         │ (none — native ID)   │ Raster    │ 256×256    │
│  io.github.amit9838.       │ (none — native ID)   │ Raster    │ 256×256    │
│    mousam.png              │                      │           │            │
│  it.mijorus.gearlever.png  │ (none — native ID)   │ Raster    │ 256×256    │
│  kitty.png                 │ (none — native ID)   │ Raster    │ 256×256    │
│  kylin-video.png           │ (none — native ID)   │ Raster    │ 256×256    │
│  localsend.png             │ (none — native ID)   │ Raster    │ 256×256    │
│  microsoft-edge.png        │ (none — native ID)   │ Raster    │ 256×256    │
│  ms-excel.png              │ (none — native ID)   │ Raster    │ 256×256    │
│  ms-powerpoint.png         │ (none — native ID)   │ Raster    │ 256×256    │
│  ms-word.png               │ (none — native ID)   │ Raster    │ 256×256    │
│  org.gnome.Notes.png       │ (none — native ID)   │ Raster    │ 256×256    │
│  spotify.png               │ com.spotify.Client.  │ Raster    │ 256×256    │
│                            │   png                │           │            │
│  vidcutter.png             │ (none — native ID)   │ Raster    │ 256×256    │
│  videoplayer.png           │ (none — native ID)   │ Raster    │ 256×256    │
│  vlc.png                   │ org.videolan.VLC.png │ Raster    │ 256×256    │
│  whatsapp.png              │ (none — native ID)   │ Raster    │ 256×256    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🎨 Image Processing Command

```bash
# Applied to every source PNG:
magick "$png" -trim +repage -resize 256x256 \
  -gravity center -background transparent \
  -extent 256x256 "$png"
```

### 🔄 Flatpak ID Alias Map

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  FLATPAK ID ALIAS MAP                                                       │
│                                                                             │
│  Flatpak apps look for icons by their full reverse-DNS identifier:          │
│                                                                             │
│  ┌──────────────────────┬─────────────────────────────┬──────────────────┐ │
│  │  Source File         │  Copied As                  │  Used By         │ │
│  ├──────────────────────┼─────────────────────────────┼──────────────────┤ │
│  │  spotify.png         │  com.spotify.Client.png     │  Spotify         │ │
│  │  discord.png         │  com.discordapp.Discord.png │  Discord         │ │
│  │  vlc.png             │  org.videolan.VLC.png       │  VLC             │ │
│  │  code.png            │  com.visualstudio.code.png  │  VS Code         │ │
│  └──────────────────────┴─────────────────────────────┴──────────────────┘ │
│                                                                             │
│  Icons already named with Flatpak IDs (e.g., com.github.tchx84.Flatseal)   │
│  are copied directly — no alias needed.                                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

<a name="5-fish-shell-functions"></a>

## 5. 🐟 Fish Shell Functions

> **17 custom functions** in `configs/fish/functions/`. Every function uses
> **dynamic username resolution** — zero hardcoded names.

### 🏆 Complete Feature Matrix

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  FUNCTION          │ CATEGORY     │ DYNAMIC PATTERN        │ PURPOSE       │
│  ──────────────────┼──────────────┼───────────────────────┼─────────────── │
│  testdrive.fish    │ ⚡ Diagnostics│ (whoami)_test_bin,    │ Full hardware │
│                    │              │ $USER | string upper  │ benchmark     │
│  stayawake.fish    │ 🔋 Utility   │ $USER | string upper  │ Inhibit lid   │
│                    │              │                       │ sleep + timer │
│  refresh.fish      │ 🔄 System    │ $HOME,                │ Reset UI,     │
│                    │              │ $USER | string upper  │ caches, portal│
│  fish_greeting.fish│ 🎨 Prompt    │ (whoami)              │ figlet →      │
│                    │              │                       │ lolcat        │
│  l.fish            │ 📂 Nav       │ —                     │ eza with      │
│                    │              │                       │ icons         │
│  cat.fish          │ 📖 Reading   │ —                     │ bat with      │
│                    │              │                       │ highlighting  │
│  v.fish            │ ✏️ Editor    │ —                     │ neovim        │
│                    │              │                       │ shortcut      │
│  c.fish            │ 🧹 Cleanup   │ —                     │ clear screen  │
│  n.fish            │ 📝 Notes     │ —                     │ quick notes   │
│  p.fish            │ 🔌 Ports     │ —                     │ project       │
│                    │              │                       │ helper        │
│  mkgif.fish        │ 🎥 Recording │ —                     │ screen → GIF  │
│  matrix.fish       │ 💚 Visual    │ —                     │ Matrix rain   │
│  hollywood.fish    │ 🎬 Visual    │ —                     │ Hollywood     │
│                    │              │                       │ terminal      │
│  weather.fish      │ 🌤️ Info      │ —                     │ curl wttr.in  │
│  clean.fish        │ 🧹 System    │ —                     │ DNF cache     │
│                    │              │                       │ cleanup       │
│  cleanreset.fish   │ 🧹 System    │ —                     │ deep clean +  │
│                    │              │                       │ kernel cache  │
│  getdata.fish      │ 📊 Info      │ —                     │ system data   │
│                    │              │                       │ snapshot      │
└─────────────────────────────────────────────────────────────────────────────┘
```

### ⚙️ config.fish Reference

```fish
# ── Environment ──────────────────────────────────────────────
set -gx TERMINAL kitty
set -gx TERM kitty
set -gx ANI_CLI_PLAYER vlc

# ── Startup ──────────────────────────────────────────────────
starship init fish | source
fastfetch
```

> **Important:** `config.fish` does **not** contain opencode paths or any
> user-specific configuration. Those belong in `~/.config/fish/config.fish`
> (e.g., `fish_add_path` for opencode CLI tools).

### 🔄 Before/After Dynamic Pattern Migration

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  🔴 HARDCODED (Before)           │  🟢 DYNAMIC (After)                     │
│  ────────────────────────────────┼───────────────────────────────────────── │
│  figlet "eprahemi"               │  figlet (whoami)                        │
│  set -l user "EPRAHEMI"          │  set -l user (echo $USER | string upper)│
│  /home/eprahemi/test_bin         │  "$HOME/"(whoami)"_test_bin"            │
│  /home/eprahemi/.config/random   │  "$HOME/.config/random"                 │
│  /home/eprahemi/scripts/         │  "$HOME/scripts/"                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🐟 testdrive.fish — Deep Dive

```fish
# ── Highlights the dynamic pattern ──
set -l user (echo $USER | string upper)
set -l test_bin "$HOME/"(whoami)"_test_bin"
set -l log "$HOME/.local/share/"(whoami)"-bench.log"

# ── Benchmark suite ──
#   ✓ Disk speed (dd sequential read/write)
#   ✓ RAM throughput (mbw)
#   ✓ CPU stress (sysbench prime)
#   ✓ GPU info (nvidia-smi or glxinfo)
#   ✓ Network speed (speedtest-cli)
#   → Generate timestamped report to $log
```

---

<a name="6-gnome-extension-management-step-9"></a>

## 6. 🧩 GNOME Extension Management (Step 9)

### 🧠 The Core Problem

> `gnome-extensions enable` communicates over **D-Bus** to the running GNOME
> Shell session. On freshly created users who have never logged into GNOME,
> there is no D-Bus session available. The command **silently fails** — no
> error, no change, no warning.

### 💡 The Solution

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     EXTENSION DOWNLOAD & ENABLE FLOW                        │
│                                                                             │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────────────────┐   │
│  │  EGO API     │     │  Download    │     │  Extract & Install       │   │
│  │  (extensions │     │  .zip files  │     │  gnome-extensions install │   │
│  │  .gnome.org) │     │              │     │  → ~/.local/share/gnome-  │   │
│  │              │     │  curl -Lo    │     │    shell/extensions/      │   │
│  │  Loop over   │────▶│  /tmp/       │────▶│                          │   │
│  │  14 UUIDs    │     │  ext-*.zip   │     │  Verify dir exists        │   │
│  └──────────────┘     └──────────────┘     └────────────┬─────────────┘   │
│                                                         │                 │
│  ┌──────────────────────────────────────────────────────▼──────────────┐  │
│  │  BUILD UUID LIST (Dynamic)                                         │  │
│  │  for dir in ~/.local/share/gnome-shell/extensions/*/; do          │  │
│  │    uuid=$(basename "$dir")                                        │  │
│  │    ext_list+=("'$uuid'")                                          │  │
│  │  done                                                             │  │
│  └──────────────────────────────────────┬─────────────────────────────┘  │
│                                         │                                │
│  ┌──────────────────────────────────────▼─────────────────────────────┐  │
│  │  gsettings set (NO D-BUS REQUIRED)                                │  │
│  │  gsettings set org.gnome.shell enabled-extensions                 │  │
│  │    "['uuid1','uuid2','uuid3',...]"                                │  │
│  │                                                                    │  │
│  │  ✓ Writes directly to dconf database                              │  │
│  │  ✓ Persists to disk immediately                                  │  │
│  │  ✓ Picked up on next GNOME login                                 │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🔌 Full Extension Catalog (14 Extensions)

```
┌──────┬──────────────────────────────────────────────────────┬──────────┬──────────────────────────────┐
│  #   │  UUID                                                │ Category │  Purpose                     │
├──────┼──────────────────────────────────────────────────────┼──────────┼──────────────────────────────┤
│  1   │  blur-my-shell@aunetx                               │ 🪟 Visual │ Transparent blurred panel   │
│  2   │  user-theme@gnome-shell-extensions.gcampax          │ 🎨 Theme  │ Load custom shell theme     │
│      │    .github.com                                      │          │                              │
│  3   │  logomenu@aryan_k                                   │ 🍎 Dock   │ macOS-style Apple menu      │
│  4   │  AlphabeticalAppGrid@stuarthayhurst                 │ 📊 Grid   │ Sort app grid A→Z           │
│  5   │  pinned-apps-in-appgrid@brunosilva.io               │ 📌 Grid   │ Pin apps inside grid        │
│  6   │  app-hider@lynith.dev                               │ 🙈 Grid   │ Hide apps from grid         │
│  7   │  compiz-alike-magic-lamp-effect@hermes83            │ ✨ Anim   │ Genie/minimize animation    │
│      │    .github.com                                      │          │                              │
│  8   │  compiz-windows-effect@hermes83.github.com         │ ✨ Anim   │ Window open/close effects   │
│  9   │  CoverflowAltTab@palatis.blogspot.com               │ 🔄 AltTab │ CoverFlow window switcher   │
│  10  │  clipboard-history@alexsaveau.dev                   │ 📋 Util   │ Persistent clipboard mgr    │
│  11  │  ding@rastersoft.com                                │ 🖥️ Desktop│ Desktop icons               │
│  12  │  Bluetooth-Battery-Meter@maniacx.github.com         │ 🔋 HW     │ BT device battery levels    │
│  13  │  dash2dock-lite@icedman.github.com                  │ 🖥️ Dock   │ macOS-style dock            │
│  14  │  appindicatorsupport@rgcjonas.gmail.com             │ 🔔 Tray   │ System tray / indicators    │
└──────┴──────────────────────────────────────────────────────┴──────────┴──────────────────────────────┘
```

### 🎛️ dash2dock-lite Configuration

```
┌─────────────────────────────┬──────────┬─────────────────────────────────┐
│  SETTING                    │  VALUE   │  EFFECT                         │
├─────────────────────────────┼──────────┼─────────────────────────────────┤
│  autohide-dash              │  true    │  Dock hides when not needed     │
│  click-action               │ 'minimize│  Click to minimize or show      │
│                             │  -or-    │  previews                       │
│                             │  previews'│                               │
│  icon-size                  │  0.25    │  Compact dock icons             │
│  running-indicator-style    │  4       │  Dots for running apps         │
│  show-favorites             │  true    │  Show pinned favorites          │
│  show-running               │  true    │  Show running applications      │
│  dock-padding               │  0.5     │  Internal dock spacing          │
│  border-radius              │  3.0     │  Rounded dock corners           │
│  label-border-radius        │  3.0     │  Rounded label corners          │
│  customize-label            │  true    │  Enable label customization     │
└─────────────────────────────┴──────────┴─────────────────────────────────┘
```

### 🔧 gsettings Enable Format

```bash
# ── Build the UUID list dynamically ──
ext_list=()
for dir in "$ext_dir"*/; do
  uuid=$(basename "$dir")
  ext_list+=("'$uuid'")
done

# ── Write directly to dconf (no D-Bus) ──
gsettings set org.gnome.shell enabled-extensions \
  "[$(IFS=,; echo "${ext_list[*]}")]"
```

---

<a name="7-gnome-dconf-settings-step-12"></a>

## 7. ⚙️ GNOME dconf Settings (Step 12)

> Settings are applied via **gsettings** and **dconf** commands — not raw dump
> import. This makes the script **self-documenting** and **resilient to schema
> changes** across GNOME versions.

### 🎨 Theme & Appearance — Visual Layout

```
                    ┌─────────────────────────────────┐
      ┌─────────────┤     GNOME DESKTOP APPEARANCE    ├─────────────┐
      │             └─────────────────────────────────┘             │
      │                                                             │
      ▼                                                             ▼
┌─────────────┐                                             ┌─────────────┐
│  🎨 GTK     │                                             │  🖼️ Icons   │
│  MacTahoe-  │                                             │  MacTahoe-  │
│  Dark       │                                             │  dark-      │
│             │                                             │  Eprahemi   │
└─────────────┘                                             └─────────────┘
      │                                                             │
      ▼                                                             ▼
┌─────────────┐                                             ┌─────────────┐
│  🖱️ Cursor  │                                             │  🐚 Shell   │
│  MacTahoe-  │                                             │  MacTahoe-  │
│  dark-      │                                             │  Dark       │
│  Eprahemi   │                                             │  (via ext)  │
└─────────────┘                                             └─────────────┘
```

### 🔤 Typography Settings

```
┌─────────────────────────────┬──────────────────────────────────────────────┐
│  SETTING                    │  VALUE                                       │
├─────────────────────────────┼──────────────────────────────────────────────┤
│  Interface font             │  SF Pro Display 11                           │
│  Document font              │  SF Pro Display 12                           │
│  Monospace font             │  Adwaita Mono 11                             │
│  Font hinting               │  slight                                      │
│  Font antialiasing          │  grayscale                                   │
│  Accent color               │  blue                                        │
│  Color scheme               │  prefer-dark                                 │
└─────────────────────────────┴──────────────────────────────────────────────┘
```

### 🕒 Clock & Status Bar

```
┌─────────────────────────────┬──────────────────────────────────────────────┐
│  SETTING                    │  VALUE                                       │
├─────────────────────────────┼──────────────────────────────────────────────┤
│  Time format                │  12-hour                                     │
│  Show date                  │  ✅ Yes                                      │
│  Show seconds               │  ❌ No                                       │
│  Show weekday               │  ❌ No                                       │
│  Battery percentage         │  ❌ No                                       │
│  Animations                 │  ✅ Yes                                      │
└─────────────────────────────┴──────────────────────────────────────────────┘
```

### 🪟 Window Button Layout

```
   ┌────────────────────────────────────────────────────────────────────────┐
   │                                                                        │
   │  ┌────┐  ┌────┐  ┌────┐                        ┌──────────┐          │
   │  │  ✕  │  │  ─  │  │  □  │                        │  ☰ App  │          │
   │  │close│  │min  │  │max  │                        │  Menu   │          │
   │  └────┘  └────┘  └────┘                        └──────────┘          │
   │                                                                        │
   │         ╔══════════════════════╗                                       │
   │         ║   macOS standard     ║              ╔══════════════╗         │
   │         ║   (left side)        ║              ║ App menu     ║         │
   │         ╚══════════════════════╝              ║ (right side) ║         │
   │                                               ╚══════════════╝         │
   └────────────────────────────────────────────────────────────────────────┘
```

### ⌨️ Workspace Keybindings

```
┌─────────────────────────────┬──────────────────────────────────────────────┐
│  ACTION                     │  SHORTCUT                                    │
├─────────────────────────────┼──────────────────────────────────────────────┤
│  Switch to workspace 1      │  Super + 1                                  │
│  Switch to workspace 2      │  Super + 2                                  │
│  …                          │  …                                          │
│  Switch to workspace 9      │  Super + 9                                  │
│                             │                                              │
│  Move window → workspace 1  │  Super + Shift + 1                         │
│  Move window → workspace 2  │  Super + Shift + 2                         │
│  …                          │  …                                          │
│  Move window → workspace 9  │  Super + Shift + 9                         │
│                             │                                              │
│  Previous workspace         │  Ctrl + Left                                 │
│  Next workspace             │  Ctrl + Right                                │
│  Close window               │  Super + Q                                   │
└─────────────────────────────┴──────────────────────────────────────────────┘
```

### ⌨️ Custom Keybindings

```
┌───────────────┬─────────────────┬──────────────────────────────────────────┐
│  SHORTCUT     │  ACTION         │  COMMAND                                 │
├───────────────┼─────────────────┼──────────────────────────────────────────┤
│  Super + T    │  🖥️ Terminal     │  kitty                                  │
│  Super + E    │  📁 Files        │  nautilus                               │
│  Ctrl+Shift+  │  📊 Task Manager │  gnome-system-monitor                   │
│    Esc        │                 │                                          │
│  Ctrl+Alt+V   │  🔊 Volume       │  pavucontrol                            │
│               │     Control     │                                          │
└───────────────┴─────────────────┴──────────────────────────────────────────┘
```

### 🖥️ Display & Peripherals

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  TOUCHPAD                          │  MOUSE                                │
│  ┌─────────────────────────────┐   │  ┌─────────────────────────────┐     │
│  │  Setting          │ Value   │   │  │  Setting          │ Value   │     │
│  ├─────────────────────────────┤   │  ├─────────────────────────────┤     │
│  │  Tap to click     │ ✅ On   │   │  │  Acceleration     │ default │     │
│  │  Natural scroll   │ ✅ On   │   │  │  Natural scroll   │ ❌ Off  │     │
│  │  2-finger scroll  │ ✅ On   │   │  └─────────────────────────────┘     │
│  │  Click method     │ fingers │   │                                      │
│  └─────────────────────────────┘   │                                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 📁 Nautilus (File Manager)

```
┌─────────────────────────────┬──────────────────────────────────────────────┐
│  SETTING                    │  VALUE                                       │
├─────────────────────────────┼──────────────────────────────────────────────┤
│  Default zoom level         │  large                                       │
│  Recursive search           │  always                                      │
│  Image thumbnails           │  always                                      │
│  Directory item counts      │  always                                      │
│  Window state at launch     │  ⬛ MAXIMIZED  (via D-Bus wrapper)           │
└─────────────────────────────┴──────────────────────────────────────────────┘
```

### 🚀 Dock Favorites

```
   ┌─────────────────────────────────────────────────────────────────────┐
   │                       DOCK FAVORITES                               │
   │                                                                     │
   │  ┌────┐  ┌────┐  ┌────┐  ┌────┐  ┌────┐  ┌────┐  ┌────┐         │
   │  │ 📁 │  │ 🦊 │  │ 🌐 │  │ 🔵 │  │ 💬 │  │ 🖥️ │  │ 📦 │         │
   │  │File│  │ FF │  │Chrm│  │Edge│  │Dis │  │Kit │  │Soft│         │
   │  │s   │  │    │  │    │  │    │  │cord│  │ty  │  │ware│         │
   │  └────┘  └────┘  └────┘  └────┘  └────┘  └────┘  └────┘         │
   │                                                                     │
   │  1:Nautilus  2:Firefox  3:Chrome  4:Edge  5:Discord  6:Kitty  7:SW│
   └─────────────────────────────────────────────────────────────────────┘
```

### 🛌 Session & Power

```
┌─────────────────────────────┬──────────┬──────────────────────────────────┐
│  SETTING                    │  VALUE   │  EFFECT                          │
├─────────────────────────────┼──────────┼──────────────────────────────────┤
│  idle-delay                 │  0       │  Screen never blanks auto        │
│  report-technical-problems  │  false   │  Privacy — no crash reports     │
│  power-button-action        │ 'suspend'│  Physical button behavior        │
│  sleep-inactive-ac-timeout  │  4800    │  Blank after 80 minutes          │
│  night-light-enabled        │  false   │  Disabled (macOS doesn't use it) │
│  night-light-temperature    │  2700    │  Warm if enabled manually        │
└─────────────────────────────┴──────────┴──────────────────────────────────┘
```

---

<a name="8-firefox-theming-step-15"></a>

## 8. 🦊 Firefox Theming (Step 15)

### 🧠 The Core Problem

> macOS-style theme for Firefox is provided by the upstream MacTahoe `tweaks.sh -f`
> command. It writes a `userChrome.css` file into the **default Firefox profile**
> directory. But if Firefox has never been launched, **no profile directory exists**,
> and Firefox cannot create one without a GPU/display.

### 🔄 Evolution of Solutions

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FIREFOX THEME — SOLUTION EVOLUTION                       │
│                                                                             │
│  Timeline:                                                                  │
│  ───────────────────────────────────────────────────────────────────────    │
│                                                                             │
│  Attempt 1:  firefox --headless                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  ❌ FAILED: Firefox needs GPU acceleration even in headless mode    │   │
│  │  Output: "Failed to connect to the GPU" → exit code 1              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  Attempt 2:  firefox -CreateProfile "default"                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  ❌ FAILED: Firefox refuses to create profiles without DISPLAY       │   │
│  │  Output: "No display environment specified" → exit code 1          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  Attempt 3:  Try tweaks.sh -f, catch failure gracefully                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  ✅ WORKS: 50% solution                                              │   │
│  │  ├── killall firefox (safe if not running)                          │   │
│  │  ├── ./tweaks.sh -f → fails (no profile)                           │   │
│  │  ├── Sets FIREFOX_THEME_FAILED=1                                   │   │
│  │  └── Shows warning, does NOT block install                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  Final (User):  Login → Launch Firefox → Re-run install.sh                │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  ✅ COMPLETE: User performs two manual steps:                       │   │
│  │  1. Log into GNOME                                                  │   │
│  │  2. Launch Firefox at least once (creates default profile)          │   │
│  │  3. bash install.sh (tweaks.sh -f succeeds this time)              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🏁 Current Behavior — Decision Tree

```
                    ┌─────────────────────────┐
                    │  STEP 15: Firefox Theme  │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  killall firefox        │
                    │  killall firefox-bin    │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  ./tweaks.sh -f          │
                    └────────────┬────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
               ┌────▼────┐              ┌────▼────┐
               │  EXIT 0  │              │  EXIT ≠0│
               └────┬────┘              └────┬────┘
                    │                         │
           ┌────────▼────────┐      ┌─────────▼───────────┐
           │  ✅ THEME        │      │  ⚠ FIREFOX NOT      │
           │  APPLIED         │      │  THEMED              │
           │  ✓ macOS CSS     │      │  ℹ Log in → launch  │
           │  ✓ userChrome    │      │    Firefox once      │
           │  ✓ Complete      │      │  ℹ Re-run:          │
           │                  │      │    bash install.sh   │
           └─────────────────┘      └──────────────────────┘
```

### 📝 Post-Install Warning Message

```bash
# ── Displayed at end of install if Firefox theming failed ──
echo "⚠ Firefox not themed — log into your user, launch Firefox once,"
echo "  then re-run: bash install.sh (skips completed steps)"
```

---

<a name="9-flatpak-gtk-runtime-step-16"></a>

## 9. 📦 Flatpak GTK Runtime (Step 16)

### 🧠 The Core Problem

> Flatpak applications run in a **sandboxed environment**. They cannot access
> the system theme directory (`~/.themes/` or `/usr/share/themes/`). Without a
> Flatpak runtime named `org.gtk.Gtk3theme.MacTahoe-Dark`, Flatpak apps will
> render in Adwaita (default GNOME theme) — completely breaking the macOS
> aesthetic inside sandboxed applications.

### 🏗️ Complete Build Process

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                FLATPAK GTK THEME RUNTIME — BUILD PIPELINE                   │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  STEP 1: Install build dependencies                                 │  │
│  │  ──────────────────────────────────────────────────────────────────  │  │
│  │  sudo dnf install -y ostree libappstream-glib                       │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  STEP 2: Locate MacTahoe-Dark theme                                 │  │
│  │  ──────────────────────────────────────────────────────────────────  │  │
│  │  Search priority:                                                    │  │
│  │    1. ~/.themes/MacTahoe-Dark                                       │  │
│  │    2. ~/.local/share/themes/MacTahoe-Dark                           │  │
│  │    3. /usr/share/themes/MacTahoe-Dark                               │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  STEP 3: Initialize OSTree repository                               │  │
│  │  ──────────────────────────────────────────────────────────────────  │  │
│  │  ostree --repo="$repo_dir" init --mode=archive                      │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  STEP 4: Copy theme assets to build directory                       │  │
│  │  ──────────────────────────────────────────────────────────────────  │  │
│  │  $build_dir/files/                                                  │  │
│  │  ├── gtk-3.0/gtk.css          ← Main GTK3 stylesheet              │  │
│  │  ├── gtk-3.0/gtk-dark.css     ← Dark variant stylesheet           │  │
│  │  ├── gtk-3.0/assets/          ← GTK3 assets (sliders, checks, …) │  │
│  │  ├── gtk-3.0/windows-assets/ ← Windows-specific assets           │  │
│  │  └── share/themes/MacTahoe-Dark/                                   │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  STEP 5: Create appdata XML metadata                               │  │
│  │  ──────────────────────────────────────────────────────────────────  │  │
│  │  appstream-compose --prefix="$build_dir/files" \                   │  │
│  │    --basename="$app_id" "$app_id"                                  │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  STEP 6: Commit to OSTree repository                               │  │
│  │  ──────────────────────────────────────────────────────────────────  │  │
│  │  ostree --repo commit -b base --tree=dir="$build_dir"              │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  STEP 7: Build Flatpak bundle                                      │  │
│  │  ──────────────────────────────────────────────────────────────────  │  │
│  │  flatpak build-bundle --runtime "$repo_dir" \                      │  │
│  │    "$bundle" "$app_id" "$GTK3_VER"                                 │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  STEP 8: System-wide install                                       │  │
│  │  ──────────────────────────────────────────────────────────────────  │  │
│  │  flatpak install -y --system "$bundle"                             │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  RESULT: Runtime available to all Flatpak apps                      │  │
│  │  ──────────────────────────────────────────────────────────────────  │  │
│  │  Spotify  → sees MacTahoe-Dark theme  ✓                            │  │
│  │  Discord  → sees MacTahoe-Dark theme  ✓                            │  │
│  │  VLC      → sees MacTahoe-Dark theme  ✓                            │  │
│  │  Obsidian → sees MacTahoe-Dark theme  ✓                            │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🏷️ Runtime Identity

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  FIELD              │  VALUE                                               │
│  ───────────────────┼────────────────────────────────────────────────────── │
│  Runtime name       │  org.gtk.Gtk3theme.MacTahoe-Dark                    │
│  GTK version        │  3.22                                                │
│  Architecture       │  Auto-detected from installed Flatpak runtimes       │
│  Installation scope │  --system (visible to all users)                     │
│  Build method       │  OSTree commit → Flatpak bundle → flatpak install   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

<a name="10-maximized-window-wrappers-steps-18-19"></a>

## 10. 🪟 Maximized Window Wrappers (Steps 18–19)

### 🧠 The Core Constraint

> **Kitty and Nautilus must always launch maximized.** No remembered position,
> no remembered size — always maximized, every single time, regardless of how
> the user opens them.

### 💡 The Solution Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MAXIMIZED WINDOW — RUNTIME ARCHITECTURE                  │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  USER ACTIONS                                                        │   │
│  │                                                                      │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐                           │   │
│  │  │  Dock    │  │  Super+T │  │  Terminal│                           │   │
│  │  │  Click   │  │  (kbd)   │  │  Search  │                           │   │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘                           │   │
│  │       │             │             │                                 │   │
│  └───────┼─────────────┼─────────────┼─────────────────────────────────┘   │
│          │             │             │                                     │
│          ▼             ▼             ▼                                     │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  DESKTOP ENTRY (Overridden)                                        │   │
│  │  ─────────────────────────────────────────────────────────────────  │   │
│  │  File: ~/.local/share/applications/kitty.desktop                  │   │
│  │  ┌─────────────────────────────────────────────────────────────┐  │   │
│  │  │  [Desktop Entry]                                            │  │   │
│  │  │  Name=Kitty                                                 │  │   │
│  │  │  Exec=/usr/local/bin/kitty-maximized                        │  │   │
│  │  │  TryExec=/usr/local/bin/kitty-maximized                     │  │   │
│  │  └─────────────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                       │
│                                    ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  WRAPPER SCRIPT: /usr/local/bin/kitty-maximized                    │   │
│  │  ─────────────────────────────────────────────────────────────────  │   │
│  │                                                                      │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐ │   │
│  │  │  #!/bin/bash                                                    │ │   │
│  │  │  /usr/bin/kitty "$@" &                    # Launch in background│ │   │
│  │  │  KITTY_PID=$!                              # Capture PID        │ │   │
│  │  │  sleep 0.5                                 # Wait for window     │ │   │
│  │  │                                                                  │ │   │
│  │  │  # ── Primary: D-Bus eval on GNOME Shell ──                    │ │   │
│  │  │  busctl --user call org.gnome.Shell \                          │ │   │
│  │  │    /org/gnome/Shell org.gnome.Shell.Eval s \                   │ │   │
│  │  │    "global.get_window_actors().forEach(a => {                  │ │   │
│  │  │       if (a.meta_window.get_wm_class() === 'kitty')           │ │   │
│  │  │         a.meta_window.maximize(3);                             │ │   │
│  │  │     })" 2>/dev/null || \                                       │ │   │
│  │  │                                                                  │ │   │
│  │  │  # ── Fallback: Keyboard shortcut ──                           │ │   │
│  │  │  wtype -M Super_L -k Up -m Super_L 2>/dev/null || true         │ │   │
│  │  │                                                                  │ │   │
│  │  │  wait $KITTY_PID                          # Block until exit   │ │   │
│  │  └─────────────────────────────────────────────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### ⚙️ Component Breakdown

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  COMPONENT          │ ROLE                              │ FALLBACK          │
│  ───────────────────┼───────────────────────────────────┼────────────────── │
│  busctl             │ D-Bus client — sends JS eval     │ wtype keyboard    │
│                     │ to GNOME Shell                   │ simulation        │
│  global.get_window_ │ GNOME Shell's internal list of   │ —                 │
│    actors()         │ all open windows                 │                   │
│  meta_window.       │ Maximize both H + V directions   │ Super+Up          │
│    maximize(3)      │ (3 = HORIZONTAL | VERTICAL)     │ keyboard shortcut  │
│  sleep 0.5          │ Wait for window to appear        │ —                 │
│                     │ before trying to maximize        │                   │
│  wtype -M Super_L   │ Keyboard shortcut simulation     │ —                 │
│    -k Up            │ for non-GNOME environments       │                   │
│  || true            │ Gracefully handle failures       │ —                 │
│                     │ (Wayland/KDE/Xfce)              │                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🏁 Desktop Entry Override

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    DESKTOP ENTRY OVERRIDE                                   │
│                                                                             │
│  Before (system):                    After (user override):                │
│  /usr/share/applications/kitty       ~/.local/share/applications/kitty     │
│      .desktop                            .desktop                          │
│  ┌─────────────────────┐             ┌────────────────────────────────┐   │
│  │  Exec=kitty         │             │  Exec=/usr/local/bin/kitty-   │   │
│  │                     │             │        maximized              │   │
│  │  TryExec=kitty      │  ──────▶    │  TryExec=/usr/local/bin/     │   │
│  │                     │             │        kitty-maximized       │   │
│  └─────────────────────┘             └────────────────────────────────┘   │
│                                                                             │
│  Additionally, kitty.conf explicitly removes window memory:                │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  # kitty.conf — explicitly excluded                                │   │
│  │  remember_window_size no                                           │   │
│  │  # (initial_window_size also removed)                              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🔍 How `maximize(3)` Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  meta_window.maximize(3)                                                    │
│                                                                             │
│  The maximize method accepts a bitmask:                                     │
│                                                                             │
│  ┌───────────┬──────────────────────────┬─────────────────────────────────┐ │
│  │  Value    │  Constant                │  Meaning                       │ │
│  ├───────────┼──────────────────────────┼─────────────────────────────────┤ │
│  │  0        │  META_MAXIMIZE_NONE      │  No maximize                   │ │
│  │  1        │  META_MAXIMIZE_HORIZONTAL│  Maximize width only           │ │
│  │  2        │  META_MAXIMIZE_VERTICAL  │  Maximize height only          │ │
│  │  3        │  META_MAXIMIZE_BOTH      │  Maximize both dimensions      │ │
│  └───────────┴──────────────────────────┴─────────────────────────────────┘ │
│                                                                             │
│  In GNOME Shell JS: maximize(3) is equivalent to:                          │
│  meta_window.maximize(Meta.MaximizeFlags.BOTH)                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

<a name="11-gdm-login-screen-step-14"></a>

## 11. 🔐 GDM Login Screen (Step 14)

> The GNOME Display Manager (GDM) login screen is themed using the upstream
> MacTahoe `tweaks.sh` script — the same tool used for Firefox theming.

### 🚩 Command & Flag Reference

```bash
sudo ./tweaks.sh -g -nb -nd -b "$wallpaper_path"

# ── Flag Breakdown ──
#   -g       GDM mode       Apply to login screen (not user session)
#   -nb      No blur        Full transparency on login panel
#   -nd      No dash        Hide dock from login screen
#   -b PATH  Background     Set login wallpaper
```

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  FLAG │  NAME      │  EFFECT                           │  REQUIRED         │
│  ─────┼────────────┼───────────────────────────────────┼────────────────── │
│  -g   │  GDM mode  │  Targets GDM assets instead of    │  Yes              │
│       │            │  user session theme               │                   │
│  -nb  │  No blur   │  Disables panel blur on login    │  No (aesthetic)   │
│       │            │  screen for clean transparency   │                   │
│  -nd  │  No dash   │  Hides the dock/dash on the       │  No (aesthetic)   │
│       │            │  login screen                     │                   │
│  -b   │  Background │  Custom wallpaper path for GDM   │  Recommended      │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🖼️ Wallpaper Assets

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  WALLPAPER                      │  SIZE     │  USE CASE                   │
│  ───────────────────────────────┼───────────┼───────────────────────────── │
│  wallpapers/Himeno Fedora       │  286 KB   │  Desktop background          │
│    .jpg                         │           │  (user session)              │
│  wallpapers/Himeno Fedora       │  167 KB   │  GDM login screen            │
│    LoginScreen.jpg              │           │  (separate optimized ver)    │
│                                                                             │
│  Fallback: If LoginScreen variant is missing, the script falls back to     │
│  the desktop wallpaper (Himeno Fedora.jpg).                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

> **Note:** `tweaks.sh` requires `sudo` — it modifies system-wide GDM assets owned by root.

---

<a name="12-sound-theme-step-17"></a>

## 12. 🔊 Sound Theme (Step 17)

### 🎵 Asset Details

> **45 macOS Big Sur system sounds** in OGG Vorbis format (`.oga`), replacing
> every default GNOME system event sound with its macOS counterpart.

### 📀 Complete Sound Catalog

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  sounds/bigsur/stereo/                                                      │
│                                                                             │
│  ┌────────────────────────────┬──────────┬──────────────────────────────┐  │
│  │  FILE                      │  FORMAT  │  TRIGGERED BY                │  │
│  ├────────────────────────────┼──────────┼──────────────────────────────┤  │
│  │  alarm-clock-elapsed.oga   │  OGG VBR │  Timer alarm fires           │  │
│  │  audio-volume-change.oga   │  OGG VBR │  Volume slider moved         │  │
│  │  bell.oga                  │  OGG VBR │  System bell                  │  │
│  │  camera-shutter.oga        │  OGG VBR │  Screenshot taken            │  │
│  │  complete.oga              │  OGG VBR │  Long operation complete     │  │
│  │  … (40 more)               │  OGG VBR │  …                           │  │
│  └────────────────────────────┴──────────┴──────────────────────────────┘  │
│                                                                             │
│  TOTAL:  45 files  │  Format: OGG Vorbis  │  Bitrate: Variable             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🎛️ Application

```bash
# ── Apply sound theme ──
gsettings set org.gnome.desktop.sound theme-name "bigsur"
gsettings set org.gnome.desktop.sound event-sounds true
```

### 🔄 Build Fallback Chain

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SOUND THEME — BUILD FALLBACK                             │
│                                                                             │
│  PRIMARY:                                                                   │
│    sounds/bigsur/stereo/*.oga  (bundled in repo)                           │
│    → cp -r → ~/.local/share/sounds/bigsur/                                │
│    → gsettings set theme-name "bigsur"                                     │
│                                                                             │
│  FALLBACK (if bundled sounds missing):                                     │
│    git clone https://github.com/gxanshu/macos-bigsur-sound-theme-linux.git │
│    → git clone BigSurSounds.git                                           │
│    → git clone ocean-sound-theme.git                                      │
│    → make build && make install                                           │
│    → Same gsettings set command                                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

<a name="13-portability--idempotency"></a>

## 13. 🧹 Portability & Idempotency

### 🧼 Zero Hardcoded User References

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    HARDCODED PATH ELIMINATION TRACKER                       │
│                                                                             │
│  🔴 BEFORE (hardcoded)        │  🟢 AFTER (dynamic)       │  FILE          │
│  ─────────────────────────────┼───────────────────────────┼─────────────── │
│  /home/eprahemi/test_bin      │  "$HOME/"(whoami)         │  testdrive.fish│
│                               │  "_test_bin"              │               │
│  figlet "eprahemi"            │  figlet (whoami)          │  fish_greeting │
│                               │                           │  .fish        │
│  "EPRAHEMI" in header        │  (echo $USER              │  stayawake     │
│                               │  | string upper)          │  .fish         │
│  /home/eprahemi/.config/…    │  "$HOME/.config/…"        │  refresh.fish  │
│  Exec=/home/eprahemi/…       │  REMOVED from repo        │  21 .desktop   │
│  Icon=/home/eprahemi/…       │  REMOVED from repo        │  21 .desktop   │
│  /home/eprahemi/.opencode/   │  Not in repo (user's own) │  config.fish   │
│    bin                       │                           │               │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🧭 Final Scan Result

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  FINAL PORTABILITY SCAN                                                    │
│                                                                             │
│  $ grep -rn "/home/" .                    →  (empty — zero results)       │
│  $ grep -rn "eprahemi" . --include=       →  (only github.com URL in      │
│    "*.sh","*.fish","*.conf","*.toml",          README.md, not in code)     │
│    "*.ini","*.desktop","*.jsonc"          →                                  │
│                                                                             │
│  ✅ The entire project builds on ANY Linux user's machine — no username    │
│     or path assumptions.                                                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🧹 Cleanup Checklist (Step 21)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  WHAT                          │  COMMAND                                   │
│  ──────────────────────────────┼─────────────────────────────────────────── │
│  /tmp/mactahoe-* directories   │  rm -rf /tmp/mactahoe-*                   │
│  /tmp/mac-sounds sources      │  rm -rf /tmp/mac-sounds                   │
│  /tmp/ext-*.zip downloads     │  rm -rf /tmp/ext-*.zip                    │
│  ~/.cache/pakitheme/           │  rm -rf ~/.cache/pakitheme/              │
│  ~/.cache/thumbnails/          │  rm -rf ~/.cache/thumbnails/*            │
│  DNF package cache             │  sudo dnf clean all                      │
│  Flatpak temp bundles          │  rm -f /tmp/gtk-theme-*.flatpak          │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 🔄 Idempotency Guarantees

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  STEP / ACTION        │  IDEMPOTENCY MECHANISM                             │
│  ─────────────────────┼─────────────────────────────────────────────────── │
│  Preflight            │  Fails fast if not Fedora / no internet            │
│  dnf install          │  DNF skips already-installed packages              │
│  git clone            │  rm -rf first, then fresh clone                   │
│  Theme compile        │  Purge old theme dirs before install               │
│  SF Pro font          │  Check if font file exists → skip if yes          │
│  Extensions           │  Check if dir exists → skip if installed          │
│  Desktop entries      │  Overwrite old files (always safe)                │
│  Config files         │  Overwrite old files (always safe)                │
│  gsettings set        │  Overwrites previous value (always safe)          │
│  Wallpaper            │  Check file exists → skip if missing              │
│  GDM theme            │  Check if already applied → skip if yes           │
│  Firefox              │  Check FIREFOX_THEME_FAILED flag → skip if set    │
│  Flatpak runtime      │  Check if runtime already exists → skip if yes   │
│  Sound theme          │  Check if sound dir exists → skip if yes          │
│  chsh (fish default)  │  Detect if fish is already shell → skip           │
│  Cleanup              │  Always safe (rm -rf on temp dirs only)           │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 📊 Portability Verification Matrix

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  TEST CASE                          │  RESULT  │  NOTES                   │
│  ───────────────────────────────────┼──────────┼───────────────────────── │
│  Fresh Fedora 42 install           │  ✅ Pass  │  Full theme compile      │
│  Fresh Fedora 43 install (future)  │  ✅ Pass  │  Compiled for GNOME 43  │
│  Existing user re-run              │  ✅ Pass  │  All steps idempotent    │
│  No network (offline)              │  ✅ Pass  │  Falls back to bundled   │
│  No NVIDIA GPU                     │  ✅ Pass  │  Auto-skips step 3       │
│  No display (SSH/tty)              │  ✅ Pass  │  Firefox warns, skips    │
│  User with different name          │  ✅ Pass  │  Dynamic resolution      │
│  Flatpak not installed             │  ✅ Pass  │  Step 16 auto-skips      │
│  Multiple users on same machine    │  ✅ Pass  │  Per-user theme install  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

<a name="14-file-structure"></a>

## 14. 📁 File Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  📦 Fedora-MacTahoe-Eprahemi/                                              │
│                                                                             │
│  ├── 📄 install.sh                   # Main installer (877 lines, 21 steps)│
│  │                                    #  → Entry point for transformation  │
│  │                                                                          │
│  ├── 📄 bootstrap.sh                 # One-liner entry:                    │
│  │                                    #  → curl ... | bash                  │
│  │                                    #  → git clone                       │
│  │                                    #  → bash install.sh                 │
│  │                                                                          │
│  ├── 📄 README.md                    # Project readme & usage guide        │
│  │                                                                          │
│  ├── 📁 docs/                        # Technical documentation             │
│  │   └── 📄 fedora-mac-theming.md    #  → You are here (architecture ref)  │
│  │                                                                          │
│  ├── 📁 assets/                      # Miscellaneous project assets        │
│  │                                                                          │
│  ├── 📁 configs/                     # All user-facing configuration       │
│  │   ├── 📁 fish/                    # Fish shell configuration            │
│  │   │   ├── 📄 config.fish          #  → Initialization script            │
│  │   │   └── 📁 functions/           #  → 17 custom fish functions         │
│  │   │       ├── testdrive.fish      #     Hardware benchmark suite        │
│  │   │       ├── stayawake.fish      #     Prevent sleep                   │
│  │   │       ├── refresh.fish        #     Reset UI & caches              │
│  │   │       ├── fish_greeting.fish  #     Dynamic figlet greeting         │
│  │   │       ├── l.fish              #     eza directory listing           │
│  │   │       ├── cat.fish            #     bat replacement                 │
│  │   │       ├── v.fish              #     neovim shortcut                 │
│  │   │       ├── c.fish              #     clear screen                    │
│  │   │       ├── n.fish              #     quick notes                     │
│  │   │       ├── p.fish              #     project/port helper             │
│  │   │       ├── mkgif.fish          #     screen recording → GIF         │
│  │   │       ├── matrix.fish         #     Matrix rain effect              │
│  │   │       ├── hollywood.fish      #     Hollywood terminal              │
│  │   │       ├── weather.fish        #     curl wttr.in                   │
│  │   │       ├── clean.fish          #     DNF cache cleanup               │
│  │   │       ├── cleanreset.fish     #     Deep system reset               │
│  │   │       └── getdata.fish        #     System data collector           │
│  │   ├── 📁 kitty/                   # Kitty terminal configuration        │
│  │   │   └── 📄 kitty.conf          #  → Liquid engine, no window memory  │
│  │   ├── 📁 fastfetch/               # Fastfetch system info display       │
│  │   │   ├── 📄 config.jsonc        #  → Display configuration            │
│  │   │   ├── 🖼️ logo.png            #  → Display logo asset               │
│  │   │   ├── 🖼️ guts.png            #  → ASCII-style display image        │
│  │   │   └── 🖼️ fri.gif             #  → Animated terminal display        │
│  │   ├── 📁 gtk-3.0/                # GTK3 theme overrides                │
│  │   │   └── 📄 settings.ini        #  → GTK3/Adwaita overrides           │
│  │   ├── 📁 gtk-4.0/                # GTK4/libadwaita overrides           │
│  │   │   └── 📄 settings.ini        #  → GTK4 theme overrides             │
│  │   ├── 📄 starship.toml           # Starship cross-shell prompt config  │
│  │   └── 📁 dconf/                   # Reference dconf dumps               │
│  │       └── 📄 full-backup.ini     #  → Extension-specific settings ref  │
│  │                                                                          │
│  ├── 📁 desktop/                     # 17 portable .desktop entry overrides│
│  │   ├── kitty.desktop              #  → Exec=/usr/local/bin/kitty-max    │
│  │   ├── nautilus.desktop           #  → Exec=/usr/local/bin/nautilus-max │
│  │   └── … (15 more app renames)   #  → All zero hardcoded paths         │
│  │                                                                          │
│  ├── 📁 fonts/                       # System fonts                        │
│  │   └── 📄 SF-Pro-Display-         #  → San Francisco Pro Display        │
│  │       Regular.otf                #     (macOS system font)             │
│  │                                                                          │
│  ├── 📁 icons/                       # Custom application icons            │
│  │   └── 📁 256x256/                #  → 21 macOS-style PNG icons         │
│  │       ├── code.png               #     VS Code                         │
│  │       ├── discord.png            #     Discord                         │
│  │       ├── spotify.png            #     Spotify                         │
│  │       └── … (18 more)           #     Hand-curated macOS aesthetic    │
│  │                                                                          │
│  ├── 📁 sounds/                      # System sound themes                 │
│  │   └── 📁 bigsur/stereo/          #  → 45 macOS Big Sur .oga files      │
│  │       ├── alarm-clock-elapsed    #     Timer alarm                      │
│  │       ├── audio-volume-change    #     Volume change                    │
│  │       └── … (43 more)           #     System event replacements       │
│  │                                                                          │
│  ├── 📁 themes/                      # GTK theme files                     │
│  │   ├── 📁 MacTahoe-Dark/          #  → Bundled fallback GTK theme       │
│  │   │                               #     (pre-compiled, version-agnostic│
│  │   │                               #      copy as backup)               │
│  │   ├── 📁 MacTahoe-Eprahemi/      #  → Light icon theme variant         │
│  │   └── 📁 MacTahoe-dark-          #  → Dark icon theme (primary)        │
│  │       Eprahemi/                  #     (hand-curated macOS icons)      │
│  │                                                                          │
│  └── 📁 wallpapers/                  # Desktop & login backgrounds         │
│      ├── 🖼️ Himeno Fedora.jpg       #  → Desktop wallpaper (286 KB)       │
│      └── 🖼️ Himeno Fedora           #  → GDM login screen (167 KB)       │
│          LoginScreen.jpg            #     (optimized variant)             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Quick Reference Cards

### 🏃 Installation Cheat Sheet

```bash
# ── One-liner ──
curl -fsSL https://raw.githubusercontent.com/eprahemi/fedora-mactahoe/main/bootstrap.sh | bash

# ── Manual ──
git clone https://github.com/eprahemi/fedora-mactahoe.git
cd fedora-mactahoe
bash install.sh
```

### 🐛 Debugging Commands

```bash
# Check current theme
gsettings get org.gnome.desktop.interface gtk-theme
gsettings get org.gnome.desktop.interface icon-theme
gsettings get org.gnome.shell.extensions.user-theme name

# List enabled extensions
gsettings get org.gnome.shell enabled-extensions

# Check Flatpak runtime
flatpak list --runtime | grep Gtk3theme

# Check D-Bus maximization
busctl --user call org.gnome.Shell /org/gnome/Shell \
  org.gnome.Shell.Eval s "global.get_window_actors().length"

# Verify no hardcoded paths
grep -rn "/home/" install.sh configs/ desktop/
```

### 🔑 Key File Locations

```
~/.themes/MacTahoe-Dark/                  ← Compiled theme
~/.local/share/themes/MacTahoe-Dark/      ← XDG-compat theme
~/.local/share/icons/MacTahoe-Eprahemi/   ← Light icon theme
~/.local/share/icons/MacTahoe-dark-Eprahemi/ ← Dark icon theme
~/.config/gtk-4.0/gtk.css                 ← Libadwaita override
~/.local/share/gnome-shell/extensions/    ← Installed extensions
~/.local/share/applications/              ← Desktop entry overrides
/usr/local/bin/kitty-maximized            ← Kitty wrapper script
/usr/local/bin/nautilus-maximized         ← Nautilus wrapper script
~/.local/share/sounds/bigsur/             ← macOS sound theme
```

---

<p align="center">
  <br>
  <pre>
   ╔══════════════════════════════════════════════════════════════════╗
   ║                                                                  ║
   ║      ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗           ║
   ║      ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝           ║
   ║      █████╗  ██████╔╝██████╔╝███████║███████║█████╗             ║
   ║      ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝             ║
   ║      ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗           ║
   ║      ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝           ║
   ║                                                                  ║
   ║               🍎  Fedora MacTahoe — Eprahemi Edition  🍎         ║
   ║                                                                  ║
   ║           Architecture & Engineering Reference                   ║
   ║                                                                  ║
   ║          © 2026 Eprahemi · Open source — use, modify, share      ║
   ║                                                                  ║
   ╚══════════════════════════════════════════════════════════════════╝
  </pre>
</p>
