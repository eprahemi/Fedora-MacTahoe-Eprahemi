function refresh
    # --- EPRAHEMI CUSTOM HEADER ---
    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████║██║     ██║  ██║██║  ██║██║  ██║███████║██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    echo -e "          [!] INITIATING NUKE SYSTEM REFRESH...\033[0m"
    
    # 1. Clean up broken scripts
    if test -f /home/eprahemi/.local/share/nautilus-python/extensions/kitty_open.py
        rm /home/eprahemi/.local/share/nautilus-python/extensions/kitty_open.py 2>/dev/null
    end
    
    # 2. Reset Graphics & UI logic
    echo -n "  ➤ Resetting GPU Display Buffers... "
    busctl call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Main.layoutManager._updateHotCorners();' 2>/dev/null
    echo -e "\033[1;32mDONE\033[0m"

    # 3. Deep Cache Purge (Fixed Wildcards)
    echo -n "  ➤ Purging System Thumbnails & Temp Caches... "
    # Using 'find' is safer than '*' in Fish to avoid "No matches" errors
    find ~/.cache/thumbnails -type f -delete 2>/dev/null
    find ~/.cache/gnome-shell/gvfs-metadata -type f -delete 2>/dev/null
    fc-cache -f 2>/dev/null 
    echo -e "\033[1;32mDONE\033[0m"

    # 4. Infrastructure Reset
    echo -n "  ➤ Restarting File & Portal Services... "
    nautilus -q 2>/dev/null
    killall xdg-desktop-portal 2>/dev/null
    sleep 0.5
    /usr/libexec/xdg-desktop-portal & disown
    echo -e "\033[1;32mDONE\033[0m"
    
    # 5. Extension Re-sync
    echo -n "  ➤ Power-cycling Dash-to-Dock... "
    gnome-extensions disable dash-to-dock@micxgx.gmail.com 2>/dev/null
    sleep 1
    gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null
    echo -e "\033[1;32mDONE\033[0m"
    
    # 6. Hardware Memory Flush (The real deal)
    echo -n "  ➤ Freeing Hardware PageCache... "
    sync
    # Optional: If you want total RAM refresh, uncomment the next line
    # sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 
    echo -e "\033[1;32mCOMPLETE\033[0m"
    
    echo -e "\n\033[1;36m✨ EPRAHEMI HARDWARE & INTERFACE FULLY RESTORED\033[0m"
end
