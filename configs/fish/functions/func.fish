function func --description 'List all available fish functions with descriptions'
    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    echo -e "\033[1;30m╔══════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;30m║          \033[1;36mEPRAHEMI FUNCTION ARCHIVE - v1.0\033[1;30m               ║\033[0m"
    echo -e "\033[1;30m╚══════════════════════════════════════════════════════════╝\033[0m"

    set -l func_dir "$HOME/.config/fish/functions"
    set -l files (ls "$func_dir"/*.fish 2>/dev/null)
    set -l total 0
    set -l max_name_len 0

    for f in $files
        set -l name (string replace -r '\.fish$' '' (basename "$f"))
        set -l len (string length "$name")
        if test $len -gt $max_name_len
            set max_name_len $len
        end
    end

    if test $max_name_len -lt 14
        set max_name_len 14
    end

    set -l pad (math "$max_name_len + 2")

    echo -e "\n  \033[1;33mALL AVAILABLE COMMANDS\033[0m"
    echo -e "  \033[1;30m"(string repeat -n (math 70 + $max_name_len) "─")"\033[0m"

    for f in $files
        set -l name (string replace -r '\.fish$' '' (basename "$f"))
        set -l desc (grep -h -- '--description' "$f" 2>/dev/null | head -1 | sed "s/.*--description '\(.*\)'.*/\1/" | sed "s/.*--description \"\(.*\)\".*/\1/")

        if test -z "$desc"
            set desc "No description provided"
        end

        set -l name_padded $name
        while test (string length "$name_padded") -lt $max_name_len
            set name_padded "$name_padded "
        end

        set -l color "\033[1;36m"
        switch $name
            case c v n weather;          set color "\033[1;33m"
            case l p;                    set color "\033[1;32m"
            case cat mkgif;              set color "\033[1;35m"
            case clean cleanreset refresh; set color "\033[1;31m"
            case testdrive getdata myip stats calc; set color "\033[1;34m"
            case matrix hollywood stayawake; set color "\033[1;35m"
        end

        if test $name = "func"
            set color "\033[1;36m"
        end

        echo -e "   $color$name_padded\033[0m  \033[1;30m→\033[0m  \033[1;37m$desc\033[0m"
        set total (math $total + 1)
    end

    echo -e "  \033[1;30m"(string repeat -n (math 70 + $max_name_len) "─")"\033[0m"
    echo -e "  \033[1;36m📦 $total functions loaded\033[0m    \033[1;37mUSER: \033[1;36m"(string upper "$USER")"\033[0m"
    echo -e "  \033[1;33m💡 Tip: use \033[1;36mtype <function>\033[1;33m to see source code\033[0m"
end
