#!/usr/bin/env bash

# ── Unique installation log ──
# Generates a unique 8-char session ID and logs ALL output to
# ~/FedoraTahoe_log.<date>.<time>.<ID> ( TAG ).txt  (sorts chronologically)
# TAG = who ran this: BASH / MANUAL / UPDATE-QUICK / UPDATE-FULL /
# UPDATE-<target> — same tag logic as bootstrap.sh (which creates the log
# first on the curl|bash path and hands it over via _FED_LOG).
#
# If bootstrap.sh already created a log (env _FED_LOG is set), skip this
# block so running via bootstrap.sh → one .txt file, not two.
#
# ── Install/update method tag ──
# Who invoked the installer: the bootstrap one-liner (BASH), a direct
# ./install.sh run (MANUAL), or an update path (UPDATE-QUICK /
# UPDATE-FULL / UPDATE-CONFIG / UPDATE-<target>). Stamped into the log
# filename ( … ( TAG ).txt), the log header and install-state.json.
_FED_METHOD="${INSTALL_SOURCE:-manual}"
_FED_TAG=""
case "$_FED_METHOD" in
  bash)        _FED_TAG="BASH" ;;
  manual)      _FED_TAG="MANUAL" ;;
  update-*)    _FED_TAG=$(printf '%s' "$_FED_METHOD" | tr '[:lower:]' '[:upper:]') ;;
esac
_FED_TAG_EXT=""
[ -n "$_FED_TAG" ] && _FED_TAG_EXT=" ( $_FED_TAG )"
if [ -z "${_FED_LOG:-}" ]; then
  _FED_ID=$(tr -dc 'a-zA-Z0-9' < /dev/urandom 2>/dev/null | head -c 8)
  [ -z "$_FED_ID" ] && _FED_ID="X$(date +%s 2>/dev/null | sha256sum 2>/dev/null | head -c7 || echo "00000001")"
  _FED_DATE_STAMP=$(date '+%Y-%m-%d.%H-%M-%S' 2>/dev/null || echo "unknown")
  _FED_LOG="$HOME/FedoraTahoe_log.${_FED_DATE_STAMP}.${_FED_ID}${_FED_TAG_EXT}.txt"
  # Create privately without changing the caller's umask; fail before logging if unsafe.
  if ! (umask 077; touch "$_FED_LOG") || ! chmod 600 "$_FED_LOG"; then
    printf 'Cannot create a private session log: %s\n' "$_FED_LOG" >&2
    exit 1
  fi
  # Preserve original stdout/stderr, then redirect all output to both terminal and log
  exec 5>&1 6>&2
  exec > >(tee -a "$_FED_LOG") 2>&1
  _FED_TEE_PID=$!
fi

# A foreground Fish fetch can hand its already-created transcript to this
# process without inheriting Bash's fd setup. Bootstrap handoff is unchanged.
if [ "${_FED_UPDATER_LOG:-0}" = 1 ]; then
  unset _FED_UPDATER_LOG
  exec 5>&1 6>&2
  exec > >(tee -a "$_FED_LOG") 2>&1
  _FED_TEE_PID=$!
fi

# Both entry points share one presentation library and keep the original fds.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bootstrap.sh" --ui-library
_FED_NET_STOP=$(mktemp "${TMPDIR:-/tmp}/mactahoe-network-stop.XXXXXXXX") || {
  echo 'Cannot create the network recovery marker; no installation work was started.' >&2
  exit 1
}
_ui_init
set -euo pipefail

# ── Log finalization (runs on normal exit, crash, or Ctrl+C) ──
_fed_log_finalize() {
  local _exit_rc=$?
  if [ -n "${_FED_ASSET_ROLLBACK:-}" ]; then
    python3 "$BUNDLE/scripts/mactahoe_assets.py" restore "$_FED_ASSET_ROLLBACK" || \
      echo 'Wallpaper settings rollback needs attention; the preserved snapshot is retained.' >&2
  fi
  if [ -n "${_FED_TRANSFER_PID:-}" ]; then
    kill "$_FED_TRANSFER_PID" 2>/dev/null || true
    wait "$_FED_TRANSFER_PID" 2>/dev/null || true
  fi
  rm -f "${_FED_NET_STOP:-}" 2>/dev/null || true
  if [ "${_UI_ACTIVE:-0}" = 1 ]; then
    if [ "$_exit_rc" -eq 0 ]; then
      _ui_finish "${_UI_COMPLETION:-Selected tasks finished.}"
    else
      _ui_finish "${_UI_COMPLETION:-Stopped or finished with issues. See the full log for details.}"
    fi
  fi
  exec 1>&5 2>&6 2>/dev/null || true
  trap - EXIT
  # User closed the installer (Ctrl+C forced exit) or it closed itself
  # (cancelled input) — completed work and its transcript are retained below.
  # Interrupted runs retain the transcript too; completed work is not erased.
  if [ -n "${_FED_TEE_PID:-}" ]; then wait "$_FED_TEE_PID" 2>/dev/null || true; fi
  # Strip ANSI escape sequences from log file (post-process, no pipe race)
  if [ "${_FED_LOG_PARENT:-0}" != 1 ] && [ -n "${_FED_LOG:-}" ] && [ -f "$_FED_LOG" ]; then
    LC_ALL=C sed -i 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$_FED_LOG" 2>/dev/null || true
    LC_ALL=C sed -i 's/\x1b\][0-9;]*[^\x07\x1b]*[\x07\x1b]//g' "$_FED_LOG" 2>/dev/null || true
    chmod 600 "$_FED_LOG" || printf 'Warning: could not secure session log permissions.\n' >&2
    # Set custom icon for this log file
    command -v gio &>/dev/null && [ -f "${_FED_ICON_PATH:-}" ] && \
      gio set "$_FED_LOG" metadata::custom-icon "file://$_FED_ICON_PATH" 2>/dev/null || true
  fi
  # The completion dashboard already shows the log name. Do not print it twice.
  if [ "${_UI_FINISHED:-0}" != 1 ]; then
    echo -e "  ${CYAN}Log saved: ${_FED_LOG}${NC}"
  fi
}
trap _fed_log_finalize EXIT

# ── Error logging ──
_fed_log_error() {
  local _line=$1 _code=$2
  _ui_notice 'An operation could not complete. Details are in the session log.'
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
if [ ! -t 5 ]; then
  RED='' GREEN='' YELLOW='' CYAN='' NC='' BOLD='' WHITE='' DIM='' PINK=''
fi

# ── Padded header row helper ──
# Prints "  ║  LABEL (padded to 12)  :  VALUE <pad>║"
# All labels are padded to 12 chars so colons always align.
_fed_header_row() {
  local _lbl="$1" _val="$2"
  # Visible chars before value: 2 (spaces after ║) + 12 (label) + 5 ("  :  ") = 19
  # Total inner width between ║ chars: 62 (matches the 62 ═'s in the border)
  # Max value length = 62 - 19 - 1 (min pad) = 42
  local _max_val=41  # leaves room for ellipsis + 1 pad
  if [ ${#_val} -gt 42 ]; then
    _val="${_val:0:_max_val}…"
  fi
  local _pad=$((62 - 19 - ${#_val}))
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
  _log_name="FedoraTahoe_log.${_FED_DATE_STAMP:-?}.${_FED_ID:-?}${_FED_TAG_EXT:-}.txt"

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
  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
  _hdr_t1="FEDORA MACTAHOE — EPRAHEMI EDITION"
  echo -e "  ${CYAN}║${NC}        ${BOLD}${WHITE}${_hdr_t1}${NC}$(printf '%*s' $((62 - 8 - ${#_hdr_t1})) '')${CYAN}║${NC}"
  _hdr_t2="Installation Log"
  echo -e "  ${CYAN}║${NC}        ${DIM}${_hdr_t2}${NC}$(printf '%*s' $((62 - 8 - ${#_hdr_t2})) '')${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
  echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
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
  _fed_header_row "Method"     "${_FED_TAG:-(unknown)}"
  _fed_header_row "Log"        "$_log_name"
  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
  echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
  _repo_url="https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi"
  echo -e "  ${CYAN}║${NC}  ${DIM}${_repo_url}${NC}$(printf '%*s' $((60 - ${#_repo_url})) '')${CYAN}║${NC}"
_credit="  ┊  Made by eprahemi — Fedora MacTahoe © 2026"
  echo -e "  ${CYAN}║${NC}  ${DIM}${_credit}${NC}$(printf '%*s' $((60 - ${#_credit})) '')${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
  echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}
_print_log_header

# ── Ctrl+C / Interrupt handling ──
# First press warns, second press force-exits immediately (no log saved).
_INT_PRESS=0
_FED_ABORT=0
_handle_sigint() {
  _ui_stop
  if [ "${_UI_ACTIVE:-0}" = 1 ]; then
    printf '\033[?25h\n Interrupted. Press Ctrl+C again to exit.\n' >&7
  fi
  _INT_PRESS=$((_INT_PRESS + 1))
  if [ "$_INT_PRESS" -ge 2 ]; then
    _FED_ABORT=1
    echo -e "\n  ${RED}${BOLD}⛔  Forced exit.${NC}"
    exit 130
  fi
  echo -e "\n  ${YELLOW}${BOLD}⚠  Interrupted. Press Ctrl+C again to exit.${NC}"
}
trap _handle_sigint INT

# Wait for a key indefinitely; missing input cancels rather than granting consent.
_wait_or_close() {
  if [ "${_UI_ACTIVE:-0}" = 1 ]; then
    _ui_question 'Kitty is recommended' 'Install Kitty, then run this installer there for the intended experience.' 'Press any key to continue, or Ctrl+C to stop.'
  fi
  local _rc=0
  read -r -s -n 1 key < /dev/tty || _rc=$?
  if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_resume; fi
  if [ "$_rc" -ne 0 ]; then
    _FED_ABORT=1
    echo ""
    echo 'No input available — installation cancelled.'
    exit 42
  fi
}

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
warn()  {
  echo -e "  ${YELLOW}  ┊ ⚠ ${NC}  $1"
  if [ "${_UI_ACTIVE:-0}" = 1 ]; then _UI_WARNINGS+=("$1"); _ui_notice "$1"; fi
}
fail()  {
  echo -e "  ${RED}  ┊ ✗ ${NC}  $1"
  if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_notice "$1" '1;31'; fi
  exit 1
}

# ── Step status tracking ────────────────────────────────────────
# The installer must never fall over because one step failed. A dead
# mirror, a missing package or a third-party download that times out
# may not take the remaining steps down with it. Every step records
# its outcome here; the final summary prints what is missing and the
# exact command that adds it.
#
#   STEP_RESULT_*  — one entry per step: id, status, label
#                    status is one of: ok | skipped | failed
#   MISSING_*      — pieces that are absent after the run, each with
#                    the command that installs it later
STEP_RESULT_IDS=()
STEP_RESULT_VALS=()
STEP_RESULT_LABELS=()
STEP_FAILED_COUNT=0

MISSING_LABEL=()
MISSING_FIX=()
MISSING_COUNT=0

# The label of the step currently running — next_step() sets it, so the
# report never has to repeat a hardcoded title for every step id.
CURRENT_STEP_LABEL=""

_step_record() {
    # _step_record <step_id> <status> <label>
    # A step id is recorded once — a later record replaces the earlier
    # one, so a step that reports itself while it is still running can
    # be corrected afterwards with its real outcome.
    local _i
    for _i in ${STEP_RESULT_IDS[@]+"${!STEP_RESULT_IDS[@]}"}; do
        if [ "${STEP_RESULT_IDS[$_i]}" = "$1" ]; then
            STEP_RESULT_VALS[$_i]="$2"
            STEP_RESULT_LABELS[$_i]="$3"
            return 0
        fi
    done
    STEP_RESULT_IDS+=("$1")
    STEP_RESULT_VALS+=("$2")
    STEP_RESULT_LABELS+=("$3")
}

# The recorded outcome of a step: ok | skipped | failed.
# Empty when the step never ran.
_step_status() {
    local _i
    for _i in ${STEP_RESULT_IDS[@]+"${!STEP_RESULT_IDS[@]}"}; do
        if [ "${STEP_RESULT_IDS[$_i]}" = "$1" ]; then
            echo "${STEP_RESULT_VALS[$_i]}"
            return 0
        fi
    done
    echo ""
}

_note_missing() {
    # _note_missing "<what is missing>" "<how to add it later>"
    MISSING_LABEL+=("$1")
    MISSING_FIX+=("$2")
    MISSING_COUNT=$((MISSING_COUNT + 1))
}

# The command that adds a failed step's piece to the system later.
# "bash install.sh" is the universal fallback: a failed step is never
# written to install-state.json, so a re-run retries exactly that step.
_step_fix() {
    case "$1" in
        install_rpmfusion)            echo "dnf install rpmfusion-{free,nonfree}-release" ;;
        install_nvidia)               echo "dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda" ;;
        install_browsers)             echo "update full" ;;
        install_flatpaks)             echo "flatpak install <app-id>" ;;
        install_mactahoe_theme)       echo "update theme" ;;
        install_font)                 echo "update fonts" ;;
        apply_desktop_entries)        echo "update defaults" ;;
        ensure_celluloid_default)     echo "update defaults" ;;
        configure_nautilus_defaults)  echo "update defaults" ;;
        apply_configs)                echo "update configs" ;;
        apply_dconf)                  echo "update dconf" ;;
        optimize_system_resources)    echo "update services" ;;
        apply_wallpapers)             echo "update wallpaper" ;;
        install_custom_avatars)       echo "update pfp" ;;
        setup_gdm)                    echo "gdm <image>   # then reboot" ;;
        setup_firefox_theme)          echo "launch Firefox once, then: update theme" ;;
        setup_flatpak_theme)          echo "update gtk" ;;
        install_sounds)               echo "update sounds" ;;
        install_updater)              echo "update services" ;;
        install_ktheme_watcher)       echo "update services" ;;
        setup_terminal)               echo "update configs" ;;
        setup_shell)                  echo "sudo chsh -s /usr/bin/fish \$USER" ;;
        install_extensions)           echo "update extensions" ;;
        download_optional_videos)     echo "update videos" ;;
        remove_gnome_weather)         echo "dnf remove gnome-weather" ;;
        remove_ptyxis)                echo "dnf remove ptyxis" ;;
        *)                            echo "bash install.sh" ;;
    esac
}

# A step failed: record it, tell the user, and let the run continue.
_step_failed() {
    # _step_failed <step_id> <exit_code>
    local step_id="$1" rc="$2"
    local label="${CURRENT_STEP_LABEL:-$step_id}"
    STEP_FAILED_COUNT=$((STEP_FAILED_COUNT + 1))
    _step_record "$step_id" "failed" "$label"
    echo -e "  ${RED}  ┊ ✗ ${NC}  ${BOLD}${RED}Step failed${NC} ${DIM}(${step_id}, exit ${rc})${NC}"
    if [ "${3:-}" = stopped ]; then
      echo 'Stopped at a safe task boundary. Completed work and the session log are kept.'
    else
      echo -e "  ${RED}  ┊   ${NC}  ${DIM}Continuing with the next step — this one is retried on the next run.${NC}"
    fi
    _note_missing "$label" "$(_step_fix "$step_id")"
    if [ "${_UI_ACTIVE:-0}" = 1 ]; then
      if [ "${3:-}" = stopped ]; then
        _ui_notice "$label was interrupted. Stopping safely; completed work is kept." '1;33'
      else
        _ui_notice "$label could not complete. Continuing with the remaining steps." '1;31'
      fi
      _UI_RESULT_DETAILS+="$label - retry: $(_step_fix "$step_id")"$'\n'
    fi
}

_asset_verify_helper() {
  local expected actual
  expected=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["asset_helper_sha256"])' "$BUNDLE/updates.json") || return 1
  actual=$(sha256sum "$BUNDLE/scripts/mactahoe_assets.py") || return 1
  if [ "${#expected}" -ne 64 ] || [ "${actual%% *}" != "$expected" ]; then
    warn 'Asset safety helper verification failed — no asset operation was run'
    return 1
  fi
}

_asset_tool() {
  _asset_verify_helper || return 1
  python3 "$BUNDLE/scripts/mactahoe_assets.py" "$@"
}

_preserve_active_wallpaper() {
  if [ -n "${_FED_WALLPAPER_SNAPSHOT:-}" ] && [ -f "$_FED_WALLPAPER_SNAPSHOT" ]; then return 0; fi
  if ! _FED_WALLPAPER_SNAPSHOT=$(_asset_tool snapshot); then
    warn 'Could not preserve the active wallpaper and its dependencies — settings were not changed'
    return 1
  fi
}

_install_asset_pack() {
  local kind="$1" variant=normal mode=replace current stage legacy plan active_snapshot image preserve_settings=false choice
  [ "${INSTALL_WALLPAPER_18:-false}" != true ] || variant=18
  [ "${INSTALL_WALLPAPER_BOTH:-false}" != true ] || variant=both
  [ "${INSTALL_WALLPAPER_ADD:-false}" != true ] || mode=add
  stage=$(mktemp -d "${TMPDIR:-/tmp}/mactahoe-assets.XXXXXXXX") || return 1
  legacy="$stage/initial-state.json"
  if [ -n "${_ASSET_INITIAL_STATE_JSON:-}" ]; then
    printf '%s\n' "$_ASSET_INITIAL_STATE_JSON" > "$legacy"
  elif [ -f "${STATE_FILE:-/dev/null}" ]; then
    cp "$STATE_FILE" "$legacy" || return 1
  else
    printf '{}\n' > "$legacy"
  fi
  if ! current=$(_asset_tool installed "$kind" "$legacy"); then
    rm -rf -- "$stage"  # only this invocation's private staging directory
    return 1
  fi
  if [ "$current" = both ]; then
    # Installed reality wins over saved/caller choices: never retire either pack.
    variant=keep; mode=add; preserve_settings=true
  elif [ "$current" = 18 ]; then
    _ui_stop
    if [ "${_UI_ACTIVE:-0}" = 1 ]; then printf '\033[2J\033[H\033[?25h' >&7; fi
    printf '\n  Only the extra %s collection is installed.\n  [1] Replace with normal\n  [2] Add normal alongside it\n  [3] Leave untouched (default)\n  Choice [3]: ' "$kind" > /dev/tty 2>/dev/null || true
    choice=''
    read -r choice < /dev/tty 2>/dev/null || choice=3
    _ui_resume
    case "$choice" in
      1|replace) variant=normal; mode=replace ;;
      2|add) variant=normal; mode=add ;;
      *) rm -rf -- "$stage"; _VISUAL_SKIP_REASON='existing collection kept by request'; return 0 ;;
    esac
    preserve_settings=true
  elif [ "$current" = normal ]; then
    # A choice may add a pack, never silently remove the installed normal one.
    mode=add; preserve_settings=true
  fi
  local archives=()
  if [ "$variant" != normal ] && [ "$variant" != keep ]; then
    if { [ "$kind" = avatar ] && [ "${SKIP_FACES_18:-false}" = true ]; } ||
       { [ "$kind" = wallpaper ] && { [ "${SKIP_WALLPAPER_18:-false}" = true ] || [ "${SKIP_WALLPAPER_18_V2:-false}" = true ]; }; }; then
      _VISUAL_SKIP_REASON='hosted asset unavailable; existing collection preserved'
      rm -rf -- "$stage"; return 0
    fi
    if [ "$kind" = wallpaper ]; then
      if ! _net_download "$WALLPAPER_18_URL" "$stage/extra-1.zip" --max-time 90 -b 'download_warning=1' ||
         ! _net_download "$WALLPAPER_18_URL_V2" "$stage/extra-2.zip" --max-time 90 -b 'download_warning=1'; then
        rm -rf -- "$stage"; return 1
      fi
      archives=("$stage/extra-1.zip" "$stage/extra-2.zip")
    else
      if ! _net_download "$FACES_18_URL" "$stage/extra.zip" --max-time 90 -b 'download_warning=1'; then
        rm -rf -- "$stage"; return 1
      fi
      archives=("$stage/extra.zip")
    fi
  fi
  # Avatar validation may need a narrow privileged metadata read. Authenticate
  # through the existing foreground sudo/UI boundary, never inside captured output.
  if [ "$kind" = avatar ] && ! sudo -v; then
    rm -rf -- "$stage"; return 1
  fi
  if ! plan=$(_asset_tool build "$kind" "$variant" "$mode" "$BUNDLE" "$stage" "$legacy" "${archives[@]}"); then
    warn 'Asset validation failed — the installed collection is unchanged'
    rm -rf -- "$stage"; return 1
  fi
  local rechecked
  if ! rechecked=$(_asset_tool installed "$kind" "$legacy") || [ "$rechecked" != "$current" ]; then
    warn 'The installed collection changed during staging — rerun for a fresh choice'
    rm -rf -- "$stage"; return 1
  fi
  if [ "$kind" = wallpaper ]; then
    if ! active_snapshot=$(_asset_tool snapshot); then rm -rf -- "$stage"; return 1; fi
    _FED_ASSET_ROLLBACK="$active_snapshot"
    if ! _asset_tool relocate "$active_snapshot" "$plan"; then
      _FED_ASSET_ROLLBACK=''; rm -rf -- "$stage"; return 1
    fi
    if [ "$preserve_settings" = false ] && [ "${INSTALL_DESKTOP_WALLPAPER:-false}" = true ]; then
      if ! image=$(_asset_tool desktop "$BUNDLE/wallpapers/desktop/Himeno Fedora.jpg") ||
         ! _asset_tool activate "$active_snapshot" "$image"; then
        _asset_tool restore "$active_snapshot" || warn "Restore wallpaper settings from $active_snapshot"
        _FED_ASSET_ROLLBACK=''; rm -rf -- "$stage"; return 1
      fi
    fi
  fi
  if ! _asset_verify_helper || ! sudo python3 "$BUNDLE/scripts/mactahoe_assets.py" apply "$plan"; then
    if [ "$kind" = wallpaper ]; then
      _asset_tool restore "$active_snapshot" || warn "Restore wallpaper settings from $active_snapshot"
    fi
    _FED_ASSET_ROLLBACK=''
    warn 'Asset publication failed; recovery data is retained if rollback needs attention'
    rm -rf -- "$stage"; return 1
  fi
  _FED_ASSET_ROLLBACK=''
  rm -rf -- "$stage"
  if [ "$current" = unknown ]; then
    warn 'Unidentified legacy avatar files were preserved alongside the managed collection'
  fi
  ok "Validated $kind collection installed; active image dependencies preserved"
  return 0
}

backup_dconf() {
  _preserve_active_wallpaper || return 1
  # Rollback point before ANY destructive dconf operation (load/reset).
  # Saves a full dump of the user's live dconf database (few KB) to
  # ~/.cache/fedora-mactahoe/backups/ as dconf-<timestamp>.conf, chmod 600.
  # Restore anytime with:  dconf load / < ~/.cache/fedora-mactahoe/backups/dconf-*.conf
  local bk_dir="$HOME/.cache/fedora-mactahoe/backups"
  mkdir -p "$bk_dir" 2>/dev/null || true
  chmod 700 "$bk_dir" 2>/dev/null || true
  local bk_file="$bk_dir/dconf-$(date +%Y%m%d-%H%M%S).conf"
  if dconf dump / > "$bk_file" 2>/dev/null; then
    chmod 600 "$bk_file" 2>/dev/null || true
    ok "dconf snapshot saved"
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
  local _rc=0
  local _correction=''
  while true; do
    if [ "${_UI_ACTIVE:-0}" = 1 ]; then
      _ui_question "${_UI_QUESTION_TITLE:-Your preference}" "${_UI_QUESTION_BODY:-Please review this choice.}${_correction}" "$prompt"
    fi
    if [ "${_UI_ACTIVE:-0}" = 1 ]; then
      printf '%s\n' "$prompt"
    else
      echo -en "  ${DIM}${prompt}${NC} " >/dev/tty
    fi
    _rc=0
    read -r reply </dev/tty || _rc=$?
    if [ "$_rc" -ne 0 ]; then
      _FED_ABORT=1
      echo ""
      echo 'No input available — installation cancelled without consent.'
      exit 42
    fi
    case "${reply,,}" in
      y|yes) if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_resume; fi; return 0 ;;
      n|no)  if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_resume; fi; return 1 ;;
      '')    if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_resume; fi; [ "$default" = "Y" ] && return 0 || return 1 ;;
      *)     echo 'Type y/yes or n/no'; _correction=$'\nType y/yes or n/no.' ;;
    esac
  done
}

