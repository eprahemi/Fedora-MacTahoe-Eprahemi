function kernels -d "List and clean up old Fedora kernels and GRUB entries"
    # ── Colors ──
    set -l R (set_color red)
    set -l G (set_color green)
    set -l Y (set_color yellow)
    set -l C (set_color cyan)
    set -l M (set_color magenta)
    set -l W (set_color white)
    set -l D (set_color brblack)
    set -l N (set_color normal)
    set -l BOLD (set_color --bold white)
    set -l BOLDG (set_color --bold green)
    set -l BOLDY (set_color --bold yellow)
    set -l BOLDR (set_color --bold red)
    set -l BOLDX (set_color --bold brblack)

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

    # ── Check sudo access early ──
    printf '  Checking sudo access... '
    if sudo -n true 2>/dev/null
        printf '%sok%s\n' $G $N
    else
        if sudo true 2>/dev/null
            printf '%sok%s\n' $G $N
        else
            printf '%sdenied%s\n' $R $N
            printf '  %serror:%s sudo access required. Aborted.\n' $R $N
            return 1
        end
    end

    # ── Get running kernel ──
    set -l running (uname -r)

    # ── Get all kernel packages and extract unique versions ──
    set -l all_packages (rpm -qa kernel 2>/dev/null)
    if test (count $all_packages) -eq 0
        printf '  No kernel packages installed.\n'
        return 0
    end

    # Extract unique version strings
    set -l seen
    set -l unique_versions
    for pkg in $all_packages
        set -l ver (string replace -r '^kernel(-core|-modules|-modules-core|-modules-extra|-devel|-devel-matched|-headers)?-' '' -- $pkg)
        if not contains -- $ver $seen
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
        if string match -q -- $ver $running
            set running_ver $ver
            break
        end
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

    # ── Safety: block rescue from delete list ──
    for dv in $delete_versions
        if string match -q "*rescue*" -- $dv
            set -l new_delete
            for d in $delete_versions
                if test "$d" != "$dv"
                    set -a new_delete $d
                end
            end
            set delete_versions $new_delete
            if not contains -- $dv $keep_versions
                set -a keep_versions $dv
            end
        end
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

    # ── Reboot prompt if not on latest kernel ──
    if test $blocked_running -eq 1
        printf '\n  %sYou are running kernel %s%s%s but the latest is %s.%s\n' $BOLDY $W $running_ver $N $BOLDG $N
        printf '  %sReboot into the latest kernel first?%s\n' $BOLD $N
        printf '  %sThis will clean up the old kernel after reboot.%s\n' $D $N
        printf '\n  Reboot now? [Y/n] '
        read -l -P "" reboot_reply
        if test "$reboot_reply" = "" -o "$reboot_reply" = "y" -o "$reboot_reply" = "Y"
            printf '  %sRebooting...%s\n' $G $N
            sudo reboot
            return 0
        else
            printf '  Continuing with cleanup on running kernel.\n'
            printf '  %sNote:%s The running kernel will be kept safe.\n' $BOLDY $N
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

        # find GRUB index
        for entry in $ver_grub_map
            set -l e_ver (string split ':' -- $entry)[1]
            set -l e_idx (string split ':' -- $entry)[2]
            if test "$e_ver" = "$ver"
                set grub_idx $e_idx
                break
            end
        end

        # classify with colors
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
            printf '  %s[GRUB %s]%s' $D $grub_idx $N
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
            printf '  %s[GRUB %s]%s' $D $grub_idx $N
        end
        printf '\n'
    end

    printf '  %sKEEP%s:\n' $BOLDX $N
    for kv in $keep_versions
        set -l marker '  '
        set -l tag ''
        set -l grub_idx ''
        for entry in $ver_grub_map
            set -l e_ver (string split ':' -- $entry)[1]
            set -l e_idx (string split ':' -- $entry)[2]
            if test "$e_ver" = "$kv"; and test -n "$e_idx"
                set grub_idx $e_idx
                break
            end
        end
        if string match -q "*rescue*" -- $kv
            set tag (printf '%srescue%s' $M $N)
        else if test "$kv" = "$running_ver"; and test "$kv" = "$latest_ver"
            set marker (printf '%s* %s' $BOLDG $N)
            set tag (printf '%srunning, latest%s' $BOLDG $N)
        else if test "$kv" = "$running_ver"
            set marker (printf '%s* %s' $BOLDG $N)
            set tag (printf '%srunning%s' $BOLDY $N)
        else if test "$kv" = "$latest_ver"
            set tag (printf '%slatest%s' $BOLDG $N)
        end
        printf '  %s%skernel-%s%s  %-30s' $marker $BOLDG $kv $N $tag
        if test -n "$grub_idx"
            printf '  %s[GRUB %s]%s' $D $grub_idx $N
        end
        printf '\n'
    end

    # ── Build dnf package names ──
    set -l dnf_pkgs
    for dv in $delete_versions
        for pkg in $all_packages
            if string match -q -- "*$dv*" $pkg
                if not contains -- $pkg $dnf_pkgs
                    set -a dnf_pkgs $pkg
                end
            end
        end
    end

    # Sort GRUB indices descending (remove highest first)
    set -l sorted_grub (printf '%s\n' $delete_grub_indices | sort -rn)

    # ── Confirmation prompt 1 ──
    printf '\n  %sACTION PLAN%s\n' $BOLD $N
    printf '  %ssudo dnf remove %s%s\n' $D (string join " " $dnf_pkgs) $N
    for g in $sorted_grub
        printf '  %ssudo grubby --remove-kernel=%s%s\n' $D $g $N
    end
    printf '\n  Remove %s%d old kernel(s) + %d GRUB entry(ies)?%s' $BOLDR (count $delete_versions) (count $delete_grub_indices) $N
    read -l -P "  [Y/n] " reply1
    if test "$reply1" != "" -a "$reply1" != "y" -a "$reply1" != "Y"
        printf '  %sAborted.%s\n' $D $N
        return 0
    end

    # ── Confirmation prompt 2 ──
    printf '  %sFinal check:%s This will permanently delete:\n' $BOLDY $N
    printf '    %s- %d kernel version(s):%s %s\n' $R (count $delete_versions) $N (string join ", " $delete_versions)
    printf '    %s- %d GRUB boot entry(ies)%s\n' $R (count $delete_grub_indices) $N
    printf '  Are you %ssure%s?' $BOLDY $N
    read -l -P "  [Y/n] " reply2
    if test "$reply2" != "" -a "$reply2" != "y" -a "$reply2" != "Y"
        printf '  %sAborted.%s\n' $D $N
        return 0
    end

    # ── Execute: remove kernels via dnf ──
    printf '\n  %sRemoving old kernel packages...%s\n' $BOLD $N
    sudo dnf remove $dnf_pkgs

    if test $status -ne 0
        printf '\n  %serror:%s dnf remove failed. GRUB entries not touched.\n' $R $N
        printf '  Retry: %ssudo dnf remove %s%s\n' $D (string join " " $dnf_pkgs) $N
        return 1
    end
    printf '  %sKernel packages removed.%s\n' $G $N

    # ── Execute: remove GRUB entries (highest first) ──
    printf '\n  %sRemoving old GRUB entries...%s\n' $BOLD $N
    for g in $sorted_grub
        sudo grubby --remove-kernel=$g 2>/dev/null
        if test $status -eq 0
            printf '  %sRemoved GRUB index %s%s\n' $G $g $N
        else
            printf '  %swarning:%s GRUB index %s already gone or invalid\n' $Y $N $g
        end
    end

    # ── Set GRUB default ──
    sudo grubby --set-default-index=0 2>/dev/null
    if test $status -eq 0
        printf '  %sGRUB default set to index 0%s\n' $G $N
    end

    # ── Done ──
    printf '\n  %sDone.%s Reboot to apply.\n' $G $N
    return 0
end
