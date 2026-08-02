# ══════════════════════════════════════════════════════════════
# update 🚀 — Fedora MacTahoe updater
# Kitty-only. Shows what's new, then offers a
# menu: quick / full reinstall / configs-only / just checking.
#   update           → open the menu
#   update check     → status at a glance, no prompts
#   update configs   → refresh kitty, fish, updater, fastfetch files only
#   update full      → full reinstall from scratch
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

# ── fetch updates.json into the cache; rc 0 = got it ──
# raw.githubusercontent is CDN-cached and can lag a fresh push for minutes
# (observed 2026-08-01: old copy served after the push landed). When the
# pinned fingerprint is missing, fall back to the GitHub API — always fresh.
function _update_fetch_manifest --description 'fetch the version manifest from GitHub'
    set -l cache_dir "$HOME/.cache/fedora-mactahoe"
    mkdir -p "$cache_dir"
    set -l url "https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/updates.json"
    curl -sf --max-time 15 "$url" -o "$cache_dir/latest-manifest.json" 2>/dev/null
    if test -s "$cache_dir/latest-manifest.json"; and not string match -q '*bootstrap_sha256*' (cat "$cache_dir/latest-manifest.json")
        # stale CDN copy — pull the manifest from the GitHub API instead
        curl -sf --max-time 20 "https://api.github.com/repos/eprahemi/Fedora-MacTahoe-Eprahemi/contents/updates.json" -o "$cache_dir/api-manifest.json" 2>/dev/null
        if test -s "$cache_dir/api-manifest.json"
            python3 -c 'import json,sys,base64
try:
    d = json.load(open(sys.argv[1]))
    open(sys.argv[2], "w").write(base64.b64decode(d["content"]).decode("utf-8"))
except Exception:
    pass' "$cache_dir/api-manifest.json" "$cache_dir/latest-manifest.json"
        end
        rm -f "$cache_dir/api-manifest.json"
    end
    test -s "$cache_dir/latest-manifest.json"
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
    python3 -c 'import json,sys
try:
    print(json.load(open(sys.argv[1])).get(sys.argv[2], ""))
except Exception:
    pass' "$man" "$key"
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
    _update_box_title "INSTALLER FINGERPRINT CHANGED" "1;33"
    _update_box_rule
    _update_box_text "The installer's fingerprint is new:" "1;37"
    _update_box_text "  before  "(string sub -l 16 -- $old)"…" "2;37"
    _update_box_text "  now     "(string sub -l 16 -- $hash)"…" "1;37"
    _update_box_text ""
    _update_box_text "Normal when a new version is released." "1;37"
    _update_box_text "Could also mean a tampered download." "1;33"
    _update_box_text ""
    _update_box_text "Trust this new fingerprint?" "1;37"
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

# ── history log ──
function _update_log_add --description 'append one line to the update history'
    set -l mode $argv[1]
    set -l frm $argv[2]
    set -l to $argv[3]
    set -l res $argv[4]
    set -l logf "$HOME/.cache/fedora-mactahoe/update-history.log"
    mkdir -p "$HOME/.cache/fedora-mactahoe"
    printf '%s | %s | %s → %s | %s\n' (date "+%Y-%m-%d %H:%M") $mode $frm $to $res >> "$logf"
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

# ── animated loading line: spinner + rotating status + filling progress bar ──
# Usage: _update_loading [seconds]  (default 5; update full uses 8)
# Ctrl+C mid-animation: clears the line + cancels cleanly (no leftover text,
# no blinking cursor stuck inside the prompt). Verified --on-signal behavior.
function _update_loading --description 'loading ritual; optional seconds (default 5)'
    set -l seconds 5
    if set -q argv[1]; and string match -qr '^[0-9]+$' -- $argv[1]
        set seconds $argv[1]
    end
    set -g __update_abort 0
    function __update_clear --on-signal INT
        set -g __update_abort 1
        printf '\e[?25h\r  %*s\r' 80 ''
    end
    printf '\e[?25l'
    set -l frames ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
    set -l msgs "Contacting GitHub..." "Fetching the manifest..." "Comparing versions..." "Scanning your setup..." "Preparing the installer..." "Almost there..."
    set -l ticks (math "$seconds * 5")
    set -l step (math "$ticks / "(count $msgs))
    if test $step -lt 1
        set step 1
    end
    set -l i 1
    set -l j 1
    for t in (seq 1 $ticks)
        if test $__update_abort -eq 1
            break
        end
        set -l pct (math -s0 "$t * 100 / $ticks")
        set -l filled (math -s0 "$pct * 20 / 100")
        set -l fill_part (string repeat -n $filled '█')
        set -l empty_part (string repeat -n (math -s0 "20 - $filled") '░')
        printf '\r  \e[1;36m%s\e[0m  \e[1;37m%s\e[0m  \e[2;37m[\e[0m\e[1;36m%s\e[0m\e[2;37m%s\e[0m\e[2;37m]\e[0m \e[1;33m%3d%%\e[0m' $frames[$i] $msgs[$j] "$fill_part" "$empty_part" $pct
        sleep 0.2
        set i (math "$i % 10 + 1")
        if test (math "$t % $step") -eq 0
            if test $j -lt (count $msgs)
                set j (math "$j + 1")
            end
        end
    end
    functions -e __update_clear 2>/dev/null
    printf '\e[?25h\r  %*s\r' 80 ''
    if test $__update_abort -eq 1
        set -e __update_abort
        printf "\n  \e[1;31m✘ Cancelled.\e[0m\n"
        return 1
    end
    set -e __update_abort
    return 0
