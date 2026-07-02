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
- **Latest commit:** `94fcfd65` — (feat: update notifier now persists across boots until user updates, 2026-07-02)

### ⚠️ CRITICAL — Repo Path Mistake
Do NOT search with glob patterns like `*Eprahemi*` — the directory has "Mactahoe" (not "MacTahoe"), and glob won't match. Use the **exact literal path** from this file:
```
/home/eprahemi/Documents/Codes University [Mine]/Eprahemi Websites/Fedora Mactahoe Eprahemi GTK theme + Icon + Sf Pro Font/
```
The `gdm.fish` source file lives at `configs/fish/functions/gdm.fish` inside this repo. When the user says "push to fedoratahoe", they mean the main `Fedora-MacTahoe-Eprahemi` repo. The `FedoraTahoe-GDM` repo is a separate companion for GDM shell theme files (no gdm.fish).
- **Install script:** `install.sh` (3364 lines, 28 steps, 3 decorative atmosphere prompts)
- **Update notifier script:** `configs/updater/fedora-mactahoe-updater.sh` (installed to `~/.local/bin/`)
- **Bootstrap script:** `bootstrap.sh` (636 lines)
- **Upstream MacTahoe repo** (for theme compilation): `https://github.com/vinceliuice/MacTahoe-gtk-theme.git` (cloned to `/tmp/mactahoe-build/`)

### Key Paths
| What | Path |
|------|------|
| Fish functions | `~/.config/fish/functions/*.fish` |
| Config source | `$BUNDLE/configs/fish/functions/*.fish` |
| Desktop wallpaper | `~/.local/share/backgrounds/Himeno Fedora.jpg` (always copied) |
| Login wallpaper | `$BUNDLE/wallpapers/login/Himeno Fedora LoginScreen.jpg` (applied via `tweaks.sh -b` from bundle, no intermediate copy) |
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
| Update notifier script | `~/.local/bin/fedora-mactahoe-updater.sh` |
| Update notifier cache | `~/.cache/fedora-mactahoe/` (last-notified-commit, last-dismissed-commit, last-boot-id) |
| Update notifier systemd timer | `~/.config/systemd/user/fedora-mactahoe-updater.timer` |
| Update notifier systemd service | `~/.config/systemd/user/fedora-mactahoe-updater.service` |

---

## 2. INSTALL FLOW (28 Steps + 3 Atmosphere Prompts)

The installer runs in 6 phases. Every step uses `next_step()` with a progress bar. Three decorative atmosphere functions (`__secure_tunnel`, `__system_dashboard`, `__cdn_speed_test`) appear after the splash banner but are not counted in TOTAL_STEPS (remains 28).

### Preflight (unnumbered)
1. **Preflight checks** — Kitty detection (blocks Ptyxis), OS check (Fedora only), DE check (GNOME only), user check (not root), network check, sudo check
2. **Remove Ptyxis** — Deletes ptyxis package, config, data, dconf, desktop entries, symlinks, traces
3. **Remove GNOME Weather** — Removed because Mousam Flatpak replaces it

### Atmosphere (before Step 1, after splash banner)
These three decorative functions appear between the main splash banner and preflight checks. They are not numbered steps (TOTAL_STEPS remains 28) and require no user interaction.

- **`__secure_tunnel()`** — Shows a randomized per-run tunnel credentials box (token, node, region, bandwidth, uptime). Purely decorative.
- **`__system_dashboard()`** — Reads real system data: OS, kernel, CPU, GPU, RAM/disk usage bars (via /proc, lspci, df). Uses awk, no bc dependency.
- **`__cdn_speed_test()`** — Simulated optimal route test with random latency (20-200ms), bandwidth (200-999 Mbps), stability (95-99%), and route hops.

### Phase 1: System Foundations (Steps 3-4)
4. **RPM Fusion + Codecs** — Installs RPM Fusion free/nonfree repos, swaps ffmpeg-free → ffmpeg, installs codecs
5. **NVIDIA Drivers** — Auto-detects NVIDIA GPU, warns about upgrade requirements, installs akmod-nvidia + CUDA

### Phase 2: Packages (Steps 5-7)
6. **RPM Packages** — fish, kitty, fastfetch, figlet, lolcat, eza, celluloid, vlc, kdenlive, pavucontrol, alacarte, nautilus-python, gnome-tweaks, adwaita-icon-theme, ImageMagick, fzf, ripgrep, jq, unzip, curl, wget, git, bat, cmatrix, qrencode, podman, python3-pip, speedtest-cli, xdg-utils, libreoffice. Also installs Starship.
7. **Browsers** — Firefox, Chrome, Edge, VS Code
8. **Flatpak Apps** — ZapZap, Mousam, Extension Manager, Flatseal, Gear Lever, HandBrake, Komikku, Obsidian, Proton VPN, Spotify, LocalSend, Discord (optional)

### Phase 3: Themes (Steps 8-9)
9. **MacTahoe GTK Theme** — Clones upstream MacTahoe repo, compiles for current GNOME version with blur + libadwaita. Installs icon themes (MacTahoe, MacTahoe-dark) from bundle. Fixes symbolic SVGs (currentColor), adds Adwaita-style directory entries, installs custom macOS app icons (SVG+PNG) with Flatpak aliases.
10. **SF Pro Font** — Copies `SF-Pro-Display-Regular.otf` from bundle

