# Fedora MacTahoe — Technical Architecture

## Overview

This document describes the architecture, design decisions, and implementation details
of the Fedora MacTahoe — Eprahemi Edition desktop transformation project.

The project is a single `install.sh` script (877 lines, 21 steps) that converts a
stock Fedora Workstation into a macOS-inspired environment. Everything is bundled
locally — no external dependencies beyond the initial clone.

---

## 1. Theme Compilation (Step 7)

### Decision: Compile from upstream instead of bundling pre-compiled CSS

**Problem:** The MacTahoe theme produces different CSS for different GNOME Shell
versions. Bundling a pre-compiled theme meant it would only work correctly on the
GNOME version it was built for.

**Solution:** Clone `https://github.com/vinceliuice/MacTahoe-gtk-theme.git` and run
its `install.sh -t all -b -l` at install time. This compiles the theme for the
current GNOME Shell version.

- `-t all` — installs all variants (gnome-shell, gtk3, gtk4, metacity, xfwm, etc.)
- `-b` — enables blur (transparent panel effect)
- `-l` — copies gtk-4.0 CSS to `~/.config/gtk-4.0/` for libadwaita

**Fallback:** If the clone fails, the bundled `themes/MacTahoe-Dark/` directory is
used as a pre-compiled fallback.

### Name normalization

The upstream theme produces a directory called `MacTahoe-Dark`. The old bundle used
`MacTahoe-Dark-Eprahemi`. These are byte-identical — only the directory name differs.
All references now use `MacTahoe-Dark`.

### Icon themes (always bundled)

Custom icon themes `MacTahoe-Eprahemi` and `MacTahoe-dark-Eprahemi` are bundled and
never compiled — they contain hand-curated replacements that differ from upstream.

---

## 2. Custom Application Icons (Step 7, within theme function)

21 macOS-style PNG icons in `icons/256x256/` are deployed into three target directories:

- `MacTahoe-dark-Eprahemi/apps/scalable/`
- `MacTahoe-Eprahemi/apps/scalable/`
- `hicolor/256x256/apps/`

**Flatpak compatibility:** Flatpak applications require icons named by their full
reverse-DNS ID (e.g., `com.spotify.Client.png`). The script maintains an alias map:

| Short name | Flatpak ID |
|---|---|
| `spotify.png` | `com.spotify.Client.png` |
| `discord.png` | `com.discordapp.Discord.png` |
| `vlc.png` | `org.videolan.VLC.png` |
| `code.png` | `com.visualstudio.code.png` |

Icons already named by Flatpak ID (e.g., `com.github.tchx84.Flatseal.png`) are copied
directly and need no alias.

Each PNG is trimmed, padded, and resized to 256×256 via ImageMagick (`magick` or
`convert`).

---

## 3. Fish Shell Functions

17 custom fish functions in `configs/fish/functions/`. Every function uses dynamic
username resolution — no hardcoded names.

| Function | Purpose | Key dynamic pattern |
|---|---|---|
| `testdrive.fish` | Disk/CPU/RAM benchmarking suite | `(whoami)_test_bin`, `(echo $USER | string upper)` |
| `stayawake.fish` | Inhibit lid-sleep with timer | `(echo $USER | string upper)` |
| `refresh.fish` | Reset UI, caches, portals | `$HOME`, `(echo $USER | string upper)` |
| `fish_greeting.fish` | Display figlet on shell start | `(whoami)` |
| `cat.fish` | cat replacement with bat/syntax | — |
| `c.fish` | Quick clear | — |
| `clean.fish` | Package cache cleanup | — |
| `hollywood.fish` | Hollywood-style terminal output | — |
| `matrix.fish` | Matrix rain effect | — |
| `mkgif.fish` | Screen-to-GIF recording | — |
| `l.fish` | eza-based directory listing | — |
| `n.fish` | Quick notes | — |
| `p.fish` | Port/project helper | — |
| `v.fish` | neovim shortcut | — |
| `weather.fish` | curl wttr.in | — |
| `getdata.fish` | System data collector | — |
| `cleanreset.fish` | Deep cleanup alias | — |

