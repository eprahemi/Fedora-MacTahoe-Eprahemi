# ══════════════════════════════════════════════════════════════
# mkgif 🎞️ — EPRAHEMI INC. 🏢 GIF creation utility
# Video to GIF converter
# Fedora MacTahoe Eprahemi Edition © 2026
# ══════════════════════════════════════════════════════════════
function mkgif --description 'Convert video to optimized GIF'
    set -l fps 10
    set -l scale "480:-1"
    set -l input ""

    for arg in $argv
        switch $arg
            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mmkgif [options] <video>\033[0m"
                echo -e "  \033[38;5;248m  --fps N       Output framerate (default: 10)\033[0m"
                echo -e "  \033[38;5;248m  --scale W:H   Output scale (default: 480:-1)\033[0m"
                echo -e "  \033[38;5;248m  --help, -h    📖 Show help\033[0m"
                echo -e "  \033[38;5;248mExample: \033[1;36mmkgif --fps 15 --scale 640:-1 video.mp4\033[0m"
                echo -e "  \033[38;5;248m📦 Unknown flag handling (Jun 2026)\033[0m"
                return 0
            case --fps
            case --scale
            case '-*'
                if string match -q -- '--fps=*' $arg
                    set fps (string replace '--fps=' '' $arg)
                else if string match -q -- '--scale=*' $arg
                    set scale (string replace '--scale=' '' $arg)
                else
                    echo -e "\033[1;31m✘ Error: Unknown flag '\033[1;33m$arg\033[1;31m'\033[0m"
                    return 1
                end
                        case '*'
                if test -z "$input"
                    set input $arg
                else if test -z "$fps"
                    set fps $arg
                else if test -z "$scale"
                    set scale $arg
                else
                    echo -e "\033[1;31m❌ Unexpected argument: $arg\033[0m"
                    return 1
                end
        end
    end

    if test -z "$input"
        echo -e "\033[1;33mUsage: \033[1;36mmkgif [--fps=N] [--scale=W:H] input.mp4\033[0m"
        return 1
    end

    if not test -f "$input"
        echo -e "\033[1;31m❌ File not found: $input\033[0m"
        return 1
    end

    set -l palette "/tmp/__mkgif_palette.png"
    set -l output (string replace -r '\.[^.]+$' '' "$input").gif

    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    echo -e "\033[1;30m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "  \033[1;37mInput:\033[0m  $input"
    echo -e "  \033[1;37mOutput:\033[0m $output"
    echo -e "  \033[1;37mFPS:\033[0m    $fps"
    echo -e "  \033[1;37mScale:\033[0m  $scale"
    echo -e "\033[1;30m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

    echo -n "  \033[1;37m⏳ Generating palette...\033[0m "
    ffmpeg -v warning -i "$input" -vf "fps=$fps,scale=$scale:flags=lanczos,palettegen=stats_mode=diff" "$palette" -y 2>/dev/null
    echo -e "\033[1;32m✅\033[0m"

    echo -n "  \033[1;37m⏳ Creating GIF...\033[0m "
    ffmpeg -v warning -i "$input" -i "$palette" -lavfi "fps=$fps,scale=$scale:flags=lanczos [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=5" "$output" -y 2>/dev/null
    echo -e "\033[1;32m✅\033[0m"

    rm -f "$palette"

    echo -e "\033[1;30m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e " \033[1;32m✨ GIF created successfully 🎬\033[0m \033[1;36m$output\033[0m"
end
