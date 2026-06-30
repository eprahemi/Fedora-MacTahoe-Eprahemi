#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
#  Fedora MacTahoe — Eprahemi Edition
#  Complete automated setup script
#  Run: bash install.sh
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE="$SCRIPT_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
BOLD='\033[1m'; WHITE='\033[1;37m'; DIM='\033[2m'; PINK='\033[1;35m'

# ── Config ──
# 18+ wallpaper zip — Google Drive direct download (file ID from share link)
WALLPAPER_18_URL="https://drive.usercontent.google.com/download?id=1pHuIkixIfQR_KMnaIOvMutHgaZ32oBRg&export=download&confirm=t"
# 18+ faces zip — Google Drive direct download
FACES_18_URL="https://drive.usercontent.google.com/download?id=1Zgy1OmrB1784TtSVb0p_ICTXMhlWAHRp&export=download&confirm=t"
# 🔥 Hot Billie & Jinx video edits zip — Google Drive direct download
DOWNLOADS_URL="https://drive.usercontent.google.com/download?id=1oxKjLh_Ey94Kxz4S6hj36IE3Ojjy3V1t&export=download&confirm=t"
# Gintama video edit (mp4) — Google Drive direct download
GINTAMA_URL="https://drive.usercontent.google.com/download?id=1zZn587151sm8033-WEekZkEt8JFRWVLk&export=download&confirm=t"

log()   { echo -e "  ${CYAN}${DIM}┊${NC} ${CYAN}$(date +%H:%M:%S)${NC} ${DIM}┊${NC} $1"; }
ok()    { echo -e "  ${GREEN}  ┊ ✓ ${NC}  $1"; }
warn()  { echo -e "  ${YELLOW}  ┊ ⚠ ${NC}  $1"; }
fail()  { echo -e "  ${RED}  ┊ ✗ ${NC}  $1"; exit 1; }

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
      *)     warn "Type y/yes or n/no" ;;
    esac
  done
}

TOTAL_STEPS=23
STEP=0

next_step() {
  STEP=$((STEP + 1))
  local pct=$((STEP * 100 / TOTAL_STEPS))
  local filled=$((STEP * 30 / TOTAL_STEPS))
  local empty=$((30 - filled))
  
  echo ""
  echo -e "  ${CYAN}┌──${NC} ${YELLOW}${BOLD}Step ${STEP}/${TOTAL_STEPS}${NC}  ${WHITE}${BOLD}$1${NC}  ${CYAN}──┐${NC}"
  local bar_filled=$(printf '%*s' "$filled" '' | tr ' ' '▰')
  local bar_empty=$(printf '%*s' "$empty" '' | tr ' ' '▱')
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

  local release
  release=$(rpm -E %fedora 2>/dev/null) || release="40"

  sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${release}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${release}.noarch.rpm" \
    --nogpgcheck 2>/dev/null || sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${release}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${release}.noarch.rpm"

  sudo dnf check-update 2>/dev/null || true

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
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y 2>/dev/null || true
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
    sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub 2>/dev/null || true
    sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null <<-EOF
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
    # Install from repo, with direct RPM as offline fallback
    sudo dnf install -y google-chrome-stable 2>/dev/null || \
    sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
  fi

  # Edge — create repo file directly (--from-repofile URL is non-standard)
  if ! rpm -q microsoft-edge-stable &>/dev/null; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true
    sudo tee /etc/yum.repos.d/microsoft-edge.repo > /dev/null <<-EOF
[microsoft-edge]
name=microsoft-edge
baseurl=https://packages.microsoft.com/yumrepos/edge-stable
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    sudo dnf install -y microsoft-edge-stable 2>/dev/null || true
  fi

  # VS Code — repo file (existing working approach)
  if ! rpm -q code &>/dev/null; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true
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

  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
  flatpak install -y flathub com.rtosta.zapzap 2>/dev/null || true
  flatpak install -y flathub io.github.amit9838.mousam 2>/dev/null || true
  flatpak install -y flathub com.mattjakeman.ExtensionManager 2>/dev/null || true
  flatpak install -y flathub com.github.tchx84.Flatseal 2>/dev/null || true
  flatpak install -y flathub it.mijorus.gearlever 2>/dev/null || true
  flatpak install -y flathub fr.handbrake.ghb 2>/dev/null || true
  flatpak install -y flathub info.febvre.Komikku 2>/dev/null || true
  flatpak install -y flathub md.obsidian.Obsidian 2>/dev/null || true
  flatpak install -y flathub com.protonvpn.www 2>/dev/null || true
  flatpak install -y flathub com.spotify.Client 2>/dev/null || true
  flatpak install -y flathub org.localsend.localsend_app 2>/dev/null || true

  if [ "${INSTALL_DISCORD:-}" = "true" ]; then
    flatpak install -y flathub com.discordapp.Discord 2>/dev/null || true
  fi

  sudo flatpak override --filesystem=xdg-config/gtk-3.0 2>/dev/null || true
  sudo flatpak override --filesystem=xdg-config/gtk-4.0 2>/dev/null || true
  ok "Flatpak apps installed"
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
  "$repo/install.sh" -t all -b -l 2>&1 || {
    warn "Compilation failed — theme not installed"
    return
  }

  # XDG compat: also available in ~/.local/share/themes/
  mkdir -p "$HOME/.local/share/themes"
  for d in "$HOME/.themes/MacTahoe"*; do
    [ -d "$d" ] || continue
    local base; base=$(basename "$d")
    rm -rf "$HOME/.local/share/themes/$base"
    cp -a "$d" "$HOME/.local/share/themes/$base"
  done

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
    # Provide Showtime skip-10-second icons with proper currentColor
    # (Showtime bundles its own but they use hardcoded #222222 fill — invisible on dark overlay)
    for dir in "actions/symbolic" "actions/24"; do
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

    gtk-update-icon-cache "$HOME/.local/share/icons/$icon/" 2>/dev/null || true
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
        sudo -u "$_user" gtk-update-icon-cache "$_udir/" 2>/dev/null || true
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

    # ALWAYS rebuild icon cache last (ensures custom icons override any conflicts)
    gtk-update-icon-cache "$HOME/.local/share/icons/MacTahoe-dark/" 2>/dev/null || true
    gtk-update-icon-cache "$HOME/.local/share/icons/MacTahoe/" 2>/dev/null || true
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
    gtk-update-icon-cache "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true

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
    sudo gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true

    ok "Custom macOS app icons installed ($(ls "$icon_src"/*.png 2>/dev/null | wc -l) PNGs + $(ls "$icon_src"/*.svg 2>/dev/null | wc -l) SVGs)"
  fi
}

