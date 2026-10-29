# ══════════════════════════════════════════════════════════════
# update 🚀 — Fedora MacTahoe updater
# Kitty-only. Shows what's new, then offers a
# menu: quick / full reinstall / configs-only / just checking.
#   update           → open the menu
#   update check     → status at a glance, no prompts
#   update configs   → refresh kitty, fish, updater, fastfetch files only
#   update quick     → incremental update, saved answers, no prompts
#   update full      → full reinstall from scratch
#   update uninstall → guarded full removal (typed word + 30s countdown)
#   update log       → your update history
#   update menu      → pick any target from a numbered list
#   update help      → this box
# Per-target toolbox — re-run ONE part of the setup:
#   update icons      → icon themes + custom macOS app icons
#   update theme      → recompile the GTK theme for current GNOME
#   update fonts      → reinstall SF Pro Display
#   update sounds     → reinstall the Big Sur sounds
#   update gtk        → GTK settings + Flatpak GTK runtime
#   update extensions → reinstall all GNOME extensions from EGO
#   update wallpaper  → normal / +18 pack picker, reinstalls wallpapers
#   update pfp        → normal / +18 pack picker, reinstalls profile pics
#   update gdm        → re-apply the GDM login theme
#   update videos     → re-download the optional video edits
#   update services   → re-apply RAM-saving service tweaks
#   update defaults   → desktop renames + Celluloid + Nautilus defaults
#   update dconf      → re-apply GNOME settings from the bundle
#   update notifier   → reinstall the update notifier
#   update clean      → flush caches and trim logs
# Same as clicking "Update Now" on the notification popup.
# Fedora MacTahoe Eprahemi Edition © 2026
# ══════════════════════════════════════════════════════════════

# The installer and updater share bootstrap.sh's presentation engine. Keep a
# local library after configuration refresh; never download executable UI code
# merely to manage apps. An older installation without it gets plain status.
set -g __update_source (status filename)

function _update_ui_publish --argument-names mode
    set -q __update_ui_dir; or return 0
    set -g __update_ui_seq (math $__update_ui_seq + 1)
    begin
        printf '%s\t%s\n' $__update_ui_seq "$mode"
        for i in (seq (count $__update_ui_labels))
            printf '%s\t%s\n' "$__update_ui_states[$i]" "$__update_ui_labels[$i]"
        end
    end > "$__update_ui_dir/next"
    command mv -f "$__update_ui_dir/next" "$__update_ui_dir/state"
    # Acknowledge terminal ownership, not an animation delay. Fail to plain mode
    # if the painter exits or cannot acknowledge; never leave native input hidden.
    for tick in (seq 250)
        if test -f "$__update_ui_dir/ack"; and test (string trim < "$__update_ui_dir/ack") = "$__update_ui_seq"
            return 0
        end
        command kill -0 $__update_ui_pid 2>/dev/null; or break
        sleep 0.02
    end
    command kill -TERM $__update_ui_pid 2>/dev/null
    wait $__update_ui_pid 2>/dev/null
    command rm -rf -- "$__update_ui_dir"
    set -e __update_ui_dir
    printf '\e[0m\e[?25h\e[?1049l' >/dev/tty 2>/dev/null
end

function _update_ui_begin --argument-names retry library
    # No reentrant/competing painters (installer-backed targets own their UI).
    set -q __update_ui_log; and return 0
    if test -n "$library"
        set -l manifest (path dirname "$library")/updates.json
        set -l expected (python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["bootstrap_sha256"])' "$manifest")
        or return 1
        if test (string length -- "$expected") -ne 64; or test (_update_sha256 "$library") != "$expected"
            printf '\n  UI library fingerprint mismatch. No configuration work started.\n' >&2
            return 1
        end
    end
    set -g __update_ui_labels $argv[3..-1]
    set -g __update_ui_states
    for label in $__update_ui_labels
        set -a __update_ui_states waiting
    end
    set -g __update_ui_current 1
    set -g __update_ui_failed 0
    set -g __update_ui_cancel 0
    set -g __update_ui_retry "$retry"
    set -g __update_ui_seq 0
    if set -q __update_fetch_log
        set -g __update_ui_log "$__update_fetch_log"
        set -e __update_fetch_log
    else
        set -g __update_ui_log (mktemp "$HOME/FedoraTahoe_log."(date +%Y-%m-%d.%H-%M-%S)".XXXXXXXX ( UPDATE ).txt")
        or return 1
    end
    chmod 600 "$__update_ui_log"
    printf 'Fedora MacTahoe — %s\nNative authentication/input is never recorded. Native interactive output remains on the terminal.\n' "$retry" >> "$__update_ui_log"
    if test -z "$library"
        set library "$HOME/.local/share/fedora-mactahoe/ui-library.sh"
        # Bundled developer execution, not a remote fetch or installed setting.
        set -l bundled (path normalize (path dirname "$__update_source")/../../../bootstrap.sh)
        if string match -q '*/configs/fish/functions/update.fish' -- "$__update_source"; and test -f "$bundled"
            set library "$bundled"
        end
    end
    # A pre-dashboard bootstrap ignores unknown arguments and would INSTALL.
    # Never execute an older library merely because its fingerprint is valid.
    if test -t 1; and test -t 2; and test "$TERM" != dumb; and test -f "$library"; and command grep -Fq 'if [ "${1:-}" = --ui-events ]; then' "$library"
        set -g __update_ui_dir (mktemp -d /tmp/mactahoe-ui.XXXXXXXX)
        bash "$library" --ui-events "$__update_ui_dir" "$__update_ui_log" "$fish_pid" "$retry" &
        set -g __update_ui_pid $last_pid
        _update_ui_publish work
    end
    function __update_ui_interrupt --on-signal INT
        if set -q __update_ui_pid
            command kill -TERM $__update_ui_pid 2>/dev/null
        end
        set -g __update_ui_failed 1
        set -g __update_ui_cancel 1
    end
end

function _update_ui_task --argument-names index state
    set -q __update_ui_log; or return 0
    test "$__update_ui_cancel" = 1; and return 130
    set -g __update_ui_current $index
    test "$state" = failed; and set -g __update_ui_failed 1
    # A later successful command cannot turn a failed task green.
    if test "$__update_ui_states[$index]" != failed
        set -g __update_ui_states[$index] "$state"
    end
    printf '%s: %s\n' "$__update_ui_states[$index]" "$__update_ui_labels[$index]" >> "$__update_ui_log"
    if set -q __update_ui_dir
        _update_ui_publish work
    else
        printf '  %s: %s\n' "$__update_ui_states[$index]" "$__update_ui_labels[$index]"
    end
end

function _update_ui_quiet
    # ONLY audited, noninteractive local file/query/download operations use this.
    # Never wrap a whole updater function or a native package/auth transaction.
    if set -q __update_ui_cancel; and test "$__update_ui_cancel" = 1
        return 130
    end
    if not set -q __update_ui_log
        $argv
        return $status
    end
    set -l rc 0
    if test -t 1; and test -t 2
        $argv >> "$__update_ui_log" 2>&1
        set rc $status
    else
        $argv 2>&1 | tee -a "$__update_ui_log"
        set rc $pipestatus[1]
    end
    if test $rc -ne 0
        set -g __update_ui_failed 1
        _update_ui_task $__update_ui_current failed
        _update_ui_publish pause
        printf '\n  Failed: %s (exit %s). Retry: %s\n  Details: %s\n' "$__update_ui_labels[$__update_ui_current]" $rc "$__update_ui_retry" "$__update_ui_log" >&2
    end
    return $rc
end

function _update_ui_native
    # Preserve actual TTY fds and stdin: tee/blanket redirection changes native
    # isatty decisions and can hide consent. No password reader/proxy is added.
    if set -q __update_ui_cancel; and test "$__update_ui_cancel" = 1
        return 130
    end
    _update_ui_publish pause
    $argv
    set -l rc $status
    if test $rc -eq 130
        set -g __update_ui_cancel 1
    end
    if set -q __update_ui_log
        printf 'Native foreground operation exited %s (interactive output not captured).\n' $rc >> "$__update_ui_log"
        if test $rc -ne 0
            set -g __update_ui_failed 1
            _update_ui_task $__update_ui_current failed
            _update_ui_publish pause
        end
    end
    return $rc
end

function _update_ui_end --argument-names code
    set -q __update_ui_log; or return $code
    test "$__update_ui_cancel" = 1; and set code 130
    if test "$code" -ne 0
        set -g __update_ui_failed 1
    end
    if set -q __update_ui_dir
        if test "$code" -eq 130
            _update_ui_publish abort
        else if test "$code" -ne 0; or test "$__update_ui_failed" -ne 0
            _update_ui_publish failed
        else
            _update_ui_publish finish
        end
        wait $__update_ui_pid 2>/dev/null
        set -q __update_ui_dir; and command rm -rf -- "$__update_ui_dir"
    else
        printf '\n  Fedora MacTahoe — task results\n'
        for i in (seq (count $__update_ui_labels))
            printf '  %s: %s\n' "$__update_ui_states[$i]" "$__update_ui_labels[$i]"
        end
        printf '  Log: %s\n' "$__update_ui_log"
    end
    printf 'Operation exit: %s; task failures: %s\n' $code $__update_ui_failed >> "$__update_ui_log"
    command sed -i 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$__update_ui_log"
    set -l failed $__update_ui_failed
    set -e __update_ui_log __update_ui_dir __update_ui_pid __update_ui_cancel
    functions -e __update_ui_interrupt
    test $code -ne 0; and return $code
    return $failed
end

# ── fetch updates.json into the cache; rc 0 = got it ──
# Stage and validate complete responses before atomic cache publication.
# The API is a fallback transport, not a separate signature/trust authority.
function _update_validate_manifest --argument-names file
    command python3 -I -c 'import json,re,sys
def unique(pairs):
    d = {}
    for k,v in pairs:
        if k in d: raise ValueError("duplicate key")
        d[k] = v
    return d
try:
    with open(sys.argv[1]) as f: d=json.load(f, object_pairs_hook=unique)
    assert isinstance(d,dict)
    assert isinstance(d.get("latest_version"),str) and re.fullmatch(r"[0-9]+(?:\.[0-9]+)*",d["latest_version"])
    for k in ("bootstrap_sha256","install_sha256","update_sha256","asset_helper_sha256"):
        assert isinstance(d.get(k),str) and re.fullmatch(r"[0-9a-f]{64}",d[k])
except Exception:
    sys.exit(1)' "$file"
end

function _update_fetch_manifest --description 'fetch the version manifest from GitHub'
    set -l cache_dir "$HOME/.cache/fedora-mactahoe"
    mkdir -p "$cache_dir"; or return 1
    set -l stage (mktemp -d "$cache_dir/.manifest.XXXXXXXX")
    or return 1
    set -l url "https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/updates.json"
    set -l valid 0
    if command curl -q -fsSL --proto '=https' --proto-redir '=https' --max-redirs 3 --connect-timeout 5 --max-time 15 --max-filesize 1048576 "$url" -o "$stage/manifest.json"
        if _update_validate_manifest "$stage/manifest.json"
            set valid 1
        end
    end
    if test $valid -eq 0
        if command curl -q -fsSL --proto '=https' --proto-redir '=https' --max-redirs 3 --connect-timeout 5 --max-time 20 --max-filesize 2097152 "https://api.github.com/repos/eprahemi/Fedora-MacTahoe-Eprahemi/contents/updates.json?ref=main" -o "$stage/api.json"
            if command python3 -I -c 'import json,sys,base64
try:
    d = json.load(open(sys.argv[1]))
    assert d["encoding"] == "base64" and isinstance(d["content"],str)
    content = base64.b64decode("".join(d["content"].split()), validate=True)
    assert len(content) <= 1048576
    open(sys.argv[2], "wb").write(content)
except Exception:
    sys.exit(1)' "$stage/api.json" "$stage/manifest.json"
                if _update_validate_manifest "$stage/manifest.json"
                    set valid 1
                end
            end
        end
    end
    set -l result 1
    if test $valid -eq 1
        command mv -f -- "$stage/manifest.json" "$cache_dir/latest-manifest.json"
        set result $status
    end
    command rm -rf -- "$stage"
    return $result
end

# ── sha256 hex of a file (empty on failure) — the fingerprint ──
function _update_sha256 --description 'sha256 hex of a file (empty on failure)'
    set -l file "$argv[1]"
    if not test -f "$file"
        return 1
    end
    if not command -q sha256sum
        return 1
    end
    sha256sum "$file" 2>/dev/null | string split ' ' -f1
end

# ── pinned sha256 for a key in the cached manifest (bootstrap_sha256 / update_sha256) ──
function _update_manifest_hash --description 'pinned sha256 for a key in the cached manifest'
    set -l key "$argv[1]"
    set -l man "$HOME/.cache/fedora-mactahoe/latest-manifest.json"
    if not test -f "$man"
        return 1
    end
    _update_validate_manifest "$man"; or return 1
    command python3 -I -c 'import json,re,sys
try:
    value=json.load(open(sys.argv[1]))[sys.argv[2]]
    assert isinstance(value,str) and re.fullmatch(r"[0-9a-f]{64}",value)
    print(value)
except Exception:
    sys.exit(1)' "$man" "$key"
end

# ── fingerprint trust: first run saves silently; a change asks for trust ──
# returns 0 = safe to run the installer
function _update_fingerprint_check --description 'trust-store check for the installer hash'
    set -l hash "$argv[1]"
    set -l trust_file "$HOME/.cache/fedora-mactahoe/trusted-bootstrap-hash"
    mkdir -p "$HOME/.cache/fedora-mactahoe"
    if not test -f "$trust_file"
        printf '%s\n' "$hash" > "$trust_file"
        chmod 600 "$trust_file"
        printf "\n  \e[2;37mFirst verified run — installer fingerprint %s… saved.\e[0m\n" (string sub -l 16 -- $hash)
        return 0
    end
    set -l old (string trim < "$trust_file")
    if test "$old" = "$hash"
        return 0
    end
    printf "\n"
    _update_box_top
    _update_box_title "NEW INSTALLER FINGERPRINT" "1;36"
    _update_box_rule
    _update_box_text "This fingerprint differs from your saved version." "1;37"
    _update_box_text "  before  "(string sub -l 16 -- $old)"…" "2;37"
    _update_box_text "  now     "(string sub -l 16 -- $hash)"…" "1;37"
    _update_box_text ""
    _update_box_text "The download matches the published manifest." "1;37"
    _update_box_text "A new release normally changes this fingerprint." "2;37"
    _update_box_text ""
    _update_box_text "Continue with this version?" "1;37"
    _update_box_text "y = yes   n = no (default)" "1;37"
    _update_box_bottom
    read -l fpr -P "  Your choice [y/N]: "
    if test $status -ne 0
        printf "\n  \e[1;31m✘ Cancelled.\e[0m\n"
        return 1
    end
    switch $fpr
        case y Y yes Yes YES
            printf '%s\n' "$hash" > "$trust_file"
            chmod 600 "$trust_file"
            return 0
        case '*'
            printf "\n  \e[1;31m✘ Refused — the installer was NOT run.\e[0m\n"
            return 1
    end
end

# ── diff installed state against the manifest ──
# emits: LATEST=… HASUPDATE=0|1  then CH=… rows and ST=… rows
function _update_parse --description 'compare installed state to the manifest'
    set -l _script '
import json, os, sys

man_path, state_path = sys.argv[1], sys.argv[2]

def vk(v):
    try:
        return tuple(int(x) for x in str(v).split("."))
    except Exception:
        return (0,)

try:
    with open(man_path) as fh:
        man = json.load(fh)
except Exception:
    sys.exit(1)

cur = "0.0"
sstate = {}
if os.path.exists(state_path):
    try:
        with open(state_path) as fh:
            data = json.load(fh)
        cur = str(data.get("version") or "0.0")
        sstate = data.get("steps") or {}
    except Exception:
        pass

latest = str(man.get("latest_version") or "")
print("LATEST=" + latest)
print("HASUPDATE=" + ("1" if latest and vk(latest) > vk(cur) else "0"))

def wrap(text, width=57):
    words = text.split()
    lines, curline = [], ""
    for w in words:
        if curline and len(curline) + 1 + len(w) > width:
            lines.append(curline)
            curline = w
        elif curline:
            curline += " " + w
        else:
            curline = w
    if curline:
        lines.append(curline)
    return lines or [""]

