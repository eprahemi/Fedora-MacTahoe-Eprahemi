# ══════════════════════════════════════════════════════════════
# cat 🐱 — EPRAHEMI INC. 🏢 Meow meow pay meow 🔫
# This cat don't do free work bestie 💅
# Fedora MacTahoe Eprahemi Edition © 2026 — purr-otected
# ══════════════════════════════════════════════════════════════
function cat --description 'Pretty file viewer with bat (supports --lang, --line-range)'
    if set -q argv[1]
        switch $argv[1]
            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mcat [file|--lang LANG file|--line-range :50 file]\033[0m"
                echo -e "  \033[38;5;248m  --lang, -l <lang>   Set syntax highlighting language\033[0m"
                echo -e "  \033[38;5;248m  --line-range, -r <:N>  Show only first N lines\033[0m"
                echo -e "  \033[38;5;248m  --help, -h           📖 Read the manual dummy\033[0m"
                echo -e "  \033[38;5;248m  (no args)            Show bat's own help\033[0m"
                return 0
            case --lang -l
                if set -q argv[2]
                    bat --paging=never --language=$argv[2] $argv[3..]
                else
                    echo -e "\033[1;31m❌ Girl you gotta specify a language! Usage: cat --lang <language> <file>\033[0m"
                end
            case --line-range -r
                if set -q argv[2]
                    bat --paging=never --line-range=$argv[2] $argv[3..]
                else
                    echo -e "\033[1;31m❌ Bestie you need a range! Usage: cat --line-range <:N> <file>\033[0m"
                end
            case '-*'
                set -l bu_idx (random 1 5)
                set -l burns; set burns[1] "BRUH '\033[1;33m$argv[1]\033[1;33m' is NOT a cat option 💀"; set burns[2] "'\033[1;33m$argv[1]\033[1;33m'??? That ain't a file bestie 💅"; set burns[3] "SIR THIS IS A CAT... '\033[1;33m$argv[1]\033[1;33m' is not a file 🍔"; set burns[4] "The cat council voted: '\033[1;33m$argv[1]\033[1;33m' is DENIED ⚖️"; set burns[5] "BZZT! '\033[1;33m$argv[1]\033[1;33m' is incorrect! 🎮💥"; echo -e "\033[1;31m✘ $burns[$bu_idx]\033[0m"; echo -e "  \033[38;5;248m  Try \033[1;36mcat --help\033[38;5;248m bestie 📋\033[0m"
            case '*'
                bat --paging=never $argv
        end
    else
        bat --paging=never --help
    end
end
