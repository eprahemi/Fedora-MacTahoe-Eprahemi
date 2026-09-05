#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  Fedora MacTahoe  —  Eprahemi Edition         uninstall.sh
#  Reverses everything install.sh did, guided by install-state.json.
#
#  Fedora-only + GNOME-only. Never run as root.
#
#  Usage:
#    bash uninstall.sh                 # recommended revert (asks first)
#    bash uninstall.sh --surgical      # remove only MacTahoe keys/files,
#                                      # keep your post-install tweaks
#    bash uninstall.sh --purge-packages# also remove RPMs/Flatpaks/repos
#    bash uninstall.sh --dry-run       # show what would happen, do nothing
#    bash uninstall.sh --yes           # answer "yes" to every prompt
#
#  What is restored:
#    • Theme / icons / fonts / sounds / desktop entries / kitty+starship
#    • dconf + fish from the OLDEST snapshot taken before MacTahoe ever
#      touched them (pre-install state), then MacTahoe-specific keys are
#      cleared on top so a rotated-out backup cannot leave leftovers
#    • Stock Fedora wallpapers (reinstalled), GDM logo tweaks, avatars
#    • Services: tracker, ABRT, packagekit, firewalld, updater timer,
#      ktheme watcher, dnf5-automatic
#    • 15 GNOME extensions (user copies), default terminal + shell
#    • Ptyxis + GNOME Weather (reinstalled — the installer removed them)
#
#  What stays by default (only --purge-packages removes it):
#    • RPM packages (kitty, fish, celluloid, libreoffice, ...)
#    • Flatpaks (Spotify, Discord, ...)
#    • RPM Fusion, NVIDIA driver, browser repos (Chrome/Edge/VS Code)
# ═══════════════════════════════════════════════════════════════════

# ── Never run as root ────────────────────────────────────────────
if [ "$(id -u)" -eq 0 ]; then
  echo "  ✗  Do not run uninstall.sh as root — run it as your normal user." >&2
  exit 1
fi

if [ ! -f /etc/fedora-release ]; then
  echo "  ✗  Fedora MacTahoe uninstaller targets Fedora only." >&2
  exit 1
fi

# ── Option parsing ───────────────────────────────────────────────
MODE="recommended"      # recommended | surgical
PURGE_PACKAGES=0
DRY_RUN=0
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --surgical)       MODE="surgical" ;;
    --purge-packages) PURGE_PACKAGES=1 ;;
    --dry-run)        DRY_RUN=1 ;;
    --yes)            ASSUME_YES=1 ;;
    --help|-h)
      sed -n '2,32p' "$0" 2>/dev/null || true
      exit 0
      ;;
    *)
      echo "  ✗  Unknown option: $arg (try --help)" >&2
      exit 1
      ;;
  esac
done

# ── Paths (zero hardcoded paths) ─────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE="$SCRIPT_DIR"
STATE_DIR="$HOME/.cache/fedora-mactahoe"
STATE_FILE="$STATE_DIR/install-state.json"
BACKUP_DIR="$STATE_DIR/backups"

# ── Colors (same palette as install.sh) ──────────────────────────
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; MAGENTA='\033[1;35m'; CYAN='\033[1;36m'
DIM='\033[2m'; BOLD='\033[1m'; NC='\033[0m'; WHITE='\033[1;37m'

log()   { echo -e "  ${CYAN}${DIM}┊${NC} ${CYAN}$(date +%H:%M:%S)${NC} ${DIM}┊${NC} $1"; }
ok()    { echo -e "  ${GREEN}  ┊ ✓ ${NC}  $1"; }
warn()  { echo -e "  ${YELLOW}  ┊ ⚠ ${NC}  $1"; }
fail()  { echo -e "  ${RED}  ┊ ✗ ${NC}  $1"; exit 1; }

# ── confirm() — same y/n loop as install.sh (60s → graceful exit) ─
confirm() {
  local prompt="$1" default="${2:-}"
  local reply="" _rc=0
  [ "$ASSUME_YES" = "1" ] && return 0
  [ "$DRY_RUN" = "1" ] && return 0
  while true; do
    echo -en "  ${DIM}${prompt}${NC} " >/dev/tty
    _rc=0
    read -t 60 -r reply </dev/tty || _rc=$?
    if [ "$_rc" -eq 142 ]; then
      echo ""
      echo -e "  ${YELLOW}◆${NC}  No answer in 60 seconds — closing. Run it again when you're ready!"
      exit 42
    fi
    case "${reply,,}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      '')    [ "$default" = "Y" ] && return 0 || return 1 ;;
      *)     warn "Type y/yes or n/no" ;;
    esac
  done
}

# ── run() — executes a command (or prints it in dry-run mode) ─────
run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf "  %s ${DIM}[dry-run]${NC}\n" "$*"
  else
    eval "$*"
  fi
}

# ── State helpers ────────────────────────────────────────────────
# Read fields from install-state.json. Usage:
#   state_get version        → prints the overall installed version
#   state_has_step <id>      → 0 if that step is recorded in state
#   state_prompt <id>        → prints the saved prompt choice (or "")
state_json_valid=0
if [ -f "$STATE_FILE" ] && command -v python3 &>/dev/null; then
  if python3 -c "import json; json.load(open('$STATE_FILE'))" 2>/dev/null; then
    state_json_valid=1
  fi
fi