### Phase 4: Configuration (Steps 11-23)
11. **Custom Desktop Entries** — App renames (e.g., Files → Finder, etc.)
12. **Celluloid Default** — Sets Celluloid as default video player for 15+ MIME types, configures draggable video area and loop-file=inf
13. **Nautilus Defaults** — Per-folder sort order (Downloads→date, Pictures/Videos/Music/Documents→name), sidebar bookmark order (Downloads, Pictures, Videos, Music, Documents, Trash), file chooser sort-directories-first disabled
14. **Config Files** — Copies Kitty config, Fish config+functions, Starship toml, GTK 3.0/4.0 settings.ini, Fastfetch config (with `PLACEHOLDER_USER_HOME` sed replacement), systemd-logind overrides
15. **GNOME dconf Settings** — Theme (MacTahoe-Dark), icon theme (MacTahoe-dark), cursor (MacTahoe-dark), font (SF Pro Display 11), color scheme (prefer-dark), window buttons (close,minimize,maximize:appmenu), touchpad settings, workspace keybindings (Super+1-9), custom keybindings (Super+T=Kitty, Super+E=Nautilus, Super+Q=Close, Super+N=Notes, Super+W=Chrome, Super+F=Firefox, Super+Z=Spotify), night light, power settings, privacy, default terminal (kitty). Also restores extension dconf from backup.
16. **System Resources** — Optimizes swappiness, inotify watchers, vm.dirty ratios
17. **Wallpapers + Login Screen** — Clears stock Fedora backgrounds; only one Wallvault folder exists based on +18 choice (normal or +18 folder/XML destroyed entirely); desktop wallpaper `Himeno Fedora.jpg` always copied to `~/.local/share/backgrounds/`; leftover `Himeno Fedora LoginScreen.jpg` always deleted from there; GDM login wallpaper read directly from bundle path via `tweaks.sh -b` (no `/tmp/` intermediate); sets active desktop wallpaper via gsettings
18. **Custom Avatars** — Converts normal faces to 512x512 JPEG, installs to `/usr/share/pixmaps/faces/`, updates AccountsService icon. 18+ faces optional.
19. **GDM Login Theme** — Clones upstream MacTahoe repo to `/tmp/mactahoe-gtk`, runs `sudo ./tweaks.sh -g -nb -nd -b "$bg"` where `bg` is `$BUNDLE/wallpapers/login/Himeno Fedora LoginScreen.jpg`; no intermediate `/tmp/` or `~/.local/share/backgrounds/` copy. Hides Fedora logo via dconf.
20. **Firefox Theming** — Applies macOS Firefox theme via upstream `tweaks.sh -f`. Close-wait loop if Firefox is running.
21. **Flatpak GTK Runtime** — Builds and installs `org.gtk.Gtk3theme.MacTahoe-Dark` from local theme files.
22. **macOS Big Sur Sounds** — Installs Big Sur sound theme, sets via gsettings `theme-name "bigsur"`.
23. **Update Notifier** — Installs `fedora-mactahoe-updater.sh` to `~/.local/bin/`, creates systemd service + timer (`OnBootSec=5min` + `OnUnitActiveSec=2h`), enables and starts the timer.

### Phase 5: Terminal & Shell (Steps 24-25)
24. **Kitty as Default** — Symlinks kitty to gnome-terminal and x-terminal-emulator, updates gsettings, fixes stale desktop entries for all users
25. **Fish as Default Shell** — `chsh -s /usr/bin/fish $USER`

### Phase 6: Extensions & Finalize (Steps 26-28)
26. **GNOME Extensions** — Installs 14+ extensions via EGO API (blur-my-shell, user-theme, logomenu, AlphabeticalAppGrid, pinned-apps-in-appgrid, app-hider, compiz-alike-magic-lamp-effect, compiz-windows-effect, CoverflowAltTab, clipboard-history, ding, Bluetooth-Battery-Meter, dash2dock-lite, appindicatorsupport, Window Title Pro). Enables via gsettings.
27. **Billie & Jinx Videos** — Optional download (~500 MB zip from Google Drive), extracts to ~/Downloads. Has a "naughty" second prompt if declined.
28. **Cleanup & Reboot** — Removes temp files, Flatpak build cache, thumbnails, fontconfig cache, Mesa shader cache, DNF metadata, unused Flatpak runtimes, orphaned RPMs, old journal logs (3-day). Rebuilds icon caches. Shows **`__install_summary()`** (duration, steps, flatpak results, disk usage, theme info), then victory banner, "More from Eprahemi" footer, and reboot prompt.

---

## 3. BOOTSTRAP FLOW (`bootstrap.sh`)

The bootstrap script is the internet-first entry point:
1. **Terminal checks** — Blocks Ptyxis, recommends Kitty (two any-key prompts if non-Kitty)
2. **ASCII Splash Banner** — MacTahoe ASCII art, GNOME version, **bold red warning about yes/no prompts**, press any key
3. **ALL prompts before clone** (9 total):
   - **Discord** — `[y/N]` default **No** (changed from Yes per user request)
   - **Desktop wallpaper** — `[Y/n]` default Yes
   - **Login screen wallpaper** — `[Y/n]` default Yes
     - If Yes → **second confirm** `[Y/n]` with gdm/gdm.fish info
   - **18+ wallpapers** — `[y/N]` default No
   - **Billie & Jinx videos** — `[y/N]` default No
     - If No → **naughty second prompt** `👀  For real though? [y/N]`
4. **Git check** — Installs git if missing
5. **"Grabbing the Goods"** — Clone banner
6. **Clone bundle** — `git clone --depth 1` to `/tmp/fedora-mactahoe`
7. **"Got Everything"** — Success banner after clone
8. **Hides Fedora logo** — `sudo dconf` at GDM level
9. **Copies Eprahemi License** — To `~/Documents/`
10. **Runs `install.sh`** — `cd /tmp/fedora-mactahoe && bash install.sh`

Bootstrap passes all env vars (`INSTALL_DISCORD`, `INSTALL_DESKTOP_WALLPAPER`, `INSTALL_LOGIN_WALLPAPER`, `INSTALL_WALLPAPER_18`, `INSTALL_BILLIE_VIDEOS`) so install.sh runs fully automated with no prompts.