# changelog rows newer than the installed version
rows = []
for entry in man.get("changelog", []):
    ver = str(entry.get("version") or "")
    if not ver or not (vk(ver) > vk(cur)):
        continue
    for change in entry.get("changes", []):
        for i, chunk in enumerate(wrap(change)):
            rows.append(("• " if i == 0 else "  ") + chunk)
for i, row in enumerate(rows):
    if i >= 12:
        print("CH=… and more in the full notes")
        break
    print("CH=" + row)
'
    python3 -c "$_script" "$HOME/.cache/fedora-mactahoe/latest-manifest.json" "$HOME/.cache/fedora-mactahoe/install-state.json"
end

# ── box drawing (house style, 62 inner width) ──
function _update_box_top --description 'top border'
    printf '  \e[1;36m╔%s╗\e[0m\n' (string repeat -n 62 '═')
end

function _update_box_bottom --description 'bottom border'
    printf '  \e[1;36m╚%s╝\e[0m\n' (string repeat -n 62 '═')
end

function _update_box_rule --description 'divider'
    printf '  \e[1;36m╠%s╣\e[0m\n' (string repeat -n 62 '═')
end

function _update_box_text --description 'one padded row; optional color like 1;33'
    set -l txt "$argv[1]"
    set -l col "$argv[2]"
    set -l pad (math "61 - "(string length -- "$txt"))
    if test $pad -lt 0
        set pad 0
    end
    if test -n "$col"
        printf '  \e[%sm║ %s\e[0m%*s║\e[0m\n' $col "$txt" $pad ""
    else
        printf '  ║ %s%*s║\n' "$txt" $pad ""
    end
end

function _update_box_title --description 'centered title row; color like 1;36'
    set -l title "$argv[1]"
    set -l col "$argv[2]"
    set -l hl (string length -- "$title")
    set -l hleft (math -s0 "(62 - $hl) / 2")
    set -l hright (math "62 - $hl - $hleft")
    if test $hleft -lt 0
        set hleft 0
    end
    if test $hright -lt 0
        set hright 0
    end
    printf '  \e[%sm║%s%s%s║\e[0m\n' $col (string repeat -n $hleft ' ') "$title" (string repeat -n $hright ' ')
end

function _update_header --description 'box top + centered title + divider'
    _update_box_top
    _update_box_title "$argv[1]" "1;36"
    _update_box_rule
end

function _update_box_tag --description 'section tag row: diamond + bold label'
    set -l txt "$argv[1]"
    set -l pad (math "58 - "(string length -- "$txt"))
    if test $pad -lt 0
        set pad 0
    end
    printf '  ║  \e[1;36m◈\e[0m \e[1;37m%s\e[0m%*s║\n' "$txt" $pad ""
end

function _update_box_cloud --description 'bold gray tag-cloud row'
    set -l txt "$argv[1]"
    set -l pad (math "58 - "(string length -- "$txt"))
    if test $pad -lt 0
        set pad 0
    end
    printf '  ║    \e[1;90m%s\e[0m%*s║\n' "$txt" $pad ""
end

function _update_box_cmd --description 'command row: bold name + bold gray description, two aligned columns'
    set -l name "$argv[1]"
    set -l desc "$argv[2]"
    set -l nl (string length -- "$name")
    set -l npad (math "22 - $nl")
    if test $npad -lt 0
        set npad 0
    end
    set -l dl (string length -- "$desc")
    set -l dpad (math "37 - $dl")
    if test $dpad -lt 0
        set dpad 0
    end
    printf '  ║  \e[1;37m%s\e[0m%*s \e[1;90m%s\e[0m%*s║\n' "$name" $npad "" "$desc" $dpad ""
end

function _update_box_gradient_title --description 'centered two-tone title'
    set -l total (math "1 + 3 + 6 + 1 + 1 + 1 + 4 + 3 + 1")
    set -l hleft (math -s0 "(62 - $total) / 2")
    set -l hright (math "62 - $total - $hleft")
    printf '  ║%s\e[1;36m◈\e[0m   \e[1;96mUPDATE\e[0m \e[1;36m—\e[0m \e[1;95mHELP\e[0m   \e[1;36m◈\e[0m%s║\n' (string repeat -n $hleft ' ') (string repeat -n $hright ' ')
end

# ── per-target gradient title: ◈ UPDATE <target> — HELP ◈ ──
function _update_box_gradient_title_target --description 'centered two-tone title with the target name in bold white'
    set -l target "$argv[1]"
    set -l tl (string length -- "$target")
    set -l total (math "1 + 3 + 6 + 1 + $tl + 1 + 1 + 1 + 4 + 3 + 1")
    set -l hleft (math -s0 "(62 - $total) / 2")
    set -l hright (math "62 - $total - $hleft")
    printf '  ║%s\e[1;36m◈\e[0m   \e[1;96mUPDATE\e[0m \e[1;37m%s\e[0m \e[1;36m—\e[0m \e[1;95mHELP\e[0m   \e[1;36m◈\e[0m%s║\n' (string repeat -n $hleft ' ') "$target" (string repeat -n $hright ' ')
end

# ── history log ──
function _update_log_add --description 'append one line to the update history'
    set -l mode $argv[1]
    set -l frm $argv[2]
    set -l to $argv[3]
    set -l res $argv[4]
    set -l tagl ""
    # optional 5th arg: the entry-method tag (UPDATE-QUICK, UPDATE-FULL,
    # UPDATE-CONFIG, UPDATE-ICONS, ...) — same marker as the log filename
    if set -q argv[5]
        set tagl " ( "$argv[5]" )"
    end
    set -l logf "$HOME/.cache/fedora-mactahoe/update-history.log"
    mkdir -p "$HOME/.cache/fedora-mactahoe"
    printf '%s | %s%s | %s → %s | %s\n' (date "+%Y-%m-%d %H:%M") $mode $tagl $frm $to $res >> "$logf"
end

function _update_last_update --description 'the most recent history line, if any'
    set -l logf "$HOME/.cache/fedora-mactahoe/update-history.log"
    if test -f "$logf"
        tail -n 1 "$logf"
    end
end

# ── battery guard: 1 if unplugged and below 20% ──
function _update_low_battery --description 'is the machine on dying battery?'
    set -l bat (ls /sys/class/power_supply/ 2>/dev/null | string match -r '^BAT' | head -1)
    if test -z "$bat"
        echo 0
        return
    end
    set -l st_file "/sys/class/power_supply/$bat/status"
    set -l cap_file "/sys/class/power_supply/$bat/capacity"
    if not test -r "$st_file"; or not test -r "$cap_file"
        echo 0
        return
    end
    set -l st (cat "$st_file")
    set -l cap (cat "$cap_file")
    if test "$st" = Discharging; and test $cap -lt 20
        echo 1
    else
        echo 0
    end
end

# Compatibility hook for existing callers: the old timed ritual invented both
# work and percentages after the real check had already finished. No fake work.
function _update_loading --description 'legacy presentation hook (no artificial delay)'
    return 0
end

# ── update check: status at a glance, no prompts ──
function _update_check --description 'show versions + what is waiting'
    if not _update_fetch_manifest
        printf "\n  \e[1;31m✘ Could not fetch a complete, valid version manifest. Nothing was run.\e[0m\n"
        return 1
    end
    set -l current_ver "0.0"
    if test -f "$HOME/.cache/fedora-mactahoe/install-state.json"
        set current_ver (cat "$HOME/.cache/fedora-mactahoe/install-state.json" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('version', '0.0'))
except Exception:
    print('0.0')
" 2>/dev/null)
    end
    set -l latest_ver ""
    set -l has_update 0
    set -l st_count 0
    for line in (_update_parse)
        switch $line
            case 'LATEST=*'
                set latest_ver (string replace 'LATEST=' '' -- $line)
            case 'HASUPDATE=*'
                set has_update (string replace 'HASUPDATE=' '' -- $line)
            case 'ST=*'
                set st_count (math $st_count + 1)
        end
    end
    printf "\n"
    if not _update_loading
        return 1
    end
    _update_header "FEDORA MACTAHOE UPDATER"
    _update_box_text "Installed:  $current_ver"
    _update_box_text "Available:  $latest_ver"
    _update_box_rule
    if test "$has_update" -eq 0
        _update_box_text "✓ You're on the latest version." "1;32"
        set -l last (_update_last_update)
        if test -n "$last"
            _update_box_text "last update: $last" "1;37"
        end
    else
        _update_box_text "An update is available — run 'update' to apply it." "1;33"
        _update_box_text "steps waiting: $st_count" "1;33"
    end
    _update_box_text "Made by eprahemi — Fedora MacTahoe © 2026" "1;37"
    _update_box_bottom
    printf "\n"
    return 0
end

# ── update log: your history ──
function _update_log_show --description 'show the last updates'
    printf "\n"
    _update_header "UPDATE HISTORY"
    set -l logf "$HOME/.cache/fedora-mactahoe/update-history.log"
    if not test -f "$logf"
        _update_box_text "No updates yet — your system is fresh."
    else
        set -l lines (tail -n 10 "$logf")
        if test -z "$lines"
            _update_box_text "No updates yet — your system is fresh."
        else
            for ln in $lines
                _update_box_text "$ln"
            end
        end
    end
    _update_box_text "Made by eprahemi — Fedora MacTahoe © 2026" "1;37"
    _update_box_bottom
    printf "\n"
    return 0
end

# ── update help ──
function _update_usage --description 'the help box'
    printf "\n"
    _update_box_top
    _update_box_gradient_title
    _update_box_rule
    _update_box_text ""
    _update_box_tag "CORE COMMANDS"
    _update_box_text ""
    _update_box_cmd "update" "open the updater menu"
    _update_box_cmd "update check" "status at a glance, no prompts"
    _update_box_cmd "update configs" "kitty · fish · updater · fastfetch"
    _update_box_cmd "update quick" "incremental, keeps saved answers"
    _update_box_cmd "update full" "full reinstall from scratch"
    _update_box_cmd "update uninstall" "guarded removal — word + countdown"
    _update_box_cmd "update log" "your update history"
    _update_box_cmd "update menu" "pick any target from a list"
    _update_box_text ""
    _update_box_tag "PER-TARGET TOOLBOX"
    _update_box_text ""
    _update_box_cloud "icons · theme · fonts · sounds · gtk · extensions"
    _update_box_cloud "wallpaper · pfp · gdm · videos · services · defaults"
    _update_box_cloud "dconf · notifier · clean · wallvault · apps"
    _update_box_text ""
    _update_box_tag "EXTRA FLAGS"
    _update_box_text ""
    _update_box_cmd "update wallpaper add" "install the other pack alongside"
    _update_box_cmd "update wallpaper both" "wipe both, fresh install of both"
    _update_box_cmd "update wallvault" "deploy the 500+ wallpaper vault"
    _update_box_cmd "update wallvault <url>" "register a custom endpoint"
    _update_box_cmd "update wallvault pass" "store an archive key (optional)"
    _update_box_cmd "update pfp add" "same for profile pictures"
    _update_box_cmd "update pfp both" "wipe both packs, fresh install"
    _update_box_cmd "update <target> help" "details for one part"
    _update_box_cmd "update help <target>" "same box, flipped order"
    _update_box_cmd "update help" "this box"
    _update_box_text ""
    _update_box_rule
    _update_box_title "Made by eprahemi — Fedora MacTahoe © 2026" "1;90"
    _update_box_bottom
    printf "\n"
    return 0
end

