#!/usr/bin/env bash

# Shared terminal presentation library. install.sh sources this file with
# --ui-library; the online bash -c entry needs no extra download/dependency.
# Installation functions always execute in the foreground shell. Only painting
# runs in a child; it never reads input, executes work, or writes the transcript.
_UI_ACTIVE=0 _UI_PID='' _UI_TASK='Preparing your Fedora desktop'
_UI_PHASE='Preparation' _UI_DONE=0 _UI_TOTAL=0 _UI_STARTED=${_FED_UI_STARTED:-$EPOCHSECONDS}
export _FED_UI_STARTED="$_UI_STARTED"
_UI_OWNER=$BASHPID
_UI_NOTICE='' _UI_NOTICE_COLOR='1;33' _UI_CHOICES='' _UI_FINISHED=0 _UI_RESULT_DETAILS=''
_UI_NOTICES=()
_UI_NOTICE_COLORS=()
_UI_WARNINGS=()
_UI_TRANSFER_DONE=0 _UI_TRANSFER_TOTAL=0
_ui_stop() {
  if [ -n "${_UI_PID:-}" ]; then
    kill -CONT "$_UI_PID" 2>/dev/null || true
    kill "$_UI_PID" 2>/dev/null || true
    wait "$_UI_PID" 2>/dev/null || true
    _UI_PID=''
  fi
}
_ui_line() {
  # All dynamic text is clipped to terminal columns by using ASCII UI copy.
  local text="$1" width="$2" ansi=$'\033''\[[[:digit:];?]*[[:alpha:]]'
  while [[ "$text" =~ $ansi ]]; do text=${text//"${BASH_REMATCH[0]}"/}; done
  text=${text//$'\033'/}
  text=${text//$'\n'/ }
  text=${text//$'\r'/ }
  printf '\033[0m\033[%sm\033[2K %.*s\033[0m\r\n' "${3:-0}" "$((width - 2))" "$text" >&7
}
_ui_brand() {
  local cols="$1"
  if [ "$cols" -ge 36 ] && [ "${3:-24}" -ge 18 ]; then
    _ui_line '   ____' "$cols" "1;38;5;${2:-44}"
    _ui_line '  / __/   Fedora MacTahoe' "$cols" "1;38;5;${2:-44}"
    _ui_line ' / /_     Eprahemi Edition' "$cols" "1;38;5;${2:-44}"
    _ui_line '/ __/' "$cols" "1;38;5;${2:-44}"
    _ui_line '/_/       Made by Eprahemi' "$cols" '90'
  else
    _ui_wrap 'Fedora MacTahoe' "$cols" '1;36'
    _ui_wrap 'Eprahemi Edition' "$cols" '36'
    _ui_wrap 'Made by Eprahemi' "$cols" '90'
  fi
  printf '\033[0m' >&7
}
_ui_wrap() {
  local text="$1" cols="$2" line
  while IFS= read -r line; do
    _ui_line "  $line" "$cols" "${3:-0}"
  done < <(printf '%s\n' "$text" | fold -sw "$((cols > 4 ? cols - 4 : 1))")
}
_ui_bar() {
  local cols="$1" done="$2" total="$3" pct cells filled bar empty
  [ "$total" -gt 0 ] || return 0
  pct=$((done * 100 / total))
  [ "$pct" -le 100 ] || pct=100
  cells=$((cols - 12))
  [ "$cells" -le 48 ] || cells=48
  if [ "$cells" -lt 4 ]; then
    if [ "$cols" -lt 6 ]; then
      printf '\033[0m\033[1;36m\033[2K%s%%\033[0m\r\n' "$pct" >&7
    else
      _ui_line "${pct}%" "$cols" '1;36'
    fi
    return 0
  fi
  filled=$((cells * pct / 100))
  printf -v bar '%*s' "$filled" ''; bar=${bar// /#}
  printf -v empty '%*s' "$((cells - filled))" ''; empty=${empty// /-}
  _ui_line "[$bar$empty] ${pct}%" "$cols" '1;36'
}
_ui_paint() {
  local frame="${1:-0}" rows cols elapsed pct trail name short idx=0
  read -r rows cols < <(stty size < /dev/tty 2>/dev/null) || { rows=24; cols=80; }
  case "$rows:$cols" in *[!0-9:]*|:*) rows=24; cols=80 ;; esac
  [ "$cols" -ge 4 ] || cols=4
  elapsed=$((EPOCHSECONDS - _UI_STARTED))
  printf '\033[H' >&7
   if [ "$rows" -lt 20 ] || [ "$cols" -lt 52 ]; then
    _ui_line 'Fedora MacTahoe - Eprahemi Edition' "$cols" '1;36'
    _ui_wrap "$_UI_TASK" "$cols" '1;36'
    if [ "$_UI_TOTAL" -gt 0 ]; then
      _ui_bar "$cols" "$_UI_DONE" "$_UI_TOTAL"
      _ui_line "Tasks $_UI_DONE/$_UI_TOTAL" "$cols" '1'
    fi
    if [ "$_UI_TRANSFER_TOTAL" -gt 0 ]; then _ui_bar "$cols" "$_UI_TRANSFER_DONE" "$_UI_TRANSFER_TOTAL"; fi
    _ui_line "Elapsed ${elapsed}s" "$cols" '90'
    _ui_wrap "$_UI_NOTICE" "$cols" "$_UI_NOTICE_COLOR"
    _ui_line 'Made by Eprahemi' "$cols" '90'
    printf '\033[J' >&7
    return 0
  fi
  local colors=(38 44 51 44) spin=('|' '/' '-' '\\')
  _ui_brand "$cols" "${colors[$((frame % 4))]}"
  _ui_line '' "$cols"
  _ui_line "${spin[$((frame % 4))]} $_UI_TASK" "$cols" '1;36'
  _ui_line "Elapsed ${elapsed}s - keep this window open" "$cols" '90'
  if [ "$_UI_TOTAL" -gt 0 ]; then
    pct=$((_UI_DONE * 100 / _UI_TOTAL))
    _ui_line "Step $_UI_DONE of $_UI_TOTAL · ${pct}%" "$cols" '1'
    _ui_bar "$cols" "$_UI_DONE" "$_UI_TOTAL"
  else
    _ui_line 'Preparing installation' "$cols" '90'
  fi
  if [ "$_UI_TRANSFER_TOTAL" -gt 0 ]; then _ui_bar "$cols" "$_UI_TRANSFER_DONE" "$_UI_TRANSFER_TOTAL"; fi
  _ui_line '' "$cols"
  # The current phase is highlighted; all prior/next phases remain visible.
  trail=''
  printf '\033[0m\033[2K ' >&7
  for name in Preparation Foundations Packages Themes Configuration Shell Finalize; do
    case "$name" in
      Preparation) short=Prep ;; Foundations) short=Base ;; Packages) short=Apps ;;
      Themes) short=Theme ;; Configuration) short=Config ;; Shell) short=Shell ;; Finalize) short=Finish ;;
    esac
    if [ "$name" = "$_UI_PHASE" ]; then
      printf '\033[1;36m[%s]\033[0m ' "$short" >&7
    else
      printf '\033[90m%s\033[0m ' "$short" >&7
    fi
  done
  printf '\r\n' >&7
  _ui_line '' "$cols"
  _ui_wrap "$_UI_NOTICE" "$cols" "$_UI_NOTICE_COLOR"
  if [ -n "$_UI_CHOICES" ] && [ "$rows" -ge 24 ]; then
    while IFS= read -r name; do _ui_line "$name" "$cols" '90'; done <<<"$_UI_CHOICES"
  fi
  _ui_line '' "$cols"
  _ui_line 'Made by Eprahemi' "$cols" '90'
  printf '\033[J' >&7
}
_ui_resume() {
  if [ "${_UI_ACTIVE:-0}" = 1 ] && [ "$BASHPID" = "$_UI_OWNER" ]; then
    _ui_stop
    printf '\033[?25l' >&7
    _ui_paint 0
    (
      _tick_pid=''
      trap 'if [ -n "$_tick_pid" ]; then kill "$_tick_pid" 2>/dev/null || true; fi; exit 0' TERM INT
      _frame=0
      while :; do
        # Waiting for a background tick lets TERM interrupt the wait promptly;
        # replacing a task never adds the animation interval to install time.
        sleep 0.4 & _tick_pid=$!
        wait "$_tick_pid" || true
        _tick_pid=''
        _frame=$((_frame + 1))
        _ui_paint "$_frame"
      done
    ) &
    _UI_PID=$!
  fi
}
_ui_init() {
  # Test ORIGINAL stdout, not tee's pipe. Never infer TTY from /dev/tty alone.
  if [ -t 5 ] && [ -t 6 ] && [ "${TERM:-dumb}" != dumb ] &&
     { exec 7>/dev/tty; } 2>/dev/null; then
    _UI_ACTIVE=1
    exec >>"$_FED_LOG" 2>&1
    printf '\033[?1049h\033[?25l' >&7
    _ui_resume
  fi
}
_ui_task() { _UI_TASK="$1"; _UI_TRANSFER_DONE=0; _UI_TRANSFER_TOTAL=0; _ui_resume; }
_ui_download_progress() {
  _UI_TASK="$1" _UI_TRANSFER_DONE="$2" _UI_TRANSFER_TOTAL="$3"
  _ui_resume
}
_ui_phase() { _UI_PHASE="$1"; _ui_resume; }
_ui_progress() { _UI_DONE="$1"; _UI_TOTAL="$2"; _ui_resume; }
_ui_notice() {
  if [ "${_UI_ACTIVE:-0}" = 1 ] && [ "$BASHPID" = "$_UI_OWNER" ]; then
    _UI_NOTICE="$1"
    _UI_NOTICE_COLOR="${2:-1;33}"
    _UI_NOTICES+=("$1")
    _UI_NOTICE_COLORS+=("$_UI_NOTICE_COLOR")
    _ui_resume
  fi
}
_ui_question() {
  if [ "${_UI_ACTIVE:-0}" = 1 ]; then
    _ui_stop
    # Alternate screen belongs entirely to us, never erase normal scrollback.
    printf '\033[H\033[J\033[?25h\033[0m' >&7
    local rows cols line
    read -r rows cols < <(stty size < /dev/tty 2>/dev/null) || cols=80
    [ "${cols:-0}" -ge 4 ] || cols=4
    _ui_brand "$cols" 44 "${rows:-24}"
    _ui_line '' "$cols"
    _ui_wrap "$1" "$cols" '1;36'
    _ui_line '' "$cols"
    _ui_wrap "${2:-}" "$cols"
    _ui_line '' "$cols"
    if [ -n "${3:-}" ]; then
      _ui_wrap "$3" "$cols" '90'
      printf '\033[1;36m   > \033[0m' >&7
    fi
  fi
}
_ui_cleanup() {
  if [ "${_UI_ACTIVE:-0}" = 1 ]; then
    _ui_stop
    printf '\033[0m\033[?25h\033[?1049l' >&7
    _UI_ACTIVE=0
  fi
}
_ui_finish() {
  if [ "${_UI_ACTIVE:-0}" = 1 ]; then
    _ui_cleanup
    local result_color='1;32'
    case "$1" in *ISSUES*|*issues*|*stopped*|*Stopped*|*failed*) result_color='1;33' ;; esac
    printf '\n\033[1;36m Fedora MacTahoe - Eprahemi Edition\033[0m\n Your desktop, reimagined.\n\033[%sm %s\033[0m\n' "$result_color" "$1" >&5
    # Routine activity belongs in the transcript, not a second completion dump.
    # Failed tasks and their recovery commands are retained separately below.
    if [ -n "${_UI_RESULT_DETAILS:-}" ]; then printf '%s\n' "$_UI_RESULT_DETAILS" >&5; fi
    local warning
    for warning in "${_UI_WARNINGS[@]}"; do printf '\033[1;33m Warning: %s\033[0m\n' "$warning" >&5; done
    printf '\033[90m Made by Eprahemi\033[0m\n' >&5
    _UI_FINISHED=1
  fi
}
_ui_auth() {
  # sudo owns authentication and hidden input. Never read passwords ourselves,
  # never enable pwfeedback, never log authentication output or keystrokes.
  local rc=0
  # Pipeline/command-substitution children must never spawn replacement
  # painters or pretend to own their parent's foreground UI/state.
  if [ "${_UI_ACTIVE:-0}" = 1 ] && [ "$BASHPID" != "$_UI_OWNER" ]; then
    if [ -n "${_UI_PID:-}" ]; then kill -STOP "$_UI_PID" 2>/dev/null || true; fi
    printf '\033[?25h\n Administrator permission: your password stays hidden while you type.\n' >/dev/tty
    command sudo -v >/dev/tty 2>/dev/tty || rc=$?
    if [ -n "${_UI_PID:-}" ]; then kill -CONT "$_UI_PID" 2>/dev/null || true; fi
    return "$rc"
  fi
  if [ "${_UI_ACTIVE:-0}" = 1 ]; then
    _ui_question 'Administrator permission' 'Your password stays hidden while you type.' ''
    command sudo -v >/dev/tty 2>/dev/tty || rc=$?
    _ui_resume
  else
    command sudo -v || rc=$?
  fi
  return "$rc"
}

