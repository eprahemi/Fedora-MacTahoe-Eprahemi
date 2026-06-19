function func --description 'Function archive: list/search/show all fish commands'
    set -l func_dir "$HOME/.config/fish/functions"
    set -l files (ls "$func_dir"/*.fish 2>/dev/null)

    function __func_desc
        set -l file $argv[1]
        set -l desc (grep -h -- '--description' "$file" 2>/dev/null | head -1 | sed "s/.*--description '\(.*\)'.*/\1/" | sed 's/.*--description "\(.*\)".*/\1/')
        if test -z "$desc"
            echo "No description"
        else
            echo "$desc"
        end
    end

    function __func_color
        set -l name $argv[1]
        switch $name
            case c v n weather;     echo "33"
            case cat l p mkgif extract; echo "32"
            case clean cleanreset refresh; echo "31"
            case testdrive getdata myip stats calc qr; echo "34"
            case matrix hollywood stayawake fish_greeting; echo "35"
            case passgen;           echo "33"
            case '*';               echo "36"
        end
    end

    function __func_usage
        set -l name $argv[1]
        switch $name
            case c;       echo "c [file|--recent]"
            case v;       echo "v [file|--recent]"
            case cat;     echo "cat [file|--lang LANG file|--line-range :N file]"
            case n;       echo "n [file|--today|--last]"
            case weather; echo "weather [--gui]"
            case matrix;  echo "matrix [--red|--blue|--green|--rainbow] [--speed=N]"
            case mkgif;   echo "mkgif [--fps=N] [--scale=W:H] input.mp4"
            case stayawake; echo "stayawake [duration|--display|--stop]"
            case getdata; echo "getdata [--list|--venv]"
            case clean;   echo "clean [--all|--pip|--dry-run]"
            case myip;    echo "myip"
            case stats;   echo "stats"
            case calc;    echo "calc <expression>"
            case qr;      echo "qr <text-or-url>"
            case l;       echo "l [path]"
            case p;       echo "p"
            case mkgif;   echo "mkgif [--fps=N] [--scale=W:H] input"
            case extract; echo "extract <archive> [dest]"
            case func;    echo "func [search|show]"
            case passgen; echo "passgen [opts]"
            case '*';     echo "$name"
        end
    end

    if set -q argv[1]
        switch $argv[1]
            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mfunc [subcommand]\033[0m"
                echo -e "  \033[38;5;248m  search <keyword>   Search functions by name or description\033[0m"
                echo -e "  \033[38;5;248m  show <function>    Show the source code of a function\033[0m"
                echo -e "  \033[38;5;248m  --help, -h         Show this help\033[0m"
                echo -e "  \033[38;5;248m  (no args)          List all available functions\033[0m"
                return 0
            case search
                if not set -q argv[2]
                    echo -e "\033[1;33mUsage bestie: \033[1;36mfunc search <keyword>\033[0m"
                    return 1
                end
                set -l keyword $argv[2]
                echo -e "\033[1;36m"
                echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
                echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
                echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
                echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
                echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
                echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
                echo -e "\033[1;33m╔══════════════════════════════════════════════════════════╗\033[0m"
                echo -e "\033[1;33m║          \033[1;36mSEARCH RESULTS — \"$keyword\"\033[1;33m                    ║\033[0m"
                echo -e "\033[1;33m╚══════════════════════════════════════════════════════════╝\033[0m"

                set -l found 0
                for f in $files
                    set -l name (string replace -r '\.fish$' '' (basename "$f"))
                    set -l desc (__func_desc "$f")
                    if string match -qir "$keyword" "$name $desc"
                        set -l c (__func_color $name)
                        printf "  \033[1;%sm%-14s\033[0m  \033[1;30m→\033[0m  \033[1;37m%s\033[0m\n" $c $name $desc
                        set found (math $found + 1)
                    end
                end
                echo -e "\n  \033[1;36m📦 $found matches\033[0m"
                return 0

            case show
                if not set -q argv[2]
                    echo -e "\033[1;33mUsage bestie: \033[1;36mfunc show <function>\033[0m"
                    return 1
                end
                if functions -q $argv[2]
                    functions $argv[2]
                else
                    echo -e "\033[1;31m❌ No function named '$argv[2]' bestie! That ain't it 💅\033[0m"
                    return 1
                end
                return 0

            case '-*'
                echo -e "\033[1;33m📖 Read the manual dummy: \033[1;36mfunc search <kw>  |  func show <func>  |  func --help\033[0m"
                return 1
        end
    end

    # ── DEFAULT: Full archive ──
    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"

    set -l total 0
    set -l column_width 65

    # ── CATEGORIES ──
    # Media
    echo -e "\n  \033[1;33m🎬  MEDIA\033[0m"
    echo -e "  \033[1;30m"(string repeat -n $column_width "─")"\033[0m"
    for name in c v n weather
        for f in $files
            set -l fn (string replace -r '\.fish$' '' (basename "$f"))
            if test "$fn" = "$name"
                set -l desc (__func_desc "$f")
                set -l usage (__func_usage "$name")
                printf "  \033[1;33m%-14s\033[0m  \033[1;30m→\033[0m  \033[1;37m%-35s\033[0m  \033[1;30m(\033[1;33m%s\033[1;30m)\033[0m\n" "$name" "$desc" "$usage"
                set total (math $total + 1)
            end
        end
    end

    # Files
    echo -e "\n  \033[1;32m📁  FILES\033[0m"
    echo -e "  \033[1;30m"(string repeat -n $column_width "─")"\033[0m"
    for name in cat l p mkgif extract
        for f in $files
            set -l fn (string replace -r '\.fish$' '' (basename "$f"))
            if test "$fn" = "$name"
                set -l desc (__func_desc "$f")
                set -l usage (__func_usage "$name")
                printf "  \033[1;32m%-14s\033[0m  \033[1;30m→\033[0m  \033[1;37m%-35s\033[0m  \033[1;30m(\033[1;32m%s\033[1;30m)\033[0m\n" "$name" "$desc" "$usage"
                set total (math $total + 1)
            end
        end
    end

    # System
    echo -e "\n  \033[1;31m⚙️  SYSTEM\033[0m"
    echo -e "  \033[1;30m"(string repeat -n $column_width "─")"\033[0m"
    for name in clean cleanreset refresh
        for f in $files
            set -l fn (string replace -r '\.fish$' '' (basename "$f"))
            if test "$fn" = "$name"
                set -l desc (__func_desc "$f")
                set -l usage (__func_usage "$name")
                printf "  \033[1;31m%-14s\033[0m  \033[1;30m→\033[0m  \033[1;37m%-35s\033[0m  \033[1;30m(\033[1;31m%s\033[1;30m)\033[0m\n" "$name" "$desc" "$usage"
                set total (math $total + 1)
            end
        end
    end

    # Diagnostics
    echo -e "\n  \033[1;34m📊  DIAGNOSTICS\033[0m"
    echo -e "  \033[1;30m"(string repeat -n $column_width "─")"\033[0m"
    for name in testdrive getdata myip stats calc qr
        for f in $files
            set -l fn (string replace -r '\.fish$' '' (basename "$f"))
            if test "$fn" = "$name"
                set -l desc (__func_desc "$f")
                set -l usage (__func_usage "$name")
                printf "  \033[1;34m%-14s\033[0m  \033[1;30m→\033[0m  \033[1;37m%-35s\033[0m  \033[1;30m(\033[1;34m%s\033[1;30m)\033[0m\n" "$name" "$desc" "$usage"
                set total (math $total + 1)
            end
        end
    end

    # Fun
    echo -e "\n  \033[1;35m🎨  FUN\033[0m"
    echo -e "  \033[1;30m"(string repeat -n $column_width "─")"\033[0m"
    for name in matrix hollywood stayawake fish_greeting
        for f in $files
            set -l fn (string replace -r '\.fish$' '' (basename "$f"))
            if test "$fn" = "$name"
                set -l desc (__func_desc "$f")
                set -l usage (__func_usage "$name")
                printf "  \033[1;35m%-14s\033[0m  \033[1;30m→\033[0m  \033[1;37m%-35s\033[0m  \033[1;30m(\033[1;35m%s\033[1;30m)\033[0m\n" "$name" "$desc" "$usage"
                set total (math $total + 1)
            end
        end
    end

    # Utility
    echo -e "\n  \033[1;36m🔧  UTILITY\033[0m"
    echo -e "  \033[1;30m"(string repeat -n $column_width "─")"\033[0m"
    for name in func passgen
        for f in $files
            set -l fn (string replace -r '\.fish$' '' (basename "$f"))
            if test "$fn" = "$name"
                set -l desc (__func_desc "$f")
                set -l usage (__func_usage "$name")
                printf "  \033[1;36m%-14s\033[0m  \033[1;30m→\033[0m  \033[1;37m%-35s\033[0m  \033[1;30m(\033[1;36m%s\033[1;30m)\033[0m\n" "$name" "$desc" "$usage"
                set total (math $total + 1)
            end
        end
    end

    echo -e "  \033[1;30m"(string repeat -n $column_width "═")"\033[0m"
    echo -e "  \033[1;36m📦  $total functions loaded bestie! No cap\033[0m    \033[1;37mUSER: \033[1;36m"(string upper "$USER")"\033[0m"
    echo -e "  \033[1;33m💡  \033[1;36mfunc search <kw>\033[1;33m  —  \033[1;36mfunc show <function>\033[1;33m  —  \033[1;36mtype <function>\033[1;33m for source\033[0m"

    functions -e __func_desc __func_color __func_usage
end
