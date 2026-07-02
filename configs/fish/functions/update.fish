# ══════════════════════════════════════════════════════════════
# update 🚀 — Fedora MacTahoe updater
# Kitty-only. Shows version diff, prompts y/n, runs bootstrap.
# Same as clicking "Update Now" on the notification popup.
# Fedora MacTahoe Eprahemi Edition © 2026
# ══════════════════════════════════════════════════════════════
function update --description 'Fedora MacTahoe update — Kitty only (same as Update Now)'
    # ── Kitty gate: only Kitty is supported ──
    if not set -q KITTY_PID
        echo -e "\033[1;31m"
        echo "  ╔═══════════════════════════════════════════╗"
        echo "  ║            \033[1;37m🚫  BLOCKED\033[1;31m                  ║"
        echo "  ║                                           ║"
        echo "  ║  \033[1;33mFedora MacTahoe requires\033[1;31m               ║"
        echo "  ║  \033[1;33mKitty terminal.\033[1;31m                        ║"
        echo "  ║                                           ║"
        echo "  ║  \033[1;37mOpen Kitty and type 'update' there.\033[1;31m    ║"
        echo "  ╚══════════════════════════════════════════════╝"
        echo -e "\033[0m"
        return 1
    end

    # ── Read current installed version ──
    set -l current_ver "0.0"
    if test -f "$HOME/.cache/fedora-mactahoe/install-state.json"
        set current_ver (cat "$HOME/.cache/fedora-mactahoe/install-state.json" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('version', '0.0'))
except Exception:
    print('0.0')
" 2>/dev/null)
    end

    # ── Fetch the latest version manifest from GitHub ──
    set -l latest_ver ""
    set -l repo "eprahemi/Fedora-MacTahoe-Eprahemi"
    set -l updates_url "https://raw.githubusercontent.com/$repo/main/updates.json"
    set -l manifest (curl -sf "$updates_url" 2>/dev/null)
    if test -n "$manifest"
        set latest_ver (echo "$manifest" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('latest_version', ''))
except Exception:
    print('')
" 2>/dev/null)
    end

    # ── Display header ──
    echo -e "\033[1;36m"
    echo "  ╔═══════════════════════════════════════════╗"
    echo "  ║      \033[1;33mFEDORA MACTAHOE UPDATER\033[1;36m           ║"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "\033[0m"

    # ── Show versions ──
    echo -e "  \033[1;37mInstalled:\033[0m  \033[1;36m$current_ver\033[0m"
    if test -n "$latest_ver"
        echo -e "  \033[1;37mAvailable:\033[0m \033[1;33m$latest_ver\033[0m"
    else
        echo -e "  \033[1;37mAvailable:\033[0m \033[1;31mcould not fetch\033[0m"
    end
    echo ""

    # ── Compare versions ──
    set -l needs_update 0
    if test -n "$latest_ver"
        # sort -V puts smaller version first; if current == larger, we're fine
        set -l larger (printf '%s\n' "$current_ver" "$latest_ver" | sort -V 2>/dev/null | tail -1)
        if test "$current_ver" != "$larger"
            set needs_update 1
        end
    end

    if test $needs_update -eq 0
        echo -e "  \033[1;32m✓ You're already at the latest version.\033[0m"
        return 0
    end

    # ── Prompt y/n (Ctrl+C cancels) ──
    echo -e "  \033[1;33mAn update is available.\033[0m"
    read -l confirm -P "  \033[1;37mProceed with update? [y/N]: \033[0m"
    if test $status -ne 0
        # Ctrl+C or error during read
        echo ""
        echo -e "  \033[1;31m✘ Cancelled.\033[0m"
        return 1
    end

    switch $confirm
        case y Y yes Yes YES
            # confirmed — proceed below
        case '*'
            echo -e "  \033[1;31m✘ Cancelled.\033[0m"
            return 1
    end

    # ── Run the installer ──
    echo ""
    echo -e "  \033[1;37mFetching latest installer from GitHub...\033[0m"

    set -l url "https://raw.githubusercontent.com/$repo/main/bootstrap.sh"
    env UPDATE_MODE=incremental curl -fsSL "$url" | bash

    set -l exit_code $status
    if test $exit_code -eq 0
        echo -e "\n  \033[1;32m✅ Update complete — you're at the latest version\033[0m"
    else
        echo -e "\n  \033[1;31m✘ Update failed (exit code $exit_code)\033[0m"
    end

    return $exit_code
end