# Retry only transport failures at an individual, repeatable download boundary.
# Phase replay is intentionally not attempted: configuration phases include asset
# deletion, config backup and browser consent and are not safely replayable.
_net_reachable() {
  command curl -q --silent --show-error --head --location --output /dev/null \
    --connect-timeout 3 --max-time 8 "$1" 2>/dev/null
}
_net_recover() {
  local endpoint="$1" answer rc
  while :; do
    printf 'Download endpoint unavailable: %s\n' "$endpoint"
    _ui_question 'CONNECTION PAUSED' "Cannot reach $endpoint. Completed work and your log are kept. Retry this download only; earlier phases are not replayed." 'Enter/y = retry; n = stop safely.'
    if [ "${_UI_ACTIVE:-0}" != 1 ]; then printf 'Enter/y = retry; n = stop safely: '; fi
    answer='' rc=0
    read -r answer </dev/tty || rc=$?
    if [ "$rc" -ne 0 ]; then answer=n; fi
    case "${answer,,}" in
      n|no)
        if [ -n "${_FED_NET_STOP:-}" ]; then printf stopped >"$_FED_NET_STOP"; fi
        _ui_resume
        return 130 ;;
      ''|y|yes)
        _ui_task 'Checking the download endpoint'
        if _net_reachable "$endpoint"; then _ui_resume; return 0; fi
        printf 'Endpoint is still unreachable; no work was marked complete.\n' ;;
      *) printf 'Type y/yes or n/no.\n' ;;
    esac
  done
}
_net_download() {
  local url="$1" dest="$2"; shift 2
  if [ -s "${_FED_NET_STOP:-/dev/null}" ]; then return 130; fi
  local headers pid rc bytes previous=0 started=$EPOCHREALTIME now speed total last=''
  headers=$(mktemp "${TMPDIR:-/tmp}/mactahoe-transfer.XXXXXXXX") || return 1
  while :; do
    previous=0 started=$EPOCHREALTIME
    : >"$dest" || { rm -f "$headers"; return 1; }
    : >"$headers"
    command curl -q --fail --location --silent --show-error --dump-header "$headers" \
      "$@" --output "$dest" "$url" &
    pid=$! rc=0
    _FED_TRANSFER_PID=$pid
    while kill -0 "$pid" 2>/dev/null; do
      bytes=$(stat -c %s "$dest" 2>/dev/null || echo 0)
      now=$EPOCHREALTIME
      total=$(awk '/^HTTP\// {n=0} tolower($1)=="content-length:" {gsub("\r", "", $2); n=$2} END {print n+0}' "$headers")
      speed=$(awk -v b="$bytes" -v p="$previous" -v t="$now" -v s="$started" 'BEGIN {if(t>s && b>=p) printf "%.2f",(b-p)/(t-s)/1048576; else print "0.00"}')
      if [ "$total" -gt 0 ] && [ "$bytes" -le "$total" ]; then
        last="Download $bytes / $total bytes ($((bytes * 100 / total))%) - $speed MiB/s"
      else
        last="Download $bytes bytes - $speed MiB/s"
      fi
      _ui_download_progress "$last" "$bytes" "$total"
      previous=$bytes started=$now
      sleep 0.25
    done
    wait "$pid" || rc=$?
    _FED_TRANSFER_PID=''
    if [ "$rc" -eq 0 ]; then
      bytes=$(stat -c %s "$dest" 2>/dev/null || echo 0)
      _ui_download_progress "Download complete: $bytes bytes" "$bytes" "$bytes"
      rm -f "$headers"
      return 0
    fi
    case "$rc" in
      5|6|7|18|28|52|55|56)
        if ! _net_recover "$url"; then rm -f "$headers"; return 130; fi ;;
      *) rm -f "$headers"; return "$rc" ;;
    esac
  done
}
_net_package_run() {
  # The manager is foreground and owns its transaction/locks. Inspect transport
  # diagnostics ONLY after it exits. Never kill it on a connectivity change.
  local capture rc endpoint diagnostic
  if [ -s "${_FED_NET_STOP:-/dev/null}" ]; then return 130; fi
  capture=$(mktemp "${TMPDIR:-/tmp}/mactahoe-package.XXXXXXXX") || return 1
  while :; do
    rc=0
    if "$@" 2>&1 | tee "$capture"; then rc=${PIPESTATUS[0]}; else rc=${PIPESTATUS[0]}; fi
    if [ "$rc" -eq 0 ]; then rm -f "$capture"; return 0; fi
    diagnostic=$(grep -Ei 'Curl error \((5|6|7|28|52|55|56)\)|Could not resolve host|Could not connect to' "$capture" || true)
    endpoint=$(printf '%s\n' "$diagnostic" | grep -Eo 'https?://[^[:space:]<>]+' | head -1 | sed 's/[]),;"]*$//' || true)
    if [ -z "$endpoint" ]; then
      endpoint=$(printf '%s\n' "$diagnostic" | sed -nE 's/.*[Cc]ould not resolve host: ([A-Za-z0-9.-]+).*/https:\/\/\1\//p' | head -1)
    fi
    # Without the actual failed endpoint and an explicit transport diagnostic,
    # this could be a missing package, bad repository, GPG or configuration error.
    if [ -z "$endpoint" ]; then rm -f "$capture"; return "$rc"; fi
    if ! _net_recover "$endpoint"; then rm -f "$capture"; return 130; fi
  done
}
flatpak() {
  if [ "${1:-}" = install ]; then _net_package_run command flatpak "$@"; else command flatpak "$@"; fi
}
sudo() {
  # Preserve noninteractive credential checks. For work, warm authentication
  # before invoking the original argv; do not wrap the work in a subshell.
  if [ "${_UI_ACTIVE:-0}" = 1 ] && [ "${1:-}" != -n ]; then
    if ! command sudo -n -v 2>/dev/null; then _ui_auth || return $?; fi
  fi
  case "${1:-}:${2:-}:${3:-}" in
    dnf:install:*|dnf:swap:*|dnf:group:install)
      _net_package_run command sudo "$@" ;;
    *) command sudo "$@" ;;
  esac
}