state_get() {
  [ "$state_json_valid" = "1" ] || { echo ""; return; }
  python3 -c "
import sys, json
try:
    d = json.load(open('$STATE_FILE'))
except Exception:
    print(''); sys.exit(0)
key = sys.argv[1]
if key == 'version':
    print(d.get('version', ''))
elif key == 'install_date':
    print(d.get('install_date', ''))
elif key == 'source':
    print(d.get('source', ''))
" "$1" 2>/dev/null || true
}

state_has_step() {
  [ "$state_json_valid" = "1" ] || return 1
  python3 -c "
import sys, json
d = json.load(open('$STATE_FILE'))
sys.exit(0 if sys.argv[1] in d.get('steps', {}) else 1)
" "$1" 2>/dev/null
}

state_prompt() {
  [ "$state_json_valid" = "1" ] || { echo ""; return; }
  python3 -c "
import sys, json
try:
    d = json.load(open('$STATE_FILE'))
    p = d.get('prompts', {}).get(sys.argv[1], {})
    print(p.get('choice', ''))
except Exception:
    print('')
" "$1" 2>/dev/null || true
}

# ── Extension list (mirrors install.sh install_extensions) ───────
EXTENSIONS=(
  "blur-my-shell@aunetx"
  "user-theme@gnome-shell-extensions.gcampax.github.com"
  "logomenu@aryan_k"
  "AlphabeticalAppGrid@stuarthayhurst"
  "pinned-apps-in-appgrid@brunosilva.io"
  "app-hider@lynith.dev"
  "compiz-alike-magic-lamp-effect@hermes83.github.com"
  "compiz-windows-effect@hermes83.github.com"
  "CoverflowAltTab@palatis.blogspot.com"
  "clipboard-history@alexsaveau.dev"
  "ding@rastersoft.com"
  "Bluetooth-Battery-Meter@maniacx.github.com"
  "dash2dock-lite@icedman.github.com"
  "appindicatorsupport@rgcjonas.gmail.com"
  "window-title-pro@eprahemi.github.io"
)

# ── Package lists (only used with --purge-packages) ──────────────
RPM_PACKAGES="fish kitty fastfetch figlet lolcat eza \
  celluloid vlc kdenlive pavucontrol alacarte nautilus-python \
  gnome-tweaks gnome-characters adwaita-icon-theme \
  adwaita-icon-theme-legacy ImageMagick fzf ripgrep jq 7zip unzip \
  curl wget git bat cmatrix qrencode podman python3-pip \
  speedtest-cli xdg-utils libreoffice-writer libreoffice-calc \
  libreoffice-impress libheif-freeworld libheif-tools \
  intel-media-driver mesa-va-drivers gstreamer1-libav \
  gstreamer1-plugins-good gstreamer1-plugins-bad-free \
  gstreamer1-plugins-ugly mozilla-openh264 alsa-sof-firmware \
  ntfs-3g samba-client cifs-utils cups-filters hplip"

FLATPAK_APPS=(
  com.rtosta.zapzap
  io.github.amit9838.mousam
  com.mattjakeman.ExtensionManager
  com.github.tchx84.Flatseal
  it.mijorus.gearlever
  fr.handbrake.ghb
  info.febvre.Komikku
  md.obsidian.Obsidian
  com.protonvpn.www
  com.spotify.Client
  org.localsend.localsend_app
  com.discordapp.Discord
)

# ═════════════════════════════════════════════════════════════════
#  HEADER
# ═════════════════════════════════════════════════════════════════
echo ""
echo -e "  ${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "  ${RED}║${NC}                                                              ${RED}║${NC}"
u_title="  Fedora MacTahoe  —  Uninstaller"
echo -e "  ${RED}║${NC}  ${BOLD}${RED}${u_title}${NC}$(printf '%*s' $((60 - ${#u_title})) '')${RED}║${NC}"
u_sub="  Reverses install.sh using the recorded install state"
echo -e "  ${RED}║${NC}  ${DIM}${u_sub}${NC}$(printf '%*s' $((60 - ${#u_sub})) '')${RED}║${NC}"
echo -e "  ${RED}║${NC}                                                              ${RED}║${NC}"
if [ -f "$STATE_FILE" ]; then
  u_ver="  Installed version: $(state_get version)  (state: present)"
  echo -e "  ${RED}║${NC}  ${YELLOW}${u_ver}${NC}$(printf '%*s' $((60 - ${#u_ver})) '')${RED}║${NC}"
  u_date="  Installed on: $(state_get install_date)"
  echo -e "  ${RED}║${NC}  ${YELLOW}${u_date}${NC}$(printf '%*s' $((60 - ${#u_date})) '')${RED}║${NC}"
else
  u_miss="  No install-state.json found — scanning the system"
  echo -e "  ${RED}║${NC}  ${YELLOW}${u_miss}${NC}$(printf '%*s' $((60 - ${#u_miss})) '')${RED}║${NC}"
fi
echo -e "  ${RED}║${NC}                                                              ${RED}║${NC}"
echo -e "  ${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── Mode banner ──────────────────────────────────────────────────
if [ "$MODE" = "surgical" ]; then
  warn "SURGICAL mode: only MacTahoe-specific keys/files are removed."
  warn "Your post-install tweaks (themes you changed, fish config, dconf"
  warn "settings you customized) are left untouched."
elif [ "$DRY_RUN" = "1" ]; then
  log "DRY RUN: everything below is printed, nothing is executed."
fi
[ "$PURGE_PACKAGES" = "1" ] && warn "PURGE mode: installed packages will also be removed."
echo ""

