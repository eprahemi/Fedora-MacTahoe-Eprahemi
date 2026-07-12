#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# Fedora MacTahoe — Update Notifier
# Checks updates.json on GitHub for version bumps only.
# Shows a persistent notification until the user updates.
# Clicking "Later" silences it until next boot.
# ══════════════════════════════════════════════════════════════

CACHE_DIR="$HOME/.cache/fedora-mactahoe"
mkdir -p "$CACHE_DIR" 2>/dev/null || true

NOTIFIED_FILE="$CACHE_DIR/last-notified-version"    # saved on "Update Now"
DISMISSED_FILE="$CACHE_DIR/last-dismissed-version"  # saved on "Later" / X
BOOT_ID_FILE="$CACHE_DIR/last-boot-id"              # tracks reboots
STATE_FILE="$CACHE_DIR/install-state.json"          # installed version from install.sh
REPO="eprahemi/Fedora-MacTahoe-Eprahemi"

# ── Version comparison helper (returns 0 if v1 < v2) ──
_ver_lt() {
  [ "$(echo -e "$1\n$2" | sort -V 2>/dev/null | head -1)" = "$1" ] && [ "$1" != "$2" ]
}

# ── Boot detection: if boot_id changed, clear dismissed version ──
CURRENT_BOOT_ID=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo "unknown")
LAST_BOOT_ID=$(cat "$BOOT_ID_FILE" 2>/dev/null || echo "")
if [ "$CURRENT_BOOT_ID" != "$LAST_BOOT_ID" ]; then
  rm -f "$DISMISSED_FILE"
  echo "$CURRENT_BOOT_ID" > "$BOOT_ID_FILE"
fi

# ── Fetch latest version from updates.json on GitHub ──
LATEST_VER=""
UPDATES_JSON=$(curl -sf "https://raw.githubusercontent.com/${REPO}/main/updates.json" 2>/dev/null)
if [ -z "$UPDATES_JSON" ]; then
  exit 0  # offline or unreachable — skip silently
fi

LATEST_VER=$(echo "$UPDATES_JSON" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('latest_version', ''))
except Exception:
    print('')
" 2>/dev/null)

[ -z "$LATEST_VER" ] && exit 0

# ── Read user's installed version from install-state.json ──
USER_VER="0.0"
if [ -f "$STATE_FILE" ]; then
  USER_VER=$(cat "$STATE_FILE" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('version', '0.0'))
except Exception:
    print('0.0')
" 2>/dev/null || echo "0.0")
fi

# ── If user's installed version is already at or above latest → nothing to do ──
if ! _ver_lt "$USER_VER" "$LATEST_VER"; then
  exit 0
fi

# ── Already clicked "Update Now" for this version? ──
if [ -f "$NOTIFIED_FILE" ]; then
  NOTIFIED=$(cat "$NOTIFIED_FILE" 2>/dev/null || true)
  [ "$LATEST_VER" = "$NOTIFIED" ] && exit 0
fi

# ── Already dismissed this version this boot session? ──
if [ -f "$DISMISSED_FILE" ]; then
  DISMISSED=$(cat "$DISMISSED_FILE" 2>/dev/null || true)
  [ "$LATEST_VER" = "$DISMISSED" ] && exit 0
fi

# ── Notify with action buttons ──
# -u critical -t 0 → stays on screen until user clicks a button
RESULT=$(notify-send -u critical -t 0 \
  -a "Fedora MacTahoe" \
  -i software-update-available \
  -h "string:sound-name:message-attention" \
  -A "update=Update Now" \
  -A "later=Later" \
  "Fedora MacTahoe — Update v${LATEST_VER}" \
  "A new version is available. Click Update Now to upgrade.\nType 'update' in your terminal to update anytime." 2>/dev/null)

# ── Handle user action ──
if [ "$RESULT" = "update" ]; then
  # Save permanently — never notify for this version again
  echo "$LATEST_VER" > "$NOTIFIED_FILE"

  # Kitty is the only supported terminal for updates
  if command -v kitty &>/dev/null; then
    # Write a temp launcher script to avoid quoting issues and keep window open
    LAUNCHER="/tmp/.mct-update-$(date +%s).sh"
    cat > "$LAUNCHER" << 'LAUNCHER_EOF'
#!/usr/bin/env bash
UPDATE_MODE=incremental bash <(curl -fsSL 'https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh')
echo ""
read -rp "Press Enter to close this window..."
LAUNCHER_EOF
    chmod +x "$LAUNCHER"
    # setsid fully detaches Kitty from this process so systemd won't kill it
    setsid kitty --title "Fedora MacTahoe Update" "$LAUNCHER" </dev/null &>/dev/null &
    sleep 2
    rm -f "$LAUNCHER" 2>/dev/null || true
  else
    # Kitty not installed — show error notification
    notify-send -u critical -t 10000 \
      -a "Fedora MacTahoe" \
      -i dialog-error \
      "Kitty terminal not found" \
      "Kitty is required for updates. Install it with: sudo dnf install kitty" 2>/dev/null || true
  fi
else
  # "Later" or X / Esc — dismiss until next boot only
  echo "$LATEST_VER" > "$DISMISSED_FILE"
fi
