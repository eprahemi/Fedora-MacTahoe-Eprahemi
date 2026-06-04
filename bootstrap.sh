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
    echo -e "  ║            ⛔  UNSUPPORTED TERMINAL DETECTED                  ║"
    echo -e "  ╠══════════════════════════════════════════════════════════════╣"
    echo -e "  ║                                                              ║"
    echo -e "  ║  You are currently running inside ${BOLD}Ptyxis${NC}, the default          ║"
    echo -e "  ║  Fedora terminal emulator. This installer is designed to      ║"
    echo -e "  ║  completely replace Ptyxis with Kitty as the system terminal  ║"
    echo -e "  ║  and will ${BOLD}${RED}remove${NC} Ptyxis during the installation process.         ║"
    echo -e "  ║                                                              ║"
    echo -e "  ║  ${YELLOW}╳${NC}  Running the installer from inside Ptyxis would:            ║"
    echo -e "  ║     • Uninstall the terminal you are currently using          ║"
    echo -e "  ║     • Crash the installation process mid-way                  ║"
    echo -e "  ║     • Potentially corrupt your session or lose unsaved work  ║"
    echo -e "  ║                                                              ║"
    echo -e "  ║  ${GREEN}✓${NC}  To proceed with the installation:                          ║"
    echo -e "  ║                                                              ║"
    echo -e "  ║  ${BOLD}Step 1${NC}  Install Kitty terminal:                                 ║"
    echo -e "  ║       sudo dnf install kitty                                 ║"
    echo -e "  ║                                                              ║"
    echo -e "  ║  ${BOLD}Step 2${NC}  Launch Kitty and re-run the installer:                   ║"
    echo -e "  ║       kitty -e bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh)\" ║"
    echo -e "  ║                                                              ║"
    echo -e "  ║  ${YELLOW}Note:${NC} You can keep Ptyxis as a secondary terminal if you wish,   ║"
    echo -e "  ║  but Kitty is required as the primary terminal for the       ║"
    echo -e "  ║  MacTahoe experience to function correctly.                  ║"
    echo -e "  ║                                                              ║"
    echo -e "  ╚══════════════════════════════════════════════════════════════╝"
    echo ""
    exit 1
  fi
fi

echo "=========================================="
echo "  Fedora MacTahoe — Eprahemi Edition"
echo "  One-click installer"
echo "=========================================="
echo ""

# Ensure git is available (not included in Fedora Workstation by default)
if ! command -v git &>/dev/null; then
  echo "Git not found — installing..."
  sudo dnf install -y git
fi

rm -rf "$TMP"
echo "Downloading bundle..."
git clone --depth 1 "$REPO" "$TMP"

cd "$TMP"
bash install.sh
