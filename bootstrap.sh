#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git"
TMP="/tmp/fedora-mactahoe"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
BOLD='\033[1m'; WHITE='\033[1;37m'; DIM='\033[2m'; PINK='\033[1;35m'

confirm() {
  local prompt="$1" default="${2:-}"
  local reply
  while true; do
    echo -en "  ${DIM}${prompt}${NC} " >/dev/tty
    read -r reply </dev/tty || true
    case "${reply,,}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      '')    [ "$default" = "Y" ] && return 0 || return 1 ;;
      *)     echo -e "  ${YELLOW}║${NC}  Type y/yes or n/no" ;;
    esac
  done
}

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
wp_line="  ⚠  Read yes/no prompts carefully — some are permanent!"
echo -e "  ${CYAN}║${NC}  ${BOLD}${RED}${wp_line}${NC}$(printf '%*s' $((60 - ${#wp_line})) '')${CYAN}║${NC}"
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
d6="  Press Enter for default (No)"
echo -e "  ${CYAN}║${NC}${d6}$(printf '%*s' $((62 - ${#d6})) '')${CYAN}║${NC}"
d7="  Tip: set INSTALL_DISCORD=false to skip silently"
echo -e "  ${CYAN}║${NC}${d7}$(printf '%*s' $((62 - ${#d7})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
if confirm "Discord? [y/N]: " N; then
  export INSTALL_DISCORD="true"
  echo -e "  ${GREEN}→ Discord will be installed${NC}"
else
  export INSTALL_DISCORD="false"
  echo -e "  ${DIM}→ Skipping Discord${NC}"
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
dw5="  (Login screen wallpaper has its own prompt below)"
echo -e "  ${CYAN}║${NC}${dw5}$(printf '%*s' $((62 - ${#dw5})) '')${CYAN}║${NC}"
dw6="  Press Enter for default (Yes)"
echo -e "  ${CYAN}║${NC}${dw6}$(printf '%*s' $((62 - ${#dw6})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
if confirm "Desktop wallpaper? [Y/n]: " Y; then
  export INSTALL_DESKTOP_WALLPAPER="true"
  echo -e "  ${GREEN}→ Desktop wallpaper will be installed${NC}"
else
  export INSTALL_DESKTOP_WALLPAPER="false"
  echo -e "  ${DIM}→ Skipping desktop wallpaper${NC}"
fi

# ── Login screen wallpaper prompt (separate from desktop) ──
echo ""
echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
log_t="       ◆  LOGIN SCREEN WALLPAPER?  ◆"
echo -e "  ${CYAN}║${NC}${log_t}$(printf '%*s' $((62 - ${#log_t})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
log1="  Override the GDM login screen with the Himeno theme?"
echo -e "  ${CYAN}║${NC}${log1}$(printf '%*s' $((62 - ${#log1})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
log2="  This sets the macOS-style login screen with the"
echo -e "  ${CYAN}║${NC}${log2}$(printf '%*s' $((62 - ${#log2})) '')${CYAN}║${NC}"
log3="  Himeno background, macOS theme, and hides the logo."
echo -e "  ${CYAN}║${NC}${log3}$(printf '%*s' $((62 - ${#log3})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
log4="  Not stuck with just this one — the gdm command"
echo -e "  ${CYAN}║${NC}${log4}$(printf '%*s' $((62 - ${#log4})) '')${CYAN}║${NC}"
log4b="  lets you swap wallpapers anytime after install."
echo -e "  ${CYAN}║${NC}${log4b}$(printf '%*s' $((62 - ${#log4b})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
log4c="  If you already have a custom GDM setup, skip this."
echo -e "  ${CYAN}║${NC}${log4c}$(printf '%*s' $((62 - ${#log4c})) '')${CYAN}║${NC}"
log5="  Press Enter for default (Yes)"
echo -e "  ${CYAN}║${NC}${log5}$(printf '%*s' $((62 - ${#log5})) '')${CYAN}║${NC}"
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
    export INSTALL_LOGIN_WALLPAPER="true"
    echo -e "  ${GREEN}→ GDM login screen will be themed${NC}"
  else
    export INSTALL_LOGIN_WALLPAPER="false"
    echo -e "  ${DIM}→ Skipping GDM login screen${NC}"
  fi
else
  export INSTALL_LOGIN_WALLPAPER="false"
  echo -e "  ${DIM}→ Skipping GDM login screen${NC}"
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
echo ""
if confirm "18+ wallpapers? [y/N]: " N; then
  export INSTALL_WALLPAPER_18="true"
  echo -e "  ${GREEN}→ 18+ wallpapers will be downloaded${NC}"
