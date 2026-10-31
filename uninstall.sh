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
#    bash uninstall.sh --yes           # skip routine prompts (removal word still required)
#
#  What is restored:
#    • Theme / icons / fonts / sounds / desktop entries / kitty+starship
#    • dconf + fish from the OLDEST snapshot taken before MacTahoe ever
#      touched them (pre-install state), then MacTahoe-specific keys are
#      cleared on top so a rotated-out backup cannot leave leftovers
#    • Stock Fedora wallpapers (reinstalled), GDM logo tweaks, avatars
#    • Services: ABRT, packagekit, firewalld, updater timer,
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

# ── Private transcript + shared presentation library ─────────────
# The removal process owns its transcript even when an updater is waiting for
# this child. Inherited log paths, traps and painter state never authorize
# consent or logging.
exec 5>&1 6>&2
unset _FED_LOG _FED_TEE_PID _UI_ACTIVE _UI_PID _UI_OWNER _UI_MODE _UI_FINISHED
_FED_LOG=''
for _fed_log_try in 1 2 3 4 5; do
  _fed_log_id=$(tr -dc 'a-zA-Z0-9' < /dev/urandom 2>/dev/null | head -c 8)
  [ -n "$_fed_log_id" ] || _fed_log_id="X$(date +%s 2>/dev/null | sha256sum 2>/dev/null | head -c7 || echo 00000001)"
  _fed_log_path="$HOME/FedoraTahoe_log.$(date '+%Y-%m-%d.%H-%M-%S' 2>/dev/null || echo unknown).${_fed_log_id} ( UNINSTALL ).txt"
  # noclobber creates a new private file without ever reusing an existing log.
  if (umask 077; set -C; : >"$_fed_log_path") 2>/dev/null; then
    _FED_LOG="$_fed_log_path"
    break
  fi
done
[ -n "$_FED_LOG" ] || {
  printf 'Cannot create a private removal log in %s\n' "$HOME" >&2
  exit 1
}
chmod 600 "$_FED_LOG" 2>/dev/null || {
  printf 'Cannot secure the private removal log.\n' >&2
  exit 1
}
export _FED_LOG

# Plain fallback used only when the local UI library is missing or its bytes do
# not match the manifest pin. No library is ever sourced unverified.
_ui_init() { exec >>"$_FED_LOG" 2>&1; }
_ui_cleanup() { :; }
_ui_finish() { :; }
_ui_phase() { :; }
_ui_task() { :; }
_ui_progress() { :; }
_ui_notice() { printf '%s\n' "$1" >&6; }
_ui_question() { printf '\n%s\n%s\n%s\n' "$1" "${2:-}" "${3:-}" >&6; }
_ui_native_run() { "$@"; }
_ui_auth() { command sudo -v; }
_ui_step() { :; }
_ui_resume() { :; }