if [ "${1:-}" = --ui-library ]; then return 0; fi

# ─────────────────────────────────────────────────────────────
#  Fedora MacTahoe — Eprahemi Edition
#  Bootstrap: fetches install.sh from GitHub and runs it
# ─────────────────────────────────────────────────────────────

# ── Bootstrap log ──
# Generates a unique 8-char session ID and logs ALL output to
# ~/FedoraTahoe_log.<date>.<time>.<ID> ( TAG ).txt  (sorts chronologically)
#
# The tag stamps WHO ran this — ( BASH ) for the curl|bash one-liner,
# ( UPDATE-FULL ) / ( UPDATE-QUICK ) when the updater drives it. update.fish
# already exports INSTALL_SOURCE; anything else reaching bootstrap is the
# copy-paste route → ( BASH ). Same logic and names as install.sh so the
# bootstrap-made log and the installer header stay consistent.
export INSTALL_SOURCE="${INSTALL_SOURCE:-bash}"
_FED_TAG=""
case "$INSTALL_SOURCE" in
  bash)     _FED_TAG="BASH" ;;
  manual)   _FED_TAG="MANUAL" ;;
  update-*) _FED_TAG=$(printf '%s' "$INSTALL_SOURCE" | tr '[:lower:]' '[:upper:]') ;;
