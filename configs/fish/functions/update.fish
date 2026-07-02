# ══════════════════════════════════════════════════════════════
# update 🚀 — Fedora MacTahoe updater
# Kitty-only. Shows version diff, prompts y/n, runs bootstrap.
# Same as clicking "Update Now" on the notification popup.
# Fedora MacTahoe Eprahemi Edition © 2026
# ══════════════════════════════════════════════════════════════
function update --description 'Fedora MacTahoe update — Kitty only (same as Update Now)'
    # ── Kitty gate: only Kitty is supported ──
    if not set -q KITTY_PID
        printf "\e[1;31m\n"
        printf "  ╔═══════════════════════════════════════════╗\n"
        printf "  ║            \e[1;37m🚫  BLOCKED\e[1;31m                  ║\n"
        printf "  ║                                           ║\n"
        printf "  ║  \e[1;33mFedora MacTahoe requires\e[1;31m               ║\n"
        printf "  ║  \e[1;33mKitty terminal.\e[1;31m                        ║\n"
        printf "  ║                                           ║\n"
        printf "  ║  \e[1;37mOpen Kitty and type 'update' there.\e[1;31m    ║\n"
        printf "  ╚══════════════════════════════════════════════╝\n"
        printf "\e[0m\n"
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
    printf "\e[1;36m\n"
    printf "  ╔═══════════════════════════════════════════╗\n"
    printf "  ║      \e[1;33mFEDORA MACTAHOE UPDATER\e[1;36m           ║\n"
    printf "  ╚══════════════════════════════════════════════╝\n"
    printf "\e[0m\n"

    # ── Show versions ──
    printf "  \e[1;37mInstalled:\e[0m  \e[1;36m%s\e[0m\n" "$current_ver"
    if test -n "$latest_ver"
        printf "  \e[1;37mAvailable:\e[0m \e[1;33m%s\e[0m\n" "$latest_ver"
    else
        printf "  \e[1;37mAvailable:\e[0m \e[1;31mcould not fetch\e[0m\n"
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
        printf "  \e[1;32m✓ You're already at the latest version.\e[0m\n"
        return 0
    end

    # ── Prompt y/n (Ctrl+C cancels) ──
    printf "  \e[1;33mAn update is available.\e[0m\n"
    read -l confirm -P "  Proceed with update? [y/N]: "
    if test $status -ne 0
        # Ctrl+C or error during read
        echo ""
        printf "  \e[1;31m✘ Cancelled.\e[0m\n"
        return 1
    end

    switch $confirm
        case y Y yes Yes YES
            # confirmed — proceed below
        case '*'
            printf "  \e[1;31m✘ Cancelled.\e[0m\n"
            return 1
    end

    # ── Run the installer ──
    echo ""
    printf "  \e[1;37mFetching latest installer from GitHub...\e[0m\n"

    set -l url "https://raw.githubusercontent.com/$repo/main/bootstrap.sh"
    env UPDATE_MODE=incremental curl -fsSL "$url" | bash

    set -l exit_code $status
    if test $exit_code -eq 0
        printf "\n  \e[1;32m✅ Update complete — you're at the latest version\e[0m\n"
    else
        printf "\n  \e[1;31m✘ Update failed (exit code %s)\e[0m\n" $exit_code
    end

    return $exit_code
end
