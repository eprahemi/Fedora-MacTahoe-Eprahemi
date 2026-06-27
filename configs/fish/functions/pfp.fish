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

    # ── Branding footer (default empty, overridden in help box) ──
    set -l br ""

    # ── Constants ──
    set -l user (whoami)
    set -l icon_file "/var/lib/AccountsService/icons/$user"
    set -l icon_size 512
    set -l key_file "$HOME/.config/pfp.key"

    # ── Help ──
    if set -q argv[1]
        switch $argv[1]
            case --help -h
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
                # ── Get current desktop wallpaper ──
                set -l wp_path ""
                set -l wp_uri (gsettings get org.gnome.desktop.background picture-uri 2>/dev/null; or echo "")
                if test -n "$wp_uri"
                    set wp_path (string replace -r "^'?file://" "" "$wp_uri")
                    set wp_path (string trim --right --chars "'" "$wp_path")
                    set wp_path (python3 -c "import urllib.parse; print(urllib.parse.unquote('$wp_path'))" 2>/dev/null)
                    if not test -f "$wp_path"
                        set wp_uri (gsettings get org.gnome.desktop.background picture-uri-dark 2>/dev/null; or echo "")
                        if test -n "$wp_uri"
                            set wp_path (string replace -r "^'?file://" "" "$wp_uri")
                            set wp_path (string trim --right --chars "'" "$wp_path")
                            set wp_path (python3 -c "import urllib.parse; print(urllib.parse.unquote('$wp_path'))" 2>/dev/null)
                        end
                    end
                end

                if test -z "$wp_path"; or not test -f "$wp_path"
                    echo -e ""
                    echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
                    echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                    set -l e "  ✘  NO DESKTOP WALLPAPER DETECTED  ✘"
                    echo -e "  $RE║$C  $WH$e$C$(printf '%*s' (math "60 - "(string length "$e")) '')$RE║$C"
                    echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                    echo -e "  $RE║$C  $D  Could not find your current wallpaper.$C$(printf '%*s' 17 '')$RE║$C"
                    echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                    echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
                    echo -e ""
                    return 1
                end

                # ── Crop to 512×512 ──
                set -l tmp_file "/tmp/pfp-current-crop-$user.jpg"
                if not magick "$wp_path" -resize 512x512^ -gravity center -extent 512x512 "$tmp_file" 2>/dev/null
                    echo -e ""
                    echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
                    echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                    set -l e "  ✘  CROP FAILED  ✘"
                    echo -e "  $RE║$C  $WH$e$C$(printf '%*s' (math "60 - "(string length "$e")) '')$RE║$C"
                    echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                    echo -e "  $RE║$C  $D  ImageMagick could not process the wallpaper.$C$(printf '%*s' 8 '')$RE║$C"
                    echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                    echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
                    echo -e ""
                    return 1
                end

                set -l wp_disp (string replace -- "$HOME" '~' "$wp_path")

                # ── Preview ──
                echo -e ""
                echo -e "  $D  Cropped from your wallpaper ($wp_disp) → 512×512$C"
                set -l previewed 0
                if test -n "$KITTY_PID"; and command -q kitty
                    kitty +kitten icat --align left "$tmp_file" 2>/dev/null
                    and set previewed 1
                end
                if test $previewed -eq 0; and command -q chafa
                    chafa --symbols solid "$tmp_file" 2>/dev/null
                    and set previewed 1
                end
                if test $previewed -eq 0
                    echo -e "  $GY  Preview not available (install kitty or chafa)$C"
                end

                # ── Ask ──
                echo -e ""
                echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l a1 "  🖼️  USE AS PROFILE PICTURE?"
                echo -e "  $CY║$C  $WH$a1$C$(printf '%*s' (math "60 - "(string length "$a1")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l yt "  [Y] Yes  → Set as profile picture"
                set -l nt "  [N] No   → Cancel"
                echo -e "  $CY║$C  $GR$yt$C$(printf '%*s' (math "60 - "(string length "$yt")) '')$CY║$C"
                echo -e "  $CY║$C  $RE$nt$C$(printf '%*s' (math "60 - "(string length "$nt")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
                echo -e ""

                set -l __cc 0
                while true
                    read -P "  [Y/n]: " pfp_choice
                    set -l __rs $status
                    if test $__rs -ne 0
                        set __cc (math $__cc + 1)
                        if test $__cc -ge 2
                            rm -f "$tmp_file" 2>/dev/null
                            echo -e "  $D  → Cancelled.  $C"
                            return 1
                        end
                        echo -e "  $D  (Ctrl+C again to cancel)  $C"
                        continue
                    end
                    break
                end

                if test -z "$pfp_choice"; or string match -qir '^y' "$pfp_choice"
                    __pfp_apply "$tmp_file"
                    rm -f "$tmp_file" 2>/dev/null
                else
                    rm -f "$tmp_file" 2>/dev/null
                    echo -e "  $GY  ✧  Temp file deleted. No change.$C"
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
                    echo -e "  $RE║$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
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
                set -l info_disp (__pfp_display_path "$icon_file")
                set -l info_len (string length "$info_disp")
                if test $info_len -gt 48
                    set info_disp (string sub -l 45 "$info_disp")"..."
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
                echo -e "  $CY║$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
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
                    echo -e "  $RE║$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
                    echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
                    echo -e ""
                    return 1
                end

                # Generate encrypted-style 16-char name encoding set-date + save-date + random
                # Base36 looks random but decodes to date — fixed 6 chars per timestamp
                set -l applied_ts (stat -c "%Y" "$icon_file" 2>/dev/null; or date +%s)
                set -l save_ts (date +%s)
                set -l applied_b36 (__pfp_b36 "$applied_ts")
                set -l save_b36 (__pfp_b36 "$save_ts")
                # Pad each to exactly 6 chars (left-pad with zeros)
                while test (string length "$applied_b36") -lt 6
                    set applied_b36 "0$applied_b36"
                end
                while test (string length "$save_b36") -lt 6
                    set save_b36 "0$save_b36"
                end
                # Random suffix for uniqueness (4 chars)
                set -l rand_sfx (python3 -c "
import secrets, string
print(''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(4)))
" 2>/dev/null; or echo "x0x0")
                set -l save_name "$applied_b36$save_b36$rand_sfx"
                set save_path "$HOME/Pictures/$save_name.png"

                mkdir -p "$HOME/Pictures"
                cp "$icon_file" "$save_path"

                if test -f "$save_path"
                    set -l orig_disp (__pfp_display_path "$icon_file")
                    if test (string length "$orig_disp") -gt 48
                        set orig_disp (string sub -l 45 "$orig_disp")"..."
                    end
                    # Strip /home/user → ~ for display
                    set -l path_disp (string replace -- "$HOME" '~' "$save_path")
                    # Truncate if needed (max 50 chars inside "  Path:  ")
                    if test (string length "$path_disp") -gt 50
                        set path_disp (string sub -l 47 "$path_disp")"..."
                    end
                    set -l applied_date (date -r "$icon_file" "+%d %b %Y  %H:%M")
                    set -l save_date (date "+%d %b %Y  %H:%M")
                    echo -e ""
                    echo -e "  $GR╔══════════════════════════════════════════════════════════════╗$C"
                    echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
                    set -l s "  ✅  PROFILE PICTURE SAVED"
                    echo -e "  $GR║$C  $WH$s$C$(printf '%*s' (math "60 - "(string length "$s")) '')$GR║$C"
                    echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
                    echo -e "  $GR╠══════════════════════════════════════════════════════════════╣$C"
                    echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
                    set -l i1 "  Path:  $path_disp"
                    echo -e "  $GR║$C  $D$i1$C$(printf '%*s' (math "60 - "(string length "$i1")) '')$GR║$C"
                    set -l i2 "  Orig:  $orig_disp"
                    echo -e "  $GR║$C  $D$i2$C$(printf '%*s' (math "60 - "(string length "$i2")) '')$GR║$C"
                    set -l i3 "  Saved:  $save_date"
                    echo -e "  $GR║$C  $D$i3$C$(printf '%*s' (math "60 - "(string length "$i3")) '')$GR║$C"
                    echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
                    echo -e "  $GR║$C$(printf '%*s' (math "60 - "(string length "$br")) '')$GR║$C"
                    echo -e "  $GR╚══════════════════════════════════════════════════════════════╝$C"
                    echo -e ""
                else
                    echo -e "  $RE  ✘  Failed to save to "(string replace -- "$HOME" '~' "$save_path")"$C"
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
                    echo -e "  $YE║$C$(printf '%*s' (math "60 - "(string length "$br")) '')$YE║$C"
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
                echo -e "  $YE║$C$(printf '%*s' (math "60 - "(string length "$br")) '')$YE║$C"
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
                    echo -e "  $GR║$C$(printf '%*s' (math "60 - "(string length "$br")) '')$GR║$C"
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
                echo -e "  $RE║$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
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
# Internal: Convert a Unix timestamp to base36
# (looks like random gibberish, decodes to date)
# ──────────────────────────────────────────────────────────────
function __pfp_b36 --description 'Convert Unix timestamp to base36'
    set -l n $argv[1]
    if test -z "$n"; or not string match -qr '^[0-9]+$' "$n"
        echo ""
        return 1
    end
    python3 -c "
