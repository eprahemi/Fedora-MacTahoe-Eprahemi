# ══════════════════════════════════════════════════════════════
# passwd — Toggle passwordless sudo for the current user
# Finds the "username ALL=(ALL) NOPASSWD: ALL" line in
# /etc/sudoers and comments/uncomments it.
# Fedora MacTahoe Eprahemi Edition © 2026
# ══════════════════════════════════════════════════════════════
function passwd --description 'Toggle passwordless sudo for the current user — usage: passwd [enable|disable|toggle|status|--help]'
    # ── Color palette ──
    set -l C  "\033[0m"
    set -l B  "\033[1m"
    set -l D  "\033[38;5;248m"
    set -l CY "\033[1;36m"
    set -l GR "\033[1;32m"
    set -l YE "\033[1;33m"
    set -l RE "\033[1;31m"
    set -l WH "\033[1;37m"
    set -l GY "\033[38;5;245m"

    set -l user (whoami)
    set -l sudoers /etc/sudoers

    # ─── Regex fragments (separate variables to avoid Fish parsing $user[...]) ───
    set -l rx_gap "[[:space:]]+ALL=\(ALL\)[[:space:]]+NOPASSWD:[[:space:]]+ALL"
    set -l rx_user_uc "^[[:space:]]*$user$rx_gap"
    set -l rx_user_cm "^[[:space:]]*#[[:space:]]*$user$rx_gap"

    # ─── Detect current state ───
    set -l uncommented 0
    set -l commented 0
    if sudo grep -Eqs "$rx_user_uc" "$sudoers" 2>/dev/null
        set uncommented 1
    end
    if sudo grep -Eqs "$rx_user_cm" "$sudoers" 2>/dev/null
        set commented 1
    end

    # ─── Status display helper ───
    function __pw_show_status --no-scope-shadowing
        set -l ln_num ""
        set -l ln_text ""
        set -l line_info (sudo grep -nE "^\s*#*\s*$user\s+ALL=\(ALL\)\s+NOPASSWD:\s+ALL" "$sudoers" 2>/dev/null | head -1)
        if test -n "$line_info"
            # Fish 3.x array indexing — first field is line number
            set -l parts (string split -n ":" -- "$line_info")
            set ln_num $parts[1]
            set ln_text (string sub -s (math (string length "$ln_num") + 2) "$line_info")
        end

        # Truncate line text if too long
        if test (string length -- "$ln_text") -gt 52
            set ln_text (string sub -l 52 "$ln_text")"…"
        end

        set -l ulen (string length -- "$user")
        set -l llen (string length -- "$ln_text")
        set -l nlen (string length -- "$ln_num")
        set -l title_suffix (string upper "$user")
        # Inner width is 62 chars (between the two ║)
        set -l IW 62

        echo -e "\n  $CY╔══════════════════════════════════════════════════════════════╗$C"
        echo -e "  $CY║$C$(printf '%*s' $IW '')$CY║$C"
        echo -e "  $CY║$C    $CY┌────────────────────────────────────────────────────┐$C    $CY║$C"
        set -l title "🛡️  PASSWORDLESS SUDO  —  $title_suffix"
        set -l title_len (string length -- "$title")
        set -l title_pad (math "56 - $title_len")
        echo -e "  $CY║$C    $CY│$C  $WH$title$C$(printf '%*s' $title_pad '')$CY│$C    $CY║$C"
        echo -e "  $CY║$C    $CY└────────────────────────────────────────────────────┘$C    $CY║$C"
        echo -e "  $CY║$C$(printf '%*s' $IW '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' $IW '')$CY║$C"

        # FILE line
        set -l fline "🖿  FILE     /etc/sudoers"
        set -l flen (string length -- "$fline")
        echo -e "  $CY║$C    $D┌─ $fline$C$(printf '%*s' (math "57 - $flen") '')$CY║$C"
        echo -e "  $CY║$C    $D│$C$(printf '%*s' 57 '')$CY║$C"

        # USER line
        set -l uline "👤  USER     $user"
        set -l uline_len (string length -- "$uline")
        echo -e "  $CY║$C    $D└─ $uline$C$(printf '%*s' (math "57 - $uline_len") '')$CY║$C"

        echo -e "  $CY║$C$(printf '%*s' $IW '')$CY║$C"

        # STATE box
        echo -e "  $CY║$C    $D┌────────────────────────────────────────────────────┐$C  $CY║$C"
        if test "$uncommented" -eq 1
            set -l state_line "✅  STATE:  $B Enabled   (NOPASSWD is active)"
            set -l state_len (string length -- "$state_line")
            echo -e "  $CY║$C    $D│$C  $GR$state_line$C$(printf '%*s' (math "55 - $state_len") '')$D│$C  $CY║$C"
        else if test "$commented" -eq 1
            set -l state_line "❌  STATE:  $B Disabled  (line is commented)"
            set -l state_len (string length -- "$state_line")
            echo -e "  $CY║$C    $D│$C  $RE$state_line$C$(printf '%*s' (math "55 - $state_len") '')$D│$C  $CY║$C"
        else
            set -l state_line "⚠️   STATE:  $B Missing   (no NOPASSWD line found)"
            set -l state_len (string length -- "$state_line")
            echo -e "  $CY║$C    $D│$C  $YE$state_line$C$(printf '%*s' (math "55 - $state_len") '')$D│$C  $CY║$C"
        end
        echo -e "  $CY║$C    $D└────────────────────────────────────────────────────┘$C  $CY║$C"
        echo -e "  $CY║$C$(printf '%*s' $IW '')$CY║$C"

        # MATCH line
        if test -n "$ln_num" -a -n "$ln_text"
            set -l match_line "🔍  MATCH     Line $ln_num:  $ln_text"
            set -l match_len (string length -- "$match_line")
            set -l match_pad (math "57 - $match_len")
            if test $match_pad -lt 0
                set match_pad 0
            end
            echo -e "  $CY║$C    $D┌─ $match_line$C$(printf '%*s' $match_pad '')$CY║$C"
        else
            echo -e "  $CY║$C    $D┌─ 🔍  MATCH     (no matching line in sudoers)$C$(printf '%*s' 8 '')$CY║$C"
        end
        echo -e "  $CY║$C    $D└────────────────────────────────────────────────────┘$C  $CY║$C"
        echo -e "  $CY║$C$(printf '%*s' $IW '')$CY║$C"

        # Footer branding
        set -l brand "eprahemi  •  github.com/eprahemi"
        set -l brand_len (string length -- "$brand")
        echo -e "  $CY║$C    $D$brand$C$(printf '%*s' (math "57 - $brand_len") '')$CY║$C"
        echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
        echo ""
    end

    # ─── Help ───
    if test "$argv[1]" = "--help" -o "$argv[1]" = "-h"
        echo -e ""
        echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l th1 "  🛡️  PASSWORDLESS SUDO"
        echo -e "  $CY║$C  $WH$th1$C$(printf '%*s' (math "60 - "(string length -- "$th1")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        if command -v figlet &>/dev/null
            set -l fig_lines (figlet -f small "eprahemi" | string split "\n")
            for fl in $fig_lines
                if test -n "$fl"
                    set -l fl_trim "$fl"
                    if test (string length -- "$fl_trim") -gt 58
                        set fl_trim (string sub -l 55 "$fl_trim")"..."
                    end
                    echo -e "  $CY║$C  $YE$fl_trim$C$(printf '%*s' (math "60 - "(string length -- "$fl_trim")) '')$CY║$C"
                else
                    echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                end
            end
        end
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l sh1 "  📋  USAGE"
        echo -e "  $CY║$C  $WH$sh1$C$(printf '%*s' (math "60 - "(string length -- "$sh1")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"

        set -l u1 "    passwd"
        echo -e "  $CY║$C  $CY$B$u1$C$(printf '%*s' (math "60 - "(string length -- "$u1")) '')$CY║$C"
        set -l d1 "    Show current passwordless sudo status"
        echo -e "  $CY║$C  $D$d1$C$(printf '%*s' (math "60 - "(string length -- "$d1")) '')$CY║$C"

        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l u2 "    passwd enable"
        echo -e "  $CY║$C  $CY$B$u2$C$(printf '%*s' (math "60 - "(string length -- "$u2")) '')$CY║$C"
        set -l d2 "    Uncomment NOPASSWD line for the current user"
        echo -e "  $CY║$C  $D$d2$C$(printf '%*s' (math "60 - "(string length -- "$d2")) '')$CY║$C"

        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l u3 "    passwd disable"
        echo -e "  $CY║$C  $CY$B$u3$C$(printf '%*s' (math "60 - "(string length -- "$u3")) '')$CY║$C"
        set -l d3 "    Comment out NOPASSWD line for the current user"
        echo -e "  $CY║$C  $D$d3$C$(printf '%*s' (math "60 - "(string length -- "$d3")) '')$CY║$C"

        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l u4 "    passwd toggle"
        echo -e "  $CY║$C  $CY$B$u4$C$(printf '%*s' (math "60 - "(string length -- "$u4")) '')$CY║$C"
        set -l d4 "    Toggle between enabled and disabled"
        echo -e "  $CY║$C  $D$d4$C$(printf '%*s' (math "60 - "(string length -- "$d4")) '')$CY║$C"

        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l u5 "    passwd status"
        echo -e "  $CY║$C  $CY$B$u5$C$(printf '%*s' (math "60 - "(string length -- "$u5")) '')$CY║$C"
        set -l d5 "    Show current passwordless sudo status"
        echo -e "  $CY║$C  $D$d5$C$(printf '%*s' (math "60 - "(string length -- "$d5")) '')$CY║$C"

        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l u6 "    passwd on / passwd off"
        echo -e "  $CY║$C  $CY$B$u6$C$(printf '%*s' (math "60 - "(string length -- "$u6")) '')$CY║$C"
        set -l d6 "    Shorthand for enable / disable"
        echo -e "  $CY║$C  $D$d6$C$(printf '%*s' (math "60 - "(string length -- "$d6")) '')$CY║$C"

        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY║$C  $D  eprahemi  •  github.com/eprahemi$(printf '%*s' (math "60 - 33") '')$CY║$C"
        echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
        echo ""
        return 0
    end

    # ─── No args / status ───
    if test (count $argv) -eq 0 -o "$argv[1]" = "status"
        __pw_show_status
        functions -e __pw_show_status
        return 0
    end

    # ─── Validate subcommand ───
    if test "$argv[1]" != "enable" -a "$argv[1]" != "disable" -a "$argv[1]" != "toggle" \
       -a "$argv[1]" != "on" -a "$argv[1]" != "off"
        echo -e "\n  $RE✘  Unknown subcommand: $CY$B$argv[1]$C"
        echo -e "  $D    Usage: $CY$Bpasswd$C $D[on|off|enable|disable|toggle|status|--help]$C\n"
        return 1
    end

    # ─── Resolve action ───
    set -l do_enable 0
    switch "$argv[1]"
        case enable on
            set do_enable 1
        case disable off
            set do_enable 0
        case toggle
            if test "$uncommented" -eq 1
                set do_enable 0
            else
                set do_enable 1
            end
    end

    # ─── Already in desired state? ───
    if test "$do_enable" -eq 1 -a "$uncommented" -eq 1
        echo -e "\n  $YE⚠️   Passwordless sudo is already enabled for $CY$B$user$C\n"
        return 0
    end
    if test "$do_enable" -eq 0 -a "$commented" -eq 1
        echo -e "\n  $YE⚠️   Passwordless sudo is already disabled for $CY$B$user$C\n"
        return 0
    end

    # ─── Perform edit ───
    set -l bak_file /tmp/sudoers.bak
    sudo cp "$sudoers" "$bak_file"

    if test "$do_enable" -eq 1
        echo -e "\n  $D📝  Enabling passwordless sudo for $CY$B$user$C ...$C"
        # Remove leading # and any whitespace between # and username
        # $user followed by ) is safe — no [ adjacency issue
        sudo sed -ri "s/^[[:space:]]*#[[:space:]]*($user)/\1/" "$sudoers"
    else
        echo -e "\n  $D📝  Disabling passwordless sudo for $CY$B$user$C ...$C"
        # Build pattern safely: $user enclosed in (...) so [ doesn't touch it
        # $sed_gap cannot touch $user (Fish array-index issue), and
        # we must capture the full username + rest to keep the line intact.
        # Use & (entire match) and a safe pattern without capturing beyond $user.
        set -l sed_gap "[[:space:]]+ALL=\(ALL\)[[:space:]]+NOPASSWD:[[:space:]]+ALL"
        sudo sed -ri "s/^[[:space:]]*$user$sed_gap/#&/" "$sudoers"
    end

    # ─── Validate with visudo ───
    if sudo visudo -c -f "$sudoers" &>/dev/null
        sudo rm -f "$bak_file"
        if test "$do_enable" -eq 1
            echo -e "  $GR✅  Passwordless sudo enabled for $CY$B$user$C\n"
        else
            echo -e "  $GR✅  Passwordless sudo disabled for $CY$B$user$C\n"
        end
    else
        sudo cp "$bak_file" "$sudoers"
        sudo rm -f "$bak_file"
        echo -e "\n  $RE✘  visudo validation failed — change reverted.$C"
        echo -e "  $D    The sudoers file may have been corrupted. No changes applied.$C\n"
        return 1
    end
end
