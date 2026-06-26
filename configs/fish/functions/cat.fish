# ══════════════════════════════════════════════════════════════
# cat 🐱 — EPRAHEMI INC. 🏢 Syntax-highlighted file previewer
# Wrapper for bat with lang/line-range support
# Fedora MacTahoe Eprahemi Edition © 2026 — purr-otected
# ══════════════════════════════════════════════════════════════
function cat --description 'Pretty file viewer with bat (supports --lang, --line-range)'
    if set -q argv[1]
        switch $argv[1]
            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mcat [file|--lang LANG file|--line-range :50 file]\033[0m"
                echo -e "  \033[38;5;248m  --lang, -l <lang>   Set syntax highlighting language\033[0m"
                echo -e "  \033[38;5;248m  --line-range, -r <:N>  Show only first N lines\033[0m"
                echo -e "  \033[38;5;248m  --help, -h           📖 Show this help\033[0m"
                echo -e "  \033[38;5;248m  (no args)            Show bat's own help\033[0m"
                echo -e "  \033[38;5;248mVersion: June 2026\033[0m"
                return 0
            case --lang -l
                if set -q argv[2]
                    bat --paging=never --language=$argv[2] $argv[3..]
                else
                    echo -e "\033[1;31m❌ Language required. Usage: cat --lang <language> <file>\033[0m"
                end
            case --line-range -r
                if set -q argv[2]
                    bat --paging=never --line-range=$argv[2] $argv[3..]
                else
                    echo -e "\033[1;31m❌ Range required. Usage: cat --line-range <:N> <file>\033[0m"
                end
            case '-*'
                set -l burns; set burns[1] "Error: '\033[1;33m$argv[1]\033[1;33m' is not a valid option"; echo -e "\033[1;31m✘ $burns[1]\033[0m"; echo -e "  \033[38;5;248m  Try \033[1;36mcat --help\033[38;5;248m for details 📋\033[0m"
            case '*'
                bat --paging=never $argv
        end
    else
        bat --paging=never --help
    end
end
