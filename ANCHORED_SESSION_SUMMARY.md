# Anchored Session Summary — Fedora MacTahoe (Eprahemi Edition)

## ⚠ CRITICAL BUG REGISTRY — NEVER REPEAT THESE ⚠

This is the master record of every bug ever fixed. If you're about to edit install.sh or bootstrap.sh, **read this first**.

---

### 🔴 CLASS A: SCRIPT CRASHES (set -euo pipefail violations)

These caused (or would cause) the script to abort silently on edge cases.

| # | Line(s) | File | Bug | Fix |
|---|----------|------|-----|-----|
| 1 | 79 | install.sh | `walk_pid=$(cat … \| awk …)` — process tree walk fails with non-zero exit on orphan | Added `\|\| true` |
| 2 | 322 | install.sh | `release=$(rpm -E %fedora)` — theoretical abort if `rpm` ever fails | Added `2>/dev/null \|\| release="40"` |
| 3 | 1112 → now ~1120 | install.sh | `dl_url=$(curl … \| jq …)` — extension API failure aborts script | Added `\|\| true` |
| 4 | 138,158,369,1242 | install.sh | All `read -r -s -n 1 key` and `read -rp` — Ctrl+D aborts under `set -euo pipefail` | Added `\|\| true` after each read |
| 5 | 102,137,171 | bootstrap.sh | Same `read` pattern without fallback | Added `\|\| true` |

### 🟡 CLASS B: LOGIC / INPUT BUGS

| # | Line(s) | File | Bug | Fix |
|---|----------|------|-----|-----|
| 6 | All `read` | both | `read -r -s -n 1 key` used `-s` (silent) making debug impossible + used `[ "$key" = " " ]` requiring SPACE | Removed `-s`, changed to `[ -n "$key" ]` to accept **any key** |
| 7 | All `read` | both | `read` without `</dev/tty` — breaks in non-interactive shells | Added `</dev/tty` |
| 8 | ~1400 | install.sh | TOTAL_STEPS was 21 but there were 22 `next_step` calls | Fixed to TOTAL_STEPS=22, updated phase dividers |
| 9 | 893 | install.sh | `sudo rm -rf /usr/share/backgrounds/` only deleted subdirs + `.jpg`, missed other formats | Changed to `sudo rm -rf /usr/share/backgrounds/*` (catch-all) |
| 10 | 981 | install.sh | `sudo rm -rf "$face_dir"*.jpg` only deleted `.jpg`, missed `.png`/`.webp`/`.gif` | Changed to `sudo rm -rf "$face_dir"/*` (catch-all) |
| 11 | 944-949 | install.sh | Stock XMLs were moved to `stock-backup/` instead of deleted | Changed to `sudo rm -f` (permanent deletion) |
| 12 | 1066 | install.sh | GDM logo dconf override was inside `if [ -f /tmp/mactahoe-gtk/tweaks.sh ]` — skipped if theme clone failed | Moved OUTSIDE the if/else — runs regardless |
| 13 | 624 | install.sh | `INSTALL_DISCORD` usage inconsistency: line 424 `[ "$INSTALL_DISCORD" = "true" ]` vs lines 624/853 `[ "${INSTALL_DISCORD:-true}" = "true" ]` | All safe (variable always set by prompt), but noted for consistency |
| 14 | 388-406 | install.sh | Discord prompt used `┌──┐` box instead of script's signature `╔═╗` double-line style | Polished to match ╔═╗ style |
| 15 | 388-406 | install.sh | Discord prompt `(Y/n)` didn't clarify Enter = default Yes | Changed to `[Y/n]` + "Press Enter for default" |
| 16 | 619-623 | install.sh | `localsend.png` missing from `fp_aliases` — Flatpak LocalSend had no icon | Added `[localsend.png]="org.localsend.localsend_app.png"` |
| 17 | 494-512 | install.sh | LocalSend not in Flatpak install list | Added `flatpak install -y flathub org.localsend.localsend_app` |
| 18 | 524-525 | install.sh | Old MacTahoe themes from other installers are NOT cleaned on re-run — they ARE (intentional wipe) | Verified: `rm -rf $HOME/.themes/MacTahoe*` + `sudo rm -rf /usr/share/themes/MacTahoe*` |
| 19 | 567-568 | install.sh | Old MacTahoe icon themes from other installers cleaned on re-run | Verified: `rm -rf $HOME/.local/share/icons/MacTahoe*` |

### 🟠 CLASS C: CONTENT / UX ISSUES

| # | Description | Fix |
|---|-------------|-----|
| 20 | SPACE prompts said "Press SPACE" but now accept any key | Changed all prompt text to "Press any key" |
| 21 | Humanized tone missing from Ptyxis/NVIDIA/Kitty blocks | Applied consistently across both scripts |
| 22 | `echo -n` used instead of `echo -en` for ANSI color sequences | Changed to `echo -en` |
| 23 | GNOME version in banner was hardcoded padding | Dynamic padding based on version string length |
| 24 | Video copy to `~/Downloads/` had step heading and `ok` output | Inlined silently inside avatar function — zero output, no step, no function call |
| 25 | bootstrap.sh accidentally reverted to git HEAD during testing | Restored all content |

### 🔵 CLASS D: ARCHITECTURE / DESIGN DECISIONS

| # | Decision | Rationale |
|---|----------|-----------|
| 26 | Wallpaper XML required in `/usr/share/gnome-background-properties/` | GNOME 48+ doesn't scan filesystem, reads XML metadata |
| 27 | `Wallvault-Wallpapers` (hyphen, no space) | Avoids path quoting issues |
| 28 | Avatars converted via temp dir → `sudo cp` | `magick` runs as user, can't write to `/usr/share/pixmaps/faces/` directly |
| 29 | Stock XMLs DELETED (not backed up) | User explicitly requested removal of dead Fedora/GNOME entries |
| 30 | Discord optional via `INSTALL_DISCORD` env var | bootstrap.sh exports it → install.sh reads it silently |
| 31 | GDM logo hide runs outside tweaks.sh if/else | Ensures it runs even if theme repo fails to clone |
| 32 | Zero hardcoded `/home/` or username paths | All dynamic: `$HOME`, `$(whoami)`, `$USER` |
| 33 | Kitty IS required (Ptyxis blocked), non-Kitty warned not blocked | Ptyxis gets removed during install → would crash the installer |
| 34 | Stock Fedora GTK/icon themes kept (not deleted) | Safety net — user can switch back in Settings; `dnf update` would reinstall anyway |

---

## Current State

- **install.sh**: 1492 lines, 22 steps, 6 phases
- **bootstrap.sh**: 230 lines
- Both pass `bash -n` syntax check
- All 33 bugs listed above are FIXED and PUSHED to GitHub

## Key Files

| File | Purpose |
|------|---------|
| `install.sh` | Main installer — all 22 steps |
| `bootstrap.sh` | One-liner downloader — curl-pipe-bash entry point |
| `ANCHORED_SESSION_SUMMARY.md` | This file — session log + bug registry |
| `icons/256x256/` | Custom macOS app icons (PNG + SVG) |
| `wallpapers/desktop/` | Desktop wallpapers |
| `wallpapers/login/` | GDM login wallpaper |
| `wallpapers/backgrounds/` | Additional backgrounds (30 files) |
| `assets/faces/` | Custom profile pictures (16 files, 512×512 JPEG) |
| `configs/` | Kitty, Fish, Starship, GTK configs |
| `themes/` | Bundled MacTahoe-Dark fallback theme |

## To Resume

Read this file, then read ANCHORED_SESSION_SUMMARY.md for the full bug registry. Never repeat a fix already in this registry.