The `config.fish` sets `$TERMINAL`, `$TERM`, `$ANI_CLI_PLAYER`, enables Starship,
and runs `fastfetch` on interactive start. It does **not** contain opencode paths
or user-specific configuration — those belong in the user's personal config.

---

## 4. GNOME Extension Management (Step 9)

**Decision:** Use `gsettings set org.gnome.shell enabled-extensions` instead of
`gnome-extensions enable`.

**Problem:** `gnome-extensions enable` communicates over D-Bus to the running GNOME
Shell session. On freshly created users who have never logged into GNOME, there is
no D-Bus session, so the command silently fails.

**Solution:** Build a list of installed extension UUIDs and apply them via gsettings
directly, which writes to the dconf database without requiring a running session.

**Extension download:** Each UUID is fetched from `extensions.gnome.org` using the
EGO API with the detected shell version. Failed downloads (no internet, EGO down,
incompatible version) are silently skipped.

14 extensions are installed:

| UUID | Purpose |
|---|---|
| `blur-my-shell@aunetx` | Transparent/blurred panel and windows |
| `user-theme@gnome-shell-extensions.gcampax.github.com` | Load custom GTK theme |
| `logomenu@aryan_k` | macOS-style Apple menu |
| `AlphabeticalAppGrid@stuarthayhurst` | Sorted app grid |
| `pinned-apps-in-appgrid@brunosilva.io` | Pinned apps in grid |
| `app-hider@lynith.dev` | Hide apps from grid |
| `compiz-alike-magic-lamp-effect@hermes83.github.com` | Minimize animation |
| `compiz-windows-effect@hermes83.github.com` | Window open/close effects |
| `CoverflowAltTab@palatis.blogspot.com` | CoverFlow-style Alt+Tab |
| `clipboard-history@alexsaveau.dev` | Clipboard manager |
| `ding@rastersoft.com` | Desktop icons |
| `Bluetooth-Battery-Meter@maniacx.github.com` | Bluetooth battery levels |
| `dash2dock-lite@icedman.github.com` | macOS-style dock |
| `appindicatorsupport@rgcjonas.gmail.com` | Tray icons |

### dash2dock-lite configuration (applied via dconf)

- Autohide dash: enabled
- Click action: minimize-or-previews
- Icon size: 0.25
- Running indicator style: 4 (dots)
- Show favorites and running applications
- Dock padding: 0.5
- Border radius: 3.0
- Custom labels: enabled

---

## 5. GNOME dconf Settings (Step 12)

Settings are applied via `gsettings` and `dconf` commands rather than importing a
raw dump — this makes the script self-documenting and resilient to schema changes.

### Theme
- GTK theme: `MacTahoe-Dark`
- Icon theme: `MacTahoe-dark-Eprahemi`
- Cursor theme: `MacTahoe-dark-Eprahemi`
- Shell theme: `MacTahoe-Dark` (via user-theme extension)

### Interface
- Font: SF Pro Display 11 (interface), 12 (documents)
- Monospace: Adwaita Mono 11
- Color scheme: prefer-dark
- Hinting: slight · Antialiasing: grayscale · Accent: blue
- Clock: 12h, date shown, seconds hidden, weekday hidden
- Animations: enabled
- Window buttons: close,minimize,maximize:appmenu

### Peripherals
- Touchpad: tap-to-click, natural scroll, two-finger scrolling, click method: fingers
- Mouse: default acceleration profile, natural scroll off

### Workspaces
- Dynamic workspaces (GNOME 40+ vertical model)
- Workspaces only on primary display
- Super+1-9: switch to workspace
- Super+Shift+1-9: move window to workspace
- Ctrl+Left/Right: workspace navigation