end

# ── update check: status at a glance, no prompts ──
function _update_check --description 'show versions + what is waiting'
    if not _update_fetch_manifest
        printf "\n  \e[1;31m✘ Could not reach GitHub — check your connection.\e[0m\n"
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
    _update_header "UPDATE — HELP"
    _update_box_text "update                  open the updater menu"
    _update_box_text "update check            status at a glance, no prompts"
    _update_box_text "update configs          refresh kitty/fish/updater/fastfetch only"
    _update_box_text "update full             full reinstall from scratch"
    _update_box_text "update log              your update history"
    _update_box_text "update menu             pick any target from a list"
    _update_box_text ""
    _update_box_text "Per-target toolbox:" "1;36"
    _update_box_text "icons / theme / fonts / sounds / gtk / extensions" "1;37"
    _update_box_text "wallpaper / pfp / gdm / videos / services / defaults" "1;37"
    _update_box_text "dconf / notifier / clean" "1;37"
    _update_box_text ""
    _update_box_text "update wallpaper add     install the other pack alongside" "1;36"
    _update_box_text "update pfp add           same for profile pictures" "1;36"
    _update_box_text ""
    _update_box_text "update help             this box"
    _update_box_text "Made by eprahemi — Fedora MacTahoe © 2026" "1;37"
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
        printf "\n  \e[1;31m✘ Could not reach GitHub — check your connection.\e[0m\n"
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
    curl -fsSL --max-time 120 "$base/bootstrap.sh" -o "$tmpfile" 2>/dev/null
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
        env UPDATE_MODE=full bash "$tmpfile"
    else
        env UPDATE_MODE=incremental bash "$tmpfile"
    end
    set -l code $status
    rm -f "$tmpfile"
    if test $code -eq 0
        _update_log_add $label $frm $to ok
        echo "$to" > "$HOME/.cache/fedora-mactahoe/last-notified-version"
        printf "\n  \e[1;32m✅ Update complete — you're on version $to.\e[0m\n"
    else if test $code -eq 42; or test $code -eq 130
        # 42 = installer closed itself (60s no-answer auto-close),
        # 130 = user force-closed with Ctrl+C — neither is a failure.
        _update_log_add $label $frm $to close
        printf "\n  \e[1;33m⏹ Installer closed before finishing (exit $code) — nothing was marked done.\e[0m\n"
        printf "  \e[1;33mRun 'update' again when you're ready — it continues where it left off.\e[0m\n"
    else
        _update_log_add $label $frm $to fail
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
    set -g __update_clean_tmp "$tmp"
    function __update_fetch_cleanup --on-signal INT
        printf '\e[?25h\r  %*s\r' 78 '' >&2
        if set -q __update_clean_tmp
            string match -q "/tmp/*" "$__update_clean_tmp"
            and rm -rf "$__update_clean_tmp"
        end
        set -e __update_clean_tmp
    end
    set -l frames ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
    printf '\e[?25l' >&2
    # fish's wait() always reports 0 for background jobs, so record git's
    # real exit code in a status file and read it back after the spinner.
    sh -c 'git clone --depth 1 -q https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git "$1" 2>/dev/null; echo $? > "$1/.clone-status"' sh "$tmp" &
    set -l pid $last_pid
    set -l i 1
    while kill -0 $pid 2>/dev/null
        printf '\r  \e[1;36m%s\e[0m  \e[1;37mFetching the latest files from GitHub...\e[0m' $frames[$i] >&2
        sleep 0.1
        set i (math "$i % 10 + 1")
    end
    wait $pid 2>/dev/null
    set -l code 130
    if test -f "$tmp/.clone-status"
        set code (cat "$tmp/.clone-status")
    end
    printf '\e[?25h\r  %*s\r' 78 '' >&2
    functions --erase __update_fetch_cleanup
    set -e __update_clean_tmp
    if test $code -ne 0
        rm -rf "$tmp"
        if test $code -eq 130
            printf "\n  \e[1;33m✘ Cancelled — nothing was changed.\e[0m\n" >&2
        else
            printf "\n  \e[1;31m✘ Could not fetch the repo — check your connection.\e[0m\n" >&2
        end
        return 1
    end
    echo "$tmp"
    return 0
