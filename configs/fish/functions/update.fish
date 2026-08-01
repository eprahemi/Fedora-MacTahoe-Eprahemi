# ══════════════════════════════════════════════════════════════
# update 🚀 — Fedora MacTahoe updater
# Kitty-only. Shows what's new + which steps will re-run, then
# offers a menu: quick / full reinstall / configs-only / just checking.
#   update           → open the menu
#   update check     → status at a glance, no prompts
#   update configs   → refresh kitty, fish, fastfetch files only
#   update full      → full reinstall from scratch
#   update log       → your update history
#   update help      → this box
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

# steps that will re-run
for name, mver in (man.get("steps") or {}).items():
    mver = str(mver)
    if name not in sstate:
        print("ST=" + name + " (new)")
    elif vk(mver) > vk(sstate.get(name)):
        print("ST=" + name + " (" + str(sstate.get(name)) + " → " + mver + ")")
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
    _update_box_text "update configs          refresh kitty/fish/fastfetch only"
    _update_box_text "update full             full reinstall from scratch"
    _update_box_text "update log              your update history"
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

# ── configs-only: just the files, no system changes ──
function _update_configs_mode --description 'refresh kitty, fish, starship, gtk, fastfetch files'
    if not command -q git
        printf "\n  \e[1;31m✘ git is not installed — can't fetch the files.\e[0m\n"
        return 1
    end
    printf "\n  \e[1;37mFetching the latest files from GitHub...\e[0m\n"
    set -l tmp (mktemp -d /tmp/mactahoe-configs.XXXXXX)
    git clone --depth 1 -q https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi.git "$tmp" 2>/dev/null
    if test $status -ne 0
        rm -rf "$tmp"
        printf "\n  \e[1;31m✘ Could not fetch the repo — check your connection.\e[0m\n"
        return 1
    end
    set -l cfg "$tmp/configs"
    mkdir -p "$HOME/.config/kitty" "$HOME/.config/fish/functions" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.config/fastfetch" "$HOME/.config/systemd/user"
    # Auto-backup the live fish config before overwriting (keeps last 10)
    set -l bk "$HOME/.cache/fedora-mactahoe/backups"
    if test -d "$HOME/.config/fish"
        mkdir -p "$bk"
        chmod 700 "$bk" 2>/dev/null
        set -l snap "$bk/fish-"(date +%Y%m%d-%H%M%S)".tar.gz"
        tar czf "$snap" -C "$HOME/.config" fish 2>/dev/null
        chmod 600 "$snap" 2>/dev/null
        for old in (ls -1t "$bk"/fish-*.tar.gz 2>/dev/null | tail -n +11)
            rm -f "$old"
        end
    end
    if test -f "$cfg/kitty/kitty.conf"
        cp -f "$cfg/kitty/kitty.conf" "$HOME/.config/kitty/"
    end
    if test -f "$cfg/kitty/auto-theme.conf"
        cp -f "$cfg/kitty/auto-theme.conf" "$HOME/.config/kitty/"
    end
    if test -f "$cfg/fish/config.fish"
        cp -f "$cfg/fish/config.fish" "$HOME/.config/fish/"
    end
    if test -d "$cfg/fish/functions"
        cp -f "$cfg/fish/functions/"*.fish "$HOME/.config/fish/functions/"
    end
    if test -f "$cfg/starship.toml"
        cp -f "$cfg/starship.toml" "$HOME/.config/"
    end
    if test -f "$cfg/gtk-3.0/settings.ini"
        cp -f "$cfg/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/"
    end
    if test -f "$cfg/gtk-4.0/settings.ini"
        cp -f "$cfg/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/"
    end
    if test -f "$cfg/fastfetch/config.jsonc"
        sed "s|PLACEHOLDER_USER_HOME|$HOME|g" "$cfg/fastfetch/config.jsonc" > "$HOME/.config/fastfetch/config.jsonc"
        cp -f "$cfg/fastfetch/"*.png "$HOME/.config/fastfetch/" 2>/dev/null
        cp -f "$cfg/fastfetch/"*.gif "$HOME/.config/fastfetch/" 2>/dev/null
    end
    if test -d "$cfg/systemd"
        cp -f "$cfg/systemd/"*.service "$HOME/.config/systemd/user/"
    end
    systemctl --user daemon-reload 2>/dev/null
    systemctl --user enable --now ktheme-watcher.service 2>/dev/null
    # live palette re-apply — the copied auto-theme.conf is the seed fallback,
    # the real colors come from the current wallpaper
    if functions -q ktheme
        ktheme apply --silent 2>/dev/null
    end
    for sock in /tmp/kitty-*
        if test -S "$sock"
            kitty @ --to "unix:$sock" load-config 2>/dev/null
        end
    end
    rm -rf "$tmp"
    _update_log_add configs "—" "—" ok
    printf "\n  \e[1;32m✓ Configs refreshed — kitty, fish and fastfetch are current.\e[0m\n"
    return 0
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
    set -l st_lines
    for line in (_update_parse)
        switch $line
            case 'LATEST=*'
                set latest_ver (string replace 'LATEST=' '' -- $line)
            case 'HASUPDATE=*'
                set has_update (string replace 'HASUPDATE=' '' -- $line)
            case 'CH=*'
                set -a ch_lines (string replace 'CH=' '' -- $line)
            case 'ST=*'
                set -a st_lines (string replace 'ST=' '' -- $line)
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
        printf "\n"
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

    # ── what will re-run ──
    _update_box_rule
    _update_box_text "This update will re-run:" "1;33"
    if test (count $st_lines) -eq 0
        _update_box_text "  nothing re-runs — just the version bump" "1;37"
    else
        for ln in $st_lines
            _update_box_text "  $ln" "1;37"
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
