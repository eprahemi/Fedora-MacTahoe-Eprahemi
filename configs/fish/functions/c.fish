function c --description 'Open Celluloid or fzf-pick a media file'
    # Ensure Celluloid's script-opts directory exists to suppress the "Failed to open" warning
    mkdir -p "$HOME/.config/celluloid/script-opts"

    # All media file extensions (video + audio) — regex for find -iregex
    set -l media_regex '.*\.\(mp4\|mkv\|avi\|mov\|webm\|m4v\|mpg\|mpeg\|wmv\|flv\|3gp\|ogv\|ts\|mts\|mp3\|wav\|flac\|ogg\|m4a\|wma\|aac\|opus\|aiff\|alac\|ac3\|wv\|ape\|dsf\)$'

    if set -q argv[1]
        switch $argv[1]
            case --recent -r
                set -l recent (string match -r '.*\.(mp4|mkv|avi|mov|webm|m4v|mpg|mpeg|wmv|flv|3gp|ogv|ts|mts|mp3|wav|flac|ogg|m4a|wma|aac|opus|aiff|alac|ac3|wv|ape|dsf)' < ~/.local/share/recently-used.xbel 2>/dev/null | head -20 | string trim)
                if test -z "$recent"
                    echo -e "\033[1;31m❌ No recent media files found.\033[0m"
                    return 1
                end
                set -l pick (printf "%s\n" $recent | fzf --prompt="🎬 Pick media > " --height=10)
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
                    # File not found as-is — fuzzy search home directory
                    set -l query (string trim "$argv")
                    set -l all_media (find "$HOME" -path '*/.*' -prune -o -type f -iregex "$media_regex" -print 2>/dev/null)
                    if test -z "$all_media"
                        echo -e "\033[1;31m❌ No media files found anywhere in ~/\033[0m"
                        return 1
                    end
                    # Fuzzy match using Python difflib
                    set -l matches (printf "%s\n" $all_media | python3 -c "
import sys, difflib, os
query = sys.argv[1] if len(sys.argv) > 1 else ''
lines = [l.rstrip() for l in sys.stdin if l.strip()]
if not lines:
    sys.exit(0)
basenames = [os.path.basename(l) for l in lines]
close = difflib.get_close_matches(query, basenames, n=len(lines), cutoff=0.3)
if close:
    seen = set()
    for b in close:
        for i, bn in enumerate(basenames):
            if bn == b and i not in seen:
                print(lines[i])
                seen.add(i)
                break
else:
    ql = query.lower()
    for i, bn in enumerate(basenames):
        if ql in bn.lower():
            print(lines[i])
" "$query" 2>/dev/null)
                    if set -q matches[1]
                        # Open the best match directly (fuzzy results are relevance-sorted)
                        celluloid "$matches[1]" >/dev/null 2>&1 & disown
                    else
                        echo -e "\033[1;31m❌ No media found matching '\033[1;33m$argv\033[1;31m' in ~/\033[0m"
                        return 1
                    end
                end
        end
    else
        set -l media (find . -maxdepth 1 -type f -iregex "$media_regex" 2>/dev/null | fzf --prompt="🎬 Pick media > " --height=10)
        if test -n "$media"
            celluloid "$media" >/dev/null 2>&1 & disown
        end
    end
end
