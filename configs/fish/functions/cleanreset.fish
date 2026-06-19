function cleanreset --description 'Safe refresh: shell restart, thumbs, DNF, Flatpak, logs'
    # --- EPRAHEMI CUSTOM HEADER ---
    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    echo -e "\e[1;34m--- STARTING SAFE REFRESH (KEEPING LOGINS) ---\e[0m"
    
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
    
    echo -e "\e[1;32m--- REFRESH COMPLETE: APPS & LOGINS SAVED ---\e[0m"
end