else
  export INSTALL_WALLPAPER_18="false"
  echo -e "  ${DIM}→ Skipping 18+ wallpapers${NC}"
fi

# ── 🔥 Billie & Jinx video edits prompt ──
echo ""
echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
bv_t="        ◆  🔥  HOT BILLIE & JINX VIDEO EDITS?  ◆"
echo -e "  ${CYAN}║${NC}${bv_t}$(printf '%*s' $((61 - ${#bv_t})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
bv1="  🔥  Sick edits — Billie, Jinx, and cool stuff (~500 MB)"
echo -e "  ${CYAN}║${NC}${bv1}$(printf '%*s' $((61 - ${#bv1})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
bv2="    Yes  — Heck yeah! Drop 'em in ~/Downloads"
echo -e "  ${CYAN}║${NC}    ${BOLD}${GREEN}Y${NC}${BOLD}es${NC}  — Heck yeah! Drop 'em in ~/Downloads$(printf '%*s' $((62 - ${#bv2})) '')${CYAN}║${NC}"
bv3="    No   — Nah, not today (default)"
echo -e "  ${CYAN}║${NC}    ${BOLD}${YELLOW}n${NC}${BOLD}o${NC}   — Nah, not today (default)$(printf '%*s' $((62 - ${#bv3})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
bv4="  You'll get Billie Eilish , Jinx Edit Hot, and more"
echo -e "  ${CYAN}║${NC}${bv4}$(printf '%*s' $((62 - ${#bv4})) '')${CYAN}║${NC}"
bv5="  Press Enter for default (No)"
echo -e "  ${CYAN}║${NC}${bv5}$(printf '%*s' $((62 - ${#bv5})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
if confirm "Billie & Jinx video edits? [y/N]: " N; then
  export INSTALL_BILLIE_VIDEOS="true"
  echo -e "  ${GREEN}→  🔥  Alright! Dropping hot edits in ~/Downloads${NC}"
else
  # ── Naughty second prompt — are you REALLY sure? ──
  echo ""
  echo -e "  ${PINK}╔══════════════════════════════════════════════════════════════╗${NC}"
nsty_t="     ◆  👀  U SURE BUDDY?  👀  ◆"
  echo -e "  ${PINK}║${NC}${nsty_t}$(printf '%*s' $((60 - ${#nsty_t})) '')${PINK}║${NC}"
  echo -e "  ${PINK}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "  ${PINK}║${NC}                                                              ${PINK}║${NC}"
nsty1="  You really gonna miss out on mommy Billie's sweet"
  echo -e "  ${PINK}║${NC}${nsty1}$(printf '%*s' $((62 - ${#nsty1})) '')${PINK}║${NC}"
nsty2="  body and Jinx's hot slim curves?  🔥  💦"
  echo -e "  ${PINK}║${NC}${nsty2}$(printf '%*s' $((60 - ${#nsty2})) '')${PINK}║${NC}"
  echo -e "  ${PINK}║${NC}                                                              ${PINK}║${NC}"
nsty3="    Yes  — OK OK YOU CONVINCED ME!  😩🔥"
  echo -e "  ${PINK}║${NC}    ${BOLD}${GREEN}Y${NC}${BOLD}es${NC}  — OK OK YOU CONVINCED ME!  😩🔥$(printf '%*s' $((60 - ${#nsty3})) '')${PINK}║${NC}"
nsty4="    No   — Nah I'm good (for real this time)"
  echo -e "  ${PINK}║${NC}    ${BOLD}${YELLOW}n${NC}${BOLD}o${NC}   — Nah I'm good (for real this time)$(printf '%*s' $((62 - ${#nsty4})) '')${PINK}║${NC}"
  echo -e "  ${PINK}║${NC}                                                              ${PINK}║${NC}"
nsty5="  Last chance before you miss mommy..."
  echo -e "  ${PINK}║${NC}${nsty5}$(printf '%*s' $((62 - ${#nsty5})) '')${PINK}║${NC}"
  echo -e "  ${PINK}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  if confirm "👀  For real though? [y/N]: " N; then
    export INSTALL_BILLIE_VIDEOS="true"
    echo -e "  ${GREEN}→  😩  Alright alright — dropping hot edits in ~/Downloads${NC}"
  else
    export INSTALL_BILLIE_VIDEOS="false"
    echo -e "  ${DIM}→  Aight your loss, more for the rest of us 🔥${NC}"
  fi
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
