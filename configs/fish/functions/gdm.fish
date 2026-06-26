# ══════════════════════════════════════════════════════════════
# gdm 🖼️ — EPRAHEMI INC. 🏢 Login screen flex on em 💅
# Eprahemi makes GDM wallpaper hot or not? ALWAYS HOT 🔥
# Fedora MacTahoe Eprahemi Edition © 2026 — change yo login
# ══════════════════════════════════════════════════════════════
function gdm --description 'Change GDM login screen wallpaper — clones MacTahoe repo once, reuses forever'
    # ── Arg check ──
    if not set -q argv[1]
        echo -e "\033[1;31m✘ Usage: \033[1;36mgdm /path/to/wallpaper.jpg\033[0m"
        echo -e "  \033[38;5;248m  -h, --help     Show this help\033[0m"
        return 1
    end

    if contains -- "$argv[1]" "-h" "--help"
        echo -e "\033[1;33mUsage: \033[1;36mgdm /path/to/image.jpg\033[0m"
        echo -e "  \033[38;5;248m  Changes the GDM (login screen) background to your chosen image.\033[0m"
        echo -e "  \033[38;5;248m  Clones MacTahoe theme repo once to ~/.local/share/mactahoe-gtk/\033[0m"
        echo -e "  \033[38;5;248m  Every call after that reuses it — no re-download.\033[0m"
        echo -e ""
        echo -e "  \033[1;36mExamples:\033[0m"
        echo -e "    \033[1;36mgdm ~/Pictures/my-wallpaper.jpg\033[0m"
        echo -e "    \033[1;36mgdm ~/.config/Wallpapers/Himeno\ Fedora\ LoginScreen.jpg\033[0m"
        echo -e ""
        echo -e "  \033[38;5;248m📦 GDM wallpaper switcher — permanent repo (Jun 2026)\033[0m"
        return 0
    end

    set -l image (realpath "$argv[1]" 2>/dev/null)
    if not test -f "$image"
        echo -e "\033[1;31m✘ File not found: \033[1;33m$argv[1]\033[0m"
        return 1
    end

    # ── Persistent MacTahoe repo location (NOT in /tmp) ──
    set -l repo "$HOME/.local/share/mactahoe-gtk"

    if not test -f "$repo/tweaks.sh"
        echo -e "  \033[1;36m📦 Cloning MacTahoe theme repo (one-time)...\033[0m"
        mkdir -p "$HOME/.local/share"
        rm -rf "$repo"
        git clone --depth 1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$repo" 2>/dev/null
        and echo -e "  \033[1;32m✅ Repo cloned to $repo\033[0m"
        or begin
            echo -e "  \033[1;31m✘ Clone failed — check your internet\033[0m"
            return 1
        end
    end

    # ── Apply the wallpaper ──
    echo -e "  \033[1;36m🖼️  Applying GDM wallpaper...\033[0m"
    cd "$repo"
    sudo ./tweaks.sh -g -nb -nd -b "$image"
    cd -

    echo -e "  \033[1;32m✅ GDM wallpaper updated! Reboot to see it.\033[0m"
end
