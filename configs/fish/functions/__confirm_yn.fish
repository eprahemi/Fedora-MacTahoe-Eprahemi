function __confirm_yn --description 'Prompt for y/n confirmation with Ctrl+C'
    # Usage: __confirm_yn "  Apply changes? [y/n]: "
    # Returns: 0 = yes, 1 = no
    # Ctrl+C once = re-prompt, twice = cancel
    set -l prompt "$argv[1]"
    set -l __cc 0
    while true
        read -P "$prompt" _reply
        set -l __rs $status
        if test $__rs -ne 0
            set __cc (math $__cc + 1)
            if test $__cc -ge 2
                printf "\n"
                return 1
            end
            printf "  (Ctrl+C again to cancel)\n"
            continue
        end
        set -l _lc (string lower -- "$_reply" | string trim)
        if test "$_lc" = "y"; or test "$_lc" = "yes"; or test "$_lc" = "yeah"; or test "$_lc" = "yep"; or test "$_lc" = "yup"; or test "$_lc" = "ya"; or test "$_lc" = "sure"; or test "$_lc" = "ok"; or test "$_lc" = "okay"
            return 0
        else if test "$_lc" = "n"; or test "$_lc" = "no"; or test "$_lc" = "nah"; or test "$_lc" = "nope"; or test "$_lc" = "nahh"; or test "$_lc" = "nahhh"; or test "$_lc" = "noo"; or test "$_lc" = "nooo"; or test "$_lc" = "naw"; or test "$_lc" = "no way"; or test "$_lc" = "no thanks"; or test "$_lc" = "no thank you"; or test "$_lc" = "negative"
            return 1
        else
            printf "  Invalid input. Type y or n: "
        end
    end
end
