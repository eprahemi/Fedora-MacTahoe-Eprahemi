function mirror-icons --description "Mirror Flatpak app icons into local hicolor (fixes GTK 512x512 bug)"
    # GTK 3.24.52 cannot resolve icons that only exist at 512x512 in the
    # Flatpak system hicolor. This mirrors them into ~/.local/share/icons/hicolor/48x48/apps/
    set -l flatpak_hicolor /var/lib/flatpak/exports/share/icons/hicolor
    set -l user_hicolor ~/.local/share/icons/hicolor
    set -l user_48 $user_hicolor/48x48/apps
    set -l mirrored 0
    set -l skipped 0

    if not test -d "$flatpak_hicolor"
        echo "No Flatpak hicolor icons to mirror"
        return 0
    end

    mkdir -p "$user_48"

    # Ensure user hicolor has an index.theme
    if not test -f "$user_hicolor/index.theme"
        mkdir -p "$user_hicolor"
        echo "[Icon Theme]
Name=Hicolor
Comment=Fallback icon theme (local overrides)
Hidden=true
Directories=256x256/apps,48x48/apps

[48x48/apps]
Size=48
Context=Applications
Type=Fixed" >"$user_hicolor/index.theme"
    end

    # Collect unique icon names from Flatpak hicolor
    set -l seen
    for f in (find "$flatpak_hicolor" -name '*.png' -o -name '*.svg' 2>/dev/null)
        set -l name (basename "$f")
        set -l name_noext (string replace -r '\.[^.]+$' '' "$name")
        set -l ext (string match -r '\.([^.]+)$' "$name")[2]

        # Skip if already processed
        if contains "$name_noext" $seen
            continue
        end
        set -a seen "$name_noext"

        # Check if MacTahoe-dark already has this icon
        if count (find ~/.local/share/icons/MacTahoe-dark -name "$name" -o -name "$name_noext.svg" 2>/dev/null | head -1) >/dev/null
            set skipped (math "$skipped + 1")
            continue
        end

        # Check if user hicolor already has it at a resolvable size
        if test -f "$user_hicolor/48x48/apps/$name" -o -f "$user_hicolor/scalable/apps/$name_noext.svg"
            set skipped (math "$skipped + 1")
            continue
        end

        # SVG: mirror to scalable
        if test "$ext" = "svg"
            set -l target_dir $user_hicolor/scalable/apps
            mkdir -p "$target_dir"
            ln -sf "$f" "$target_dir/$name" 2>/dev/null; or cp -f "$f" "$target_dir/$name" 2>/dev/null
            set mirrored (math "$mirrored + 1")
            continue
        end

        # PNG: prefer smallest available size
        set -l best_src ""
        for size_dir in 48x48 64x64 128x128 256x256 512x512
            if test -f "$flatpak_hicolor/$size_dir/apps/$name"
                set best_src "$flatpak_hicolor/$size_dir/apps/$name"
                break
            end
        end
        if test -z "$best_src"
            set skipped (math "$skipped + 1")
            continue
        end
        ln -sf "$best_src" "$user_48/$name" 2>/dev/null; or cp -f "$best_src" "$user_48/$name" 2>/dev/null
        set mirrored (math "$mirrored + 1")
    end

    # Rebuild user hicolor cache
    if test "$mirrored" -gt 0
        gtk-update-icon-cache "$user_hicolor/" ^/dev/null 2>/dev/null
    end

    echo "Mirrored $mirrored Flatpak icon(s) to $user_hicolor/48x48/apps/ ($skipped already covered)"
end
