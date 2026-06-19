function clean --description 'DNF + pip cleanup. Flags: --all, --pip, --dry-run'
    if set -q argv[1]
        switch $argv[1]
            case --pip -p
                if command -v pip &>/dev/null
                    echo -e "  \033[1;37m⏳ Purging pip cache like it's nobody's biz...\033[0m"
                    pip cache purge 2>/dev/null
                    echo -e "  \033[1;32m✅ pip cache cleared bestie! ✨\033[0m"
                else
                    echo -e "  \033[1;31m❌ pip not installed bestie, nothing to purge 💅\033[0m"
                end
                return 0

            case --all -a
                echo -e "\033[1;36m"
                echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
                echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
                echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
                echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
                echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
                echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
                echo -e "  \033[1;34m── FULL SYSTEM CLEAN ──\033[0m\n"
                echo -e "  \033[1;33m🔥 Time to nuke this machine (but in a cute way)...\033[0m\n"
                echo -n "  \033[1;37m⏳ DNF clean all...\033[0m "
                sudo dnf clean all 2>/dev/null
                echo -e "\033[1;32m✅\033[0m"
                echo -n "  \033[1;37m⏳ DNF autoremove...\033[0m "
                sudo dnf autoremove -y 2>/dev/null
                echo -e "\033[1;32m✅\033[0m"
                if command -v pip &>/dev/null
                    echo -n "  \033[1;37m⏳ Pip cache purge...\033[0m "
                    pip cache purge 2>/dev/null
                    echo -e "\033[1;32m✅\033[0m"
                end
                if command -v flatpak &>/dev/null
                    echo -n "  \033[1;37m⏳ Flatpak unused...\033[0m "
                    flatpak uninstall --unused -y 2>/dev/null
                    echo -e "\033[1;32m✅\033[0m"
                end
                echo -e "\n  \033[1;32m✨ Deep clean complete bestie! System's fresher than a TikTok transition 🔥\033[0m"
                return 0

            case --dry-run -n
                echo -e "\033[1;36m"
                echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
                echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
                echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
                echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
                echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
                echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
                echo -e "  \033[1;33m── DRY RUN (we're just fantasizing bestie) ──\033[0m"
                echo -e "  \033[1;33mWould run:\033[0m"
                echo -e "    \033[1;36msudo dnf clean all\033[0m"
                echo -e "    \033[1;36msudo dnf autoremove -y\033[0m"
                echo -e "    \033[1;36mpip cache purge\033[0m"
                echo -e "    \033[1;36mflatpak uninstall --unused -y\033[0m"
                echo -e "  \033[1;33mRun \033[1;36mclean --all\033[1;33m to send it bestie 🔥\033[0m"
                return 0

            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mclean [flags]\033[0m"
                echo -e "  \033[38;5;248m  --all, -a      Full DNF cleanup + pip + autoremove\033[0m"
                echo -e "  \033[38;5;248m  --pip, -p      Purge pip cache only\033[0m"
                echo -e "  \033[38;5;248m  --dry-run      Preview what would be cleaned\033[0m"
                echo -e "  \033[38;5;248m  --help, -h     Show this help\033[0m"
                return 0
            case '-*'
                echo -e "\033[1;33m📖 Read the manual dummy: \033[1;36mclean --help\033[0m"
                return 1
        end
    end

    # Default: standard DNF cleanup
    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"

    echo -e "\033[1;33m🧹 Time to sweep bestie...\033[0m\n"
    sudo dnf clean all && sudo dnf autoremove -y
end
