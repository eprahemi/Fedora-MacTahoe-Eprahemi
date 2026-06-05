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
BOLD='\033[1m'; WHITE='\033[1;37m'; DIM='\033[2m'

log()   { echo -e "  ${CYAN}${DIM}┊${NC} ${CYAN}$(date +%H:%M:%S)${NC} ${DIM}┊${NC} $1"; }
ok()    { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail()  { echo -e "  ${RED}✗${NC} $1"; exit 1; }

TOTAL_STEPS=21
STEP=0

next_step() {
  STEP=$((STEP + 1))
  echo ""
  echo -e "  ${CYAN}◆${NC}  ${YELLOW}${BOLD}Step ${STEP}/${TOTAL_STEPS}${NC}  ${WHITE}${BOLD}$1${NC}"
  echo -e "  ${DIM}───────────────────────────────────────────────────────────${NC}"
}

phase_divider() {
  echo ""
  echo -e "  ${DIM}╭─${NC} ${CYAN}$1${NC} ${DIM}${NC}"
  echo -e "  ${DIM}├──────────────────────────────────────────────────────────${NC}"
}

banner() {
  echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "  ${CYAN}║${NC}  ${BOLD}${WHITE}$1${NC}"
  echo -e "  ${CYAN}║${NC}  ${DIM}$2${NC}"
  echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
}

# ── PREFLIGHT ────────────────────────────────────────────────

preflight() {
  next_step "Preflight checks"

  # ── Terminal check (must be running in Kitty) ──
  if [ -z "${KITTY_PID:-}" ]; then
    # Walk up the process tree until we find a known terminal emulator
    local detected_term="" walk_pid=$PPID comm
    while [ "$walk_pid" -gt 1 ] 2>/dev/null; do
      comm=$(cat /proc/"$walk_pid"/comm 2>/dev/null || echo "")
      case "$comm" in
        ptyxis|gnome-ptyxis|kgx|gnome-terminal-|kitty|alacritty|wezterm|foot|urxvt|st|xterm)
          detected_term=$comm
          break
          ;;
      esac
      walk_pid=$(cat /proc/"$walk_pid"/status 2>/dev/null | awk '/^PPid:/{print $2}')
    done

    # Block Ptyxis (it gets removed during installation)
    if [ "$detected_term" = "ptyxis" ] || [ "$detected_term" = "gnome-ptyxis" ]; then
      echo ""
      echo -e "  ╔══════════════════════════════════════════════════════════════╗"
      echo -e "  ║            ⛔  UNSUPPORTED TERMINAL DETECTED                  ║"
      echo -e "  ╠══════════════════════════════════════════════════════════════╣"
      echo -e "  ║                                                              ║"
      echo -e "  ║  You are currently running inside ${BOLD}Ptyxis${NC}, the default          ║"
      echo -e "  ║  Fedora terminal emulator. This installer is designed to      ║"
      echo -e "  ║  completely replace Ptyxis with Kitty as the system terminal  ║"
      echo -e "  ║  and will ${BOLD}${RED}remove${NC} Ptyxis during the installation process.         ║"
      echo -e "  ║                                                              ║"
      echo -e "  ║  ${YELLOW}╳${NC}  Running the installer from inside Ptyxis would:            ║"
      echo -e "  ║     • Uninstall the terminal you are currently using          ║"
      echo -e "  ║     • Crash the installation process mid-way                  ║"
      echo -e "  ║     • Potentially corrupt your session or lose unsaved work  ║"
      echo -e "  ║                                                              ║"
      echo -e "  ║  ${GREEN}✓${NC}  To proceed with the installation:                          ║"
      echo -e "  ║                                                              ║"
      echo -e "  ║  ${BOLD}Step 1${NC}  Install Kitty terminal:                                 ║"
      echo -e "  ║       sudo dnf install kitty                                 ║"
      echo -e "  ║                                                              ║"
      echo -e "  ║  ${BOLD}Step 2${NC}  Launch Kitty and re-run the installer:                   ║"
      echo -e "  ║       kitty -e bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh)\" ║"
      echo -e "  ║                                                              ║"
      echo -e "  ║  ${YELLOW}Note:${NC} You can keep Ptyxis as a secondary terminal if you wish,   ║"
      echo -e "  ║  but Kitty is required as the primary terminal for the       ║"
      echo -e "  ║  MacTahoe experience to function correctly.                  ║"
      echo -e "  ║                                                              ║"
      echo -e "  ╚══════════════════════════════════════════════════════════════╝"
      echo ""
      exit 1
    fi

    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │  ✦  PREMIUM TERMINAL RECOMMENDED  ✦                       │"
    echo "  ├─────────────────────────────────────────────────────────────┤"
    echo "  │  You are currently running inside a standard terminal       │"
    echo "  │  emulator. The Fedora MacTahoe experience is engineered     │"
    echo "  │  and tested exclusively on Kitty terminal for the most      │"
    echo "  │  authentic macOS-like desktop transformation.               │"
    echo "  │                                                             │"
    echo "  │  By switching to Kitty, you gain access to:                 │"
    echo "  │  ◆ Native true-color support for accurate color rendering   │"
    echo "  │  ◆ GPU-accelerated rendering for buttery-smooth scrolling   │"
    echo "  │  ◆ Seamless glass-blur integration with the GNOME desktop   │"
    echo "  │  ◆ Custom tab bar styling that matches the MacTahoe theme   │"
    echo "  │  ◆ Keyboard-driven nature with sane defaults and ligatures  │"
    echo "  │                                                             │"
    echo "  │  Install Kitty and re-run the installer:                    │"
    echo "  │    sudo dnf install kitty                                   │"
    echo "  │    kitty -e bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/eprahemi/Fedora-MacTahoe-Eprahemi/main/bootstrap.sh)\" │"
    echo "  │                                                             │"
    echo "  │  Press SPACE to acknowledge and continue                      │"
    echo "  │  or press Ctrl+C to cancel and switch to Kitty first.       │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
    # First space: acknowledge the warning
    while true; do
      read -r -s -n 1 key
      if [ "$key" = " " ]; then break; fi
    done
    # Second space: confirm you really want to proceed
    echo ""
    echo -e "  ┌─────────────────────────────────────────────────────────────┐"
    echo -e "  │  ${BOLD}${YELLOW}⚠  Confirm Installation Without Kitty${NC}                        │"
    echo -e "  ├─────────────────────────────────────────────────────────────┤"
    echo -e "  │  You are about to proceed without the recommended terminal. │"
    echo -e "  │  Some visual features may not render as intended, and the   │"
    echo -e "  │  overall experience may differ from the MacTahoe design.    │"
    echo -e "  │                                                             │"
    echo -e "  │  Press ${BOLD}SPACE${NC} to confirm and continue                              │"
    echo -e "  │  Press ${BOLD}Ctrl+C${NC} to cancel and install Kitty first                     │"
    echo -e "  └─────────────────────────────────────────────────────────────┘"
    echo -n "  ${DIM}Waiting for confirmation...${NC} "
    while true; do
      read -r -s -n 1 key
      if [ "$key" = " " ]; then
        echo -e "${GREEN}confirmed${NC}"
        break
      fi
    done
  fi

  # ── OS check ──
  local detected_os="Unknown Linux"
  if [ -f /etc/os-release ]; then
    detected_os=$(grep -oP '^NAME="?\K[^"]+' /etc/os-release 2>/dev/null || echo "Unknown Linux")
  fi
  if [ ! -f /etc/fedora-release ]; then
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║            INCOMPATIBLE OPERATING SYSTEM                    ║"
    echo "  ╠══════════════════════════════════════════════════════════════╣"
    echo "  ║  Detected OS :  $detected_os"
    echo "  ║  Required OS :  Fedora Linux (Workstation edition)"  
    echo "  ║                                                              ║"
    echo "  ║  Fedora MacTahoe — Eprahemi Edition is designed exclusively  ║"
    echo "  ║  for Fedora Linux with the GNOME desktop environment. It     ║"
    echo "  ║  relies on Fedora-specific package managers (dnf), RPM       ║"
    echo "  ║  repositories (RPM Fusion), and system paths that do not     ║"
    echo "  ║  exist on other distributions.                               ║"
    echo "  ║                                                              ║"
    echo "  ║  To use this theme, install Fedora Workstation from:         ║"
    echo "  ║  https://fedoraproject.org/workstation/                      ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo ""
    exit 1
  fi
  ok "Fedora detected"

  # ── Desktop environment check ──
  local gnome_ok=false
  if command -v gnome-shell &>/dev/null; then
    gnome_ok=true
  fi
  # Detect actual desktop (for error messages)
  local detected_desk="${XDG_CURRENT_DESKTOP:-}"
  if [ -z "$detected_desk" ]; then
    detected_desk="${GDMSESSION:-}"
  fi
  if [ -z "$detected_desk" ]; then
    detected_desk="${DESKTOP_SESSION:-}"
  fi
  if [ -z "$detected_desk" ]; then
    detected_desk="none (TTY / no graphical session detected)"
  fi
  # If a desktop session is running, double-check it's actually GNOME
  if [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
    if echo "$XDG_CURRENT_DESKTOP" | grep -qi "gnome"; then
      gnome_ok=true
    else
      echo ""
      echo "  ╔══════════════════════════════════════════════════════════════╗"
      echo "  ║            INCOMPATIBLE DESKTOP ENVIRONMENT                 ║"
      echo "  ╠══════════════════════════════════════════════════════════════╣"
      echo "  ║  Detected DE :  ${detected_desk}"
      echo "  ║  Required DE :  GNOME (default Fedora Workstation desktop)"  
      echo "  ║                                                              ║"
      echo "  ║  Fedora MacTahoe — Eprahemi Edition integrates deeply       ║"
      echo "  ║  with GNOME Shell extensions, dconf/gsettings schemas,      ║"
      echo "  ║  and GNOME-specific D-Bus APIs. These components are not    ║"
      echo "  ║  available on other desktop environments.                   ║"
      echo "  ║                                                              ║"
      echo "  ║  Switch to Fedora Workstation (GNOME) or install GNOME:     ║"
      echo "  ║    sudo dnf groupinstall 'Fedora Workstation'               ║"
      echo "  ╚══════════════════════════════════════════════════════════════╝"
      echo ""
      exit 1
    fi
  fi
  if [ "$gnome_ok" = false ]; then
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║            GNOME SHELL NOT FOUND                            ║"
    echo "  ╠══════════════════════════════════════════════════════════════╣"
    echo "  ║  Detected DE :  ${detected_desk}"
    echo "  ║  Required DE :  GNOME (default Fedora Workstation desktop)"  
    echo "  ║                                                              ║"
    echo "  ║  The gnome-shell binary is not installed on this system.     ║"
    echo "  ║  This script cannot proceed without it.                      ║"
    echo "  ║                                                              ║"
    echo "  ║  To install GNOME on Fedora, run:                            ║"
    echo "  ║    sudo dnf groupinstall 'Fedora Workstation'                ║"
    echo "  ║    sudo systemctl set-default graphical.target                ║"
    echo "  ║    sudo reboot                                               ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo ""
    exit 1
  fi
  ok "GNOME desktop detected"

  # ── User check ──
  if [ "$EUID" -eq 0 ]; then
    fail "Do NOT run as root. Run as your normal user — sudo prompts will appear."
  fi
  ok "Running as normal user"

  # ── Network check ──
  if ! ping -c1 -W2 google.com &>/dev/null && ! ping -c1 -W2 github.com &>/dev/null; then
    fail "No internet connection detected."
  fi
  ok "Internet connection"

  # ── Sudo check ──
  if ! sudo -n true 2>/dev/null; then
    warn "You will be prompted for sudo password shortly."
  fi
  sudo echo "Sudo OK" >/dev/null || fail "Sudo required"
  ok "Sudo access granted"
}

# ── PTYXIS REMOVAL ───────────────────────────────────────────

remove_ptyxis() {
  next_step "Remove Ptyxis (system terminal)"

  if rpm -q ptyxis &>/dev/null; then
    log "Removing Ptyxis package..."
    sudo dnf remove -y ptyxis 2>&1 | tail -1 || true
    ok "Ptyxis package removed"
  else
    ok "Ptyxis not installed — nothing to remove"
  fi

  # User config
  rm -rf "$HOME/.config/org.gnome.Ptyxis" 2>/dev/null || true
  # User data (palettes, sessions)
  rm -rf "$HOME/.local/share/org.gnome.Ptyxis" 2>/dev/null || true
  # GNOME Software cache icons
  find "$HOME/.cache/gnome-software" -name "*ptyxi*" -delete 2>/dev/null || true
  # Dconf profiles and settings
  dconf reset -f /org/gnome/Ptyxis/ 2>/dev/null || true
  # Desktop entry
  sudo rm -f /usr/share/applications/org.gnome.Ptyxis.desktop 2>/dev/null || true
  sudo rm -f /usr/share/applications/org.gnome.Console.desktop 2>/dev/null || true
  # MacTahoe theme icon for Ptyxis
  find "$HOME/.local/share/icons" -path "*MacTahoe*ptyxis*" -delete 2>/dev/null || true
  # Symlinks that may point to Ptyxis
  sudo rm -f /usr/bin/gnome-terminal 2>/dev/null || true
  sudo rm -f /usr/bin/x-terminal-emulator 2>/dev/null || true

  # Verify no traces remain
  local leftover_config leftover_data leftover_dconf
  leftover_config=$(find "$HOME/.config" -maxdepth 1 -name "*Ptyxis*" 2>/dev/null)
  leftover_data=$(find "$HOME/.local/share" -maxdepth 1 -name "*Ptyxis*" 2>/dev/null)
  leftover_dconf=$(dconf dump /org/gnome/Ptyxis/ 2>/dev/null)
  if [ -z "$leftover_config" ] && [ -z "$leftover_data" ] && [ -z "$leftover_dconf" ]; then
    ok "All Ptyxis traces cleaned"
  else
    warn "Some Ptyxis traces may remain — manual check recommended"
  fi
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

  nvidia_found=false
  lspci 2>/dev/null | grep -qi nvidia && nvidia_found=true
  lsmod 2>/dev/null | grep -qi nouveau && nvidia_found=true
  if [ "$nvidia_found" = true ]; then
    echo ""
    echo -e "  ${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${YELLOW}║${NC}  ${BOLD}NVIDIA DETECTED${NC}                                               ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}  On a ${BOLD}fresh Fedora install${NC}, the open-source nouveau driver      ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}  can switch to basic modes (e.g. 800×600) once the           ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}  proprietary NVIDIA driver is installed mid-install.          ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}  ${BOLD}Recommended before running this script:${NC}                       ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}    1. Connect to ethernet or WiFi (ethernet recommended)        ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}    2. ${BOLD}sudo dnf upgrade${NC}                                        ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}    3. Reboot                                                    ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}    4. Run installer again                                        ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}                                                              ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}  If you already did that, proceed below.                      ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -n "  ${DIM}Press SPACE to continue...${NC} "
    while true; do
      read -r -s -n 1 key
      if [ "$key" = " " ]; then
        echo -e "${GREEN}continuing${NC}"
        break
      fi
    done
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
    ffmpeg-free \
    libreoffice-writer libreoffice-calc libreoffice-impress

  # Starship prompt (not in Fedora repos — install via official script)
  if ! command -v starship &>/dev/null; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y 2>/dev/null || true
  fi

  ok "RPM packages installed"
}

install_browsers() {
  next_step "Browsers (Firefox, Chrome, Edge, VS Code)"

  # Firefox
  if ! rpm -q firefox &>/dev/null; then
    sudo dnf install -y firefox
  fi

  # Chrome — create repo file directly (--from-repofile not supported by Google)
  if ! rpm -q google-chrome-stable &>/dev/null; then
    sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub 2>/dev/null || true
    sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null <<-EOF
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
    # Install from repo, with direct RPM as offline fallback
    sudo dnf install -y google-chrome-stable 2>/dev/null || \
    sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
  fi

  # Edge — create repo file directly (--from-repofile URL is non-standard)
  if ! rpm -q microsoft-edge-stable &>/dev/null; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true
    sudo tee /etc/yum.repos.d/microsoft-edge.repo > /dev/null <<-EOF
[microsoft-edge]
name=microsoft-edge
baseurl=https://packages.microsoft.com/yumrepos/edge-stable
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    sudo dnf install -y microsoft-edge-stable 2>/dev/null || true
  fi

  # VS Code — repo file (existing working approach)
  if ! rpm -q code &>/dev/null; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true
    sudo tee /etc/yum.repos.d/vscode.repo > /dev/null <<-EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    sudo dnf check-update 2>/dev/null || true
    sudo dnf install -y code
  fi

  ok "Browsers + VS Code installed (Spotify via Flatpak)"
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
  next_step "MacTahoe GTK Theme (compiled from source)"

  local repo="/tmp/mactahoe-build"
  local gtk_version
  gtk_version=$(gnome-shell --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1 || echo "unknown")

  # Purge leftovers
  rm -rf "$HOME/.themes/MacTahoe"* "$HOME/.local/share/themes/MacTahoe"*
  sudo rm -rf /usr/share/themes/MacTahoe* 2>/dev/null || true

  # Clone and compile for current GNOME version
  log "Cloning MacTahoe source (GNOME $gtk_version)..."
  rm -rf "$repo"
  git clone --depth 1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$repo" 2>/dev/null || {
    warn "Clone failed — falling back to bundled pre-compiled theme"
    local fallback_dir="$BUNDLE/themes/MacTahoe-Dark"
    if [ -d "$fallback_dir" ]; then
      mkdir -p "$HOME/.themes" "$HOME/.local/share/themes" "$HOME/.config/gtk-4.0"
      cp -r "$fallback_dir" "$HOME/.themes/"
      cp -r "$fallback_dir" "$HOME/.local/share/themes/"
      cp -r "$fallback_dir/gtk-4.0/"* "$HOME/.config/gtk-4.0/" 2>/dev/null || true
      ok "Bundled MacTahoe-Dark installed as fallback"
    else
      warn "No fallback available — theme not installed"
    fi
    return
  }

  log "Compiling all theme variants with blur + libadwaita..."
  "$repo/install.sh" -t all -b -l 2>&1 || {
    warn "Compilation failed — theme not installed"
    return
  }

  # XDG compat: also available in ~/.local/share/themes/
  mkdir -p "$HOME/.local/share/themes"
  for d in "$HOME/.themes/MacTahoe"*; do
    [ -d "$d" ] || continue
    local base; base=$(basename "$d")
    rm -rf "$HOME/.local/share/themes/$base"
    cp -a "$d" "$HOME/.local/share/themes/$base"
  done

  ok "MacTahoe theme compiled & installed for GNOME $gtk_version"

  # ── Icon themes (always from bundle, never change) ─────────

  local theme_src="$BUNDLE/themes"

  # Clean stale icon theme directories/symlinks from previous installs
  for stale in MacTahoe MacTahoe-dark MacTahoe-light MacTahoe-Eprahemi MacTahoe-dark-Eprahemi; do
    rm -rf "$HOME/.local/share/icons/$stale" 2>/dev/null || true
  done

  for icon in MacTahoe MacTahoe-dark; do
    mkdir -p "$HOME/.local/share/icons"
    cp -a "$theme_src/$icon" "$HOME/.local/share/icons/"
    # Ensure Adwaita is in the inheritance chain (needed for ui/ icons like checkboxes)
    if ! grep -q "Adwaita" "$HOME/.local/share/icons/$icon/index.theme" 2>/dev/null; then
      sed -i 's/Inherits=hicolor,breeze/Inherits=hicolor,breeze,Adwaita/' \
        "$HOME/.local/share/icons/$icon/index.theme"
    fi
    # Provide Showtime skip-10-second icons with proper currentColor
    # (Showtime bundles its own but they use hardcoded #222222 fill — invisible on dark overlay)
    for dir in "actions/symbolic" "actions/24"; do
      mkdir -p "$HOME/.local/share/icons/$icon/$dir"
      for f in "$theme_src/$icon/$dir/skip-backwards-10-symbolic.svg" \
               "$theme_src/$icon/$dir/skip-forward-10-symbolic.svg"; do
        [ -f "$f" ] && cp -f "$f" "$HOME/.local/share/icons/$icon/$dir/"
      done
    done
    gtk-update-icon-cache "$HOME/.local/share/icons/$icon/" 2>/dev/null || true
  done

  ok "Icon themes installed (MacTahoe + MacTahoe-dark)"

  # Custom macOS app icons (SVG+PNG) — ALWAYS OVERRIDE on conflict
  local icon_src="$BUNDLE/icons/256x256"
  if [ -d "$icon_src" ] && [ "$(ls -A "$icon_src"/*.png "$icon_src"/*.svg 2>/dev/null)" ]; then
    local targets=(
      "$HOME/.local/share/icons/MacTahoe-dark/apps/scalable"
      "$HOME/.local/share/icons/MacTahoe/apps/scalable"
      "$HOME/.local/share/icons/hicolor/256x256/apps"
    )
    mkdir -p "${targets[@]}"

    # Copy SVGs first (preferred format for scalable)
    for svg in "$icon_src"/*.svg; do
      [ -f "$svg" ] || continue
      f=$(basename "$svg")
      for t in "${targets[@]}"; do cp -f "$svg" "$t/$f"; done
    done

    # Also copy PNGs as fallback for older apps
    for png in "$icon_src"/*.png; do
      [ -f "$png" ] || continue
      f=$(basename "$png")
      for t in "${targets[@]}"; do cp -f "$png" "$t/$f"; done
    done

    # Flatpak app IDs need their full reverse-DNS name to get themed
    # Map short name → Flatpak ID so both native and Flatpak installs pick it up
    declare -A fp_aliases=(
      [spotify.png]="com.spotify.Client.png"
      [discord.png]="com.discordapp.Discord.png"
      [vlc.png]="org.videolan.VLC.png"
      [code.png]="com.visualstudio.code.png"
    )
    # SVG aliases
    for svg in "$icon_src"/*.svg; do
      [ -f "$svg" ] || continue
      local base; base=$(basename "$svg")
      local base_noext="${base%.svg}"
      local alias_svg="${fp_aliases[${base_noext}.png]:-}"
      [ -z "$alias_svg" ] && continue
      local alias_svg_name="${alias_svg%.png}.svg"
      for t in "${targets[@]}"; do cp -f "$svg" "$t/$alias_svg_name"; done
    done
    # PNG aliases
    for png in "$icon_src"/*.png; do
      [ -f "$png" ] || continue
      local base; base=$(basename "$png")
      local alias_png="${fp_aliases[$base]:-}"
      [ -z "$alias_png" ] && continue
      for t in "${targets[@]}"; do cp -f "$png" "$t/$alias_png"; done
    done

    # Trim padding + resize to 256×256 (PNGs only — SVGs are already correct)
    for t in "${targets[@]}"; do
      for png in "$t"/*.png; do
        [ -f "$png" ] || continue
        magick "$png" -trim +repage -resize 256x256 -gravity center -background transparent -extent 256x256 "$png" 2>/dev/null || \
        convert "$png" -trim +repage -resize 256x256 -gravity center -background transparent -extent 256x256 "$png"
      done
    done

    # ALWAYS rebuild icon cache last (ensures custom icons override any conflicts)
    gtk-update-icon-cache "$HOME/.local/share/icons/MacTahoe-dark/" 2>/dev/null || true
    gtk-update-icon-cache "$HOME/.local/share/icons/MacTahoe/" 2>/dev/null || true
    # Ensure hicolor has an index.theme so gtk-update-icon-cache works
    if [ ! -f "$HOME/.local/share/icons/hicolor/index.theme" ]; then
      cat > "$HOME/.local/share/icons/hicolor/index.theme" <<-EOF
[Icon Theme]
Name=Hicolor
Comment=Fallback icon theme (local overrides)
Hidden=true
Directories=256x256/apps
EOF
    fi
    gtk-update-icon-cache "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true
    ok "Custom macOS app icons installed ($(ls "$icon_src"/*.png 2>/dev/null | wc -l) PNGs + $(ls "$icon_src"/*.svg 2>/dev/null | wc -l) SVGs)"
  fi
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

  # Clean up any leftover nautilus-maximized references (wrapper was removed)
  if [ -f "$HOME/.local/share/applications/org.gnome.Nautilus.desktop" ]; then
    if grep -q "nautilus-maximized" "$HOME/.local/share/applications/org.gnome.Nautilus.desktop" 2>/dev/null; then
      rm -f "$HOME/.local/share/applications/org.gnome.Nautilus.desktop"
      ok "Nautilus desktop entry cleaned (was referencing deleted wrapper)"
    fi
  fi

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
  gsettings set org.gnome.desktop.interface gtk-theme "MacTahoe-Dark" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme "MacTahoe-dark" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface cursor-theme "MacTahoe-dark" 2>/dev/null || true
  dconf write /org/gnome/shell/extensions/user-theme/name "'MacTahoe-Dark'" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.preferences theme "MacTahoe-Dark" 2>/dev/null || true

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

  # ── Window buttons (no double-click toggle) ──
  gsettings set org.gnome.desktop.wm.preferences button-layout "close,minimize,maximize:appmenu" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar "'none'" 2>/dev/null || true

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

  # ── Dock favorites ──
  gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'org.mozilla.firefox.desktop', 'google-chrome.desktop', 'microsoft-edge.desktop', 'discord.desktop', 'kitty.desktop', 'org.gnome.Software.desktop']" 2>/dev/null || true

  # ── Session (never sleep) ──
  gsettings set org.gnome.desktop.session idle-delay 0 2>/dev/null || true

  # ── Privacy ──
  gsettings set org.gnome.desktop.privacy report-technical-problems false 2>/dev/null || true

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

setup_firefox_theme() {
  next_step "Firefox macOS Theme (userChrome.css)"

  local repo="/tmp/mactahoe-gtk"
  if [ ! -f "$repo/tweaks.sh" ]; then
    warn "MacTahoe repo not found — cloning fresh"
    rm -rf "$repo"
    git clone --depth 1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git "$repo" 2>/dev/null || {
      warn "Could not clone MacTahoe repo — Firefox theme not applied"
      return
    }
  fi

  killall firefox firefox-bin 2>/dev/null || true

  if ! "$repo/tweaks.sh" -f 2>&1; then
    warn "Firefox theming skipped — not yet initialized"
    FIREFOX_THEME_FAILED=1
  fi
}

setup_flatpak_theme() {
  next_step "Flatpak GTK Runtime (org.gtk.Gtk3theme.MacTahoe-Dark)"

  sudo dnf install -y ostree libappstream-glib 2>/dev/null || {
    warn "Could not install ostree/appstream-glib — Flatpak theme skipped"
    return
  }

  local THEME="MacTahoe-Dark"
  local GTK3_VER="3.22"
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}"
  local pkg_cache="$cache/pakitheme/$THEME"
  local repo_dir="$pkg_cache/repo"
  local build_dir="$pkg_cache/build"
  local app_id="org.gtk.Gtk3theme.$THEME"
  local theme_path=""

  for loc in "$HOME/.local/share/themes" "$HOME/.themes" /usr/share/themes; do
    if [ -d "$loc/$THEME" ]; then
      theme_path="$loc/$THEME"; break
    fi
  done

  if [ -z "$theme_path" ]; then
    warn "Theme '$THEME' not found in any theme directory"
    return
  fi

  rm -rf "$pkg_cache"
  mkdir -p "$repo_dir"

  ostree --repo="$repo_dir" init --mode=archive || true
  ostree --repo="$repo_dir" config set core.min-free-space-percent 0 || true

  rm -rf "$build_dir"
  mkdir -p "$build_dir/files"
  cp -a "$theme_path/gtk-3.0/"{gtk.css,gtk-dark.css,thumbnail.png,assets,windows-assets} "$build_dir/files" 2>/dev/null || true

  mkdir -p "$build_dir/files/share/appdata"
  cat >"$build_dir/files/share/appdata/$app_id.appdata.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="runtime">
  <id>$app_id</id>
  <metadata_license>CC0-1.0</metadata_license>
  <name>$THEME Gtk theme</name>
  <summary>$THEME Gtk theme for flatpak</summary>
</component>
EOF

  appstream-compose --prefix="$build_dir/files" --basename="$app_id" --origin=flatpak "$app_id" 2>/dev/null || true
  ostree --repo="$repo_dir" commit -b base --tree=dir="$build_dir" || true

  local bundles=()
  while IFS= read -r arch; do
    [ -z "$arch" ] && continue
    bundle="$pkg_cache/$app_id-$arch.flatpak"
    rm -rf "$build_dir"
    ostree --repo="$repo_dir" checkout -U base "$build_dir" || continue

    read -rd '' metadata <<EOF ||:
[Runtime]
name=$app_id
runtime=$app_id/$arch/$GTK3_VER
sdk=$app_id/$arch/$GTK3_VER
EOF
    echo -n "$metadata" > "$build_dir/metadata"

    ostree --repo="$repo_dir" commit -b "runtime/$app_id/$arch/$GTK3_VER" \
      --add-metadata-string "xa.metadata=$(cat "$build_dir/metadata")" --link-checkout-speedup "$build_dir" || continue
    flatpak build-bundle --runtime "$repo_dir" "$bundle" "$app_id" "$GTK3_VER" || continue
    bundles+=("$bundle")
  done < <(flatpak list --runtime --columns=arch:f 2>/dev/null | sort -u)

  if [ ${#bundles[@]} -eq 0 ]; then
    warn "No Flatpak architectures found — no runtime bundles built"
    return
  fi

  for bundle in "${bundles[@]}"; do
    sudo flatpak install -y --system "$bundle" 2>/dev/null || true
    rm -f "$bundle" 2>/dev/null || true
  done

  ok "Flatpak runtime '$app_id' installed (${#bundles[@]} arch(s))"
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

  # Ptyxis already removed earlier in remove_ptyxis()
  sudo ln -sf /usr/bin/kitty /usr/bin/gnome-terminal 2>/dev/null || true
  sudo ln -sf /usr/bin/kitty /usr/bin/x-terminal-emulator 2>/dev/null || true
  gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty' 2>/dev/null || true

  # Copy desktop entry with Name=Terminal (from repo, fallback to system)
  mkdir -p "$HOME/.local/share/applications"
  cp "$BUNDLE/desktop/kitty.desktop" "$HOME/.local/share/applications/kitty.desktop" 2>/dev/null || \
    cp /usr/share/applications/kitty.desktop "$HOME/.local/share/applications/kitty.desktop" 2>/dev/null

  # Scan all users for stale kitty.desktop referencing deleted kitty-maximized wrapper
  # or with Name=kitty (won't match GNOME "Terminal" search)
  local desktop_src
  desktop_src="$BUNDLE/desktop/kitty.desktop"
  [ -f "$desktop_src" ] || desktop_src="/usr/share/applications/kitty.desktop"
  if [ -f "$desktop_src" ]; then
    for _h in /home/*; do
      _entry="$_h/.local/share/applications/kitty.desktop"
      if [ -f "$_entry" ] && grep -q "kitty-maximized\|^Name=kitty$" "$_entry" 2>/dev/null; then
        _owner=$(stat -c '%U' "$_h" 2>/dev/null || echo root)
        if [ "$_owner" != "root" ]; then
          cp "$desktop_src" "$_entry" 2>/dev/null && chown "$_owner:" "$_entry" 2>/dev/null
          log "Fixed stale kitty.desktop for $_owner"
        fi
      fi
      unset _entry _owner
    done
  fi
  unset desktop_src _h

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

  # Install from EGO using API (CLI install $uuid requires browser session)
  local shell_version
  shell_version=$(gnome-shell --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1 || echo "50")
  for uuid in "${extensions[@]}"; do
    local dl_url
    dl_url=$(curl -s "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$shell_version" | jq -r '.download_url // empty' 2>/dev/null)
    if [ -n "$dl_url" ]; then
      rm -f /tmp/ext-"$uuid".zip
      curl -sL "https://extensions.gnome.org$dl_url" -o /tmp/ext-"$uuid".zip 2>/dev/null
      gnome-extensions install --force /tmp/ext-"$uuid".zip 2>/dev/null || true
      rm -f /tmp/ext-"$uuid".zip
    fi
  done

  # Enable all installed extensions via direct gsettings (no D-Bus needed)
  local -a ext_list
  for uuid in "${extensions[@]}"; do
    if [ -d "$HOME/.local/share/gnome-shell/extensions/$uuid" ] || [ -d "/usr/share/gnome-shell/extensions/$uuid" ]; then
      ext_list+=("'$uuid'")
    fi
  done
  if [ ${#ext_list[@]} -gt 0 ]; then
    gsettings set org.gnome.shell enabled-extensions "[$(IFS=,; echo "${ext_list[*]}")]" 2>/dev/null || true
  fi

  # Also mark Fedora defaults as disabled
  gsettings set org.gnome.shell disabled-extensions "['background-logo@fedorahosted.org', 'apps-menu@gnome-shell-extensions.gcampax.github.com']" 2>/dev/null || true

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

  ok "Extensions installed & configured"
}

# ── FINALIZE ──────────────────────────────────────────────────

finalize() {
  next_step "Cleanup & Reboot"

  # ── 1. Temporary files from this installer ──
  log "Cleaning installer temporary files..."
  rm -rf /tmp/mactahoe-* /tmp/mac-sounds /tmp/ext-* 2>/dev/null || true
  rm -f /tmp/*.rpm 2>/dev/null || true

  # ── 2. Flatpak theme build cache ──
  log "Cleaning Flatpak theme build cache..."
  rm -rf "$HOME/.cache/pakitheme" 2>/dev/null || true

  # ── 3. Thumbnail cache ──
  log "Cleaning thumbnail cache..."
  rm -rf "$HOME/.cache/thumbnails/"* 2>/dev/null || true

  # ── 4. Fontconfig cache (safe — rebuilds on next font render) ──
  log "Cleaning fontconfig cache..."
  rm -rf "$HOME/.cache/fontconfig/"* 2>/dev/null || true

  # ── 5. Mesa shader cache (safe — rebuilds on next GL/Vulkan app) ──
  log "Cleaning Mesa shader cache..."
  rm -rf "$HOME/.cache/mesa_shader_cache/"* 2>/dev/null || true

  # ── 6. DNF metadata cache ──
  log "Cleaning DNF metadata cache..."
  sudo dnf clean all 2>/dev/null || true

  # ── 7. Unused Flatpak runtimes ──
  log "Removing unused Flatpak runtimes..."
  flatpak uninstall --unused -y 2>/dev/null || true

  # ── 8. Orphaned RPM packages (dependencies no longer needed) ──
  log "Removing orphaned RPM packages..."
  sudo dnf autoremove -y 2>/dev/null || true

  # ── 9. Old system journal logs (keep last 3 days) ──
  log "Trimming old system logs (keeping 3 days)..."
  sudo journalctl --vacuum-time=3d 2>/dev/null || true

  ok "System cleaned and polished"

  echo ""
  echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "  ${CYAN}║${NC}  ${GREEN}${BOLD}✓  INSTALLATION COMPLETE  ✓${NC}                            ${CYAN}║${NC}"
  echo -e "  ${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
  echo -e "  ${CYAN}║${NC}  ${BOLD}${WHITE}Fedora MacTahoe  ◆  Eprahemi Edition${NC}                       ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}                                                             ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}  ${YELLOW}◆${NC}  All themes, icons, fonts are active                   ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}  ${YELLOW}◆${NC}  Kitty is the default terminal                          ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}  ${YELLOW}◆${NC}  Fish will be the default shell (after logout)          ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}  ${YELLOW}◆${NC}  All custom keybindings are active                      ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}  ${YELLOW}◆${NC}  macOS Big Sur sounds will play                         ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}  ${YELLOW}◆${NC}  GDM login screen themed                                ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}  ${YELLOW}◆${NC}  Flatpak GTK runtime installed                          ${CYAN}║${NC}"
  if [ "${FIREFOX_THEME_FAILED:-0}" = 1 ]; then
    echo -e "  ${CYAN}║${NC}                                                             ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}  ${YELLOW}⚠${NC}  Firefox not themed — log in, launch Firefox once,        ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}  ${YELLOW}⚠${NC}  then re-run: bash install.sh (skips done steps)        ${CYAN}║${NC}"
  fi
  echo -e "  ${CYAN}║${NC}                                                             ${CYAN}║${NC}"
  echo -e "  ${CYAN}║${NC}  ${BOLD}${YELLOW}⚠  Recommended: Reboot now to apply all changes${NC}          ${CYAN}║${NC}"
  echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${DIM}╭─${NC} ${BOLD}${WHITE}✦  More from Eprahemi${NC} ${DIM}────────────────────────────────────────╮${NC}"
  echo -e "  ${DIM}│${NC}                                                                 ${DIM}│${NC}"
  echo -e "  ${DIM}│${NC}  ${CYAN}🐙${NC}  GitHub         ${CYAN}→${NC}  ${BOLD}https://github.com/eprahemi${NC}                ${DIM}│${NC}"
  echo -e "  ${DIM}│${NC}  ${CYAN}🖥${NC}   MacTahoe Site  ${CYAN}→${NC}  ${BOLD}https://fedora-config.pages.dev${NC}          ${DIM}│${NC}"
  echo -e "  ${DIM}│${NC}  ${CYAN}🖼${NC}   Wallpapers     ${CYAN}→${NC}  ${BOLD}https://wallvault.pages.dev/home${NC}  ${RED}(+18)${NC}   ${DIM}│${NC}"
  echo -e "  ${DIM}│${NC}                                                                 ${DIM}│${NC}"
  echo -e "  ${DIM}│${NC}  ${DIM}If you enjoyed this project, consider starring ⭐ on GitHub${NC}   ${DIM}│${NC}"
  echo -e "  ${DIM}╰${NC}${DIM}─────────────────────────────────────────────────────────────────╯${NC}"
  echo ""

  read -rp "Reboot now? [y/N] " reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    sudo reboot
  else
    echo "Reboot later to apply all changes."
  fi
}

# ── Capture GNOME version ──
GNOME_VER=$(gnome-shell --version 2>/dev/null | grep -oP '\d+\.\d+' || echo "?")

# ─────────────────────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────────────────────

echo ""
echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'      ______                 __                   _           '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'     / ____/___  _________ _/ /_  ___  ____ ___  (_)          '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'    / __/ / __ \/ ___/ __ `/ __ \/ _ \/ __ `__ \/ /           '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'   / /___/ /_/ / /  / /_/ / / / /  __/ / / / / / /            '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'  /_____/ .___/_/   \__,_/_/ /_/\___/_/ /_/ /_/_/             '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'       /_/                                                     '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'  '"${BOLD}${WHITE}"'◆  Fedora MacTahoe  —  Eprahemi Edition'"${NC}"'                      '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'  '"${BOLD}"'◆  Automated macOS Desktop Transformation'"${NC}"'              '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}  ${DIM}GNOME${NC} ${GNOME_VER}  ${DIM}◆  Kitty Terminal  ◆  Fish Shell${NC}           ${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}  ${DIM}◆${NC}  21-Step Installer    ${DIM}◆${NC}  Auto-detects your system    ${DIM}◆${NC}  ${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}  ${DIM}◆${NC}  Theme compiles for your GNOME ${BOLD}${GNOME_VER}${NC}                         ${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}  ${DIM}◆${NC}  Sets up Kitty, Fish, icons, fonts, sounds${NC}                 ${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}"'                                                              '"${CYAN}║${NC}"
echo -e "  ${CYAN}║${NC}  ${YELLOW}Press Ctrl+C at any time to cancel${NC}                           ${CYAN}║${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

preflight

remove_ptyxis

phase_divider "PHASE 1 : SYSTEM FOUNDATIONS"
install_rpmfusion
install_nvidia

phase_divider "PHASE 2 : PACKAGES"
install_rpm_packages
install_browsers
install_flatpaks

phase_divider "PHASE 3 : THEMES"
install_mactahoe_theme
install_font

phase_divider "PHASE 4 : CONFIGURATION"
install_extensions
apply_desktop_entries
apply_configs
apply_dconf
apply_wallpapers
setup_gdm
setup_firefox_theme
setup_flatpak_theme
install_sounds

phase_divider "PHASE 5 : TERMINAL & SHELL"
setup_terminal
setup_shell

phase_divider "PHASE 6 : FINALIZE"
finalize