# ═════════════════════════════════════════════════════════════════
#  PHASE 1 : SERVICES & TIMERS
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 1  :  Services & Timers${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"

# ── 1a. ktheme watcher (user service) ──
if state_has_step "install_ktheme_watcher" || [ -f "$HOME/.config/systemd/user/ktheme-watcher.service" ]; then
  log "Stopping ktheme-watcher (kitty auto-theme watcher)"
  run "systemctl --user disable --now ktheme-watcher.service 2>/dev/null || true"
  run "rm -f '$HOME/.config/systemd/user/ktheme-watcher.service' 2>/dev/null || true"
  run "systemctl --user daemon-reload 2>/dev/null || true"
  ok "ktheme watcher removed"
fi

# ── 1b. Update notifier (user service + timer + root rescue files) ──
if state_has_step "install_updater" || [ -f "$HOME/.config/systemd/user/fedora-mactahoe-updater.timer" ]; then
  log "Stopping Fedora MacTahoe update notifier"
  run "systemctl --user disable --now fedora-mactahoe-updater.timer fedora-mactahoe-updater.service 2>/dev/null || true"
  run "rm -f '$HOME/.config/systemd/user/fedora-mactahoe-updater.timer' '$HOME/.config/systemd/user/fedora-mactahoe-updater.service' 2>/dev/null || true"
  run "rm -f '$HOME/.local/bin/fedora-mactahoe-updater.sh' 2>/dev/null || true"
  # Root-owned rescue detector + did-you-mean handler (installed to /etc/fish)
  if [ -f /etc/fish/functions/update.fish ]; then
    run "sudo rm -f /etc/fish/functions/update.fish 2>/dev/null || true"
    ok "Rescue detector removed from /etc/fish/functions/"
  fi
  if [ -f /etc/fish/functions/__fish_default_command_not_found_handler.fish ]; then
    run "sudo rm -f /etc/fish/functions/__fish_default_command_not_found_handler.fish 2>/dev/null || true"
    ok "Did-you-mean handler removed from /etc/fish/functions/"
  fi
  run "systemctl --user daemon-reload 2>/dev/null || true"
  ok "Update notifier removed"
fi

# ── 1c. dnf5-automatic (installer enabled the timer + own config) ──
if state_has_step "install_updater"; then
  log "Disabling automatic security-update downloads"
  run "sudo systemctl disable --now dnf5-automatic.timer 2>/dev/null || true"
  # /etc/dnf/automatic.conf was overwritten by install.sh — restore the
  # packaged default by reinstalling the plugin (keeps the package).
  if [ -f /etc/dnf/automatic.conf ] && grep -q "apply_updates = no" /etc/dnf/automatic.conf 2>/dev/null; then
    if confirm "Restore the stock automatic.conf (dnf reinstall dnf5-plugin-automatic)? [Y/n]: " Y; then
      run "sudo dnf reinstall -y dnf5-plugin-automatic >/dev/null 2>&1 || true"
      ok "dnf5-plugin-automatic config restored to stock"
    fi
  fi
fi

# ── 1d. Optimize_system_resources reversal (tracker/ABRT/Software/PackageKit/firewalld) ──
if state_has_step "optimize_system_resources" || [ -f "$HOME/.config/autostart/org.gnome.Software.desktop" ]; then
  log "Restoring default service states (RAM optimizations reversed)"
  # Tracker file indexer (masked by optimize_system_resources)
  run "systemctl --user unmask tracker-miner-fs-3 tracker-miner-fs tracker-store 2>/dev/null || true"
  # Tracker3 miners (disabled by apply_dconf)
  run "systemctl --user enable --now tracker3-miner-fs tracker3-miner-fs-control tracker3-miner-apps tracker3-miner-extractor 2>/dev/null || true"
  # ABRT crash reporter
  run "sudo systemctl enable --now abrtd abrt-oops abrt-journal-core abrt-xorg 2>/dev/null || true"
  # GNOME Software auto-start (the disabled copy we installed)
  run "rm -f '$HOME/.config/autostart/org.gnome.Software.desktop' 2>/dev/null || true"
  # PackageKit (masked by optimize_system_resources)
  run "sudo systemctl unmask packagekit 2>/dev/null || true"
  run "sudo systemctl enable --now packagekit 2>/dev/null || true"
  # Firewalld — re-enable if the saved answer said "disable"
  if [ "$(state_prompt firewalld)" = "true" ]; then
    run "sudo systemctl enable --now firewalld 2>/dev/null || true"
    ok "Firewalld re-enabled"
  fi
  ok "System services restored to defaults"
fi

# ═════════════════════════════════════════════════════════════════
#  PHASE 2 : FISH SHELL (guard, rescue, config restore)
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 2  :  Fish Shell${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"

# ── 2a. Strip the MacTahoe guard + handler block from /etc/fish/config.fish ──
if [ -f /etc/fish/config.fish ] && grep -q "fedora-mactahoe-guard" /etc/fish/config.fish 2>/dev/null; then
  log "Removing MacTahoe guard + handler from /etc/fish/config.fish"
  # Backup the system file first, then delete between the marker comments.
  run "sudo cp /etc/fish/config.fish /etc/fish/config.fish.mactahoe-bak 2>/dev/null || true"
  run "sudo sed -i '/# ── Fedora MacTahoe guard (eprahemi) ──/,/# ── end of fedora-mactahoe-guard ──/d' /etc/fish/config.fish 2>/dev/null || true"
  ok "Guard removed from system fish config"
fi

# ── 2b. Restore the pre-MacTahoe fish config (recommended mode only) ──
if [ "$MODE" = "surgical" ]; then
  log "Surgical mode: ~/.config/fish left untouched"
else
  local_fish_backup=""
  if [ -d "$BACKUP_DIR" ]; then
    # Oldest snapshot = the one taken just before MacTahoe first touched fish.
    local_fish_backup=$(ls -1t "$BACKUP_DIR"/fish-*.tar.gz 2>/dev/null | tail -1 || true)
  fi
  if [ -n "$local_fish_backup" ] && [ -f "$local_fish_backup" ]; then
    if confirm "Restore the pre-install fish config from $local_fish_backup? [Y/n]: " Y; then
      log "Restoring fish config from $(basename "$local_fish_backup")"
      run "mkdir -p '$HOME/.config/fish'"
      run "tar xzf '$local_fish_backup' -C '$HOME/.config' 2>/dev/null || true"
      # Remove any MacTahoe-provided function files that may still linger
      # (covers rotated-out backups that already contain MacTahoe functions).
      if [ -d "$BUNDLE/configs/fish/functions" ] && [ -d "$HOME/.config/fish/functions" ]; then
        for _mf in "$BUNDLE/configs/fish/functions/"*.fish; do
          [ -f "$_mf" ] || continue
          run "rm -f '$HOME/.config/fish/functions/$(basename "$_mf")' 2>/dev/null || true"
        done
      fi
      # Kill the PATH-preservation file install.sh created (the restored
      # config.fish already carries the original PATH lines).
      run "rm -f '$HOME/.config/fish/conf.d/50-user-path.fish' 2>/dev/null || true"
      ok "Fish config restored to pre-install state"
    else
      warn "Keeping current fish config"
    fi
  else
    warn "No fish backup found — removing MacTahoe-provided functions only"
    if [ -d "$BUNDLE/configs/fish/functions" ] && [ -d "$HOME/.config/fish/functions" ]; then
      for _mf in "$BUNDLE/configs/fish/functions/"*.fish; do
        [ -f "$_mf" ] || continue
        run "rm -f '$HOME/.config/fish/functions/$(basename "$_mf")' 2>/dev/null || true"
      done
      ok "Removed $(find "$BUNDLE/configs/fish/functions" -name '*.fish' 2>/dev/null | wc -l) MacTahoe fish function(s)"
    fi
  fi
fi

# ═════════════════════════════════════════════════════════════════
#  PHASE 3 : DCONF / GSETTINGS
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 3  :  GNOME Settings (dconf/gsettings)${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"

# ── 3a. Full dconf rollback (recommended mode) ──
if [ "$MODE" = "surgical" ]; then
  log "Surgical mode: full dconf restore skipped"
else
  old_dconf=""
  if [ -d "$BACKUP_DIR" ]; then
    old_dconf=$(ls -1t "$BACKUP_DIR"/dconf-*.conf 2>/dev/null | tail -1 || true)
  fi
  if [ -n "$old_dconf" ] && [ -f "$old_dconf" ]; then
    if confirm "Restore the pre-install GNOME settings from $(basename "$old_dconf")? [Y/n]: " Y; then
      log "Restoring GNOME settings from $(basename "$old_dconf")"
      run "dconf load / < '$old_dconf' 2>/dev/null || true"
      ok "GNOME settings restored to pre-install state"
    else
      warn "Keeping current GNOME settings"
    fi
  else
    warn "No dconf backup found — clearing MacTahoe keys surgically below"
  fi
fi

# ── 3b. Surgical MacTahoe-key cleanup — always runs as a safety net ──
# Safe even on a freshly-restored dconf (belt-and-suspenders).
log "Clearing MacTahoe-specific GNOME settings"

# Themes → Adwaita (Fedora default)
run "gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true"
run "gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null || true"
run "gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita' 2>/dev/null || true"
run "gsettings set org.gnome.desktop.wm.preferences theme 'Adwaita' 2>/dev/null || true"
run "dconf write /org/gnome/shell/extensions/user-theme/name \"''\" 2>/dev/null || true"

# Fonts → stock Fedora (Cantarell)
run "gsettings set org.gnome.desktop.interface font-name 'Cantarell 11' 2>/dev/null || true"
run "gsettings set org.gnome.desktop.interface document-font-name 'Cantarell 12' 2>/dev/null || true"
run "gsettings set org.gnome.desktop.interface monospace-font-name 'Monospace 11' 2>/dev/null || true"

# Window buttons / double-click → GNOME defaults
run "gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:close' 2>/dev/null || true"
run "gsettings reset org.gnome.desktop.wm.preferences action-double-click-titlebar 2>/dev/null || true"

# Custom keybindings (custom0..custom9) → clear the whole set
log "Removing custom keybindings (Super+T/E/N/W/F/Z, Ctrl+Alt+V, ...)"
for c in 0 1 2 3 4 5 6 7 8 9; do
  cpath="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${c}/"
  run "gsettings reset-recursively '$cpath' 2>/dev/null || true"
done
run "gsettings reset org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || true"
run "gsettings reset org.gnome.shell.keybindings focus-active-notification 2>/dev/null || true"

# Default terminal (was forced to kitty)
run "gsettings reset org.gnome.desktop.default-applications.terminal exec 2>/dev/null || true"
run "gsettings reset org.gnome.desktop.default-applications.terminal exec-arg 2>/dev/null || true"

# Sound theme (was forced to "bigsur")
run "gsettings reset org.gnome.desktop.sound theme-name 2>/dev/null || true"
run "gsettings set org.gnome.desktop.sound event-sounds true 2>/dev/null || true"

# Extensions on/off lists → strip MacTahoe UUIDs, keep the user's own
# enabled list (works on a restored dconf AND on a live one).
_ext_enabled=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null || true)
if [ -n "$_ext_enabled" ] && [ "$_ext_enabled" != "@as []" ]; then
  _ext_new=$(python3 -c "
import ast, sys
try:
    lst = ast.literal_eval(sys.argv[1])
    drop = set(sys.argv[2:])
    kept = [x for x in lst if x not in drop]
except Exception:
    kept = []
print(\"['\" + \"', '\".join(kept) + \"']\" if kept else '@as []')
" "$_ext_enabled" "${EXTENSIONS[@]}" 2>/dev/null || echo "@as []")
  run "gsettings set org.gnome.shell enabled-extensions '$_ext_new' 2>/dev/null || true"
fi
unset _ext_enabled _ext_new 2>/dev/null || true
run "gsettings reset org.gnome.shell disabled-extensions 2>/dev/null || true"

# GTK bookmarks sidebar order (Downloads/Pictures/.../Trash was prepended)
if [ -f "$HOME/.config/gtk-3.0/bookmarks" ]; then
  log "Restoring GTK sidebar bookmarks (removing MacTahoe XDG order)"
  if [ "$DRY_RUN" != "1" ]; then
    tmp_bookmarks=$(mktemp)
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        file://"$HOME"/Downloads*|file://"$HOME"/Pictures*|file://"$HOME"/Videos*|file://"$HOME"/Music*|file://"$HOME"/Documents*|file://"$HOME"/.local/share/Trash*)
          continue
          ;;
        *)
          [ -n "$line" ] && printf '%s\n' "$line" >> "$tmp_bookmarks"
          ;;
      esac
    done < "$HOME/.config/gtk-3.0/bookmarks"
    mv "$tmp_bookmarks" "$HOME/.config/gtk-3.0/bookmarks"
    ok "Bookmarks restored (custom entries preserved)"
  fi
fi

ok "GNOME settings cleared"

# ═════════════════════════════════════════════════════════════════
#  PHASE 4 : GNOME EXTENSIONS
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 4  :  GNOME Extensions (15)${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"

if [ "$(command -v gnome-extensions)" != "" ]; then
  for uuid in "${EXTENSIONS[@]}"; do
    if [ -d "$HOME/.local/share/gnome-shell/extensions/$uuid" ]; then
      run "gnome-extensions uninstall '$uuid' 2>/dev/null || rm -rf '$HOME/.local/share/gnome-shell/extensions/$uuid' 2>/dev/null || true"
      ok "Uninstalled $uuid"
    fi
  done
else
  warn "gnome-extensions CLI not found — removing extension directories manually"
  for uuid in "${EXTENSIONS[@]}"; do
    run "rm -rf '$HOME/.local/share/gnome-shell/extensions/$uuid' 2>/dev/null || true"
  done
fi

# ═════════════════════════════════════════════════════════════════
#  PHASE 5 : THEMES, ICONS, FONTS, SOUNDS
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 5  :  Themes, Icons, Fonts, Sounds${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"

# ── 5a. MacTahoe GTK themes (user + system) ──
log "Removing MacTahoe GTK themes"
run "rm -rf '$HOME/.themes'/MacTahoe* 2>/dev/null || true"
run "rm -rf '$HOME/.local/share/themes'/MacTahoe* 2>/dev/null || true"
run "sudo rm -rf /usr/share/themes/MacTahoe* 2>/dev/null || true"
ok "MacTahoe themes removed"

# ── 5b. MacTahoe icon themes + custom app icons ──
log "Removing MacTahoe icon themes"
run "rm -rf '$HOME/.local/share/icons'/MacTahoe* 2>/dev/null || true"
ok "Icon themes removed"

log "Removing custom macOS app icons"
if [ -d "$BUNDLE/icons/256x256" ]; then
  for f in "$BUNDLE/icons/256x256/"*.svg "$BUNDLE/icons/256x256/"*.png; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    for t in "$HOME/.local/share/icons/hicolor/256x256/apps" \
             "$HOME/.local/share/icons/hicolor/scalable/apps" \
             "$HOME/.local/share/icons/MacTahoe-dark/apps/scalable" \
             "$HOME/.local/share/icons/MacTahoe/apps/scalable"; do
      run "rm -f '$t/$base' 2>/dev/null || true"
    done
    run "sudo rm -f /usr/share/icons/hicolor/256x256/apps/$base 2>/dev/null || true"
    # Flatpak reverse-DNS aliases were copied alongside the base file
    case "$base" in
      discord.png)           alias_name="com.discordapp.Discord" ;;
      spotify.png)           alias_name="com.spotify.Client" ;;
      vlc.png)               alias_name="org.videolan.VLC" ;;
      code.png)              alias_name="com.visualstudio.code" ;;
      localsend.png)         alias_name="org.localsend.localsend_app" ;;
      opencode.png)          alias_name="ai.opencode.desktop" ;;
      *)                     alias_name="" ;;
    esac
    if [ -n "$alias_name" ]; then
      ext="${base##*.}"
      alias_file="${alias_name}.${ext}"
      for t in "$HOME/.local/share/icons/hicolor/256x256/apps" \
               "$HOME/.local/share/icons/hicolor/scalable/apps"; do
        run "rm -f '$t/$alias_file' 2>/dev/null || true"
      done
      run "sudo rm -f /usr/share/icons/hicolor/256x256/apps/$alias_file 2>/dev/null || true"
    fi
  done
