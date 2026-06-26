# ══════════════════════════════════════════════════════════════
# gdm — GDM login wallpaper switcher with blur, preview, and search
# Fedora MacTahoe eprahemi Edition © 2026
# github.com/eprahemi
# ══════════════════════════════════════════════════════════════
function gdm --description 'Change GDM login screen wallpaper — needs internet only the first time — github.com/eprahemi/FedoraTahoe-GDM'
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
        set -l n5c "    gdm save"
        echo -e "  $CY║$C  $CY$B$n5c$C$(printf '%*s' (math "60 - "(string length "$n5c")) '')$CY║$C"
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
        set -l u7 "    gdm save"
        echo -e "  $CY║$C  $CY$B$u7$C$(printf '%*s' (math "60 - "(string length "$u7")) '')$CY║$C"
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
        set -l f10 "  💾  gdm save  — save wallpaper to ~/Pictures/ (16-char encrypted name)"
        echo -e "  $CY║$C  $D$f10$C$(printf '%*s' (math "60 - "(string length "$f10")) '')$CY║$C"
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
        set -l e8 "  gdm save"
        echo -e "  $CY║$C  $CY$e8$C$(printf '%*s' (math "60 - "(string length "$e8")) '')$CY║$C"
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
        set -l n3 "  • Internet only needed ONCE (clones FedoraTahoe-GDM repo)"
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

        set -l __cc 0
        while true
            read -l -P "  [Y/n]: " current_confirm
            set -l __rs $status
            if test $__rs -ne 0
                set __cc (math $__cc + 1)
                if test $__cc -ge 2
                    echo -e "  $D  → Cancelled.  $C  $GY eprahemi$C"
                    return 1
                end
                echo -e "  $D  (Ctrl+C again to cancel)  $C  $GY eprahemi$C"
                continue
            end
            break
        end
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
        set -l wp_url "https://raw.githubusercontent.com/eprahemi/FedoraTahoe-GDM/main/himeno-login.jpg"

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
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY║$C  $D  Checking internet connection...$C                          $CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
            echo ""
            # Check internet connectivity before download attempt
            set -l has_net 0
            if command -v curl &>/dev/null
                curl -fsSL -o /dev/null --connect-timeout 5 "https://github.com" 2>/dev/null
                and set has_net 1
            else if command -v ping &>/dev/null
                ping -c 1 -W 5 "github.com" 2>/dev/null
                and set has_net 1
            end
            if test $has_net -eq 0
                echo ""
                echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l ni1 "  🌐  INTERNET NEEDED"
                echo -e "  $RE║$C  $WH$ni1$C$(printf '%*s' (math "60 - "(string length "$ni1")) '')$RE║$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                echo -e "  $RE╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l ni2 "  The default Himeno wallpaper was not found"
                set -l ni3 "  locally, and an internet connection is"
                set -l ni4 "  required to download it from the repo."
                echo -e "  $RE║$C  $D$ni2$C$(printf '%*s' (math "60 - "(string length "$ni2")) '')$RE║$C"
                echo -e "  $RE║$C  $D$ni3$C$(printf '%*s' (math "60 - "(string length "$ni3")) '')$RE║$C"
                echo -e "  $RE║$C  $D$ni4$C$(printf '%*s' (math "60 - "(string length "$ni4")) '')$RE║$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l ni5 "  Connect to the internet, or apply a custom"
                set -l ni6 "  wallpaper instead:"
                set -l ni7 "    gdm /path/to/your/image.jpg"
                echo -e "  $RE║$C  $YE$ni5$C$(printf '%*s' (math "60 - "(string length "$ni5")) '')$RE║$C"
                echo -e "  $RE║$C  $YE$ni6$C$(printf '%*s' (math "60 - "(string length "$ni6")) '')$RE║$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                echo -e "  $RE║$C  $CY$ni7$C$(printf '%*s' (math "60 - "(string length "$ni7")) '')$RE║$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l br "  eprahemi  •  github.com/eprahemi"
                echo -e "  $RE║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
                echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
                echo ""
                return 1
            end
            echo ""
            echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY║$C  $WH🌐  DOWNLOADING HIMENO LOGIN WALLPAPER$C                    $CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY║$C  $D  Downloading from FedoraTahoe-GDM repo...$C                $CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY║$C  $YE  📦  Saving to ~/.local/share/mactahoe-gtk/$C              $CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
            echo ""
            mkdir -p "$HOME/.local/share/mactahoe-gtk"
            if not curl -fsSL "$wp_url" -o "$wp_repo" 2>/dev/null
                echo -e "  $RE✘  Download failed — no internet?$C"
                echo -e "  $GY  Run gdm with any image, or connect to the internet.$C"
                echo -e "  $GY  github.com/eprahemi/FedoraTahoe-GDM$C"
                return 1
            end
            echo -e "  $GR✅  Himeno login wallpaper saved to repo$C"
            gdm --yes "$wp_repo"
        end
        return $status
    end

    # ── "save" subcommand: save current wallpaper to ~/Pictures/ ──
    if set -q argv[1]; and contains -- "$argv[1]" "save" "--save" "-save"
        set -e argv[1]
        set -l repo_dir "$HOME/.local/share/mactahoe-gtk"
        set -l last_file "$repo_dir/.gdm-undo-copy.jpg"
        if not test -f "$last_file"
            echo ""
            echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l sv_e1 "  ✘  NO WALLPAPER TO SAVE"
            echo -e "  $RE║$C  $WH$sv_e1$C$(printf '%*s' (math "60 - "(string length "$sv_e1")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            echo -e "  $RE╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l sv_e2 "  You haven't applied any wallpaper yet."
            echo -e "  $RE║$C  $D$sv_e2$C$(printf '%*s' (math "60 - "(string length "$sv_e2")) '')$RE║$C"
            set -l sv_e3 "  Apply one first:"
            echo -e "  $RE║$C  $D$sv_e3$C$(printf '%*s' (math "60 - "(string length "$sv_e3")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l sv_e4 "    gdm filename.jpg"
            echo -e "  $RE║$C  $CY$sv_e4$C$(printf '%*s' (math "60 - "(string length "$sv_e4")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l br "  eprahemi  •  github.com/eprahemi"
            echo -e "  $RE║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
            echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
            echo ""
            return 1
        end
        # File exists — now check if it's empty (corrupt / 0 bytes)
        if not test -s "$last_file"
            set -l zero_size (stat -c "%s" "$last_file" 2>/dev/null)
            if test -z "$zero_size"
                set zero_size "0"
            end
            echo ""
            echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l sv_c1 "  ⚠️  WALLPAPER FILE IS EMPTY"
            echo -e "  $RE║$C  $WH$sv_c1$C$(printf '%*s' (math "60 - "(string length "$sv_c1")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            echo -e "  $RE╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l sv_c2 "  The saved wallpaper is $zero_size bytes — it may be"
            set -l sv_c3 "  corrupted. Apply a new wallpaper to fix it."
            echo -e "  $RE║$C  $D$sv_c2$C$(printf '%*s' (math "60 - "(string length "$sv_c2")) '')$RE║$C"
            echo -e "  $RE║$C  $D$sv_c3$C$(printf '%*s' (math "60 - "(string length "$sv_c3")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l sv_c4 "    gdm filename.jpg"
            echo -e "  $RE║$C  $CY$sv_c4$C$(printf '%*s' (math "60 - "(string length "$sv_c4")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l br "  eprahemi  •  github.com/eprahemi"
            echo -e "  $RE║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
            echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
            echo ""
            return 1
        end

        # Generate 16-char encrypted-like name with timestamp meaning
        # First ~6 chars = current Unix timestamp in base36 (looks random, decodes to date)
        # Remaining ~10 chars = pure random
        set -l ts_b36 (python3 -c "
import sys
n = int(__import__('time').time())
alpha = '0123456789abcdefghijklmnopqrstuvwxyz'
res = ''
while n > 0:
    res = alpha[n % 36] + res
    n //= 36
print(res or '0')
" 2>/dev/null)
        if test -z "$ts_b36"; or test "$ts_b36" = "0"
            set ts_b36 "000000"
        end
        set -l ts_len (string length -- "$ts_b36")
        set -l rand_needed (math "16 - $ts_len")
        if test $rand_needed -lt 0
            set ts_b36 (string sub -l 16 "$ts_b36")
            set rand_needed 0
        end
        set -l rand_part ""
        if test $rand_needed -gt 0
            set rand_part (python3 -c "
import secrets, string
print(''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range($rand_needed)))
" 2>/dev/null)
        end
        set -l rand_name "$ts_b36$rand_part"
        if test -z "$rand_name"; or test (string length -- "$rand_name") -lt 16
            # Fallback: generate fully random 16-char
            set rand_name (tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 16)
            if test -z "$rand_name"
                set rand_name "GDM_Save_Unknown"
            end
        end

        set -l dest_dir "$HOME/Pictures"
        mkdir -p "$dest_dir"
        set -l dest_file "$dest_dir/$rand_name.jpg"

        # Copy with overwrite protection (append number if exists)
        set -l counter 1
        set -l try_file "$dest_file"
        while test -f "$try_file"
            set try_file (string join '' "$dest_dir/" "$rand_name" "_$counter.jpg")
            set counter (math "$counter + 1")
        end
        set dest_file "$try_file"

        cp "$last_file" "$dest_file"

        # Show beautiful save confirmation box
        echo ""
        echo -e "  $GR╔══════════════════════════════════════════════════════════════╗$C"
        echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
        set -l sv1 "  💾  WALLPAPER SAVED"
        echo -e "  $GR║$C  $WH$sv1$C$(printf '%*s' (math "60 - "(string length "$sv1")) '')$GR║$C"
        echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
        echo -e "  $GR╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"

        set -l sv2 "  📁  Saved to:"
        echo -e "  $GR║$C  $D$sv2$C$(printf '%*s' (math "60 - "(string length "$sv2")) '')$GR║$C"
        set -l sv3 "  $dest_file"
        set -l sv3_len (string length -- "$sv3")
        if test $sv3_len -gt 54
            set sv3 (string sub -l 51 "$sv3")"..."
            set sv3_len 54
        end
        echo -e "  $GR║$C    $CY$sv3$C$(printf '%*s' (math "58 - $sv3_len") '')$GR║$C"
        echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"

        set -l sv4 "  🔐  Filename:  $WH$B$rand_name.jpg$C"
        set -l sv4_plain "  🔐  Filename:  $rand_name.jpg"
        set -l sv4_len (string length -- "$sv4_plain")
        echo -e "  $GR║$C  $D$sv4$C$(printf '%*s' (math "60 - $sv4_len - 1") '')$GR║$C"
        echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"

        # Show decoded date as a nice detail
        set -l decoded_date (python3 -c "
import sys, time
alpha = '0123456789abcdefghijklmnopqrstuvwxyz'
try:
    n = 0
    for c in '$ts_b36':
        n = n * 36 + alpha.index(c)
    print(time.strftime('%d %b %Y  %H:%M', time.localtime(n)))
except:
    print('')
" 2>/dev/null)
        if test -n "$decoded_date"
            set -l sv5 "  🕒  Applied:  $D$decoded_date$C"
            set -l sv5_plain "  🕒  Applied:  $decoded_date"
            set -l sv5_len (string length -- "$sv5_plain")
            echo -e "  $GR║$C  $sv5$(printf '%*s' (math "60 - $sv5_len - 1") '')$GR║$C"
            echo -e "  $GR║$C$(printf '%*s' 62 '')$GR║$C"
        end

        set -l br "  eprahemi  •  github.com/eprahemi"
        echo -e "  $GR║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$GR║$C"
        echo -e "  $GR╚══════════════════════════════════════════════════════════════╝$C"
        echo ""
        return 0
    end

    # ── "info" subcommand: beautiful GDM wallpaper details with preview ──
    if set -q argv[1]; and contains -- "$argv[1]" "info" "--info" "-info"
        set -e argv[1]
        set -l repo_dir "$HOME/.local/share/mactahoe-gtk"
        set -l last_file "$repo_dir/.gdm-undo-copy.jpg"
        if not test -f "$last_file"
            echo -e "  $RE✘  No GDM wallpaper info available.$C"
            echo -e "  $GY  Apply a wallpaper first with $CY$B gdm filename.jpg$C"
            echo -e "  $GY  github.com/eprahemi$C"
            return 1
        end
        if not test -s "$last_file"
            echo -e "  $RE✘  Saved wallpaper is empty (0 bytes) — corrupted.$C"
            echo -e "  $GY  Apply a new wallpaper to rebuild the cache.$C"
            echo -e "  $GY  github.com/eprahemi$C"
            return 1
        end

        # ─── Initialize metadata variables (function-scoped) ───
        set -l fmt "?"; set -l csp "?"; set -l dep "?"
        set -l dims "?x?"; set -l dpi "?"; set -l mp "?"
        set -l aspect "?"; set -l blur "?"; set -l source "?"
        set -l gdm_size "?"; set -l gdm_date "?"

        set -l info_file "$repo_dir/.gdm-info.txt"
        if test -f "$info_file"
            # Parse KEY: value lines — use `set` (no -l) to modify function locals
            for pair in "FORMAT:fmt" "COLORSPACE:csp" "DEPTH:dep" "DIMS:dims" "DPI:dpi" "MP:mp" "ASPECT:aspect" "BLUR:blur" "SOURCE:source" "SIZE:gdm_size" "DATE:gdm_date" "NAME:f_name"
                set -l kv (string split ":" "$pair")
                set -l key $kv[1]
                set -l var $kv[2]
                set -l _line (string match -r "^$key: (.+)" < "$info_file" 2>/dev/null)
                if test (count $_line) -ge 2
                    set "$var" "$_line[2]"
                end
            end
        else
            # Fallback: gather from backup image
            if command -v magick &>/dev/null
                set fmt (magick identify -format "%m" "$last_file" 2>/dev/null)
                set csp (magick identify -format "%[colorspace]" "$last_file" 2>/dev/null)
                set dep (magick identify -format "%[depth]" "$last_file" 2>/dev/null)
                set dims (magick identify -format "%wx%h" "$last_file" 2>/dev/null)
                set dpi (magick identify -format "%xx%y" "$last_file" 2>/dev/null)
                # Calc MP + aspect
                if command -v python3 &>/dev/null
                    set -l w_str (string split "x" "$dims" 2>/dev/null)[1]
                    set -l h_str (string split "x" "$dims" 2>/dev/null)[2]
                    if test -n "$w_str"; and test -n "$h_str"
                        set mp (python3 -c "import sys; w=int(sys.argv[1]); h=int(sys.argv[2]); print(f'{w*h/1000000:.1f}')" "$w_str" "$h_str" 2>/dev/null)
                        set aspect (python3 -c "import sys,math; w=int(sys.argv[1]); h=int(sys.argv[2]); g=math.gcd(w,h); print(f'{w//g}:{h//g}')" "$w_str" "$h_str" 2>/dev/null)
                    end
                end
            end
            if command -v stat &>/dev/null
                set -l f_bytes (stat -c "%s" "$last_file" 2>/dev/null)
                if command -v python3 &>/dev/null; and test -n "$f_bytes"
                    set gdm_size (python3 -c "import sys; n=int(sys.argv[1]); print(f'{n/1048576:.1f} MB' if n>=1048576 else (f'{n/1024:.1f} KB' if n>=1024 else f'{n} B'))" "$f_bytes" 2>/dev/null)
                end
            end
            if command -v date &>/dev/null
                set gdm_date (date +"%d %b %Y  %H:%M" 2>/dev/null)
            end
        end

        # ══════════════════════════════════════════════════════════
        # 🛡️  GUARD D: Replace broken/empty/? values with "Unknown"
        # ══════════════════════════════════════════════════════════
        for __var in fmt csp dep dims dpi mp aspect blur source gdm_size gdm_date
            set -l __val (eval "echo \$$__var" 2>/dev/null)
            if test -z "$__val"; or string match -qr '^\?+$' "$__val"
                set "$__var" "Unknown"
            end
        end

        # ─── Split path + fallback name if cache didn't have NAME ───
        set -l f_dir (dirname "$last_file")
        set f_dir (string replace -r "^$HOME" "~" "$f_dir")
        if test -z "$f_name"
            set f_name (basename "$last_file")
        end

        # ─── Kitty image preview ───
        if test -n "$KITTY_PID"
            echo ""
            echo -e "  $CY┌── $WH🖼️  WALLPAPER PREVIEW $D(Kitty)$C$(printf '%*s' 25 '')$CY──┐$C"
            kitty +kitten icat --align left "$last_file" 2>/dev/null
            echo -e "  $CY└$(printf '%*s' 58 '')┘$C"
            echo ""
        end

        # ═══════════════════════════════════════════════════════════════
        # INFO BOX — TWO SECTIONS: FILE DETAILS + IMAGE INFORMATION
        # ═══════════════════════════════════════════════════════════════
        echo ""
        echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l i_title "  🖼️  LAST APPLIED GDM WALLPAPER"
        echo -e "  $CY║$C  $WH$i_title$C$(printf '%*s' (math "60 - "(string length "$i_title")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"

        # ── SECTION 1: FILE DETAILS (54 ─ wide nested frame) ──
        echo -e "  $CY║$C    $D┌──────────────────────────────────────────────────────┐$C  $CY║$C"
        echo -e "  $CY║$C    $D│$C  $WH📄  FILE DETAILS$C$(printf '%*s' 36 '')$D│$C  $CY║$C"

        # File name line — bold + green (📎 emoji visual +1)
        set -l fn_label "📎  "
        set -l fn_line "$fn_label$f_name"
        set -l fn_len (string length -- "$fn_line")
        set -l fn_pad (math "50 - $fn_len - 1")
        if test $fn_pad -lt 0; set fn_pad 0; end
        echo -e "  $CY║$C    $D│$C  $fn_label$GR$B$f_name$C$(printf '%*s' $fn_pad '')$D│$C  $CY║$C"

        # Dir line — dim gray (📍 emoji visual +1)
        set -l dr_label "📍  "
        set -l dr_line "$dr_label$f_dir/"
        set -l dr_len (string length -- "$dr_line")
        set -l dr_pad (math "50 - $dr_len - 1")
        if test $dr_pad -lt 0; set dr_pad 0; end
        echo -e "  $CY║$C    $D│$C  $D$dr_label$C$GY$f_dir/$C$(printf '%*s' $dr_pad '')$D│$C  $CY║$C"

        # Size + Date on one line (💾🕒 emoji visual +2)
        set -l sd_label  "💾  "
        set -l sd_content "$sd_label$GR$gdm_size$C  $D🕒$C  $gdm_date"
        set -l sd_plain  "$sd_label$gdm_size  🕒  $gdm_date"
        set -l sd_len    (string length -- "$sd_plain")
        set -l sd_pad    (math "50 - $sd_len - 2")
        if test $sd_pad -lt 0; set sd_pad 0; end
        echo -e "  $CY║$C    $D│$C  $sd_content$(printf '%*s' $sd_pad '')$D│$C  $CY║$C"

        # ── SECTION 2: IMAGE INFORMATION ──
        echo -e "  $CY║$C    $D├──────────────────────────────────────────────────────┤$C  $CY║$C"
        echo -e "  $CY║$C    $D│$C  $WH🎨  IMAGE INFORMATION$C$(printf '%*s' 31 '')$D│$C  $CY║$C"

        # Line: Format | Colorspace | Bit depth (🎨🔲 emoji visual +2; 🖼️ is 2-wide already)
        set -l dep_str "$dep"
        if string match -qr '^\d+$' "$dep"
            set dep_str (string join -- '' "$dep" '-bit')
        end
        set -l fc_label "🖼️  "
        set -l fc_content "$fc_label$CY$fmt$C    $D🎨$C  $csp    $D🔲$C  $dep_str"
        set -l fc_plain  "$fc_label$fmt  🎨  $csp  🔲  $dep_str"
        set -l fc_len    (string length -- "$fc_plain")
        set -l fc_pad    (math "50 - $fc_len - 2")
        if test $fc_pad -lt 0; set fc_pad 0; end
        echo -e "  $CY║$C    $D│$C  $fc_content$(printf '%*s' $fc_pad '')$D│$C  $CY║$C"

        # Line: Aspect ratio | Megapixels | DPI (📏📐🔳 emoji visual +3)
        set -l mp_str "$mp MP"
        set -l am_label "📏  "
        set -l am_content "$am_label$CY$aspect$C    $D📐$C  $mp_str    $D🔳$C  $dpi"
        set -l am_plain  "$am_label$aspect  📐  $mp_str  🔳  $dpi"
        set -l am_len    (string length -- "$am_plain")
        set -l am_pad    (math "50 - $am_len - 3")
        if test $am_pad -lt 0; set am_pad 0; end
        echo -e "  $CY║$C    $D│$C  $am_content$(printf '%s%*s' '' $am_pad '')$D│$C  $CY║$C"

        # Line: Blur status (🌀 emoji visual +1)
        set -l bl_label "🌀  "
        set -l bl_content "$bl_label$blur"
        set -l bl_len   (string length -- "$bl_content")
        set -l bl_pad   (math "50 - $bl_len - 1")
        if test $bl_pad -lt 0; set bl_pad 0; end
        echo -e "  $CY║$C    $D│$C  $bl_content$(printf '%*s' $bl_pad '')$D│$C  $CY║$C"

        # Line: Source path (📂 emoji visual +1; keep end of path)
        set -l sr_label "📂  Source  "
        set -l sr_val "$source"
        set -l sr_plain  "$sr_label$sr_val"
        set -l sr_len    (string length -- "$sr_plain")
        set -l sr_max    (math "50 - 1")  # 50 inner width minus 1 for emoji visual
        if test $sr_len -gt $sr_max
            set -l max_val (math "$sr_max - "(string length -- "$sr_label"))
            # Keep last N chars with … prefix
            set -l keep (math "$max_val - 1")  # -1 for …
            set sr_val "…"(string sub -s (math (string length -- "$sr_val") - $keep + 1) "$sr_val")
            set sr_plain "$sr_label$sr_val"
            set sr_len (string length -- "$sr_plain")
        end
        set -l sr_pad    (math "50 - $sr_len - 1")
        if test $sr_pad -lt 0; set sr_pad 0; end
        echo -e "  $CY║$C    $D│$C  $D$sr_label$C$GY$sr_val$C$(printf '%*s' $sr_pad '')$D│$C  $CY║$C"

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
    # 🛡️  GUARD: Reject non-image files (pdf, txt, doc, mp4, etc.)
    # ══════════════════════════════════════════════════════════════
    set -l img_exts jpg jpeg png gif bmp webp tiff tif svg svgz ico heic heif avif jp2 jfif jfi pjpeg pjp psd jxl
    set -l ext_match (string match -r '\.([^./]+)$' "$filename" 2>/dev/null)
    if test -n "$ext_match"
        set -l ext_lower (string lower -- "$ext_match[2]" 2>/dev/null)
        if not contains -- "$ext_lower" $img_exts
            echo ""
            echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l ie1 "  ✘  UNSUPPORTED FORMAT"
            echo -e "  $RE║$C  $WH$ie1$C$(printf '%*s' (math "60 - "(string length "$ie1")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            echo -e "  $RE╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l ie2 "\"$filename\" is not a supported format."
            set -l ie2_len (string length -- "$ie2")
            if test $ie2_len -gt 56
                set ie2 (string sub -l 53 "$ie2")"..."
                set ie2_len 56
            end
            echo -e "  $RE║$C    $YE$ie2$C$(printf '%*s' (math "58 - $ie2_len") '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l ie3 "  If this is an image file, convert it to one of"
            set -l ie4 "  these formats and try again:"
            set -l ie5 "  jpg  png  webp  (most compatible)"
            echo -e "  $RE║$C  $D$ie3$C$(printf '%*s' (math "60 - "(string length "$ie3")) '')$RE║$C"
            echo -e "  $RE║$C  $D$ie4$C$(printf '%*s' (math "60 - "(string length "$ie4")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            echo -e "  $RE║$C  $CY$ie5$C$(printf '%*s' (math "60 - "(string length "$ie5")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l br "  eprahemi  •  github.com/eprahemi"
            echo -e "  $RE║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
            echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
            echo ""
            return 1
        end
    end

    # ══════════════════════════════════════════════════════════════
    # 🔍  SEARCH ENGINE — finds the image everywhere
    # ══════════════════════════════════════════════════════════════
    set -l image ""
    set -l results

    # 1. Try direct path first — no extension filter for explicit paths
    set -l direct (realpath "$filename" 2>/dev/null)
    if test -f "$direct"
        set results "$direct"
    else
        # 🛡️  GUARD: Minimum search term length (short = deadly slow)
        # Skip guard if input contains / (it's a full/relative path)
        set -l is_path (string match -r '/' "$filename")
        # Check the stem (before any extension) — "b.jpg" has a 5-char
        # filename but the meaningful search term "b" is still too short
        set -l stem (string replace -r '\..*$' '' "$filename")
        if test -z "$is_path"; and test (string length -- "$stem") -lt 3
            echo ""
            echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l se1 "  ✘  SEARCH TERM TOO SHORT"
            echo -e "  $RE║$C  $WH$se1$C$(printf '%*s' (math "60 - "(string length "$se1")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            echo -e "  $RE╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l se2 "  Use at least 3 characters to search."
            set -l se3 "  Short searches match too many files and"
            set -l se4 "  will take forever to complete."
            echo -e "  $RE║$C  $D$se2$C$(printf '%*s' (math "60 - "(string length "$se2")) '')$RE║$C"
            echo -e "  $RE║$C  $D$se3$C$(printf '%*s' (math "60 - "(string length "$se3")) '')$RE║$C"
            echo -e "  $RE║$C  $D$se4$C$(printf '%*s' (math "60 - "(string length "$se4")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l se5 "  Instead, copy the full path of your image"
            set -l se6 "  and paste it here:"
            set -l se7 "  gdm /path/to/your/image.jpg"
            echo -e "  $RE║$C  $YE$se5$C$(printf '%*s' (math "60 - "(string length "$se5")) '')$RE║$C"
            echo -e "  $RE║$C  $YE$se6$C$(printf '%*s' (math "60 - "(string length "$se6")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            echo -e "  $RE║$C  $CY$se7$C$(printf '%*s' (math "60 - "(string length "$se7")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l br "  eprahemi  •  github.com/eprahemi"
            echo -e "  $RE║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
            echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
            echo ""
            return 1
        end

        # 2. Search common user directories
        echo -e "  $D🔍  Searching for \"$filename\"...$C  $GY eprahemi$C"
        set -l search_dirs \
            "$HOME/Pictures" \
            "$HOME/Downloads" \
            "$HOME/Documents" \
            "$HOME/Videos" \
            "$HOME/Music" \
            "$HOME/Desktop" \
            "$HOME/Templates" \
            "$HOME/Public"

        for dir in $search_dirs
            if test -d "$dir"
                set -l found (find "$dir" -type f -iname "$filename" 2>/dev/null)
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
                    set -l found (find "$dir" -type f -iname "*$filename*" 2>/dev/null)
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

        # Deduplicate search results (paths with spaces: always quote $r)
        if test (count $results) -gt 1
            set -l deduped
            for r in $results
                if not contains -- "$r" $deduped
                    set -a deduped "$r"
                end
            end
            set results $deduped
        end

        # Filter search results to image files only — weed out .py, .mjs, .js
        set -l img_results
        set -l img_regex '\.(jpg|jpeg|png|gif|bmp|webp|tiff?|svg|svgz|ico|heic|heif|avif|jp2|jfif|jfi|pjpeg|pjp|psd|jxl)$'
        for r in $results
            if string match -riq -- "$img_regex" "$r"
                set -a img_results "$r"
            end
        end
        set results $img_results
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
            # 🛡️  GUARD: Reject empty/null images before any prompt
            if not test -s "$image"
                echo ""
                echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l ee1 "  ✘  EMPTY OR NULL IMAGE"
                echo -e "  $RE║$C  $WH$ee1$C$(printf '%*s' (math "60 - "(string length "$ee1")) '')$RE║$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                echo -e "  $RE╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l ee2 "  The selected image has zero bytes or doesn't"
                set -l ee3 "  exist. GDM cannot apply an empty file."
                echo -e "  $RE║$C  $D$ee2$C$(printf '%*s' (math "60 - "(string length "$ee2")) '')$RE║$C"
                echo -e "  $RE║$C  $D$ee3$C$(printf '%*s' (math "60 - "(string length "$ee3")) '')$RE║$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l ee4 "  Choose a valid image and run gdm again."
                echo -e "  $RE║$C  $YE$ee4$C$(printf '%*s' (math "60 - "(string length "$ee4")) '')$RE║$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l br "  eprahemi  •  github.com/eprahemi"
                echo -e "  $RE║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
                echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
                echo ""
                return 1
            end
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
                set -l __cc 0
                while true
                    read -l -P "  [Y/n]: " confirm
                    set -l __rs $status
                    if test $__rs -ne 0
                        set __cc (math $__cc + 1)
                        if test $__cc -ge 2
                            echo -e "  $D  → Cancelled.  $C  $GY eprahemi$C"
                            return 1
                        end
                        echo -e "  $D  (Ctrl+C again to cancel)  $C  $GY eprahemi$C"
                        continue
                    end
                    break
                end
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
            if test (string length "$m2") -le 60
                echo -e "  $CY║$C  $m2$C$(printf '%*s' (math "60 - "(string length "$m2")) '')$CY║$C"
            else
                set -l m2_part1 (string sub -l 58 "$m2")
                set -l m2_part2 (string sub -s 59 "$m2")
                echo -e "  $CY║$C  $m2_part1$C$(printf '%*s' (math "60 - "(string length "$m2_part1")) '')$CY║$C"
                set -l m2_indent "  "
                set -l m2_line2 "$m2_indent$m2_part2"
                if test (string length "$m2_line2") -gt 60
                    set m2_line2 (string sub -l 57 "$m2_line2")"..."
                end
                echo -e "  $CY║$C  $m2_line2$C$(printf '%*s' (math "60 - "(string length "$m2_line2")) '')$CY║$C"
            end
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"

            for i in (seq $result_count)
                set -l fullpath $results[$i]
                set -l dir_part (dirname "$fullpath")/
                set -l file_part (basename "$fullpath")
                set -l num_str (printf "%2d" $i)
                set -l prefix "  [$num_str]  "
                set -l cont_indent "        "
                set -l remaining "$fullpath"
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
            set -l m3 "  Type 1–$result_count to choose, or 'q' to cancel"
            echo -e "  $CY║$C  $WH$m3$C$(printf '%*s' (math "60 - "(string length "$m3")) '')$CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            set -l br "  eprahemi  •  github.com/eprahemi"
            echo -e "  $CY║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$CY║$C"
            echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
            echo ""

            set -l __cc 0
            while true
                read -l -P "  [#]: " choice
                set -l __rs $status
                if test $__rs -ne 0
                    set __cc (math $__cc + 1)
                    if test $__cc -ge 2
                        echo -e "  $D  → Exiting.  $C  $GY eprahemi$C"
                        return 1
                    end
                    echo -e "  $D  (Ctrl+C again to exit)  $C  $GY eprahemi$C"
                    continue
                end
                if string match -qir '^q' "$choice"
                    echo -e "  $RE✘  Cancelled. Run $CY$B gdm$C $RE again — github.com/eprahemi$C"
                    return 1
                end
                if string match -qr '^\d+$' "$choice"
                    set -l num (math "$choice" 2>/dev/null)
                    if test $num -ge 1 -a $num -le $result_count
                        set image "$results[$num]"
                        # 🛡️  GUARD: Reject empty/null images before proceeding
                        if not test -s "$image"
                            echo ""
                            echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
                            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                            set -l ee1 "  ✘  EMPTY OR NULL IMAGE"
                            echo -e "  $RE║$C  $WH$ee1$C$(printf '%*s' (math "60 - "(string length "$ee1")) '')$RE║$C"
                            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                            echo -e "  $RE╠══════════════════════════════════════════════════════════════╣$C"
                            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                            set -l ee2 "  That match has zero bytes or doesn't exist."
                            set -l ee3 "  Choose a different image from the list."
                            echo -e "  $RE║$C  $D$ee2$C$(printf '%*s' (math "60 - "(string length "$ee2")) '')$RE║$C"
                            echo -e "  $RE║$C  $D$ee3$C$(printf '%*s' (math "60 - "(string length "$ee3")) '')$RE║$C"
                            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                            set -l br "  eprahemi  •  github.com/eprahemi"
                            echo -e "  $RE║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
                            echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
                            echo ""
                            return 1
                        end

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

    # ── Save original source info to /tmp/ before blur/conversion overwrites $image ──
    #     This survives through blur + JPEG conversion; apply step reads it back
    mkdir -p /tmp/.gdm-info
    basename "$image" > /tmp/.gdm-info/original-name.txt
    realpath "$image" 2>/dev/null > /tmp/.gdm-info/original-path.txt

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
                set -l __cc 0
                while true
                    read -l -P "  [n/Y/c]: " blur_choice
                    set -l __rs $status
                    if test $__rs -ne 0
                        set __cc (math $__cc + 1)
                        if test $__cc -ge 2
                            echo -e "  $D  → Exiting.  $C  $GY eprahemi$C"
                            return 1
                        end
                        echo -e "  $D  (Ctrl+C again to exit)  $C  $GY eprahemi$C"
                        continue
                    end
                    break
                end

                switch (string lower "$blur_choice")
                    case n no
                        echo "No blur applied" > /tmp/.gdm-info/blur-settings.txt
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
                            echo "Blur 0x40 + black 40%" > /tmp/.gdm-info/blur-settings.txt
                            set blur_done 1
                            echo -e "  $GR✅  Default blur applied$C  github.com/eprahemi"
                        else
                            echo -e "  $RE✘  Blur failed — image may be corrupt or unsupported. Using original.$C  $GY github.com/eprahemi$C"
                            echo "No blur applied (blur failed)" > /tmp/.gdm-info/blur-settings.txt
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
                        set -l __cc 0
                        while true
                            read -l -P "    Blur sigma [30]: " blur_sigma
                            set -l __rs $status
                            if test $__rs -ne 0
                                set __cc (math $__cc + 1)
                                if test $__cc -ge 2
                                    echo -e "  $D  → Exiting.  $C  $GY eprahemi$C"
                                    return 1
                                end
                                echo -e "  $D  (Ctrl+C again to exit)  $C  $GY eprahemi$C"
                                continue
                            end
                            break
                        end
                        set -l __cc 0
                        while true
                            read -l -P "    Black tint % [30]: " colorize_pct
                            set -l __rs $status
                            if test $__rs -ne 0
                                set __cc (math $__cc + 1)
                                if test $__cc -ge 2
                                    echo -e "  $D  → Exiting.  $C  $GY eprahemi$C"
                                    return 1
                                end
                                echo -e "  $D  (Ctrl+C again to exit)  $C  $GY eprahemi$C"
                                continue
                            end
                            break
                        end

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
                                set -l __cc 0
                                while true
                                    read -l -P "  [y/N]: " like_it
                                    set -l __rs $status
                                    if test $__rs -ne 0
                                        set __cc (math $__cc + 1)
                                        if test $__cc -ge 2
                                            echo -e "  $D  → Exiting.  $C  $GY eprahemi$C"
                                            return 1
                                        end
                                        echo -e "  $D  (Ctrl+C again to exit)  $C  $GY eprahemi$C"
                                        continue
                                    end
                                    break
                                end
                                if string match -qir '^y' "$like_it"
                                    set image "$blurred_file"
                                    echo "Blur 0x$blur_sigma + black $colorize_pct%" > /tmp/.gdm-info/blur-settings.txt
                                    set blur_done 1
                                    echo -e "  $GR✅  Custom blur applied$C  github.com/eprahemi"
                                end
                                # N → loops back to blur menu
                            else
                                set image "$blurred_file"
                                echo "Blur 0x$blur_sigma + black $colorize_pct%" > /tmp/.gdm-info/blur-settings.txt
                                echo -e "  $D  💻  Preview requires Kitty terminal — blur applied without preview.$C"
                                echo -e "  $GR✅  Custom blur applied$C  github.com/eprahemi"
                                echo ""
                                set -l __cc 0
                                while true
                                    read -l -P "  [Y] Continue  [N] Try again: " non_kitty_ok
                                    set -l __rs $status
                                    if test $__rs -ne 0
                                        set __cc (math $__cc + 1)
                                        if test $__cc -ge 2
                                            echo -e "  $D  → Exiting.  $C  $GY eprahemi$C"
                                            return 1
                                        end
                                        echo -e "  $D  (Ctrl+C again to exit)  $C  $GY eprahemi$C"
                                        continue
                                    end
                                    break
                                end
                                if string match -qir '^n' "$non_kitty_ok"
                                    # loop back to blur menu
                                else
                                    set blur_done 1
                                end
                            end
                        else
                            echo -e "  $RE✘  Custom blur failed — image may be corrupt or unsupported. Using original.$C  $GY github.com/eprahemi$C"
                            echo "No blur applied (blur failed)" > /tmp/.gdm-info/blur-settings.txt
                            set blur_done 1
                        end
                end
            end
        else
            echo "No blur applied" > /tmp/.gdm-info/blur-settings.txt
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
            set -l __cc 0
            while true
                read -l -P "  [y/N]: " install_magick
                set -l __rs $status
                if test $__rs -ne 0
                    set __cc (math $__cc + 1)
                    if test $__cc -ge 2
                        echo -e "  $D  → Exiting.  $C  $GY eprahemi$C"
                        return 1
                    end
                    echo -e "  $D  (Ctrl+C again to exit)  $C  $GY eprahemi$C"
                    continue
                end
                break
            end
            if string match -qir '^y' "$install_magick"
                echo -e "  $D📦  Installing ImageMagick...$C  $GY github.com/eprahemi$C"
                if sudo dnf install -y ImageMagick 2>/dev/null
                    echo -e "  $GR✅  ImageMagick installed!$C  $GY github.com/eprahemi$C"
                    echo -e "  $GY  Run $CY$B gdm$C $GY again to use blur options.$C"
                    echo "No blur applied (ImageMagick was just installed)" > /tmp/.gdm-info/blur-settings.txt
                else
                    echo -e "  $RE✘  Installation failed. Try: $CY$B sudo dnf install ImageMagick$C  $GY github.com/eprahemi$C"
                end
            else
                echo -e "  $D  Skipping blur — using original image.$C  $GY github.com/eprahemi$C"
                echo "No blur applied (ImageMagick not installed)" > /tmp/.gdm-info/blur-settings.txt
            end
        end
    end

    # ── Persistent FedoraTahoe-GDM repo (first run clones; re-clones if files missing) ──
    set -l repo "$HOME/.local/share/mactahoe-gtk"

    # Critical files required for the wallpaper engine to work
    set -l critical_files \
        "$repo/tweaks.sh" \
        "$repo/libs/lib-core.sh" \
        "$repo/libs/lib-install.sh" \
        "$repo/other/gdm/gnome-shell-theme.gresource.xml"

    set -l need_clone 0
    if not test -d "$repo"
        set need_clone 1
    else
        for __cf in $critical_files
            if not test -f "$__cf"
                set need_clone 1
                break
            end
        end
    end

    if test $need_clone -eq 1
        echo ""
        echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l i1 "  🌐  INTERNET NEEDED — ONE TIME ONLY"
        echo -e "  $CY║$C  $WH$i1$C$(printf '%*s' (math "60 - "(string length "$i1")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l i2 "  The GDM wallpaper engine requires a local copy"
        echo -e "  $CY║$C  $D$i2$C$(printf '%*s' (math "60 - "(string length "$i2")) '')$CY║$C"
        set -l i3 "  of the FedoraTahoe-GDM repo."
        echo -e "  $CY║$C  $D$i3$C$(printf '%*s' (math "60 - "(string length "$i3")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l i4 "  Checking internet connection..."
        echo -e "  $CY║$C  $YE$i4$C$(printf '%*s' (math "60 - "(string length "$i4")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
        echo ""

        # ── Check internet connectivity before clone ──
        set -l has_net 0
        if command -v curl &>/dev/null
            curl -fsSL -o /dev/null --connect-timeout 5 "https://github.com" 2>/dev/null
            and set has_net 1
        else if command -v ping &>/dev/null
            ping -c 1 -W 5 "github.com" 2>/dev/null
            and set has_net 1
        end
        if test $has_net -eq 0
            echo ""
            echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l ni1 "  🌐  INTERNET NEEDED"
            echo -e "  $RE║$C  $WH$ni1$C$(printf '%*s' (math "60 - "(string length "$ni1")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            echo -e "  $RE╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l ni2 "  The GDM wallpaper engine is not installed yet,"
            set -l ni3 "  and an internet connection is required to"
            set -l ni4 "  download it from GitHub."
            echo -e "  $RE║$C  $D$ni2$C$(printf '%*s' (math "60 - "(string length "$ni2")) '')$RE║$C"
            echo -e "  $RE║$C  $D$ni3$C$(printf '%*s' (math "60 - "(string length "$ni3")) '')$RE║$C"
            echo -e "  $RE║$C  $D$ni4$C$(printf '%*s' (math "60 - "(string length "$ni4")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l ni5 "  Please connect to the internet and try again."
            echo -e "  $RE║$C  $YE$ni5$C$(printf '%*s' (math "60 - "(string length "$ni5")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l br "  eprahemi  •  github.com/eprahemi"
            echo -e "  $RE║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
            echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
            echo ""
            return 1
        end

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
            set -l gi2 "  git is required to download the repo."
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
            set -l __cc 0
            while true
                read -l -P "  [y/N]: " install_git
                set -l __rs $status
                if test $__rs -ne 0
                    set __cc (math $__cc + 1)
                    if test $__cc -ge 2
                        echo -e "  $RE✘  Cancelled — git is required.$C  $GY github.com/eprahemi$C"
                        return 1
                    end
                    echo -e "  $D  (Ctrl+C again to cancel)  $C  $GY eprahemi$C"
                    continue
                end
                break
            end
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

        if not git clone --depth 1 https://github.com/eprahemi/FedoraTahoe-GDM.git "$repo" 2>/dev/null
            echo -e "  $RE✘  Clone failed — no internet?$C  $GY github.com/eprahemi$C"
            echo -e "  $GY  Connect to the internet and try again.$C"
            echo -e "  $GY  github.com/eprahemi/FedoraTahoe-GDM$C"
            return 1
        end
        echo -e "  $GR✅  FedoraTahoe-GDM cached at $repo (works offline from now on)$C  $GY github.com/eprahemi$C"
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

    # ══════════════════════════════════════════════════════════════
    # 🛡️  GUARD A: Auto-install ImageMagick if missing (no prompt)
    # ══════════════════════════════════════════════════════════════
    if not command -v magick &>/dev/null
        if command -v sudo &>/dev/null
            echo -e "  $D  🛡️  magick not installed — auto-installing for metadata...$C  $GY eprahemi$C"
            if sudo dnf install -y ImageMagick 2>/dev/null
                echo -e "  $GR  ✅  ImageMagick installed by safety guard$C  github.com/eprahemi"
            else
                echo -e ""
                echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l gu1 "  ✘  IMAGEMAGICK INSTALL FAILED"
                echo -e "  $RE║$C  $WH$gu1$C$(printf '%*s' (math "60 - "(string length "$gu1")) '')$RE║$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                echo -e "  $RE╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l gu2 "  ImageMagick is required for metadata + blur."
                echo -e "  $RE║$C  $D$gu2$C$(printf '%*s' (math "60 - "(string length "$gu2")) '')$RE║$C"
                set -l gu3 "  Install it manually, then run gdm again:"
                echo -e "  $RE║$C  $D$gu3$C$(printf '%*s' (math "60 - "(string length "$gu3")) '')$RE║$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l gu4 "    sudo dnf install ImageMagick"
                echo -e "  $RE║$C  $YE$gu4$C$(printf '%*s' (math "60 - "(string length "$gu4")) '')$RE║$C"
                echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
                set -l br "  eprahemi  •  github.com/eprahemi"
                echo -e "  $RE║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
                echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
                echo ""
                return 1
            end
        else
            echo -e ""
            echo -e "  $RE╔══════════════════════════════════════════════════════════════╗$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l gu1 "  ✘  SUDO NOT AVAILABLE"
            echo -e "  $RE║$C  $WH$gu1$C$(printf '%*s' (math "60 - "(string length "$gu1")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            echo -e "  $RE╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l gu2 "  sudo is required to install ImageMagick."
            echo -e "  $RE║$C  $D$gu2$C$(printf '%*s' (math "60 - "(string length "$gu2")) '')$RE║$C"
            set -l gu3 "  Install it manually, then run gdm again:"
            echo -e "  $RE║$C  $D$gu3$C$(printf '%*s' (math "60 - "(string length "$gu3")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l gu4 "    sudo dnf install ImageMagick"
            echo -e "  $RE║$C  $YE$gu4$C$(printf '%*s' (math "60 - "(string length "$gu4")) '')$RE║$C"
            echo -e "  $RE║$C$(printf '%*s' 62 '')$RE║$C"
            set -l br "  eprahemi  •  github.com/eprahemi"
            echo -e "  $RE║$C  $D$br$C$(printf '%*s' (math "60 - "(string length "$br")) '')$RE║$C"
            echo -e "  $RE╚══════════════════════════════════════════════════════════════╝$C"
            echo ""
            return 1
        end
    end

    # ══════════════════════════════════════════════════════════════
    # 🛡️  GUARD B+C: Gather metadata with 3x retry + field validation
    # ══════════════════════════════════════════════════════════════

    # Default blur-settings if not written by any path
    if not test -f /tmp/.gdm-info/blur-settings.txt
        echo "No blur applied" > /tmp/.gdm-info/blur-settings.txt
    end
    set -l blur_desc (string trim < /tmp/.gdm-info/blur-settings.txt 2>/dev/null)

    # Read saved source path (fallback to $image if missing)
    set -l orig_path ""
    if test -f /tmp/.gdm-info/original-path.txt
        set orig_path (string trim < /tmp/.gdm-info/original-path.txt 2>/dev/null)
    end
    if test -z "$orig_path"
        set orig_path "$image"
    end
    set orig_path (string replace -r "^$HOME" "~" "$orig_path")

    # Read original filename from /tmp/ (saved before blur/conversion)
    set -l original_name ""
    if test -f /tmp/.gdm-info/original-name.txt
        set original_name (string trim < /tmp/.gdm-info/original-name.txt 2>/dev/null)
    end
    if test -z "$original_name"
        set original_name (basename "$image")
    end

    set -l retry_count 0
    set -l cache_ok 0

    while test $cache_ok -eq 0; and test $retry_count -lt 3
        set retry_count (math "$retry_count + 1")

        if test $retry_count -gt 1
            echo -e "  $D  🔄  Retry $retry_count/3 — gathering metadata again...$C  $GY eprahemi$C"
        end

        # ── Reset vars for this attempt ──
        set -l fmt "?"; set -l csp "?"; set -l dep "?"
        set -l dims "?x?"; set -l dpi "?"; set -l mp "?"
        set -l aspect "?"; set -l f_bytes "?"; set -l f_size "?"
        set -l f_date "?"

        # ── Gather technical metadata via magick ──
        if command -v magick &>/dev/null
            set fmt (magick identify -format "%m" "$image" 2>/dev/null)
            set csp (magick identify -format "%[colorspace]" "$image" 2>/dev/null)
            set dep (magick identify -format "%[depth]" "$image" 2>/dev/null)
            set dims (magick identify -format "%wx%h" "$image" 2>/dev/null)
            set dpi (magick identify -format "%xx%y" "$image" 2>/dev/null)

            # Megapixels + aspect ratio via python3
            set -l w_str (string split "x" "$dims" 2>/dev/null)[1]
            set -l h_str (string split "x" "$dims" 2>/dev/null)[2]
            if test -n "$w_str"; and test -n "$h_str"
                set mp (python3 -c "
        import sys
        w = int(sys.argv[1])
        h = int(sys.argv[2])
        print(f'{w*h/1000000:.1f}')
        " "$w_str" "$h_str" 2>/dev/null)
                set aspect (python3 -c "
        import sys, math
        w = int(sys.argv[1])
        h = int(sys.argv[2])
        g = math.gcd(w, h)
        print(f'{w//g}:{h//g}')
        " "$w_str" "$h_str" 2>/dev/null)
            end
        end

        # ── File size from stat; date = current timestamp ──
        set -l stat_target "$image"
        if test -f /tmp/.gdm-info/original-path.txt
            set -l op (string trim < /tmp/.gdm-info/original-path.txt 2>/dev/null)
            if test -f "$op"
                set stat_target "$op"
            end
        end
        if command -v stat &>/dev/null
            set f_bytes (stat -c "%s" "$stat_target" 2>/dev/null)
        end
        # Date: use current timestamp so user sees when they applied it, not file mtime
        if command -v date &>/dev/null
            set f_date (date +"%d %b %Y  %H:%M" 2>/dev/null)
        end

        # ── Human-readable size ──
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
        " "$f_bytes" 2>/dev/null)
        else
            set f_size "$f_bytes B"
        end

        # ── Write to temporary cache file ──
        set -l tmp_cache "/tmp/.gdm-info-tmp.txt"
        mkdir -p "$repo"
        echo "NAME: $original_name"  >  "$tmp_cache"
        echo "FORMAT: $fmt"        >> "$tmp_cache"
        echo "COLORSPACE: $csp"    >> "$tmp_cache"
        echo "DEPTH: $dep"         >> "$tmp_cache"
        echo "DIMS: $dims"         >> "$tmp_cache"
        echo "DPI: $dpi"           >> "$tmp_cache"
        echo "MP: $mp"             >> "$tmp_cache"
        echo "ASPECT: $aspect"     >> "$tmp_cache"
        echo "BLUR: $blur_desc"    >> "$tmp_cache"
        echo "SOURCE: $orig_path"  >> "$tmp_cache"
        echo "SIZE: $f_size"       >> "$tmp_cache"
        echo "DATE: $f_date"       >> "$tmp_cache"

        # ══════════════════════════════════════════════════════════
        # 🛡️  GUARD C: Validate every field in the cache
        # ══════════════════════════════════════════════════════════
        set -l fields_ok 1
        set -l validation_errors ""

        for pair in "NAME:$original_name" "FORMAT:$fmt" "COLORSPACE:$csp" "DEPTH:$dep" "DIMS:$dims" "DPI:$dpi" "MP:$mp" "ASPECT:$aspect" "BLUR:$blur_desc" "SOURCE:$orig_path"
            set -l fname (string split ":" "$pair")[1]
            set -l fval  (string split ":" "$pair")[2]
            if test -z "$fval"; or string match -qr '^\?+$' "$fval"
                set fields_ok 0
                set validation_errors "$validation_errors  ↑ $fname "
            end
        end
        # Check size + date separately (they can be legitimately "?" if stat fails)
        if test -z "$f_size"
            set fields_ok 0
            set validation_errors "$validation_errors  ↑ SIZE "
        end
        if test -z "$f_date"
            set fields_ok 0
            set validation_errors "$validation_errors  ↑ DATE "
        end

        if test $fields_ok -eq 1
            # All fields valid — move to final location
            cp "$tmp_cache" "$repo/.gdm-info.txt" 2>/dev/null
            rm -f "$tmp_cache"
            set cache_ok 1
            if test $retry_count -gt 1
                echo -e "  $GR  ✅  Cache validated on retry $retry_count/3$C  github.com/eprahemi"
            end
        else
            # Validation failed
            echo -e "  $D  ⚠️  Metadata validation failed (attempt $retry_count/3):$C  $GY eprahemi$C"
            echo -e "  $D    $validation_errors$C"
            rm -f "$tmp_cache"
            if test $retry_count -lt 3
                echo -e "  $D    🔄  Will retry...$C"
            end
        end
    end

    # ══════════════════════════════════════════════════════════════
    # 🛡️  GUARD C (fallback): If still invalid, write with Unknown
    # ══════════════════════════════════════════════════════════════
    if test $cache_ok -eq 0
        echo -e "  $D  ⚠️  Metadata incomplete after 3 retries — writing with Unknown markers.$C  $GY eprahemi$C"

        # Fill empty/? fields with "Unknown"
        for __var in original_name fmt csp dep dims dpi mp aspect blur_desc orig_path f_size f_date
            set -l __val (eval "echo \$$__var" 2>/dev/null)
            if test -z "$__val"; or string match -qr '^\?+$' "$__val"
                set "$__var" "Unknown"
            end
        end

        mkdir -p "$repo"
        echo "NAME: $original_name"  >  "$repo/.gdm-info.txt"
        echo "FORMAT: $fmt"        >> "$repo/.gdm-info.txt"
        echo "COLORSPACE: $csp"    >> "$repo/.gdm-info.txt"
        echo "DEPTH: $dep"         >> "$repo/.gdm-info.txt"
        echo "DIMS: $dims"         >> "$repo/.gdm-info.txt"
        echo "DPI: $dpi"           >> "$repo/.gdm-info.txt"
        echo "MP: $mp"             >> "$repo/.gdm-info.txt"
        echo "ASPECT: $aspect"     >> "$repo/.gdm-info.txt"
        echo "BLUR: $blur_desc"    >> "$repo/.gdm-info.txt"
        echo "SOURCE: $orig_path"  >> "$repo/.gdm-info.txt"
        echo "SIZE: $f_size"       >> "$repo/.gdm-info.txt"
        echo "DATE: $f_date"       >> "$repo/.gdm-info.txt"
        echo -e "  $D  🛡️  Cache written with Unknown — info display will handle gracefully.$C  $GY eprahemi$C"
    end

    # ── Apply the wallpaper ──
    # Guard: sudo must be installed
    if not command -v sudo &>/dev/null
        echo -e "  $RE✘  sudo is required but not installed.$C"
        echo -e "  $GY  Install it and try again.  github.com/eprahemi$C"
        return 1
    end
    # Save a copy for 'gdm info'
    cp "$image" "$repo/.gdm-undo-copy.jpg"
    # Clean up /tmp/.gdm-info/ — original name + source path now in metadata cache
    rm -rf /tmp/.gdm-info
    echo -e "  $CY🖼️  Applying GDM wallpaper...$C  $D github.com/eprahemi$C"
    cd "$repo"
    sudo ./tweaks.sh -g -nb -nd -b "$image"
    cd -

    echo -e "  $GR✅  GDM wallpaper updated!$C  $D Reboot to see it.$C"
    echo -e "  $GY  eprahemi  •  github.com/eprahemi$C"
end