### Custom keybindings
| Key | Action |
|---|---|
| Super+T | Kitty terminal |
| Super+E | Nautilus file manager |
| Ctrl+Shift+Esc | System monitor |
| Ctrl+Alt+V | PulseAudio volume control |
| Super+Q | Close window |

### Dock favorites
Nautilus, Firefox, Chrome, Edge, Discord, Kitty, Software

### Session
- Idle delay: 0 (never sleep)
- Privacy: report-technical-problems disabled

### Nautilus
- Default zoom: large
- Recursive search: always
- Image thumbnails: always
- Directory item counts: always
- Window state: maximized

---

## 6. Firefox Theming (Step 15)

**Decision:** Do not attempt to initialize Firefox without a display.

**Problem:** Firefox creates its profile directory on first launch. Without a display
(or `firefox --headless`), the profile is not created. `tweaks.sh -f` cannot apply
the userChrome.css theme without an existing profile.

**History:**
1. `firefox --headless` — fails on systems without a GPU/display
2. `firefox -CreateProfile "default"` — also fails without DISPLAY
3. **Final:** Try `tweaks.sh -f`, catch failure, set `FIREFOX_THEME_FAILED=1`,
   print warning at end: log in, launch Firefox once, re-run script

The final message states:
> Firefox not themed — log into your user, launch Firefox once, then re-run:
> bash install.sh

---

## 7. Flatpak GTK Runtime (Step 16)

Flatpak applications sandbox their theme access. To apply the MacTahoe-Dark theme to
Flatpak apps, an `org.gtk.Gtk3theme.MacTahoe-Dark` runtime must be installed.

**Process:**
1. Install `ostree` and `libappstream-glib` (if missing)
2. Locate the installed `MacTahoe-Dark` theme in `~/.themes/`, `~/.local/share/themes/`,
   or `/usr/share/themes/`
3. Initialize an OSTree repository in a cache directory
4. Copy theme assets (gtk.css, gtk-dark.css, assets, windows-assets) into a build tree
5. Create appdata XML for the runtime
6. Run `appstream-compose` to generate metadata
7. Commit to OSTree as `runtime/org.gtk.Gtk3theme.MacTahoe-Dark/$arch/$GTK3_VER`
8. Build a Flatpak bundle for each detected architecture
9. Install each bundle via `flatpak install --system`

This produces a self-contained Flatpak runtime that matches the system GTK theme.

---

## 8. Maximized Window Wrappers (Steps 18–19)

**Constraint:** Kitty and Nautilus must **always** launch maximized, with no
remembered window position or size.

**Solution:** Mutter D-Bus API wrapper scripts at `/usr/local/bin/`:

### kitty-maximized
```bash
#!/bin/bash
/usr/bin/kitty "$@" &
KITTY_PID=$!
sleep 0.5
busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Eval s \
  "global.get_window_actors().forEach(a => { if (a.meta_window.get_wm_class() === 'kitty') a.meta_window.maximize(3); })"
wait $KITTY_PID
```

### nautilus-maximized
Same pattern, targets `wm_class === 'nautilus'`.

**Fallback:** If the D-Bus call fails (e.g., no GNOME Shell running), `wtype` simulates
Super+Up to maximize the window.

**Integration:** Desktop entries in `~/.local/share/applications/` override the Exec
line to point to the wrapper scripts. `gsettings set org.gnome.nautilus.window-state
maximized true` is also applied.

**Kitty config:** `remember_window_size no` is enforced — the terminal always opens
at a default size and is maximized by the wrapper.

---

## 9. Shell Setup (Step 20)

Fish is set as the default shell via `chsh -s /usr/bin/fish "$USER"`. The change
takes effect on next login.

