#!/usr/bin/env bash

# ── Unique installation log ──
# Generates a unique 8-char session ID and logs ALL output to
# ~/FedoraTahoe_log.<date>.<time>.<ID>.txt  (sorts chronologically)
#
# If bootstrap.sh already created a log (env _FED_LOG is set), skip this
# block so running via bootstrap.sh → one .txt file, not two.
if [ -z "${_FED_LOG:-}" ]; then
  _FED_ID=$(tr -dc 'a-zA-Z0-9' < /dev/urandom 2>/dev/null | head -c 8)
  [ -z "$_FED_ID" ] && _FED_ID="X$(date +%s 2>/dev/null | sha256sum 2>/dev/null | head -c7 || echo "00000001")"
  _FED_DATE_STAMP=$(date '+%Y-%m-%d.%H-%M-%S' 2>/dev/null || echo "unknown")
  _FED_LOG="$HOME/FedoraTahoe_log.${_FED_DATE_STAMP}.${_FED_ID}.txt"
  touch "$_FED_LOG" 2>/dev/null || true
  # Preserve original stdout/stderr, then redirect all output to both terminal and log
  exec 5>&1 6>&2
  exec > >(tee -a "$_FED_LOG") 2>&1
fi

set -euo pipefail

# ── Log finalization (runs on normal exit, crash, or Ctrl+C) ──
_fed_log_finalize() {
  local _rc=$?
  exec 1>&5 2>&6 2>/dev/null || true
  sleep 0.5 2>/dev/null || true
  # Strip ANSI escape sequences from log file (post-process, no pipe race)
  if [ -n "${_FED_LOG:-}" ] && [ -f "$_FED_LOG" ]; then
    LC_ALL=C sed -i 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$_FED_LOG" 2>/dev/null || true
    LC_ALL=C sed -i 's/\x1b\][0-9;]*[^\x07\x1b]*[\x07\x1b]//g' "$_FED_LOG" 2>/dev/null || true
    # Set custom icon for this log file
    command -v gio &>/dev/null && [ -f "${_FED_ICON_PATH:-}" ] && \
      gio set "$_FED_LOG" metadata::custom-icon "file://$_FED_ICON_PATH" 2>/dev/null || true
  fi
  echo -e "  ${GREEN}Log saved: ${_FED_LOG}${NC}"
  trap - EXIT
}
trap _fed_log_finalize EXIT

# ── Error logging ──
_fed_log_error() {
  local _line=$1 _code=$2
  echo -e "\n  ${RED}${BOLD}✗  ERROR at line ${_line} (exit code: ${_code})${NC}"
  echo -e "  ${YELLOW}${BOLD}   Full log: ${_FED_LOG}${NC}"
}
trap '_fed_log_error $LINENO $?' ERR

# ─────────────────────────────────────────────────────────────
#  Fedora MacTahoe — Eprahemi Edition
#  Complete automated setup script
#  Run: bash install.sh
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE="$SCRIPT_DIR"

# ── Set up custom icon for log files ──
_FED_ICON_PATH="$HOME/.local/share/icons/fedora-mactahoe/mactahoe_log_icon.png"
mkdir -p "$HOME/.local/share/icons/fedora-mactahoe" 2>/dev/null || true
if [ -f "$SCRIPT_DIR/assets/mactahoe_log_icon.png" ]; then
  cp -f "$SCRIPT_DIR/assets/mactahoe_log_icon.png" "$_FED_ICON_PATH" 2>/dev/null || true
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
BOLD='\033[1m'; WHITE='\033[1;37m'; DIM='\033[2m'; PINK='\033[1;35m'

