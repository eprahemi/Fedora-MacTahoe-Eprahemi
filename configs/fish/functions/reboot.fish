# ══════════════════════════════════════════════════════════════
# reboot — ﾉｼ(>_<)ﾉ  Restart the system with style
# Fedora MacTahoe eprahemi Edition © 2026
# github.com/eprahemi
# ══════════════════════════════════════════════════════════════
function reboot --description 'ﾉｼ(>_<)ﾉ  Restart the system with style'
    # ── Colors ──
    set -l C  (printf "\e[0m")
    set -l CY (printf "\e[1;36m")
    set -l GR (printf "\e[1;32m")
    set -l YE (printf "\e[1;33m")
    set -l RE (printf "\e[1;31m")
    set -l WH (printf "\e[1;37m")
    set -l GY (printf "\e[38;5;248m")
    set -l D  (printf "\e[2m")
    set -l B  (printf "\e[1m")

    # ── Check for the reboot command ──
    if not command -v reboot &>/dev/null
        echo -e "  $RE┌────────────────────────────────────────────────────────────┐$C"
        echo -e "  $RE│$C$(printf '%*s' 60 '')$RE│$C"
        echo -e "  $RE│$C     $WH✘  reboot not found$C$(printf '%*s' 30 '')$RE│$C"
        echo -e "  $RE│$C$(printf '%*s' 60 '')$RE│$C"
        echo -e "  $RE└────────────────────────────────────────────────────────────┘$C"
        return 1
    end

    # ── Pass through -h / --help without confirmation ──
    if set -q argv[1]; and contains -- "$argv[1]" "-h" "--help"
        command reboot $argv
        return $status
    end

    # ── Subcommand: "now" → treat as no-arg (reboot immediately) ──
    set -l has_now 0
    if set -q argv[1]; and contains -- "$argv[1]" "now"
        set has_now 1
        set -e argv[1]
    end

    # ── Confirm ──
    echo -e ""
    echo -e "  $GY┌──────────────────────────────────────────────────────────────┐$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    set -l line1 "ﾉｼ(>_<)ﾉ   —   Restart, $USER?"
    echo -e "  $GY│$C    $WH$line1$C$(printf '%*s' (math "58 - "(string length -- "$line1")) '')$GY│$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY│$C    $D ──────────────────────────────────────────────────────$C $GY│$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY│$C      $D This will reboot the system. All running$C$GY            │$C"
    echo -e "  $GY│$C      $D applications will be terminated.$C$GY                   │$C"
    if set -q argv[1]
        echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
        set -l arg_line "Args: $argv"
        echo -e "  $GY│$C      $GY$arg_line$C$(printf '%*s' (math "58 - "(string length -- "$arg_line")) '')$GY│$C"
    end
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY│$C    $D ──────────────────────────────────────────────────────$C $GY│$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    if test $has_now -eq 1
        set -l ch "  ❮  $GR$B Y $C$GY ❯$C   $D Yes, reboot$C    ❮  $RE n $C$GY ❯$C   $D Cancel"
        echo -e "  $GY│$C      $ch$C$(printf '%*s' (math "60 - "(string length -- "$ch")) '')$GY│$C"
    else
        set -l ch "  ❮  $GR y $C$GY ❯$C   $D Yes, reboot$C    ❮  $RE$B N $C$GY ❯$C   $D Cancel"
        echo -e "  $GY│$C      $ch$C$(printf '%*s' (math "60 - "(string length -- "$ch")) '')$GY│$C"
    end
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY└──────────────────────────────────────────────────────────────┘$C"
    read -l -P '  ❯ ' answer
    if test $status -ne 0
        echo -e "  $GY  ✧  Cancelled.$C"
        return 0
    end
    if test $has_now -eq 1
        # Y is default — only n/N cancels
        if test "$answer" = "n"; or test "$answer" = "N"
            echo -e "  $GY  ✧  Reboot cancelled. Stay awhile.$C"
            return 0
        end
    else
        # N is default — only y/Y confirms
        if test "$answer" != "y"; and test "$answer" != "Y"
            echo -e "  $GY  ✧  Reboot cancelled. Stay awhile.$C"
            return 0
        end
    end

    # ── Bye bye ──
    echo -e ""
    echo -e "  $GY┌──────────────────────────────────────────────────────────────┐$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    set -l bye_line "✧  Rebooting,  $USER!"
    echo -e "  $GY│$C    $WH $bye_line$C$(printf '%*s' (math "58 - "(string length -- "$bye_line")) '')$GY│$C"
    echo -e "  $GY│$C    $D   ﾉｼ(>_<)ﾉ   See you on the other side$C$GY              │$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY└──────────────────────────────────────────────────────────────┘$C"
    echo -e ""

    sleep 1
    if test $status -ne 0
        echo -e "  $GY  ✧  Cancelled.$C"
        return 0
    end
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
    if set -q argv[1]
        sudo command reboot $argv
    else
        sudo command reboot
    end
end