_fed_ui_ready=0
if [ -f "$BUNDLE/bootstrap.sh" ] && [ -f "$BUNDLE/updates.json" ] && command -v python3 >/dev/null 2>&1; then
  _fed_lib_pin=$(python3 -I -c 'import json,sys
try: print(json.load(open(sys.argv[1])).get("bootstrap_sha256",""))
except Exception: print("")' "$BUNDLE/updates.json" 2>/dev/null || true)
  _fed_lib_hash=$(sha256sum "$BUNDLE/bootstrap.sh" 2>/dev/null | awk '{print $1}')
  if [ -n "$_fed_lib_pin" ] && [ "$_fed_lib_pin" = "$_fed_lib_hash" ]; then
    # shellcheck disable=SC1090
    if source "$BUNDLE/bootstrap.sh" --ui-library; then
      _fed_ui_ready=1
    fi
  fi
fi

# ── Removal phases (presentation only; every registered phase still runs) ──
_UI_STEP_IDS=(services fish gnome extensions themes entries wallpaper terminal sudoers packages state)
_UI_STEP_LABELS=(
  'Services and timers'
  'Fish shell and configuration'
  'GNOME settings'
  'GNOME extensions'
  'Themes, icons, fonts, sounds'
  'Desktop entries and config files'
  'Wallpapers, avatars, login screen'
  'Terminal and shell defaults'
  'Sudoers hint'
  'Package purge'
  'State and cleanup'
)
_UI_STEP_STATES=(pending pending pending pending pending pending pending pending pending pending pending)
_UI_STEP_REASONS=('' '' '' '' '' '' '' '' '' '' '')

_FED_PHASE_FAILED=0
_FED_FAILED_PHASES=0
_FED_PHASE_ID=''
_FED_CANCEL_MESSAGE=''
_FED_EXITING=0
_fed_console() {
  if [ "${_UI_ACTIVE:-0}" != 1 ] && [ -t 6 ]; then
    printf '%s\n' "$1" >&6
  fi
}
_fed_exit() {
  local rc=$?
  [ "${_FED_EXITING:-0}" = 1 ] && return 0
  _FED_EXITING=1
  trap - EXIT INT TERM HUP
  if [ "${_UI_FINISHED:-0}" != 1 ]; then
    if [ -n "${_FED_CANCEL_MESSAGE:-}" ]; then
      _UI_FINISH_TITLE='R E M O V A L   S T O P P E D'
      _UI_FINISH_TITLE_COMPACT='Removal stopped'
      _ui_finish "$_FED_CANCEL_MESSAGE"
    elif [ "$rc" -eq 0 ]; then
      _UI_FINISH_TITLE='R E M O V A L   C O M P L E T E'
      _UI_FINISH_TITLE_COMPACT='Removal complete'
      _ui_finish 'Removal finished.'
    else
      _UI_FINISH_TITLE='R E M O V A L   F I N I S H E D   W I T H   I S S U E S'
      _UI_FINISH_TITLE_COMPACT='Removal finished with issues'
      _ui_finish 'Removal stopped or finished with issues. See the private log.'
    fi
  fi
  _ui_cleanup
  exec 1>&5 2>&6 2>/dev/null || true
  if [ -n "${_FED_CANCEL_MESSAGE:-}" ]; then
    _fed_console "$_FED_CANCEL_MESSAGE"
  fi
  if [ -f "${_FED_LOG:-}" ]; then
    LC_ALL=C sed -i 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$_FED_LOG" 2>/dev/null || true
    chmod 600 "$_FED_LOG" 2>/dev/null || true
    if [ "${_UI_FINISHED:-0}" != 1 ]; then
      _fed_console "Log saved: $_FED_LOG"
    fi
  fi
  exit "$rc"
}
_fed_stop() {
  _FED_CANCEL_MESSAGE="${1:-Removal stopped. Completed work is kept.}"
  exit "${2:-42}"
}
trap _fed_exit EXIT
trap '_fed_stop "Removal interrupted. Completed work is kept." 130' INT
trap '_fed_stop "Removal interrupted. Completed work is kept." 143' TERM
trap '_fed_stop "Removal interrupted. Completed work is kept." 129' HUP
_ui_init
_fed_phase_begin() {
  _FED_PHASE_ID="$1"
  _FED_PHASE_FAILED=0
  _ui_phase "$2"
  _ui_task "$2"
  _ui_step "$1" running
  log "$2"
}
_fed_phase_end() {
  if [ "${_FED_PHASE_FAILED:-0}" -ne 0 ]; then
    _FED_FAILED_PHASES=$((_FED_FAILED_PHASES + 1))
    _ui_step "$_FED_PHASE_ID" failed
  else
    _ui_step "$_FED_PHASE_ID" ok
  fi
}
_fed_phase_skip() {
  _ui_step "$1" skipped "${2:-}"
}
_fed_critical() {
  # A critical operation must not report success after a suppressed failure.
  if run "$1"; then
    return 0
  fi
  _FED_PHASE_FAILED=1
  warn "$2"
  return 1
}
_fed_try() {
  if run "$1"; then
    return 0
  fi
  _FED_PHASE_FAILED=1
  warn "$2"
  return 1
}
_fed_trash() {
  # User collections are recoverable: exact path only, verified moved.
  local path="$1"
  [ -e "$path" ] || [ -L "$path" ] || return 0
  if [ "$DRY_RUN" = "1" ]; then
    printf "  gio trash -- %s ${DIM}[dry-run]${NC}\n" "$path"
    return 0
  fi
  if command -v gio >/dev/null 2>&1 && gio trash -- "$path" 2>/dev/null; then
    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
      return 0
    fi
  fi
  return 1
}
_fed_trash_collection() {
  local path="$1" label="$2"
  [ -e "$path" ] || [ -L "$path" ] || return 0
  if [ "$DRY_RUN" = "1" ]; then
    printf "  gio trash -- %s ${DIM}[dry-run]${NC}\n" "$path"
    return 0
  fi
  if _fed_trash "$path"; then
    ok "Moved $label to Trash"
  else
    _FED_PHASE_FAILED=1
    warn "$label could not be moved to Trash"
  fi
}
_fed_remove_file() {
  # _fed_remove_file <path> <label> [sudo] — argv-safe, no eval for file names.
  local path="$1" label="$2" use_sudo="${3:-}"
  if [ "$DRY_RUN" = "1" ]; then
    printf "  rm -f -- %s ${DIM}[dry-run]${NC}\n" "$path"
    return 0
  fi
  if [ "$use_sudo" = "sudo" ]; then
    if sudo rm -f -- "$path"; then return 0; fi
  else
    if rm -f -- "$path"; then return 0; fi
  fi
  _FED_PHASE_FAILED=1
  warn "$label"
  return 1
}
_fed_avatar_cleanup() {
  # Remove only files recorded by the project's own ownership manifest and only
  # while their digest still matches. Unknown/custom faces are never inferred.
  local dir="$1" marker="$1/.mactahoe-pack.json" names rc=0 name
  [ -f "$marker" ] && [ ! -L "$marker" ] || return 0
  names=$(mktemp) || { _FED_PHASE_FAILED=1; warn "Could not create an avatar cleanup list"; return 0; }
  python3 -I - "$dir" "$marker" >"$names" <<'PY' || rc=$?
import hashlib, json, os, sys
directory, marker = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(marker))
    if data.get('schema') != 1 or data.get('kind') != 'avatar' or not isinstance(data.get('files'), dict):
        raise ValueError
except Exception:
    sys.exit(2)
for name, digest in data['files'].items():
    if not isinstance(name, str) or not isinstance(digest, str) or os.path.basename(name) != name:
        continue
    path = os.path.join(directory, name)
    try:
        if os.path.islink(path) or not os.path.isfile(path):
            continue
        hasher = hashlib.sha256()
        with open(path, 'rb') as stream:
            for block in iter(lambda: stream.read(1 << 20), b''):
                hasher.update(block)
        if hasher.hexdigest() == digest:
            sys.stdout.buffer.write(os.fsencode(name) + b'\0')
    except OSError:
        continue
PY
  if [ "$rc" -ne 0 ]; then
    rm -f "$names" 2>/dev/null || true
    warn "Avatar ownership manifest is unreadable — the collection was preserved"
    _FED_PHASE_FAILED=1
    return 0
  fi
  while IFS= read -r -d '' name; do
    [ -n "$name" ] || continue
    _fed_remove_file "$dir/$name" "managed avatar $name could not be removed" sudo
  done < "$names"
  rm -f "$names" 2>/dev/null || true
  # Keep the manifest while any recorded entry survives (modified or not yet
  # removed); a later run can retry without guessing ownership.
  if python3 -I - "$marker" <<'PY'
import json, os, sys
marker = sys.argv[1]
try:
    data = json.load(open(marker))
    files = data.get('files', {})
except Exception:
    sys.exit(1)
if not isinstance(files, dict):
    sys.exit(1)
base = os.path.dirname(marker)
sys.exit(1 if any(os.path.lexists(os.path.join(base, name)) for name in files if isinstance(name, str)) else 0)
PY
  then
    _fed_critical "sudo rm -f '$marker'" "avatar ownership manifest could not be removed"
  fi
}

log()   { local _m="  ${CYAN}${DIM}┊${NC} ${CYAN}$(date +%H:%M:%S)${NC} ${DIM}┊${NC} $1"; echo -e "$_m"; _fed_console "$(printf '%s' "$_m" | sed $'s/\033\\[[0-9;]*[a-zA-Z]//g')"; }
ok()    { local _m="  ${GREEN}  ┊ ✓ ${NC}  $1"; echo -e "$_m"; _fed_console "$(printf '%s' "$_m" | sed $'s/\033\\[[0-9;]*[a-zA-Z]//g')"; }
warn()  { local _m="  ${YELLOW}  ┊ ⚠ ${NC}  $1"; echo -e "$_m"; _fed_console "$(printf '%s' "$_m" | sed $'s/\033\\[[0-9;]*[a-zA-Z]//g')"; }
fail()  { echo -e "  ${RED}  ┊ ✗ ${NC}  $1"; _fed_console "$1"; exit 1; }

