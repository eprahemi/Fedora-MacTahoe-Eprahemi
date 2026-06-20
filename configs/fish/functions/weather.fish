# ══════════════════════════════════════════════════════════════
# weather 🌤️ — EPRAHEMI INC. 🏢 I control the weather now 🌩️
# Eprahemi forecast: 100% chance of copyright ⛈️
# Fedora MacTahoe Eprahemi Edition © 2026 — cloudy with a chance
# ══════════════════════════════════════════════════════════════
function weather --description 'Terminal forecast or Mousam GUI (-g)'
    if set -q argv[1]
        switch $argv[1]
            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mweather [--gui|-g]\033[0m"
                echo -e "  \033[38;5;248m  (no args)            Terminal weather from wttr.in 🌤️\033[0m"
                echo -e "  \033[38;5;248m  --gui, -g            Open Mousam weather GUI ☀️\033[0m"
                echo -e "  \033[38;5;248m  --help, -h           📖 Read the manual dummy\033[0m"
                return 0
            case --gui -g
                flatpak run io.github.amit9838.mousam & disown
            case '-*'
                set -l w_burns
                set w_burns[1] "BRUH '\\033[1;33m$argv[1]\\033[1;33m' is not a weather option 💀 The forecast says: L"
                set w_burns[2] "'\\033[1;33m$argv[1]\\033[1;33m'??? That's not a city bestie 💅"
                set w_burns[3] "SIR THIS IS A WEATHER REPORT... '\\033[1;33m$argv[1]\\033[1;33m' is not climate 🍔"
                set w_burns[4] "The weather council voted: '\\033[1;33m$argv[1]\\033[1;33m' is CLOUDY with a chance of DENIED ⚖️"
                set w_burns[5] "BZZT! '\\033[1;33m$argv[1]\\033[1;33m' is not meteorological! 🎮💥"
                set -l w_idx (random 1 5)
                echo -e "\\033[1;31m✘ $w_burns[$w_idx]\\033[0m"
                echo -e "  \\033[38;5;248m  Try \\033[1;36mweather --help\\033[38;5;248m bestie 📋\\033[0m"
                return 1
        end
    else
        if command -v curl &>/dev/null
            echo -e "\033[1;36m🌤️  Fetching the weather bestie... gimme a sec\033[0m"
            curl -s "wttr.in?m1" 2>/dev/null || echo -e "\033[1;31m❌ Could not reach wttr.in bestie! Check your connection 🌧️\033[0m"
        else
            echo -e "\033[1;31m❌ curl is required for weather bestie. Install it fr fr 🌩️\033[0m"
        end
    end
end
