# ════════════════════════════════════════════════════════════════
# doctor.fish — MacTahoe install health check
# Fedora MacTahoe Eprahemi Edition © 2026 — copyright 100%
# ────────────────────────────────────────────────────────────────
# doctor              full health report (state, drift, artifacts)
# doctor manifest     manifest vs installed version summary only
# doctor drift        per-step version drift between state and manifest
# doctor artifacts    presence of themes/icons/fonts/sounds/config
#
# Everything reads from ~/.cache/fedora-mactahoe and standard
# installed locations under $HOME — no hardcoded machine paths.
# ════════════════════════════════════════════════════════════════

function doctor --description "MacTahoe install health check"
    set -l which "all"
    if test (count $argv) -ge 1
        set which $argv[1]
    end

    switch $which
        case manifest
            __doctor_manifest
        case drift
            __doctor_drift
        case artifacts
            __doctor_artifacts
        case all ''
            __doctor_manifest
            __doctor_drift
            __doctor_artifacts
        case '*'
            printf '\n  %serror:%s unknown doctor target: %s\n' (set_color red) (set_color normal) "$which"
            printf '  usage: doctor [manifest | drift | artifacts]\n'
            return 1
    end
end

# ── shared box + color helpers (62 inner width — house standard) ──
function __dr_col
    set -g __dr_C (set_color cyan)
    set -g __dr_K (set_color normal)
    set -g __dr_G (set_color green)
    set -g __dr_R (set_color red)
    set -g __dr_Y (set_color yellow)
    set -g __dr_W (set_color white)
    set -g __dr_D (set_color brblack)
end

function __dr_top
    printf '  %s╔%s╗%s\n' $__dr_C (string repeat -n 62 '═') $__dr_K
end

function __dr_bot
    printf '  %s╚%s╝%s\n' $__dr_C (string repeat -n 62 '═') $__dr_K
end

function __dr_sep
    printf '  %s╠%s╣%s\n' $__dr_C (string repeat -n 62 '═') $__dr_K
end

function __dr_title
    set -l t $argv[1]
    set -l len (string length -- $t)
    set -l pl (math "(62 - $len) / 2" | string replace -r '\..*' '')
    set -l pr (math "62 - $len - $pl")
    printf '  %s║%s%*s%s%*s%s║%s\n' $__dr_C $__dr_W $pl '' $t $pr '' $__dr_C $__dr_K
end

function __dr_line
    set -l txt $argv[1]
    set -l col $__dr_W
    if test (count $argv) -ge 2
        set col $argv[2]
    end
    set -l len (string length -- $txt)
    printf '  %s║%s  %s%*s%s║%s\n' $__dr_C $col $txt (math "60 - $len") '' $__dr_C $__dr_K
end

function __dr_blank
    __dr_line ""
end

# ── read a key from a JSON cache file (empty on failure/short-circuit) ──
function __dr_json
    set -l file $argv[1]
    set -l key $argv[2]
    if not test -f "$file"
        return 1
    end
    python3 -c 'import json,sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
    v = d
    for k in sys.argv[2].split("."):
        v = v.get(k, "")
        if v == "":
            break
    print(v if not isinstance(v, (dict, list)) else "")
except Exception:
    pass' "$file" "$key"
end

# ── manifest vs installed version summary ──
function __doctor_manifest
    __dr_col
    set -l man "$HOME/.cache/fedora-mactahoe/latest-manifest.json"
    set -l state "$HOME/.cache/fedora-mactahoe/install-state.json"

    set -l latest (__dr_json "$man" "latest_version")
    set -l installed (__dr_json "$state" "version")
    test -z "$latest"; and set latest "?"
    test -z "$installed"; and set installed "none"

    # semantic compare: installed < latest ?
    set -l has_update "?"
    if test "$latest" != "?" ; and test "$installed" != "none"
        if python3 -c 'import sys
def vk(v):
    try: return tuple(int(x) for x in str(v).split("."))
    except Exception: return (0,)
a,b = sys.argv[1], sys.argv[2]
sys.exit(0 if vk(a) < vk(b) else 1)' "$installed" "$latest"
            set has_update "yes"
        else
            set has_update "no"
        end
    end

    printf '\n'
    __dr_top
    __dr_title "MACTAHOE — MANIFEST"
    __dr_sep
    __dr_line "Installed version   " $__dr_W
    __dr_line "  $installed" $__dr_Y
    __dr_line "Latest available   " $__dr_W
    __dr_line "  $latest" $__dr_C
    __dr_line "Update available   " $__dr_W
    switch "$has_update"
        case yes
            __dr_line "  yes — run 'update'" $__dr_G
        case no
            __dr_line "  no — you're current" $__dr_G
        case '*'
            __dr_line "  unknown" $__dr_Y
    end
    __dr_line ""
    __dr_line "install-state.json  " $__dr_W
    if test -f "$state"
        __dr_line "  present" $__dr_G
    else
        __dr_line "  missing" $__dr_R
    end
    __dr_line "manifest (cached)   " $__dr_W
    if test -f "$man"
        __dr_line "  present" $__dr_G
    else
        __dr_line "  missing (run 'update' to fetch it)" $__dr_Y
    end
    __dr_bot
    printf '\n'
