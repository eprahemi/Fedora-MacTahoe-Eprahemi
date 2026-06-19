function weather --description 'Terminal forecast or Mousam GUI (-g)'
    if set -q argv[1]
        switch $argv[1]
            case --gui -g
                flatpak run io.github.amit9838.mousam & disown
            case '-*'
                echo -e "\033[1;33mUsage: \033[1;36mweather [--gui|-g]\033[0m"
                return 1
        end
    else
        if command -v curl &>/dev/null
            curl -s "wttr.in?m1" 2>/dev/null || echo -e "\033[1;31m❌ Could not reach wttr.in\033[0m"
        else
            echo -e "\033[1;31m❌ curl is required for terminal weather\033[0m"
        end
    end
end
