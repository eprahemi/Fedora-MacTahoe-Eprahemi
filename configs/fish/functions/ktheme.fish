# ════════════════════════════════════════════════════════════════
# ktheme.fish — dynamic kitty theming from wallpaper colors
# Fedora MacTahoe Eprahemi Edition © 2026 — copyright 100%
# ────────────────────────────────────────────────────────────────
# ktheme                 apply wallpaper colors to kitty (all instances)
# ktheme <image>         apply colors extracted from a specific image
# ktheme on              enable watcher — auto re-theme on wallpaper change
# ktheme off             disable watcher + restore the Colorful Edition palette
# ktheme undo            restore the Colorful Edition palette (watcher untouched)
# ktheme status          wallpaper, palette, watcher state, instances
# ktheme watch           internal — watcher loop (systemd user service)
# ktheme --silent        apply with no output (used by the watcher)
#
# How it works:
#   magick quantizes the wallpaper to 16 colors -> sorted by luminance
#   -> background = darkest, foreground = lightest, ANSI 0-15 = the ramp,
#   accent = most saturated color of the bright half (cursor/borders/
#   selection/url). Writes ~/.config/kitty/auto-theme.conf (included by
#   kitty.conf) and reloads every running kitty instance via
#   `kitty @ --to unix:/tmp/kitty-<pid> reload-config`.
# ════════════════════════════════════════════════════════════════

function ktheme --description "Kitty auto-theme — colors from the wallpaper"
    # ── shared state (re-set every call; nested fns don't inherit locals) ──
    set -g __kt_bw 62
    set -g __kt_K (set_color normal)
    set -g __kt_BOLD (set_color -o)
    set -g __kt_Y (set_color yellow)
    set -g __kt_R (set_color red)
    set -g __kt_G (set_color green)
    set -g __kt_W (set_color white)
    set -g __kt_D (set_color brblack)
    set -g __kt_C (set_color cyan)

    set -g __kt_hexs
    set -g __kt_ramp
    set -g __kt_ansi
    set -g __kt_bg ''
    set -g __kt_fg ''
    set -g __kt_accent ''
    set -g __kt_dim ''

    set -l silent 0
    set -l cmd apply
    set -l target ''

    for a in $argv
        switch $a
            case -s --silent
                set silent 1
            case apply on off undo status watch
                set cmd $a
            case '*'
                set target $a
        end
    end

    switch $cmd
        case watch
            __kt_watch
        case on
            __kt_on
        case off
            __kt_off
        case undo
            __kt_restore
            __kt_apply >/dev/null
            printf '\n  %sUndone.%s The Colorful Edition palette is back.\n' $__kt_G $__kt_K
        case status
            __kt_status
        case apply
            __kt_run $silent "$target"
    end
end

# ════════════════════════════════════════════════════════════════
# BOX HELPERS (62-char inner width, 66-char rows — project standard)
# ════════════════════════════════════════════════════════════════

function __kt_top
    printf '  ╔%s╗\n' (string repeat -n $__kt_bw '═')
end

function __kt_bot
    printf '  ╚%s╝\n' (string repeat -n $__kt_bw '═')
end

function __kt_sep
    printf '  ╠%s╣\n' (string repeat -n $__kt_bw '═')
end

function __kt_title
    set -l t $argv[1]
    set -l len (string length -- $t)
    set -l pl (math "(62 - $len) / 2" | string replace -r '\..*' '')
    set -l pr (math "62 - $len - $pl")
    printf '  ║%s%*s%s%*s%s║\n' $__kt_BOLD $pl '' $t $pr '' $__kt_K
end

function __kt_line
    set -l txt $argv[1]
    set -l col $__kt_W
    if test (count $argv) -ge 2
        set col $argv[2]
    end
    set -l len (string length -- $txt)
    printf '  ║%s  %s%*s%s║\n' $col $txt (math "60 - $len") '' $__kt_K
end

