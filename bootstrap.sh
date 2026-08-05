#!/usr/bin/env bash

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

set -euo pipefail

REPO="https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git"
TMP="/tmp/fedora-mactahoe"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
BOLD='\033[1m'; WHITE='\033[1;37m'; DIM='\033[2m'

# ── Log finalization (runs on normal exit, crash, or Ctrl+C) ──
_fed_log_finalize() {
  exec 1>&5 2>&6 2>/dev/null || true
  trap - EXIT
  # User closed the script (Ctrl+C forced exit) or it closed itself
  # (60s no-key timeout) — nothing ran, so the log is not worth keeping.
  if [ "${_FED_ABORT:-0}" = "1" ]; then
    rm -f "${_FED_LOG:-}" 2>/dev/null || true
    return 0
  fi
  sleep 0.5 2>/dev/null || true
  # Strip ANSI escape sequences from log file (post-process, no pipe race)
  if [ -n "${_FED_LOG:-}" ] && [ -f "$_FED_LOG" ]; then
    LC_ALL=C sed -i 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$_FED_LOG" 2>/dev/null || true
    LC_ALL=C sed -i 's/\x1b\][0-9;]*[^\x07\x1b]*[\x07\x1b]//g' "$_FED_LOG" 2>/dev/null || true
    # Set custom icon for this log file (icon may not exist yet on first bootstrap run — silently ignored)
    command -v gio &>/dev/null && [ -f "${HOME}/.local/share/icons/fedora-mactahoe/mactahoe_log_icon.png" ] && \
      gio set "$_FED_LOG" metadata::custom-icon "file://${HOME}/.local/share/icons/fedora-mactahoe/mactahoe_log_icon.png" 2>/dev/null || true
    echo -e "  ${GREEN}Log saved: ${_FED_LOG}${NC}"
  fi
}
trap _fed_log_finalize EXIT

# ── Error logging ──
_fed_log_error() {
  local _line=$1 _code=$2
  echo -e "\n  ${RED}${BOLD}✗  ERROR at line ${_line} (exit code: ${_code})${NC}"
  echo -e "  ${YELLOW}${BOLD}   Full log: ${_FED_LOG}${NC}"
}
trap '_fed_log_error $LINENO $?' ERR

# ── Ctrl+C / Interrupt handling ──
# First press warns, second press force-exits immediately (no log saved).
_INT_PRESS=0
_FED_ABORT=0
_handle_sigint() {
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
    walk_pid=$(cat /proc/"$walk_pid"/status 2>/dev/null | awk '/^PPid:/{print $2}')
  done

  if [ "$detected_term" = "ptyxis" ] || [ "$detected_term" = "gnome-ptyxis" ]; then
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

# ── Ensure git is available ──
if ! command -v git &>/dev/null; then
  echo -e "  ${CYAN}◆${NC}  Git's not here — grabbing it real quick..."
  sudo dnf install -y git
fi

# ── Download bundle (silent clone + live progress bar) ──
echo ""
rm -rf "$TMP"
_clone_log=$(mktemp 2>/dev/null || echo /tmp/mct-clone.$$)
timeout 180 git clone --depth 1 --progress "$REPO" "$TMP" >"$_clone_log" 2>&1 &
_clone_pid=$!
_clone_rc=0
_spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
_msgs=("Contacting GitHub..." "Fetching the installer..." "Cloning the repository..." "Almost there...")
_i=0
_pct=0
printf '\e[?25l'
while kill -0 "$_clone_pid" 2>/dev/null; do
  _i=$((_i + 1))
  _frame=${_spin[$((_i % 10))]}
  _real=$(tr '\r' '\n' < "$_clone_log" 2>/dev/null | grep -Eo '(Receiving objects|Resolving deltas): *[0-9]+%' | tail -1 | grep -Eo '[0-9]+' || true)
  if [ -n "$_real" ] && [ "$_real" -gt "$_pct" ]; then
    _pct=$_real
  elif [ -z "$_real" ]; then
    _pct=$((_i * 100 / 900))
  fi
  [ "$_pct" -gt 99 ] && _pct=99
  _filled=$((_pct * 20 / 100))
  _empty=$((20 - _filled))
  _bar=""
  _pad=""
  for ((_k = 0; _k < _filled; _k++)); do _bar+="█"; done
  for ((_k = 0; _k < _empty; _k++)); do _pad+="░"; done
  _midx=$((_i / 25))
  [ "$_midx" -gt 3 ] && _midx=3
  _msg=${_msgs[$_midx]}
  printf '\r  \e[1;36m%s\e[0m  \e[1;37m%s\e[0m  \e[2;37m[\e[0m\e[1;36m%s\e[0m\e[2;37m%s\e[0m\e[2;37m]\e[0m \e[1;33m%3d%%\e[0m' "$_frame" "$_msg" "$_bar" "$_pad" "$_pct"
  sleep 0.2
done
wait "$_clone_pid" 2>/dev/null || _clone_rc=$?
printf '\e[?25h\r  %*s\r' 80 ''

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

cd "$TMP"
bash install.sh && _inst_rc=0 || _inst_rc=$?
# 42 = the installer closed itself (60s no-key/no-answer auto-close) —
# passed through as-is, it is NOT a failure. Everything else propagates.
exit "$_inst_rc"