# ── per-target help: update <target> help ──
# Shows what the target does, what it asks, its flags and whether a
# fresh session is needed. Read-only: never prompts, never fetches,
# never touches state or files.
function _update_target_help --description 'per-target help box'
    set -l target "$argv[1]"
    printf "\n"
    _update_box_top
    _update_box_gradient_title_target "$target"
    _update_box_rule
    _update_box_text ""
    _update_box_tag "WHAT IT DOES"
    _update_box_text ""
    switch "$target"
        case icons
            _update_box_text "Reinstalls the MacTahoe icon themes (light + dark)" "1;37"
            _update_box_text "plus the custom app icons — everything icon" "1;37"
            _update_box_text "related gets refreshed from the bundle." "1;37"
            _update_box_text ""
            _update_box_tag "NOTES"
            _update_box_text ""
            _update_box_text "No questions asked. Needs a fresh session so" "1;33"
            _update_box_text "all open apps pick up the new icons." "1;33"
        case theme
            _update_box_text "Recompiles the MacTahoe GTK theme from source" "1;37"
            _update_box_text "for your current GNOME version — the theme is" "1;37"
            _update_box_text "built fresh, not copied from a prebuilt pack." "1;37"
            _update_box_text ""
            _update_box_tag "NOTES"
            _update_box_text ""
            _update_box_text "No questions asked. Needs a fresh session so" "1;33"
            _update_box_text "every app re-reads the new theme." "1;33"
        case fonts
            _update_box_text "Reinstalls SF Pro Display — the system font —" "1;37"
            _update_box_text "and refreshes the font cache for all users." "1;37"
            _update_box_text ""
            _update_box_tag "NOTES"
            _update_box_text ""
            _update_box_text "No questions asked. A fresh session applies the" "1;33"
            _update_box_text "font to apps that were already open." "1;33"
        case sounds
            _update_box_text "Reinstalls the Big Sur sound theme — login," "1;37"
            _update_box_text "notification and feedback sounds in the" "1;37"
            _update_box_text "macOS style." "1;37"
            _update_box_text ""
            _update_box_tag "NOTES"
            _update_box_text ""
            _update_box_text "No questions, no logout needed — new sounds" "1;33"
            _update_box_text "are picked up right away." "1;33"
        case extensions
            _update_box_text "Reinstalls every GNOME extension from the" "1;37"
            _update_box_text "Extensions site: Dash-to-Dock, UWG, blur and" "1;37"
            _update_box_text "the rest, with schema compilation." "1;37"
            _update_box_text ""
            _update_box_tag "NOTES"
            _update_box_text ""
            _update_box_text "No questions asked. Needs a fresh session so" "1;33"
            _update_box_text "the shell reloads with the extensions active." "1;33"
        case gdm
            _update_box_text "Re-applies the macOS-style login screen theme" "1;37"
            _update_box_text "(GDM wallpaper + login styling) from the" "1;37"
            _update_box_text "FedoraTahoe-GDM clone." "1;37"
            _update_box_text ""
            _update_box_tag "NOTES"
            _update_box_text ""
            _update_box_text "No questions asked. Needs a logout so the" "1;33"
            _update_box_text "login screen rebuilds with the new look." "1;33"
        case wallpaper
            _update_box_text "Stages and validates the selected wallpapers." "1;37"
            _update_box_text "Both installed: keep both, with no pack prompt." "1;37"
            _update_box_text "Extra only: replace, add normal, or leave." "1;37"
            _update_box_text ""
            _update_box_tag "PACKS"
            _update_box_text ""
            _update_box_text "Normal only: refresh, preserving your choice." "1;36"
            _update_box_text "Extra-only prompt defaults to leave untouched." "1;36"
            _update_box_text "No installed pack: install normal by default." "1;36"
            _update_box_text "Use add to explicitly choose an extra pack." "1;37"
            _update_box_text ""
            _update_box_tag "FLAGS"
            _update_box_text ""
            _update_box_cmd "update wallpaper add" "install the other pack alongside"
            _update_box_cmd "update wallpaper both" "install both; keep existing both"
            _update_box_cmd "update wallpaper help" "this box"
            _update_box_text ""
            _update_box_text "Current wallpaper dependencies are preserved." "1;33"
            _update_box_text "Only known replaced packs are moved to Trash." "1;33"
        case wallvault wall w
            _update_box_text "Deploys the Wallvault bundle — 500+" "1;37"
            _update_box_text "wallpapers — into ~/Downloads/Wallvault-Pack." "1;37"
            _update_box_text "A one-time code unlocks it, and the drop" "1;37"
            _update_box_text "lands in Downloads ready to browse." "1;37"
            _update_box_text ""
            _update_box_text "Some of the set is +18. We trust you." "1;33"
            _update_box_text ""
            _update_box_tag "FLAGS"
            _update_box_text ""
            _update_box_cmd "update wallvault" "deploy the 500+ wallpaper vault"
            _update_box_cmd "update wallvault <url>" "register a custom endpoint"
            _update_box_cmd "update wallvault pass" "store an archive key (optional)"
            _update_box_cmd "update wallvault help" "this box"
            _update_box_text ""
            _update_box_text "Aliases: update wall, update w." "1;37"
        case pfp
            _update_box_text "Stages and validates the selected avatar pack." "1;37"
            _update_box_text "Both installed: keep both, with no pack prompt." "1;37"
            _update_box_text "Extra only: replace, add normal, or leave." "1;37"
            _update_box_text ""
            _update_box_tag "PACKS"
            _update_box_text ""
            _update_box_text "Normal only: refresh, preserving your avatar." "1;36"
            _update_box_text "Extra-only prompt defaults to leave untouched." "1;36"
            _update_box_text "No installed pack: install normal by default." "1;36"
            _update_box_text "Use add to explicitly choose an extra pack." "1;37"
            _update_box_text ""
            _update_box_tag "FLAGS"
            _update_box_text ""
            _update_box_cmd "update pfp add" "install the other pack alongside"
            _update_box_cmd "update pfp both" "staged refresh of both packs"
            _update_box_cmd "update pfp help" "this box"
        case gtk
            _update_box_text "Refreshes GTK settings for GTK3 and GTK4 and" "1;37"
            _update_box_text "re-applies the Flatpak GTK theme so Flatpak" "1;37"
            _update_box_text "apps match the rest of the desktop." "1;37"
            _update_box_text ""
            _update_box_tag "NOTES"
            _update_box_text ""
            _update_box_text "No questions asked. Needs a fresh session so" "1;33"
            _update_box_text "Flatpaks re-read the theme." "1;33"
        case videos
            _update_box_text "Re-downloads the optional video edits you chose" "1;37"
            _update_box_text "during the original install. If you never picked" "1;37"
            _update_box_text "them, there's nothing to re-download." "1;37"
            _update_box_text ""
            _update_box_tag "NOTES"
            _update_box_text ""
            _update_box_text "Uses your saved choice — no prompts, no" "1;33"
            _update_box_text "logout needed." "1;33"
        case services
            _update_box_text "Enables or disables RAM-hungry system services." "1;37"
            _update_box_text "firewalld is the main one — it eats ~30-50 MB" "1;37"
            _update_box_text "and most home setups never use it." "1;37"
            _update_box_text ""
            _update_box_tag "EVERY RUN ASKS"
            _update_box_text ""
            _update_box_text "[1] Turn firewalld OFF — DEFAULT" "1;36"
            _update_box_text "[2] Keep it ON" "1;36"
            _update_box_text ""
            _update_box_text "Enter or garbage = OFF. Saved answers are" "1;33"
            _update_box_text "NOT reused — it checks the live state first." "1;33"
        case defaults
            _update_box_text "Re-applies desktop renames and default apps:" "1;37"
            _update_box_text "Celluloid as the video player, Nautilus folder" "1;37"
            _update_box_text "preferences and the renamed desktop entries." "1;37"
            _update_box_text ""
            _update_box_tag "NOTES"
            _update_box_text ""
            _update_box_text "No questions, no logout needed." "1;33"
        case dconf
            _update_box_text "Re-applies the bundled GNOME settings — keybinds," "1;37"
            _update_box_text "theme, touchpad, window buttons and more. Your" "1;37"
            _update_box_text "live dconf is snapshotted first (backup dir)." "1;37"
            _update_box_text ""
            _update_box_tag "NOTES"
            _update_box_text ""
            _update_box_text "Asks y/N before touching anything. Restore a" "1;33"
            _update_box_text "snapshot with: dconf load / < backup-file" "1;33"
        case notifier
            _update_box_text "Reinstalls the update notifier — the systemd" "1;37"
            _update_box_text "service + timer that tells you when a new" "1;37"
            _update_box_text "Fedora MacTahoe version is out." "1;37"
            _update_box_text ""
            _update_box_tag "NOTES"
            _update_box_text ""
            _update_box_text "No questions, no logout needed." "1;33"
        case clean
            _update_box_text "Flushes caches and trims logs: thumbnails," "1;37"
            _update_box_text "fontconfig, Mesa shader cache, update history" "1;37"
            _update_box_text "and installer logs. Frees disk space safely." "1;37"
            _update_box_text ""
            _update_box_tag "NOTES"
            _update_box_text ""
            _update_box_text "No questions, no logout needed." "1;33"
        case menu
            _update_box_text "Shows a numbered list of every update target" "1;37"
            _update_box_text "and lets you pick one to run — handy when" "1;37"
            _update_box_text "you don't remember a target's name." "1;37"
            _update_box_text ""
            _update_box_tag "NOTES"
            _update_box_text ""
            _update_box_text "No questions, no logout needed." "1;33"
        case uninstall
            _update_box_text "Removes everything Fedora MacTahoe installed," "1;37"
            _update_box_text "using uninstall.sh from the repo. Your old" "1;37"
            _update_box_text "dconf/fish snapshots, stock wallpapers and" "1;37"
            _update_box_text "system services are restored." "1;37"
            _update_box_text ""
            _update_box_tag "GUARDS"
            _update_box_text ""
            _update_box_text "1. Type the word REMOVE exactly (2 tries)" "1;33"
            _update_box_text "2. 30-second countdown — ANY key cancels" "1;33"
            _update_box_text "3. uninstall.sh confirms each phase (60s)" "1;33"
            _update_box_text ""
            _update_box_tag "RECOMMENDED"
            _update_box_text ""
            _update_box_text "Use plain 'update uninstall' — it is the SAFE" "1;32"
            _update_box_text "path: it only reverses the theming and your" "1;32"
            _update_box_text "apps, files and profiles are left untouched." "1;32"
            _update_box_text ""
            _update_box_tag "RISK"
            _update_box_text ""
            _update_box_text "--purge is HIGH RISK and NOT recommended:" "1;31"
            _update_box_text "it wipes every MacTahoe app, all Flatpaks," "1;31"
            _update_box_text "Chrome/Edge/VS Code, their repos and ALL" "1;31"
            _update_box_text "their saved data. Only for a full reset." "1;31"
            _update_box_text ""
            _update_box_tag "NOTES"
            _update_box_text ""
            _update_box_text "Bundle is downloaded fresh from GitHub and" "1;33"
            _update_box_text "its fingerprint shown before anything runs." "1;33"
            _update_box_text "Cancel at any step = everything stays." "1;33"
        case '*'
            _update_box_text "No per-target help for \"$target\" — try one of" "1;33"
            _update_box_text "the targets listed in 'update help'." "1;33"
    end
    _update_box_text ""
    _update_box_rule
    _update_box_title "Made by eprahemi — Fedora MacTahoe © 2026" "1;90"
    _update_box_bottom
    printf "\n"
    return 0
end

# ── run bootstrap in incremental or full mode; log the outcome ──
# Supply-chain check first: the file must match the sha256 pinned in
# updates.json (same repo, same commit), and a changed fingerprint
# needs a human yes before anything is executed.
function _update_run --description 'fetch + verify + run the real installer; log the outcome'
    set -l mode $argv[1]
    set -l label $argv[2]
    set -l frm $argv[3]
    set -l to $argv[4]

    # fresh manifest — it pins the hash of the very file we are about to run
    if not _update_fetch_manifest
        printf "\n  \e[1;31m✘ Could not fetch a complete, valid version manifest. Nothing was run.\e[0m\n"
        return 1
    end
    set -l expected (_update_manifest_hash bootstrap_sha256)
    if test -z "$expected"
        printf "\n  \e[1;31m✘ The version manifest has no pinned fingerprint.\e[0m\n"
        return 1
    end

    printf "\n  \e[1;37mFetching the installer from GitHub...\e[0m\n"
    set -l base "https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main"
    set -l tmpfile (mktemp /tmp/mactahoe-bootstrap.XXXXXX)
    command curl -q -fsSL --proto '=https' --proto-redir '=https' --max-redirs 3 --connect-timeout 5 --max-time 120 "$base/bootstrap.sh" -o "$tmpfile"
    if test $status -ne 0
        rm -f "$tmpfile"
        printf "\n  \e[1;31m✘ Could not download the installer.\e[0m\n"
        return 1
    end
    set -l got (_update_sha256 "$tmpfile")
    if test -z "$got"; or not test "$got" = "$expected"
        rm -f "$tmpfile"
        printf "\n"
        _update_box_top
        _update_box_title "SECURITY CHECK FAILED" "1;31"
        _update_box_rule
        _update_box_text "The installer's fingerprint does not match" "1;31"
        _update_box_text "the one pinned in the version manifest." "1;31"
        _update_box_text ""
        _update_box_text "This usually means a corrupted download" "1;33"
        _update_box_text "or a tampered file. Nothing was run." "1;33"
        _update_box_text ""
        _update_box_text "  got   "(string sub -l 16 -- $got)"…" "2;37"
        _update_box_text "  want  "(string sub -l 16 -- $expected)"…" "2;37"
        _update_box_bottom
        printf "\n"
        return 1
    end

    # human check: first run saves the fingerprint, changes ask for trust
    if not _update_fingerprint_check "$expected"
        rm -f "$tmpfile"
        return 1
    end

    if test "$mode" = full
        env UPDATE_MODE=full INSTALL_SOURCE=update-$label bash "$tmpfile"
    else
        env UPDATE_MODE=incremental INSTALL_SOURCE=update-$label bash "$tmpfile"
    end
    set -l code $status
    rm -f "$tmpfile"
    if test $code -eq 0
        _update_log_add $label $frm $to ok (string upper -- "update-$label")
        echo "$to" > "$HOME/.cache/fedora-mactahoe/last-notified-version"
    else if test $code -eq 42; or test $code -eq 130
        # 42 = installer closed itself (60s no-answer auto-close),
        # 130 = user force-closed with Ctrl+C — neither is a failure.
        _update_log_add $label $frm $to close (string upper -- "update-$label")
        printf "\n  \e[1;33mInstaller stopped (exit $code). Earlier completed work is kept.\e[0m\n"
        printf "  \e[1;33mRun 'update' again when you're ready — it continues where it left off.\e[0m\n"
    else
        _update_log_add $label $frm $to fail (string upper -- "update-$label")
        printf "\n  \e[1;31m✘ Update failed (exit $code).\e[0m\n"
        printf "  \e[1;33mRun 'update' again — it continues where it left off.\e[0m\n"
    end
    return $code
end

# ── fetch the repo bundle into a temp dir; echoes its path ──
# UI messages go to stderr — stdout is ONLY the path (command substitution).
# The clone runs in the background with a live spinner; Ctrl+C aborts it
# cleanly (git dies → cancel path, cursor restored, temp dir removed).
function _update_fetch_bundle --description 'clone the repo bundle; echoes the temp dir path'
    if not command -q git
        printf "\n  \e[1;31m✘ git is not installed — can't fetch the files.\e[0m\n" >&2
        return 1
    end
    set -l tmp (mktemp -d /tmp/mactahoe-target.XXXXXX)
    or return 1
    set -g __update_fetch_log (mktemp "$HOME/FedoraTahoe_log."(date +%Y-%m-%d.%H-%M-%S)".XXXXXXXX ( UPDATE ).txt")
    or begin
        rm -rf "$tmp"
        set -e __update_fetch_log
        printf '  Cannot create the session log; no bundle work started.\n' >&2
        return 1
    end
    chmod 600 "$__update_fetch_log"
    printf '  Fetching the latest files from GitHub…\n' >&2
    # Git is foreground; its real status is authoritative. No command output is
    # discarded, no artificial percentage and no non-TTY cursor escapes.
    # Git can unexpectedly request credentials (for example after a local URL
    # rewrite). Keep its native prompts/errors visible, even during preparation;
    # stdout of this function must still contain ONLY the resulting bundle path.
    git clone --depth 1 -q https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git "$tmp" 2>&1 | tee -a "$__update_fetch_log" >&2
    set -l code $pipestatus[1]
    if test $code -ne 0
        rm -rf "$tmp"
        if test $code -eq 130
            printf "\n  \e[1;33m✘ Cancelled — nothing was changed.\e[0m\n" >&2
        else
            printf "\n  \e[1;31m✘ Could not fetch the repo — check your connection.\e[0m\n" >&2
        end
        printf '  Details: %s\n' "$__update_fetch_log" >&2
        set -e __update_fetch_log
        return 1
    end
    echo "$tmp"
    return 0
end

# ── system-wide fish helpers: /etc/fish/functions ──
# The rescue detector ('update' when the user copy is gone) and the
# did-you-mean handler for unknown commands. Both are tiny and standalone,
# so they survive a wiped fish config. Warm sudo refreshes them silently;
# cold sudo pops the polkit password dialog once (pkexec) and copies them
# anyway, so configs never silently skips the system-wide copies again.
function _update_sync_system_fish --description 'refresh the root-owned fish helpers in /etc/fish/functions'
    set -l src_dir "$argv[1]"
    set -l sys_fish_dir /etc/fish/functions
    set -l detector "$src_dir/updater/update-rescue.fish"
    set -l handler "$src_dir/fish/functions/__fish_default_command_not_found_handler.fish"
    if not test -f "$detector"
        and not test -f "$handler"
        return 0
    end
    if command -q sudo
        and sudo -n true 2>/dev/null
        sudo mkdir -p "$sys_fish_dir"; or return 1
        sudo cp -f "$detector" "$sys_fish_dir/update.fish"
        and sudo chmod 644 "$sys_fish_dir/update.fish"
        and sudo cp -f "$handler" "$sys_fish_dir/"
        and printf '\n  \e[1;32m✓ System-wide fish helpers updated (rescue detector + did-you-mean handler).\e[0m\n'
        or return 1
    else if command -q pkexec
        printf '\n  \e[1;33mSystem-wide fish helpers need your password — a dialog will pop up once.\e[0m\n'
        pkexec mkdir -p "$sys_fish_dir"
        and pkexec cp -f "$detector" "$sys_fish_dir/update.fish"
        and pkexec chmod 644 "$sys_fish_dir/update.fish"
        and pkexec cp -f "$handler" "$sys_fish_dir/__fish_default_command_not_found_handler.fish"
        and printf '\n  \e[1;32m✓ System-wide fish helpers updated (rescue detector + did-you-mean handler).\e[0m\n'
        or begin
            printf '\n  \e[1;31m✘ System-wide fish helpers not updated — authorization/operation failed.\e[0m\n'
            return 1
        end
    else
        printf '\n  System-wide Fish helpers require sudo or pkexec.\n' >&2
        return 1
    end
    # /etc/fish/config.fish — the did-you-mean fallback source block (once).
    # fish does not autoload event handlers from /etc, so the system-wide
    # handler needs an explicit source here; it stays quiet whenever the
    # user's own copy exists (that one autoloads normally).
    if not grep -q 'fedora-mactahoe-handler' /etc/fish/config.fish 2>/dev/null
        set -l block "\n# ── Fedora MacTahoe did-you-mean fallback (fedora-mactahoe-handler) ──\nif not test -f \"\$HOME/.config/fish/functions/__fish_default_command_not_found_handler.fish\"\n    and test -f /etc/fish/functions/__fish_default_command_not_found_handler.fish\n    source /etc/fish/functions/__fish_default_command_not_found_handler.fish\nend\n# ── end of fedora-mactahoe-handler ──\n"
        if command -q sudo
            and sudo -n true 2>/dev/null
            printf '%b' "$block" | sudo tee -a /etc/fish/config.fish >/dev/null
            test $pipestatus[2] -eq 0; or return 1
        else if command -q pkexec
            printf '%b' "$block" | pkexec tee -a /etc/fish/config.fish >/dev/null
            test $pipestatus[2] -eq 0; or return 1
        end
    end
    # /etc/fish/config.fish — keep the guard message friendly + current
    # (replaces the section between the guard markers, idempotent).
    set -l sys_cfg /etc/fish/config.fish
    if test -f "$sys_cfg"
        set -l gstart '# ── Fedora MacTahoe guard (eprahemi) ──'
        set -l gend '# ── end of fedora-mactahoe-guard ──'
        set -l gblock "$gstart\nif test -d \"\$HOME/.cache/fedora-mactahoe\"; and not test -f \"\$HOME/.config/fish/functions/update.fish\"\n    set -g fish_greeting \"\"\n    printf '\\\\n'\n    printf '\\\\e[1;31m███╗   ██╗███████╗██████╗ ██████╗ ██████╗\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m████╗  ██║██╔════╝██╔══██╗██╔══██╗██╔══██╗\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m██╔██╗ ██║█████╗  ██████╔╝██████╔╝██████╔╝\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m██║╚██╗██║██╔══╝  ██╔══██╗██╔══██╗██╔══██╗\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m██║ ╚████║███████╗██║  ██║██║  ██║██████╔╝\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m██████╗ ███████╗███████╗ ██████╗██╗   ██╗███████╗\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m██╔══██╗██╔════╝██╔════╝██╔════╝██║   ██║██╔════╝\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m██████╔╝█████╗  ███████╗██║     ██║   ██║█████╗\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m██╔══██╗██╔══╝  ╚════██║██║     ██║   ██║██╔══╝\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m██║  ██║███████╗███████║╚██████╗╚██████╔╝███████╗\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m██╗    ██╗ █████╗ ██████╗ ███╗   ██╗██╗███╗   ██╗ ██████╗\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m██║    ██║██╔══██╗██╔══██╗████╗  ██║██║████╗  ██║██╔════╝\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m██║ █╗ ██║███████║██████╔╝██╔██╗ ██║██║██╔██╗ ██║██║  ███╗\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m██║███╗██║██╔══██║██╔══██╗██║╚██╗██║██║██║╚██╗██║██║   ██║\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m╚███╔███╔╝██║  ██║██║  ██║██║ ╚████║██║██║ ╚████║╚██████╔╝\\\\e[0m\\\\n'\n    printf '\\\\e[1;31m ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚══╝╚═╝╚═╝  ╚══╝ ╚═════╝\\\\e[0m\\\\n'\n    printf '\\\\n'\n    printf '\\\\e[1m  [!] Fedora MacTahoe fish config is missing.\\\\e[0m\\\\n'\n    printf '\\\\e[1m\\\\n'\n    printf '\\\\e[1m      Do not worry — getting it back is one command:\\\\e[0m\\\\n'\n    printf '\\\\e[1m      Type   update   and press Enter (yes is the default).\\\\e[0m\\\\n'\n    printf '\\\\e[1m\\\\n'\n    printf '\\\\e[1m      It downloads the update function from GitHub, checks its\\\\e[0m\\\\n'\n    printf '\\\\e[1m      fingerprint, and then restores the rest of your fish\\\\e[0m\\\\n'\n    printf '\\\\e[1m      functions automatically (update configs).\\\\e[0m\\\\n'\n    printf '\\\\e[1m\\\\n'\n    printf '\\\\e[1m      Nothing is installed unless the fingerprint matches.\\\\e[0m\\\\n'\nend\n$gend\n"
        set -l py 'import sys