function __kt_blank
    __kt_line ""
end

# ════════════════════════════════════════════════════════════════
# CORE
# ════════════════════════════════════════════════════════════════

function __kt_run
    set -l silent $argv[1]
    set -l target $argv[2]
    set -l img ''
    if test -n "$target"
        if test -f "$target"
            set img "$target"
        else
            printf '\n  %serror:%s image not found: %s\n' $__kt_R $__kt_K "$target"
            return 1
        end
    else
        set img (__kt_get_wallpaper)
    end
    if test -z "$img"
        printf '\n  %serror:%s no wallpaper found (gsettings picture-uri empty)\n' $__kt_R $__kt_K
        return 1
    end
    if not test -f "$img"
        printf '\n  %serror:%s wallpaper file not found: %s\n' $__kt_R $__kt_K "$img"
        return 1
    end
    if not __kt_extract "$img"
        printf '\n  %serror:%s ImageMagick could not process: %s\n' $__kt_R $__kt_K "$img"
        return 1
    end
    __kt_map
    __kt_write_conf
    set -l n (__kt_apply)
    if test $silent -eq 0
        __kt_show "$img" $n
    end
    return 0
end

function __kt_get_wallpaper
    set -l uri (gsettings get org.gnome.desktop.background picture-uri 2>/dev/null | string trim -c "'")
    if test -z "$uri"
        set uri (gsettings get org.gnome.desktop.background picture-uri-dark 2>/dev/null | string trim -c "'")
    end
    if test -z "$uri"
        return 1
    end
    # NOTE: no `--` separator — python3 keeps it in sys.argv[1] (tested)
    python3 -c 'import urllib.parse,sys; u=sys.argv[1]; print(urllib.parse.unquote(u[7:] if u.startswith("file://") else u))' "$uri" 2>/dev/null
end

function __kt_extract
    set -l img $argv[1]
    set -g __kt_hexs
    command magick "$img" -resize 160x160^ -gravity center -extent 160x160 -colors 16 -depth 8 -format %c histogram:info:- 2>/dev/null \
        | sed -nE 's/^[ ]*([0-9]+):.*#([0-9A-Fa-f]{6}).*/\1 \2/p' \
        | sort -rn | while read -l c h
            set -a __kt_hexs $h
            test (count $__kt_hexs) -ge 16; and break
        end
    if test (count $__kt_hexs) -lt 1
        return 1
    end
    while test (count $__kt_hexs) -lt 16
        set -a __kt_hexs $__kt_hexs[-1]
    end
    return 0
end

function __kt_lum
    set -l h (string lower -- $argv[1])
    set -l r (printf '%d' "0x"(string sub -s 1 -l 2 -- $h))
    set -l g (printf '%d' "0x"(string sub -s 3 -l 2 -- $h))
    set -l b (printf '%d' "0x"(string sub -s 5 -l 2 -- $h))
    math "0.299*$r + 0.587*$g + 0.114*$b" 2>/dev/null
end

function __kt_sat
    set -l h (string lower -- $argv[1])
    set -l r (printf '%d' "0x"(string sub -s 1 -l 2 -- $h))
    set -l g (printf '%d' "0x"(string sub -s 3 -l 2 -- $h))
    set -l b (printf '%d' "0x"(string sub -s 5 -l 2 -- $h))
    math "(max($r,$g,$b) - min($r,$g,$b))" 2>/dev/null
end

