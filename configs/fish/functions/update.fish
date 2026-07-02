# ══════════════════════════════════════════════════════════════
# update 🚀 — Fedora MacTahoe updater
# Kitty-only. Fetches and runs the latest install.sh from GitHub.
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

    echo -e "\033[1;36m"
    echo "  ╔═══════════════════════════════════════════╗"
    echo "  ║      \033[1;33mFEDORA MACTAHOE UPDATER\033[1;36m           ║"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "\033[0m"

    set -l repo "eprahemi/Fedora-MacTahoe-Eprahemi"
    set -l url "https://raw.githubusercontent.com/$repo/main/bootstrap.sh"

    echo -e "  \033[1;37mFetching latest installer from GitHub...\033[0m"

    curl -fsSL "$url" | bash

    set -l exit_code $status
    if test $exit_code -eq 0
        echo -e "\n  \033[1;32m✅ Update complete — you're at the latest version\033[0m"
    else
        echo -e "\n  \033[1;31m✘ Update failed (exit code $exit_code)\033[0m"
    end

    return $exit_code
end