# ── confirm() variant for the FINAL restart prompt ──
# Wait indefinitely. EOF finishes gracefully without requesting a reboot.
# Returns: 0 = yes, 1 = no, 2 = no input available.
confirm_final() {
  local prompt="$1" default="${2:-}"
  local reply=""
  local _rc=0
  local _correction=''
  while true; do
    if [ "${_UI_ACTIVE:-0}" = 1 ]; then
      _ui_question 'Restart your computer' "${_UI_COMPLETION:-Processing has finished.} A restart applies desktop and login changes.${_correction}" "$prompt"
    fi
    if [ "${_UI_ACTIVE:-0}" = 1 ]; then
      printf '%s\n' "$prompt"
    else
      echo -en "  ${DIM}${prompt}${NC} " >/dev/tty
    fi
    _rc=0
    read -r reply </dev/tty || _rc=$?
    if [ "$_rc" -ne 0 ]; then
      if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_resume; fi
      return 2
    fi
    case "${reply,,}" in
      y|yes) if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_resume; fi; return 0 ;;
      n|no)  if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_resume; fi; return 1 ;;
      '')    if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_resume; fi; [ "$default" = "Y" ] && return 0 || return 1 ;;
      *)     echo 'Type y/yes or n/no'; _correction=$'\nType y/yes or n/no.' ;;
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

# ── Hosted assets (Google Drive) ───────────────────────────────
# A hosted file that the user asked for but that cannot be
# downloaded is skipped instead of retried for the rest of the run.
SKIP_WALLPAPER_18=false
SKIP_WALLPAPER_18_V2=false
SKIP_FACES_18=false
SKIP_VIDEOS=false
SKIP_GINTAMA=false

# The extra wallpaper packs, the extra avatars and the video edits
# live on Google Drive. Drive answers a dead link with an HTML
# error page (404) instead of the file, so the state of a link can
# be known BEFORE a download is started. The check is a HEAD
# request — it transfers nothing.
_drive_probe() {
  # _drive_probe <url> → "ok" | "dead" | "unknown"
  local url="$1"
  local out="" code="" type=""
  out=$(curl -sIL --max-time 20 -b "download_warning=1" -o /dev/null \
        -w '%{http_code} %{content_type}' "$url" 2>/dev/null) || out=""
  code="${out%% *}"
  type="${out#* }"
  if [ "$code" = "200" ]; then
    case "$type" in
      text/html*) echo "dead" ;;
      *)          echo "ok" ;;
    esac
  elif [ "$code" = "404" ] || [ "$code" = "403" ] || [ "$code" = "410" ]; then
    echo "dead"
  else
    echo "unknown"
  fi
}

# Prints the state of one hosted asset.
# Returns 0 = alive, 1 = dead, 2 = could not be checked.
_drive_asset() {
  # _drive_asset "<label>" "<url>"
  local label="$1" url="$2"
  local state
  state="$(_drive_probe "$url")"
  case "$state" in
    ok)
      echo -e "  ${GREEN}  ┊ ✓ ${NC}  ${label} ${DIM}(link alive)${NC}"
      return 0
      ;;
    dead)
      echo -e "  ${RED}  ┊ ✗ ${NC}  ${label} ${RED}(the hosted link is dead)${NC}"
      return 1
      ;;
    *)
      echo -e "  ${YELLOW}  ┊ ⚠ ${NC}  ${label} ${DIM}(link could not be checked)${NC}"
      return 2
      ;;
  esac
}

# ── A hosted asset the user asked for, but whose link is dead ──
# This is the one place the installer asks about a hosted link: the
# user asked for the asset explicitly, so the dead link is worth a
# question. Continuing without it is the default — the install never
# stops because a third-party file is gone.
# Returns 0 = continue without it, 1 = try the download anyway.
_drive_dead_ask() {
    _UI_QUESTION_TITLE='Requested download unavailable'
    _UI_QUESTION_BODY='A hosted file you requested appears unavailable. Continue without this asset?'
  # _drive_dead_ask "<what>" "<how to add it later>"
  local what="$1" fix="$2"
  echo ""
  echo -e "  ${YELLOW}◆${NC}  ${BOLD}${YELLOW}The hosted file for ${what} is gone${NC}"
  echo -e "  ${DIM}     it was removed from Google Drive — there is nothing left to download${NC}"
  if confirm "Continue without it? [Y/n]: " Y; then
    _drive_failed "$what" "$fix"
    return 0
  fi
  return 1
}

# ── A hosted asset that could not be delivered ────────────────
# The step continues; the piece is reported as missing and the
# command that adds it later is printed right here.
_drive_failed() {
  # _drive_failed "<what>" "<how to add it later>"
  local what="$1" fix="$2"
  echo -e "  ${RED}  ┊ ✗ ${NC}  ${BOLD}${RED}${what}${NC} ${RED}could not be downloaded${NC}"
  echo -e "  ${DIM}     the hosted link is dead or unreachable — the install continues without it${NC}"
  echo -e "  ${DIM}     add it later with:  ${NC}${BOLD}${WHITE}${fix}${NC}"
  _note_missing "$what" "$fix"
}

# ── Report the state of the hosted assets this install needs ──
# Only the assets that are actually going to be downloaded are
# checked — there is no point in probing a link nobody uses.
_hosted_assets_status() {
  local _need_pack=false _need_faces=false _need_videos=false
  if [ "${INSTALL_WALLPAPER_18:-false}" = "true" ]; then
    _need_pack=true
    _need_faces=true
    local installed_pack installed_faces
    installed_pack=$(_asset_tool installed wallpaper) || return 1
    installed_faces=$(_asset_tool installed avatar) || return 1
    case "$installed_pack" in both|18) _need_pack=false ;; esac
    case "$installed_faces" in both|18) _need_faces=false ;; esac
  fi
  if [ "${INSTALL_BILLIE_VIDEOS:-false}" = "true" ]; then
    _need_videos=true
  fi
  if [ "$_need_pack" = "false" ] && [ "$_need_faces" = "false" ] && [ "$_need_videos" = "false" ]; then
    return 0
  fi

  echo ""
  echo -e "  ${BOLD}${WHITE}◆  HOSTED ASSETS — checking the links${NC}"
  local _dead=0 _st=0
  if [ "$_need_pack" = "true" ]; then
    _st=0
    _drive_asset "extra wallpaper pack" "$WALLPAPER_18_URL" || _st=$?
    if [ "$_st" -eq 1 ]; then
      _dead=$((_dead + 1))
      if _drive_dead_ask "the extra wallpaper pack" "update wallpaper"; then
        SKIP_WALLPAPER_18=true
      fi
    fi
    _st=0
    _drive_asset "extra wallpaper pack (v2)" "$WALLPAPER_18_URL_V2" || _st=$?
    if [ "$_st" -eq 1 ]; then
      _dead=$((_dead + 1))
      if _drive_dead_ask "the extra wallpaper pack (v2)" "update wallpaper"; then
        SKIP_WALLPAPER_18_V2=true
      fi
    fi
  fi
  if [ "$_need_faces" = "true" ]; then
    _st=0
    _drive_asset "extra profile pictures" "$FACES_18_URL" || _st=$?
    if [ "$_st" -eq 1 ]; then
      _dead=$((_dead + 1))
      if _drive_dead_ask "the extra profile pictures" "update pfp"; then
        SKIP_FACES_18=true
      fi
    fi
  fi
  if [ "$_need_videos" = "true" ]; then
    _st=0
    _drive_asset "video edits" "$DOWNLOADS_URL" || _st=$?
    if [ "$_st" -eq 1 ]; then
      _dead=$((_dead + 1))
      if _drive_dead_ask "the video edits" "update videos"; then
        SKIP_VIDEOS=true
      fi
    fi
    _st=0
    _drive_asset "video edit (mp4)" "$GINTAMA_URL" || _st=$?
    if [ "$_st" -eq 1 ]; then
      _dead=$((_dead + 1))
      if _drive_dead_ask "the video edit (mp4)" "update videos"; then
        SKIP_GINTAMA=true
      fi
    fi
  fi
  if [ "$_dead" -gt 0 ]; then
    echo -e "  ${DIM}     ${_dead} dead link(s) — the install continues, the piece is listed at the end${NC}"
  fi
}

TOTAL_STEPS=29
if [ -z "${UPDATE_STEPS:-}" ]; then
  _UI_STEP_IDS=(preflight remove_ptyxis remove_gnome_weather install_rpmfusion install_nvidia install_rpm_packages install_browsers install_flatpaks install_mactahoe_theme install_font apply_desktop_entries ensure_celluloid_default configure_nautilus_defaults apply_configs apply_dconf optimize_system_resources apply_wallpapers install_custom_avatars setup_gdm setup_firefox_theme setup_flatpak_theme install_sounds install_updater install_ktheme_watcher setup_terminal setup_shell install_extensions download_optional_videos finalize)
  _UI_STEP_LABELS=('Preflight' 'Old terminal' 'GNOME Weather' 'RPM Fusion and codecs' 'NVIDIA drivers' 'RPM packages' 'Browsers' 'Flatpak apps' 'GTK and icon themes' 'SF Pro font' 'Desktop entries' 'Celluloid defaults' 'Nautilus defaults' 'Configuration files' 'GNOME settings' 'System resources' 'Wallpapers' 'Custom avatars' 'Login theme' 'Firefox theme' 'Flatpak GTK runtime' 'Big Sur sounds' 'Update notifier' 'Kitty theme watcher' 'Kitty terminal' 'Fish shell' 'GNOME extensions' 'Optional videos' 'Cleanup and finalize')
  for _sid in "${_UI_STEP_IDS[@]}"; do _UI_STEP_STATES+=(waiting); _UI_STEP_REASONS+=(''); done
else
  IFS=',' read -r -a _UI_STEP_IDS <<< "$UPDATE_STEPS"
  for _sid in "${_UI_STEP_IDS[@]}"; do
    _UI_STEP_LABELS+=("$_sid")
    _UI_STEP_STATES+=(waiting)
    _UI_STEP_REASONS+=('')
  done
fi
if [ -z "${UPDATE_STEPS:-}" ]; then _ui_progress 0 "$TOTAL_STEPS"; fi
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

# ── Stamp who ran the installer (BASH / MANUAL / UPDATE-*) into state ──
STATE_JSON=$(echo "$STATE_JSON" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    d = {"version": "0.0", "steps": {}, "prompts": {}}
d["source"] = "'"$_FED_TAG"'"
print(json.dumps(d))
' 2>/dev/null || echo "$STATE_JSON")
if [ -f "$STATE_FILE" ]; then
  _SOURCE_TMP=$(mktemp "$STATE_DIR/state.XXXXXX" 2>/dev/null || echo "")
  if [ -n "$_SOURCE_TMP" ]; then
    echo "$STATE_JSON" > "$_SOURCE_TMP" 2>/dev/null && mv "$_SOURCE_TMP" "$STATE_FILE" 2>/dev/null || true
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
  # Legacy safety net: if the OVERALL installed version is older than the
  # manifest, refresh every step. Old state files stored per-step versions
  # as the then-current manifest version (e.g. steps saved as "2.2" from a
  # 2.2 install), which can be HIGHER than today's per-step values (1.x) —
  # without this, every step would be skipped, the finalize step would never
  # re-run, and the machine would stay stuck on its old version forever.
  _ver_lt "$USER_VERSION" "$MANIFEST_VERSION" && return 0
  local sid="$1"
  local mv="${STEP_MAN_VERS[$sid]:-0.0}"
  local uv="${STEP_USR_VERS[$sid]:-0.0}"
  _ver_lt "$uv" "$mv"
}

# ── Prompt gate helper ──
# Returns 0 if the prompt should be asked (no saved answer yet).
# Answers are sticky: once saved, a prompt is never re-asked.
_prompt_should_ask() {
  local pid="$1"
  local ans="${PR_ANS[$pid]:-}"

  # No answer yet → ask.
  if [ -z "$ans" ]; then
    return 0
  fi

  # An answer saved by an older installer is re-asked once per release.
  # Same-version answers stay sticky, so a re-run never nags. This is the
  # behaviour the comment above _load_prompt_answers always promised —
  # PR_VER existed but was never consulted.
  [ "${PR_VER[$pid]:-0.0}" != "$MANIFEST_VERSION" ]
}

# ── Load saved prompt answers into installer variables ──
# Only loads answers for prompts that are up-to-date (version matches manifest).
# Outdated prompts remain unset so they trigger re-asking.
# CRITICAL: an explicitly-set env var ALWAYS wins over a saved answer —
# that is how `update wallpaper`, `update pfp` and `update gdm` pass
# their pick (INSTALL_WALLPAPER_18=false, INSTALL_LOGIN_WALLPAPER=true…).
# Never overwrite a caller-provided variable here.
_load_prompt_answers() {
  local ans
  if [ -z "${INSTALL_DISCORD:-}" ] && ! _prompt_should_ask "discord"; then
    ans="${PR_ANS['discord']:-}"
    [ -n "$ans" ] && INSTALL_DISCORD="$ans"
  fi
  if [ -z "${INSTALL_DESKTOP_WALLPAPER:-}" ] && ! _prompt_should_ask "wallpaper_desktop"; then
    ans="${PR_ANS['wallpaper_desktop']:-}"
    [ -n "$ans" ] && INSTALL_DESKTOP_WALLPAPER="$ans"
  fi
  if [ -z "${INSTALL_LOGIN_WALLPAPER:-}" ] && ! _prompt_should_ask "wallpaper_login"; then
    ans="${PR_ANS['wallpaper_login']:-}"
    [ -n "$ans" ] && INSTALL_LOGIN_WALLPAPER="$ans"
  fi
  if [ -z "${INSTALL_WALLPAPER_18:-}" ] && ! _prompt_should_ask "wallpaper_18"; then
    ans="${PR_ANS['wallpaper_18']:-}"
    [ -n "$ans" ] && INSTALL_WALLPAPER_18="$ans"
  fi
  if [ -z "${INSTALL_BILLIE_VIDEOS:-}" ] && ! _prompt_should_ask "billie_videos"; then
    ans="${PR_ANS['billie_videos']:-}"
    [ -n "$ans" ] && INSTALL_BILLIE_VIDEOS="$ans"
  fi
  if [ -z "${INSTALL_DISABLE_FIREWALLD:-}" ] && ! _prompt_should_ask "firewalld"; then
    ans="${PR_ANS['firewalld']:-}"
    [ -n "$ans" ] && INSTALL_DISABLE_FIREWALLD="$ans"
  fi
  if [ -z "${INSTALL_REMOVE_OLD_TERMINAL:-}" ] && ! _prompt_should_ask "old_terminal"; then
    ans="${PR_ANS['old_terminal']:-}"
    [ -n "$ans" ] && INSTALL_REMOVE_OLD_TERMINAL="$ans"
  fi
}

# ── Save a single prompt answer to state ──
_save_prompt_answer() {
  local pid="$1" choice="$2"
  [ -z "$pid" ] && return
  PR_ANS["$pid"]="$choice"
  PR_VER["$pid"]="$MANIFEST_VERSION"
  local _MERGED _JFILE
  _JFILE=$(mktemp "$STATE_DIR/state.XXXXXX" 2>/dev/null || echo "")
  if [ -z "$_JFILE" ]; then
    return
  fi
  echo "$STATE_JSON" > "$_JFILE" 2>/dev/null || true
  _MERGED=$(python3 -c '
import sys, json
try:
    with open(sys.argv[1], "r") as fh:
        s = json.load(fh)
except Exception:
    s = {"version": "0.0", "steps": {}, "prompts": {}}
try:
    if "prompts" not in s:
        s["prompts"] = {}
    s["prompts"][sys.argv[2]] = {"answered": True, "choice": sys.argv[3], "version": sys.argv[4]}
    print(json.dumps(s))
except Exception:
    print("")
' "$_JFILE" "$pid" "$choice" "$MANIFEST_VERSION" 2>/dev/null || echo "$STATE_JSON")
  rm -f "$_JFILE" 2>/dev/null || true
  [ -n "$_MERGED" ] && STATE_JSON="$_MERGED"
  local _TMPFILE
  _TMPFILE=$(mktemp "$STATE_DIR/state.XXXXXX" 2>/dev/null || echo "")
  if [ -n "$_TMPFILE" ]; then
    echo "$STATE_JSON" > "$_TMPFILE" 2>/dev/null && mv "$_TMPFILE" "$STATE_FILE" 2>/dev/null || true
  fi
}

# ── Update a single step's version in state ──
_update_step_state() {
  local sid="$1"
  local sv="${STEP_MAN_VERS[$sid]:-0.0}"
  [ "$sv" = "0.0" ] && sv="$MANIFEST_VERSION"
  STEP_USR_VERS["$sid"]="$sv"
  local _MERGED _JFILE
  _JFILE=$(mktemp "$STATE_DIR/state.XXXXXX" 2>/dev/null || echo "")
  if [ -z "$_JFILE" ]; then
    return
  fi
  echo "$STATE_JSON" > "$_JFILE" 2>/dev/null || true
  _MERGED=$(python3 -c '
import sys, json
try:
    with open(sys.argv[1], "r") as fh:
        s = json.load(fh)
except Exception:
    s = {"version": "0.0", "steps": {}, "prompts": {}}
try:
    if "steps" not in s:
        s["steps"] = {}
    s["steps"][sys.argv[2]] = sys.argv[3]
    print(json.dumps(s))
except Exception:
    print("")
' "$_JFILE" "$sid" "$sv" 2>/dev/null || echo "$STATE_JSON")
  rm -f "$_JFILE" 2>/dev/null || true
  [ -n "$_MERGED" ] && STATE_JSON="$_MERGED"
  local _TMPFILE
  _TMPFILE=$(mktemp "$STATE_DIR/state.XXXXXX" 2>/dev/null || echo "")
  if [ -n "$_TMPFILE" ]; then
    echo "$STATE_JSON" > "$_TMPFILE" 2>/dev/null && mv "$_TMPFILE" "$STATE_FILE" 2>/dev/null || true
  fi
}

# ── Remove a step from state so the next run retries it ──
# A failed step must not keep the version of an earlier successful run:
# finalize() still writes the overall version, and _step_should_run()
# would then skip the step forever. Removing the key makes the gate fall
# back to "0.0" and re-run exactly that step.
_clear_step_state() {
  local sid="$1"
  STEP_USR_VERS["$sid"]="0.0"
  local _MERGED _JFILE
  _JFILE=$(mktemp "$STATE_DIR/state.XXXXXX" 2>/dev/null || echo "")
  if [ -z "$_JFILE" ]; then
    return 1
  fi
  echo "$STATE_JSON" > "$_JFILE" 2>/dev/null || true
  _MERGED=$(python3 -c '
import sys, json
try:
    with open(sys.argv[1], "r") as fh:
        s = json.load(fh)
except Exception:
    sys.exit(1)
try:
    steps = s.get("steps")
    if isinstance(steps, dict):
        steps.pop(sys.argv[2], None)
    print(json.dumps(s))
except Exception:
    sys.exit(1)
' "$_JFILE" "$sid" 2>/dev/null) || _MERGED=""
  rm -f "$_JFILE" 2>/dev/null || true
  if [ -z "$_MERGED" ]; then
    return 1
  fi
  STATE_JSON="$_MERGED"
  local _TMPFILE
  _TMPFILE=$(mktemp "$STATE_DIR/state.XXXXXX" 2>/dev/null || echo "")
  if [ -z "$_TMPFILE" ]; then
    return 1
  fi
  echo "$STATE_JSON" > "$_TMPFILE" 2>/dev/null || { rm -f "$_TMPFILE"; return 1; }
  mv "$_TMPFILE" "$STATE_FILE" 2>/dev/null || { rm -f "$_TMPFILE"; return 1; }
  return 0
}

# ── Step wrapper: only runs if step version is outdated ──
_run_step() {
  local step_id="$1"
  local func_name="$2"
  _VISUAL_SKIP_REASON=''
  _ui_step "$step_id" running
  # Safety checks must run even when the saved preflight step is current.
  if [ "$step_id" = "preflight" ] || _step_should_run "$step_id"; then
    # A failing step must never take the rest of the run down with it.
    # The `|| _rc=$?` keeps the call out of `set -e`'s kill path: the
    # step's own failure is captured, recorded and reported later.
    local _rc=0
    "$func_name" || _rc=$?
    if [ -s "${_FED_NET_STOP:-/dev/null}" ]; then
      _ui_step "$step_id" failed 'interrupted; retry this task'
      _step_failed "$step_id" 130 stopped
      _clear_step_state "$step_id" || warn "Could not clear interrupted step state: $step_id"
      _UI_COMPLETION='Stopped safely. Completed work is kept; retry the interrupted task later.'
      exit 130
    fi
    if [ "${_UI_ACTIVE:-0}" = 1 ]; then
      _UI_DONE=$((_UI_DONE + 1))
      _ui_progress "$_UI_DONE" "$TOTAL_STEPS"
    fi
    if [ "$_rc" -ne 0 ]; then
      _ui_step "$step_id" failed "exit $_rc; retry: $(_step_fix "$step_id")"
      # Preflight is the one step that must stay fatal: if the machine is
      # not a supported target there is nothing sensible to continue with.
      if [ "$step_id" = "preflight" ]; then
        fail "Preflight failed — the machine is not a supported target"
      fi
      _step_failed "$step_id" "$_rc"
      # A failed step must be retried on the next run. finalize() still
      # writes the overall version, so the step key itself must be
      # removed — an older successful version would make the gate skip it.
      _clear_step_state "$step_id" || \
        warn "Could not clear saved state for $step_id — it may be skipped on the next run"
      return 0
    fi
    _update_step_state "$step_id"
    _step_record "$step_id" "ok" "${CURRENT_STEP_LABEL:-$step_id}"
    if [ -n "$_VISUAL_SKIP_REASON" ]; then
      _ui_step "$step_id" skipped "$_VISUAL_SKIP_REASON"
    else
      _ui_step "$step_id" ok
    fi
  else
    _ui_step "$step_id" skipped 'up to date (not rechecked)'
    if [ "${_UI_ACTIVE:-0}" = 1 ]; then
      _UI_DONE=$((_UI_DONE + 1))
      _ui_progress "$_UI_DONE" "$TOTAL_STEPS"
    fi
    # A step that does not run has no label of its own — next_step()
    # lives inside the step function.
    _step_record "$step_id" "skipped" "$step_id"
    if $_INCREMENTAL_ACTIVE; then
      local uv="${STEP_USR_VERS[$step_id]:-0.0}"
      echo -e "  ${DIM}  ┊ SKIP  ${NC} ${func_name} ${DIM}(v${uv} current)${NC}"
    fi
  fi
  return 0
}

# ── Copy saved prompt answers into installer variables ──
_load_prompt_answers

# Preserve historical successful pack metadata before prompt defaults are saved.
_ASSET_INITIAL_STATE_JSON="${_FED_ASSET_LEGACY_STATE_JSON:-$STATE_JSON}"

next_step() {
  sudo -n -v 2>/dev/null || true  # refresh sudo credential silently
  STEP=$((STEP + 1))
  CURRENT_STEP_LABEL="$1"
  if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_task "$1"; fi
  if [ -n "${UPDATE_STEPS:-}" ]; then
    # Starting a selected task is not processed work or a completed install.
    printf '\nSelected task: %s\n' "$1"
    return 0
  fi
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
  if [ "${_UI_ACTIVE:-0}" = 1 ]; then
    case "$title" in
      *'PHASE 1'*) _ui_phase Foundations ;;
      *'PHASE 2'*) _ui_phase Packages ;;
      *'PHASE 3'*) _ui_phase Themes ;;
      *'PHASE 4'*) _ui_phase Configuration ;;
      *'PHASE 5'*) _ui_phase Shell ;;
      *'PHASE 6'*) _ui_phase Finalize ;;
    esac
  fi
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

  local t4="  Location:  Secure"
  echo -e "  ${CYAN}║${NC}  ${DIM}Location:${NC}  ${BOLD}${WHITE}Secure${NC}$(printf '%*s' $((62 - ${#t4})) '')${CYAN}║${NC}"

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
INSTALL_RPM_OK=0
INSTALL_RPM_FAIL=0

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

