# ══════════════════════════════════════════════════════════════
# passwd — Toggle passwordless sudo for the current user
# Finds the "username ALL=(ALL) NOPASSWD: ALL" line in
# /etc/sudoers and comments/uncomments it, or creates it.
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
        set -l d2 "    Add or uncomment NOPASSWD line for the current user"
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

    # ════════════════════════════════════════════════════════════════
    #  READ-ONLY PATH — status / no-args
    #  Tries sudo -n first (no prompt if creds cached).  If that fails,
    #  shows a hint instead of prompting — avoids unnecessary sudo auth
    #  for a read-only check.
    # ════════════════════════════════════════════════════════════════
    if test (count $argv) -eq 0 -o "$argv[1]" = "status"
        # ─── Check if sudo credentials are cached (no prompt) ───
        if not sudo -n true 2>/dev/null
            echo -e "\n  $YE⚠️   Cannot check status without authentication.$C"
            echo -e "  $D    Run $CY$B'passwd enable'$C$D first to authenticate and enable, or$C"
            echo -e "  $D    use $CY$B'sudo -v'$C$D to cache credentials then $CY$B'passwd status'$C$D.$C\n"
            return 0
        end

        # ─── Regex fragments (separate variables to avoid Fish parsing $user[...]) ───
        set -l rx_gap_s "[[:space:]]+ALL=\(ALL\)[[:space:]]+NOPASSWD:[[:space:]]+ALL"
        set -l rx_uc_s "^[[:space:]]*$user$rx_gap_s"
        set -l rx_cm_s "^[[:space:]]*#[[:space:]]*$user$rx_gap_s"

        # ─── Detect current state (sudo -n = no prompt since we verified above) ───
        set -l ro_uncommented 0
        set -l ro_commented 0
        if sudo -n grep -Eqs "$rx_uc_s" "$sudoers" 2>/dev/null
            set ro_uncommented 1
        end
        if sudo -n grep -Eqs "$rx_cm_s" "$sudoers" 2>/dev/null
            set ro_commented 1
        end

        # ─── Build & show status box ───
        set -l ro_line_info (sudo -n grep -nE "^\s*#*\s*$user\s+ALL=\(ALL\)\s+NOPASSWD:\s+ALL" "$sudoers" 2>/dev/null | head -1)
        set -l ro_ln_num ""
        set -l ro_ln_text ""
        if test -n "$ro_line_info"
            set -l parts (string split -n ":" -- "$ro_line_info")
            set ro_ln_num $parts[1]
            set ro_ln_text (string sub -s (math (string length "$ro_ln_num") + 2) "$ro_line_info")
        end
        if test (string length -- "$ro_ln_text") -gt 52
            set ro_ln_text (string sub -l 52 "$ro_ln_text")"…"
        end

        set -l title_suffix (string upper "$user")
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
        if test "$ro_uncommented" -eq 1
            set -l state_line "✅  STATE:  $B Enabled   (NOPASSWD is active)"
            set -l state_len (string length -- "$state_line")
            echo -e "  $CY║$C    $D│$C  $GR$state_line$C$(printf '%*s' (math "55 - $state_len") '')$D│$C  $CY║$C"
        else if test "$ro_commented" -eq 1
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
        if test -n "$ro_ln_num" -a -n "$ro_ln_text"
            set -l match_line "🔍  MATCH     Line $ro_ln_num:  $ro_ln_text"
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

        # ─── Prompt to add if missing ───
        if test "$ro_uncommented" -eq 0 -a "$ro_commented" -eq 0
            echo -n "  $YE⚠️   No NOPASSWD line found for $CY$B$user$C$YE.  Add one?$C $D[$C$GR Y$C$D/$C$RE n$C$D]$C "
            set -l answer (string lower (read -l -n 1 ans; echo "$ans"))
            if test "$answer" = "y" -o "$answer" = ""
                # ─── Add new NOPASSWD line ───
                set -l bak_file /tmp/sudoers.bak
                echo -e "  $D📝  Adding NOPASSWD line for $CY$B$user$C$D ...$C"
                sudo cp "$sudoers" "$bak_file"
                echo "$user ALL=(ALL) NOPASSWD: ALL" | sudo tee -a "$sudoers" >/dev/null 2>&1
                if sudo visudo -c -f "$sudoers" &>/dev/null
                    sudo rm -f "$bak_file"
                    echo -e "  $GR✅  Passwordless sudo enabled for $CY$B$user$C\n"
                else
                    sudo cp "$bak_file" "$sudoers"
                    sudo rm -f "$bak_file"
                    echo -e "\n  $RE✘  visudo validation failed — change reverted.$C"
                    echo -e "  $D    The sudoers file may have been corrupted. No changes applied.$C\n"
                    return 1
                end
            else
                echo ""
            end
        end
        return 0
    end

    # ════════════════════════════════════════════════════════════════
    #  WRITE PATH — enable / disable / toggle (prompts for sudo)
    # ════════════════════════════════════════════════════════════════

    # ─── Validate subcommand ───
    if test "$argv[1]" != "enable" -a "$argv[1]" != "disable" -a "$argv[1]" != "toggle" \
       -a "$argv[1]" != "on" -a "$argv[1]" != "off"
        echo -e "\n  $RE✘  Unknown subcommand: $CY$B$argv[1]$C"
        echo -e "  $D    Usage: $CY$Bpasswd$C $D[on|off|enable|disable|toggle|status|--help]$C\n"
        return 1
    end

    # ─── Regex fragments (write path — uses normal sudo) ───
    set -l rx_gap "[[:space:]]+ALL=\(ALL\)[[:space:]]+NOPASSWD:[[:space:]]+ALL"
    set -l rx_user_uc "^[[:space:]]*$user$rx_gap"
    set -l rx_user_cm "^[[:space:]]*#[[:space:]]*$user$rx_gap"

    # ─── Detect current state (normal sudo — will prompt for password) ───
    set -l uncommented 0
    set -l commented 0
    if sudo grep -Eqs "$rx_user_uc" "$sudoers" 2>/dev/null
        set uncommented 1
    end
    if sudo grep -Eqs "$rx_user_cm" "$sudoers" 2>/dev/null
        set commented 1
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
        if test "$commented" -eq 1
            # Line exists but commented — uncomment it
            echo -e "\n  $D📝  Enabling passwordless sudo for $CY$B$user$C$D ...$C"
            sudo sed -ri "s/^[[:space:]]*#[[:space:]]*($user)/\1/" "$sudoers"
        else
            # Line doesn't exist at all — append a new one
            echo -e "\n  $D📝  Adding NOPASSWD line for $CY$B$user$C$D ...$C"
            echo "$user ALL=(ALL) NOPASSWD: ALL" | sudo tee -a "$sudoers" >/dev/null 2>&1
        end
    else
        if test "$uncommented" -eq 1
            # Line exists and is active — comment it out
            echo -e "\n  $D📝  Disabling passwordless sudo for $CY$B$user$C$D ...$C"
            set -l sed_gap "[[:space:]]+ALL=\(ALL\)[[:space:]]+NOPASSWD:[[:space:]]+ALL"
            sudo sed -ri "s/^[[:space:]]*$user$sed_gap/#&/" "$sudoers"
        else
            # Line doesn't exist at all — nothing to disable
            sudo rm -f "$bak_file"
            echo -e "\n  $YE⚠️   No NOPASSWD line found for $CY$B$user$C$YE — nothing to disable.$C\n"
            return 0
        end
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