---

## 4. GDM WALLPAPER SWITCHER (`gdm` Fish Function)

### File: `configs/fish/functions/gdm.fish` (~2215 lines)

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
- **System:** `gdm`, `testdrive`, `cleanreset`, `refresh` (now has `--chrome` flag: clears Singleton lock files from Chrome/Chromium/Edge/Brave), `stats`, `stayawake`, `getdata`, `pfp`
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
- **XDG search engine** (`__pfp_search`): When the given path doesn't exist, searches recursively through 8 XDG directories (Pictures, Downloads, Documents, Videos, Music, Desktop, Templates, Public) using `find`. First tries exact filename match, then wildcard (`*$query*`), then CWD as fallback. Results are deduplicated and filtered to image file extensions only. Status messages go to stderr so they don't pollute command substitution.
- **Short search guard**: Search terms < 3 chars (after stripping extension) are rejected with an error box — prevents slow `find` on too-broad patterns.
- **Single match auto-accepted**: If exactly one image found, uses it directly without prompt.
- **Multi-picker**: If multiple results, shows a numbered interactive picker with green `[ 1]` `[ 2]` etc. labels. Fish `$var[` array-index bracket ambiguity avoided by using a `$label` variable (printf "[%2d]").
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

### `confirm()` Function (Both Files)
- Replaces all `read -n 1` yes/no prompts with `read -rp` + input validation
- Accepts: `y`/`Y`/`yes`/`Yes`/`yEs`/`yeS`/`YES` for yes, `n`/`N`/`no`/`No`/`nO`/`NO` for no
- **Everything else** (k, h, x, random text) → `"Type y/yes or n/no"` → loops forever
- Empty (Enter) → uses default (`Y` or `N`)
- Uses `echo -en` + `read -r </dev/tty` instead of `read -p` (ANSI codes not interpreted by `read -p`)

### Ptyxis Removal
- Ptyxis gets removed during setup because it conflicts with Kitty
- Removes package, config, data, dconf, desktop entries, symlinks
- Installer blocks running from Ptyxis entirely

### Firefox Theming
- Applied via `tweaks.sh -f` from upstream MacTahoe repo
- **Close-wait loop**: If Firefox is running, sends `killall` then polls `pgrep` every 1s for up to 10s
- After timeout, shows manual-close prompt with skip option (`s` to skip, Enter to retry)
- Requires Firefox to have been launched once (to create profile directory)

### Login Screen Wallpaper (NEW prompt)
- **Not mandatory anymore** — separate `INSTALL_LOGIN_WALLPAPER` env var
- Prompted between desktop wallpaper and 18+ wallpapers
- **Dual confirmation**: first `[Y/n]`, then a second `[Y/n]` if Yes
- Second box reassures user they can change anytime with `gdm` terminal command
- Both `apply_wallpapers()` copy and `setup_gdm()` background assignment guarded by the env var

### Sound System
- Bundled Big Sur OGA files in `sounds/bigsur/stereo/`
- Falls back to building from source if not bundled
- Enabled via gsettings `org.gnome.desktop.sound theme-name "bigsur"`

### Flatpak GTK Runtime
- Builds `org.gtk.Gtk3theme.MacTahoe-Dark` runtime from local theme files
- Uses `ostree` + `appstream-compose` + `flatpak build-bundle`
- Installs system-wide via `flatpak install --system`

### Update Notifier System
- **No COPR/Flatpak infrastructure**: Uses lightweight `notify-send` + systemd timer approach instead of building per-update RPMs
- **Kitty-first terminal detection**: Updater script prefers Kitty if installed, falls back to gsettings default terminal
- **Three-terminal-family support**:
  - `gnome-terminal`/`kgx` → `-- bash -c "..."` (remaining args)
  - `mate-terminal`/`xfce4-terminal`/`lxterminal`/`sakura` → `-e "bash -c '...'"` (single string)
  - Everything else (kitty, konsole, alacritty, etc.) → `-e bash -c "..."` (remaining args)
- **Two-cache persistence system**:
  - `last-notified-commit`: saved on "Update Now" → never re-notified for that version
  - `last-dismissed-commit`: saved on "Later"/X → cleared on next boot (detected via `/proc/sys/kernel/random/boot_id`)
- **Notification behavior**: `-u critical -t 0` → stays on screen until user clicks a button
- **Sound**: `message-attention` from the Big Sur sound theme
- **Timer**: `OnBootSec=5min` + `OnUnitActiveSec=2h` (catches mid-session pushes without spam)

---

## 8. BUG REGISTRY & FIXED ISSUES

