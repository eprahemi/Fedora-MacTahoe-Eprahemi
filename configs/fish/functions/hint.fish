# ══════════════════════════════════════════════════════════════
# hint  —  Terminal power-user teaching + interactive demos
# Fedora MacTahoe Eprahemi Edition © 2026 — copyright 100%
# Teaches kitty v2, fish functions, what changed — with live demos
# Usage:  hint                 → interactive menu
#         hint kitty|fish|colors|new   → show one topic
#         hint -w 80           → custom box width
#
# NOTE: everything is a __hint_* GLOBAL on purpose — nested
# helper functions do NOT inherit locals in fish 4.6, so they
# read these shared values instead. They are re-set on every call.
# ══════════════════════════════════════════════════════════════
function hint -d 'Interactive teaching: kitty v2, fish functions, whats-new + live demos'
    # ──────────────────────────────────────────────────────────
    # CONFIG — EDIT TO CUSTOMIZE
    #   __hint_bw       box inner width (>= 30)
    #   __hint_prompt   text shown before the menu choice
    #   __hint_tips     extra lines printed under the menu footer
    # ──────────────────────────────────────────────────────────
    set -g __hint_bw 62
    set -g __hint_prompt "  Choice [0-6]: "
    set -g __hint_tips \
        "" \
        "  • add your own tips here (config at top of hint.fish)"

    # ── Colors (globals so nested helpers can see them) ──
    set -g __hint_R (set_color red)
    set -g __hint_G (set_color green)
    set -g __hint_Y (set_color yellow)
    set -g __hint_M (set_color magenta)
    set -g __hint_W (set_color white)
    set -g __hint_D (set_color brblack)
    set -g __hint_N (set_color normal)
    set -g __hint_BOLD (set_color --bold white)
    set -g __hint_BOLDG (set_color --bold green)
    set -g __hint_BOLDY (set_color --bold yellow)
    set -g __hint_BOLDR (set_color --bold red)

    # ── Kitty v2 palette (must match ~/.config/kitty/kitty.conf) ──
    set -g __hint_hexs 45475a ff5f56 27c93f ffbd2e 007aff cba6f7 94e2d5 cdd6f4 585b70 ff5f56 27c93f ffbd2e 007aff cba6f7 94e2d5 f5e0dc
    set -g __hint_nms "black" "red (close)" "green (max)" "yellow (min)" "blue (hl)" "purple" "cyan" "white" "bright black" "bright red" "bright green" "bright yellow" "bright blue" "bright purple" "bright cyan" "rosewater"

    # ══════════════════════════════════════════════════════════
    # BOX HELPERS
    # ══════════════════════════════════════════════════════════
    function __hint_line --description 'print one box line: text + optional color'
        set -l txt $argv[1]
        set -l col $argv[2]
        if test (count $argv) -lt 2
            set col $__hint_W
        end
        set -l pad (math "$__hint_bw - "(string length -- "$txt"))
        if test $pad -lt 1
            set pad 1
        end
        printf '  %s║%s%s%s%s%*s%s║%s\n' $__hint_BOLD $__hint_N $col $txt $__hint_N $pad "" $__hint_BOLD $__hint_N
    end

    function __hint_blank --description 'print an empty box line'
        printf '  %s║%s%*s%s║%s\n' $__hint_BOLD $__hint_N $__hint_bw "" $__hint_BOLD $__hint_N
    end

    function __hint_sep --description 'print the box separator'
        printf '  %s╠%s╣%s\n' $__hint_BOLD (string repeat -n $__hint_bw '═') $__hint_N
    end

    function __hint_title --description 'print a centered title line'
        set -l hdr $argv[1]
        set -l hl (string length -- "$hdr")
        set -l hleft (math "($__hint_bw - $hl - 1) / 2" | string replace -r '\..*' '')
        set -l hright (math "$__hint_bw - $hl - $hleft")
        printf '  %s║%s%*s%s%s%s%*s%s║%s\n' $__hint_BOLD $__hint_N $hleft "" $__hint_BOLDG $hdr $__hint_N $hright "" $__hint_BOLD $__hint_N
    end

    function __hint_section --description 'open a section box with title'
        printf '\n'
        printf '  %s╔%s╗%s\n' $__hint_BOLD (string repeat -n $__hint_bw '═') $__hint_N
        __hint_title $argv[1]
        __hint_sep
        __hint_blank
    end

    function __hint_section_end --description 'close a section box'
        __hint_blank
        printf '  %s╚%s╝%s\n' $__hint_BOLD (string repeat -n $__hint_bw '═') $__hint_N
        printf '\n'
    end

    # ══════════════════════════════════════════════════════════
    # SECTION — KITTY v2
    # ══════════════════════════════════════════════════════════
    function __hint_section_kitty
        __hint_section "KITTY v2 — COLORFUL EDITION"
        __hint_line "  • Full 16-color Catppuccin Mocha + Mac buttons:" $__hint_W
        __hint_line "    red #ff5f56  green #27c93f" $__hint_D
        __hint_line "    yellow #ffbd2e  blue #007aff" $__hint_D
        __hint_line "  • Glass look: opacity 0.75, cursor trail, no decorations" $__hint_W
        __hint_line "  • Selection: rosewater #f5e0dc on mocha base #1e1e2e" $__hint_W
        __hint_line "  • Active border: Mac blue #007aff (visible with splits)" $__hint_W
        __hint_line "  • Tab bar: Mac blue active tab, separator style" $__hint_W
        __hint_blank
        __hint_line "  KITTENS — INTERACTIVE TOOLS" $__hint_BOLDG
        __hint_line "  • ctrl+shift+d      interactive diff viewer" $__hint_W
        __hint_line "  • ctrl+shift+f4     live theme switcher" $__hint_W
        __hint_line "  • ctrl+shift+p      hints: pick URL/path/line" $__hint_W
        __hint_line "  • ctrl+shift+u      unicode/emoji picker" $__hint_W
        __hint_line "  • ctrl+shift+h      scrollback in pager" $__hint_W
        __hint_line "  • ctrl+shift+/      search scrollback" $__hint_W
        __hint_line "  • ctrl+shift+l      cycle layouts: tall,stack,fat,grid" $__hint_W
        __hint_blank
        __hint_line "  SHELL INTEGRATION" $__hint_BOLDG
        __hint_line "  • ctrl+shift+home/end  jump between prompts" $__hint_W
        __hint_line "  • ctrl+shift+x      jump to previous prompt" $__hint_W
        __hint_line "  • ctrl+shift+g      show last command output" $__hint_W
        __hint_line "  • close warning only if a command is running" $__hint_W
        __hint_blank
        __hint_line "  REMOTE CONTROL" $__hint_BOLDG
        __hint_line "  • kitty @ get-colors   (live palette dump)" $__hint_W
        __hint_line "  • kitty @ set-colors background #11111b" $__hint_W
        __hint_line '  • kitty @ send-text --match title:fish "ls -la\n"' $__hint_W
        __hint_line "  • kitty @ new-window   (opens a window remotely)" $__hint_W
        __hint_line "  • socket: /tmp/kitty-<pid>  auto-cleanup on exit" $__hint_W
        __hint_blank
        __hint_line "  TRY THESE RIGHT NOW:" $__hint_BOLDG
        __hint_line "  • ctrl+shift+f4  →  pick a theme, Esc to undo" $__hint_W
        __hint_line "  • ctrl+shift+d   →  diff any two files" $__hint_W
        __hint_line "  • kitty @ ls     →  see this kitty's windows" $__hint_W
        __hint_blank
        __hint_line "  Tip: run  hint menu  for live demos" $__hint_D
        __hint_section_end
    end

    # ══════════════════════════════════════════════════════════
    # SECTION — FISH FUNCTIONS
    # ══════════════════════════════════════════════════════════
    function __hint_section_fish
        __hint_section "FISH — TERMINAL SUPER POWERS"
        __hint_line "  • func               list all fish functions" $__hint_W
        __hint_line "  • func search <kw>   find by name or description" $__hint_W
        __hint_line "  • func show <name>   view a function's source" $__hint_W
        __hint_line "  • functions          builtin: all loaded functions" $__hint_W
        __hint_line "  • type <name>        quick source peek" $__hint_W
        __hint_line "  • every function supports --help (try: clean --help)" $__hint_W
        __hint_line "  • recently updated: kernels, gdm, pfp, kit, hint" $__hint_W
        __hint_blank
        __hint_line "  Tip: func search smb  — or: func show gdm" $__hint_D
        __hint_section_end
    end

    # ══════════════════════════════════════════════════════════
    # SECTION — WHAT CHANGED
    # ══════════════════════════════════════════════════════════
    function __hint_section_new
        __hint_section "WHAT CHANGED — RECENT UPDATES"
        __hint_line "  • kitty v2 Colorful Edition: full palette + kittens" $__hint_W
        __hint_line "    (see: hint kitty  |  live demos: hint menu)" $__hint_D
        __hint_line "  • fastfetch: new terminal module (kitty version)" $__hint_W
        __hint_line "  • kernels.fish: help box redesigned + bugs fixed" $__hint_W
        __hint_line "  • kitty listen_on fixed: unix:/tmp/kitty" $__hint_W
        __hint_line "    (TMPDIR trap: env vars expand only if they exist)" $__hint_D
        __hint_line "  • old configs backed up in:" $__hint_W
        __hint_line "    ~/Documents/Kitty-Fastfetch-Backup/" $__hint_D
        __hint_line "  • remote control works: kitty @ from any terminal" $__hint_W
        __hint_line "  • hint.fish: this teaching function (new)" $__hint_W
        __hint_blank
        __hint_line "  Tip: hint kitty  — details + keybindings" $__hint_D
        __hint_section_end
    end

    # ══════════════════════════════════════════════════════════
    # SECTION — LIVE PALETTE (real colors from kitty.conf)
    # ══════════════════════════════════════════════════════════
    function __hint_section_colors
        __hint_section "KITTY — LIVE PALETTE"
        __hint_line "  Swatches are the real colors from kitty.conf:" $__hint_D
        __hint_blank
        for i in (seq 0 7)
            set -l a (math "$i + 1")
            set -l b (math "$i + 9")
            set -l h1 $__hint_hexs[$a]
            set -l h2 $__hint_hexs[$b]
            set -l n1 $__hint_nms[$a]
            set -l n2 $__hint_nms[$b]
            printf '  %s║%s' $__hint_BOLD $__hint_N
            set_color -b $h1; printf '  '; set_color normal
            printf ' %-7s %-14s  ' "#$h1" "$n1"
            set_color -b $h2; printf '  '; set_color normal
            printf ' %-7s %-14s' "#$h2" "$n2"
            set -l pad (math "$__hint_bw - 52")
            if test $pad -lt 1
                set pad 1
            end
            printf '%*s%s║%s\n' $pad "" $__hint_BOLD $__hint_N
        end
        __hint_blank
        __hint_line "  • Mac buttons: red #ff5f56  green #27c93f" $__hint_W
        __hint_line "    yellow #ffbd2e  blue #007aff" $__hint_W
        __hint_line "  • Background #1e1e2e  Foreground #cdd6f4" $__hint_W
        __hint_line "  • Selection: #f5e0dc on #1e1e2e (rosewater glow)" $__hint_W
        __hint_line "  • Accent: #007aff  (Mac blue — borders, tabs, url)" $__hint_W
        __hint_blank
        __hint_line "  Tip: press ctrl+shift+f4 to try live themes" $__hint_D
        __hint_section_end
    end

    # ══════════════════════════════════════════════════════════
    # SECTION — HELP
    # ══════════════════════════════════════════════════════════
    function __hint_section_help
        __hint_section "HINT — USAGE"
        __hint_line "  • hint                  interactive menu (default)" $__hint_W
        __hint_line "  • hint kitty            kitty v2 features" $__hint_W
        __hint_line "  • hint fish             fish function tips" $__hint_W
        __hint_line "  • hint colors           live palette swatches" $__hint_W
        __hint_line "  • hint new              what changed recently" $__hint_W
        __hint_line "  • hint -w 80            custom box width" $__hint_W
        __hint_line "  • hint -h               this help" $__hint_W
        __hint_blank
        __hint_line "  EXAMPLES — COPY-PASTE AND TRY:" $__hint_BOLDG
        __hint_line "  • hint -w 70 kitty      wider box, kitty topic" $__hint_W
        __hint_line "  • func search file      find file functions" $__hint_W
        __hint_line "  • func show gdm         read GDM function source" $__hint_W
        __hint_line "  • kitty @ new-window    open a window in kitty" $__hint_W
        __hint_line "  • kitty @ ls            list kitty windows" $__hint_W
        __hint_line "  • ctrl+shift+f4         live theme switcher" $__hint_W
        __hint_line "  • ctrl+shift+d          interactive diff" $__hint_W
        __hint_blank
        __hint_line "  • every fish function:  --help works too" $__hint_D
        __hint_blank
        __hint_line "  Made by eprahemi — Fedora MacTahoe © 2026" $__hint_BOLDG
        __hint_section_end
    end

    # ══════════════════════════════════════════════════════════
    # DEMO — REMOTE CONTROL (live kitty @ session)
    # ══════════════════════════════════════════════════════════
    function __hint_demo_remote
        __hint_section "REMOTE CONTROL — LIVE DEMO"
        if not command -q kitty
            __hint_line "  kitty is not installed." $__hint_R
            __hint_section_end
            return 1
        end
        set -l sock (ls /tmp/kitty-* 2>/dev/null | head -1)
        if test -z "$sock"
            __hint_line "  No running kitty socket found in /tmp." $__hint_Y
            __hint_line "  Open a kitty window first, then try again." $__hint_W
            __hint_line "  (remote control only works while kitty runs)" $__hint_D
            __hint_section_end
            return 0
        end
        __hint_line "  Found socket: $sock" $__hint_G
        __hint_line "  Command: kitty @ --to unix:$sock get-colors" $__hint_D
        __hint_blank
        for line in (kitty @ --to "unix:$sock" get-colors 2>/dev/null | head -10)
            __hint_line "  $line" $__hint_W
        end
        __hint_blank
        __hint_line "  Tip: try  kitty @ set-colors background #11111b" $__hint_D
        __hint_line '  Tip: try  kitty @ send-text --match title:fish "hi\n"' $__hint_D
        __hint_section_end
    end

    # ══════════════════════════════════════════════════════════
    # DEMO — KITTEN THEMES (interactive picker)
    # ══════════════════════════════════════════════════════════
    function __hint_demo_themes
        __hint_section "KITTEN THEMES — LIVE DEMO"
        if not command -q kitty
            __hint_line "  kitty is not installed." $__hint_R
            __hint_section_end
            return 1
        end
        # NOTE: TERM is unreliable — config.fish forces TERM=kitty everywhere.
        # KITTY_PID is the ONLY true signal (kitty exports it to child shells).
        if not set -q KITTY_PID
            __hint_line "  This demo must run INSIDE kitty." $__hint_Y
            __hint_line "  (config.fish sets TERM=kitty even outside kitty," $__hint_D
            __hint_line "   so detection uses \$KITTY_PID instead)" $__hint_D
            __hint_line "  Open kitty, type hint, pick option 3." $__hint_D
            __hint_section_end
            return 0
        end
        __hint_line "  Launching the theme picker..." $__hint_G
        __hint_line "  Browse with arrows, Enter to apply, Esc to exit." $__hint_W
        __hint_section_end
        kitty +kitten themes
    end

    # ══════════════════════════════════════════════════════════
    # INTERACTIVE MENU
    # ══════════════════════════════════════════════════════════
    function __hint_menu
        while true
            printf '\n'
            printf '  %s╔%s╗%s\n' $__hint_BOLD (string repeat -n $__hint_bw '═') $__hint_N
            __hint_title "HINT — INTERACTIVE MENU"
            __hint_sep
            __hint_blank
            __hint_line "  1  Kitty shortcuts   4  Live colors" $__hint_W
            __hint_line "  2  Remote control    5  What's new" $__hint_W
            __hint_line "  3  kitten themes     6  fish functions" $__hint_W
            __hint_line "  0  Exit" $__hint_W
            __hint_blank
            __hint_line "  Tip: 6 lists all fish functions (func.fish)" $__hint_D
            for t in $__hint_tips
                if test -n "$t"
                    __hint_line "$t" $__hint_D
                end
            end
            __hint_blank
            __hint_line "  Made by eprahemi — Fedora MacTahoe © 2026" $__hint_BOLDG
            __hint_section_end
            read -l -P "$__hint_prompt" ch
            if test $status -ne 0
                printf '\n  %sInterrupted.%s\n' $__hint_Y $__hint_N
                return 0
            end
            set -l _lc (string lower -- "$ch" | string trim)
            switch $_lc
                case 1
                    __hint_section_kitty
                case 2
                    __hint_demo_remote
                case 3
                    __hint_demo_themes
                case 4
                    __hint_section_colors
                case 5
                    __hint_section_new
                case 6
                    printf '\n'
                    if functions -q func
                        func
                    else
                        printf '  %serror:%s func.fish not found\n' $__hint_R $__hint_N
                    end
                case 0 q quit exit
                    printf '\n  %sDone.%s  Tip: ctrl+shift+f4 in kitty = live themes\n' $__hint_G $__hint_N
                    return 0
                case h help
                    __hint_section_help
                case '*'
                    printf '  %sInvalid:%s choose 0-6 (h = help)\n' $__hint_R $__hint_N
            end
        end
    end

    # ══════════════════════════════════════════════════════════
    # ARGUMENTS + DISPATCH
    # ══════════════════════════════════════════════════════════
    argparse 'w/width=' 'h/help' -- $argv
    or return 1

    if set -q _flag_width
        if string match -qr '^[0-9]+$' -- $_flag_width
            set -g __hint_bw $_flag_width
        else
            printf '  %serror:%s width must be a number (e.g. hint -w 80)\n' $__hint_R $__hint_N
            return 1
        end
    end

    if set -q _flag_help
        __hint_section_help
        return 0
    end

    set -l topic ""
    if set -q argv[1]
        set topic $argv[1]
    end

    switch $topic
        case kitty themes
            __hint_section_kitty
        case fish funcs
            __hint_section_fish
        case colors palette
            __hint_section_colors
        case new whatsnew whats-new news
            __hint_section_new
        case menu demo
            __hint_menu
        case ''
            __hint_menu
        case '*'
            printf '\n  %serror:%s unknown topic "%s"\n' $__hint_R $__hint_N $topic
            printf '  Try: %skitty%s %sfish%s %scolors%s %snew%s %smenu%s\n' $__hint_Y $__hint_N $__hint_Y $__hint_N $__hint_Y $__hint_N $__hint_Y $__hint_N $__hint_Y $__hint_N
            return 1
    end
end