esac
_FED_TAG_EXT=""
[ -n "$_FED_TAG" ] && _FED_TAG_EXT=" ( $_FED_TAG )"
_FED_ID=$(tr -dc 'a-zA-Z0-9' < /dev/urandom 2>/dev/null | head -c 8)
[ -z "$_FED_ID" ] && _FED_ID="X$(date +%s 2>/dev/null | sha256sum 2>/dev/null | head -c7 || echo "00000001")"
_FED_DATE_STAMP=$(date '+%Y-%m-%d.%H-%M-%S' 2>/dev/null || echo "unknown")
_FED_LOG="$HOME/FedoraTahoe_log.${_FED_DATE_STAMP}.${_FED_ID}${_FED_TAG_EXT}.txt"
export _FED_ID _FED_DATE_STAMP _FED_LOG
touch "$_FED_LOG" 2>/dev/null || true
# Preserve original stdout/stderr, then redirect all output to both terminal and log
exec 5>&1 6>&2
exec > >(tee -a "$_FED_LOG") 2>&1
_FED_TEE_PID=$!

set -euo pipefail

REPO="https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git"
TMP="/tmp/fedora-mactahoe"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
BOLD='\033[1m'; WHITE='\033[1;37m'; DIM='\033[2m'
if [ ! -t 5 ]; then
  RED='' GREEN='' YELLOW='' CYAN='' NC='' BOLD='' WHITE='' DIM=''