function __kt_map
    # sort all 16 colors by luminance ascending
    set -l sorted
    for h in $__kt_hexs
        set -a sorted (string join ' ' -- (__kt_lum $h) $h)
    end
    set -g __kt_ramp
    for s in (printf '%s\n' $sorted | sort -n)
        set -a __kt_ramp (string split -m1 ' ' -- $s)[2]
    end
    set -g __kt_bg $__kt_ramp[1]
    set -g __kt_fg $__kt_ramp[16]
    # ANSI 0-7 = darkest half, 8-15 = brightest half (luminance ramp)
    set -g __kt_ansi
    for i in (seq 1 8)
        set -a __kt_ansi $__kt_ramp[$i]
    end
    for i in (seq 9 16)
        set -a __kt_ansi $__kt_ramp[$i]
    end
    # accent: most saturated color of the bright half
    # (sat values are integers 0-255 — plain test -gt, fish math has no >)
    set -g __kt_accent $__kt_ramp[16]
    set -l best 0
    for i in (seq 9 16)
        set -l s (__kt_sat $__kt_ramp[$i])
        if test $s -gt $best
            set best $s
            set __kt_accent $__kt_ramp[$i]
        end
    end
    set -g __kt_dim $__kt_ramp[2]
end

function __kt_write_conf
    set -l f ~/.config/kitty/auto-theme.conf
    set -l a $__kt_accent
    printf '# auto-generated by ktheme — do not edit\n' > $f
    printf 'background #%s\n' $__kt_bg >> $f
    printf 'foreground #%s\n' $__kt_fg >> $f
    for i in (seq 0 15)
        printf 'color%d #%s\n' $i $__kt_ansi[(math "$i + 1")] >> $f
    end
    printf 'cursor #%s\n' $a >> $f
    printf 'cursor_text_color #%s\n' $__kt_bg >> $f
    # NOTE: 8-digit #RRGGBBAA alpha is REJECTED for selection_background in
    # the config parser (tested) — 6-digit only, kitty keeps the old value
    printf 'selection_background #%s\n' $a >> $f
    printf 'selection_foreground #%s\n' $__kt_bg >> $f
    printf 'active_border_color #%s\n' $a >> $f
    printf 'inactive_border_color #%s\n' $__kt_dim >> $f
    printf 'tab_bar_background #%s\n' $__kt_bg >> $f
    printf 'tab_bar_foreground #%s\n' $a >> $f
    printf 'url_color #%s\n' $a >> $f
end

function __kt_apply
    set -l n 0
    for sock in /tmp/kitty-*
        if test -S "$sock"
            chmod 600 "$sock" 2>/dev/null
            command kitty @ --to "unix:$sock" load-config 2>/dev/null
            if test $status -eq 0
                set n (math "$n + 1")
            end
        end
    end
    echo $n
end

function __kt_restore
    set -l f ~/.config/kitty/auto-theme.conf
    printf '# Colorful Edition palette (ktheme restore) — do not edit\n' > $f
    printf 'background #1e1e2e\nforeground #cdd6f4\n' >> $f
    printf 'color0  #45475a\ncolor1  #ff5f56\ncolor2  #27c93f\ncolor3  #ffbd2e\n' >> $f
    printf 'color4  #007aff\ncolor5  #cba6f7\ncolor6  #94e2d5\ncolor7  #cdd6f4\n' >> $f
    printf 'color8  #585b70\ncolor9  #ff5f56\ncolor10 #27c93f\ncolor11 #ffbd2e\n' >> $f
    printf 'color12 #007aff\ncolor13 #cba6f7\ncolor14 #94e2d5\ncolor15 #f5e0dc\n' >> $f
    printf 'cursor #f5e0dc\ncursor_text_color #1e1e2e\n' >> $f
    printf 'selection_background #f5e0dc\nselection_foreground #1e1e2e\n' >> $f
    printf 'active_border_color #007aff\ninactive_border_color #313244\n' >> $f
    printf 'tab_bar_background #1e1e2e\ntab_bar_foreground #007aff\nurl_color #89b4fa\n' >> $f
end

# ════════════════════════════════════════════════════════════════
# WATCHER (systemd user service: ktheme-watcher.service)
# ════════════════════════════════════════════════════════════════

