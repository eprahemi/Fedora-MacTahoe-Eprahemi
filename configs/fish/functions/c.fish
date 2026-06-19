function c --description 'Open Celluloid or fzf-pick a video'
    # Ensure Celluloid's script-opts directory exists to suppress the "Failed to open" warning
    mkdir -p "$HOME/.config/celluloid/script-opts"

    if set -q argv[1]
        switch $argv[1]
            case --recent -r
                set -l recent (string match -r '.*\.(mp4|mkv|avi|mov|webm)' < ~/.local/share/recently-used.xbel 2>/dev/null | head -20 | string trim)
                if test -z "$recent"
                    echo -e "\033[1;31m❌ No recent video files found.\033[0m"
                    return 1
                end
                set -l pick (printf "%s\n" $recent | fzf --prompt="🎬 Recent video > " --height=10)
                if test -n "$pick"
                    celluloid "$pick" >/dev/null 2>&1 & disown
                end
            case '-*'
                echo -e "\033[1;33mUsage: \033[1;36mc [file|--recent]\033[0m"
                return 1
            case '*'
                set -l target "$argv"
                # Expand ~ if present
                set target (string replace -r '^~' "$HOME" "$target")
                if test -f "$target"
                    celluloid "$target" >/dev/null 2>&1 & disown
                else
                    # File not found as-is — search Downloads
                    set -l query (string trim "$argv")
                    set -l matches (find "$HOME/Downloads" -maxdepth 1 -type f \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.avi' -o -iname '*.mov' -o -iname '*.webm' \) -iname "*$query*" 2>/dev/null)
                    if set -q matches[2]
                        # Multiple matches — fzf picker
                        set -l pick (printf "%s\n" $matches | fzf --prompt="🎬 Pick video > " --height=10)
                        if test -n "$pick"
                            celluloid "$pick" >/dev/null 2>&1 & disown
                        end
                    else if set -q matches[1]
                        celluloid "$matches[1]" >/dev/null 2>&1 & disown
                    else
                        echo -e "\033[1;31m❌ No video found matching '\033[1;33m$argv\033[1;31m' in ~/Downloads/\033[0m"
                        return 1
                    end
                end
        end
    else
        set -l vid (find . -maxdepth 1 \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.avi' -o -iname '*.mov' -o -iname '*.webm' \) 2>/dev/null | fzf --prompt="🎬 Pick video > " --height=10)
        if test -n "$vid"
            celluloid "$vid" >/dev/null 2>&1 & disown
        end
    end
end