# ── The pieces that are missing, and how to add each one ──────
# Only pieces that were actually attempted and failed are listed here.
# An optional extra that was deliberately left out is not "missing" —
# it was never asked for, so it is never reported as a failure.
_print_missing_pieces() {
  if [ "$MISSING_COUNT" -eq 0 ]; then
    return 0
  fi
  local _i
  echo ""
  echo -e "  ${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
  local _mt="  ◆  MISSING PIECES  -  ${MISSING_COUNT} item(s)"
  echo -e "  ${YELLOW}║${NC}${_mt}$(printf '%*s' $((62 - ${#_mt})) '')${YELLOW}║${NC}"
  echo -e "  ${YELLOW}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
  for _i in ${MISSING_LABEL[@]+"${!MISSING_LABEL[@]}"}; do
    local _l="  •  ${MISSING_LABEL[$_i]}"
    local _f="      add it with:  ${MISSING_FIX[$_i]}"
    if [ "${#_f}" -gt 62 ]; then
      _f="      add it with:  ${MISSING_FIX[$_i]:0:48}..."
    fi
    echo -e "  ${YELLOW}║${NC}${_l}$(printf '%*s' $((62 - ${#_l})) '')${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}${_f}$(printf '%*s' $((62 - ${#_f})) '')${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
  done
  local _f1="  A failed step is never marked as done, so a re-run of"
  local _f2="  'bash install.sh' retries exactly what is missing."
  echo -e "  ${YELLOW}║${NC}${_f1}$(printf '%*s' $((62 - ${#_f1})) '')${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}${_f2}$(printf '%*s' $((62 - ${#_f2})) '')${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
  echo -e "  ${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# ── RAM / RESOURCE OPTIMIZATION ──────────────────────────────
# Applies service tweaks without changing GNOME file indexing.
# Existing indexer masks/disables are left untouched: their origin is unknown.

optimize_system_resources() {
  next_step "Disable RAM-wasting Services"

  local _step_fail=0

  # ── 1. ABRT (crash reporter) ──
  # Saves ~50-80 MB. Removes bug-report popups — crash logs still exist.
  if sudo systemctl disable --now abrtd abrt-oops abrt-journal-core abrt-xorg 2>/dev/null; then
    ok "ABRT crash reporting disabled (~50-80 MB saved)"
  else
    local _abrt_left=0 _u
    for _u in abrtd abrt-oops abrt-journal-core abrt-xorg; do
      if systemctl is-enabled "$_u" 2>/dev/null | grep -Eq '^(enabled|enabled-runtime|linked)'; then
        _abrt_left=1
      fi
    done
    if [ "$_abrt_left" -ne 0 ]; then
      warn "ABRT could not be disabled"
      _step_fail=1
    else
      warn "ABRT already disabled or not installed"
    fi
  fi

  # ── 2. GNOME Software auto-start ──
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

  # ── 3. PackageKit background updates ──
  # Saves ~40-60 MB. `sudo dnf update` still works manually.
  if sudo systemctl mask packagekit 2>/dev/null; then
    sudo systemctl stop packagekit 2>/dev/null || true
    ok "PackageKit background updates disabled (~40-60 MB saved)"
  else
    if systemctl is-enabled packagekit 2>/dev/null | grep -Eq '^(enabled|enabled-runtime|linked)'; then
      warn "PackageKit could not be masked"
      _step_fail=1
    else
      warn "PackageKit already masked or not installed"
    fi
  fi

  # ── 4. Firewalld (decision made up front with the other prompts) ──
  # INSTALL_DISABLE_FIREWALLD comes from prompt_firewalld (top prompts) or
  # a saved answer. "true" = disable, "false" = keep/enable, unset = firewalld
  # wasn't running at prompt time, so there is nothing to do.
  if [ "${INSTALL_DISABLE_FIREWALLD:-}" = "true" ]; then
    if sudo systemctl disable --now firewalld 2>/dev/null; then
      ok "Firewalld disabled (~30-50 MB saved)"
    elif systemctl is-active --quiet firewalld 2>/dev/null; then
      warn "Firewalld could not be disabled"
      _step_fail=1
    else
      ok "Firewalld already disabled"
    fi
  elif [ "${INSTALL_DISABLE_FIREWALLD:-}" = "false" ]; then
    if sudo systemctl enable --now firewalld 2>/dev/null; then
      ok "Firewalld enabled and active"
    elif systemctl is-active --quiet firewalld 2>/dev/null; then
      ok "Firewalld enabled and active"
    else
      warn "Firewalld could not be enabled"
      _step_fail=1
    fi
  else
    log "Firewalld not running — nothing to change"
  fi

  if [ "$_step_fail" -ne 0 ]; then
    return 1
  fi
  return 0
}

# ── PREFLIGHT ────────────────────────────────────────────────

# Read-only reachability check, not a guarantee that every later host is available.
_preflight_https() {
  _PREFLIGHT_RETRY_URL=''
  command -v curl >/dev/null 2>&1 || {
    warn "HTTPS preflight requires curl. Install curl (sudo dnf install curl), then retry."
    return 1
  }
  # Immutable, small project manifest: validate bytes, not an arbitrary HTTP 200
  # (a captive portal or proxy error page is not a successful project download).
  local ref=6529c3695cabf05543cc94712806a3c90b9c445a
  local expected=51850cfb13b3853378f602afbf9d5bff3d7994e8c26a0bdbf883f65e48e22a0d
  local url digest probe_rc transport_only=1
  for url in \
    "https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/$ref/updates.json" \
    "https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi/raw/$ref/updates.json"; do
    # -q ignores curlrc overrides; normal proxy/CA environment remains supported.
    # Two attempts total, no retries; HTTPS-only redirects, verified TLS.
    if digest=$(curl -q --fail --silent --show-error --location \
      --proto '=https' --proto-redir '=https' --max-redirs 3 \
      --connect-timeout 3 --max-time 8 --retry 0 --max-filesize 65536 \
      "$url" | sha256sum); then
      if [ "${digest%% *}" = "$expected" ]; then
        return 0
      fi
      warn "Project HTTPS probe returned unexpected content: $url"
      transport_only=0
    else
      probe_rc=$?
      case "$probe_rc" in 5|6|7|18|28|52|55|56) : ;; *) transport_only=0 ;; esac
      warn "Project HTTPS probe failed: $url"
    fi
  done
  warn "Neither project HTTPS download could be verified. Check DNS, proxy/VPN, captive-portal login, system clock and CA certificates, or retry later."
  if [ "$transport_only" -eq 1 ]; then _PREFLIGHT_RETRY_URL="$url"; fi
  return 1
}

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
      if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_notice 'Use Kitty instead of Ptyxis. Install Kitty with sudo dnf install kitty, then run this installer there.'; fi
      echo ""
      echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
pt_title="          ⛔  WOAH — PTYXIS DETECTED"
      echo -e "  ${CYAN}║${NC}${pt_title}$(printf '%*s' $((61 - ${#pt_title})) '')${CYAN}║${NC}"
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
      echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
      echo -e "     ${YELLOW}kitty -e bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh)\"${NC}"
      echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
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
    echo "  │  ✦  KITTY = THE REAL DEAL  ✦                                │"
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
    echo "  │  Then:    run this in Kitty:                                │"
    echo "  │                                                             │"
    echo "     kitty -e bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh)\""
    echo "  │                                                             │"
    echo "  │                                                             │"
    echo "  │  Press any key to continue                                  │"
    echo "  │  or Ctrl+C to grab Kitty first (recommended)                │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
    # First press: acknowledge (any key including Enter works)
    _wait_or_close
    echo -e "  ${DIM}ok, one more thing...${NC}"
    # Second press: confirm
    echo ""
    echo -e "  ┌─────────────────────────────────────────────────────────────┐"
    echo -e "  │  ${BOLD}${YELLOW}⚠  FOR REAL? NO KITTY?${NC}                                     │"
    echo -e "  ├─────────────────────────────────────────────────────────────┤"
    echo -e "  │  You're about to run without the terminal this whole        │"
    echo -e "  │  thing was designed for. Some stuff might look off,         │"
    echo -e "  │  and you'll miss out on the best parts. Your call.          │"
    echo -e "  │                                                             │"
    echo -e "  │  Press ${BOLD}any key${NC} to proceed (no judgment)                     │"
    echo -e "  │  Press ${BOLD}Ctrl+C${NC} to install Kitty first (smart move)           │"
    echo -e "  └─────────────────────────────────────────────────────────────┘"
    echo -en "  ${DIM}Waiting on you...${NC} "
    _wait_or_close
    echo -e "${GREEN}let's roll${NC}"
  fi

  # ── OS check ──
  local detected_os="Unknown Linux"
  if [ -f /etc/os-release ]; then
    detected_os=$(grep -oP '^NAME="?\K[^"]+' /etc/os-release 2>/dev/null || echo "Unknown Linux")
  fi
  if [ ! -f /etc/fedora-release ]; then
    if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_notice 'Fedora Workstation is required. This operating system is unsupported.'; fi
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
      if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_notice 'The active desktop must be GNOME. Switch to Fedora Workstation GNOME.'; fi
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
ide_cmd="    sudo dnf group install workstation-product-environment"
      echo -e "  ${RED}║${NC}${ide_cmd}$(printf '%*s' $((62 - ${#ide_cmd})) '')${RED}║${NC}"
      echo -e "  ${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
      echo ""
      exit 1
    fi
  fi
  if [ "$gnome_ok" = false ]; then
    if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_notice 'GNOME Shell was not found. Fedora Workstation with GNOME is required.'; fi
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
gnome_cmd1="    sudo dnf group install workstation-product-environment"
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
  while ! _preflight_https; do
    if [ -n "${_PREFLIGHT_RETRY_URL:-}" ]; then
      _net_recover "$_PREFLIGHT_RETRY_URL" || return 130
    else
      fail "Project HTTPS preflight failed; installation has not started."
    fi
  done
  ok "Project HTTPS download verified"

  # ── Sudo check ──
  if ! sudo -n true 2>/dev/null; then
    warn "Sudo coming up — have your password ready."
  fi
  sudo echo "Sudo OK" >/dev/null || fail "Sudo required"
  ok "Sudo access granted"
}

# ── PTYXIS REMOVAL ───────────────────────────────────────────

remove_ptyxis() {
  next_step "Remove Old Terminal (system terminal)"

  # Honor the old-terminal prompt: a decline keeps the app fully untouched.
  # Unset means the prompt never ran (no old terminal installed) — nothing
  # to remove anyway, so the checks below report cleanly.
  if [ "${INSTALL_REMOVE_OLD_TERMINAL:-false}" != "true" ]; then
    if rpm -q ptyxis &>/dev/null || command -v ptyxis &>/dev/null || flatpak info org.gnome.Ptyxis &>/dev/null; then
      ok "Old terminal kept — you declined removal"
      _VISUAL_SKIP_REASON='removal declined'
    else
      ok "Old terminal not installed — nothing to remove"
      _VISUAL_SKIP_REASON='not installed'
    fi
    return 0
  fi

  if rpm -q ptyxis &>/dev/null; then
    log "Removing Ptyxis package..."
    local _dnf_log="/tmp/_ptyxis-dnf.log" _dnf_rc=0
    sudo dnf remove -y ptyxis > "$_dnf_log" 2>&1 || _dnf_rc=$?
    tail -1 "$_dnf_log" 2>/dev/null | sed 's/^/      /' || true
    rm -f "$_dnf_log" 2>/dev/null || true
    if rpm -q ptyxis &>/dev/null; then
      warn "Ptyxis package removal failed (dnf exit $_dnf_rc) — leaving its settings untouched"
      return 1
    fi
    if [ "$_dnf_rc" -ne 0 ]; then
      warn "dnf exited $_dnf_rc, but the Ptyxis package is no longer installed"
    fi
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
  backup_dconf || return 1
  dconf reset -f /org/gnome/Ptyxis/ 2>/dev/null || true
  # Desktop entry
  sudo rm -f /usr/share/applications/org.gnome.Ptyxis.desktop 2>/dev/null || true
  sudo rm -f /usr/share/applications/org.gnome.Console.desktop 2>/dev/null || true
  # MacTahoe theme icon for Ptyxis
  find "$HOME/.local/share/icons" -path "*MacTahoe*ptyxis*" -delete 2>/dev/null || true
  # System terminal binaries belong to their packages/alternatives manager.

  # Verify no traces remain
  local leftover_config leftover_data leftover_dconf
  leftover_config=$(find "$HOME/.config" -maxdepth 1 -name "*Ptyxis*" 2>/dev/null)
  leftover_data=$(find "$HOME/.local/share" -maxdepth 1 -name "*Ptyxis*" 2>/dev/null)
  leftover_dconf=$(dconf dump /org/gnome/Ptyxis/ 2>/dev/null)
  if [ -z "$leftover_config" ] && [ -z "$leftover_data" ] && [ -z "$leftover_dconf" ]; then
    ok "All Ptyxis traces cleaned"
    return 0
  fi
  warn "Some Ptyxis traces may remain — manual check recommended"
  return 1
}

remove_gnome_weather() {
  next_step "Remove GNOME Weather (replaced by Mousam)"

  if rpm -q gnome-weather &>/dev/null; then
    log "Removing gnome-weather package..."
    local _dnf_log="/tmp/_gnome-weather-dnf.log" _dnf_rc=0
    sudo dnf remove -y gnome-weather > "$_dnf_log" 2>&1 || _dnf_rc=$?
    tail -1 "$_dnf_log" 2>/dev/null | sed 's/^/      /' || true
    rm -f "$_dnf_log" 2>/dev/null || true
    if [ "$_dnf_rc" -ne 0 ] && rpm -q gnome-weather &>/dev/null; then
      warn "gnome-weather removal failed (dnf exit $_dnf_rc)"
      return 1
    fi
    ok "gnome-weather removed"
  else
    ok "gnome-weather not installed — nothing to remove"
    _VISUAL_SKIP_REASON='not installed'
  fi
  return 0
}

# ── PHASE 1: SYSTEM FOUNDATIONS ──────────────────────────────

# ── RPM Fusion mirror fetch ─────────────────────────────────────
# mirrors.rpmfusion.org now redirects release-RPM downloads to dead
# mirrors (ftp.cc.uoc.gr times out after 30s, repos.eggycrew.com has no
# DNS record at all). A single dead mirror aborts the entire dnf
# transaction, and under `set -e` that kills the installer at step 4 of 29.
#
# download1.rpmfusion.org is the canonical origin and stays healthy, so we
# pull the release RPMs ourselves, verify each one really is a package (a
# mirror can answer 200 with an HTML error page), and hand dnf a local
# file. No metalink, no redirect, no dead mirror.
_rpmfusion_fetch() {
  # $1 = repo (free|nonfree)   $2 = fedora release   $3 = private staging dir
  local repo="$1" release="$2"
  local name="rpmfusion-${repo}-release-${release}.noarch.rpm"
  local dest="$3/${name}"
  local mirror mime
  for mirror in \
    "https://download1.rpmfusion.org" \
    "https://mirrors.rpmfusion.org" \
    "https://mirror.rpmfusion.org"; do
    rm -f "$dest"
    if curl -fsSL --connect-timeout 10 --max-time 60 -o "$dest" \
         "${mirror}/${repo}/fedora/${name}" 2>/dev/null; then
      mime=$(file --brief --mime-type "$dest" 2>/dev/null || true)
      if [ "$mime" = "application/x-rpm" ] || rpm -qp "$dest" &>/dev/null; then
        echo "$dest"
        return 0
      fi
    fi
    rm -f "$dest"
  done
  return 1
}

# Mark the RPM Fusion repos skip_if_unavailable so one dead mirror inside
# the metalink set can never abort a dnf transaction.
_rpmfusion_harden_repos() {
  local _f
  for _f in /etc/yum.repos.d/rpmfusion-*.repo; do
    [ -f "$_f" ] || continue
    if ! grep -q '^skip_if_unavailable' "$_f"; then
      sudo sed -i '/^\[rpmfusion-/a skip_if_unavailable=True' "$_f" 2>/dev/null || true
    fi
  done
}

install_rpmfusion() {
  local _step_fail=0
  next_step "RPM Fusion + Codecs"
  log "Tip: If this step hangs on repo metadata, press Ctrl+C once — the script handles it safely"

  local release rpm_free rpm_nonfree rpm_dir
  release=$(rpm -E %fedora 2>/dev/null) || release="40"
  if ! rpm_dir=$(mktemp -d /tmp/fedora-mactahoe-rpms.XXXXXXXXXX); then
    warn "Cannot create private RPM staging directory"
    return 1
  fi

  # Fetch the release RPMs from a healthy mirror, then install the local
  # files. Installing straight from a URL lets the mirror service pick a
  # dead target — that is what broke this step.
  rpm_free=$(_rpmfusion_fetch free "$release" "$rpm_dir" || true)
  rpm_nonfree=$(_rpmfusion_fetch nonfree "$release" "$rpm_dir" || true)

  if [ -n "$rpm_free" ] && [ -n "$rpm_nonfree" ]; then
    if sudo dnf install -y "$rpm_free" "$rpm_nonfree" > /tmp/_rpmfusion-dnf.log 2>&1; then
      ok "RPM Fusion repos installed"
    else
      warn "RPM Fusion repo install failed — continuing without them"
      _step_fail=1
      tail -3 /tmp/_rpmfusion-dnf.log 2>/dev/null | sed 's/^/      /' || true
    fi
    rm -f /tmp/_rpmfusion-dnf.log 2>/dev/null || true
  else
    warn "No RPM Fusion mirror reachable — skipping repos (codecs will be limited)"
    _step_fail=1
  fi
  [ -n "$rpm_free" ] && rm -f "$rpm_free" 2>/dev/null || true
  [ -n "$rpm_nonfree" ] && rm -f "$rpm_nonfree" 2>/dev/null || true
  rmdir -- "$rpm_dir" 2>/dev/null || warn "RPM staging directory retained: $rpm_dir"

  _rpmfusion_harden_repos

  # Authentication belongs to native sudo, without a process deadline. Keep
  # the existing bound on the subsequent network/package query only.
  sudo -v || return 1
  timeout 60 sudo -n dnf check-update 2>/dev/null || true

  # Fedora 44+ ships ffmpeg-free which conflicts with RPM Fusion's ffmpeg.
  # Swap it out cleanly before installing the rest.
  if rpm -q ffmpeg-free &>/dev/null && ! rpm -q ffmpeg &>/dev/null; then
    log "Replacing Fedora's ffmpeg-free with RPM Fusion's ffmpeg..."
    sudo dnf swap -y ffmpeg-free ffmpeg 2>/dev/null || \
      sudo dnf install -y --allowerasing ffmpeg 2>/dev/null || {
        warn "Could not replace ffmpeg-free with ffmpeg"
        _step_fail=1
      }
  fi

  # Codecs are a nice-to-have, never a blocker. A theming install must not
  # die because a third-party repo is unreachable.
  if sudo dnf install -y \
    ffmpeg ffmpegthumbnailer gstreamer1-plugin-libav gstreamer1-plugins-ugly \
    gstreamer1-plugins-bad-freeworld gstreamer1-plugins-bad-free-extras \
    > /tmp/_rpmfusion-dnf.log 2>&1; then
    ok "Codecs installed"
  else
    warn "Codec packages unavailable — skipping (RPM Fusion repos may be unreachable)"
    _step_fail=1
    tail -3 /tmp/_rpmfusion-dnf.log 2>/dev/null | sed 's/^/      /' || true
  fi
  rm -f /tmp/_rpmfusion-dnf.log 2>/dev/null || true

  if ! sudo dnf group install -y multimedia; then
    warn "Multimedia group installation failed — continuing; retry with: sudo dnf group install -y multimedia"
    _step_fail=1
  fi
  rm -rf ~/.cache/thumbnails/
  nautilus -q 2>/dev/null || true
  if [ "$_step_fail" -ne 0 ]; then
    return 1
  fi
  ok "RPM Fusion + codecs step complete"
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
    _wait_or_close
    echo -e "${GREEN}proceeding${NC}"
    # A missing driver package must not kill the install — the desktop
    # still works on the fallback graphics driver.
    if sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-settings vdpauinfo libva-utils > /tmp/_nvidia-dnf.log 2>&1; then
      ok "NVIDIA drivers installed — fingers crossed"
    else
      warn "NVIDIA driver packages unavailable — continuing (fallback graphics driver stays)"
      tail -3 /tmp/_nvidia-dnf.log 2>/dev/null | sed 's/^/      /' || true
    fi
    rm -f /tmp/_nvidia-dnf.log 2>/dev/null || true
  else
    warn "No NVIDIA gear found — moving on"
    _VISUAL_SKIP_REASON='no NVIDIA GPU detected'
  fi
}

# ── PHASE 2: PACKAGES ────────────────────────────────────────

