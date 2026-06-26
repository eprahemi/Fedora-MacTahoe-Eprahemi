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

    # ── Arg check ──
    if not set -q argv[1]
        echo -e "$RE✘$C Usage: $CY$B gdm /path/to/wallpaper.jpg$C"
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
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY║$C  $D  Changes the GDM login screen background.$C                    $CY║$C"
        echo -e "  $CY║$C  $D  First run  → needs internet (clones repo once).$C             $CY║$C"
        echo -e "  $CY║$C  $D  After that → works OFFLINE (cached repo).$C                   $CY║$C"
        echo -e "  $CY║$C  $D  Relative filenames work — no need for full paths.$C           $CY║$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY║$C  $GR  Examples:$C                                                   $CY║$C"
        echo -e "  $CY║$C  $CY  gdm my-image.jpg$C                                            $CY║$C"
        echo -e "  $CY║$C  $CY  gdm ~/Pictures/my-wallpaper.jpg$C                             $CY║$C"
        echo -e "  $CY║$C  $CY  gdm HOT PUSSASS.jpg$C                                         $CY║$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
        echo ""
        return 0
    end

    # ── Join all args so unquoted filenames with spaces work — ──
    #     e.g. `gdm HOT PUSSASS.jpg` from inside the folder
    set -l filename (string join ' ' $argv)
    set -l image (realpath "$filename" 2>/dev/null)
    if not test -f "$image"
        echo -e "  $RE✘$C File not found: $YE$filename$C"
        echo -e "  $GY  Tip: you can just type the filename if you're in the same folder.$C"
        return 1
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
