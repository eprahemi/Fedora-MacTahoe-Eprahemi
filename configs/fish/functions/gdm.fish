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
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY║$C  $WH🖼️  GDM WALLPAPER SWITCHER                                $C  $CY║$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY║$C    $CY$B gdm filename.jpg$C                                          $CY║$C"
        echo -e "  $CY║$C    $CY$B gdm /path/to/image.jpg$C                                    $CY║$C"
        echo -e "  $CY║$C    $CY$B gdm -y|--yes filename.jpg$C                                 $CY║$C"
        echo -e "  $CY║$C$GY$(printf '%s' '                                                                 ')$CY║$C"
        echo -e "  $CY║$C  $D  Changes the GDM login screen background.$C                    $CY║$C"
        echo -e "  $CY║$C  $D  First run  → needs internet (clones repo once).$C             $CY║$C"
        echo -e "  $CY║$C  $D  After that → works OFFLINE (cached repo).$C                   $CY║$C"
        echo -e "  $CY║$C  $D  🔍  System-wide search across all your folders.$C             $CY║$C"
        echo -e "  $CY║$C  $D  Multiple matches? Pick one with 1/2/3…$C                      $CY║$C"
        echo -e "  $CY║$C  $D  🎨  Optional blur + dark tint before applying.$C              $CY║$C"
        echo -e "  $CY║$C  $D  Use $CY-y$C $D or $CY--yes$C $D to skip all prompts.$C                       $CY║$C"
        echo -e "  $CY║$C$GY$(printf '%s' '                                                                 ')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY║$C  $GR  Examples:$C                                                   $CY║$C"
        echo -e "  $CY║$C  $CY  gdm my-image.jpg$C                                            $CY║$C"
        echo -e "  $CY║$C  $CY  gdm ~/Pictures/my-wallpaper.jpg$C                             $CY║$C"
        echo -e "  $CY║$C  $CY  gdm HOT PUSSASS.jpg$C                                         $CY║$C"
        echo -e "  $CY║$C  $CY  gdm -y ~/Pictures/definite.jpg$C                              $CY║$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
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
                echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY║$C  $WH🖼️  DO YOU MEAN THIS?$C                                   $CY║$C"
                echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
                printf "  $CY║$C    $YE%s$C  $CY║$C\n" "$image"
                echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY║$C  $GR  [Y] Yes → Apply wallpaper$C                             $CY║$C"
                echo -e "  $CY║$C  $RE  [N] No  → Cancel, type gdm again$C                      $CY║$C"
                echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
                echo ""
                read -l -P "  [y/N]: " confirm
                if not string match -qir '^y' "$confirm"
                    echo -e "  $RE✘  Cancelled. Run $CY$B gdm$C $RE again with the correct path.$C"
                    return 1
                end
            end

        case '*'
            echo ""
            echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
            echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY║$C  $WH🖼️  MULTIPLE MATCHES$C                                  $CY║$C"
            echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
            printf "  $CY║$C    File $WH\"%s\"$C found in $YE%d$C locations:$C\n" "$filename" $result_count
            echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"

            for i in (seq $result_count)
                set -l path $results[$i]
                set -l display "$path"
                if test (string length "$display") -gt 55
                    set display (string sub -l 52 "$display")"..."
                end
                set -l num_str (printf "%2d" $i)
                echo -e "  $CY║$C  $GR"'['$num_str']'"$C  $D$display$C  $CY║$C"
            end

            echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
            printf "  $CY║$C  $WH  Type 1–%d to choose, or 'q' to cancel$C     $CY║$C\n" $result_count
            echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
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
            echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY║$C  $WH🎨  BLUR BACKGROUND?$C                                   $CY║$C"
            echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
            echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY║$C  Add blur + dark overlay to the wallpaper?$C                  $CY║$C"
            echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
            echo -e "  $CY║$C  $GR  [N] No$C — use original image$C                         $CY║$C"
            echo -e "  $CY║$C  $CY  [Y] Yes$C — default blur 0x30 + black 30%$C             $CY║$C"
            echo -e "  $CY║$C  $YE  [C] Custom$C — set blur sigma + tint %%$C                $CY║$C"
            echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
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
                echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY║$C  $WH🎨  CUSTOM BLUR$C                                       $CY║$C"
                echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
                echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY║$C  $D  Blur sigma$C $D(0=auto, try 20-50):$C                     $CY║$C"
                echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
                echo -e "  $CY║$C  $D  Black tint %%$C $D(0-100, try 20-40):$C                    $CY║$C"
                echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
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
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY║$C  $WH🌐  INTERNET NEEDED — ONE TIME ONLY$C                         $CY║$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY║$C  $D  This is the first time you're running gdm.$C                   $CY║$C"
        echo -e "  $CY║$C  $D  It needs to download the MacTahoe theme repo$C                 $CY║$C"
        echo -e "  $CY║$C  $D  to set up the GDM theme engine.$C                              $CY║$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY║$C  $YE  📦  Downloading ~5 MB to ~/.local/share/mactahoe-gtk$C  $CY║$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY║$C  $GR  ✅  After this, gdm works OFFLINE forever$C                    $CY║$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
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
