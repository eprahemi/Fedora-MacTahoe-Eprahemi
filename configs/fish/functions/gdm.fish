# ══════════════════════════════════════════════════════════════
# gdm 🖼️ — EPRAHEMI INC. 🏢 Login screen flex on em 💅
# Eprahemi makes GDM wallpaper hot or not? ALWAYS HOT 🔥
# Fedora MacTahoe Eprahemi Edition © 2026 — change yo login
# ══════════════════════════════════════════════════════════════
function gdm --description 'Change GDM login screen wallpaper — needs internet only the first time'
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

    # ── Arg check ──
    if not set -q argv[1]
        echo -e "$RE✘$C Usage: $CY$B gdm [-y|--yes] /path/to/wallpaper.jpg$C"
        echo -e "  $GY-h, --help$C  Show this help"
        return 1
    end

    if contains -- "$argv[1]" "-h" "--help"
        echo ""
        echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l h1 "  🖼️  GDM WALLPAPER SWITCHER"
        echo -e "  $CY║$C  $WH$h1$C$(printf '%*s' (math "60 - "(string length "$h1")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        # ── Figlet "eprahemi" copyright ──
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
        set -l h2 "    gdm filename.jpg"
        echo -e "  $CY║$C  $CY$B$h2$C$(printf '%*s' (math "60 - "(string length "$h2")) '')$CY║$C"
        set -l h3 "    gdm /path/to/image.jpg"
        echo -e "  $CY║$C  $CY$B$h3$C$(printf '%*s' (math "60 - "(string length "$h3")) '')$CY║$C"
        set -l h4 "    gdm -y|--yes filename.jpg"
        echo -e "  $CY║$C  $CY$B$h4$C$(printf '%*s' (math "60 - "(string length "$h4")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l h5 "  Changes the GDM login screen background."
        echo -e "  $CY║$C  $D$h5$C$(printf '%*s' (math "60 - "(string length "$h5")) '')$CY║$C"
        set -l h6 "  First run  → needs internet (clones repo once)."
        echo -e "  $CY║$C  $D$h6$C$(printf '%*s' (math "60 - "(string length "$h6")) '')$CY║$C"
        set -l h7 "  After that → works OFFLINE (cached repo)."
        echo -e "  $CY║$C  $D$h7$C$(printf '%*s' (math "60 - "(string length "$h7")) '')$CY║$C"
        set -l h8 "  🔍  System-wide search across all your folders."
        echo -e "  $CY║$C  $D$h8$C$(printf '%*s' (math "60 - "(string length "$h8")) '')$CY║$C"
        set -l h9 "  Multiple matches? Pick one with 1/2/3…"
        echo -e "  $CY║$C  $D$h9$C$(printf '%*s' (math "60 - "(string length "$h9")) '')$CY║$C"
        set -l h10 "  🎨  Optional blur + dark tint before applying."
        echo -e "  $CY║$C  $D$h10$C$(printf '%*s' (math "60 - "(string length "$h10")) '')$CY║$C"
        set -l h11 "  Use -y or --yes to skip all prompts."
        echo -e "  $CY║$C  $D$h11$C$(printf '%*s' (math "60 - "(string length "$h11")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        set -l h12 "  Examples:"
        echo -e "  $CY║$C  $GR$h12$C$(printf '%*s' (math "60 - "(string length "$h12")) '')$CY║$C"
        set -l h13 "  gdm my-image.jpg"
        echo -e "  $CY║$C  $CY$h13$C$(printf '%*s' (math "60 - "(string length "$h13")) '')$CY║$C"
        set -l h14 "  gdm ~/Pictures/my-wallpaper.jpg"
        echo -e "  $CY║$C  $CY$h14$C$(printf '%*s' (math "60 - "(string length "$h14")) '')$CY║$C"
        set -l h15 "  gdm HOT PUSSASS.jpg"
        echo -e "  $CY║$C  $CY$h15$C$(printf '%*s' (math "60 - "(string length "$h15")) '')$CY║$C"
        set -l h16 "  gdm -y ~/Pictures/definite.jpg"
        echo -e "  $CY║$C  $CY$h16$C$(printf '%*s' (math "60 - "(string length "$h16")) '')$CY║$C"
        echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
        echo ""
        return 0
    end

    # ── Parse -y / --yes flag ──
    if contains -- "$argv[1]" "-y" "--yes"
        set skip_confirm 1
        set -e argv[1]
    end

    # ── Join all args so unquoted filenames with spaces work ──
    #     e.g. `gdm HOT PUSSASS.jpg` from inside the folder
    if not set -q argv[1]
        echo -e "$RE✘$C Usage: $CY$B gdm [-y|--yes] /path/to/wallpaper.jpg$C"
        return 1
    end
    set -l filename (string join ' ' $argv)

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
        echo -e "  $D🔍  Searching for \"$filename\"...$C"
        set -l search_dirs \
            "$HOME/Downloads" \
            "$HOME/Pictures" \
            "$HOME/Documents" \
            "$HOME/Desktop" \
            "$HOME/Videos" \
            "$HOME/Music" \
            "$HOME/Templates" \
            "$HOME/Public" \
            "$HOME/.config/Wallpapers" \
            "$HOME/.local/share/backgrounds" \
            "$HOME/.local/share/wallpapers" \
            "$HOME/.local/share/mactahoe-gtk" \
            "$HOME/Pictures/Wallpapers"

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
            echo -e "  $D  No exact match — trying wildcard...$C"
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

    # Deduplicate
    if test (count $results) -gt 1
        set -l deduped
        for r in $results
            if not contains -- $r $deduped
                set -a deduped $r
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
            return 1

        case 1
            set image $results[1]
            if test $skip_confirm -eq 0
                echo ""
                echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l c1 "  🖼️  DO YOU MEAN THIS?"
                echo -e "  $CY║$C  $WH$c1$C$(printf '%*s' (math "60 - "(string length "$c1")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l c2_len (string length "$image")
                if test $c2_len -gt 56
                    set c2 (string sub -l 53 "$image")"..."
                    set c2_len 56
                end
                echo -e "  $CY║$C    $YE$image$C$(printf '%*s' (math "58 - $c2_len") '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                set -l c3 "  [Y] Yes → Apply wallpaper"
                echo -e "  $CY║$C  $GR$c3$C$(printf '%*s' (math "60 - "(string length "$c3")) '')$CY║$C"
                set -l c4 "  [N] No  → Cancel, type gdm again"
                echo -e "  $CY║$C  $RE$c4$C$(printf '%*s' (math "60 - "(string length "$c4")) '')$CY║$C"
                echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
                echo ""
                read -l -P "  [y/N]: " confirm
                if not string match -qir '^y' "$confirm"
                    echo -e "  $RE✘  Cancelled. Run $CY$B gdm$C $RE again with the correct path.$C"
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
            echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
            echo ""

            while true
                read -l -P "  [#]: " choice
                if string match -qir '^q' "$choice"
                    echo -e "  $RE✘  Cancelled. Run $CY$B gdm$C $RE again with the correct path.$C"
                    return 1
                end
                if string match -qr '^\d+$' "$choice"
                    set -l num (math "$choice" 2>/dev/null)
                    if test $num -ge 1 -a $num -le $result_count
                        set image $results[$num]

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
            set -l b4 "  [Y] Yes — default blur 0x30 + black 30%"
            echo -e "  $CY║$C  $CY$b4$C$(printf '%*s' (math "60 - "(string length "$b4")) '')$CY║$C"
            set -l b5 "  [C] Custom — set blur sigma + tint %"
            echo -e "  $CY║$C  $YE$b5$C$(printf '%*s' (math "60 - "(string length "$b5")) '')$CY║$C"
            echo -e "  $CY║$C$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
            echo ""
            read -l -P "  [n/Y/c]: " blur_choice
        else
            set blur_choice "n"
        end

        switch (string lower "$blur_choice")
            case '' y yes
                set -l blurred "$HOME/.cache/gdm-blurred.jpg"
                mkdir -p "$HOME/.cache"
                echo -e "  $D🎨  Applying default blur (0x30) + black 30%% tint...$C"
                if magick "$image" -blur 0x30 -fill black -colorize 30% "$blurred" 2>/dev/null
                    set image "$blurred"
                    echo -e "  $GR✅  Blur applied$C"
                else
                    echo -e "  $RE✘  Blur failed, using original$C"
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

                set -l blurred "$HOME/.cache/gdm-blurred.jpg"
                mkdir -p "$HOME/.cache"
                echo -e "  $D🎨  Applying blur (0x$blur_sigma) + black $colorize_pct%% tint...$C"
                if magick "$image" -blur "0x$blur_sigma" -fill black -colorize "$colorize_pct%" "$blurred" 2>/dev/null
                    set image "$blurred"
                    echo -e "  $GR✅  Custom blur applied$C"
                else
                    echo -e "  $RE✘  Blur failed, using original$C"
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
        echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
        echo ""

        mkdir -p "$HOME/.local/share"
        rm -rf "$repo"
        if not git clone --depth 1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$repo" 2>/dev/null
            echo -e "  $RE✘  Clone failed — no internet?$C"
            echo -e "  $GY  Run the full installer first, or connect to the internet once.$C"
            return 1
        end
        echo -e "  $GR✅  Repo cached at $repo (works offline from now on)$C"

        # ── Also download the Himeno default login wallpaper ──
        echo -e "  $D📥  Downloading default Himeno login wallpaper...$C"
        curl -fsSL "https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/wallpapers/login/Himeno%20Fedora%20LoginScreen.jpg" -o "$repo/himeno-login.jpg" 2>/dev/null
        and echo -e "  $GR✅  Himeno wallpaper saved to repo$C"
        or echo -e "  $D  (skipped — not critical)$C"
    end

    # ── Apply the wallpaper ──
    echo -e "  $CY🖼️  Applying GDM wallpaper...$C"
    cd "$repo"
    sudo ./tweaks.sh -g -nb -nd -b "$image"
    cd -

    echo -e "  $GR✅  GDM wallpaper updated!$C  $D Reboot to see it.$C"
end