end

# ── per-step version drift between state and manifest ──
function __doctor_drift
    __dr_col
    set -l man "$HOME/.cache/fedora-mactahoe/latest-manifest.json"
    set -l state "$HOME/.cache/fedora-mactahoe/install-state.json"
    if not test -f "$man"; or not test -f "$state"
        printf '\n  %s\n    %s\n    %s\n' \
            (set_color yellow) "Both the manifest and install-state are needed for drift check." \
            "Run 'update' once to fetch the manifest, then re-run 'doctor drift'."
        set_color normal
        return 1
    end
    set -l rows (python3 -c '
import json, sys
man = json.load(open(sys.argv[1], encoding="utf-8"))
state = json.load(open(sys.argv[2], encoding="utf-8"))
ms = man.get("steps") or {}
ss = state.get("steps") or {}
for k in sorted(set(ms) | set(ss)):
    mv = str(ms.get(k, ""))
    sv = str(ss.get(k, ""))
    if not mv and not sv:
        continue
    flag = "OK"
    if mv and sv and mv != sv:
        flag = "DRIFT"
    elif mv and not sv:
        flag = "MISSING"
    elif sv and not mv:
        flag = "EXCESS"
    print("%s|%s|%s|%s" % (k, sv, mv, flag))
' "$man" "$state")
    if test -z "$rows"
        printf '\n  %sNo steps to compare.%s\n' (set_color yellow) (set_color normal)
        return 0
    end
    printf '\n'
    __dr_top
    __dr_title "MACTAHOE — STEP DRIFT"
    __dr_sep
    __dr_line "step                          installed   wanted   state" $__dr_D
    for row in $rows
        set -l parts (string split '|' -- $row)
        set -l k $parts[1]
        set -l inst $parts[2]
        set -l want $parts[3]
        set -l flag $parts[4]
        set -l col $__dr_G
        switch $flag
            case DRIFT
                set col $__dr_Y
            case MISSING
                set col $__dr_R
            case EXCESS
                set col $__dr_D
        end
        set -l name (string sub -l 28 -- $k)
        # interior must total exactly 62: 2 indent + 28 + 2 + 8 + 2 + 8 + 2 + flag + pad
        set -l prefix (printf '%-28s  %-8s  %-8s  ' $name $inst $want)
        set -l prefix_len (string length -- $prefix)
        set -l flag_len (string length -- $flag)
        set -l flag_pad (math "62 - 2 - $prefix_len - $flag_len")
        printf '  %s║%s  %s%s%s%s%*s%s║%s\n' \
            $__dr_C $__dr_W $prefix $__dr_K $col $flag $flag_pad '' $__dr_K $__dr_C
    end
    __dr_bot
    printf '\n'
end

# ── presence of shipped artifacts under $HOME ──
function __doctor_artifacts
    __dr_col
    set -l icons "$HOME/.local/share/icons"
    set -l themes "$HOME/.themes"
    set -l fonts "$HOME/.local/share/fonts"
    set -l cfg "$HOME/.config"

    set -l checks
    set -a checks "Icon theme   MacTahoe"        (test -d "$icons/MacTahoe";    and echo ok; or echo miss)
    set -a checks "Icon dark    MacTahoe-dark"   (test -d "$icons/MacTahoe-dark"; and echo ok; or echo miss)
    set -a checks "Theme        MacTahoe-Dark"   (test -d "$themes/MacTahoe-Dark"; and echo ok; or echo miss)
    set -a checks "Font         SF Pro Regular"  (test -f "$fonts/SF-Pro-Display-Regular.otf"; and echo ok; or echo miss)
    set -a checks "GDM fish fn  gdm.fish"        (test -f "$cfg/fish/functions/gdm.fish"; and echo ok; or echo miss)
    set -a checks "Updater fn   update.fish"     (test -f "$cfg/fish/functions/update.fish"; and echo ok; or echo miss)
    set -a checks "Doctor fn    doctor.fish"     (test -f "$cfg/fish/functions/doctor.fish"; and echo ok; or echo miss)
    set -a checks "Kitty conf   kitty.conf"      (test -f "$cfg/kitty/kitty.conf"; and echo ok; or echo miss)

    printf '\n'
    __dr_top
    __dr_title "MACTAHOE — ARTIFACTS"
    __dr_sep
    set -l i 1
    while test $i -le (count $checks)
        set -l label $checks[$i]
        set -l val $checks[(math $i + 1)]
        set -l col $__dr_G
        test "$val" = "miss"; and set col $__dr_R
        __dr_line "$label" $__dr_W
        __dr_line "  $val" $col
        set i (math $i + 2)
    end
    __dr_line ""
    if test -f "$cfg/fish/functions/gdm.fish"
        set -l ghash (sha256sum "$cfg/fish/functions/gdm.fish" 2>/dev/null | string split ' ' -f1)
        __dr_line "live gdm.fish sha256" $__dr_W
        if test -n "$ghash"
            __dr_line "  "(string sub -l 16 -- $ghash)"…" $__dr_D
        end
    end
    __dr_bot
    printf '\n'
end
