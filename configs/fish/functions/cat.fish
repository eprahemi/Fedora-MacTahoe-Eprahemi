function cat --description 'Pretty file viewer with bat (supports --lang, --line-range)'
    if set -q argv[1]
        switch $argv[1]
            case --lang -l
                if set -q argv[2]
                    bat --paging=never --language=$argv[2] $argv[3..]
                else
                    echo -e "\033[1;31m❌ Usage: cat --lang <language> <file>\033[0m"
                end
            case --line-range -r
                if set -q argv[2]
                    bat --paging=never --line-range=$argv[2] $argv[3..]
                else
                    echo -e "\033[1;31m❌ Usage: cat --line-range <:N> <file>\033[0m"
                end
            case '-*'
                echo -e "\033[1;33mUsage: \033[1;36mcat [file|--lang LANG file|--line-range :50 file]\033[0m"
            case '*'
                bat --paging=never $argv
        end
    else
        bat --paging=never --help
    end
end
