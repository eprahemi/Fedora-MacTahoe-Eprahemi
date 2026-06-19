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
                echo -e "\033[1;33m📖 Read the manual dummy: \033[1;36mweather --help\033[0m"
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
