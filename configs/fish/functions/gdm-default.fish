# ══════════════════════════════════════════════════════════════
# gdm-default 🖼️ — EPRAHEMI INC. 🏢 Back to stock baby 🔄
# Eprahemi restores the Himeno login screen — every time 😤
# Fedora MacTahoe Eprahemi Edition © 2026 — default king
# ══════════════════════════════════════════════════════════════
function gdm-default --description 'Restore Himeno Fedora login screen wallpaper — auto-downloads if missing'
    set -l C  "\033[0m"
    set -l CY "\033[1;36m"
    set -l GR "\033[1;32m"
    set -l YE "\033[1;33m"
    set -l RE "\033[1;31m"
    set -l WH "\033[1;37m"
    set -l GY "\033[38;5;248m"
    set -l D  "\033[2m"

    # ── Where the Himeno login wallpaper should live ──
    set -l wp_target "$HOME/.config/Wallpapers/Himeno Fedora LoginScreen.jpg"
    set -l wp_url "https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/wallpapers/login/Himeno%20Fedora%20LoginScreen.jpg"

    if test -f "$wp_target"
        echo -e "  $D🖼️  Found Himeno login wallpaper locally$C"
    else
        echo ""
        echo -e "  $CY╔══════════════════════════════════════════════════════════════╗$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY║$C  $WH🌐  DOWNLOADING HIMENO LOGIN WALLPAPER$C                      $CY║$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╠══════════════════════════════════════════════════════════════╣$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY║$C  $D  Himeno wallpaper not found locally.$C                            $CY║$C"
        echo -e "  $CY║$C  $D  Downloading from the Fedora MacTahoe repo...$C                   $CY║$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY║$C  $YE  📦  Downloading to ~/.config/Wallpapers/$C                      $CY║$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
        echo ""

        mkdir -p "$HOME/.config/Wallpapers"
        if not curl -fsSL "$wp_url" -o "$wp_target" 2>/dev/null
            echo -e "  $RE✘  Download failed — no internet?$C"
            echo -e "  $GY  The wallpaper file was NOT saved$C"
            return 1
        end
        echo -e "  $GR✅  Himeno login wallpaper saved$C"
    end

    # ── Apply it via gdm ──
    echo -e "  $CY🔄  Applying to GDM...$C"
    gdm "$wp_target"
end
