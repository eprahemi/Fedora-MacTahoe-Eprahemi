# ══════════════════════════════════════════════════════════════
# clean — EPRAHEMI INC. DNF, pip, Flatpak, logs & shell cleaner
# Clean temporary files and system caches
# Fedora MacTahoe Eprahemi Edition © 2026
# ══════════════════════════════════════════════════════════════
function clean --description 'DNF + pip + Flatpak cleanup. Flags: --all, --reset, --pip, --dry-run'
    set -l R "\e[1;31m"
    set -l G "\e[1;32m"
    set -l Y "\e[1;33m"
    set -l B "\e[1;34m"
    set -l C "\e[1;36m"
    set -l W "\e[1;37m"
    set -l D "\e[2;37m"
    set -l N "\e[0m"

    if set -q argv[1]
        switch $argv[1]
            case --pip -p pip
                if command -v pip &>/dev/null
                    printf "  $W⏳ Clearing pip cache...$N\n"
                    pip cache purge 2>/dev/null
                    printf "  $G✅ pip cache cleared$N\n"
                else
                    printf "  $R❌ pip not installed, nothing to purge$N\n"
                end
                return 0

            case --all -a all
                sudo -n true 2>/dev/null; or begin
                    printf "  $Y🔑 Sudo needed — enter password...$N\n"
                    sudo -v 2>/dev/null; or begin
                        printf "  $R✘ Cancelled.$N\n"
                        return 1
                    end
                end
                printf "$C\n"
                printf "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗\n"
                printf "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║\n"
                printf "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║\n"
                printf "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║\n"
                printf "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║\n"
                printf "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝$N\n"
                printf "  $B── FULL SYSTEM CLEAN + REFRESH ──$N\n\n"
                printf "  $YRunning everything...$N\n\n"
                printf "  $W⏳ DNF clean all...$N "
                sudo dnf clean all 2>/dev/null
                printf "$G✅$N\n"
                printf "  $W⏳ DNF autoremove...$N "
                sudo dnf autoremove -y 2>/dev/null
                printf "$G✅$N\n"
                if command -v pip &>/dev/null
                    printf "  $W⏳ Pip cache purge...$N "
                    pip cache purge 2>/dev/null
                    printf "$G✅$N\n"
                end
                if command -v flatpak &>/dev/null
                    printf "  $W⏳ Flatpak unused...$N "
                    flatpak uninstall --unused -y 2>/dev/null
                    printf "$G✅$N\n"
                end
                printf "  $W⏳ Clearing thumbnails...$N "
                find ~/.cache/thumbnails -type f -delete 2>/dev/null
                printf "$G✅$N\n"
                printf "  $W⏳ Vacuuming logs...$N "
                sudo journalctl --vacuum-time=1s 2>/dev/null
                printf "$G✅$N\n"
                printf "  $W⏳ Restarting GNOME Shell...$N "
                busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart_shell()' 2>/dev/null
                printf "$G✅$N\n"
                printf "\n  $G✨ Full clean + refresh complete$N\n"
                return 0

            case --reset -r reset
                sudo -n true 2>/dev/null; or begin
                    printf "  $Y🔑 Sudo needed — enter password...$N\n"
                    sudo -v 2>/dev/null; or begin
                        printf "  $R✘ Cancelled.$N\n"
                        return 1
                    end
                end
                printf "$C\n"
                printf "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗\n"
                printf "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║\n"
                printf "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║\n"
                printf "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║\n"
                printf "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║\n"
                printf "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝$N\n"
                printf "  $B── SAFE REFRESH (keeping logins) ──$N\n\n"

                printf "  $W⏳ Restarting GNOME Shell...$N "
                busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart_shell()' 2>/dev/null
                printf "$G✅$N\n"

                printf "  $W⏳ Clearing thumbnails...$N "
                find ~/.cache/thumbnails -type f -delete 2>/dev/null
                printf "$G✅$N\n"

                printf "  $W⏳ DNF clean all...$N "
                sudo dnf clean all 2>/dev/null
                printf "$G✅$N\n"

                printf "  $W⏳ Flatpak unused...$N "
                flatpak uninstall --unused -y 2>/dev/null
                printf "$G✅$N\n"

                printf "  $W⏳ Vacuuming logs...$N "
                sudo journalctl --vacuum-time=1s 2>/dev/null
                printf "$G✅$N\n"

                printf "\n  $G✨ Safe refresh complete$N\n"
                return 0

            case --dry-run -n
                printf "$C\n"
                printf "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗\n"
                printf "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║\n"
                printf "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║\n"
                printf "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║\n"
                printf "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║\n"
                printf "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝$N\n"
                printf "  $Y── DRY RUN (preview only) ──$N\n"
                printf "  $YWould run:$N\n"
                printf "    $Csudo dnf clean all$N\n"
                printf "    $Csudo dnf autoremove -y$N\n"
                printf "    $Cpip cache purge$N\n"
                printf "    $Cflatpak uninstall --unused -y$N\n"
                printf "    $Cfind ~/.cache/thumbnails -delete$N\n"
                printf "    $Csudo journalctl --vacuum-time=1s$N\n"
                printf "    $Cbusctl restart GNOME Shell$N\n"
                printf "  $YRun $Cclean --all$Y or $Cclean --reset$Y to proceed$N\n"
                return 0

            case --help -h
                printf "$YUsage: $Cclean [flags]$N\n"
                printf "  $D  --all, -a      Full DNF cleanup + pip + autoremove + refresh$N\n"
                printf "  $D  --reset, -r    Safe refresh: GNOME restart, thumbnails, logs$N\n"
                printf "  $D  --pip, -p      Purge pip cache only$N\n"
                printf "  $D  --dry-run      Preview what would be cleaned$N\n"
                printf "  $D  --help, -h     Show this help$N\n"
                printf "  $DVersion: July 2026$N\n"
                return 0

            case '-*'
                printf "  $R✘ Error: '$Y$argv[1]$R' is not a valid option$N\n"
                printf "  $D  Try $Cclean --help$D for details$N\n"
                return 1
        end
    end

    # Default: standard DNF cleanup
    sudo -n true 2>/dev/null; or begin
        printf "  $Y🔑 Sudo needed — enter password...$N\n"
        sudo -v 2>/dev/null; or begin
            printf "  $R✘ Cancelled.$N\n"
            return 1
        end
    end
    printf "$C\n"
    printf "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗\n"
    printf "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║\n"
    printf "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║\n"
    printf "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║\n"
    printf "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║\n"
    printf "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝$N\n"
    printf "  $YStarting cleanup...$N\n\n"
    sudo dnf clean all && sudo dnf autoremove -y
end