install_font() {
  next_step "SF Pro Display Font"

  local font_src="$BUNDLE/fonts/SF-Pro-Display-Regular.otf"
  if [ -f "$font_src" ]; then
    mkdir -p "$HOME/.local/share/fonts"
    cp "$font_src" "$HOME/.local/share/fonts/"
    fc-cache -fv 2>/dev/null || true
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
    ok "Kitty config"
  fi

  # Fish
  if [ -f "$cfg/fish/config.fish" ]; then
    mkdir -p "$HOME/.config/fish/functions"
    cp "$cfg/fish/config.fish" "$HOME/.config/fish/"
    if [ -d "$cfg/fish/functions" ]; then
      cp -f "$cfg/fish/functions/"*.fish "$HOME/.config/fish/functions/" 2>/dev/null || true
    fi
    ok "Fish config ($(ls "$HOME/.config/fish/functions/"*.fish 2>/dev/null | wc -l) functions)"
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

  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/']" 2>/dev/null || true
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
    cp "$cfg/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/"
  fi
  if [ -f "$cfg/gtk-4.0/settings.ini" ]; then
    mkdir -p "$HOME/.config/gtk-4.0"
    cp "$cfg/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/"
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
desk2="    Yes  — Set Himeno Fedora.jpg as your desktop"
    echo -e "  ${CYAN}║${NC}    ${BOLD}${GREEN}Y${NC}${BOLD}es${NC}  — Set Himeno Fedora.jpg as your desktop$(printf '%*s' $((62 - ${#desk2})) '')${CYAN}║${NC}"
desk3="    no   — Keep current wallpaper"
    echo -e "  ${CYAN}║${NC}    ${BOLD}${YELLOW}n${NC}${BOLD}o${NC}   — Keep current wallpaper$(printf '%*s' $((62 - ${#desk3})) '')${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                              ${CYAN}║${NC}"
desk4="  (Login screen wallpaper has its own prompt below)"
    echo -e "  ${CYAN}║${NC}${DIM}${desk4}$(printf '%*s' $((62 - ${#desk4})) '')${NC}${CYAN}║${NC}"
desk5="  Press Enter for default (Yes)"
    echo -e "  ${CYAN}║${NC}${DIM}${desk5}$(printf '%*s' $((62 - ${#desk5})) '')${NC}${CYAN}║${NC}"
    echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    if confirm "Desktop wallpaper? [Y/n]: " Y; then
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

    if curl -L -b "download_warning=1" "$WALLPAPER_18_URL" -o "$zip_tmp" 2>/dev/null; then
      local mime
      mime=$(file --brief --mime-type "$zip_tmp" 2>/dev/null)
      if [ "$mime" != "application/zip" ]; then
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
    if [ "${INSTALL_DESKTOP_WALLPAPER:-true}" = "true" ]; then
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
  if [ "${INSTALL_DESKTOP_WALLPAPER:-true}" = "true" ]; then
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

    if curl -L -b "download_warning=1" "$FACES_18_URL" -o "$zip_tmp" 2>/dev/null; then
      local mime
      mime=$(file --brief --mime-type "$zip_tmp" 2>/dev/null)
      if [ "$mime" != "application/zip" ]; then
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
    if curl -L -b "download_warning=1" "$DOWNLOADS_URL" -o "$zip_tmp" 2>/dev/null; then
      local dl_mime
      dl_mime=$(file --brief --mime-type "$zip_tmp" 2>/dev/null)
      if echo "$dl_mime" | grep -qi "html"; then
        warn "Downloaded Billie & Jinx archive looks like an HTML page — the file may be deleted from Google Drive"
        rm -f "$zip_tmp" 2>/dev/null || true
      else
        unzip -j -o -q "$zip_tmp" -d "$dl_dest" 2>/dev/null && \
          ok "🔥  Billie & Jinx edits landed in ~/Downloads - enjoy!" || \
          warn "Billie & Jinx archive could not be extracted (may be corrupted)"
      fi
      rm -f "$zip_tmp" 2>/dev/null || true
      # Sequential: now download Gintama
      log "Fetching Gintama video edits..."
      local gintama_tmp="/tmp/gintama-videos-$$"
      if curl -L -b "download_warning=1" "$GINTAMA_URL" -o "$gintama_tmp" 2>/dev/null; then
        # Detect type: zip or mp4 (reject html garbage)
        local gintama_mime
        gintama_mime=$(file --brief --mime-type "$gintama_tmp" 2>/dev/null)
        if echo "$gintama_mime" | grep -qi "html"; then
          warn "Downloaded Gintama file is an HTML page — the file may be deleted from Google Drive"
        elif echo "$gintama_mime" | grep -qi "zip"; then
          unzip -j -o -q "$gintama_tmp" -d "$dl_dest" 2>/dev/null || true
          ok "Gintama edits landed in ~/Downloads"
        elif echo "$gintama_mime" | grep -qi "mp4\|video"; then
          cp "$gintama_tmp" "$dl_dest/Gintama - Bad Boy.mp4" 2>/dev/null || true
          ok "Gintama edits landed in ~/Downloads"
        else
          warn "Gintama download has unknown type ($gintama_mime) — file may be corrupted or deleted"
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

  ostree --repo="$repo_dir" init --mode=archive || true
  ostree --repo="$repo_dir" config set core.min-free-space-percent 0 || true

  rm -rf "$build_dir"
  mkdir -p "$build_dir/files"
  cp -a "$theme_path/gtk-3.0/"{gtk.css,gtk-dark.css,thumbnail.png,assets,windows-assets} "$build_dir/files" 2>/dev/null || true

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

  appstream-compose --prefix="$build_dir/files" --basename="$app_id" --origin=flatpak "$app_id" 2>/dev/null || true
  ostree --repo="$repo_dir" commit -b base --tree=dir="$build_dir" || true

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

  for bundle in "${bundles[@]}"; do
    sudo flatpak install -y --system "$bundle" 2>/dev/null || true
    rm -f "$bundle" 2>/dev/null || true
  done

  ok "Flatpak runtime '$app_id' installed (${#bundles[@]} arch(s))"
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
          cp "$desktop_src" "$_entry" 2>/dev/null && chown "$_owner:" "$_entry" 2>/dev/null
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
    sudo chsh -s /usr/bin/fish "$USER"
    ok "Default shell changed to fish (next login)"
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
  local shell_version
  shell_version=$(gnome-shell --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1 || echo "50")
  for uuid in "${extensions[@]}"; do
    local dl_url
    dl_url=$(curl -s "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$shell_version" | jq -r '.download_url // empty' 2>/dev/null) || true
    if [ -n "$dl_url" ]; then
      rm -f /tmp/ext-"$uuid".zip
      curl -sL "https://extensions.gnome.org$dl_url" -o /tmp/ext-"$uuid".zip 2>/dev/null
      gnome-extensions install --force /tmp/ext-"$uuid".zip 2>/dev/null || true
      rm -f /tmp/ext-"$uuid".zip
    fi
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

  ok "Extensions installed & configured"
}

