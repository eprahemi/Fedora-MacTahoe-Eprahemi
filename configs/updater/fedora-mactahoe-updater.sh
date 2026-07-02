#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# Fedora MacTahoe — Update Notifier
# Checks GitHub for new commits on boot and every 2 hours.
# Shows a persistent notification until the user updates.
# Clicking "Later" silences it until next boot.
# ══════════════════════════════════════════════════════════════

CACHE_DIR="$HOME/.cache/fedora-mactahoe"
mkdir -p "$CACHE_DIR" 2>/dev/null || true

NOTIFIED_FILE="$CACHE_DIR/last-notified-commit"    # saved on "Update Now"
DISMISSED_FILE="$CACHE_DIR/last-dismissed-commit"  # saved on "Later" / X
BOOT_ID_FILE="$CACHE_DIR/last-boot-id"             # tracks reboots
REPO="eprahemi/Fedora-MacTahoe-Eprahemi"

# ── Boot detection: if boot_id changed, clear dismissed hash ──
CURRENT_BOOT_ID=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo "unknown")
LAST_BOOT_ID=$(cat "$BOOT_ID_FILE" 2>/dev/null || echo "")
if [ "$CURRENT_BOOT_ID" != "$LAST_BOOT_ID" ]; then
  rm -f "$DISMISSED_FILE"
  echo "$CURRENT_BOOT_ID" > "$BOOT_ID_FILE"
fi

# ── Fetch latest commit + version from GitHub ──
LATEST_JSON=$(curl -sf "https://api.github.com/repos/${REPO}/commits/main" 2>/dev/null)
if [ -z "$LATEST_JSON" ]; then
  exit 0  # offline or unreachable — skip silently
fi

LATEST_HASH=$(echo "$LATEST_JSON" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d['sha'][:8])
except Exception:
    print('')
" 2>/dev/null)

LATEST_MSG=$(echo "$LATEST_JSON" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    msg = d['commit']['message'].split(chr(10))[0]
    print(msg[:80])
except Exception:
    print('')
" 2>/dev/null)

[ -z "$LATEST_HASH" ] && exit 0

# ── Fetch version info from updates.json ──
LATEST_VER=""
UPDATES_JSON=$(curl -sf "https://raw.githubusercontent.com/${REPO}/main/updates.json" 2>/dev/null)
if [ -n "$UPDATES_JSON" ]; then
  LATEST_VER=$(echo "$UPDATES_JSON" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('latest_version', ''))
except Exception:
    print('')
" 2>/dev/null)
fi

# ── Already updated to this commit? ──
if [ -f "$NOTIFIED_FILE" ]; then
  NOTIFIED=$(cat "$NOTIFIED_FILE" 2>/dev/null || true)
  [ "$LATEST_HASH" = "$NOTIFIED" ] && exit 0
fi

# ── Already dismissed this boot session? ──
if [ -f "$DISMISSED_FILE" ]; then
  DISMISSED=$(cat "$DISMISSED_FILE" 2>/dev/null || true)
  [ "$LATEST_HASH" = "$DISMISSED" ] && exit 0
fi

# ── Build notification title and body ──
NOTIFY_TITLE="Fedora MacTahoe — Update Available"
[ -n "$LATEST_VER" ] && NOTIFY_TITLE="Fedora MacTahoe — Update v${LATEST_VER}"
NOTIFY_BODY="New: ${LATEST_MSG} (${LATEST_HASH})"

# ── Notify with action buttons ──
# -u critical -t 0 → stays on screen until user clicks a button
RESULT=$(notify-send -u critical -t 0 \
  -a "Fedora MacTahoe" \
  -i software-update-available \
  -h "string:sound-name:message-attention" \
  -A "update=Update Now" \
  -A "later=Later" \
  "${NOTIFY_TITLE}" \
  "${NOTIFY_BODY}" 2>/dev/null)

# ── Handle user action ──
if [ "$RESULT" = "update" ]; then
  # Save permanently — never notify for this commit again
  echo "$LATEST_HASH" > "$NOTIFIED_FILE"

  BOOTSTRAP_URL="https://raw.githubusercontent.com/${REPO}/main/bootstrap.sh"

  # Kitty is the only supported terminal for updates
  if command -v kitty &>/dev/null; then
    nohup kitty -e bash -c "curl -fsSL '${BOOTSTRAP_URL}' | bash" >/dev/null 2>&1 &
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
  echo "$LATEST_HASH" > "$DISMISSED_FILE"
fi
