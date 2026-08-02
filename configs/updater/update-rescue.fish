# ── Fedora MacTahoe — system-wide rescue detector ──────────────────
# Installed as /etc/fish/functions/update.fish (root-owned, outside the
# home folder). This is the TINY fallback for the 'update' command: fish
# autoloads it ONLY when the real update.fish is missing from
# ~/.config/fish/functions/.
#   update            — exclusive: restores the latest verified update.fish
#                       from GitHub — nothing else.
#   update configs    — also works while the real updater is missing:
#                       sparse-clones just configs/fish, copies it, and
#                       hands over to the fresh real updater, which then
#                       refreshes kitty, GTK, systemd, /etc helpers, etc.
function update --description 'rescue detector: restores the real update.fish into ~/.config'
    set -l target "$HOME/.config/fish/functions/update.fish"

    # the real updater is here — load it and hand over
    if test -f "$target"
        source "$target"
        update $argv
        return $status
    end

    # ── update configs — restore the fish config directly, no download
    #    box (configs was explicitly requested). Sparse clone keeps the
    #    fetch lean — only the configs/fish blobs, not the whole repo.
    if set -q argv[1]; and string match -qr '^configs?$' "$argv[1]"
        if not command -q git
            printf "\n  \e[1;31m✘ git is not installed — can't restore the fish config.\e[0m\n"
            return 1
        end
        set -l tmp (mktemp -d /tmp/mactahoe-rescue.XXXXXX)
        set -l ok 0
        for i in (seq 5)
            rm -rf "$tmp"; mkdir -p "$tmp"
            printf "\r  \e[1;36mFetching the fish config…  (attempt %d/5)\e[0m   " $i
            if git clone --depth 1 --filter=blob:none --sparse -q "https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi" "$tmp" 2>/dev/null
                and git -C "$tmp" sparse-checkout set configs/fish 2>/dev/null
                and test -d "$tmp/configs/fish/functions"
                set ok 1
                break
            end
            sleep 1
        end
        printf "\r  %*s\r" 78 ''
        if not test "$ok" -eq 1
            rm -rf "$tmp"
            printf "\n  \e[1;31m✘ Could not fetch the fish config — check your connection and try again.\e[0m\n"
            return 1
        end
        mkdir -p "$HOME/.config/fish/functions"
        if test -f "$tmp/configs/fish/config.fish"
            cp -f "$tmp/configs/fish/config.fish" "$HOME/.config/fish/"
        end
        for f in "$tmp/configs/fish/functions/"*.fish
            cp -f "$f" "$HOME/.config/fish/functions/"
        end
        rm -rf "$tmp"
        printf "\n  \e[1;32m✓ fish config restored — reloading the full updater…\e[0m\n"
        source "$target"
        update $argv
        return $status
    end

    printf "\n"
    set -l t "UPDATE FUNCTION MISSING"
    set -l len (string length -- "$t")
    set -l l (math "floor((62 - $len) / 2)")
    set -l r (math "62 - $l - $len")
    printf "  \e[1;31m╔%s╗\e[0m\n" (string repeat -n 62 '═')
    printf "  \e[1;31m║%*s%s%*s║\e[0m\n" $l '' "$t" $r ''
    printf "  \e[1;36m╠%s╣\e[0m\n" (string repeat -n 62 '═')
    printf "  \e[1;37m║ %-62s║\e[0m\n" "You're missing the dependencies — the update"
    printf "  \e[1;37m║ %-62s║\e[0m\n" "function is not in ~/.config/fish/functions/."
    printf "  \e[1;33m║ %-62s║\e[0m\n" "This rescue copy only restores it — nothing else."
    printf "  \e[1;33m║ %-62s║\e[0m\n" ""
    printf "  \e[1;36m║ %-62s║\e[0m\n" "Download the latest update function now?"
    printf "  \e[1;36m║ %-62s║\e[0m\n" "y — download and restore (default)"
    printf "  \e[1;37m║ %-62s║\e[0m\n" "n — stop here"
    printf "  \e[1;31m╚%s╝\e[0m\n" (string repeat -n 62 '═')
    printf "\n  \e[1;37mDownload now?  [Y/n]: \e[0m"
    read -l ans
    if test $status -ne 0
        printf "\n  \e[1;31m✘ Cancelled — update stays disabled.\e[0m\n"
        return 1
    end
    switch (string lower -- "$ans")
        case '' y yes Y YES Yes
            # download below
        case '*'
            printf "\n  \e[1;33mOK — nothing downloaded. update stays disabled until\n  ~/.config/fish/functions/update.fish is back.\e[0m\n"
            return 1
    end

    set -l base "https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main"
    set -l tmp (mktemp /tmp/mactahoe-rescue.XXXXXX)
    set -l ok 0
    for i in (seq 5)
        printf "\r  \e[1;36mDownloading the update function…  (attempt %d/5)\e[0m   " $i
        if curl -fsSL --max-time 30 "$base/updates.json" -o "$tmp.manifest" 2>/dev/null
            and set -l pin (python3 -c '
import sys, json
try:
    d = json.load(open(sys.argv[1]))
    print(d.get("update_sha256", ""))
except Exception:
    pass' "$tmp.manifest" 2>/dev/null)
            and test -n "$pin"
            and curl -fsSL --max-time 60 "$base/configs/fish/functions/update.fish" -o "$tmp" 2>/dev/null
            and test (sha256sum "$tmp" 2>/dev/null | string split ' ' -f1) = "$pin"
            set ok 1
            break
        end
        sleep 1
    end
    printf "\r  %*s\r" 78 ''
    if not test "$ok" -eq 1
        rm -f "$tmp" "$tmp.manifest"
        printf "\n  \e[1;31m✘ Could not download the update function — check your connection and try again.\e[0m\n"
        return 1
    end
    mkdir -p "$HOME/.config/fish/functions"
    chmod 644 "$tmp"
    mv -f "$tmp" "$target"
    rm -f "$tmp.manifest"
    printf "\n  \e[1;32m✓ update function restored — reloading the fresh copy…\e[0m\n"
    source "$target"
    update $argv
    return $status
end
