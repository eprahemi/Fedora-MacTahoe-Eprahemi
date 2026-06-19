function refresh --description 'Deep system refresh: cache, services, extensions, DNS & more'
    set -l start_time (date +%s)
    set -l do_all 0
    set -l do_cache 0
    set -l do_services 0
    set -l do_extensions 0
    set -l do_dns 0
    set -l do_dnf 0
    set -l do_flatpak 0
    set -l do_pip 0

    if test (count $argv) -eq 0
        set do_all 1
    else
        for arg in $argv
            switch $arg
                case -a --all;     set do_all 1
                case -c --cache;   set do_cache 1
                case -s --services; set do_services 1
                case -e --extensions; set do_extensions 1
                case -d --dns;     set do_dns 1
                case -dnf;         set do_dnf 1
                case -fp --flatpak; set do_flatpak 1
                case -pip;         set do_pip 1
                case -h --help
                    echo -e "\033[1;36m"
                    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
                    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
                    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
                    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
                    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
                    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
                    echo -e "\033[1;36m╔══════════════════════════════════════════════════════════╗\033[0m"
                    echo -e "\033[1;36m║           \033[1;33mREFRESH FLAGS - USAGE GUIDE\033[1;36m                  ║\033[0m"
                    echo -e "\033[1;36m╚══════════════════════════════════════════════════════════╝\033[0m"
                    echo -e "  \033[1;37mrefresh\033[0m           — full safe refresh (all below)"
                    echo -e "  \033[1;37mrefresh -c\033[0m        — thumbnail, gnome-software, PackageKit caches"
                    echo -e "  \033[1;37mrefresh -s\033[0m        — restart Nautilus + xdg-desktop-portal"
                    echo -e "  \033[1;37mrefresh -e\033[0m        — cycle Dash-to-Dock extension"
                    echo -e "  \033[1;37mrefresh -d\033[0m        — flush DNS resolver cache"
                    echo -e "  \033[1;37mrefresh -dnf\033[0m      — dnf clean all & autoremove"
                    echo -e "  \033[1;37mrefresh -fp\033[0m       — flatpak uninstall --unused"
                    echo -e "  \033[1;37mrefresh -pip\033[0m      — pip cache purge"
                    return 0
                case '*'
                    echo -e "\033[1;31m❌ Unknown flag bestie: $arg 💀\033[0m"
                    echo -e "   \033[1;33mUse \033[1;36mrefresh --help\033[1;33m like a smart sigma 📖\033[0m"
                    return 1
            end
        end
    end

    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    echo -e "\033[1;33m╔══════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;33m║           \033[1;36mNUKE DEEP SYSTEM REFRESH\033[1;33m                    ║\033[0m"
    echo -e "\033[1;33m╚══════════════════════════════════════════════════════════╝\033[0m"

    if test $do_all -eq 1
        set do_cache 1
        set do_services 1
        set do_extensions 1
        set do_dns 1
        set do_dnf 1
        set do_flatpak 1
        set do_pip 1
        echo -e "  \033[1;34mMode: FULL SYSTEM REFRESH (we going ALL in bestie)\033[0m\n"
    else
        echo -e "  \033[1;34mMode: SELECTIVE CLEANUP (picking and choosing fam)\033[0m\n"
    end

    set -g __rf_total 0
    set -g __rf_current 0
    set -g __rf_frames "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"

    if test $do_cache -eq 1
        set __rf_total (math $__rf_total + 5)
    end
    if test $do_dnf -eq 1;      set __rf_total (math $__rf_total + 2); end
    if test $do_flatpak -eq 1;  set __rf_total (math $__rf_total + 1); end
    if test $do_pip -eq 1;      set __rf_total (math $__rf_total + 1); end
    if test $do_dns -eq 1;      set __rf_total (math $__rf_total + 1); end
    if test $do_services -eq 1; set __rf_total (math $__rf_total + 4); end
    if test $do_extensions -eq 1; set __rf_total (math $__rf_total + 4); end

    function __refresh_anim
        set -l label $argv[1]
        set -l cmd $argv[2]
        set __rf_current (math $__rf_current + 1)

        sh -c "$cmd" 2>/dev/null &
        set -l pid $last_pid

        set -l i 1
        while kill -0 $pid 2>/dev/null
            printf "\r  \033[1;37m⏳ \033[1;36m%s\033[1;37m... \033[1;33m%s  \033[1;31m[%d/%d]\033[0m" "$label" $__rf_frames[$i] $__rf_current $__rf_total
            set i (math $i % 10 + 1)
            sleep 0.06
        end
        wait $pid 2>/dev/null
        printf "\r  \033[1;37m⏳ \033[1;36m%s\033[1;37m... \033[1;32m✅  \033[1;31m[%d/%d]\033[0m\n" "$label" $__rf_current $__rf_total
    end

    function __refresh_section
        set -l name $argv[1]
        echo -e "  \033[1;34m── \033[1;37m$name\033[1;34m ──\033[0m"
    end

    if test $do_cache -eq 1
        __refresh_section "CACHE CLEANUP"
        __refresh_anim "Thumbnail cache"      "find ~/.cache/thumbnails -type f -delete 2>/dev/null; true"
        __refresh_anim "GNOME Shell metadata" "find ~/.cache/gnome-shell/gvfs-metadata -type f -delete 2>/dev/null; true"
        __refresh_anim "GNOME Software cache" "rm -rf ~/.cache/gnome-software/ 2>/dev/null"
        __refresh_anim "PackageKit metadata"  "rm -rf ~/.cache/PackageKit/ 2>/dev/null"
        __refresh_anim "Font cache rebuild"   "fc-cache -f 2>/dev/null"
    end

    if test $do_dnf -eq 1
        __refresh_section "DNF CLEANUP"
        __refresh_anim "DNF clean all"  "sudo dnf clean all 2>/dev/null"
        __refresh_anim "DNF autoremove" "sudo dnf autoremove -y 2>/dev/null"
    end

    if test $do_flatpak -eq 1
        __refresh_section "FLATPAK CLEANUP"
        __refresh_anim "Unused runtimes" "flatpak uninstall --unused -y 2>/dev/null"
    end

    if test $do_pip -eq 1
        __refresh_section "PIP CLEANUP"
        if command -v pip &>/dev/null
            __refresh_anim "Pip cache purge" "pip cache purge 2>/dev/null"
        else
            __refresh_anim "Pip cache purge" "true"
        end
    end

    if test $do_dns -eq 1
        __refresh_section "DNS"
        __refresh_anim "Flush resolver cache" "resolvectl flush-caches 2>/dev/null"
    end

    if test $do_services -eq 1
        __refresh_section "SERVICES"
        __refresh_anim "Restart Nautilus"        "nautilus -q 2>/dev/null"
        __refresh_anim "Kill portal daemon"     "killall xdg-desktop-portal 2>/dev/null"
        __refresh_anim "Restart portal daemon"  "nohup /usr/libexec/xdg-desktop-portal >/dev/null 2>&1 &"
        __refresh_anim "GPU display buffer"     "busctl call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Main.layoutManager._updateHotCorners();' 2>/dev/null"
    end

    if test $do_extensions -eq 1
        __refresh_section "EXTENSIONS"
        __refresh_anim "Disable Dash-to-Dock" "gnome-extensions disable dash-to-dock@micxgx.gmail.com 2>/dev/null"
        sleep 0.3
        __refresh_anim "Enable Dash-to-Dock"  "gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null"
        sleep 0.3
        __refresh_anim "Disable User Themes"  "gnome-extensions disable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null"
        sleep 0.3
        __refresh_anim "Enable User Themes"   "gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null"
    end

    set -l end_time (date +%s)
    set -l elapsed (math "$end_time - $start_time")

    echo -e "\n\033[1;30m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e " \033[1;32m✨ REFRESH COMPLETE bestie! System's fresher than ever 🔥\033[0m   \033[1;37m⏱️  $elapsed sec   \033[1;36m$__rf_current/$__rf_total steps\033[0m"
    echo -e " \033[1;36m  USER: "(string upper "$USER")"\033[0m"

    functions -e __refresh_anim __refresh_section
    set -e __rf_frames __rf_total __rf_current
end