Kitty replaces ptyxis (Fedora's default terminal emulator):

```bash
sudo ln -sf /usr/bin/kitty /usr/bin/gnome-terminal
sudo ln -sf /usr/bin/kitty /usr/bin/x-terminal-emulator
gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty'
```

Ptyxis and GNOME Console desktop entries are removed.

---

## 10. GDM Login Screen (Step 14)

The upstream MacTahoe repository's `tweaks.sh` is used to theme GNOME Display Manager:

```bash
sudo ./tweaks.sh -g -nb -nd -b "$wallpaper_path"
```

- `-g` — apply to GDM
- `-nb` — no blur (full transparency)
- `-nd` — no dash
- `-b` — custom background image

The chosen wallpaper (`Himeno Fedora LoginScreen.jpg`) is bundled in `wallpapers/`.

---

## 11. Sound Theme (Step 17)

macOS Big Sur system sounds: 45 `.oga` files in `sounds/bigsur/stereo/`.

Applied via:
```bash
gsettings set org.gnome.desktop.sound theme-name "bigsur"
gsettings set org.gnome.desktop.sound event-sounds true
```

**Fallback:** If sounds are not bundled, the script clones
`https://github.com/gxanshu/macos-bigsur-sound-theme-linux.git` and builds from
source.

---

## 12. Portability and Idempotency

### Zero hardcoded user references

Every reference to a user-specific path uses `$HOME`, `$USER`, or `$(whoami)`:

| Original (hardcoded) | Fixed (dynamic) |
|---|---|
| `/home/eprahemi/test_bin` | `"$HOME/"(whoami)"_test_bin"` |
| `figlet "eprahemi"` | `figlet (whoami)` |
| `"EPRAHEMI"` in stayawake | `(echo $USER | string upper)` |
| `/home/eprahemi/.opencode/bin` | removed from repo (user installs separately) |
| `desktop/*.desktop` with `/home/eprahemi/` paths | 21 files removed from repo |

### Cleanup

Every temp file is removed in `finalize()`:
- `/tmp/mactahoe-*` — cloned theme repositories
- `/tmp/mac-sounds` — cloned sound repository
- `/tmp/ext-*.zip` — downloaded extensions
- `~/.cache/pakitheme/` — Flatpak runtime build cache
- `~/.cache/thumbnails/` — generated thumbnail cache
- `sudo dnf clean all` — package manager cache

---

## 13. File Structure

```
.
├── install.sh                      # Main installer (877 lines, 21 steps)
├── bootstrap.sh                    # One-liner entry point (clones + runs)
├── README.md
├── docs/
│   └── fedora-mac-theming.md       # This document
├── assets/                         # Misc assets
├── configs/
│   ├── fish/
│   │   ├── config.fish             # Fish initialization
│   │   └── functions/              # 17 custom fish functions
│   ├── kitty/
│   │   └── kitty.conf              # Kitty terminal configuration
│   ├── fastfetch/
│   │   ├── config.jsonc            # Fastfetch configuration
│   │   └── *.png / *.gif           # Fastfetch logo assets
│   ├── gtk-3.0/
│   │   └── settings.ini            # GTK3 settings
│   ├── gtk-4.0/
│   │   └── settings.ini            # GTK4 settings
│   ├── starship.toml               # Starship prompt config
│   └── dconf/
│       └── full-backup.ini         # Extension-specific dconf settings
├── desktop/                        # 17 portable .desktop entries
├── fonts/
│   └── SF-Pro-Display-Regular.otf  # SF Pro Display font
├── icons/
│   └── 256x256/                    # 21 macOS-style app PNGs
├── sounds/
│   └── bigsur/stereo/              # 45 macOS Big Sur .oga files
├── themes/
│   ├── MacTahoe-Dark/              # Fallback GTK theme (pre-compiled)
│   ├── MacTahoe-Eprahemi/          # Light icon theme
│   └── MacTahoe-dark-Eprahemi/     # Dark icon theme
└── wallpapers/
    ├── Himeno Fedora.jpg           # Desktop wallpaper
    └── Himeno Fedora LoginScreen.jpg  # GDM wallpaper
```