# ── confirm() — same y/n loop as install.sh (60s → graceful exit) ─
# EOF or a missing TTY always cancels; a default answer is never applied when
# input is unavailable.
confirm() {
  local prompt="$1" default="${2:-}"
  local reply="" _rc=0
  [ "$ASSUME_YES" = "1" ] && return 0
  [ "$DRY_RUN" = "1" ] && return 0
  while true; do
    echo -en "  ${DIM}${prompt}${NC} " >/dev/tty
    _rc=0
    read -t 60 -r reply </dev/tty || _rc=$?
    case "$_rc" in
      0) ;;
      142)
        echo ""
        _fed_stop 'No answer in 60 seconds — removal stopped. Completed work is kept.' 42
        ;;
      *)
        echo ""
        _fed_stop 'Input closed — removal stopped. Completed work is kept.' 42
        ;;
    esac
    case "${reply,,}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      '')    [ "$default" = "Y" ] && return 0 || return 1 ;;
      *)     warn "Type y/yes or n/no" ;;
    esac
  done
}

# ── confirm_removal() — fresh destructive consent, never bypassed by --yes ──
confirm_removal() {
  [ "$DRY_RUN" = "1" ] && return 0
  local answer="" rc=0
  _ui_question 'REMOVE FEDORA MACTAHOE?' \
    'Themes, icons, fonts, sounds, extensions, GDM, wallpapers and services are reverted. Named project collections go to Trash; custom files, shared assets, app data and recovery snapshots are kept.' \
    'Type yes to proceed. Anything else cancels; nothing is changed.'
  if [ "${_UI_ACTIVE:-0}" != 1 ]; then printf '  Type yes to proceed: ' >&6; fi
  IFS= read -r answer </dev/tty || rc=$?
  if [ "$rc" -ne 0 ] || [ "$answer" != yes ]; then
    _FED_CANCEL_MESSAGE='Removal cancelled — nothing was changed.'
    exit 42
  fi
  _ui_task 'Starting guarded removal'
  return 0
}

# ── run() — executes a command (or prints it in dry-run mode) ─────
run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf "  %s ${DIM}[dry-run]${NC}\n" "$*"
    return 0
  fi
  eval "$*"
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

# Plain-mode header: the dashboard already carries the branding when active.
if [ "${_UI_ACTIVE:-0}" != 1 ] && [ -t 6 ]; then
  printf '\n  Fedora MacTahoe — Uninstaller\n' >&6
  if [ -f "$STATE_FILE" ]; then
    printf '  Installed version: %s\n' "$(state_get version)" >&6
  else
    printf '  No install-state.json found — scanning the system\n' >&6
  fi
  printf '\n' >&6
fi

# Fresh destructive consent before any mutation. --yes never bypasses it.
confirm_removal
if [ "$DRY_RUN" != 1 ]; then
  _ui_auth || fail 'Administrator permission is required to restore system services.'
fi

