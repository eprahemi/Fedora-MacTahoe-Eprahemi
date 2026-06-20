# ══════════════════════════════════════════════════════════════
# stayawake 😴 — EPRAHEMI INC. 🏢 Sleep is for the weak 💤
# Eprahemi stays awake so you don't have to (you're welcome) ☕
# Fedora MacTahoe Eprahemi Edition © 2026 — no sleep till...
# ══════════════════════════════════════════════════════════════
function stayawake --description 'Prevent sleep/display sleep — usage: stayawake [duration|--display|--stop]'
    if set -q argv[1]
        switch $argv[1]
            case --stop
                if set -q __SA_PID
                    kill $__SA_PID 2>/dev/null
                    functions -e __sa_cleanup
                    set -e __SA_PID
                    echo -e "\033[1;32m⏹️  Inhibitor stopped.\033[0m"
                else
                    echo -e "\033[1;31m❌ No active inhibitor.\033[0m"
                end
                return 0

            case --display -d
                set -l what "handle-lid-switch:handle-suspend-key:handle-hibernate-key"
                echo -e "\033[1;33m⚠️  Only display sleep blocked — lid & suspend keys still active.\033[0m"

            case --help -h
                echo -e "\033[1;33mUsage:\033[0m"
                echo -e "  \033[1;36mstayawake\033[0m         — block lid-sleep for 1 day"
                echo -e "  \033[1;36mstayawake 2h\033[0m      — block lid-sleep for 2 hours"
                echo -e "  \033[1;36mstayawake 30m\033[0m     — block lid-sleep for 30 minutes"
                echo -e "  \033[1;36mstayawake --display\033[0m — block display sleep only"
                echo -e "  \033[1;36mstayawake --stop\033[0m   — cancel active inhibitor"
                return 0

            case '*'
                set -l duration "$argv[1]"
        end
    end

    # Stop previous if running
    if set -q __SA_PID
        kill $__SA_PID 2>/dev/null
        set -e __SA_PID
    end

    set -l current_user (string upper "$USER")

    echo -e "\033[1;34m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    echo -e "             [ OPERATOR: $current_user ]\033[0m"
    echo -e "\033[1;30m------------------------------------------------------------------\033[0m"

    set -l duration_str "1d"
    if set -q duration
        set duration_str $duration
    end

    set -l what "handle-lid-switch"
    if set -q argv[1]
        if test "$argv[1]" = "--display" -o "$argv[1]" = "-d"
            set what "handle-lid-switch:handle-suspend-key:handle-hibernate-key"
            set duration_str "1d"
        end
    end

    echo -e "\033[1;32mACTIVE:\033[0m Sleep blocked for \033[1;36m$duration_str\033[0m  \033[1;31m[--stop to cancel]\033[0m"

    systemd-inhibit --what=$what --why="stayawake by $USER" sleep $duration_str &
    set -g __SA_PID $last_pid

    function __sa_cleanup --on-process-exit %self
        set -e __SA_PID 2>/dev/null
        functions -e __sa_cleanup
    end

    set -l seconds 0
    set -l max_seconds 86400
    while kill -0 $__SA_PID 2>/dev/null
        set -l hours (math -s0 "$seconds / 3600")
        set -l mins (math -s0 "($seconds % 3600) / 60")
        set -l secs (math -s0 "$seconds % 60")

        printf "\r\033[1;36m🕒 ELAPSED: %02dh %02dm %02ds\033[0m" $hours $mins $secs

        sleep 1
        set seconds (math "$seconds + 1")
        if test $seconds -gt $max_seconds
            break
        end
    end

    set -e __SA_PID 2>/dev/null
    printf "\r\033[1;32m✅ TIMER EXPIRED — Sleep restored.                    \033[0m\n"
end