function __kt_watch
    # NOTE: gsettings monitor exits immediately when given MULTIPLE keys
    # (tested) — monitor ONE key; picture-uri-dark mirrors picture-uri here.
    # Filter 'picture-uri:*' (with colon) so picture-uri-dark never matches.
    while true
        gsettings monitor org.gnome.desktop.background picture-uri 2>/dev/null | while read -l ev
            if string match -q 'picture-uri:*' -- $ev
                sleep 2
                ktheme --silent
            end
        end
        sleep 5
    end
end

function __kt_on
    if systemctl --user enable --now ktheme-watcher.service 2>/dev/null
        printf '\n  %sWatcher enabled.%s kitty re-themes on every wallpaper change.\n' $__kt_G $__kt_K
    else
        printf '\n  %serror:%s could not start ktheme-watcher.service\n' $__kt_R $__kt_K
    end
end

function __kt_off
    if systemctl --user disable --now ktheme-watcher.service 2>/dev/null
        printf '\n  %sWatcher disabled.%s\n' $__kt_Y $__kt_K
    else
        printf '\n  %serror:%s could not stop ktheme-watcher.service\n' $__kt_R $__kt_K
    end
    __kt_restore
    __kt_apply >/dev/null
    printf '  %sColorful Edition palette restored.%s\n' $__kt_G $__kt_K
end

# ════════════════════════════════════════════════════════════════
# OUTPUT
# ════════════════════════════════════════════════════════════════

function __kt_show
    set -l img $argv[1]
    set -l n $argv[2]
    set -l short (path basename -- "$img")
    set -l dir (path basename -- (path dirname -- "$img"))
    printf '\n'
    __kt_top
    __kt_title "KTHEME — KITTY COLORS FROM WALLPAPER"
    __kt_sep
    __kt_line "wallpaper: $short ($dir)" $__kt_D
    __kt_blank
    __kt_line (printf 'background %s  foreground %s' (__kt_sw $__kt_bg) (__kt_sw $__kt_fg))
    __kt_line (printf 'accent    %s  dim        %s' (__kt_sw $__kt_accent) (__kt_sw $__kt_dim))
    __kt_blank
    __kt_ramp_rows
    __kt_blank
    if test $n -eq 0
        __kt_line "no kitty running — colors will apply on next launch" $__kt_G
    else
        __kt_line "applied live to $n kitty window(s)" $__kt_G
    end
    __kt_line "saved in: ~/.config/kitty/auto-theme.conf" $__kt_D
    __kt_blank
    __kt_line "Made by eprahemi — Fedora MacTahoe © 2026" $__kt_BOLD
    __kt_bot
end

function __kt_sw
    printf '██ #%s' $argv[1]
end

function __kt_ramp_rows
    for i in (seq 0 7)
        set -l a $__kt_ansi[(math "$i + 1")]
        set -l b $__kt_ansi[(math "$i + 9")]
        __kt_line (printf '██ #%s color%-5s ██ #%s color%d' $a $i $b (math "$i + 8"))
    end
end

function __kt_status
    set -l img (__kt_get_wallpaper)
    set -l short 'none'
    set -l dir ''
    if test -n "$img"
        set short (path basename -- "$img")
        set dir (path basename -- (path dirname -- "$img"))
    end
    set -l w (systemctl --user is-active ktheme-watcher.service 2>/dev/null)
    set -l socks 0
    for s in /tmp/kitty-*
        if test -S "$s"
            chmod 600 "$s" 2>/dev/null
            set socks (math "$socks + 1")
        end
    end
    printf '\n'
    __kt_top
    __kt_title "KTHEME — STATUS"
    __kt_sep
    __kt_line "wallpaper: $short ($dir)" $__kt_D
    __kt_line "palette:   ~/.config/kitty/auto-theme.conf" $__kt_D
    __kt_line "watcher:   $w" (test "$w" = active; and echo $__kt_G; or echo $__kt_Y)
    __kt_line "kitty windows: $socks" $__kt_W
    __kt_blank
    __kt_line "Made by eprahemi — Fedora MacTahoe © 2026" $__kt_BOLD
    __kt_bot
end
