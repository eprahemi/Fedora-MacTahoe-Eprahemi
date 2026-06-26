# ══════════════════════════════════════════════════════════════
# matrix — Cmatrix wrapper with color and speed options
# Fedora MacTahoe Eprahemi Edition © 2026
# ══════════════════════════════════════════════════════════════
function matrix --description 'Cmatrix with color & speed options'
    set -l color "green"
    set -l speed 0
    set -l args ""

    for arg in $argv
        switch $arg
            case --red -r
                set color "red"
            case --blue -b
                set color "blue"
            case --green -g
                set color "green"
            case --rainbow -w
                set color "rainbow"
            case --speed
                # next arg is speed
            case '-*'
                if string match -q -- '--speed=*' $arg
                    set speed (string replace '--speed=' '' $arg)
                else
                    set args "$args $arg"
                end
            case --help -h
                echo -e "[1;33mUsage: [1;36mmatrix [options][0m"
                echo -e "  [38;5;248m  --red, -r     Red matrix rain[0m"
                echo -e "  [38;5;248m  --green, -g   Green matrix rain (default)[0m"
                echo -e "  [38;5;248m  --blue, -b    Blue matrix rain[0m"
                echo -e "  [38;5;248m  --rainbow, -w Rainbow matrix rain[0m"
                echo -e "  [38;5;248m  --speed N     Set drop speed (default: 0)[0m"
                echo -e "  [38;5;248m  --help, -h    Show this help message[0m"
                echo -e "  [38;5;248mExample: [1;36mmatrix --red --speed 5[0m"
                return 0
                        case '*'
                if test -n "$speed"; set speed $arg; else; set args "$args $arg"; end
        end
    end

    switch $color
        case red;     cmatrix -a -b -C red $args
        case blue;    cmatrix -a -b -C blue $args
        case rainbow; cmatrix -a -b -C rainbow $args
        case '*';     cmatrix -a -b -C green $args
    end
end
