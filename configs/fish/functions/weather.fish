# ══════════════════════════════════════════════════════════════
# weather 🌤️ — EPRAHEMI INC. 🏢 Weather forecast utility
# Terminal weather from wttr.in and Mousam GUI
# Fedora MacTahoe Eprahemi Edition © 2026
# ══════════════════════════════════════════════════════════════
function weather --description 'Terminal forecast or Mousam GUI (-g)'
    if set -q argv[1]
        switch $argv[1]
            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mweather [--gui|-g]\033[0m"
                echo -e "  \033[38;5;248m  (no args)            Terminal weather from wttr.in 🌤️\033[0m"
                echo -e "  \033[38;5;248m  --gui, -g            Open Mousam weather GUI ☀️\033[0m"
                echo -e "  \033[38;5;248m  --help, -h           📖 Show help\033[0m"
                echo -e "  \033[38;5;248m📦 Unknown flag handling (Jun 2026)\033[0m"
                return 0
            case --gui -g
                flatpak run io.github.amit9838.mousam & disown
            case '-*'
                echo -e "\033[1;31m✘ Error: Unknown flag '\033[1;33m$argv[1]\033[1;31m'\033[0m"
                echo -e "  \033[38;5;248m  Try \033[1;36mweather --help\033[38;5;248m for available options 📋\033[0m"
                return 1
        end
    else
        if command -v curl &>/dev/null
            __loading "Fetching weather data" "curl -s 'wttr.in?m1'"
            if test $status -ne 0
                echo -e "\033[1;31m❌ Could not reach wttr.in. Check your connection 🌧️\033[0m"
            else if test -n "$__loading_result"
                printf '%s\n' $__loading_result
            end
            set -e __loading_result
        else
            echo -e "\033[1;31m❌ curl is required for weather. Install it 🌩️\033[0m"
        end
    end
end
