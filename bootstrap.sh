#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git"
TMP="/tmp/fedora-mactahoe"

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
