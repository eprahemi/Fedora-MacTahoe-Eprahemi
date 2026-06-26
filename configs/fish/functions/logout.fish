# ══════════════════════════════════════════════════════════════
# logout — ﾉｼ(>_<)ﾉ  Kicks you out of the GNOME session
# Fedora MacTahoe eprahemi Edition © 2026
# github.com/eprahemi
# ══════════════════════════════════════════════════════════════
function logout --description '(ﾉｼ>_<)ﾉ  Kicks you out of the login screen — bye bye!'
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
    echo -e "  $GY┌────────────────────────────────────────────────────┐$C"
    echo -e "  $GY│$C$(printf '%*s' 52 '')$GY│$C"
    echo -e "  $GY│$C     $WHﾉｼ(>_<)ﾉ  Kick you out of the login screen?$C$GY│$C"
    echo -e "  $GY│$C$(printf '%*s' 52 '')$GY│$C"
    echo -e "  $GY│$C     $D  Logout will terminate all running$C$GY           │$C"
    echo -e "  $GY│$C     $D  applications and return to GDM.$C$GY          │$C"
    echo -e "  $GY│$C$(printf '%*s' 52 '')$GY│$C"
    echo -e "  $GY└────────────────────────────────────────────────────┘$C"
    echo -e "  $CY  [y/N]$C $D  —  Say yes to disappear$C"
    read -l answer
    if test "$answer" != "y"; and test "$answer" != "Y"
        echo -e "  $GY  ✧  Stay a little longer then.$C"
        return 0
    end

    # ── Bye bye ──
    echo -e ""
    echo -e "  $GY┌────────────────────────────────────────────────────┐$C"
    echo -e "  $GY│$C$(printf '%*s' 52 '')$GY│$C"
    echo -e "  $GY│$C     $WH✧  Sayonara,  $CY$USER$WH!$C$GY                   │$C"
    echo -e "  $GY│$C     $D  (ﾉｼ>_<)ﾉ   See you on the other side$C$GY       │$C"
    echo -e "  $GY│$C$(printf '%*s' 52 '')$GY│$C"
    echo -e "  $GY└────────────────────────────────────────────────────┘$C"
    echo -e ""

    sleep 1
    gnome-session-quit --logout
end