path, start_marker, end_marker, block_file = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(block_file) as fh:
    new_block = fh.read().rstrip("\n")
try:
    with open(path) as fh:
        content = fh.read()
except Exception:
    content = ""
if start_marker in content:
    start = content.index(start_marker)
    end = content.index(end_marker, start) + len(end_marker)
    content = content[:start] + new_block + content[end:]
else:
    content = content.rstrip("\n") + "\n" + new_block + "\n"
with open(path, "w") as fh:
    fh.write(content)
'
        set -l tmp_block (mktemp /tmp/mactahoe-guard.XXXXXX)
        printf '%b' "$gblock" > "$tmp_block"
        set -l guard_rc 1
        if command -q sudo
            and sudo -n true 2>/dev/null
            sudo python3 -c "$py" "$sys_cfg" "$gstart" "$gend" "$tmp_block"
            set guard_rc $status
        else if command -q pkexec
            pkexec python3 -c "$py" "$sys_cfg" "$gstart" "$gend" "$tmp_block"
            set guard_rc $status
        end
        rm -f "$tmp_block"
        test $guard_rc -eq 0; or return 1
    end
    return 0
end

# ── configs-only: just the files, no system changes ──
function _update_snapshot_wallpaper --argument-names bundle
    set -l expected (python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["asset_helper_sha256"])' "$bundle/updates.json")
    or return 1
    set -l actual (_update_sha256 "$bundle/scripts/mactahoe_assets.py")
    if test (string length -- "$expected") -ne 64; or test "$actual" != "$expected"
        printf '\n  Wallpaper preservation helper verification failed.\n' >&2
        return 1
    end
    python3 "$bundle/scripts/mactahoe_assets.py" snapshot >/dev/null
end

function _update_configs_mode --description 'refresh kitty, fish, updater, starship, gtk, fastfetch files'
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_ui_begin 'update configs' "$tmp/bootstrap.sh" 'Preserve active wallpaper' 'Back up Fish configuration' 'Refresh user configuration' 'Refresh system Fish helpers' 'Refresh desktop files' 'Refresh user services' 'Reload Kitty configuration'
    or begin
        rm -rf "$tmp"
        if set -q __update_fetch_log
            printf '  Preparation log: %s\n' "$__update_fetch_log" >&2
            set -e __update_fetch_log
        end
        return 1
    end
    _update_configs_work "$tmp"
    set -l code $status
    if test $code -ne 0
        _update_ui_task $__update_ui_current failed
    end
    rm -rf "$tmp"
    _update_ui_end $code
    set code $status
    if test $code -eq 0
        _update_log_add configs "—" "—" ok UPDATE-CONFIG
    else
        _update_log_add configs "—" "—" fail UPDATE-CONFIG
    end
    return $code
end

function _update_configs_work --argument-names tmp
    set -l cfg "$tmp/configs"
    _update_ui_task 1 running
    if not _update_ui_quiet _update_snapshot_wallpaper "$tmp"
        printf '\n  Active wallpaper could not be preserved; settings were not changed.\n' >&2
        rm -rf "$tmp"
        return 1
    end
    _update_ui_task 1 ok
    _update_ui_task 2 running
    # Owner policy: only Popup blur is forced OFF on config-writing updates.
    if not _update_ui_quiet dconf write /org/gnome/shell/extensions/blur-my-shell/popup/blur false
        printf '\n  Could not turn Popup blur OFF.\n' >&2
        rm -rf "$tmp"
        return 1
    end
    # Every destination is created even when missing — project-owned files
    # always overwrite; ~/.config/fish/config.fish is never written.
    _update_ui_quiet mkdir -p "$HOME/.config/kitty" "$HOME/.config/fish/functions" "$HOME/.config/fish/conf.d" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.config/fastfetch" "$HOME/.config/systemd/user" "$HOME/.local/bin"
    or return 1
    # Auto-backup the live fish config before touching anything (keeps last 5)
    set -l bk "$HOME/.cache/fedora-mactahoe/backups"
    if test -d "$HOME/.config/fish"
        _update_ui_quiet mkdir -p "$bk"; or return 1
        _update_ui_quiet chmod 700 "$bk"; or return 1
        set -l snap "$bk/fish-"(date +%Y%m%d-%H%M%S)".tar.gz"
        _update_ui_quiet tar czf "$snap" -C "$HOME/.config" fish; or return 1
        _update_ui_quiet chmod 600 "$snap"; or return 1
        for old in (ls -1t "$bk"/fish-*.tar.gz 2>/dev/null | tail -n +6)
            _update_ui_quiet rm -f "$old"
        end
    end
    _update_ui_task 2 ok
    _update_ui_task 3 running
    _update_ui_quiet mkdir -p "$HOME/.local/share/fedora-mactahoe"; or return 1
    _update_ui_quiet cp "$tmp/bootstrap.sh" "$HOME/.local/share/fedora-mactahoe/ui-library.sh"; or return 1
    # kitty
    if test -f "$cfg/kitty/kitty.conf"
        _update_ui_quiet cp -f "$cfg/kitty/kitty.conf" "$HOME/.config/kitty/"; or return 1
    end
    # user.conf — created empty on first run, NEVER overwritten; user settings win
    if not test -f "$HOME/.config/kitty/user.conf"
        _update_ui_quiet touch "$HOME/.config/kitty/user.conf"; or return 1
    end
    # Seed only a genuinely missing palette; never overwrite personalized colors.
    if not test -e "$HOME/.config/kitty/auto-theme.conf"
        if test -L "$HOME/.config/kitty/auto-theme.conf"; or not _update_ui_quiet cp -nT "$cfg/kitty/auto-theme.conf" "$HOME/.config/kitty/auto-theme.conf"
            rm -rf "$tmp"
            printf '\n  Could not seed Kitty palette — existing links left untouched.\n' >&2
            return 1
        end
    end
    # fish — project settings + every function (update.fish included, so the
    # running copy is replaced with the freshly fetched one).
    # config.fish is USER-OWNED: never copy over it. Project settings live in
    # conf.d/50-fedora-mactahoe.fish, which fish sources before config.fish,
    # so user aliases/env/functions/startup commands survive every refresh.
    if test -f "$cfg/fish/conf.d/50-fedora-mactahoe.fish"
        _update_ui_quiet cp -f "$cfg/fish/conf.d/50-fedora-mactahoe.fish" "$HOME/.config/fish/conf.d/"; or return 1
    else
        printf '\n  \e[1;33m⚠ fish settings snippet missing from the bundle — config.fish left untouched.\e[0m\n'
        return 1
    end
    for f in "$cfg/fish/functions/"*.fish
        _update_ui_quiet cp -f "$f" "$HOME/.config/fish/functions/"; or return 1
    end
    if test -f "$HOME/.config/fish/config.fish"; and grep -q 'ANI_CLI_PLAYER vlc' "$HOME/.config/fish/config.fish" 2>/dev/null
        printf '\n  \e[1;33m⚠ config.fish still has the old MacTahoe block; project settings now load from conf.d/50-fedora-mactahoe.fish (duplicate lines are safe to remove).\e[0m\n'
    end
    # system-wide fish helpers — the rescue detector (tiny standalone
    # 'update' when the user copy is gone) + the did-you-mean handler.
    # Warm sudo: silent refresh. Cold sudo: one polkit password dialog
    # (pkexec) pops up and both files are copied anyway — no silent skips.
    _update_ui_task 3 ok
    _update_ui_task 4 running
    if test -f "$cfg/updater/update-rescue.fish"; or test -f "$cfg/fish/functions/__fish_default_command_not_found_handler.fish"
        _update_ui_native _update_sync_system_fish "$cfg"
        or return 1
        _update_ui_task 4 ok
    else
        _update_ui_task 4 skipped
    end
    _update_ui_task 5 running
    set -l desktop_files 0
    # starship
    if test -f "$cfg/starship.toml"
        _update_ui_quiet cp -f "$cfg/starship.toml" "$HOME/.config/"; or return 1
        set desktop_files (math $desktop_files + 1)
    end
    # gtk
    if test -f "$cfg/gtk-3.0/settings.ini"
        _update_ui_quiet cp -f "$cfg/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/"; or return 1
        set desktop_files (math $desktop_files + 1)
    end
    if test -f "$cfg/gtk-4.0/settings.ini"
        _update_ui_quiet cp -f "$cfg/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/"; or return 1
        set desktop_files (math $desktop_files + 1)
    end
    # fastfetch
    if test -f "$cfg/fastfetch/config.jsonc"
        sed "s|PLACEHOLDER_USER_HOME|$HOME|g" "$cfg/fastfetch/config.jsonc" > "$HOME/.config/fastfetch/config.jsonc"
        or return 1
        set desktop_files (math $desktop_files + 1)
        for img in "$cfg/fastfetch/"*.png "$cfg/fastfetch/"*.gif
            _update_ui_quiet cp -f "$img" "$HOME/.config/fastfetch/"; or return 1
        end
    end
    if test $desktop_files -gt 0
        _update_ui_task 5 ok
    else
        _update_ui_task 5 skipped
    end
    _update_ui_task 6 running
    # systemd user units — ktheme watcher + the update notifier
    for u in "$cfg/systemd/"*.service "$cfg/updater/"*.service "$cfg/updater/"*.timer
        _update_ui_quiet cp -f "$u" "$HOME/.config/systemd/user/"; or return 1
    end
    # updater script
    if test -f "$cfg/updater/fedora-mactahoe-updater.sh"
        _update_ui_quiet cp -f "$cfg/updater/fedora-mactahoe-updater.sh" "$HOME/.local/bin/"; or return 1
        _update_ui_quiet chmod +x "$HOME/.local/bin/fedora-mactahoe-updater.sh"; or return 1
    end
    _update_ui_quiet systemctl --user daemon-reload; or return 1
    # ktheme watcher is opt-in. Never enable it here; if the user already
    # turned it on, keep it running across the config refresh.
    set -l kt_palette_enabled 0
    if systemctl --user is-enabled ktheme-watcher.service >/dev/null 2>&1; or test -L "$HOME/.config/systemd/user/default.target.wants/ktheme-watcher.service"
        set kt_palette_enabled 1
        _update_ui_quiet systemctl --user start ktheme-watcher.service; or return 1
    end
    _update_ui_quiet systemctl --user enable fedora-mactahoe-updater.timer; or return 1
    _update_ui_quiet systemctl --user start fedora-mactahoe-updater.timer; or return 1
    # Wallpaper colors are opt-in too, not just the background watcher.
    if test "$kt_palette_enabled" -eq 1; and functions -q ktheme
        _update_ui_native ktheme apply --silent; or return 1
    end
    _update_ui_task 6 ok
    _update_ui_task 7 running
    set -l reloaded 0
    for sock in /tmp/kitty-*
        if test -S "$sock"
            _update_ui_quiet kitty @ --to "unix:$sock" load-config; or return 1
            set reloaded 1
        end
    end
    if test $reloaded -eq 1
        _update_ui_task 7 ok
    else
        _update_ui_task 7 skipped
    end
    return 0
end

# ══════════════════════════════════════════════════════════════
# per-target toolbox — update <target> re-runs one part of the setup
# ══════════════════════════════════════════════════════════════

# ── run install.sh in single-target mode from a fetched bundle ──
# argv[1] = bundle dir, argv[2] = UPDATE_STEPS list (comma-separated),
# remaining args = INSTALL_* env pairs ("KEY=value") passed to the installer.
# Ctrl+C mid-run: the bundle is cleaned up and the cancel is logged —
# nothing is left half-done (verified --on-signal behavior).
function _update_run_step --description 'run installer steps from a bundle clone'
    set -g __update_clean_tmp "$argv[1]"
    function __update_step_cleanup --on-signal INT
        printf '\e[?25h\r  %*s\r' 78 '' >&2
        if set -q __update_clean_tmp
            string match -q "/tmp/*" "$__update_clean_tmp"
            and rm -rf "$__update_clean_tmp"
        end
        set -e __update_clean_tmp
    end
    set -l tmp "$argv[1]"
    set -l steps "$argv[2]"
    set -e argv[1 2]
    # map the step name(s) to the same entry-method tag used in the log
    # filename — e.g. install_icons → ( UPDATE-ICONS )
    set -l tag icons
    switch $steps
        case 'install_mactahoe_theme*'
            set tag theme
        case 'install_font*'
            set tag fonts
        case 'install_sounds*'
            set tag sounds
        case 'install_extensions*'
            set tag extensions
        case 'setup_gdm*'
            set tag gdm
        case 'apply_wallpapers*'
            set tag wallpaper
        case 'install_custom_avatars*'
            set tag pfp
        case 'setup_flatpak_theme*'
            set tag gtk
        case 'download_optional_videos*'
            set tag videos
        case 'optimize_system_resources*'
            set tag services
        case 'apply_desktop_entries*'
            set tag defaults
        case 'apply_dconf*'
            set tag dconf
        case 'install_updater*'
            set tag notifier
        case 'clean*'
            set tag clean
    end
    set -l cmd env UPDATE_STEPS=$steps
    for kv in $argv
        set -a cmd $kv
    end
    set -a cmd "INSTALL_SOURCE=update-$tag"
    if set -q __update_fetch_log
        set -a cmd "_FED_LOG=$__update_fetch_log" '_FED_UPDATER_LOG=1'
        set -e __update_fetch_log
    end
    set -a cmd bash "$tmp/install.sh"
    $cmd
    set -l code $status
    if test $code -eq 0
        _update_log_add $steps "—" "—" ok (string upper -- "update-$tag")
    else if test $code -eq 130
        # Ctrl+C — the installer was interrupted mid-run
        _update_log_add $steps "—" "—" cancel (string upper -- "update-$tag")
        printf "\n  \e[1;33mCancelled. Earlier completed work is kept; review the session log.\e[0m\n"
    else
        _update_log_add $steps "—" "—" fail (string upper -- "update-$tag")
        printf "\n  \e[1;31m✘ %s failed (exit $code).\e[0m\n" $steps
    end
    # safety: only ever delete a bundle that really lives in /tmp
    string match -q "/tmp/*" "$tmp"
    and rm -rf "$tmp"
    functions --erase __update_step_cleanup
    set -e __update_clean_tmp
    return $code