n = $n
alpha = '0123456789abcdefghijklmnopqrstuvwxyz'
res = ''
while n > 0:
    res = alpha[n % 36] + res
    n //= 36
print(res or '0')
" 2>/dev/null
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
# Internal: Return display-friendly path — encrypt system paths,
# show user paths (XDG dirs, avatar) plainly with ~ prefix
# ──────────────────────────────────────────────────────────────
function __pfp_display_path --description 'Return display path (encrypted for system, plain for user)'
    set -l path $argv[1]
    # User's own avatar — always show plainly
    if string match -q "/var/lib/AccountsService/icons/*" "$path"
        string replace -- "$HOME" '~' "$path"
        return 0
    end
    # User's home directory — show plainly with ~
    if string match -q "$HOME/*" "$path"
        string replace -- "$HOME" '~' "$path"
        return 0
    end
    # System/default paths — encrypt
    __pfp_encrypt "$path"
end


# ──────────────────────────────────────────────────────────────
# Internal: Search for an image across XDG user directories
# Recursive, matches gdm.fish search engine style
# ──────────────────────────────────────────────────────────────
function __pfp_search --description 'Search for image across XDG dirs'
    set -l query $argv[1]
    if test -z "$query"
        return 1
    end

    # ── Colors ──
    set -l C  "\033[0m"
    set -l GY "\033[38;5;248m"
    set -l D  "\033[2m"

    # ── Search 8 XDG directories ──
    set -l search_dirs \
        "$HOME/Pictures" \
        "$HOME/Downloads" \
        "$HOME/Documents" \
        "$HOME/Videos" \
        "$HOME/Music" \
        "$HOME/Desktop" \
        "$HOME/Templates" \
        "$HOME/Public"

    set -l results
    set -l img_regex '\.(jpg|jpeg|png|gif|bmp|webp|tiff?|svg|svgz|ico|heic|heif|avif|jp2|jfif|jfi|pjpeg|pjp|psd|jxl)$'

    # 1. Try exact match as given
    echo -e "  $D🔍  Searching for \"$query\"...$C" >&2
    for dir in $search_dirs
        if test -d "$dir"
            for f in (find "$dir" -type f -iname "$query" 2>/dev/null)
                set -l rp (realpath "$f" 2>/dev/null)
                if test -n "$rp"
                    if string match -riq -- $img_regex "$rp"
                        if not contains -- "$rp" $results
                            set -a results "$rp"
                        end
                    end
                end
            end
        end
    end

    # 2. Try query + extension pattern (e.g. "help" → "help.*")
    if test (count $results) -eq 0
        echo -e "  $D  No exact match — trying \"$query.*\"...$C" >&2
        for dir in $search_dirs
            if test -d "$dir"
                for f in (find "$dir" -type f -iname "$query.*" 2>/dev/null)
                    set -l rp (realpath "$f" 2>/dev/null)
                    if test -n "$rp"
                        if string match -riq -- $img_regex "$rp"
                            if not contains -- "$rp" $results
                                set -a results "$rp"
                            end
                        end
                    end
                end
            end
        end
    end

    # 3. Try wildcard match
    if test (count $results) -eq 0
        echo -e "  $D  No match — trying wildcard \"*$query*\"...$C" >&2
        for dir in $search_dirs
            if test -d "$dir"
                for f in (find "$dir" -type f -iname "*$query*" 2>/dev/null)
                    set -l rp (realpath "$f" 2>/dev/null)
                    if test -n "$rp"
                        if string match -riq -- $img_regex "$rp"
                            if not contains -- "$rp" $results
                                set -a results "$rp"
                            end
                        end
                    end
                end
            end
        end
    end

    # 4. Try current working directory
    if test (count $results) -eq 0
        echo -e "  $D  Also checking current directory...$C" >&2
        for f in (find (pwd) -maxdepth 1 -type f -iname "*$query*" 2>/dev/null)
            set -l rp (realpath "$f" 2>/dev/null)
            if test -n "$rp"
                if string match -riq -- $img_regex "$rp"
                    if not contains -- "$rp" $results
                        set -a results "$rp"
                    end
                end
            end
        end
    end

    # Output results (caller checks count)
    for r in $results
        echo "$r"
    end
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

    # ── Check file exists, else search ──
    if not test -f "$source_img"
        # ── Search engine (gdm.fish style: XDG dirs, recursive) ──
        set -l search_query (basename "$source_img")

        # 🛡️  GUARD: Minimum search term length
        set -l is_path (string match -r -- '/' "$source_img")
        set -l stem (string replace -r -- '\..*$' '' "$search_query")
        # Allow short stem if the filename has a recognized image extension —
        # "t.jpg" clearly specifies an image file
        set -l img_exts jpg jpeg png gif bmp webp tiff tif svg svgz ico heic heif avif jp2 jfif jfi pjpeg pjp psd jxl
        set -l has_img_ext 0
        set -l this_ext (string match -r '\.([^./]+)$' "$search_query" 2>/dev/null)
        if test -n "$this_ext"
            set -l ext_lower (string lower -- "$this_ext[2]" 2>/dev/null)
            if contains -- "$ext_lower" $img_exts
                set has_img_ext 1
            end
        end
        if test -z "$is_path"; and test $has_img_ext -eq 0; and test (string length -- "$stem") -lt 3
            echo -e ""
            echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l se1 "  ✘  SEARCH TERM TOO SHORT"
            echo -e "  $RE║$C  $WH$se1$C$(printf '%*s' (math "60 - "(string length "$se1")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            echo -e "  $RE╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l se2 "  Use at least 3 characters to search."
            echo -e "  $RE║$C  $D$se2$C$(printf '%*s' (math "60 - "(string length "$se2")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            echo -e "  $RE╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l se3 "  Instead, use the full path:"
            echo -e "  $RE║$C  $YE$se3$C$(printf '%*s' (math "60 - "(string length "$se3")) '')$RE║$C"
            set -l se4 "  pfp /path/to/your/image.jpg"
            echo -e "  $RE║$C  $CY$se4$C$(printf '%*s' (math "60 - "(string length "$se4")) '')$RE║$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
            echo -e ""
            return 1
        end

        set -l search_results (__pfp_search "$search_query" 2>/dev/null)
        set -l result_count (count $search_results)

        switch $result_count
            case 0
                echo -e ""
                echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l e "  ✘  File not found: "$search_query"  ✘"
                echo -e "  $RE║$C  $WH$e$C$(printf '%*s' (math "60 - "(string length "$e")) '')$RE║$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                echo -e "  $RE╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l se2 "  Searched all your home folders — nothing found."
                echo -e "  $RE║$C  $D$se2$C$(printf '%*s' (math "60 - "(string length "$se2")) '')$RE║$C"
                set -l se3 "  Use the full path: pfp /path/to/your/image.jpg"
                echo -e "  $RE║$C  $YE$se3$C$(printf '%*s' (math "60 - "(string length "$se3")) '')$RE║$C"
                if string match -q -- "help" "$search_query"
                    set -l h1 "  If you meant an image — name wrong, missing, or mistyped."
                    set -l h2 "  If you meant --help to see available commands —"
                    set -l h3 "  you need to type:  pfp --help"
                    echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                    echo -e "  $RE║$C  $GY$B$h1$C$(printf '%*s' (math "60 - "(string length "$h1")) '')$RE║$C"
                    echo -e "  $RE║$C  $GY$B$h2$C$(printf '%*s' (math "60 - "(string length "$h2")) '')$RE║$C"
                    echo -e "  $RE║$C  $GY$h3$C$(printf '%*s' (math "60 - "(string length "$h3")) '')$RE║$C"
                end
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
                echo -e ""
                return 1

            case 1
                set source_img "$search_results[1]"

            case '*'
                # Multiple results — interactive picker
                echo -e ""
                echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l mh "  Multiple images found — pick one:"
                echo -e "  $CY║$C  $WH$mh$C$(printf '%*s' (math "60 - "(string length "$mh")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"

                for i in (seq $result_count)
                    set -l fullpath $search_results[$i]
                    set -l disp_path (string replace -- "$HOME" '~' "$fullpath")
                    set -l dir_part (dirname "$disp_path")/
                    set -l file_part (basename "$disp_path")
                    set -l num_str (printf "%2d" $i)
                    set -l prefix "  [$num_str]  "
                    set -l cont_indent "        "
                    set -l remaining "$disp_path"
                    set -l line_num 1
                    while test -n "$remaining"
                        set -l trimmed (string sub -l 52 "$remaining")
                        set -l match_end (string match -r ".* " "$trimmed")
                        set -l split_pos (string length -- "$match_end")
                        set -l part; set -l rest
                        if test -n "$match_end"; and test "$split_pos" -gt 10
                            set -l split (math "$split_pos - 1")
                            set part (string sub -l $split "$remaining")
                            set rest (string sub -s (math "$split_pos + 1") "$remaining")
                        else
                            set part "$trimmed"
                            set rest (string sub -s 53 "$remaining")
                        end
                        # Bold the filename within the displayed text
                        set -l file_regex (string escape --style=regex "$file_part")
                        set -l display (string replace -r -- "^(.*)($file_regex)" '$1'"$WH$B"'$2' "$part")
                        if test $line_num -eq 1
                            set -l raw_line "$prefix$part"
                            set -l col_line "$prefix$display"
                            echo -e "  $CY║$C  $col_line$C$(printf '%*s' (math "60 - "(string length "$raw_line")) '')$CY║$C"
                        else
                            set -l raw_line "$cont_indent$part"
                            set -l col_line "$cont_indent$display"
                            echo -e "  $CY║$C  $col_line$C$(printf '%*s' (math "60 - "(string length "$raw_line")) '')$CY║$C"
                        end
                        set remaining "$rest"
                        set line_num (math "$line_num + 1")
                    end
                    # Blank line between entries
                    if test $i -lt $result_count
                        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                    end
                end

                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l prompt "  Enter number [1-$result_count] or [0] to cancel:"
                echo -e "  $CY║$C  $YE$prompt$C$(printf '%*s' (math "60 - "(string length "$prompt")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
                echo ""

                set -l chosen 0
                set -l __cc 0
                while test $chosen -eq 0
                    echo -e "  $D  Enter number [1-$result_count], or 0 to cancel.$C"
                    read -P "  > " choice
                    set -l __rs $status
                    if test $__rs -ne 0
                        set __cc (math $__cc + 1)
                        if test $__cc -ge 2
                            echo -e "  $D  → Cancelled.  $C"
                            return 1
                        end
                        echo -e "  $D  (Ctrl+C again to cancel)  $C"
                        continue
                    end
                    set __cc 0
                    if test "$choice" = "0"
                        echo -e "  $D  Cancelled.$C"
                        return 1
                    end
                    if string match -rq '^[0-9]+$' -- "$choice"; and test "$choice" -ge 1; and test "$choice" -le $result_count
                        set source_img "$search_results[$choice]"
                        # ── Preview the selected image ──
                        echo -e ""
                        echo -e "  $D  Preview: "(string replace -- $HOME '~' "$source_img")"$C"
                        set -l previewed 0
                        # Try kitty's icat (terminal preview)
                        if test -n "$KITTY_PID"; and command -q kitty
                            kitty +kitten icat --align left "$source_img" 2>/dev/null
                            and set previewed 1
                        end
                        # Try chafa (terminal preview)
                        if test $previewed -eq 0
                            if command -q chafa
                                chafa --symbols solid "$source_img" 2>/dev/null
                                and set previewed 1
                            end
                        end
                        # Fallback: just show the path
                        if test $previewed -eq 0
                            echo -e "  $GY  (no terminal image previewer found)$C"
                        end
                        # ── Confirm ──
                        echo -e ""
                        set -l confirmed 0
                        set -l __cc2 0
                        while test $confirmed -eq 0
                            read -P "  Use this image? [Y/n/0] " confirm
                            set -l __rs2 $status
                            if test $__rs2 -ne 0
                                set __cc2 (math $__cc2 + 1)
                                if test $__cc2 -ge 2
                                    echo -e "  $D  → Cancelled.  $C"
                                    return 1
                                end
                                echo -e "  $D  (Ctrl+C again to cancel)  $C"
                                continue
                            end
                            set __cc2 0
                            if string match -qir '^0$' "$confirm"
                                echo -e "  $D  → Cancelled.  $C"
                                return 1
                            end
                            if test -z "$confirm"; or string match -q -- "y" "$confirm"; or string match -q -- "Y" "$confirm"; or string match -iq -- "yes" "$confirm"
                                set chosen 1
                                set confirmed 1
                            else if string match -q -- "n" "$confirm"; or string match -q -- "N" "$confirm"; or string match -iq -- "no" "$confirm"
                                set confirmed 1
                                echo -e ""
                                echo -e "  $D  Choose another...$C"
                            else
                                echo -e "  $RE  Enter y, n, or 0 to cancel.$C"
                            end
                        end
                    else
                        echo -e "  $RE  Invalid choice. Enter 1-$result_count or 0 to cancel.$C"
                    end
                end
        end
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
        echo -e "  $RE║$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
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
    echo -e "  $GR║$C$(printf '%*s' (math "60 - "(string length "$br")) '')$GR║$C"
    echo -e "  $GR╚══════════════════════════════════════════════════════════════╝$C"
    echo -e ""
end
