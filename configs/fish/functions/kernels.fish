function kernels -d "List and clean up old Fedora kernels and GRUB entries"
    # ── Colors ──
    set -l R (set_color red)
    set -l G (set_color green)
    set -l Y (set_color yellow)
    set -l M (set_color magenta)
    set -l W (set_color white)
    set -l D (set_color brblack)
    set -l N (set_color normal)
    set -l BOLD (set_color --bold white)
    set -l BOLDG (set_color --bold green)
    set -l BOLDY (set_color --bold yellow)
    set -l BOLDR (set_color --bold red)
    set -l BOLDX (set_color --bold brblack)

    # ── Detect clean subcommand BEFORE argparse (argparse can't handle -clean/-cl) ──
    set -l want_clean 0
    if set -q argv[1]; and contains -- $argv[1] clean cl -clean --clean -cl --cl
        set want_clean 1
        set -e argv[1]
    end

    # ── Bare `kernels` (no command) → show help ──
    if test $want_clean -eq 0; and test (count $argv) -eq 0
        set argv -h
    end

    # ── Argparse ──
    argparse 'n/dry-run' 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        set -l blank (printf '%*s' 62 '')
        printf '\n'
        printf '  %s╔══════════════════════════════════════════════════════════╗%s\n' $BOLD $N
        set -l hdr "KERNELS — HELP"
        set -l hl (string length -- "$hdr")
        set -l hleft (math "(62 - $hl) / 2" | string replace -r '\..*' '')
        set -l hright (math "62 - $hl - $hleft")
        printf '  %s║%s%*s%s%s%s%*s%s║%s\n' $BOLD $N $hleft "" $BOLDG $hdr $N $hright "" $BOLD $N
        printf '  %s╠══════════════════════════════════════════════════════════╣%s\n' $BOLD $N
        printf '  %s║%s%s%s║%s\n' $BOLD $N $blank $BOLD $N

        # Tagline
        set -l txt "  Clean up old Fedora kernels and GRUB entries"
        set -l pad (math "62 - "(string length -- "$txt"))
        printf '  %s║%s%s%s%s%*s%s║%s\n' $BOLD $N $D $txt $N $pad "" $BOLD $N
        printf '  %s║%s%s%s║%s\n' $BOLD $N $blank $BOLD $N

        # Usage
        set -l txt "  USAGE:"
        set -l pad (math "62 - "(string length -- "$txt"))
        printf '  %s║%s%s%s%s%*s%s║%s\n' $BOLD $N $BOLDY $txt $N $pad "" $BOLD $N
        set -l txt "    kernels [COMMAND] [OPTIONS]"
        set -l pad (math "62 - "(string length -- "$txt"))
        printf '  %s║%s%s%s%s%*s%s║%s\n' $BOLD $N $W $txt $N $pad "" $BOLD $N
        printf '  %s║%s%s%s║%s\n' $BOLD $N $blank $BOLD $N

        # Commands
        set -l txt "  COMMANDS:"
        set -l pad (math "62 - "(string length -- "$txt"))
        printf '  %s║%s%s%s%s%*s%s║%s\n' $BOLD $N $BOLDG $txt $N $pad "" $BOLD $N
        set -l txt "    clean            Remove old kernels + GRUB entries"
        set -l pad (math "62 - "(string length -- "$txt"))
        printf '  %s║%s%s%s%s%*s%s║%s\n' $BOLD $N $W $txt $N $pad "" $BOLD $N
        set -l txt "    status           Show kernel state (read-only, no sudo)"
        set -l pad (math "62 - "(string length -- "$txt"))
        printf '  %s║%s%s%s%s%*s%s║%s\n' $BOLD $N $W $txt $N $pad "" $BOLD $N
        set -l txt "    (no args)        Show this help"
        set -l pad (math "62 - "(string length -- "$txt"))
        printf '  %s║%s%s%s%s%*s%s║%s\n' $BOLD $N $W $txt $N $pad "" $BOLD $N
        set -l txt "    clean aliases:   -clean --clean -cl --cl"
        set -l pad (math "62 - "(string length -- "$txt"))
        printf '  %s║%s%s%s%s%*s%s║%s\n' $BOLD $N $D $txt $N $pad "" $BOLD $N
        printf '  %s║%s%s%s║%s\n' $BOLD $N $blank $BOLD $N

        # Options
        set -l txt "  OPTIONS:"
        set -l pad (math "62 - "(string length -- "$txt"))
        printf '  %s║%s%s%s%s%*s%s║%s\n' $BOLD $N $BOLDG $txt $N $pad "" $BOLD $N
        set -l txt "    -n, --dry-run    Preview cleanup without changes"
        set -l pad (math "62 - "(string length -- "$txt"))
        printf '  %s║%s%s%s%s%*s%s║%s\n' $BOLD $N $W $txt $N $pad "" $BOLD $N
        set -l txt "    -h, --help       Show this help"
        set -l pad (math "62 - "(string length -- "$txt"))
        printf '  %s║%s%s%s%s%*s%s║%s\n' $BOLD $N $W $txt $N $pad "" $BOLD $N
        printf '  %s║%s%s%s║%s\n' $BOLD $N $blank $BOLD $N

        # Safety
        set -l txt "  SAFETY:"
        set -l pad (math "62 - "(string length -- "$txt"))
        printf '  %s║%s%s%s%s%*s%s║%s\n' $BOLD $N $BOLDG $txt $N $pad "" $BOLD $N
        set -l safetxt \
            "    • Running kernel is always protected" \
            "    • Rescue kernels are always protected" \
            "    • Latest kernel is always kept" \
            "    • Double confirmation before any changes" \
            "    • Reboot prompt if not on latest kernel" \
            "    • GRUB indices validated before removal"
        for st in $safetxt
            set -l pad (math "62 - "(string length -- "$st"))
            printf '  %s║%s%s%s%s%*s%s║%s\n' $BOLD $N $D $st $N $pad "" $BOLD $N
        end
        printf '  %s║%s%s%s║%s\n' $BOLD $N $blank $BOLD $N

        # Footer
        set -l txt "  Tip: type kernel and get corrected to kernels"
        set -l pad (math "62 - "(string length -- "$txt"))
        printf '  %s║%s%s%s%s%*s%s║%s\n' $BOLD $N $D $txt $N $pad "" $BOLD $N
        printf '  %s╚══════════════════════════════════════════════════════════╝%s\n' $BOLD $N
        printf '\n'
        return 0
    end

    # ══════════════════════════════════════════════════════════
    # STATUS subcommand — read-only kernel state, no sudo
    # ══════════════════════════════════════════════════════════
    if set -q argv[1]; and contains -- $argv[1] status st
        set -l running (uname -r 2>/dev/null | string trim)

        # Installed kernel versions
        set -l pkgs (rpm -qa kernel 2>/dev/null)
        set -l seen
        set -l vers
        for p in $pkgs
            set -l v (string replace -r '^kernel(-[a-z]+)*-' '' -- $p)
            if test -n "$v"; and not contains -- $v $seen
                set -a seen $v
                set -a vers $v
            end
        end
        set vers (printf '%s\n' $vers 2>/dev/null | sort -V)
        set -l kcount (count $vers)
        set -l latest $vers[-1]
        if test -z "$latest"
            set latest "—"
        end

        # Reboot needed?
        set -l rn_txt "No — you're on the latest"
        set -l rn_col $G
        if test -n "$running"; and test "$running" != "$latest"
            set rn_txt "YES — reboot to use the latest"
            set rn_col $R
        end

        # Uptime
        set -l up_txt "—"
        set -l up_raw (cat /proc/uptime 2>/dev/null)
        if test -n "$up_raw"
            set -l up_secs (string replace -r '\..*' '' -- (string split ' ' -- "$up_raw")[1])
            if test -n "$up_secs"; and string match -qr '^[0-9]+$' -- "$up_secs"
                set -l d (string replace -r '\..*' '' -- (math "$up_secs / 86400" 2>/dev/null))
                set -l h (string replace -r '\..*' '' -- (math "($up_secs % 86400) / 3600" 2>/dev/null))
                set -l m (string replace -r '\..*' '' -- (math "($up_secs % 3600) / 60" 2>/dev/null))
                if test -n "$d"; and test "$d" -gt 0
                    set up_txt "$d days, $h hours"
                else if test -n "$h"; and test "$h" -gt 0
                    set up_txt "$h hours, $m mins"
                else
                    set up_txt "$m mins"
                end
            end
        end

        # Boot partition usage
        set -l boot_txt "—"
        set -l boot_row (df -h /boot 2>/dev/null | awk 'NR==2 {print $3 " used / " $2}')
        if test -n "$boot_row"
            set boot_txt "$boot_row"
        end

        # GRUB default index
        set -l grub_txt "—"
        if command -q grubby
            set -l gd (grubby --default-index 2>/dev/null | string trim)
            if test -z "$gd"; and test -r /boot/grub2/grubenv
                set gd (string replace 'saved_entry=' '' -- (grep -m1 '^saved_entry=' /boot/grub2/grubenv 2>/dev/null) | string trim)
            end
            if test -n "$gd"
                set grub_txt "index $gd"
            end
        end

        # ── Draw box (62-char inner width) ──
        set -l blank (printf '%*s' 62 '')
        printf '\n'
        printf '  %s╔══════════════════════════════════════════════════════════╗%s\n' $BOLD $N
        set -l hdr "KERNEL STATUS"
        set -l hl (string length -- "$hdr")
        set -l hleft (math "(62 - $hl - 1) / 2")
        set -l hright (math "62 - $hl - $hleft")
        printf '  %s║%s%*s%s%s%s%*s%s║%s\n' $BOLD $N $hleft "" $BOLDG $hdr $N $hright "" $BOLD $N
        printf '  %s╠══════════════════════════════════════════════════════════╣%s\n' $BOLD $N
        printf '  %s║%s%s%s║%s\n' $BOLD $N $blank $BOLD $N

        # Running kernel
        set -l lab "  Running kernel:    "
        set -l plain "$lab$running"
        set -l pad (math "62 - "(string length -- "$plain"))
        printf '  %s║%s%s%s%s%s%*s%s║%s\n' $BOLD $N $lab $W $running $N $pad "" $BOLD $N

        # Latest installed
        set -l lab "  Latest installed:  "
        set -l plain "$lab$latest"
        set -l pad (math "62 - "(string length -- "$plain"))
        printf '  %s║%s%s%s%s%s%*s%s║%s\n' $BOLD $N $lab $W $latest $N $pad "" $BOLD $N

        # Reboot needed
        set -l lab "  Reboot needed:     "
        set -l plain "$lab$rn_txt"
        set -l pad (math "62 - "(string length -- "$plain"))
        printf '  %s║%s%s%s%s%s%*s%s║%s\n' $BOLD $N $lab $rn_col $rn_txt $N $pad "" $BOLD $N

        # Uptime
        set -l lab "  Uptime:            "
        set -l plain "$lab$up_txt"
        set -l pad (math "62 - "(string length -- "$plain"))
        printf '  %s║%s%s%s%s%s%*s%s║%s\n' $BOLD $N $lab $W $up_txt $N $pad "" $BOLD $N

        # Boot partition
        set -l lab "  Boot partition:    "
        set -l plain "$lab$boot_txt"
        set -l pad (math "62 - "(string length -- "$plain"))
        printf '  %s║%s%s%s%s%s%*s%s║%s\n' $BOLD $N $lab $W $boot_txt $N $pad "" $BOLD $N

        # GRUB default
        set -l lab "  GRUB default:      "
        set -l plain "$lab$grub_txt"
        set -l pad (math "62 - "(string length -- "$plain"))
        printf '  %s║%s%s%s%s%s%*s%s║%s\n' $BOLD $N $lab $W $grub_txt $N $pad "" $BOLD $N

        printf '  %s║%s%s%s║%s\n' $BOLD $N $blank $BOLD $N

        # Installed kernels list
        set -l khdr "INSTALLED KERNELS ($kcount):"
        set -l plain "  $khdr"
        set -l pad (math "62 - "(string length -- "$plain"))
        printf '  %s║%s  %s%s%s%*s%s║%s\n' $BOLD $N $BOLDG $khdr $N $pad "" $BOLD $N
        for v in $vers
            set -l mark "  "
            set -l tag ""
            set -l tagc $D
            if string match -q "*rescue*" -- $v
                set mark "- "
                set tagc $M
                set tag "rescue"
            else if test "$v" = "$running"; and test "$v" = "$latest"
                set mark "* "
                set tagc $G
                set tag "running, latest"
            else if test "$v" = "$running"
                set mark "* "
                set tagc $Y
                set tag "running"
            else if test "$v" = "$latest"
                set mark "! "
                set tagc $G
                set tag "latest"
            else
                set mark "- "
                set tagc $R
                set tag "OLD"
            end
            set -l plain "    $mark$v   ($tag)"
            set -l pad (math "62 - "(string length -- "$plain"))
            printf '  %s║%s    %s%s%s%s%s   (%s%s%s)%s%*s%s║%s\n' $BOLD $N $tagc $mark $N $W $v $N $tagc $tag $N $pad "" $BOLD $N
        end

        printf '  %s║%s%s%s║%s\n' $BOLD $N $blank $BOLD $N

        # TIP
        set -l tip "TIP: run kernels --dry-run to preview cleanup"
        set -l plain "  $tip"
        set -l pad (math "62 - "(string length -- "$plain"))
        printf '  %s║%s  %s%s%s%*s%s║%s\n' $BOLD $N $D $tip $N $pad "" $BOLD $N

        printf '  %s╚══════════════════════════════════════════════════════════╝%s\n' $BOLD $N
        printf '\n'
        return 0
    end

    set -l dry_run 0
    if set -q _flag_dry_run
        set dry_run 1
    end

    # ── Guard: cleanup only runs with `clean` subcommand or --dry-run ──
    # (bare `kernels` shows help; `kernels -n` is safe dry-run preview)
    if test $want_clean -eq 0; and test $dry_run -eq 0
        printf '\n  %sUsage:%s kernels clean   (or: -clean --clean -cl --cl)\n' $Y $N
        printf '  %s       %s kernels status   (read-only state)\n' $Y $N
        printf '  %s       %s kernels -h       (full help)\n' $Y $N
        printf '\n'
        return 0
    end

    # ── Pre-checks ──
    if not command -q rpm
        printf '  %serror:%s rpm not found\n' $R $N
        return 1
    end
    if not command -q grubby
        printf '  %serror:%s grubby not found\n' $R $N
        return 1
    end
    if not command -q dnf
        printf '  %serror:%s dnf not found\n' $R $N
        return 1
    end

    # ── Check sudo access ──
    printf '\n'
    printf '  Checking sudo access...\n'
    if sudo -n true 2>/dev/null
        printf '  %s[Granted Access]%s\n' $G $N
    else
        if sudo true 2>/dev/null
            printf '  %s[Granted Access]%s\n' $G $N
        else
            printf '  %s[Access Denied]%s\n' $R $N
            printf '  %serror:%s sudo access required. Aborted.\n' $R $N
            return 1
        end
    end

    # ── Get running kernel ──
    set -l running (uname -r | string trim)

    # ── Get all kernel packages and extract unique versions ──
    set -l all_packages (rpm -qa kernel 2>/dev/null)
    if test (count $all_packages) -eq 0
        printf '  No kernel packages installed.\n'
        return 0
    end

    # Extract unique version strings
    # Regex: strip "kernel" + any variant suffixes (core, modules, debug, rt, etc.)
    set -l seen
    set -l unique_versions
    for pkg in $all_packages
        set -l ver (string replace -r '^kernel(-[a-z]+)*-' '' -- $pkg)
        if test -n "$ver"; and not contains -- $ver $seen
            set -a seen $ver
            set -a unique_versions $ver
        end
    end

    set unique_versions (printf '%s\n' $unique_versions | sort -V)

    if test (count $unique_versions) -eq 0
        printf '  Could not parse kernel versions.\n'
        return 1
    end

    # ── Identify latest and running ──
    set -l latest_ver $unique_versions[-1]
    set -l running_ver ""
    for ver in $unique_versions
        if test "$ver" = "$running"
            set running_ver $ver
            break
        end
    end

    # Warn if running kernel not found in installed packages
    if test -z "$running_ver"
        printf '  %swarning:%s running kernel %s not found in installed packages\n' $Y $N $running
    end

    # ── Get GRUB entries ──
    set -l grub_output (sudo grubby --info=ALL 2>/dev/null)
    if test (count $grub_output) -eq 0
        printf '  %serror:%s could not read GRUB entries\n' $R $N
        return 1
    end

    # ── Parse GRUB index/title pairs ──
    set -l grub_indices
    set -l grub_titles
    set -l cur_idx ""
    for line in $grub_output
        if string match -q 'index=*' -- $line
            set cur_idx (string replace 'index=' '' -- $line)
        else if string match -q 'title=*' -- $line
            set -a grub_indices $cur_idx
            set -a grub_titles (string replace -a '"' '' -- (string replace 'title=' '' -- $line))
            set cur_idx ""
        end
    end

    if test (count $grub_indices) -eq 0
        printf '  %serror:%s no GRUB entries found\n' $R $N
        return 1
    end

    # ── Build index→title lookup ──
    set -l idx_to_title
    for i in (seq 1 (count $grub_indices))
        set -a idx_to_title "$grub_indices[$i]:$grub_titles[$i]"
    end

    # ── Classify each version ──
    set -l keep_versions
    set -l delete_versions
    set -l rescue_ver ""

    for ver in $unique_versions
        if string match -q "*rescue*" -- $ver
            set rescue_ver $ver
            set -a keep_versions $ver
        else if test "$ver" = "$latest_ver"
            set -a keep_versions $ver
        else
            set -a delete_versions $ver
        end
    end

    # ── Safety: block running kernel from delete list ──
    set -l blocked_running 0
    if test -n "$running_ver"; and contains -- $running_ver $delete_versions
        set blocked_running 1
        set -l new_delete
        for d in $delete_versions
            if test "$d" != "$running_ver"
                set -a new_delete $d
            end
        end
        set delete_versions $new_delete
        if not contains -- $running_ver $keep_versions
            set -a keep_versions $running_ver
        end
    end

    # ── Safety: block rescue from delete list (filter, not mutate-during-iterate) ──
    set -l new_delete
    for d in $delete_versions
        if string match -q "*rescue*" -- $d
            if not contains -- $d $keep_versions
                set -a keep_versions $d
            end
        else
            set -a new_delete $d
        end
    end
    set delete_versions $new_delete

    # ── Safety: refuse if only 1 kernel total ──
    if test (count $unique_versions) -le 1
        printf '\n  %sOnly 1 kernel installed.%s Nothing to clean.\n' $BOLDG $N
        return 0
    end

    # ── Nothing to delete? ──
    if test (count $delete_versions) -eq 0
        printf '\n  %sSystem is clean.%s No old kernels to remove.\n' $BOLDG $N
        printf '  Installed: %s' $W
        printf 'kernel-%s' $latest_ver
        printf '%s' $N
        if test -n "$rescue_ver"
            printf ' + rescue'
        end
        printf '\n'
        return 0
    end

    # ── Map versions to GRUB indices ──
    set -l ver_grub_map
    for ver in $unique_versions
        set -l matched_idx ""
        for i in (seq 1 (count $grub_indices))
            if string match -q -- "*$ver*" $grub_titles[$i]
                set matched_idx $grub_indices[$i]
                break
            end
        end
        set -a ver_grub_map "$ver:$matched_idx"
    end

    # ── Find GRUB indices to delete ──
    set -l delete_grub_indices
    for dv in $delete_versions
        for entry in $ver_grub_map
            set -l e_ver (string split ':' -- $entry)[1]
            set -l e_idx (string split ':' -- $entry)[2]
            if test "$e_ver" = "$dv"; and test -n "$e_idx"
                set -a delete_grub_indices $e_idx
            end
        end
    end

    # ── Validate GRUB indices (must be numeric) ──
    for g in $delete_grub_indices
        if not string match -qr '^[0-9]+$' -- $g
            printf '  %serror:%s invalid GRUB index %s\n' $R $N $g
            return 1
        end
    end

    # ── Reboot prompt if not on latest kernel ──
    if test $blocked_running -eq 1
        printf '\n  %sYou are running kernel %s%s%s but the latest is %s.%s\n' $BOLDY $W $running_ver $N $BOLDG $N
        printf '  %sReboot into the latest kernel first?%s\n' $BOLD $N
        printf '  %sThis will clean up the old kernel after reboot.%s\n' $D $N
        printf '  %sWARNING:%s This will reboot immediately. Save your work!\n' $BOLDY $N
        set -l reboot_reply ""
        while true
            printf '\n  Reboot now? '
            read -l -P '[y/N] ' reboot_reply
            if test $status -ne 0
                printf '\n  %sInterrupted.%s\n' $Y $N
                return 0
            end
            set -l _lc (string lower -- "$reboot_reply" | string trim)
            if test -z "$_lc"; or test "$_lc" = "n"; or test "$_lc" = "no"
                printf '  Continuing with cleanup on running kernel.\n'
                printf '  %sNote:%s The running kernel will be kept safe.\n' $BOLDY $N
                break
            else if test "$_lc" = "y"; or test "$_lc" = "yes"
                printf '  %sRebooting...%s\n' $G $N
                sudo reboot
                return 0
            else
                printf '  %sInvalid input:%s type y/yes/n/no or press Enter.\n' $R $N
            end
        end
    end

    # ── Print header ──
    printf '\n  %sKERNEL CLEANUP%s\n\n' $BOLD $N

    # ── Print installed kernels ──
    printf '  %sINSTALLED KERNELS%s\n' $BOLDX $N
    for ver in $unique_versions
        set -l marker '  '
        set -l tag ''
        set -l grub_idx ''

        for entry in $ver_grub_map
            set -l e_ver (string split ':' -- $entry)[1]
            set -l e_idx (string split ':' -- $entry)[2]
            if test "$e_ver" = "$ver"
                set grub_idx $e_idx
                break
            end
        end

        set -l ver_color $D
        if string match -q "*rescue*" -- $ver
            set ver_color $M
            set tag (printf '%srescue%s' $M $N)
        else if test "$ver" = "$running_ver"; and test "$ver" = "$latest_ver"
            set marker (printf '%s* %s' $BOLDG $N)
            set ver_color $W
            set tag (printf '%srunning, latest%s' $BOLDG $N)
        else if test "$ver" = "$running_ver"
            set marker (printf '%s* %s' $BOLDG $N)
            set ver_color $W
            set tag (printf '%srunning%s' $BOLDY $N)
        else if test "$ver" = "$latest_ver"
            set ver_color $BOLDG
            set tag (printf '%slatest%s' $BOLDG $N)
        else
            set ver_color $BOLDR
            set tag (printf '%s[OLD]%s' $BOLDX $N)
        end

        printf '  %s%skernel-%s%s  %-30s' $marker $ver_color $ver $N $tag
        if test -n "$grub_idx"
            set -l gtitle ""
            for entry in $idx_to_title
                set -l e_idx (string split ':' -- $entry)[1]
                set -l e_title (string split ':' -- $entry)[2..]
                if test "$e_idx" = "$grub_idx"
                    set gtitle $e_title
                    break
                end
            end
            if test -n "$gtitle"
                printf '  %s[GRUB %s]%s %s(%s)%s' $D $grub_idx $N $D $gtitle $N
            else
                printf '  %s[GRUB %s]%s' $D $grub_idx $N
            end
        end
        printf '\n'
    end

    # ── Print recommendation ──
    printf '\n  %sRECOMMENDATION%s\n' $BOLD $N

    printf '  %sDELETE%s (%d version(s)):\n' $BOLDX $N (count $delete_versions)
    for dv in $delete_versions
        set -l grub_idx ''
        for entry in $ver_grub_map
            set -l e_ver (string split ':' -- $entry)[1]
            set -l e_idx (string split ':' -- $entry)[2]
            if test "$e_ver" = "$dv"; and test -n "$e_idx"
                set grub_idx $e_idx
                break
            end
        end
        printf '    %skernel-%s%s' $R $dv $N
        if test -n "$grub_idx"
            set -l gtitle ""
            for entry in $idx_to_title
                set -l e_idx2 (string split ':' -- $entry)[1]
                set -l e_title (string split ':' -- $entry)[2..]
                if test "$e_idx2" = "$grub_idx"
                    set gtitle $e_title
                    break
                end
            end
            if test -n "$gtitle"
                printf '  %s[GRUB %s]%s %s(%s)%s' $D $grub_idx $N $D $gtitle $N
            else
                printf '  %s[GRUB %s]%s' $D $grub_idx $N
            end
        end
        printf '\n'
    end

    printf '  %sKEEP%s:\n' $BOLDX $N
    for kv in $keep_versions
        set -l marker '  '
        set -l tag ''
        set -l grub_idx ''
        set -l kv_color $BOLDG
        for entry in $ver_grub_map
            set -l e_ver (string split ':' -- $entry)[1]
            set -l e_idx (string split ':' -- $entry)[2]
            if test "$e_ver" = "$kv"; and test -n "$e_idx"
                set grub_idx $e_idx
                break
            end
        end
        if string match -q "*rescue*" -- $kv
            set kv_color $M
            set tag (printf '%srescue%s' $M $N)
        else if test "$kv" = "$running_ver"; and test "$kv" = "$latest_ver"
            set marker (printf '%s* %s' $BOLDG $N)
            set kv_color $W
            set tag (printf '%srunning, latest%s' $BOLDG $N)
        else if test "$kv" = "$running_ver"
            set marker (printf '%s* %s' $BOLDG $N)
            set kv_color $W
            set tag (printf '%srunning%s' $BOLDY $N)
        else if test "$kv" = "$latest_ver"
            set tag (printf '%slatest%s' $BOLDG $N)
        end
        printf '  %s%skernel-%s%s  %-30s' $marker $kv_color $kv $N $tag
        if test -n "$grub_idx"
            set -l gtitle ""
            for entry in $idx_to_title
                set -l e_idx3 (string split ':' -- $entry)[1]
                set -l e_title (string split ':' -- $entry)[2..]
                if test "$e_idx3" = "$grub_idx"
                    set gtitle $e_title
                    break
                end
            end
            if test -n "$gtitle"
                printf '  %s[GRUB %s]%s %s(%s)%s' $D $grub_idx $N $D $gtitle $N
            else
                printf '  %s[GRUB %s]%s' $D $grub_idx $N
            end
        end
        printf '\n'
    end

    # ── Build dnf package names (anchored match: version at end of pkg name) ──
    set -l dnf_pkgs
    for dv in $delete_versions
        for pkg in $all_packages
            if string match -q -- "*$dv" "$pkg"
                if not contains -- $pkg $dnf_pkgs
                    set -a dnf_pkgs $pkg
                end
            end
        end
    end

    # Safety: no matching packages found
    if test (count $dnf_pkgs) -eq 0
        printf '  %swarning:%s no matching packages found for removal\n' $Y $N
        return 1
    end

    # ── Calculate disk space to be freed (kernel meta-packages = 0 bytes, query kernel-core for real size) ──
    set -l total_size 0
    set -l core_pkgs (rpm -qa kernel-core 2>/dev/null)
    for dv in $delete_versions
        for pkg in $dnf_pkgs $core_pkgs
            if string match -q -- "*$dv" "$pkg"
                set -l size (rpm -q --queryformat '%{SIZE}' "$pkg" 2>/dev/null)
                if test -n "$size"; and string match -qr '^[0-9]+$' -- "$size"
                    set total_size (math $total_size + $size)
                end
            end
        end
    end
    set -l size_mb (math --scale=1 "$total_size / 1024 / 1024")

    # Sort GRUB indices descending (remove highest first so indices don't shift)
    set -l sorted_grub (printf '%s\n' $delete_grub_indices | sort -rn)

    # ── Dry-run exit ──
    if test $dry_run -eq 1
        printf '\n  %sACTION PLAN%s\n' $BOLD $N
        printf '  %ssudo dnf remove %s%s\n' $D (string join " " $dnf_pkgs) $N
        for g in $sorted_grub
            set -l gtitle ""
            for entry in $idx_to_title
                set -l e_idx (string split ':' -- $entry)[1]
                set -l e_title (string split ':' -- $entry)[2..]
                if test "$e_idx" = "$g"
                    set gtitle $e_title
                    break
                end
            end
            if test -n "$gtitle"
                printf '  %ssudo grubby --remove-kernel=%s  %s(%s)%s\n' $D $g $D $gtitle $N
            else
                printf '  %ssudo grubby --remove-kernel=%s%s\n' $D $g $N
            end
        end
        printf '\n  %s[DRY RUN]%s Would free ~%s MB\n' $BOLDY $N $size_mb
        printf '  %sNo changes made.%s\n' $D $N
        return 0
    end

    # ── Confirmation prompt 1 ──
    printf '\n  %sACTION PLAN%s\n' $BOLD $N
    printf '  %ssudo dnf remove %s%s\n' $D (string join " " $dnf_pkgs) $N
    for g in $sorted_grub
        set -l gtitle ""
        for entry in $idx_to_title
            set -l e_idx (string split ':' -- $entry)[1]
            set -l e_title (string split ':' -- $entry)[2..]
            if test "$e_idx" = "$g"
                set gtitle $e_title
                break
            end
        end
        if test -n "$gtitle"
            printf '  %ssudo grubby --remove-kernel=%s  %s(%s)%s\n' $D $g $D $gtitle $N
        else
            printf '  %ssudo grubby --remove-kernel=%s%s\n' $D $g $N
        end
    end
    printf '\n  Remove %s%d old kernel(s) + %d GRUB entry(ies)?%s' $BOLDR (count $delete_versions) (count $delete_grub_indices) $N
    printf '  %s(~%s MB to free)%s' $D $size_mb $N
    set -l reply1 ""
    while true
        printf '\n  '
        read -l -P '[Y/n] ' reply1
        if test $status -ne 0
            printf '\n  %sInterrupted.%s\n' $Y $N
            return 0
        end
        set -l _lc (string lower -- "$reply1" | string trim)
        if test -z "$_lc"; or test "$_lc" = "y"; or test "$_lc" = "yes"
            break
        else if test "$_lc" = "n"; or test "$_lc" = "no"
            printf '  %sAborted.%s\n' $D $N
            return 0
        else
            printf '  %sInvalid input:%s type y/yes/n/no or press Enter.\n' $R $N
        end
    end

    # ── Confirmation prompt 2 (detailed) ──
    printf '\n  %s╔══════════════════════════════════════════════════════════════╗%s\n' $BOLD $N
    printf '  %s║                     FINAL CONFIRMATION                      ║%s\n' $BOLD $N
    printf '  %s╚══════════════════════════════════════════════════════════════╝%s\n\n' $BOLD $N

    # ── Kernel versions to remove ──
    printf '  %sKERNEL VERSIONS TO REMOVE:%s (%d)\n' $BOLDR $N (count $delete_versions)
    for dv in $delete_versions
        set -l grub_idx ''
        for entry in $ver_grub_map
            set -l e_ver (string split ':' -- $entry)[1]
            set -l e_idx (string split ':' -- $entry)[2]
            if test "$e_ver" = "$dv"; and test -n "$e_idx"
                set grub_idx $e_idx
                break
            end
        end
        printf '    %s- kernel-%s' $R $dv
        if test -n "$grub_idx"
            set -l gtitle ""
            for entry in $idx_to_title
                set -l e_idx (string split ':' -- $entry)[1]
                set -l e_title (string split ':' -- $entry)[2..]
                if test "$e_idx" = "$grub_idx"
                    set gtitle $e_title
                    break
                end
            end
            if test -n "$gtitle"
                printf '  %s[GRUB %s]%s %s(%s)%s' $D $grub_idx $N $D $gtitle $N
            else
                printf '  %s[GRUB %s]%s' $D $grub_idx $N
            end
        end
        printf '%s\n' $N
    end
    printf '\n'

    # ── GRUB boot entries to remove ──
    printf '  %sGRUB BOOT ENTRIES TO REMOVE:%s (%d)\n' $BOLDR $N (count $sorted_grub)
    for g in $sorted_grub
        set -l gtitle ""
        for entry in $idx_to_title
            set -l e_idx (string split ':' -- $entry)[1]
            set -l e_title (string split ':' -- $entry)[2..]
            if test "$e_idx" = "$g"
                set gtitle $e_title
                break
            end
        end
        if test -n "$gtitle"
            printf '    %s- GRUB %s%s: %s%s%s%s\n' $R $g $N $W $gtitle $N $R
        else
            printf '    %s- GRUB %s%s\n' $R $g $N
        end
    end
    printf '%s\n' $N

    # ── DNF packages to remove ──
    printf '  %sDNF PACKAGES TO REMOVE:%s (%d)\n' $BOLDR $N (count $dnf_pkgs)
    for pkg in $dnf_pkgs
        printf '    %s- %s%s\n' $R $pkg $N
    end
    printf '\n'

    # ── Disk space ──
    printf '  %sDISK SPACE:%s ~%s%s MB%s will be freed\n' $BOLDY $N $BOLDY $size_mb $N
    printf '\n'

    # ── Will be kept (safe) ──
    printf '  %sWILL BE KEPT (safe):%s\n' $BOLDG $N
    for kv in $keep_versions
        set -l marker '  '
        set -l tag ''
        set -l grub_idx ''
        set -l kv_color $BOLDG
        for entry in $ver_grub_map
            set -l e_ver (string split ':' -- $entry)[1]
            set -l e_idx (string split ':' -- $entry)[2]
            if test "$e_ver" = "$kv"; and test -n "$e_idx"
                set grub_idx $e_idx
                break
            end
        end
        if string match -q "*rescue*" -- $kv
            set kv_color $M
            set tag (printf '%srescue%s' $M $N)
        else if test "$kv" = "$running_ver"; and test "$kv" = "$latest_ver"
            set marker (printf '%s* %s' $BOLDG $N)
            set kv_color $W
            set tag (printf '%srunning, latest%s' $BOLDG $N)
        else if test "$kv" = "$running_ver"
            set marker (printf '%s* %s' $BOLDG $N)
            set kv_color $W
            set tag (printf '%srunning%s' $BOLDY $N)
        else if test "$kv" = "$latest_ver"
            set tag (printf '%slatest%s' $BOLDG $N)
        end
        printf '    %s%skernel-%s%s  %-30s' $marker $kv_color $kv $N $tag
        if test -n "$grub_idx"
            set -l gtitle ""
            for entry in $idx_to_title
                set -l e_idx4 (string split ':' -- $entry)[1]
                set -l e_title (string split ':' -- $entry)[2..]
                if test "$e_idx4" = "$grub_idx"
                    set gtitle $e_title
                    break
                end
            end
            if test -n "$gtitle"
                printf '  %s[GRUB %s]%s %s(%s)%s' $D $grub_idx $N $D $gtitle $N
            else
                printf '  %s[GRUB %s]%s' $D $grub_idx $N
            end
        end
        printf '\n'
    end
    printf '\n'

    # ── Summary line ──
    printf '  %sSUMMARY:%s %sRemove %d kernel(s)%s + %s%d GRUB entries%s → Free ~%s%s MB%s\n' $BOLD $N $R (count $delete_versions) $N $R (count $delete_grub_indices) $N $BOLDY $size_mb $N
    printf '  Are you %ssure%s? ' $BOLDY $N
    set -l reply2 ""
    while true
        read -l -P '[Y/n] ' reply2
        if test $status -ne 0
            printf '\n  %sInterrupted.%s\n' $Y $N
            return 0
        end
        set -l _lc (string lower -- "$reply2" | string trim)
        if test -z "$_lc"; or test "$_lc" = "y"; or test "$_lc" = "yes"
            break
        else if test "$_lc" = "n"; or test "$_lc" = "no"
            printf '  %sAborted.%s\n' $D $N
            return 0
        else
            printf '  %sInvalid input:%s type y/yes/n/no or press Enter.\n' $R $N
            printf '  Are you %ssure%s? ' $BOLDY $N
        end
    end

    # ── Execute: remove kernels via dnf ──
    printf '\n  %sRemoving old kernel packages...%s\n' $BOLD $N
    sudo dnf remove --assumeyes $dnf_pkgs

    if test $status -ne 0
        printf '\n  %serror:%s dnf remove failed. GRUB entries not touched.\n' $R $N
        printf '  Retry: %ssudo dnf remove %s%s\n' $D (string join " " $dnf_pkgs) $N
        return 1
    end
    printf '  %sKernel packages removed.%s\n' $G $N

    # ── Execute: remove GRUB entries (highest index first) ──
    printf '\n  %sRemoving old GRUB entries...%s\n' $BOLD $N
    for g in $sorted_grub
        set -l gtitle ""
        for entry in $idx_to_title
            set -l e_idx (string split ':' -- $entry)[1]
            set -l e_title (string split ':' -- $entry)[2..]
            if test "$e_idx" = "$g"
                set gtitle $e_title
                break
            end
        end
        sudo grubby --remove-kernel=$g 2>/dev/null
        if test $status -eq 0
            if test -n "$gtitle"
                printf '  %sRemoved GRUB %s: %s%s\n' $G $g $gtitle $N
            else
                printf '  %sRemoved GRUB index %s%s\n' $G $g $N
            end
        else
            printf '  %swarning:%s GRUB index %s already gone or invalid\n' $Y $N $g
        end
    end

    # ── Set GRUB default to index 0 (newest after cleanup) ──
    sudo grubby --set-default-index=0 2>/dev/null
    if test $status -eq 0
        printf '  %sGRUB default set to index 0%s\n' $G $N
    end

    # ── Log cleanup ──
    set -l log_dir "$HOME/.local/share/mactahoe"
    set -l log_file "$log_dir/kernels.log"
    if not test -d "$log_dir"
        mkdir -p "$log_dir" 2>/dev/null
    end
    if test -d "$log_dir"
        printf '[%s] Removed %d kernel(s): %s | GRUB: %s | Freed: ~%s MB\n' \
            (date '+%Y-%m-%d %H:%M:%S') \
            (count $delete_versions) \
            (string join ", " $delete_versions) \
            (string join ", " $delete_grub_indices) \
            $size_mb \
            >> "$log_file"
        printf '  %sLogged to %s%s\n' $D $log_file $N
    end

    # ── Done ──
    printf '\n  %sDone.%s Reboot to apply.\n' $G $N
    return 0
end