end

# ── configs-only: just the files, no system changes ──
function _update_configs_mode --description 'refresh kitty, fish, updater, starship, gtk, fastfetch files'
    set -l tmp (_update_fetch_bundle)
    or return 1
    set -l cfg "$tmp/configs"
    # Every destination is created even when missing — files always overwrite
    mkdir -p "$HOME/.config/kitty" "$HOME/.config/fish/functions" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.config/fastfetch" "$HOME/.config/systemd/user" "$HOME/.local/bin"
    # Auto-backup the live fish config before overwriting (keeps last 5)
    set -l bk "$HOME/.cache/fedora-mactahoe/backups"
    if test -d "$HOME/.config/fish"
        mkdir -p "$bk"
        chmod 700 "$bk" 2>/dev/null
        set -l snap "$bk/fish-"(date +%Y%m%d-%H%M%S)".tar.gz"
        tar czf "$snap" -C "$HOME/.config" fish 2>/dev/null
        chmod 600 "$snap" 2>/dev/null
        for old in (ls -1t "$bk"/fish-*.tar.gz 2>/dev/null | tail -n +6)
            rm -f "$old"
        end
    end
    # kitty
    if test -f "$cfg/kitty/kitty.conf"
        cp -f "$cfg/kitty/kitty.conf" "$HOME/.config/kitty/"
    end
    if test -f "$cfg/kitty/auto-theme.conf"
        cp -f "$cfg/kitty/auto-theme.conf" "$HOME/.config/kitty/"
    end
    # fish — config.fish + every function (update.fish included, so the
    # running copy is replaced with the freshly fetched one)
    if test -f "$cfg/fish/config.fish"
        cp -f "$cfg/fish/config.fish" "$HOME/.config/fish/"
    end
    for f in "$cfg/fish/functions/"*.fish
        cp -f "$f" "$HOME/.config/fish/functions/"
    end
    # system-wide rescue copy — kept current too, but only when sudo needs
    # no prompt, so configs stays silent and never blocks on a password
    # (a full install always refreshes it regardless). The confirmation
    # prints only when the copy really happened.
    if command -q sudo
        and sudo -n true 2>/dev/null
        set -l sys_fish_dir /etc/fish/functions
        sudo mkdir -p "$sys_fish_dir" 2>/dev/null
        if sudo cp -f "$HOME/.config/fish/functions/update.fish" "$sys_fish_dir/update.fish"
            sudo chmod 644 "$sys_fish_dir/update.fish" 2>/dev/null
            printf '\n  \e[1;32m✓ Rescue copy (system-wide) updated.\e[0m\n'
        end
    end
    # starship
    if test -f "$cfg/starship.toml"
        cp -f "$cfg/starship.toml" "$HOME/.config/"
    end
    # gtk
    if test -f "$cfg/gtk-3.0/settings.ini"
        cp -f "$cfg/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/"
    end
    if test -f "$cfg/gtk-4.0/settings.ini"
        cp -f "$cfg/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/"
    end
    # fastfetch
    if test -f "$cfg/fastfetch/config.jsonc"
        sed "s|PLACEHOLDER_USER_HOME|$HOME|g" "$cfg/fastfetch/config.jsonc" > "$HOME/.config/fastfetch/config.jsonc"
        for img in "$cfg/fastfetch/"*.png "$cfg/fastfetch/"*.gif
            cp -f "$img" "$HOME/.config/fastfetch/"
        end
    end
    # systemd user units — ktheme watcher + the update notifier
    for u in "$cfg/systemd/"*.service "$cfg/updater/"*.service "$cfg/updater/"*.timer
        cp -f "$u" "$HOME/.config/systemd/user/"
    end
    # updater script
    if test -f "$cfg/updater/fedora-mactahoe-updater.sh"
        cp -f "$cfg/updater/fedora-mactahoe-updater.sh" "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/fedora-mactahoe-updater.sh"
    end
    systemctl --user daemon-reload 2>/dev/null
    systemctl --user enable --now ktheme-watcher.service 2>/dev/null
    systemctl --user enable fedora-mactahoe-updater.timer 2>/dev/null
    systemctl --user start fedora-mactahoe-updater.timer 2>/dev/null
    # live palette re-apply — the copied auto-theme.conf is the seed fallback,
    # the real colors come from the current wallpaper
    if functions -q ktheme
        ktheme apply --silent >/dev/null 2>&1
    end
    for sock in /tmp/kitty-*
        if test -S "$sock"
            kitty @ --to "unix:$sock" load-config 2>/dev/null
        end
    end
    rm -rf "$tmp"
    _update_log_add configs "—" "—" ok
    printf "\n  \e[1;32m✓ Configs refreshed — kitty, fish, updater and fastfetch are current.\e[0m\n"
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
    set -l cmd env UPDATE_STEPS=$steps
    for kv in $argv
        set -a cmd $kv
    end
    set -a cmd bash "$tmp/install.sh"
    $cmd
    set -l code $status
    if test $code -eq 0
        _update_log_add $steps "—" "—" ok
        printf "\n  \e[1;32m✓ %s — done.\e[0m\n" $steps
    else if test $code -eq 130
        # Ctrl+C — the installer was interrupted mid-run
        _update_log_add $steps "—" "—" cancel
        printf "\n  \e[1;33m✘ Cancelled — nothing was changed.\e[0m\n" $steps
    else
        _update_log_add $steps "—" "—" fail
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

