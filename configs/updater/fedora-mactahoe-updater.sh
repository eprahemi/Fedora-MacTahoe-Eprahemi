#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# Fedora MacTahoe — Update Notifier
# Checks GitHub for new commits every time it's called.
# If a new commit is found and hasn't been notified yet, it
# fires a GNOME notification with "Update Now" / "Later" buttons.
# Clicking "Update Now" opens the default terminal with the installer.
# ══════════════════════════════════════════════════════════════

CACHE_DIR="$HOME/.cache/fedora-mactahoe"
mkdir -p "$CACHE_DIR" 2>/dev/null || true
LAST_HASH_FILE="$CACHE_DIR/last-notified-commit"
REPO="eprahemi/Fedora-MacTahoe-Eprahemi"

# ── Detect terminal ──
# Prefer Kitty (Fedora MacTahoe installs it by default).
# Fall back to the user's configured terminal if Kitty isn't available.
if command -v kitty &>/dev/null; then
    TERMINAL="kitty"
else
    TERMINAL=$(gsettings get org.gnome.desktop.default-applications.terminal exec 2>/dev/null | tr -d "'")
    [ -z "$TERMINAL" ] && TERMINAL="kgx"
fi

# ── Fetch latest commit from GitHub ──
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

# ── Compare with last notified ──
if [ -f "$LAST_HASH_FILE" ]; then
    LAST_HASH=$(cat "$LAST_HASH_FILE" 2>/dev/null || true)
    [ "$LATEST_HASH" = "$LAST_HASH" ] && exit 0
fi

# ── Notify with action buttons ──
# -u critical -t 0 → stays on screen until user clicks a button
RESULT=$(notify-send -u critical -t 0 \
    -a "Fedora MacTahoe" \
    -i software-update-available \
    -h "string:sound-name:message-attention" \
    -A "update=Update Now" \
    -A "later=Later" \
    "Fedora MacTahoe — Update Available" \
    "New: ${LATEST_MSG} (${LATEST_HASH})" 2>/dev/null)

# Save hash regardless (don't re-notify the same commit)
echo "$LATEST_HASH" > "$LAST_HASH_FILE"

# If user clicked "Update Now", launch default terminal with the installer
if [ "$RESULT" = "update" ]; then
    BOOTSTRAP_URL="https://raw.githubusercontent.com/${REPO}/main/bootstrap.sh"

    # Different terminals use different syntax to run a command:
    #   gnome-terminal/kgx  →  --  (remaining args after --)
    #   kitty/konsole       →  -e  (remaining args after -e)
    #   mate-terminal       →  -e  (single string argument only)
    case "$TERMINAL" in
        gnome-terminal|kgx)
            nohup "$TERMINAL" -- bash -c "curl -fsSL '$BOOTSTRAP_URL' | bash" >/dev/null 2>&1 &
            ;;
        mate-terminal|xfce4-terminal|lxterminal|sakura)
            nohup "$TERMINAL" -e "bash -c 'curl -fsSL $BOOTSTRAP_URL | bash'" >/dev/null 2>&1 &
            ;;
        *)
            nohup "$TERMINAL" -e bash -c "curl -fsSL '$BOOTSTRAP_URL' | bash" >/dev/null 2>&1 &
            ;;
    esac
fi
