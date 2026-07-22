# ══════════════════════════════════════════════════════════════
# logout — ﾉｼ(>_<)ﾉ  Kicks you out of the GNOME session
# Fedora MacTahoe eprahemi Edition © 2026
# github.com/eprahemi
# ══════════════════════════════════════════════════════════════
function logout --description '(ﾉｼ>_<)ﾉ  Kicks you out of the login screen — bye bye!'
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

    # ── Check for the logout command ──
    if not command -v gnome-session-quit &>/dev/null
        echo -e "  $RE┌────────────────────────────────────────────────────────────┐$C"
        echo -e "  $RE│$C$(printf '%*s' 60 '')$RE│$C"
        echo -e "  $RE│$C     $WH✘  gnome-session-quit not found$C$(printf '%*s' 22 '')$RE│$C"
        echo -e "  $RE│$C     $D  Are you even on GNOME?$C$(printf '%*s' 28 '')$RE│$C"
        echo -e "  $RE│$C$(printf '%*s' 60 '')$RE│$C"
        echo -e "  $RE└────────────────────────────────────────────────────────────┘$C"
        return 1
    end

    # ── Confirm ──
    echo -e ""
    echo -e "  $GY┌──────────────────────────────────────────────────────────────┐$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    set -l line1 " ﾉｼ(>_<)ﾉ   —   Farewell, $USER?"
    echo -e "  $GY│$C    $WH$line1$C$(printf '%*s' (math "58 - "(string length -- "$line1")) '')$GY│$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY│$C    $D ──────────────────────────────────────────────────────$C $GY│$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY│$C      $D This will end your session and return$C$GY              │$C"
    echo -e "  $GY│$C      $D to the GDM login screen. All running$C$GY               │$C"
    echo -e "  $GY│$C      $D applications will be terminated.$C$GY                   │$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY│$C    $D ──────────────────────────────────────────────────────$C $GY│$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY│$C       $GR ❮$C $WH Y $C$GR ❯$C  $D Yes, log out$C   $RE ❮$C $WH N $C$RE ❯$C  $D Cancel$C$GY           │$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    echo -e "  $GY└──────────────────────────────────────────────────────────────┘$C"
    read -l -P '  ❯ ' answer
    if test $status -ne 0
        echo -e "  $GY  ✧  Cancelled.$C"
        return 0
    end
    if test "$answer" != "y"; and test "$answer" != "Y"
        echo -e "  $GY  ✧  Stay a little longer then.$C"
        return 0
    end

    # ── Bye bye ──
    echo -e ""
    echo -e "  $GY┌──────────────────────────────────────────────────────────────┐$C"
    echo -e "  $GY│$C$(printf '%*s' 62 '')$GY│$C"
    set -l bye_line "✧  Sayonara,  $USER!"
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
    gnome-session-quit --logout
end