fi
run "gtk-update-icon-cache '$HOME/.local/share/icons/hicolor/' 2>/dev/null || true"
run "sudo gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true"
ok "Custom app icons removed"

# ── 5c. SF Pro font ──
log "Removing SF Pro Display font"
run "rm -f '$HOME/.local/share/fonts/SF-Pro-Display-Regular.otf' 2>/dev/null || true"
run "find '$HOME/.local/share/fonts' -maxdepth 1 -iname '*sf-pro*' -delete 2>/dev/null || true"
run "fc-cache -f '$HOME/.local/share/fonts' >/dev/null 2>&1 || true"
ok "SF Pro font removed"

# ── 5d. macOS sounds ──
log "Removing macOS Big Sur sounds"
run "rm -rf '$HOME/.local/share/sounds/bigsur' 2>/dev/null || true"
ok "Sounds removed"

# ═════════════════════════════════════════════════════════════════
#  PHASE 6 : DESKTOP ENTRIES + CONFIG FILES
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 6  :  Desktop Entries + Config Files${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"

# ── 6a. Desktop entries shipped by the bundle ──
log "Removing MacTahoe desktop entries"
if [ -d "$BUNDLE/desktop" ]; then
  for f in "$BUNDLE/desktop/"*.desktop; do
    [ -f "$f" ] || continue
    run "rm -f '$HOME/.local/share/applications/$(basename "$f")' 2>/dev/null || true"
  done
fi
# kitty.desktop (copied separately by setup_terminal)
run "rm -f '$HOME/.local/share/applications/kitty.desktop' 2>/dev/null || true"
ok "Desktop entries removed"

# ── 6b. Kitty config (keep user.conf — user-owned overrides file) ──
log "Removing MacTahoe kitty configuration"
run "rm -f '$HOME/.config/kitty/kitty.conf' '$HOME/.config/kitty/auto-theme.conf' 2>/dev/null || true"
ok "Kitty config removed (user.conf kept)"

# ── 6c. Starship ──
run "rm -f '$HOME/.config/starship.toml' 2>/dev/null || true"
ok "Starship config removed"

# ── 6d. GTK settings.ini (only in recommended mode — files were overwritten) ──
if [ "$MODE" = "surgical" ]; then
  warn "Surgical: gtk-3.0/4.0 settings.ini kept as-is"
else
  run "rm -f '$HOME/.config/gtk-3.0/settings.ini' 2>/dev/null || true"
  run "rm -f '$HOME/.config/gtk-4.0/settings.ini' 2>/dev/null || true"
  ok "GTK settings.ini removed (GNOME regenerates defaults)"
fi

# ── 6e. Fastfetch ──
if [ "$MODE" = "surgical" ]; then
  warn "Surgical: fastfetch config kept"
else
  run "rm -rf '$HOME/.config/fastfetch' 2>/dev/null || true"
  ok "Fastfetch config removed"
fi

# ── 6f. systemd logind overrides ──
if [ -f /etc/systemd/logind.conf.d/logind-overrides.conf ]; then
  run "sudo rm -f /etc/systemd/logind.conf.d/logind-overrides.conf 2>/dev/null || true"
  ok "logind overrides removed"
fi

# ═════════════════════════════════════════════════════════════════
#  PHASE 7 : WALLPAPERS + AVATARS + GDM + FIREFOX + FLATPAK THEME
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 7  :  Wallpapers, Avatars, Login Screen${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"

# ── 7a. Wallvault wallpaper packs + XML registrations ──
log "Removing Wallvault wallpaper packs"
run "sudo rm -rf '/usr/share/backgrounds/Wallvault Wallpapers' 2>/dev/null || true"
run "sudo rm -rf '/usr/share/backgrounds/Wallvault Wallpapers +18' 2>/dev/null || true"
run "sudo rm -f /usr/share/gnome-background-properties/wallvault-wallpapers.xml 2>/dev/null || true"
run "sudo rm -f /usr/share/gnome-background-properties/wallvault-wallpapers-18.xml 2>/dev/null || true"
run "rm -f '$HOME/.local/share/backgrounds/Himeno Fedora.jpg' 2>/dev/null || true"
run "rm -f '$HOME/.local/share/backgrounds/Himeno Fedora LoginScreen.jpg' 2>/dev/null || true"
ok "Wallvault wallpapers removed"

# Stock backgrounds were wiped by install.sh (rm -rf /usr/share/backgrounds/*).
# The files belong to desktop-backgrounds packages — reinstalling brings them back.
if rpm -q desktop-backgrounds-basic &>/dev/null || rpm -q fedora-workstation-backgrounds &>/dev/null; then
  if confirm "Reinstall the stock Fedora wallpapers (removed by install.sh)? [Y/n]: " Y; then
    run "sudo dnf reinstall -y desktop-backgrounds-basic desktop-backgrounds-compat fedora-workstation-backgrounds >/dev/null 2>&1 || true"
    ok "Stock Fedora wallpapers restored"
  fi
fi

# ── 7b. Custom avatars (normal + 18+ go to the same dir) ──
log "Removing custom profile pictures"
run "sudo rm -f /usr/share/pixmaps/faces/* 2>/dev/null || true"
run "sudo rm -rf /usr/share/pixmaps/face* 2>/dev/null || true"
ok "Custom avatars removed"

# ── 7c. GDM: logo tweak + themed shell ──
log "Restoring GDM login screen"
if [ -f /etc/dconf/db/gdm.d/01-logo ]; then
  run "sudo rm -f /etc/dconf/db/gdm.d/01-logo 2>/dev/null || true"
  run "sudo dconf update 2>/dev/null || true"
  ok "GDM logo tweak removed"
fi
# MacTahoe tweaks.sh -g also themes the GDM shell. The only reliable way to
# restore the stock GDM resource is to reinstall gnome-shell.
if confirm "Reinstall gnome-shell to restore the stock GDM theme? [Y/n]: " Y; then
  run "sudo dnf reinstall -y gnome-shell >/dev/null 2>&1 || true"
  ok "Stock GDM theme restored"
fi

# ── 7d. Firefox userChrome (macOS theme from tweaks.sh -f) ──
log "Removing Firefox macOS theme"
for _profile in "$HOME/.mozilla/firefox/"*/; do
  [ -d "${_profile}chrome" ] || continue
  if [ -f "${_profile}chrome/userChrome.css" ]; then
    run "rm -f '${_profile}chrome/userChrome.css' 2>/dev/null || true"
    run "rm -f '${_profile}chrome/userContent.css' 2>/dev/null || true"
    # Drop the legacy customization pref if tweaks.sh set it to true
    if [ -f "${_profile}prefs.js" ] && grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "${_profile}prefs.js" 2>/dev/null; then
      run "sed -i '/toolkit.legacyUserProfileCustomizations.stylesheets/d' '${_profile}prefs.js' 2>/dev/null || true"
    fi
    ok "Firefox theme removed from $(basename "$_profile")"
  fi
done

# ── 7e. Flatpak GTK runtime (org.gtk.Gtk3theme.MacTahoe-Dark) ──
log "Removing Flatpak GTK theme runtime"
run "sudo flatpak uninstall -y --system org.gtk.Gtk3theme.MacTahoe-Dark 2>/dev/null || true"
run "rm -rf '$HOME/.cache/pakitheme' 2>/dev/null || true"
ok "Flatpak theme runtime removed"

# ═════════════════════════════════════════════════════════════════
#  PHASE 8 : TERMINAL + SHELL DEFAULTS
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 8  :  Terminal + Shell Defaults${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"

# ── 8a. Undo kitty symlinks (`sudo ln -sf /usr/bin/kitty /usr/bin/gnome-terminal`) ──
if [ -L /usr/bin/gnome-terminal ] || [ -L /usr/bin/x-terminal-emulator ]; then
  run "sudo rm -f /usr/bin/gnome-terminal /usr/bin/x-terminal-emulator 2>/dev/null || true"
  ok "Terminal symlinks removed (kitty no longer masquerades)"
fi

# ── 8b. Restore ptyxis / gnome-weather (removed by the installer) ──
if state_has_step "remove_ptyxis" && ! rpm -q ptyxis &>/dev/null; then
  if confirm "Reinstall ptyxis (the terminal install.sh removed)? [Y/n]: " Y; then
    run "sudo dnf install -y ptyxis >/dev/null 2>&1 || true"
    ok "Ptyxis reinstalled"
  fi
fi
if state_has_step "remove_gnome_weather" && ! rpm -q gnome-weather &>/dev/null; then
  if confirm "Reinstall gnome-weather (removed by install.sh)? [Y/n]: " Y; then
    run "sudo dnf install -y gnome-weather >/dev/null 2>&1 || true"
    ok "GNOME Weather reinstalled"
  fi
fi

# ── 8c. Default shell (was changed to fish) ──
if [ "$SHELL" = "/usr/bin/fish" ] || grep -q "^$USER:.*fish" /etc/passwd 2>/dev/null; then
  if confirm "Restore /bin/bash as your default shell? [Y/n]: " Y; then
    run "sudo chsh -s /bin/bash '$USER' 2>/dev/null || true"
    ok "Default shell restored to bash (next login)"
  fi
fi

# ═════════════════════════════════════════════════════════════════
#  PHASE 9 : SUDOERS HINT (commented NOPASSWD line added on install)
# ═════════════════════════════════════════════════════════════════
if sudo grep -q "^# $USER ALL=(ALL) NOPASSWD: ALL$" /etc/sudoers 2>/dev/null; then
  if confirm "Remove the commented NOPASSWD hint from /etc/sudoers? [Y/n]: " Y; then
    _tmp_sudoers=$(mktemp)
    run "sudo cat /etc/sudoers > '$_tmp_sudoers'"
    run "sudo sed -i '/^# $USER ALL=(ALL) NOPASSWD: ALL$/d' '$_tmp_sudoers'"
    if [ "$DRY_RUN" != "1" ] && sudo visudo -c -f "$_tmp_sudoers" 2>/dev/null; then
      run "sudo cp '$_tmp_sudoers' /etc/sudoers"
      run "sudo chmod 440 /etc/sudoers"
      run "sudo chown root:root /etc/sudoers"
      ok "NOPASSWD hint removed from /etc/sudoers"
    elif [ "$DRY_RUN" = "1" ]; then
      ok "NOPASSWD hint removal (dry-run)"
    else
      warn "sudoers validation failed — hint left in place"
    fi
    run "rm -f '$_tmp_sudoers'"
  fi
fi

# ═════════════════════════════════════════════════════════════════
#  PHASE 10 : PACKAGE PURGE (only with --purge-packages)
# ═════════════════════════════════════════════════════════════════
if [ "$PURGE_PACKAGES" = "1" ]; then
  echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}PHASE 10 :  Package Purge (--purge-packages)${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
  warn "You asked for the packages install.sh added to be removed."
  warn "This will also remove config you may have created in these apps."
  if confirm "Remove all MacTahoe-installed RPM packages? [y/N]: " N; then
    run "sudo dnf remove -y $RPM_PACKAGES >/dev/null 2>&1 || true"
    ok "RPM packages removed"
  fi
  if confirm "Remove all MacTahoe-installed Flatpaks? [y/N]: " N; then
    for fp in "${FLATPAK_APPS[@]}"; do
      run "flatpak uninstall -y '$fp' 2>/dev/null || true"
    done
    run "flatpak uninstall --unused -y 2>/dev/null || true"
    ok "Flatpaks removed"
  fi
  if confirm "Remove Chrome + Edge + VS Code and their repos? [y/N]: " N; then
    run "sudo dnf remove -y google-chrome-stable microsoft-edge-stable code >/dev/null 2>&1 || true"
    run "sudo rm -f /etc/yum.repos.d/google-chrome.repo /etc/yum.repos.d/microsoft-edge.repo /etc/yum.repos.d/vscode.repo 2>/dev/null || true"
    ok "Browsers + VS Code removed"
  fi
  if confirm "Disable RPM Fusion (keep installed packages)? [y/N]: " N; then
    run "sudo dnf config-manager --set-disabled rpmfusion-free rpmfusion-nonfree 2>/dev/null || true"
    ok "RPM Fusion disabled"
  fi
  if confirm "Remove dnf5-plugin-automatic? [y/N]: " N; then
    run "sudo dnf remove -y dnf5-plugin-automatic >/dev/null 2>&1 || true"
    ok "dnf5-plugin-automatic removed"
  fi
fi

# ═════════════════════════════════════════════════════════════════
#  PHASE 11 : STATE + MISCELLANEOUS
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 11 :  State + Cleanup${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"

# ── Remove the installer's cache (state, backups, logs-adjacent) ──
if [ -d "$STATE_DIR" ]; then
  if confirm "Delete the installer cache ($STATE_DIR)? [Y/n]: " Y; then
    run "rm -rf '$STATE_DIR' 2>/dev/null || true"
    ok "Installer cache removed"
  else
    warn "Keeping $STATE_DIR"
  fi
fi

# ── License copy dropped in ~/Documents by finalize ──
if [ -f "$HOME/Documents/EPRAHEMI — PUBLIC LICENSE & REUSE TERMS.md" ]; then
  run "rm -f '$HOME/Documents/EPRAHEMI — PUBLIC LICENSE & REUSE TERMS.md' 2>/dev/null || true"
  ok "License copy removed from Documents"
fi

# ── Installer temp leftovers ──
run "rm -rf /tmp/mactahoe-* /tmp/mac-sounds /tmp/ext-* 2>/dev/null || true"
run "rm -f /tmp/window-title-pro.zip 2>/dev/null || true"

# ═════════════════════════════════════════════════════════════════
#  SUMMARY
# ═════════════════════════════════════════════════════════════════
echo ""
echo -e "  ${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "  ${GREEN}║${NC}                                                              ${GREEN}║${NC}"
s1="  ✅  Fedora MacTahoe uninstall complete"
echo -e "  ${GREEN}║${NC}  ${BOLD}${WHITE}${s1}${NC}$(printf '%*s' $((60 - ${#s1})) '')${GREEN}║${NC}"
echo -e "  ${GREEN}║${NC}                                                              ${GREEN}║${NC}"
s2="  ◆  Themes, icons, fonts, sounds — removed"
echo -e "  ${GREEN}║${NC}  ${YELLOW}${s2}${NC}$(printf '%*s' $((60 - ${#s2})) '')${GREEN}║${NC}"
[ "$MODE" = "surgical" ] && s3="  ◆  Surgical — your fish/dconf tweaks kept" || s3="  ◆  dconf + fish restored to pre-install state"
echo -e "  ${GREEN}║${NC}  ${YELLOW}${s3}${NC}$(printf '%*s' $((60 - ${#s3})) '')${GREEN}║${NC}"
s4="  ◆  15 GNOME extensions uninstalled"
echo -e "  ${GREEN}║${NC}  ${YELLOW}${s4}${NC}$(printf '%*s' $((60 - ${#s4})) '')${GREEN}║${NC}"
s5="  ◆  Services, terminal, shell, GDM restored"
echo -e  "  ${GREEN}║${NC}  ${YELLOW}${s5}${NC}$(printf '%*s' $((60 - ${#s5})) '')${GREEN}║${NC}"
if [ "$PURGE_PACKAGES" = "1" ]; then
  s6="  ◆  Installed packages removed (purge mode)"
  echo -e "  ${GREEN}║${NC}  ${YELLOW}${s6}${NC}$(printf '%*s' $((60 - ${#s6})) '')${GREEN}║${NC}"
else
  s6="  ◆  Packages kept — rerun with --purge-packages to remove"
  echo -e "  ${GREEN}║${NC}  ${YELLOW}${s6}${NC}$(printf '%*s' $((60 - ${#s6})) '')${GREEN}║${NC}"
fi
echo -e "  ${GREEN}║${NC}                                                              ${GREEN}║${NC}"
s7="  ⚠  Restart your session for everything to settle"
echo -e "  ${GREEN}║${NC}  ${BOLD}${RED}${s7}${NC}$(printf '%*s' $((60 - ${#s7})) '')${GREEN}║${NC}"
echo -e "  ${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
if [ "$DRY_RUN" = "1" ]; then
  log "DRY RUN finished — nothing was changed on your system."
else
  log "Log out and back in (or reboot) to complete the cleanup."
fi
echo ""