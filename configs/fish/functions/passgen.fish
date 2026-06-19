function passgen --description 'Generate secure random passwords'
    set -l length 16
    set -l use_lower yes
    set -l use_upper yes
    set -l use_digits yes
    set -l use_punct yes
    set -l copy_clip no
    set -l count 1

    # Parse arguments
    while set -q argv[1]
        switch $argv[1]
            case --length -l
                set length $argv[2]
                set -e argv[1..2]
            case --no-lower
                set use_lower no
                set -e argv[1]
            case --no-upper
                set use_upper no
                set -e argv[1]
            case --no-digits
                set use_digits no
                set -e argv[1]
            case --no-symbols -s
                set use_punct no
                set -e argv[1]
            case --clip -c
                set copy_clip yes
                set -e argv[1]
            case --count -n
                set count $argv[2]
                set -e argv[1..2]
            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mpassgen [options]\033[0m"
                echo -e "  \033[1;30m--length, -l N\033[0m     \033[1;37mPassword length (default: 16)\033[0m"
                echo -e "  \033[1;30m--count, -n N\033[0m      \033[1;37mNumber of passwords (default: 1)\033[0m"
                echo -e "  \033[1;30m--no-lower\033[0m         \033[1;37mExclude lowercase letters\033[0m"
                echo -e "  \033[1;30m--no-upper\033[0m         \033[1;37mExclude uppercase letters\033[0m"
                echo -e "  \033[1;30m--no-digits\033[0m        \033[1;37mExclude digits\033[0m"
                echo -e "  \033[1;30m--no-symbols, -s\033[0m   \033[1;37mExclude symbols\033[0m"
                echo -e "  \033[1;30m--clip, -c\033[0m         \033[1;37mCopy to clipboard\033[0m"
                echo -e "  \033[1;30m--help, -h\033[0m         \033[1;37mThis help\033[0m"
                return 0
            case '*'
                # Try as length
                if string match -qr '^\d+$' "$argv[1]"
                    set length $argv[1]
                    set -e argv[1]
                else
                    echo -e "\033[1;31m❌ Unknown option: \033[1;33m$argv[1]\033[0m"
                    return 1
                end
        end
    end

    # Build character set
    set -l chars ""
    test "$use_lower" = yes; and set chars "$chars"abcdefghijklmnopqrstuvwxyz
    test "$use_upper" = yes; and set chars "$chars"ABCDEFGHIJKLMNOPQRSTUVWXYZ
    test "$use_digits" = yes; and set chars "$chars"0123456789
    test "$use_punct" = yes; and set chars "$chars"'!@#$%^&*()_-+=<>?'

    if test (string length "$chars") -eq 0
        echo -e "\033[1;31m❌ No character types selected!\033[0m"
        return 1
    end

    set -l charlen (string length "$chars")

    echo -e "\033[1;36m"
    echo "  ██████╗  █████╗ ███████╗███████╗ ██████╗ ███████╗███╗   ██╗"
    echo "  ██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝ ██╔════╝████╗  ██║"
    echo "  ██████╔╝███████║███████╗███████╗██║  ███╗█████╗  ██╔██╗ ██║"
    echo "  ██╔═══╝ ██╔══██║╚════██║╚════██║██║   ██║██╔══╝  ██║╚██╗██║"
    echo "  ██║     ██║  ██║███████║███████║╚██████╔╝███████╗██║ ╚████║"
    echo "  ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝"
    echo -e "\033[1;30m┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄\033[0m"
    printf "  \033[1;37mLength: \033[1;33m%s\033[0m     \033[1;37mCount: \033[1;33m%s\033[0m\n" "$length" "$count"

    for p in (seq $count)
        set -l password ""
        for i in (seq $length)
            set -l idx (math (random) % $charlen + 1)
            set password "$password"(string sub -s $idx -l 1 "$chars")
        end
        set passwords $passwords $password
    end

    # Print passwords with index
    for i in (seq (count $passwords))
        if test (count $passwords) -gt 1
            printf "  \033[1;36m%2d\033[0m  \033[1;32m%s\033[0m\n" $i $passwords[$i]
        else
            printf "  \033[1;32m%s\033[0m\n" $passwords[$i]
        end
    end

    # Copy to clipboard if requested
    if test "$copy_clip" = yes -a (count $passwords) -eq 1
        printf "%s" $passwords[1] | wl-copy 2>/dev/null
        if test $status -eq 0
            echo -e "\n  \033[1;36m📋 Copied to clipboard\033[0m"
        end
    else if test "$copy_clip" = yes
        printf "%s\n" $passwords | wl-copy 2>/dev/null
        if test $status -eq 0
            echo -e "\n  \033[1;36m📋 All passwords copied to clipboard\033[0m"
        end
    end

    # Show entropy estimate for the first password
    set -l pool_size 0
    test "$use_lower" = yes; and set pool_size (math $pool_size + 26)
    test "$use_upper" = yes; and set pool_size (math $pool_size + 26)
    test "$use_digits" = yes; and set pool_size (math $pool_size + 10)
    test "$use_punct" = yes; and set pool_size (math $pool_size + 20)
    set -l entropy (math "floor( $length * ( l($pool_size) / l(2) ) )" 2>/dev/null)
    if test -n "$entropy"
        echo -e "\n  \033[1;33m🔐 \033[1;37mEntropy: \033[1;36m~$entropy bits\033[0m"
    end
end