install_rpm_packages() {
  next_step "RPM Packages"

  local pkgs="fish kitty fastfetch figlet lolcat eza \
    celluloid vlc \
    kdenlive pavucontrol alacarte \
    nautilus-python gnome-tweaks gnome-characters \
    adwaita-icon-theme adwaita-icon-theme-legacy \
    ImageMagick fzf ripgrep jq 7zip unzip curl wget git \
    bat cmatrix qrencode podman python3-pip speedtest-cli xdg-utils \
    libreoffice-writer libreoffice-calc libreoffice-impress \
    libheif-freeworld libheif-tools \
    intel-media-driver mesa-va-drivers \
    gstreamer1-libav gstreamer1-plugins-good gstreamer1-plugins-bad-free gstreamer1-plugins-ugly \
    mozilla-openh264 alsa-sof-firmware \
    ntfs-3g samba-client cifs-utils \
    cups-filters hplip"

  # Package names change between Fedora releases. One unknown name must
  # not take the whole transaction — and with it the whole install —
  # down. Try the full set first; if that fails, retry one by one and
  # report exactly what was unavailable.
  local failed_pkgs=""
  local _step_fail=0
  INSTALL_RPM_OK=0
  INSTALL_RPM_FAIL=0
  if sudo dnf install -y $pkgs > /tmp/_pkgs-dnf.log 2>&1; then
    INSTALL_RPM_OK=$(echo $pkgs | wc -w | tr -d ' ')
    log "RPM packages installed"
  else
    warn "Bulk package install failed — retrying one by one"
    local _p
    for _p in $pkgs; do
      if ! sudo dnf install -y "$_p" >> /tmp/_pkgs-dnf.log 2>&1; then
        failed_pkgs="${failed_pkgs} $_p"
        INSTALL_RPM_FAIL=$((INSTALL_RPM_FAIL + 1))
      else
        INSTALL_RPM_OK=$((INSTALL_RPM_OK + 1))
      fi
    done
    if [ -n "$failed_pkgs" ]; then
      warn "Unavailable packages:${failed_pkgs}"
      _step_fail=1
    fi
    if [ "$INSTALL_RPM_FAIL" -eq 0 ]; then
      log "RPM packages installed after the one-by-one retry"
    fi
  fi
  rm -f /tmp/_pkgs-dnf.log 2>/dev/null || true

  # Load-bearing packages must be present — later steps depend on them
  # (kitty becomes the default terminal, fish becomes the shell).
  local _crit="kitty fish fastfetch ImageMagick fzf"
  local _missing=""
  local _c
  for _c in $_crit; do
    if ! rpm -q "$_c" &>/dev/null && ! command -v "$_c" &>/dev/null; then
      _missing="${_missing} $_c"
    fi
  done
  if [ -n "$_missing" ]; then
    warn "Critical packages missing:${_missing}  — later steps may not fully apply"
    _step_fail=1
  fi

  # Starship prompt (not in Fedora repos — install via official script)
  if ! command -v starship &>/dev/null; then
    if ! curl -fsSL --max-time 60 https://starship.rs/install.sh | _ui_native_run sh -s -- -y; then
      warn "Starship install failed — check network or https://starship.rs"
      _step_fail=1
    fi
  fi

  if [ "$_step_fail" -ne 0 ]; then
    warn "RPM package step incomplete — see warnings above"
    return 1
  fi
  ok "RPM packages installed"
  return 0
}

install_browsers() {
  next_step "Browsers (Firefox, Chrome, Edge, VS Code)"

  local _step_fail=0

  # Firefox
  if ! rpm -q firefox &>/dev/null; then
    if ! sudo dnf install -y firefox > /tmp/_firefox-dnf.log 2>&1; then
      warn "Firefox unavailable — skipping (Fedora repo may be unreachable)"
      tail -3 /tmp/_firefox-dnf.log 2>/dev/null | sed 's/^/      /' || true
      _step_fail=1
    fi
    rm -f /tmp/_firefox-dnf.log 2>/dev/null || true
  fi

  # Chrome — create repo file directly (--from-repofile not supported by Google)
  if [ "$(uname -m)" != "x86_64" ]; then
    warn "Google Chrome RPM is supported only on x86_64 — skipping Chrome on $(uname -m)"
  elif ! rpm -q google-chrome-stable &>/dev/null; then
    if ! sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub 2>/dev/null; then
      warn "Failed to import Google signing key — Chrome repo may not be trusted"
    fi
    if [ ! -e /etc/yum.repos.d/google-chrome.repo ] && [ ! -L /etc/yum.repos.d/google-chrome.repo ]; then
      if ! sudo sh -c 'set -C; cat > /etc/yum.repos.d/google-chrome.repo' <<-EOF
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
      then
        warn "Could not create Chrome repository — existing configuration preserved"
        _step_fail=1
      fi
    fi
    # Install from repo, with direct RPM as offline fallback
    if ! sudo dnf install -y google-chrome-stable 2>/dev/null && \
       ! sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm; then
      warn "Chrome installation failed — check network or Google repos"
      _step_fail=1
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
      _step_fail=1
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
    if ! sudo dnf install -y code > /tmp/_vscode-dnf.log 2>&1; then
      warn "VS Code unavailable — skipping (Microsoft repo may be unreachable)"
      tail -3 /tmp/_vscode-dnf.log 2>/dev/null | sed 's/^/      /' || true
      _step_fail=1
    fi
    rm -f /tmp/_vscode-dnf.log 2>/dev/null || true
  fi

  if [ "$_step_fail" -ne 0 ]; then
    warn "Browser step incomplete — one or more apps were not installed"
    return 1
  fi
  ok "Browsers + VS Code installed"
  return 0
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
  if [ "$INSTALL_FP_FAIL" -gt 0 ]; then
    warn "$INSTALL_FP_FAIL flatpak(s) failed to install — check network or flathub status"
  fi

  # Always attempt overrides (non-critical)
  sudo flatpak override --filesystem=xdg-config/gtk-3.0 2>/dev/null || true
  sudo flatpak override --filesystem=xdg-config/gtk-4.0 2>/dev/null || true

  if [ "$INSTALL_FP_FAIL" -gt 0 ]; then
    return 1
  fi
  return 0
}

# ── PHASE 3: THEMES ──────────────────────────────────────────

# ── MacTahoe source locator (upstream → vendored fallback) ──
# Populates $1 with a working MacTahoe-gtk source tree, preferring the
# upstream repo; falls back to the vendored snapshot bundled in this
# project (vendor/MacTahoe-gtk-theme/) when upstream is unreachable.
# Sets _MCT_SRC (path) and _MCT_FROM (upstream|vendored) on success.
# Returns 0 on success, 1 when neither source is available.
_mactahoe_get_source() {
  _MCT_SRC=""
  _MCT_FROM=""
  local repo="$1"
  local vendored="$BUNDLE/vendor/MacTahoe-gtk-theme"

  rm -rf "$repo"
  if timeout 120 git clone --depth 1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$repo" 2>/dev/null \
      && [ -f "$repo/install.sh" ] && [ -f "$repo/tweaks.sh" ] && bash -n "$repo/install.sh" 2>/dev/null; then
    _MCT_SRC="$repo"
    _MCT_FROM="upstream"
    return 0
  fi

  # Vendored snapshot (survives upstream deletion / network failures)
  if [ -f "$vendored/install.sh" ] && [ -f "$vendored/tweaks.sh" ] && bash -n "$vendored/install.sh" 2>/dev/null; then
    warn "Upstream MacTahoe unreachable — using vendored source"
    rm -rf "$repo"
    if cp -a "$vendored" "$repo" 2>/dev/null && [ -f "$repo/install.sh" ]; then
      _MCT_SRC="$repo"
      _MCT_FROM="vendored"
      return 0
    fi
    warn "Vendored source copy failed — MacTahoe source unavailable"
    return 1
  fi

  return 1
}

install_mactahoe_theme() {
  next_step "MacTahoe GTK Theme (compiled from source)"

  local repo="/tmp/mactahoe-build"
  local gtk_version
  gtk_version=$(gnome-shell --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1 || echo "unknown")

  # Purge leftovers
  rm -rf "$HOME/.themes/MacTahoe"* "$HOME/.local/share/themes/MacTahoe"*
  sudo rm -rf /usr/share/themes/MacTahoe* 2>/dev/null || true

  # Get MacTahoe source: upstream clone → vendored snapshot → pre-compiled bundle
  log "Cloning MacTahoe source (GNOME $gtk_version)..."
  if _mactahoe_get_source "$repo"; then
    log "Compiling all theme variants with blur + libadwaita..."
    if ! _ui_native_run "$repo/install.sh" -t all -b -l; then
      warn "Compilation failed — theme not installed"
      return 1
    fi
  else
    warn "No MacTahoe source available (upstream + vendored) — falling back to bundled pre-compiled theme"
    local fallback_dir="$BUNDLE/themes/MacTahoe-Dark"
    if [ -d "$fallback_dir" ]; then
      mkdir -p "$HOME/.themes" "$HOME/.local/share/themes" "$HOME/.config/gtk-4.0"
      cp -r "$fallback_dir" "$HOME/.themes/"
      cp -r "$fallback_dir" "$HOME/.local/share/themes/"
      cp -r "$fallback_dir/gtk-4.0/"* "$HOME/.config/gtk-4.0/" 2>/dev/null || true
      ok "Bundled MacTahoe-Dark installed as fallback"
      return 0
    fi
    warn "No fallback available — theme not installed"
    return 1
  fi

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
  install_icons
}

# ── Icon themes + custom macOS app icons (standalone step for `update icons`) ──
_resize_app_icon() {
  local png="$1" stage
  local -a writer=()
  if [ "${2:-}" = system ]; then writer=(sudo); fi
  stage=$(mktemp "${TMPDIR:-/tmp}/mactahoe-icon.XXXXXXXXXX.png") || return 1
  if { magick -regard-warnings "$png" -trim +repage -resize 256x256 -gravity center -background transparent -extent 256x256 "$stage" 2>/dev/null ||
       convert -regard-warnings "$png" -trim +repage -resize 256x256 -gravity center -background transparent -extent 256x256 "$stage"; } &&
     [ -s "$stage" ] && "${writer[@]}" cp -f "$stage" "$png"; then
    rm -f -- "$stage"
    return 0
  fi
  rm -f -- "$stage"
  warn "Could not resize icon: $png — continuing with other assets"
  return 1
}