# ── shared normal / +18 picker for wallpaper + pfp; echoes normal|18|cancel ──
# box goes to stderr — stdout is ONLY the choice (command substitution).
function _update_pick_pack --description 'picker: normal / +18 / cancel'
    begin
        printf "\n"
        _update_box_top
        _update_box_title "$argv[1]" "1;36"
        _update_box_rule
        _update_box_text "[1] Normal pack" "1;36"
        _update_box_text "[2] +18 pack" "1;36"
        _update_box_text "[3] Cancel" "1;37"
        _update_box_text ""
        _update_box_text "Made by eprahemi — Fedora MacTahoe © 2026" "1;37"
        _update_box_bottom
    end >&2
    read -l pick -P "  Your choice [1-3]: "
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
        case 3 q 0
            echo cancel
        case '*'
            printf "  \e[1;31m✘ Invalid — choose 1, 2 or 3.\e[0m\n" >&2
            _update_pick_pack $argv[1]
    end
    return 0
end

# ── logout prompt after a target that needs a fresh session ──
# Strict y/n — NO default: Enter alone does nothing, so nothing logs
# out by accident. Reason text explains why THIS target needs it.
function _update_ask_logout --description 'ask whether to log out now (strict y/n, no default)'
    set -l why (switch "$argv[1]"
        case theme
            echo "The GTK theme was recompiled for your GNOME."
            echo "Every open app still holds the old theme in"
            echo "memory — themes are only re-read on start."
            echo "Logging out applies the new theme everywhere."
        case gtk
            echo "GTK settings and the Flatpak runtime theme"
            echo "were refreshed. Open apps and Flatpak apps"
            echo "keep the old look until they restart — a"
            echo "logout applies the new look everywhere."
        case extensions
            echo "All extensions were reinstalled. GNOME Shell"
            echo "only loads extensions when a session starts,"
            echo "so a logout is required for them to appear."
        case gdm
            echo "The login screen was re-themed. GDM builds"
            echo "the login UI fresh for every session — the"
            echo "new look shows the next time you log out."
        case wallpaper
            echo "The desktop wallpaper is already live."
            echo "The login-screen wallpaper only shows on"
            echo "the next login screen — log out to see it."
        case icons
            echo "New icons are live for new windows; apps"
            echo "already open keep old icons until restart."
            echo "Logging out refreshes everything at once."
        case fonts
            echo "SF Pro is installed and cached — new apps"
            echo "use it right away, open apps keep the old"
            echo "font. Log out to apply it everywhere."
        case '*'
    end)
    if test (count $why) -eq 0
        return 1
    end
    printf "\n"
    _update_box_top
    _update_box_title "LOG OUT NOW?" "1;33"
    _update_box_rule
    for l in $why
        _update_box_text "$l" "1;37"
    end
    _update_box_text ""
    _update_box_text "y  — Log out now" "1;36"
    _update_box_text "n  — Stay here" "1;36"
    _update_box_text ""
    _update_box_text "Enter does nothing — your call." "1;33"
    _update_box_bottom
    set -l tries 0
    while true
        read -l lo -P "  Log out now?  y = yes  n = no: "
        if test $status -ne 0
            printf "\n  \e[1;33mOK — staying here. Changes apply when you log out on your own.\e[0m\n"
            return 1
        end
        switch $lo
            case y Y yes Yes YES
                printf "\n  \e[1;32mSee you on the other side!\e[0m\n"
                if command -q gnome-session-quit
                    gnome-session-quit --logout --no-prompt 2>/dev/null
                    return 0
                else
                    printf "  \e[1;33mCouldn't start a session logout — use the user menu (Log Out).\e[0m\n"
                    return 1
                end
            case n N no No NO
                printf "\n  \e[1;33mStaying here — changes apply after you log out when you're ready.\e[0m\n"
                return 1
            case '*'
                set tries (math $tries + 1)
                if test $tries -ge 3
                    printf "  \e[1;33mNo answer given — staying here. Log out yourself when ready.\e[0m\n"
                    return 1
                end
                printf "  \e[1;33mType y (yes) or n (no) — Enter alone does nothing.\e[0m\n"
        end
    end
