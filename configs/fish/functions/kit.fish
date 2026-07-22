# ══════════════════════════════════════════════════════════════
# kit — Kitty config theme toggle
# Toggle between MacTahoe theme (kitty.conf) and stock defaults (#kitty.conf)
# Fedora MacTahoe Eprahemi Edition © 2026
# ══════════════════════════════════════════════════════════════
function kit --description 'Toggle kitty.conf theme: kit original/theme'
    set -l conf "$HOME/.config/kitty/kitty.conf"
    set -l hash "$HOME/.config/kitty/#kitty.conf"

    set -l sep "══════════════════════════════════════════════════════════"

    if not set -q argv[1]
        # ── No args: show status + all subcommands ──
        if test -f "$conf"
            printf "\n"
            printf "  \033[1;32m╔%s╗\033[0m\n" "$sep"
            printf "  \033[1;32m║\033[0m              \033[1;37m🐱  KITTY  CONFIG  STATUS\033[0m\n"
            printf "  \033[1;32m╠%s╣\033[0m\n" "$sep"
            printf "  \033[1;32m║\033[0m\n"
            printf "  \033[1;32m║\033[0m  \033[1;32m● ACTIVE\033[0m   kitty.conf\n"
            printf "  \033[1;32m║\033[0m  \033[2;37m  MacTahoe theme loaded\033[0m\n"
            printf "  \033[1;32m║\033[0m\n"
            printf "  \033[1;32m║\033[0m  \033[2;37m○ HIDDEN\033[0m   #kitty.conf\n"
            printf "  \033[1;32m║\033[0m  \033[2;37m  Stock defaults (disabled)\033[0m\n"
            printf "  \033[1;32m║\033[0m\n"
            printf "  \033[1;32m╠%s╣\033[0m\n" "$sep"
            printf "  \033[1;32m║\033[0m  \033[1;37mSUBCOMMANDS:\033[0m\n"
            printf "  \033[1;32m║\033[0m\n"
            printf "  \033[1;32m║\033[0m    \033[1;36mkit original\033[0m  \033[2;37m(\033[1;36mkit o\033[2;37m, \033[1;36mkit off\033[2;37m)\033[0m   \033[2;37m→\033[0m  \033[1;33mDisable MacTahoe theme\033[0m\n"
            printf "  \033[1;32m║\033[0m    \033[1;36mkit theme\033[0m     \033[2;37m(\033[1;36mkit t\033[2;37m, \033[1;36mkit on\033[2;37m)\033[0m    \033[2;37m→\033[0m  \033[1;32mRestore MacTahoe theme\033[0m\n"
            printf "  \033[1;32m║\033[0m    \033[1;36mkit\033[0m                            \033[2;37m→\033[0m  \033[1;37mShow this status\033[0m\n"
            printf "  \033[1;32m║\033[0m    \033[1;36mkit --help\033[0m   \033[2;37m(\033[1;36m-h\033[2;37m)\033[0m        \033[2;37m→\033[0m  \033[1;37mShow help\033[0m\n"
            printf "  \033[1;32m║\033[0m\n"
            printf "  \033[1;32m╚%s╝\033[0m\n" "$sep"
            printf "  \033[2;37m  Restart Kitty after toggle to apply changes\033[0m\n\n"

        else if test -f "$hash"
            printf "\n"
            printf "  \033[1;33m╔%s╗\033[0m\n" "$sep"
            printf "  \033[1;33m║\033[0m              \033[1;37m🐱  KITTY  CONFIG  STATUS\033[0m\n"
            printf "  \033[1;33m╠%s╣\033[0m\n" "$sep"
            printf "  \033[1;33m║\033[0m\n"
            printf "  \033[1;33m║\033[0m  \033[2;37m○ HIDDEN\033[0m   kitty.conf\n"
            printf "  \033[1;33m║\033[0m  \033[2;37m  MacTahoe theme (disabled)\033[0m\n"
            printf "  \033[1;33m║\033[0m\n"
            printf "  \033[1;33m║\033[0m  \033[1;33m● ACTIVE\033[0m   #kitty.conf\n"
            printf "  \033[1;33m║\033[0m  \033[1;33m●\033[0m  \033[2;37mStock defaults loaded\033[0m\n"
            printf "  \033[1;33m║\033[0m\n"
            printf "  \033[1;33m╠%s╣\033[0m\n" "$sep"
            printf "  \033[1;33m║\033[0m  \033[1;37mSUBCOMMANDS:\033[0m\n"
            printf "  \033[1;33m║\033[0m\n"
            printf "  \033[1;33m║\033[0m    \033[1;36mkit original\033[0m  \033[2;37m(\033[1;36mkit o\033[2;37m, \033[1;36mkit off\033[2;37m)\033[0m   \033[2;37m→\033[0m  \033[1;33mAlready stock defaults\033[0m\n"
            printf "  \033[1;33m║\033[0m    \033[1;36mkit theme\033[0m     \033[2;37m(\033[1;36mkit t\033[2;37m, \033[1;36mkit on\033[2;37m)\033[0m    \033[2;37m→\033[0m  \033[1;32mRestore MacTahoe theme\033[0m\n"
            printf "  \033[1;33m║\033[0m    \033[1;36mkit\033[0m                            \033[2;37m→\033[0m  \033[1;37mShow this status\033[0m\n"
            printf "  \033[1;33m║\033[0m    \033[1;36mkit --help\033[0m   \033[2;37m(\033[1;36m-h\033[2;37m)\033[0m        \033[2;37m→\033[0m  \033[1;37mShow help\033[0m\n"
            printf "  \033[1;33m║\033[0m\n"
            printf "  \033[1;33m╚%s╝\033[0m\n" "$sep"
            printf "  \033[2;37m  Restart Kitty after toggle to apply changes\033[0m\n\n"

        else
            printf "\n"
            printf "  \033[1;31m╔%s╗\033[0m\n" "$sep"
            printf "  \033[1;31m║\033[0m              \033[1;37m🐱  KITTY  CONFIG  STATUS\033[0m\n"
            printf "  \033[1;31m╠%s╣\033[0m\n" "$sep"
            printf "  \033[1;31m║\033[0m\n"
            printf "  \033[1;31m║\033[0m  \033[1;31m✗\033[0m  kitty.conf    \033[1;31mNOT FOUND\033[0m\n"
            printf "  \033[1;31m║\033[0m  \033[1;31m✗\033[0m  #kitty.conf   \033[1;31mNOT FOUND\033[0m\n"
            printf "  \033[1;31m║\033[0m\n"
            printf "  \033[1;31m╚%s╝\033[0m\n" "$sep"
            printf "\n"
        end
        return 0
    end

    switch $argv[1]
        case original o off
            if test -f "$hash"
                printf "\n"
                printf "  \033[1;33m╔%s╗\033[0m\n" "$sep"
                printf "  \033[1;33m║\033[0m  \033[1;33m⚠\033[0m  #kitty.conf already exists — theme is stock\n"
                printf "  \033[1;33m╚%s╝\033[0m\n" "$sep"
                printf "\n"
                return 0
            end
            if not test -f "$conf"
                printf "\n"
                printf "  \033[1;31m╔%s╗\033[0m\n" "$sep"
                printf "  \033[1;31m║\033[0m  \033[1;31m✗\033[0m  kitty.conf not found — nothing to disable\n"
                printf "  \033[1;31m╚%s╝\033[0m\n" "$sep"
                printf "\n"
                return 1
            end
            # ── Save backup to /tmp before disabling ──
            set -l tmp_dir "/tmp/kit-kitty-backup"
            mkdir -p "$tmp_dir" 2>/dev/null
            cp "$conf" "$tmp_dir/kitty.conf" 2>/dev/null
            mv "$conf" "$hash"
            if test $status -eq 0
                printf "\n"
                printf "  \033[1;32m╔%s╗\033[0m\n" "$sep"
                printf "  \033[1;32m║\033[0m  \033[1;32m✓\033[0m  kitty.conf  →  #kitty.conf\n"
                printf "  \033[1;32m║\033[0m\n"
                printf "  \033[1;32m║\033[0m  \033[2;37mMacTahoe theme disabled — stock defaults active\033[0m\n"
                printf "  \033[1;32m║\033[0m  \033[2;37mRestart Kitty to apply\033[0m\n"
                printf "  \033[1;32m╚%s╝\033[0m\n" "$sep"
                printf "\n"
            else
                printf "\n"
                printf "  \033[1;31m╔%s╗\033[0m\n" "$sep"
                printf "  \033[1;31m║\033[0m  \033[1;31m✗\033[0m  Failed to rename — check permissions\n"
                printf "  \033[1;31m╚%s╝\033[0m\n" "$sep"
                printf "\n"
                return 1
            end

        case theme t th on
            if test -f "$conf"
                printf "\n"
                printf "  \033[1;32m╔%s╗\033[0m\n" "$sep"
                printf "  \033[1;32m║\033[0m  \033[1;32m✓\033[0m  kitty.conf already exists — MacTahoe active\n"
                printf "  \033[1;32m╚%s╝\033[0m\n" "$sep"
                printf "\n"
                return 0
            end
            # ── Tier 1: restore from #kitty.conf ──
            if test -f "$hash"
                mkdir -p "$HOME/.config/kitty" 2>/dev/null
                mv "$hash" "$conf"
                if test $status -eq 0
                    printf "\n"
                    printf "  \033[1;32m╔%s╗\033[0m\n" "$sep"
                    printf "  \033[1;32m║\033[0m  \033[1;32m✓\033[0m  #kitty.conf  →  kitty.conf\n"
                    printf "  \033[1;32m║\033[0m\n"
                    printf "  \033[1;32m║\033[0m  \033[2;37mMacTahoe theme restored\033[0m\n"
                    printf "  \033[1;32m║\033[0m  \033[2;37mRestart Kitty to apply\033[0m\n"
                    printf "  \033[1;32m╚%s╝\033[0m\n" "$sep"
                    printf "\n"
                else
                    printf "\n"
                    printf "  \033[1;31m╔%s╗\033[0m\n" "$sep"
                    printf "  \033[1;31m║\033[0m  \033[1;31m✗\033[0m  Failed to rename — check permissions\n"
                    printf "  \033[1;31m╚%s╝\033[0m\n" "$sep"
                    printf "\n"
                    return 1
                end
                return 0
            end
            # ── Tier 2: restore from /tmp backup ──
            set -l tmp_backup "/tmp/kit-kitty-backup/kitty.conf"
            if test -f "$tmp_backup"
                mkdir -p "$HOME/.config/kitty" 2>/dev/null
                cp "$tmp_backup" "$conf" 2>/dev/null
                if test $status -eq 0
                    printf "\n"
                    printf "  \033[1;32m╔%s╗\033[0m\n" "$sep"
                    printf "  \033[1;32m║\033[0m  \033[1;32m✓\033[0m  Restored from /tmp backup\n"
                    printf "  \033[1;32m║\033[0m\n"
                    printf "  \033[1;32m║\033[0m  \033[2;37mMacTahoe theme restored from tmp\033[0m\n"
                    printf "  \033[1;32m║\033[0m  \033[2;37mRestart Kitty to apply\033[0m\n"
                    printf "  \033[1;32m║\033[0m\n"
                    printf "  \033[1;33m║\033[0m  \033[2;37mTip: This is a local backup — may be outdated.\033[0m\n"
                    printf "  \033[1;33m║\033[0m  \033[2;37mDownload the latest from GitHub? [y/N]: \033[0m"
                    printf "  \033[1;32m╚%s╝\033[0m\n" "$sep"
                    printf "\n"
                    read -P "  Download latest from GitHub? [y/N]: " -l dl_reply
                    if test "$dl_reply" = "y" -o "$dl_reply" = "Y" -o "$dl_reply" = "yes"
                        set -l dl_url "https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/configs/kitty/kitty.conf"
                        if curl -sfL "$dl_url" -o "$conf" 2>/dev/null
                            printf "\n  \033[1;32m  ✓  Downloaded latest from GitHub\033[0m\n\n"
                        else
                            printf "\n  \033[1;31m  ✗  Download failed — keeping tmp backup\033[0m\n\n"
                        end
                    end
                else
                    printf "\n"
                    printf "  \033[1;31m╔%s╗\033[0m\n" "$sep"
                    printf "  \033[1;31m║\033[0m  \033[1;31m✗\033[0m  Failed to copy from /tmp backup\n"
                    printf "  \033[1;31m╚%s╝\033[0m\n" "$sep"
                    printf "\n"
                    return 1
                end
                return 0
            end
            # ── Tier 3: offer to download from GitHub ──
            printf "\n"
            printf "  \033[1;33m╔%s╗\033[0m\n" "$sep"
            printf "  \033[1;33m║\033[0m  \033[1;33m⚠\033[0m  No kitty.conf found\n"
            printf "  \033[1;33m║\033[0m  \033[2;37m#kitty.conf not found, no /tmp backup available\033[0m\n"
            printf "  \033[1;33m║\033[0m\n"
            printf "  \033[1;33m║\033[0m  \033[2;37mDownload the default Fedora MacTahoe kitty.conf?\033[0m\n"
            printf "  \033[1;33m╚%s╝\033[0m\n" "$sep"
            printf "\n"
            if not __confirm_yn "  Download default theme? [Y/n]: " y
                printf "\n  \033[1;31m  ✗ Cancelled.\033[0m\n\n"
                return 0
            end
            # ── Download from GitHub ──
            set -l dl_url "https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/configs/kitty/kitty.conf"
            mkdir -p "$HOME/.config/kitty" 2>/dev/null
            if curl -sfL "$dl_url" -o "$conf" 2>/dev/null
                printf "\n"
                printf "  \033[1;32m╔%s╗\033[0m\n" "$sep"
                printf "  \033[1;32m║\033[0m  \033[1;32m✓\033[0m  Downloaded default Fedora MacTahoe kitty.conf\n"
                printf "  \033[1;32m║\033[0m\n"
                printf "  \033[1;32m║\033[0m  \033[2;37mRestart Kitty to apply\033[0m\n"
                printf "  \033[1;32m╚%s╝\033[0m\n" "$sep"
                printf "\n"
            else
                printf "\n"
                printf "  \033[1;31m╔%s╗\033[0m\n" "$sep"
                printf "  \033[1;31m║\033[0m  \033[1;31m✗\033[0m  Failed to download — check your internet\n"
                printf "  \033[1;31m╚%s╝\033[0m\n" "$sep"
                printf "\n"
                return 1
            end

        case --help -h
            printf "\n"
            printf "  \033[1;36m╔%s╗\033[0m\n" "$sep"
            printf "  \033[1;36m║\033[0m              \033[1;37m🐱  KITTY  THEME  TOGGLE\033[0m\n"
            printf "  \033[1;36m╠%s╣\033[0m\n" "$sep"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mToggle between MacTahoe theme and stock defaults\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mby renaming kitty.conf with a # prefix.\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[1;37mHOW IT WORKS:\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mKitty loads kitty.conf on startup.\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mRenaming it to #kitty.conf hides it.\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mKitty uses built-in stock defaults instead.\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[1;37mCOMMANDS:\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m    \033[1;36mkit\033[0m                            \033[2;37m→\033[0m  \033[1;37mShow current status\033[0m\n"
            printf "  \033[1;36m║\033[0m    \033[1;36mkit original\033[0m  \033[2;37m(\033[1;36mkit o\033[2;37m, \033[1;36mkit off\033[2;37m)\033[0m   \033[2;37m→\033[0m  \033[1;33mDisable theme → stock defaults\033[0m\n"
            printf "  \033[1;36m║\033[0m    \033[1;36mkit theme\033[0m     \033[2;37m(\033[1;36mkit t\033[2;37m, \033[1;36mkit on\033[2;37m)\033[0m    \033[2;37m→\033[0m  \033[1;32mRestore theme → MacTahoe\033[0m\n"
            printf "  \033[1;36m║\033[0m    \033[1;36mkit --help\033[0m   \033[2;37m(\033[1;36m-h\033[2;37m)\033[0m        \033[2;37m→\033[0m  \033[1;37mShow this help\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mAliases: kit o/off = kit original  |  kit t/on = kit theme\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[1;33mNOTE:\033[0m \033[2;37mRestart Kitty after toggle to apply changes\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mVersion: July 2026\033[0m\n"
            printf "  \033[1;36m╚%s╝\033[0m\n" "$sep"
            printf "\n"

        case '-*'
            printf "\n"
            printf "  \033[1;31m╔%s╗\033[0m\n" "$sep"
            printf "  \033[1;31m║\033[0m  \033[1;31m✗\033[0m  Unknown flag: $argv[1]\n"
            printf "  \033[1;31m║\033[0m  \033[2;37mTry\033[0m \033[1;36mkit --help\033[0m\n"
            printf "  \033[1;31m╚%s╝\033[0m\n" "$sep"
            printf "\n"
            return 1

        case '*'
            printf "\n"
            printf "  \033[1;31m╔%s╗\033[0m\n" "$sep"
            printf "  \033[1;31m║\033[0m  \033[1;31m✗\033[0m  Unknown command: $argv[1]\n"
            printf "  \033[1;31m║\033[0m  \033[2;37mTry\033[0m \033[1;36mkit --help\033[0m\n"
            printf "  \033[1;31m╚%s╝\033[0m\n" "$sep"
            printf "\n"
            return 1
    end
end
