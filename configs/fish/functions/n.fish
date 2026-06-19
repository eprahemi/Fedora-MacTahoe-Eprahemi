function n --description 'Quick notes: open, --today, --last'
    if set -q argv[1]
        switch $argv[1]
            case --today -t
                mkdir -p "$HOME/Notes"
                set -l today (date +%F)
                set -l file "$HOME/Notes/$today.md"
                if not test -f "$file"
                    echo "# Notes — $today" > "$file"
                    echo "" >> "$file"
                end
                gnome-text-editor "$file" & disown
            case --last -l
                set -l last (ls -t "$HOME/Notes"*.md 2>/dev/null | head -1)
                if test -z "$last"
                    echo -e "\033[1;31m❌ No notes found in ~/Notes/\033[0m"
                    return 1
                end
                gnome-text-editor "$last" & disown
            case '-*'
                echo -e "\033[1;33mUsage: \033[1;36mn [file|--today|--last]\033[0m"
                return 1
            case '*'
                gnome-text-editor $argv & disown
        end
    else
        gnome-text-editor --new-window & disown
    end
end