end

function _update_target_icons --description 'reinstall icon themes + custom app icons'
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "install_icons"
    set -l code $status
    if test $code -eq 0
        _update_ask_logout icons
    end
    return $code
end

function _update_target_theme --description 'recompile the GTK theme for the current GNOME'
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "install_mactahoe_theme"
    set -l code $status
    if test $code -eq 0
        _update_ask_logout theme
    end
    return $code
end

function _update_target_fonts --description 'reinstall SF Pro Display'
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "install_font"
    set -l code $status
    if test $code -eq 0
        _update_ask_logout fonts
    end
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
    if test $code -eq 0
        _update_ask_logout extensions
    end
    return $code
end

function _update_target_gdm --description 're-apply the GDM login theme'
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "setup_gdm" "INSTALL_LOGIN_WALLPAPER=true"
    set -l code $status
    if test $code -eq 0
        _update_ask_logout gdm
    end
    return $code
end

function _update_target_wallpaper --description 'reinstall wallpapers: normal or +18 — add keeps the other pack'
    # update wallpaper        → replace: the other pack (folder + XML) is removed
    # update wallpaper add    → install the chosen pack alongside the other one
    # update wallpaper --add  → same (also: -add)
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
    set -l pick (_update_pick_pack $title)
    set -l want false
    switch $pick
        case cancel
            return 1
        case 18
            set want true
    end
    set -l tmp (_update_fetch_bundle)
    or return 1
    # default = replace: the installer keeps ONE Wallvault set — this swaps
    # to the chosen one. With the add flag the installer refreshes the chosen
    # pack and leaves the other folder + XML in place (both stay in the picker).
    set -l envs "INSTALL_WALLPAPER_18=$want" "INSTALL_DESKTOP_WALLPAPER=true"
    if test "$add_mode" = true
        set -a envs "INSTALL_WALLPAPER_ADD=true"
    end
    _update_run_step "$tmp" "apply_wallpapers" $envs
    set -l code $status
    if test $code -eq 0
        _update_ask_logout wallpaper
    end
    return $code
end

function _update_target_pfp --description 'reinstall profile pictures: normal or +18 — add keeps the other pack'
    # update pfp           → replace: the other pack is wiped from the picker
    # update pfp add       → install the chosen pack alongside the other one
    # update pfp --add     → same (also: -add)
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
    set -l pick (_update_pick_pack $title)
    set -l want false
    switch $pick
        case cancel
            return 1
        case 18
            set want true
    end
    set -l tmp (_update_fetch_bundle)
    or return 1
    # install_custom_avatars keys off the same INSTALL_WALLPAPER_18 answer;
    # the add flag skips the faces-dir wipe so both packs stay in the picker
    set -l envs "INSTALL_WALLPAPER_18=$want"
    if test "$add_mode" = true
        set -a envs "INSTALL_WALLPAPER_ADD=true"
    end
    _update_run_step "$tmp" "install_custom_avatars" $envs
    return $status
