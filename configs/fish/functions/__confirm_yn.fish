function __confirm_yn --description 'Prompt for y/n confirmation with Ctrl+C support'
    # Usage: __confirm_yn "  Apply changes? [Y/n]: " y
    #   argv[1] = prompt string
    #   argv[2] = default (y = default yes, n = default no)
    # Returns: 0 = yes, 1 = no, 130 = Ctrl+C
    # Ctrl+C once = cancel (return 1), twice = kill calling function (return 130)
    set -l prompt "$argv[1]"
    set -l default "y"
    if test (count $argv) -ge 2
        set default "$argv[2]"
    end
    set -g __cyn_cc 0
    function __cyn_int --on-signal INT
        set -g __cyn_cc (math $__cyn_cc + 1)
    end
    while true
        set -g _reply ""
        read -l _reply -P "$prompt"
        if test $__cyn_cc -ge 2
            functions -e __cyn_int
            set -g __cyn_cc 0
            printf "\n"
            return 130
        else if test $__cyn_cc -ge 1
            functions -e __cyn_int
            set -g __cyn_cc 0
            printf "\n"
            return 1
        end
        set -l _lc (string lower -- "$_reply" | string trim)
        if test -z "$_lc"
            functions -e __cyn_int
            set -g __cyn_cc 0
            if test "$default" = "y"
                return 0
            else
                return 1
            end
        else if test "$_lc" = "y"; or test "$_lc" = "yes"; or test "$_lc" = "yeah"; or test "$_lc" = "yep"; or test "$_lc" = "yup"; or test "$_lc" = "ya"; or test "$_lc" = "sure"; or test "$_lc" = "ok"; or test "$_lc" = "okay"
            functions -e __cyn_int
            set -g __cyn_cc 0
            return 0
        else if test "$_lc" = "n"; or test "$_lc" = "no"; or test "$_lc" = "nah"; or test "$_lc" = "nope"; or test "$_lc" = "nahh"; or test "$_lc" = "nope"; or test "$_lc" = "noo"; or test "$_lc" = "nooo"; or test "$_lc" = "nahhh"; or test "$_lc" = "nahh"; or test "$_lc" = "naw"; or test "$_lc" = "no way"; or test "$_lc" = "nope"; or test "$_lc" = "no thanks"; or test "$_lc" = "no thank you"; or test "$_lc" = "negative"
            functions -e __cyn_int
            set -g __cyn_cc 0
            return 1
        else
            printf "  Invalid input. Type y or n: "
        end
    end
end
