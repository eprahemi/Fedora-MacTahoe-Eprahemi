# ══════════════════════════════════════════════════════════════
# cleanreset 🧹 — EPRAHEMI INC. 🏢 Cleaning service don't come free
# This broom is patented bestie sweep your own code 🧽
# Fedora MacTahoe Eprahemi Edition © 2026 — dust-free & lit
# ══════════════════════════════════════════════════════════════
function cleanreset --description 'Safe refresh: shell restart, thumbs, DNF, Flatpak, logs'
    if set -q argv[1]
        switch $argv[1]
            case --help -h
                echo -e "\033[1;36m"
                echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
                echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
                echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
                echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
                echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
                echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
                echo -e "\033[1;33mUsage: \033[1;36mcleanreset\033[0m"
                echo -e "  \033[38;5;248mSafe refresh: restarts GNOME Shell, clears thumbnails,\033[0m"
                echo -e "  \033[38;5;248mcleans DNF & Flatpak, vacuums logs, reloads config\033[0m"
                echo -e "  \033[38;5;248m  --help, -h    📖 Read the manual dummy\033[0m"
                echo -e "  \033[38;5;248m📦 Unknown flag handling + rotating burns (Jun 2026)\033[0m"
                return 0
        end
    end

    # --- EPRAHEMI CUSTOM HEADER ---
    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    echo -e "\e[1;34m--- STARTING SAFE REFRESH bestie (keeping logins) ---\e[0m"
    
    # Refresh GNOME Shell
    busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart_shell()'
    
    # Clear Thumbnails (The "Fish-friendly" way to avoid wildcard errors)
    find ~/.cache/thumbnails -type f -delete 2>/dev/null
    
    # Clean DNF & Flatpak
    sudo dnf clean all
    flatpak uninstall --unused -y
    
    # Clean Logs
    sudo journalctl --vacuum-time=1s
    
    # Reload Shell
    source ~/.config/fish/config.fish
    
    echo -e "\e[1;32m--- REFRESH COMPLETE bestie! Apps & logins saved fr fr ---\e[0m"
end