fi
_ui_init

# ── Log finalization (runs on normal exit, crash, or Ctrl+C) ──
_fed_log_finalize() {
  local _exit_rc=$?
  if [ -n "${_clone_pid:-}" ]; then
    kill "$_clone_pid" 2>/dev/null || true
    wait "$_clone_pid" 2>/dev/null || true
  fi
  if [ "${_UI_ACTIVE:-0}" = 1 ]; then
    _ui_finish 'Preparation stopped. Review the session log and try again when ready.'
  fi
  exec 1>&5 2>&6 2>/dev/null || true
  trap - EXIT
  # User closed the script (Ctrl+C forced exit) or it closed itself
  # (60s no-key timeout) — nothing ran, so the log is not worth keeping.
  # Retain partial transcripts on interruption as well.
  if [ -n "${_FED_TEE_PID:-}" ]; then wait "$_FED_TEE_PID" 2>/dev/null || true; fi
  # Strip ANSI escape sequences from log file (post-process, no pipe race)
  if [ -n "${_FED_LOG:-}" ] && [ -f "$_FED_LOG" ]; then
    LC_ALL=C sed -i 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$_FED_LOG" 2>/dev/null || true
    LC_ALL=C sed -i 's/\x1b\][0-9;]*[^\x07\x1b]*[\x07\x1b]//g' "$_FED_LOG" 2>/dev/null || true
    # Set custom icon for this log file (icon may not exist yet on first bootstrap run — silently ignored)
    command -v gio &>/dev/null && [ -f "${HOME}/.local/share/icons/fedora-mactahoe/mactahoe_log_icon.png" ] && \
      gio set "$_FED_LOG" metadata::custom-icon "file://${HOME}/.local/share/icons/fedora-mactahoe/mactahoe_log_icon.png" 2>/dev/null || true
    if [ "${_FED_LOG_HANDED_OFF:-0}" != 1 ]; then
      echo -e "  ${CYAN}Log saved: ${_FED_LOG}${NC}"
    fi
  fi
}
trap _fed_log_finalize EXIT