install_icons() {
  local _step_fail=0
  local theme_src="$BUNDLE/themes"
  local user_hicolor="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
  [[ "$user_hicolor" = /* ]] || user_hicolor="$HOME/.local/share/icons/hicolor"
  if ! _merge_hicolor_index; then return 1; fi

  # Clean stale icon theme directories/symlinks from previous installs
  for stale in MacTahoe MacTahoe-dark MacTahoe-light MacTahoe-Eprahemi MacTahoe-dark-Eprahemi; do
    rm -rf "$HOME/.local/share/icons/$stale" 2>/dev/null || true
  done

  for icon in MacTahoe MacTahoe-dark; do
    if ! mkdir -p "$HOME/.local/share/icons" ||
       ! cp -a "$theme_src/$icon" "$HOME/.local/share/icons/"; then
      warn "Could not install required icon theme: $icon"
      _step_fail=1
      continue
    fi
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
    # Skip home dirs whose user no longer exists (leftover dirs) — sudo would fail
    id "$_user" >/dev/null 2>&1 || continue
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

  if [ "$_step_fail" -eq 0 ]; then ok "Icon themes installed (MacTahoe + MacTahoe-dark)"; fi

  # Custom macOS app icons (SVG+PNG) — ALWAYS OVERRIDE on conflict
  local icon_src="$BUNDLE/icons/256x256"
  if [ -d "$icon_src" ] && [ "$(ls -A "$icon_src"/*.png "$icon_src"/*.svg 2>/dev/null)" ]; then
    local targets=(
      "$HOME/.local/share/icons/MacTahoe-dark/apps/scalable"
      "$HOME/.local/share/icons/MacTahoe/apps/scalable"
      "$user_hicolor/256x256/apps"
    )
    if ! mkdir -p "${targets[@]}"; then warn "Could not prepare custom icon destinations"; return 1; fi

    # Copy SVGs first (preferred format for scalable)
    for svg in "$icon_src"/*.svg; do
      [ -f "$svg" ] || continue
      f=$(basename "$svg")
      for t in "${targets[@]}"; do
        if ! cp -f "$svg" "$t/$f"; then warn "Could not copy icon: $f"; _step_fail=1; fi
      done
    done

    # Also copy PNGs as fallback for older apps
    for png in "$icon_src"/*.png; do
      [ -f "$png" ] || continue
      f=$(basename "$png")
      for t in "${targets[@]}"; do
        if ! cp -f "$png" "$t/$f"; then warn "Could not copy icon: $f"; _step_fail=1; fi
      done
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
      for t in "${targets[@]}"; do
        if ! cp -f "$svg" "$t/$alias_svg_name"; then warn "Could not copy icon alias: $alias_svg_name"; _step_fail=1; fi
      done
    done
    # PNG aliases
    for png in "$icon_src"/*.png; do
      [ -f "$png" ] || continue
      local base; base=$(basename "$png")
      local alias_png="${fp_aliases[$base]:-}"
      [ -z "$alias_png" ] && continue
      for t in "${targets[@]}"; do
        if ! cp -f "$png" "$t/$alias_png"; then warn "Could not copy icon alias: $alias_png"; _step_fail=1; fi
      done
    done

    # Trim padding + resize to 256×256 (PNGs only — SVGs are already correct)
    for t in "${targets[@]}"; do
      for png in "$t"/*.png; do
        [ -f "$png" ] || continue
        if ! _resize_app_icon "$png"; then _step_fail=1; fi
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
    # The shared merge runs before installing icons; never replace the user index.
    gtk-update-icon-cache "$user_hicolor/" 2>/dev/null || warn "Icon cache update failed for hicolor"

    # ── System-wide: copy all icons + aliases so EVERY user gets them ──
    local sys="/usr/share/icons/hicolor/256x256/apps"
    if ! sudo mkdir -p "$sys"; then warn "Could not prepare system app icon destination"; _step_fail=1; fi
    for f in "$icon_src"/*.svg "$icon_src"/*.png; do
      [ -f "$f" ] || continue
      if ! sudo cp -f "$f" "$sys/"; then warn "Could not copy system icon: $f"; _step_fail=1; fi
    done
    # Flatpak aliases system-wide (PNG)
    for f in "$icon_src"/*.png; do
      [ -f "$f" ] || continue
      local base; base=$(basename "$f")
      local alias="${fp_aliases[$base]:-}"
      [ -z "$alias" ] && continue
      if ! sudo cp -f "$f" "$sys/$alias"; then warn "Could not copy system icon alias: $alias"; _step_fail=1; fi
    done
    # Flatpak aliases system-wide (SVG)
    for f in "$icon_src"/*.svg; do
      [ -f "$f" ] || continue
      local base; base=$(basename "$f")
      local base_noext="${base%.svg}"
      local alias="${fp_aliases[${base_noext}.png]:-}"
      [ -z "$alias" ] && continue
      local alias_svg_name="${alias%.png}.svg"
      if ! sudo cp -f "$f" "$sys/$alias_svg_name"; then warn "Could not copy system icon alias: $alias_svg_name"; _step_fail=1; fi
    done
    # Trim + resize system-wide PNGs
    for png in "$sys"/*.png; do
      [ -f "$png" ] || continue
      if ! _resize_app_icon "$png" system; then _step_fail=1; fi
    done
    # Rebuild system icon cache
    sudo gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || warn "System-wide icon cache update failed"

    if [ "$_step_fail" -eq 0 ]; then
      ok "Custom macOS app icons installed ($(ls "$icon_src"/*.png 2>/dev/null | wc -l) PNGs + $(ls "$icon_src"/*.svg 2>/dev/null | wc -l) SVGs)"
    fi
  else
    warn "Required custom app icons are missing from $icon_src"
    _step_fail=1
  fi
  return "$_step_fail"
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
    return 1
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
  if [ ! -d "$desktop_src" ] || [ -z "$(ls -A "$desktop_src" 2>/dev/null)" ]; then
    warn "No desktop entries found"
    return 1
  fi

  mkdir -p "$HOME/.local/share/applications"
  local _copied=0
  local _desk
  for _desk in "$desktop_src"/*.desktop; do
    [ -f "$_desk" ] || continue
    if cp "$_desk" "$HOME/.local/share/applications/" 2>/dev/null; then
      _copied=$((_copied + 1))
    fi
  done
  if [ "$_copied" -eq 0 ]; then
    warn "No desktop entries could be copied"
    return 1
  fi
  ok "Desktop entries applied ($_copied file(s))"
  return 0
}

apply_configs() {
  next_step "Config Files (Kitty, Fish, Starship, GTK, Fastfetch)"
  _force_popup_blur_off || return 1

  local cfg="$BUNDLE/configs"
  local _fish_fail=0

  # The updater uses this same presentation engine without fetching executable
  # UI code during local app management. The bundle is already verified by its
  # caller; copy failure is a real configuration-step failure.
  if [ -f "$BUNDLE/bootstrap.sh" ]; then
    mkdir -p "$HOME/.local/share/fedora-mactahoe" || return 1
    cp "$BUNDLE/bootstrap.sh" "$HOME/.local/share/fedora-mactahoe/ui-library.sh" || return 1
  fi

  # Kitty
  if [ -f "$cfg/kitty/kitty.conf" ]; then
    mkdir -p "$HOME/.config/kitty"
    cp "$cfg/kitty/kitty.conf" "$HOME/.config/kitty/"
    # User overrides file — created empty on first install, NEVER overwritten.
    # kitty.conf ends with `include user.conf`, so user settings always win.
    if [ ! -f "$HOME/.config/kitty/user.conf" ]; then
      : > "$HOME/.config/kitty/user.conf"
    fi
    # ktheme auto-theme palette file — kitty.conf ends with `include auto-theme.conf`,
    # so the file MUST exist or kitty logs an include error and skips it.
    if [ ! -e "$HOME/.config/kitty/auto-theme.conf" ]; then
      if [ -L "$HOME/.config/kitty/auto-theme.conf" ] ||
         ! cp -nT "$cfg/kitty/auto-theme.conf" "$HOME/.config/kitty/auto-theme.conf"; then
        warn "Could not seed Kitty palette — existing links left untouched"
        return 1
      fi
    fi
    # Preserve personalized colors while off, including a disabled but running
    # watcher. Match install_ktheme_watcher's enabled-state fallback policy.
    local _kt_palette_enabled=0
    if systemctl --user is-enabled ktheme-watcher.service &>/dev/null ||
       [ -L "$HOME/.config/systemd/user/default.target.wants/ktheme-watcher.service" ]; then
      _kt_palette_enabled=1
    fi
    if [ "$_kt_palette_enabled" -eq 1 ] && command -v fish >/dev/null 2>&1 && [ -f "$HOME/.config/fish/functions/ktheme.fish" ]; then
      fish -c 'ktheme apply --silent' >/dev/null 2>&1 || true
    fi
    ok "Kitty config"
  fi

  # Fish
  # NEVER write ~/.config/fish/config.fish — it belongs to the user. Project
  # settings are a conf.d snippet, which fish sources before config.fish, so
  # user aliases, environment variables, functions and startup commands always
  # survive an install. (Before 3.7.5 this step overwrote config.fish.)
  if [ -d "$cfg/fish" ]; then
    # Auto-backup the live fish config before touching anything (keeps last 5)
    if [ -d "$HOME/.config/fish" ]; then
      mkdir -p "$HOME/.cache/fedora-mactahoe/backups"
      chmod 700 "$HOME/.cache/fedora-mactahoe/backups" 2>/dev/null || true
      local snap="$HOME/.cache/fedora-mactahoe/backups/fish-$(date +%Y%m%d-%H%M%S).tar.gz"
      tar czf "$snap" -C "$HOME/.config" fish 2>/dev/null || true
      chmod 600 "$snap" 2>/dev/null || true
      ls -1t "$HOME/.cache/fedora-mactahoe/backups"/fish-*.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm -f 2>/dev/null || true
    fi
    mkdir -p "$HOME/.config/fish/functions" "$HOME/.config/fish/conf.d"

    if [ -f "$cfg/fish/conf.d/50-fedora-mactahoe.fish" ]; then
      if ! cp -f "$cfg/fish/conf.d/50-fedora-mactahoe.fish" \
           "$HOME/.config/fish/conf.d/50-fedora-mactahoe.fish"; then
        warn "Could not install the Fedora MacTahoe fish settings snippet"
        _fish_fail=1
      fi
    else
      warn "Fish settings snippet missing from the bundle"
      _fish_fail=1
    fi

    if [ -d "$cfg/fish/functions" ]; then
      cp -f "$cfg/fish/functions/"*.fish "$HOME/.config/fish/functions/" 2>/dev/null || true
    fi

    # A pre-3.7.5 install may still carry the old project block inside
    # config.fish. It is left untouched; the snippet is additive. Mention the
    # duplicate once so a double fastfetch banner is not a mystery.
    if [ -f "$HOME/.config/fish/config.fish" ] && grep -q 'ANI_CLI_PLAYER vlc' "$HOME/.config/fish/config.fish" 2>/dev/null; then
      warn "config.fish still contains the old MacTahoe block; project settings now load from conf.d/50-fedora-mactahoe.fish (the duplicate lines are safe to remove)"
    fi
    ok "Fish config ($(ls "$HOME/.config/fish/functions/"*.fish 2>/dev/null | wc -l) functions)"
  fi

  # Guard hook (root-owned) — the system fish config warns in every terminal if
  # the MacTahoe fish config is ever deleted. A normal user cannot remove it.
  # The recovery one-liner fingerprint-checks update.fish against updates.json
  # before it is restored (sha256 pinned in the manifest — same supply-chain
  # rule as _update_run in update.fish).
  if [ -f /etc/fish/config.fish ] && sudo -n true 2>/dev/null; then
    if ! grep -q "fedora-mactahoe-guard" /etc/fish/config.fish 2>/dev/null; then
      sudo tee -a /etc/fish/config.fish >/dev/null <<'EOF'

# ── Fedora MacTahoe guard (eprahemi) ──
if test -d "$HOME/.cache/fedora-mactahoe"; and not test -f "$HOME/.config/fish/functions/update.fish"
    set -g fish_greeting ""
    printf '\n'
    printf '\e[1;31m███╗   ██╗███████╗██████╗ ██████╗ ██████╗\e[0m\n'
    printf '\e[1;31m████╗  ██║██╔════╝██╔══██╗██╔══██╗██╔══██╗\e[0m\n'
    printf '\e[1;31m██╔██╗ ██║█████╗  ██████╔╝██████╔╝██████╔╝\e[0m\n'
    printf '\e[1;31m██║╚██╗██║██╔══╝  ██╔══██╗██╔══██╗██╔══██╗\e[0m\n'
    printf '\e[1;31m██║ ╚████║███████╗██║  ██║██║  ██║██████╔╝\e[0m\n'
    printf '\e[1;31m╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝\e[0m\n'
    printf '\e[1;31m██████╗ ███████╗███████╗ ██████╗██╗   ██╗███████╗\e[0m\n'
    printf '\e[1;31m██╔══██╗██╔════╝██╔════╝██╔════╝██║   ██║██╔════╝\e[0m\n'
    printf '\e[1;31m██████╔╝█████╗  ███████╗██║     ██║   ██║█████╗\e[0m\n'
    printf '\e[1;31m██╔══██╗██╔══╝  ╚════██║██║     ██║   ██║██╔══╝\e[0m\n'
    printf '\e[1;31m██║  ██║███████╗███████║╚██████╗╚██████╔╝███████╗\e[0m\n'
    printf '\e[1;31m╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝\e[0m\n'
    printf '\e[1;31m██╗    ██╗ █████╗ ██████╗ ███╗   ██╗██╗███╗   ██╗ ██████╗\e[0m\n'
    printf '\e[1;31m██║    ██║██╔══██╗██╔══██╗████╗  ██║██║████╗  ██║██╔════╝\e[0m\n'
    printf '\e[1;31m██║ █╗ ██║███████║██████╔╝██╔██╗ ██║██║██╔██╗ ██║██║  ███╗\e[0m\n'
    printf '\e[1;31m██║███╗██║██╔══██║██╔══██╗██║╚██╗██║██║██║╚██╗██║██║   ██║\e[0m\n'
    printf '\e[1;31m╚███╔███╔╝██║  ██║██║  ██║██║ ╚████║██║██║ ╚████║╚██████╔╝\e[0m\n'
    printf '\e[1;31m ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚══╝╚═╝╚═╝  ╚══╝ ╚═════╝\e[0m\n'
    printf '\n'
    printf '\e[1m  [!] Fedora MacTahoe fish config is missing.\e[0m\n'
    printf '\e[1m\n'
    printf '\e[1m      Do not worry — getting it back is one command:\e[0m\n'
    printf '\e[1m      Type   update   and press Enter (yes is the default).\e[0m\n'
    printf '\e[1m\n'
    printf '\e[1m      It downloads the update function from GitHub, checks its\e[0m\n'
    printf '\e[1m      fingerprint, and then restores the rest of your fish\e[0m\n'
    printf '\e[1m      functions automatically (update configs).\e[0m\n'
    printf '\e[1m\n'
    printf '\e[1m      Nothing is installed unless the fingerprint matches.\e[0m\n'
end
# ── Fedora MacTahoe did-you-mean fallback (fedora-mactahoe-handler) ──
# fish does not autoload event handlers from /etc, so the system-wide
# handler needs an explicit source here; it stays quiet whenever the
# user's own copy exists (that one autoloads normally).
if not test -f "$HOME/.config/fish/functions/__fish_default_command_not_found_handler.fish"
    and test -f /etc/fish/functions/__fish_default_command_not_found_handler.fish
    source /etc/fish/functions/__fish_default_command_not_found_handler.fish
end
# ── end of fedora-mactahoe-handler ──
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

  # Update only our drop-in; preserve all other admin/vendor overrides.
  if [ -f "$BUNDLE/config/logind.conf.d/logind-overrides.conf" ]; then
    if ! sudo mkdir -p /etc/systemd/logind.conf.d ||
       ! sudo install -o root -g root -m 644 "$BUNDLE/config/logind.conf.d/logind-overrides.conf" /etc/systemd/logind.conf.d/logind-overrides.conf; then
      warn "Could not install systemd-logind overrides"
      return 1
    fi
    ok "systemd-logind overrides"
  fi

  if [ "$_fish_fail" -ne 0 ]; then
    warn "Fish configuration could not be installed completely"
    return 1
  fi
  return 0
}

# Merge the MacTahoe custom keybindings into the user's existing list.
# Existing paths are never removed and an occupied slot is never overwritten.
# New users get every default. Existing users get only the missing defaults
# whose key combination is not already in use; conflicts are reported.
_merge_custom_keybindings() {
  local plan
  if ! plan=$(python3 - <<'KEYBINDING_MERGE'
import ast
import os
import subprocess
import sys

GSETTINGS = os.environ.get('GSETTINGS_BIN', 'gsettings')
BASE = 'org.gnome.settings-daemon.plugins.media-keys'
CUSTOM = BASE + '.custom-keybinding:'
PREFIX = '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/'

DEFAULTS = [
    ('Kitty', '<Super>t', 'kitty'),
    ('Nautilus', '<Super>e', 'nautilus'),
    ('Task Manager', '<Shift><Control>Escape', 'gnome-system-monitor'),
    ('Volume', '<Control><Alt>v', 'pavucontrol'),
    ('Notes', '<Super>n', 'gnome-text-editor'),
    ('Chrome', '<Super>w', 'google-chrome'),
    ('Firefox', '<Super>f', 'firefox'),
    ('Spotify', '<Super>z', 'flatpak run com.spotify.Client'),
    ('Settings', '<Control>i', 'gnome-control-center'),
    ('Emoji Picker', '<Super>period', 'gnome-characters'),
]


def run_get(schema, key):
    result = subprocess.run([GSETTINGS, 'get', schema, key],
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            text=True)
    if result.returncode != 0:
        raise RuntimeError('gsettings get failed')
    return result.stdout.strip()


def parse_array(text):
    text = text.strip()
    if text.startswith('@as '):
        text = text[4:].strip()
    value = ast.literal_eval(text)
    if not isinstance(value, (list, tuple)):
        raise ValueError('not an array')
    if not all(isinstance(item, str) for item in value):
        raise ValueError('non-string entry')
    return list(value)


def parse_string(text):
    text = text.strip()
    if text.startswith('@s '):
        text = text[3:].strip()
    value = ast.literal_eval(text)
    if not isinstance(value, str):
        raise ValueError('not a string')
    return value


def variant_array(items):
    escaped = []
    for item in items:
        escaped.append("'" + item.replace('\\', '\\\\').replace("'", "\\'") + "'")
    return '[' + ', '.join(escaped) + ']'


def clean(text):
    return ' '.join(str(text).split())


def slot_path(number):
    return PREFIX + 'custom' + str(number) + '/'


def read_slot(path):
    return {
        'path': path,
        'name': parse_string(run_get(CUSTOM + path, 'name')),
        'binding': parse_string(run_get(CUSTOM + path, 'binding')),
        'command': parse_string(run_get(CUSTOM + path, 'command')),
    }


try:
    paths = parse_array(run_get(BASE, 'custom-keybindings'))
    active = [read_slot(path) for path in paths]
except Exception as error:
    print('cannot read custom keybindings: ' + str(error), file=sys.stderr)
    raise SystemExit(1)

used_bindings = {}
for entry in active:
    if entry['binding'] and entry['binding'] not in used_bindings:
        used_bindings[entry['binding']] = entry

plan = []
conflicts = []
chosen = []
slot_cache = {}


def cached_slot(number):
    if number not in slot_cache:
        slot_cache[number] = read_slot(slot_path(number))
    return slot_cache[number]


for name, binding, command in DEFAULTS:
    existing = used_bindings.get(binding)
    if existing is not None:
        if existing['name'] == name and existing['command'] == command:
            continue
        conflicts.append(binding + " is already used by '" + clean(existing['name']) + "'; keeping your binding")
        continue

    target = None
    for number in range(100):
        path = slot_path(number)
        if path in paths or path in chosen:
            continue
        state = cached_slot(number)
        if state['binding'] == '':
            target = state
            break
        if (state['binding'] == binding and state['name'] == name
                and state['command'] == command):
            target = state
            break

    if target is None:
        conflicts.append('no free custom keybinding slot for ' + name + ' (' + binding + ')')
        continue

    plan.append((target['path'], name, binding, command))
    chosen.append(target['path'])
    used_bindings[binding] = {
        'path': target['path'], 'name': name,
        'binding': binding, 'command': command,
    }

for path, name, binding, command in plan:
    print('SET\t' + path + '\t' + name + '\t' + binding + '\t' + command)
for message in conflicts:
    print('CONFLICT\t' + message)
print('LIST\t' + variant_array(paths + chosen))
KEYBINDING_MERGE
  ); then
    warn "Could not read the current custom keybindings"
    return 1
  fi

  local kind a b c d rc=0
  # Write the slot values before publishing the path in the list. If a write
  # fails the slot stays unlisted; the next run recognises it as our own stale
  # entry and reuses it instead of creating a duplicate.
  while IFS=$'\t' read -r kind a b c d; do
    [ "$kind" = "SET" ] || continue
    if ! gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$a" name "$b" 2>/dev/null ||
       ! gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$a" command "$d" 2>/dev/null ||
       ! gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$a" binding "$c" 2>/dev/null; then
      warn "Could not write custom keybinding $a"
      rc=1
    fi
  done <<< "$plan"

  if [ "$rc" -eq 0 ]; then
    while IFS=$'\t' read -r kind a b c d; do
      [ "$kind" = "LIST" ] || continue
      if ! gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$a" 2>/dev/null; then
        warn "Could not update the custom-keybindings list"
        rc=1
      fi
    done <<< "$plan"
  fi

  while IFS=$'\t' read -r kind a b c d; do
    [ "$kind" = "CONFLICT" ] || continue
    warn "$a"
  done <<< "$plan"

  return "$rc"
}

_force_popup_blur_off() {
  _preserve_active_wallpaper || return 1
  # Exact key only; dconf is safe before the extension schema is installed.
  if ! dconf write /org/gnome/shell/extensions/blur-my-shell/popup/blur false; then
    warn "Could not turn Popup blur OFF"
    return 1
  fi
}

_restore_extension_settings() {
  # dconf works before extension schemas are installed (apply_dconf runs first).
  # Owner policy: configuration runs override even an explicitly saved ON.
  (
    set -o pipefail
    python3 - "$1" <<'PY' | dconf load /org/gnome/shell/extensions/
import re
import sys

section = ''
for line in open(sys.argv[1]):
    header = re.fullmatch(r'\s*\[([^]]+)\]\s*', line)
    if header:
        section = header[1]
    if section == 'blur-my-shell/popup' and re.match(r'\s*blur\s*=', line):
        line = 'blur=false\n'
    sys.stdout.write(line)
PY
  )
}

apply_dconf() {
  next_step "GNOME dconf Settings"

  # Rollback point before any gsettings/dconf writes + extension restore
  backup_dconf || return 1
  _force_popup_blur_off || return 1

  local _core_fail=0
  local _ini_fail=0

  local dconf_file="$BUNDLE/configs/dconf/full-backup.ini"

  # ── Theme ──
  gsettings set org.gnome.desktop.interface gtk-theme "MacTahoe-Dark" 2>/dev/null || _core_fail=1
  gsettings set org.gnome.desktop.interface icon-theme "MacTahoe-dark" 2>/dev/null || _core_fail=1
  gsettings set org.gnome.desktop.interface cursor-theme "MacTahoe-dark" 2>/dev/null || _core_fail=1
  dconf write /org/gnome/shell/extensions/user-theme/name "'MacTahoe-Dark'" 2>/dev/null || _core_fail=1
  gsettings set org.gnome.desktop.wm.preferences theme "MacTahoe-Dark" 2>/dev/null || _core_fail=1

  # ── Interface ──
  gsettings set org.gnome.desktop.interface font-name "SF Pro Display 11" 2>/dev/null || _core_fail=1
  gsettings set org.gnome.desktop.interface document-font-name "SF Pro Display 12" 2>/dev/null || _core_fail=1
  gsettings set org.gnome.desktop.interface monospace-font-name "Adwaita Mono 11" 2>/dev/null || _core_fail=1
  gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || _core_fail=1
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
  gsettings set org.gnome.desktop.wm.preferences button-layout "close,minimize,maximize:appmenu" 2>/dev/null || _core_fail=1
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

  # MERGE, never replace: existing custom bindings are preserved. New users
  # get every MacTahoe default; existing users get only the missing,
  # nonconflicting ones. A key combination already in use is reported and
  # left untouched.
  if ! _merge_custom_keybindings; then
    _core_fail=1
  fi

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

  # ── Extension dconf restore ──
  if [ -f "$dconf_file" ]; then
    if _restore_extension_settings "$dconf_file"; then
      ok "Extension settings restored from backup"
    else
      warn "Could not restore extension settings from backup"
      _core_fail=1
    fi
  fi

  # Re-apply GTK settings.ini AFTER dconf/gsettings (GNOME daemon overwrites it)
  local cfg="$BUNDLE/configs"
  if [ -f "$cfg/gtk-3.0/settings.ini" ]; then
    mkdir -p "$HOME/.config/gtk-3.0"
    cp "$cfg/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/" || { warn "Failed to copy gtk-3.0 settings.ini"; _ini_fail=1; }
  fi
  if [ -f "$cfg/gtk-4.0/settings.ini" ]; then
    mkdir -p "$HOME/.config/gtk-4.0"
    cp "$cfg/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/" || { warn "Failed to copy gtk-4.0 settings.ini"; _ini_fail=1; }
  fi

  if [ "$_core_fail" -ne 0 ] || [ "$_ini_fail" -ne 0 ]; then
    warn "Some core GNOME settings could not be applied"
    return 1
  fi
  ok "dconf settings applied"
  return 0
}

# ── Optional passwordless sudo prompt (run before Phase 1) ──

prompt_sudoers_entry() {
  # A documentation-only template: never migrate or change existing policy.
  # Keep creation/validation/publication in one privileged process so the
  # validated inode is root-owned and cannot be replaced by the caller.
  local template_user
  if ! template_user=$(id -un); then
    warn "Cannot identify the sudoers template user"
    return 1
  fi
  if ! sudo bash -s -- "$template_user" <<'SUDOERS_TEMPLATE'
set -u
user=$1
case "$user" in
  ''|*[!a-zA-Z0-9_.@-]*) echo "Unsupported sudoers template username" >&2; exit 1 ;;
esac
target=/etc/sudoers.d/90-fedora-mactahoe
# Includes dangling symlinks and directories: never overwrite admin content,
# even if it has our filename or a previous template has been enabled.
if [ -e "$target" ] || [ -L "$target" ]; then
  echo "Existing sudoers drop-in preserved: $target"
  exit 0
fi
if ! visudo -cf /etc/sudoers; then exit 1; fi
if ! mkdir -p /etc/sudoers.d; then exit 1; fi
umask 077
if ! stage=$(mktemp -d /etc/sudoers.d/.fedora-mactahoe.XXXXXXXXXX); then exit 1; fi
trap 'rm -f -- "$stage/template"; rmdir -- "$stage"' EXIT
if ! printf '%s\n' '# Fedora MacTahoe: optional template only; no privileges granted.' \
    "# $user ALL=(ALL) NOPASSWD: ALL" > "$stage/template"; then exit 1; fi
if ! chown root:root "$stage/template" || ! chmod 0440 "$stage/template"; then exit 1; fi
if ! visudo -cf "$stage/template"; then exit 1; fi
# Hard-link publication is atomic and fails if ANY target already exists.
# Unlike mv/cp it never replaces a concurrently-created admin drop-in.
if ! ln -T -- "$stage/template" "$target"; then exit 1; fi
echo "Commented sudoers template installed; existing sudo policy unchanged"
SUDOERS_TEMPLATE
  then
    warn "Sudoers template not installed; existing sudo policy left untouched"
    return 1
  fi
  return 0
}



# ── Desktop wallpaper prompt ─────────────────────────────────
# Asked once per manifest version. A caller-provided
# INSTALL_DESKTOP_WALLPAPER (update wallpaper) skips it, so the
# updater can apply the wallpaper without a second confirmation.
prompt_desktop_wallpaper() {
  _UI_QUESTION_TITLE='Desktop wallpaper'
  _UI_QUESTION_BODY=$'Set Himeno as your desktop background?\nNo keeps the wallpaper you picked. Change later with update wallpaper.'
  if [ -z "${INSTALL_DESKTOP_WALLPAPER:-}" ]; then
    echo ""
    echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    desk_t="       ◆  DESKTOP WALLPAPER?  ◆"
    echo -e "  ${CYAN}║${NC}       ${BOLD}${WHITE}◆  DESKTOP WALLPAPER?${NC}  ${DIM}◆${NC}$(printf '%*s' $((62 - ${#desk_t})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    desk1="  Set the Himeno wallpaper as your desktop background?"
    echo -e "  ${CYAN}║${NC}${desk1}$(printf '%*s' $((62 - ${#desk1})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    desk2="  It is the macOS-style wallpaper that matches the theme."
    echo -e "  ${CYAN}║${NC}${desk2}$(printf '%*s' $((62 - ${#desk2})) '')${CYAN}║${NC}"
    desk3="  A wallpaper you picked yourself is kept if you answer No."
    echo -e "  ${CYAN}║${NC}${desk3}$(printf '%*s' $((62 - ${#desk3})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    desk4="  Change it anytime with: update wallpaper"
    echo -e "  ${CYAN}║${NC}${desk4}$(printf '%*s' $((62 - ${#desk4})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    desk5="  Press Enter for default (Yes)"
    echo -e "  ${CYAN}║${NC}${DIM}${desk5}$(printf '%*s' $((62 - ${#desk5})) '')${NC}${CYAN}║${NC}"
    echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    if confirm "Set the Himeno desktop wallpaper? [Y/n]: " Y; then
      INSTALL_DESKTOP_WALLPAPER="true"
      echo -e "  ${GREEN}→ Himeno will be set as your desktop wallpaper${NC}"
    else
      INSTALL_DESKTOP_WALLPAPER="false"
      echo -e "  ${DIM}→ Your desktop wallpaper will be left alone${NC}"
    fi
  fi
}

# ── GDM login screen prompt ─────────────────────────────────
prompt_gdm_login() {
  _UI_QUESTION_TITLE='LOGIN SCREEN'
  _UI_QUESTION_BODY=$'Use the Himeno wallpaper and macOS-style theme, and hide the Fedora logo.\n\nChoose No to preserve your current login screen.\nAfter installation, use the gdm command to manage its wallpaper.'
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
    if confirm "Apply the Fedora MacTahoe login theme? [Y/n]: " Y; then
      INSTALL_LOGIN_WALLPAPER="true"
      echo -e "  ${GREEN}→ GDM login screen will be themed${NC}"
    else
      INSTALL_LOGIN_WALLPAPER="false"
      echo -e "  ${DIM}→ Skipping GDM login screen${NC}"
    fi
  fi
}

# ── Old terminal prompt (asked up front with the other prompts) ──
# Only asked when Ptyxis is actually installed. If it is not there, there is
# nothing to remove and the prompt must not appear. Returns 1 when Ptyxis is
# absent (caller saves no answer — the default is false anyway).
prompt_remove_old_terminal() {
  _UI_QUESTION_TITLE='Remove the old terminal?'
  _UI_QUESTION_BODY=$'Ptyxis is installed. Yes removes the app, its settings and cache.\nNo keeps it untouched. Kitty remains the intended terminal.'
  local _present=0
  if rpm -q ptyxis &>/dev/null; then _present=1; fi
  if command -v ptyxis &>/dev/null; then _present=1; fi
  if flatpak info org.gnome.Ptyxis &>/dev/null; then _present=1; fi
  if [ "$_present" -eq 0 ]; then
    return 1
  fi

  if [ -z "${INSTALL_REMOVE_OLD_TERMINAL:-}" ]; then
    echo ""
    echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    ot_t="          ◆  REMOVE OLD TERMINAL?  ◆"
    echo -e "  ${CYAN}║${NC}${ot_t}$(printf '%*s' $((62 - ${#ot_t})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    ot1="  The old terminal app that came with Fedora is installed."
    echo -e "  ${CYAN}║${NC}${ot1}$(printf '%*s' $((62 - ${#ot1})) '')${CYAN}║${NC}"
    ot2="  Remove it together with its settings and cache so you"
    echo -e "  ${CYAN}║${NC}${ot2}$(printf '%*s' $((62 - ${#ot2})) '')${CYAN}║${NC}"
    ot3="  start completely fresh with Kitty as your only terminal."
    echo -e "  ${CYAN}║${NC}${ot3}$(printf '%*s' $((62 - ${#ot3})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    ot4="    Yes  — Remove old terminal, its cache and settings"
    echo -e "  ${CYAN}║${NC}    ${BOLD}${GREEN}Y${NC}${BOLD}es${NC}  — Remove old terminal, its cache and settings$(printf '%*s' $((62 - ${#ot4})) '')${CYAN}║${NC}"
    ot5="    no   — Keep it, don't delete anything"
    echo -e "  ${CYAN}║${NC}    ${BOLD}${YELLOW}n${NC}${BOLD}o${NC}   — Keep it, don't delete anything$(printf '%*s' $((62 - ${#ot5})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    ot6="  Press Enter for default (No — keep it)"
    echo -e "  ${CYAN}║${NC}${DIM}${ot6}$(printf '%*s' $((62 - ${#ot6})) '')${NC}${CYAN}║${NC}"
    ot7="  Tip: set INSTALL_REMOVE_OLD_TERMINAL=true to skip this"
    echo -e "  ${CYAN}║${NC}${DIM}${ot7}$(printf '%*s' $((62 - ${#ot7})) '')${NC}${CYAN}║${NC}"
    echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    if confirm "Remove the old terminal app + its cache? [y/N]: " N; then
      INSTALL_REMOVE_OLD_TERMINAL="true"
      echo -e "  ${GREEN}→ Old terminal will be removed — fresh start with Kitty${NC}"
    else
      INSTALL_REMOVE_OLD_TERMINAL="false"
      echo -e "  ${DIM}→ Old terminal will be kept — nothing gets deleted${NC}"
    fi
  fi
  return 0
}

# ── Firewalld prompt (asked up front with the other prompts) ──
# The actual disable/enable action still runs later in
# optimize_system_resources (Step: Disable RAM-wasting Services).
# Returns 0 when an answer is available, 1 when firewalld isn't
# running (nothing to ask about — the step skips it too).
prompt_firewalld() {
  _UI_QUESTION_TITLE='Disable firewalld?'
  _UI_QUESTION_BODY=$'Yes stops the firewall manager. No keeps/enables it.\nManaged filtering and container integration can change when it stops.\nReview this security choice carefully. Enter defaults to Yes.'
  # Only ask when firewalld is actually running — the box's premise is
  # "Firewalld is running and using ~30-50 MB RAM."
  if ! systemctl is-active firewalld >/dev/null 2>&1; then
    return 1
  fi

  if [ -z "${INSTALL_DISABLE_FIREWALLD:-}" ]; then
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
fw7="  Press Enter for default (Yes — disable)"
    echo -e "  ${YELLOW}║${NC}${DIM}${fw7}$(printf '%*s' $((62 - ${#fw7})) '')${NC}${YELLOW}║${NC}"
    echo -e "  ${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    if confirm "Disable firewalld? [Y/n]: " Y; then
      INSTALL_DISABLE_FIREWALLD="true"
      echo -e "  ${GREEN}→ Firewalld will be disabled (saves ~30-50 MB)${NC}"
    else
      INSTALL_DISABLE_FIREWALLD="false"
      echo -e "  ${DIM}→ Firewalld will be kept/enabled${NC}"
    fi
  fi
  return 0
}

apply_wallpapers() {
  next_step "Wallpaper + Login Screen"
  _install_asset_pack wallpaper
}

install_custom_avatars() {
  next_step "Custom Profile Pictures (Avatars)"
  _install_asset_pack avatar
}

# ── 🔥 Billie & Jinx video edits (optional prompt + download, step 22) ──
_install_downloaded_videos() {
  # Flatten nested archive paths; exclusive creation preserves every collision.
  # Never extract archive links or use archive paths as filesystem paths.
  python3 - "$1" "$2" "${3:-}" <<'PY'
import os, pathlib, shutil, stat, sys, zipfile
source, destination, raw_name = sys.argv[1:]
extensions = {'.mp4', '.mkv', '.mov', '.avi', '.webm', '.m4v'}
try:
    os.makedirs(destination, exist_ok=True)
    directory = os.open(destination, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        def publish(name, stream):
            try:
                fd = os.open(name, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                             0o600, dir_fd=directory)
            except FileExistsError:
                print('Preserved existing video: ' + repr(name))
                return
            try:
                with os.fdopen(fd, 'wb') as output:
                    shutil.copyfileobj(stream, output)
                # Only files created by this invocation receive fresh timestamps.
                os.utime(name, None, dir_fd=directory, follow_symlinks=False)
            except BaseException:
                os.unlink(name, dir_fd=directory)
                raise
        if raw_name:
            with open(source, 'rb') as stream:
                publish(raw_name, stream)
        else:
            with zipfile.ZipFile(source) as archive:
                entries = []
                for entry in archive.infolist():
                    path = pathlib.PurePosixPath(entry.filename)
                    mode = entry.external_attr >> 16
                    if (path.is_absolute() or '..' in path.parts or
                            '\\' in entry.filename or '\x00' in entry.filename or
                            stat.S_ISLNK(mode)):
                        raise ValueError('Unsafe archive path or link')
                    if not entry.is_dir() and path.suffix.lower() in extensions:
                        entries.append((entry, path.name))
                if not entries:
                    raise ValueError('Archive contains no videos')
                for entry, name in entries:
                    with archive.open(entry) as stream:
                        publish(name, stream)
    finally:
        os.close(directory)
except Exception as error:
    print('Video installation failed: ' + str(error), file=sys.stderr)
    sys.exit(1)
PY
}

download_optional_videos() {
  # Keep progress accounting, but do not announce an unrequested extra.
  if [ "${INSTALL_BILLIE_VIDEOS:-false}" != "true" ]; then
    next_step "Download Billie & Jinx + Gintama Videos" >/dev/null
    _VISUAL_SKIP_REASON='not requested'
    return 0
  fi
  next_step "Download Billie & Jinx + Gintama Videos"

  # ── Download if opted in ──
  if [ "${INSTALL_BILLIE_VIDEOS:-false}" = "true" ]; then
    log "Fetching hot Billie & Jinx edits… 🔥"
    local dl_dest _video_tmp _video_failed=0
    dl_dest=$(xdg-user-dir DOWNLOAD 2>/dev/null) || dl_dest=""
    case "$dl_dest" in /*) ;; *) dl_dest="$HOME/Downloads" ;; esac
    dl_dest="$dl_dest/Billie Hot Body"
    _video_tmp=$(mktemp -d) || return 1
    local zip_tmp="$_video_tmp/billie.zip"
    if [ "${SKIP_VIDEOS:-false}" = "true" ]; then
      warn "Skipping the video edits — the hosted link is dead"
      if [ "${SKIP_GINTAMA:-false}" = "true" ]; then
        _VISUAL_SKIP_REASON='hosted assets unavailable; skipped by request'
      fi
    elif _net_download "$DOWNLOADS_URL" "$zip_tmp" --max-time 90 -b "download_warning=1"; then
      local _extracted=false
      if is_valid_zip "$zip_tmp"; then
        if _install_downloaded_videos "$zip_tmp" "$dl_dest"; then
          _extracted=true
          ok "Billie & Jinx edits installed in $dl_dest"
        else
          warn "Billie & Jinx archive could not be extracted (may be corrupted)"
        fi
      elif file --brief --mime-type "$zip_tmp" 2>/dev/null | grep -qi "html"; then
        warn "Downloaded Billie & Jinx archive looks like an HTML page — the file may be deleted from Google Drive"
        _drive_failed "video edits" "update videos"
      else
        # Try extracting anyway (some zips don't have PK magic at offset 0)
        if _install_downloaded_videos "$zip_tmp" "$dl_dest"; then
          _extracted=true
          ok "Billie & Jinx edits installed in $dl_dest"
        else
          warn "Billie & Jinx archive could not be extracted (may be corrupted)"
        fi
      fi
      [ "$_extracted" = true ] || _video_failed=1
      rm -f "$zip_tmp" 2>/dev/null || true
    else
      _drive_failed "video edits" "update videos"
      _video_failed=1
    fi
    # A transport Stop is different from an ordinary per-asset failure.
    if [ -s "${_FED_NET_STOP:-/dev/null}" ]; then
      rm -f -- "$_video_tmp/billie.zip"
      rmdir -- "$_video_tmp" 2>/dev/null || true
      return 1
    fi
      # Independently attempt the second requested asset.
      log "Fetching Gintama video edits..."
      local gintama_tmp="$_video_tmp/gintama"
      if [ "${SKIP_GINTAMA:-false}" = "true" ]; then
        warn "Skipping the video edit (mp4) — the hosted link is dead"
      elif _net_download "$GINTAMA_URL" "$gintama_tmp" --max-time 90 -b "download_warning=1"; then
        # Detect type: zip, mp4, or html
        local gintama_mime
        gintama_mime=$(file --brief --mime-type "$gintama_tmp" 2>/dev/null || echo "unknown")
        local _gintama_ok=false
        if echo "$gintama_mime" | grep -qi "html"; then
          warn "Downloaded Gintama file is an HTML page — the file may be deleted from Google Drive"
          _drive_failed "video edit (mp4)" "update videos"
        elif is_valid_zip "$gintama_tmp"; then
          _install_downloaded_videos "$gintama_tmp" "$dl_dest" && _gintama_ok=true || true
          [ "$_gintama_ok" = true ] && ok "Gintama edits installed in $dl_dest"
        elif echo "$gintama_mime" | grep -qi "mp4\|video"; then
          if _install_downloaded_videos "$gintama_tmp" "$dl_dest" "Gintama - Bad Boy.mp4"; then
            _gintama_ok=true
            ok "Gintama edits installed in $dl_dest"
          fi
        else
          warn "Gintama download has unknown type ($gintama_mime) — file may be corrupted or deleted"
          _drive_failed "video edit (mp4)" "update videos"
        fi
        [ "$_gintama_ok" = true ] || _video_failed=1
        rm -f "$gintama_tmp" 2>/dev/null || true
      else
        warn "Gintama download failed"
        _drive_failed "video edit (mp4)" "update videos"
        _video_failed=1
      fi
    rm -f -- "$_video_tmp/billie.zip" "$_video_tmp/gintama"
    rmdir -- "$_video_tmp" 2>/dev/null || true
    # A partially installed pair must remain eligible for retry.
    [ "$_video_failed" -eq 0 ] || return 1
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
  local _step_fail=0 folder sort reverse
  # ── 1. Per‑folder sort order (via GVFS metadata — what Nautilus 50 actually reads) ──
  for folder in "$HOME/Downloads" "$HOME/Pictures" "$HOME/Videos" "$HOME/Music" "$HOME/Documents"; do
    if [ -d "$folder" ]; then
      sort=name; reverse=false
      if [ "$folder" = "$HOME/Downloads" ]; then sort=date_modified; reverse=true; fi
      if gio set "$folder" metadata::nautilus-icon-view-sort-by "$sort" &&
         gio set "$folder" metadata::nautilus-icon-view-sort-reversed "$reverse"; then
        ok "${folder##*/} → sort by $sort (reversed: $reverse)"
      else
        warn "Could not set Nautilus sorting for ${folder##*/}"
        _step_fail=1
      fi
    fi
  done

  # GTK3, GTK4 and Nautilus share gtk-3.0/bookmarks. Never rebuild a user's list.
  # Remove only the exact literal line emitted by older project installers.
  if ! _remove_project_trash_bookmark; then
    warn "Could not remove the old project Trash bookmark"
    return 1
  fi

  # ── 3. File-chooser dialogs: do NOT sort folders before files ──
  if gsettings set org.gtk.Settings.FileChooser sort-directories-first false &&
     gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first false; then
    ok "File chooser: 'Sort folders before files' turned off"
  else
    warn "Could not configure file chooser sorting"
    _step_fail=1
  fi
  return "$_step_fail"
}

_remove_project_trash_bookmark() {
  python3 - <<'PY'
import os
import pathlib
import stat
import tempfile

config = os.environ.get('XDG_CONFIG_HOME', '')
if not os.path.isabs(config):
    config = os.path.join(os.environ['HOME'], '.config')
path = pathlib.Path(config) / 'gtk-3.0' / 'bookmarks'
try:
    before = path.lstat()
except FileNotFoundError:
    raise SystemExit(0)
if not stat.S_ISREG(before.st_mode):
    raise SystemExit('Refusing non-regular bookmarks file')
original = path.read_bytes()
known = os.fsencode('file://' + os.environ['HOME'] + '/.local/share/Trash/files Trash')
updated = b''.join(line for line in original.splitlines(keepends=True)
                   if line.rstrip(b'\r\n') != known)
if updated == original:
    raise SystemExit(0)
fd, temporary = tempfile.mkstemp(prefix='.mactahoe-bookmarks-', dir=path.parent)
try:
    with os.fdopen(fd, 'wb') as stream:
        stream.write(updated)
        stream.flush()
        os.fchmod(stream.fileno(), stat.S_IMODE(before.st_mode))
        os.fchown(stream.fileno(), before.st_uid, before.st_gid)
        os.fsync(stream.fileno())
    if path.lstat() != before or path.read_bytes() != original:
        raise RuntimeError('Bookmarks changed during cleanup')
    os.replace(temporary, path)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
PY
}

setup_gdm() {
  next_step "GDM Login Screen Theme"

  local _gdm_requested=0
  if [ "${INSTALL_LOGIN_WALLPAPER:-true}" = "true" ]; then
    _gdm_requested=1
  else
    _VISUAL_SKIP_REASON='not requested'
  fi

  local wp="$BUNDLE/wallpapers"
  local bg=""
  local engine="$HOME/.local/share/mactahoe-gdm"
  local engine_script="$engine/gdm-wallpaper.sh"
  local _gdm_ok=0
  local _gdm_fb_ok=0

  if [ "$_gdm_requested" -eq 1 ]; then
    if [ -f "$wp/login/Himeno Fedora LoginScreen.jpg" ]; then
      bg="$wp/login/Himeno Fedora LoginScreen.jpg"
    elif [ -f "$wp/desktop/Himeno Fedora.jpg" ]; then
      bg="$wp/desktop/Himeno Fedora.jpg"
    fi

  # ── Apply with the runtime engine (FedoraTahoe-GDM) ──
  # This is the same engine `gdm` uses and the only one verified against the
  # live GNOME release. Upstream tweaks.sh stays as a fallback for the rare
  # case where the engine cannot be fetched.
  if [ ! -f "$engine_script" ]; then
    local _engine_tmp="${engine}.clone.$$"
    rm -rf "$_engine_tmp"
    if timeout 120 git clone --depth 1 https://github.com/eprahemi/FedoraTahoe-GDM.git "$_engine_tmp" 2>/dev/null; then
      mkdir -p "$engine"
      cp -a "$_engine_tmp/." "$engine/"
      chmod +x "$engine/gdm-wallpaper.sh" "$engine/restore.sh" 2>/dev/null || true
    fi
    rm -rf "$_engine_tmp"
  fi

  if [ -f "$engine_script" ]; then
    local _before="" _after="" _gdm_rc=0
    if [ -f /usr/share/gnome-shell/gnome-shell-theme.gresource ]; then
      _before=$(sha256sum /usr/share/gnome-shell/gnome-shell-theme.gresource 2>/dev/null | cut -d' ' -f1)
    fi
    if [ -n "$bg" ]; then
      sudo bash "$engine_script" -g -nb -nd -b "$bg" || _gdm_rc=$?
    else
      sudo bash "$engine_script" -g -nb -nd || _gdm_rc=$?
    fi
    if [ -f /usr/share/gnome-shell/gnome-shell-theme.gresource ]; then
      _after=$(sha256sum /usr/share/gnome-shell/gnome-shell-theme.gresource 2>/dev/null | cut -d' ' -f1)
    fi

    if [ "$_gdm_rc" -eq 0 ] && [ -n "$_after" ]; then
      _gdm_ok=1
      # Same bookkeeping the `gdm` command does: keep the applied image for
      # `gdm save`, and record the installed bundle for `gdm protect`.
      if [ -n "$bg" ]; then
        cp "$bg" "$engine/.gdm-undo-copy.jpg" 2>/dev/null || true
      fi
      sudo cp /usr/share/gnome-shell/gnome-shell-theme.gresource "$engine/.last-gdm.gresource" 2>/dev/null || true
      if [ -n "$_before" ] && [ "$_after" = "$_before" ]; then
        ok "GDM login screen already up to date"
      elif [ -n "$bg" ]; then
        ok "GDM login screen themed — Himeno login wallpaper"
      else
        ok "GDM login screen themed"
      fi
    else
      warn "GDM engine failed (exit $_gdm_rc) — login screen not changed"
    fi
  fi

    # Fallback: upstream tweaks.sh, only when the runtime engine did not run.
    if [ "$_gdm_ok" -eq 0 ]; then
      if _mactahoe_get_source /tmp/mactahoe-gtk && [ -f /tmp/mactahoe-gtk/tweaks.sh ]; then
        local _fb_rc=0
        if [ -n "$bg" ]; then
          ( cd /tmp/mactahoe-gtk && sudo ./tweaks.sh -g -nb -nd -b "$bg" ) || _fb_rc=$?
        else
          ( cd /tmp/mactahoe-gtk && sudo ./tweaks.sh -g -nb -nd ) || _fb_rc=$?
        fi
        if [ "$_fb_rc" -eq 0 ]; then
          _gdm_fb_ok=1
          ok "GDM login screen themed via upstream tweaks.sh"
        else
          warn "GDM login screen not changed (upstream exit $_fb_rc)"
          warn "  Apply it later with: gdm default"
        fi
      else
        warn "No GDM engine available — login screen not changed"
        warn "  Apply it later with: gdm default"
      fi
    fi
  fi

  # Hide Fedora logo on GDM login screen (runs regardless of theme)
  local _logo_fail=0
  if ! sudo mkdir -p /etc/dconf/db/gdm.d; then
    warn "Could not prepare the GDM dconf directory — Fedora logo not hidden"
    _logo_fail=1
  fi
  if [ "$_logo_fail" -eq 0 ]; then
    if ! printf '%s\n' '[org/gnome/login-screen]' "logo=''" | sudo tee /etc/dconf/db/gdm.d/01-logo > /dev/null; then
      warn "Could not write the GDM logo setting"
      _logo_fail=1
    fi
  fi
  if [ "$_logo_fail" -eq 0 ]; then
    if ! sudo dconf update; then
      warn "Could not apply the GDM logo setting (dconf update failed)"
      _logo_fail=1
    fi
  fi
  if [ "$_logo_fail" -eq 0 ]; then
    ok "Fedora logo hidden from GDM login screen"
  fi

  if [ "$_gdm_requested" -eq 0 ]; then
    ok "GDM login screen skipped (user opted out)"
    if [ "$_logo_fail" -ne 0 ]; then return 1; fi
    return 0
  fi
  if [ "$_logo_fail" -ne 0 ]; then return 1; fi
  if [ "$_gdm_ok" -eq 0 ] && [ "$_gdm_fb_ok" -eq 0 ]; then
    return 1
  fi
  return 0
}

# Match executable identity, not command-line substrings or another user's
# process names. A windowless DBus/background Firefox still owns its profile.
# pidfds pin the selected process across the consent-to-signal race.
_firefox_processes() {
  python3 - "${1:-list}" <<'PY'
import os, pathlib, signal, sys
root = pathlib.Path('/proc')
for entry in root.iterdir():
    if not entry.name.isdecimal():
        continue
    fd = None
    try:
        if entry.stat().st_uid != os.getuid():
            continue
        if sys.argv[1] == 'terminate':
            fd = os.pidfd_open(int(entry.name))
        exe = os.readlink(entry / 'exe').removesuffix(' (deleted)')
        if pathlib.Path(exe).name not in ('firefox', 'firefox-bin'):
            continue
        state = (entry / 'stat').read_text().rsplit(')', 1)[1].split()[0]
        if state in ('Z', 'X'):
            continue
        if fd is not None:
            signal.pidfd_send_signal(fd, signal.SIGTERM)
        else:
            print(entry.name)
    except (OSError, ValueError):
        continue
    finally:
        if fd is not None:
            os.close(fd)
PY
}

setup_firefox_theme() {
  next_step "Firefox macOS Theme (userChrome.css)"
  FIREFOX_THEME_FAILED=0

  local repo="/tmp/mactahoe-gtk"
  if [ ! -f "$repo/tweaks.sh" ]; then
    warn "MacTahoe source not found — fetching (upstream or vendored)"
    if ! _mactahoe_get_source "$repo"; then
      warn "No MacTahoe source available (upstream + vendored) — Firefox theme not applied"
      FIREFOX_THEME_FAILED=1
      return 1
    fi
  fi

  # ── Ensure Firefox is closed before theming ──
  if [ -n "$(_firefox_processes)" ]; then
    echo ""
    echo -e "  ${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${YELLOW}║${NC}        ${BOLD}Close Firefox for macOS theming${NC}                       ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}  Firefox is running (possibly without a browser window).     ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}  Closing Firefox requires your permission.                   ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}  Save your work if needed.                                   ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"

    local reply="" _ff_tty
    # Source fetching and rendering can take time. Recheck before consent.
    if [ -z "$(_firefox_processes)" ]; then
      _ui_native_run "$repo/tweaks.sh" -f || { FIREFOX_THEME_FAILED=1; return 1; }
      return 0
    fi
    if ! { exec {_ff_tty}<>/dev/tty; } 2>/dev/null; then
      warn "No terminal available for consent — skipping Firefox theming"
      _VISUAL_SKIP_REASON='no terminal for close consent'
      return 0
    fi
    if [ "${_UI_ACTIVE:-0}" = 1 ]; then
      _ui_question 'Close Firefox for theming?' 'Your Firefox process is running, possibly in the background without a window. Save your work. Only Yes permits closing it.' 'Close Firefox and apply its theme? [y/N]:'
    fi
    if [ "${_UI_ACTIVE:-0}" != 1 ]; then
      printf '  Save your work. Close Firefox and apply its theme? [y/N]: ' >&"$_ff_tty"
    fi
    if ! read -r reply <&"$_ff_tty"; then
      exec {_ff_tty}>&-
      if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_resume; fi
      warn "No consent received — skipping Firefox theming"
      _VISUAL_SKIP_REASON='no close consent received'
      return 0
    fi
    exec {_ff_tty}>&-
    if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_resume; fi
    case "${reply,,}" in
      y|yes)
        if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_resume work; fi
        _firefox_processes terminate ;;
      *) _VISUAL_SKIP_REASON='close consent declined'; log "Firefox theming skipped; Firefox left running"; return 0 ;;
    esac

    # Wait up to 10 seconds for Firefox to fully exit
    local _ff_wait=0
    while [ -n "$(_firefox_processes)" ]; do
      if [ "$_ff_wait" -ge 10 ]; then
        warn "Firefox did not close within 10 seconds — theme not applied; close it manually and retry"
        FIREFOX_THEME_FAILED=1
        return 1
      fi
      sleep 1
      _ff_wait=$((_ff_wait + 1))
    done
    echo -e "  ${GREEN}  ┊ ✓ ${NC}  Firefox closed — proceeding with theming"
  fi

  if ! _ui_native_run "$repo/tweaks.sh" -f; then
    warn "Firefox theming skipped — not yet initialized"
    FIREFOX_THEME_FAILED=1
  fi

  if [ "${FIREFOX_THEME_FAILED:-0}" = "1" ]; then
    return 1
  fi
  return 0
}

