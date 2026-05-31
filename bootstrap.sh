#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git"
TMP="/tmp/fedora-mactahoe"

echo "=========================================="
echo "  Fedora MacTahoe — Eprahemi Edition"
echo "  One-click installer"
echo "=========================================="
echo ""

if [ ! -d "$TMP" ]; then
  echo "Downloading bundle..."
  git clone --depth 1 "$REPO" "$TMP"
else
  echo "Updating bundle..."
  cd "$TMP" && git pull
fi

cd "$TMP"
bash install.sh
