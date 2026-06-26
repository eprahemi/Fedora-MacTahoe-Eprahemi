# ══════════════════════════════════════════════════════════════
# func 🗃️ — EPRAHEMI INC. 🏢 The archive of all archives 📦
# Touch this code and I'll appear in your walls 🧱👀
# Fedora MacTahoe Eprahemi Edition © 2026 — copyright 100%
# ══════════════════════════════════════════════════════════════
function func --description 'Function archive: list/search/show all fish commands'
    set -l func_dir "$HOME/.config/fish/functions"

    # ── Color palette ──
    set -l R   "\033[1;31m"
    set -l G   "\033[1;32m"
    set -l Y   "\033[1;33m"
    set -l B   "\033[1;34m"
    set -l M   "\033[1;35m"
    set -l C   "\033[1;36m"
    set -l W   "\033[1;37m"
    set -l D   "\033[2;37m"
    set -l N   "\033[0m"

    # ── Category arrays (indexed 1..6) ──
    set -l cat_name[1] "🎬  Media"
    set -l cat_esc[1]  $Y
    set -l cat_func[1] "c v n weather"

    set -l cat_name[2] "📁  Files"
    set -l cat_esc[2]  $G
    set -l cat_func[2] "cat l p mkgif extract"

    set -l cat_name[3] "⚙️  System"
    set -l cat_esc[3]  $R
    set -l cat_func[3] "clean cleanreset refresh gdm"

    set -l cat_name[4] "📊  Diagnostics"
    set -l cat_esc[4]  $B
    set -l cat_func[4] "testdrive getdata myip stats calc qr"

    set -l cat_name[5] "🎨  Fun"
    set -l cat_esc[5]  $M
    set -l cat_func[5] "matrix hollywood stayawake fish_greeting"

    set -l cat_name[6] "🔧  Utility"
    set -l cat_esc[6]  $C
    set -l cat_func[6] "func passgen"

    set -l cat_cnt (count $cat_name)

    # ── Helper: map function name → category index (0 = uncategorized) ──
    function __func_cat_idx
        set -l f $argv[1]
        switch $f
            case c v n weather;           echo 1
            case cat l p mkgif extract;   echo 2
            case clean cleanreset refresh gdm; echo 3
            case testdrive getdata myip stats calc qr; echo 4
            case matrix hollywood stayawake fish_greeting; echo 5
            case func passgen;            echo 6
            case '*';                     echo 0
        end
    end

    # ── Helper: extract description ──
    function __func_desc
        set -l file $argv[1]
        set -l d (grep -h -- '--description' "$file" 2>/dev/null | head -1 | sed "s/.*--description ['\"]\(.*\)['\"].*/\1/")
        if test -z "$d"
            echo "No description"
        else
            echo "$d"
        end
    end

    # ── Helper: get usage hint ──
    function __func_usage
        set -l u $argv[1]
        switch $u
            case c;       echo "c [file|--recent]"
            case v;       echo "v [file|--recent]"
            case cat;     echo "cat [file|--lang L --line-range :N]"
            case n;       echo "n [--today|--last|file]"
            case weather; echo "weather [--gui|-g]"
            case matrix;  echo "matrix [--color] [--speed=N]"
            case mkgif;   echo "mkgif [--fps=N] [--scale=W:H] input"
            case stayawake; echo "stayawake [dur|--display|--stop]"
            case getdata; echo "getdata [--list|--venv]"
            case clean;   echo "clean [--all|--pip|--dry-run]"
            case gdm;     echo "gdm [-y|--yes|default] [image]  — auto-search | default wallpaper"
            case refresh; echo "refresh [-k|--all|--cache|--dns|--dnf|...]"
            case myip;    echo "myip"
            case stats;   echo "stats"
            case calc;    echo "calc <expr>"
            case qr;      echo "qr <text-or-url>"
            case l;       echo "l [path]"
            case p;       echo "p"
            case extract; echo "extract <archive> [dest]"
            case func;    echo "func [search|show]"
            case passgen; echo "passgen [opts]"
            case '*';     echo "$u"
        end
    end

    # ── Helpers: file metadata ──
    function __func_bytes; wc -c < "$argv[1]" 2>/dev/null | string trim; end
    function __func_lines; wc -l < "$argv[1]" 2>/dev/null | string trim; end

    # ══════════════════════════════════════════════════════════════
    # SUBCOMMANDS:  --help  |  search <kw>  |  show <name>
    # ══════════════════════════════════════════════════════════════

    if set -q argv[1]
        switch $argv[1]
            case --help -h
                echo -e "$Y"
                echo "  ╭──────────────────────────────────────────────────────────╮"
                echo "  │                   🗃️  FUNCTION  ARCHIVE                  │"
                echo "  │                    Usage & Commands                      │"
                echo "  ╰──────────────────────────────────────────────────────────╯"
                echo -e "$N"
                echo -e "  $Y func$N             — List all available functions"
                echo -e "  $Y func search <kw>$N — Find functions matching keyword"
                echo -e "  $Y func show <name>$N — Show full source of a function"
                echo -e "  $Y func --help$N      — This help"
                echo ""
                echo -e "  $D Every function supports $Y--help$N $D— try e.g. $C c --help$N $D or $C testdrive --help$N"
                echo ""
                echo -e "  $D╭─ Categories ──────────────────────────────────────╮$N"
                for ci in (seq $cat_cnt)
                    set -l fl (string split ' ' -- $cat_func[$ci])
                    echo -e "  $D│$N  $cat_esc[$ci]$cat_name[$ci]$N  $D("(count $fl)" functions)$N"
                end
                echo -e "  $D╰────────────────────────────────────────────────────╯$N"
                return 0

            case search
                if not set -q argv[2]
                    echo -e "$R❌ Usage:$Y func search <keyword>$N"
                    return 1
                end
                set -l kw $argv[2]
                set -l sf (ls "$func_dir"/*.fish 2>/dev/null)

                echo ""
                echo -e "  $Y╭─ SEARCH RESULTS ─────────────────────────────────╮$N"
                echo -e "  $Y│   $W\"$kw\"$N"
                echo -e "  $Y╰────────────────────────────────────────────────────╯$N"

                set -l found 0
                for f in $sf
                    set -l sn (string replace -r '\.fish$' '' (basename "$f"))
                    set -l sd (__func_desc "$f")
                    if string match -qir "$kw" "$sn $sd"
                        set -l sci (__func_cat_idx $sn)
                        if test $sci -ge 1 -a $sci -le $cat_cnt
                            printf "  $D│$N  $cat_esc[$sci]%-16s$N $D→$N $W%s$N\n" $sn $sd
                        else
                            printf "  $D│$N  $C%-16s$N $D→$N $W%s$N\n" $sn $sd
                        end
                        set found (math $found + 1)
                    end
                end
                if test $found -eq 0
                    echo -e "  $D│$N  $R✘ No matches for \"$kw\"$N"
                end
                echo -e "  $D╰────────────────────────────────────────────────────╯$N"
                echo -e "\n  $C📦  $found matches$N"
                return 0

            case show
                if not set -q argv[2]
                    echo -e "$R❌ Usage:$Y func show <function_name>$N"
                    return 1
                end
                if functions -q $argv[2]
                    echo ""
                    functions $argv[2]
                    echo ""
                else
                    echo -e "$R❌ No function named '$argv[2]' bestie! That ain't it$N"
                    return 1
                end
                return 0

            case '-*'
                set -l fn_burns
                set fn_burns[1] "BRUH '$Y$argv[1]$Y' is not a func subcommand 💀"
                set fn_burns[2] "'$Y$argv[1]$Y'??? That's not in the archive bestie 💅"
                set fn_burns[3] "SIR THIS IS A FUNCTION ARCHIVE... '$Y$argv[1]$Y' is not here 🍔"
                set fn_burns[4] "The func council voted: '$Y$argv[1]$Y' is DENIED ⚖️"
                set fn_burns[5] "BZZT! '$Y$argv[1]$Y' is not a func command! 🎮💥"
                set -l fn_idx (random 1 5)
                echo -e "$R✘ $fn_burns[$fn_idx]$N"
                echo -e "  $D Try $C""func --help$D bestie 📋$N"
                return 1
        end
    end

    # ══════════════════════════════════════════════════════════════
    # DEFAULT — Full Interactive Archive
    # ══════════════════════════════════════════════════════════════

    # ── Scan all .fish files ──
    set -l all_f (ls "$func_dir"/*.fish 2>/dev/null)
    if test (count $all_f) -eq 0
        echo -e "$R❌ No function files found in $func_dir$N"
        return 1
    end

    set -l fn_n  # names
    set -l fn_d  # descriptions
    set -l fn_u  # usage hints
    set -l fn_l  # line counts
    set -l fn_b  # byte counts
    set -l fn_c  # category index
    set -l tl 0  # total lines
    set -l tb 0  # total bytes

    for f in $all_f
        set -l nm (string replace -r '\.fish$' '' (basename "$f"))
        # Skip internal helpers (starting with __)
        if string match -q '__*' "$nm"
            continue
        end
        set -a fn_n $nm
        set -a fn_d (__func_desc "$f")
        set -a fn_u (__func_usage "$nm")
        set -l lc (__func_lines "$f")
        set -l bc (__func_bytes "$f")
        set -a fn_l $lc
        set -a fn_b $bc
        set tl (math "$tl + $lc")
        set tb (math "$tb + $bc")
        set -a fn_c (__func_cat_idx $nm)
    end

    set -l tf (count $fn_n)
    if test $tf -eq 0
        echo -e "$R❌ No user functions found in $func_dir$N"
        return 1
    end

    # ── Find smallest / largest (by line count) ──
    set -l sm_name "—"
    set -l sm_lines 999999
    set -l lg_name "—"
    set -l lg_lines 0
    for i in (seq $tf)
        if test $fn_l[$i] -lt $sm_lines
            set sm_lines $fn_l[$i]
            set sm_name $fn_n[$i]
        end
        if test $fn_l[$i] -gt $lg_lines
            set lg_lines $fn_l[$i]
            set lg_name $fn_n[$i]
        end
    end

    # ══════════════════════════════════════════════════════════════
    # RENDER — Header
    # ══════════════════════════════════════════════════════════════
    echo ""
    echo -e "  $C╭──────────────────────────────────────────────────────────╮$N"
    echo -e "  $C│                    🗃️  FUNCTION  ARCHIVE                  │$N"
    echo -e "  $C│             Fedora MacTahoe  ·  Eprahemi Edition          │$N"
    echo -e "  $C│          $D$tf functions  ·  $tl lines  ·  $cat_cnt categories          $C│$N"
    echo -e "  $C╰──────────────────────────────────────────────────────────╯$N"
    echo ""

    # ══════════════════════════════════════════════════════════════
    # RENDER — Category Cards
    # ══════════════════════════════════════════════════════════════
    for ci in (seq $cat_cnt)
        set -l esc $cat_esc[$ci]
        set -l cn $cat_name[$ci]
        set -l fl (string split ' ' -- $cat_func[$ci])

        # Count present functions
        set -l pres 0
        for f in $fl
            if contains -- $f $fn_n
                set pres (math $pres + 1)
            end
        end
        if test $pres -eq 0
            continue
        end

        echo -e "  $esc╭─ $cn ($pres) ───────────────────────────────────╮$N"

        for f in $fl
            set -l idx 0
            for i in (seq $tf)
                if test "$fn_n[$i]" = "$f"
                    set idx $i
                    break
                end
            end
            if test $idx -eq 0
                continue
            end

            # Truncate long descriptions
            set -l desc $fn_d[$idx]
            if test (string length "$desc") -gt 50
                set desc (string sub -l 47 "$desc")"..."
            end

            printf "  $esc│$N  $esc%-13s$N  $W%s$N\n" "$f" "$desc"
            printf "  $esc│$N    $D%s Usage: $C%s$N  $D│  %s lines$N\n" " " "$fn_u[$idx]" "$fn_l[$idx]"
        end

        echo -e "  $esc╰────────────────────────────────────────────────────╯$N"
        echo ""
    end

    # ── Uncategorized functions ──
    set -l unc 0
    for i in (seq $tf)
        if test $fn_c[$i] -eq 0
            set unc (math $unc + 1)
        end
    end
    if test $unc -gt 0
        echo -e "  $D╭─ 📦  Other ($unc) ───────────────────────────────────╮$N"
        for i in (seq $tf)
            if test $fn_c[$i] -eq 0
                printf "  $D│$N  $W%-13s$N  $D%s$N\n" $fn_n[$i] $fn_d[$i]
            end
        end
        echo -e "  $D╰────────────────────────────────────────────────────╯$N"
        echo ""
    end

    # ══════════════════════════════════════════════════════════════
    # ══════════════════════════════════════════════════════════════
    # RENDER — Help Footer
    # ══════════════════════════════════════════════════════════════
    echo -e "  $D╭─ 💡  Quick Tips ────────────────────────────────────╮$N"
    echo -e "  $D│$N  $Y--help$N  $D""works on$N $W every$N $D single function$N              $D│$N"
    echo -e "  $D│$N    $D try:$N $C c --help$N    $D|$N $C v --help$N    $D|$N $C n --help$N    $D|$N $C weather --help$N $D│$N"
    echo -e "  $D│$N    $D try:$N $C cat --help$N   $D|$N $C clean --help$N $D|$N $C refresh --help$N $D│$N"
    echo -e "  $D│$N  $Yfunc search$N $W<word>$N    $D— Find functions by name or desc$N  $D│$N"
    echo -e "  $D│$N  $Yfunc show$N $W<name>$N      $D— View full source code$N         $D│$N"
    echo -e "  $D│$N  $Ytype$N $W<name>$N             $D— Quick source peek$N             $D│$N"
    echo -e "  $D╰────────────────────────────────────────────────────╯$N"
    echo ""
    echo -e "  $GY  ╭──────────────────────────────────────────────────────╮$N"
    echo -e "  $GY  │$N  $D↑  Scroll up to see all functions above$N               $GY│$N"
    echo -e "  $GY  ╰──────────────────────────────────────────────────────╯$N"
    echo ""

    # ── Cleanup ──
    functions -e __func_desc __func_usage __func_bytes __func_lines __func_cat_idx
end
