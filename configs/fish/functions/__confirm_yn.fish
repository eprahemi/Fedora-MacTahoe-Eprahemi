function __confirm_yn --description 'Prompt for y/n confirmation with input validation and Ctrl+C'
    # Usage: __confirm_yn "  Apply changes? [Y/n]: " y
    #   argv[1] = prompt string
    #   argv[2] = default (y = default yes, n = default no)
    # Returns: 0 = yes, 1 = no
    # Ctrl+C once = cancel (return 1), twice = kill function (return 130)
    set -l prompt "$argv[1]"
    set -l default "y"
    if test (count $argv) -ge 2
        set default "$argv[2]"
    end
    set -g __confirm_cc_count 0
    while true
        read -l _reply -P "$prompt"
        # Ctrl+C: status 130 = SIGINT
        if test $status -eq 130
            if test $__confirm_cc_count -eq 1
                # Second Ctrl+C — kill the calling function
                set -g __confirm_cc_count 0
                printf "\n"
                kill -INT $fish_pid
                return 130
            else
                # First Ctrl+C — cancel this prompt
                set -g __confirm_cc_count 1
                printf "\n"
                return 1
            end
        end
        # Got real input — reset counter
        set -g __confirm_cc_count 0
        set -l _lc (string lower -- "$_reply" | string trim)
        if test -z "$_lc"
            if test "$default" = "y"
                return 0
            else
                return 1
            end
        else if test "$_lc" = "y"; or test "$_lc" = "yes"
            return 0
        else if test "$_lc" = "n"; or test "$_lc" = "no"
            return 1
        else
            printf "  Invalid input. Type y or n: "
        end
    end
end