# ── Error logging ──
_fed_log_error() {
  local _line=$1 _code=$2
  _ui_notice 'Preparation could not complete. The session log has details.'
  echo -e "\n  ${RED}${BOLD}✗  ERROR at line ${_line} (exit code: ${_code})${NC}"
  echo -e "  ${YELLOW}${BOLD}   Full log: ${_FED_LOG}${NC}"
}
trap '_fed_log_error $LINENO $?' ERR

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

# ── Terminal check: block Ptyxis immediately ──
if [ -z "${KITTY_PID:-}" ]; then
  detected_term=""
  walk_pid=$PPID
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

  if [ "$detected_term" = "ptyxis" ] || [ "$detected_term" = "gnome-ptyxis" ]; then
    _ui_notice 'Ptyxis cannot run this installer. Install Kitty with sudo dnf install kitty, then run it there.'
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

  # ── Kitty recommendation for non-Kitty terminals ──
  if [ "$detected_term" != "kitty" ]; then
    _ui_question 'Kitty is recommended' 'Install Kitty with sudo dnf install kitty and run this installer there.' 'Press any key to continue here, or Ctrl+C to stop.'
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
    # First press: acknowledge
    while true; do
      read -r -s -n 1 key < /dev/tty || true
      echo -e "  ${DIM}ok, one more thing...${NC}"
      break
    done
    # Second space: confirm
    _ui_question 'Continue without Kitty?' 'The intended desktop terminal experience uses Kitty.' 'Press any key to proceed, or Ctrl+C to stop.'
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
    while true; do
      read -r -s -n 1 key < /dev/tty || true
      echo -e "${GREEN}let's roll${NC}"
      break
    done
  fi
fi

# Preparation checks are visible before any package download or privilege use.
_ui_task 'Checking Fedora, GNOME and installer prerequisites'
if [ "$EUID" -eq 0 ]; then
  _ui_notice 'Run as your normal desktop user, not root.'
  echo 'Run as your normal desktop user, not root.'
  exit 1
