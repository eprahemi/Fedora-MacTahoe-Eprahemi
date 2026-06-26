# ══════════════════════════════════════════════════════════════
# gdm — GDM login wallpaper switcher with blur, preview, and search
# Fedora MacTahoe eprahemi Edition © 2026
# github.com/eprahemi
# ══════════════════════════════════════════════════════════════
function gdm --description 'Change GDM login screen wallpaper — needs internet only the first time — github.com/eprahemi'
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

    # ── Flags ──
    set -l skip_confirm 0
    set -l skip_double_confirm 0

    # ── Arg check (no args → show all usages in a box) ──
    if not set -q argv[1]
        echo ""
        echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l n1 "  🖼️  GDM WALLPAPER SWITCHER"
        echo -e "  $CY║$C  $WH$n1$C$(printf '%*s' (math "60 - "(string length "$n1")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l n2 "    gdm current"
        echo -e "  $CY║$C  $CY$B$n2$C$(printf '%*s' (math "60 - "(string length "$n2")) '')$CY║$C"
        set -l n2b "          →  use current desktop wallpaper"
        echo -e "  $CY║$C  $D$n2b$C$(printf '%*s' (math "60 - "(string length "$n2b")) '')$CY║$C"
        set -l n3 "    gdm filename.jpg"
        echo -e "  $CY║$C  $CY$B$n3$C$(printf '%*s' (math "60 - "(string length "$n3")) '')$CY║$C"
        set -l n4 "    gdm /path/to/image.jpg"
        echo -e "  $CY║$C  $CY$B$n4$C$(printf '%*s' (math "60 - "(string length "$n4")) '')$CY║$C"
        set -l n5 "    gdm default"
        echo -e "  $CY║$C  $CY$B$n5$C$(printf '%*s' (math "60 - "(string length "$n5")) '')$CY║$C"
        set -l n5b "    gdm info"
        echo -e "  $CY║$C  $CY$B$n5b$C$(printf '%*s' (math "60 - "(string length "$n5b")) '')$CY║$C"
        set -l n6 "    gdm -y|--yes filename.jpg"
        echo -e "  $CY║$C  $CY$B$n6$C$(printf '%*s' (math "60 - "(string length "$n6")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l n7 "  🔍  gdm --help   →  full features + blur"
        echo -e "  $CY║$C  $D$n7$C$(printf '%*s' (math "60 - "(string length "$n7")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l br "  eprahemi  •  github.com/eprahemi"
        echo -e "  $CY║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
        echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
        echo ""
        return 1
    end

    if contains -- "$argv[1]" "-h" "--help"
        echo ""
        echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l t1 "  🖼️  GDM WALLPAPER SWITCHER"
        echo -e "  $CY║$C  $WH$t1$C$(printf '%*s' (math "60 - "(string length "$t1")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        # ── Figlet "eprahemi" copyright (surprise!) ──
        if command -v figlet &>/dev/null
            set -l fig_lines (figlet -f small "eprahemi" | string split "\n")
            for fl in $fig_lines
                if test -n "$fl"
                    set -l fl_trim "$fl"
                    if test (string length "$fl_trim") -gt 58
                        set fl_trim (string sub -l 55 "$fl_trim")"..."
                    end
                    echo -e "  $CY║$C  $YE$fl_trim$C$(printf '%*s' (math "60 - "(string length "$fl_trim")) '')$CY║$C"
                else
                    echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                end
            end
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        end
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l s1 "  📋  USAGE"
        echo -e "  $CY║$C  $WH$s1$C$(printf '%*s' (math "60 - "(string length "$s1")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l u1 "    gdm filename.jpg"
        echo -e "  $CY║$C  $CY$B$u1$C$(printf '%*s' (math "60 - "(string length "$u1")) '')$CY║$C"
        set -l u2 "    gdm /path/to/image.jpg"
        echo -e "  $CY║$C  $CY$B$u2$C$(printf '%*s' (math "60 - "(string length "$u2")) '')$CY║$C"
        set -l u3 "    gdm current"
        echo -e "  $CY║$C  $CY$B$u3$C$(printf '%*s' (math "60 - "(string length "$u3")) '')$CY║$C"
        set -l u4 "    gdm default"
        echo -e "  $CY║$C  $CY$B$u4$C$(printf '%*s' (math "60 - "(string length "$u4")) '')$CY║$C"
        set -l u5 "    gdm -y|--yes filename.jpg"
        echo -e "  $CY║$C  $CY$B$u5$C$(printf '%*s' (math "60 - "(string length "$u5")) '')$CY║$C"
        set -l u6 "    gdm info"
        echo -e "  $CY║$C  $CY$B$u6$C$(printf '%*s' (math "60 - "(string length "$u6")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l s2 "  🔥  FEATURES"
        echo -e "  $CY║$C  $WH$s2$C$(printf '%*s' (math "60 - "(string length "$s2")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l f1 "  🔍  System-wide search across 13 user folders"
        echo -e "  $CY║$C  $D$f1$C$(printf '%*s' (math "60 - "(string length "$f1")) '')$CY║$C"
        set -l f2 "  🖼️  Kitty inline image preview before applying"
        echo -e "  $CY║$C  $D$f2$C$(printf '%*s' (math "60 - "(string length "$f2")) '')$CY║$C"
        set -l f3 "  🎨  Optional blur + dark tint (ImageMagick)"
        echo -e "  $CY║$C  $D$f3$C$(printf '%*s' (math "60 - "(string length "$f3")) '')$CY║$C"
        set -l f4 "  🔄  Blur preview loop — retry until you like it"
        echo -e "  $CY║$C  $D$f4$C$(printf '%*s' (math "60 - "(string length "$f4")) '')$CY║$C"
        set -l f5 "  🏷️  Multi-match picker — pick 1/2/3 from all results"
        echo -e "  $CY║$C  $D$f5$C$(printf '%*s' (math "60 - "(string length "$f5")) '')$CY║$C"
        set -l f6 "  ⚡  -y / --yes flag to skip all prompts + blur"
        echo -e "  $CY║$C  $D$f6$C$(printf '%*s' (math "60 - "(string length "$f6")) '')$CY║$C"
        set -l f7 "  🔁  gdm default — restore Himeno login screen"
        echo -e "  $CY║$C  $D$f7$C$(printf '%*s' (math "60 - "(string length "$f7")) '')$CY║$C"
        set -l f8 "  🖥️  gdm current — use current desktop wallpaper"
        echo -e "  $CY║$C  $D$f8$C$(printf '%*s' (math "60 - "(string length "$f8")) '')$CY║$C"
        set -l f9 "  ℹ️   gdm info — show last applied GDM wallpaper details"
        echo -e "  $CY║$C  $D$f9$C$(printf '%*s' (math "60 - "(string length "$f9")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l s3 "  🎨  BLUR SYSTEM"
        echo -e "  $CY║$C  $WH$s3$C$(printf '%*s' (math "60 - "(string length "$s3")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l bl1 "  Default   → -blur 0x40  +  40% black tint"
        echo -e "  $CY║$C  $D$bl1$C$(printf '%*s' (math "60 - "(string length "$bl1")) '')$CY║$C"
        set -l bl2 "  Custom    → choose sigma (20-50) + tint % (20-40)"
        echo -e "  $CY║$C  $D$bl2$C$(printf '%*s' (math "60 - "(string length "$bl2")) '')$CY║$C"
        set -l bl3 "  Preview   → see result in Kitty, say N to retry"
        echo -e "  $CY║$C  $D$bl3$C$(printf '%*s' (math "60 - "(string length "$bl3")) '')$CY║$C"
        set -l bl4 "  No Kitty  → \"Continue / Try again\" text prompt"
        echo -e "  $CY║$C  $D$bl4$C$(printf '%*s' (math "60 - "(string length "$bl4")) '')$CY║$C"
        set -l bl5 "  No Magick → auto-offer to install it for you"
        echo -e "  $CY║$C  $D$bl5$C$(printf '%*s' (math "60 - "(string length "$bl5")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l s4 "  📝  EXAMPLES"
        echo -e "  $CY║$C  $GR$s4$C$(printf '%*s' (math "60 - "(string length "$s4")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l e1 "  gdm my-image.jpg"
        echo -e "  $CY║$C  $CY$e1$C$(printf '%*s' (math "60 - "(string length "$e1")) '')$CY║$C"
        set -l e2 "  gdm ~/Pictures/my-wallpaper.jpg"
        echo -e "  $CY║$C  $CY$e2$C$(printf '%*s' (math "60 - "(string length "$e2")) '')$CY║$C"
        set -l e3 "  gdm HOT PUSSASS.jpg"
        echo -e "  $CY║$C  $CY$e3$C$(printf '%*s' (math "60 - "(string length "$e3")) '')$CY║$C"
        set -l e4 "  gdm -y ~/Pictures/definite.jpg"
        echo -e "  $CY║$C  $CY$e4$C$(printf '%*s' (math "60 - "(string length "$e4")) '')$CY║$C"
        set -l e5 "  gdm default"
        echo -e "  $CY║$C  $CY$e5$C$(printf '%*s' (math "60 - "(string length "$e5")) '')$CY║$C"
        set -l e6 "  gdm current"
        echo -e "  $CY║$C  $CY$e6$C$(printf '%*s' (math "60 - "(string length "$e6")) '')$CY║$C"
        set -l e7 "  gdm info"
        echo -e "  $CY║$C  $CY$e7$C$(printf '%*s' (math "60 - "(string length "$e7")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l s5 "  💡  NOTES"
        echo -e "  $CY║$C  $WH$s5$C$(printf '%*s' (math "60 - "(string length "$s5")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l n1 "  • Spaces in names work: gdm HOT PUSS.jpg"
        echo -e "  $CY║$C  $D$n1$C$(printf '%*s' (math "60 - "(string length "$n1")) '')$CY║$C"
        set -l n2 "  • Reboot required for GDM changes to take effect"
        echo -e "  $CY║$C  $D$n2$C$(printf '%*s' (math "60 - "(string length "$n2")) '')$CY║$C"
        set -l n3 "  • Internet only needed ONCE (first run clones repo)"
        echo -e "  $CY║$C  $D$n3$C$(printf '%*s' (math "60 - "(string length "$n3")) '')$CY║$C"
        set -l n4 "  • Works 100% offline after repo is cached"
        echo -e "  $CY║$C  $D$n4$C$(printf '%*s' (math "60 - "(string length "$n4")) '')$CY║$C"
        set -l n5 "  • Kitty + ImageMagick are optional, not required"
        echo -e "  $CY║$C  $D$n5$C$(printf '%*s' (math "60 - "(string length "$n5")) '')$CY║$C"
        set -l n6 "  • Auto-detects missing git, curl, ImageMagick — offers install"
        echo -e "  $CY║$C  $D$n6$C$(printf '%*s' (math "60 - "(string length "$n6")) '')$CY║$C"
        set -l n7 "  • Zero hardcoded paths — 100% portable"
        echo -e "  $CY║$C  $D$n7$C$(printf '%*s' (math "60 - "(string length "$n7")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l br "  eprahemi  •  github.com/eprahemi"
        echo -e "  $CY║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
        echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
        echo ""
        return 0
    end

    # ── Parse -y / --yes flag ──
    if contains -- "$argv[1]" "-y" "--yes"
        set skip_confirm 1
        set -e argv[1]
        # Guard: -y / --yes with no image after it
        if not set -q argv[1]
            echo -e "$RE✘$C Usage: $CY$B gdm [-y|--yes] /path/to/wallpaper.jpg$C"
            echo -e "  $D  You used -y but forgot an image path.$C"
            echo -e "  $GY  github.com/eprahemi$C"
            return 1
        end
    end

    # ── "current" subcommand: use current desktop wallpaper ──
    if set -q argv[1]; and contains -- "$argv[1]" "current" "--current"
        set -e argv[1]
        set -l C  "\033[0m"
        set -l CY "\033[1;36m"
        set -l GR "\033[1;32m"
        set -l YE "\033[1;33m"
        set -l RE "\033[1;31m"
        set -l GY "\033[38;5;248m"
        set -l WH "\033[1;37m"
        set -l D  "\033[2m"

        # Get current desktop wallpaper URI from GNOME gsettings
        set -l bg_uri (gsettings get org.gnome.desktop.background picture-uri 2>/dev/null)

        if test -z "$bg_uri"
            echo -e "  $RE✘  No desktop wallpaper detected.$C"
            echo -e "  $GY  Set one in Settings → Background first.$C"
            echo -e "  $GY  github.com/eprahemi$C"
            return 1
        end

        # Strip 'file://' prefix and quotes: 'file:///path/img.jpg' → /path/img.jpg
        set -l bg_uri_s (string trim -c "'" "$bg_uri")
        set -l bg_path_raw (string replace -r '^file://' '' "$bg_uri_s")
        # URL-decode (%20 → space, %23 → #, etc.)
        set -l bg_path "$bg_path_raw"
        if command -v python3 &>/dev/null
            set bg_path (python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.argv[1]))" "$bg_path_raw" 2>/dev/null)
        end

        if not test -f "$bg_path"
            echo -e "  $RE✘  Wallpaper file not found: $YE$bg_path$C"
            echo -e "  $GY  The file may have been moved or deleted.$C"
            echo -e "  $GY  github.com/eprahemi$C"
            return 1
        end

        # ── Show confirm box ──
        echo ""
        echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l cc1 "  🖼️  CURRENT DESKTOP WALLPAPER"
        echo -e "  $CY║$C  $WH$cc1$C$(printf '%*s' (math "60 - "(string length "$cc1")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"

        set -l cc2_len (string length "$bg_path")
        set -l cc2_disp "$bg_path"
        if test $cc2_len -gt 56
            set cc2_disp (string sub -l 53 "$bg_path")"..."
            set cc2_len 56
        end
        echo -e "  $CY║$C    $YE$cc2_disp$C$(printf '%*s' (math "58 - $cc2_len") '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l cc3 "  [Y] Yes → Apply + blur options"
        echo -e "  $CY║$C  $GR$cc3$C$(printf '%*s' (math "60 - "(string length "$cc3")) '')$CY║$C"
        set -l cc4 "  [N] No  → Cancel"
        echo -e "  $CY║$C  $RE$cc4$C$(printf '%*s' (math "60 - "(string length "$cc4")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l br "  eprahemi  •  github.com/eprahemi"
        echo -e "  $CY║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
        echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
        echo ""

        # ── Preview in Kitty ──
        if test -n "$KITTY_PID"
            kitty +kitten icat --align left "$bg_path" 2>/dev/null
            echo ""
        end

        read -l -P "  [Y/n]: " current_confirm
        if not test -z "$current_confirm"; and not string match -qir '^y' "$current_confirm"
            echo -e "  $RE✘  Cancelled. Run $CY$B gdm$C $RE again — github.com/eprahemi$C"
            return 1
        end

        # Set up for blur/apply — skip redundant DO YOU MEAN THIS? but keep blur
        echo -e "  $D  Using current desktop wallpaper: $bg_path$C"
        set skip_double_confirm 1
        set argv[1] "$bg_path"
        # Fall through → default check (won't match) → search → blur → apply
    end

    # ── "default" subcommand: restore Himeno login wallpaper ──
    if set -q argv[1]; and contains -- "$argv[1]" "default" "--default"
        set -e argv[1]
        set -l C  "\033[0m"
        set -l CY "\033[1;36m"
        set -l GR "\033[1;32m"
        set -l YE "\033[1;33m"
        set -l RE "\033[1;31m"
        set -l GY "\033[38;5;248m"
        set -l D  "\033[2m"
        set -l wp_bg "$HOME/.local/share/backgrounds/Himeno Fedora LoginScreen.jpg"
        set -l wp_repo "$HOME/.local/share/mactahoe-gtk/himeno-login.jpg"
        set -l wp_url "https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/wallpapers/login/Himeno%20Fedora%20LoginScreen.jpg"

        if test -f "$wp_bg"
            echo -e "  $D🖼️  Found Himeno login wallpaper in ~/.local/share/backgrounds/$C"
            gdm --yes "$wp_bg"
        else if test -f "$wp_repo"
            echo -e "  $D🖼️  Found Himeno login wallpaper in cached repo$C"
            gdm --yes "$wp_repo"
        else
            echo ""
            echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY║$C  $WH🌐  DOWNLOADING HIMENO LOGIN WALLPAPER$C                    $CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY║$C  $D  Himeno wallpaper not found locally.$C                          $CY║$C"
            echo -e "  $CY║$C  $D  Downloading from the Fedora MacTahoe repo...$C                 $CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY║$C  $YE  📦  Saving to ~/.local/share/mactahoe-gtk/$C                   $CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
            echo ""
            mkdir -p "$HOME/.local/share/mactahoe-gtk"
            if not curl -fsSL "$wp_url" -o "$wp_repo" 2>/dev/null
                echo -e "  $RE✘  Download failed — no internet?$C"
                echo -e "  $GY  Run gdm with any image, or connect to the internet.$C"
                return 1
            end
            echo -e "  $GR✅  Himeno login wallpaper saved to repo$C"
            gdm --yes "$wp_repo"
        end
        return $status
    end

    # ── "info" subcommand: beautiful GDM wallpaper details with preview ──
    if set -q argv[1]; and contains -- "$argv[1]" "info" "--info" "-info"
        set -e argv[1]
        set -l last_file "$HOME/.local/share/mactahoe-gtk/.gdm-undo-copy.jpg"
        if not test -f "$last_file"
            echo -e "  $RE✘  No GDM wallpaper info available.$C"
            echo -e "  $GY  Apply a wallpaper first with $CY$B gdm filename.jpg$C"
            echo -e "  $GY  github.com/eprahemi$C"
            return 1
        end

        # ─── Gather metadata ───
        set -l f_bytes (command -v stat &>/dev/null; and stat -c "%s" "$last_file" 2>/dev/null; or echo "?")
        set -l f_dims (command -v identify &>/dev/null; and magick identify -format "%wx%h" "$last_file" 2>/dev/null; or echo "?x?")
        set -l f_mtime (command -v stat &>/dev/null; and stat -c "%y" "$last_file" 2>/dev/null | string sub -l 16; or echo "?")

        # Human-readable size with python3 rounding
        set -l f_size "$f_bytes B"
        if command -v python3 &>/dev/null; and test "$f_bytes" != "?"
            set f_size (python3 -c "
import sys
n = int(sys.argv[1])
if n >= 1073741824:
    print(f'{n/1073741824:.1f} GB')
elif n >= 1048576:
    print(f'{n/1048576:.1f} MB')
elif n >= 1024:
    print(f'{n/1024:.1f} KB')
else:
    print(f'{n} B')
" "$f_bytes")
        end

        # Format date: "2026-06-26 14:32" → "26 Jun 2026  14:32"
        set -l f_date "$f_mtime"
        if command -v python3 &>/dev/null; and test "$f_mtime" != "?"
            set f_date (python3 -c "
import sys
from datetime import datetime
try:
    dt = datetime.strptime(sys.argv[1].strip(), '%Y-%m-%d %H:%M')
    print(dt.strftime('%d %b %Y  %H:%M'))
except:
    print(sys.argv[1])
" "$f_mtime")
        end

        # ─── Split path ───
        set -l f_dir (dirname "$last_file")
        set -l f_name (basename "$last_file")
        set f_dir (string replace -r "^$HOME" "~" "$f_dir")

        # ─── Kitty image preview (before the info box) ───
        if test -n "$KITTY_PID"
            echo ""
            echo -e "  $CY┌── $WH🖼️  WALLPAPER PREVIEW $D(Kitty)$C$(printf '%*s' 27 '')$CY──┐$C"
            kitty +kitten icat --align left "$last_file" 2>/dev/null
            echo -e "  $CY└$(printf '%*s' 58 '')┘$C"
            echo ""
        end

        # ═══════════════════════════════════════════════════════════════
        # INFO BOX — nested details section
        # All lines: 62 chars between ║
        #   ║    ┌─...─┐  ║  (4 left + box + 2 right = 62)
        #   ║    │      │  ║  (4 + 1 + cont + 2 + 1 + 2 = 62)
        #   ║    └─...─┘  ║  (4 + 1 + n + 1 + 2 = 62, n=54)
        # ═══════════════════════════════════════════════════════════════
        echo ""
        echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l i_title "  🖼️  LAST APPLIED GDM WALLPAPER"
        echo -e "  $CY║$C  $WH$i_title$C$(printf '%*s' (math "60 - "(string length "$i_title")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"

        # ── Nested info frame (54 ─ wide, ┐ at 59, │ at 59) ──
        echo -e "  $CY║$C    $D┌──────────────────────────────────────────────────────┐$C  $CY║$C"
        echo -e "  $CY║$C    $D│$C  $WH📄  FILE$C$(printf '%*s' 45 '')$D│$C  $CY║$C"

        # Dir line
        set -l f_dir_label "📂  Dir "
        set -l f_dir_val "$f_dir/"
        set -l f_dir_full "$f_dir_label$f_dir_val"
        set -l f_dir_len (string length -- "$f_dir_full")
        set -l f_dir_pad (math "50 - $f_dir_len")
        if test $f_dir_pad -lt 0; set f_dir_pad 0; end
        echo -e "  $CY║$C    $D│$C  $D$f_dir_label$C$GY$f_dir_val$C$(printf '%*s' $f_dir_pad '')$D│$C  $CY║$C"

        # File line
        set -l f_file_label "📎  File "
        set -l f_file_full "$f_file_label$f_name"
        set -l f_file_len (string length -- "$f_file_full")
        set -l f_file_pad (math "50 - $f_file_len")
        if test $f_file_pad -lt 0; set f_file_pad 0; end
        echo -e "  $CY║$C    $D│$C  $D$f_file_label$C$YE$f_name$C$(printf '%*s' $f_file_pad '')$D│$C  $CY║$C"

        # Separator inside frame
        echo -e "  $CY║$C    $D│$C$(printf '%*s' 52 '')$D│$C  $CY║$C"

        # Size + Dims on one line (two columns)
        set -l size_label "💾  Size "
        set -l dims_label "📐  Dims "
        set -l left_col "$size_label$CY$f_size$C"
        set -l right_col "$dims_label$GR$f_dims$C"
        # Left part: label + value (padded to ~26)
        set -l left_full "$size_label$f_size"
        set -l left_len (string length -- "$left_full")
        set -l left_pad (math "26 - $left_len")
        if test $left_pad -lt 0; set left_pad 0; end
        set -l l_part "$D$size_label$C$CY$f_size$C$(printf '%*s' $left_pad '')"
        set -l r_part "$D$dims_label$C$GR$f_dims$C"
        set -l row_full "$size_label$f_size$dims_label$f_dims"
        set -l row_len (string length -- "$row_full")
        set -l row_pad (math "50 - $row_len")
        if test $row_pad -lt 0; set row_pad 0; end
        echo -e "  $CY║$C    $D│$C  $D$size_label$C$CY$f_size$C  $D$dims_label$C$GR$f_dims$C$(printf '%*s' $row_pad '')$D│$C  $CY║$C"

        # Date line
        set -l date_label "🕒  Added "
        set -l date_full "$date_label$f_date"
        set -l date_len (string length -- "$date_full")
        set -l date_pad (math "50 - $date_len")
        if test $date_pad -lt 0; set date_pad 0; end
        echo -e "  $CY║$C    $D│$C  $D$date_label$C$f_date$C$(printf '%*s' $date_pad '')$D│$C  $CY║$C"

        # Frame bottom
        echo -e "  $CY║$C    $D└──────────────────────────────────────────────────────┘$C  $CY║$C"

        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l br "  eprahemi  •  github.com/eprahemi"
        echo -e "  $CY║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
        echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
        echo ""
        return 0
    end

    # ── Join all args so unquoted filenames with spaces work ──
    #     e.g. `gdm HOT PUSSASS.jpg` from inside the folder
    if not set -q argv[1]
        echo -e "$RE✘$C Usage: $CY$B gdm [-y|--yes] /path/to/wallpaper.jpg$C"
        echo -e "  $GY  github.com/eprahemi$C"
        return 1
    end
    set -l filename (string join ' ' -- $argv)

    # ══════════════════════════════════════════════════════════════
    # 🔍  SEARCH ENGINE — finds the image everywhere
    # ══════════════════════════════════════════════════════════════
    set -l image ""
    set -l results

    # 1. Try direct path first
    set -l direct (realpath "$filename" 2>/dev/null)
    if test -f "$direct"
        set results "$direct"
    else
        # 2. Search common user directories
        echo -e "  $D🔍  Searching for \"$filename\"...$C  $GY eprahemi$C"
        set -l search_dirs \
            "$HOME/.local/share/backgrounds" \
            "$HOME/Pictures/Wallpapers" \
            "$HOME/Pictures" \
            "$HOME/Downloads" \
            "$HOME/Desktop" \
            "$HOME/Documents" \
            "$HOME/Videos" \
            "$HOME/Music" \
            "$HOME/Templates" \
            "$HOME/Public" \
            "$HOME/.local/share/wallpapers" \
            "$HOME/.local/share/mactahoe-gtk" \
            "$HOME/.config/Wallpapers"

        for dir in $search_dirs
            if test -d "$dir"
                set -l found (find "$dir" -maxdepth 5 -type f -iname "$filename" 2>/dev/null)
                if test -n "$found"
                    for f in $found
                        set -a results (realpath "$f" 2>/dev/null)
                    end
                end
            end
        end

        # 3. No exact match? Try wildcard *$filename*
        if test (count $results) -eq 0
            echo -e "  $D  No exact match — trying wildcard...  $GY eprahemi$C"
            for dir in $search_dirs
                if test -d "$dir"
                    set -l found (find "$dir" -maxdepth 5 -type f -iname "*$filename*" 2>/dev/null)
                    if test -n "$found"
                        for f in $found
                            set -a results (realpath "$f" 2>/dev/null)
                        end
                    end
                end
            end
        end

        # 4. Still nothing? Try in CWD as last resort
        if test (count $results) -eq 0
            set -l cwd_find (find (pwd) -maxdepth 1 -type f -iname "*$filename*" 2>/dev/null)
            if test -n "$cwd_find"
                for f in $cwd_find
                    set -a results (realpath "$f" 2>/dev/null)
                end
            end
        end
    end

    # Deduplicate (paths with spaces: always quote $r)
    if test (count $results) -gt 1
        set -l deduped
        for r in $results
            if not contains -- "$r" $deduped
                set -a deduped "$r"
            end
        end
        set results $deduped
    end

    set -l result_count (count $results)

    # ══════════════════════════════════════════════════════════════
    # 🎯  RESULT HANDLER — single confirm / multi picker
    # ══════════════════════════════════════════════════════════════
    switch $result_count
        case 0
            echo -e "  $RE✘$C File not found: $YE$filename$C"
            echo -e "  $GY  Searched everywhere in your home folders.$C"
            echo -e "  $GY  Tip: use the full path like $CY$B gdm /path/to/your/image.jpg$C"
            echo -e "  $GY  github.com/eprahemi$C"
            return 1

        case 1
            set image "$results[1]"
            if test $skip_confirm -eq 0; and test $skip_double_confirm -eq 0
                echo ""
                echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l c1 "  🖼️  DO YOU MEAN THIS?"
                echo -e "  $CY║$C  $WH$c1$C$(printf '%*s' (math "60 - "(string length "$c1")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l c2_len (string length "$image")
                set -l image_display "$image"
                if test $c2_len -gt 56
                    set image_display (string sub -l 53 "$image")"..."
                    set c2_len 56
                end
                echo -e "  $CY║$C    $YE$image_display$C$(printf '%*s' (math "58 - $c2_len") '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l c3 "  [Y] Yes → Apply wallpaper"
                echo -e "  $CY║$C  $GR$c3$C$(printf '%*s' (math "60 - "(string length "$c3")) '')$CY║$C"
                set -l c4 "  [N] No  → Cancel, type gdm again"
                echo -e "  $CY║$C  $RE$c4$C$(printf '%*s' (math "60 - "(string length "$c4")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l br "  eprahemi  •  github.com/eprahemi"
                echo -e "  $CY║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
                echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
                echo ""
                read -l -P "  [Y/n]: " confirm
                if not test -z "$confirm"; and not string match -qir '^y' "$confirm"
                    echo -e "  $RE✘  Cancelled. Run $CY$B gdm$C $RE again — github.com/eprahemi$C"
                    return 1
                end

                # ── Preview image in Kitty terminal (interactive only) ──
                if test -n "$KITTY_PID"
                    echo ""
                    kitty +kitten icat --align left "$image" 2>/dev/null
                    echo ""
                end
            end

        case '*'
            echo ""
            echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            set -l m1 "  🖼️  MULTIPLE MATCHES"
            echo -e "  $CY║$C  $WH$m1$C$(printf '%*s' (math "60 - "(string length "$m1")) '')$CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            set -l m2 "  File \"$filename\" found in $result_count locations:"
            set -l m2_trim "$m2"
            if test (string length "$m2_trim") -gt 60
                set m2_trim (string sub -l 57 "$m2")"..."
            end
            echo -e "  $CY║$C  $m2_trim$C$(printf '%*s' (math "60 - "(string length "$m2_trim")) '')$CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"

            for i in (seq $result_count)
                set -l path $results[$i]
                set -l disp "$path"
                if test (string length "$disp") -gt 54
                    set disp (string sub -l 51 "$disp")"..."
                end
                set -l num_str (printf "%2d" $i)
                set -l m_line "  [$num_str]  $disp"
                if test (string length "$m_line") -gt 60
                    set m_line (string sub -l 57 "$m_line")"..."
                end
                echo -e "  $CY║$C  $GR$m_line$C$(printf '%*s' (math "60 - "(string length "$m_line")) '')$CY║$C"
            end

            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            set -l m3 "  Type 1–$result_count to choose, or 'q' to cancel"
            echo -e "  $CY║$C  $WH$m3$C$(printf '%*s' (math "60 - "(string length "$m3")) '')$CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            set -l br "  eprahemi  •  github.com/eprahemi"
            echo -e "  $CY║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
            echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
            echo ""

            while true
                read -l -P "  [#]: " choice
                if string match -qir '^q' "$choice"
                    echo -e "  $RE✘  Cancelled. Run $CY$B gdm$C $RE again — github.com/eprahemi$C"
                    return 1
                end
                if string match -qr '^\d+$' "$choice"
                    set -l num (math "$choice" 2>/dev/null)
                    if test $num -ge 1 -a $num -le $result_count
                        set image "$results[$num]"

                        # ── Preview image in Kitty terminal ──
                        if test -n "$KITTY_PID"
                            echo ""
                            kitty +kitten icat --align left "$image" 2>/dev/null
                            echo ""
                        end
                        break
                    end
                end
                echo -e "  $RE  Invalid — type 1-$result_count or q.$C"
            end
    end

    # ══════════════════════════════════════════════════════════════
    # 🎨  BLUR OPTIONS — blur + dark tint before applying
    # ══════════════════════════════════════════════════════════════
    if command -v magick &>/dev/null
        if test $skip_confirm -eq 0
            set -l blurred_file "/tmp/gdm-blurred.jpg"
            set -l blur_done 0
            # Guard: /tmp must be writable for blur output
            if not touch "/tmp/.gdm-tmp-write" 2>/dev/null
                echo -e "  $D  ⚠️  Cannot write to /tmp — blur unavailable. Using original.$C  $GY github.com/eprahemi$C"
                set blur_done 1
            else
                rm -f "/tmp/.gdm-tmp-write"
            end
            mkdir -p /tmp

            while test $blur_done -eq 0
                echo ""
                echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l b1 "  🎨  BLUR BACKGROUND?"
                echo -e "  $CY║$C  $WH$b1$C$(printf '%*s' (math "60 - "(string length "$b1")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l b2 "  Add blur + dark overlay to the wallpaper?"
                echo -e "  $CY║$C  $b2$C$(printf '%*s' (math "60 - "(string length "$b2")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l b3 "  [N] No — use original image"
                echo -e "  $CY║$C  $GR$b3$C$(printf '%*s' (math "60 - "(string length "$b3")) '')$CY║$C"
                set -l b4 "  [Y] Yes — Default Blur"
                echo -e "  $CY║$C  $CY$b4$C$(printf '%*s' (math "60 - "(string length "$b4")) '')$CY║$C"
                set -l b5 "  [C] Custom — set blur sigma + tint %"
                echo -e "  $CY║$C  $YE$b5$C$(printf '%*s' (math "60 - "(string length "$b5")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l br "  eprahemi  •  github.com/eprahemi"
                echo -e "  $CY║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
                echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
                echo ""
                read -l -P "  [n/Y/c]: " blur_choice

                switch (string lower "$blur_choice")
                    case n no
                        set blur_done 1

                    case '' y yes
                        echo -e "  $D🎨  Applying default blur (0x40) + black 40%% tint...$C  $GY eprahemi$C"
                        if magick "$image" -blur 0x40 -fill black -colorize 40% "$blurred_file" 2>/dev/null
                            # ── Preview blurred result in Kitty ──
                            if test -n "$KITTY_PID"
                                echo ""
                                kitty +kitten icat --align left "$blurred_file" 2>/dev/null
                                echo ""
                            else
                                echo -e "  $D  💻  Preview requires Kitty terminal — blur applied without preview.$C"
                            end
                            # Apply immediately — no LIKE THE RESULT? prompt for default
                            set image "$blurred_file"
                            set blur_done 1
                            echo -e "  $GR✅  Default blur applied$C  github.com/eprahemi"
                        else
                            echo -e "  $RE✘  Blur failed — image may be corrupt or unsupported. Using original.$C  $GY github.com/eprahemi$C"
                            set blur_done 1
                        end

                    case c custom
                        echo ""
                        echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
                        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                        set -l cu1 "  🎨  CUSTOM BLUR"
                        echo -e "  $CY║$C  $WH$cu1$C$(printf '%*s' (math "60 - "(string length "$cu1")) '')$CY║$C"
                        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                        set -l cu2 "  Blur sigma (0=auto, try 20-50):"
                        echo -e "  $CY║$C  $D$cu2$C$(printf '%*s' (math "60 - "(string length "$cu2")) '')$CY║$C"
                        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                        set -l cu3 "  Black tint % (0-100, try 20-40):"
                        echo -e "  $CY║$C  $D$cu3$C$(printf '%*s' (math "60 - "(string length "$cu3")) '')$CY║$C"
                        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                        set -l br "  eprahemi  •  github.com/eprahemi"
                        echo -e "  $CY║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
                        echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
                        echo ""
                        read -l -P "    Blur sigma [30]: " blur_sigma
                        read -l -P "    Black tint % [30]: " colorize_pct

                        if test -z "$blur_sigma"
                            set blur_sigma 30
                        end
                        if test -z "$colorize_pct"
                            set colorize_pct 30
                        end

                        echo -e "  $D🎨  Applying blur (0x$blur_sigma) + black $colorize_pct%% tint...$C  $GY eprahemi$C"
                        if magick "$image" -blur "0x$blur_sigma" -fill black -colorize "$colorize_pct%" "$blurred_file" 2>/dev/null
                            # ── Preview blurred result in Kitty ──
                            if test -n "$KITTY_PID"
                                echo ""
                                kitty +kitten icat --align left "$blurred_file" 2>/dev/null
                                echo ""
                            end
                            # ── Ask if user likes it (only in Kitty) ──
                            if test -n "$KITTY_PID"
                                echo ""
                                echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
                                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                                set -l l1 "  👍  LIKE THE RESULT?"
                                echo -e "  $CY║$C  $WH$l1$C$(printf '%*s' (math "60 - "(string length "$l1")) '')$CY║$C"
                                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                                echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                                set -l l2 "  [Y] Yes — apply this blurred version"
                                echo -e "  $CY║$C  $GR$l2$C$(printf '%*s' (math "60 - "(string length "$l2")) '')$CY║$C"
                                set -l l3 "  [N] No  — try different blur settings"
                                echo -e "  $CY║$C  $YE$l3$C$(printf '%*s' (math "60 - "(string length "$l3")) '')$CY║$C"
                                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                                set -l br "  eprahemi  •  github.com/eprahemi"
                                echo -e "  $CY║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
                                echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
                                echo ""
                                read -l -P "  [y/N]: " like_it
                                if string match -qir '^y' "$like_it"
                                    set image "$blurred_file"
                                    set blur_done 1
                                    echo -e "  $GR✅  Custom blur applied$C  github.com/eprahemi"
                                end
                                # N → loops back to blur menu
                            else
                                set image "$blurred_file"
                                echo -e "  $D  💻  Preview requires Kitty terminal — blur applied without preview.$C"
                                echo -e "  $GR✅  Custom blur applied$C  github.com/eprahemi"
                                echo ""
                                read -l -P "  [Y] Continue  [N] Try again: " non_kitty_ok
                                if string match -qir '^n' "$non_kitty_ok"
                                    # loop back to blur menu
                                else
                                    set blur_done 1
                                end
                            end
                        else
                            echo -e "  $RE✘  Custom blur failed — image may be corrupt or unsupported. Using original.$C  $GY github.com/eprahemi$C"
                            set blur_done 1
                        end
                end
            end
        else
            set blur_choice "n"
        end
    else
        # ── ImageMagick not installed prompt ──
        if test $skip_confirm -eq 0
            echo ""
            echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            set -l mi1 "  ⚠️  IMAGEMAGICK NOT INSTALLED"
            echo -e "  $CY║$C  $WH$mi1$C$(printf '%*s' (math "60 - "(string length "$mi1")) '')$CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            set -l mi2 "  Blur + dark tint requires ImageMagick."
            echo -e "  $CY║$C  $D$mi2$C$(printf '%*s' (math "60 - "(string length "$mi2")) '')$CY║$C"
            set -l mi3 "  It is NOT installed on your system."
            echo -e "  $CY║$C  $YE$mi3$C$(printf '%*s' (math "60 - "(string length "$mi3")) '')$CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            set -l mi4 "  [Y] Yes — install it now"
            echo -e "  $CY║$C  $GR$mi4$C$(printf '%*s' (math "60 - "(string length "$mi4")) '')$CY║$C"
            set -l mi5 "  [N] No  — skip blur, use original"
            echo -e "  $CY║$C  $RE$mi5$C$(printf '%*s' (math "60 - "(string length "$mi5")) '')$CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            set -l br "  eprahemi  •  github.com/eprahemi"
            echo -e "  $CY║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
            echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
            echo ""
            read -l -P "  [y/N]: " install_magick
            if string match -qir '^y' "$install_magick"
                echo -e "  $D📦  Installing ImageMagick...$C  $GY github.com/eprahemi$C"
                if sudo dnf install -y ImageMagick 2>/dev/null
                    echo -e "  $GR✅  ImageMagick installed!$C  $GY github.com/eprahemi$C"
                    echo -e "  $GY  Run $CY$B gdm$C $GY again to use blur options.$C"
                else
                    echo -e "  $RE✘  Installation failed. Try: $CY$B sudo dnf install ImageMagick$C  $GY github.com/eprahemi$C"
                end
            else
                echo -e "  $D  Skipping blur — using original image.$C  $GY github.com/eprahemi$C"
            end
        end
    end

    # ── Persistent MacTahoe repo (kept after first clone) ──
    set -l repo "$HOME/.local/share/mactahoe-gtk"

    if not test -f "$repo/tweaks.sh"
        echo ""
        echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l i1 "  🌐  INTERNET NEEDED — ONE TIME ONLY"
        echo -e "  $CY║$C  $WH$i1$C$(printf '%*s' (math "60 - "(string length "$i1")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l i2 "  This is the first time you're running gdm."
        echo -e "  $CY║$C  $D$i2$C$(printf '%*s' (math "60 - "(string length "$i2")) '')$CY║$C"
        set -l i3 "  It needs to download the MacTahoe theme repo"
        echo -e "  $CY║$C  $D$i3$C$(printf '%*s' (math "60 - "(string length "$i3")) '')$CY║$C"
        set -l i4 "  to set up the GDM theme engine."
        echo -e "  $CY║$C  $D$i4$C$(printf '%*s' (math "60 - "(string length "$i4")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l i5 "  📦  Downloading ~5 MB to ~/.local/share/mactahoe-gtk"
        echo -e "  $CY║$C  $YE$i5$C$(printf '%*s' (math "60 - "(string length "$i5")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l i6 "  ✅  After this, gdm works OFFLINE forever"
        echo -e "  $CY║$C  $GR$i6$C$(printf '%*s' (math "60 - "(string length "$i6")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l br "  eprahemi  •  github.com/eprahemi"
        echo -e "  $CY║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
        echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
        echo ""

        mkdir -p "$HOME/.local/share"
        rm -rf "$repo"

        # ── Guard: git must be installed ──
        if not command -v git &>/dev/null
            echo ""
            echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            set -l gi1 "  ⚠️  GIT NOT INSTALLED"
            echo -e "  $CY║$C  $YE$gi1$C$(printf '%*s' (math "60 - "(string length "$gi1")) '')$CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            set -l gi2 "  git is required to download the theme repo."
            echo -e "  $CY║$C  $D$gi2$C$(printf '%*s' (math "60 - "(string length "$gi2")) '')$CY║$C"
            set -l gi3 "  It is NOT installed on your system."
            echo -e "  $CY║$C  $YE$gi3$C$(printf '%*s' (math "60 - "(string length "$gi3")) '')$CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            set -l gi4 "  [Y] Yes — install git now"
            echo -e "  $CY║$C  $GR$gi4$C$(printf '%*s' (math "60 - "(string length "$gi4")) '')$CY║$C"
            set -l gi5 "  [N] No  — cancel"
            echo -e "  $CY║$C  $RE$gi5$C$(printf '%*s' (math "60 - "(string length "$gi5")) '')$CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            set -l br "  eprahemi  •  github.com/eprahemi"
            echo -e "  $CY║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
            echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
            echo ""
            read -l -P "  [y/N]: " install_git
            if string match -qir '^y' "$install_git"
                echo -e "  $D📦  Installing git...$C  $GY github.com/eprahemi$C"
                if not sudo dnf install -y git 2>/dev/null
                    echo -e "  $RE✘  Git installation failed. Try: $CY$B sudo dnf install git$C"
                    return 1
                end
                echo -e "  $GR✅  git installed!$C"
            else
                echo -e "  $RE✘  Cancelled — git is required.$C  $GY github.com/eprahemi$C"
                return 1
            end
        end

        if not git clone --depth 1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$repo" 2>/dev/null
            echo -e "  $RE✘  Clone failed — no internet?$C  $GY github.com/eprahemi$C"
            echo -e "  $GY  Run the full installer first, or connect to the internet once.$C"
            return 1
        end
        echo -e "  $GR✅  Repo cached at $repo (works offline from now on)$C  $GY github.com/eprahemi$C"

        # ── Also download the Himeno default login wallpaper ──
        if command -v curl &>/dev/null
            echo -e "  $D📥  Downloading default Himeno login wallpaper...$C  $GY eprahemi$C"
            curl -fsSL "https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/wallpapers/login/Himeno%20Fedora%20LoginScreen.jpg" -o "$repo/himeno-login.jpg" 2>/dev/null
            and echo -e "  $GR✅  Himeno wallpaper saved to repo$C  $GY github.com/eprahemi$C"
            or echo -e "  $D  (skipped — not critical)$C"
        else
            echo -e "  $D  ⚠️  curl not installed — skipping himeno download.$C  $GY github.com/eprahemi$C"
        end
    end

    # ══════════════════════════════════════════════════════════════
    # 🔄  JPEG CONVERSION — ensure GDM-compatible format (any → jpg)
    # ══════════════════════════════════════════════════════════════
    if command -v magick &>/dev/null
        set -l ext (string lower (string replace -r '.*\.' '' "$image" 2>/dev/null) 2>/dev/null)
        if not contains -- "$ext" "jpg" "jpeg"
            set -l converted "/tmp/gdm-converted.jpg"
            if touch "/tmp/.gdm-conv-write" 2>/dev/null
                rm -f "/tmp/.gdm-conv-write"
                echo -e "  $D🔄  Converting $ext → JPEG 90%% quality...$C  $GY eprahemi$C"
                if magick "$image" -quality 90 "$converted" 2>/dev/null
                    set image "$converted"
                    echo -e "  $GR✅  Converted to JPEG$C  github.com/eprahemi"
                else
                    echo -e "  $D  ⚠️  JPEG conversion failed, using original.$C  $GY github.com/eprahemi$C"
                end
            else
                echo -e "  $D  ⚠️  Cannot write to /tmp — skipping JPEG conversion.$C  $GY github.com/eprahemi$C"
            end
        end
    else
        echo -e "  $D  ⚠️  ImageMagick not installed — skipping JPEG conversion.$C  $GY github.com/eprahemi$C"
    end

    # ── Apply the wallpaper ──
    # Guard: sudo must be installed
    if not command -v sudo &>/dev/null
        echo -e "  $RE✘  sudo is required but not installed.$C"
        echo -e "  $GY  Install it and try again.  github.com/eprahemi$C"
        return 1
    end
    # Save a copy for 'gdm info'
    mkdir -p "$repo"
    cp "$image" "$repo/.gdm-undo-copy.jpg"
    echo -e "  $CY🖼️  Applying GDM wallpaper...$C  $D github.com/eprahemi$C"
    cd "$repo"
    sudo ./tweaks.sh -g -nb -nd -b "$image"
    cd -

    echo -e "  $GR✅  GDM wallpaper updated!$C  $D Reboot to see it.$C"
    echo -e "  $GY  eprahemi  •  github.com/eprahemi$C"
end
