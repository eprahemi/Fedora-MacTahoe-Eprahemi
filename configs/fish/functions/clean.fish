# ══════════════════════════════════════════════════════════════
# clean — EPRAHEMI INC. 🏢 DNF and pip cache cleaner
# Clean temporary files and system caches
# Fedora MacTahoe Eprahemi Edition © 2026 — dust-free & lit
# ══════════════════════════════════════════════════════════════
function clean --description 'DNF + pip cleanup. Flags: --all, --pip, --dry-run'
    if set -q argv[1]
        switch $argv[1]
            case --pip -p
                if command -v pip &>/dev/null
                    echo -e "  \033[1;37m⏳ Clearing pip cache...\033[0m"
                    pip cache purge 2>/dev/null
                    echo -e "  \033[1;32m✅ pip cache cleared\033[0m"
                else
                    echo -e "  \033[1;31m❌ pip not installed, nothing to purge\033[0m"
                end
                return 0

            case --all -a
                # ── Sudo check (passwordless = skip, otherwise double Ctrl+C to cancel) ──
                if not sudo -n true 2>/dev/null
                    set -l __cc 0
                    while true
                        echo -e "  \033[1;33m🔑 Sudo needed — enter password once...\033[0m"
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
                end
                echo -e "\033[1;36m"
                echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
                echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
                echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
                echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
                echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
                echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
                echo -e "  \033[1;34m── FULL SYSTEM CLEAN ──\033[0m\n"
                echo -e "  \033[1;33mRunning full system cleanup...\033[0m\n"
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
                echo -e "\n  \033[1;32m✨ Deep clean complete\033[0m"
                return 0

            case --dry-run -n
                echo -e "\033[1;36m"
                echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
                echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
                echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
                echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
                echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
                echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
                echo -e "  \033[1;33m── DRY RUN (preview only) ──\033[0m"
                echo -e "  \033[1;33mWould run:\033[0m"
                echo -e "    \033[1;36msudo dnf clean all\033[0m"
                echo -e "    \033[1;36msudo dnf autoremove -y\033[0m"
                echo -e "    \033[1;36mpip cache purge\033[0m"
                echo -e "    \033[1;36mflatpak uninstall --unused -y\033[0m"
                echo -e "  \033[1;33mRun \033[1;36mclean --all\033[1;33m to proceed\033[0m"
                return 0

            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mclean [flags]\033[0m"
                echo -e "  \033[38;5;248m  --all, -a      Full DNF cleanup + pip + autoremove\033[0m"
                echo -e "  \033[38;5;248m  --pip, -p      Purge pip cache only\033[0m"
                echo -e "  \033[38;5;248m  --dry-run      Preview what would be cleaned\033[0m"
                echo -e "  \033[38;5;248m  --help, -h     Show this help\033[0m"
                echo -e "  \033[38;5;248mVersion: June 2026\033[0m"
                return 0
            case '-*'
                set -l cl_burns
                set cl_burns[1] "Error: '\\033[1;33m$argv[1]\\033[1;33m' is not a valid option"
                echo -e "\\033[1;31m✘ $cl_burns[1]\\033[0m"
                echo -e "  \\033[38;5;248m  Try \\033[1;36mclean --help\\033[38;5;248m for details 📋\\033[0m"
                return 1
        end
    end

    # Default: standard DNF cleanup
    # ── Sudo check (passwordless = skip, otherwise double Ctrl+C to cancel) ──
    if not sudo -n true 2>/dev/null
        set -l __cc 0
        while true
            echo -e "  \033[1;33m🔑 Sudo needed — enter password once...\033[0m"
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
    end
    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"

    echo -e "\033[1;33mStarting cleanup...\033[0m\n"
    sudo dnf clean all && sudo dnf autoremove -y
end
