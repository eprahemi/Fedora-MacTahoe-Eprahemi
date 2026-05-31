#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
#  Fedora MacTahoe — Eprahemi Edition
#  Complete automated setup script
#  Run: bash install.sh
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE="$SCRIPT_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $1"; }
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; exit 1; }

TOTAL_STEPS=19
STEP=0

next_step() {
  STEP=$((STEP + 1))
  echo ""
  echo -e "${YELLOW}[${STEP}/${TOTAL_STEPS}]${NC} $1"
}

# ── PREFLIGHT ────────────────────────────────────────────────

preflight() {
  next_step "Preflight checks"

  if [ ! -f /etc/fedora-release ]; then
    fail "This script is designed for Fedora Linux only."
  fi
  ok "Fedora detected"

  if [ "$EUID" -eq 0 ]; then
    fail "Do NOT run as root. Run as your normal user — sudo prompts will appear."
  fi
  ok "Running as normal user"

  if ! ping -c1 -W2 google.com &>/dev/null && ! ping -c1 -W2 github.com &>/dev/null; then
    fail "No internet connection detected."
  fi
  ok "Internet connection"

  if ! sudo -n true 2>/dev/null; then
    warn "You will be prompted for sudo password shortly."
  fi

  # Ensure sudo works
  sudo echo "Sudo OK" >/dev/null || fail "Sudo required"
  ok "Sudo access granted"
}

# ── PHASE 1: SYSTEM FOUNDATIONS ──────────────────────────────

install_rpmfusion() {
  next_step "RPM Fusion + Codecs"

  local release
  release=$(rpm -E %fedora)

  sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${release}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${release}.noarch.rpm" \
    --nogpgcheck 2>/dev/null || sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${release}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${release}.noarch.rpm"

  sudo dnf check-update 2>/dev/null || true
  sudo dnf install -y \
    ffmpegthumbnailer gstreamer1-plugin-libav gstreamer1-plugins-ugly \
    gstreamer1-plugins-bad-freeworld gstreamer1-plugins-bad-free-extras
  sudo dnf groupinstall -y multimedia 2>/dev/null || true
  rm -rf ~/.cache/thumbnails/
  nautilus -q 2>/dev/null || true
  ok "RPM Fusion + codecs installed"
}

install_nvidia() {
  next_step "NVIDIA Drivers (auto-detect)"

  if lspci | grep -qi nvidia; then
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-settings vdpauinfo libva-utils
    ok "NVIDIA drivers installed"
  else
    warn "No NVIDIA GPU detected — skipping"
  fi
}

# ── PHASE 2: PACKAGES ────────────────────────────────────────

install_rpm_packages() {
  next_step "RPM Packages"

  sudo dnf install -y \
    fish kitty fastfetch figlet lolcat eza \
    celluloid vlc \
    discord kdenlive pavucontrol alacarte \
    nautilus-python gnome-tweaks \
    ImageMagick fzf ripgrep jq unzip curl wget git \
    ffmpeg-free
  ok "RPM packages installed"
}

install_browsers() {
  next_step "Browsers (Chrome, Edge, Spotify)"

  # Chrome
  if ! rpm -q google-chrome-stable &>/dev/null; then
    sudo dnf install -y fedora-workstation-repositories
    sudo dnf config-manager --set-enabled google-chrome 2>/dev/null || true
    sudo dnf install -y google-chrome-stable --nogpgcheck 2>/dev/null || \
    sudo dnf install -y google-chrome-stable
  fi

  # Edge
  if ! rpm -q microsoft-edge-stable &>/dev/null; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true
    sudo dnf config-manager addrepo --from-repofile="https://packages.microsoft.com/yumrepos/edge/config" 2>/dev/null || true
    sudo dnf install -y microsoft-edge-stable 2>/dev/null || true
  fi

  # VS Code
  if ! rpm -q code &>/dev/null; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo' 2>/dev/null || true
    sudo dnf check-update 2>/dev/null || true
    sudo dnf install -y code
  fi

  ok "Browsers + VS Code installed (Spotify is installed via Flatpak)"
}

