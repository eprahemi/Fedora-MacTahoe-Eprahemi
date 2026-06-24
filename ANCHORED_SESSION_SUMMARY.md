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
| 20 | 18 | install.sh | `WALLPAPER_18_URL` used `drive.google.com/uc?export=download&id=...` which returns HTML (virus scan warning page), not the zip | Changed to `drive.usercontent.google.com/download?id=...&export=download&confirm=t` — direct download, verified working |
| 21 | 20 | install.sh | Same bug for `FACES_18_URL` — also returned HTML | Same fix applied |
| 22 | 1033–1036, 1197–1200 | install.sh | 18+ zip files have nested subdirectories (`backgrounds+18/`, `faces+18/`). Old `for img in "$extract_tmp/"*; [ -f "$img" ] || continue` skipped directories — all files silently lost | Replaced with `while IFS= read -r -d '' img; do ... done < <(find "$extract_tmp" -type f -print0)` — recursive, finds files at any depth |
| 23 | 1194–1216, 1180–1197 | install.sh | 18+ faces installed ONLY to `faces +18/` — GNOME avatar picker scans `/usr/share/pixmaps/faces/` but NOT `faces +18/`. Result: zero avatars visible when 18+ chosen. Also: `$CURRENT_USER` was undefined (variable never set). Normal faces also lacked AccountsService auto-set. | Added `sudo mkdir -p "$face_dir"` + second `sudo cp "$img" "$face_dir/"` in same loop + `sudo chmod 644 "$face_dir"/*` + AccountsService icon update for BOTH normal and 18+ blocks using `$USER` (not `$CURRENT_USER`) |
| 24 | 596-631 | install.sh | `qr-code-symbolic.svg` missing from MacTahoe-dark icon theme — GNOME 48+ WiFi QR button shows no icon | Created `qr-code-symbolic.svg` (16×16, `fill="currentColor"`) in project source; copy to `actions/symbolic/` + `actions/scalable/` during install |
| 25 | 608-628 | install.sh | GNOME 48+ Settings bundles GResource icons at new-style paths like `scalable/actions/` — old-style `Directories` list can't find them | Added 16 new-style dirs (`scalable/actions`, `symbolic/actions`, etc.) to `index.theme` + `mkdir` empty dirs |
| 26 | 596-631 | install.sh | Icon cache not rebuilt after installing icon themes | Added `gtk-update-icon-cache` call per theme + in `finalize()` |

### 🟠 CLASS C: CONTENT / UX ISSUES

| # | Description | Fix |
|---|-------------|------|
| 20 | SPACE prompts said "Press SPACE" but now accept any key | Changed all prompt text to "Press any key" |
| 21 | Humanized tone missing from Ptyxis/NVIDIA/Kitty blocks | Applied consistently across both scripts |
| 22 | `echo -n` used instead of `echo -en` for ANSI color sequences | Changed to `echo -en` |
| 23 | GNOME version in banner was hardcoded padding | Dynamic padding based on version string length |
| 24 | Video copy to `~/Downloads/` had step heading and `ok` output | Inlined silently inside avatar function — zero output, no step, no function call |
| 25 | bootstrap.sh accidentally reverted to git HEAD during testing | Restored all content |
| 26 | Missing icon fix applied to per-user install only — other users (gooner) not covered | Added loop in install.sh that applies same fixes to all `/home/*` users who already have the theme |
| 27 | `rm -rf` used instead of trash for deletion | User rule: always use `gio trash` instead of permanent delete |

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
| 35 | `qr-code-symbolic.svg` uses `fill="currentColor"` | Matches other symbolic icons, works on light and dark backgrounds |
| 36 | Icon fix applied per-user (NOT system-wide) | User rejected system-wide `/usr/share/icons/` approach; prefers per-user copies |
| 37 | Other users' themes get augmented (files added), not replaced | Non-destructive — existing user configs preserved |

### 🟣 CLASS E: BOX ALIGNMENT / DYNAMIC PADDING

