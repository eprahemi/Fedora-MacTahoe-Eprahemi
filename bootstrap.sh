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
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -en "  ${DIM}Waiting on you...${NC} "
read -r -s -n 1 key < /dev/tty || true
echo -e "${GREEN}here we go${NC}"

# ── Discord optional prompt ──
echo ""
echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
d1="            ◆  INSTALL DISCORD?  ◆              "
echo -e "  ${CYAN}║${NC}${d1}$(printf '%*s' $((62 - ${#d1})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
d2="  Discord via Flatpak — ~214 MB download, ~540 MB installed."
echo -e "  ${CYAN}║${NC}${d2}$(printf '%*s' $((62 - ${#d2})) '')${CYAN}║${NC}"
d3="  Skip it if you don't need it."
echo -e "  ${CYAN}║${NC}${d3}$(printf '%*s' $((62 - ${#d3})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
d4="    Y  — Install Discord"
echo -e "  ${CYAN}║${NC}${d4}$(printf '%*s' $((62 - ${#d4})) '')${CYAN}║${NC}"
d5="    n   — Skip it"
echo -e "  ${CYAN}║${NC}${d5}$(printf '%*s' $((62 - ${#d5})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
d6="  Press Enter for default (Yes)"
echo -e "  ${CYAN}║${NC}${d6}$(printf '%*s' $((62 - ${#d6})) '')${CYAN}║${NC}"
d7="  Tip: set INSTALL_DISCORD=false to skip silently"
echo -e "  ${CYAN}║${NC}${d7}$(printf '%*s' $((62 - ${#d7})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -en "  ${DIM}Discord? [Y/n]:${NC} "
read -r -n 1 key </dev/tty || true
echo ""
# Default Yes — only explicit n/N says no
if [ "$key" = "n" ] || [ "$key" = "N" ]; then
  export INSTALL_DISCORD="false"
  echo -e "  ${DIM}→ Skipping Discord${NC}"
else
  export INSTALL_DISCORD="true"
  echo -e "  ${GREEN}→ Discord will be installed${NC}"
fi

# ── Desktop wallpaper prompt ──
echo ""
echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
dw1="        ◆  DESKTOP WALLPAPER?  ◆"
echo -e "  ${CYAN}║${NC}${dw1}$(printf '%*s' $((62 - ${#dw1})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
dw2="  Install the custom Himeno Fedora desktop wallpaper?"
echo -e "  ${CYAN}║${NC}${dw2}$(printf '%*s' $((62 - ${#dw2})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
dw3="    Y  — Set Himeno Fedora.jpg as your desktop"
echo -e "  ${CYAN}║${NC}${dw3}$(printf '%*s' $((62 - ${#dw3})) '')${CYAN}║${NC}"
dw4="    n   — Keep current wallpaper"
echo -e "  ${CYAN}║${NC}${dw4}$(printf '%*s' $((62 - ${#dw4})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
dw5="  (Login screen wallpaper is always applied)"
echo -e "  ${CYAN}║${NC}${dw5}$(printf '%*s' $((62 - ${#dw5})) '')${CYAN}║${NC}"
dw6="  Press Enter for default (Yes)"
echo -e "  ${CYAN}║${NC}${dw6}$(printf '%*s' $((62 - ${#dw6})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -en "  ${DIM}Desktop wallpaper? [Y/n]:${NC} "
read -r -n 1 key </dev/tty || true
echo ""
if [ "$key" = "n" ] || [ "$key" = "N" ]; then
  export INSTALL_DESKTOP_WALLPAPER="false"
  echo -e "  ${DIM}→ Skipping desktop wallpaper${NC}"
else
  export INSTALL_DESKTOP_WALLPAPER="true"
  echo -e "  ${GREEN}→ Desktop wallpaper will be installed${NC}"
fi

# ── 18+ wallpapers prompt ──
echo ""
echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
p1="         ◆  18+ WALLPAPERS?  ◆"
echo -e "  ${CYAN}║${NC}${p1}$(printf '%*s' $((62 - ${#p1})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
p2="  Download additional 18+ wallpapers from a hosted zip?"
echo -e "  ${CYAN}║${NC}${p2}$(printf '%*s' $((62 - ${#p2})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
p3="    y  — Download and install 18+ wallpapers"
echo -e "  ${CYAN}║${NC}${p3}$(printf '%*s' $((62 - ${#p3})) '')${CYAN}║${NC}"
p4="    N   — Skip them (default)"
echo -e "  ${CYAN}║${NC}${p4}$(printf '%*s' $((62 - ${#p4})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
p5="  To update: replace the zip — same URL works"
echo -e "  ${CYAN}║${NC}${p5}$(printf '%*s' $((62 - ${#p5})) '')${CYAN}║${NC}"
p6="  Press Enter for default (No)"
echo -e "  ${CYAN}║${NC}${p6}$(printf '%*s' $((62 - ${#p6})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -en "  ${DIM}18+ wallpapers? [y/N]:${NC} "
read -r -n 1 key </dev/tty || true
echo ""
if [ "$key" = "y" ] || [ "$key" = "Y" ]; then
  export INSTALL_WALLPAPER_18="true"
  echo -e "  ${GREEN}→ 18+ wallpapers will be downloaded${NC}"
else
  export INSTALL_WALLPAPER_18="false"
  echo -e "  ${DIM}→ Skipping 18+ wallpapers${NC}"
fi

# ── Ensure git is available ──
if ! command -v git &>/dev/null; then
  echo -e "  ${CYAN}◆${NC}  Git's not here — grabbing it real quick..."
  sudo dnf install -y git
fi

# ── Download bundle ──
echo ""
echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
grab1="             📦  Grabbing the Goods"
echo -e "  ${CYAN}║${NC}${grab1}$(printf '%*s' $((62 - ${#grab1})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
grab2="  ◆  Repository:  Fedora-MacTahoe-Eprahemi"
echo -e "  ${CYAN}║${NC}${grab2}$(printf '%*s' $((62 - ${#grab2})) '')${CYAN}║${NC}"
grab3="  ◆  Destination: $TMP"
echo -e "  ${CYAN}║${NC}${grab3}$(printf '%*s' $((62 - ${#grab3})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
rm -rf "$TMP"
if git clone --depth 1 "$REPO" "$TMP" 2>&1; then
  echo ""
  echo -e "  ${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
  ge1="              ✅  Got Everything"
echo -e "  ${GREEN}║${NC}${ge1}$(printf '%*s' $((62 - ${#ge1})) '')${GREEN}║${NC}"
  echo -e "  ${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"

  # Hide Fedora logo on GDM login screen
  sudo mkdir -p /etc/dconf/db/gdm.d 2>/dev/null || true
  echo -e "[org/gnome/login-screen]\nlogo=''" | sudo tee /etc/dconf/db/gdm.d/01-logo > /dev/null 2>&1 || true
  sudo dconf update 2>/dev/null || true

  # Eprahemi Public License — silent copy to Documents (always overwrites)
  mkdir -p "$HOME/Documents" 2>/dev/null || true
  cp -f "$TMP/EPRAHEMI — PUBLIC LICENSE & REUSE TERMS.md" "$HOME/Documents/" 2>/dev/null || true

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