fi
if [ ! -f /etc/fedora-release ] || ! command -v gnome-shell >/dev/null 2>&1; then
  _ui_notice 'Fedora Workstation with GNOME is required.'
  echo 'Fedora Workstation with GNOME is required.'
  exit 1
fi
if ! command -v sudo >/dev/null 2>&1; then
  _ui_notice 'sudo is required. Ask your administrator to install/configure it first.'
  echo 'sudo is required. Ask your administrator to install/configure it first.'
  exit 1
fi

# ── Capture GNOME version ──
GNOME_VER=$(gnome-shell --version 2>/dev/null | grep -oP '\d+\.\d+' || echo "?")

# ── ASCII Banner ──
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
b1="  ◆  Fedora MacTahoe  —  Eprahemi Edition"
echo -e "  ${CYAN}║${NC}${BOLD}${WHITE}${b1}${NC}$(printf '%*s' $((62 - ${#b1})) '')${CYAN}║${NC}"
b2="  ◆  Make your Fedora look like a Mac — the fun way"
echo -e "  ${CYAN}║${NC}${BOLD}${b2}${NC}$(printf '%*s' $((62 - ${#b2})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
gnome_text="  GNOME ${GNOME_VER}  ◆  Kitty Terminal  ◆  Fish Shell"
echo -e "  ${CYAN}║${NC}  ${DIM}GNOME${NC} ${GNOME_VER}  ${DIM}◆  Kitty Terminal  ◆  Fish Shell${NC}$(printf '%*s' $((62 - ${#gnome_text})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
b3="  ◆  Press any key to begin"
echo -e "  ${CYAN}║${NC}${YELLOW}${b3}${NC}$(printf '%*s' $((62 - ${#b3})) '')${CYAN}║${NC}"
wp_line="  ⚠  Read yes/no prompts carefully — some are permanent!"
echo -e "  ${CYAN}║${NC}  ${BOLD}${RED}${wp_line}${NC}$(printf '%*s' $((60 - ${#wp_line})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -en "  ${DIM}Waiting on you...${NC} "
_ui_question 'Welcome to Fedora MacTahoe' 'Choose your preferences, then we will prepare your desktop.' 'Press any key to begin.'
_read_rc=0
read -t 60 -r -s -n 1 key < /dev/tty || _read_rc=$?
# 142 = read's timeout (SIGALRM). Other codes (Ctrl+C = 130, EOF = 1) are NOT the timeout.
if [ "$_read_rc" -eq 142 ]; then
  _FED_ABORT=1
  echo ""
  echo -e "  ${YELLOW}◆${NC}  No key pressed in 60 seconds — closing. Run it again when you're ready!"
  exit 42
fi
echo -e "${GREEN}here we go${NC}"
_ui_resume

# ── Ensure git is available ──
if ! command -v git &>/dev/null; then
  _ui_task 'Installing the Git download prerequisite'
  echo -e "  ${CYAN}◆${NC}  Git's not here — grabbing it real quick..."
  sudo dnf install -y git
fi

# ── Download bundle (silent clone + live progress bar) ──
echo ""
rm -rf "$TMP"
_clone_log=$(mktemp 2>/dev/null || echo /tmp/mct-clone.$$)
while :; do
timeout 180 git clone --depth 1 --progress "$REPO" "$TMP" >"$_clone_log" 2>&1 &
_clone_pid=$!
_clone_rc=0
_ui_task 'Downloading installation files…'
echo 'Downloading the installer bundle (preparation)...'
_transfer_last=''
while kill -0 "$_clone_pid" 2>/dev/null; do
  # Git's transfer record is measured data: object percentage, received bytes
  # and transfer rate when Git reports them. Never synthesize missing values,
  # combine resolving-delta percentages with transfer, or advance by elapsed time.
  _transfer=$(tr '\r' '\n' < "$_clone_log" | grep 'Receiving objects:' | tail -1 | sed -E 's/^.*Receiving objects: */Download objects: /; s/, done\.$//' || true)
  if [ -n "$_transfer" ] && [ "$_transfer" != "$_transfer_last" ]; then
    _transfer_pct=$(printf '%s\n' "$_transfer" | sed -nE 's/^Download objects: *([0-9]+)%.*/\1/p')
    if [ -n "$_transfer_pct" ]; then
      _ui_download_progress "$_transfer" "$_transfer_pct" 100
    else
      _ui_task "$_transfer"
    fi
    _transfer_last="$_transfer"
  fi
  sleep 0.2