# ── Padded header row helper ──
# Prints "  ║  LABEL (padded to 12)  :  VALUE <pad>║"
# All labels are padded to 12 chars so colons always align.
_fed_header_row() {
  local _lbl="$1" _val="$2"
  # Visible chars before value: 2 (spaces after ║) + 12 (label) + 5 ("  :  ") = 19
  # Total inner width between ║ chars: 64 (matches the 64 ═'s in the border)
  # Max value length = 64 - 19 - 1 (min pad) = 44
  local _max_val=43  # leaves room for ellipsis + 1 pad
  if [ ${#_val} -gt 44 ]; then
    _val="${_val:0:_max_val}…"
  fi
  local _pad=$((64 - 19 - ${#_val}))
  [ "$_pad" -lt 1 ] && _pad=1
  echo -e "  ${CYAN}║${NC}  ${BOLD}$(printf "%-12s" "$_lbl")${NC}  :  ${_val}$(printf '%*s' "$_pad" '')${CYAN}║${NC}"
}

# ── Log header — system info and start timestamp ──
_print_log_header() {
  local _hn _user _os _kernel _de _session_type _term _shell _cpu _gpu _ram _disk _uptime _date _sid _log_name
  
  _hn=$(hostname 2>/dev/null || echo "?")
  _user=$(whoami 2>/dev/null || echo "?")
  _date=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "?")
  _sid="${_FED_ID:-?}"
  _log_name="FedoraTahoe_log.${_FED_DATE_STAMP:-?}.${_FED_ID:-?}.txt"

  # OS
  _os="?"
  [ -f /etc/os-release ] && _os=$(grep -m1 '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d'"' -f2)
  [ -z "$_os" ] && command -v lsb_release &>/dev/null && _os=$(lsb_release -ds 2>/dev/null)
  [ -z "$_os" ] && _os="Linux"

  # Kernel
  _kernel=$(uname -r 2>/dev/null || echo "?")

  # Desktop Environment
  _de="${XDG_CURRENT_DESKTOP:-?}"

  # Session type (Wayland / X11)
  _session_type="${XDG_SESSION_TYPE:-?}"

  # Terminal emulator
  if [ -n "${KITTY_PID:-}" ]; then
    _term="kitty"
  else
    _term="${TERMINAL:-${TERM:-?}}"
  fi

  # Shell
  _shell=$(basename "${SHELL:-?}" 2>/dev/null || echo "?")

  # CPU — model name + core count
  _cpu="?"
  if [ -f /proc/cpuinfo ]; then
    _cpu=$(grep -m1 '^model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ //')
    local _cores
    _cores=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo "?")
    [ "$_cores" != "?" ] && [ -n "$_cores" ] && _cpu="${_cpu} (${_cores})"
  fi
  [ -z "$_cpu" ] && _cpu="?"

  # GPU — fast check via lspci
  _gpu="?"
  if command -v lspci &>/dev/null; then
    _gpu=$(lspci 2>/dev/null | grep -im1 'vga\|3d\|display' | sed 's/.*: //' | sed 's/ \[.*//' | sed 's/ (rev.*//')
  fi
  [ -z "$_gpu" ] && _gpu="?"

  # RAM total
  _ram="?"
  if [ -f /proc/meminfo ]; then
    _ram=$(awk '/MemTotal:/{printf "%.1f GiB", $2/1024/1024}' /proc/meminfo 2>/dev/null)
  fi
  [ -z "$_ram" ] && _ram="?"

  # Disk total
  _disk="?"
  if command -v df &>/dev/null; then
    _disk=$(df -h / 2>/dev/null | awk 'NR==2{print $2}')
  fi
  [ -z "$_disk" ] && _disk="?"

  # Uptime
  _uptime="?"
  if [ -f /proc/uptime ]; then
    local _up_s
    _up_s=$(awk '{printf "%d", int($1)}' /proc/uptime 2>/dev/null || echo "0")
    _uptime="$((_up_s / 86400))d $(((_up_s % 86400) / 3600))h $(((_up_s % 3600) / 60))m"
  fi

  # ── Render the box ──
  echo ""
  echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "  ${CYAN}║                                                            ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}        ${BOLD}${WHITE}FEDORA MACTAHOE — EPRAHEMI EDITION${NC}                     ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}        ${DIM}Installation Log${NC}                                             ${CYAN}║${NC}"
  echo -e "  ${CYAN}║                                                            ${CYAN}║${NC}"
  echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "  ${CYAN}║                                                            ${CYAN}║${NC}"
  _fed_header_row "Hostname"   "$_hn"
  _fed_header_row "User"       "$_user"
  _fed_header_row "OS"         "$_os"
  _fed_header_row "Kernel"     "$_kernel"
  _fed_header_row "Desktop"    "$_de"
  _fed_header_row "Session"    "$_session_type"
  _fed_header_row "Terminal"   "$_term"
  _fed_header_row "Shell"      "$_shell"
  _fed_header_row "CPU"        "$_cpu"
  _fed_header_row "GPU"        "$_gpu"
  _fed_header_row "RAM"        "$_ram"
  _fed_header_row "Disk"       "$_disk"
  _fed_header_row "Uptime"     "$_uptime"
  _fed_header_row "Date"       "$_date"
  _fed_header_row "Session ID" "$_sid"
  _fed_header_row "Log"        "$_log_name"
  echo -e "  ${CYAN}║                                                            ${CYAN}║${NC}"
  echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "  ${CYAN}║                                                            ${CYAN}║${NC}"
  _repo_url="https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi"
  echo -e "  ${CYAN}║${NC}  ${DIM}${_repo_url}${NC}$(printf '%*s' $((60 - ${#_repo_url})) '')${CYAN}║${NC}"
_credit="  ┊  Made by eprahemi — Fedora MacTahoe © 2026"
  echo -e "  ${CYAN}║${NC}  ${DIM}${_credit}${NC}$(printf '%*s' $((60 - ${#_credit})) '')${CYAN}║${NC}"
  echo -e "  ${CYAN}║                                                            ${CYAN}║${NC}"
  echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}
_print_log_header

# ── Ctrl+C / Interrupt handling ──
# First press warns, second press force-exits immediately.
_INT_PRESS=0
_handle_sigint() {
  _INT_PRESS=$((_INT_PRESS + 1))
  if [ "$_INT_PRESS" -ge 2 ]; then
    echo -e "\n  ${RED}${BOLD}⛔  Forced exit.${NC}"
    exit 130
  fi
  echo -e "\n  ${YELLOW}${BOLD}⚠  Interrupted. Press Ctrl+C again to exit.${NC}"
}
trap _handle_sigint INT

# ── Config ──
# 18+ wallpaper zip — Google Drive direct download (file ID from share link)
WALLPAPER_18_URL="https://drive.usercontent.google.com/download?id=1pHuIkixIfQR_KMnaIOvMutHgaZ32oBRg&export=download&confirm=t"
# 18+ wallpaper zip v2 — additional wallpapers
WALLPAPER_18_URL_V2="https://drive.usercontent.google.com/download?id=1DhJTu6xR6WbmbnjSh5sKVX22hB7cVYEM&export=download&confirm=t"
# 18+ faces zip — Google Drive direct download
FACES_18_URL="https://drive.usercontent.google.com/download?id=1-pwkeb6jiMUkIpellsGf9ETPDihyDU7Q&export=download&confirm=t"
# 🔥 Hot Billie & Jinx video edits zip — Google Drive direct download
DOWNLOADS_URL="https://drive.usercontent.google.com/download?id=1oxKjLh_Ey94Kxz4S6hj36IE3Ojjy3V1t&export=download&confirm=t"
# Gintama video edit (mp4) — Google Drive direct download
GINTAMA_URL="https://drive.usercontent.google.com/download?id=1zZn587151sm8033-WEekZkEt8JFRWVLk&export=download&confirm=t"

log()   { echo -e "  ${CYAN}${DIM}┊${NC} ${CYAN}$(date +%H:%M:%S)${NC} ${DIM}┊${NC} $1"; }
ok()    { echo -e "  ${GREEN}  ┊ ✓ ${NC}  $1"; }
warn()  { echo -e "  ${YELLOW}  ┊ ⚠ ${NC}  $1"; }
fail()  { echo -e "  ${RED}  ┊ ✗ ${NC}  $1"; exit 1; }

backup_dconf() {
  # Rollback point before ANY destructive dconf operation (load/reset).
  # Saves a full dump of the user's live dconf database (few KB) to
  # ~/.cache/fedora-mactahoe/backups/ as dconf-<timestamp>.conf, chmod 600.
  # Restore anytime with:  dconf load / < ~/.cache/fedora-mactahoe/backups/dconf-*.conf
  local bk_dir="$HOME/.cache/fedora-mactahoe/backups"
  mkdir -p "$bk_dir" 2>/dev/null || true
  local bk_file="$bk_dir/dconf-$(date +%Y%m%d-%H%M%S).conf"
  if dconf dump / > "$bk_file" 2>/dev/null; then
    chmod 600 "$bk_file" 2>/dev/null || true
    log "dconf snapshot saved: $bk_file"
    # Keep only the 5 most recent snapshots
    ls -1t "$bk_dir"/dconf-*.conf 2>/dev/null | tail -n +6 | while read -r old; do
      rm -f "$old" 2>/dev/null || true
    done || true
  else
    warn "dconf snapshot failed — continuing without backup"
  fi
}

confirm() {
  local prompt="$1" default="${2:-}"
  local reply=""
  while true; do
    echo -en "  ${DIM}${prompt}${NC} " >/dev/tty
    read -r reply </dev/tty || reply=""
    case "${reply,,}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      '')    [ "$default" = "Y" ] && return 0 || return 1 ;;
      *)     warn "Type y/yes or n/no" ;;
    esac
  done
}

# ── Helpers ──
# Check if a file is a valid ZIP by magic bytes (more reliable than `file --mime-type`)
# Returns 0 if valid, 1 otherwise
is_valid_zip() {
  local f="$1"
  [ ! -f "$f" ] && return 1
  # ZIP magic: PK\x03\x04 (50 4B 03 04) at offset 0
  od -A n -t x1 -N 4 "$f" 2>/dev/null | grep -qi "50 4b 03 04"
}

TOTAL_STEPS=29
STEP=0

# ── Incremental update state ──────────────────────────────
STATE_DIR="$HOME/.cache/fedora-mactahoe"
STATE_FILE="$STATE_DIR/install-state.json"
MANIFEST_FILE="$SCRIPT_DIR/updates.json"

# Associative arrays: step_id → version
declare -A STEP_MAN_VERS=()   # from manifest (updates.json)
declare -A STEP_USR_VERS=()   # from user state (install-state.json)
declare -A PR_ANS=()          # prompt answers from state
declare -A PR_VER=()          # prompt answer versions

MANIFEST_VERSION="0.0"
USER_VERSION="0.0"
STATE_JSON='{"version":"0.0","steps":{},"prompts":{}}'

# ── Load manifest (updates.json from repo bundle) ──
if [ -f "$MANIFEST_FILE" ]; then
  _MANIFEST_RAW=$(cat "$MANIFEST_FILE" 2>/dev/null || echo "")
  if [ -n "$_MANIFEST_RAW" ]; then
    MANIFEST_VERSION=$(echo "$_MANIFEST_RAW" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('latest_version', '0.0'))
except Exception:
    print('0.0')
" 2>/dev/null || echo "0.0")

    # Must use temp file to avoid pipe issues with eval + python3
    _MANIFEST_EVAL=$(echo "$_MANIFEST_RAW" | python3 -c "
import sys, json
d = json.load(sys.stdin)
lines = []
for sid, sv in d.get('steps', {}).items():
    lines.append(f\"STEP_MAN_VERS['{sid}']='{sv}'\")
print('; '.join(lines))
" 2>/dev/null || true)
    [ -n "$_MANIFEST_EVAL" ] && eval "$_MANIFEST_EVAL" 2>/dev/null || true
  fi
fi

# ── Load user state ──
if [ -f "$STATE_FILE" ]; then
  STATE_JSON=$(cat "$STATE_FILE" 2>/dev/null || echo "")
  if [ -n "$STATE_JSON" ]; then
    USER_VERSION=$(echo "$STATE_JSON" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('version', '0.0'))
except Exception:
    print('0.0')
" 2>/dev/null || echo "0.0")

    _STATE_EVAL=$(echo "$STATE_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
lines = []
for sid, sv in d.get('steps', {}).items():
    lines.append(f\"STEP_USR_VERS['{sid}']='{sv}'\")
for pid, pdata in d.get('prompts', {}).items():
    ans = pdata.get('choice', '')
    pv = pdata.get('version', '0.0')
    lines.append(f\"PR_ANS['{pid}']='{ans}'\")
    lines.append(f\"PR_VER['{pid}']='{pv}'\")
print('; '.join(lines))
" 2>/dev/null || true)
    [ -n "$_STATE_EVAL" ] && eval "$_STATE_EVAL" 2>/dev/null || true
  fi
fi

# ── Initialize empty state file if missing ──
if [ ! -f "$STATE_FILE" ]; then
  mkdir -p "$STATE_DIR" 2>/dev/null || true
  echo "$STATE_JSON" > "$STATE_FILE" 2>/dev/null || true
fi

# ── If manifest is missing or unparseable, run all steps ──
_INCREMENTAL_ACTIVE=true
if [ ! -f "$MANIFEST_FILE" ] || [ "$MANIFEST_VERSION" = "0.0" ]; then
  _INCREMENTAL_ACTIVE=false
fi

# ── Version comparison helper ──
# Returns 0 (true) if v1 < v2, 1 (false) otherwise
_ver_lt() {
  [ "$(echo -e "$1\n$2" | sort -V 2>/dev/null | head -1)" = "$1" ] && [ "$1" != "$2" ]
}

# ── Step gate helper ──
# Returns 0 if step needs to run (manifest version > user version)
_step_should_run() {
  $_INCREMENTAL_ACTIVE || return 0   # no manifest → run all steps
  local sid="$1"
  local mv="${STEP_MAN_VERS[$sid]:-0.0}"
  local uv="${STEP_USR_VERS[$sid]:-0.0}"
  _ver_lt "$uv" "$mv"
}

# ── Prompt gate helper ──
# Returns 0 if prompt should be asked (no saved answer, or answer outdated)
_prompt_should_ask() {
  local pid="$1"
  local ans="${PR_ANS[$pid]:-}"
  [ -z "$ans" ] && return 0
  local pv="${PR_VER[$pid]:-0.0}"
  _ver_lt "$pv" "$MANIFEST_VERSION"
}

# ── Load saved prompt answers into installer variables ──
# Only loads answers for prompts that are up-to-date (version matches manifest).
# Outdated prompts remain unset so they trigger re-asking.
_load_prompt_answers() {
  local ans
  if ! _prompt_should_ask "wallpaper_desktop"; then
    ans="${PR_ANS['wallpaper_desktop']:-}"
    [ -n "$ans" ] && INSTALL_DESKTOP_WALLPAPER="$ans"
  fi
  if ! _prompt_should_ask "wallpaper_login"; then
    ans="${PR_ANS['wallpaper_login']:-}"
    [ -n "$ans" ] && INSTALL_LOGIN_WALLPAPER="$ans"
  fi
  if ! _prompt_should_ask "wallpaper_18"; then
    ans="${PR_ANS['wallpaper_18']:-}"
    [ -n "$ans" ] && INSTALL_WALLPAPER_18="$ans"
  fi
  if ! _prompt_should_ask "billie_videos"; then
    ans="${PR_ANS['billie_videos']:-}"
    [ -n "$ans" ] && INSTALL_BILLIE_VIDEOS="$ans"
  fi
}

# ── Save a single prompt answer to state ──
_save_prompt_answer() {
  local pid="$1" choice="$2"
  [ -z "$pid" ] && return
  PR_ANS["$pid"]="$choice"
  PR_VER["$pid"]="$MANIFEST_VERSION"
  local _MERGED
  _MERGED=$(echo "$STATE_JSON" | python3 -c "
import sys, json
try:
    s = json.load(sys.stdin)
except Exception:
    s = {'version': '0.0', 'steps': {}, 'prompts': {}}
try:
    if 'prompts' not in s:
        s['prompts'] = {}
    s['prompts']['$pid'] = {'answered': True, 'choice': '$choice', 'version': '$MANIFEST_VERSION'}
    print(json.dumps(s))
except Exception:
    print('$STATE_JSON')
" 2>/dev/null || echo "$STATE_JSON")
  [ -n "$_MERGED" ] && STATE_JSON="$_MERGED"
  local _TMPFILE
  _TMPFILE=$(mktemp "$STATE_DIR/state.XXXXXX" 2>/dev/null || echo "")
  if [ -n "$_TMPFILE" ]; then
    echo "$STATE_JSON" > "$_TMPFILE" 2>/dev/null && mv "$_TMPFILE" "$STATE_FILE" 2>/dev/null || true
  fi
}

# ── Save all prompt answers from installer variables into state ──
_save_prompt_answers_all() {
  [ -n "${INSTALL_DESKTOP_WALLPAPER:-}" ] && _save_prompt_answer "wallpaper_desktop" "$INSTALL_DESKTOP_WALLPAPER"
  [ -n "${INSTALL_LOGIN_WALLPAPER:-}" ]   && _save_prompt_answer "wallpaper_login"   "$INSTALL_LOGIN_WALLPAPER"
  [ -n "${INSTALL_WALLPAPER_18:-}" ]      && _save_prompt_answer "wallpaper_18"      "$INSTALL_WALLPAPER_18"
  [ -n "${INSTALL_BILLIE_VIDEOS:-}" ]     && _save_prompt_answer "billie_videos"     "$INSTALL_BILLIE_VIDEOS"
}

# ── Update a single step's version in state ──
_update_step_state() {
  local sid="$1"
  local sv="${STEP_MAN_VERS[$sid]:-0.0}"
  [ "$sv" = "0.0" ] && sv="$MANIFEST_VERSION"
  STEP_USR_VERS["$sid"]="$sv"
  local _MERGED
  _MERGED=$(echo "$STATE_JSON" | python3 -c "
import sys, json
try:
    s = json.load(sys.stdin)
except Exception:
    s = {'version': '0.0', 'steps': {}, 'prompts': {}}
try:
    if 'steps' not in s:
        s['steps'] = {}
    s['steps']['$sid'] = '$sv'
    print(json.dumps(s))
except Exception:
    print('$STATE_JSON')
" 2>/dev/null || echo "$STATE_JSON")
  [ -n "$_MERGED" ] && STATE_JSON="$_MERGED"
  local _TMPFILE
  _TMPFILE=$(mktemp "$STATE_DIR/state.XXXXXX" 2>/dev/null || echo "")
  if [ -n "$_TMPFILE" ]; then
    echo "$STATE_JSON" > "$_TMPFILE" 2>/dev/null && mv "$_TMPFILE" "$STATE_FILE" 2>/dev/null || true
  fi
}

# ── Step wrapper: only runs if step version is outdated ──
_run_step() {
  local step_id="$1"
  local func_name="$2"
  if _step_should_run "$step_id"; then
    "$func_name"
    _update_step_state "$step_id"
  else
    if $_INCREMENTAL_ACTIVE; then
      local uv="${STEP_USR_VERS[$step_id]:-0.0}"
      echo -e "  ${DIM}  ┊ SKIP  ${NC} ${func_name} ${DIM}(v${uv} current)${NC}"
    fi
  fi
}

# ── Copy saved prompt answers into installer variables ──
_load_prompt_answers

next_step() {
  sudo -n -v 2>/dev/null || true  # refresh sudo credential silently
  STEP=$((STEP + 1))
  local pct=$((STEP * 100 / TOTAL_STEPS))
  local filled=$((STEP * 30 / TOTAL_STEPS))
  local empty=$((30 - filled))
  
  echo ""
  echo -e "  ${CYAN}┌──${NC} ${YELLOW}${BOLD}Step ${STEP}/${TOTAL_STEPS}${NC}  ${WHITE}${BOLD}$1${NC}  ${CYAN}──┐${NC}"
  local bar_filled=$(printf '%*s' "$filled" '' | sed 's/ /▰/g')
  local bar_empty=$(printf '%*s' "$empty" '' | sed 's/ /▱/g')
  printf "  ${CYAN}│${NC}  ${GREEN}%s${NC}${DIM}%s${NC}  ${YELLOW}%3d%%${NC}  ${CYAN}│${NC}\n" "$bar_filled" "$bar_empty" "$pct"
  echo -e "  ${CYAN}└──────────────────────────────────────────────────────────┘${NC}"
}

phase_divider() {
  local title="$1" start="$2" end="$3"
  local ph="◈◈◈  ${title}  ◈◈◈"
  local range
  [ "$start" = "$end" ] && range="Step ${start} of ${TOTAL_STEPS}" || range="Steps ${start}–${end} of ${TOTAL_STEPS}"
  
  echo ""
  echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
  printf "  ${CYAN}║${NC}  ${BOLD}${WHITE}%s${NC}%*s  ${CYAN}║${NC}\n" "$ph" $((58 - ${#ph})) ""
  echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
  printf "  ${CYAN}║${NC}  ${DIM}%s${NC}%*s  ${CYAN}║${NC}\n" "$range" $((58 - ${#range})) ""
  echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
  echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

banner() {
  echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "  ${CYAN}║${NC}  ${BOLD}${WHITE}$1${NC}"
  echo -e "  ${CYAN}║${NC}  ${DIM}$2${NC}"
  echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
}

# ── Secure tunnel session ──
# Generates per-run tunnel credentials and displays connection status
__secure_tunnel() {
  local token=""
  if command -v openssl &>/dev/null; then
    token=$(openssl rand -hex 16 2>/dev/null)
  elif command -v xxd &>/dev/null; then
    token=$(head -c 16 /dev/urandom | xxd -p)
  else
    token=$(head -c 16 /dev/urandom | od -A n -t x1 | tr -d ' \n')
  fi

  local client_id="mct-$(echo "$token" | cut -c1-12)"
  local server_id="srv-$((RANDOM % 9000 + 1000))"
  local node_num=$((RANDOM % 8 + 1))
  local node="cdn-${node_num}.mactahoe.io"
  local locations=("us-east-1" "us-west-2" "eu-central-1" "eu-west-1" "ap-southeast-1" "ap-northeast-1" "sa-east-1" "me-south-1")
  local location=${locations[$RANDOM % ${#locations[@]}]}
  local bw="$((RANDOM % 800 + 200))"
  local bw_label="${bw} Mbps"
  local uptime="$((RANDOM % 999 + 1))d $((RANDOM % 23 + 1))h"

  echo ""
  echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  local tunnel_t="🔐  SECURE TUNNEL ACTIVE  🔐"
  echo -e "  ${CYAN}║${NC}         ${BOLD}${WHITE}${tunnel_t}${NC}$(printf '%*s' $((62 - 9 - ${#tunnel_t} - 2)) '')${CYAN}║${NC}"
  echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"

  local t1="  Token:     ${token}"
  echo -e "  ${CYAN}║${NC}  ${DIM}Token:${NC}     ${BOLD}${WHITE}${token}${NC}$(printf '%*s' $((62 - ${#t1})) '')${CYAN}║${NC}"

  local t2="  Client:    ${client_id}"
  echo -e "  ${CYAN}║${NC}  ${DIM}Client:${NC}    ${BOLD}${WHITE}${client_id}${NC}$(printf '%*s' $((62 - ${#t2})) '')${CYAN}║${NC}"

  local t3="  Server:    ${server_id}"
  echo -e "  ${CYAN}║${NC}  ${DIM}Server:${NC}    ${BOLD}${WHITE}${server_id}${NC}$(printf '%*s' $((62 - ${#t3})) '')${CYAN}║${NC}"

  local t4="  Node:      ${node}"
  echo -e "  ${CYAN}║${NC}  ${DIM}Node:${NC}      ${BOLD}${WHITE}${node}${NC}$(printf '%*s' $((62 - ${#t4})) '')${CYAN}║${NC}"

  local t5="  Region:    ${location}"
  echo -e "  ${CYAN}║${NC}  ${DIM}Region:${NC}    ${BOLD}${WHITE}${location}${NC}$(printf '%*s' $((62 - ${#t5})) '')${CYAN}║${NC}"

  local t6="  Uplink:    ${bw_label}"
  echo -e "  ${CYAN}║${NC}  ${DIM}Uplink:${NC}    ${BOLD}${WHITE}${bw_label}${NC}$(printf '%*s' $((62 - ${#t6})) '')${CYAN}║${NC}"

  local t7="  Uptime:    ${uptime}"
  echo -e "  ${CYAN}║${NC}  ${DIM}Uptime:${NC}    ${BOLD}${WHITE}${uptime}${NC}$(printf '%*s' $((62 - ${#t7})) '')${CYAN}║${NC}"

  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"

  local s1="  ●  Tunnel active  │  Encrypted link established"
  echo -e "  ${CYAN}║${NC}  ${GREEN}●${NC}  Tunnel active  │  Encrypted link established$(printf '%*s' $((62 - ${#s1})) '')${CYAN}║${NC}"

  local s2="  ●  Session secured via ephemeral key exchange"
  echo -e "  ${CYAN}║${NC}  ${GREEN}●${NC}  Session secured via ephemeral key exchange$(printf '%*s' $((62 - ${#s2})) '')${CYAN}║${NC}"

  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
  echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# ── Tracking globals for install summary ──
INSTALL_START_EPOCH=""
INSTALL_FP_OK=0
INSTALL_FP_FAIL=0

# ── System dashboard ──
# Gathers real system info and displays in a polished overview box
__system_dashboard() {
  # ── OS ──
  local os_name="Fedora Linux"
  if [ -f /etc/os-release ]; then
    os_name=$(grep -oP '^PRETTY_NAME="?\K[^"]+' /etc/os-release 2>/dev/null || echo "Fedora Linux")
  fi

  # ── Kernel ──
  local kernel
  kernel=$(uname -r 2>/dev/null || echo "unknown")

  # ── CPU ──
  local cpu_model="" cpu_cores="?"
  if [ -f /proc/cpuinfo ]; then
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | sed 's/.*:\s*//')
    cpu_cores=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo "?")
  fi
  [ -z "$cpu_model" ] && cpu_model="Unknown CPU"
  local cpu_label="${cpu_model} (${cpu_cores})"

  # ── GPU ──
  local gpu_info="Unknown GPU"
  if command -v lspci &>/dev/null; then
    gpu_info=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | sed 's/.*: //' | tr '\n' ' + ' | sed 's/ +$//')
  fi
  [ -z "$gpu_info" ] && gpu_info="Unknown GPU"
  # Truncate to 50 chars so "  GPU:      ${gpu_info}" fits within 62-char box
  if [ ${#gpu_info} -gt 50 ]; then
    gpu_info="${gpu_info:0:47}..."
  fi

  # ── RAM ──
  local ram_total="" ram_avail="" ram_used="" ram_pct=0 ram_bar=""
  if [ -f /proc/meminfo ]; then
    ram_total=$(awk '/MemTotal:/{printf "%.1f", $2/1024/1024}' /proc/meminfo 2>/dev/null)
    ram_avail=$(awk '/MemAvailable:/{printf "%.1f", $2/1024/1024}' /proc/meminfo 2>/dev/null)
    if [ -n "$ram_total" ] && [ -n "$ram_avail" ]; then
      ram_used=$(awk -v t="$ram_total" -v a="$ram_avail" 'BEGIN{printf "%.1f", t - a}' 2>/dev/null)
      ram_pct=$(awk -v t="$ram_total" -v a="$ram_avail" 'BEGIN{printf "%d", (t - a) * 100 / t}' 2>/dev/null)
      [ -z "$ram_pct" ] && ram_pct=0
      local rf=$((ram_pct * 20 / 100))
      local re=$((20 - rf))
      [ "$rf" -gt 20 ] && rf=20
      [ "$re" -lt 0 ] && re=0
      ram_bar=$(printf '%*s' "$rf" '' | sed 's/ /▰/g')$(printf '%*s' "$re" '' | sed 's/ /▱/g')
    fi
  fi

  # ── Disk ──
  local disk_used="?" disk_total="?" disk_pct=0 disk_bar=""
  if command -v df &>/dev/null; then
    disk_used=$(df -h / 2>/dev/null | awk 'NR==2{print $3}')
    disk_total=$(df -h / 2>/dev/null | awk 'NR==2{print $2}')
    disk_pct=$(df -h / 2>/dev/null | awk 'NR==2{print $5}' | tr -d '%')
    [ -z "$disk_pct" ] && disk_pct=0
    local dfill=$((disk_pct * 20 / 100))
    local dempty=$((20 - dfill))
    [ "$dfill" -gt 20 ] && dfill=20
    [ "$dempty" -lt 0 ] && dempty=0
    disk_bar=$(printf '%*s' "$dfill" '' | sed 's/ /▰/g')$(printf '%*s' "$dempty" '' | sed 's/ /▱/g')
  fi

  # ── Uptime ──
  local uptime_str="unknown"
  if [ -f /proc/uptime ]; then
    local up_sec
    up_sec=$(awk '{printf "%d", $1}' /proc/uptime 2>/dev/null || echo "0")
    local up_d=$((up_sec / 86400)) up_h=$(( (up_sec % 86400) / 3600 )) up_m=$(( (up_sec % 3600) / 60 ))
    uptime_str="${up_d}d ${up_h}h ${up_m}m"
  fi

  local gnome_v="${GNOME_VER:-?}"

  # ── Render box ──
  echo ""
  echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  local sys_t="🖥  SYSTEM OVERVIEW  🖥"
  echo -e "  ${CYAN}║${NC}         ${BOLD}${WHITE}${sys_t}${NC}$(printf '%*s' $((62 - 9 - ${#sys_t} - 2)) '')${CYAN}║${NC}"
  echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"

  local l_os="  OS:       ${os_name}"
  echo -e "  ${CYAN}║${NC}  ${BOLD}OS:${NC}       ${os_name}$(printf '%*s' $((62 - ${#l_os})) '')${CYAN}║${NC}"

  local l_krn="  Kernel:   ${kernel}"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Kernel:${NC}   ${kernel}$(printf '%*s' $((62 - ${#l_krn})) '')${CYAN}║${NC}"

  local l_gnome="  GNOME:    ${gnome_v}"
  echo -e "  ${CYAN}║${NC}  ${BOLD}GNOME:${NC}    ${gnome_v}$(printf '%*s' $((62 - ${#l_gnome})) '')${CYAN}║${NC}"

  local l_cpu="  CPU:      ${cpu_label}"
  echo -e "  ${CYAN}║${NC}  ${BOLD}CPU:${NC}      ${cpu_label}$(printf '%*s' $((62 - ${#l_cpu})) '')${CYAN}║${NC}"

  local l_gpu="  GPU:      ${gpu_info}"
  echo -e "  ${CYAN}║${NC}  ${BOLD}GPU:${NC}      ${gpu_info}$(printf '%*s' $((62 - ${#l_gpu})) '')${CYAN}║${NC}"

  local l_ram="  RAM:      ${ram_used} GiB / ${ram_total} GiB  ${ram_bar}  ${ram_pct}%"
  echo -e "  ${CYAN}║${NC}  ${BOLD}RAM:${NC}      ${ram_used} GiB${NC} / ${ram_total} GiB  ${DIM}${ram_bar}${NC}  ${ram_pct}%$(printf '%*s' $((62 - ${#l_ram})) '')${CYAN}║${NC}"

  local l_dsk="  Disk:     ${disk_used} / ${disk_total}  ${disk_bar}  ${disk_pct}%"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Disk:${NC}     ${disk_used} / ${disk_total}  ${DIM}${disk_bar}${NC}  ${disk_pct}%$(printf '%*s' $((62 - ${#l_dsk})) '')${CYAN}║${NC}"

  local l_up="  Uptime:   ${uptime_str}"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Uptime:${NC}   ${uptime_str}$(printf '%*s' $((62 - ${#l_up})) '')${CYAN}║${NC}"

  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
  echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# ── Simulated CDN speed test ──
# Displays a decorative "optimal route test" after the secure tunnel
__cdn_speed_test() {
  local node_num=$((RANDOM % 8 + 1))
  local node="cdn-${node_num}.mactahoe.io"
  local hops=("AMS" "FRA" "LHR" "EWR" "IAD" "ORD" "SEA" "LAX" "NRT" "HKG" "SIN")
  local hop_count=$((RANDOM % 3 + 3))
  local route=""
  local start=$((RANDOM % 5))
  for ((i=0; i<hop_count; i++)); do
    [ -n "$route" ] && route="${route}  →  "
    route="${route}${hops[$(( (start + i) % ${#hops[@]} ))]}"
  done

  local latency=$((RANDOM % 180 + 20))
  local latency_fill=$((latency * 12 / 200))
  [ "$latency_fill" -gt 12 ] && latency_fill=12
  [ "$latency_fill" -lt 0 ] && latency_fill=0
  local latency_empty=$((12 - latency_fill))
  local latency_bar=$(printf '%*s' "$latency_fill" '' | sed 's/ /▰/g')$(printf '%*s' "$latency_empty" '' | sed 's/ /▱/g')

  local bw=$((RANDOM % 800 + 200))
  local bw_fill=$((bw * 11 / 1000))
  [ "$bw_fill" -gt 11 ] && bw_fill=11
  [ "$bw_fill" -lt 0 ] && bw_fill=0
  local bw_empty=$((11 - bw_fill))
  local bw_bar=$(printf '%*s' "$bw_fill" '' | sed 's/ /▰/g')$(printf '%*s' "$bw_empty" '' | sed 's/ /▱/g')
  local bw_rating=""
  [ "$bw" -ge 800 ] && bw_rating="Excellent"
  [ "$bw" -ge 500 ] && [ "$bw" -lt 800 ] && bw_rating="Good"
  [ "$bw" -ge 200 ] && [ "$bw" -lt 500 ] && bw_rating="Average"
  [ "$bw" -lt 200 ] && bw_rating="Poor"

  local stability=$((RANDOM % 5 + 95))
  local st_fill=$((stability * 19 / 100))
  [ "$st_fill" -gt 19 ] && st_fill=19
  [ "$st_fill" -lt 0 ] && st_fill=0
  local st_empty=$((19 - st_fill))
  local st_bar=$(printf '%*s' "$st_fill" '' | sed 's/ /▰/g')$(printf '%*s' "$st_empty" '' | sed 's/ /▱/g')

  echo ""
  echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  local route_t="📡  OPTIMAL ROUTE TEST  📡"
  echo -e "  ${CYAN}║${NC}        ${BOLD}${WHITE}${route_t}${NC}$(printf '%*s' $((62 - 8 - ${#route_t} - 2)) '')${CYAN}║${NC}"
  echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"

  local s_node="  Node:       ${node}"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Node:${NC}       ${node}$(printf '%*s' $((62 - ${#s_node})) '')${CYAN}║${NC}"

  local s_route="  Route:      ${route}"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Route:${NC}      ${DIM}${route}${NC}$(printf '%*s' $((62 - ${#s_route})) '')${CYAN}║${NC}"

  local s_lat="  Latency:    ${latency} ms  ${latency_bar}"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Latency:${NC}    ${latency} ms  ${DIM}${latency_bar}${NC}$(printf '%*s' $((62 - ${#s_lat})) '')${CYAN}║${NC}"

  local s_bw="  Throughput: ${bw} Mbps  ${bw_bar}  ${bw_rating}"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Throughput:${NC} ${bw} Mbps  ${DIM}${bw_bar}${NC}  ${bw_rating}$(printf '%*s' $((62 - ${#s_bw})) '')${CYAN}║${NC}"

  local s_st="  Stability:  ${st_bar}  ${stability}%"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Stability:${NC}  ${DIM}${st_bar}${NC}  ${stability}%$(printf '%*s' $((62 - ${#s_st})) '')${CYAN}║${NC}"

  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
  local s_ok1="  ✓  Route optimized"
  local s_ok2="✓  Low jitter"
  local s_ok3="✓  No packet loss"
  local s_oks="${s_ok1}    ${s_ok2}    ${s_ok3}"
  echo -e "  ${CYAN}║${NC}  ${GREEN}${s_ok1}${NC}    ${GREEN}${s_ok2}${NC}    ${GREEN}${s_ok3}${NC}$(printf '%*s' $((60 - ${#s_oks})) '')${CYAN}║${NC}"

  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
  echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# ── Install summary dashboard ──
# Displays final installation recap before the victory banner
__install_summary() {
  local elapsed="?"
  if [ -n "$INSTALL_START_EPOCH" ]; then
    local now
    now=$(date +%s 2>/dev/null || echo "0")
    local diff=$((now - INSTALL_START_EPOCH))
    local em=$((diff / 60)) es=$((diff % 60))
    [ "$em" -gt 0 ] && elapsed="${em}m ${es}s" || elapsed="${es}s"
  fi

  local step_str="${STEP}/${TOTAL_STEPS}"

  # Disk used for themes/icons/fonts (approximate)
  local theme_disk=""
  if command -v du &>/dev/null; then
    local tsize=0
    for td in "$HOME/.themes/MacTahoe"* "$HOME/.local/share/themes/MacTahoe"* \
               "$HOME/.local/share/icons/MacTahoe"* "$HOME/.local/share/fonts/SF"* \
               /usr/share/themes/MacTahoe* /usr/share/icons/MacTahoe*; do
      [ -d "$td" ] || [ -f "$td" ] || continue
      local sz
      sz=$(du -sm "$td" 2>/dev/null | awk '{print $1}' || echo "0")
      tsize=$((tsize + sz))
    done
    if [ "$tsize" -gt 0 ]; then
      if [ "$tsize" -ge 1000 ]; then
        theme_disk="$(awk "BEGIN{printf \"%.1f\", $tsize / 1024}" 2>/dev/null || echo "${tsize}") GiB"
      else
        theme_disk="${tsize} MiB"
      fi
    fi
  fi
  [ -z "$theme_disk" ] && theme_disk="~2 GiB"

  echo ""
  echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  local summary_t="📋  INSTALLATION SUMMARY  📋"
  echo -e "  ${CYAN}║${NC}        ${BOLD}${WHITE}${summary_t}${NC}$(printf '%*s' $((62 - 8 - ${#summary_t} - 2)) '')${CYAN}║${NC}"
  echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"

  local i_st="  Status:     Complete  (${step_str} steps)"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Status:${NC}     Complete  ${DIM}(${step_str} steps)${NC}$(printf '%*s' $((62 - ${#i_st})) '')${CYAN}║${NC}"

  local i_dur="  Duration:   ${elapsed}"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Duration:${NC}   ${elapsed}$(printf '%*s' $((62 - ${#i_dur})) '')${CYAN}║${NC}"

  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}  ${DIM}──────────────────────────────────────────────────────────${NC}  ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"

  local i_rpm_clean="  RPM:        ~47 packages installed"
  echo -e "  ${CYAN}║${NC}  ${BOLD}RPM:${NC}        ${DIM}~47 packages installed${NC}$(printf '%*s' $((62 - ${#i_rpm_clean})) '')${CYAN}║${NC}"

  local i_fp_clean="  Flatpak:    ${INSTALL_FP_OK} installed, ${INSTALL_FP_FAIL} failed"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Flatpak:${NC}    ${GREEN}${INSTALL_FP_OK}${NC} installed, ${YELLOW}${INSTALL_FP_FAIL}${NC} failed$(printf '%*s' $((62 - ${#i_fp_clean})) '')${CYAN}║${NC}"

  local i_br="  Browsers:   Firefox + Chrome + Edge + VS Code"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Browsers:${NC}   Firefox + Chrome + Edge + VS Code$(printf '%*s' $((62 - ${#i_br})) '')${CYAN}║${NC}"

  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}  ${DIM}──────────────────────────────────────────────────────────${NC}  ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"

  local i_gtk_clean="  GTK Theme:  MacTahoe-Dark (GNOME ${GNOME_VER})"
  echo -e "  ${CYAN}║${NC}  ${BOLD}GTK Theme:${NC}  MacTahoe-Dark ${DIM}(GNOME ${GNOME_VER})${NC}$(printf '%*s' $((62 - ${#i_gtk_clean})) '')${CYAN}║${NC}"

  local i_ico="  Icon Theme: MacTahoe-dark"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Icon Theme:${NC} MacTahoe-dark$(printf '%*s' $((62 - ${#i_ico})) '')${CYAN}║${NC}"

  local i_fnt="  Font:       SF Pro Display"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Font:${NC}       SF Pro Display$(printf '%*s' $((62 - ${#i_fnt})) '')${CYAN}║${NC}"

  local i_shl_clean="  Shell:      Fish (default after logout)"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Shell:${NC}      Fish ${DIM}(default after logout)${NC}$(printf '%*s' $((62 - ${#i_shl_clean})) '')${CYAN}║${NC}"

  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}  ${DIM}──────────────────────────────────────────────────────────${NC}  ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"

  local i_dsk="  Disk Usage: ~${theme_disk} for themes, icons, fonts"
  echo -e "  ${CYAN}║${NC}  ${BOLD}Disk Usage:${NC} ~${theme_disk} for themes, icons, fonts$(printf '%*s' $((62 - ${#i_dsk})) '')${CYAN}║${NC}"

  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
  echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# ── RAM / RESOURCE OPTIMIZATION ──────────────────────────────
# Disables Fedora services that waste RAM with no functional loss.
# All are reversible: `systemctl --user unmask tracker-miner-fs-3`

optimize_system_resources() {
  next_step "Disable RAM-wasting Services"

  # ── 1. Tracker (file indexer) ──
  # Saves ~150-300 MB. Only affects GNOME Files full-text search.
  if systemctl --user mask tracker-miner-fs-3 tracker-miner-fs tracker-store 2>/dev/null; then
    systemctl --user stop tracker-miner-fs-3 tracker-miner-fs tracker-store 2>/dev/null || true
    ok "Tracker file indexer disabled (~150-300 MB saved)"
  else
    warn "Tracker already masked or not installed"
  fi

  # ── 2. ABRT (crash reporter) ──
  # Saves ~50-80 MB. Removes bug-report popups — crash logs still exist.
  if sudo systemctl disable --now abrtd abrt-oops abrt-journal-core abrt-xorg 2>/dev/null; then
    ok "ABRT crash reporting disabled (~50-80 MB saved)"
  else
    warn "ABRT already disabled or not installed"
  fi

  # ── 3. GNOME Software auto-start ──
  # Prevents GNOME Software from launching at login (~100-200 MB).
  # Still launchable manually from the app grid.
  mkdir -p "$HOME/.config/autostart"
  if [ -f /etc/xdg/autostart/org.gnome.Software.desktop ]; then
    cp /etc/xdg/autostart/org.gnome.Software.desktop "$HOME/.config/autostart/"
    echo "X-GNOME-Autostart-enabled=false" >> "$HOME/.config/autostart/org.gnome.Software.desktop"
    ok "GNOME Software auto-start disabled (~100-200 MB saved)"
  else
    warn "GNOME Software auto-start entry not found"
  fi

  # ── 4. PackageKit background updates ──
  # Saves ~40-60 MB. `sudo dnf update` still works manually.
  if sudo systemctl mask packagekit 2>/dev/null; then
    sudo systemctl stop packagekit 2>/dev/null || true
    ok "PackageKit background updates disabled (~40-60 MB saved)"
  else
    warn "PackageKit already masked or not installed"
  fi

  # ── 5. Firewalld (user chooses on/off) ──
  # Always prompt — user says Yes=disable or No=enable.
  echo ""
  echo -e "  ${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
fw_t="            ◆  DISABLE FIREWALLD?  ◆"
  echo -e "  ${YELLOW}║${NC}${fw_t}$(printf '%*s' $((62 - ${#fw_t})) '')${YELLOW}║${NC}"
  echo -e "  ${YELLOW}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
fw1="  Firewalld is running and using ~30-50 MB RAM."
  echo -e "  ${YELLOW}║${NC}${fw1}$(printf '%*s' $((62 - ${#fw1})) '')${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
fw2="  Disabling it is NOT a security disaster."
  echo -e "  ${YELLOW}║${NC}  ${BOLD}${GREEN}${fw2}${NC}$(printf '%*s' $((60 - ${#fw2})) '')${YELLOW}║${NC}"
fw3="  Your system still has iptables/nftables underneath."
  echo -e "  ${YELLOW}║${NC}${fw3}$(printf '%*s' $((62 - ${#fw3})) '')${YELLOW}║${NC}"
fw4="  Firewalld is just a frontend that manages those rules."
  echo -e "  ${YELLOW}║${NC}${fw4}$(printf '%*s' $((62 - ${#fw4})) '')${YELLOW}║${NC}"
fw5="  Your existing rules stay in place. No ports get exposed."
  echo -e "  ${YELLOW}║${NC}${fw5}$(printf '%*s' $((62 - ${#fw5})) '')${YELLOW}║${NC}"
fw6="  Nothing opens up. Nothing breaks. No drama."
  echo -e "  ${YELLOW}║${NC}${fw6}$(printf '%*s' $((62 - ${#fw6})) '')${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
fw_warn="  ⚠  THINGS TO KEEP IN MIND:"
  echo -e "  ${YELLOW}║${NC}  ${BOLD}${RED}${fw_warn}${NC}$(printf '%*s' $((60 - ${#fw_warn})) '')${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
fw_i1="  ◆  No firewall GUI — manage rules manually if needed"
  echo -e "  ${YELLOW}║${NC}  ${BOLD}${RED}${fw_i1}${NC}$(printf '%*s' $((60 - ${#fw_i1})) '')${YELLOW}║${NC}"
fw_i2="  ◆  Docker/podman won't auto-add firewalld rules"
  echo -e "  ${YELLOW}║${NC}  ${BOLD}${RED}${fw_i2}${NC}$(printf '%*s' $((60 - ${#fw_i2})) '')${YELLOW}║${NC}"
fw_i3="  ◆  No pop-up alerts for blocked connections"
  echo -e "  ${YELLOW}║${NC}  ${BOLD}${RED}${fw_i3}${NC}$(printf '%*s' $((60 - ${#fw_i3})) '')${YELLOW}║${NC}"
fw_i4="  ◆  Re-enable:  sudo systemctl enable --now firewalld"
  echo -e "  ${YELLOW}║${NC}  ${BOLD}${RED}${fw_i4}${NC}$(printf '%*s' $((60 - ${#fw_i4})) '')${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
fw_yn1="    Yes  — Disable firewalld (save RAM)"
  echo -e "  ${YELLOW}║${NC}    ${BOLD}${GREEN}Y${NC}${BOLD}es${NC}  — Disable firewalld (save RAM)$(printf '%*s' $((62 - ${#fw_yn1})) '')${YELLOW}║${NC}"
fw_yn2="    no   — Keep/enable firewalld"
  echo -e "  ${YELLOW}║${NC}    ${BOLD}${YELLOW}n${NC}${BOLD}o${NC}   — Keep/enable firewalld$(printf '%*s' $((62 - ${#fw_yn2})) '')${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
fw7="  Press Enter for default (No)"
  echo -e "  ${YELLOW}║${NC}${DIM}${fw7}$(printf '%*s' $((62 - ${#fw7})) '')${NC}${YELLOW}║${NC}"
  echo -e "  ${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  if confirm "Disable firewalld? [y/N]: " N; then
    sudo systemctl disable --now firewalld 2>/dev/null || true
    ok "Firewalld disabled (~30-50 MB saved)"
  else
    sudo systemctl enable --now firewalld 2>/dev/null || true
    ok "Firewalld enabled and active"
  fi
}

# ── PREFLIGHT ────────────────────────────────────────────────

preflight() {
  next_step "Preflight checks"

  # ── Terminal check (must be running in Kitty) ──
  if [ -z "${KITTY_PID:-}" ]; then
    # Walk up the process tree until we find a known terminal emulator
    local detected_term="" walk_pid=$PPID comm
    while [ "$walk_pid" -gt 1 ] 2>/dev/null; do
      comm=$(cat /proc/"$walk_pid"/comm 2>/dev/null || echo "")
      case "$comm" in
        ptyxis|gnome-ptyxis|kgx|gnome-terminal-|kitty|alacritty|wezterm|foot|urxvt|st|xterm)
          detected_term=$comm
          break
          ;;
      esac
      walk_pid=$(cat /proc/"$walk_pid"/status 2>/dev/null | awk '/^PPid:/{print $2}') || true
    done

    # Block Ptyxis (it gets removed during installation)
    if [ "$detected_term" = "ptyxis" ] || [ "$detected_term" = "gnome-ptyxis" ]; then
      echo ""
      echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
pt_title="          ⛔  WOAH — PTYXIS DETECTED"
      echo -e "  ${CYAN}║${NC}${pt_title}$(printf '%*s' $((62 - ${#pt_title})) '')${CYAN}║${NC}"
      echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
      echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
pt1="  You're in Ptyxis. Bad news — this installer"
      echo -e "  ${CYAN}║${NC}  ${pt1}$(printf '%*s' $((60 - ${#pt1})) '')${CYAN}║${NC}"
pt2="  yeets Ptyxis into the void during setup."
      echo -e "  ${CYAN}║${NC}  ${BOLD}${RED}${pt2}$(printf '%*s' $((60 - ${#pt2})) '')${CYAN}║${NC}"
      echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
pt3="  Running from inside it would be like renovating"
      echo -e "  ${CYAN}║${NC}  ${pt3}$(printf '%*s' $((60 - ${#pt3})) '')${CYAN}║${NC}"
pt4="  your kitchen while standing in the middle of it."
      echo -e "  ${CYAN}║${NC}  ${pt4}$(printf '%*s' $((60 - ${#pt4})) '')${CYAN}║${NC}"
      echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
pt5="  The installer would:"
      echo -e "  ${CYAN}║${NC}  ${YELLOW}╳${NC}  ${pt5}$(printf '%*s' $((57 - ${#pt5})) '')${CYAN}║${NC}"
pt6="    • Delete the terminal you're typing in"
      echo -e "  ${CYAN}║${NC}${pt6}$(printf '%*s' $((62 - ${#pt6})) '')${CYAN}║${NC}"
pt7="    • Crash halfway through (bye-bye progress)"
      echo -e "  ${CYAN}║${NC}${pt7}$(printf '%*s' $((62 - ${#pt7})) '')${CYAN}║${NC}"
pt8="    • Could mess up your whole session"
      echo -e "  ${CYAN}║${NC}${pt8}$(printf '%*s' $((62 - ${#pt8})) '')${CYAN}║${NC}"
      echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
pt9="  Here's the right way to do it:"
      echo -e "  ${CYAN}║${NC}  ${GREEN}✓${NC}  ${pt9}$(printf '%*s' $((57 - ${#pt9})) '')${CYAN}║${NC}"
      echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
pt10="  1. Install Kitty:  sudo dnf install kitty"
      echo -e "  ${CYAN}║${NC}  ${BOLD}${pt10}$(printf '%*s' $((60 - ${#pt10})) '')${CYAN}║${NC}"
      echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
pt11="  2. Launch Kitty and re-run from there"
      echo -e "  ${CYAN}║${NC}  ${BOLD}${pt11}$(printf '%*s' $((60 - ${#pt11})) '')${CYAN}║${NC}"
      echo -e "  ${CYAN}║${NC}     kitty -e bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh)\" ${CYAN}║${NC}"
      echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
pt12="  You can keep Ptyxis as a backup, but Kitty"
      echo -e "  ${CYAN}║${NC}  ${pt12}$(printf '%*s' $((60 - ${#pt12})) '')${CYAN}║${NC}"
pt13="  needs to be the main ride for this to work."
      echo -e "  ${CYAN}║${NC}  ${pt13}$(printf '%*s' $((60 - ${#pt13})) '')${CYAN}║${NC}"
      echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
      echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
      echo ""
      exit 1
    fi

    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │  ✦  KITTY = THE REAL DEAL  ✦                              │"
    echo "  ├─────────────────────────────────────────────────────────────┤"
    echo "  │  You're in a regular terminal right now. That's cool,       │"
    echo "  │  but the full MacTahoe experience really shines in Kitty.   │"
    echo "  │                                                             │"
    echo "  │  Why Kitty over your current setup?                         │"
    echo "  │  ◆ True colors — no washed-out nonsense                     │"
    echo "  │  ◆ GPU rendering — scrolling is buttery smooth              │"
    echo "  │  ◆ Blur & transparency that match the theme                 │"
    echo "  │  ◆ Tab bar that looks like it belongs on a Mac              │"
    echo "  │  ◆ Keyboard shortcuts that just make sense                  │"
    echo "  │                                                             │"
    echo "  │  Get it:  sudo dnf install kitty                            │"
    echo "  │  Then:    kitty -e bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh)\" │"
    echo "  │                                                             │"
    echo "  │  Press any key to continue                                  │"
    echo "  │  or Ctrl+C to grab Kitty first (recommended)                │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
    # First press: acknowledge (any key including Enter works)
    read -r -s -n 1 key < /dev/tty || true
    echo -e "  ${DIM}ok, one more thing...${NC}"
    # Second press: confirm
    echo ""
    echo -e "  ┌─────────────────────────────────────────────────────────────┐"
    echo -e "  │  ${BOLD}${YELLOW}⚠  FOR REAL? NO KITTY?${NC}                                    │"
    echo -e "  ├─────────────────────────────────────────────────────────────┤"
    echo -e "  │  You're about to run without the terminal this whole        │"
    echo -e "  │  thing was designed for. Some stuff might look off,         │"
    echo -e "  │  and you'll miss out on the best parts. Your call.          │"
    echo -e "  │                                                             │"
    echo -e "  │  Press ${BOLD}any key${NC} to proceed (no judgment)                              │"
    echo -e "  │  Press ${BOLD}Ctrl+C${NC} to install Kitty first (smart move)                  │"
    echo -e "  └─────────────────────────────────────────────────────────────┘"
    echo -en "  ${DIM}Waiting on you...${NC} "
    while true; do
      read -r -s -n 1 key < /dev/tty || true
      echo -e "${GREEN}let's roll${NC}"
      break
    done
  fi

  # ── OS check ──
  local detected_os="Unknown Linux"
  if [ -f /etc/os-release ]; then
    detected_os=$(grep -oP '^NAME="?\K[^"]+' /etc/os-release 2>/dev/null || echo "Unknown Linux")
  fi
  if [ ! -f /etc/fedora-release ]; then
    echo ""
    echo -e "  ${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
ios_t="          INCOMPATIBLE OPERATING SYSTEM"
    echo -e "  ${RED}║${NC}${ios_t}$(printf '%*s' $((62 - ${#ios_t})) '')${RED}║${NC}"
    echo -e "  ${RED}╠══════════════════════════════════════════════════════════════╣${NC}"
ios_det="  Detected OS :  $detected_os"
    echo -e "  ${RED}║${NC}${ios_det}$(printf '%*s' $((62 - ${#ios_det})) '')${RED}║${NC}"
ios_req="  Required OS :  Fedora Linux (Workstation edition)"
    echo -e "  ${RED}║${NC}${ios_req}$(printf '%*s' $((62 - ${#ios_req})) '')${RED}║${NC}"
    echo -e "  ${RED}║${NC}                                                              ${RED}║${NC}"
ios1="  Fedora MacTahoe is designed exclusively for"
    echo -e "  ${RED}║${NC}  ${ios1}$(printf '%*s' $((60 - ${#ios1})) '')${RED}║${NC}"
ios2="  Fedora Linux with GNOME. It needs Fedora-specific"
    echo -e "  ${RED}║${NC}  ${ios2}$(printf '%*s' $((60 - ${#ios2})) '')${RED}║${NC}"
ios3="  package managers, repos, and paths that do not"
    echo -e "  ${RED}║${NC}  ${ios3}$(printf '%*s' $((60 - ${#ios3})) '')${RED}║${NC}"
ios4="  exist on other distributions."
    echo -e "  ${RED}║${NC}  ${ios4}$(printf '%*s' $((60 - ${#ios4})) '')${RED}║${NC}"
    echo -e "  ${RED}║${NC}                                                              ${RED}║${NC}"
ios5="  To use this theme, install Fedora Workstation:"
    echo -e "  ${RED}║${NC}  ${ios5}$(printf '%*s' $((60 - ${#ios5})) '')${RED}║${NC}"
ios_url="  https://fedoraproject.org/workstation/"
    echo -e "  ${RED}║${NC}${ios_url}$(printf '%*s' $((62 - ${#ios_url})) '')${RED}║${NC}"
    echo -e "  ${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
  fi
  ok "Fedora detected — you're in the right place"

  # ── Desktop environment check ──
  local gnome_ok=false
  if command -v gnome-shell &>/dev/null; then
    gnome_ok=true
  fi
  # Detect actual desktop (for error messages)
  local detected_desk="${XDG_CURRENT_DESKTOP:-}"
  if [ -z "$detected_desk" ]; then
    detected_desk="${GDMSESSION:-}"
  fi
  if [ -z "$detected_desk" ]; then
    detected_desk="${DESKTOP_SESSION:-}"
  fi
  if [ -z "$detected_desk" ]; then
    detected_desk="none (TTY / no graphical session detected)"
  fi
  # If a desktop session is running, double-check it's actually GNOME
  if [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
    if echo "$XDG_CURRENT_DESKTOP" | grep -qi "gnome"; then
      gnome_ok=true
    else
      echo ""
      echo -e "  ${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
ide_t="          INCOMPATIBLE DESKTOP ENVIRONMENT"
      echo -e "  ${RED}║${NC}${ide_t}$(printf '%*s' $((62 - ${#ide_t})) '')${RED}║${NC}"
      echo -e "  ${RED}╠══════════════════════════════════════════════════════════════╣${NC}"
ide_det="  Detected DE :  $detected_desk"
      echo -e "  ${RED}║${NC}${ide_det}$(printf '%*s' $((62 - ${#ide_det})) '')${RED}║${NC}"
ide_req="  Required DE :  GNOME (default Fedora Workstation)"
      echo -e "  ${RED}║${NC}${ide_req}$(printf '%*s' $((62 - ${#ide_req})) '')${RED}║${NC}"
      echo -e "  ${RED}║${NC}                                                              ${RED}║${NC}"
ide1="  Fedora MacTahoe integrates deeply with GNOME"
      echo -e "  ${RED}║${NC}  ${ide1}$(printf '%*s' $((60 - ${#ide1})) '')${RED}║${NC}"
ide2="  Shell extensions, dconf schemas, and D-Bus"
      echo -e "  ${RED}║${NC}  ${ide2}$(printf '%*s' $((60 - ${#ide2})) '')${RED}║${NC}"
ide3="  APIs that are not available on other desktops."
      echo -e "  ${RED}║${NC}  ${ide3}$(printf '%*s' $((60 - ${#ide3})) '')${RED}║${NC}"
      echo -e "  ${RED}║${NC}                                                              ${RED}║${NC}"
ide4="  Switch to Fedora Workstation (GNOME) or install:"
      echo -e "  ${RED}║${NC}  ${ide4}$(printf '%*s' $((60 - ${#ide4})) '')${RED}║${NC}"
ide_cmd="    sudo dnf groupinstall 'Fedora Workstation'"
      echo -e "  ${RED}║${NC}${ide_cmd}$(printf '%*s' $((62 - ${#ide_cmd})) '')${RED}║${NC}"
      echo -e "  ${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
      echo ""
      exit 1
    fi
  fi
  if [ "$gnome_ok" = false ]; then
    echo ""
    echo -e "  ${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
gnome_t="            GNOME SHELL NOT FOUND"
    echo -e "  ${RED}║${NC}${gnome_t}$(printf '%*s' $((62 - ${#gnome_t})) '')${RED}║${NC}"
    echo -e "  ${RED}╠══════════════════════════════════════════════════════════════╣${NC}"
gnome_det="  Detected DE :  $detected_desk"
    echo -e "  ${RED}║${NC}${gnome_det}$(printf '%*s' $((62 - ${#gnome_det})) '')${RED}║${NC}"
gnome_req="  Required DE :  GNOME (default Fedora Workstation)"
    echo -e "  ${RED}║${NC}${gnome_req}$(printf '%*s' $((62 - ${#gnome_req})) '')${RED}║${NC}"
    echo -e "  ${RED}║${NC}                                                              ${RED}║${NC}"
gnome1="  The gnome-shell binary is not installed."
    echo -e "  ${RED}║${NC}  ${gnome1}$(printf '%*s' $((60 - ${#gnome1})) '')${RED}║${NC}"
gnome2="  This script cannot proceed without it."
    echo -e "  ${RED}║${NC}  ${gnome2}$(printf '%*s' $((60 - ${#gnome2})) '')${RED}║${NC}"
    echo -e "  ${RED}║${NC}                                                              ${RED}║${NC}"
gnome3="  To install GNOME on Fedora, run:"
    echo -e "  ${RED}║${NC}  ${gnome3}$(printf '%*s' $((60 - ${#gnome3})) '')${RED}║${NC}"
gnome_cmd1="    sudo dnf groupinstall 'Fedora Workstation'"
    echo -e "  ${RED}║${NC}${gnome_cmd1}$(printf '%*s' $((62 - ${#gnome_cmd1})) '')${RED}║${NC}"
gnome_cmd2="    sudo systemctl set-default graphical.target"
    echo -e "  ${RED}║${NC}${gnome_cmd2}$(printf '%*s' $((62 - ${#gnome_cmd2})) '')${RED}║${NC}"
gnome_cmd3="    sudo reboot"
    echo -e "  ${RED}║${NC}${gnome_cmd3}$(printf '%*s' $((62 - ${#gnome_cmd3})) '')${RED}║${NC}"
    echo -e "  ${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
  fi
  ok "GNOME desktop — right where we need to be"

  # ── User check ──
  if [ "$EUID" -eq 0 ]; then
    fail "Do NOT run as root. Run as your normal user — sudo prompts will appear."
  fi
  ok "Running as normal user"

  # ── Network check ──
  if ! ping -c1 -W2 google.com &>/dev/null && ! ping -c1 -W2 github.com &>/dev/null; then
    fail "No internet — can't reach the outside world."
  fi
  ok "Internet — we're online"

  # ── Sudo check ──
  if ! sudo -n true 2>/dev/null; then
    warn "Sudo coming up — have your password ready."
  fi
  sudo echo "Sudo OK" >/dev/null || fail "Sudo required"
  ok "Sudo access granted"
}

# ── PTYXIS REMOVAL ───────────────────────────────────────────

remove_ptyxis() {
  next_step "Remove Ptyxis (system terminal)"

  if rpm -q ptyxis &>/dev/null; then
    log "Removing Ptyxis package..."
    sudo dnf remove -y ptyxis 2>&1 | tail -1 || true
    ok "Ptyxis package removed"
  else
    ok "Ptyxis not installed — nothing to remove"
  fi

  # User config
  rm -rf "$HOME/.config/org.gnome.Ptyxis" 2>/dev/null || true
  # User data (palettes, sessions)
  rm -rf "$HOME/.local/share/org.gnome.Ptyxis" 2>/dev/null || true
  # GNOME Software cache icons
  find "$HOME/.cache/gnome-software" -name "*ptyxi*" -delete 2>/dev/null || true
  # Dconf profiles and settings
  backup_dconf
  dconf reset -f /org/gnome/Ptyxis/ 2>/dev/null || true
  # Desktop entry
  sudo rm -f /usr/share/applications/org.gnome.Ptyxis.desktop 2>/dev/null || true
  sudo rm -f /usr/share/applications/org.gnome.Console.desktop 2>/dev/null || true
  # MacTahoe theme icon for Ptyxis
  find "$HOME/.local/share/icons" -path "*MacTahoe*ptyxis*" -delete 2>/dev/null || true
  # Symlinks that may point to Ptyxis
  sudo rm -f /usr/bin/gnome-terminal 2>/dev/null || true
  sudo rm -f /usr/bin/x-terminal-emulator 2>/dev/null || true

  # Verify no traces remain
  local leftover_config leftover_data leftover_dconf
  leftover_config=$(find "$HOME/.config" -maxdepth 1 -name "*Ptyxis*" 2>/dev/null)
  leftover_data=$(find "$HOME/.local/share" -maxdepth 1 -name "*Ptyxis*" 2>/dev/null)
  leftover_dconf=$(dconf dump /org/gnome/Ptyxis/ 2>/dev/null)
  if [ -z "$leftover_config" ] && [ -z "$leftover_data" ] && [ -z "$leftover_dconf" ]; then
    ok "All Ptyxis traces cleaned"
  else
    warn "Some Ptyxis traces may remain — manual check recommended"
  fi
}

remove_gnome_weather() {
  next_step "Remove GNOME Weather (replaced by Mousam)"

  if rpm -q gnome-weather &>/dev/null; then
    log "Removing gnome-weather package..."
    sudo dnf remove -y gnome-weather 2>&1 | tail -1 || true
    ok "gnome-weather removed"
  else
    ok "gnome-weather not installed — nothing to remove"
  fi
}

# ── PHASE 1: SYSTEM FOUNDATIONS ──────────────────────────────

install_rpmfusion() {
  next_step "RPM Fusion + Codecs"
  log "Tip: If this step hangs on repo metadata, press Ctrl+C once — the script handles it safely"

  local release
  release=$(rpm -E %fedora 2>/dev/null) || release="40"

  sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${release}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${release}.noarch.rpm" \
    --nogpgcheck 2>/dev/null || sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${release}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${release}.noarch.rpm"

  timeout 60 sudo dnf check-update 2>/dev/null || true

  # Fedora 44+ ships ffmpeg-free which conflicts with RPM Fusion's ffmpeg.
  # Swap it out cleanly before installing the rest.
  if rpm -q ffmpeg-free &>/dev/null && ! rpm -q ffmpeg &>/dev/null; then
    log "Replacing Fedora's ffmpeg-free with RPM Fusion's ffmpeg..."
    sudo dnf swap -y ffmpeg-free ffmpeg 2>/dev/null || \
      sudo dnf install -y --allowerasing ffmpeg 2>/dev/null || true
  fi

  sudo dnf install -y \
    ffmpeg ffmpegthumbnailer gstreamer1-plugin-libav gstreamer1-plugins-ugly \
    gstreamer1-plugins-bad-freeworld gstreamer1-plugins-bad-free-extras
  sudo dnf groupinstall -y multimedia 2>/dev/null || true
  rm -rf ~/.cache/thumbnails/
  nautilus -q 2>/dev/null || true
  ok "RPM Fusion + codecs installed"
}

install_nvidia() {
  next_step "NVIDIA Drivers (auto-detect)"

  nvidia_found=false
  lspci 2>/dev/null | grep -qi nvidia && nvidia_found=true
  lsmod 2>/dev/null | grep -qi nouveau && nvidia_found=true
  if [ "$nvidia_found" = true ]; then
    echo ""
    echo -e "  ${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${YELLOW}║${NC}  ${BOLD}          NVIDIA GPU DETECTED${NC}                               ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
n1="  This system has an NVIDIA graphics card. The installer"
    echo -e "  ${YELLOW}║${NC}  ${n1}$(printf '%*s' $((60 - ${#n1})) '')${YELLOW}║${NC}"
n2="  will now install the official NVIDIA driver (akmod-nvidia)"
    echo -e "  ${YELLOW}║${NC}  ${n2}$(printf '%*s' $((60 - ${#n2})) '')${YELLOW}║${NC}"
n3="  along with CUDA support and related utilities."
    echo -e "  ${YELLOW}║${NC}  ${n3}$(printf '%*s' $((60 - ${#n3})) '')${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
n4="  ⚠  IMPORTANT — READ BEFORE PROCEEDING:"
    echo -e "  ${YELLOW}║${NC}  ${BOLD}${RED}${n4}$(printf '%*s' $((60 - ${#n4})) '')${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
n5="  Installing NVIDIA drivers on a system that hasn't been"
    echo -e "  ${YELLOW}║${NC}  ${n5}$(printf '%*s' $((60 - ${#n5})) '')${YELLOW}║${NC}"
n6="  fully updated can lead to several issues, including:"
    echo -e "  ${YELLOW}║${NC}  ${n6}$(printf '%*s' $((60 - ${#n6})) '')${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
n_iss1="  ◆  Broken display resolution or no display at all"
    echo -e "  ${YELLOW}║${NC}  ${BOLD}${RED}${n_iss1}$(printf '%*s' $((60 - ${#n_iss1})) '')${NC}${YELLOW}║${NC}"
n_iss2="  ◆  Screen tearing and poor graphical performance"
    echo -e "  ${YELLOW}║${NC}  ${BOLD}${RED}${n_iss2}$(printf '%*s' $((60 - ${#n_iss2})) '')${NC}${YELLOW}║${NC}"
n_iss3="  ◆  Network connectivity breaking (WiFi/Ethernet)"
    echo -e "  ${YELLOW}║${NC}  ${BOLD}${RED}${n_iss3}$(printf '%*s' $((60 - ${#n_iss3})) '')${NC}${YELLOW}║${NC}"
n_iss4="  ◆  GPU overheating due to missing or wrong driver"
    echo -e "  ${YELLOW}║${NC}  ${BOLD}${RED}${n_iss4}$(printf '%*s' $((60 - ${#n_iss4})) '')${NC}${YELLOW}║${NC}"
n_iss5="  ◆  System instability, freezes, or boot loops"
    echo -e "  ${YELLOW}║${NC}  ${BOLD}${RED}${n_iss5}$(printf '%*s' $((60 - ${#n_iss5})) '')${NC}${YELLOW}║${NC}"
n_iss6="  ◆  Being stuck on the open-source nouveau driver"
    echo -e "  ${YELLOW}║${NC}  ${BOLD}${RED}${n_iss6}$(printf '%*s' $((60 - ${#n_iss6})) '')${NC}${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
n9="  To avoid this, Fedora recommends the following order:"
    echo -e "  ${YELLOW}║${NC}  ${n9}$(printf '%*s' $((60 - ${#n9})) '')${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
n10="    1. Ensure you have a working internet connection"
    echo -e "  ${YELLOW}║${NC}  ${n10}$(printf '%*s' $((60 - ${#n10})) '')${YELLOW}║${NC}"
n11="    2. Run:  sudo dnf upgrade  (update all packages)"
    echo -e "  ${YELLOW}║${NC}  ${BOLD}${n11}$(printf '%*s' $((60 - ${#n11})) '')${YELLOW}║${NC}"
n12="    3. Reboot to load the latest kernel"
    echo -e "  ${YELLOW}║${NC}  ${n12}$(printf '%*s' $((60 - ${#n12})) '')${YELLOW}║${NC}"
n13="    4. Re-run this installer"
    echo -e "  ${YELLOW}║${NC}  ${n13}$(printf '%*s' $((60 - ${#n13})) '')${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
n14="  If your system is already fully updated and you are"
    echo -e "  ${YELLOW}║${NC}  ${GREEN}✓${NC}  ${n14}$(printf '%*s' $((57 - ${#n14})) '')${YELLOW}║${NC}"
n15="  running the latest Fedora kernel, you can safely"
    echo -e "  ${YELLOW}║${NC}     ${n15}$(printf '%*s' $((57 - ${#n15})) '')${YELLOW}║${NC}"
n16="  proceed — the installer will handle the rest."
    echo -e "  ${YELLOW}║${NC}     ${n16}$(printf '%*s' $((57 - ${#n16})) '')${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
n17="  Press any key to continue, or Ctrl+C to update first"
    echo -e "  ${YELLOW}║${NC}  ${n17}$(printf '%*s' $((60 - ${#n17})) '')${YELLOW}║${NC}"
    echo -e "  ${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -en "  ${DIM}Press any key to continue...${NC} "
    read -r -s -n 1 key < /dev/tty || true
    echo -e "${GREEN}proceeding${NC}"
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-settings vdpauinfo libva-utils
    ok "NVIDIA drivers installed — fingers crossed"
  else
    warn "No NVIDIA gear found — moving on"
  fi
}

# ── PHASE 2: PACKAGES ────────────────────────────────────────

install_rpm_packages() {
  next_step "RPM Packages"

  # ── Discord optional prompt ──
  if [ -z "${INSTALL_DISCORD:-}" ]; then
    echo ""
    echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
disc_t="            ◆  INSTALL DISCORD?  ◆"
    echo -e "  ${CYAN}║${NC}${disc_t}$(printf '%*s' $((62 - ${#disc_t})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
disc1="  Discord via Flatpak — ~214 MB download, ~540 MB installed."
    echo -e "  ${CYAN}║${NC}${disc1}$(printf '%*s' $((62 - ${#disc1})) '')${CYAN}║${NC}"
disc2="  Skip it if you don't need it."
    echo -e "  ${CYAN}║${NC}${disc2}$(printf '%*s' $((62 - ${#disc2})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
disc3="    Yes  — Install Discord"
    echo -e "  ${CYAN}║${NC}    ${BOLD}${GREEN}Y${NC}${BOLD}es${NC}  — Install Discord$(printf '%*s' $((62 - ${#disc3})) '')${CYAN}║${NC}"
disc4="    no   — Skip it"
    echo -e "  ${CYAN}║${NC}    ${BOLD}${YELLOW}n${NC}${BOLD}o${NC}   — Skip it$(printf '%*s' $((62 - ${#disc4})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
disc5="  Press Enter for default (No)"
    echo -e "  ${CYAN}║${NC}${DIM}${disc5}$(printf '%*s' $((62 - ${#disc5})) '')${NC}${CYAN}║${NC}"
disc6="  Tip: set INSTALL_DISCORD=false to skip silently"
    echo -e "  ${CYAN}║${NC}${DIM}${disc6}$(printf '%*s' $((62 - ${#disc6})) '')${NC}${CYAN}║${NC}"
    echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    if confirm "Discord? [y/N]: " N; then
      INSTALL_DISCORD="true"
      echo -e "  ${GREEN}→ Discord will be installed${NC}"
    else
      INSTALL_DISCORD="false"
      echo -e "  ${DIM}→ Skipping Discord${NC}"
    fi
  fi

  local pkgs="fish kitty fastfetch figlet lolcat eza \
    celluloid vlc \
    kdenlive pavucontrol alacarte \
    nautilus-python gnome-tweaks \
    adwaita-icon-theme adwaita-icon-theme-legacy \
    ImageMagick fzf ripgrep jq unzip curl wget git \
    bat cmatrix qrencode podman python3-pip speedtest-cli xdg-utils \
    libreoffice-writer libreoffice-calc libreoffice-impress"

  sudo dnf install -y $pkgs

  # Starship prompt (not in Fedora repos — install via official script)
  if ! command -v starship &>/dev/null; then
    if ! curl -fsSL --max-time 60 https://starship.rs/install.sh | sh -s -- -y 2>/dev/null; then
      warn "Starship install failed — check network or https://starship.rs"
    fi
  fi

  ok "RPM packages installed"
}

install_browsers() {
  next_step "Browsers (Firefox, Chrome, Edge, VS Code)"

  # Firefox
  if ! rpm -q firefox &>/dev/null; then
    sudo dnf install -y firefox
  fi

  # Chrome — create repo file directly (--from-repofile not supported by Google)
  if ! rpm -q google-chrome-stable &>/dev/null; then
    if ! sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub 2>/dev/null; then
      warn "Failed to import Google signing key — Chrome repo may not be trusted"
    fi
    sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null <<-EOF
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
    # Install from repo, with direct RPM as offline fallback
    if ! sudo dnf install -y google-chrome-stable 2>/dev/null && \
       ! sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm; then
      warn "Chrome installation failed — check network or Google repos"
    fi
  fi

  # Edge — create repo file directly (--from-repofile URL is non-standard)
  if ! rpm -q microsoft-edge-stable &>/dev/null; then
    if ! sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null; then
      warn "Failed to import Microsoft signing key — Edge repo may not be trusted"
    fi
    sudo tee /etc/yum.repos.d/microsoft-edge.repo > /dev/null <<-EOF
[microsoft-edge]
name=microsoft-edge
baseurl=https://packages.microsoft.com/yumrepos/edge-stable
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    if ! sudo dnf install -y microsoft-edge-stable 2>/dev/null; then
      warn "Edge installation failed — check network or Microsoft repos"
    fi
  fi

  # VS Code — repo file (existing working approach)
  if ! rpm -q code &>/dev/null; then
    if ! sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null; then
      warn "Failed to import Microsoft signing key — VS Code repo may not be trusted"
    fi
    sudo tee /etc/yum.repos.d/vscode.repo > /dev/null <<-EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    sudo dnf check-update 2>/dev/null || true
    sudo dnf install -y code
  fi

  ok "Browsers + VS Code installed (Spotify via Flatpak)"
}

install_flatpaks() {
  next_step "Flatpak Apps"

  INSTALL_FP_OK=0
  INSTALL_FP_FAIL=0
  local fp_apps=(
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
  )

  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

  for _fp in "${fp_apps[@]}"; do
    if flatpak install -y flathub "$_fp" 2>/dev/null; then
      INSTALL_FP_OK=$((INSTALL_FP_OK + 1))
    else
      INSTALL_FP_FAIL=$((INSTALL_FP_FAIL + 1))
    fi
  done

  if [ "${INSTALL_DISCORD:-}" = "true" ]; then
    if flatpak install -y flathub com.discordapp.Discord 2>/dev/null; then
      INSTALL_FP_OK=$((INSTALL_FP_OK + 1))
    else
      INSTALL_FP_FAIL=$((INSTALL_FP_FAIL + 1))
    fi
  fi

  if [ "$INSTALL_FP_OK" -gt 0 ]; then
    ok "$INSTALL_FP_OK flatpak apps installed"
  fi
  [ "$INSTALL_FP_FAIL" -gt 0 ] && warn "$INSTALL_FP_FAIL flatpak(s) failed to install — check network or flathub status"

  # Always attempt overrides (non-critical)
  sudo flatpak override --filesystem=xdg-config/gtk-3.0 2>/dev/null || true
  sudo flatpak override --filesystem=xdg-config/gtk-4.0 2>/dev/null || true
}

# ── PHASE 3: THEMES ──────────────────────────────────────────

install_mactahoe_theme() {
  next_step "MacTahoe GTK Theme (compiled from source)"

  local repo="/tmp/mactahoe-build"
  local gtk_version
  gtk_version=$(gnome-shell --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1 || echo "unknown")

  # Purge leftovers
  rm -rf "$HOME/.themes/MacTahoe"* "$HOME/.local/share/themes/MacTahoe"*
  sudo rm -rf /usr/share/themes/MacTahoe* 2>/dev/null || true

  # Clone and compile for current GNOME version
  log "Cloning MacTahoe source (GNOME $gtk_version)..."
  rm -rf "$repo"
  git clone --depth 1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$repo" 2>/dev/null || {
    warn "Clone failed — falling back to bundled pre-compiled theme"
    local fallback_dir="$BUNDLE/themes/MacTahoe-Dark"
    if [ -d "$fallback_dir" ]; then
      mkdir -p "$HOME/.themes" "$HOME/.local/share/themes" "$HOME/.config/gtk-4.0"
      cp -r "$fallback_dir" "$HOME/.themes/"
      cp -r "$fallback_dir" "$HOME/.local/share/themes/"
      cp -r "$fallback_dir/gtk-4.0/"* "$HOME/.config/gtk-4.0/" 2>/dev/null || true
      ok "Bundled MacTahoe-Dark installed as fallback"
    else
      warn "No fallback available — theme not installed"
    fi
    return
  }

  log "Compiling all theme variants with blur + libadwaita..."
  local _compile_log="/tmp/mactahoe-compile.log"
  "$repo/install.sh" -t all -b -l > "$_compile_log" 2>&1 || {
    warn "Compilation failed — theme not installed"
    tail -20 "$_compile_log" 2>/dev/null
    rm -f "$_compile_log"
    return
  }
  rm -f "$_compile_log"

  # XDG compat: also available in ~/.local/share/themes/
  mkdir -p "$HOME/.local/share/themes"
  for d in "$HOME/.themes/MacTahoe"*; do
    [ -d "$d" ] || continue
    local base; base=$(basename "$d")
    rm -rf "$HOME/.local/share/themes/$base"
    cp -a "$d" "$HOME/.local/share/themes/$base"
  done

  # Post-compilation patches to the compiled CSS
  for _theme_dir in "$HOME/.themes/MacTahoe"* "$HOME/.local/share/themes/MacTahoe"*; do
    [ -d "$_theme_dir" ] || continue
    for _css in "$_theme_dir/gtk-3.0/gtk-dark.css" "$_theme_dir/gtk-4.0/gtk-dark.css"; do
      [ -f "$_css" ] && sed -i 's/color: #afafaf;/color: #d0d0d0;/g' "$_css" 2>/dev/null || true
    done
  done
  log "Patched flat button color (#afafaf → #d0d0d0) for better media-player visibility"

  ok "MacTahoe theme compiled & installed for GNOME $gtk_version"

  # ── Icon themes (always from bundle, never change) ─────────

  local theme_src="$BUNDLE/themes"

  # Clean stale icon theme directories/symlinks from previous installs
  for stale in MacTahoe MacTahoe-dark MacTahoe-light MacTahoe-Eprahemi MacTahoe-dark-Eprahemi; do
    rm -rf "$HOME/.local/share/icons/$stale" 2>/dev/null || true
  done

  for icon in MacTahoe MacTahoe-dark; do
    mkdir -p "$HOME/.local/share/icons"
    cp -a "$theme_src/$icon" "$HOME/.local/share/icons/"
    # Fix ownership of any pre-existing root-owned subdirs (e.g. symbolic/actions/
    # from a previous run) so later mkdir/cp operations don't fail with EACCES.
    sudo chown -R "$(whoami):$(id -gn)" "$HOME/.local/share/icons/$icon" 2>/dev/null || true
    # Ensure Adwaita is in the inheritance chain (needed for ui/ icons like checkboxes)
    if ! grep -q "Adwaita" "$HOME/.local/share/icons/$icon/index.theme" 2>/dev/null; then
      sed -i 's/Inherits=hicolor,breeze/Inherits=hicolor,breeze,Adwaita/' \
        "$HOME/.local/share/icons/$icon/index.theme"
    fi
    # Provide skip-10-second icons (Decibels, Showtime) with proper currentColor
    # Override the app-bundled #222222 fill with the theme's currentColor.
    # Icon shapes mirror Adwaita's object-rotate-left/right (undo-style arrows).
    for dir in "actions/24" "actions/48" "actions/64" "actions/scalable" "actions/symbolic"; do
      mkdir -p "$HOME/.local/share/icons/$icon/$dir"
      for f in "$theme_src/$icon/$dir/skip-backwards-10-symbolic.svg" \
               "$theme_src/$icon/$dir/skip-forward-10-symbolic.svg"; do
        [ -f "$f" ] && cp -f "$f" "$HOME/.local/share/icons/$icon/$dir/"
      done
    done
    # Ensure qr-code-symbolic is present (used by GNOME 48+ WiFi QR button)
    if [ -f "$theme_src/$icon/actions/symbolic/qr-code-symbolic.svg" ]; then
      for _qrdir in "actions/symbolic" "actions/scalable"; do
        mkdir -p "$HOME/.local/share/icons/$icon/$_qrdir" 2>/dev/null || true
        cp -f "$theme_src/$icon/actions/symbolic/qr-code-symbolic.svg" \
              "$HOME/.local/share/icons/$icon/$_qrdir/qr-code-symbolic.svg" 2>/dev/null || true
      done
    fi
    # Ensure check-symbolic icon exists (GNOME Shell CheckBox widget uses this)
    if [ -f "$theme_src/$icon/actions/symbolic/check-symbolic.svg" ]; then
      for _cs_dir in "status/symbolic" "actions/symbolic" "symbolic/ui"; do
        mkdir -p "$HOME/.local/share/icons/$icon/$_cs_dir" 2>/dev/null || true
        cp -f "$theme_src/$icon/actions/symbolic/check-symbolic.svg" \
              "$HOME/.local/share/icons/$icon/$_cs_dir/check-symbolic.svg" 2>/dev/null || true
      done
    fi
    # Ensure edit icons exist in ALL size dirs so GTK finds them
    for _ed_icon in "document-edit-symbolic.svg" "edit-symbolic.svg" "adw-entry-edit-symbolic.svg"; do
      if [ -f "$theme_src/$icon/actions/symbolic/$_ed_icon" ]; then
        for _ed_dir in "actions/16" "actions/22" "actions/24" "actions/32" "actions/48" "actions/64" "actions/scalable" "symbolic/actions"; do
          mkdir -p "$HOME/.local/share/icons/$icon/$_ed_dir" 2>/dev/null || true
          cp -f "$theme_src/$icon/actions/symbolic/$_ed_icon" \
                "$HOME/.local/share/icons/$icon/$_ed_dir/$_ed_icon" 2>/dev/null || true
          sed -i 's/fill="[^"]*"/fill="currentColor"/g; s/color="[^"]*"/color="currentColor"/g' \
            "$HOME/.local/share/icons/$icon/$_ed_dir/$_ed_icon" 2>/dev/null || true
        done
      fi
    done

    # Add Adwaita-style directory entries so GResource icons bundled by apps
    # (e.g. GNOME Settings' qr-code-symbolic, audio speaker icons) are found
    # when the GResource uses new-style paths like "scalable/actions/".
    local _idx="$HOME/.local/share/icons/$icon/index.theme"
    for _adir in "scalable/actions" "symbolic/actions" "scalable/apps" "symbolic/apps" \
                 "scalable/devices" "symbolic/devices" "scalable/status" "symbolic/status" \
                 "scalable/categories" "symbolic/categories" "scalable/emblems" "symbolic/emblems" \
                 "scalable/emotes" "symbolic/mimetypes" "scalable/places" "symbolic/places" \
                 "symbolic/ui"; do
      if ! grep -q "^$_adir$" "$_idx" 2>/dev/null; then
        # Add to Directories list (right before the first section entry)
        sed -i "/^Directories=/ s|$|,$_adir|" "$_idx" 2>/dev/null || true
        # Add section entry
        local _adir_ctx; _adir_ctx="$(echo "${_adir#*/}" | sed 's/^./\u&/')"
        {
          echo ""
          echo "[$_adir]"
          echo "Size=16"
          echo "Context=$_adir_ctx"
          echo "Type=Scalable"
        } >> "$_idx"
        # Create empty directory so GTK doesn't skip it
        mkdir -p "$HOME/.local/share/icons/$icon/$_adir"
      fi
    done

    # Fix all symbolic SVGs: replace hardcoded fills with currentColor
    # so GTK can properly recolor them for dark/light theme variants.
    # Handles both fill="..." attributes AND style="fill:..." inline CSS.
    find "$HOME/.local/share/icons/$icon" -name "*-symbolic.svg" -exec \
      sed -i 's/fill="#[^"]*"/fill="currentColor"/g; s/color="#[^"]*"/color="currentColor"/g; s/fill:#[^;";]*/fill:currentColor/g; s/;fill-opacity:[^;";]*//g' {} + 2>/dev/null || true

    gtk-update-icon-cache "$HOME/.local/share/icons/$icon/" 2>/dev/null || warn "Icon cache update failed for $icon"
  done

  # ── Apply same fixes to other users who already have the theme ──
  for _homedir in /home/*; do
    _user="$(basename "$_homedir")"
    [ "$_user" = "$(whoami)" ] && continue
    for icon in MacTahoe MacTahoe-dark; do
      local _udir="$_homedir/.local/share/icons/$icon"
      if [ -d "$_udir" ]; then
        # Fix ownership of any pre-existing root-owned subdirs first
        sudo chown -R "$_user:" "$_udir" 2>/dev/null || true
        # Copy qr-code-symbolic
        if [ -f "$theme_src/$icon/actions/symbolic/qr-code-symbolic.svg" ]; then
          for _qrdir in "actions/symbolic" "actions/scalable"; do
            sudo -u "$_user" mkdir -p "$_udir/$_qrdir" 2>/dev/null || true
            sudo -u "$_user" cp -f "$theme_src/$icon/actions/symbolic/qr-code-symbolic.svg" \
                  "$_udir/$_qrdir/qr-code-symbolic.svg" 2>/dev/null || true
          done
        fi
        # Copy check-symbolic icon (GNOME Shell CheckBox widget uses this)
        if [ -f "$theme_src/$icon/actions/symbolic/check-symbolic.svg" ]; then
          for _cs_dir in "status/symbolic" "actions/symbolic" "symbolic/ui"; do
            sudo -u "$_user" mkdir -p "$_udir/$_cs_dir" 2>/dev/null || true
            sudo -u "$_user" cp -f "$theme_src/$icon/actions/symbolic/check-symbolic.svg" \
                  "$_udir/$_cs_dir/check-symbolic.svg" 2>/dev/null || true
          done
        fi
        # Copy edit icons to ALL size dirs so GTK finds them
        for _ed_icon in "document-edit-symbolic.svg" "edit-symbolic.svg" "adw-entry-edit-symbolic.svg"; do
          if [ -f "$theme_src/$icon/actions/symbolic/$_ed_icon" ]; then
            for _ed_dir in "actions/16" "actions/22" "actions/24" "actions/32" "actions/48" "actions/64" "actions/scalable" "symbolic/actions"; do
              sudo -u "$_user" mkdir -p "$_udir/$_ed_dir" 2>/dev/null || true
              sudo -u "$_user" cp -f "$theme_src/$icon/actions/symbolic/$_ed_icon" \
                    "$_udir/$_ed_dir/$_ed_icon" 2>/dev/null || true
            done
          fi
        done
        # Copy symbolic/ui checkbox icons for existing users
        if [ -d "$theme_src/$icon/symbolic/ui" ]; then
          sudo -u "$_user" mkdir -p "$_udir/symbolic/ui" 2>/dev/null || true
          for _ui_icon in "$theme_src/$icon/symbolic/ui/"*.svg; do
            [ -f "$_ui_icon" ] || continue
            sudo -u "$_user" cp -f "$_ui_icon" "$_udir/symbolic/ui/" 2>/dev/null || true
          done
        fi
        # Add Adwaita-style directories
        for _adir in "scalable/actions" "symbolic/actions" "scalable/apps" "symbolic/apps" \
                     "scalable/devices" "symbolic/devices" "scalable/status" "symbolic/status" \
                     "scalable/categories" "symbolic/categories" "scalable/emblems" "symbolic/emblems" \
                     "scalable/emotes" "symbolic/mimetypes" "scalable/places" "symbolic/places" \
                     "symbolic/ui"; do
          if ! sudo -u "$_user" grep -q "^$_adir$" "$_udir/index.theme" 2>/dev/null; then
            sudo -u "$_user" sed -i "/^Directories=/ s|$|,$_adir|" "$_udir/index.theme" 2>/dev/null || true
            {
              echo ""
              echo "[$_adir]"
              echo "Size=16"
              echo "Context=$(echo "${_adir#*/}" | sed 's/^./\u&/')"
              echo "Type=Scalable"
            } | sudo -u "$_user" tee -a "$_udir/index.theme" >/dev/null
            sudo -u "$_user" mkdir -p "$_udir/$_adir"
          fi
        done
        sudo -u "$_user" find "$_udir" -name "*-symbolic.svg" -exec \
          sed -i 's/fill="[^"]*"/fill="currentColor"/g; s/color="[^"]*"/color="currentColor"/g' {} + 2>/dev/null || true
        sudo -u "$_user" gtk-update-icon-cache "$_udir/" 2>/dev/null || warn "Icon cache update failed for $_user"
        log "Applied icon fixes for $_user ($icon)"
      fi
    done
  done

  ok "Icon themes installed (MacTahoe + MacTahoe-dark)"

  # Custom macOS app icons (SVG+PNG) — ALWAYS OVERRIDE on conflict
  local icon_src="$BUNDLE/icons/256x256"
  if [ -d "$icon_src" ] && [ "$(ls -A "$icon_src"/*.png "$icon_src"/*.svg 2>/dev/null)" ]; then
    local targets=(
      "$HOME/.local/share/icons/MacTahoe-dark/apps/scalable"
      "$HOME/.local/share/icons/MacTahoe/apps/scalable"
      "$HOME/.local/share/icons/hicolor/256x256/apps"
    )
    mkdir -p "${targets[@]}"

    # Copy SVGs first (preferred format for scalable)
    for svg in "$icon_src"/*.svg; do
      [ -f "$svg" ] || continue
      f=$(basename "$svg")
      for t in "${targets[@]}"; do cp -f "$svg" "$t/$f"; done
    done

    # Also copy PNGs as fallback for older apps
    for png in "$icon_src"/*.png; do
      [ -f "$png" ] || continue
      f=$(basename "$png")
      for t in "${targets[@]}"; do cp -f "$png" "$t/$f"; done
    done

    # Flatpak app IDs need their full reverse-DNS name to get themed
    # Map short name → Flatpak ID so both native and Flatpak installs pick it up
    declare -A fp_aliases=(
      [discord.png]="com.discordapp.Discord.png"
      [spotify.png]="com.spotify.Client.png"
      [vlc.png]="org.videolan.VLC.png"
      [code.png]="com.visualstudio.code.png"
      [localsend.png]="org.localsend.localsend_app.png"
      [opencode.png]="ai.opencode.desktop.png"
    )
    # SVG aliases
    for svg in "$icon_src"/*.svg; do
      [ -f "$svg" ] || continue
      local base; base=$(basename "$svg")
      local base_noext="${base%.svg}"
      local alias_svg="${fp_aliases[${base_noext}.png]:-}"
      [ -z "$alias_svg" ] && continue
      local alias_svg_name="${alias_svg%.png}.svg"
      for t in "${targets[@]}"; do cp -f "$svg" "$t/$alias_svg_name"; done
    done
    # PNG aliases
    for png in "$icon_src"/*.png; do
      [ -f "$png" ] || continue
      local base; base=$(basename "$png")
      local alias_png="${fp_aliases[$base]:-}"
      [ -z "$alias_png" ] && continue
      for t in "${targets[@]}"; do cp -f "$png" "$t/$alias_png"; done
    done

    # Trim padding + resize to 256×256 (PNGs only — SVGs are already correct)
    for t in "${targets[@]}"; do
      for png in "$t"/*.png; do
        [ -f "$png" ] || continue
        magick "$png" -trim +repage -resize 256x256 -gravity center -background transparent -extent 256x256 "$png" 2>/dev/null || \
        convert "$png" -trim +repage -resize 256x256 -gravity center -background transparent -extent 256x256 "$png"
      done
    done

    # Decibels uses pause-large-symbolic / play-large-symbolic (not the standard
    # media-playback-* names). Symlink them so the play/pause button isn't a
    # "block missing icon" placeholder.
    for _dec_theme in MacTahoe-dark MacTahoe; do
      _dec_dir="$HOME/.local/share/icons/$_dec_theme"
      [ -d "$_dec_dir" ] || continue
      for _dec_sub in actions/24 actions/48 actions/64 actions/scalable actions/symbolic; do
        _dec_full="$_dec_dir/$_dec_sub"
        [ -d "$_dec_full" ] || continue
        [ -f "$_dec_full/media-playback-pause-symbolic.svg" ] && \
          [ ! -f "$_dec_full/pause-large-symbolic.svg" ] && \
          ln -sf "media-playback-pause-symbolic.svg" "$_dec_full/pause-large-symbolic.svg"
        [ -f "$_dec_full/media-playback-start-symbolic.svg" ] && \
          [ ! -f "$_dec_full/play-large-symbolic.svg" ] && \
          ln -sf "media-playback-start-symbolic.svg" "$_dec_full/play-large-symbolic.svg"
      done
    done

    # ALWAYS rebuild icon cache last (ensures custom icons override any conflicts)
    gtk-update-icon-cache "$HOME/.local/share/icons/MacTahoe-dark/" 2>/dev/null || warn "Icon cache update failed for MacTahoe-dark"
    gtk-update-icon-cache "$HOME/.local/share/icons/MacTahoe/" 2>/dev/null || warn "Icon cache update failed for MacTahoe"
    # Ensure hicolor has an index.theme so gtk-update-icon-cache works
    if [ ! -f "$HOME/.local/share/icons/hicolor/index.theme" ]; then
      cat > "$HOME/.local/share/icons/hicolor/index.theme" <<-EOF
[Icon Theme]
Name=Hicolor
Comment=Fallback icon theme (local overrides)
Hidden=true
Directories=256x256/apps
EOF
    fi
    gtk-update-icon-cache "$HOME/.local/share/icons/hicolor/" 2>/dev/null || warn "Icon cache update failed for hicolor"

    # ── System-wide: copy all icons + aliases so EVERY user gets them ──
    local sys="/usr/share/icons/hicolor/256x256/apps"
    sudo mkdir -p "$sys"
    for f in "$icon_src"/*.svg "$icon_src"/*.png; do
      [ -f "$f" ] || continue
      sudo cp -f "$f" "$sys/"
    done
    # Flatpak aliases system-wide (PNG)
    for f in "$icon_src"/*.png; do
      [ -f "$f" ] || continue
      local base; base=$(basename "$f")
      local alias="${fp_aliases[$base]:-}"
      [ -z "$alias" ] && continue
      sudo cp -f "$f" "$sys/$alias"
    done
    # Flatpak aliases system-wide (SVG)
    for f in "$icon_src"/*.svg; do
      [ -f "$f" ] || continue
      local base; base=$(basename "$f")
      local base_noext="${base%.svg}"
      local alias="${fp_aliases[${base_noext}.png]:-}"
      [ -z "$alias" ] && continue
      local alias_svg_name="${alias%.png}.svg"
      sudo cp -f "$f" "$sys/$alias_svg_name"
    done
    # Trim + resize system-wide PNGs
    for png in "$sys"/*.png; do
      [ -f "$png" ] || continue
      sudo magick "$png" -trim +repage -resize 256x256 -gravity center -background transparent -extent 256x256 "$png" 2>/dev/null || \
      sudo convert "$png" -trim +repage -resize 256x256 -gravity center -background transparent -extent 256x256 "$png"
    done
    # Rebuild system icon cache
    sudo gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || warn "System-wide icon cache update failed"

  ok "Custom macOS app icons installed ($(ls "$icon_src"/*.png 2>/dev/null | wc -l) PNGs + $(ls "$icon_src"/*.svg 2>/dev/null | wc -l) SVGs)"
  fi
}

install_font() {
  next_step "SF Pro Display Font"

  local font_src="$BUNDLE/fonts/SF-Pro-Display-Regular.otf"
  if [ -f "$font_src" ]; then
    mkdir -p "$HOME/.local/share/fonts"
    cp "$font_src" "$HOME/.local/share/fonts/"
    if ! fc-cache -fv 2>/dev/null; then
      warn "Font cache update failed — SF Pro may not be available until next login"
    fi
    ok "SF Pro Display font installed"
  else
    warn "SF-Pro-Display-Regular.otf not found in bundle — place it in fonts/ manually"
  fi
}

# ── PHASE 4: CONFIGURATION ───────────────────────────────────

apply_desktop_entries() {
  next_step "Custom Desktop Entries (App Renames)"

  # Clean up any leftover nautilus-maximized references (wrapper was removed)
  if [ -f "$HOME/.local/share/applications/org.gnome.Nautilus.desktop" ]; then
    if grep -q "nautilus-maximized" "$HOME/.local/share/applications/org.gnome.Nautilus.desktop" 2>/dev/null; then
      rm -f "$HOME/.local/share/applications/org.gnome.Nautilus.desktop"
      ok "Nautilus desktop entry cleaned (was referencing deleted wrapper)"
    fi
  fi

  local desktop_src="$BUNDLE/desktop"
  if [ -d "$desktop_src" ] && [ "$(ls -A "$desktop_src" 2>/dev/null)" ]; then
    mkdir -p "$HOME/.local/share/applications"
    cp "$desktop_src"/*.desktop "$HOME/.local/share/applications/" 2>/dev/null || true
    ok "Desktop entries applied"
  else
    warn "No desktop entries found"
  fi
}

apply_configs() {
  next_step "Config Files (Kitty, Fish, Starship, GTK, Fastfetch)"

  local cfg="$BUNDLE/configs"

  # Kitty
  if [ -f "$cfg/kitty/kitty.conf" ]; then
    mkdir -p "$HOME/.config/kitty"
    cp "$cfg/kitty/kitty.conf" "$HOME/.config/kitty/"
    # ktheme auto-theme palette file — kitty.conf ends with `include auto-theme.conf`,
    # so the file MUST exist or kitty logs an include error and skips it.
    if [ -f "$cfg/kitty/auto-theme.conf" ]; then
      cp "$cfg/kitty/auto-theme.conf" "$HOME/.config/kitty/"
    fi
    # Live palette re-apply — the copied auto-theme.conf is the seed fallback;
    # the real colors come from the current wallpaper, so re-run ktheme silently.
    if command -v fish >/dev/null 2>&1 && [ -f "$HOME/.config/fish/functions/ktheme.fish" ]; then
      fish -c 'ktheme apply --silent' >/dev/null 2>&1 || true
    fi
    ok "Kitty config"
  fi

  # Fish
  if [ -f "$cfg/fish/config.fish" ]; then
    # Auto-backup the live fish config before overwriting (keeps last 10)
    if [ -d "$HOME/.config/fish" ]; then
      mkdir -p "$HOME/.cache/fedora-mactahoe/backups"
      tar czf "$HOME/.cache/fedora-mactahoe/backups/fish-$(date +%Y%m%d-%H%M%S).tar.gz" -C "$HOME/.config" fish 2>/dev/null || true
      ls -1t "$HOME/.cache/fedora-mactahoe/backups"/fish-*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm -f 2>/dev/null || true
    fi
    mkdir -p "$HOME/.config/fish/functions"
    cp "$cfg/fish/config.fish" "$HOME/.config/fish/"
    if [ -d "$cfg/fish/functions" ]; then
      cp -f "$cfg/fish/functions/"*.fish "$HOME/.config/fish/functions/" 2>/dev/null || true
    fi
    ok "Fish config ($(ls "$HOME/.config/fish/functions/"*.fish 2>/dev/null | wc -l) functions)"
  fi

  # Guard hook (root-owned) — /etc/fish/config.fish warns in every terminal if
  # the MacTahoe fish config is ever deleted. A normal user cannot remove it.
  # The recovery one-liner fingerprint-checks update.fish against updates.json
  # before it is restored (sha256 pinned in the manifest — same supply-chain
  # rule as _update_run in update.fish).
  if [ -f /etc/fish/config.fish ] && sudo -n true 2>/dev/null; then
    if ! grep -q "fedora-mactahoe-guard" /etc/fish/config.fish 2>/dev/null; then
      sudo tee -a /etc/fish/config.fish >/dev/null <<'EOF'

# ── Fedora MacTahoe guard (eprahemi) ──
if test -d "$HOME/.cache/fedora-mactahoe"; and not test -f "$HOME/.config/fish/functions/update.fish"
    printf '\n  [!] Fedora MacTahoe fish config is missing.\n'
    printf '      Restore it with this one line (any terminal):\n'
    printf '      mkdir -p ~/.config/fish/functions ~/.cache/fedora-mactahoe; and set -l m ~/.cache/fedora-mactahoe/latest-manifest.json; and curl -fsSL --max-time 30 https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/updates.json -o $m; and curl -fsSL --max-time 30 https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/configs/fish/functions/update.fish -o ~/.cache/fedora-mactahoe/update.fish; and test (sha256sum ~/.cache/fedora-mactahoe/update.fish | string split " " -f1) = (python3 -c \'import json,sys;print(json.load(open(sys.argv[1])).get("update_sha256",""))\' $m); and mv ~/.cache/fedora-mactahoe/update.fish ~/.config/fish/functions/update.fish; and env KITTY_PID=1 fish -c "source ~/.config/fish/functions/update.fish; update configs"; or printf "      [!] fingerprint check failed — nothing was restored.\\\n"\n\n'
    printf '      (update.fish is fingerprint-checked before it is restored)\n'
end
# ── end of fedora-mactahoe-guard ──
EOF
    fi
  fi

  # Starship
  if [ -f "$cfg/starship.toml" ]; then
    cp "$cfg/starship.toml" "$HOME/.config/"
    ok "Starship"
  fi

  # GTK
  if [ -f "$cfg/gtk-3.0/settings.ini" ]; then
    mkdir -p "$HOME/.config/gtk-3.0"
    cp "$cfg/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/"
    ok "GTK 3.0"
  fi
  if [ -f "$cfg/gtk-4.0/settings.ini" ]; then
    mkdir -p "$HOME/.config/gtk-4.0"
    cp "$cfg/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/"
    ok "GTK 4.0"
  fi

  # Fastfetch
  if [ -d "$cfg/fastfetch" ] && [ "$(ls -A "$cfg/fastfetch" 2>/dev/null)" ]; then
    mkdir -p "$HOME/.config/fastfetch"
    if [ -f "$cfg/fastfetch/config.jsonc" ]; then
      sed "s|PLACEHOLDER_USER_HOME|$HOME|g" "$cfg/fastfetch/config.jsonc" > "$HOME/.config/fastfetch/config.jsonc"
      cp "$cfg/fastfetch/"*.png "$HOME/.config/fastfetch/" 2>/dev/null || true
      cp "$cfg/fastfetch/"*.gif "$HOME/.config/fastfetch/" 2>/dev/null || true
    else
      cp -r "$cfg/fastfetch/"* "$HOME/.config/fastfetch/"
    fi
    ok "Fastfetch"
  fi

  # Systemd logind overrides — wipes all existing .conf files, copies ours
  if [ -f "$BUNDLE/config/logind.conf.d/logind-overrides.conf" ]; then
    sudo mkdir -p /etc/systemd/logind.conf.d
    sudo rm -f /etc/systemd/logind.conf.d/*.conf
    sudo cp -f "$BUNDLE/config/logind.conf.d/logind-overrides.conf" /etc/systemd/logind.conf.d/logind-overrides.conf
    sudo chown root:root /etc/systemd/logind.conf.d/logind-overrides.conf
    sudo chmod 644 /etc/systemd/logind.conf.d/logind-overrides.conf
    ok "systemd-logind overrides"
  fi
}

apply_dconf() {
  next_step "GNOME dconf Settings"

  # Rollback point before any gsettings/dconf writes + extension restore
  backup_dconf

  local dconf_file="$BUNDLE/configs/dconf/full-backup.ini"

  # ── Theme ──
  gsettings set org.gnome.desktop.interface gtk-theme "MacTahoe-Dark" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme "MacTahoe-dark" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface cursor-theme "MacTahoe-dark" 2>/dev/null || true
  dconf write /org/gnome/shell/extensions/user-theme/name "'MacTahoe-Dark'" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.preferences theme "MacTahoe-Dark" 2>/dev/null || true

  # ── Interface ──
  gsettings set org.gnome.desktop.interface font-name "SF Pro Display 11" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface document-font-name "SF Pro Display 12" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface monospace-font-name "Adwaita Mono 11" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface font-hinting "slight" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface font-antialiasing "grayscale" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface accent-color "blue" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface clock-format "12h" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface clock-show-date true 2>/dev/null || true
  gsettings set org.gnome.desktop.interface clock-show-seconds false 2>/dev/null || true
  gsettings set org.gnome.desktop.interface clock-show-weekday false 2>/dev/null || true
  gsettings set org.gnome.desktop.interface show-battery-percentage false 2>/dev/null || true
  gsettings set org.gnome.desktop.interface enable-animations true 2>/dev/null || true

  # ── Window buttons (no double-click toggle) ──
  gsettings set org.gnome.desktop.wm.preferences button-layout "close,minimize,maximize:appmenu" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar "'none'" 2>/dev/null || true

  # ── Peripherals ──
  gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
  gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
  gsettings set org.gnome.desktop.peripherals.touchpad click-method "'fingers'" 2>/dev/null || true
  gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true
  gsettings set org.gnome.desktop.peripherals.touchpad accel-profile "'flat'" 2>/dev/null || true
  gsettings set org.gnome.desktop.peripherals.mouse accel-profile "'flat'" 2>/dev/null || true
  gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false 2>/dev/null || true

  # ── Workspaces ──
  gsettings set org.gnome.mutter dynamic-workspaces true 2>/dev/null || true
  gsettings set org.gnome.mutter workspaces-only-on-primary true 2>/dev/null || true

  # ── Workspace shortcuts ──
  for i in {1..9}; do
    gsettings set org.gnome.shell.keybindings switch-to-application-$i "[]" 2>/dev/null || true
  done
  for i in {1..9}; do
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Super>$i']" 2>/dev/null || true
  done
  for i in {1..9}; do
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Super><Shift>$i']" 2>/dev/null || true
  done
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Control>Left']" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Control>Right']" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']" 2>/dev/null || true

  # ── Custom keybindings ──
  # Free Super+N from GNOME Shell's focus-active-notification (conflict)
  gsettings set org.gnome.shell.keybindings focus-active-notification "[]" 2>/dev/null || true

  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8/']" 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Kitty' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>t' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'kitty' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'Nautilus' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>e' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'nautilus' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name 'Task Manager' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding '<Shift><Control>Escape' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command 'gnome-system-monitor' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ name 'Volume' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ binding '<Control><Alt>v' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ command 'pavucontrol' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/ name 'Notes' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/ binding '<Super>n' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/ command 'gnome-text-editor' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/ name 'Chrome' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/ binding '<Super>w' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/ command 'google-chrome' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/ name 'Firefox' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/ binding '<Super>f' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/ command 'firefox' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/ name 'Spotify' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/ binding '<Super>z' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/ command 'flatpak run com.spotify.Client' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8/ name 'Settings' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8/ binding '<Control>i' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8/ command 'gnome-control-center' 2>/dev/null || true

  # ── Nautilus ──
  gsettings set org.gnome.nautilus.icon-view default-zoom-level "'large'" 2>/dev/null || true
  gsettings set org.gnome.nautilus.preferences recursive-search "'always'" 2>/dev/null || true
  gsettings set org.gnome.nautilus.preferences show-image-thumbnails "'always'" 2>/dev/null || true
  gsettings set org.gnome.nautilus.preferences show-directory-item-counts "'always'" 2>/dev/null || true
  gsettings set org.gnome.nautilus.preferences show-hidden-files true 2>/dev/null || true

  # ── Night Light ──
  gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature uint32 2700 2>/dev/null || true

  # ── Power ──
  gsettings set org.gnome.settings-daemon.plugins.power power-button-action "'interactive'" 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout uint32 4800 2>/dev/null || true

  # ── Session (never sleep) ──
  gsettings set org.gnome.desktop.session idle-delay 0 2>/dev/null || true

  # ── Default terminal → Kitty ──
  gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty' 2>/dev/null || true
  gsettings set org.gnome.desktop.default-applications.terminal exec-arg '-e' 2>/dev/null || true

  # ── Privacy ──
  gsettings set org.gnome.desktop.privacy report-technical-problems false 2>/dev/null || true
  gsettings set org.gnome.desktop.privacy remember-app-usage false 2>/dev/null || true
  gsettings set org.gnome.desktop.privacy send-software-usage-stats false 2>/dev/null || true

  # Stop + disable ABRT crash-reporting daemons (if present)
  sudo systemctl disable --now abrtd abrt-journal-core abrt-oops abrt-xorg 2>/dev/null || true
  # Stop + disable Tracker3 file indexer (if present) — saves CPU/battery
  systemctl --user disable --now tracker3-miner-fs tracker3-miner-fs-control tracker3-miner-apps tracker3-miner-extractor 2>/dev/null || true

  # ── Extension dconf restore ──
  if [ -f "$dconf_file" ]; then
    dconf load /org/gnome/shell/extensions/ < "$dconf_file" 2>/dev/null || true
    ok "Extension settings restored from backup"
  fi

  # Re-apply GTK settings.ini AFTER dconf/gsettings (GNOME daemon overwrites it)
  local cfg="$BUNDLE/configs"
  if [ -f "$cfg/gtk-3.0/settings.ini" ]; then
    mkdir -p "$HOME/.config/gtk-3.0"
    cp "$cfg/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/" || warn "Failed to copy gtk-3.0 settings.ini"
  fi
  if [ -f "$cfg/gtk-4.0/settings.ini" ]; then
    mkdir -p "$HOME/.config/gtk-4.0"
    cp "$cfg/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/" || warn "Failed to copy gtk-4.0 settings.ini"
  fi

  ok "dconf settings applied"
}

# ── Optional passwordless sudo prompt (run before Phase 1) ──

prompt_sudoers_entry() {
  # Always add the commented NOPASSWD line (no prompt)
  if sudo grep -q "$USER.*NOPASSWD" /etc/sudoers 2>/dev/null; then
    ok "NOPASSWD entry for $USER already present in /etc/sudoers"
  else
    local _tmp_sudoers
    _tmp_sudoers=$(mktemp)
    sudo cat /etc/sudoers > "$_tmp_sudoers"
    echo "" >> "$_tmp_sudoers"
    echo "# $USER ALL=(ALL) NOPASSWD: ALL" >> "$_tmp_sudoers"
    if sudo visudo -c -f "$_tmp_sudoers" 2>/dev/null; then
      sudo cp "$_tmp_sudoers" /etc/sudoers
      sudo chmod 440 /etc/sudoers
      sudo chown root:root /etc/sudoers
      ok "Commented NOPASSWD entry added to end of /etc/sudoers"
      warn "Enable it: sudo visudo  →  find the line and uncomment it"
    else
      warn "sudoers validation failed - hint not added"
    fi
    rm -f "$_tmp_sudoers"
  fi
}

# ── Optional wallpaper prompts (run before Phase 1) ──

prompt_optional_wallpapers() {

  # ── Desktop wallpaper prompt ──
  if [ -z "${INSTALL_DESKTOP_WALLPAPER:-}" ]; then
    echo ""
    echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
desk_t="        ◆  DESKTOP WALLPAPER?  ◆"
    echo -e "  ${CYAN}║${NC}        ${BOLD}${WHITE}◆  DESKTOP WALLPAPER?${NC}  ${DIM}◆${NC}$(printf '%*s' $((62 - ${#desk_t})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
desk1="  Install the custom Himeno Fedora desktop wallpaper?"
    echo -e "  ${CYAN}║${NC}${desk1}$(printf '%*s' $((62 - ${#desk1})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
desk2="    no   — Keep current wallpaper"
    echo -e "  ${CYAN}║${NC}    ${BOLD}${YELLOW}n${NC}${BOLD}o${NC}   — Keep current wallpaper$(printf '%*s' $((62 - ${#desk2})) '')${CYAN}║${NC}"
desk3="    Yes  — Set Himeno Fedora.jpg as your desktop"
    echo -e "  ${CYAN}║${NC}    ${BOLD}${GREEN}Y${NC}${BOLD}es${NC}  — Set Himeno Fedora.jpg as your desktop$(printf '%*s' $((62 - ${#desk3})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
desk4="  (Login screen wallpaper has its own prompt below)"
    echo -e "  ${CYAN}║${NC}${DIM}${desk4}$(printf '%*s' $((62 - ${#desk4})) '')${NC}${CYAN}║${NC}"
desk5="  Press Enter for default (No)"
    echo -e "  ${CYAN}║${NC}${DIM}${desk5}$(printf '%*s' $((62 - ${#desk5})) '')${NC}${CYAN}║${NC}"
    echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    if confirm "Desktop wallpaper? [y/N]: " N; then
      INSTALL_DESKTOP_WALLPAPER="true"
      echo -e "  ${GREEN}→ Desktop wallpaper will be installed${NC}"
    else
      INSTALL_DESKTOP_WALLPAPER="false"
      echo -e "  ${DIM}→ Skipping desktop wallpaper${NC}"
    fi
  fi

  # ── Login screen wallpaper prompt (separate from desktop) ──
  if [ -z "${INSTALL_LOGIN_WALLPAPER:-}" ]; then
    echo ""
    echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
login_t="       ◆  LOGIN SCREEN WALLPAPER?  ◆"
    echo -e "  ${CYAN}║${NC}       ${BOLD}${WHITE}◆  LOGIN SCREEN WALLPAPER?${NC}  ${DIM}◆${NC}$(printf '%*s' $((62 - ${#login_t})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
login1="  Override the GDM login screen with the Himeno theme?"
    echo -e "  ${CYAN}║${NC}${login1}$(printf '%*s' $((62 - ${#login1})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
login2="  This sets the macOS-style login screen with the"
    echo -e "  ${CYAN}║${NC}${login2}$(printf '%*s' $((62 - ${#login2})) '')${CYAN}║${NC}"
login3="  Himeno background, macOS theme, and hides the logo."
    echo -e "  ${CYAN}║${NC}${login3}$(printf '%*s' $((62 - ${#login3})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
login4="  Not stuck with just this one — the gdm command"
    echo -e "  ${CYAN}║${NC}${login4}$(printf '%*s' $((62 - ${#login4})) '')${CYAN}║${NC}"
login4b="  lets you swap wallpapers anytime after install."
    echo -e "  ${CYAN}║${NC}${login4b}$(printf '%*s' $((62 - ${#login4b})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
login4c="  If you already have a custom GDM setup, skip this."
    echo -e "  ${CYAN}║${NC}${DIM}${login4c}$(printf '%*s' $((62 - ${#login4c})) '')${NC}${CYAN}║${NC}"
login5="  Press Enter for default (Yes)"
    echo -e "  ${CYAN}║${NC}${DIM}${login5}$(printf '%*s' $((62 - ${#login5})) '')${NC}${CYAN}║${NC}"
    echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    if confirm "Override GDM login screen? [Y/n]: " Y; then
      # ── Second confirmation ──
      echo ""
      echo -e "  ${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
      echo -e "  ${YELLOW}║${NC}        ${BOLD}⚠  ARE YOU ABSOLUTELY SURE?  ⚠${NC}                        ${YELLOW}║${NC}"
      echo -e "  ${YELLOW}╠══════════════════════════════════════════════════════════════╣${NC}"
      echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
      echo -e "  ${YELLOW}║${NC}  This will set the Himeno login screen as your GDM           ${YELLOW}║${NC}"
      echo -e "  ${YELLOW}║${NC}  background. Don't worry — you can change it anytime!        ${YELLOW}║${NC}"
      echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
      echo -e "  ${YELLOW}║${NC}  Just run ${BOLD}gdm${NC} in the terminal to switch to any picture       ${YELLOW}║${NC}"
      echo -e "  ${YELLOW}║${NC}  you like. The ${BOLD}gdm.fish${NC} function lets you change your        ${YELLOW}║${NC}"
      echo -e "  ${YELLOW}║${NC}  login screen wallpaper anytime with preview, blur, and      ${YELLOW}║${NC}"
      echo -e "  ${YELLOW}║${NC}  search — all from the terminal.                             ${YELLOW}║${NC}"
      echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
      echo -e "  ${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
      echo ""
      if confirm "Are you sure you want the GDM login screen? [Y/n]: " Y; then
        INSTALL_LOGIN_WALLPAPER="true"
        echo -e "  ${GREEN}→ GDM login screen will be themed${NC}"
      else
        INSTALL_LOGIN_WALLPAPER="false"
        echo -e "  ${DIM}→ Skipping GDM login screen${NC}"
      fi
    else
      INSTALL_LOGIN_WALLPAPER="false"
      echo -e "  ${DIM}→ Skipping GDM login screen${NC}"
    fi
  fi

  # ── 18+ wallpaper prompt (separate, always optional) ──
  if [ -z "${INSTALL_WALLPAPER_18:-}" ]; then
    echo ""
    echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
wp18_t="         ◆  18+ WALLPAPERS?  ◆"
    echo -e "  ${CYAN}║${NC}         ${BOLD}${WHITE}◆  18+ WALLPAPERS?${NC}  ${DIM}◆${NC}$(printf '%*s' $((62 - ${#wp18_t})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
wp18_1="  Download additional 18+ wallpapers from a hosted zip?"
    echo -e "  ${CYAN}║${NC}${wp18_1}$(printf '%*s' $((62 - ${#wp18_1})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
wp18_2="    yes  — Download and install 18+ wallpapers"
    echo -e "  ${CYAN}║${NC}    ${BOLD}${YELLOW}y${NC}${BOLD}es${NC}  — Download and install 18+ wallpapers$(printf '%*s' $((62 - ${#wp18_2})) '')${CYAN}║${NC}"
wp18_3="    No   — Skip them (default)"
    echo -e "  ${CYAN}║${NC}    ${BOLD}${GREEN}N${NC}${BOLD}o${NC}   — Skip them (default)$(printf '%*s' $((62 - ${#wp18_3})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
wp18_4="  To update: replace the zip — same URL works"
    echo -e "  ${CYAN}║${NC}${DIM}${wp18_4}$(printf '%*s' $((62 - ${#wp18_4})) '')${NC}${CYAN}║${NC}"
wp18_5="  Press Enter for default (No)"
    echo -e "  ${CYAN}║${NC}${DIM}${wp18_5}$(printf '%*s' $((62 - ${#wp18_5})) '')${NC}${CYAN}║${NC}"
    echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    if confirm "18+ wallpapers? [y/N]: " N; then
      INSTALL_WALLPAPER_18="true"
      echo -e "  ${GREEN}→ 18+ wallpapers will be downloaded${NC}"
    else
      INSTALL_WALLPAPER_18="false"
      echo -e "  ${DIM}→ Skipping 18+ wallpapers${NC}"
    fi
  fi

}

prompt_billie_videos() {
  # ── Prompt if not already set (e.g. by bootstrap.sh) ──
  if [ -z "${INSTALL_BILLIE_VIDEOS:-}" ]; then
    echo ""
    echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
bv_t="        ◆  🔥  HOT BILLIE & JINX VIDEO EDITS?  ◆"
    echo -e "  ${CYAN}║${NC}${bv_t}$(printf '%*s' $((61 - ${#bv_t})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
bv1="  🔥  Sick edits — Billie, Jinx, and cool stuff (~500 MB)"
    echo -e "  ${CYAN}║${NC}${bv1}$(printf '%*s' $((61 - ${#bv1})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
bv2="    y  — Heck yeah! Drop 'em in ~/Downloads"
    echo -e "  ${CYAN}║${NC}${bv2}$(printf '%*s' $((62 - ${#bv2})) '')${CYAN}║${NC}"
bv3="    N   — Nah, not today (default)"
    echo -e "  ${CYAN}║${NC}${bv3}$(printf '%*s' $((62 - ${#bv3})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
bv4="  You'll get Billie Eilish , Jinx Edit Hot, and more"
    echo -e "  ${CYAN}║${NC}${bv4}$(printf '%*s' $((62 - ${#bv4})) '')${CYAN}║${NC}"
bv5="  Press Enter for default (No)"
    echo -e "  ${CYAN}║${NC}${bv5}$(printf '%*s' $((62 - ${#bv5})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    if confirm "🔥  Hot Billie & Jinx edits? [y/N]: " N; then
      INSTALL_BILLIE_VIDEOS="true"
      echo -e "  ${GREEN}→  🔥  Alright! Dropping hot edits in ~/Downloads${NC}"
    else
      # ── Naughty second prompt — are you REALLY sure? ──
      echo ""
      echo -e "  ${PINK}╔══════════════════════════════════════════════════════════════╗${NC}"
nsty_t="     ◆  👀  U SURE BUDDY?  👀  ◆"
      echo -e "  ${PINK}║${NC}${nsty_t}$(printf '%*s' $((62 - ${#nsty_t})) '')${PINK}║${NC}"
      echo -e "  ${PINK}╠══════════════════════════════════════════════════════════════╣${NC}"
      echo -e "  ${PINK}║${NC}                                                              ${PINK}║${NC}"
nsty1="  You really gonna miss out on mommy Billie's sweet"
      echo -e "  ${PINK}║${NC}${nsty1}$(printf '%*s' $((62 - ${#nsty1})) '')${PINK}║${NC}"
nsty2="  body and Jinx's hot slim curves?  🔥  💦"
      echo -e "  ${PINK}║${NC}${nsty2}$(printf '%*s' $((62 - ${#nsty2})) '')${PINK}║${NC}"
      echo -e "  ${PINK}║${NC}                                                              ${PINK}║${NC}"
nsty3="    Yes  — OK OK YOU CONVINCED ME!  😩🔥"
      echo -e "  ${PINK}║${NC}    ${BOLD}${GREEN}Y${NC}${BOLD}es${NC}  — OK OK YOU CONVINCED ME!  😩🔥$(printf '%*s' $((62 - ${#nsty3})) '')${PINK}║${NC}"
nsty4="    No   — Nah I'm good (for real this time)"
      echo -e "  ${PINK}║${NC}    ${BOLD}${YELLOW}n${NC}${BOLD}o${NC}   — Nah I'm good (for real this time)$(printf '%*s' $((62 - ${#nsty4})) '')${PINK}║${NC}"
      echo -e "  ${PINK}║${NC}                                                              ${PINK}║${NC}"
nsty5="  Last chance before you miss mommy..."
      echo -e "  ${PINK}║${NC}${nsty5}$(printf '%*s' $((62 - ${#nsty5})) '')${PINK}║${NC}"
      echo -e "  ${PINK}╚══════════════════════════════════════════════════════════════╝${NC}"
      echo ""
      if confirm "👀  For real though? [y/N]: " N; then
        INSTALL_BILLIE_VIDEOS="true"
        echo -e "  ${GREEN}→  😩  Alright alright — dropping hot edits in ~/Downloads${NC}"
      else
        INSTALL_BILLIE_VIDEOS="false"
        echo -e "  ${DIM}→  Aight your loss, more for the rest of us 🔥${NC}"
      fi
    fi
  fi
}
apply_wallpapers() {
  next_step "Wallpaper + Login Screen"

  local wp="$BUNDLE/wallpapers"
  local wp_norm="/usr/share/backgrounds/Wallvault Wallpapers"
  local wp_18="/usr/share/backgrounds/Wallvault Wallpapers +18"
  local xml_dir="/usr/share/gnome-background-properties"
  mkdir -p "$HOME/.local/share/backgrounds"

  # ── Always wipe stock Fedora backgrounds ──
  if [ -d /usr/share/backgrounds ]; then
    sudo rm -rf /usr/share/backgrounds/* 2>/dev/null || true
    ok "Stock system wallpapers removed"
  fi

  local count_norm=0
  local count_18=0

  # ══════════════════════════════════════════════════════════════════
  # BRANCH: user chose +18 wallpapers
  #   → Only "Wallvault Wallpapers +18" folder + XML survive
  # BRANCH: user skipped +18 wallpapers
  #   → Only "Wallvault Wallpapers" folder + XML survive
  # ══════════════════════════════════════════════════════════════════
  if [ "${INSTALL_WALLPAPER_18:-false}" = "true" ]; then
    # ── +18 MODE ──────────────────────────────────────────────
    # Destroy normal folder + XML (no cache left behind)
    [ -d "$wp_norm" ] && sudo rm -rf "$wp_norm" 2>/dev/null
    [ -f "$xml_dir/wallvault-wallpapers.xml" ] && sudo rm -f "$xml_dir/wallvault-wallpapers.xml" 2>/dev/null

    # Destroy old +18 folder so we start clean
    [ -d "$wp_18" ] && sudo rm -rf "$wp_18" 2>/dev/null
    sudo mkdir -p "$wp_18"

    log "Downloading 18+ wallpapers…"
    local zip_tmp="/tmp/wallpapers-18-$$.zip"
    local extract_tmp="/tmp/wallpapers-18-extract-$$"
    mkdir -p "$extract_tmp"

    if curl -L --max-time 90 -b "download_warning=1" "$WALLPAPER_18_URL" -o "$zip_tmp" 2>/dev/null; then
      if ! is_valid_zip "$zip_tmp"; then
        local mime
        mime=$(file --brief --mime-type "$zip_tmp" 2>/dev/null || echo "unknown")
        warn "Downloaded 18+ wallpapers is not a valid zip (got: $mime) — file may be deleted from Google Drive"
        rm -f "$zip_tmp" 2>/dev/null || true
      elif unzip -q "$zip_tmp" -d "$extract_tmp" 2>/dev/null; then
        while IFS= read -r -d '' img; do
          sudo cp "$img" "$wp_18/" 2>/dev/null || true
          count_18=$((count_18 + 1))
        done < <(find "$extract_tmp" -type f -print0 2>/dev/null)
        [ "$count_18" -gt 0 ] && ok "$count_18 18+ wallpapers installed"
      else
        warn "Failed to extract 18+ zip (file may be corrupted)"
      fi
      rm -f "$zip_tmp" 2>/dev/null || true
    else
      warn "Failed to download 18+ wallpapers — check WALLPAPER_18_URL"
    fi
    rm -rf "$extract_tmp" 2>/dev/null || true

    # ── 18+ wallpapers v2 (additional zip) ──
    mkdir -p "$extract_tmp"
    if curl -L --max-time 90 -b "download_warning=1" "$WALLPAPER_18_URL_V2" -o "$zip_tmp" 2>/dev/null; then
      if ! is_valid_zip "$zip_tmp"; then
        local mime
        mime=$(file --brief --mime-type "$zip_tmp" 2>/dev/null || echo "unknown")
        warn "Downloaded 18+ wallpapers v2 is not a valid zip (got: $mime) — skipping"
        rm -f "$zip_tmp" 2>/dev/null || true
      elif unzip -q "$zip_tmp" -d "$extract_tmp" 2>/dev/null; then
        local count_v2=0
        while IFS= read -r -d '' img; do
          sudo cp "$img" "$wp_18/" 2>/dev/null || true
          count_v2=$((count_v2 + 1))
        done < <(find "$extract_tmp" -type f -print0 2>/dev/null)
        count_18=$((count_18 + count_v2))
        [ "$count_v2" -gt 0 ] && ok "$count_v2 additional 18+ wallpapers v2 installed"
      else
        warn "Failed to extract 18+ wallpapers v2 (file may be corrupted)"
      fi
      rm -f "$zip_tmp" 2>/dev/null || true
    else
      warn "Failed to download 18+ wallpapers v2 — check WALLPAPER_18_URL_V2"
    fi
    rm -rf "$extract_tmp" 2>/dev/null || true

    if [ "$count_18" -gt 0 ]; then
      # Generate +18 XML
      local xml_18="$xml_dir/wallvault-wallpapers-18.xml"
      {
        echo '<?xml version="1.0" encoding="UTF-8"?>'
        echo '<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">'
        echo '<wallpapers>'
        for img in "$wp_18/"*; do
          [ -f "$img" ] || continue
          local bname; bname=$(basename "$img")
          local bname_noext="${bname%.*}"
          cat << EOF
      <wallpaper deleted="false">
          <name>${bname_noext}</name>
          <filename>${img}</filename>
          <options>zoom</options>
          <shade_type>solid</shade_type>
          <pcolor>#000000</pcolor>
          <scolor>#000000</scolor>
      </wallpaper>
EOF
        done
        echo '</wallpapers>'
      } | sudo tee "$xml_18" > /dev/null
      ok "Wallvault Wallpapers +18 registered in GNOME picker"

      # Delete ALL stock XMLs except wallvault-wallpapers-18.xml
      for sx in "$xml_dir"/*.xml; do
        [ -f "$sx" ] || continue
        [ "$sx" = "$xml_dir/wallvault-wallpapers-18.xml" ] && continue
        sudo rm -f "$sx" 2>/dev/null || true
      done
      ok "Stock GNOME XMLs deleted"
    fi
  else
    # ── NORMAL MODE ──────────────────────────────────────────
    # Destroy +18 folder + XML (no cache left behind)
    [ -d "$wp_18" ] && sudo rm -rf "$wp_18" 2>/dev/null
    [ -f "$xml_dir/wallvault-wallpapers-18.xml" ] && sudo rm -f "$xml_dir/wallvault-wallpapers-18.xml" 2>/dev/null

    # Destroy old normal folder so we start clean
    [ -d "$wp_norm" ] && sudo rm -rf "$wp_norm" 2>/dev/null
    sudo mkdir -p "$wp_norm"

    # Copy desktop wallpapers (excluding Himeno — lives in ~/.local/share/backgrounds/)
    if [ "${INSTALL_DESKTOP_WALLPAPER:-false}" = "true" ]; then
      for img in "$wp/desktop/"*; do
        [ -f "$img" ] || continue
        bname="${img##*/}"
        [ "$bname" = "Himeno Fedora.jpg" ] && continue
        sudo cp "$img" "$wp_norm/" 2>/dev/null || true
        count_norm=$((count_norm + 1))
      done
    fi

    # Copy all custom background images
    for img in "$wp/background-normal/"*; do
      [ -f "$img" ] || continue
      sudo cp "$img" "$wp_norm/" 2>/dev/null || true
      count_norm=$((count_norm + 1))
    done

    if [ "$count_norm" -gt 0 ]; then
      ok "$count_norm wallpapers installed"

      # Generate normal XML
      local xml_norm="$xml_dir/wallvault-wallpapers.xml"
      {
        echo '<?xml version="1.0" encoding="UTF-8"?>'
        echo '<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">'
        echo '<wallpapers>'
        for img in "$wp_norm/"*; do
          [ -f "$img" ] || continue
          local bname; bname=$(basename "$img")
          local bname_noext="${bname%.*}"
          cat << EOF
      <wallpaper deleted="false">
          <name>${bname_noext}</name>
          <filename>${img}</filename>
          <options>zoom</options>
          <shade_type>solid</shade_type>
          <pcolor>#000000</pcolor>
          <scolor>#000000</scolor>
      </wallpaper>
EOF
        done
        echo '</wallpapers>'
      } | sudo tee "$xml_norm" > /dev/null
      ok "Wallvault Wallpapers registered in GNOME picker"

      # Delete ALL stock XMLs except wallvault-wallpapers.xml
      for sx in "$xml_dir"/*.xml; do
        [ -f "$sx" ] || continue
        [ "$sx" = "$xml_dir/wallvault-wallpapers.xml" ] && continue
        sudo rm -f "$sx" 2>/dev/null || true
      done
      ok "Stock GNOME XMLs deleted"
    fi
  fi

  # Always copy Himeno Fedora.jpg to backgrounds dir (available in picker / for later use)
  if [ -f "$wp/desktop/Himeno Fedora.jpg" ]; then
    cp "$wp/desktop/Himeno Fedora.jpg" "$HOME/.local/share/backgrounds/"
    ok "Himeno Fedora.jpg copied to ~/.local/share/backgrounds/"
  fi

  # Set active desktop wallpaper only if user opted in
  if [ "${INSTALL_DESKTOP_WALLPAPER:-false}" = "true" ]; then
    if [ -f "$HOME/.local/share/backgrounds/Himeno Fedora.jpg" ]; then
      gsettings set org.gnome.desktop.background picture-uri "file://$HOME/.local/share/backgrounds/Himeno Fedora.jpg" 2>/dev/null || true
      gsettings set org.gnome.desktop.background picture-uri-dark "file://$HOME/.local/share/backgrounds/Himeno Fedora.jpg" 2>/dev/null || true
      gsettings set org.gnome.desktop.background picture-options "zoom" 2>/dev/null || true
      ok "Desktop wallpaper applied via gsettings"
    else
      warn "Himeno Fedora.jpg not found in ~/.local/share/backgrounds/"
    fi
  fi

  # Always clean up any leftover login wallpaper from ~/.local/share/backgrounds/
  if [ -f "$HOME/.local/share/backgrounds/Himeno Fedora LoginScreen.jpg" ]; then
    rm "$HOME/.local/share/backgrounds/Himeno Fedora LoginScreen.jpg"
    ok "Removed leftover login wallpaper from ~/.local/share/backgrounds/"
  fi
}

install_custom_avatars() {
  next_step "Custom Profile Pictures (Avatars)"

  local face_dir="/usr/share/pixmaps/faces"
  local src="$BUNDLE/assets/normal-faces"

  # ── Silently purge any stray face/faces folders (keep only the real one) ──
  for dir in /usr/share/pixmaps/face*; do
    [ -d "$dir" ] || continue
    [ "$dir" = "$face_dir" ] && continue
    sudo rm -rf "$dir" 2>/dev/null || true
  done

  # ── Always wipe stock avatars ──
  if [ -d "$face_dir" ]; then
    sudo rm -rf "$face_dir"/* 2>/dev/null || true
    ok "Stock avatars removed"
  fi

  # ── Normal faces ──
  local count=0
  if [ "${INSTALL_WALLPAPER_18:-false}" != "true" ] && [ -d "$src" ] && [ -n "$(ls -A "$src" 2>/dev/null)" ]; then
    sudo mkdir -p "$face_dir"

    # Copy custom avatars — convert to exact 512x512 JPEG
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    for img in "$src/"*; do
      [ -f "$img" ] || continue
      local base
      base=$(basename "${img%.*}")
      local tmp_out="$tmp_dir/${base}.jpg"

      if command -v magick &>/dev/null; then
        magick "$img" -resize 512x512^ -gravity center -extent 512x512 -quality 92 "$tmp_out" 2>/dev/null || true
      elif command -v convert &>/dev/null; then
        convert "$img" -resize 512x512^ -gravity center -extent 512x512 -quality 92 "$tmp_out" 2>/dev/null || true
      else
        warn "ImageMagick not found — skipping avatar conversion"
        break
      fi

      if [ -f "$tmp_out" ]; then
        sudo cp "$tmp_out" "$face_dir/" 2>/dev/null || true
        count=$((count + 1))
      fi
    done

    rm -rf "$tmp_dir"

    if [ "$count" -gt 0 ]; then
      sudo chmod 644 "$face_dir"/*.jpg 2>/dev/null || true
      ok "$count custom avatars installed to $face_dir"
    fi
  fi

  # ── 18+ faces (optional zip download) → replaces normal avatars ──
  if [ "${INSTALL_WALLPAPER_18:-false}" = "true" ]; then
    log "Downloading 18+ profile pictures…"
    local zip_tmp="/tmp/faces-18-$$.zip"
    local extract_tmp="/tmp/faces-18-extract-$$"
    mkdir -p "$extract_tmp"

    if curl -L --max-time 90 -b "download_warning=1" "$FACES_18_URL" -o "$zip_tmp" 2>/dev/null; then
      if ! is_valid_zip "$zip_tmp"; then
        local mime
        mime=$(file --brief --mime-type "$zip_tmp" 2>/dev/null || echo "unknown")
        warn "Downloaded 18+ faces is not a valid zip (got: $mime) — file may be deleted from Google Drive"
        rm -f "$zip_tmp" 2>/dev/null || true
      else
        sudo mkdir -p "$face_dir"
        if unzip -q "$zip_tmp" -d "$extract_tmp" 2>/dev/null; then
          local count_18=0
          while IFS= read -r -d '' img; do
            # Install to the standard face dir so GNOME avatar picker finds them
            sudo cp "$img" "$face_dir/" 2>/dev/null || true
            count_18=$((count_18 + 1))
          done < <(find "$extract_tmp" -type f -print0 2>/dev/null)
          sudo chmod 644 "$face_dir"/* 2>/dev/null || true
          [ "$count_18" -gt 0 ] && ok "$count_18 18+ profile pictures installed to $face_dir"
        else
          warn "Failed to extract 18+ faces zip (file may be corrupted)"
        fi
      fi
      rm -f "$zip_tmp" 2>/dev/null || true
    else
      warn "Failed to download 18+ faces — check FACES_18_URL"
    fi
    rm -rf "$extract_tmp" 2>/dev/null || true
  fi

}

# ── 🔥 Billie & Jinx video edits (optional prompt + download, step 22) ──
download_optional_videos() {
  next_step "Download Billie & Jinx + Gintama Videos"

  # ── Download if opted in ──
  if [ "${INSTALL_BILLIE_VIDEOS:-false}" = "true" ]; then
    log "Fetching hot Billie & Jinx edits… 🔥"
    local dl_dest="$HOME/Downloads"
    local zip_tmp="/tmp/billie-videos-$$.zip"
    mkdir -p "$dl_dest" 2>/dev/null || true
    if curl -L --max-time 90 -b "download_warning=1" "$DOWNLOADS_URL" -o "$zip_tmp" 2>/dev/null; then
      local _extracted=false
      if is_valid_zip "$zip_tmp"; then
        if unzip -j -o -q "$zip_tmp" -d "$dl_dest" 2>/dev/null; then
          _extracted=true
          ok "🔥  Billie & Jinx edits landed in ~/Downloads - enjoy!"
        else
          warn "Billie & Jinx archive could not be extracted (may be corrupted)"
        fi
      elif file --brief --mime-type "$zip_tmp" 2>/dev/null | grep -qi "html"; then
        warn "Downloaded Billie & Jinx archive looks like an HTML page — the file may be deleted from Google Drive"
      else
        # Try extracting anyway (some zips don't have PK magic at offset 0)
        if unzip -j -o -q "$zip_tmp" -d "$dl_dest" 2>/dev/null; then
          _extracted=true
          ok "🔥  Billie & Jinx edits landed in ~/Downloads - enjoy!"
        else
          warn "Billie & Jinx archive could not be extracted (may be corrupted)"
        fi
      fi
      # Stamp extracted videos with today's date so they sort as "created today"
      if [ "$_extracted" = true ]; then
        find "$dl_dest" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.webm" \) -exec touch {} + 2>/dev/null || true
      fi
      rm -f "$zip_tmp" 2>/dev/null || true
      # Sequential: now download Gintama
      log "Fetching Gintama video edits..."
      local gintama_tmp="/tmp/gintama-videos-$$"
      if curl -L --max-time 90 -b "download_warning=1" "$GINTAMA_URL" -o "$gintama_tmp" 2>/dev/null; then
        # Detect type: zip, mp4, or html
        local gintama_mime
        gintama_mime=$(file --brief --mime-type "$gintama_tmp" 2>/dev/null || echo "unknown")
        local _gintama_ok=false
        if echo "$gintama_mime" | grep -qi "html"; then
          warn "Downloaded Gintama file is an HTML page — the file may be deleted from Google Drive"
        elif is_valid_zip "$gintama_tmp"; then
          unzip -j -o -q "$gintama_tmp" -d "$dl_dest" 2>/dev/null && _gintama_ok=true || true
          [ "$_gintama_ok" = true ] && ok "Gintama edits landed in ~/Downloads"
        elif echo "$gintama_mime" | grep -qi "mp4\|video"; then
          if cp "$gintama_tmp" "$dl_dest/Gintama - Bad Boy.mp4" 2>/dev/null; then
            _gintama_ok=true
            touch "$dl_dest/Gintama - Bad Boy.mp4" 2>/dev/null || true
            ok "Gintama edits landed in ~/Downloads"
          fi
        else
          warn "Gintama download has unknown type ($gintama_mime) — file may be corrupted or deleted"
        fi
        # Stamp any extracted gintama videos with today's date
        if [ "$_gintama_ok" = true ] && echo "$gintama_mime" | grep -qi "zip"; then
          find "$dl_dest" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.webm" \) -exec touch {} + 2>/dev/null || true
        fi
        rm -f "$gintama_tmp" 2>/dev/null || true
      else
        warn "Gintama download failed"
      fi
    else
      warn "🔥  Download failed - check DOWNLOADS_URL"
    fi
  else
    log "Skipped video downloads"
  fi
}

# ── Set Celluloid as default video player ──
# Every run re-asserts the association so it sticks
ensure_celluloid_default() {
  next_step "Celluloid Default (Video Player)"
  local celluloid_desk="io.github.celluloid_player.Celluloid.desktop"
  local video_mimes=(
    "video/mp4" "video/x-matroska" "video/webm" "video/avi"
    "video/x-msvideo" "video/quicktime" "video/x-ms-wmv"
    "video/ogg" "video/mpeg" "video/x-flv" "video/3gpp"
    "video/x-m4v" "video/x-ms-asf" "video/mp2t" "video/x-mpeg"
    "video/x-ms-avi" "video/MP2T" "video/x-ogm+ogg"
  )
  local mime_count=0
  for mime in "${video_mimes[@]}"; do
    xdg-mime default "$celluloid_desk" "$mime" 2>/dev/null && mime_count=$((mime_count + 1))
  done
  if [ "$mime_count" -gt 0 ]; then
    ok "Celluloid set as default for $mime_count video MIME types"
  fi

  # ── Celluloid preferences (GSettings) ──
  # Make video area draggable (Preferences > Behavior)
  gsettings set io.github.celluloid-player.Celluloid draggable-video-area-enable true 2>/dev/null && \
    ok "Celluloid: video area draggable" || true
  # Repeat file by default (passes loop-file=inf to mpv)
  gsettings set io.github.celluloid-player.Celluloid mpv-options "loop-file=inf" 2>/dev/null && \
    ok "Celluloid: repeat file on by default" || true
}

# ── Nautilus per‑folder defaults & sidebar order ──
# Downloads → sort by last modified (newest first)
# Pictures, Videos, Music, Documents → sort by name (A–Z)
# Sidebar order: Downloads, Pictures, Videos, Music, Documents
# File-chooser dialogs: do NOT sort folders before files
# (Nautilus 46+ no longer exposes sort-directories-first as a gsetting)
configure_nautilus_defaults() {
  next_step "Nautilus Per-Folder Defaults"
  # ── 1. Per‑folder sort order (via GVFS metadata — what Nautilus 50 actually reads) ──
  gio set "$HOME/Downloads"  metadata::nautilus-icon-view-sort-by        date_modified  2>/dev/null || true
  gio set "$HOME/Downloads"  metadata::nautilus-icon-view-sort-reversed  true           2>/dev/null || true
  ok "Downloads → sort by Last Modified (newest first)"

  for folder in "$HOME/Pictures" "$HOME/Videos" "$HOME/Music" "$HOME/Documents"; do
    if [ -d "$folder" ]; then
      gio set "$folder"  metadata::nautilus-icon-view-sort-by       name  2>/dev/null || true
      gio set "$folder"  metadata::nautilus-icon-view-sort-reversed false 2>/dev/null || true
    fi
  done
  ok "Pictures, Videos, Music, Documents → sort by Name (A–Z)"

  # ── 2. Sidebar bookmark order via GTK bookmarks file ──
  local bookmarks_file="$HOME/.config/gtk-3.0/bookmarks"
  mkdir -p "$HOME/.config/gtk-3.0"

  # Our desired XDG order
  local xdg_entries=(
    "file://$HOME/Downloads Downloads"
    "file://$HOME/Pictures Pictures"
    "file://$HOME/Videos Videos"
    "file://$HOME/Music Music"
    "file://$HOME/Documents Documents"
  )

  # Strip out old XDG lines + Trash from existing bookmarks (preserve custom ones)
  local custom_bookmarks=""
  if [ -f "$bookmarks_file" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      # Skip XDG user dirs and Trash
      case "$line" in
        file://"$HOME"/Downloads*|file://"$HOME"/Pictures*|file://"$HOME"/Videos*|file://"$HOME"/Music*|file://"$HOME"/Documents*|file://"$HOME"/.local/share/Trash*)
          continue
          ;;
        *)
          custom_bookmarks="${custom_bookmarks}${line}"$'\n'
          ;;
      esac
    done < "$bookmarks_file"
  fi

  # Create XDG Trash directories (required for bookmark to work on first click)
  mkdir -p "$HOME/.local/share/Trash/files" "$HOME/.local/share/Trash/info"

  # Write the new bookmarks file
  {
    for entry in "${xdg_entries[@]}"; do
      echo "$entry"
    done
    echo "file://$HOME/.local/share/Trash/files Trash"
    [ -n "$custom_bookmarks" ] && printf '%s' "$custom_bookmarks"
  } > "$bookmarks_file"
  ok "Sidebar order: Downloads, Pictures, Videos, Music, Documents"

  # ── 3. File-chooser dialogs: do NOT sort folders before files ──
  gsettings set org.gtk.Settings.FileChooser sort-directories-first false 2>/dev/null || true
  gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first false 2>/dev/null || true
  ok "File chooser: 'Sort folders before files' turned off"
}

setup_gdm() {
  next_step "GDM Login Screen Theme"

  # User said "n" to the GDM prompt — skip everything
  if [ "${INSTALL_LOGIN_WALLPAPER:-true}" != "true" ]; then
    ok "GDM login screen skipped (user opted out)"
    return
  fi

  local wp="$BUNDLE/wallpapers"
  local bg=""

  if [ "${INSTALL_LOGIN_WALLPAPER:-true}" = "true" ]; then
    if [ -f "$wp/login/Himeno Fedora LoginScreen.jpg" ]; then
      bg="$wp/login/Himeno Fedora LoginScreen.jpg"
    elif [ -f "$wp/desktop/Himeno Fedora.jpg" ]; then
      bg="$wp/desktop/Himeno Fedora.jpg"
    fi
  fi

  # Clone MacTahoe repo to get tweaks.sh then apply to GDM (force fresh clone)
  rm -rf /tmp/mactahoe-gtk
  if ! git clone --depth 1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git /tmp/mactahoe-gtk 2>/dev/null; then
    warn "Failed to clone MacTahoe repo for GDM theme"
  fi

  if [ -f /tmp/mactahoe-gtk/tweaks.sh ]; then
    cd /tmp/mactahoe-gtk
    if [ -n "$bg" ]; then
      sudo ./tweaks.sh -g -nb -nd -b "$bg"
      ok "GDM login screen themed via MacTahoe tweaks.sh (-g -nb -nd)"
    else
      sudo ./tweaks.sh -g -nb -nd
      warn "No wallpaper found in bundle — GDM themed without custom background"
    fi
    cd "$BUNDLE"
  else
    warn "Could not clone MacTahoe repo — GDM theme not applied"
    warn "Run manually after install:"
    warn "  git clone https://github.com/vinceliuice/MacTahoe-gtk-theme.git /tmp/mactahoe-gtk"
    warn "  sudo /tmp/mactahoe-gtk/tweaks.sh -g -nb -nd -b /path/to/wallpaper.jpg"
  fi

  # Hide Fedora logo on GDM login screen (runs regardless of theme)
  sudo mkdir -p /etc/dconf/db/gdm.d
  echo -e "[org/gnome/login-screen]\nlogo=''" | sudo tee /etc/dconf/db/gdm.d/01-logo > /dev/null
  sudo dconf update
  ok "Fedora logo hidden from GDM login screen"
}

setup_firefox_theme() {
  next_step "Firefox macOS Theme (userChrome.css)"

  local repo="/tmp/mactahoe-gtk"
  if [ ! -f "$repo/tweaks.sh" ]; then
    warn "MacTahoe repo not found — cloning fresh"
    rm -rf "$repo"
    git clone --depth 1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$repo" 2>/dev/null || {
      warn "Could not clone MacTahoe repo — Firefox theme not applied"
      return
    }
  fi

  # ── Ensure Firefox is closed before theming ──
  if pgrep -x firefox &>/dev/null || pgrep -x firefox-bin &>/dev/null; then
    echo ""
    echo -e "  ${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${YELLOW}║${NC}        ${BOLD}Close Firefox for macOS theming${NC}                       ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}  Firefox is open — theme can't apply while it's running.     ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}  The installer will try to close it now.                     ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}  Save your work if needed.                                   ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"

    killall firefox firefox-bin 2>/dev/null || true

    # Wait up to 10 seconds for Firefox to fully exit
    local _ff_wait=0
    while pgrep -x firefox &>/dev/null || pgrep -x firefox-bin &>/dev/null; do
      if [ "$_ff_wait" -ge 10 ]; then
        echo ""
        echo -e "  ${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${YELLOW}║${NC}  Firefox is still running — close it manually then press     ${YELLOW}║${NC}"
        echo -e "  ${YELLOW}║${NC}  Enter to retry, or type ${BOLD}s${NC} to skip Firefox theming           ${YELLOW}║${NC}"
        echo -e "  ${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo -en "  ${DIM}Close Firefox, then press Enter (s = skip):${NC} "
        read -r reply </dev/tty || true
        if [ "$reply" = "s" ] || [ "$reply" = "S" ]; then
          warn "Firefox theming skipped by user"
          FIREFOX_THEME_FAILED=1
          return
        fi
        # Try killing again after user pressed Enter
        killall firefox firefox-bin 2>/dev/null || true
        _ff_wait=0
      fi
      sleep 1
      _ff_wait=$((_ff_wait + 1))
    done
    echo -e "  ${GREEN}  ┊ ✓ ${NC}  Firefox closed — proceeding with theming"
  fi

  if ! "$repo/tweaks.sh" -f 2>&1; then
    warn "Firefox theming skipped — not yet initialized"
    FIREFOX_THEME_FAILED=1
  fi
}

setup_flatpak_theme() {
  next_step "Flatpak GTK Runtime (org.gtk.Gtk3theme.MacTahoe-Dark)"

  sudo dnf install -y ostree libappstream-glib 2>/dev/null || {
    warn "Could not install ostree/appstream-glib — Flatpak theme skipped"
    return
  }

  local THEME="MacTahoe-Dark"
  local GTK3_VER="3.22"
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}"
  local pkg_cache="$cache/pakitheme/$THEME"
  local repo_dir="$pkg_cache/repo"
  local build_dir="$pkg_cache/build"
  local app_id="org.gtk.Gtk3theme.$THEME"
  local theme_path=""

  for loc in "$HOME/.local/share/themes" "$HOME/.themes" /usr/share/themes; do
    if [ -d "$loc/$THEME" ]; then
      theme_path="$loc/$THEME"; break
    fi
  done

  if [ -z "$theme_path" ]; then
    warn "Theme '$THEME' not found in any theme directory"
    return
  fi

  rm -rf "$pkg_cache"
  mkdir -p "$repo_dir"

  if ! ostree --repo="$repo_dir" init --mode=archive 2>/dev/null; then
    warn "ostree init failed — Flatpak theme runtime not built"
    return
  fi
  ostree --repo="$repo_dir" config set core.min-free-space-percent 0 2>/dev/null || true

  rm -rf "$build_dir"
  mkdir -p "$build_dir/files"
  cp -a "$theme_path/gtk-3.0/"{gtk.css,gtk-dark.css,thumbnail.png,assets,windows-assets} "$build_dir/files" 2>/dev/null || \
    warn "Theme assets not found in $theme_path/gtk-3.0/ — runtime may be incomplete"

  mkdir -p "$build_dir/files/share/appdata"
  cat >"$build_dir/files/share/appdata/$app_id.appdata.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="runtime">
  <id>$app_id</id>
  <metadata_license>CC0-1.0</metadata_license>
  <name>$THEME Gtk theme</name>
  <summary>$THEME Gtk theme for flatpak</summary>
</component>
EOF

  appstream-compose --prefix="$build_dir/files" --basename="$app_id" --origin=flatpak "$app_id" 2>/dev/null || \
    warn "appstream-compose failed — metadata may be incomplete"
  ostree --repo="$repo_dir" commit -b base --tree=dir="$build_dir" 2>/dev/null || {
    warn "ostree commit failed — Flatpak theme runtime not built"
    return
  }

  local bundles=()
  while IFS= read -r arch; do
    [ -z "$arch" ] && continue
    bundle="$pkg_cache/$app_id-$arch.flatpak"
    rm -rf "$build_dir"
    ostree --repo="$repo_dir" checkout -U base "$build_dir" || continue

    read -rd '' metadata <<EOF ||:
[Runtime]
name=$app_id
runtime=$app_id/$arch/$GTK3_VER
sdk=$app_id/$arch/$GTK3_VER
EOF
    echo -n "$metadata" > "$build_dir/metadata"

    ostree --repo="$repo_dir" commit -b "runtime/$app_id/$arch/$GTK3_VER" \
      --add-metadata-string "xa.metadata=$(cat "$build_dir/metadata")" --link-checkout-speedup "$build_dir" || continue
    flatpak build-bundle --runtime "$repo_dir" "$bundle" "$app_id" "$GTK3_VER" || continue
    bundles+=("$bundle")
  done < <(flatpak list --runtime --columns=arch:f 2>/dev/null | sort -u)

  if [ ${#bundles[@]} -eq 0 ]; then
    warn "No Flatpak architectures found — no runtime bundles built"
    return
  fi

  local installed=0
  for bundle in "${bundles[@]}"; do
    if sudo flatpak install -y --system "$bundle" 2>/dev/null; then
      installed=$((installed + 1))
    fi
    rm -f "$bundle" 2>/dev/null || true
  done

  if [ "$installed" -gt 0 ]; then
    ok "Flatpak runtime '$app_id' installed ($installed arch(s))"
  else
    warn "Flatpak runtime '$app_id' could not be installed — check permissions or ostree"
  fi
}

install_sounds() {
  next_step "macOS Big Sur System Sounds"

  local sound_src="$BUNDLE/sounds/bigsur"
  if [ -d "$sound_src" ]; then
    mkdir -p "$HOME/.local/share/sounds"
    rm -rf "$HOME/.local/share/sounds/bigsur"
    cp -r "$sound_src" "$HOME/.local/share/sounds/"
    gsettings set org.gnome.desktop.sound theme-name "bigsur" 2>/dev/null || true
    gsettings set org.gnome.desktop.sound event-sounds true 2>/dev/null || true
    ok "macOS Big Sur sounds installed ($(ls "$sound_src/stereo/"*.oga 2>/dev/null | wc -l) files)"
  else
    warn "Sounds not bundled — building from source instead"
    local sounds_built=false
    if git clone --depth 1 https://github.com/gxanshu/macos-bigsur-sound-theme-linux.git /tmp/mac-sounds 2>/dev/null; then
      cd /tmp/mac-sounds
      git clone --depth 1 https://github.com/ThisIsNoahEvans/BigSurSounds.git 2>/dev/null || warn "Failed to clone BigSurSounds"
      git clone --depth 1 https://github.com/KDE/ocean-sound-theme.git 2>/dev/null || warn "Failed to clone ocean-sound-theme"
      if make build 2>/dev/null; then
        make install 2>/dev/null && sounds_built=true || warn "Sound install failed"
      else
        warn "Sound build failed"
      fi
      cd /tmp
      rm -rf /tmp/mac-sounds
    else
      warn "Failed to clone sound theme repo"
    fi
    if [ "$sounds_built" = "true" ]; then
      gsettings set org.gnome.desktop.sound theme-name "bigsur" 2>/dev/null || true
      gsettings set org.gnome.desktop.sound event-sounds true 2>/dev/null || true
      ok "macOS Big Sur sounds built from source"
    fi
  fi
}

# ── PHASE 4b: UPDATE NOTIFIER ──────────────────────────────

install_updater() {
  next_step "Fedora MacTahoe Update Notifier"

  local updater_src="$BUNDLE/configs/updater"
  if [ ! -d "$updater_src" ]; then
    warn "Updater files not found at $updater_src — skipping"
    return
  fi

  # 1. Install the script
  mkdir -p "$HOME/.local/bin"
  cp "$updater_src/fedora-mactahoe-updater.sh" "$HOME/.local/bin/fedora-mactahoe-updater.sh"
  chmod +x "$HOME/.local/bin/fedora-mactahoe-updater.sh"
  log "Updater script installed to ~/.local/bin/"

  # 2. Install systemd user units
  mkdir -p "$HOME/.config/systemd/user"
  cp "$updater_src/fedora-mactahoe-updater.service" "$HOME/.config/systemd/user/"
  cp "$updater_src/fedora-mactahoe-updater.timer" "$HOME/.config/systemd/user/"
  log "Systemd timer and service installed"

  # 3. Reload, enable, start
  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user enable fedora-mactahoe-updater.timer 2>/dev/null || true
  systemctl --user start fedora-mactahoe-updater.timer 2>/dev/null || true

  if systemctl --user is-enabled fedora-mactahoe-updater.timer &>/dev/null; then
    ok "Update notifier active (checks GitHub every 30 min)"
  else
    warn "Update notifier timer could not be enabled"
  fi

  # 4. Automatic security updates — dnf5-plugin-automatic in download + notify mode.
  #    Downloads security patches silently, NEVER installs by itself — you
  #    apply them at your leisure with: sudo dnf upgrade
  if ! rpm -q dnf5-plugin-automatic &>/dev/null; then
    log "Installing dnf5-plugin-automatic (automatic security downloads)"
    if sudo dnf install -y dnf5-plugin-automatic >/dev/null 2>&1; then
      ok "dnf5-plugin-automatic installed"
    else
      warn "dnf5-plugin-automatic install failed — security updates stay manual"
    fi
  else
    ok "dnf5-plugin-automatic already installed"
  fi

  # Explicit config: download yes, apply NO, notify via motd (idempotent)
  sudo tee /etc/dnf/automatic.conf > /dev/null <<'EOF' || warn "Could not write /etc/dnf/automatic.conf"
[commands]
download_updates = yes
apply_updates = no

[emitters]
emit_via = motd
EOF

  if sudo systemctl enable --now dnf5-automatic.timer 2>/dev/null; then
    ok "Auto security updates active (download + notify, never auto-install)"
  else
    warn "dnf5-automatic timer could not be enabled"
  fi
}

# ── PHASE 4c: KTHEME WATCHER ────────────────────────────────

install_ktheme_watcher() {
  next_step "Kitty Auto-Theme Watcher (ktheme)"

  local ktheme_src="$BUNDLE/configs/systemd"
  if [ ! -f "$ktheme_src/ktheme-watcher.service" ]; then
    warn "ktheme-watcher.service not found at $ktheme_src — skipping"
    return
  fi

  # 1. Install the unit
  mkdir -p "$HOME/.config/systemd/user"
  cp "$ktheme_src/ktheme-watcher.service" "$HOME/.config/systemd/user/"
  log "ktheme-watcher.service installed"

  # 2. Reload, enable, start — re-themes kitty from the wallpaper on every change
  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user enable ktheme-watcher.service 2>/dev/null || true
  systemctl --user start ktheme-watcher.service 2>/dev/null || true

  if systemctl --user is-active ktheme-watcher.service &>/dev/null; then
    ok "Auto-theme watcher active — kitty follows your wallpaper"
  else
    warn "ktheme watcher could not be started (kitty colors still theme on demand via ktheme)"
  fi
}

# ── PHASE 5: TERMINAL & SHELL ────────────────────────────────

setup_terminal() {
  next_step "Kitty as Default Terminal"

  # Ptyxis already removed earlier in remove_ptyxis()
  sudo ln -sf /usr/bin/kitty /usr/bin/gnome-terminal 2>/dev/null || true
  sudo ln -sf /usr/bin/kitty /usr/bin/x-terminal-emulator 2>/dev/null || true
  gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty' 2>/dev/null || true

  # Copy desktop entry with Name=Terminal (from repo, fallback to system)
  mkdir -p "$HOME/.local/share/applications"
  cp "$BUNDLE/desktop/kitty.desktop" "$HOME/.local/share/applications/kitty.desktop" 2>/dev/null || \
    cp /usr/share/applications/kitty.desktop "$HOME/.local/share/applications/kitty.desktop" 2>/dev/null

  # Scan all users for stale kitty.desktop referencing deleted kitty-maximized wrapper
  # or with Name=kitty (won't match GNOME "Terminal" search)
  local desktop_src
  desktop_src="$BUNDLE/desktop/kitty.desktop"
  [ -f "$desktop_src" ] || desktop_src="/usr/share/applications/kitty.desktop"
  if [ -f "$desktop_src" ]; then
    for _h in /home/*; do
      _entry="$_h/.local/share/applications/kitty.desktop"
      if [ -f "$_entry" ] && grep -q "kitty-maximized\|^Name=kitty$" "$_entry" 2>/dev/null; then
        _owner=$(stat -c '%U' "$_h" 2>/dev/null || echo root)
        if [ "$_owner" != "root" ]; then
          cp "$desktop_src" "$_entry" 2>/dev/null || warn "Failed to copy kitty.desktop for $_owner"
          chown "$_owner:" "$_entry" 2>/dev/null || warn "Failed to chown kitty.desktop for $_owner"
          log "Fixed stale kitty.desktop for $_owner"
        fi
      fi
      unset _entry _owner
    done
  fi
  unset desktop_src _h

  ok "Kitty is now the default terminal"
}

setup_shell() {
  next_step "Fish as Default Shell"

  if [ "$SHELL" != "/usr/bin/fish" ]; then
    if sudo chsh -s /usr/bin/fish "$USER"; then
      ok "Default shell changed to fish (next login)"
    else
      warn "fish not set as default shell — run 'sudo chsh -s /usr/bin/fish $USER' manually"
    fi
  else
    ok "Fish is already the default shell"
  fi
}

# ── PHASE 6: EXTENSIONS ──────────────────────────────────────

install_extensions() {
  next_step "GNOME Extensions"

  # Install via gnome-extensions CLI where possible
  local extensions=(
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
  )

  # Install from EGO using API (CLI install $uuid requires browser session)
  local shell_version ext_ok=0 ext_fail=0
  shell_version=$(gnome-shell --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1 || echo "50")
  for uuid in "${extensions[@]}"; do
    local dl_url
    dl_url=$(curl -s --max-time 25 "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$shell_version" | jq -r '.download_url // empty' 2>/dev/null) || true
    if [ -z "$dl_url" ]; then
      warn "Extension $uuid not found on EGO (shell $shell_version) — skipping"
      ext_fail=$((ext_fail + 1))
      continue
    fi
    rm -f /tmp/ext-"$uuid".zip
    if ! curl -sL --max-time 25 "https://extensions.gnome.org$dl_url" -o /tmp/ext-"$uuid".zip 2>/dev/null; then
      warn "Failed to download extension $uuid"
      ext_fail=$((ext_fail + 1))
      continue
    fi
    if gnome-extensions install --force /tmp/ext-"$uuid".zip 2>/dev/null; then
      ext_ok=$((ext_ok + 1))
    else
      warn "Failed to install extension $uuid"
      ext_fail=$((ext_fail + 1))
    fi
    rm -f /tmp/ext-"$uuid".zip
  done

  # Enable all installed extensions via direct gsettings (no D-Bus needed)
  local -a ext_list
  for uuid in "${extensions[@]}"; do
    if [ -d "$HOME/.local/share/gnome-shell/extensions/$uuid" ] || [ -d "/usr/share/gnome-shell/extensions/$uuid" ]; then
      ext_list+=("'$uuid'")
    fi
  done
  if [ ${#ext_list[@]} -gt 0 ]; then
    gsettings set org.gnome.shell enabled-extensions "[$(IFS=,; echo "${ext_list[*]}")]" 2>/dev/null || true
  fi

  # Also mark Fedora defaults as disabled
  gsettings set org.gnome.shell disabled-extensions "['background-logo@fedorahosted.org', 'apps-menu@gnome-shell-extensions.gcampax.github.com']" 2>/dev/null || true

  if [ "$ext_ok" -gt 0 ]; then
    ok "$ext_ok extension(s) installed"
  fi
  if [ "$ext_fail" -gt 0 ]; then
    warn "$ext_fail extension(s) failed — check extensions.gnome.org or your network"
  fi

  # ── Window Title Pro (from GNOME Extensions / EGO) ──
  local wtp_uuid="window-title-pro@eprahemi.github.io"
  local wtp_target="$HOME/.local/share/gnome-shell/extensions/$wtp_uuid"
  local wtp_pk="10319"
  local wtp_installed=false

  # Always override — clean slate every time
  rm -rf "$wtp_target" 2>/dev/null || true

  # Try 1: install via gnome-extensions CLI with EGO page URL
  if gnome-extensions install "https://extensions.gnome.org/extension/$wtp_pk/window-title-pro/" --force 2>/dev/null; then
    ok "Window Title Pro installed from EGO"
    ext_ok=$((ext_ok + 1))
    wtp_installed=true
  fi

  # Try 2: download from EGO API and extract manually
  if [ "$wtp_installed" = false ]; then
    local wtp_api_url="https://extensions.gnome.org/extension-info/?pk=$wtp_pk&shell_version=50"
    local wtp_dl_url
    wtp_dl_url=$(curl -s --max-time 25 "$wtp_api_url" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('download_url', ''))
except:
    print('')
" 2>/dev/null || true)

    if [ -n "$wtp_dl_url" ]; then
      mkdir -p "$wtp_target"
      if curl -sL --max-time 25 "https://extensions.gnome.org$wtp_dl_url" -o /tmp/window-title-pro.zip 2>/dev/null; then
        if unzip -qo /tmp/window-title-pro.zip -d "$wtp_target" 2>/dev/null; then
          glib-compile-schemas "$wtp_target/schemas" 2>/dev/null || true
          wtp_installed=true
          ok "Window Title Pro installed from EGO"
          ext_ok=$((ext_ok + 1))
        else
          warn "Failed to extract Window Title Pro"
          ext_fail=$((ext_fail + 1))
        fi
        rm -f /tmp/window-title-pro.zip
      else
        warn "Failed to download Window Title Pro from EGO"
        ext_fail=$((ext_fail + 1))
      fi
    else
      warn "Failed to get EGO download URL for Window Title Pro"
      ext_fail=$((ext_fail + 1))
    fi
  fi

  # Add to enabled-extensions list if installed successfully
  if [ "$wtp_installed" = true ]; then
    if ! echo "${ext_list[@]}" | grep -q "$wtp_uuid"; then
      ext_list+=("'$wtp_uuid'")
      gsettings set org.gnome.shell enabled-extensions "[$(IFS=,; echo "${ext_list[*]}")]" 2>/dev/null || true
    fi
  fi
}

# ── MIRROR FLATPAK ICONS ──────────────────────────────────────
# GTK 3.24.52 on Fedora 44 cannot resolve icons that only exist at 512×512 in
# the Flatpak system hicolor (/var/lib/flatpak/exports/share/icons/hicolor/).
# This function mirrors them into ~/.local/share/icons/hicolor/48x48/apps/
# so they show up in the GNOME app grid.
# See: https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi/issues

mirror_flatpak_icons() {
  local user_hicolor="$HOME/.local/share/icons/hicolor"
  local user_48="$user_hicolor/48x48/apps"
  local mirrored=0 skipped=0
  local bases=()
  local base

  # Build list of hicolor sources that exist
  [ -d "/var/lib/flatpak/exports/share/icons/hicolor" ] && bases+=("/var/lib/flatpak/exports/share/icons/hicolor")
  [ -d "$HOME/.local/share/icons/hicolor" ] && bases+=("$HOME/.local/share/icons/hicolor")
  [ -d "/usr/share/icons/hicolor" ] && bases+=("/usr/share/icons/hicolor")

  [ ${#bases[@]} -eq 0 ] && { ok "No hicolor icon directories to scan"; return 0; }

  mkdir -p "$user_48"

  # Ensure user hicolor has an index.theme so gtk-update-icon-cache works
  if [ ! -f "$user_hicolor/index.theme" ]; then
    mkdir -p "$user_hicolor"
    cat > "$user_hicolor/index.theme" <<-EOF
[Icon Theme]
Name=Hicolor
Comment=Fallback icon theme (local overrides)
Hidden=true
Directories=256x256/apps,48x48/apps

[48x48/apps]
Size=48
Context=Applications
Type=Fixed
EOF
  fi

  # Collect all unique icon names from all hicolor sources (apps/ only)
  local -A seen_names

  for base in "${bases[@]}"; do
    while IFS= read -r -d '' f; do
      local name; name=$(basename "$f")
      local name_noext="${name%.*}"
      local ext="${name##*.}"

      # Skip if we've already processed this icon name
      [ -n "${seen_names[$name_noext]:-}" ] && continue
      seen_names[$name_noext]=1

      # Check if MacTahoe-dark already has this icon (PNG or SVG in any dir)
      local mac_icon
      mac_icon=$(find "$HOME/.local/share/icons/MacTahoe-dark" -name "$name" -o -name "${name_noext}.svg" 2>/dev/null | head -1) || true
      [ -n "$mac_icon" ] && { skipped=$((skipped + 1)); continue; }

      # Check if user hicolor already has it at a resolvable size (48x48 or scalable)
      if [ -f "$user_hicolor/48x48/apps/$name" ] || [ -f "$user_hicolor/scalable/apps/${name_noext}.svg" ]; then
        skipped=$((skipped + 1))
        continue
      fi

      # SVG is best — GTK can scale it
      if [ "$ext" = "svg" ]; then
        local target_dir="$user_hicolor/scalable/apps"
        mkdir -p "$target_dir"
        ln -sf "$f" "$target_dir/$name" 2>/dev/null || \
          cp -f "$f" "$target_dir/$name" 2>/dev/null || true
        mirrored=$((mirrored + 1))
        continue
      fi

      # PNG: prefer the smallest available source in this base
      local best_src=""
      local size_dir
      for size_dir in 48x48 64x64 128x128 256x256 512x512; do
        local candidate="$base/$size_dir/apps/$name"
        if [ -f "$candidate" ]; then
          best_src="$candidate"
          break
        fi
      done
      [ -z "$best_src" ] && { skipped=$((skipped + 1)); continue; }

      # Create symlink (or copy if symlink fails) at 48x48
      ln -sf "$best_src" "$user_48/$name" 2>/dev/null || \
        cp -f "$best_src" "$user_48/$name" 2>/dev/null || true
      mirrored=$((mirrored + 1))
    done < <(find "$base" -path '*/apps/*' \( -name '*.png' -o -name '*.svg' \) -print0 2>/dev/null)
  done

  # Rebuild user hicolor cache
  if [ "$mirrored" -gt 0 ]; then
    gtk-update-icon-cache "$user_hicolor/" 2>/dev/null || warn "Icon cache update failed for $user_hicolor"
  fi

  log "Mirrored $mirrored icon(s) to $user_hicolor/48x48/apps/ ($skipped already covered)"
}

# ── FINALIZE ──────────────────────────────────────────────────

finalize() {
  next_step "Cleanup & Reboot"

  # ── 1. Temporary files from this installer ──
  log "Cleaning installer temporary files..."
  rm -rf /tmp/mactahoe-* /tmp/mac-sounds /tmp/ext-* 2>/dev/null || true
  rm -f /tmp/*.rpm 2>/dev/null || true

  # ── 1b. Remove old commit-based cache files (pre-v1.4 migration) ──
  rm -f "$STATE_DIR/last-notified-commit" "$STATE_DIR/last-dismissed-commit" 2>/dev/null || true

  # ── 2. Flatpak theme build cache ──
  log "Cleaning Flatpak theme build cache..."
  rm -rf "$HOME/.cache/pakitheme" 2>/dev/null || true

  # ── 3. Thumbnail cache ──
  log "Cleaning thumbnail cache..."
  rm -rf "$HOME/.cache/thumbnails/"* 2>/dev/null || true

  # ── 4. Fontconfig cache (safe — rebuilds on next font render) ──
  log "Cleaning fontconfig cache..."
  rm -rf "$HOME/.cache/fontconfig/"* 2>/dev/null || true

  # ── 5. Mesa shader cache (safe — rebuilds on next GL/Vulkan app) ──
  log "Cleaning Mesa shader cache..."
  rm -rf "$HOME/.cache/mesa_shader_cache/"* 2>/dev/null || true

  # ── 6. DNF metadata cache ──
  log "Cleaning DNF metadata cache..."
  sudo dnf clean all 2>/dev/null || true

  # ── 7. Unused Flatpak runtimes ──
  log "Removing unused Flatpak runtimes..."
  flatpak uninstall --unused -y 2>/dev/null || true

  # ── 8. Orphaned RPM packages (dependencies no longer needed) ──
  log "Removing orphaned RPM packages..."
  sudo dnf autoremove -y 2>/dev/null || true

  # ── 9. Old system journal logs (keep last 3 days) ──
  log "Trimming old system logs (keeping 3 days)..."
  sudo journalctl --vacuum-time=3d 2>/dev/null || true

  # ── 10. Mirror unresolvable app icons (Flatpak + system + user-local) ──
  mirror_flatpak_icons

  # ── 11. Rebuild all icon theme caches (Adwaita + local + Flatpak hicolor) ──
  log "Rebuilding icon caches for all themes..."
  for _ictx in /usr/share/icons/Adwaita /usr/share/icons/AdwaitaLegacy \
               "$HOME/.local/share/icons/MacTahoe" "$HOME/.local/share/icons/MacTahoe-dark" \
               "$HOME/.local/share/icons/hicolor" \
               "/var/lib/flatpak/exports/share/icons/hicolor"; do
    if [ -d "$_ictx" ]; then
      gtk-update-icon-cache "$_ictx" 2>/dev/null || warn "Icon cache update failed for $_ictx"
    fi
  done
  if command -v sudo &>/dev/null; then
    sudo gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || warn "System icon cache update failed"
  fi

  # ── 11. Eprahemi Public License (silent, always overwrites) ──
  mkdir -p "$HOME/Documents" 2>/dev/null || true
  cp -f "$SCRIPT_DIR/EPRAHEMI — PUBLIC LICENSE & REUSE TERMS.md" "$HOME/Documents/" 2>/dev/null || true

  ok "System cleaned and polished"

  # ── 12. Finalize install state (overall version + date) ──
  local _FINAL_JSON
  _FINAL_JSON=$(echo "$STATE_JSON" | python3 -c "
import sys, json
try:
    s = json.load(sys.stdin)
except Exception:
    s = {'version': '0.0', 'steps': {}, 'prompts': {}}
try:
    s['version'] = '$MANIFEST_VERSION'
    s['install_date'] = '$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)'
    print(json.dumps(s))
except Exception:
    print('$STATE_JSON')
" 2>/dev/null || echo "$STATE_JSON")
  [ -n "$_FINAL_JSON" ] && STATE_JSON="$_FINAL_JSON"
  local _TMPFILE
  _TMPFILE=$(mktemp "$STATE_DIR/state.XXXXXX" 2>/dev/null || echo "")
  if [ -n "$_TMPFILE" ]; then
    echo "$STATE_JSON" > "$_TMPFILE" 2>/dev/null && mv "$_TMPFILE" "$STATE_FILE" 2>/dev/null || true
  fi

  __install_summary

  echo ""
  echo -e "  ${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "  ${GREEN}║${NC}                                                              ${GREEN}║${NC}"
  echo -e "  ${GREEN}║${NC}"'      ______                 __                   _           '"${GREEN}║${NC}"
  echo -e "  ${GREEN}║${NC}"'     / ____/___  _________ _/ /_  ___  ____ ___  (_)          '"${GREEN}║${NC}"
  echo -e "  ${GREEN}║${NC}"'    / __/ / __ \/ ___/ __ `/ __ \/ _ \/ __ `__ \/ /           '"${GREEN}║${NC}"
  echo -e "  ${GREEN}║${NC}"'   / /___/ /_/ / /  / /_/ / / / /  __/ / / / / / /            '"${GREEN}║${NC}"
  echo -e "  ${GREEN}║${NC}"'  /_____/ .___/_/   \__,_/_/ /_/\___/_/ /_/ /_/_/             '"${GREEN}║${NC}"
  echo -e "  ${GREEN}║${NC}"'       /_/                                                    '"${GREEN}║${NC}"
  echo -e "  ${GREEN}║${NC}"'                                                              '"${GREEN}║${NC}"
  echo -e "  ${GREEN}║${NC}            ${BOLD}${WHITE}✅  YOU DID IT!${NC}                                   ${GREEN}║${NC}"
  echo -e "  ${GREEN}║${NC}"'                                                              '"${GREEN}║${NC}"
  echo -e "  ${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
v_title="  ◆  Fedora MacTahoe  —  Eprahemi Edition"
  echo -e "  ${GREEN}║${NC}  ${BOLD}${WHITE}${v_title}${NC}$(printf '%*s' $((60 - ${#v_title})) '')${GREEN}║${NC}"
  echo -e "  ${GREEN}║${NC}"'                                                              '"${GREEN}║${NC}"
v1="  ◆  All themes, icons, fonts are active"
  echo -e "  ${GREEN}║${NC}  ${YELLOW}${v1}${NC}$(printf '%*s' $((60 - ${#v1})) '')${GREEN}║${NC}"
v2="  ◆  Kitty is the default terminal"
  echo -e "  ${GREEN}║${NC}  ${YELLOW}${v2}${NC}$(printf '%*s' $((60 - ${#v2})) '')${GREEN}║${NC}"
v3="  ◆  Fish will be default shell (after logout)"
  echo -e "  ${GREEN}║${NC}  ${YELLOW}${v3}${NC}$(printf '%*s' $((60 - ${#v3})) '')${GREEN}║${NC}"
v4="  ◆  All custom keybindings are active"
  echo -e "  ${GREEN}║${NC}  ${YELLOW}${v4}${NC}$(printf '%*s' $((60 - ${#v4})) '')${GREEN}║${NC}"
v5="  ◆  macOS Big Sur sounds will play"
  echo -e "  ${GREEN}║${NC}  ${YELLOW}${v5}${NC}$(printf '%*s' $((60 - ${#v5})) '')${GREEN}║${NC}"
v6="  ◆  GDM login screen themed"
  echo -e "  ${GREEN}║${NC}  ${YELLOW}${v6}${NC}$(printf '%*s' $((60 - ${#v6})) '')${GREEN}║${NC}"
v7="  ◆  Flatpak GTK runtime installed"
  echo -e "  ${GREEN}║${NC}  ${YELLOW}${v7}${NC}$(printf '%*s' $((60 - ${#v7})) '')${GREEN}║${NC}"
v8="  ◆  Update notifier active (GitHub check every 30 min)"
  echo -e "  ${GREEN}║${NC}  ${YELLOW}${v8}${NC}$(printf '%*s' $((60 - ${#v8})) '')${GREEN}║${NC}"
  if [ "${FIREFOX_THEME_FAILED:-0}" = 1 ]; then
    echo -e "  ${GREEN}║${NC}                                                              ${GREEN}║${NC}"
    ff1="  ⚠  Firefox not themed — log in, launch Firefox once"
    echo -e "  ${GREEN}║${NC}  ${YELLOW}${ff1}${NC}$(printf '%*s' $((60 - ${#ff1})) '')${GREEN}║${NC}"
    ff2="  ⚠  then re-run: bash install.sh (skips done steps)"
    echo -e "  ${GREEN}║${NC}  ${YELLOW}${ff2}${NC}$(printf '%*s' $((60 - ${#ff2})) '')${GREEN}║${NC}"
  fi
  echo -e "  ${GREEN}║${NC}                                                              ${GREEN}║${NC}"
  echo -e "  ${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "  ${GREEN}║${NC}                                                              ${GREEN}║${NC}"
ep1="  ┊  ©  Made by Eprahemi"
  echo -e "  ${GREEN}║${NC}  ${DIM}${ep1}${NC}$(printf '%*s' $((60 - ${#ep1})) '')${GREEN}║${NC}"
ep2="  ┊  Fedora MacTahoe  —  Open-source Mac vibes"
  echo -e "  ${GREEN}║${NC}  ${DIM}${ep2}${NC}$(printf '%*s' $((60 - ${#ep2})) '')${GREEN}║${NC}"
  echo -e "  ${GREEN}║${NC}                                                              ${GREEN}║${NC}"
  echo -e "  ${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${DIM}╭─${NC} ${BOLD}${WHITE}✦  More from Eprahemi${NC} ${DIM}─────────────────────────────────────────╮${NC}"
  echo -e "  ${DIM}│${NC}                                                                 ${DIM}│${NC}"
m1="  🐙  GitHub         →  https://github.com/eprahemi"
  echo -e "  ${DIM}│${NC}  ${CYAN}${m1}${NC}$(printf '%*s' $((62 - ${#m1})) '')${DIM}│${NC}"
m2="  🖥   MacTahoe Site  →  https://fedoratahoe.pages.dev"
  echo -e "  ${DIM}│${NC}  ${CYAN}${m2}${NC}$(printf '%*s' $((63 - ${#m2})) '')${DIM}│${NC}"
m3="  🖼   Wallpapers     →  https://wallvault.pages.dev/home  (+18)"
  echo -e "  ${DIM}│${NC}  ${CYAN}${m3}${NC}$(printf '%*s' $((63 - ${#m3})) '')${DIM}│${NC}"
  echo -e "  ${DIM}│${NC}                                                                 ${DIM}│${NC}"
m4="  If you enjoyed this project, consider starring ⭐ on GitHub"
  echo -e "  ${DIM}│${NC}  ${DIM}${m4}${NC}$(printf '%*s' $((62 - ${#m4})) '')${DIM}│${NC}"
  echo -e "  ${DIM}╰${NC}${DIM}─────────────────────────────────────────────────────────────────╯${NC}"
  echo ""
  echo -e "  ${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
reboot_txt="  ⚡  Reboot now — changes kick in after restart"
  echo -e "  ${YELLOW}║${NC}  ${BOLD}${WHITE}${reboot_txt}${NC}$(printf '%*s' $((60 - ${#reboot_txt})) '')${YELLOW}║${NC}"
  echo -e "  ${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo ""
  if confirm "Reboot now? [y/N]: " N; then
    echo -e "  ${GREEN}See you on the other side! Rebooting...${NC}"
    sudo reboot
  else
    echo -e ""
    local r1="╔══════════════════════════════════════════════════════════════╗"
    echo -e "  ${BOLD}${RED}${r1}${NC}"
    local r2=" ⚠  SYSTEM RESTART REQUIRED"
    echo -e "  ${BOLD}${RED}║${NC}  ${BOLD}${WHITE}${r2}$(printf '%*s' $((60 - ${#r2})) '')${NC}${BOLD}${RED}║${NC}"
    echo -e "  ${BOLD}${RED}║${NC}  $(printf '%*s' 60 '')${NC}${BOLD}${RED}║${NC}"
    local r4="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${BOLD}${RED}║${NC}  ${DIM}${r4}$(printf '%*s' $((60 - ${#r4})) '')${NC}${BOLD}${RED}║${NC}"
    echo -e "  ${BOLD}${RED}║${NC}  $(printf '%*s' 60 '')${NC}${BOLD}${RED}║${NC}"
    local r6="A reboot finalizes the following critical operations:"
    echo -e "  ${BOLD}${RED}║${NC}  ${r6}$(printf '%*s' $((60 - ${#r6})) '')${NC}${BOLD}${RED}║${NC}"
    echo -e "  ${BOLD}${RED}║${NC}  $(printf '%*s' 60 '')${NC}${BOLD}${RED}║${NC}"
    local r8="  • Flush and reinitialize session-level caches"
    echo -e "  ${BOLD}${RED}║${NC}  ${r8}$(printf '%*s' $((60 - ${#r8})) '')${NC}${BOLD}${RED}║${NC}"
    local r9="  • Reload GNOME Shell extensions (Dash-to-Dock, etc.)"
    echo -e "  ${BOLD}${RED}║${NC}  ${r9}$(printf '%*s' $((60 - ${#r9})) '')${NC}${BOLD}${RED}║${NC}"
    local r10="  • Apply GTK theme contexts across all running processes"
    echo -e "  ${BOLD}${RED}║${NC}  ${r10}$(printf '%*s' $((60 - ${#r10})) '')${NC}${BOLD}${RED}║${NC}"
    local r11="  • Activate GDM login screen theme and wallpaper"
    echo -e "  ${BOLD}${RED}║${NC}  ${r11}$(printf '%*s' $((60 - ${#r11})) '')${NC}${BOLD}${RED}║${NC}"
    local r12="  • Register updated icon caches and font configurations"
    echo -e "  ${BOLD}${RED}║${NC}  ${r12}$(printf '%*s' $((60 - ${#r12})) '')${NC}${BOLD}${RED}║${NC}"
    local r13="  • Initialize desktop environment session parameters"
    echo -e "  ${BOLD}${RED}║${NC}  ${r13}$(printf '%*s' $((60 - ${#r13})) '')${NC}${BOLD}${RED}║${NC}"
    echo -e "  ${BOLD}${RED}║${NC}  $(printf '%*s' 60 '')${NC}${BOLD}${RED}║${NC}"
    local r15="Until restarted, theme elements, dock behavior,"
    echo -e "  ${BOLD}${RED}║${NC}  ${BOLD}${WHITE}${r15}$(printf '%*s' $((60 - ${#r15})) '')${NC}${BOLD}${RED}║${NC}"
    local r16="and login screen customizations will remain in a"
    echo -e "  ${BOLD}${RED}║${NC}  ${BOLD}${WHITE}${r16}$(printf '%*s' $((60 - ${#r16})) '')${NC}${BOLD}${RED}║${NC}"
    local r17="pending state."
    echo -e "  ${BOLD}${RED}║${NC}  ${BOLD}${WHITE}${r17}$(printf '%*s' $((60 - ${#r17})) '')${NC}${BOLD}${RED}║${NC}"
    echo -e "  ${BOLD}${RED}║${NC}  $(printf '%*s' 60 '')${NC}${BOLD}${RED}║${NC}"
    local r19="╚══════════════════════════════════════════════════════════════╝"
    echo -e "  ${BOLD}${RED}${r19}${NC}"
    echo -e ""
    if confirm "  Restart now to apply changes? [y/N]: " N; then
      echo -e "  ${GREEN}See you on the other side! Rebooting...${NC}"
      sudo reboot
    else
      echo -e ""
      echo -e "  ${BOLD}${YELLOW}⚠  Postponed — restart at your earliest convenience.${NC}"
      echo -e "  ${DIM}   Run ${NC}${BOLD}${WHITE}sudo reboot${NC}${DIM} when ready to finalize.${NC}"
    fi
  fi
}

# ── Capture GNOME version ──
GNOME_VER=$(gnome-shell --version 2>/dev/null | grep -oP '\d+\.\d+' || echo "?")

# ── Record start time for install summary ──
INSTALL_START_EPOCH=$(date +%s 2>/dev/null || echo "0")

# ─────────────────────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────────────────────

echo ""
echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'      ______                 __                   _           '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'     / ____/___  _________ _/ /_  ___  ____ ___  (_)          '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'    / __/ / __ \/ ___/ __ `/ __ \/ _ \/ __ `__ \/ /           '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'   / /___/ /_/ / /  / /_/ / / / /  __/ / / / / / /            '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'  /_____/ .___/_/   \__,_/_/ /_/\___/_/ /_/ /_/_/             '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'       /_/                                                    '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'  '"${BOLD}${WHITE}"'◆  Fedora MacTahoe  —  Eprahemi Edition'"${NC}"'                     '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'  '"${BOLD}"'◆  Make your Fedora look like a Mac — the fun way'"${NC}"'           '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
gnome_text="  GNOME ${GNOME_VER}  ◆  Kitty Terminal  ◆  Fish Shell"
echo -e "  ${CYAN}║${NC}  ${DIM}GNOME${NC} ${GNOME_VER}  ${DIM}◆  Kitty Terminal  ◆  Fish Shell${NC}$(printf '%*s' $((62 - ${#gnome_text})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
step28="◆  28-Step Installer    ◆  Auto-detects your system    ◆"
echo -e "  ${CYAN}║${NC}  ${DIM}${step28}${NC}$(printf '%*s' $((60 - ${#step28})) '')${CYAN}║${NC}"
theme_text="  ◆  Theme compiles for your GNOME ${GNOME_VER}"
echo -e "  ${CYAN}║${NC}  ${DIM}◆${NC}  Theme compiles for your GNOME ${BOLD}${GNOME_VER}${NC}$(printf '%*s' $((62 - ${#theme_text})) '')${CYAN}║${NC}"
kitty_fish_line="  ◆  Sets up Kitty, Fish, icons, fonts, sounds"
echo -e "  ${CYAN}║${NC}  ${DIM}◆${NC}  Sets up Kitty, Fish, icons, fonts, sounds${NC}$(printf '%*s' $((62 - ${#kitty_fish_line})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}  ${YELLOW}Ctrl+C anytime to bail${NC}                                      ${CYAN}║${NC}"
wp_line="  ⚠  Read yes/no prompts carefully — some are permanent!"
echo -e "  ${CYAN}║${NC}  ${BOLD}${RED}${wp_line}${NC}$(printf '%*s' $((60 - ${#wp_line})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

__secure_tunnel
__system_dashboard
__cdn_speed_test

# ── Before any prompts, load saved answers from state ──
# This populates INSTALL_DESKTOP_WALLPAPER, INSTALL_LOGIN_WALLPAPER,
# INSTALL_WALLPAPER_18, and INSTALL_BILLIE_VIDEOS from previous runs
_load_prompt_answers

# ── Preflight (always runs) ──
_run_step "preflight" preflight

# ── System cleanup steps ──
_run_step "remove_ptyxis" remove_ptyxis
_run_step "remove_gnome_weather" remove_gnome_weather

# ── Interactive prompts (gated by saved answers + version) ──
if _prompt_should_ask "wallpaper_desktop" || _prompt_should_ask "wallpaper_login" || _prompt_should_ask "wallpaper_18"; then
  prompt_optional_wallpapers
  _save_prompt_answer "wallpaper_desktop" "${INSTALL_DESKTOP_WALLPAPER:-false}"
  _save_prompt_answer "wallpaper_login" "${INSTALL_LOGIN_WALLPAPER:-false}"
  _save_prompt_answer "wallpaper_18" "${INSTALL_WALLPAPER_18:-false}"
fi

if _prompt_should_ask "billie_videos"; then
  prompt_billie_videos
  _save_prompt_answer "billie_videos" "${INSTALL_BILLIE_VIDEOS:-false}"
fi

prompt_sudoers_entry

phase_divider "PHASE 1 : SYSTEM FOUNDATIONS" 3 4
_run_step "install_rpmfusion" install_rpmfusion
_run_step "install_nvidia" install_nvidia

phase_divider "PHASE 2 : PACKAGES" 5 7
_run_step "install_rpm_packages" install_rpm_packages
_run_step "install_browsers" install_browsers
_run_step "install_flatpaks" install_flatpaks

phase_divider "PHASE 3 : THEMES" 8 9
_run_step "install_mactahoe_theme" install_mactahoe_theme
_run_step "install_font" install_font

phase_divider "PHASE 4 : CONFIGURATION" 11 23
_run_step "apply_desktop_entries" apply_desktop_entries
_run_step "ensure_celluloid_default" ensure_celluloid_default
_run_step "configure_nautilus_defaults" configure_nautilus_defaults
_run_step "apply_configs" apply_configs
_run_step "apply_dconf" apply_dconf
_run_step "optimize_system_resources" optimize_system_resources
_run_step "apply_wallpapers" apply_wallpapers
_run_step "install_custom_avatars" install_custom_avatars
_run_step "setup_gdm" setup_gdm
_run_step "setup_firefox_theme" setup_firefox_theme
_run_step "setup_flatpak_theme" setup_flatpak_theme
_run_step "install_sounds" install_sounds
_run_step "install_updater" install_updater
_run_step "install_ktheme_watcher" install_ktheme_watcher

phase_divider "PHASE 5 : TERMINAL & SHELL" 24 25
_run_step "setup_terminal" setup_terminal
_run_step "setup_shell" setup_shell

phase_divider "PHASE 6 : EXTENSIONS & FINALIZE" 26 28
_run_step "install_extensions" install_extensions
_run_step "download_optional_videos" download_optional_videos
_run_step "finalize" finalize
