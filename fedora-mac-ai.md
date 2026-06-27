# Fedora MacTahoe — Eprahemi Edition
## Complete System Knowledge File (AI Brain)

**📍 Location:** `fedora-mac-ai.md` (in repo root)
**📁 Full path:** `$REPO_DIR/fedora-mac-ai.md`
**ℹ️  Read this file first at the start of every session.**

---

## 1. PROJECT OVERVIEW

Fedora MacTahoe is a Fedora Linux → macOS transformation project. It turns a standard Fedora Workstation GNOME desktop into a macOS-like experience with GTK themes, icon themes, SF Pro font, Big Sur sounds, GNOME extensions, custom keybindings, Kitty terminal, Fish shell, and GDM login screen theming.

- **Repository (main):** `https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git` (a.k.a. "Fedoratahoe")
- **Repository (GDM companion):** `https://github.com/eprahemi/FedoraTahoe-GDM.git`
- **Branch:** `main`
- **Local repo path:** `/home/eprahemi/Documents/Codes University [Mine]/Eprahemi Websites/Fedora Mactahoe Eprahemi GTK theme + Icon + Sf Pro Font/`
- **Latest commit:** `6ed1bf65` — `gdm.fish save: dual-timestamp base36 naming (applied + saved) matching pfp.fish style`

### ⚠️ CRITICAL — Repo Path Mistake
Do NOT search with glob patterns like `*Eprahemi*` — the directory has "Mactahoe" (not "MacTahoe"), and glob won't match. Use the **exact literal path** from this file:
```
/home/eprahemi/Documents/Codes University [Mine]/Eprahemi Websites/Fedora Mactahoe Eprahemi GTK theme + Icon + Sf Pro Font/
```
The `gdm.fish` source file lives at `configs/fish/functions/gdm.fish` inside this repo. When the user says "push to fedoratahoe", they mean the main `Fedora-MacTahoe-Eprahemi` repo. The `FedoraTahoe-GDM` repo is a separate companion for GDM shell theme files (no gdm.fish).
- **Install script:** `install.sh` (2271 lines, 23 steps)
- **Bootstrap script:** `bootstrap.sh` (299 lines)
- **Upstream MacTahoe repo** (for theme compilation): `https://github.com/vinceliuice/MacTahoe-gtk-theme.git` (cloned to `/tmp/mactahoe-build/`)

### Key Paths
| What | Path |
|------|------|
| Fish functions | `~/.config/fish/functions/*.fish` |
| Config source | `$BUNDLE/configs/fish/functions/*.fish` |
| Wallpapers | `~/.local/share/backgrounds/` (XDG data) |
| **FedoraTahoe-GDM clone** (gdm.fish engine) | **`~/.local/share/mactahoe-gdm/`** ← DO NOT confuse with `/tmp/mactahoe-gtk` |
| Upstream MacTahoe GTK theme clone (install.sh) | `/tmp/mactahoe-gtk` (vinceliuice/MacTahoe-gtk-theme) |
| Kitty config | `~/.config/kitty/kitty.conf` |
| GTK settings | `~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini` |
| Starship | `~/.config/starship.toml` |
| Fastfetch | `~/.config/fastfetch/config.jsonc` |
| Dconf backup | `configs/dconf/full-backup.ini` |
| GDM undo backup | `~/.local/share/mactahoe-gdm/.gdm-undo-copy.jpg` |
| Icon themes | `~/.local/share/icons/MacTahoe/`, `~/.local/share/icons/MacTahoe-dark/` |
| Big Sur sounds | `~/.local/share/sounds/bigsur/` |
| Eprahemi License | `~/Documents/EPRAHEMI — PUBLIC LICENSE & REUSE TERMS.md` |

---

## 2. INSTALL FLOW (23 Steps)

The installer runs in 6 phases. Every step uses `next_step()` with a progress bar.

### Preflight
1. **Preflight checks** — Kitty detection (blocks Ptyxis), OS check (Fedora only), DE check (GNOME only), user check (not root), network check, sudo check
2. **Remove Ptyxis** — Deletes ptyxis package, config, data, dconf, desktop entries, symlinks, traces
3. **Remove GNOME Weather** — Removed because Mousam Flatpak replaces it

### Phase 1: System Foundations
4. **RPM Fusion + Codecs** — Installs RPM Fusion free/nonfree repos, swaps ffmpeg-free → ffmpeg, installs codecs
5. **NVIDIA Drivers** — Auto-detects NVIDIA GPU, warns about upgrade requirements, installs akmod-nvidia + CUDA

### Phase 2: Packages
6. **RPM Packages** — fish, kitty, fastfetch, figlet, lolcat, eza, celluloid, vlc, kdenlive, pavucontrol, alacarte, nautilus-python, gnome-tweaks, adwaita-icon-theme, ImageMagick, fzf, ripgrep, jq, unzip, curl, wget, git, bat, cmatrix, qrencode, podman, python3-pip, speedtest-cli, xdg-utils, libreoffice. Also installs Starship.
7. **Browsers** — Firefox, Chrome, Edge, VS Code
8. **Flatpak Apps** — ZapZap, Mousam, Extension Manager, Flatseal, Gear Lever, HandBrake, Komikku, Obsidian, Proton VPN, Spotify, LocalSend, Discord (optional)

### Phase 3: Themes
9. **MacTahoe GTK Theme** — Clones upstream MacTahoe repo, compiles for current GNOME version with blur + libadwaita. Installs icon themes (MacTahoe, MacTahoe-dark) from bundle. Fixes symbolic SVGs (currentColor), adds Adwaita-style directory entries, installs custom macOS app icons (SVG+PNG) with Flatpak aliases.
10. **SF Pro Font** — Copies `SF-Pro-Display-Regular.otf` from bundle

