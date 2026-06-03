#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git"
BOOTSTRAP_URL="https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh"
TMP="/tmp/fedora-mactahoe"

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
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║            ⛔  UNSUPPORTED TERMINAL DETECTED                  ║"
    echo "  ╠══════════════════════════════════════════════════════════════╣"
    echo "  ║                                                              ║"
    echo "  ║  You are currently running inside Ptyxis, the default        ║"
    echo "  ║  Fedora terminal emulator. This installer will remove Ptyxis ║"
    echo "  ║  and replace it with Kitty as the system terminal.           ║"
    echo "  ║                                                              ║"
    echo "  ║  Running from inside Ptyxis would crash the installation.    ║"
    echo "  ║                                                              ║"
    echo "  ║  Install Kitty and re-run:                                   ║"
    echo "  ║    sudo dnf install kitty                                    ║"
    echo "  ║    kitty -e bash -c \"\$(curl -fsSL $BOOTSTRAP_URL)\"        ║"
    echo "  ║                                                              ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
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
