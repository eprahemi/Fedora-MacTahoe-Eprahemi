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
                echo -e "\033[1;33m📖 Read the manual dummy: \033[1;36mcat --help\033[0m"
            case '*'
                bat --paging=never $argv
        end
    else
        bat --paging=never --help
    end
end