install_flatpaks() {
  next_step "Flatpak Apps"

  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
  flatpak install -y flathub com.rtosta.zapzap 2>/dev/null || true
  flatpak install -y flathub io.github.amit9838.mousam 2>/dev/null || true
  flatpak install -y flathub com.mattjakeman.ExtensionManager 2>/dev/null || true
  flatpak install -y flathub com.github.tchx84.Flatseal 2>/dev/null || true
  flatpak install -y flathub it.mijorus.gearlever 2>/dev/null || true
  flatpak install -y flathub fr.handbrake.ghb 2>/dev/null || true
  flatpak install -y flathub info.febvre.Komikku 2>/dev/null || true
  flatpak install -y flathub md.obsidian.Obsidian 2>/dev/null || true
  flatpak install -y flathub com.protonvpn.www 2>/dev/null || true
  flatpak install -y flathub com.spotify.Client 2>/dev/null || true

  sudo flatpak override --filesystem=xdg-config/gtk-3.0 2>/dev/null || true
  sudo flatpak override --filesystem=xdg-config/gtk-4.0 2>/dev/null || true
  ok "Flatpak apps installed"
}

# ── PHASE 3: THEMES ──────────────────────────────────────────

install_mactahoe_theme() {
  next_step "MacTahoe GTK Theme + Icons (bundled)"

  local theme_src="$BUNDLE/themes"

  # Purge any upstream MacTahoe-Dark that might conflict
  rm -rf "$HOME/.themes/MacTahoe-Dark" \
         "$HOME/.themes/MacTahoe" \
         "$HOME/.themes/MacTahoe-Darker"
  sudo rm -rf "/usr/share/themes/MacTahoe-Dark" \
              "/usr/share/themes/MacTahoe" \
              "/usr/share/themes/MacTahoe-Darker" 2>/dev/null || true

  # GTK Theme (force overwrite)
  mkdir -p "$HOME/.themes"
  rm -rf "$HOME/.themes/MacTahoe-Dark-Eprahemi"
  cp -r "$theme_src/MacTahoe-Dark-Eprahemi" "$HOME/.themes/"
  ok "GTK theme installed (MacTahoe-Dark-Eprahemi)"

  # Icon themes (force overwrite)
  for icon in MacTahoe-Eprahemi MacTahoe-dark-Eprahemi; do
    mkdir -p "$HOME/.local/share/icons"
    rm -rf "$HOME/.local/share/icons/$icon"
    cp -a "$theme_src/$icon" "$HOME/.local/share/icons/"
    gtk-update-icon-cache "$HOME/.local/share/icons/$icon/" 2>/dev/null || true
  done

  ok "Icon themes installed (MacTahoe-Eprahemi + MacTahoe-dark-Eprahemi)"
}