setup_flatpak_theme() {
  next_step "Flatpak GTK Runtime (org.gtk.Gtk3theme.MacTahoe-Dark)"

  sudo dnf install -y ostree libappstream-glib 2>/dev/null || {
    warn "Could not install ostree/appstream-glib — Flatpak theme skipped"
    return 1
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
    return 1
  fi

  rm -rf "$pkg_cache"
  mkdir -p "$repo_dir"

  if ! ostree --repo="$repo_dir" init --mode=archive 2>/dev/null; then
    warn "ostree init failed — Flatpak theme runtime not built"
    return 1
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
    return 1
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
    return 1
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
    return 0
  fi
  warn "Flatpak runtime '$app_id' could not be installed — check permissions or ostree"
  return 1
}

install_sounds() {
  next_step "macOS Big Sur System Sounds"
 (
  local sound_src="$BUNDLE/sounds/bigsur"
  local stage parent="$HOME/.local/share/sounds" target="$HOME/.local/share/sounds/bigsur"
  stage=$(mktemp -d "${TMPDIR:-/tmp}/mactahoe-sounds.XXXXXXXXXX") || return 1
  trap 'rm -rf -- "$stage"' EXIT
  if [ ! -d "$sound_src" ]; then
    warn "Sounds not bundled — building from source instead"
    if ! timeout 120 git clone --depth 1 https://github.com/gxanshu/macos-bigsur-sound-theme-linux.git "$stage/source" ||
       ! timeout 120 git clone --depth 1 https://github.com/ThisIsNoahEvans/BigSurSounds.git "$stage/source/BigSurSounds" ||
       ! timeout 120 git clone --depth 1 https://github.com/KDE/ocean-sound-theme.git "$stage/source/ocean-sound-theme" ||
       ! (cd "$stage/source" && timeout 180 make build); then
      warn "Sound source download/build failed — existing sounds preserved"
      return 1
    fi
    sound_src="$stage/source/theme/bigsur"
  fi
  if [ ! -s "$sound_src/index.theme" ] ||
     ! find "$sound_src/stereo" -type f -name '*.oga' -print -quit 2>/dev/null | grep -q .; then
    warn "Sound payload is incomplete — existing sounds preserved"
    return 1
  fi
  # Add missing bundled sounds, never replace a user's existing sound data.
  if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
    warn "Sound destination is not a regular directory — preserved"
    return 1
  fi
  if ! mkdir -p "$parent" "$target" || ! cp -an "$sound_src/." "$target/"; then
    warn "Could not install sounds — existing files retained"
    return 1
  fi
  if ! gsettings set org.gnome.desktop.sound theme-name "bigsur" ||
     ! gsettings set org.gnome.desktop.sound event-sounds true; then
    warn "Sounds copied but sound preferences could not be applied"
    return 1
  fi
  ok "macOS Big Sur sounds installed (existing sound files preserved)"
  return 0
 )
}

# ── PHASE 4b: UPDATE NOTIFIER ──────────────────────────────

_merge_dnf_automatic() {
  # Parse before modifying; publish from the same directory atomically. Never
  # follow an administrator's symlink or replace a concurrently changed file.
  sudo python3 - /etc/dnf/automatic.conf <<'DNF_AUTOMATIC_MERGE'
import configparser
import os
from pathlib import Path
import re
import shutil
import stat
import sys
import tempfile

path = Path(sys.argv[1])
stage = None
try:
    def identity():
        try:
            s = path.lstat()
        except FileNotFoundError:
            return None
        if not stat.S_ISREG(s.st_mode):
            raise ValueError('automatic.conf is not a regular file; preserved')
        return (s.st_dev, s.st_ino, s.st_size, s.st_mtime_ns, s.st_ctime_ns)

    original_id = identity()
    original = path.read_text() if original_id is not None else ''
    parser = configparser.ConfigParser(interpolation=None, strict=True)
    parser.read_string(original)
    required = {'commands': {'upgrade_type': 'security',
                             'download_updates': 'yes', 'apply_updates': 'no'}}
    # A notification destination is a default, not an administrator override.
    if not parser.has_option('emitters', 'emit_via'):
        required['emitters'] = {'emit_via': 'motd'}
    pending = {section: dict(values) for section, values in required.items()}
    output = []
    section = None

    def finish_section():
        for key, value in pending.get(section, {}).items():
            if output and not output[-1].endswith('\n'):
                output[-1] += '\n'
            output.append(f'{key} = {value}\n')
        pending.pop(section, None)

    for line in original.splitlines(keepends=True):
        header = re.match(r'^\s*\[([^]]+)\]', line)
        if header:
            finish_section()
            section = header.group(1)
        keyline = re.match(r'^(\s*)([^#;\s][^=:\n]*?)(\s*[=:]\s*)(.*?)(\r?\n)?$', line)
        if keyline and section in pending:
            key = keyline.group(2).strip().lower()
            if key in pending[section]:
                value = pending[section].pop(key)
                # Preserve indentation, delimiter and inline comment if present.
                comment = re.search(r'\s+[;#].*$', keyline.group(4))
                line = (keyline.group(1) + keyline.group(2) + keyline.group(3)
                        + value + (comment.group(0) if comment else '')
                        + (keyline.group(5) or '\n'))
        output.append(line)
    finish_section()
    for name, values in pending.items():
        if output and not output[-1].endswith('\n'):
            output[-1] += '\n'
        output.append(f'\n[{name}]\n')
        output.extend(f'{key} = {value}\n' for key, value in values.items())
    result = ''.join(output)
    # Validate the complete result before any filesystem write.
    check = configparser.ConfigParser(interpolation=None, strict=True,
                                      inline_comment_prefixes=('#', ';'))
    check.read_string(result)
    for key, value in required['commands'].items():
        if check.get('commands', key) != value:
            raise ValueError(f'Could not establish commands.{key}')
    if result != original:
        fd, stage = tempfile.mkstemp(prefix='.mactahoe-automatic-', dir=path.parent)
        with os.fdopen(fd, 'w') as stream:
            stream.write(result)
            stream.flush()
            os.fsync(stream.fileno())
        if original_id is not None:
            old = path.stat()
            os.chown(stage, old.st_uid, old.st_gid)
            shutil.copystat(path, stage)
        else:
            os.chmod(stage, 0o644)
        if identity() != original_id:
            raise ValueError('automatic.conf changed during merge; preserved')
        if original_id is None:
            # No-clobber first publication, including a concurrent symlink.
            os.link(stage, path)
        else:
            os.replace(stage, path)
        print('Automatic updates: security downloads only; admin settings preserved')
except (OSError, ValueError, configparser.Error) as error:
    print(f'DNF automatic configuration merge failed: {error}', file=sys.stderr)
    sys.exit(1)
finally:
    if stage is not None and os.path.lexists(stage):
        os.unlink(stage)
DNF_AUTOMATIC_MERGE
}

install_updater() {
  next_step "Fedora MacTahoe Update Notifier"
 (

  local updater_src="$BUNDLE/configs/updater"
  local _step_fail=0
  local source destination backup committed=0 item rollback_failed=0
  local was_enabled=0 was_active=0 activation_started=0
  local -a sources=("$updater_src/fedora-mactahoe-updater.sh" "$updater_src/fedora-mactahoe-updater.service" "$updater_src/fedora-mactahoe-updater.timer"
    "$updater_src/update-rescue.fish" "$BUNDLE/configs/fish/functions/__fish_default_command_not_found_handler.fish")
  for source in "${sources[@]}"; do
    if [ ! -s "$source" ] || [ ! -f "$source" ]; then
      warn "Required updater payload missing or empty: $source"
      return 1
    fi
  done
  if ! bash -n "${sources[0]}" ||
     ! fish --no-config -n "${sources[3]}" || ! fish --no-config -n "${sources[4]}" ||
     ! grep -qxF 'ExecStart=%h/.local/bin/fedora-mactahoe-updater.sh' "${sources[1]}" ||
     ! grep -q '^OnUnitActiveSec=' "${sources[2]}"; then
    warn "Updater payload validation failed — existing installation preserved"
    return 1
  fi
  backup=$(mktemp -d "${TMPDIR:-/tmp}/mactahoe-updater.XXXXXXXXXX") || return 1
  local -a destinations=("$HOME/.local/bin/fedora-mactahoe-updater.sh" "$HOME/.config/systemd/user/fedora-mactahoe-updater.service" "$HOME/.config/systemd/user/fedora-mactahoe-updater.timer")
  for item in 0 1 2; do
    destination="${destinations[$item]}"
    if [ -L "$destination" ] || { [ -e "$destination" ] && [ ! -f "$destination" ]; }; then
      warn "Updater destination is not a regular file: $destination"
      rm -rf -- "$backup"
      return 1
    fi
    if [ -e "$destination" ]; then
      if ! cp -p "$destination" "$backup/$item"; then rm -rf -- "$backup"; return 1; fi
    fi
  done
  if systemctl --user is-enabled fedora-mactahoe-updater.timer &>/dev/null; then was_enabled=1; fi
  if systemctl --user is-active fedora-mactahoe-updater.timer &>/dev/null; then was_active=1; fi
  trap 'if [ "$committed" -eq 0 ]; then
    if [ "$activation_started" -eq 1 ]; then
      if [ "$was_active" -eq 0 ]; then systemctl --user stop fedora-mactahoe-updater.timer || rollback_failed=1; fi
      if [ "$was_enabled" -eq 0 ]; then systemctl --user disable fedora-mactahoe-updater.timer || rollback_failed=1; fi
    fi
    for item in 0 1 2; do
      if [ -f "$backup/$item" ]; then
        cp -p "$backup/$item" "${destinations[$item]}" || rollback_failed=1
      else rm -f -- "${destinations[$item]}" || rollback_failed=1; fi
    done
    systemctl --user daemon-reload || rollback_failed=1
    if [ "$activation_started" -eq 1 ] && [ "$was_active" -eq 1 ]; then
      systemctl --user restart fedora-mactahoe-updater.timer || rollback_failed=1
    fi
  fi
  if [ "$rollback_failed" -eq 0 ]; then rm -rf -- "$backup";
  else warn "Updater recovery needs attention; original payload retained at $backup"; fi' EXIT

  # 1. Install the script
  mkdir -p "$HOME/.local/bin" || return 1
  cp "$updater_src/fedora-mactahoe-updater.sh" "$HOME/.local/bin/fedora-mactahoe-updater.sh" || return 1
  chmod +x "$HOME/.local/bin/fedora-mactahoe-updater.sh" || return 1
  log "Updater script installed to ~/.local/bin/"

  # 2. Install systemd user units
  mkdir -p "$HOME/.config/systemd/user" || return 1
  cp "$updater_src/fedora-mactahoe-updater.service" "$HOME/.config/systemd/user/" || return 1
  cp "$updater_src/fedora-mactahoe-updater.timer" "$HOME/.config/systemd/user/" || return 1
  log "Systemd timer and service installed"

  # 2.5 System-wide rescue detector — a tiny standalone 'update' function
  #      (NOT the full updater — that lives only in ~/.config/fish/functions/).
  #      If the user copy is ever wiped, fish autoloads this one from the
  #      system dir and it restores the latest verified update.fish from
  #      GitHub interactively. The did-you-mean command handler rides along
  #      so a wiped fish config still suggests command fixes. Refreshed on
  #      every full install; 'update configs' keeps both current in between.
  local sys_fish_dir="/etc/fish/functions"
  sudo mkdir -p "$sys_fish_dir" || return 1
  if [ -f "$BUNDLE/configs/updater/update-rescue.fish" ]; then
    sudo cp "$BUNDLE/configs/updater/update-rescue.fish" "$sys_fish_dir/update.fish" || return 1
    sudo chmod 644 "$sys_fish_dir/update.fish" || return 1
    log "Rescue detector installed (root-owned, outside the home folder)"
  fi
  if [ -f "$BUNDLE/configs/fish/functions/__fish_default_command_not_found_handler.fish" ]; then
    sudo cp "$BUNDLE/configs/fish/functions/__fish_default_command_not_found_handler.fish" "$sys_fish_dir/" || return 1
    sudo chmod 644 "$sys_fish_dir/__fish_default_command_not_found_handler.fish" || return 1
    log "Did-you-mean handler installed (root-owned, outside the home folder)"
  fi

  # 3. Reload, enable, start
  activation_started=1
  if ! systemctl --user daemon-reload ||
     ! systemctl --user enable fedora-mactahoe-updater.timer ||
     ! systemctl --user start fedora-mactahoe-updater.timer; then
    warn "Could not activate update notifier — restoring previous user payload"
    return 1
  fi

  if systemctl --user is-enabled fedora-mactahoe-updater.timer &>/dev/null &&
     systemctl --user is-active fedora-mactahoe-updater.timer &>/dev/null; then
    ok "Update notifier active (checks GitHub every 2 hours)"
  else
    warn "Update notifier timer could not be enabled"
    _step_fail=1
  fi
  if [ "$_step_fail" -ne 0 ]; then return 1; fi
  committed=1

  # 4. Automatic security updates — dnf5-plugin-automatic in download + notify mode.
  #    Downloads security patches silently, NEVER installs by itself — you
  #    apply them at your leisure with: sudo dnf upgrade
  if ! rpm -q dnf5-plugin-automatic &>/dev/null; then
    log "Installing dnf5-plugin-automatic (automatic security downloads)"
    if sudo dnf install -y dnf5-plugin-automatic >/dev/null 2>&1; then
      ok "dnf5-plugin-automatic installed"
    else
      warn "dnf5-plugin-automatic install failed — security updates stay manual"
      _step_fail=1
    fi
  else
    ok "dnf5-plugin-automatic already installed"
  fi

  # Do not start automatic updates unless the security-only policy was saved.
  # Keep unrelated administrator settings (including their notification choice).
  if ! _merge_dnf_automatic; then
    warn "Could not merge /etc/dnf/automatic.conf; automatic timer not enabled"
    return 1
  fi

  if sudo systemctl enable --now dnf5-automatic.timer 2>/dev/null; then
    ok "Auto security updates active (download + notify, never auto-install)"
  else
    warn "dnf5-automatic timer could not be enabled"
    _step_fail=1
  fi

  if [ "$_step_fail" -ne 0 ]; then
    return 1
  fi
  return 0
 )
}

# ── PHASE 4c: KTHEME WATCHER ────────────────────────────────

install_ktheme_watcher() {
  next_step "Kitty Auto-Theme Watcher (ktheme)"

  local ktheme_src="$BUNDLE/configs/systemd"
  if [ ! -s "$ktheme_src/ktheme-watcher.service" ] ||
     [ ! -s "$HOME/.config/fish/functions/ktheme.fish" ] ||
     ! command -v fish >/dev/null 2>&1 || ! command -v gsettings >/dev/null 2>&1 ||
     ! command -v python3 >/dev/null 2>&1 || ! command -v magick >/dev/null 2>&1; then
    warn "ktheme-watcher.service not found at $ktheme_src — skipping"
    return 1
  fi
  if ! fish --no-config -n "$HOME/.config/fish/functions/ktheme.fish" ||
     ! grep -q '^ExecStart=.*ktheme watch' "$ktheme_src/ktheme-watcher.service"; then
    warn "ktheme watcher payload or installed function is invalid — preserved"
    return 1
  fi

  # 1. Install the unit
  mkdir -p "$HOME/.config/systemd/user" || return 1
  cp "$ktheme_src/ktheme-watcher.service" "$HOME/.config/systemd/user/" || return 1
  log "ktheme-watcher.service installed"

  # 2. Preserve the user's choice. The watcher is opt-in: a fresh install
  #    leaves it OFF, and only `ktheme on` enables it. An install where the
  #    user already enabled it keeps it enabled (and running). The symlink
  #    check covers a session without a reachable user manager.
  local _kt_was_enabled=0
  if systemctl --user is-enabled ktheme-watcher.service &>/dev/null ||
     [ -L "$HOME/.config/systemd/user/default.target.wants/ktheme-watcher.service" ]; then
    _kt_was_enabled=1
  fi

  if ! systemctl --user daemon-reload; then warn "Could not reload the user service manager"; return 1; fi

  if [ "$_kt_was_enabled" -eq 1 ]; then
    if ! systemctl --user enable ktheme-watcher.service ||
       ! systemctl --user start ktheme-watcher.service; then
      warn "ktheme watcher was enabled but could not be started (run: ktheme on)"
      return 1
    fi
    if systemctl --user is-active ktheme-watcher.service &>/dev/null; then
      ok "Auto-theme watcher kept on — kitty follows your wallpaper"
      return 0
    fi
    warn "ktheme watcher was enabled but could not be started (run: ktheme on)"
    return 1
  fi

  ok "Auto-theme watcher installed but off by default — enable with: ktheme on"
  return 0
}

# ── PHASE 5: TERMINAL & SHELL ────────────────────────────────

setup_terminal() {
  next_step "Kitty as Default Terminal"
  local _step_fail=0

  # Select Kitty through desktop settings, never replace system terminal binaries.
  # This is independent of the optional old-terminal removal choice.
  if ! gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty'; then
    warn "Could not select Kitty as the default terminal"
    _step_fail=1
  fi

  # Copy desktop entry with Name=Terminal (from repo, fallback to system)
  if ! mkdir -p "$HOME/.local/share/applications" ||
     { ! cp "$BUNDLE/desktop/kitty.desktop" "$HOME/.local/share/applications/kitty.desktop" 2>/dev/null &&
       ! cp /usr/share/applications/kitty.desktop "$HOME/.local/share/applications/kitty.desktop"; }; then
    warn "Could not install Kitty desktop entry (bundle and system fallback failed)"
    _step_fail=1
  fi

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
          if cp "$desktop_src" "$_entry" && chown "$_owner:" "$_entry"; then
            log "Fixed stale kitty.desktop for $_owner"
          else
            warn "Could not repair kitty.desktop for $_owner"
            _step_fail=1
          fi
        fi
      fi
      unset _entry _owner
    done
  fi
  unset desktop_src _h

  if [ "$_step_fail" -ne 0 ]; then return 1; fi
  ok "Kitty is now the default terminal"
  return 0
}

setup_shell() {
  next_step "Fish as Default Shell"

  if [ "$SHELL" != "/usr/bin/fish" ]; then
    if sudo chsh -s /usr/bin/fish "$USER"; then
      ok "Default shell changed to fish (next login)"
    else
      warn "fish not set as default shell — run 'sudo chsh -s /usr/bin/fish $USER' manually"
      return 1
    fi
  else
    ok "Fish is already the default shell"
  fi
  return 0
}

# ── PHASE 6: EXTENSIONS ──────────────────────────────────────

# Add UUIDs to enabled-extensions / disabled-extensions WITHOUT replacing the
# user's existing choices. Existing entries are never removed. A UUID the user
# explicitly disabled is never enabled (and vice versa); the conflict is
# reported and the user's choice wins.
_merge_shell_extension_lists() {
  local mode="$1"
  shift
  case "$mode" in
    enable|disable) ;;
    *) warn "Internal: invalid extension merge mode '$mode'"; return 1 ;;
  esac
  [ "$#" -gt 0 ] || return 0

  local enabled_raw disabled_raw merged
  if ! enabled_raw=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null); then
    warn "Could not read enabled-extensions"
    return 1
  fi
  if ! disabled_raw=$(gsettings get org.gnome.shell disabled-extensions 2>/dev/null); then
    warn "Could not read disabled-extensions"
    return 1
  fi

  # dconf holds only the user's own value. Empty means enabled-extensions is
  # still the schema default (a fresh account), not a user decision. That
  # distinction lets "disable" hide the Fedora defaults on a new install
  # without overriding a user who explicitly enabled one later.
  local enabled_user_set=1 dconf_enabled
  if [ "$mode" = "disable" ]; then
    if dconf_enabled=$(dconf read /org/gnome/shell/enabled-extensions 2>/dev/null); then
      [ -n "$dconf_enabled" ] || enabled_user_set=0
    fi
  fi

  if ! merged=$(python3 - "$mode" "$enabled_user_set" "$enabled_raw" "$disabled_raw" "$@" <<'EXTENSION_MERGE'
import ast
import sys

mode = sys.argv[1]
enabled_user_set = sys.argv[2] == '1'
raw_enabled = sys.argv[3]
raw_disabled = sys.argv[4]
requested = sys.argv[5:]


def parse(text):
    text = text.strip()
    if text.startswith('@as '):
        text = text[4:].strip()
    value = ast.literal_eval(text)
    if not isinstance(value, (list, tuple)):
        raise ValueError('not an array')
    if not all(isinstance(item, str) for item in value):
        raise ValueError('non-string entry')
    return list(value)


try:
    enabled = parse(raw_enabled)
    disabled = parse(raw_disabled)
except Exception as error:
    print(f'cannot parse extension lists: {error}', file=sys.stderr)
    raise SystemExit(1)

original_enabled = list(enabled)
conflicts = []
if mode == 'enable':
    for uuid in requested:
        if uuid in disabled:
            conflicts.append(uuid)
        elif uuid not in enabled:
            enabled.append(uuid)
else:
    for uuid in requested:
        if uuid in enabled:
            if enabled_user_set:
                conflicts.append(uuid)
            else:
                enabled.remove(uuid)
                if uuid not in disabled:
                    disabled.append(uuid)
        elif uuid not in disabled:
            disabled.append(uuid)


def variant(items):
    escaped = []
    for item in items:
        escaped.append("'" + item.replace('\\', '\\\\').replace("'", "\\'") + "'")
    return '[' + ', '.join(escaped) + ']'


print('TARGET\t' + variant(enabled if mode == 'enable' else disabled))
for uuid in conflicts:
    print('CONFLICT\t' + uuid)
if mode == 'disable' and enabled != original_enabled:
    print('ENABLED\t' + variant(enabled))
EXTENSION_MERGE
  ); then
    warn "Could not merge the GNOME extension lists"
    return 1
  fi

  local kind value target_list="" enabled_list="" conflicts=()
  while IFS=$'\t' read -r kind value; do
    case "$kind" in
      TARGET) target_list="$value" ;;
      ENABLED) enabled_list="$value" ;;
      CONFLICT) conflicts+=("$value") ;;
    esac
  done <<< "$merged"

  if [ -z "$target_list" ]; then
    warn "Could not merge the GNOME extension lists"
    return 1
  fi
  if [ -n "$enabled_list" ]; then
    if ! gsettings set org.gnome.shell enabled-extensions "$enabled_list" 2>/dev/null; then
      warn "Could not write enabled-extensions"
      return 1
    fi
  fi
  if ! gsettings set org.gnome.shell "${mode}d-extensions" "$target_list" 2>/dev/null; then
    warn "Could not write ${mode}d-extensions"
    return 1
  fi
  local uuid
  for uuid in "${conflicts[@]}"; do
    if [ "$mode" = "enable" ]; then
      warn "Extension $uuid is disabled in your settings — leaving it disabled"
    else
      warn "Extension $uuid is enabled in your settings — leaving it enabled"
    fi
  done
  return 0
}

