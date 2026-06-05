#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git"
TMP="/tmp/fedora-mactahoe"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
BOLD='\033[1m'; WHITE='\033[1;37m'; DIM='\033[2m'

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
    echo -e "  ╔══════════════════════════════════════════════════════════════╗"
    echo -e "  ║            ⛔  WOAH — PTYXIS DETECTED                        ║"
    echo -e "  ╠══════════════════════════════════════════════════════════════╣"
    echo -e "  ║                                                              ║"
    echo -e "  ║  You're in ${BOLD}Ptyxis${NC} right now. Bad news — this installer         ║"
    echo -e "  ║  ${BOLD}${RED}yeets Ptyxis into the void${NC} during setup.                     ║"
    echo -e "  ║                                                              ║"
    echo -e "  ║  Running from inside it would be like trying to renovate     ║"
    echo -e "  ║  your kitchen while you're standing in the middle of it.     ║"
    echo -e "  ║                                                              ║"
    echo -e "  ║  ${YELLOW}╳${NC}  The installer would:                                         ║"
    echo -e "  ║     • Delete the terminal you're currently typing in         ║"
    echo -e "  ║     • Crash halfway through (bye-bye progress)               ║"
    echo -e "  ║     • Potentially mess up your whole session                 ║"
    echo -e "  ║                                                              ║"
    echo -e "  ║  ${GREEN}✓${NC}  Here's the right way to do it:                              ║"
    echo -e "  ║                                                              ║"
    echo -e "  ║  ${BOLD}1${NC}  Install Kitty:  sudo dnf install kitty                        ║"
    echo -e "  ║                                                              ║"
    echo -e "  ║  ${BOLD}2${NC}  Launch Kitty and re-run:                                      ║"
    echo -e "  ║       kitty -e bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh)\" ║"
    echo -e "  ║                                                              ║"
    echo -e "  ║  You can keep Ptyxis as a backup if you want, but            ║"
    echo -e "  ║  Kitty needs to be the main ride for this to work.           ║"
    echo -e "  ║                                                              ║"
    echo -e "  ╚══════════════════════════════════════════════════════════════╝"
    echo ""
    exit 1
  fi

  # ── Kitty recommendation for non-Kitty terminals ──
  if [ "$detected_term" != "kitty" ]; then
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
    echo "  │  Press any key to continue                                 │"
    echo "  │  or Ctrl+C to grab Kitty first (recommended)                │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
    # First press: acknowledge
    while true; do
      read -r -n 1 key </dev/tty || true
      if [ -n "$key" ]; then
        echo -e "  ${DIM}ok, one more thing...${NC}"
        break
      fi
    done
    # Second space: confirm
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
      read -r -n 1 key </dev/tty || true
      if [ -n "$key" ]; then
        echo -e "${GREEN}let's roll${NC}"
        break
      fi
    done
  fi
fi

