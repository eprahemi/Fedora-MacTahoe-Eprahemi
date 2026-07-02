# ══════════════════════════════════════════════════════════════
# update 🚀 — Fedora MacTahoe updater
# Fetches and runs the latest install.sh from GitHub.
# Same as clicking "Update Now" on the notification popup.
# Fedora MacTahoe Eprahemi Edition © 2026
# ══════════════════════════════════════════════════════════════
function update --description 'Run Fedora MacTahoe installer from GitHub (same as Update Now)'
    echo -e "\033[1;36m"
    echo "  ╔═══════════════════════════════════════════╗"
    echo "  ║      \033[1;33mFEDORA MACTAHOE UPDATER\033[1;36m           ║"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "\033[0m"

    set -l repo "eprahemi/Fedora-MacTahoe-Eprahemi"
    set -l url "https://raw.githubusercontent.com/$repo/main/bootstrap.sh"

    echo -e "  \033[1;37mFetching latest installer from GitHub...\033[0m"

    # Run it through Kitty if available (matches the updater behavior)
    curl -fsSL "$url" | bash

    set -l exit_code $status
    if test $exit_code -eq 0
        echo -e "\n  \033[1;32m✅ Update complete — you're at the latest version\033[0m"
    else
        echo -e "\n  \033[1;31m✘ Update failed (exit code $exit_code)\033[0m"
    end

    return $exit_code
end
