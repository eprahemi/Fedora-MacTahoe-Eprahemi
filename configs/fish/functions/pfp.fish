# ══════════════════════════════════════════════════════════════
# pfp — User profile picture (avatar) switcher
# Sets, views, and manages the GNOME AccountsService avatar
# Fedora MacTahoe Eprahemi Edition © 2026
# github.com/eprahemi
# ══════════════════════════════════════════════════════════════
function pfp --description 'Manage your GNOME profile picture (avatar) — github.com/eprahemi/Fedora-MacTahoe-Eprahemi'
    # ── Colors ──
    set -l C  "\033[0m"
    set -l CY "\033[1;36m"
    set -l GR "\033[1;32m"
    set -l YE "\033[1;33m"
    set -l RE "\033[1;31m"
    set -l WH "\033[1;37m"
    set -l GY "\033[38;5;248m"
    set -l D  "\033[2m"
    set -l B  "\033[1m"

    # ── Constants ──
    set -l user (whoami)
    set -l icon_file "/var/lib/AccountsService/icons/$user"
    set -l icon_size 512
    set -l key_file "$HOME/.config/pfp.key"

    # ── Help ──
    if set -q argv[1]
        switch $argv[1]
            case --help -h help
                echo -e ""
                echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l t "  👤  PFP — PROFILE PICTURE"
                echo -e "  $CY║$C  $WH$t$C$(printf '%*s' (math "60 - "(string length "$t")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l l1 "  pfp <image>        Set profile picture from image file"
                echo -e "  $CY║$C  $GR$l1$C$(printf '%*s' (math "60 - "(string length "$l1")) '')$CY║$C"
                set -l l2 "  pfp current        Show avatar + suggest desktop wallpaper"
                echo -e "  $CY║$C  $GR$l2$C$(printf '%*s' (math "60 - "(string length "$l2")) '')$CY║$C"
                set -l l3 "  pfp info           Show full profile picture details"
                echo -e "  $CY║$C  $GR$l3$C$(printf '%*s' (math "60 - "(string length "$l3")) '')$CY║$C"
                set -l l4 "  pfp save           Save current avatar to ~/Pictures/"
                echo -e "  $CY║$C  $GR$l4$C$(printf '%*s' (math "60 - "(string length "$l4")) '')$CY║$C"
                set -l l5 "  pfp remove         Reset to default avatar"
                echo -e "  $CY║$C  $GR$l5$C$(printf '%*s' (math "60 - "(string length "$l5")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l l7 "  pfp --help, -h     Show this help"
                echo -e "  $CY║$C  $D$l7$C$(printf '%*s' (math "60 - "(string length "$l7")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l br "  eprahemi  •  github.com/eprahemi"
                echo -e "  $CY║$C  $GY$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
                echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
                echo -e ""
                return 0

            case current
                # ── Show current avatar ──
                if test -f "$icon_file"
                    if test -n "$KITTY_PID"
                        kitty +kitten icat --align left "$icon_file" 2>/dev/null
                        echo ""
                    end
                    set -l cur_size (du -h "$icon_file" 2>/dev/null | awk '{print $1}')
                    set -l cur_dims (identify -format "%wx%h" "$icon_file" 2>/dev/null; or echo "?x?")
                    set -l cur_fmt (identify -format "%m" "$icon_file" 2>/dev/null; or echo "?")
                    set -l cur_mtime (date -r "$icon_file" "+%d %b %Y  %H:%M" 2>/dev/null; or echo "?")
                    set -l cur_enc (__pfp_encrypt "$icon_file")
                    set -l cur_disp "$cur_enc"
                    if test (string length "$cur_enc") -gt 48
                        set cur_disp (string sub -l 45 "$cur_enc")"..."
                    end
                    echo -e ""
                    echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
                    echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                    set -l t "  👤  CURRENT PROFILE PICTURE"
                    echo -e "  $CY║$C  $WH$t$C$(printf '%*s' (math "60 - "(string length "$t")) '')$CY║$C"
                    echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                    echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                    echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                    set -l i1 "  User:  $user"
                    echo -e "  $CY║$C  $GY$i1$C$(printf '%*s' (math "60 - "(string length "$i1")) '')$CY║$C"
                    set -l i2 "  File:  $cur_disp"
                    echo -e "  $CY║$C  $GY$i2$C$(printf '%*s' (math "60 - "(string length "$i2")) '')$CY║$C"
                    set -l i3 "  Size:  $cur_size"
                    echo -e "  $CY║$C  $GY$i3$C$(printf '%*s' (math "60 - "(string length "$i3")) '')$CY║$C"
                    set -l i4 "  Dims:  $cur_dims"
                    echo -e "  $CY║$C  $GY$i4$C$(printf '%*s' (math "60 - "(string length "$i4")) '')$CY║$C"
                    set -l i5 "  Type:  $cur_fmt"
                    echo -e "  $CY║$C  $GY$i5$C$(printf '%*s' (math "60 - "(string length "$i5")) '')$CY║$C"
                    set -l i6 "  Date:  $cur_mtime"
                    echo -e "  $CY║$C  $GY$i6$C$(printf '%*s' (math "60 - "(string length "$i6")) '')$CY║$C"
                    echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                    set -l br "  eprahemi  •  github.com/eprahemi"
                    echo -e "  $CY║$C  $GY$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
                    echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
                    echo -e ""
                else
                    echo -e ""
                    echo -e "  $YE╔══════════════════════════════════════════════════════════════╗$C"
                    echo -e "  $YE║$C$(printf '%*s' 62 '')$YE║$C"
                    set -l e "  ⚠️  No profile picture set  ⚠️"
                    echo -e "  $YE║$C  $WH$e$C$(printf '%*s' (math "60 - "(string length "$e")) '')$YE║$C"
                    echo -e "  $YE║$C$(printf '%*s' 62 '')$YE║$C"
                    set -l br "  eprahemi  •  github.com/eprahemi"
                    echo -e "  $YE║$C  $GY$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$YE║$C"
                    echo -e "  $YE╚══════════════════════════════════════════════════════════════╝$C"
                    echo -e ""
                end

                # ── Detect desktop wallpaper ──
                set -l wp_path ""
                set -l wp_uri (gsettings get org.gnome.desktop.background picture-uri 2>/dev/null; or echo "")
                if test -n "$wp_uri"
                    # Strip leading 'file:// and trailing '
                    set wp_path (string replace -r "^'?file://" "" "$wp_uri")
                    set wp_path (string trim --right --chars "'" "$wp_path")
                    # URL-decode (e.g. %20 → space)
                    set wp_path (python3 -c "import urllib.parse; print(urllib.parse.unquote('$wp_path'))" 2>/dev/null)
                    if not test -f "$wp_path"
                        # Try picture-uri-dark
                        set wp_uri (gsettings get org.gnome.desktop.background picture-uri-dark 2>/dev/null; or echo "")
                        if test -n "$wp_uri"
                            set wp_path (string replace -r "^'?file://" "" "$wp_uri")
                            set wp_path (string trim --right --chars "'" "$wp_path")
                            set wp_path (python3 -c "import urllib.parse; print(urllib.parse.unquote('$wp_path'))" 2>/dev/null)
                        end
                    end
                end

                if test -n "$wp_path" -a -f "$wp_path"
                    set -l wp_name (basename "$wp_path")
                    set -l wp_size (du -h "$wp_path" 2>/dev/null | awk '{print $1}')
                    set -l wp_dims (identify -format "%wx%h" "$wp_path" 2>/dev/null; or echo "?x?")
                    set -l wp_enc (__pfp_encrypt "$wp_path")
                    set -l wp_disp "$wp_enc"
                    if test (string length "$wp_enc") -gt 48
                        set wp_disp (string sub -l 45 "$wp_enc")"..."
                    end

                    echo -e ""
                    echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
                    echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                    set -l t "  🖼️  DESKTOP WALLPAPER DETECTED"
                    echo -e "  $CY║$C  $WH$t$C$(printf '%*s' (math "60 - "(string length "$t")) '')$CY║$C"
                    echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                    echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                    echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                    set -l w1 "  File:  $wp_disp"
                    echo -e "  $CY║$C  $GY$w1$C$(printf '%*s' (math "60 - "(string length "$w1")) '')$CY║$C"
                    set -l w2 "  Size:  $wp_size"
                    echo -e "  $CY║$C  $GY$w2$C$(printf '%*s' (math "60 - "(string length "$w2")) '')$CY║$C"
                    set -l w3 "  Dims:  $wp_dims"
                    echo -e "  $CY║$C  $GY$w3$C$(printf '%*s' (math "60 - "(string length "$w3")) '')$CY║$C"
                    echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                    echo -e "  $CY║$C  $D  Use wallpaper as profile picture?$C                 $CY║$C"
                    echo -e "  $CY║$C  $D  [y/N]: $C$(printf '%*s' 45 '')$CY║$C"
                    echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                    set -l br "  eprahemi  •  github.com/eprahemi"
                    echo -e "  $CY║$C  $GY$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
                    echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
                    echo -e ""

                    # ── Read answer ──
                    echo -n "  → "
                    read -l wp_choice
                    if test $status -ne 0
                        echo -e "  $GY  ✧  Cancelled.$C"
                        return 0
                    end
                    if string match -qir '^y' "$wp_choice"
                        __pfp_apply "$wp_path"
                    else
                        echo -e "  $GY  ✧  No change.$C"
                    end
                else
                    echo -e "  $GY  ✧  No desktop wallpaper detected to suggest.$C"
                end
                return 0

            case info
                # ── Show profile picture info (old pfp current) ──
                if not test -f "$icon_file"
                    echo -e ""
                    echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
                    echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                    set -l e "  ✘  No profile picture set  ✘"
                    echo -e "  $RE║$C  $WH$e$C$(printf '%*s' (math "60 - "(string length "$e")) '')$RE║$C"
                    echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                    set -l br "  eprahemi  •  github.com/eprahemi"
                    echo -e "  $RE║$C  $GY$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
                    echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
                    echo -e ""
                    return 1
                end

                # ── Preview in Kitty if available ──
                if test -n "$KITTY_PID"
                    kitty +kitten icat --align left "$icon_file" 2>/dev/null
                    echo ""
                end

                # ── Show info box with encrypted path ──
                set -l info_size (du -h "$icon_file" 2>/dev/null | awk '{print $1}')
                set -l info_dims (identify -format "%wx%h" "$icon_file" 2>/dev/null; or echo "?x?")
                set -l info_fmt (identify -format "%m" "$icon_file" 2>/dev/null; or echo "?")
                set -l info_mtime (date -r "$icon_file" "+%d %b %Y  %H:%M" 2>/dev/null; or echo "?")
                set -l info_enc (__pfp_encrypt "$icon_file")
                # Show truncated encrypted path for display
                set -l info_disp "$info_enc"
                if test (string length "$info_enc") -gt 48
                    set info_disp (string sub -l 45 "$info_enc")"..."
                end

                echo -e ""
                echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l t "  👤  PROFILE PICTURE INFO"
                echo -e "  $CY║$C  $WH$t$C$(printf '%*s' (math "60 - "(string length "$t")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l i1 "  User:  $user"
                echo -e "  $CY║$C  $GY$i1$C$(printf '%*s' (math "60 - "(string length "$i1")) '')$CY║$C"
                set -l i2 "  File:  $info_disp"
                echo -e "  $CY║$C  $GY$i2$C$(printf '%*s' (math "60 - "(string length "$i2")) '')$CY║$C"
                set -l i3 "  Size:  $info_size"
                echo -e "  $CY║$C  $GY$i3$C$(printf '%*s' (math "60 - "(string length "$i3")) '')$CY║$C"
                set -l i4 "  Dims:  $info_dims"
                echo -e "  $CY║$C  $GY$i4$C$(printf '%*s' (math "60 - "(string length "$i4")) '')$CY║$C"
                set -l i5 "  Type:  $info_fmt"
                echo -e "  $CY║$C  $GY$i5$C$(printf '%*s' (math "60 - "(string length "$i5")) '')$CY║$C"
                set -l i6 "  Date:  $info_mtime"
                echo -e "  $CY║$C  $GY$i6$C$(printf '%*s' (math "60 - "(string length "$i6")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l br "  eprahemi  •  github.com/eprahemi"
                echo -e "  $CY║$C  $GY$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
                echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
                echo -e ""
                return 0

            case save
                # ── Save current avatar to ~/Pictures/ ──
                if not test -f "$icon_file"
                    echo -e ""
                    echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
                    echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                    set -l e "  ✘  No profile picture to save  ✘"
                    echo -e "  $RE║$C  $WH$e$C$(printf '%*s' (math "60 - "(string length "$e")) '')$RE║$C"
                    echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                    set -l br "  eprahemi  •  github.com/eprahemi"
                    echo -e "  $RE║$C  $GY$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
                    echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
                    echo -e ""
                    return 1
                end

                # Generate filename: timestamp + random
                set -l ts (date +%s)
                set -l rand (python3 -c "import secrets; print(secrets.token_hex(5))" 2>/dev/null; or echo "xxxxx")
                set -l save_name (printf "%x" $ts)"-$rand.png"
                set -l save_path "$HOME/Pictures/$save_name"

                mkdir -p "$HOME/Pictures"
                cp "$icon_file" "$save_path"

                if test -f "$save_path"
                    set -l enc_orig (__pfp_encrypt "$icon_file")
                    set -l applied_date (date -r "$icon_file" "+%d %b %Y  %H:%M")
                    echo -e ""
                    echo -e "  $GR╔══════════════════════════════════════════════════════════════╗$C"
                    echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
                    set -l s "  ✅  Profile picture saved!"
                    echo -e "  $GR║$C  $WH$s$C$(printf '%*s' (math "60 - "(string length "$s")) '')$GR║$C"
                    echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
                    set -l i1 "  Path:  $save_path"
                    echo -e "  $GR║$C  $D$i1$C$(printf '%*s' (math "60 - "(string length "$i1")) '')$GR║$C"
                    set -l i2 "  Orig:  $enc_orig"
                    echo -e "  $GR║$C  $D$i2$C$(printf '%*s' (math "60 - "(string length "$i2")) '')$GR║$C"
                    set -l i3 "  🕒  Saved:  "(date "+%d %b %Y  %H:%M")""
                    echo -e "  $GR║$C  $D$i3$C$(printf '%*s' (math "60 - "(string length "$i3")) '')$GR║$C"
                    echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
                    set -l br "  eprahemi  •  github.com/eprahemi"
                    echo -e "  $GR║$C  $GY$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$GR║$C"
                    echo -e "  $GR╚══════════════════════════════════════════════════════════════╝$C"
                    echo -e ""
                else
                    echo -e "  $RE  ✘  Failed to save to $save_path$C"
                    return 1
                end
                return 0

            case remove reset
                # ── Reset profile picture ──
                if not test -f "$icon_file"
                    echo -e ""
                    echo -e "  $YE╔══════════════════════════════════════════════════════════════╗$C"
                    echo -e "  $YE║$C$(printf '%*s' 62 '')$YE║$C"
                    set -l e "  ⚠️  No profile picture to remove  ⚠️"
                    echo -e "  $YE║$C  $WH$e$C$(printf '%*s' (math "60 - "(string length "$e")) '')$YE║$C"
                    echo -e "  $YE║$C$(printf '%*s' 62 '')$YE║$C"
                    set -l br "  eprahemi  •  github.com/eprahemi"
                    echo -e "  $YE║$C  $GY$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$YE║$C"
                    echo -e "  $YE╚══════════════════════════════════════════════════════════════╝$C"
                    echo -e ""
                    return 0
                end

                # Confirm
                echo -e ""
                echo -e "  $YE╔══════════════════════════════════════════════════════════════╗$C"
                echo -e "  $YE║$C$(printf '%*s' 62 '')$YE║$C"
                set -l e "  ⚠️  Reset to default avatar?  ⚠️"
                echo -e "  $YE║$C  $WH$e$C$(printf '%*s' (math "60 - "(string length "$e")) '')$YE║$C"
                echo -e "  $YE║$C$(printf '%*s' 62 '')$YE║$C"
                set -l br "  eprahemi  •  github.com/eprahemi"
                echo -e "  $YE║$C  $GY$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$YE║$C"
                echo -e "  $YE╚══════════════════════════════════════════════════════════════╝$C"
                echo -e ""
                echo -n "  [y/N]: "
                read -l confirm
                if test $status -ne 0
                    echo -e "  $GY  ✧  Cancelled.$C"
                    return 0
                end
                if not string match -qir '^y' "$confirm"
                    echo -e "  $GY  ✧  Cancelled.$C"
                    return 0
                end

                sudo rm -f "$icon_file"
                if test $status -eq 0
                    echo -e ""
                    echo -e "  $GR╔══════════════════════════════════════════════════════════════╗$C"
                    echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
                    set -l s "  ✅  Profile picture reset to default"
                    echo -e "  $GR║$C  $WH$s$C$(printf '%*s' (math "60 - "(string length "$s")) '')$GR║$C"
                    echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
                    echo -e "  $GR║$C  $D  Log out or reboot to see the change.$C$(printf '%*s' 19 '')$GR║$C"
                    echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
                    set -l br "  eprahemi  •  github.com/eprahemi"
                    echo -e "  $GR║$C  $GY$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$GR║$C"
                    echo -e "  $GR╚══════════════════════════════════════════════════════════════╝$C"
                    echo -e ""
                else
                    echo -e "  $RE  ✘  Failed to remove profile picture. Try: sudo rm -f $icon_file$C"
                    return 1
                end
                return 0

            case '-*'
                echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l e "  ✘  Unknown flag: $argv[1]  ✘"
                echo -e "  $RE║$C  $WH$e$C$(printf '%*s' (math "60 - "(string length "$e")) '')$RE║$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l br "  eprahemi  •  github.com/eprahemi"
                echo -e "  $RE║$C  $GY$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
                echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
                echo -e "  $D  Try: pfp --help$C"
                return 1
        end
    end

    # ── No args = show help ──
    if not set -q argv[1]
        pfp --help
        return 0
    end

    # ── Default: pfp <image> — set profile picture ──
    __pfp_apply $argv
