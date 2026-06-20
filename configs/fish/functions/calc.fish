# ══════════════════════════════════════════════════════════════
# calc 🧮 — EPRAHEMI INC. 🏢 Stop right there criminal scum 🚔
# You ain't stealing this math engine bestie 💅
# Fedora MacTahoe Eprahemi Edition © 2026 — proprietary (ong)
# ══════════════════════════════════════════════════════════════
function calc --description 'Quick math in the terminal using Python'
    if set -q argv[1]
        switch $argv[1]
            case --help -h
                echo -e "\033[1;36m"
                echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
                echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
                echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
                echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
                echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
                echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
                echo -e "\033[1;35m╔══════════════════════════════════════════════════════════╗\033[0m"
                echo -e "\033[1;35m║       \033[1;33mUSAGE:  calc <expression>\033[1;35m                     ║\033[0m"
                echo -e "\033[1;35m╚══════════════════════════════════════════════════════════╝\033[0m"
                echo -e "  \033[1;37mExamples:\033[0m"
                echo -e "    \033[1;36mcalc "2 + 2"\033[0m"
                echo -e "    \033[1;36mcalc "sin(pi/4)"\033[0m"
                echo -e "    \033[1;36mcalc "2**10"\033[0m"
                echo -e "    \033[1;36mcalc "sqrt(144)"\033[0m"
                return 0
            case '*'
                if string match -qr -- '^--?[a-zA-Z]' "$argv[1]"
                    set -l burns
                    set burns[1]  "BRUH '\033[1;33m$argv[1]\033[1;31m' is not math bestie 💀 That's a flag, not a number"
                    set burns[2]  "'\033[1;33m$argv[1]\033[1;31m'??? Last I checked that ain't a number sigma 💅"
                    set burns[3]  "ERROR 404: '\033[1;33m$argv[1]\033[1;31m' not found in the math dictionary 📕"
                    set burns[4]  "SIR THIS IS A CALCULATOR... '\033[1;33m$argv[1]\033[1;31m' is not math 🍔"
                    set burns[5]  "AIYO '\033[1;33m$argv[1]\033[1;31m'?! That's not how numbers work bestie 😭"
                    set burns[6]  "The math council has voted: '\033[1;33m$argv[1]\033[1;31m' is DENIED ⚖️"
                    set burns[7]  "'\033[1;33m$argv[1]\033[1;31m' didn't pass the vibe check. Numbers only. ❌"
                    set burns[8]  "BZZT! '\033[1;33m$argv[1]\033[1;31m' is not a number! Thanks for playing! 🎮💥"
                    set -l ridx (random 1 8)
                    echo -e "\033[1;31m✘ $burns[$ridx]\033[0m"
                    echo -e "  \033[38;5;248m  Try \033[1;36mcalc --help\033[38;5;248m for the math menu 📋\033[0m"
                    return 1
                end
        end
    end

    if test (count $argv) -lt 1
        echo -e "\033[1;36m"
        echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
        echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
        echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
        echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
        echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
        echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
        echo -e "\033[1;35m╔══════════════════════════════════════════════════════════╗\033[0m"
        echo -e "\033[1;35m║       \033[1;33mUSAGE:  calc <expression>\033[1;35m                     ║\033[0m"
        echo -e "\033[1;35m╚══════════════════════════════════════════════════════════╝\033[0m"
        echo -e "  \033[1;37mExamples:\033[0m"
        echo -e "    \033[1;36mcalc "2 + 2"\033[0m"
        echo -e "    \033[1;36mcalc "sin(pi/4)"\033[0m"
        echo -e "    \033[1;36mcalc "2**10"\033[0m"
        echo -e "    \033[1;36mcalc "sqrt(144)"\033[0m"
        return 1
    end

    set -l expr (string join -- " " $argv)

    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║█████╗  ██╔████╔██║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    echo -e "\033[1;35m╔══════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;35m║             \033[1;36mEPRAHEMI MATH ENGINE\033[1;35m                    ║\033[0m"
    echo -e "\033[1;35m╚══════════════════════════════════════════════════════════╝\033[0m"
    echo -e "  \033[1;37mEXPRESSION:\033[0m \033[1;33m$expr\033[0m"

    set -l result (python3 -c "
from math import *
try:
    val = eval(\"$expr\")
    if isinstance(val, float):
        print(f'{val:.10g}')
    else:
        print(val)
except Exception as e:
    print(f'ERROR: {e}')
" 2>&1)

    if string match -q "ERROR:*" "$result"
        echo -e "  \033[1;31m❌ Oopsie bestie, your math ain't mathin': $result\033[0m"
        return 1
    else
        echo -e "  \033[1;37mRESULT:\033[0m   \033[1;32m$result\033[0m   \033[1;33m✨ slay\033[0m"
    end

    echo -e "\n\033[1;30m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\033[1;35m🧮 MATH SLAAAAY bestie    \033[1;37mUSER: \033[1;36m"(string upper "$USER")"\033[0m"
end