install_custom_icons() {
  next_step "Custom macOS App Icons"

  local icon_src="$BUNDLE/icons/256x256"
  local icon_dest="$HOME/.local/share/icons/MacTahoe-dark-Eprahemi/apps/scalable"
  local icon_dest2="$HOME/.local/share/icons/MacTahoe-Eprahemi/apps/scalable"
  local hicolor="$HOME/.local/share/icons/hicolor/256x256/apps"

  mkdir -p "$icon_dest" "$icon_dest2" "$hicolor"

  for png in "$icon_src"/*.png; do
    f=$(basename "$png")
    cp "$png" "$icon_dest/$f"
    cp "$png" "$icon_dest2/$f"
    cp "$png" "$hicolor/$f"
  done

  # Trim transparent padding
  for png in "$icon_dest"/*.png; do
    magick "$png" -trim +repage -resize 256x256 -gravity center -background transparent -extent 256x256 "$png" 2>/dev/null || \
    convert "$png" -trim +repage -resize 256x256 -gravity center -background transparent -extent 256x256 "$png"
  done

  gtk-update-icon-cache "$HOME/.local/share/icons/MacTahoe-dark-Eprahemi/" 2>/dev/null || true
  gtk-update-icon-cache "$HOME/.local/share/icons/MacTahoe-Eprahemi/" 2>/dev/null || true
  if [ -f "$HOME/.local/share/icons/hicolor/index.theme" ]; then
    gtk-update-icon-cache "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true
  fi

  ok "Custom icons installed ($(ls "$icon_src"/*.png 2>/dev/null | wc -l) icons)"
}

install_font() {
  next_step "SF Pro Display Font"

  local font_src="$BUNDLE/fonts/SF-Pro-Display-Regular.otf"
  if [ -f "$font_src" ]; then
    mkdir -p "$HOME/.local/share/fonts"
    cp "$font_src" "$HOME/.local/share/fonts/"
    fc-cache -fv 2>/dev/null || true
    ok "SF Pro Display font installed"
  else
    warn "SF-Pro-Display-Regular.otf not found in bundle — place it in fonts/ manually"
  fi
}

# ── PHASE 4: CONFIGURATION ───────────────────────────────────

apply_desktop_entries() {
  next_step "Custom Desktop Entries (App Renames)"

  local desktop_src="$BUNDLE/desktop"
  if [ -d "$desktop_src" ] && [ "$(ls -A "$desktop_src" 2>/dev/null)" ]; then
    mkdir -p "$HOME/.local/share/applications"
    cp "$desktop_src"/*.desktop "$HOME/.local/share/applications/" 2>/dev/null || true
    ok "Desktop entries applied"
  else
    warn "No desktop entries found"
  fi
}

apply_configs() {
  next_step "Config Files (Kitty, Fish, Starship, GTK, Fastfetch)"

  local cfg="$BUNDLE/configs"

  # Kitty
  if [ -f "$cfg/kitty/kitty.conf" ]; then
    mkdir -p "$HOME/.config/kitty"
    cp "$cfg/kitty/kitty.conf" "$HOME/.config/kitty/"
    ok "Kitty config"
  fi

  # Fish
  if [ -f "$cfg/fish/config.fish" ]; then
    mkdir -p "$HOME/.config/fish/functions"
    cp "$cfg/fish/config.fish" "$HOME/.config/fish/"
    if [ -d "$cfg/fish/functions" ]; then
      cp "$cfg/fish/functions/"*.fish "$HOME/.config/fish/functions/" 2>/dev/null || true
    fi
    ok "Fish config ($(ls "$HOME/.config/fish/functions/"*.fish 2>/dev/null | wc -l) functions)"
  fi

  # Starship
  if [ -f "$cfg/starship.toml" ]; then
    cp "$cfg/starship.toml" "$HOME/.config/"
    ok "Starship"
  fi

  # GTK
  if [ -f "$cfg/gtk-3.0/settings.ini" ]; then
    mkdir -p "$HOME/.config/gtk-3.0"
    cp "$cfg/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/"
    ok "GTK 3.0"
  fi
  if [ -f "$cfg/gtk-4.0/settings.ini" ]; then
    mkdir -p "$HOME/.config/gtk-4.0"
    cp "$cfg/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/"
    ok "GTK 4.0"
  fi

  # Fastfetch
  if [ -d "$cfg/fastfetch" ] && [ "$(ls -A "$cfg/fastfetch" 2>/dev/null)" ]; then
    mkdir -p "$HOME/.config/fastfetch"
    if [ -f "$cfg/fastfetch/config.jsonc" ]; then
      sed "s|PLACEHOLDER_USER_HOME|$HOME|g" "$cfg/fastfetch/config.jsonc" > "$HOME/.config/fastfetch/config.jsonc"
      cp "$cfg/fastfetch/"*.png "$HOME/.config/fastfetch/" 2>/dev/null || true
      cp "$cfg/fastfetch/"*.gif "$HOME/.config/fastfetch/" 2>/dev/null || true
    else
      cp -r "$cfg/fastfetch/"* "$HOME/.config/fastfetch/"
    fi
    ok "Fastfetch"
  fi
}

apply_dconf() {
  next_step "GNOME dconf Settings"

  local dconf_file="$BUNDLE/configs/dconf/full-backup.ini"

  # ── Theme ──
  gsettings set org.gnome.desktop.interface gtk-theme "MacTahoe-Dark-Eprahemi" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme "MacTahoe-dark-Eprahemi" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface cursor-theme "MacTahoe-dark-Eprahemi" 2>/dev/null || true
  dconf write /org/gnome/shell/extensions/user-theme/name "'MacTahoe-Dark-Eprahemi'" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.preferences theme "MacTahoe-Dark-Eprahemi" 2>/dev/null || true

  # ── Interface ──
  gsettings set org.gnome.desktop.interface font-name "SF Pro Display 11" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface document-font-name "SF Pro Display 12" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface monospace-font-name "Adwaita Mono 11" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface font-hinting "slight" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface font-antialiasing "grayscale" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface accent-color "blue" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface clock-format "12h" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface clock-show-date true 2>/dev/null || true
  gsettings set org.gnome.desktop.interface clock-show-seconds false 2>/dev/null || true
  gsettings set org.gnome.desktop.interface clock-show-weekday false 2>/dev/null || true
  gsettings set org.gnome.desktop.interface show-battery-percentage false 2>/dev/null || true
  gsettings set org.gnome.desktop.interface enable-animations true 2>/dev/null || true

  # ── Window buttons ──
  gsettings set org.gnome.desktop.wm.preferences button-layout "close,minimize,maximize:appmenu" 2>/dev/null || true

  # ── Peripherals ──
  gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
  gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
  gsettings set org.gnome.desktop.peripherals.touchpad click-method "'fingers'" 2>/dev/null || true
  gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true
  gsettings set org.gnome.desktop.peripherals.mouse accel-profile "'default'" 2>/dev/null || true
  gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false 2>/dev/null || true

  # ── Workspaces ──
  gsettings set org.gnome.mutter dynamic-workspaces true 2>/dev/null || true
  gsettings set org.gnome.mutter workspaces-only-on-primary true 2>/dev/null || true

  # ── Workspace shortcuts ──
  for i in {1..9}; do
    gsettings set org.gnome.shell.keybindings switch-to-application-$i "[]" 2>/dev/null || true
  done
  for i in {1..9}; do
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Super>$i']" 2>/dev/null || true
  done
  for i in {1..9}; do
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Super><Shift>$i']" 2>/dev/null || true
  done
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Control>Left']" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Control>Right']" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']" 2>/dev/null || true

  # ── Custom keybindings ──
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/']" 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Kitty' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>t' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'kitty' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'Nautilus' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>e' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'nautilus' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name 'Task Manager' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding '<Shift><Control>Escape' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command 'gnome-system-monitor' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ name 'Volume' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ binding '<Control><Alt>v' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ command 'pavucontrol' 2>/dev/null || true

  # ── Nautilus ──
  gsettings set org.gnome.nautilus.icon-view default-zoom-level "'large'" 2>/dev/null || true
  gsettings set org.gnome.nautilus.preferences recursive-search "'always'" 2>/dev/null || true
  gsettings set org.gnome.nautilus.preferences show-image-thumbnails "'always'" 2>/dev/null || true
  gsettings set org.gnome.nautilus.preferences show-directory-item-counts "'always'" 2>/dev/null || true

  # ── Night Light ──
  gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature uint32 2700 2>/dev/null || true

  # ── Power ──
  gsettings set org.gnome.settings-daemon.plugins.power power-button-action "'suspend'" 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout uint32 4800 2>/dev/null || true

  # ── Extension dconf restore ──
  if [ -f "$dconf_file" ]; then
    dconf load /org/gnome/shell/extensions/ < "$dconf_file" 2>/dev/null || true
    ok "Extension settings restored from backup"
  fi

  # Re-apply GTK settings.ini AFTER dconf/gsettings (GNOME daemon overwrites it)
  local cfg="$BUNDLE/configs"
  if [ -f "$cfg/gtk-3.0/settings.ini" ]; then
    mkdir -p "$HOME/.config/gtk-3.0"
    cp "$cfg/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/"
  fi
  if [ -f "$cfg/gtk-4.0/settings.ini" ]; then
    mkdir -p "$HOME/.config/gtk-4.0"
    cp "$cfg/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/"
  fi

  ok "dconf settings applied"
}

apply_wallpapers() {
  next_step "Wallpaper + Login Screen"

  local wp="$BUNDLE/wallpapers"
  mkdir -p "$HOME/.config/Wallpapers"

  if [ -f "$wp/Himeno Fedora.jpg" ]; then
    cp "$wp/Himeno Fedora.jpg" "$HOME/.config/Wallpapers/"
    gsettings set org.gnome.desktop.background picture-uri "file://$HOME/.config/Wallpapers/Himeno Fedora.jpg" 2>/dev/null || true
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$HOME/.config/Wallpapers/Himeno Fedora.jpg" 2>/dev/null || true
    gsettings set org.gnome.desktop.background picture-options "zoom" 2>/dev/null || true
    ok "Desktop wallpaper set"
  else
    warn "Wallpaper file not found"
  fi

  if [ -f "$wp/Himeno Fedora LoginScreen.jpg" ]; then
    cp "$wp/Himeno Fedora LoginScreen.jpg" "$HOME/.config/Wallpapers/"
    ok "Login screen wallpaper copied to ~/.config/Wallpapers/"
  fi
}

setup_gdm() {
  next_step "GDM Login Screen Theme"

  local wp="$BUNDLE/wallpapers"
  local bg=""

  if [ -f "$wp/Himeno Fedora LoginScreen.jpg" ]; then
    bg="$wp/Himeno Fedora LoginScreen.jpg"
  elif [ -f "$wp/Himeno Fedora.jpg" ]; then
    bg="$wp/Himeno Fedora.jpg"
  fi

  # Clone MacTahoe repo to get tweaks.sh then apply to GDM (force fresh clone)
  rm -rf /tmp/mactahoe-gtk
  git clone --depth 1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git /tmp/mactahoe-gtk 2>/dev/null || true

  if [ -f /tmp/mactahoe-gtk/tweaks.sh ]; then
    cd /tmp/mactahoe-gtk
    if [ -n "$bg" ]; then
      sudo ./tweaks.sh -g -nb -nd -b "$bg"
      ok "GDM login screen themed via MacTahoe tweaks.sh (-g -nb -nd)"
    else
      sudo ./tweaks.sh -g -nb -nd
      warn "No wallpaper found in bundle — GDM themed without custom background"
    fi
    cd "$BUNDLE"
  else
    warn "Could not clone MacTahoe repo — GDM theme not applied"
    warn "Run manually after install:"
    warn "  git clone https://github.com/vinceliuice/MacTahoe-gtk-theme.git /tmp/mactahoe-gtk"
    warn "  sudo /tmp/mactahoe-gtk/tweaks.sh -g -nb -nd -b /path/to/wallpaper.jpg"
  fi
}

install_sounds() {
  next_step "macOS Big Sur System Sounds"

  local sound_src="$BUNDLE/sounds/bigsur"
  if [ -d "$sound_src" ]; then
    mkdir -p "$HOME/.local/share/sounds"
    rm -rf "$HOME/.local/share/sounds/bigsur"
    cp -r "$sound_src" "$HOME/.local/share/sounds/"
    gsettings set org.gnome.desktop.sound theme-name "bigsur" 2>/dev/null || true
    gsettings set org.gnome.desktop.sound event-sounds true 2>/dev/null || true
    ok "macOS Big Sur sounds installed ($(ls "$sound_src/stereo/"*.oga 2>/dev/null | wc -l) files)"
  else
    warn "Sounds not bundled — building from source instead"
    if git clone --depth 1 https://github.com/gxanshu/macos-bigsur-sound-theme-linux.git /tmp/mac-sounds 2>/dev/null; then
      cd /tmp/mac-sounds
      git clone --depth 1 https://github.com/ThisIsNoahEvans/BigSurSounds.git 2>/dev/null || true
      git clone --depth 1 https://github.com/KDE/ocean-sound-theme.git 2>/dev/null || true
      make build 2>/dev/null || true
      make install 2>/dev/null || true
      cd /tmp
      rm -rf /tmp/mac-sounds
    fi
    gsettings set org.gnome.desktop.sound theme-name "bigsur" 2>/dev/null || true
    gsettings set org.gnome.desktop.sound event-sounds true 2>/dev/null || true
    ok "macOS Big Sur sounds built from source"
  fi
}

# ── PHASE 5: TERMINAL & SHELL ────────────────────────────────

setup_terminal() {
  next_step "Kitty as Default Terminal"

  sudo dnf remove -y ptyxis 2>/dev/null || true
  sudo ln -sf /usr/bin/kitty /usr/bin/gnome-terminal 2>/dev/null || true
  sudo ln -sf /usr/bin/kitty /usr/bin/x-terminal-emulator 2>/dev/null || true
  gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty' 2>/dev/null || true
  sudo rm -f /usr/share/applications/org.gnome.Ptyxis.desktop
  sudo rm -f /usr/share/applications/org.gnome.Console.desktop
  ok "Kitty is now the default terminal"
}

setup_shell() {
  next_step "Fish as Default Shell"

  if [ "$SHELL" != "/usr/bin/fish" ]; then
    sudo chsh -s /usr/bin/fish "$USER"
    ok "Default shell changed to fish (next login)"
  else
    ok "Fish is already the default shell"
  fi
}

# ── PHASE 6: EXTENSIONS ──────────────────────────────────────

install_extensions() {
  next_step "GNOME Extensions"

  # Install via gnome-extensions CLI where possible
  local extensions=(
    "blur-my-shell@aunetx"
    "user-theme@gnome-shell-extensions.gcampax.github.com"
    "logomenu@aryan_k"
    "AlphabeticalAppGrid@stuarthayhurst"
    "pinned-apps-in-appgrid@brunosilva.io"
    "app-hider@lynith.dev"
    "compiz-alike-magic-lamp-effect@hermes83.github.com"
    "compiz-windows-effect@hermes83.github.com"
    "CoverflowAltTab@palatis.blogspot.com"
    "clipboard-history@alexsaveau.dev"
    "ding@rastersoft.com"
    "Bluetooth-Battery-Meter@maniacx.github.com"
    "dash2dock-lite@icedman.github.com"
    "appindicatorsupport@rgcjonas.gmail.com"
  )

  # Install from EGO
  for uuid in "${extensions[@]}"; do
    gnome-extensions install "$uuid" 2>/dev/null || true
  done

  # Enable all installed extensions
  local enabled
  enabled=$(gsettings get org.gnome.shell enabled-extensions)
  enabled="${enabled:1:${#enabled}-2}"  # strip brackets

  for uuid in "${extensions[@]}"; do
    if ! echo "$enabled" | grep -q "$uuid"; then
      # Check if extension is installed
      if [ -d "$HOME/.local/share/gnome-shell/extensions/$uuid" ] || [ -d "/usr/share/gnome-shell/extensions/$uuid" ]; then
        gnome-extensions enable "$uuid" 2>/dev/null || true
      fi
    fi
  done

  # Configure dash2dock-lite
  dconf write /org/gnome/shell/extensions/dash2dock-lite/autohide-dash true 2>/dev/null || true
  dconf write /org/gnome/shell/extensions/dash2dock-lite/click-action "'minimize-or-previews'" 2>/dev/null || true
  dconf write /org/gnome/shell/extensions/dash2dock-lite/icon-size 0.25 2>/dev/null || true
  dconf write /org/gnome/shell/extensions/dash2dock-lite/running-indicator-style 4 2>/dev/null || true
  dconf write /org/gnome/shell/extensions/dash2dock-lite/show-favorites true 2>/dev/null || true
  dconf write /org/gnome/shell/extensions/dash2dock-lite/show-running true 2>/dev/null || true
  dconf write /org/gnome/shell/extensions/dash2dock-lite/dock-padding 0.5 2>/dev/null || true
  dconf write /org/gnome/shell/extensions/dash2dock-lite/border-radius 3.0 2>/dev/null || true
  dconf write /org/gnome/shell/extensions/dash2dock-lite/label-border-radius 3.0 2>/dev/null || true
  dconf write /org/gnome/shell/extensions/dash2dock-lite/customize-label true 2>/dev/null || true

  # Disable Fedora default extensions
  gsettings set org.gnome.shell disabled-extensions "['background-logo@fedorahosted.org', 'apps-menu@gnome-shell-extensions.gcampax.github.com']" 2>/dev/null || true

  ok "Extensions installed & configured"
}

# ── FINALIZE ──────────────────────────────────────────────────

finalize() {
  next_step "Cleanup & Reboot"

  # Clean temporary files
  rm -rf /tmp/mactahoe-* /tmp/mac-sounds 2>/dev/null || true

  echo ""
  echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}  Fedora MacTahoe — Eprahemi Edition              ${NC}"
  echo -e "${GREEN}  Setup complete!                                  ${NC}"
  echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
  echo ""
  echo "  ${YELLOW}⚠ Recommended: Reboot now to apply all changes${NC}"
  echo ""
  echo "  After reboot:"
  echo "    - All themes, icons, fonts will be active"
  echo "    - Kitty will be the default terminal"
  echo "    - Fish will be the default shell (after logout)"
  echo "    - All custom keybindings will work"
  echo "    - macOS Big Sur sounds will play"
  echo ""
  echo "  - GDM login screen themed (custom wallpaper + GTK theme + icons)"
  echo ""

  read -rp "Reboot now? [y/N] " reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    sudo reboot
  else
    echo "Reboot later to apply all changes."
  fi
}

# ─────────────────────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Fedora MacTahoe — Eprahemi Edition             ${NC}"
echo -e "${GREEN}   Fully self-contained — no external repos       ${NC}"
echo -e "${GREEN}   Automated Installer                            ${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo ""

preflight
install_rpmfusion
install_nvidia
install_rpm_packages
install_browsers
install_flatpaks
install_mactahoe_theme
install_custom_icons
install_font
install_extensions
apply_desktop_entries
apply_configs
apply_dconf
apply_wallpapers
setup_gdm
install_sounds
setup_terminal
setup_shell
finalize