# ═════════════════════════════════════════════════════════════════
#  PHASE 1 : SERVICES & TIMERS
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 1  :  Services & Timers${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
_fed_phase_begin services 'Phase 1: Services and timers'

# ── 1a. ktheme watcher (user service) ──
if state_has_step "install_ktheme_watcher" || [ -f "$HOME/.config/systemd/user/ktheme-watcher.service" ]; then
  log "Stopping ktheme-watcher (kitty auto-theme watcher)"
  run "systemctl --user disable --now ktheme-watcher.service 2>/dev/null || true"
  _fed_critical "rm -f '$HOME/.config/systemd/user/ktheme-watcher.service'" "ktheme watcher service file could not be removed"
  run "systemctl --user daemon-reload 2>/dev/null || true"
  ok "ktheme watcher removed"
fi

# ── 1b. Update notifier (user service + timer + root rescue files) ──
if state_has_step "install_updater" || [ -f "$HOME/.config/systemd/user/fedora-mactahoe-updater.timer" ]; then
  log "Stopping Fedora MacTahoe update notifier"
  run "systemctl --user disable --now fedora-mactahoe-updater.timer fedora-mactahoe-updater.service 2>/dev/null || true"
  _fed_critical "rm -f '$HOME/.config/systemd/user/fedora-mactahoe-updater.timer' '$HOME/.config/systemd/user/fedora-mactahoe-updater.service'" "update notifier unit files could not be removed"
  _fed_critical "rm -f '$HOME/.local/bin/fedora-mactahoe-updater.sh'" "update notifier script could not be removed"
  # Root-owned rescue detector + did-you-mean handler (installed to /etc/fish)
  if [ -f /etc/fish/functions/update.fish ]; then
    _fed_critical "sudo rm -f /etc/fish/functions/update.fish" "rescue detector could not be removed from /etc/fish/functions/"
    ok "Rescue detector removed from /etc/fish/functions/"
  fi
  if [ -f /etc/fish/functions/__fish_default_command_not_found_handler.fish ]; then
    _fed_critical "sudo rm -f /etc/fish/functions/__fish_default_command_not_found_handler.fish" "did-you-mean handler could not be removed from /etc/fish/functions/"
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
      _fed_critical "sudo dnf reinstall -y dnf5-plugin-automatic" "dnf5-plugin-automatic could not be reinstalled; automatic.conf was not restored"
      ok "dnf5-plugin-automatic config restored to stock"
    fi
  fi
fi

# ── 1d. Optimize_system_resources reversal (ABRT/Software/PackageKit/firewalld) ──
if state_has_step "optimize_system_resources" || [ -f "$HOME/.config/autostart/org.gnome.Software.desktop" ]; then
  log "Restoring default service states (RAM optimizations reversed)"
  # Leave file indexing alone, including legacy masks/disables of unknown origin.
  # ABRT crash reporter
  _fed_try "sudo systemctl enable --now abrtd abrt-oops abrt-journal-core abrt-xorg" "ABRT services could not all be re-enabled"
  # GNOME Software auto-start (the disabled copy we installed)
  _fed_critical "rm -f '$HOME/.config/autostart/org.gnome.Software.desktop'" "GNOME Software autostart file could not be removed"
  # PackageKit (masked by optimize_system_resources)
  _fed_critical "sudo systemctl unmask packagekit" "PackageKit could not be unmasked"
  _fed_critical "sudo systemctl enable --now packagekit" "PackageKit could not be re-enabled"
  # Firewalld — re-enable if the saved answer said "disable"
  if [ "$(state_prompt firewalld)" = "true" ]; then
    _fed_try "sudo systemctl enable --now firewalld" "Firewalld could not be re-enabled"
    ok "Firewalld re-enabled"
  fi
  ok "System services restored to defaults"
fi
_fed_phase_end

# ═════════════════════════════════════════════════════════════════
#  PHASE 2 : FISH SHELL (guard, rescue, config restore)
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 2  :  Fish Shell${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
_fed_phase_begin fish 'Phase 2: Fish shell and configuration'

# ── 2a. Strip the MacTahoe guard + handler block from /etc/fish/config.fish ──
if [ -f /etc/fish/config.fish ] && grep -q "fedora-mactahoe-guard" /etc/fish/config.fish 2>/dev/null; then
  log "Removing MacTahoe guard + handler from /etc/fish/config.fish"
  # Backup the system file first, then delete between the marker comments.
  _fed_try "sudo cp /etc/fish/config.fish /etc/fish/config.fish.mactahoe-bak" "system fish config backup could not be written"
  _fed_critical "sudo sed -i '/# ── Fedora MacTahoe guard (eprahemi) ──/,/# ── end of fedora-mactahoe-guard ──/d' /etc/fish/config.fish" "MacTahoe guard could not be removed from the system fish config"
  ok "Guard removed from system fish config"
fi

# ── 2a2. Remove the project-owned conf.d snippet (new in 3.7.5) ──
# ~/.config/fish/config.fish is user-owned and is never touched here.
if [ -f "$HOME/.config/fish/conf.d/50-fedora-mactahoe.fish" ]; then
  log "Removing the Fedora MacTahoe fish settings snippet"
  _fed_critical "rm -f '$HOME/.config/fish/conf.d/50-fedora-mactahoe.fish'" "Fedora MacTahoe fish snippet could not be removed"
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
      _fed_critical "mkdir -p '$HOME/.config/fish'" "fish configuration directory could not be created"
      _fed_critical "tar xzf '$local_fish_backup' -C '$HOME/.config'" "fish configuration snapshot could not be restored"
      # Remove any MacTahoe-provided function files that may still linger
      # (covers rotated-out backups that already contain MacTahoe functions).
      if [ -d "$BUNDLE/configs/fish/functions" ] && [ -d "$HOME/.config/fish/functions" ]; then
        for _mf in "$BUNDLE/configs/fish/functions/"*.fish; do
          [ -f "$_mf" ] || continue
          _fed_critical "rm -f '$HOME/.config/fish/functions/$(basename "$_mf")'" "project fish function $(basename "$_mf") could not be removed"
        done
      fi
      # Kill the PATH-preservation file install.sh created (the restored
      # config.fish already carries the original PATH lines).
      _fed_critical "rm -f '$HOME/.config/fish/conf.d/50-user-path.fish'" "legacy PATH-preservation file could not be removed"
      ok "Fish config restored to pre-install state"
    else
      warn "Keeping current fish config"
    fi
  else
    warn "No fish backup found — removing MacTahoe-provided functions only"
    if [ -d "$BUNDLE/configs/fish/functions" ] && [ -d "$HOME/.config/fish/functions" ]; then
      for _mf in "$BUNDLE/configs/fish/functions/"*.fish; do
        [ -f "$_mf" ] || continue
        _fed_critical "rm -f '$HOME/.config/fish/functions/$(basename "$_mf")'" "project fish function $(basename "$_mf") could not be removed"
      done
      ok "Removed $(find "$BUNDLE/configs/fish/functions" -name '*.fish' 2>/dev/null | wc -l) MacTahoe fish function(s)"
    fi
  fi
fi
_fed_phase_end

# ═════════════════════════════════════════════════════════════════
#  PHASE 3 : DCONF / GSETTINGS
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 3  :  GNOME Settings (dconf/gsettings)${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
_fed_phase_begin gnome 'Phase 3: GNOME settings'

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
      _fed_critical "dconf load / < '$old_dconf'" "GNOME settings snapshot could not be restored"
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
_fed_try "gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'" "GTK theme could not be reset to Adwaita"
_fed_try "gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'" "icon theme could not be reset to Adwaita"
_fed_try "gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'" "cursor theme could not be reset to Adwaita"
_fed_try "gsettings set org.gnome.desktop.wm.preferences theme 'Adwaita'" "window theme could not be reset to Adwaita"
_fed_try "dconf write /org/gnome/shell/extensions/user-theme/name \"''\"" "user-theme extension name could not be cleared"

# Fonts → stock Fedora (Cantarell)
_fed_try "gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'" "interface font could not be reset"
_fed_try "gsettings set org.gnome.desktop.interface document-font-name 'Cantarell 12'" "document font could not be reset"
_fed_try "gsettings set org.gnome.desktop.interface monospace-font-name 'Monospace 11'" "monospace font could not be reset"

# Window buttons / double-click → GNOME defaults
_fed_try "gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:close'" "window button layout could not be reset"
_fed_try "gsettings reset org.gnome.desktop.wm.preferences action-double-click-titlebar" "titlebar action could not be reset"

# Custom keybindings (custom0..custom9) → clear the whole set
log "Removing custom keybindings (Super+T/E/N/W/F/Z, Ctrl+Alt+V, ...)"
for c in 0 1 2 3 4 5 6 7 8 9; do
  cpath="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${c}/"
  _fed_try "gsettings reset-recursively '$cpath'" "custom keybinding custom${c} could not be reset"
done
_fed_try "gsettings reset org.gnome.settings-daemon.plugins.media-keys custom-keybindings" "custom keybinding list could not be reset"
_fed_try "gsettings reset org.gnome.shell.keybindings focus-active-notification" "notification keybinding could not be reset"

# Default terminal (was forced to kitty)
_fed_try "gsettings reset org.gnome.desktop.default-applications.terminal exec" "default terminal could not be reset"
_fed_try "gsettings reset org.gnome.desktop.default-applications.terminal exec-arg" "default terminal arguments could not be reset"

# Sound theme (was forced to "bigsur")
_fed_try "gsettings reset org.gnome.desktop.sound theme-name" "sound theme could not be reset"
_fed_try "gsettings set org.gnome.desktop.sound event-sounds true" "event sounds could not be re-enabled"

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
  _fed_try "gsettings set org.gnome.shell enabled-extensions '$_ext_new'" "enabled-extension list could not be updated"
fi
unset _ext_enabled _ext_new 2>/dev/null || true
_fed_try "gsettings reset org.gnome.shell disabled-extensions" "disabled-extension list could not be reset"

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
    if ! mv "$tmp_bookmarks" "$HOME/.config/gtk-3.0/bookmarks"; then
      rm -f "$tmp_bookmarks" 2>/dev/null || true
      _FED_PHASE_FAILED=1
      warn "GTK sidebar bookmarks could not be rewritten"
    else
      ok "Bookmarks restored (custom entries preserved)"
    fi
  fi
fi

ok "GNOME settings cleared"
_fed_phase_end

# ═════════════════════════════════════════════════════════════════
#  PHASE 4 : GNOME EXTENSIONS
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 4  :  GNOME Extensions (15)${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
_fed_phase_begin extensions 'Phase 4: GNOME extensions'

if command -v gnome-extensions >/dev/null 2>&1; then
  for uuid in "${EXTENSIONS[@]}"; do
    _ext_dir="$HOME/.local/share/gnome-shell/extensions/$uuid"
    [ -d "$_ext_dir" ] || continue
    if run "gnome-extensions uninstall '$uuid'"; then
      ok "Uninstalled $uuid"
    elif [ ! -d "$_ext_dir" ]; then
      ok "Uninstalled $uuid"
    elif run "rm -rf '$_ext_dir'"; then
      ok "Removed $uuid"
    else
      _FED_PHASE_FAILED=1
      warn "Extension $uuid could not be removed"
    fi
  done
else
  warn "gnome-extensions CLI not found — removing extension directories manually"
  for uuid in "${EXTENSIONS[@]}"; do
    _ext_dir="$HOME/.local/share/gnome-shell/extensions/$uuid"
    [ -d "$_ext_dir" ] || continue
    _fed_critical "rm -rf '$_ext_dir'" "extension $uuid could not be removed"
  done
fi
_fed_phase_end

# ═════════════════════════════════════════════════════════════════
#  PHASE 5 : THEMES, ICONS, FONTS, SOUNDS
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 5  :  Themes, Icons, Fonts, Sounds${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
_fed_phase_begin themes 'Phase 5: Themes, icons, fonts, sounds'

# ── 5a. MacTahoe GTK themes (user + system) ──
log "Removing MacTahoe GTK themes"
for _theme in MacTahoe MacTahoe-dark MacTahoe-light MacTahoe-Eprahemi MacTahoe-dark-Eprahemi; do
  _fed_trash_collection "$HOME/.themes/$_theme" "user theme $_theme"
  _fed_trash_collection "$HOME/.local/share/themes/$_theme" "local theme $_theme"
  if [ -e "/usr/share/themes/$_theme" ] || [ -L "/usr/share/themes/$_theme" ]; then
    _fed_critical "sudo rm -rf '/usr/share/themes/$_theme'" "system theme $_theme could not be removed"
  fi
done
ok "MacTahoe themes removed"

# ── 5b. MacTahoe icon themes + custom app icons ──
log "Removing MacTahoe icon themes"
for _icons in MacTahoe MacTahoe-dark MacTahoe-light MacTahoe-Eprahemi MacTahoe-dark-Eprahemi; do
  _fed_trash_collection "$HOME/.local/share/icons/$_icons" "icon theme $_icons"
done
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
      [ -e "$t/$base" ] || continue
      _fed_critical "rm -f '$t/$base'" "custom icon $base could not be removed"
    done
    if [ -e "/usr/share/icons/hicolor/256x256/apps/$base" ]; then
      _fed_critical "sudo rm -f '/usr/share/icons/hicolor/256x256/apps/$base'" "system icon $base could not be removed"
    fi
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
        [ -e "$t/$alias_file" ] || continue
        _fed_critical "rm -f '$t/$alias_file'" "custom icon alias $alias_file could not be removed"
      done
      if [ -e "/usr/share/icons/hicolor/256x256/apps/$alias_file" ]; then
        _fed_critical "sudo rm -f '/usr/share/icons/hicolor/256x256/apps/$alias_file'" "system icon alias $alias_file could not be removed"
      fi
    fi
  done
fi
run "gtk-update-icon-cache '$HOME/.local/share/icons/hicolor/' 2>/dev/null || true"
run "sudo gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true"
ok "Custom app icons removed"

# ── 5c. SF Pro font ──
log "Removing SF Pro Display font"
if [ -e "$HOME/.local/share/fonts/SF-Pro-Display-Regular.otf" ]; then
  _fed_critical "rm -f '$HOME/.local/share/fonts/SF-Pro-Display-Regular.otf'" "SF Pro Display font file could not be removed"
fi
# Optional extra SF Pro files beyond the known filename; absent folder is fine.
if [ -d "$HOME/.local/share/fonts" ]; then
  _fed_try "find '$HOME/.local/share/fonts' -maxdepth 1 -iname '*sf-pro*' -delete" "some SF Pro font files could not be removed"
fi
run "fc-cache -f '$HOME/.local/share/fonts' 2>/dev/null || true"
ok "SF Pro font removed"

# ── 5d. macOS sounds ──
log "Removing macOS Big Sur sounds"
_fed_trash_collection "$HOME/.local/share/sounds/bigsur" "Big Sur sound theme"
ok "Sounds removed"
_fed_phase_end

# ═════════════════════════════════════════════════════════════════
#  PHASE 6 : DESKTOP ENTRIES + CONFIG FILES
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 6  :  Desktop Entries + Config Files${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
_fed_phase_begin entries 'Phase 6: Desktop entries and config files'

# ── 6a. Desktop entries shipped by the bundle ──
log "Removing MacTahoe desktop entries"
if [ -d "$BUNDLE/desktop" ]; then
  for f in "$BUNDLE/desktop/"*.desktop; do
    [ -f "$f" ] || continue
    _dest="$HOME/.local/share/applications/$(basename "$f")"
    [ -e "$_dest" ] || continue
    _fed_critical "rm -f '$_dest'" "desktop entry $(basename "$f") could not be removed"
  done
fi
# kitty.desktop (copied separately by setup_terminal)
if [ -e "$HOME/.local/share/applications/kitty.desktop" ]; then
  _fed_critical "rm -f '$HOME/.local/share/applications/kitty.desktop'" "kitty desktop entry could not be removed"
fi
ok "Desktop entries removed"

# ── 6b. Kitty config (keep user.conf — user-owned overrides file) ──
log "Removing MacTahoe kitty configuration"
for _kitty_cfg in "$HOME/.config/kitty/kitty.conf" "$HOME/.config/kitty/auto-theme.conf"; do
  [ -e "$_kitty_cfg" ] || continue
  _fed_critical "rm -f '$_kitty_cfg'" "kitty configuration $(basename "$_kitty_cfg") could not be removed"
done
ok "Kitty config removed (user.conf kept)"

# ── 6c. Starship ──
if [ -e "$HOME/.config/starship.toml" ]; then
  _fed_critical "rm -f '$HOME/.config/starship.toml'" "Starship configuration could not be removed"
fi
ok "Starship config removed"

# ── 6d. GTK settings.ini (only in recommended mode — files were overwritten) ──
if [ "$MODE" = "surgical" ]; then
  warn "Surgical: gtk-3.0/4.0 settings.ini kept as-is"
else
  for _gtk_cfg in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
    [ -e "$_gtk_cfg" ] || continue
    _fed_critical "rm -f '$_gtk_cfg'" "GTK settings $(basename "$_gtk_cfg") could not be removed"
  done
  ok "GTK settings.ini removed (GNOME regenerates defaults)"
fi

# ── 6e. Fastfetch ──
if [ "$MODE" = "surgical" ]; then
  warn "Surgical: fastfetch config kept"
else
  _fed_trash_collection "$HOME/.config/fastfetch" "fastfetch configuration"
  ok "Fastfetch config removed"
fi

# ── 6f. systemd logind overrides ──
if [ -f /etc/systemd/logind.conf.d/logind-overrides.conf ]; then
  _fed_critical "sudo rm -f /etc/systemd/logind.conf.d/logind-overrides.conf" "logind override could not be removed"
  ok "logind overrides removed"
fi
_fed_phase_end

# ═════════════════════════════════════════════════════════════════
#  PHASE 7 : WALLPAPERS + AVATARS + GDM + FIREFOX + FLATPAK THEME
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 7  :  Wallpapers, Avatars, Login Screen${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
_fed_phase_begin wallpaper 'Phase 7: Wallpapers, avatars and login screen'

# ── 7a. Wallvault wallpaper packs + XML registrations ──
# Exact project paths only. Nothing here is a wildcard over shared system dirs.
log "Removing Wallvault wallpaper packs"
for _wall_dir in '/usr/share/backgrounds/Wallvault Wallpapers' \
                 '/usr/share/backgrounds/Wallvault Wallpapers +18'; do
  if [ -e "$_wall_dir" ] || [ -L "$_wall_dir" ]; then
    _fed_critical "sudo rm -rf '$_wall_dir'" "wallpaper pack $(basename "$_wall_dir") could not be removed"
  fi
done
for _wall_xml in /usr/share/gnome-background-properties/wallvault-wallpapers.xml \
                 /usr/share/gnome-background-properties/wallvault-wallpapers-18.xml; do
  if [ -e "$_wall_xml" ] || [ -L "$_wall_xml" ]; then
    _fed_critical "sudo rm -f '$_wall_xml'" "wallpaper registration $(basename "$_wall_xml") could not be removed"
  fi
done
for _desktop_wall in "$HOME/.local/share/backgrounds/Himeno Fedora.jpg" \
                     "$HOME/.local/share/backgrounds/Himeno Fedora LoginScreen.jpg"; do
  if [ -e "$_desktop_wall" ] || [ -L "$_desktop_wall" ]; then
    _fed_critical "rm -f '$_desktop_wall'" "desktop wallpaper $(basename "$_desktop_wall") could not be removed"
  fi
done
ok "Wallvault wallpapers removed"

# Stock backgrounds were wiped by install.sh (rm -rf /usr/share/backgrounds/*).
# The files belong to desktop-backgrounds packages — reinstalling brings them back.
if rpm -q desktop-backgrounds-basic &>/dev/null || rpm -q fedora-workstation-backgrounds &>/dev/null; then
  if confirm "Reinstall the stock Fedora wallpapers (removed by install.sh)? [Y/n]: " Y; then
    _fed_critical "sudo dnf reinstall -y desktop-backgrounds-basic desktop-backgrounds-compat fedora-workstation-backgrounds" \
      "stock Fedora wallpapers could not be restored"
    ok "Stock Fedora wallpapers restored"
  fi
fi

# ── 7b. Custom avatars (normal + 18+ are merged into the same dir) ──
# Only manifest-recorded, digest-verified project files are removed. Stock faces,
# user photos and unknown collections in /usr/share/pixmaps/faces are preserved.
log "Removing custom profile pictures"
_fed_avatar_cleanup '/usr/share/pixmaps/faces'
if [ -d '/usr/share/pixmaps/faces +18' ]; then
  log "Preserving unknown avatar collection '/usr/share/pixmaps/faces +18' (no project ownership manifest)"
fi
ok "Project-managed avatars removed"

# ── 7c. GDM: logo tweak + themed shell + boot-time restore ──
log "Restoring GDM login screen"
if [ -f /etc/dconf/db/gdm.d/01-logo ]; then
  _fed_critical "sudo rm -f /etc/dconf/db/gdm.d/01-logo" "GDM logo tweak could not be removed"
  _fed_try "sudo dconf update" "GDM dconf database could not be refreshed"
  ok "GDM logo tweak removed"
fi
# `gdm protect on` installs a boot-time restore unit. Remove it before restoring
# the stock shell so it cannot reapply the project theme on the next boot.
if [ -f /etc/systemd/system/mactahoe-gdm-restore.service ]; then
  _fed_try "sudo systemctl disable --now mactahoe-gdm-restore.service" "GDM restore service could not be stopped"
  _fed_critical "sudo rm -f /etc/systemd/system/mactahoe-gdm-restore.service" "GDM restore service file could not be removed"
  ok "GDM boot-time restore service removed"
fi
if [ -f /usr/local/sbin/mactahoe-gdm-restore.sh ]; then
  _fed_critical "sudo rm -f /usr/local/sbin/mactahoe-gdm-restore.sh" "GDM restore helper could not be removed"
fi
_fed_try "sudo systemctl daemon-reload" "systemd could not be reloaded after removing the GDM helper"
# MacTahoe tweaks.sh -g also themes the GDM shell. The only reliable way to
# restore the stock GDM resource is to reinstall gnome-shell.
if confirm "Reinstall gnome-shell to restore the stock GDM theme? [Y/n]: " Y; then
  _fed_critical "sudo dnf reinstall -y gnome-shell" "stock GDM theme could not be restored"
  ok "Stock GDM theme restored"
fi

# ── 7d. Firefox userChrome (macOS theme from tweaks.sh -f) ──
log "Removing Firefox macOS theme"
for _profile in "$HOME/.mozilla/firefox/"*/; do
  [ -d "$_profile" ] || continue
  _chrome="$_profile/chrome"
  if [ -L "$_chrome" ]; then
    _chrome_target=$(readlink -f "$_chrome" 2>/dev/null || true)
    case "$_chrome_target" in
      "$HOME/.mozilla/firefox/firefox-themes"|"$HOME/.mozilla/firefox/firefox-themes/"*)
        _fed_critical "rm -f '$_chrome'" "Firefox theme symlink could not be removed from $(basename "$_profile")"
        ;;
      *)
        log "Preserving custom Firefox chrome link in $(basename "$_profile")"
        ;;
    esac
  elif [ -d "$_chrome" ]; then
    for _ff_file in userChrome.css userContent.css customChrome.css; do
      [ -e "$_chrome/$_ff_file" ] || continue
      _fed_critical "rm -f '$_chrome/$_ff_file'" "Firefox theme file $_ff_file could not be removed from $(basename "$_profile")"
    done
  fi
  # tweaks.sh writes the customization pref to user.js (prefs.js is checked for
  # older runs). Only that pref is removed; other user prefs stay untouched.
  for _ff_prefs in "$_profile/user.js" "$_profile/prefs.js"; do
    [ -f "$_ff_prefs" ] || continue
    if grep -q 'toolkit.legacyUserProfileCustomizations.stylesheets' "$_ff_prefs" 2>/dev/null; then
      _fed_try "sed -i '/toolkit.legacyUserProfileCustomizations.stylesheets/d' '$_ff_prefs'" \
        "Firefox theme preference could not be cleared from $(basename "$_ff_prefs")"
    fi
  done
done
_fed_trash_collection "$HOME/.mozilla/firefox/firefox-themes" "Firefox theme directory"
ok "Firefox theme removed"

# ── 7e. Flatpak GTK runtime (org.gtk.Gtk3theme.MacTahoe-Dark) ──
log "Removing Flatpak GTK theme runtime"
if command -v flatpak >/dev/null 2>&1; then
  _fed_try "sudo flatpak uninstall -y --system org.gtk.Gtk3theme.MacTahoe-Dark" "Flatpak GTK theme runtime could not be removed"
fi
_fed_trash_collection "$HOME/.cache/pakitheme" "Flatpak theme build cache"
ok "Flatpak theme runtime removed"
_fed_phase_end

# ═════════════════════════════════════════════════════════════════
#  PHASE 8 : TERMINAL + SHELL DEFAULTS
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 8  :  Terminal + Shell Defaults${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
_fed_phase_begin terminal 'Phase 8: Terminal and shell defaults'

# ── 8a. Undo kitty symlinks (`sudo ln -sf /usr/bin/kitty /usr/bin/gnome-terminal`) ──
# Verify the link target before removing anything: a real package binary or a
# user-created link must never be deleted just because the path matches.
for _link in /usr/bin/gnome-terminal /usr/bin/x-terminal-emulator; do
  [ -L "$_link" ] || continue
  _link_raw=$(readlink "$_link" 2>/dev/null || true)
  _link_target=$(readlink -f "$_link" 2>/dev/null || true)
  if [ "$_link_raw" = "/usr/bin/kitty" ] || [ "$_link_raw" = "kitty" ] ||
     [ "$_link_target" = "/usr/bin/kitty" ]; then
    _fed_critical "sudo rm -f '$_link'" "terminal symlink $_link could not be removed"
  else
    log "Preserving $_link (target is '${_link_target:-unresolved}', not kitty)"
  fi
done
ok "Terminal symlinks removed (kitty no longer masquerades)"

# ── 8b. Restore ptyxis / gnome-weather (removed by the installer) ──
if state_has_step "remove_ptyxis" && ! rpm -q ptyxis &>/dev/null; then
  if confirm "Reinstall ptyxis (the terminal install.sh removed)? [Y/n]: " Y; then
    _fed_critical "sudo dnf install -y ptyxis" "Ptyxis could not be reinstalled"
    ok "Ptyxis reinstalled"
  fi
fi
if state_has_step "remove_gnome_weather" && ! rpm -q gnome-weather &>/dev/null; then
  if confirm "Reinstall gnome-weather (removed by install.sh)? [Y/n]: " Y; then
    _fed_critical "sudo dnf install -y gnome-weather" "GNOME Weather could not be reinstalled"
    ok "GNOME Weather reinstalled"
  fi
fi

# ── 8c. Default shell (was changed to fish) ──
_current_shell=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)
if [ "$_current_shell" = "/usr/bin/fish" ] || [ "$_current_shell" = "/bin/fish" ]; then
  if confirm "Restore /bin/bash as your default shell? [Y/n]: " Y; then
    _fed_critical "sudo chsh -s /bin/bash '$USER'" "default shell could not be restored to bash"
    ok "Default shell restored to bash (next login)"
  fi
fi
_fed_phase_end

# ═════════════════════════════════════════════════════════════════
#  PHASE 9 : SUDOERS HINT (commented NOPASSWD line added on install)
# ═════════════════════════════════════════════════════════════════
if [ "$DRY_RUN" = "1" ]; then
  _fed_phase_skip sudoers 'dry-run: administrator check skipped'
elif sudo grep -q "^# $USER ALL=(ALL) NOPASSWD: ALL$" /etc/sudoers 2>/dev/null; then
  _fed_phase_begin sudoers 'Phase 9: Sudoers hint'
  if confirm "Remove the commented NOPASSWD hint from /etc/sudoers? [Y/n]: " Y; then
    _tmp_sudoers=$(mktemp) || { _FED_PHASE_FAILED=1; warn "Could not create a temporary sudoers file"; }
    if [ -n "${_tmp_sudoers:-}" ]; then
      _fed_critical "sudo cat /etc/sudoers > '$_tmp_sudoers'" "sudoers could not be read"
      _fed_critical "sudo sed -i '/^# $USER ALL=(ALL) NOPASSWD: ALL$/d' '$_tmp_sudoers'" "NOPASSWD hint could not be removed from the temporary copy"
      if [ "$DRY_RUN" = "1" ]; then
        ok "NOPASSWD hint removal (dry-run)"
      elif sudo visudo -c -f "$_tmp_sudoers" 2>/dev/null; then
        _fed_critical "sudo cp '$_tmp_sudoers' /etc/sudoers" "sudoers could not be updated"
        _fed_critical "sudo chmod 440 /etc/sudoers" "sudoers permissions could not be restored"
        _fed_critical "sudo chown root:root /etc/sudoers" "sudoers ownership could not be restored"
        ok "NOPASSWD hint removed from /etc/sudoers"
      else
        _FED_PHASE_FAILED=1
        warn "sudoers validation failed — hint left in place"
      fi
      rm -f "$_tmp_sudoers" 2>/dev/null || warn "Temporary sudoers copy could not be removed"
    fi
  else
    _ui_step sudoers skipped 'declined'
    _FED_PHASE_ID=''
  fi
  [ -n "${_FED_PHASE_ID:-}" ] && _fed_phase_end
else
  _fed_phase_skip sudoers 'no NOPASSWD hint present'
fi

# ═════════════════════════════════════════════════════════════════
#  PHASE 10 : PACKAGE PURGE (only with --purge-packages)
# ═════════════════════════════════════════════════════════════════
if [ "$PURGE_PACKAGES" = "1" ]; then
  echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}PHASE 10 :  Package Purge (--purge-packages)${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
  _fed_phase_begin packages 'Phase 10: Package purge'
  warn "You asked for the packages install.sh added to be removed."
  warn "This will also remove config you may have created in these apps."
  if confirm "Remove all MacTahoe-installed RPM packages? [y/N]: " N; then
    _fed_try "sudo dnf remove -y $RPM_PACKAGES" "some MacTahoe RPM packages could not be removed"
    ok "RPM packages removed"
  fi
  if confirm "Remove all MacTahoe-installed Flatpaks? [y/N]: " N; then
    for fp in "${FLATPAK_APPS[@]}"; do
      flatpak info "$fp" >/dev/null 2>&1 || continue
      _fed_critical "flatpak uninstall -y '$fp'" "Flatpak $fp could not be removed"
    done
    _fed_try "flatpak uninstall --unused -y" "unused Flatpak runtimes could not be removed"
    ok "Flatpaks removed"
  fi
  if confirm "Remove Chrome + Edge + VS Code and their repos? [y/N]: " N; then
    _fed_try "sudo dnf remove -y google-chrome-stable microsoft-edge-stable code" "some browser packages could not be removed"
    for _repo_file in /etc/yum.repos.d/google-chrome.repo \
                      /etc/yum.repos.d/microsoft-edge.repo \
                      /etc/yum.repos.d/vscode.repo; do
      [ -e "$_repo_file" ] || continue
      _fed_critical "sudo rm -f '$_repo_file'" "repository file $(basename "$_repo_file") could not be removed"
    done
    ok "Browsers + VS Code removed"
  fi
  if confirm "Disable RPM Fusion (keep installed packages)? [y/N]: " N; then
    _fed_try "sudo dnf config-manager --set-disabled rpmfusion-free rpmfusion-nonfree" "RPM Fusion repositories could not be disabled"
    ok "RPM Fusion disabled"
  fi
  if confirm "Remove dnf5-plugin-automatic? [y/N]: " N; then
    _fed_try "sudo dnf remove -y dnf5-plugin-automatic" "dnf5-plugin-automatic could not be removed"
    ok "dnf5-plugin-automatic removed"
  fi
  _fed_phase_end
else
  _fed_phase_skip packages 'purge not requested'
fi

# ═════════════════════════════════════════════════════════════════
#  PHASE 11 : STATE + MISCELLANEOUS
# ═════════════════════════════════════════════════════════════════
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}PHASE 11 :  State + Cleanup${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"

_fed_phase_begin state 'Phase 11: State and cleanup'

# ── Remove the installer's cache (state, backups, logs-adjacent) ──
if [ -d "$STATE_DIR" ]; then
  if confirm "Delete the installer cache ($STATE_DIR)? [Y/n]: " Y; then
    _fed_trash_collection "$STATE_DIR" "installer cache"
    ok "Installer cache moved to Trash"
  else
    warn "Keeping $STATE_DIR"
  fi
fi

# ── License copy dropped in ~/Documents by finalize ──
_fed_trash_collection "$HOME/Documents/EPRAHEMI — PUBLIC LICENSE & REUSE TERMS.md" "license copy"

# ── GDM runtime clone (re-created on demand by `gdm`) ──
_fed_trash_collection "$HOME/.local/share/mactahoe-gdm" "GDM engine clone"

# ── Exact installer temp leftovers (no broad /tmp sweeps) ──
for _tmp_path in /tmp/mactahoe-gtk /tmp/window-title-pro.zip \
                 /tmp/gdm-converted.jpg /tmp/gdm-blurred.jpg; do
  [ -e "$_tmp_path" ] || [ -L "$_tmp_path" ] || continue
  if [ "$DRY_RUN" = "1" ]; then
    printf "  rm -rf -- %s ${DIM}[dry-run]${NC}\n" "$_tmp_path"
  else
    rm -rf -- "$_tmp_path" 2>/dev/null || warn "Temporary path $_tmp_path could not be removed"
  fi
done
_fed_phase_end

# ═════════════════════════════════════════════════════════════════
#  SUMMARY
# ═════════════════════════════════════════════════════════════════
if [ "${_UI_ACTIVE:-0}" = 1 ]; then
  if [ "$_FED_FAILED_PHASES" -gt 0 ]; then
    _UI_FINISH_TITLE='R E M O V A L   F I N I S H E D   W I T H   I S S U E S'
    _UI_FINISH_TITLE_COMPACT='Removal finished with issues'
    _ui_finish "Removal finished with issues in $_FED_FAILED_PHASES phase(s). Review the private log and retry the affected phase."
  else
    _UI_FINISH_TITLE='R E M O V A L   C O M P L E T E'
    _UI_FINISH_TITLE_COMPACT='Removal complete'
    _ui_finish 'Removal finished.'
  fi
else
  if [ -t 6 ]; then
    printf '\n' >&6
    if [ "$DRY_RUN" = "1" ]; then
      printf '  DRY RUN finished — nothing was changed on your system.\n' >&6
    elif [ "$_FED_FAILED_PHASES" -gt 0 ]; then
      printf '  Removal finished with %s phase(s) needing attention.\n' "$_FED_FAILED_PHASES" >&6
      printf '  Review the private log: %s\n' "$_FED_LOG" >&6
    else
      printf '  Removal finished. Log out and back in (or reboot) to complete the cleanup.\n' >&6
      printf '  Log saved: %s\n' "$_FED_LOG" >&6
    fi
    printf '\n' >&6
  fi
  _UI_FINISHED=1
fi

if [ "$_FED_FAILED_PHASES" -gt 0 ]; then
  exit 1
fi
exit 0