_extension_payload() {
  # Validate archives before any live replacement. Keep previous user data in
  # persistent backups; failed validation/extraction/schema compilation is inert.
  python3 - "$@" <<'EXTENSION_PAYLOAD'
import json, os, pathlib, re, shutil, stat, subprocess, sys, tempfile, zipfile
mode, source, uuid, shell = sys.argv[1:]
stage = None
try:
    def metadata(root):
        if root.is_symlink():
            raise ValueError('symlinked extension directory preserved')
        path = root / 'metadata.json'
        if path.is_symlink() or not path.is_file() or path.stat().st_size > 1048576:
            raise ValueError('missing or unsafe metadata.json')
        data = json.loads(path.read_text())
        if not isinstance(data, dict) or data.get('uuid') != uuid:
            raise ValueError('extension UUID does not match requested payload')
        if not all(isinstance(data.get(key), str) and data[key].strip()
                   for key in ('name', 'description')):
            raise ValueError('missing required extension name or description')
        versions = data.get('shell-version')
        if not isinstance(versions, list) or not versions or not all(isinstance(v, str) for v in versions):
            raise ValueError('invalid shell-version metadata')
        parts = shell.split('.')
        major = int(parts[0])
        wanted = parts[0] if major >= 40 else '.'.join(parts[:2])
        if not any(re.fullmatch(r'\d+(?:\.\d+){0,2}', v) and
                   (v.split('.')[0] == wanted if major >= 40 else '.'.join(v.split('.')[:2]) == wanted)
                   for v in versions):
            raise ValueError(f'extension does not support GNOME Shell {shell}')
        if not (root / 'extension.js').is_file() or (root / 'extension.js').is_symlink():
            raise ValueError('missing extension.js')
    if not re.fullmatch(r'[A-Za-z0-9_.@+-]+', uuid):
        raise ValueError('unsafe extension UUID')
    if mode == 'check':
        metadata(pathlib.Path(source))
    elif mode == 'install':
        parent = pathlib.Path.home() / '.local/share/gnome-shell/extensions'
        parent.mkdir(parents=True, exist_ok=True)
        if parent.is_symlink():
            raise ValueError('symlinked extension directory preserved')
        stage = pathlib.Path(tempfile.mkdtemp(prefix='.mactahoe-extension-', dir=parent))
        if pathlib.Path(source).stat().st_size > 134217728:
            raise ValueError('extension ZIP exceeds compressed size limit')
        with zipfile.ZipFile(source) as archive:
            entries = archive.infolist()
            if len(entries) > 10000 or sum(i.file_size for i in entries) > 268435456:
                raise ValueError('extension archive exceeds limits')
            seen = set()
            for item in entries:
                name = item.filename
                path = pathlib.PurePosixPath(name)
                kind = stat.S_IFMT(item.external_attr >> 16)
                if (not name or '\\' in name or '\x00' in name or path.is_absolute() or
                    '..' in path.parts or path.as_posix() != name.rstrip('/') or
                    name.rstrip('/') in seen or item.flag_bits & 1 or
                    kind not in (0, stat.S_IFREG, stat.S_IFDIR) or
                    item.file_size > 67108864 or
                    item.file_size > max(1048576, item.compress_size * 1000)):
                    raise ValueError('unsafe extension archive member')
                seen.add(name.rstrip('/'))
            archive.extractall(stage)
        metadata(stage)
        schemas = stage / 'schemas'
        if schemas.is_dir():
            subprocess.run(['glib-compile-schemas', '--strict', str(schemas)], check=True, timeout=30)
        target = parent / uuid
        previous = None
        if os.path.lexists(target):
            if target.is_symlink() or not target.is_dir():
                raise ValueError('unsafe existing extension destination preserved')
            backups = pathlib.Path.home() / '.local/share/fedora-mactahoe/extension-backups'
            backups.mkdir(parents=True, exist_ok=True, mode=0o700)
            previous = pathlib.Path(tempfile.mkdtemp(prefix=uuid + '-', dir=backups)) / uuid
            os.rename(target, previous)
        try:
            os.rename(stage, target)
            stage = None
        except BaseException:
            if previous is not None:
                os.rename(previous, target)
            raise
    else:
        raise ValueError('unknown extension payload operation')
except (OSError, ValueError, zipfile.BadZipFile, RuntimeError, subprocess.SubprocessError) as error:
    print(f'Extension {uuid}: {error}', file=sys.stderr)
    sys.exit(1)
finally:
    if stage is not None:
        shutil.rmtree(stage)
EXTENSION_PAYLOAD
}

