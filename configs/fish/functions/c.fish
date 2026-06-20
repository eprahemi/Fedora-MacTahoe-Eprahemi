# ══════════════════════════════════════════════════════════════
# c 🎬 — EPRAHEMI INC. 🏢 Lights, camera, COPYRIGHT 🎥
# Eprahemi owns the whole cinema sorry not sorry 🍿
# Fedora MacTahoe Eprahemi Edition © 2026 — blockbuster energy
# ══════════════════════════════════════════════════════════════
function c --description 'Open Celluloid or fzf-pick a media file'
    mkdir -p "$HOME/.config/celluloid/script-opts"

    set -l media_regex '.*\.\(mp4\|mkv\|avi\|mov\|webm\|m4v\|mpg\|mpeg\|wmv\|flv\|3gp\|ogv\|mp3\|wav\|flac\|ogg\|m4a\|wma\|aac\|opus\)$'

    if set -q argv[1]
        switch $argv[1]
            case --recent -r
                set -l recent (string match -r '.*\.(mp4|mkv|avi|mov|webm|m4v|mpg|mpeg|wmv|flv|3gp|ogv|mp3|wav|flac|ogg|m4a|wma|aac|opus)' < ~/.local/share/recently-used.xbel 2>/dev/null | head -20 | string trim)
                if test -z "$recent"
                    echo -e "\033[1;31m❌ No recent media files found bestie. Go watch something! 📺\033[0m"
                    return 1
                end
                set -l pick (printf "%s\n" $recent | fzf --prompt="🎬 Pick media > " --height=10)
                if test -n "$pick"
                    celluloid "$pick" >/dev/null 2>&1 & disown
                end
            case '-*'
                set -l c_burns
                set c_burns[1] "BRUH '\\033[1;33m$argv[1]\\033[1;33m' is not a movie bestie 💀 Try a real file"
                set c_burns[2] "'\\033[1;33m$argv[1]\\033[1;33m'??? That ain't cinema, that's a crime 💅"
                set c_burns[3] "SIR THIS IS A CELLULOID... '\\033[1;33m$argv[1]\\033[1;33m' is not media 🍔"
                set c_burns[4] "The cinema council voted: '\\033[1;33m$argv[1]\\033[1;33m' is DENIED ⚖️"
                set c_burns[5] "BZZT! '\\033[1;33m$argv[1]\\033[1;33m' is not a video file! 🎮💥"
                set -l c_idx (random 1 5)
                echo -e "\\033[1;31m✘ $c_burns[$c_idx]\\033[0m"
                echo -e "  \\033[38;5;248m  Try \\033[1;36mc --help\\033[38;5;248m bestie 📋\\033[0m"
                return 1
            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mc [file]\033[0m"
                echo -e "  \033[38;5;248mPlay video/audio files with Celluloid\033[0m"
                echo -e "  \033[38;5;248mFuzzy-searches entire home for media files\033[0m"
                echo -e "  \033[38;5;248mSupports: mp4, mkv, avi, mov, webm, wmv, flv, m4v, mpg, mpeg, 3gp, ogv, ts, mts, m2ts, vob, divx, xvid, rm, rmvb, asf\033[0m"
                echo -e "  \033[38;5;248m  --help, -h    Show this help\033[0m"
                return 0
                        case '*'
                set -l target "$argv[1]"
                set target (string replace -r '^~' "$HOME" "$target")
                if test -f "$target"
                    celluloid "$target" >/dev/null 2>&1 & disown
                else
                    set -l query (string trim "$argv[1]")
                    set -l all_media (find "$HOME" -path '*/.*' -prune -o -type f -iregex "$media_regex" -print 2>/dev/null)
                    if test -z "$all_media"
                        echo -e "\033[1;31m❌ No media files found anywhere in ~/ bestie! 📁\033[0m"
                        return 1
                    end
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
                    if set -q matches[2]
                        set -l pick (printf "%s\n" $matches | fzf --prompt="🎬 Pick media > " --height=10)
                        if test -n "$pick"
                            celluloid "$pick" >/dev/null 2>&1 & disown
                        end
                    else if set -q matches[1]
                        celluloid "$matches[1]" >/dev/null 2>&1 & disown
                    else
                        echo -e "\033[1;31m❌ No media found matching '\033[1;33m$argv[1]\033[1;31m' bestie! 🤷\033[0m"
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
