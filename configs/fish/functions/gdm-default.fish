# ══════════════════════════════════════════════════════════════
# gdm-default 🖼️ — EPRAHEMI INC. 🏢 Back to stock baby 🔄
# Eprahemi restores the Himeno login screen — every time 😤
# Fedora MacTahoe Eprahemi Edition © 2026 — default king
# ══════════════════════════════════════════════════════════════
function gdm-default --description 'Restore Himeno Fedora login screen — checks ~/.config/Wallpapers/ first, then cached repo'
    set -l C  "\033[0m"
    set -l CY "\033[1;36m"
    set -l GR "\033[1;32m"
    set -l YE "\033[1;33m"
    set -l RE "\033[1;31m"
    set -l GY "\033[38;5;248m"
    set -l D  "\033[2m"

    # ── Look in ~/.config/Wallpapers/ first (left by install.sh) ──
    set -l wp_config "$HOME/.config/Wallpapers/Himeno Fedora LoginScreen.jpg"
    # ── Fallback: inside the cached MacTahoe repo (downloaded by gdm) ──
    set -l wp_repo "$HOME/.local/share/mactahoe-gtk/himeno-login.jpg"
    set -l wp_url "https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/wallpapers/login/Himeno%20Fedora%20LoginScreen.jpg"

    set -l wp_target ""

    if test -f "$wp_config"
        set wp_target "$wp_config"
        echo -e "  $D🖼️  Found Himeno login wallpaper in ~/.config/Wallpapers/$C"
    else if test -f "$wp_repo"
        set wp_target "$wp_repo"
        echo -e "  $D🖼️  Found Himeno login wallpaper in cached repo$C"
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
        echo -e "  $CY║$C  $YE  📦  Saving to ~/.local/share/mactahoe-gtk/$C                     $CY║$C"
        echo -e "  $CY║$C$GY$(printf '%*s' 62 '')$CY║$C"
        echo -e "  $CY╚══════════════════════════════════════════════════════════════╝$C"
        echo ""

        set wp_target "$wp_repo"
        mkdir -p "$HOME/.local/share/mactahoe-gtk"
        if not curl -fsSL "$wp_url" -o "$wp_target" 2>/dev/null
            echo -e "  $RE✘  Download failed — no internet?$C"
            echo -e "  $GY  Run gdm with any image, or connect to the internet.$C"
            return 1
        end
        echo -e "  $GR✅  Himeno login wallpaper saved to repo$C"
    end

    # ── Apply it via gdm ──
    echo -e "  $CY🔄  Applying to GDM...$C"
    gdm "$wp_target"
end