end

function _update_target_gtk --description 'refresh GTK settings + Flatpak GTK runtime'
    set -l tmp (_update_fetch_bundle)
    or return 1
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
    if test -f "$tmp/configs/gtk-3.0/settings.ini"
        cp -f "$tmp/configs/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/"
    end
    if test -f "$tmp/configs/gtk-4.0/settings.ini"
        cp -f "$tmp/configs/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/"
    end
    _update_run_step "$tmp" "setup_flatpak_theme"
    set -l code $status
    if test $code -eq 0
        _update_ask_logout gtk
    end
    return $code
end

function _update_target_videos --description 're-download the optional video edits'
    set -l bv (_update_state_prompt billie_videos)
    if test -z "$bv"
        printf "\n  \e[1;33mNo saved choice for the optional videos — nothing to re-download.\e[0m\n"
        return 0
    end
    set -l tmp (_update_fetch_bundle)
    or return 1
    _update_run_step "$tmp" "download_optional_videos" "INSTALL_BILLIE_VIDEOS=$bv"
    return $status
end

function _update_target_services --description 're-apply the RAM-saving services'
    set -l fw (_update_state_prompt firewalld)
    set -l tmp (_update_fetch_bundle)
    or return 1
    if test -n "$fw"
        _update_run_step "$tmp" "optimize_system_resources" "INSTALL_DISABLE_FIREWALLD=$fw"
    else
        _update_run_step "$tmp" "optimize_system_resources"
    end
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
    printf "\n"
    _update_header "UPDATE — CLEAN"
    if test -d "$HOME/.cache/thumbnails"
        rm -rf "$HOME/.cache/thumbnails/"* 2>/dev/null
        _update_box_text "✓ thumbnail cache cleared" "1;32"
    end
    if test -d "$HOME/.cache/fontconfig"
        rm -rf "$HOME/.cache/fontconfig/"* 2>/dev/null
        _update_box_text "✓ fontconfig cache cleared" "1;32"
    end
    if test -d "$HOME/.cache/mesa_shader_cache"
        rm -rf "$HOME/.cache/mesa_shader_cache/"* 2>/dev/null
        _update_box_text "✓ Mesa shader cache cleared" "1;32"
    end
    sudo dnf clean all 2>/dev/null
    _update_box_text "✓ DNF metadata cache cleared" "1;32"
    flatpak uninstall --unused -y 2>/dev/null
    _update_box_text "✓ unused Flatpak runtimes removed" "1;32"
    sudo dnf autoremove -y 2>/dev/null
    _update_box_text "✓ orphaned RPM packages removed" "1;32"
    sudo journalctl --vacuum-time=3d 2>/dev/null
    _update_box_text "✓ old journal logs trimmed (3 days)" "1;32"
    for icon in MacTahoe MacTahoe-dark hicolor
        if test -d "$HOME/.local/share/icons/$icon"
            gtk-update-icon-cache "$HOME/.local/share/icons/$icon/" 2>/dev/null
        end
    end
    _update_box_text "✓ icon caches rebuilt" "1;32"
    _update_box_text "Made by eprahemi — Fedora MacTahoe © 2026" "1;37"
    _update_box_bottom
    printf "\n"
    _update_log_add clean "—" "—" ok
    return 0
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
    _update_box_text "[8]  sounds        [0]  exit" "1;36"
    _update_box_text ""
    _update_box_text "Made by eprahemi — Fedora MacTahoe © 2026" "1;37"
    _update_box_bottom
    read -l t -P "  Your choice [0-15]: "
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
        case 0 q
            printf "\n  \e[1;32m✓ Nothing changed.\e[0m\n"
            return 0
        case '*'
            printf "  \e[1;31m✘ Invalid — choose a number 0-15.\e[0m\n"
            return 1
    end
    return $status
end

# ══════════════════════════════════════════════════════════════
# update — the entry point
# ══════════════════════════════════════════════════════════════
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
                _update_usage
                return 0
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
            case menu
                _update_target_menu
                return $status
            case '*'
                printf "\n  \e[1;31m✘ Unknown option: %s\e[0m\n" "$argv[1]"
                _update_usage
                return 1
        end
    end

    # ── fetch + parse ──
    if not _update_fetch_manifest
        printf "\n  \e[1;31m✘ Could not reach GitHub — check your connection and try again.\e[0m\n"
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
        _update_box_text "[2] Full reinstall — everything fresh" "1;36"
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