done
wait "$_clone_pid" 2>/dev/null || _clone_rc=$?
_clone_pid=''
# Original Git output belongs in the transcript, not the clean dashboard.
cat "$_clone_log" >>"$_FED_LOG"
if [ "$_clone_rc" -eq 0 ]; then break; fi
# Classify Git transport diagnostics, not arbitrary clone/configuration failures.
# A timeout has already ended the clone; package transactions are never involved.
if [ "$_clone_rc" -eq 124 ] || grep -Eqi 'could not resolve|failed to connect|connection timed out|connection reset|network is unreachable|early EOF' "$_clone_log"; then
  _net_recover "${REPO}/info/refs?service=git-upload-pack" || exit 130
  rm -rf "$TMP"
else
  break
fi
done

if [ "$_clone_rc" -eq 0 ]; then
  printf "  ${GREEN}◆${NC}  Cloning installer  ✓  \n"
  rm -f "$_clone_log"

  # Hide Fedora logo on GDM login screen
  sudo mkdir -p /etc/dconf/db/gdm.d 2>/dev/null || true
  echo -e "[org/gnome/login-screen]\nlogo=''" | sudo tee /etc/dconf/db/gdm.d/01-logo > /dev/null 2>&1 || true
  sudo dconf update 2>/dev/null || true

  # Eprahemi Public License — silent copy to Documents (always overwrites)
  mkdir -p "$HOME/Documents" 2>/dev/null || true
  cp -f "$TMP/EPRAHEMI — PUBLIC LICENSE & REUSE TERMS.md" "$HOME/Documents/" 2>/dev/null || true

else
  _ui_notice 'The installer bundle could not be downloaded. Check your connection and retry.'
  printf "  ${RED}◆${NC}  Cloning installer  ✗  \n"
  echo ""
  echo -e "  ${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "  ${RED}║${NC}           ${BOLD}⛔  Download Failed — Check Connection${NC}              ${RED}║${NC}"
  echo -e "  ${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo -e "  ${DIM}  $(tail -n 2 "$_clone_log" 2>/dev/null)${NC}"
  rm -f "$_clone_log"
  exit 1
fi
echo ""

# Full re-install for direct bootstrap.sh; incremental for update / notification
if [ "${UPDATE_MODE:-}" != "incremental" ]; then
    rm -f "$HOME/.cache/fedora-mactahoe/install-state.json"
fi

# ── Verify install.sh against the pin in the same clone before running ──
# updates.json and install.sh come from the same commit, so the pinned hash
# is always the expected hash for the file about to run. This catches a
# truncated or tampered installer between clone and execution.
cd "$TMP"
_inst_pin=""
if command -v python3 &>/dev/null && [ -f "updates.json" ]; then
  _inst_pin=$(python3 -c 'import json,sys
try:
    print(json.load(open("updates.json", encoding="utf-8")).get("install_sha256", ""))
except Exception:
    pass' 2>/dev/null || true)
fi
if [ -n "$_inst_pin" ]; then
  _inst_got=$(sha256sum install.sh 2>/dev/null | awk '{print $1}' || true)
  if [ "$_inst_got" != "$_inst_pin" ]; then
    _ui_notice 'Installer verification failed. Nothing was run. Fetch a fresh copy and try again.'
    echo -e "  ${RED}◆${NC}  ${BOLD}Installer verification failed${NC} — the downloaded install.sh"
    echo -e "  ${RED}◆${NC}  does not match the fingerprint pinned in updates.json."
    echo -e "  ${RED}◆${NC}  This usually means a corrupted download or a tampered file."
    echo -e "  ${RED}◆${NC}  Nothing was run. Re-run the bootstrap to fetch it fresh."
    echo -e "  ${RED}◆${NC}  got:  ${_inst_got:-<unreadable>}"
    echo -e "  ${RED}◆${NC}  want: ${_inst_pin}"
    exit 1
  fi
fi

# Stop the preparation painter before the foreground installer takes over the
# same original terminal and log. Do not export UI process/animation state.
_ui_cleanup
_FED_LOG_HANDED_OFF=1
export _FED_LOG_PARENT=1
bash install.sh && _inst_rc=0 || _inst_rc=$?
# 42 = the installer closed itself (60s no-key/no-answer auto-close) —
# passed through as-is, it is NOT a failure. Everything else propagates.
exit "$_inst_rc"