### Phase 4: Configuration (Steps 11-19)
11. **GNOME Extensions** — Installs 14+ extensions via EGO API (blur-my-shell, user-theme, logomenu, AlphabeticalAppGrid, pinned-apps-in-appgrid, app-hider, compiz-alike-magic-lamp-effect, compiz-windows-effect, CoverflowAltTab, clipboard-history, ding, Bluetooth-Battery-Meter, dash2dock-lite, appindicatorsupport). Enables via gsettings.
12. **Custom Desktop Entries** — App renames (e.g., Files → Finder, etc.)
13. **Celluloid Default** — Sets Celluloid as default video player for 15+ MIME types, configures draggable video area and loop-file=inf
14. **Nautilus Defaults** — Per-folder sort order (Downloads→date, Pictures/Videos/Music/Documents→name), sidebar bookmark order (Downloads, Pictures, Videos, Music, Documents, Trash), file chooser sort-directories-first disabled
15. **Config Files** — Copies Kitty config, Fish config+functions, Starship toml, GTK 3.0/4.0 settings.ini, Fastfetch config (with `PLACEHOLDER_USER_HOME` sed replacement), systemd-logind overrides
16. **GNOME dconf Settings** — Theme (MacTahoe-Dark), icon theme (MacTahoe-dark), cursor (MacTahoe-dark), font (SF Pro Display 11), color scheme (prefer-dark), window buttons (close,minimize,maximize:appmenu), touchpad settings, workspace keybindings (Super+1-9), custom keybindings (Super+T=Kitty, Super+E=Nautilus, Super+Q=Close, Super+N=Notes, Super+W=Chrome, Super+F=Firefox, Super+Z=Spotify), night light, power settings, privacy, default terminal (kitty). Also restores extension dconf from backup.
17. **Wallpapers + Login Screen** — Clears stock Fedora backgrounds, copies desktop wallpapers to `/usr/share/backgrounds/Wallvault Wallpapers/`, creates XML for GNOME picker, sets active desktop wallpaper via gsettings, copies login screen wallpaper to `~/.local/share/backgrounds/`
18. **Custom Avatars** — Converts normal faces to 512x512 JPEG, installs to `/usr/share/pixmaps/faces/`, updates AccountsService icon. 18+ faces optional.
19. **GDM Login Theme** — Clones upstream MacTahoe repo to `/tmp/mactahoe-gtk`, runs `sudo ./tweaks.sh -g -nb -nd -b "$wallpaper"`. Hides Fedora logo via dconf.

### Phase 5: Terminal & Shell
20. **Kitty as Default** — Symlinks kitty to gnome-terminal and x-terminal-emulator, updates gsettings, fixes stale desktop entries for all users
21. **Fish as Default Shell** — `chsh -s /usr/bin/fish $USER`

### Phase 6: Finalize
22. **Billie & Jinx Videos** — Optional download (~500 MB zip from Google Drive), extracts to ~/Downloads. Has a "naughty" second prompt if declined.
23. **Cleanup & Reboot** — Removes temp files, Flatpak build cache, thumbnails, fontconfig cache, Mesa shader cache, DNF metadata, unused Flatpak runtimes, orphaned RPMs, old journal logs (3-day). Rebuilds icon caches. Asks to reboot.

---

## 3. BOOTSTRAP FLOW (`bootstrap.sh`)

The bootstrap script is the internet-first entry point:
1. **Terminal check** — Blocks Ptyxis, recommends Kitty
2. **ASCII Banner** — MacTahoe ASCII art, GNOME version, press any key
3. **Discord prompt** — [Y/n] (default Yes)
4. **Desktop wallpaper prompt** — [Y/n] (default Yes)
5. **18+ wallpapers prompt** — [y/N] (default No)
6. **Git check** — Installs git if missing
7. **Clone bundle** — `git clone --depth 1` to `/tmp/fedora-mactahoe`
8. **Hides Fedora logo** — `sudo dconf` at GDM level
9. **Copies Eprahemi License** — To `~/Documents/`
10. **Runs `install.sh`** — `cd /tmp/fedora-mactahoe && bash install.sh`