### Fixed
| Bug | Fix | Commit |
|-----|-----|--------|
| `info()` called on line 2931 of install.sh (Window Title Pro step) — undefined function, `set -euo pipefail` kills whole install | Replaced with unconditional `rm -rf "$wtp_target" 2>/dev/null \|\| true` | `a99d9489` |
| `_FED_LOG` set in bootstrap.sh but never exported — install.sh doesn't inherit it, creates second log file | Added `export _FED_LOG` in bootstrap.sh line 10 | `a99d9489` |
| `refresh.fish` had no way to clear browser Singleton lock files (Chrome/Chromium/Edge/Brave) | Added `--chrome`/`-ch` flag with 4 browser lock cleanup steps, included in `--all` | `5a0f23b1` |
| Two-log problem (bootstrap.sh + install.sh each create a log file) | `install.sh` checks `if [ -z "\${_FED_LOG:-}" ]` before creating its own log. bootstrap exports `_FED_LOG` → install.sh skips | `a99d9489` |
| MATE Terminal `-e` flag passes command as separate args instead of single string | Added `mate-terminal`/`xfce4-terminal`/`lxterminal`/`sakura` case using `-e "bash -c '...'"` (single string) | Session (94fcfd65) |
| Notification showed every 30 min with no boot-persistence | Replaced single-cache with two-file approach: `last-notified-commit` (permanent) + `last-dismissed-commit` (cleared on boot via `boot_id` detection) | Session (94fcfd65) |
| Quoting broke arrays with spaces | `contains -- "$r"` and `set image "$results[...]"` | Session |
| `gdm current` showed double confirm | `skip_double_confirm` flag + fall-through instead of `--yes` recursion | `46f878a2` |
| Default blur showed LIKE THE RESULT? | Removed prompt — applies immediately | Session |
| Custom blur LIKE THE RESULT? defaulted to Yes | Changed to `[y/N]` — Enter = retry | Session |
| Wallpapers in `~/.config/Wallpapers/` | Migrated to `~/.local/share/backgrounds/` | `46f878a2` |
| 16.jpg forced on user decline | Removed fallback entirely | `46f878a2` |
| PNG/GIF/WEBP failed on GDM | JPEG 90% auto-conversion added | `c6e83e28` |
| JPEG conversion ran before blur | Moved to right before apply (after blur) | `46f878a2` |
| Ptyxis blocks install entirely | Added full Ptyxis detection + blocking with helpful message | Original |
| Decibels play/pause buttons show "block missing icon" | Symlink `pause-large-symbolic` → `media-playback-pause-symbolic` and `play-large-symbolic` → `media-playback-start-symbolic` in all 5 size dirs of icon theme | Session |
| Decibels skip-back/skip-forward buttons show "block missing icon" or invisible `#222222` fill | Replace skip SVG files with Adwaita-style rotate-left/rotate-right arrows using `currentColor` (#dedede) | Session |
| Two log files when running via bootstrap.sh (`bootstrap.sh` + `install.sh` each create one) | `install.sh` checks `if [ -z "\${_FED_LOG:-}" ]` — skips log setup when called from bootstrap | Session |
| Window Title Pro right-click context menu broken in GNOME Shell 50 | Removed entire right-click menu (Clutter.ClickGesture lacks `set_button`/`pressed` signals) | Session |

### Known Issues (Unfixed)
- GDM changes require reboot (GNOME Shell restart insufficient)
- Firefox theming requires first Firefox launch (can't create profile in advance)
- Flatpak GTK runtime build can fail if ostree/appstream-compose missing
- Google Drive download URLs for 18+ content may expire (need updating)
- Wallpaper black-screen after install: `rm -rf /usr/share/backgrounds/*` always runs, deleting user's current wallpaper if it lives there. When user opts out of desktop wallpaper (`INSTALL_DESKTOP_WALLPAPER=false`), no `picture-uri` gsettings are set, so GNOME shows black/dark solid color. Reboot fixes it (zip re-populates paths). User declined /tmp backup fix.

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
- **Emoji double-width caveat** — emoji (🔥 👀 ⚠ 🐙 ⭐ 😩 💦 🖥) render as 2 visual columns but bash `${#var}` counts them as 1. For variable-padded boxes, adjust `pad_max` down by `(emoji_vis_count - emoji_bash_count)` to compensate. Standard boxes use pad_max=62; the "More from Eprahemi" box uses a wider 63-char inner width with a 2-space echo prefix.
- **→ (U+2192) is single-width** in this terminal + SF Pro font, despite being in the Arrows Unicode range. Do NOT count → as double-width in visual-width calculations.

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
│   ├── updater/
│   │   ├── fedora-mactahoe-updater.sh    # Update notifier script
│   │   ├── fedora-mactahoe-updater.service  # Systemd oneshot service
│   │   └── fedora-mactahoe-updater.timer    # Systemd timer (boot + 2h)
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
│   │   ├── gdm.fish        # GDM wallpaper switcher (~2215 lines)
│   │       ├── getdata.fish
│   │       ├── hollywood.fish
│   │       ├── l.fish
│   │       ├── matrix.fish
│   │       ├── mkgif.fish
│   │       ├── myip.fish
│   │       ├── n.fish
│   │       ├── passgen.fish
│   │   ├── pfp.fish       # Profile picture manager (~878 lines, XDG search engine)
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
├── EPRAHEMI FORK EXTENSIONS/
│   └── window-title-pro@eprahemi.github.io/  # Window Title Pro GNOME extension
│       ├── extension.js
│       ├── metadata.json
│       ├── prefs.js
│       └── schemas/
│           └── org.gnome.shell.extensions.window-title-pro.gschema.xml
├── fonts/
│   └── SF-Pro-Display-Regular.otf
├── icons/
│   └── 256x256/                # Custom macOS app icons
├── install.sh                  # 3309 lines, 24 steps + 3 atmosphere prompts
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

> **📌 User Note (Jun 30, 2026):** `Fedora MacTahoe — All Visual Outputs.md` lives at the repo root — a running document of every visual output the scripts produce. Check here for expected terminal output, screenshots, and formatting reference.  
> **Latest:** WALLPAPER_18_URL updated to new Google Drive link (id `1pHuIkixIfQR_KMnaIOvMutHgaZ32oBRg`). Committed alongside the Visual Outputs doc as `a07a16e0`.

---

## 12. RECENT COMMITS (Latest on top)

```
8e7f2cab fix: add warn fallbacks for chsh, gtk settings.ini copy, and kitty.desktop chown
7c79cc2e fix: add warn messages to all gtk-update-icon-cache calls
3bd2ebb6 fix: proper error handling for remaining silent-failure areas
e121553e fix: proper error handling for all remote downloads and git clones
94e897df chore: remove unused /tmp/ copy of login wallpaper
83b1ff6a refactor: only one Wallvault folder + XML exists based on +18 choice
90c6e964 fix: always delete leftover login wallpaper from ~/.local/share/backgrounds/
21bd1202 refactor: always copy Himeno Fedora.jpg to ~/.local/share/backgrounds/
8959c350 feat: clean up leftover Himeno images from /usr/share/backgrounds/Wallvault Wallpapers/
19654095 fix: exclude Himeno Fedora.jpg from Wallvault wallpapers directory
9752a3e9 feat: clean up leftover login wallpaper from ~/.local/share/backgrounds/
c8e35f9d refactor: GDM login wallpaper copies to /tmp/ instead of ~/.local/share/backgrounds/
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
bash install.sh               # Full 24-step installer + 3 atmosphere prompts (tunnel, dashboard, speed test)

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

# Quick Decibels icon fix (run on any laptop with MacTahoe themes)
for theme in MacTahoe-dark MacTahoe; do
  d="$HOME/.local/share/icons/$theme"; [ -d "$d" ] || continue
  for sub in actions/24 actions/48 actions/64 actions/scalable actions/symbolic; do
    s="$d/$sub"; [ -d "$s" ] || continue
    [ -f "$s/media-playback-pause-symbolic.svg" -a ! -f "$s/pause-large-symbolic.svg" ] && \
      ln -sf "media-playback-pause-symbolic.svg" "$s/pause-large-symbolic.svg"
    [ -f "$s/media-playback-start-symbolic.svg" -a ! -f "$s/play-large-symbolic.svg" ] && \
      ln -sf "media-playback-start-symbolic.svg" "$s/play-large-symbolic.svg"
  done
done
gtk-update-icon-cache "$HOME/.local/share/icons/MacTahoe-dark/"
gtk-update-icon-cache "$HOME/.local/share/icons/MacTahoe/"
# Restart Decibels: killall org.gnome.Decibels && /usr/bin/org.gnome.Decibels &

# Window Title Pro extension
# Install from GitHub release (used by install.sh)
wget -O /tmp/window-title-pro.zip https://github.com/eprahemi/window-title-pro/releases/download/v1/window-title-pro.zip
mkdir -p ~/.local/share/gnome-shell/extensions/window-title-pro@eprahemi.github.io
unzip -o /tmp/window-title-pro.zip -d ~/.local/share/gnome-shell/extensions/window-title-pro@eprahemi.github.io/
glib-compile-schemas ~/.local/share/gnome-shell/extensions/window-title-pro@eprahemi.github.io/schemas/
gnome-extensions enable window-title-pro@eprahemi.github.io

# Icon cache rebuild
gtk-update-icon-cache ~/.local/share/icons/MacTahoe-dark/
gtk-update-icon-cache ~/.local/share/icons/MacTahoe/
```

---

## 14. VERSION HISTORY
- **Current:** 2026-07-02 — Update notifier system (step 28), commit `94fcfd65`
- **Previous:** Session (atmosphere prompts: system dashboard, CDN speed test, install summary)
- **Prior:** `4da20e31` (install_extensions set -e bug: `[ ... ] &&` as function tail kills script when all succeed)
- **Session highlights (2026-07-02 — Combined Session: Decibels/Log/WTP + Update Notifier):**
  - **Window Title Pro GNOME extension**: Created skeleton (`window-title-pro@eprahemi.github.io`), wrote `extension.js`/`prefs.js`/`gschema.xml` with 11 settings keys, panel-position switching, `Super+Y` keyboard shortcut via `Main.wm.addKeybinding()`, shortcut recorder widget in prefs. Removed right-click context menu entirely (GNOME Shell 50 `Clutter.ClickGesture` lacks `set_button`/`pressed`). Fixed EGO warnings: replaced custom `_destroy()` with `destroy` signal, excluded `gschemas.compiled` from zip. Published to GitHub repo `eprahemi/window-title-pro` (v1) and submitted to EGO (v1 rejected, v2 Unreviewed).
  - **Window Title Pro → install.sh**: `install_extensions()` downloads zip from GitHub release, extracts to `~/.local/share/gnome-shell/extensions/`, compiles schemas, enables extension.
  - **Window Title Pro crash fix** (`a99d9489`): `info "already installed"` on line 2931 used undefined `info()` function → `set -e` killed install. Replaced with `rm -rf "$wtp_target" 2>/dev/null || true`.
  - **Log dedup fix** (`a99d9489`): `_FED_LOG` was set but not exported in bootstrap.sh → install.sh didn't inherit it. Added `export _FED_LOG` on line 10.
  - **Decibels play/pause icons**: GTK lookup for `pause-large-symbolic`/`play-large-symbolic` fell to `image-missing.svg` (block placeholder). Fix: symlink in all 5 size dirs × 2 themes (20 symlinks total).
  - **Decibels skip icons**: Replaced `skip-backwards-10-symbolic.svg` and `skip-forward-10-symbolic.svg` with Adwaita-style rotate arrows using `currentColor` + `#dedede`.
  - **`refresh --chrome` flag** (`5a0f23b1`): Added `-ch`/`--chrome` to refresh.fish — clears Singleton lock files from Chrome/Chromium/Edge/Brave without touching profiles. Part of `--all`.
  - **Update Notifier System** (step 23, `install_updater()`): Installs `fedora-mactahoe-updater.sh` to `~/.local/bin/`, creates systemd service + timer (`OnBootSec=5min` + `OnUnitActiveSec=2h`). Two-cache persistence: `last-notified-commit` (Update Now → permanent), `last-dismissed-commit` (Later/X → cleared on next boot via `boot_id` detection). Kitty-first terminal detection with 3-terminal-family case statement. Sound: `message-attention` from Big Sur theme. Banner updated to 28-Step Installer. Pushed as commits `0a7325f9` and `94fcfd65`.
- **Session highlights (2026-06-30 — Atmosphere Prompts):**
  - Added `__system_dashboard()` — real system info box (CPU, RAM, disk, GPU, kernel, uptime)
  - Added `__cdn_speed_test()` — simulated optimal route test with visual bars
  - Added `__install_summary()` — final recap with duration, flatpak counts, disk usage
  - All three wired into main flow: banner → tunnel → dashboard → speed test → preflight
  - Cleanup → install summary → victory banner → reboot
  - `fp_ok`/`fp_fail` promoted to globals `INSTALL_FP_OK`/`INSTALL_FP_FAIL`
  - `INSTALL_START_EPOCH` tracking for elapsed time calculation
  - All padding uses ANSI-free reference strings (no emoji-alignment bugs)
  - `bc` avoided — all math via `awk` or integer arithmetic
  - Updated "Fedora MacTahoe — All Visual Outputs.md" with 3 new sections + install summary
- **Session highlights (2026-06-30 — Error Hardening):**
  - `c8e35f9d` — GDM login: copy to /tmp/ (later removed)
  - `9752a3e9` — Clean up leftover Himeno login images from ~/.local/share/backgrounds/
  - `19654095` — Exclude Himeno Fedora.jpg from Wallvault directory copy
  - `8959c350` — Clean leftover Himeno from Wallvault dir pre-copy
  - `21bd1202` — Always copy desktop wallpaper to ~/.local/share/backgrounds/
  - `90c6e96` — Always delete leftover login wallpaper from ~/.local/share/backgrounds/
  - `83b1ff6a` — Only one Wallvault folder + XML based on +18 choice
  - `94e897d` — Remove dead /tmp/ login wallpaper copy
  - `e121553e` — Google Drive mime-type HTML detection + git clone warns
  - `3bd2ebb6` — Flatpak/extensions/starship/browser/font/ostree error handling
  - `7c79cc2` — Icon cache `|| true` → `|| warn` on all 8 calls
  - `8e7f2cab` — chsh/gtk-settings/kitty.desktop → warn fallbacks
  - `4da20e31` — ⚠️ EXTENSION BUG FIX: `[ ... ] && warn` as function tail returns non-zero → `set -e` kills script after "N extensions installed"

---

## APPENDIX A: ANCHORED SESSION SUMMARY — BUG REGISTRY

This section is the master record of every bug ever fixed in the Fedora MacTahoe project, directly from `ANCHORED_SESSION_SUMMARY.md`. **If you're about to edit install.sh or bootstrap.sh, read this first.**

### 🔴 CLASS A: SYNTAX / CRASH BUGS

These caused (or would cause) the script to abort silently on edge cases.

| # | File | Bug | Fix |
|---|------|-----|-----|
| 1 | install.sh | `walk_pid=$(cat … \| awk …)` — process tree walk fails with non-zero exit on orphan | Added `\|\| true` |
| 2 | install.sh | `release=$(rpm -E %fedora)` — theoretical abort if `rpm` ever fails | Added `2>/dev/null \|\| release="40"` |
| 3 | install.sh | `dl_url=$(curl … \| jq …)` — extension API failure aborts script | Added `\|\| true` |
| 4 | install.sh | All `read -r -s -n 1 key` and `read -rp` — Ctrl+D aborts under `set -euo pipefail` | Added `\|\| true` after each read |
| 5 | bootstrap.sh | Same `read` pattern without fallback | Added `\|\| true` |
| 6 | install.sh | Missing `fi` for outer `if [ -z "${KITTY_PID:-}" ]` at line 78 — Kitty warning `while` loop had no closing `fi` for the if | Added missing `fi` after Kitty warning block |
| 7 | install.sh | Line 2930-2933: `info "already installed — removing prior copy"` called undefined `info()` function → `set -euo pipefail` kills entire install | Replaced with `rm -rf "$wtp_target" 2>/dev/null \|\| true` |
| 8 | bootstrap.sh | `_FED_LOG` was set but never exported — bash doesn't pass unexported variables to child processes | Added `export _FED_LOG` on line 10 |

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
| 28 | install.sh | Firefox theming step: `killall firefox firefox-bin` sent SIGTERM but didn't wait — `tweaks.sh -f` checked `pgrep` before Firefox exited and refused to run | Added close-wait loop: `killall` → poll `pgrep` every 1s up to 10s → manual prompt with skip → retry |
| 29 | updater.sh | `mate-terminal -e` expects entire command as single string argument — passing `bash -c "..."` as separate args failed silently | Added `mate-terminal`/`xfce4-terminal`/`lxterminal`/`sakura` case using `-e "bash -c '...'"` (single string) |
| 30 | updater.sh | Single `last-notified-commit` cache always saved before checking button result → "Later" also saved hash → never re-notified | Split into two files: `last-notified-commit` (Update Now only) + `last-dismissed-commit` (Later/X, cleared on boot via `boot_id`) |

### 🔴 CLASS A (continued): CRASH BUGS (Fixed 2026-06-30, post-hardening)

| # | File | Bug | Fix |
|---|------|-----|-----|
| 6b | install.sh | `[ "$ext_fail" -gt 0 ] && warn "..."` was the last command in `install_extensions()`. When all 14 extensions installed (ext_fail=0), `[ 0 -gt 0 ]` returned 1 (false), making the function return 1. `set -e` on the caller line killed the script right after "14 extensions installed". **Introduced by error-hardening commit `3bd2ebb6`.** | Changed to `if [ "$ext_fail" -gt 0 ]; then warn; fi` — ensures function returns 0 when no failures. |

**IMPORTANT LESSON:** `[ ... ] && command` as the LAST command in a function makes the function return the exit code of the `&&` list. When the condition is false, `[` returns 1, the function returns 1, and `set -e` kills the caller. **Always use `if [ ... ]; then command; fi` at function tails.**

### 🟢 CLASS G: SILENT FAILURES (Fixed 2026-06-30)

| # | File | Bug | Fix |
|---|------|-----|-----|
| 76 | install.sh | Google Drive deleted files returned HTML (200 OK) → `unzip` or `cp` failed with opaque error | `file --brief --mime-type` check after every curl; if HTML, warn "file may be deleted from Google Drive" instead of failing |
| 77 | install.sh | `setup_gdm()` `/tmp/` login wallpaper copy was written but never consumed by `tweaks.sh -b` — dead weight | Removed entirely; `setup_gdm()` reads direct from bundle path |
| 78 | install.sh | `Himeno Fedora LoginScreen.jpg` leftover in `~/.local/share/backgrounds/` from old runs never cleaned | Unconditional `rm -f` in `apply_wallpapers()` |
| 79 | install.sh | `Himeno Fedora.jpg` only copied to `~/.local/share/backgrounds/` if user chose desktop wallpaper — always needed | Always copied regardless of wallpaper choice |
| 80 | install.sh | Both Wallvault folders (`Wallvault Wallpapers` + `Wallvault Wallpapers +18`) could accumulate stale files | Only one folder + XML survives based on `INSTALL_WALLPAPER_18`; opposite destroyed entirely |
| 81 | install.sh | `git clone` for GDM repo used `|| true` — failure hidden with no user feedback | Replaced with `if ! git clone ...; then warn` |
| 82 | install.sh | `flatpak install` 14 apps used 14 separate `|| true` calls — no aggregate success/fail tracking | Loop with counters → `"N installed"` / `"M failed"` |
| 83 | install.sh | GNOME extension install used `|| true` after curl and after `gnome-extensions install` — failures invisible | Per-UUID tracking; warns for missing EGO URL, failed curl, failed install |
| 84 | install.sh | `Starship` install used `|| true` — failure hidden | Replaced with `if ! ...; then warn` |
| 85 | install.sh | Browser GPG key imports + Chrome/Edge install used `|| true` — failures hidden | Replaced with `if ! ...; then warn` |
| 86 | install.sh | `fc-cache` failure hidden by `|| true` | Replaced with `|| warn` |
| 87 | install.sh | Flatpak GTK runtime `ostree init` failure hidden by `|| true` | Early `return` with warn |
| 88 | install.sh | All 8 `gtk-update-icon-cache` calls used `|| true` — failures invisible | All changed to `|| warn` |
| 89 | install.sh | `chsh -s /usr/bin/fish "$USER"` had no `|| true` — if fish not in `/etc/shells`, `set -e` kills script | Changed to `if sudo chsh ...; then ok; else warn; fi` |
| 90 | install.sh | GTK `settings.ini` copy had no error handling — `set -e` could abort if copy fails | Added `|| warn` to both gtk-3.0 and gtk-4.0 copies |
| 91 | install.sh | kitty.desktop `cp` + `chown` for stale entries had no error handling — `set -e` could abort | Split into separate lines with `|| warn` each |

### 🟠 CLASS C: CONTENT / UX / MISSING FEATURES

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
| 28 | Gintama video saved as generic `gintama.mp4` | Renamed to `Gintama - Bad Boy.mp4` |
| 29 | Login screen wallpaper was always mandatory with no prompt | Added separate `INSTALL_LOGIN_WALLPAPER` prompt with dual confirmation |
| 30 | GDM second confirmation said scary "cannot be undone / manually reset" | Reassures user they can change anytime with `gdm` terminal command + explains `gdm.fish` |
| 31 | First login screen prompt didn't mention gdm command | Added "Not stuck with just this one — the gdm command lets you swap wallpapers anytime" |
| 32 | Splash banner had no warning about yes/no prompts | Added bold red line: "⚠  Read yes/no prompts carefully — some are permanent!" |
| 33 | Discord defaulted to Yes | Changed to No (`[y/N]` default No) |
| 34 | Billie & Jinx prompt missing from bootstrap.sh | Added before clone section |
| 35 | All yes/no prompts used `read -n 1` with no validation | Replaced with `confirm()` function — validates y/yes/n/no, loops on invalid input |
| 36 | `refresh.fish` couldn't clear browser Singleton lock files — Chrome/Chromium/Edge/Brave failed to open after refresh | Added `--chrome`/`-ch` flag removing `SingletonLock`/`SingletonSocket`/`SingletonCookie` from 4 browser config dirs |
| 37 | Wallpaper black-screen after opting out of desktop wallpaper — `rm -rf /usr/share/backgrounds/*` always runs, deleting current wallpaper | User declined fix (reboot repopulates via zip). Known issue, not a bug in our code |

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

**Emoji caveat**: Double-width emoji (⛔ 📦 ✅ 🔥 👀 ⚠ 🐙 ⭐ 😩 💦) report as 1 char in bash `${#var}` but render as 2 columns. For variable-padded boxes, subtract the emoji surplus from `pad_max`. Affected lines across 4 boxes in install.sh.

**ASCII art banners** use fixed single-quoted strings that fill 62 cols — do NOT convert to dynamic.

**New entries from session `7c06b83d`:**
| # | Box | Bug | Fix |
|---|-----|------|-----|
| 65 | Firefox close (L1831-1836) | Title + 3 body lines had wrong trailing spaces | Adjusted: title +3, L1834 −1, L1835 −2, L1836 −2 |
| 66 | Firefox still running (L1848-1849) | Both lines had excess trailing spaces | L1848 −3, L1849 −5 |
| 67 | Billie & Jinx (bv_t, bv1) | 🔥 double-width → overflow by 1 | `pad_max 62→61` |
| 68 | Naughty prompt (nsty_t, nsty2, nsty3) | 👀🔥💦😩 double-width → overflow by 2 | `pad_max 62→60` |
| 69 | More from Eprahemi (m1, m4) | 🐙⭐ double-width → overflow by 1 | `pad_max 63→62` |
| 70 | NVIDIA (L427) | Trailing spaces 30 → needed 31 | +1 trailing |
| 71 | ARE YOU SURE (L1289) | ⚠ renders single‑width in GNOME Terminal + SF Pro → was underflowing by 2 | **REVERTED**: 22→24 trailing spaces (matching bootstrap.sh) |
| 72 | Billie/Naughty `'\''` quoting bug | `'\''` inside double‑quoted echo renders literally (`\`+`'`), adding 2 extra visible chars | Replace `'\''` with `'` in bootstrap.sh L322/L351, install.sh L1390 |
| 73 | `faces +18` separate folder | Avatars stored in two folders: `faces` (normal) and `faces +18` (18+) | Eliminate `faces +18`; 18+ replaces normal in `faces` based on user choice |
| 74 | Normal avatar path missing `mkdir -p` | On minimal installs, `/usr/share/pixmaps/faces/` might not exist → `sudo cp` fails silently | Added `sudo mkdir -p "$face_dir"` before normal avatar loop |
| 75 | Stray `face*`/`faces*` folders not cleaned | Old runs could leave `faces +18`, `faces-backup`, etc. in `/usr/share/pixmaps/` | Glob purge: `for dir in /usr/share/pixmaps/face*;` skips `faces`, deletes rest silently |

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
5. **GNOME avatar picker ONLY reads from `/usr/share/pixmaps/faces/`**. The old `faces +18/` dir was eliminated — now all avatars go to a single folder and the +18 choice swaps the content. Always purge stray `face*`/`faces*` folders before install.
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
14. **Google Drive deleted files return HTML at 200 OK (not 404).** Always check with `file --brief --mime-type` after any GDrive curl before piping to `unzip`, `cp`, or other consumers.
15. **`set -euo pipefail` does NOT apply inside `if` conditions.** Use `if command; then ok; else warn; fi` instead of `command || warn` when you need to branch on success/failure without aborting the script.
16. **Flatpak install failures are per-app, not global.** Use a loop with counters to track individual successes instead of a single `|| true` after a chain.
17. **Icon cache rebuilds are non-critical** — failure only affects caching performance, icons still exist on disk. Always use `|| warn` not `|| die` for `gtk-update-icon-cache`.
18. **Wallpapers: GDM login wallpaper is NEVER copied to an intermediate location.** `setup_gdm()` passes the bundle path directly to `tweaks.sh -b`. The `~/.local/share/backgrounds/` copy is only for the desktop wallpaper (`Himeno Fedora.jpg`), which is always copied unconditionally.
19. **`[ ... ] && command` at function tail is a `set -e` trap.** When the condition is false, `[` returns 1, the `&&` list propagates 1, the function returns 1, and `set -e` kills the caller. **Always use `if [ ... ]; then command; fi` for the last command in a function.**

---

## Done

### All changes committed and pushed as of `94fcfd65` (2026-07-02)

### What was accomplished this session

| Area | Changes |
|------|---------|
| **Update Notifier** | New `install_updater()` step 23. Script with Kitty-first terminal detection, 3-terminal-family support, two-cache persistence (boot-crossing), `message-attention` sound, `OnBootSec=5min` + `OnUnitActiveSec=2h` timer |
| **Window Title Pro** | Created GNOME extension with 11 settings, Super+Y shortcut, panel-position switching. Fixed EGO warnings. Integrated into install.sh. Fixed crash (`info()` → `rm -rf`). Published to GitHub + EGO |
| **Decibels Icons** | Fixed play/pause/skip icons (symlinks + custom SVGs) across 5 size dirs × 2 themes |
| **Log Dedup** | Single log file regardless of bootstrap.sh or install.sh entry point |
| **refresh --chrome** | New flag clears Singleton lock files from 4 browsers |
| **MATE Terminal** | Fixed `-e` flag handling for single-string terminals |
| **Banner & Steps** | Updated to 28-Step Installer |

### New / Modified Files

| File | Change |
|------|--------|
| `configs/updater/fedora-mactahoe-updater.sh` | **NEW** — Update notifier script |
| `configs/updater/fedora-mactahoe-updater.service` | **NEW** — Systemd oneshot service |
| `configs/updater/fedora-mactahoe-updater.timer` | **NEW** — Systemd timer (boot + 2h) |
| `install.sh` | Added `install_updater()` function, renumbered phases to 28 steps, updated banner |
| `bootstrap.sh` | `export _FED_LOG` (commit `a99d9489`) |
| `configs/fish/functions/refresh.fish` | Added `--chrome` flag (commit `5a0f23b1`) |

### Critical Context (Update Notifier)

- **Cache files** in `~/.cache/fedora-mactahoe/`:
  - `last-notified-commit` — saved on "Update Now", never re-notified
  - `last-dismissed-commit` — saved on "Later"/X, cleared on boot
  - `last-boot-id` — tracks `/proc/sys/kernel/random/boot_id` for reboot detection
- **Terminal detection order**: 1) Kitty if installed, 2) gsettings default terminal
- **Timer**: `OnBootSec=5min` (after login) + `OnUnitActiveSec=2h` (catches mid-session pushes)
- **Sound**: `message-attention` from Big Sur theme
- **Notification**: `-u critical -t 0` (persistent, no auto-dismiss)
- **No COPR/Flatpak**: lightweight notify-send + systemd timer approach
