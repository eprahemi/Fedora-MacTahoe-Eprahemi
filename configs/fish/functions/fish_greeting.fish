function fish_greeting --description 'Greeting with time-of-day, user, and uptime'
    set -l hour (date +%H)
    set -l greeting "Hey"
    if test $hour -lt 12
        set greeting "Good morning"
    else if test $hour -lt 17
        set greeting "Good afternoon"
    else
        set greeting "Good evening"
    end

    set -l user (whoami | string upper)
    set -l host (hostname -s 2>/dev/null)
    set -l uptime_str (uptime -p 2>/dev/null | sed 's/up //')

    set_color -o cyan
    figlet "$user" 2>/dev/null
    set_color normal

    echo -e " \033[1;36m$greeting, \033[1;37m$user\033[0m \033[1;30m@\033[0m \033[1;33m$host\033[0m"
    echo -e " \033[1;30m⏱️  Up $uptime_str\033[0m"
end