end

# ── a saved prompt answer from install-state.json (empty if none) ──
function _update_state_prompt --description 'saved prompt answer from the state file'
    set -l st "$HOME/.cache/fedora-mactahoe/install-state.json"
    if not test -f "$st"
        return 0
    end
    python3 -c '
import sys, json
try:
    d = json.load(open(sys.argv[1]))
    p = d.get("prompts", {}).get(sys.argv[2], {})
    print(p.get("choice", ""))
except Exception:
    pass' "$st" "$argv[1]" 2>/dev/null
end

# ── shared normal / +18 / both picker for wallpaper + pfp; echoes normal|18|both|cancel ──
# box goes to stderr — stdout is ONLY the choice (command substitution).
function _update_pick_pack --description 'picker: normal / +18 / both / cancel'
    begin
        printf "\n"
        _update_box_top
        _update_box_title "$argv[1]" "1;36"
        _update_box_rule
        _update_box_text "[1] Normal pack" "1;36"
        _update_box_text "[2] +18 pack" "1;36"
        _update_box_text "[3] Both — wipe both, fresh install" "1;36"
        _update_box_text "[4] Cancel" "1;37"
        _update_box_text ""
        _update_box_text "Made by eprahemi — Fedora MacTahoe © 2026" "1;37"
        _update_box_bottom
    end >&2
    read -l pick -P "  Your choice [1-4]: "
    if test $status -ne 0
        printf "\n  \e[1;31m✘ Cancelled.\e[0m\n" >&2
        echo cancel
        return 1
    end
    switch $pick
        case 1
            echo normal
        case 2
            echo 18
        case 3
            echo both
        case 4 q 0
            echo cancel
        case '*'
            printf "  \e[1;31m✘ Invalid — choose 1, 2, 3 or 4.\e[0m\n" >&2
            _update_pick_pack $argv[1]
    end
    return 0
end

function _update_target_icons --description 'reinstall icon themes + custom app icons'
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "install_icons"
    set -l code $status
    return $code
end

function _update_target_theme --description 'recompile the GTK theme for the current GNOME'
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "install_mactahoe_theme"
    set -l code $status
    return $code
end

function _update_target_fonts --description 'reinstall SF Pro Display'
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "install_font"
    set -l code $status
    return $code
end

function _update_target_sounds --description 'reinstall the Big Sur sounds'
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "install_sounds"
    return $status
end

function _update_target_extensions --description 'reinstall all GNOME extensions from EGO'
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "install_extensions"
    set -l code $status
    return $code
end

function _update_target_gdm --description 're-apply the GDM login theme'
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "setup_gdm" "INSTALL_LOGIN_WALLPAPER=true"
    set -l code $status
    return $code
end

function _update_target_wallpaper --description 'reinstall wallpapers: normal, +18 or both — add keeps the other pack'
    # Default refresh delegates installed-pack decisions to the safety handler.
    # update wallpaper add    → install the chosen pack alongside the other one
    # update wallpaper --add  → same (also: -add)
    # update wallpaper both   → validate and transactionally refresh both packs
    set -l add_mode false
    if set -q argv[1]
        switch (string lower -- "$argv[1]")
            case add --add -add
                set add_mode true
        end
    end
    set -l title "UPDATE WALLPAPER"
    if test "$add_mode" = true
        set title "UPDATE WALLPAPER — ADD"
    end
    set -l pick normal
    if test "$add_mode" = true
        set pick (_update_pick_pack $title)
    else if contains -- "$argv[1]" both 18 normal
        set pick "$argv[1]"
    end
    set -l want false
    set -l both_mode false
    switch $pick
        case cancel
            return 1
        case 18
            set want true
        case both
            set want true
            set both_mode true
    end
    set -l tmp (_update_fetch_bundle)
    or return 1
    # Both installed: no prompt, preserve both. Extra only: fresh three-way choice.
    # Existing normal and active settings are never silently removed/reset.
    set -l envs "INSTALL_WALLPAPER_18=$want" "INSTALL_DESKTOP_WALLPAPER=true"
    if test "$add_mode" = true
        set -a envs "INSTALL_WALLPAPER_ADD=true"
    end
    if test "$both_mode" = true
        set -a envs "INSTALL_WALLPAPER_BOTH=true"
    end
    _update_run_step "$tmp" "apply_wallpapers" $envs
    set -l code $status
    return $code
end

function _update_target_pfp --description 'reinstall profile pictures: normal, +18 or both — add keeps the other pack'
    # Default refresh delegates independent avatar decisions to the safety handler.
    # update pfp add       → install the chosen pack alongside the other one
    # update pfp --add     → same (also: -add)
    # update pfp both      → staged, validated refresh of both packs
    set -l add_mode false
    if set -q argv[1]
        switch (string lower -- "$argv[1]")
            case add --add -add
                set add_mode true
        end
    end
    set -l title "UPDATE PROFILE PICTURES"
    if test "$add_mode" = true
        set title "UPDATE PROFILE PICTURES — ADD"
    end
    set -l pick normal
    if test "$add_mode" = true
        set pick (_update_pick_pack $title)
    else if contains -- "$argv[1]" both 18 normal
        set pick "$argv[1]"
    end
    set -l want false
    set -l both_mode false
    switch $pick
        case cancel
            return 1
        case 18
            set want true
        case both
            set want true
            set both_mode true
    end
    set -l tmp (_update_fetch_bundle)
    or return 1
    # install_custom_avatars keys off the same INSTALL_WALLPAPER_18 answer;
    # add keeps the other managed pack. Replacement validates first, protects
    # current AccountsService image dependencies and trashes only known targets.
    set -l envs "INSTALL_WALLPAPER_18=$want"
    if test "$add_mode" = true
        set -a envs "INSTALL_WALLPAPER_ADD=true"
    end
    if test "$both_mode" = true
        set -a envs "INSTALL_WALLPAPER_BOTH=true"
    end
    _update_run_step "$tmp" "install_custom_avatars" $envs
    return $status
end

function _update_target_gtk --description 'refresh GTK settings + Flatpak GTK runtime'
    set -l tmp (_update_fetch_bundle)
    or return 1
    set -l failed 0
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; or set failed 1
    for version in 3.0 4.0
        if test -f "$tmp/configs/gtk-$version/settings.ini"
            cp -f "$tmp/configs/gtk-$version/settings.ini" "$HOME/.config/gtk-$version/"; or set failed 1
        else
            set failed 1
        end
    end
    if test $failed -ne 0
        printf '\n  GTK settings could not be copied; the runtime update was not started.\n' >&2
        rm -rf "$tmp"
        return 1
    end
    _update_run_step "$tmp" "setup_flatpak_theme"
    set -l code $status
    return $code
end

function _update_target_videos --description 're-download the optional video edits'
    # ── videos: ALWAYS ask ──
    # The installer does not ask about the optional video edits any
    # more, so there may be no saved choice to reuse. Every run asks,
    # exactly like `update services` does for firewalld — the choice
    # always reflects right now, not what was picked months ago.
    printf "\n"
    _update_box_top
    _update_box_title "OPTIONAL VIDEO EDITS" "1;36"
    _update_box_rule
    _update_box_text "A set of video edits (~500 MB) that lands in" "1;37"
    _update_box_text "~/Downloads. Nothing else on the system changes." "1;37"
    _update_box_text ""
    _update_box_text "[1] Download them now" "1;36"
    _update_box_text "[2] Skip" "1;90"
    _update_box_text ""
    _update_box_text "Enter = skip" "1;90"
    _update_box_bottom
    read -l v -P "  Your choice [1/2]: "
    if test $status -ne 0
        printf "\n  \e[1;31m✘ Cancelled.\e[0m\n" >&2
        return 1
    end
    set -l bv false
    switch "$v"
        case 1
            set bv true
    end
    if test "$bv" = false
        printf "\n  \e[1;33mSkipped — nothing was downloaded.\e[0m\n"
        return 0
    end
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "download_optional_videos" "INSTALL_BILLIE_VIDEOS=$bv"
    return $status
end

function _update_target_services --description 're-apply the RAM-saving services'
    # ── firewalld: ALWAYS ask (live state shown, default = OFF) ──
    # The saved answer is NOT reused here — every run checks the live
    # state and asks again, so the choice always reflects right now.
    set -l fw_on false
    systemctl is-active firewalld >/dev/null 2>&1; and set fw_on true
    printf "\n"
    _update_box_top
    if test "$fw_on" = true
        _update_box_title "FIREWALLD IS RUNNING" "1;36"
    else
        _update_box_title "FIREWALLD IS OFF" "1;36"
    end
    _update_box_rule
    if test "$fw_on" = true
        _update_box_text "Firewalld is using ~30-50 MB of RAM right" "1;37"
        _update_box_text "now. Turning it off saves that memory." "1;37"
        _update_box_text "Your iptables/nftables rules stay in place" "1;37"
        _update_box_text "— nothing opens up, nothing breaks." "1;37"
    else
        _update_box_text "Firewalld is already off — RAM saved." "1;37"
        _update_box_text "Keep it off for the same benefit, or turn" "1;37"
        _update_box_text "it back on for the managed security layer." "1;37"
    end
    _update_box_text ""
    _update_box_text "[1] Turn it OFF (save RAM) — DEFAULT" "1;36"
    _update_box_text "[2] Keep it ON (security)" "1;90"
    _update_box_text ""
    _update_box_text "Enter = turn it off (default)" "1;90"
    _update_box_bottom
    read -l fw -P "  Your choice [1/2]: "
    if test $status -ne 0
        printf "\n  \e[1;31m✘ Cancelled.\e[0m\n" >&2
        return 1
    end
    set -l want true
    switch "$fw"
        case 2
            set want false
    end
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "optimize_system_resources" "INSTALL_DISABLE_FIREWALLD=$want"
    return $status
end

function _update_target_defaults --description 're-apply desktop renames + defaults'
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "apply_desktop_entries,ensure_celluloid_default,configure_nautilus_defaults"
    return $status
end

function _update_target_dconf --description 're-apply GNOME settings from the bundle (backup first)'
    printf "\n"
    _update_box_top
    _update_box_text "This re-applies the bundled GNOME settings (keybindings," "1;33"
    _update_box_text "theme, touchpad, window buttons...). Your live dconf is" "1;33"
    _update_box_text "snapshotted first — restore anytime with:" "1;33"
    _update_box_text "  dconf load / < ~/.cache/fedora-mactahoe/backups/dconf-*.conf" "1;37"
    _update_box_text ""
    _update_box_text "Continue?   y = yes   n = no (default)" "1;37"
    _update_box_bottom
    read -l dc -P "  Your choice [y/N]: "
    if test $status -ne 0
        printf "\n  \e[1;31m✘ Cancelled.\e[0m\n"
        return 1
    end
    switch $dc
        case y Y yes Yes YES
        case '*'
            printf "\n  \e[1;31m✘ Cancelled.\e[0m\n"
            return 1
    end
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "apply_dconf"
    return $status
end

function _update_target_notifier --description 'reinstall the update notifier'
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "install_updater"
    return $status
end

function _update_target_clean --description 'flush caches and trim logs'
    _update_ui_begin 'update clean' '' 'Thumbnail cache' 'Font cache' 'Mesa shader cache' 'DNF metadata' 'Unused Flatpak runtimes' 'Review unused RPM packages' 'Old journal entries' 'Icon caches'
    or return 1
    set -l i 0
    for cache in thumbnails fontconfig mesa_shader_cache
        set i (math $i + 1)
        _update_ui_task $i running
        if test -L "$HOME/.cache/$cache"
            _update_ui_task $i failed
            _update_ui_publish pause
            printf '  Refusing to clean a symlinked cache: %s\n' "$HOME/.cache/$cache" >&2
            continue
        end
        if test -d "$HOME/.cache/$cache"
            # find also handles empty directories without unmatched Fish globs.
            _update_ui_quiet find "$HOME/.cache/$cache" -mindepth 1 -maxdepth 1 -exec rm -rf -- '{}' +
            _update_ui_task $i ok
        else
            _update_ui_task $i skipped
        end
    end
    _update_ui_task 4 running
    _update_ui_native sudo dnf clean all
    _update_ui_task 4 ok
    _update_ui_task 5 running
    # Native transaction/authorization/consent must remain foreground and visible.
    _update_ui_native flatpak uninstall --unused
    _update_ui_task 5 ok
    _update_ui_task 6 running
    _update_ui_native sudo dnf --setopt=assumeyes=False --setopt=assumeno=False --setopt=defaultyes=False autoremove
    _update_ui_task 6 ok
    _update_ui_task 7 running
    _update_ui_native sudo journalctl --vacuum-time=3d
    _update_ui_task 7 ok
    _update_ui_task 8 running
    set -l icons 0
    for icon in MacTahoe MacTahoe-dark hicolor
        if test -d "$HOME/.local/share/icons/$icon"
            _update_ui_quiet gtk-update-icon-cache "$HOME/.local/share/icons/$icon/"
            set icons 1
        end
    end
    if test $icons -eq 1
        _update_ui_task 8 ok
    else
        _update_ui_task 8 skipped
    end
    _update_ui_end 0
    set -l code $status
    set -l result ok
    test $code -ne 0; and set result fail
    _update_log_add clean "—" "—" $result UPDATE-CLEAN
    return $code
end

function _update_target_menu --description 'pick any target from a numbered list'
    printf "\n"
    _update_header "UPDATE — TARGETS"
    _update_box_text "[1]  icons         [9]  videos" "1;36"
    _update_box_text "[2]  gtk           [10] services" "1;36"
    _update_box_text "[3]  extensions    [11] gdm" "1;36"
    _update_box_text "[4]  wallpaper     [12] defaults" "1;36"
    _update_box_text "[5]  pfp           [13] dconf" "1;36"
    _update_box_text "[6]  theme         [14] notifier" "1;36"
    _update_box_text "[7]  fonts         [15] clean" "1;36"
    _update_box_text "[8]  sounds        [16] wallvault" "1;36"
    _update_box_text "[17] apps — install/remove desktop apps" "1;36"
    _update_box_text "[0]  exit" "1;36"
    _update_box_text ""
    _update_box_text "Made by eprahemi — Fedora MacTahoe © 2026" "1;37"
    _update_box_bottom
    read -l t -P "  Your choice [0-17]: "
    if test $status -ne 0
        printf "\n  \e[1;31m✘ Cancelled.\e[0m\n"
        return 1
    end
    switch $t
        case 1;  _update_target_icons
        case 2;  _update_target_gtk
        case 3;  _update_target_extensions
        case 4;  _update_target_wallpaper
        case 5;  _update_target_pfp
        case 6;  _update_target_theme
        case 7;  _update_target_fonts
        case 8;  _update_target_sounds
        case 9;  _update_target_videos
        case 10; _update_target_services
        case 11; _update_target_gdm
        case 12; _update_target_defaults
        case 13; _update_target_dconf
        case 14; _update_target_notifier
        case 15; _update_target_clean
        case 16; _update_target_wallvault
        case 17; _update_target_apps
        case 0 q
            printf "\n  \e[1;32m✓ Nothing changed.\e[0m\n"
            return 0
        case '*'
            printf "  \e[1;31m✘ Invalid — choose a number 0-17.\e[0m\n"
            return 1
    end
    return $status
end

