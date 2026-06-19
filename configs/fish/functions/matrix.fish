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