Bootstrap does NOT ask about Billie videos (that's in install.sh step 22).
Bootstrap passes `INSTALL_DISCORD`, `INSTALL_DESKTOP_WALLPAPER`, `INSTALL_WALLPAPER_18` as env vars to install.sh.

---

## 4. GDM WALLPAPER SWITCHER (`gdm` Fish Function)

### File: `configs/fish/functions/gdm.fish` (~2051 lines)

A persistent GDM wallpaper switching function that works entirely offline after the repo is cached once.

### Subcommands
| Command | Description |
|---------|-------------|
| `gdm filename.jpg` | Search + apply with blur options |
| `gdm /path/to/image.jpg` | Direct path, bypasses search |
| `gdm current` | Use current GNOME desktop wallpaper |
| `gdm default` | Restore Himeno login (3-tier fallback) |
| `gdm info` | Show last applied GDM wallpaper details |
| `gdm -y/--yes filename.jpg` | Skip all prompts + blur |
| `gdm --help` | Full help with 6 sections + figlet art |
| `gdm` (no args) | Show all usages in branded box |

### Search Engine
- Searches across 13 user directories (ordered by priority):
  1. `~/.local/share/backgrounds`
  2. `~/Pictures/Wallpapers`
  3. `~/Pictures`
  4. `~/Downloads`
  5. `~/Desktop`
  6. `~/Documents`
  7. `~/Videos`
  8. `~/Music`
  9. `~/Templates`
  10. `~/Public`
  11. `~/.local/share/wallpapers`
  12. `~/.local/share/mactahoe-gdm`
  13. `~/.config/Wallpapers`
- Supports spaces in filenames (joins args with `string join ' '`)
- Supports interactive multi-match picker (1/2/3 from all results)

### Blur System
- **Default blur** (`-blur 0x40 -fill black -colorize 40%`) — applies immediately with no LIKE THE RESULT? prompt
- **Custom blur** — user chooses sigma (20-50) + tint % (20-40), shows preview in Kitty, retry loop with `[y/N]` default
- **No blur** — Apply original image directly
- **ImageMagick check** — if `magick` not installed, offers to install via sudo dnf
- Blur temp file: `/tmp/gdm-blurred.jpg`

### JPEG Conversion
- Non-JPEG images (PNG, WEBP, BMP, etc.) auto-convert to JPEG 90% quality right before apply
- Converted copy at `/tmp/gdm-converted.jpg`
- Only runs if ImageMagick available and /tmp writable
- Original file untouched

### Guards
1. `--yes` with no image → error
2. Git not installed → prompt to install
3. Curl not installed → error
4. Sudo not installed → error
5. /tmp not writable → error
6. Corrupt image blur → fallback to original
7. Long path padding fix (path > 54 chars truncated)
8. Auto-dependency-check note (Kitty + ImageMagick optional)

### `gdm current` Flow
1. Reads `org.gnome.desktop.background picture-uri` via gsettings
2. Strips `file://` prefix and URL-decodes via python3
3. Shows confirm box with Kitty preview
4. Sets `skip_double_confirm=1` flag (skips DO YOU MEAN THIS? box)
5. Falls through to blur/apply flow

### `gdm default` Flow (3-tier fallback)
1. `~/.local/share/backgrounds/Himeno Fedora LoginScreen.jpg`
2. `~/.local/share/mactahoe-gdm/himeno-login.jpg`
3. Download from GitHub raw URL

### `gdm info` Flow
1. Reads `~/.local/share/mactahoe-gdm/.gdm-undo-copy.jpg` (backup kept from last apply)
2. Two-section nested frame: FILE DETAILS + IMAGE INFORMATION
3. Shows filename, dir, size, date (current ts — not file mtime), format, colorspace, depth, DPI, MP, aspect, blur status, source path
4. All padding adjusted for emoji double-width (emoji renders 2 cols, Fish string length counts as 1)
5. Source path truncated with `…` prefix showing end of path
6. Displayed in branded high-end box with eprahemi footer

### `gdm save` Flow (re-added per user request)
1. Reads `~/.local/share/mactahoe-gdm/.gdm-undo-copy.jpg`
2. Generates **16-char encrypted-looking name** — `applied-b36(6) + saved-b36(6) + random(4).jpg` (same dual-timestamp base36 style as `pfp save`)
3. Each save = unique name — collision protection with `_1`, `_2`, … suffix
4. Shows **decoded applied date** (`🕒  Applied:`) + **decoded saved date** (`💾  Saved:`) alongside the encrypted name
5. **Error prompt**: beautiful red branded box if no wallpaper applied yet
6. Shows beautiful green branded box with path + encrypted filename + decoded dates

### Undo (REMOVED PERMANENTLY)
- `gdm undo` subcommand was removed per user request — will not be re-added
- `.gdm-undo-copy.jpg` backup still created before each apply (for `gdm info` and `gdm save` to read)

### Confirm Defaults
| Prompt | Default | Action |
|--------|---------|--------|
| CURRENT DESKTOP WALLPAPER | `[Y/n]` | Enter → Yes |
| DO YOU MEAN THIS? | `[Y/n]` | Enter → Yes |
| LIKE THE RESULT? (custom blur) | `[y/N]` | Enter → No (retry) |
| ImageMagick install | `[Y/n]` | Enter → Yes |

### Key Dependencies
- `magick` at `/usr/bin/magick` (ImageMagick)
- Kitty detection via `$KITTY_PID`
- `figlet` for "eprahemi" ASCII art in `--help`
- GDM changes take effect after reboot (not just GNOME Shell restart)
- Fish functions auto-installed by `install.sh` line 1008

---

## 5. FISH FUNCTION ARCHIVE (`func.fish`)

File: `configs/fish/functions/func.fish` (~352 lines)

Archives all custom Fish functions organized by categories:
- **System:** `gdm`, `testdrive`, `cleanreset`, `refresh`, `stats`, `stayawake`, `getdata`, `pfp`
- **Navigation:** `c`, `l`, `n`, `v`, `p`, `f` (not in func.fish, but referenced)
- **Utilities:** `calc`, `extract`, `weather`, `myip`, `qr`, `passgen`, `cat`, `mkgif`, `matrix`, `hollywood`, `clean`

The `gdm-default.fish` was deleted — merged into `gdm.fish`.

---

## 6. GDM WALLPAPER ENGINE (`gdm-wallpaper.sh`)

**This is the user's own work** — NOT from vinceliuice/MacTahoe-gtk-theme.

| What | Where |
|------|-------|
| **Source repo** | `https://github.com/eprahemi/FedoraTahoe-GDM.git` |
| **Cloned to** | `~/.local/share/mactahoe-gdm/` |
| **Main script** | `gdm-wallpaper.sh` (NOT tweaks.sh) |
| **Original name** | Was `tweaks.sh`, renamed to `gdm-wallpaper.sh` |

Used by `gdm.fish` to apply GDM wallpaper:
- `sudo ./gdm-wallpaper.sh -g -nb -nd -b "$image"` — apply GDM theme with wallpaper
- `sudo ./gdm-wallpaper.sh -g -nb -nd` — apply GDM theme without wallpaper
- `sudo ./gdm-wallpaper.sh -r -g` — revert GDM theme

This is a COMPLETELY separate thing from `/tmp/mactahoe-gtk/tweaks.sh` (which install.sh clones from upstream vinceliuice/MacTahoe-gtk-theme for the INITIAL one-time GDM theme install). The runtime GDM wallpaper switcher is the user's own `FedoraTahoe-GDM` repo.

---

### Fish Professionalization + Subcommands (Jun 2026)

All 26 Fish function files were purged of unprofessional/brainrot/childish language:
- **Removed:** "bestie", "fr fr", "BRUH", "no cap", "slay", "sigma" (as slang), "💀", "💅", "🔥" (as flavor), 40-item rotating insult array in command-not-found handler, 20-item burn arrays, "Read the manual dummy", "rotating burns", "oopsie", "ain't"
- **Replaced with:** Professional error messages (`"Error: Unknown flag"`), clear success messages, "Show this help message", "Version: June 2026"
- **Kept:** Utility emojis (✅ ❌ ⚠️ 📋 🔧), project attribution, all escape codes/colors, all logic
- **Strictly** `"sigma"` in gdm.fish is the ImageMagick blur parameter (`-blur 0xN`), NOT slang — left as-is
- 26 files changed, 828 insertions, 434 deletions
- **Passgen subcommands added:** `passgen gen <N>` (bypasses length limit) and `passgen check <pw>` (analyze any password including numeric). Removed ≤128 threshold hack. Bare numeric args still work (≤99999 as length, >99999 shows helpful error with gen/check hints).
- Commits: `494b746c` (professionalization), `c28ba81` (threshold fix), `cd4a456` (gen/check subcommands)

### pfp.fish — GNOME Profile Picture Manager (Jun 2026)

New function for managing the GNOME AccountsService avatar with subcommands:

| Subcommand | Description |
|------------|-------------|
| `pfp <image>` | Set profile picture (converts to 512×512 PNG via magick) |
| `pfp current` | Show avatar + detect desktop wallpaper, ask to use as pfp |
| `pfp info` | Show full profile picture info (encrypted path, size, dims, type, date) |
| `pfp save` | Save current avatar to `~/Pictures/<timestamp>-<random>.png` |
| `pfp remove` / `pfp reset` | Reset to default avatar |
| `pfp --help` / `-h` | Show help |

Key design decisions:
- **Fernet encryption** for file paths shown in display output: key stored at `~/.config/pfp.key`, auto-generated on first use. Encrypted paths shown in `pfp current`, `pfp info`, and `pfp save` — not reversible (no decrypt command).
- **`pfp current`** detects GNOME desktop wallpaper via `gsettings get org.gnome.desktop.background picture-uri`, URL-decodes it, shows the info, and prompts to use it as profile picture.
- **`pfp save` naming**: 16-char filename encoding `applied-b36(6) + saved-b36(6) + random(4).png`. Base36 looks like random gibberish but first 6 chars decode to when avatar was set, next 6 to when saved. `gdm.fish` save uses identical scheme.
- **Full path privacy**: The actual `/var/lib/AccountsService/icons/$USER` path is never shown in plaintext.
- **Fallback to base64** if `cryptography` python package is unavailable.
- **Unknown subcommands** fall through to the default `pfp <image>` handler (tries to use the word as a file path).
- **Kitty icat preview** in `pfp info` when running in Kitty terminal.

## 7. KEY DESIGN DECISIONS

### Zero Hardcoded Paths
- All user references use `$HOME`, `$USER`, `whoami`, `$(id -gn)`
- Never use `/home/eprahemi/` or any hardcoded username
- Fish configs use `$HOME/.local/share/backgrounds/` not `~/.config/Wallpapers/`

### Wallpaper Location (XDG-Compliant)
- Wallpapers stored in `~/.local/share/backgrounds/` (XDG `$XDG_DATA_HOME`)
- Previously was `~/.config/Wallpapers/` (which is `$XDG_CONFIG_HOME`)
- Wallpapers are data, not configuration

### Icon Theme Fixes
- All symbolic SVGs get `fill="currentColor"` applied recursively
- Adwaita-style directory entries added to `index.theme` for GResource icon paths
- Icon cache rebuilt after every modification
- System-wide copy at `/usr/share/icons/hicolor/256x256/apps/` for all users
- Flatpak aliases map short names to reverse-DNS (e.g., `discord.png` → `com.discordapp.Discord.png`)

### Ptyxis Removal
- Ptyxis gets yeeted during setup because it conflicts with Kitty
- Removes package, config, data, dconf, desktop entries, symlinks
- Installer blocks running from Ptyxis entirely

### Firefox Theming
- Applied via `tweaks.sh -f` from upstream MacTahoe repo
- Requires Firefox to have been launched once (to create profile directory)
- If skipped, user is instructed to re-run install.sh

### Sound System
- Bundled Big Sur OGA files in `sounds/bigsur/stereo/`
- Falls back to building from source if not bundled
- Enabled via gsettings `org.gnome.desktop.sound theme-name "bigsur"`

### Flatpak GTK Runtime
- Builds `org.gtk.Gtk3theme.MacTahoe-Dark` runtime from local theme files
- Uses `ostree` + `appstream-compose` + `flatpak build-bundle`
- Installs system-wide via `flatpak install --system`

---

## 8. BUG REGISTRY & FIXED ISSUES

### Fixed
| Bug | Fix | Commit |
|-----|-----|--------|
| Quoting broke arrays with spaces | `contains -- "$r"` and `set image "$results[...]"` | Session |
| `gdm current` showed double confirm | `skip_double_confirm` flag + fall-through instead of `--yes` recursion | `46f878a2` |
| Default blur showed LIKE THE RESULT? | Removed prompt — applies immediately | Session |
| Custom blur LIKE THE RESULT? defaulted to Yes | Changed to `[y/N]` — Enter = retry | Session |
| Wallpapers in `~/.config/Wallpapers/` | Migrated to `~/.local/share/backgrounds/` | `46f878a2` |
| 16.jpg forced on user decline | Removed fallback entirely | `46f878a2` |
| PNG/GIF/WEBP failed on GDM | JPEG 90% auto-conversion added | `c6e83e28` |
| JPEG conversion ran before blur | Moved to right before apply (after blur) | `46f878a2` |
| Ptyxis blocks install entirely | Added full Ptyxis detection + blocking with helpful message | Original |

### Known Issues (Unfixed)
- GDM changes require reboot (GNOME Shell restart insufficient)
- Firefox theming requires first Firefox launch (can't create profile in advance)
- Flatpak GTK runtime build can fail if ostree/appstream-compose missing
- Google Drive download URLs for 18+ content may expire (need updating)

---

## 9. TESTING RESULTS

- **PNG → JPEG 90%:** 3.5 MB → 326-754 KB, visually lossless
- **GDM wallpaper apply (gdm.fish runtime):** Works via `sudo ./gdm-wallpaper.sh -g -nb -nd -b "$image"` from FedoraTahoe-GDM repo at `~/.local/share/mactahoe-gdm` 
- **Fish function auto-install:** `cp -f "$cfg/fish/functions/"*.fish "$HOME/.config/fish/functions/"`
- **Fastfetch config:** `PLACEHOLDER_USER_HOME` sed replacement works for dynamic paths

---

## 10. CONSTRAINTS

- **Fedora only** — uses dnf, fedora-release check, Fedora-specific paths
- **GNOME only** — uses gnome-shell, gsettings, dconf, GNOME extensions
- **Not root** — installer checks EUID and refuses to run as root
- **Internet required for first run** — bootstrap.sh clones repo; subsequent `gdm` runs work offline
- **Kitty recommended** — full experience designed for Kitty terminal; falls back gracefully
- **No emojis in code** — user prefers no emojis unless explicitly requested
- **62-char boxes** — all prompt boxes use 62-char inner width with `printf '%*s'` right-padding

---

## 11. REPO FILE STRUCTURE

```
Fedora Mactahoe Eprahemi GTK theme + Icon + Sf Pro Font/
├── assets/
│   └── normal-faces/          # Avatar source images
├── bootstrap.sh               # Internet-first entry point
├── config/
│   └── logind.conf.d/
│       └── logind-overrides.conf
├── configs/
│   ├── dconf/
│   │   └── full-backup.ini
│   ├── fastfetch/
│   │   ├── config.jsonc
│   │   ├── fri.gif
│   │   ├── guts.png
│   │   └── logo.png
│   ├── fish/
│   │   ├── config.fish
│   │   └── functions/
│   │       ├── __fish_default_command_not_found_handler.fish
│   │       ├── calc.fish
│   │       ├── cat.fish
│   │       ├── clean.fish
│   │       ├── cleanreset.fish
│   │       ├── c.fish
│   │       ├── extract.fish
│   │       ├── fish_greeting.fish
│   │       ├── func.fish       # Function archive
│   │   ├── gdm.fish        # GDM wallpaper switcher (~2051 lines)
│   │       ├── getdata.fish
│   │       ├── hollywood.fish
│   │       ├── l.fish
│   │       ├── matrix.fish
│   │       ├── mkgif.fish
│   │       ├── myip.fish
│   │       ├── n.fish
│   │       ├── passgen.fish
│   │       ├── pfp.fish       # Profile picture manager (~540 lines)
│   │       ├── p.fish
│   │       ├── qr.fish
│   │       ├── refresh.fish
│   │       ├── stats.fish
│   │       ├── stayawake.fish
│   │       ├── testdrive.fish
│   │       ├── v.fish
│   │       └── weather.fish
│   ├── gtk-3.0/
│   │   └── settings.ini
│   ├── gtk-4.0/
│   │   └── settings.ini
│   ├── kitty/
│   │   └── kitty.conf
│   └── starship.toml
├── desktop/                    # Custom .desktop entries
├── docs/
├── fonts/
│   └── SF-Pro-Display-Regular.otf
├── icons/
│   └── 256x256/                # Custom macOS app icons
├── install.sh                  # 2271 lines, 23 steps
├── README.md
├── sounds/
│   └── bigsur/
│       └── stereo/*.oga
├── themes/
│   ├── MacTahoe/              # Light icon theme
│   └── MacTahoe-dark/         # Dark icon theme
└── wallpapers/
    ├── background-normal/     # 30 custom wallpapers
    ├── desktop/               # Desktop wallpaper
    └── login/                 # GDM login wallpaper
```

---

## 12. RECENT COMMITS (Latest on top)

```
a2206e2e gdm.fish: fix read -l scoping bug (loop-local vars lost after while break) + switch/case → if/else with string match
494b746c fish: professionalize all prompts, errors, and comments (27 files)
c232f29a gdm: keep only info subcommand, remove undo/save
46f878a2 fix(gdm): move JPEG conversion to right before apply (after blur)
c6e83e28 feat(gdm): auto-convert non-JPEG images to JPEG 90% quality for GDM
```

---

## 13. IMPORTANT COMMANDS

```fish
# GDM wallpaper
gdm filename.jpg              # Search + apply with blur
gdm /path/to/image.jpg        # Direct path
gdm current                   # Use current desktop wallpaper
gdm default                   # Restore Himeno login
gdm info                      # Show last applied wallpaper details
gdm -y image.jpg              # Skip all prompts + blur
gdm --help                    # Full help

# Install (from bundle)
bash install.sh               # Full 23-step installer

# Install (from internet)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh)"

# GDM wallpaper apply (runtime — gdm.fish clones FedoraTahoe-GDM)
sudo ./gdm-wallpaper.sh -g -nb -nd -b /path/to/image.jpg
sudo ./gdm-wallpaper.sh -g -nb -nd              # Without wallpaper
sudo ./gdm-wallpaper.sh -r -g                   # Revert GDM theme

# GDM theme install (install.sh — clones upstream MacTahoe-gtk-theme)
sudo /tmp/mactahoe-gtk/tweaks.sh -g -nb -nd -b /path/to/image.jpg
sudo /tmp/mactahoe-gtk/tweaks.sh -g -nb -nd
sudo /tmp/mactahoe-gtk/tweaks.sh -r -g
sudo /tmp/mactahoe-gtk/tweaks.sh -f             # Firefox macOS theme

# Icon cache rebuild
gtk-update-icon-cache ~/.local/share/icons/MacTahoe-dark/
gtk-update-icon-cache ~/.local/share/icons/MacTahoe/
```

---

## 14. VERSION HISTORY
- **Current:** `a2206e2e` (gdm.fish read -l scoping fix)
- **Previous:** `494b746c` (fish professionalization)
- **Initial work:** Multiple commits from earlier sessions (gdm.fish creation, blur system, etc.)

---

## APPENDIX A: ANCHORED SESSION SUMMARY — BUG REGISTRY

This section is the master record of every bug ever fixed in the Fedora MacTahoe project, directly from `ANCHORED_SESSION_SUMMARY.md`. **If you're about to edit install.sh or bootstrap.sh, read this first.**

### 🔴 CLASS A: SCRIPT CRASHES (set -euo pipefail violations)

These caused (or would cause) the script to abort silently on edge cases.

| # | File | Bug | Fix |
|---|------|-----|-----|
| 1 | install.sh | `walk_pid=$(cat … \| awk …)` — process tree walk fails with non-zero exit on orphan | Added `\|\| true` |
| 2 | install.sh | `release=$(rpm -E %fedora)` — theoretical abort if `rpm` ever fails | Added `2>/dev/null \|\| release="40"` |
| 3 | install.sh | `dl_url=$(curl … \| jq …)` — extension API failure aborts script | Added `\|\| true` |
| 4 | install.sh | All `read -r -s -n 1 key` and `read -rp` — Ctrl+D aborts under `set -euo pipefail` | Added `\|\| true` after each read |
| 5 | bootstrap.sh | Same `read` pattern without fallback | Added `\|\| true` |

### 🟡 CLASS B: LOGIC / INPUT BUGS

| # | File | Bug | Fix |
|---|------|-----|-----|
| 6 | both | `read -r -s -n 1 key` used `-s` (silent) making debug impossible + used `[ "$key" = " " ]` requiring SPACE | Removed `-s`, changed to `[ -n "$key" ]` to accept **any key** |
| 7 | both | `read` without `</dev/tty` — breaks in non-interactive shells | Added `</dev/tty` |
| 8 | install.sh | TOTAL_STEPS was wrong (mismatched count vs next_step calls) | Fixed to match actual step count |
| 9 | install.sh | `sudo rm -rf /usr/share/backgrounds/` only deleted subdirs | Changed to `sudo rm -rf /usr/share/backgrounds/*` |
| 10 | install.sh | `sudo rm -rf "$face_dir"*.jpg` missed non-JPG formats | Changed to `sudo rm -rf "$face_dir"/*` |
| 11 | install.sh | Stock XMLs were backed up instead of deleted | Changed to permanent deletion |
| 12 | install.sh | GDM logo dconf was inside if/else — skipped if theme clone failed | Moved OUTSIDE the if/else |
| 13 | install.sh | `INSTALL_DISCORD` usage inconsistency (`= "true"` vs `${INSTALL_DISCORD:-true}`) | All safe (always set), noted for consistency |
| 14-15 | install.sh | Discord prompt used wrong box style, `(Y/n)` unclear | Polished to ╔═╗ + `[Y/n]` + "Press Enter" |
| 16 | install.sh | `localsend.png` missing from `fp_aliases` | Added alias |
| 17 | install.sh | LocalSend not in Flatpak install list | Added `flatpak install` entry |
| 18-19 | install.sh | Old MacTahoe themes/icons cleaned on re-run | Verified intentional (intentional wipe) |
| 20-21 | install.sh | Google Drive URLs returned HTML (virus warning page) | Changed to `drive.usercontent.google.com/download?id=...&export=download&confirm=t` |
| 22 | install.sh | 18+ zip extraction used `for f in "$dir/"*` — skipped nested dirs | Replaced with `find -type f -print0` |
| 23 | install.sh | 18+ faces only went to `faces +18/` (invisible to GNOME) + `$CURRENT_USER` undefined | Copy to BOTH dirs + use `$USER` + AccountsService update |
| 24 | install.sh | `qr-code-symbolic.svg` missing — GNOME 48+ WiFi QR button no icon | Created + copied to actions/symbolic + actions/scalable |
| 25 | install.sh | GResource icons at new-style paths (`scalable/actions/`) not found | Added 16 new-style dirs to `index.theme` + `mkdir` |
| 26 | install.sh | Icon cache not rebuilt after install | `gtk-update-icon-cache` per theme + in finalize |
| 27 | gdm.fish | `read -l` inside `while` loop — variable scoped to loop body, DESTROYED after `break` exits loop. Affected all 10 `read` calls, most visible: `blur_choice` was `c` after read but `""` at matching logic. | Changed all 10 `read -l -P` → `read -P` (function-scoped instead of loop-scoped) |

### 🟠 CLASS C: CONTENT / UX ISSUES

| # | Bug | Fix |
|---|------|------|
| 20 | SPACE prompts said "Press SPACE" but now accept any key | Changed to "Press any key" |
| 21 | Humanized tone missing from Ptyxis/NVIDIA/Kitty blocks | Applied consistently across both scripts |
| 22 | `echo -n` used instead of `echo -en` for ANSI color | Changed to `echo -en` |
| 23 | GNOME version banner padding hardcoded | Dynamic padding based on version length |
| 24 | Video copy had step heading + ok output | Inlined silently inside avatar function |
| 25 | bootstrap.sh accidentally reverted to git HEAD during testing | Restored all content |
| 26 | Icon fix applied only to current user | Added loop applying fixes to ALL `/home/*` users |
| 27 | `rm -rf` used for user files | Use `gio trash` instead |

### 🔵 CLASS D: ARCHITECTURE / DESIGN DECISIONS

| # | Decision | Rationale |
|---|----------|-----------|
| 26 | Wallpaper XML in `/usr/share/gnome-background-properties/` | GNOME 48+ doesn't scan filesystem, reads XML |
| 27 | `Wallvault-Wallpapers` (hyphen, no space) | Avoids path quoting issues |
| 28 | Avatars via temp dir → sudo cp | magick can't write to system dirs directly |
| 29 | Stock XMLs DELETED, not backed up | User requested removal of dead entries |
| 30 | Discord optional via env var | bootstrap.sh exports → install.sh reads silently |
| 31 | GDM logo hide outside tweaks.sh if/else | Ensures it runs even if theme clone fails |
| 32 | Zero hardcoded paths | All dynamic: `$HOME`, `$(whoami)`, `$USER` |
| 33 | Kitty required (Ptyxis blocked), non-Kitty warned | Ptyxis gets removed during install |
| 34 | Stock Fedora themes kept (not deleted) | Safety net; dnf update reinstall anyway |
| 35 | `qr-code-symbolic.svg` uses `fill="currentColor"` | Works on light + dark backgrounds |
| 36 | Icon fix per-user, NOT system-wide | User rejected system-wide approach |
| 37 | Other users augmented, not replaced | Non-destructive |

### 🟣 CLASS E: BOX ALIGNMENT / DYNAMIC PADDING

All boxes in install.sh and bootstrap.sh use the dynamic padding formula:
```bash
$(printf '%*s' $((62 - ${#var})) '')
```
Box inner width = 62 chars. Line total = 66 chars.

| # | Box | Bug | Fix |
|---|-----|------|-----|
| 38 | Victory banner | Overflow lines, misaligned, static text | Shortened + dynamic `%*s` |
| 39 | Phase dividers | Hardcoded 62 but banner 66 wide | Changed to 58 |
| 40 | Main banner title | `%*s` with 62 instead of 60 | Changed to 60 |
| 41 | "Time to reboot" | Overflow + hardcoded spaces | Shortened + dynamic |
| 42 | "Already updated?" | Hardcoded trailing spaces | Dynamic `%*s` |
| 43 | NVIDIA detection | Missing (deleted during collapse) | Restored + dynamic padding |
| 44 | Kitty "Press any key" | Off by 1 space | +1 to match 62 |
| 45 | Ptyxis detection | Hardcoded padding | All converted to dynamic |
| 46 | Passwordless sudo | Long lines overflow 62-char | Rewritten shorter + dynamic |
| 47 | Discord prompt | 7 lines hardcoded | Converted to dynamic |
| 48 | Desktop wallpaper | Title + 5 lines hardcoded | Converted to dynamic |
| 49 | 18+ wallpapers prompt | Title + 5 lines hardcoded | Converted to dynamic |
| 50 | Incompatible OS box | 4 lines missing borders, no ANSI | Full rewrite |
| 51 | Incompatible DE box | Same issues as OS box | Full rewrite |
| 52 | GNOME Not Found box | Same issues as OS box | Full rewrite |
| 53 | NVIDIA title (bootstrap) | Hardcoded 64 vs 62 | Dynamic `%*s` |
| 54 | "More from Eprahemi" | Top/bottom mismatched 69 chars | Unified at 69 |
| 55 | "Grabbing the Goods" etc. | Already dynamic | Verified correct |

**Emoji caveat**: Double-width emoji (⛔ 📦 ✅) report as 1 char in bash `${#var}` but render as 2 columns — only affects 3 lines in bootstrap.sh; acceptable.

**ASCII art banners** use fixed single-quoted strings that fill 62 cols — do NOT convert to dynamic.

### 🟤 CLASS F: PACKAGE SOURCE CHANGES / DOCUMENTATION

| # | Change | Details |
|---|--------|---------|
| 56 | Discord RPM → Flatpak | Removed from RPM list, added to Flatpak install |
| 57 | Discord size text | Updated from "~100 MB" to "~214 MB / ~540 MB installed" |
| 58 | EPRAHEMI Public License | Added to repo root (`EPRAHEMI — PUBLIC LICENSE & REUSE TERMS.md` — permissive, copyright-free) |
| 59 | License auto-copy | Copies to `~/Documents/` on every install in finalize step |

### Crucial Lessons — Never Forget

1. **Google Drive 18+ zips** return HTML (virus warning) from `drive.google.com/uc`. Use `drive.usercontent.google.com/download` with `confirm=t` instead.
2. **18+ zips have nested subdirs** (`backgrounds+18/`, `faces+18/`). Never use `for f in "$dir/"*; [ -f "$f" ]` — always use `find -type f -print0` for zip extraction loops.
3. **Icons must install system-wide** (`/usr/share/icons/hicolor/256x256/apps`) AND per-user (`$HOME/.local/share/icons/`) so all users get themed icons.
4. **Zero hardcoded paths** — all `$HOME`, `$(whoami)`, `$USER`.
5. **GNOME avatar picker only reads from `/usr/share/pixmaps/faces/`** — `faces +18/` is invisible. When installing 18+ faces, always copy to BOTH directories + update AccountsService icon.
6. **GNOME 48+ Settings bundles custom icons** in GResource at `/org/gnome/Settings/icons/scalable/actions/` — the icon theme's `Directories` list MUST include new-style paths like `scalable/actions` or GTK can't resolve them.
7. **Icon theme uses old-style dirs** (`actions/symbolic/`) but GResource paths use new-style (`scalable/actions/`). Both must be in `Directories`.
8. **Always use `gio trash`** instead of `rm -rf` for user files. Never permanently delete user data.
9. **When applying fixes to other users**, augment their existing theme files. Never replace or delete their per-user copies.
10. **`edit-symbolic` and `document-edit-symbolic` ARE present in MacTahoe-dark** — if user reports them missing, rebuild icon cache and restart GNOME Settings first.
11. **Fish `read -l` inside a `while` loop creates a LOOP-LOCAL variable** that gets DESTROYED when the loop exits via `break`. If the variable is needed after the loop, use `read` (without `-l`) for function-scoped, or `read -g` for global. This affected ALL 10 `read -l` calls in `gdm.fish` — most visibly `blur_choice` was set to `c` by `read` but empty by the time the `if/else` matched it.
12. **Never search the repo path with glob patterns** — the directory name has "Mactahoe" (not "MacTahoe"), so `*Eprahemi*` won't match. Always use the **exact literal path** from `fedora-mac-ai.md` line 16. When the user says "push to fedoratahoe" or "push to main Fedoratahoe", they mean the `Fedora-MacTahoe-Eprahemi` repo at `https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git`.
13. **`mactahoe-gdm` vs `mactahoe-gtk` are TWO COMPLETELY DIFFERENT THINGS:**
    - **`~/.local/share/mactahoe-gdm`** — Runtime GDM wallpaper engine. Cloned by `gdm.fish` from `https://github.com/eprahemi/FedoraTahoe-GDM.git`. Uses `gdm-wallpaper.sh` (user's own script, renamed from the original `tweaks.sh`). NOT from vinceliuice.
    - **`/tmp/mactahoe-gtk`** — Install-time upstream GTK theme. Cloned by `install.sh` from `https://github.com/vinceliuice/MacTahoe-gtk-theme.git`. Uses `tweaks.sh`. Only used during initial installation for GDM theme + Firefox theming setup.
    - **NEVER confuse these two.** When editing gdm.fish runtime paths, use `mactahoe-gdm`. The `gdm-wallpaper.sh` script is the user's own work from `FedoraTahoe-GDM`.

---

## Done

### Progress

- **`passwd` function — no-password status, missing-line prompt, auto-add (new file `passwd.fish`, ~331 lines):** Toggles per-user passwordless sudo in `/etc/sudoers`. Subcommands: `on`, `off`, `enable`, `disable`, `toggle`, `status`, `--help`. Three complete feature additions:
  1. **No-password status** — `passwd status` / `passwd` (no args) use `sudo -n` (non-interactive) for all grep calls, so they NEVER prompt for `sudo` credentials. If `sudo -n true` fails (no cached credentials and no NOPASSWD active), displays "Cannot check status without authentication" with hint to run `sudo passwd status` or `passwd enable`.
  2. **Add new NOPASSWD line** — when `passwd enable` is called and the line doesn't exist at all (neither commented nor uncommented), appends `username ALL=(ALL) NOPASSWD: ALL` to `/etc/sudoers` using backup + `tee -a` append + `visudo -c` validation + revert on failure. Same mechanism for `passwd disable` when line is missing: says "nothing to disable".
  3. **Prompt to add when missing** — `passwd status` status box shows `⚠️ Missing (no NOPASSWD line found)` and then asks `⚠️ No NOPASSWD line found for username. Add one? [Y/n]`. If Yes, uses the same backup + append + visudo flow.
  Three-state detection separated into readonly (`sudo -n`, no prompt) and write (`sudo`, prompts) paths. Commits: `0420f56`, `b5819b8`, `2576e1e` + latest uncommitted: no-password status + missing-line prompt + auto-add.

### Relevant Files

| File | Purpose |
|------|---------|
| `configs/fish/functions/passwd.fish` (~331 lines) | Toggle passwordless sudo — `on`/`off`/`enable`/`disable`/`toggle`/`status`/`--help`. Edits per-user NOPASSWD line in `/etc/sudoers`. High-end branded box with figlet eprahemi art. Redesigned status display with match line showing line number and content. **No-password status (uses `sudo -n`), auto-adds missing line, prompts to add when missing.** Backup + visudo validation + revert on failure. |

## Critical Context

- `passwd` status/no-args path uses `sudo -n` (non-interactive) for ALL grep calls — NEVER prompts for sudo password. If `sudo -n true` fails (no cached creds, no active NOPASSWD), shows auth-needed message instead of status box.
- `passwd` enable/disable/toggle path uses normal `sudo` (prompts for password as expected).
- Three-state detection: uncommented (✅ Enabled), commented (❌ Disabled), neither (⚠️ Missing).
- `passwd enable` when Missing: appends `$user ALL=(ALL) NOPASSWD: ALL` via `sudo tee -a`, then visudo validation. Same backup flow as comment/uncomment.
- `passwd` reads-only path defined inline (not as inner function) — avoids inner-function scoping bugs.
- `passwd` modification uses `sudo sed -ri` with escaped parens `\(ALL\)` and `#&` (entire match) for commenting; backreference `\1` with `($user)` for uncommenting. For adding: `sudo tee -a`.
- `passwd` validates with `sudo visudo -c -f /etc/sudoers` after every edit; reverts from `/tmp/sudoers.bak` on failure.