# ══════════════════════════════════════════════════════════════
# wallvault — Wallvault asset vault (authorized bundle)
# ══════════════════════════════════════════════════════════════
# update wallvault | update wall | update w
# Flow: yes/no → one-time authorization code (no account needed) →
# boxed live transfer with a hand-rolled progress bar (curl runs in
# the background; the size comes from a HEAD probe) → decryption via
# 7zip with the baked-in key (never prompted, never displayed, only
# touched when the archive is genuinely encrypted) → staged into
# ~/Downloads/Wallvault-Pack → temp removed (also on abort). The
# default endpoint is baked in; a custom one can be set with
# `update wallvault <google-drive-link>` and an optional key override
# with `update wallvault pass <key>` — stored in
# ~/.cache/fedora-mactahoe/wallvault.conf (chmod 600).
function _update_target_wallvault --description 'Wallvault asset vault — gated bundle, boxed live transfer, decrypted, staged into Downloads'
    set -l cfg_dir "$HOME/.cache/fedora-mactahoe"
    set -l cfg "$cfg_dir/wallvault.conf"
    set -l default_url "https://drive.usercontent.google.com/download?id=1JOG25rsQKL-e4yx86HLsue8gkzsp9QHW&export=download&confirm=t"
    # baked-in archive decryption key — applied automatically in the background;
    # the user is never asked for it and never sees it (authorization code is
    # the only interactive credential).
    set -l default_key "hentailover"

    # ── subcommand: store an optional archive decryption key ──
    # update wallvault pass <key> — key optional; silent prompt if omitted
    # (only used when the archive is genuinely encrypted; plain zips
    #  never touch the key — the authorization code is the only gate)
    if set -q argv[1]; and string match -q 'pass' -- $argv[1]
        set -l key ""
        if set -q argv[2]
            set key $argv[2]
        else
            read -s key -P "  Archive decryption key: "
            if test -z "$key"
                printf "\n  \e[1;31m✘ No key provided — operation aborted.\e[0m\n"
                return 1
            end
        end
        set -l url "$default_url"
        if test -f "$cfg"
            set -l stored (command grep '^URL=' "$cfg" 2>/dev/null | string replace -r '^URL=' '')
            if test -n "$stored"
                set url "$stored"
            end
        end
        mkdir -p "$cfg_dir"
        printf 'URL=%s\nPASSWORD=%s\n' "$url" "$key" > "$cfg"
        chmod 600 "$cfg"
        printf "\n  \e[1;32m✓ Decryption key stored — credentials persisted (chmod 600).\e[0m\n"
        return 0
    end

    # ── subcommand: per-target help ──
    if set -q argv[1]; and string match -qr '^(help|h|-h|--help)$' -- $argv[1]
        _update_target_help wallvault
        return 0
    end

    # ── subcommand: register a custom endpoint (with optional key) ──
    # update wallvault <google-drive-link> [key]
    if set -q argv[1]
        set -l id (string match -r 'id=([A-Za-z0-9_-]{20,})' -- "$argv[1]")
        if not set -q id[2]
            set id (string match -r '/file/d/([A-Za-z0-9_-]{20,})' -- "$argv[1]")
        end
        if set -q id[2]
            set -l newkey ""
            if set -q argv[2]
                set newkey $argv[2]
            else if test -f "$cfg"
                set -l oldkey (command grep '^PASSWORD=' "$cfg" 2>/dev/null | string replace -r '^PASSWORD=' '')
                if test -n "$oldkey"
                    set newkey "$oldkey"
                end
            end
            mkdir -p "$cfg_dir"
            if test -n "$newkey"
                printf 'URL=%s\nPASSWORD=%s\n' "https://drive.usercontent.google.com/download?id=$id[2]&export=download&confirm=t" "$newkey" > "$cfg"
            else
                printf 'URL=%s\n' "https://drive.usercontent.google.com/download?id=$id[2]&export=download&confirm=t" > "$cfg"
            end
            chmod 600 "$cfg"
            printf "\n  \e[1;32m✓ Endpoint registered — configuration persisted (chmod 600).\e[0m\n"
            return 0
        end
        printf "\n  \e[1;31m✘ Invalid endpoint — no Google Drive file identifier found.\e[0m\n"
        printf "  \e[1;37m    Provide the complete share URL (must contain id=…).\e[0m\n"
        return 1
    end

    # ── configuration: endpoint + decryption key ──
    set -l vault_url "$default_url"
    set -l vault_pass ""
    if test -f "$cfg"
        set -l stored (command grep '^URL=' "$cfg" 2>/dev/null | string replace -r '^URL=' '')
        if test -n "$stored"
            set vault_url "$stored"
        end
        set -l stored_pass (command grep '^PASSWORD=' "$cfg" 2>/dev/null | string replace -r '^PASSWORD=' '')
        if test -n "$stored_pass"
            set vault_pass "$stored_pass"
        end
    end
    # silent background default — no prompt, no display
    if test -z "$vault_pass"
        set vault_pass "$default_key"
    end

    printf "\n"
    _update_box_top
    _update_box_title "Wallvault." "1;36"
    _update_box_text ""
    _update_box_text "500+ wallpapers, hand-picked with questionable" "1;37"
    _update_box_text "taste. Every theme, every vibe — all in one" "1;37"
    _update_box_text "drop. Your desktop will never be this cool." "1;37"
    _update_box_text ""
    _update_box_text "Heads up: some are +18. You're an adult." "1;33"
    _update_box_text "We trust you. Sort of." "1;33"
    _update_box_text ""
    _update_box_text "Proceed?   y = yes   n = no (boring)" "1;37"
    _update_box_bottom
    read -l yn -P "  Your choice [y/N]: "
    if test $status -ne 0
        printf "\n  \e[1;31m✘ Operation aborted.\e[0m\n"
        return 1
    end
    switch $yn
        case y Y yes Yes YES
        case '*'
            printf "\n  \e[1;31m✘ Operation aborted.\e[0m\n"
            return 1
    end

    # ── one-time authorization code ──
    set -l code (random 100000 999999)
    set -l code_start (date +%s)
    set -l attempts 3
    printf "\n"
    _update_box_top
    _update_box_title "YOUR CODE" "1;37"
    _update_box_text ""
    _update_box_title (string join ' ' (string split '' -- $code)) "1;36"
    _update_box_text ""
    _update_box_text "Enter your code to begin." "1;37"
    _update_box_bottom
    while test $attempts -gt 0
        read -l got -P "  Authorization code: "
        if test $status -ne 0
            printf "\n  \e[1;31m✘ Operation aborted.\e[0m\n"
            return 1
        end
        if test (math (date +%s) - $code_start) -gt 600
            printf "\n  \e[1;31m✘ Authorization expired — re-run update wallvault.\e[0m\n"
            return 1
        end
        if test "$got" = "$code"
            break
        end
        set attempts (math $attempts - 1)
        if test $attempts -gt 0
            printf "\n  \e[1;31m✘ Verification failed — %d attempt(s) remaining.\e[0m\n" $attempts
        else
            printf "\n  \e[1;31m✘ Verification failed — access locked. Re-run for a new code.\e[0m\n"
            return 1
        end
    end

    # ── workspace allocation + Ctrl+C safety ──
    _update_ui_begin 'update wallvault' '' 'Download Wallvault archive' 'Verify archive' 'Extract archive' 'Publish Wallvault folder'
    or return 1
    _update_wallvault_work "$vault_url" "$vault_pass"
    set -l result $status
    if test $result -ne 0
        _update_ui_task $__update_ui_current failed
    end
    _update_ui_end $result
    return $status
end

function _update_wallvault_work --argument-names vault_url vault_pass
    set -l tbase /tmp
    if set -q TMPDIR; and test -n "$TMPDIR"
        set tbase "$TMPDIR"
    end
    set -l tmp (mktemp -d "$tbase/wallvault.XXXXXX") 2>/dev/null
    if test -z "$tmp"; or not test -d "$tmp"
        printf "\n  \e[1;31m✘ Workspace allocation failed — temporary directory unavailable.\e[0m\n"
        return 1
    end
    # Foreground downloader; the shared engine is the only background painter.
    _update_ui_task 1 running
    set -l zip "$tmp/wallvault.zip"
    set -l attempt 0
    set -l dl_rc 1
    while test $attempt -lt 2
        set attempt (math $attempt + 1)
        if test $attempt -gt 1
            printf 'Retrying Wallvault download (attempt %s).\n' $attempt >> "$__update_ui_log"
        end
        curl -q -fL --retry 3 --retry-delay 2 --max-time 900 -o "$zip" "$vault_url" >> "$__update_ui_log" 2>&1
        set dl_rc $status
        if test "$__update_ui_cancel" = 1; or test $dl_rc -eq 130
            rm -rf "$tmp"
            return 130
        end
        if test $dl_rc -eq 0; and test -s "$zip"
            break
        end
        rm -f "$zip" 2>/dev/null
    end
    if test $dl_rc -ne 0; or not test -s "$zip"
        _update_ui_task 1 failed
        rm -rf "$tmp" 2>/dev/null
        _update_ui_publish pause
        printf "\n  \e[1;31m✘ Transfer failed — endpoint unreachable or connection interrupted.\e[0m\n"
        return 1
    end
    _update_ui_task 1 ok
    _update_ui_task 2 running

    # ── integrity verification (7zip backend; silent background decryption) ──
    if command -q 7z
        # detect encryption via listing — no password needed, never prompts
        set -l enc (7z l -slt "$zip" 2>/dev/null | grep -c "Encrypted = +")
        if test "$enc" -gt 0
            # archive is genuinely encrypted — decrypt in the background with the
            # baked-in key (never prompted, never displayed)
            if not _update_ui_quiet 7z t -p"$vault_pass" "$zip" </dev/null
                rm -rf "$tmp" 2>/dev/null
                printf "\n  \e[1;31m✘ Decryption failed — the bundle could not be opened.\e[0m\n"
                return 1
            end
        else
            # plain archive: verify without any password
            if not _update_ui_quiet 7z t -p"$vault_pass" "$zip" </dev/null
                rm -rf "$tmp" 2>/dev/null
                printf "\n  \e[1;31m✘ Integrity verification failed — payload is not a valid archive.\e[0m\n"
                return 1
            end
        end
    else
        rm -rf "$tmp" 2>/dev/null
        printf "\n  \e[1;31m✘ Archive backend unavailable — the 7zip package is required.\e[0m\n"
        printf "  \e[1;37m    Run update (full / services) to install it, then retry.\e[0m\n"
        return 1
    end
    _update_ui_task 2 ok
    _update_ui_task 3 running

    # ── extraction + staging into Downloads ──
    _update_ui_quiet mkdir -p "$tmp/extract"; or begin; rm -rf "$tmp"; return 1; end
    if test -n "$vault_pass"
        _update_ui_quiet 7z x -y -o"$tmp/extract" -p"$vault_pass" "$zip" </dev/null
    else
        _update_ui_quiet 7z x -y -o"$tmp/extract" -p- "$zip" </dev/null
    end
    if test $status -ne 0
        rm -rf "$tmp"
        return 1
    end
    if test -z (find "$tmp/extract" -type f -print -quit)
        _update_ui_task 3 failed
        rm -rf "$tmp"
        return 1
    end
    _update_ui_task 3 ok
    _update_ui_task 4 running
    set -l folder (find "$tmp/extract" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)
    if test -z "$folder"
        set folder "$tmp/extract"
    end
    set -l name "Wallvault-Pack"
    set -l dest "$HOME/Downloads"
    _update_ui_quiet mkdir -p "$dest"; or begin; rm -rf "$tmp"; return 1; end
    if test -e "$dest/$name"
        set name "Wallvault-Pack-"(date +%Y%m%d-%H%M%S)
    end
    _update_ui_quiet mv -T -n -- "$folder" "$dest/$name"
    # mv -n may report success without moving after a concurrent collision.
    if test $status -ne 0; or test -d "$folder"
        rm -rf "$tmp"
        return 1
    end
    if not test -d "$dest/$name"
        rm -rf "$tmp" 2>/dev/null
        printf "\n  \e[1;31m✘ Staging failed — unable to deploy the bundle into the target directory.\e[0m\n"
        return 1
    end
    set -l count (string trim -- (find "$dest/$name" -type f 2>/dev/null | wc -l))
    rm -rf "$tmp" 2>/dev/null
    _update_ui_task 4 ok
    printf 'Published %s files to %s/%s\n' "$count" "$dest" "$name" >> "$__update_ui_log"
    _update_ui_publish pause
    printf '\n  Wallvault: %s files saved to %s/%s\n' "$count" "$dest" "$name"
    return 0
end

# ══════════════════════════════════════════════════════════════
# update uninstall — guarded full removal
# ══════════════════════════════════════════════════════════════
# Three gates, so a stray keystroke can never remove anything:
#   1. the word REMOVE typed exactly (case-sensitive, 2 tries)
#   2. a live 30-second countdown — press ANY key to cancel
#   3. uninstall.sh's own per-phase confirmations (60s each)
# Flag: --purge   also removes RPMs, Flatpaks and third-party repos
function _update_target_uninstall --description 'guarded full removal via uninstall.sh'
    set -l purge 0
    for a in $argv
        switch (string lower -- "$a")
            case purge --purge --purge-packages -p
                set purge 1
            case h help -h --help
                _update_target_help uninstall
                return 0
        end
    end

    # ── network preflight — offline users should not go through the gates ──
    printf "\n  \e[1;37mChecking connection to GitHub...\e[0m"
    if not curl -sfI --max-time 10 "https://codeload.github.com/eprahemi/Fedora-MacTahoe-Eprahemi/tar.gz/refs/heads/main" -o /dev/null 2>/dev/null
        printf " \e[1;31mOFFLINE\e[0m\n\n"
        _update_box_top
        _update_box_title "NO INTERNET — NOTHING HAPPENED" "1;31"
        _update_box_rule
        _update_box_text "Hey, easy there — the bundle can't be fetched" "1;37"
        _update_box_text "right now, so nothing was changed at all." "1;37"
        _update_box_text ""
        _update_box_tag "BEFORE YOU UNINSTALL"
        _update_box_text ""
        _update_box_text "Why take everything apart? Try these first:" "1;33"
        _update_box_text "  update full     — fresh reinstall of everything" "1;36"
        _update_box_text "  update check    — status + health at a glance" "1;36"
        _update_box_text "Whatever is bothering you might just go away." "1;33"
        _update_box_text ""
        _update_box_tag "STILL STUCK? TALK TO ME"
        _update_box_text ""
        _update_box_text "Tell me what's wrong and I will fix it for you:" "1;33"
        _update_box_text "  Discord:   .3ar." "1;37"
        _update_box_text "  Website:   fedoratahoe.pages.dev  (report form)" "1;37"
        _update_box_text "File a report, I will see it and reply — and" "1;33"
        _update_box_text "fix it in a future update. Until then, chill." "1;33"
        _update_box_bottom
        return 1
    end
    printf " \e[1;32mOK\e[0m\n"

    # ── gate 1: typed word — exact, case-sensitive ──
    set -l magic "REMOVE"
    if test $purge -eq 1
        set magic "REMOVE ALL"
    end
    printf "\n"
    _update_box_top
    _update_box_title "UNINSTALL — EVERYTHING WILL BE REMOVED" "1;31"
    _update_box_rule
    _update_box_text "Themes, icons, fonts, sounds, extensions, GDM," "1;37"
    _update_box_text "wallpapers and services are removed; your old" "1;37"
    _update_box_text "dconf/fish snapshots and stock Fedora defaults" "1;37"
    _update_box_text "are restored to pre-MacTahoe state." "1;37"
    if test $purge -eq 1
        _update_box_text ""
        _update_box_tag "LET'S TALK FIRST — SERIOUSLY"
        _update_box_text ""
        _update_box_text "Purge erases every app, Flatpak, browser and" "1;31"
        _update_box_text "ALL their data. If something is broken this" "1;31"
        _update_box_text "won't fix it — it just deletes everything." "1;31"
        _update_box_text "  update full     — fresh reinstall, fixes most bugs" "1;36"
        _update_box_text "  update check    — status + health at a glance" "1;36"
        _update_box_text "Report the bug instead — Discord .3ar. or" "1;33"
        _update_box_text "fedoratahoe.pages.dev — I'll fix it properly." "1;33"
        _update_box_text ""
    else
        _update_box_text ""
        _update_box_tag "WHY UNINSTALL? LET'S TALK"
        _update_box_text ""
        _update_box_text "Hey — everything okay? Before you take it all" "1;33"
        _update_box_text "apart, try these — they fix most things:" "1;33"
        _update_box_text "  update full     — fresh reinstall of everything" "1;36"
        _update_box_text "  update check    — status + health at a glance" "1;36"
        _update_box_text "Bug or broken bit? Tell me and I'll fix it:" "1;33"
        _update_box_text "  Discord:   .3ar." "1;37"
        _update_box_text "  Website:   fedoratahoe.pages.dev" "1;37"
        _update_box_text ""
    end
    _update_box_text "Type the word below EXACTLY to continue." "1;33"
    _update_box_text "Anything else cancels and keeps everything." "1;33"
    if test $purge -eq 1
        _update_box_rule
        _update_box_text "HIGH RISK — this also wipes every MacTahoe" "1;31"
        _update_box_text "app, ALL Flatpaks, Chrome/Edge/VS Code," "1;31"
        _update_box_text "their repos and ALL their saved data." "1;31"
        _update_box_text ""
        _update_box_text "For purge mode the word is  REMOVE ALL" "1;33"
        _update_box_text "not just REMOVE — think twice first." "1;33"
    end
    _update_box_bottom

    set -l tries 0
    set -l typed ""
    while test $tries -lt 2
        printf "\n"
        read typed -P "  Type  $magic  (case-sensitive): "
        if test $status -ne 0 -o -z "$typed"
            printf "\n  \e[1;31m✘ Cancelled — everything stays.\e[0m\n"
            return 1
        end
        if test "$typed" = "$magic"
            break
        end
        set tries (math $tries + 1)
        if test $tries -lt 2
            printf "\n  \e[1;33m⚠  Not the word — one more try, then it cancels.\e[0m\n"
        end
    end
    if not test "$typed" = "$magic"
        printf "\n  \e[1;31m✘ Cancelled — everything stays.\e[0m\n"
        return 1
    end

    # ── gate 2: 30-second countdown — ANY key cancels ──
    printf "\n"
    _update_box_top
    if test $purge -eq 1
        _update_box_text "REMOVE ALL accepted — HIGH RISK. Starts in 30s." "1;31"
    else
        _update_box_text "REMOVE accepted. Uninstall starts in 30 seconds." "1;31"
    end
    _update_box_text "Press  Ctrl+C  or ANY key to cancel it now." "1;37"
    _update_box_bottom
    printf "\n  \e[1;37mStarting in:\e[0m "
    for i in (seq 30 -1 1)
        if read -t 1 -n 1 -s cancel_key 2>/dev/null
            printf "\n\n  \e[1;31m✘ Cancelled — everything stays.\e[0m\n"
            return 1
        end
        if test $i -le 10
            printf "\e[1;31m%2ds\e[0m  " $i
        else
            printf "\e[1;36m%2ds\e[0m  " $i
        end
    end
    printf "\n"

    # ── gate 3: fresh bundle + fingerprint, then run ──
    printf "\n  \e[1;37mDownloading the MacTahoe bundle from GitHub...\e[0m\n"
    set -l tmpdir (mktemp -d /tmp/mactahoe-uninstall.XXXXXX 2>/dev/null)
    if test -z "$tmpdir"; or not test -d "$tmpdir"
        printf "\n  \e[1;31m✘ Could not create a temp folder.\e[0m\n"
        return 1
    end
    curl -fsSL --max-time 120 "https://codeload.github.com/eprahemi/Fedora-MacTahoe-Eprahemi/tar.gz/refs/heads/main" -o "$tmpdir/bundle.tar.gz" 2>/dev/null
    if test $status -ne 0
        rm -rf "$tmpdir"
        printf "\n  \e[1;31m✘ Could not download the bundle — check your connection.\e[0m\n"
        return 1
    end
    tar -xzf "$tmpdir/bundle.tar.gz" -C "$tmpdir" 2>/dev/null
    if test $status -ne 0
        rm -rf "$tmpdir"
        printf "\n  \e[1;31m✘ Could not extract the bundle.\e[0m\n"
        return 1
    end
    set -l bundle_dir "$tmpdir/Fedora-MacTahoe-Eprahemi-main"
    if not test -f "$bundle_dir/uninstall.sh"
        rm -rf "$tmpdir"
        printf "\n  \e[1;31m✘ Bundle is missing uninstall.sh — aborting.\e[0m\n"
        return 1
    end

    set -l got_hash (string match -r '^[0-9a-f]+' (sha256sum "$bundle_dir/uninstall.sh" 2>/dev/null))
    printf "\n"
    _update_box_top
    _update_box_text "uninstall.sh fingerprint" "1;37"
    _update_box_text "  "(string sub -l 32 -- $got_hash)"…" "1;31"
    _update_box_bottom
    printf "\n"

    if test $purge -eq 1
        bash "$bundle_dir/uninstall.sh" --purge-packages
    else
        bash "$bundle_dir/uninstall.sh"
    end
    set -l rc $status
    rm -rf "$tmpdir" 2>/dev/null
    return $rc