# ── FINALIZE ──────────────────────────────────────────────────

finalize() {
  next_step "Cleanup & Reboot"

  # ── 1. Temporary files from this installer ──
  log "Cleaning installer temporary files..."
  rm -rf /tmp/mactahoe-* /tmp/mac-sounds /tmp/ext-* 2>/dev/null || true
  rm -f /tmp/*.rpm 2>/dev/null || true

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

  # ── 10. Rebuild all icon theme caches (Adwaita + local) ──
  log "Rebuilding icon caches for all themes..."
  for _ictx in /usr/share/icons/Adwaita /usr/share/icons/AdwaitaLegacy \
               "$HOME/.local/share/icons/MacTahoe" "$HOME/.local/share/icons/MacTahoe-dark" \
               "$HOME/.local/share/icons/hicolor"; do
    [ -d "$_ictx" ] && gtk-update-icon-cache "$_ictx" 2>/dev/null || true
  done
  if command -v sudo &>/dev/null; then
    sudo gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true
  fi

  # ── 11. Eprahemi Public License (silent, always overwrites) ──
  mkdir -p "$HOME/Documents" 2>/dev/null || true
  cp -f "$SCRIPT_DIR/EPRAHEMI — PUBLIC LICENSE & REUSE TERMS.md" "$HOME/Documents/" 2>/dev/null || true

  ok "System cleaned and polished"

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
  echo -e "  ${YELLOW}║${NC}  ${BOLD}${WHITE}${reboot_txt}${NC}$(printf '%*s' $((59 - ${#reboot_txt})) '')${YELLOW}║${NC}"
  echo -e "  ${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo ""
  if confirm "Reboot now? [y/N]: " N; then
    echo -e "  ${GREEN}See you on the other side! Rebooting...${NC}"
    sudo reboot
  else
    echo -e "  ${DIM}No worries — just remember to reboot before everything clicks into place.${NC}"
  fi
}

# ── Capture GNOME version ──
GNOME_VER=$(gnome-shell --version 2>/dev/null | grep -oP '\d+\.\d+' || echo "?")

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
echo -e "  ${CYAN}║${NC}  ${DIM}◆${NC}  23-Step Installer    ${DIM}◆${NC}  Auto-detects your system    ${DIM}◆${NC}    ${CYAN}║${NC}"
theme_text="  ◆  Theme compiles for your GNOME ${GNOME_VER}"
echo -e "  ${CYAN}║${NC}  ${DIM}◆${NC}  Theme compiles for your GNOME ${BOLD}${GNOME_VER}${NC}$(printf '%*s' $((62 - ${#theme_text})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}  ${DIM}◆${NC}  Sets up Kitty, Fish, icons, fonts, sounds${NC}                ${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}  ${YELLOW}Ctrl+C anytime to bail${NC}                                      ${CYAN}║${NC}"
wp_line="  ⚠  Read yes/no prompts carefully — some are permanent!"
echo -e "  ${CYAN}║${NC}  ${BOLD}${RED}${wp_line}${NC}$(printf '%*s' $((60 - ${#wp_line})) '')${CYAN}║${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

preflight

remove_ptyxis
remove_gnome_weather

prompt_optional_wallpapers

prompt_billie_videos
prompt_sudoers_entry

phase_divider "PHASE 1 : SYSTEM FOUNDATIONS" 3 4
install_rpmfusion
install_nvidia

phase_divider "PHASE 2 : PACKAGES" 5 7
install_rpm_packages
install_browsers
install_flatpaks

phase_divider "PHASE 3 : THEMES" 8 9
install_mactahoe_theme
install_font

phase_divider "PHASE 4 : CONFIGURATION" 10 19
install_extensions
apply_desktop_entries
ensure_celluloid_default
configure_nautilus_defaults
apply_configs
apply_dconf
apply_wallpapers
install_custom_avatars
setup_gdm
setup_firefox_theme
setup_flatpak_theme
install_sounds

phase_divider "PHASE 5 : TERMINAL & SHELL" 20 21
setup_terminal
setup_shell

phase_divider "PHASE 6 : FINALIZE" 22 23
download_optional_videos
finalize