end


# ──────────────────────────────────────────────────────────────
# Internal: Encrypt a path using Fernet (symmetric encryption)
# Key stored at ~/.config/pfp.key
# ──────────────────────────────────────────────────────────────
function __pfp_encrypt --description 'Encrypt a file path for display'
    set -l path $argv[1]
    if test -z "$path"
        return 1
    end

    # Generate key on first use
    set -l key_file "$HOME/.config/pfp.key"
    if not test -f "$key_file"
        mkdir -p "$HOME/.config"
        python3 -c "
from cryptography.fernet import Fernet
key = Fernet.generate_key()
with open('$key_file', 'wb') as f:
    f.write(key)
" 2>/dev/null
        chmod 600 "$key_file" 2>/dev/null
    end

    # Encrypt the path
    set -l encrypted (python3 -c "
import sys
from cryptography.fernet import Fernet
try:
    with open('$key_file', 'rb') as f:
        key = f.read()
    f = Fernet(key)
    enc = f.encrypt(sys.argv[1].encode())
    print(enc.decode())
except Exception:
    sys.exit(1)
" "$path" 2>/dev/null)

    if test $status -ne 0 -o -z "$encrypted"
        # Fallback: base64 if Fernet fails
        set encrypted (echo -n "$path" | python3 -c "import sys,base64; print(base64.urlsafe_b64encode(sys.stdin.read().encode()).decode())" 2>/dev/null)
    end

    echo "$encrypted"
end

# ──────────────────────────────────────────────────────────────
# Internal: Apply an image as the profile picture
# ──────────────────────────────────────────────────────────────
function __pfp_apply --description 'Internal: apply image as profile picture'
    # ── Colors (reuse from parent) ──
    set -l C  "\033[0m"
    set -l CY "\033[1;36m"
    set -l GR "\033[1;32m"
    set -l YE "\033[1;33m"
    set -l RE "\033[1;31m"
    set -l WH "\033[1;37m"
    set -l GY "\033[38;5;248m"
    set -l D  "\033[2m"
    set -l B  "\033[1m"

    set -l user (whoami)
    set -l icon_file "/var/lib/AccountsService/icons/$user"
    set -l icon_size 512
    set -l temp_file "/tmp/pfp-converted-$user.png"

    # ── Check argument ──
    if not set -q argv[1]
        echo -e "  $RE  ✘  No image specified.$C"
        echo -e "  $D     Usage: pfp /path/to/image.jpg$C"
        return 1
    end

    set -l source_img (string join ' ' $argv)

    # ── Check file exists ──
    if not test -f "$source_img"
        echo -e ""
        echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
        echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
        set -l e "  ✘  File not found: "(basename "$source_img")"  ✘"
        echo -e "  $RE║$C  $WH$e$C$(printf '%*s' (math "60 - "(string length "$e")) '')$RE║$C"
        echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
        set -l br "  eprahemi  •  github.com/eprahemi"
        echo -e "  $RE║$C  $GY$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
        echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
        echo -e ""
        return 1
    end

    # ── Check magick ──
    if not command -q magick
        echo -e ""
        echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
        echo -e "  $RE║$C$(printf '%s' '                                                            ')$RE║$C"
        set -l e "  ✘  ImageMagick not found  ✘"
        echo -e "  $RE║$C  $WH$e$C$(printf '%*s' (math "60 - "(string length "$e")) '')$RE║$C"
        echo -e "  $RE║$C$(printf '%s' '                                                            ')$RE║$C"
        echo -e "  $RE║$C  $D  Install: sudo dnf install ImageMagick$C$(printf '%*s' 10 '')$RE║$C"
        echo -e "  $RE║$C$(printf '%s' '                                                            ')$RE║$C"
        set -l br "  eprahemi  •  github.com/eprahemi"
        echo -e "  $RE║$C  $GY$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
        echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
        echo -e ""
        return 1
    end

    # ── Convert: crop to square, resize to 512x512 PNG ──
    echo -e "  $D  Converting to $icon_size"x"$icon_size PNG...$C"
    if not magick "$source_img" -gravity center -extent 1:1 -resize "$icon_size"x"$icon_size"^ -gravity center -extent "$icon_size"x"$icon_size" "$temp_file" 2>/dev/null
        echo -e "  $RE  ✘  Failed to convert image. File may be corrupt or unsupported.$C"
        return 1
    end

    # ── Copy to AccountsService (needs sudo) ──
    echo -e "  $D  Installing to AccountsService...$C"
    if not sudo cp "$temp_file" "$icon_file" 2>/dev/null
        echo -e "  $RE  ✘  Failed to install profile picture. Try: sudo cp $temp_file $icon_file$C"
        rm -f "$temp_file"
        return 1
    end
    sudo chown root:root "$icon_file" 2>/dev/null
    rm -f "$temp_file"

    # ── Success ──
    echo -e ""
    echo -e "  $GR╔══════════════════════════════════════════════════════════════╗$C"
    echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
    set -l s "  ✅  Profile picture updated!"
    echo -e "  $GR║$C  $WH$s$C$(printf '%*s' (math "60 - "(string length "$s")) '')$GR║$C"
    echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
    set -l i1 "  User:  $user"
    echo -e "  $GR║$C  $D$i1$C$(printf '%*s' (math "60 - "(string length "$i1")) '')$GR║$C"
    set -l src (basename "$source_img")
    set -l i2 "  From:  $src"
    echo -e "  $GR║$C  $D$i2$C$(printf '%*s' (math "60 - "(string length "$i2")) '')$GR║$C"
    echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
    echo -e "  $GR║$C  $D  Log out or reboot to see the change.$C$(printf '%*s' 19 '')$GR║$C"
    echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
    set -l br "  eprahemi  •  github.com/eprahemi"
    echo -e "  $GR║$C  $GY$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$GR║$C"
    echo -e "  $GR╚══════════════════════════════════════════════════════════════╝$C"
    echo -e ""
end
