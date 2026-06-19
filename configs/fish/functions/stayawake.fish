function stayawake --description 'Prevent lid-sleep with live timer display'
    set -l current_user (echo $USER | string upper)
    echo -e "\033[1;34m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    echo -e "             [ OPERATOR: $current_user ]\033[0m"
    echo -e "\033[1;30m------------------------------------------------------------------\033[0m"
    echo -e "\033[1;32mACTIVE:\033[0m Lid-sleep is blocked. \033[1;31m[CTRL+C to restore default]\033[0m"

    # Start the simple inhibitor in the background
    systemd-inhibit --what=handle-lid-switch --why="Active" sleep 1d &
    set -l pid $last_pid

    # Simple timer loop
    set -l seconds 0
    while kill -0 $pid 2>/dev/null
        set -l hours (math -s0 "$seconds / 3600")
        set -l mins (math -s0 "($seconds % 3600) / 60")
        set -l secs (math -s0 "$seconds % 60")
        
        printf "\r\033[1;36m🕒 ELAPSED TIME: %02dh %02dm %02ds\033[0m" $hours $mins $secs
        
        sleep 1
        set seconds (math "$seconds + 1")
    end
end