end

# ══════════════════════════════════════════════════════════════
# update — the entry point
# ══════════════════════════════════════════════════════════════
# Fixed installer desktop-app allowlist. Never turn input into shell commands.
function _update_apps_catalog
    printf '%s\n' 'Kitty|rpm|kitty' 'Celluloid|rpm|celluloid' 'VLC|rpm|vlc' \
        'Kdenlive|rpm|kdenlive' 'Volume Control|rpm|pavucontrol' 'Main Menu|rpm|alacarte' \
        'GNOME Tweaks|rpm|gnome-tweaks' 'GNOME Characters|rpm|gnome-characters' \
        'LibreOffice Writer|rpm|libreoffice-writer' 'LibreOffice Calc|rpm|libreoffice-calc' \
        'LibreOffice Impress|rpm|libreoffice-impress' 'Firefox|rpm|firefox' \
        'Google Chrome|rpm|google-chrome-stable' 'Microsoft Edge|rpm|microsoft-edge-stable' \
        'Visual Studio Code|rpm|code' 'ZapZap|flatpak|com.rtosta.zapzap' \
        'Mousam|flatpak|io.github.amit9838.mousam' 'Extension Manager|flatpak|com.mattjakeman.ExtensionManager' \
        'Flatseal|flatpak|com.github.tchx84.Flatseal' 'Gear Lever|flatpak|it.mijorus.gearlever' \
        'HandBrake|flatpak|fr.handbrake.ghb' 'Komikku|flatpak|info.febvre.Komikku' \
        'Obsidian|flatpak|md.obsidian.Obsidian' 'Proton VPN|flatpak|com.protonvpn.www' \
        'Spotify|flatpak|com.spotify.Client' 'LocalSend|flatpak|org.localsend.localsend_app' \
        'Discord (optional)|flatpak|com.discordapp.Discord'
end

# Allowlist of app-specific data dirs safe to move to Trash on explicit request.
function _update_apps_data_candidates --argument-names kind id
    if test "$kind" = flatpak
        set -l base "$HOME/.var/app/$id"
        if test -d "$base"
            printf '%s\n' "$base"
        end
    end
    return 0
end

function _update_apps_safe_trash --argument-names path
    test -n "$path"; or return 1
    string match -q "$HOME/*" "$path"; or return 1
    if test -L "$path"
        return 1
    end
    set -l real (realpath -e "$path" 2>/dev/null)
    if test -n "$real"
        string match -q "$HOME/*" "$real"; or return 1
    end
    if command -q gio
        gio trash -- "$path"; or return $status
    else if command -q trash-put
        trash-put -- "$path"; or return $status
    else
        return 1
    end
    not test -e "$path"; and not test -L "$path"
end

# Emit only after validating the entire selection; malformed suffixes do nothing.
function _update_apps_selection
    set -l input (string replace -a ',' ' ' -- "$argv[1]" | string trim)
    set -l limit 27
    set -q argv[2]; and set limit $argv[2]
    if contains -- (string lower -- "$input") a all
        test $limit -gt 0; or return 1
        seq $limit
        return 0
    end
    string match -qr '^[0-9 ,\t-]+$' -- "$input"; or return 1
    set -l result
    for token in (string split -n ' ' -- (string replace -ar '\s+' ' ' -- "$input"))
        string match -qr '^[0-9]{1,2}(-[0-9]{1,2})?$' -- "$token"; or return 1
        set -l bounds (string split '-' -- "$token")
        set -l first (math "$bounds[1] + 0")
        set -l last $first
        if set -q bounds[2]
            set last (math "$bounds[2] + 0")
        end
        test $first -ge 1; and test $last -le $limit; and test $first -le $last; or return 1
        for n in (seq $first $last)
            contains -- $n $result; or set -a result $n
        end
    end
    test (count $result) -gt 0; or return 1
    printf '%s\n' $result
end

# Empty output = missing; query failure = unknown (never interpreted as missing).
# Every installed Flatpak branch and scope is shown and explicitly approved.
function _update_apps_probe --argument-names kind id
    if test "$kind" = rpm
        set -l packages (rpm -qa --queryformat '%{NAME}\n')
        test $status -eq 0; or return 1
        if contains -- "$id" $packages
            echo rpm
        end
    else
        for scope in user system
            set -l refs (flatpak list --$scope --app --columns=ref)
            test $status -eq 0; or return 1
            for ref in $refs
                set -l parts (string split / -- "$ref")
                if test "$parts[1]" = "$id"
                    # Reject malformed tool output, not just malformed user input.
                    string match -qr '^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$' -- "$ref"; or return 1
                    echo "$scope:$ref"
                end
            end
        end
    end
    return 0
end

function _update_apps_help
    _update_box_top
    _update_box_title 'DESKTOP APPS' '1;36'
    _update_box_rule
    _update_box_text 'update apps — manage the 27 installer desktop apps'
    _update_box_text 'First choose: 1 Install apps / 2 Remove apps / q Exit.'
    _update_box_text 'Install lists missing apps; Remove lists installed apps.'
    _update_box_text 'Unknown apps and protected Kitty cannot be removed.'
    _update_box_text 'Select 3 5, 3,5 or 3-5; a/all selects this entire list.'
    _update_box_text 'Enter/q cancels; b returns to the action menu.'
    _update_box_text 'Review the exact plan; confirmation defaults to No.'
    _update_box_text 'Kitty removal is protected in this active terminal.'
    _update_box_text 'All installed Flatpak scopes/branches appear in the plan.'
    _update_box_text 'Keep data, or explicitly Trash known Flatpak data.'
    _update_box_text 'Data removal needs separate typed confirmation.'
    _update_box_text 'Remove-all also requires typing REMOVE ALL.'
    _update_box_text 'Native package prompts remain enabled.'
    _update_box_text 'Review dependent removals at the DNF prompt; decline'
    _update_box_text 'if anything outside your approved plan would be removed.'
    _update_box_text 'Uses existing repos only; never rewrites repo settings.'
    _update_box_text 'Browser setup help: google.com/chrome or microsoft.com'
    _update_box_text 'Flatpak installs use existing system Flathub.'
    _update_box_bottom
end

# Output stable catalog IDs, never display numbers. Unknown states fail closed.
function _update_apps_eligible --argument-names mode
    set -l catalog (_update_apps_catalog)
    for n in (seq (count $catalog))
        set -l fields (string split '|' -- "$catalog[$n]")
        set -l refs (_update_apps_probe $fields[2] $fields[3])
        if test $status -ne 0
            printf '  %s: status unknown; excluded.\n' "$fields[1]" >&2
            continue
        end
        if test "$mode" = install; and test (count $refs) -eq 0
            echo $n
        else if test "$mode" = remove; and test (count $refs) -gt 0; and test "$fields[3]" != kitty
            echo $n
        end
    end
end

function _update_apps_show --argument-names mode
    set -l catalog (_update_apps_catalog)
    set -l eligible $argv[2..-1]
    _update_box_top
    _update_box_title (string upper -- "$mode apps") '1;36'
    _update_box_rule
    set -l number 0
    for n in $eligible
        set number (math $number + 1)
        set -l fields (string split '|' -- "$catalog[$n]")
        set -l color '1;31'
        if test "$mode" = remove
            set color '1;32'
        end
        _update_box_text (printf '%2d  %s' $number "$fields[1]") "$color"
    end
    _update_box_rule
    if test "$mode" = remove
        _update_box_text 'Kitty is protected: it runs this updater; excluded.'
    end
    _update_box_text 'User caches, settings and data are kept.'
    _update_box_text 'Select: 3 5 / 3,5 / 3-5 / a or all (current list).'
    _update_box_text 'Enter/q exits; b returns to the action menu.'
    _update_box_bottom
end

