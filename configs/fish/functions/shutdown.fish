# ══════════════════════════════════════════════════════════════
# shutdown — ﾉｼ(>_<)ﾉ  Power off the system with style
# Fedora MacTahoe eprahemi Edition © 2026
# github.com/eprahemi
# ══════════════════════════════════════════════════════════════
function shutdown --description 'ﾉｼ(>_<)ﾉ  Power off the system with style'
    # ── Colors ──
    set -l C  "\033[0m"
    set -l CY "\033[1;36m"
    set -l GR "\033[1;32m"
    set -l YE "\033[1;33m"
    set -l RE "\033[1;31m"
    set -l WH "\033[1;37m"
    set -l GY "\033[38;5;248m"
    set -l D  "\033[2m"
    set -l B  "\033[1m"

    # ── Check for the shutdown command ──
    if not command -v shutdown &>/dev/null
        echo -e "  $RE┌────────────────────────────────────────────────────────────┐$C"
        echo -e "  $RE│$C$(printf '%*s' 60 '')$RE│$C"
        echo -e "  $RE│$C     $WH✘  shutdown not found$C$(printf '%*s' 26 '')$RE│$C"
        echo -e "  $RE│$C$(printf '%*s' 60 '')$RE│$C"
        echo -e "  $RE└────────────────────────────────────────────────────────────┘$C"
        return 1
    end

    # ── Pass through -h / --help without confirmation ──
    if set -q argv[1]; and contains -- "$argv[1]" "-h" "--help"
        command shutdown $argv
        return $status
    end

    # ── Subcommand: "now" → treat as no-arg (shutdown immediately) ──
    if set -q argv[1]; and contains -- "$argv[1]" "now"
        set -e argv[1]
    end

    # ── Confirm ──
    echo -e ""
    echo -e "  $GY┌──────────────────────────────────────────────────────────────┐$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    set -l line1 "ﾉｼ(>_<)ﾉ   —   Shut down, $USER?"
    echo -e "  $GY│$C    $WH$line1$C$(printf '%*s' (math "58 - "(string length -- "$line1")) '')$GY│$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY│$C    $D ──────────────────────────────────────────────────────$C $GY│$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY│$C      $D This will power off the system. All$C$GY                │$C"
    echo -e "  $GY│$C      $D running applications will be$C$GY                       │$C"
    echo -e "  $GY│$C      $D terminated.$C$GY                                        │$C"
    if set -q argv[1]
        echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
        set -l arg_line "Args: $argv"
        echo -e "  $GY│$C      $GY$arg_line$C$(printf '%*s' (math "58 - "(string length -- "$arg_line")) '')$GY│$C"
    end
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY│$C    $D ──────────────────────────────────────────────────────$C $GY│$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY│$C       $GR ❮$C $WH Y $C$GR ❯$C  $D Yes, shut down$C   $RE ❮$C $WH N $C$RE ❯$C  $D Cancel$C$GY       │$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY└──────────────────────────────────────────────────────────────┘$C"
    read -l -P '  ❯ ' answer
    if test "$answer" != "y"; and test "$answer" != "Y"
        echo -e "  $GY  ✧  Shutdown cancelled. Stay awhile.$C"
        return 0
    end

    # ── Bye bye ──
    echo -e ""
    echo -e "  $GY┌──────────────────────────────────────────────────────────────┐$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    set -l bye_line "✧  Shutting down,  $USER!"
    echo -e "  $GY│$C    $WH $bye_line$C$(printf '%*s' (math "58 - "(string length -- "$bye_line")) '')$GY│$C"
    echo -e "  $GY│$C    $D   ﾉｼ(>_<)ﾉ   Good night,  $USER$D!$C$GY                     │$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY└──────────────────────────────────────────────────────────────┘$C"
    echo -e ""

    sleep 1
    if set -q argv[1]
        sudo command shutdown $argv
    else
        sudo command shutdown now
    end
end
