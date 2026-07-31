function __loading_clear --on-signal INT
    set -g __loading_abort 1
end

function __loading --description 'One-line live loader: spinner + message + progress bar while a command runs'
    # Usage: __loading <message> <shell-command...>
    # Runs the command in the background and animates ONE line until it
    # finishes. The bar fills over ~3 seconds and caps at 100% — fast
    # commands end fast, slow ones sit at full. No artificial delay.
    #
    # After it finishes:
    #   - the animation line is wiped clean, cursor restored
    #   - $__loading_result holds the command's stdout (list, one line per element)
    #   - the function returns the command's exit code
    #   - Ctrl+C aborts: kills the command, wipes the line, returns 130
    # ══════════════════════════════════════════════════════════════

    set -l __l_msg $argv[1]
    set -e argv[1]
    if not set -q argv[1]
        return 1
    end
    set -l __l_cmd (string join ' ' $argv)

    set -g __loading_result ""
    set -l __l_out (mktemp)
    set -l __l_exit (mktemp)

    printf '\e[?25l'

    sh -c "$__l_cmd > \"$__l_out\" 2>/dev/null; echo \$? > \"$__l_exit\"" &
    set -l __l_pid $last_pid

    set -l __l_frames ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
    set -l __l_t 0
    set -l __l_i 1

    while kill -0 $__l_pid 2>/dev/null
        if test "$__loading_abort" = 1
            break
        end
        set -l __l_pct (math -s0 "$__l_t * 100 / 15")
        if test $__l_pct -gt 100
            set __l_pct 100
        end
        set -l __l_filled (math -s0 "$__l_pct * 20 / 100")
        set -l __l_fill (string repeat -n $__l_filled '█')
        set -l __l_empty (string repeat -n (math -s0 "20 - $__l_filled") '░')
        printf '\r  \e[1;36m%s\e[0m  \e[1;37m%s\e[0m  \e[2;37m[\e[0m\e[1;36m%s\e[0m\e[2;37m%s\e[0m\e[2;37m]\e[0m \e[1;33m%3d%%\e[0m' $__l_frames[$__l_i] $__l_msg "$__l_fill" "$__l_empty" $__l_pct
        set __l_i (math "$__l_i % 10 + 1")
        set __l_t (math "$__l_t + 1")
        sleep 0.2
    end

    printf '\r  %*s\r' 90 ''

    if test "$__loading_abort" = 1
        kill $__l_pid 2>/dev/null
        wait $__l_pid 2>/dev/null
        rm -f $__l_out $__l_exit
        set -e __loading_abort
        functions -e __loading_clear
        printf '\e[?25h'
        return 130
    end

    wait $__l_pid 2>/dev/null
    set -l __l_code 1
    if test -s "$__l_exit"
        set __l_code (cat "$__l_exit")
    end

    if test -s "$__l_out"
        set -g __loading_result (cat "$__l_out")
    else
        set -g __loading_result ""
    end

    rm -f $__l_out $__l_exit
    functions -e __loading_clear
    printf '\e[?25h'
    return $__l_code
end
