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
            printf "  \033[1;32m║\033[0m    \033[1;36mkit original\033[0m  \033[2;37m(\033[1;36mkit o\033[2;37m)\033[0m      \033[2;37m→\033[0m  \033[1;33mDisable MacTahoe theme\033[0m\n"
            printf "  \033[1;32m║\033[0m    \033[1;36mkit theme\033[0m     \033[2;37m(\033[1;36mkit t\033[2;37m)\033[0m      \033[2;37m→\033[0m  \033[1;32mRestore MacTahoe theme\033[0m\n"
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
            printf "  \033[1;33m║\033[0m    \033[1;36mkit original\033[0m  \033[2;37m(\033[1;36mkit o\033[2;37m)\033[0m      \033[2;37m→\033[0m  \033[1;33mAlready stock defaults\033[0m\n"
            printf "  \033[1;33m║\033[0m    \033[1;36mkit theme\033[0m     \033[2;37m(\033[1;36mkit t\033[2;37m)\033[0m      \033[2;37m→\033[0m  \033[1;32mRestore MacTahoe theme\033[0m\n"
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
        case original o
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

        case theme t th
            if test -f "$conf"
                printf "\n"
                printf "  \033[1;32m╔%s╗\033[0m\n" "$sep"
                printf "  \033[1;32m║\033[0m  \033[1;32m✓\033[0m  kitty.conf already exists — MacTahoe active\n"
                printf "  \033[1;32m╚%s╝\033[0m\n" "$sep"
                printf "\n"
                return 0
            end
            if not test -f "$hash"
                printf "\n"
                printf "  \033[1;31m╔%s╗\033[0m\n" "$sep"
                printf "  \033[1;31m║\033[0m  \033[1;31m✗\033[0m  #kitty.conf not found — no saved theme to restore\n"
                printf "  \033[1;31m╚%s╝\033[0m\n" "$sep"
                printf "\n"
                return 1
            end
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
            printf "  \033[1;36m║\033[0m    \033[1;36mkit original\033[0m  \033[2;37m(\033[1;36mkit o\033[2;37m)\033[0m      \033[2;37m→\033[0m  \033[1;33mDisable theme → stock defaults\033[0m\n"
            printf "  \033[1;36m║\033[0m    \033[1;36mkit theme\033[0m     \033[2;37m(\033[1;36mkit t\033[2;37m)\033[0m      \033[2;37m→\033[0m  \033[1;32mRestore theme → MacTahoe\033[0m\n"
            printf "  \033[1;36m║\033[0m    \033[1;36mkit --help\033[0m   \033[2;37m(\033[1;36m-h\033[2;37m)\033[0m        \033[2;37m→\033[0m  \033[1;37mShow this help\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mAliases: kit o = kit original  |  kit t = kit theme\033[0m\n"
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
