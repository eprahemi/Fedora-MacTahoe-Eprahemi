# ══════════════════════════════════════════════════════════════
# refresh 🔄 — Deep system refresh utility
# Cleans caches, restarts services, flushes DNS, and rebuilds desktop grids
# Fedora MacTahoe Eprahemi Edition © 2026 — refreshed & blessed
# ══════════════════════════════════════════════════════════════
function refresh --description 'Deep system refresh: cache, services, extensions, DNS, desktop grid & more'
    set -l start_time (date +%s)
    set -l do_all 0
    set -l do_cache 0
    set -l do_services 0
    set -l do_extensions 0
    set -l do_dns 0
    set -l do_dnf 0
    set -l do_flatpak 0
    set -l do_pip 0
    set -l do_desktop 0
    set -l do_icons 0

    if test (count $argv) -eq 0
        echo -e "\033[1;36m"
        echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
        echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
        echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
        echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
        echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
        echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
        echo -e "\033[1;36m╔══════════════════════════════════════════════════════════╗\033[0m"
        echo -e "\033[1;36m║           \033[1;33mREFRESH FLAGS - USAGE GUIDE\033[1;36m                  ║\033[0m"
        echo -e "\033[1;36m╚══════════════════════════════════════════════════════════╝\033[0m"
        echo -e "  \033[1;37mrefresh\033[0m                    — show this help menu"
        echo -e "  \033[1;37mrefresh --all\033[0m \033[38;5;245m(-a)\033[0m           — full safe refresh (all below)"
        echo -e "  \033[1;37mrefresh --cache\033[0m \033[38;5;245m(-c)\033[0m         — thumbnail, gnome-software, PackageKit caches"
        echo -e "  \033[1;37mrefresh --services\033[0m \033[38;5;245m(-s)\033[0m       — restart Nautilus + xdg-desktop-portal"
        echo -e "  \033[1;37mrefresh --extensions\033[0m \033[38;5;245m(-e)\033[0m     — cycle Dash-to-Dock extension"
        echo -e "  \033[1;37mrefresh --dns\033[0m \033[38;5;245m(-d)\033[0m           — flush DNS resolver cache"
        echo -e "  \033[1;37mrefresh --desktop\033[0m \033[38;5;245m(-k)\033[0m        — refresh desktop app grid, icons, names"
        echo -e "  \033[1;37mrefresh --icons\033[0m \033[38;5;245m(-i)\033[0m          — mirror unresolvable app icons (512×512 fix)"
        echo -e "  \033[1;37mrefresh --dnf\033[0m \033[38;5;245m(-dnf)\033[0m          — dnf clean all & autoremove"
        echo -e "  \033[1;37mrefresh --flatpak\033[0m \033[38;5;245m(-fp)\033[0m       — flatpak uninstall --unused"
        echo -e "  \033[1;37mrefresh --pip\033[0m \033[38;5;245m(-pip)\033[0m          — pip cache purge"
        echo -e "  \033[38;5;248m📦 Desktop refresh, D-Bus app grid, icon cache rebuild (Jun 2026)\033[0m"
        return 0
    else
        for arg in $argv
            switch $arg
                case -a --all all;                   set do_all 1
                case -c --cache cache;               set do_cache 1
                case -s --services services;         set do_services 1
                case -e --extensions extensions;     set do_extensions 1
                case -d --dns dns;                   set do_dns 1
                case -dnf --dnf dnf;                 set do_dnf 1
                case -fp --flatpak flatpak;          set do_flatpak 1
                case -pip --pip pip;                 set do_pip 1
                case -k --desktop desktop;           set do_desktop 1
                case -i --icons icons;               set do_icons 1
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
                    echo -e "  \033[1;37mrefresh\033[0m                    — show this help menu"
                    echo -e "  \033[1;37mrefresh --all\033[0m \033[38;5;245m(-a)\033[0m           — full safe refresh (all below)"
                    echo -e "  \033[1;37mrefresh --cache\033[0m \033[38;5;245m(-c)\033[0m         — thumbnail, gnome-software, PackageKit caches"
                    echo -e "  \033[1;37mrefresh --services\033[0m \033[38;5;245m(-s)\033[0m       — restart Nautilus + xdg-desktop-portal"
                    echo -e "  \033[1;37mrefresh --extensions\033[0m \033[38;5;245m(-e)\033[0m     — cycle Dash-to-Dock extension"
                    echo -e "  \033[1;37mrefresh --dns\033[0m \033[38;5;245m(-d)\033[0m           — flush DNS resolver cache"
                    echo -e "  \033[1;37mrefresh --desktop\033[0m \033[38;5;245m(-k)\033[0m        — refresh desktop app grid, icons, names"
                    echo -e "  \033[1;37mrefresh --icons\033[0m \033[38;5;245m(-i)\033[0m          — mirror unresolvable app icons (512×512 fix)"
                    echo -e "  \033[1;37mrefresh --dnf\033[0m \033[38;5;245m(-dnf)\033[0m          — dnf clean all & autoremove"
                    echo -e "  \033[1;37mrefresh --flatpak\033[0m \033[38;5;245m(-fp)\033[0m       — flatpak uninstall --unused"
                    echo -e "  \033[1;37mrefresh --pip\033[0m \033[38;5;245m(-pip)\033[0m          — pip cache purge"
                    echo -e "  \033[38;5;248m📦 Desktop refresh, D-Bus app grid, icon cache rebuild (Jun 2026)\033[0m"
                    return 0
                case '*'
                    echo -e "\033[1;31m✘ Unknown option: '\033[1;33m$arg\033[1;31m'\033[0m"
                    echo -e "   \033[1;33mUse \033[1;36mrefresh --help\033[1;33m for available options 📖\033[0m"
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
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
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
        set do_desktop 1
        set do_icons 1
        echo -e "  \033[1;34mMode: FULL SYSTEM REFRESH (full system)\033[0m\n"
    else
        echo -e "  \033[1;34mMode: SELECTIVE CLEANUP\033[0m\n"
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
    if test $do_desktop -eq 1;  set __rf_total (math $__rf_total + 8); end
    if test $do_icons -eq 1;    set __rf_total (math $__rf_total + 1); end

    function __refresh_anim
        set -l label $argv[1]
        set -l cmd $argv[2]
        set __rf_current (math $__rf_current + 1)

        # Temp files for stderr and exit code
        set -l errfile (mktemp -t refresh-err-XXXXXXXXXX 2>/dev/null)
        set -l exitfile (mktemp -t refresh-exit-XXXXXXXXXX 2>/dev/null)

        # Start command in background; write exit code to exitfile when done
        sh -c "($cmd) 2>\"$errfile\"; echo \$? > \"$exitfile\"" &
        set -l pid $last_pid

        # Spinner while command is running
        set -l i 1
        while kill -0 $pid 2>/dev/null
            printf "\r  \033[1;37m⏳ \033[1;36m%s\033[1;37m... \033[1;33m%s  \033[1;31m[%d/%d]\033[0m" "$label" $__rf_frames[$i] $__rf_current $__rf_total
            set i (math $i % 10 + 1)
            sleep 0.06
        end
        wait $pid 2>/dev/null

        # Read exit code from file
        set -l exit_code 1
        if test -f "$exitfile" -a -s "$exitfile"
            set exit_code (cat "$exitfile" 2>/dev/null)
        end

        if test "$exit_code" = "0"
            printf "\r  \033[1;37m⏳ \033[1;36m%s\033[1;37m... \033[1;32m✅  \033[1;31m[%d/%d]\033[0m\n" "$label" $__rf_current $__rf_total
        else
            printf "\r  \033[1;37m⏳ \033[1;36m%s\033[1;37m... \033[1;31m❌  \033[1;31m[%d/%d]\033[0m\n" "$label" $__rf_current $__rf_total
            # Show first 3 lines of stderr in red
            if test -s "$errfile"
                for line in (head -3 "$errfile" 2>/dev/null)
                    echo -e "  \033[1;31m✘ $line\033[0m"
                end
            end
            if test (wc -l <"$errfile" 2>/dev/null) -gt 3
                echo -e "  \033[38;5;244m  (... and more — check the command output)\033[0m"
            end
        end

        rm -f "$errfile" "$exitfile" 2>/dev/null
    end

    function __refresh_section
        set -l name $argv[1]
        echo -e "  \033[1;34m── \033[1;37m$name\033[1;34m ──\033[0m"
    end

    # ── Cache sudo credentials upfront if any task needs root ──
    if test $do_all -eq 1 -o $do_dnf -eq 1 -o $do_desktop -eq 1
        # Skip password prompt if sudo is already passwordless
        sudo -n true 2>/dev/null
        if test $status -eq 0
            # Passwordless sudo — just proceed
        else
            set -l __cc 0
            while true
                echo -e "  \033[1;33m🔑 Sudo needed for some tasks — enter password once...\033[0m"
                sudo -v 2>/dev/null
                if test $status -ne 0
                    set __cc (math $__cc + 1)
                    if test $__cc -ge 2
                        echo -e "  \033[1;31m✘ Cancelled.\033[0m"
                        return 1
                    end
                    echo -e "  \033[1;33m⚠  (Ctrl+C again to cancel)\033[0m"
                    continue
                end
                break
            end
            echo -e "  \033[1;32m✅ Sudo cached — proceeding\033[0m\n"
        end
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
        __refresh_anim "DNF clean all"  "sudo -n dnf clean all 2>/dev/null"
        __refresh_anim "DNF autoremove" "sudo -n dnf autoremove -y 2>/dev/null"
    end

    if test $do_flatpak -eq 1
        __refresh_section "FLATPAK CLEANUP"
        __refresh_anim "Unused runtimes" "flatpak uninstall --unused -y 2>/dev/null"
    end

    if test $do_icons -eq 1
        __refresh_section "ICON MIRROR"
        # Inline bash (run via sh -c inside __refresh_anim)
        __refresh_anim "Mirror 512×512 icons" '
            uh=$HOME/.local/share/icons/hicolor;
            u48=$uh/48x48/apps;
            mkdir -p "$u48";
            if [ ! -f "$uh/index.theme" ]; then
                mkdir -p "$uh";
                printf "[Icon Theme]\nName=Hicolor\nComment=Local overrides\nHidden=true\nDirectories=256x256/apps,48x48/apps\n\n[48x48/apps]\nSize=48\nContext=Applications\nType=Fixed\n" > "$uh/index.theme";
            fi;
            for base in /var/lib/flatpak/exports/share/icons/hicolor \
                        "$HOME/.local/share/icons/hicolor" \
                        /usr/share/icons/hicolor; do
                [ -d "$base" ] || continue;
                find "$base" -path "*/apps/*" \( -name "*.png" -o -name "*.svg" \) 2>/dev/null | while IFS= read -r f; do
                    name=$(basename "$f");
                    noext="${name%.*}";
                    [ -f "$HOME/.local/share/icons/MacTahoe-dark/$name" ] || [ -f "$HOME/.local/share/icons/MacTahoe-dark/${noext}.svg" ] && continue;
                    [ -f "$uh/48x48/apps/$name" ] || [ -f "$uh/scalable/apps/${noext}.svg" ] && continue;
                    ext="${name##*.}";
                    if [ "$ext" = "svg" ]; then
                        mkdir -p "$uh/scalable/apps";
                        ln -sf "$f" "$uh/scalable/apps/$name" 2>/dev/null || cp -f "$f" "$uh/scalable/apps/$name" 2>/dev/null;
                    else
                        best="";
                        for sz in 48x48 64x64 128x128 256x256 512x512; do
                            if [ -f "$base/$sz/apps/$name" ]; then best="$base/$sz/apps/$name"; break; fi;
                        done;
                        [ -n "$best" ] || continue;
                        ln -sf "$best" "$u48/$name" 2>/dev/null || cp -f "$best" "$u48/$name" 2>/dev/null;
                    fi;
                done;
            done;
            gtk-update-icon-cache "$uh/" 2>/dev/null;
        '
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
        __refresh_anim "Restart Nautilus"        "nautilus -q 2>/dev/null; true"
        __refresh_anim "Kill portal daemon"     "killall xdg-desktop-portal 2>/dev/null; true"
        __refresh_anim "Restart portal daemon"  "nohup /usr/libexec/xdg-desktop-portal >/dev/null 2>&1 &"
        __refresh_anim "GPU display buffer"     "busctl call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Main.layoutManager._updateHotCorners();' 2>/dev/null; true"
    end

    if test $do_extensions -eq 1
        __refresh_section "EXTENSIONS"
        __refresh_anim "Disable Dash-to-Dock" "gnome-extensions disable dash-to-dock@micxgx.gmail.com 2>/dev/null; true"
        sleep 0.3
        __refresh_anim "Enable Dash-to-Dock"  "gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null; true"
        sleep 0.3
        __refresh_anim "Disable User Themes"  "gnome-extensions disable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null; true"
        sleep 0.3
        __refresh_anim "Enable User Themes"   "gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null; true"
    end

    if test $do_desktop -eq 1
        __refresh_section "DESKTOP / APP GRID"
        set -l icon_theme (gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | string trim -c "'")
        set -l gtk_theme (gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | string trim -c "'")
        set -l cursor_theme (gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | string trim -c "'")

        # ── Rebuild icon cache for the current icon theme ──
        for theme_dir in /usr/share/icons/$icon_theme ~/.local/share/icons/$icon_theme ~/.icons/$icon_theme
            if test -d "$theme_dir"
                __refresh_anim "Icon cache ($icon_theme)" "gtk-update-icon-cache -f '$theme_dir' 2>/dev/null"
                break
            end
        end

        # ── Update desktop file database (makes app grid pick up name/icon changes) ──
        __refresh_anim "User desktop db" "update-desktop-database ~/.local/share/applications/ 2>/dev/null; true"
        if test -d /usr/share/applications/
            __refresh_anim "System desktop db" "sudo -n update-desktop-database /usr/share/applications/ 2>/dev/null; true"
        end

        # ── Re-apply themes to force runtime reload ──
        __refresh_anim "Re-apply icon theme" "gsettings set org.gnome.desktop.interface icon-theme '$icon_theme' 2>/dev/null"
        __refresh_anim "Re-apply cursor theme" "gsettings set org.gnome.desktop.interface cursor-theme '$cursor_theme' 2>/dev/null"
        if test -n "$gtk_theme"
            __refresh_anim "Re-apply GTK theme" "gsettings set org.gnome.desktop.interface gtk-theme '$gtk_theme' 2>/dev/null"
        end

        # ── Refresh the app grid via D-Bus (safe — no shell restart) ──
        __refresh_anim "Refresh app grid" "busctl call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Main.overview._dash._iconGrid.redisplay(); Main.overview._appDisplay._grid._redisplay()' 2>/dev/null; true"

        # ── Wallpaper flash: black → restore (clears wallpaper cache) ──
        __refresh_anim "Flash wallpaper" '
            user=$(whoami);
            black="/tmp/refresh-black-$user.png";
            [ -f "$black" ] || magick -size 1x1 xc:black "$black" 2>/dev/null;
            wp_light=$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null);
            wp_dark=$(gsettings get org.gnome.desktop.background picture-uri-dark 2>/dev/null);
            gsettings set org.gnome.desktop.background picture-uri "'"'"'file://$black'"'"'";
            [ -n "$wp_dark" ] && gsettings set org.gnome.desktop.background picture-uri-dark "'"'"'file://$black'"'"'";
            sleep 2;
            rm -f ~/.cache/gnome-shell/background.properties ~/.cache/gnome-shell/background-* 2>/dev/null;
            gsettings set org.gnome.desktop.background picture-uri "$wp_light";
            [ -n "$wp_dark" ] && gsettings set org.gnome.desktop.background picture-uri-dark "$wp_dark";
            rm -f "$black"
        '
        echo -e "  \033[1;33m💡 Tip: If icons don't update fully, press Alt+F2 then type \033[1;36mr\033[1;33m and press Enter — safe shell reload without logout\033[0m"
    end

    set -l end_time (date +%s)
    set -l elapsed (math "$end_time - $start_time")

    echo -e "\n\033[1;30m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e " \033[1;32m✨ REFRESH COMPLETE\033[0m   \033[1;37m⏱️  $elapsed sec   \033[1;36m$__rf_current/$__rf_total steps\033[0m"
    echo -e " \033[1;36m  USER: "(string upper "$USER")"\033[0m"

    functions -e __refresh_anim __refresh_section
    set -e __rf_frames __rf_total __rf_current
end