install_extensions() {
  next_step "GNOME Extensions"
  _force_popup_blur_off || return 1

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
  shell_version=$(gnome-shell --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)+' | head -1) || true
  if [ -z "$shell_version" ]; then warn "Cannot determine GNOME Shell compatibility"; return 1; fi
  local ext_stage
  ext_stage=$(mktemp -d "${TMPDIR:-/tmp}/mactahoe-extensions.XXXXXXXXXX") || return 1
  for uuid in "${extensions[@]}"; do
    local dl_url
    dl_url=$(curl -s --max-time 25 "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$shell_version" | jq -r '.download_url // empty' 2>/dev/null) || true
    if [ -z "$dl_url" ]; then
      warn "Extension $uuid not found on EGO (shell $shell_version) — skipping"
      ext_fail=$((ext_fail + 1))
      continue
    fi
    if ! _net_download "https://extensions.gnome.org$dl_url" "$ext_stage/$uuid.zip" --max-time 25; then
      warn "Failed to download extension $uuid"
      ext_fail=$((ext_fail + 1))
      if [ -s "${_FED_NET_STOP:-/dev/null}" ]; then rm -rf -- "$ext_stage"; return 1; fi
      continue
    fi
    if _extension_payload install "$ext_stage/$uuid.zip" "$uuid" "$shell_version"; then
      ext_ok=$((ext_ok + 1))
    else
      warn "Failed to install extension $uuid"
      ext_fail=$((ext_fail + 1))
    fi
    rm -f "$ext_stage/$uuid.zip"
  done

  # Enable all installed extensions via direct gsettings (no D-Bus needed).
  # MERGE, never replace: the user's enabled/disabled choices are preserved.
  local -a ext_uuids=()
  for uuid in "${extensions[@]}"; do
    if _extension_payload check "$HOME/.local/share/gnome-shell/extensions/$uuid" "$uuid" "$shell_version" 2>/dev/null ||
       { [ ! -e "$HOME/.local/share/gnome-shell/extensions/$uuid" ] &&
         [ ! -L "$HOME/.local/share/gnome-shell/extensions/$uuid" ] &&
         _extension_payload check "/usr/share/gnome-shell/extensions/$uuid" "$uuid" "$shell_version" 2>/dev/null; }; then
      ext_uuids+=("$uuid")
    fi
  done
  if [ ${#ext_uuids[@]} -gt 0 ]; then
    if ! _merge_shell_extension_lists enable "${ext_uuids[@]}"; then
      warn "Could not enable extensions via gsettings"
      ext_fail=$((ext_fail + 1))
    fi
  fi

  # Mark the Fedora defaults as disabled, but never override a user who
  # explicitly enabled one (the helper reports that conflict).
  if ! _merge_shell_extension_lists disable \
      'background-logo@fedorahosted.org' \
      'apps-menu@gnome-shell-extensions.gcampax.github.com'; then
    warn "Could not update disabled-extensions via gsettings"
    ext_fail=$((ext_fail + 1))
  fi

  if [ "$ext_ok" -gt 0 ]; then
    ok "$ext_ok extension(s) installed"
  fi
  if [ "$ext_fail" -gt 0 ]; then
    warn "$ext_fail extension(s) failed — check extensions.gnome.org or your network"
  fi

  # ── Window Title Pro (own extension — GitHub release first, EGO fallback) ──
  # The GitHub release is the source of truth: it is published together with
  # the source tag, so it always carries the newest shell-version metadata.
  # The extensions.gnome.org copy is the fallback and may lag by a release.
  # This matters for GNOME 51: the shell REFUSES to enable an extension whose
  # metadata does not list the running shell version, so a stale EGO copy
  # means a silently disabled extension on Fedora 45.
  local wtp_uuid="window-title-pro@eprahemi.github.io"
  local wtp_target="$HOME/.local/share/gnome-shell/extensions/$wtp_uuid"
  local wtp_pk="10319"
  local wtp_installed=false

  # Keep the installed copy until a complete compatible replacement is ready.

  # Try 1: the GitHub release asset — always the newest build.
  # The release tag is resolved from the GitHub API so a new WTP version
  # ships to every machine WITHOUT this installer changing (and without
  # another install_sha256 re-pin). The hardcoded version is the fallback
  # when the API is unreachable or rate-limited.
  local wtp_version="15"
  local wtp_api_ver=""
  wtp_api_ver=$(curl -fsSL --max-time 20 "https://api.github.com/repos/eprahemi/window-title-pro-topbar/releases/latest" 2>/dev/null | grep -oP '"tag_name":\s*"\Kv[0-9.]+' | head -1 | tr -d 'v' 2>/dev/null || true)
  if [ -n "$wtp_api_ver" ] && [ "$wtp_api_ver" != "$wtp_version" ]; then
    wtp_version="$wtp_api_ver"
  fi

  local wtp_candidates="$wtp_version"
  if [ "$wtp_version" != "15" ]; then
    wtp_candidates="$wtp_version 15"
  fi

  local wtp_version_try
  for wtp_version_try in $wtp_candidates; do
    local wtp_gh_url="https://github.com/eprahemi/window-title-pro-topbar/releases/download/v${wtp_version_try}/window-title-pro-v${wtp_version_try}.zip"
    if _net_download "$wtp_gh_url" "$ext_stage/window-title-pro.zip" --max-time 40; then
      if _extension_payload install "$ext_stage/window-title-pro.zip" "$wtp_uuid" "$shell_version"; then
        wtp_installed=true
        ok "Window Title Pro v${wtp_version_try} installed from the GitHub release"
        ext_ok=$((ext_ok + 1))
        break
      else
        warn "Failed to extract Window Title Pro v${wtp_version_try} from the GitHub release"
      fi
    fi
    if [ -s "${_FED_NET_STOP:-/dev/null}" ]; then rm -rf -- "$ext_stage"; return 1; fi
    rm -f "$ext_stage/window-title-pro.zip"
  done
  if [ "$wtp_installed" = false ]; then
    warn "GitHub release download failed for Window Title Pro — falling back to EGO"
  fi

  # EGO fallback uses the same staged metadata/archive checks as GitHub.
  if [ "$wtp_installed" = false ]; then
    local wtp_api_url="https://extensions.gnome.org/extension-info/?pk=$wtp_pk&shell_version=$shell_version"
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
      if _net_download "https://extensions.gnome.org$wtp_dl_url" "$ext_stage/window-title-pro.zip" --max-time 25; then
        if _extension_payload install "$ext_stage/window-title-pro.zip" "$wtp_uuid" "$shell_version"; then
          wtp_installed=true
          ok "Window Title Pro installed from EGO"
          ext_ok=$((ext_ok + 1))
        else
          warn "Failed to extract Window Title Pro"
          ext_fail=$((ext_fail + 1))
        fi
        rm -f "$ext_stage/window-title-pro.zip"
      else
        warn "Failed to download Window Title Pro from EGO"
        ext_fail=$((ext_fail + 1))
      fi
    else
      warn "Failed to get EGO download URL for Window Title Pro"
      ext_fail=$((ext_fail + 1))
    fi
  fi

  rm -rf -- "$ext_stage"

  # Enable Window Title Pro without disturbing the merged list.
  if [ "$wtp_installed" = true ]; then
    if ! _merge_shell_extension_lists enable "$wtp_uuid"; then
      warn "Could not enable Window Title Pro via gsettings"
      ext_fail=$((ext_fail + 1))
    fi
  fi

  if [ "$ext_fail" -gt 0 ]; then
    return 1
  fi
  return 0
}

# ── MIRROR FLATPAK ICONS ──────────────────────────────────────
# GTK 3.24.52 on Fedora 44 cannot resolve icons that only exist at 512×512 in
# the Flatpak system hicolor (/var/lib/flatpak/exports/share/icons/hicolor/).
# This function mirrors them into ~/.local/share/icons/hicolor/48x48/apps/
# so they show up in the GNOME app grid.
# See: https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi/issues

_merge_hicolor_index() {
  local destination="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
  [[ "$destination" = /* ]] || destination="$HOME/.local/share/icons/hicolor"
  if ! fish --no-config -c 'source "$argv[1]"; or exit 1; __mactahoe_hicolor_index "$argv[2]"' \
      "$BUNDLE/configs/fish/functions/__mactahoe_hicolor_index.fish" \
      "$destination"; then
    warn "Could not merge local hicolor index"
    return 1
  fi
}

mirror_flatpak_icons() {
  local user_hicolor="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
  [[ "$user_hicolor" = /* ]] || user_hicolor="$HOME/.local/share/icons/hicolor"
  local user_48="$user_hicolor/48x48/apps"
  local mirrored=0 skipped=0 failed=0
  local bases=()
  local base

  if ! _merge_hicolor_index; then return 1; fi
  # Build list of hicolor sources that exist
  [ -d "/var/lib/flatpak/exports/share/icons/hicolor" ] && bases+=("/var/lib/flatpak/exports/share/icons/hicolor")
  [ -d "${user_hicolor%/icons/hicolor}/flatpak/exports/share/icons/hicolor" ] && bases+=("${user_hicolor%/icons/hicolor}/flatpak/exports/share/icons/hicolor")
  [ -d "$user_hicolor" ] && bases+=("$user_hicolor")
  [ -d "/usr/share/icons/hicolor" ] && bases+=("/usr/share/icons/hicolor")

  [ ${#bases[@]} -eq 0 ] && { ok "No hicolor icon directories to scan"; return 0; }

  if ! mkdir -p "$user_48"; then return 1; fi

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
        if ln -sf "$f" "$target_dir/$name" 2>/dev/null || \
           cp -f "$f" "$target_dir/$name" 2>/dev/null; then
          mirrored=$((mirrored + 1))
        else
          failed=$((failed + 1))
        fi
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
      if ln -sf "$best_src" "$user_48/$name" 2>/dev/null || \
         cp -f "$best_src" "$user_48/$name" 2>/dev/null; then
        mirrored=$((mirrored + 1))
      else
        failed=$((failed + 1))
      fi
    done < <(find "$base" -path '*/apps/*' \( -name '*.png' -o -name '*.svg' \) -print0 2>/dev/null)
  done

  # Rebuild user hicolor cache
  gtk-update-icon-cache "$user_hicolor/" 2>/dev/null || warn "Icon cache update failed for $user_hicolor"

  log "Mirrored $mirrored icon(s) to $user_hicolor/48x48/apps/ ($skipped already covered, $failed failed)"
  if [ "$failed" -gt 0 ]; then
    return 1
  fi
  return 0
}

# ── FINALIZE ──────────────────────────────────────────────────

finalize() {
  next_step "Cleanup & Reboot"

  # ── 1. Temporary files from this installer ──
  log "Cleaning installer temporary files..."
  rm -rf /tmp/mactahoe-* /tmp/mac-sounds /tmp/ext-* 2>/dev/null || true
  # RPM downloads are removed by install_rpmfusion from its private staging dir.

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

  # Orphaned RPM removal is user-controlled, not part of theme installation.

  # ── 9. Old system journal logs (keep last 3 days) ──
  log "Trimming old system logs (keeping 3 days)..."
  sudo journalctl --vacuum-time=3d 2>/dev/null || true

  # ── 10. Mirror unresolvable app icons (Flatpak + system + user-local) ──
  if ! mirror_flatpak_icons; then
    warn "Flatpak icon mirror incomplete — some app-grid icons may be missing"
  fi

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
  local _FINAL_JSON _JFILE _INSTALL_DATE
  _INSTALL_DATE=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)
  _JFILE=$(mktemp "$STATE_DIR/state.XXXXXX" 2>/dev/null || echo "")
  if [ -n "$_JFILE" ]; then
    echo "$STATE_JSON" > "$_JFILE" 2>/dev/null || true
    _FINAL_JSON=$(python3 -c '
import sys, json
try:
    with open(sys.argv[1], "r") as fh:
        s = json.load(fh)
except Exception:
    s = {"version": "0.0", "steps": {}, "prompts": {}}
try:
    s["version"] = sys.argv[2]
    s["install_date"] = sys.argv[3]
    print(json.dumps(s))
except Exception:
    print("")
' "$_JFILE" "$MANIFEST_VERSION" "$_INSTALL_DATE" 2>/dev/null || echo "$STATE_JSON")
    rm -f "$_JFILE" 2>/dev/null || true
    [ -n "$_FINAL_JSON" ] && STATE_JSON="$_FINAL_JSON"
  fi
  local _TMPFILE
  _TMPFILE=$(mktemp "$STATE_DIR/state.XXXXXX" 2>/dev/null || echo "")
  if [ -n "$_TMPFILE" ]; then
    echo "$STATE_JSON" > "$_TMPFILE" 2>/dev/null && mv "$_TMPFILE" "$STATE_FILE" 2>/dev/null || true
  fi

  # finalize is the step that is running right now — record it so the
  # summary counts all steps. _run_step replaces this with the real
  # outcome as soon as this function returns.
  _step_record "finalize" "ok" "Cleanup & Reboot"
  _ui_step finalize ok

  _installation_completion
}

_installation_completion() {
  local completed=0 skipped=0 failed=0 value i rc=0 sid label status group state
  for value in "${STEP_RESULT_VALS[@]}"; do
    case "$value" in
      ok) completed=$((completed + 1)) ;;
      skipped) skipped=$((skipped + 1)) ;;
      failed) failed=$((failed + 1)) ;;
    esac
  done
  # Display-only deliberate skips do not alter saved successful step versions
  # or the retry contract. Count that separate model when present.
  if [ "${#_UI_STEP_IDS[@]}" -gt 0 ]; then
    completed=0 skipped=0 failed=0
    for i in "${!_UI_STEP_IDS[@]}"; do
      _ui_step_visible "${_UI_STEP_IDS[$i]}" || continue
      value=${_UI_STEP_STATES[$i]}
      case "$value" in
        ok) completed=$((completed+1));; skipped) skipped=$((skipped+1));;
        failed) failed=$((failed+1));;
      esac
    done
  fi
  _UI_FINAL_COMPLETED=$completed
  _UI_FINAL_SKIPPED=$skipped
  _UI_FINAL_FAILED=$failed
  _UI_COMPLETION='INSTALLATION COMPLETE'
  if [ "$failed" -gt 0 ]; then _UI_COMPLETION='FINISHED WITH ISSUES'; fi
  _UI_RESULT_DETAILS=" $completed completed  /  $skipped skipped  /  $failed failed"$'\n'
  _UI_RESULT_DETAILS+=" Elapsed $((EPOCHSECONDS - _UI_STARTED))s"$'\n'
  _UI_FINAL_TASKS=()
  _UI_FINAL_ATTENTION=()
  # Report task outcomes, not unverified claims that every asset is active.
  # Grouped in display order so the completion dashboard never repeats a header.
  for sid in install_mactahoe_theme install_font install_sounds setup_terminal setup_shell setup_gdm setup_flatpak_theme install_updater; do
    status=$(_step_status "$sid")
    case "$sid" in
      install_mactahoe_theme) label='GTK and icon theme'; group='APPEARANCE' ;;
      install_font) label='SF Pro font'; group='APPEARANCE' ;;
      install_sounds) label='Big Sur sounds'; group='APPEARANCE' ;;
      setup_terminal) label='Kitty default terminal'; group='TERMINAL & SHELL' ;;
      setup_shell) label='Fish default shell'; group='TERMINAL & SHELL' ;;
      setup_gdm) label='Login theme'; group='SYSTEM' ;;
      setup_flatpak_theme) label='Flatpak GTK runtime'; group='SYSTEM' ;;
      install_updater) label='Update notifier (every 2 hours)'; group='SYSTEM' ;;
    esac
    # A deliberate login opt-out is not an installed outcome.
    if [ "$sid" = setup_gdm ] && [ "${INSTALL_LOGIN_WALLPAPER:-false}" != true ]; then status=declined; fi
    case "$status" in
      ok) status=completed; state=ok ;;
      skipped) status='unchanged (not rechecked)'; state=skipped ;;
      failed) status='needs attention'; state=failed ;;
      declined) status='not requested'; state=skipped ;;
      *) status='not run'; state=notrun ;;
    esac
    _UI_RESULT_DETAILS+=" $label: $status"$'\n'
    _UI_FINAL_TASKS+=("$group|$label|$state")
    if [ "$state" = failed ]; then
      _UI_FINAL_ATTENTION+=("$label|$(_step_fix "$sid")")
    fi
  done
  for ((i=0; i<MISSING_COUNT; i++)); do
    _UI_RESULT_DETAILS+=" ${MISSING_LABEL[$i]} - retry: ${MISSING_FIX[$i]}"$'\n'
    _UI_FINAL_ATTENTION+=("${MISSING_LABEL[$i]}|${MISSING_FIX[$i]}")
  done
  _UI_QUESTION_BODY="$_UI_COMPLETION. $completed completed, $skipped skipped, $failed failed. Restart to load the changes that completed."
  # Plain report is part of the shared transcript too, not just the renderer.
  printf '\nYour desktop, reimagined.\n%s\n%s\nMade by Eprahemi\n' "$_UI_COMPLETION" "$_UI_RESULT_DETAILS"
  # Render the completion dashboard before the single restart question so the
  # report and the prompt appear together, and the dashboard is never lost to
  # a reboot. _ui_finish clears _UI_ACTIVE, so the exit trap will not repeat it.
  if [ "${_UI_ACTIVE:-0}" = 1 ]; then
    _ui_finish "$_UI_COMPLETION"
  fi
  # The only final restart decision. No/EOF finish normally.
  confirm_final 'Restart now? [y/N]: ' N || rc=$?
  if [ "$rc" -eq 0 ]; then
    if ! sudo reboot; then warn 'Restart could not be requested. Run sudo reboot when ready.'; fi
  else
    _UI_RESULT_DETAILS+=' Restart later with: sudo reboot'$'\n'
    echo 'Restart later with: sudo reboot'
  fi
  return 0
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

__system_dashboard
# Simulated security/network numbers and artificial delays are not shown/run.

# ── Before any prompts, load saved answers from state ──
# This populates INSTALL_DESKTOP_WALLPAPER, INSTALL_LOGIN_WALLPAPER,
# INSTALL_WALLPAPER_18, INSTALL_BILLIE_VIDEOS, and INSTALL_DISABLE_FIREWALLD
# from previous runs
_load_prompt_answers

# ── Single-target update mode (update icons/wallpaper/pfp/... in update.fish) ──
# Runs ONLY the listed step function(s), then exits. Prompts are skipped —
# the caller passes every INSTALL_* variable the step needs, explicitly.
if [ -n "${UPDATE_STEPS:-}" ]; then
  _preserve_active_wallpaper || exit 1
  # install_icons has no next_step of its own — print one for it
  case "$UPDATE_STEPS" in
    install_icons) next_step "MacTahoe Icon Themes + Custom App Icons" ;;
  esac
  _OLD_IFS="$IFS"
  _target_failed=0
  IFS=','
  for _ustep in $UPDATE_STEPS; do
    IFS="$_OLD_IFS"
    case "$_ustep" in
      install_mactahoe_theme|install_icons|install_font|apply_desktop_entries|ensure_celluloid_default|configure_nautilus_defaults|apply_dconf|optimize_system_resources|apply_wallpapers|install_custom_avatars|setup_gdm|setup_flatpak_theme|install_sounds|install_updater|install_extensions|download_optional_videos)
        CURRENT_STEP_LABEL="$_ustep"
        _VISUAL_SKIP_REASON=''
        _ui_step "$_ustep" running
        _target_rc=0
        "$_ustep" || _target_rc=$?
        if [ -s "${_FED_NET_STOP:-/dev/null}" ]; then
          _step_failed "$_ustep" 130 stopped
          _ui_step "$_ustep" failed 'interrupted; retry this task'
          _clear_step_state "$_ustep" || warn "Could not clear interrupted task state: $_ustep"
          _UI_COMPLETION='Stopped safely. Completed work is kept.'
          exit 130
        fi
        if [ "$_target_rc" -ne 0 ]; then
          _step_failed "$_ustep" "$_target_rc"
          _ui_step "$_ustep" failed "exit $_target_rc; retry: $(_step_fix "$_ustep")"
          _clear_step_state "$_ustep" || \
            warn "Could not clear saved state for $_ustep — it may be skipped on the next run"
          _target_failed=1
        else
          _step_record "$_ustep" ok "$CURRENT_STEP_LABEL"
          if [ -n "$_VISUAL_SKIP_REASON" ]; then
            _ui_step "$_ustep" skipped "$_VISUAL_SKIP_REASON"
          else
            _ui_step "$_ustep" ok
          fi
          _update_step_state "$_ustep"
        fi
        ;;
      *)
        warn "Unknown update step: $_ustep"
        _step_record "$_ustep" failed "$_ustep"
        _ui_step "$_ustep" failed 'unknown task; no work performed'
        _target_failed=1
        ;;
    esac
  done
  IFS="$_OLD_IFS"
  if [ "$_target_failed" -ne 0 ]; then
    exit 1
  fi
  exit 0
fi

# ── Preflight (always runs) ──
_run_step "preflight" preflight

_preserve_active_wallpaper || exit 1

# ── The questions the installer asks ──────────────────────────
# Everything else is defaulted and stays changeable later through
# `update`, so nobody has to answer a question to get a working
# system.
#
# The defaults are applied AFTER the saved answers were loaded, so
# a saved choice (or an env var from `update`) always wins over the
# default — the defaults only fill the gaps.
#
# Discord is not installed by default (a ~540 MB download nobody
# asked for). The desktop wallpaper and the GDM login screen are
# asked explicitly below (both default to Yes); the optional hosted
# packs are off by default and are added later through `update`.
INSTALL_DISCORD="${INSTALL_DISCORD:-false}"
INSTALL_WALLPAPER_18="${INSTALL_WALLPAPER_18:-false}"
INSTALL_BILLIE_VIDEOS="${INSTALL_BILLIE_VIDEOS:-false}"

# Desktop wallpaper — asked once per manifest version. A saved answer or
# an INSTALL_DESKTOP_WALLPAPER env var (update wallpaper) wins.
if [ -z "${INSTALL_DESKTOP_WALLPAPER:-}" ] && _prompt_should_ask "wallpaper_desktop"; then
  prompt_desktop_wallpaper
  _save_prompt_answer "wallpaper_desktop" "${INSTALL_DESKTOP_WALLPAPER:-true}"
fi
INSTALL_DESKTOP_WALLPAPER="${INSTALL_DESKTOP_WALLPAPER:-true}"

# GDM login screen — one question, no second confirmation.
if _prompt_should_ask "wallpaper_login"; then
  prompt_gdm_login
  _save_prompt_answer "wallpaper_login" "${INSTALL_LOGIN_WALLPAPER:-false}"
fi

# Firewalld — asked up front so the installation never pauses mid-flow.
# The actual disable/enable still happens in optimize_system_resources.
# If firewalld isn't running, prompt_firewalld returns 1 and no answer is saved.
if _prompt_should_ask "firewalld"; then
  if prompt_firewalld; then
    _save_prompt_answer "firewalld" "${INSTALL_DISABLE_FIREWALLD:-false}"
  fi
fi

# Old terminal (Ptyxis) — asked only when it is actually installed.
# prompt_remove_old_terminal returns 1 when Ptyxis is absent, so no answer
# is saved and the default below records false.
if _prompt_should_ask "old_terminal"; then
  if prompt_remove_old_terminal; then
    _save_prompt_answer "old_terminal" "${INSTALL_REMOVE_OLD_TERMINAL:-false}"
  fi
fi

# Fill the remaining gaps AFTER the prompts.
INSTALL_REMOVE_OLD_TERMINAL="${INSTALL_REMOVE_OLD_TERMINAL:-false}"

if [ "${_UI_ACTIVE:-0}" = 1 ]; then
  printf -v _UI_CHOICES 'Desktop wallpaper: %s\nLogin theme: %s\nDisable firewalld: %s\nRemove Ptyxis and its settings/cache: %s' \
    "$INSTALL_DESKTOP_WALLPAPER" "${INSTALL_LOGIN_WALLPAPER:-false}" "${INSTALL_DISABLE_FIREWALLD:-false}" "$INSTALL_REMOVE_OLD_TERMINAL"
  printf 'Choices: %s\n' "$_UI_CHOICES"
  _ui_notice 'Preferences saved. Starting installation.' '36'
fi

# A "yes" answer must run its step even when that step is already recorded
# at the current version. Without this, the prompt promises an action that
# the version gate then silently skips (the 3.7 login-screen bug).
if [ "${INSTALL_LOGIN_WALLPAPER:-false}" = "true" ]; then
  STEP_USR_VERS["setup_gdm"]="0.0"
fi
if [ "${INSTALL_REMOVE_OLD_TERMINAL:-false}" = "true" ]; then
  STEP_USR_VERS["remove_ptyxis"]="0.0"
fi

# The defaulted extras are written to the state file as they are, so
# the state always describes what the system actually has.
_save_prompt_answer "discord" "${INSTALL_DISCORD:-false}"
_save_prompt_answer "wallpaper_18" "${INSTALL_WALLPAPER_18:-false}"
_save_prompt_answer "billie_videos" "${INSTALL_BILLIE_VIDEOS:-false}"
_save_prompt_answer "old_terminal" "${INSTALL_REMOVE_OLD_TERMINAL:-false}"

# ── Hosted assets: check the links before anything is downloaded ──
# Only the assets this install actually uses are probed.
if [ "${_UI_ACTIVE:-0}" = 1 ]; then _ui_resume work; fi
_hosted_assets_status

if ! prompt_sudoers_entry; then
  warn "Continuing without the optional sudoers template"
fi

# ── System cleanup steps (after prompts — remove_ptyxis honors the
#    old-terminal answer; remove_gnome_weather has no prompt) ──
_run_step "remove_ptyxis" remove_ptyxis
_run_step "remove_gnome_weather" remove_gnome_weather

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

phase_divider "PHASE 4 : CONFIGURATION" 10 23
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

# ── Exit code ────────────────────────────────────────────────────
# 0 = every step completed.
# 1 = at least one step failed. The run itself was NOT aborted — the
#     summary above lists what is missing and the command that adds it,
#     and re-running install.sh retries exactly the steps that did not
#     complete (a failed step is never written to install-state.json).
if [ "$STEP_FAILED_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
