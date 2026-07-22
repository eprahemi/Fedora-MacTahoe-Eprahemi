function __confirm_yn --description 'Prompt for y/n confirmation'
    # Usage: __confirm_yn "  Apply changes? [y/n]: "
    # Returns: 0 = yes, 1 = no
    # Requires explicit y or n input. Enter does nothing, loops.
    set -l prompt "$argv[1]"
    if test (count $argv) -ge 2
        set prompt "$argv[1] [$argv[2]]: "
    end
    while true
        read -l _reply -P "$prompt"
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