# ── NVIDIA warning (before download) ──
nvidia_found=false
lspci 2>/dev/null | grep -qi nvidia && nvidia_found=true
lsmod 2>/dev/null | grep -qi nouveau && nvidia_found=true
if [ "$nvidia_found" = true ]; then
  echo ""
  echo -e "  ${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "  ${YELLOW}║${NC}  ${BOLD}HEADS UP — NVIDIA DETECTED${NC}                                    ${YELLOW}║${NC}"
  echo -e "  ${YELLOW}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}  You've got NVIDIA gear. On a ${BOLD}fresh install${NC}, running this           ${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}  before a full system update can mess up your display.       ${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}  Think 800×600 resolution and laggy refresh. Not fun.         ${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}  ${BOLD}Save yourself the headache — do this first:${NC}                  ${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}    1. Get online (ethernet > WiFi if you can)                   ${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}    2. ${BOLD}sudo dnf upgrade${NC}                                        ${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}    3. Reboot                                                    ${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}    4. Run this thing again                                       ${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}  ${GREEN}✓${NC}  Already updated? Press any key to roll.                      ${YELLOW}║${NC}"
  echo -e "  ${YELLOW}║${NC}  ${YELLOW}Ctrl+C${NC} to go update first.                                   ${YELLOW}║${NC}"
  echo -e "  ${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -en "  ${DIM}Press any key to continue...${NC} "
  while true; do
    read -r -n 1 key </dev/tty || true
    if [ -n "$key" ]; then
      echo -e "${GREEN}let's go${NC}"
      break
    fi
  done
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
echo -e "  ${CYAN}║${NC}"'       /_/                                                     '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'  '"${BOLD}${WHITE}"'◆  Fedora MacTahoe  —  Eprahemi Edition'"${NC}"'                      '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'  '"${BOLD}"'◆  Make your Fedora look like a Mac — the fun way'"${NC}"'           '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
gnome_text="  GNOME ${GNOME_VER}  ◆  Kitty Terminal  ◆  Fish Shell"
echo -e "  ${CYAN}║${NC}  ${DIM}GNOME${NC} ${GNOME_VER}  ${DIM}◆  Kitty Terminal  ◆  Fish Shell${NC}$(printf '%*s' $((62 - ${#gnome_text})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}  ${YELLOW}◆  Press any key to begin${NC}                                    ${CYAN}║${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -en "  ${DIM}Waiting on you...${NC} "
while true; do
  read -r -n 1 key </dev/tty || true
  if [ -n "$key" ]; then
    echo -e "${GREEN}here we go${NC}"
    break
  fi
done

# ── Discord optional prompt ──
echo ""
echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "  ${CYAN}║${NC}            ${BOLD}${WHITE}◆  INSTALL DISCORD?${NC}  ${DIM}◆${NC}                             ${CYAN}║${NC}"
echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}  Discord chat client — about 100 MB.                          ${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}  Skip it if you don't need it.                                ${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}    ${BOLD}${GREEN}Y${NC}${BOLD}es${NC}  — Install Discord                                       ${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}    ${BOLD}${YELLOW}n${NC}${BOLD}o${NC}   — Skip it                                               ${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}  ${DIM}Tip: set INSTALL_DISCORD=false to skip silently${NC}               ${CYAN}║${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -en "  ${DIM}Discord? (Y/n):${NC} "
read -r -n 1 key </dev/tty || true
echo ""
if [ "$key" = "n" ] || [ "$key" = "N" ]; then
  export INSTALL_DISCORD="false"
  echo -e "  ${DIM}→ Skipping Discord${NC}"
else
  export INSTALL_DISCORD="true"
  echo -e "  ${GREEN}→ Discord will be installed${NC}"
fi

# ── Ensure git is available ──
if ! command -v git &>/dev/null; then
  echo -e "  ${CYAN}◆${NC}  Git's not here — grabbing it real quick..."
  sudo dnf install -y git
fi

# ── Download bundle ──
echo ""
echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "  ${CYAN}║${NC}             ${BOLD}${WHITE}📦  Grabbing the Goods${NC}                            ${CYAN}║${NC}"
echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "  ${CYAN}║${NC}  ${DIM}◆${NC}  Repository:  ${BOLD}Fedora-MacTahoe-Eprahemi${NC}                    ${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}  ${DIM}◆${NC}  Destination: ${BOLD}$TMP${NC}                    ${CYAN}║${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
rm -rf "$TMP"
if git clone --depth 1 "$REPO" "$TMP" 2>&1; then
  echo ""
  echo -e "  ${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "  ${GREEN}║${NC}              ${BOLD}✅  Got Everything${NC}                                ${GREEN}║${NC}"
  echo -e "  ${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"

  # Hide Fedora logo on GDM login screen
  sudo mkdir -p /etc/dconf/db/gdm.d 2>/dev/null || true
  echo -e "[org/gnome/login-screen]\nlogo=''" | sudo tee /etc/dconf/db/gdm.d/01-logo > /dev/null 2>&1 || true
  sudo dconf update 2>/dev/null || true
else
  echo ""
  echo -e "  ${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "  ${RED}║${NC}           ${BOLD}⛔  Download Failed — Check Connection${NC}              ${RED}║${NC}"
  echo -e "  ${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
  exit 1
fi
echo ""

cd "$TMP"
bash install.sh