| # | Box | File | Original Bug | Fix |
|---|-----|------|-------------|-----|
| 38 | Victory banner (main) | install.sh | `/_/` overflow lines, feature line misaligned (43→62), `Made by` + Firefox warning static | Shortened feature lines to fit 62, dynamic `%*s` for Made by/Firefox |
| 39 | Phase dividers | install.sh | `%*s` padding hardcoded at 62 but banner is 66 wide | Changed to 58 (66 - 4 for `║  ` prefix) |
| 40 | Main banner title + subtitle | install.sh | `gnome_text`/`theme_text` used `%*s` with 62 instead of 60 (no `  ` prefix) | Changed to 60 |
| 41 | "Time to reboot" | install.sh | Text line `"  Time to reboot..."` overflowing, hardcoded trailing spaces | Shortened text + dynamic `%*s` |
| 42 | "Already updated?" | both | Hardcoded trailing spaces | Dynamic `%*s` with `$((62 - ${#var}))` |
| 43 | NVIDIA detection box | install.sh | Missing (was deleted during a collapse) | Restored with dynamic padding |
| 44 | Kitty "Press any key" | both | Line had 14 trailing spaces instead of 15 (off by 1) | Added +1 space to match 62 |
| 45 | Ptyxis detection boxes | both | Various lines with hardcoded padding | All converted to `%*s` dynamic padding |
| 46 | Passwordless sudo prompt | install.sh | Long lines overflowing 62-char box | Rewritten with shorter text + dynamic padding |
| 47 | Discord prompt | install.sh | 7 lines with hardcoded trailing spaces | All converted to `variable + $(printf '%*s' $((62 - ${#var})) '')` pattern |
| 48 | Desktop wallpaper prompt | install.sh | Title + 5 content lines hardcoded | Converted to dynamic padding |
| 49 | 18+ wallpapers prompt | install.sh | Title + 5 content lines hardcoded | Converted to dynamic padding |
| 50 | Incompatible OS box | install.sh | 4 lines missing closing `║`, all lines hardcoded, no ANSI colors | Full rewrite: ANSI colors, dynamic padding, all borders present |
| 51 | Incompatible DE box | install.sh | Same issues as OS box | Full rewrite |
| 52 | GNOME Shell Not Found box | install.sh | Same issues as OS box | Full rewrite |
| 53 | NVIDIA title | bootstrap.sh | Hardcoded trailing spaces (content was 64 vs 62) | Dynamic `%*s` (now 62) |
| 54 | "More from Eprahemi" box | install.sh | Top/bottom mismatched at 69 chars | Unified at 69 with `%*s` |
| 55 | "Grabbing the Goods" / "Got Everything" / "Download Failed" | bootstrap.sh | Already had dynamic padding (grab1/grab2/grab3/ge1) | Verified correct; `dlf` box has ⛔ emoji — kept hardcoded (double-width caveat) |

**Dynamic padding formula**: `$(printf '%*s' $((62 - ${#var})) '')` where `var` is the full content string between the `║` borders. Box inner width = 62 chars. Line total = 66 chars.

**Emoji caveat**: Double-width emoji (⛔ 📦 ✅) report as 1 char in bash `${#var}` but render as 2 columns, causing visual 1-column misalignment. Only affects 3 lines in bootstrap.sh; acceptable imperfection.

**ASCII art banners** (Fedora ASCII art, "YOU DID IT!" victory art) use single-quoted fixed strings that already fill 62 cols — do not convert to dynamic padding.

### 🟤 CLASS F: PACKAGE SOURCE CHANGES / DOCUMENTATION

| # | Change | File | Details |
|---|--------|------|---------|
| 56 | Discord RPM → Flatpak | install.sh | `pkgs="discord $pkgs"` removed from RPM list; added `flatpak install -y flathub com.discordapp.Discord` in `install_flatpaks()` |
| 57 | Discord size text updated | both | From "~100 MB" → "~214 MB download, ~540 MB installed" (actual Flatpak sizes) |
| 58 | EPRAHEMI Public License added | repo root | `EPRAHEMI — PUBLIC LICENSE & REUSE TERMS.md` — copyright-free reuse, permissive terms |
| 59 | License auto-copies to Documents | install.sh (finalize) | Copies `EPRAHEMI — PUBLIC LICENSE & REUSE TERMS.md` from repo root to `~/Documents/` on every install |

---

## Current State

- **install.sh**: 2064 lines, 22 steps, 6 phases, all box lines use dynamic padding (except fixed ASCII art)
- **bootstrap.sh**: 339 lines, all box lines use dynamic padding (except ⛔/📦/✅ emoji lines and fixed ASCII art)
- **EPRAHEMI — PUBLIC LICENSE & REUSE TERMS.md** added at repo root; installed to `~/Documents/` during finalize step
- Both pass `bash -n` syntax check
- All bugs above are FIXED

## Key Files

| File | Purpose |
|------|---------|
| `install.sh` | Main installer — now includes qr-code-symbolic fix, Adwaita-style dirs, per-user fix for other users |
| `bootstrap.sh` | One-liner downloader — curl-pipe-bash entry point |
| `EPRAHEMI — PUBLIC LICENSE & REUSE TERMS.md` | Eprahemi's public license — copied to user's Documents on install |
| `ANCHORED_SESSION_SUMMARY.md` | This file — session log + bug registry |
| `icons/256x256/` | Custom macOS app icons (PNG + SVG) |
| `wallpapers/background-normal/` | 30 custom Mac-themed wallpapers |
| `wallpapers/desktop/` | Desktop wallpapers |
| `wallpapers/login/` | GDM login wallpaper |
| `assets/normal-faces/` | Custom profile pictures (7 JPEGs) |
| `configs/` | Kitty, Fish, Starship, GTK configs |
| `themes/MacTahoe-dark/actions/symbolic/qr-code-symbolic.svg` | QR code icon (source, `currentColor`) |
| `themes/MacTahoe-dark/actions/scalable/qr-code-symbolic.svg` | QR code icon (source, scalable fallback) |
| `themes/MacTahoe/actions/symbolic/qr-code-symbolic.svg` | QR code icon for light theme |
| `themes/MacTahoe/actions/scalable/qr-code-symbolic.svg` | QR code icon for light theme, scalable fallback |

## Crucial Lessons — Never Forget

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

## To Resume

Read this file, then read ANCHORED_SESSION_SUMMARY.md for the full bug registry. Never repeat a fix already in this registry.