function _update_target_apps
    if test (count $argv) -gt 0
        _update_apps_help
        return 1
    end
    for dependency in rpm flatpak dnf
        if not command -q $dependency
            printf '  Required command missing: %s. No changes made.\n' $dependency
            return 1
        end
    end
    set -l answer ''
    set -l mode ''
    set -l eligible
    set -l selected
    set -l positions
    while true
        _update_box_top
        _update_box_title 'DESKTOP APPS' '1;36'
        _update_box_text '1 Install apps'
        _update_box_text '2 Remove apps'
        _update_box_text 'q Exit'
        _update_box_bottom
        read -P '  Action (Enter exits): ' answer; or return 0
        set answer (string lower -- (string trim -- "$answer"))
        contains -- "$answer" '' q exit cancel; and return 0
        switch "$answer"
            case 1
                set mode install
            case 2
                set mode remove
            case '*'
                printf '  Choose 1 Install apps, 2 Remove apps, or q Exit.\n'
                continue
        end
        set eligible (_update_apps_eligible $mode)
        _update_apps_show $mode $eligible
        if test (count $eligible) -eq 0
            printf '  No eligible apps to %s. Returning to the action menu.\n' $mode
            continue
        end
        while true
            read -P '  App numbers or a/all (Enter exits, b back): ' answer; or return 0
            set answer (string trim -- "$answer")
            contains -- (string lower -- "$answer") '' q exit cancel; and return 0
            contains -- (string lower -- "$answer") b back; and break
            set positions (_update_apps_selection "$answer" (count $eligible))
            if test $status -eq 0
                set selected
                for position in $positions
                    set -a selected $eligible[$position]
                end
                break
            end
            printf '  Use numbers 1-%s: 3 5, 3,5 or 3-5 (not "3 or 5"); a/all.\n' (count $eligible)
        end
        contains -- (string lower -- "$answer") b back; and continue
        break
    end
    set -l catalog (_update_apps_catalog)
    set -l snapshots
    printf '\n  EXACT PLAN (all listed Flatpak copies are included):\n'
    for n in $selected
        set -l fields (string split '|' -- "$catalog[$n]")
        set -l refs (_update_apps_probe $fields[2] $fields[3])
        if test $status -ne 0
            printf '  Cannot determine %s status. No changes made.\n' "$fields[1]"
            return 1
        end
        if begin; test "$mode" = install; and test (count $refs) -gt 0; end; or begin
                test "$mode" = remove; and begin; test (count $refs) -eq 0; or test "$fields[3]" = kitty; end
            end
            printf '  App status changed; rerun to review the intended action. No changes made.\n'
            return 1
        end
        set -a snapshots (string join ',' -- missing $refs)
        if test "$mode" = remove
            for ref in $refs
                printf '  REMOVE  %s  [%s: %s]\n' "$fields[1]" "$fields[3]" "$ref"
            end
        else
            printf '  INSTALL %s  [%s: %s]\n' "$fields[1]" "$fields[2]" "$fields[3]"
        end
    end
    printf '\n  DNF may also remove dependent packages. Review its transaction\n'
    printf '  and decline if it includes anything you did not approve.\n'
    printf '  Existing repositories only.\n'
    # Guard the entire eligible list even when selected by numeric range/single number.
    if test "$mode" = remove; and test (count $selected) -eq (count $eligible)
        read -P '  Removing the entire eligible list. Type REMOVE ALL: ' answer; or return 0
        test "$answer" = 'REMOVE ALL'; or return 0
    end

    set -l remove_data 0
    set -l data_list
    if test "$mode" = remove
        printf '\n'
        _update_box_top
        _update_box_text 'What to do with this selection?' '1;36'
        _update_box_text ''
        _update_box_text '1 Remove app only — keep settings, caches and data' '1;37'
        _update_box_text '2 Remove app and data — known folders go to Trash' '1;33'
        _update_box_text 'q Cancel' '1;37'
        _update_box_bottom
        read -P '  Choice [1]: ' answer; or return 0
        set answer (string lower -- (string trim -- "$answer"))
        if contains -- "$answer" '' q exit cancel
            return 0
        end
        if test "$answer" = '2'
            set remove_data 1
            printf '\n  App-specific data to move to Trash (if present):\n'
            set -l has_data 0
            for n in $selected
                set -l fields (string split '|' -- "$catalog[$n]")
                set -l candidates (_update_apps_data_candidates $fields[2] $fields[3])
                if test (count $candidates) -gt 0
                    set has_data 1
                    for c in $candidates
                        printf '    • %s → %s\n' "$fields[1]" "$c"
                        set -a data_list (string join '|' -- "$fields[1]" "$c")
                    end
                else
                    printf '    • %s: data cleanup not supported for this app\n' "$fields[1]"
                end
            end
            printf '\n  These go to Trash (recoverable until emptied). Moving to Trash does not\n'
            printf '  free disk space until you empty Trash. Shared folders and personal files\n'
            printf '  are NOT touched. Only app-specific allowlisted paths under $HOME.\n'
            if test "$has_data" -eq 1
                if test (count $selected) -eq 1
                    read -P "  Type REMOVE $(string replace -a ' ' '_' -- "$catalog[$selected[1]]" | string split '|' -f1) DATA: " answer; or return 0
                    set -l expected (string upper -- (string replace -a ' ' '_' -- (string split '|' -- "$catalog[$selected[1]]")[1]))
                    test (string upper -- (string replace -a ' ' '_' -- "$answer")) = "REMOVE_"$expected"_DATA"; or return 0
                else
                    read -P '  Removing app data for multiple apps. Type REMOVE ALL APP DATA: ' answer; or return 0
                    test "$answer" = 'REMOVE ALL APP DATA'; or return 0
                end
            else
                printf '  Nothing known to clean. Skipping data removal.\n'
                set remove_data 0
            end
        end
    end

    read -P '  Proceed with this exact plan? [y/N]: ' answer; or return 0
    contains -- (string lower -- (string trim -- "$answer")) y yes; or return 0
    if test (_update_low_battery) -eq 1
        printf '  Low battery: connect power, then retry. No changes made.\n'
        return 1
    end
    # Revalidate the whole plan before the first mutation.
    set -l i 0
    for n in $selected
        set i (math $i + 1)
        set -l fields (string split '|' -- "$catalog[$n]")
        set -l refs (_update_apps_probe $fields[2] $fields[3])
        if test $status -ne 0; or test (string join ',' -- missing $refs) != "$snapshots[$i]"
            printf '  App status changed or is unknown; rerun to review. No changes made.\n'
            return 1
        end
    end
    set -l failed 0
    set -l labels
    for n in $selected
        set -l fields (string split '|' -- "$catalog[$n]")
        set -a labels "$mode $fields[1]"
    end
    _update_ui_begin 'update apps' '' $labels; or return 1
    set i 0
    for n in $selected
        set i (math $i + 1)
        _update_ui_task $i running
        if test "$__update_ui_cancel" = 1
            break
        end
        set -l fields (string split '|' -- "$catalog[$n]")
        set -l refs (string split ',' -- "$snapshots[$i]")
        set -e refs[1]
        # Recheck immediately before each action too: never flip install into remove.
        set -l current (_update_apps_probe $fields[2] $fields[3])
        if test $status -ne 0; or test (string join ',' -- missing $current) != "$snapshots[$i]"
            printf '  %s: status changed/unknown; skipped. Rerun to review.\n' "$fields[1]"
            set failed 1
            _update_ui_task $i skipped
            _update_ui_publish pause
            continue
        end
        set -l rc 0
        if test "$fields[2]" = rpm
            if test "$mode" = remove
                # No -y: the user must review the native dependency transaction.
                if not dnf remove --help | string match -q '*--no-autoremove*'
                    printf '  Safe removal flag unsupported; skipping %s.\n' "$fields[1]"
                    set rc 1
                else
                    _update_ui_native sudo dnf --setopt=assumeyes=False --setopt=assumeno=False --setopt=defaultyes=False remove --no-autoremove -- "$fields[3]"
                    set rc $status
                end
            else
                _update_ui_native sudo dnf --setopt=assumeyes=False --setopt=assumeno=False --setopt=defaultyes=False install -- "$fields[3]"
                set rc $status
            end
        else if test "$mode" = remove
            for ref in $refs
                set -l parts (string split ':' -- "$ref")
                _update_ui_native flatpak uninstall --$parts[1] -- "$parts[2]"; or set rc 1
            end
        else
            _update_ui_native flatpak install --system flathub "$fields[3]"
            set rc $status
        end
        set -l after (_update_apps_probe $fields[2] $fields[3])
        set -l query_rc $status
        if test $rc -ne 0; or test $query_rc -ne 0; or begin
                test "$mode" = remove; and test (count $after) -gt 0
            end; or begin
                test "$mode" = install; and test (count $after) -eq 0
            end
            set failed 1
            _update_ui_task $i failed
            _update_ui_publish pause
            printf '  %s: not completed or could not verify; see errors above.\n' "$fields[1]"
            printf '  Check the app vendor repository/Flathub setup before retrying.\n'
            switch "$fields[3]"
                case google-chrome-stable
                    printf '  Official Chrome setup: https://www.google.com/chrome/\n'
                case microsoft-edge-stable
                    printf '  Official Edge setup: https://www.microsoft.com/edge/download\n'
                case code
                    printf '  Official VS Code setup: https://code.visualstudio.com/docs/setup/linux\n'
            end
        else
            printf '  %s: requested change verified.\n' "$fields[1]"
            if test "$mode" = remove; and test "$remove_data" -eq 1
                set -l candidates (_update_apps_data_candidates $fields[2] $fields[3])
                for c in $candidates
                    if test -e "$c"; and not test -L "$c"
                        set -l real (realpath -e "$c" 2>/dev/null)
                        if test -z "$real"; or string match -q "$HOME/*" "$real"
                            if _update_ui_quiet _update_apps_safe_trash "$c"
                                printf '  %s: moved app data to Trash.\n' "$fields[1]"
                            else
                                printf '  %s: could not move app data to Trash (skipped).\n' "$fields[1]"
                                set failed 1
                                _update_ui_task $i failed
                            end
                        else
                            printf '  %s: app data path unsafe; skipped.\n' "$fields[1]"
                            set failed 1
                            _update_ui_task $i failed
                        end
                    end
                end
            end
            _update_ui_task $i ok
        end
    end
    _update_ui_end $failed
    set failed $status
    set eligible (_update_apps_eligible $mode)
    _update_apps_show $mode $eligible
    return $failed
end

function update --description 'Fedora MacTahoe update — Kitty only (menu: quick/full/configs/check)'
    # ── Kitty gate: only Kitty is supported ──
    if not set -q KITTY_PID
        printf "\e[1;31m\n"
        _update_box_top
        _update_box_title "BLOCKED" "1;37"
        _update_box_text ""
        _update_box_text "Fedora MacTahoe requires Kitty terminal." "1;33"
        _update_box_text "Open Kitty and type 'update' there." "1;33"
        _update_box_text ""
        _update_box_bottom
        printf "\e[0m\n"
        return 1
    end

    # ── subcommand dispatch ──
    if set -q argv[1]
        set -l sub (string lower -- "$argv[1]")
        if contains -- "$sub" app aps a
            printf '  Did you mean "update apps"? No changes made.\n'
            _update_apps_help
            return 1
        end
        if test "$sub" = apps
            if set -q argv[2]; and contains -- "$argv[2]" h help -h --help
                _update_apps_help
                return 0
            end
            _update_target_apps $argv[2..-1]
            return $status
        end
        if contains -- "$sub" h help -h --help; and set -q argv[2]; and test "$argv[2]" = apps
            _update_apps_help
            return 0
        end
        # ── update <target> help → per-target help box (read-only) ──
        if set -q argv[2]
            set -l sub2 (string lower -- "$argv[2]")
            switch $sub2
                case h help -h --help
                    switch $sub
                        case icons theme fonts sounds extensions gdm wallpaper pfp gtk videos services defaults dconf notifier clean menu wallvault wall w uninstall
                            _update_target_help $sub
                            return 0
                    end
            end
        end
        switch $sub
            case check
                _update_check
                return $status
            case log
                _update_log_show
                return $status
            case configs
                _update_configs_mode
                return $status
            case full
                if not _update_loading 8
                    return 1
                end
                printf "\n"
                _update_box_top
                _update_box_text "Full reinstall — re-runs everything from scratch" "1;33"
                _update_box_text "and may ask for your password." "1;33"
                _update_box_text ""
                _update_box_text "Continue?   y = yes   n = no (default)" "1;37"
                _update_box_bottom
                read -l fc -P "  Your choice [y/N]: "
                if test $status -ne 0
                    printf "\n  \e[1;31m✘ Cancelled.\e[0m\n"
                    return 1
                end
                switch $fc
                    case y Y yes Yes YES
                        set -l current_ver (_update_state_version)
                        set -l latest_ver (_update_latest_version)
                        _update_run full full $current_ver $latest_ver
                        return $status
                    case '*'
                        printf "\n  \e[1;31m✘ Cancelled.\e[0m\n"
                        return 1
                end
            case h help -h --help
                # update help <target> → per-target help box (alias of update <target> help)
                if set -q argv[2]
                    set -l t2 (string lower -- "$argv[2]")
                    switch $t2
                        case icons theme fonts sounds extensions gdm wallpaper pfp gtk videos services defaults dconf notifier clean menu wallvault wall w uninstall
                            _update_target_help $t2
                            return 0
                    end
                end
                _update_usage
                return 0
            case quick
                # same as menu [1] — incremental update with saved answers,
                # no prompts, no loading ritual (quick means quick);
                # logged as ( UPDATE-QUICK )
                set -l current_ver (_update_state_version)
                set -l latest_ver (_update_latest_version)
                _update_run incremental quick $current_ver $latest_ver
                return $status
            case icons
                _update_target_icons
                return $status
            case gtk
                _update_target_gtk
                return $status
            case extensions
                _update_target_extensions
                return $status
            case wallpaper
                _update_target_wallpaper $argv[2..-1]
                return $status
            case pfp
                _update_target_pfp $argv[2..-1]
                return $status
            case theme
                _update_target_theme
                return $status
            case fonts
                _update_target_fonts
                return $status
            case sounds
                _update_target_sounds
                return $status
            case videos
                _update_target_videos
                return $status
            case services
                _update_target_services
                return $status
            case gdm
                _update_target_gdm
                return $status
            case defaults
                _update_target_defaults
                return $status
            case dconf
                _update_target_dconf
                return $status
            case notifier
                _update_target_notifier
                return $status
            case clean
                _update_target_clean
                return $status
            case wallvault wall w
                _update_target_wallvault $argv[2..-1]
                return $status
            case menu
                _update_target_menu
                return $status
            case uninstall
                _update_target_uninstall $argv[2..-1]
                return $status
            case '*'
                printf "\n  \e[1;31m✘ Unknown option: %s\e[0m\n" "$argv[1]"
                if command -q python3
                    python3 -c 'import difflib,sys
if difflib.get_close_matches(sys.argv[1], ["apps"], cutoff=0.55):
    print("  Did you mean update apps? Nothing was run; type it explicitly.")' "$sub"
                end
                _update_usage
                return 1
        end
    end

    # ── fetch + parse ──
    if not _update_fetch_manifest
        printf "\n  \e[1;31m✘ Could not fetch a complete, valid version manifest. Try again.\e[0m\n"
        return 1
    end
    set -l current_ver "0.0"
    if test -f "$HOME/.cache/fedora-mactahoe/install-state.json"
        set current_ver (cat "$HOME/.cache/fedora-mactahoe/install-state.json" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('version', '0.0'))
except Exception:
    print('0.0')
" 2>/dev/null)
    end
    set -l latest_ver ""
    set -l has_update 0
    set -l ch_lines
    for line in (_update_parse)
        switch $line
            case 'LATEST=*'
                set latest_ver (string replace 'LATEST=' '' -- $line)
            case 'HASUPDATE=*'
                set has_update (string replace 'HASUPDATE=' '' -- $line)
            case 'CH=*'
                set -a ch_lines (string replace 'CH=' '' -- $line)
        end
    end
    if test -z "$latest_ver"
        printf "\n  \e[1;31m✘ Could not read the version manifest.\e[0m\n"
        return 1
    end

    # ── the ritual: 5 seconds of loading, then the verdict ──
    if not _update_loading
        return 1
    end

    # ── header ──
    printf "\n"
    _update_header "FEDORA MACTAHOE UPDATER"
    _update_box_text "Installed:  $current_ver"
    _update_box_text "Available:  $latest_ver"
    _update_box_rule

    # ── up to date? ──
    if test "$has_update" -eq 0
        _update_box_text "✓ You're on the latest version." "1;32"
        set -l last (_update_last_update)
        if test -n "$last"
            _update_box_text "last update: $last" "1;37"
        end
        _update_box_text "Made by eprahemi — Fedora MacTahoe © 2026" "1;37"
        _update_box_bottom
        printf "\n  \e[2;37mupdate menu — icons, wallpaper, pfp, theme, gdm and more tools\e[0m\n"
        return 0
    end

    # ── what's new ──
    _update_box_text "What's new in $latest_ver:" "1;33"
    if test (count $ch_lines) -eq 0
        _update_box_text "  no notes for this one — just run it" "1;37"
    else
        for ln in $ch_lines
            _update_box_text "$ln" "1;37"
        end
    end
    _update_box_text "Made by eprahemi — Fedora MacTahoe © 2026" "1;37"
    _update_box_bottom
    printf "\n"

    # ── battery guard ──
    if test (_update_low_battery) -eq 1
        printf "\n"
        _update_box_top
        _update_box_text "Battery is below 20% and unplugged —" "1;31"
        _update_box_text "an update can die mid-way." "1;31"
        _update_box_text ""
        _update_box_text "Continue anyway?   y = yes   n = no (default)" "1;37"
        _update_box_bottom
        read -l bc -P "  Your choice [y/N]: "
        if test $status -ne 0
            printf "\n  \e[1;31m✘ Cancelled.\e[0m\n"
            return 1
        end
        switch $bc
            case y Y yes Yes YES
            case '*'
                printf "\n  \e[1;31m✘ Cancelled.\e[0m\n"
                return 1
        end
    end

    # ── menu ──
    set -l action ""
    set -l attempts 0
    while test $attempts -lt 3 -a -z "$action"
        printf "\n"
        _update_box_text "[1] Quick update — only what changed" "1;36"
        _update_box_text "[2] Full reinstall — everything fresh   (recommended)" "1;32"
        _update_box_text "[3] Configs only — just the files, no system changes" "1;36"
        _update_box_text "[4] Just checking — exit" "1;36"
        _update_box_text ""
        _update_box_text "Made by eprahemi — Fedora MacTahoe © 2026" "1;37"
        _update_box_bottom
        read -l choice -P "  Your choice [1-4]: "
        if test $status -ne 0
            printf "\n  \e[1;31m✘ Cancelled.\e[0m\n"
            return 1
        end
        switch $choice
            case 1
                set action quick
            case 2
                printf "\n"
                _update_box_top
                _update_box_text "Full reinstall — re-runs everything from scratch" "1;33"
                _update_box_text "and may ask for your password." "1;33"
                _update_box_text ""
                _update_box_text "Continue?   y = yes   n = no (default)" "1;37"
                _update_box_bottom
                read -l fc -P "  Your choice [y/N]: "
                if test $status -ne 0
                    printf "\n  \e[1;31m✘ Cancelled.\e[0m\n"
                    return 1
                end
                switch $fc
                    case y Y yes Yes YES
                        set action full
                    case '*'
                        printf "\n  \e[1;31m✘ Cancelled.\e[0m\n"
                        return 1
                end
            case 3
                set action configs
            case 4 q 0
                printf "\n  \e[1;32m✓ Nothing changed.\e[0m\n"
                return 0
            case '*'
                printf "  \e[1;31m✘ Invalid — choose 1, 2, 3 or 4.\e[0m\n"
        end
        set attempts (math $attempts + 1)
    end
    if test -z "$action"
        printf "\n  \e[1;31m✘ Cancelled.\e[0m\n"
        return 1
    end

    # ── go ──
    switch $action
        case quick
            _update_run incremental quick $current_ver $latest_ver
            return $status
        case full
            _update_run full full $current_ver $latest_ver
            return $status
        case configs
            _update_configs_mode
            return $status
    end
end

# ── small helpers used by the full path ──
function _update_state_version --description 'installed version from the state file'
    set -l v "0.0"
    if test -f "$HOME/.cache/fedora-mactahoe/install-state.json"
        set v (cat "$HOME/.cache/fedora-mactahoe/install-state.json" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('version', '0.0'))
except Exception:
    print('0.0')
" 2>/dev/null)
    end
    echo "$v"
end

function _update_latest_version --description 'latest version from the cached manifest'
    set -l v ""
    if test -f "$HOME/.cache/fedora-mactahoe/latest-manifest.json"
        set v (cat "$HOME/.cache/fedora-mactahoe/latest-manifest.json" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('latest_version', ''))
except Exception:
    print('')
" 2>/dev/null)
    end
    echo "$v"
end
