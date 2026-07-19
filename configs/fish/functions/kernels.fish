function kernels -d "List and clean up old Fedora kernels and GRUB entries"
    # ── Pre-checks ──
    if not command -q rpm
        printf "  error: rpm not found — this function requires Fedora/RHEL\n"
        return 1
    end

    if not command -q grubby
        printf "  error: grubby not found — cannot read GRUB entries\n"
        return 1
    end

    if not command -q dnf
        printf "  error: dnf not found\n"
        return 1
    end

    # ── Check sudo access early ──
    if not sudo -n true 2>/dev/null
        printf "  Checking sudo access...\n"
        if not sudo true 2>/dev/null
            printf "  error: sudo access required. Aborted.\n"
            return 1
        end
    end

    # ── Get running kernel version ──
    set -l running (uname -r)

    # ── Get unique kernel versions (not individual packages) ──
    # rpm -qa kernel returns kernel, kernel-core, kernel-modules etc per version
    # We extract unique version-release strings to avoid counting sub-packages
    set -l all_packages (rpm -qa kernel 2>/dev/null)
    if test (count $all_packages) -eq 0
        printf "  No kernel packages installed.\n"
        return 0
    end

    # Extract unique version strings (e.g. 7.1.3-201.fc44.x86_64)
    set -l seen_versions
    set -l unique_versions
    for pkg in $all_packages
        # strip leading "kernel-" or "kernel-core-" etc to get version
        set -l ver (string replace -r '^kernel(-core|-modules|-modules-core|-modules-extra|-devel|-devel-matched|-headers)?-' '' -- $pkg)
        if not contains -- $ver $seen_versions
            set -a seen_versions $ver
            set -a unique_versions $ver
        end
    end

    # Sort versions (oldest first, newest last)
    set unique_versions (printf '%s\n' $unique_versions | sort -V)

    if test (count $unique_versions) -eq 0
        printf "  Could not parse any kernel versions.\n"
        return 1
    end

    # ── Latest and running version strings ──
    set -l latest_ver $unique_versions[-1]
    # extract running version from uname -r (strip any suffix after dash-release)
    set -l running_ver ""
    for ver in $unique_versions
        if string match -q "$ver" -- $running
            set running_ver $ver
            break
        end
    end
    # fallback: if running version not in unique list, extract it
    if test -z "$running_ver"
        set running_ver (echo $running | sed 's/\.x86_64$//' | sed 's/\.aarch64$//')
    end

    # ── Get GRUB entries ──
    set -l grub_output (sudo grubby --info=ALL 2>/dev/null)
    if test (count $grub_output) -eq 0
        printf "  error: could not read GRUB entries\n"
        return 1
    end

    # ── Parse GRUB into index/title pairs ──
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
        printf "  error: no GRUB entries found\n"
        return 1
    end

    # ── Classify each unique kernel version ──
    set -l keep_versions      # versions to keep (latest, running, rescue)
    set -l delete_versions    # old versions to delete
    set -l rescue_ver ""      # rescue version if found
    set -l running_is_latest 0

    if test "$running_ver" = "$latest_ver"
        set running_is_latest 1
    end

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

    # ── Safety: if running kernel is not latest, warn but keep both ──
    if test $running_is_latest -eq 0
        printf "\n  WARNING: Running kernel ($running) is NOT the latest installed ($latest_ver).\n"
        printf "  The running kernel is being kept. Consider rebooting into the latest kernel.\n"
    end

    # ── Safety: nothing to delete ──
    if test (count $delete_versions) -eq 0
        printf "\n  System is clean. Only latest kernel"
        if test -n "$rescue_ver"
            printf " + rescue entry"
        end
        printf " found.\n"
        printf "  No old kernels to remove.\n"
        return 0
    end

    # ── Safety: running kernel is in delete list — NEVER allow ──
    for dv in $delete_versions
        if test "$dv" = "$running_ver"
            printf "\n  CRITICAL: Would have tried to delete the running kernel ($dv).\n"
            printf "  This has been blocked. Only non-running old kernels will be removed.\n"
            # remove it from delete list
            set -l new_delete
            for d in $delete_versions
                if test "$d" != "$dv"
                    set -a new_delete $d
                end
            end
            set delete_versions $new_delete
        end
    end

    # ── Safety: rescue kernel in delete list — NEVER allow ──
    for dv in $delete_versions
        if string match -q "*rescue*" -- $dv
            set -l new_delete
            for d in $delete_versions
                if test "$d" != "$dv"
                    set -a new_delete $d
                end
            end
            set delete_versions $new_delete
        end
    end

    # ── Re-check after safety filters ──
    if test (count $delete_versions) -eq 0
        printf "\n  Nothing safe to delete.\n"
        printf "  Only running kernel + latest + rescue remain.\n"
        return 0
    end

    # ── Build GRUB index mapping: version -> GRUB index ──
    set -l ver_grub_map  # "version:index" pairs
    for ver in $unique_versions
        set -l matched_idx ""
        for i in (seq 1 (count $grub_indices))
            set -l title $grub_titles[$i]
            if string match -q "*$ver*" -- $title
                set matched_idx $grub_indices[$i]
                break
            end
        end
        set -a ver_grub_map "$ver:$matched_idx"
    end

    # ── Find GRUB indices to delete (map versions -> GRUB indices) ──
    set -l delete_grub_indices
    for dv in $delete_versions
        for entry in $ver_grub_map
            set -l e_ver (string split ':' -- $entry)[1]
            set -l e_idx (string split ':' -- $entry)[2]
            if test "$e_ver" = "$dv" -a -n "$e_idx"
                set -a delete_grub_indices $e_idx
            end
        end
    end

    # ── Find orphaned GRUB entries (GRUB entries with no matching installed kernel) ──
    set -l orphan_indices
    for i in (seq 1 (count $grub_indices))
        set -l found 0
        for entry in $ver_grub_map
            set -l e_idx (string split ':' -- $entry)[2]
            if test "$e_idx" = "$grub_indices[$i]"
                set found 1
                break
            end
        end
        if test $found -eq 0
            # this GRUB entry has no matching kernel — but don't auto-delete rescue
            if not string match -q "*rescue*" -- $grub_titles[$i]
                set -a orphan_indices $grub_indices[$i]
            end
        end
    end

    # ── Print installed kernels ──
    printf "\n  KERNEL CLEANUP\n\n"
    printf "  INSTALLED KERNELS\n"
    for ver in $unique_versions
        set -l marker " "
        set -l tags ""
        set -l grub_idx ""

        # find GRUB index for this version
        for entry in $ver_grub_map
            set -l e_ver (string split ':' -- $entry)[1]
            set -l e_idx (string split ':' -- $entry)[2]
            if test "$e_ver" = "$ver"
                set grub_idx $e_idx
                break
            end
        end

        # classify
        if string match -q "*rescue*" -- $ver
            set tags "(rescue)"
        else if test "$ver" = "$running_ver"; and test "$ver" = "$latest_ver"
            set marker "*"
            set tags "(running, latest)"
        else if test "$ver" = "$running_ver"
            set marker "*"
            set tags "(running)"
        else if test "$ver" = "$latest_ver"
            set tags "(latest)"
        end

        # check if this version is marked for deletion
        if contains -- $ver $delete_versions
            set tags "$tags [OLD]"
        end

        if test -n "$grub_idx"
            printf "  %s  %-45s %-25s [GRUB %s]\n" $marker $ver $tags $grub_idx
        else
            printf "  %s  %-45s %-25s\n" $marker $ver $tags
        end
    end

    # ── Print orphaned GRUB entries ──
    if test (count $orphan_indices) -gt 0
        printf "\n  ORPHANED GRUB ENTRIES (no matching kernel installed)\n"
        for i in (seq 1 (count $grub_indices))
            if contains -- $grub_indices[$i] $orphan_indices
                printf "    [GRUB %s]  %s\n" $grub_indices[$i] $grub_titles[$i]
            end
        end
    end

    # ── Print recommendation ──
    printf "\n  RECOMMENDED\n"

    printf "  DELETE (%d version(s)):\n" (count $delete_versions)
    for dv in $delete_versions
        set -l grub_idx ""
        for entry in $ver_grub_map
            set -l e_ver (string split ':' -- $entry)[1]
            set -l e_idx (string split ':' -- $entry)[2]
            if test "$e_ver" = "$dv"; and test -n "$e_idx"
                set grub_idx $e_idx
                break
            end
        end
        if test -n "$grub_idx"
            printf "    kernel %-40s [GRUB %s]\n" $dv $grub_idx
        else
            printf "    kernel %-40s\n" $dv
        end
    end
    if test (count $orphan_indices) -gt 0
        printf "  + %d orphaned GRUB entry(ies)\n" (count $orphan_indices)
        for oi in $orphan_indices
            printf "    [GRUB %s]\n" $oi
        end
    end

    printf "\n  KEEP:\n"
    for kv in $keep_versions
        set -l marker " "
        set -l tags ""
        set -l grub_idx ""
        if string match -q "*rescue*" -- $kv
            set tags "(rescue)"
        else if test "$kv" = "$running_ver"; and test "$kv" = "$latest_ver"
            set marker "*"
            set tags "(running, latest)"
        else if test "$kv" = "$running_ver"
            set marker "*"
            set tags "(running)"
        else if test "$kv" = "$latest_ver"
            set tags "(latest)"
        end
        for entry in $ver_grub_map
            set -l e_ver (string split ':' -- $entry)[1]
            set -l e_idx (string split ':' -- $entry)[2]
            if test "$e_ver" = "$kv"; and test -n "$e_idx"
                set grub_idx $e_idx
                break
            end
        end
        if test -n "$grub_idx"
            printf "  %s  kernel %-40s %-15s [GRUB %s]\n" $marker $kv $tags $grub_idx
        else
            printf "  %s  kernel %-40s %-15s\n" $marker $kv $tags
        end
    end

    # ── Build command summary ──
    # Build the full package names for dnf remove
    set -l dnf_pkgs
    for dv in $delete_versions
        for pkg in $all_packages
            if string match -q "*$dv*" -- $pkg
                if not contains -- $pkg $dnf_pkgs
                    set -a dnf_pkgs $pkg
                end
            end
        end
    end

    # Sort GRUB indices descending (remove highest first to avoid index shift)
    set -l sorted_grub (printf '%s\n' $delete_grub_indices | sort -rn)

    # ── Confirmation prompt 1: show what will happen ──
    printf "\n  Remove %d old kernel version(s) + %d GRUB entry(ies)?\n" (count $delete_versions) (count $delete_grub_indices)
    printf "    sudo dnf remove %s\n" (string join " " $dnf_pkgs)
    for g in $sorted_grub
        printf "    sudo grubby --remove-kernel=%s\n" $g
    end
    printf "\n  [Y/n] "
    read -l reply1
    if test "$reply1" != "" -a "$reply1" != "y" -a "$reply1" != "Y"
        printf "  Aborted.\n"
        return 0
    end

    # ── Confirmation prompt 2: final confirmation ──
    printf "\n  This will permanently delete:\n"
    printf "    - %d kernel version(s) (%s)\n" (count $delete_versions) (string join ", " $delete_versions)
    printf "    - %d GRUB boot entry(ies)\n" (count $delete_grub_indices)
    printf "\n  Are you sure? [Y/n] "
    read -l reply2
    if test "$reply2" != "" -a "$reply2" != "y" -a "$reply2" != "Y"
        printf "  Aborted.\n"
        return 0
    end

    # ── Execute: remove kernels via dnf ──
    printf "\n  Removing old kernel packages via dnf...\n"
    sudo dnf remove $dnf_pkgs

    if test $status -ne 0
        printf "\n  error: dnf remove failed. GRUB entries not touched.\n"
        printf "  You can retry manually: sudo dnf remove %s\n" (string join " " $dnf_pkgs)
        return 1
    end

    printf "  Kernel packages removed successfully.\n"

    # ── Execute: remove GRUB entries (highest index first to avoid shifts) ──
    printf "\n  Removing old GRUB entries...\n"
    for g in $sorted_grub
        printf "  Removing GRUB index %s...\n" $g
        sudo grubby --remove-kernel=$g
        if test $status -ne 0
            printf "  warning: failed to remove GRUB index %s (may already be gone)\n" $g
        else
            printf "  Removed GRUB index %s\n" $g
        end
    end

    # ── Verify: set GRUB default to index 0 (latest kernel) ──
    printf "\n  Setting GRUB default to index 0 (latest kernel)...\n"
    sudo grubby --set-default-index=0 2>/dev/null
    if test $status -eq 0
        printf "  GRUB default set.\n"
    else
        printf "  warning: could not set GRUB default (not critical)\n"
    end

    # ── Final summary ──
    printf "\n  Done.\n"
    printf "  Remaining kernels:\n"
    printf "    - %s (latest)\n" $latest_ver
    if test -n "$rescue_ver"
        printf "    - rescue entry\n"
    end
    if test $running_is_latest -eq 0
        printf "\n  NOTE: You are running kernel %s but latest is %s.\n" $running $latest_ver
        printf "  Reboot to use the latest kernel.\n"
    else
        printf "\n  Reboot to apply GRUB changes.\n"
    end
    return 0
end
