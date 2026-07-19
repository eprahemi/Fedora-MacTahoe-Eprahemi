function kernels -d "List and clean up old Fedora kernels and GRUB entries"
    # ── Safety: must be root-capable ──
    if not command -q rpm
        printf "  error: rpm not found\n"
        return 1
    end

    if not command -q grubby
        printf "  error: grubby not found\n"
        return 1
    end

    # ── Get running kernel ──
    set -l running (uname -r)

    # ── Get all installed kernel versions (unique, sorted) ──
    set -l kernels (rpm -qa kernel | sort -V)

    if test (count $kernels) -eq 0
        printf "  No kernel packages found.\n"
        return 1
    end

    # ── Get latest kernel version ──
    set -l latest $kernels[-1]

    # ── Get GRUB entries ──
    set -l grub_output (sudo grubby --info=ALL 2>/dev/null)

    if test (count $grub_output) -eq 0
        printf "  error: failed to read GRUB entries (try with sudo)\n"
        return 1
    end

    # ── Parse GRUB index and title pairs ──
    set -l grub_indices
    set -l grub_titles
    set -l current_index ""
    set -l current_title ""

    for line in $grub_output
        if string match -q 'index=*' -- $line
            set current_index (string replace 'index=' '' -- $line)
        else if string match -q 'title=*' -- $line
            set current_title (string replace -a '"' '' -- (string replace 'title=' '' -- $line))
            set -a grub_indices $current_index
            set -a grub_titles $current_title
            set current_index ""
            set current_title ""
        end
    end

    # ── Match each kernel to its GRUB index ──
    set -l kernel_grub_map
    for k in $kernels
        set -l matched_index ""
        set -l k_version (string replace 'kernel-' '' -- $k | string replace -r '-\d+\..*$' '')
        for i in (seq 1 (count $grub_indices))
            if string match -q "*$k_version*" -- $grub_titles[$i]
                set matched_index $grub_indices[$i]
                break
            end
        end
        set -a kernel_grub_map "$k:$matched_index"
    end

    # ── Separate into running / latest / rescue / old ──
    set -l keep_kernels
    set -l delete_kernels
    set -l rescue_kernel ""

    for k in $kernels
        set -l k_version (string replace 'kernel-' '' -- $k | string replace -r '-\d+\..*$' '')
        if string match -q "*rescue*" -- $k
            set -a keep_kernels $k
            set rescue_kernel $k
        else if test "$k" = "$latest"
            set -a keep_kernels $k
        else
            set -a delete_kernels $k
        end
    end

    # ── Safety: never delete if only 1 non-rescue kernel left ──
    set -l non_rescue_count 0
    for k in $keep_kernels
        if not string match -q "*rescue*" -- $k
            set non_rescue_count (math $non_rescue_count + 1)
        end
    end
    set non_rescue_count (math $non_rescue_count + (count $delete_kernels))

    if test (count $delete_kernels) -eq 0
        printf "  Nothing to clean. Only latest kernel + rescue found.\n"
        return 0
    end

    # ── Print installed kernels ──
    printf "\n  KERNEL CLEANUP\n\n"
    printf "  INSTALLED KERNELS\n"
    for k in $kernels
        set -l marker " "
        set -l tags ""
        set -l grub_idx ""
        set -l k_version (string replace 'kernel-' '' -- $k | string replace -r '-\d+\..*$' '')

        # find grub index
        for entry in $kernel_grub_map
            set -l entry_k (string split ':' -- $entry)[1]
            set -l entry_g (string split ':' -- $entry)[2]
            if test "$entry_k" = "$k"
                set grub_idx $entry_g
                break
            end
        end

        if test "$k" = "$running"
            set marker "*"
            set tags "(running, latest)"
        else if test "$k" = "$latest"
            set tags "(latest)"
        else if string match -q "*rescue*" -- $k
            set tags "(rescue, KEEP)"
        end

        if test -n "$grub_idx"
            printf "  %s  %-45s %-25s [GRUB %s]\n" $marker $k $tags $grub_idx
        else
            printf "  %s  %-45s %-25s\n" $marker $k $tags
        end
    end

    # ── Print recommendation ──
    printf "\n  RECOMMENDED\n"
    printf "  DELETE:\n"
    for k in $delete_kernels
        set -l grub_idx ""
        for entry in $kernel_grub_map
            set -l entry_k (string split ':' -- $entry)[1]
            set -l entry_g (string split ':' -- $entry)[2]
            if test "$entry_k" = "$k"
                set grub_idx $entry_g
                break
            end
        end
        if test -n "$grub_idx"
            printf "    %-45s [GRUB %s]\n" $k $grub_idx
        else
            printf "    %-45s\n" $k
        end
    end

    printf "\n  KEEP:\n"
    for k in $keep_kernels
        set -l marker " "
        set -l tags ""
        set -l grub_idx ""
        if test "$k" = "$running"
            set marker "*"
            set tags "(running, latest)"
        else if string match -q "*rescue*" -- $k
            set tags "(rescue)"
        end
        for entry in $kernel_grub_map
            set -l entry_k (string split ':' -- $entry)[1]
            set -l entry_g (string split ':' -- $entry)[2]
            if test "$entry_k" = "$k"
                set grub_idx $entry_g
                break
            end
        end
        if test -n "$grub_idx"
            printf "  %s  %-45s %-25s [GRUB %s]\n" $marker $k $tags $grub_idx
        else
            printf "  %s  %-45s %-25s\n" $marker $k $tags
        end
    end

    # ── Build the commands that will run ──
    set -l dnf_args
    set -l grubby_args
    for k in $delete_kernels
        set -a dnf_args $k
    end
    for k in $delete_kernels
        for entry in $kernel_grub_map
            set -l entry_k (string split ':' -- $entry)[1]
            set -l entry_g (string split ':' -- $entry)[2]
            if test "$entry_k" = "$k" -a -n "$entry_g"
                set -a grubby_args $entry_g
            end
        end
    end

    # ── Confirmation prompt 1: show what will happen ──
    printf "\n  Remove %d old kernel(s) + GRUB entries?\n" (count $delete_kernels)
    printf "    sudo dnf remove %s\n" (string join " " $dnf_args)
    for g in $grubby_args
        printf "    sudo grubby --remove-kernel=%s\n" $g
    end
    printf "\n  [Y/n] "
    read -l reply1
    if test "$reply1" != "" -a "$reply1" != "y" -a "$reply1" != "Y"
        printf "  Aborted.\n"
        return 0
    end

    # ── Confirmation prompt 2: final confirmation ──
    printf "\n  This will permanently delete %d kernel(s) and %d GRUB entry(ies).\n" (count $delete_kernels) (count $grubby_args)
    printf "  Are you sure? [Y/n] "
    read -l reply2
    if test "$reply2" != "" -a "$reply2" != "y" -a "$reply2" != "Y"
        printf "  Aborted.\n"
        return 0
    end

    # ── Execute: remove kernels via dnf ──
    printf "\n  Removing kernels via dnf...\n"
    sudo dnf remove $dnf_args

    if test $status -ne 0
        printf "  error: dnf remove failed. GRUB entries not touched.\n"
        return 1
    end

    # ── Execute: remove GRUB entries ──
    for g in $grubby_args
        printf "  Removing GRUB entry index=%s\n" $g
        sudo grubby --remove-kernel=$g
        if test $status -ne 0
            printf "  warning: failed to remove GRUB index %s\n" $g
        end
    end

    # ── Verify: make sure GRUB default is set to latest ──
    printf "\n  Setting GRUB default to latest kernel...\n"
    sudo grubby --set-default-index=0 2>/dev/null

    printf "\n  Done. Reboot to apply.\n"
    return 0
end
