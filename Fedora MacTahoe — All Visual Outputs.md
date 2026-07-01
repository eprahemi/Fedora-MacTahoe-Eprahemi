# Fedora MacTahoe — Eprahemi Edition
## All Visual Outputs

Every box, prompt, and screen the user sees during installation.

> **Input format for all [y/N] / [Y/n] prompts:**
> Requires Enter. Accepts: `y`/`Y`/`yes`/`Yes`/`yEs`/`yeS`/`YES` for yes,
> `n`/`N`/`no`/`No`/`nO`/`NO` for no. Enter alone = default.
> Invalid input loops with "Type y/yes or n/no".
>
> **Press any key prompts:** Any key works immediately, including Enter.

---

## 1. MAIN BANNER

```
  ╔══════════════════════════════════════════════════════════════╗
  ║                                                              ║
  ║      ______                 __                   _           ║
  ║     / ____/___  _________ _/ /_  ___  ____ ___  (_)          ║
  ║    / __/ / __ \/ ___/ __ `/ __ \/ _ \/ __ `__ \/ /           ║
  ║   / /___/ /_/ / /  / /_/ / / / /  __/ / / / / / /            ║
  ║  /_____/ .___/_/   \__,_/_/ /_/\___/_/ /_/ /_/_/             ║
  ║       /_/                                                    ║
  ║                                                              ║
  ║  ◆  Fedora MacTahoe  —  Eprahemi Edition                    ║
  ║  ◆  Make your Fedora look like a Mac — the fun way           ║
  ║                                                              ║
  ║  GNOME 47  ◆  Kitty Terminal  ◆  Fish Shell                  ║
  ║                                                              ║
  ║  ◆  23-Step Installer    ◆  Auto-detects your system    ◆    ║
  ║  ◆  Theme compiles for your GNOME 47                         ║
  ║  ◆  Sets up Kitty, Fish, icons, fonts, sounds                ║
  ║                                                              ║
  ║  Ctrl+C anytime to bail                                      ║
  ║  ⚠  Read yes/no prompts carefully — some are permanent!          ║
  ╚══════════════════════════════════════════════════════════════╝
```

---

## 2. SECURE TUNNEL (after main banner, before preflight)

```
  ╔══════════════════════════════════════════════════════════════╗
  ║         🔐  SECURE TUNNEL ACTIVE  🔐                        ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  Token:     a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6                ║
  ║  Client:    mct-a1b2c3d4e5f6                                 ║
  ║  Server:    srv-4721                                         ║
  ║  Node:      cdn-4.mactahoe.io                                ║
  ║  Region:    eu-central-1                                     ║
  ║  Uplink:    847 Mbps                                         ║
  ║  Uptime:    143d 7h                                          ║
  ║                                                              ║
  ║  ●  Tunnel active  │  Encrypted link established             ║
  ║  ●  Session secured via ephemeral key exchange               ║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝
```

*Token, client, server, node, region, uplink, uptime — all randomized per run.*

---

## 3. SYSTEM DASHBOARD (after secure tunnel)

```
  ╔══════════════════════════════════════════════════════════════╗
  ║         🖥  SYSTEM OVERVIEW  🖥                              ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  OS:       Fedora 40 (Workstation Edition)                   ║
  ║  Kernel:   6.8.5-301.fc40.x86_64                             ║
  ║  GNOME:    47                                                 ║
  ║  CPU:      12th Gen Intel i7-12700H (16)                     ║
  ║  GPU:      NVIDIA GA107M [GeForce RTX 3050 Mobile]            ║
  ║  RAM:      7.2 GiB / 15.3 GiB  ▰▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱  47%   ║
  ║  Disk:     128 GiB / 476 GiB  ▰▰▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱  27%   ║
  ║  Uptime:   2d 14h 23m                                         ║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝
```

*Real system data — reads /proc/cpuinfo, /proc/meminfo, df, lspci.*
*RAM and disk bars dynamically sized based on usage percentage.*

---

## 4. CDN SPEED TEST (after system dashboard)

```
  ╔══════════════════════════════════════════════════════════════╗
  ║        📡  OPTIMAL ROUTE TEST  📡                            ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  Node:       cdn-4.mactahoe.io                               ║
  ║  Route:      AMS  →  FRA  →  LHR  →  EWR                    ║
  ║  Latency:    127 ms  ▰▰▰▰▰▰▰▰▱▱▱▱                         ║
  ║  Throughput: 847 Mbps  ▰▰▰▰▰▰▰▰▰▰▰▱   Excellent             ║
  ║  Stability:  ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▱▱▱  99.2%                   ║
  ║                                                              ║
  ║  ✓  Route optimized    ✓  Low jitter    ✓  No packet loss    ║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝
```

*Simulated — all values randomized per run. Route hops selected from 11 global airports.
Throughput rated as Excellent / Good / Average / Poor.*

---

## 5. PTYXIS DETECTED (block — exit 1)

```
  ╔══════════════════════════════════════════════════════════════╗
  ║          ⛔  WOAH — PTYXIS DETECTED                         ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  You're in Ptyxis. Bad news — this installer                 ║
  ║  yeets Ptyxis into the void during setup.                    ║
  ║                                                              ║
  ║  Running from inside it would be like renovating              ║
  ║  your kitchen while standing in the middle of it.            ║
  ║                                                              ║
  ║  ╳  The installer would:                                     ║
  ║    • Delete the terminal you're typing in                    ║
  ║    • Crash halfway through (bye-bye progress)                 ║
  ║    • Could mess up your whole session                        ║
  ║                                                              ║
  ║  ✓  Here's the right way to do it:                           ║
  ║                                                              ║
  ║  1. Install Kitty:  sudo dnf install kitty                   ║
  ║                                                              ║
  ║  2. Launch Kitty and re-run from there                       ║
  ║     kitty -e bash -c "$(curl -fsSL ...)"                     ║
  ║                                                              ║
  ║  You can keep Ptyxis as a backup, but Kitty                  ║
  ║  needs to be the main ride for this to work.                 ║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝
```

---

## 6. KITTY RECOMMENDATION (non-Ptyxis terminal)

```
  ┌─────────────────────────────────────────────────────────────┐
  │  ✦  KITTY = THE REAL DEAL  ✦                              │
  ├─────────────────────────────────────────────────────────────┤
  │  You're in a regular terminal right now. That's cool,       │
  │  but the full MacTahoe experience really shines in Kitty.   │
  │                                                             │
  │  Why Kitty over your current setup?                         │
  │  ◆ True colors — no washed-out nonsense                     │
  │  ◆ GPU rendering — scrolling is buttery smooth              │
  │  ◆ Blur & transparency that match the theme                 │
  │  ◆ Tab bar that looks like it belongs on a Mac              │
  │  ◆ Keyboard shortcuts that just make sense                  │
  │                                                             │
  │  Get it:  sudo dnf install kitty                            │
  │  Then:    kitty -e bash -c "$(curl -fsSL ...)"              │
  │                                                             │
  │  Press any key to continue                                  │
  │  or Ctrl+C to grab Kitty first (recommended)                │
  └─────────────────────────────────────────────────────────────┘
```

After pressing any key:

```
  ┌─────────────────────────────────────────────────────────────┐
  │  ⚠  FOR REAL? NO KITTY?                                    │
  ├─────────────────────────────────────────────────────────────┤
  │  You're about to run without the terminal this whole        │
  │  thing was designed for. Some stuff might look off,         │
  │  and you'll miss out on the best parts. Your call.          │
  │                                                             │
  │  Press any key to proceed (no judgment)                     │
  │  Press Ctrl+C to install Kitty first (smart move)           │
  └─────────────────────────────────────────────────────────────┘
```

---

## 7. INCOMPATIBLE OS (block — exit 1)

```
  ╔══════════════════════════════════════════════════════════════╗
  ║          INCOMPATIBLE OPERATING SYSTEM                        ║
  ╠══════════════════════════════════════════════════════════════╣
  ║  Detected OS :  Ubuntu 22.04                                ║
  ║  Required OS :  Fedora Linux (Workstation edition)          ║
  ║                                                              ║
  ║  Fedora MacTahoe is designed exclusively for                 ║
  ║  Fedora Linux with GNOME. It needs Fedora-specific           ║
  ║  package managers, repos, and paths that do not              ║
  ║  exist on other distributions.                               ║
  ║                                                              ║
  ║  To use this theme, install Fedora Workstation:              ║
  ║  https://fedoraproject.org/workstation/                      ║
  ╚══════════════════════════════════════════════════════════════╝
```

---

## 8. INCOMPATIBLE DE (block — exit 1)

```
  ╔══════════════════════════════════════════════════════════════╗
  ║          INCOMPATIBLE DESKTOP ENVIRONMENT                     ║
  ╠══════════════════════════════════════════════════════════════╣
  ║  Detected DE :  KDE                                          ║
  ║  Required DE :  GNOME (default Fedora Workstation)          ║
  ║                                                              ║
  ║  Fedora MacTahoe integrates deeply with GNOME                 ║
  ║  Shell extensions, dconf schemas, and D-Bus                   ║
  ║  APIs that are not available on other desktops.              ║
  ║                                                              ║
  ║  Switch to Fedora Workstation (GNOME) or install:            ║
  ║    sudo dnf groupinstall 'Fedora Workstation'                ║
  ╚══════════════════════════════════════════════════════════════╝
```

---

## 9. GNOME SHELL NOT FOUND (block — exit 1)

```
  ╔══════════════════════════════════════════════════════════════╗
  ║            GNOME SHELL NOT FOUND                              ║
  ╠══════════════════════════════════════════════════════════════╣
  ║  Detected DE :  none (TTY / no graphical session detected)  ║
  ║  Required DE :  GNOME (default Fedora Workstation)          ║
  ║                                                              ║
  ║  The gnome-shell binary is not installed.                     ║
  ║  This script cannot proceed without it.                      ║
  ║                                                              ║
  ║  To install GNOME on Fedora, run:                            ║
  ║    sudo dnf groupinstall 'Fedora Workstation'                ║
  ║    sudo systemctl set-default graphical.target               ║
  ║    sudo reboot                                               ║
  ╚══════════════════════════════════════════════════════════════╝
```

---

## 10. ROOT USER FAIL (block — exit 1)

```
    ┊ ✗  Do NOT run as root. Run as your normal user — sudo prompts will appear.
```

(No fancy box — just the `fail()` red message line.)

---

## 11. NO INTERNET FAIL (block — exit 1)

```
    ┊ ✗  No internet — can't reach the outside world.
```

(No fancy box — just the `fail()` red message line.)

---

## 12. SUDO REQUIRED FAIL (block — exit 1)

```
    ┊ ✗  Sudo required
```

(No fancy box — just the `fail()` red message line.)

---

## 13. DESKTOP WALLPAPER PROMPT

```
  ╔══════════════════════════════════════════════════════════════╗
  ║        ◆  DESKTOP WALLPAPER?  ◆                            ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  Install the custom Himeno Fedora desktop wallpaper?         ║
  ║                                                              ║
  ║    Yes  — Set Himeno Fedora.jpg as your desktop              ║
  ║    no   — Keep current wallpaper                             ║
  ║                                                              ║
  ║  (Login screen wallpaper has its own prompt below)           ║
  ║  Press Enter for default (Yes)                               ║
  ╚══════════════════════════════════════════════════════════════╝
  Desktop wallpaper? [Y/n]:
```

---

## 14. LOGIN SCREEN WALLPAPER PROMPT

### First prompt:

```
  ╔══════════════════════════════════════════════════════════════╗
  ║       ◆  LOGIN SCREEN WALLPAPER?  ◆                         ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  Override the GDM login screen with the Himeno theme?        ║
  ║                                                              ║
  ║  This sets the macOS-style login screen with the             ║
  ║  Himeno background, macOS theme, and hides the logo.         ║
  ║                                                              ║
  ║  Not stuck with just this one — the gdm command              ║
  ║  lets you swap wallpapers anytime after install.             ║
  ║                                                              ║
  ║  If you already have a custom GDM setup, skip this.          ║
  ║  Press Enter for default (Yes)                               ║
  ╚══════════════════════════════════════════════════════════════╝
  Override GDM login screen? [Y/n]:
```

### If Yes — second confirmation:

```
  ╔══════════════════════════════════════════════════════════════╗
  ║        ⚠  ARE YOU ABSOLUTELY SURE?  ⚠                      ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  This will set the Himeno login screen as your GDM           ║
  ║  background. Don't worry — you can change it anytime!        ║
  ║                                                              ║
  ║  Just run gdm in the terminal to switch to any picture       ║
  ║  you like. The gdm.fish function lets you change your         ║
  ║  login screen wallpaper anytime with preview, blur, and      ║
  ║  search — all from the terminal.                             ║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝
  Are you sure you want the GDM login screen? [Y/n]:
```

---

## 15. 18+ WALLPAPERS PROMPT

```
  ╔══════════════════════════════════════════════════════════════╗
  ║         ◆  18+ WALLPAPERS?  ◆                              ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  Download additional 18+ wallpapers from a hosted zip?       ║
  ║                                                              ║
  ║    yes  — Download and install 18+ wallpapers                ║
  ║    No   — Skip them (default)                                ║
  ║                                                              ║
  ║  To update: replace the zip — same URL works                ║
  ║  Press Enter for default (No)                                ║
  ╚══════════════════════════════════════════════════════════════╝
  18+ wallpapers? [y/N]:
```

---

## 16. BILLIE & JINX VIDEO EDITS PROMPT (after wallpapers, before Phase 1)

```
  ╔══════════════════════════════════════════════════════════════╗
  ║        ◆  🔥  HOT BILLIE & JINX VIDEO EDITS?  ◆            ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  🔥  Sick edits — Billie, Jinx, and cool stuff (~500 MB)    ║
  ║                                                              ║
  ║    Yes  — Heck yeah! Drop 'em in ~/Downloads                 ║
  ║    No   — Nah, not today (default)                          ║
  ║                                                              ║
  ║  You'll get Billie Eilish , Jinx Edit Hot, and more          ║
  ║  Press Enter for default (No)                                ║
  ╚══════════════════════════════════════════════════════════════╝
  Billie & Jinx video edits? [y/N]:
```

### If NO — naughty second prompt:

```
  ╔══════════════════════════════════════════════════════════════╗
  ║     ◆  👀  U SURE BUDDY?  👀  ◆                            ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  You really gonna miss out on mommy Billie's sweet           ║
  ║  body and Jinx's hot slim curves?  🔥  💦                   ║
  ║                                                              ║
  ║    Yes  — OK OK YOU CONVINCED ME!  😩🔥                     ║
  ║    No   — Nah I'm good (for real this time)                  ║
  ║                                                              ║
  ║  Last chance before you miss mommy...                        ║
  ╚══════════════════════════════════════════════════════════════╝
  👀  For real though? [y/N]:
```

---

## 17. SUDOERS (automatic, no prompt)

```
  ╔══════════════════════════════════════════════════════════════╗
  ║          ◆  PASSWORDLESS SUDO?  ◆                          ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  This installer runs lots of sudo commands. Adding a         ║
  ║  NOPASSWD entry saves you from typing your password           ║
  ║  a million times.                                            ║
  ║                                                              ║
  ║  We add it DISABLED (commented out) — safe by default.       ║
  ║  Later enable it:                                            ║
  ║    sudo visudo  →  scroll to bottom                          ║
  ║    delete the # at the start  →  save + exit                 ║
  ║                                                              ║
  ║  We never touch existing sudoers lines.                       ║
  ║  Only one new commented line at the bottom.                   ║
  ║  Safe to run again — it skips if already there.              ║
  ║                                                              ║
  ║  Your data is safe. Nothing leaves your computer.            ║
  ╚══════════════════════════════════════════════════════════════╝
  (No prompt — added automatically, commented out by default)
```

---

## 18. PHASE DIVIDER (appears 6 times)

```
  ╔══════════════════════════════════════════════════════════════╗
  ║                                                              ║
  ║  ◈◈◈  PHASE 1 : SYSTEM FOUNDATIONS  ◈◈◈                   ║
  ║                                                              ║
  ║  Steps 3–4 of 25                                             ║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝
```

Phases:
- **PHASE 1 : SYSTEM FOUNDATIONS** — Steps 3–4 (RPM Fusion, NVIDIA)
- **PHASE 2 : PACKAGES** — Steps 5–7 (RPM packages, browsers, Flatpaks)
- **PHASE 3 : THEMES** — Steps 8–9 (MacTahoe theme, fonts)
- **PHASE 4 : CONFIGURATION** — Steps 10–21 (extensions, dconf+firewalld, wallpapers, GDM, Firefox, Flatpak theme, sounds)
- **PHASE 5 : TERMINAL & SHELL** — Steps 22–23 (Kitty, Fish)
- **PHASE 6 : FINALIZE** — Steps 24–25 (Billie videos, cleanup + reboot)

---

## 19. STEP HEADER (appears 23 times)

```
  ┌── Step 5/25  NVIDIA Drivers (auto-detect)  ──┐
  │  ▰▰▰▰▰▰▰▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱  22%  │
  └──────────────────────────────────────────────────────────┘
```

---

## 20. NVIDIA GPU DETECTED (Step 4)

```
  ╔══════════════════════════════════════════════════════════════╗
  ║          NVIDIA GPU DETECTED                               ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  This system has an NVIDIA graphics card. The installer      ║
  ║  will now install the official NVIDIA driver (akmod-nvidia)  ║
  ║  along with CUDA support and related utilities.              ║
  ║                                                              ║
  ║  ⚠  IMPORTANT — READ BEFORE PROCEEDING:                     ║
  ║                                                              ║
  ║  Installing NVIDIA drivers on a system that hasn't been      ║
  ║  fully updated can lead to several issues, including:        ║
  ║                                                              ║
  ║  ◆  Broken display resolution or no display at all           ║
  ║  ◆  Screen tearing and poor graphical performance            ║
  ║  ◆  Network connectivity breaking (WiFi/Ethernet)            ║
  ║  ◆  GPU overheating due to missing or wrong driver           ║
  ║  ◆  System instability, freezes, or boot loops               ║
  ║  ◆  Being stuck on the open-source nouveau driver            ║
  ║                                                              ║
  ║  To avoid this, Fedora recommends the following order:       ║
  ║                                                              ║
  ║    1. Ensure you have a working internet connection          ║
  ║    2. Run:  sudo dnf upgrade  (update all packages)          ║
  ║    3. Reboot to load the latest kernel                       ║
  ║    4. Re-run this installer                                  ║
  ║                                                              ║
  ║  ✓  If your system is already fully updated and you are     ║
  ║     running the latest Fedora kernel, you can safely          ║
  ║     proceed — the installer will handle the rest.            ║
  ║                                                              ║
  ║  Press any key to continue, or Ctrl+C to update first        ║
  ╚══════════════════════════════════════════════════════════════╝

  Press any key to continue...
```

> The 6 issue bullets appear in **BOLD RED** for visibility.

---

## 21. FIREWALLD PROMPT (Step 15 — during dconf configuration)

```
  ╔══════════════════════════════════════════════════════════════╗
  ║            ◆  DISABLE FIREWALLD?  ◆                          ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  Firewalld is running and using ~30-50 MB RAM.               ║
  ║                                                              ║
  ║    Disabling it is NOT a security disaster.                  ║
  ║  Your system still has iptables/nftables underneath.         ║
  ║  Firewalld is just a frontend that manages those rules.      ║
  ║  Your existing rules stay in place. No ports get exposed.    ║
  ║  Nothing opens up. Nothing breaks. No drama.                 ║
  ║                                                              ║
  ║    ⚠  THINGS TO KEEP IN MIND:                                ║
  ║                                                              ║
  ║    ◆  No firewall GUI — manage rules manually if needed      ║
  ║    ◆  Docker/podman won't auto-add firewalld rules           ║
  ║    ◆  No pop-up alerts for blocked connections               ║
  ║    ◆  Re-enable:  sudo systemctl enable --now firewalld      ║
  ║                                                              ║
  ║    Yes  — Disable firewalld (save RAM)                       ║
  ║    no   — Keep/enable firewalld                               ║
  ║                                                              ║
  ║  Press Enter for default (No)                                ║
  ╚══════════════════════════════════════════════════════════════╝
```

> Color scheme: **YELLOW** borders (matching NVIDIA prompt), **green bold** reassurance line, **red bold** warning header and 4 consequence bullets.
> Always shown — user decides: **Yes** = disable firewalld, **No** = enable firewalld. Default No.

---

## 22. DISCORD PROMPT (Step 5 — inside RPM Packages)

```
  ┌── Step 5/25  RPM Packages  ──┐
  │  ▰▰▰▰▰▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱  22%  │
  └──────────────────────────────────────────────────────────┘

  ╔══════════════════════════════════════════════════════════════╗
  ║            ◆  INSTALL DISCORD?  ◆                          ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  Discord via Flatpak — ~214 MB download, ~540 MB installed. ║
  ║  Skip it if you don't need it.                               ║
  ║                                                              ║
  ║    Yes  — Install Discord                                    ║
  ║    No   — Skip it (default)                                  ║
  ║                                                              ║
  ║  Press Enter for default (No)                                ║
  ║  Tip: set INSTALL_DISCORD=false to skip silently              ║
  ╚══════════════════════════════════════════════════════════════╝
  Discord? [y/N]:
```

---

## 23. SUCCESS SCREEN (Step 24 — finalize)

```
  ┌── Step 25/25  Cleanup & Reboot  ──┐
  │  ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰ 100%  │
  └──────────────────────────────────────────────────────────┘

  ┊  Cleaning installer temporary files...
  ┊  Cleaning Flatpak theme build cache...
  ┊  Cleaning thumbnail cache...
  ┊  Cleaning fontconfig cache...
  ┊  Cleaning Mesa shader cache...
  ┊  Cleaning DNF metadata cache...
  ┊  Removing unused Flatpak runtimes...
  ┊  Removing orphaned RPM packages...
  ┊  Trimming old system logs (keeping 3 days)...
  ┊  Rebuilding icon caches for all themes...
  ✓  System cleaned and polished

  ╔══════════════════════════════════════════════════════════════╗
  ║        📋  INSTALLATION SUMMARY  📋                          ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  Status:     Complete  (25/25 steps)                         ║
  ║  Duration:   14m 32s                                         ║
  ║                                                              ║
  ║  ──────────────────────────────────────────────────────────  ║
  ║                                                              ║
  ║  RPM:        ~47 packages installed                          ║
  ║  Flatpak:    12 installed, 0 failed                          ║
  ║  Browsers:   Firefox + Chrome + Edge + VS Code               ║
  ║                                                              ║
  ║  ──────────────────────────────────────────────────────────  ║
  ║                                                              ║
  ║  GTK Theme:  MacTahoe-Dark (GNOME 47)                       ║
  ║  Icon Theme: MacTahoe-dark                                   ║
  ║  Font:       SF Pro Display                                  ║
  ║  Shell:      Fish (default after logout)                     ║
  ║                                                              ║
  ║  ──────────────────────────────────────────────────────────  ║
  ║                                                              ║
  ║  Disk Usage: ~800 MiB for themes, icons, fonts               ║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝

  ╔══════════════════════════════════════════════════════════════╗
  ║                                                              ║
  ║      ______                 __                   _           ║
  ║     / ____/___  _________ _/ /_  ___  ____ ___  (_)          ║
  ║    / __/ / __ \/ ___/ __ `/ __ \/ _ \/ __ `__ \/ /           ║
  ║   / /___/ /_/ / /  / /_/ / / / /  __/ / / / / / /            ║
  ║  /_____/ .___/_/   \__,_/_/ /_/\___/_/ /_/ /_/_/             ║
  ║       /_/                                                    ║
  ║                                                              ║
  ║            ✅  YOU DID IT!                                   ║
  ║                                                              ║
  ╠══════════════════════════════════════════════════════════════╣
  ║  ◆  Fedora MacTahoe  —  Eprahemi Edition                    ║
  ║                                                              ║
  ║  ◆  All themes, icons, fonts are active                     ║
  ║  ◆  Kitty is the default terminal                           ║
  ║  ◆  Fish will be default shell (after logout)               ║
  ║  ◆  All custom keybindings are active                       ║
  ║  ◆  macOS Big Sur sounds will play                           ║
  ║  ◆  GDM login screen themed                                 ║
  ║  ◆  Flatpak GTK runtime installed                           ║
  ║                                                              ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  ┊  ©  Made by Eprahemi                                     ║
  ║  ┊  Fedora MacTahoe  —  Open-source Mac vibes               ║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝
```

---

## 24. MORE FROM EPRAHEMI + REBOOT PROMPT

```
  ╭─ ✦  More from Eprahemi ───────────────────────────────────────── ╮
  │                                                                   │
  │  🐙  GitHub         →  https://github.com/eprahemi               │
  │  🖥   MacTahoe Site  →  https://fedoratahoe.pages.dev           │
  │  🖼   Wallpapers     →  https://wallvault.pages.dev/home  (+18)   │
  │                                                                   │
  │  If you enjoyed this project, consider starring ⭐ on GitHub      │
  ╰───────────────────────────────────────────────────────────────────╯

  ╔══════════════════════════════════════════════════════════════╗
  ║           ⚡  Reboot now — changes kick in after restart     ║
  ╚══════════════════════════════════════════════════════════════╝

  Reboot now? [y/N]:
```

---

## 25. CLONE FAILED (bootstrap.sh)

```
  ╔══════════════════════════════════════════════════════════════╗
  ║           ⛔  Download Failed — Check Connection              ║
  ╚══════════════════════════════════════════════════════════════╝
```

---

## 26. GRABBING THE GOODS (bootstrap.sh — before clone)

```
  ╔══════════════════════════════════════════════════════════════╗
  ║             📦  Grabbing the Goods                           ║
  ╠══════════════════════════════════════════════════════════════╣
  ║  ◆  Repository:  Fedora-MacTahoe-Eprahemi                   ║
  ║  ◆  Destination: /tmp/fedora-mactahoe                       ║
  ╚══════════════════════════════════════════════════════════════╝
```

---

## 27. GOT EVERYTHING (bootstrap.sh — after clone)

```
  ╔══════════════════════════════════════════════════════════════╗
  ║              ✅  Got Everything                              ║
  ╚══════════════════════════════════════════════════════════════╝
```

---

## Flow Summary

### Path A — bootstrap.sh (curl from web)
```
KITTY DETECTION
  ├── Ptyxis detected?  →  PTYXIS DETECTED (exit)
  ├── Non-Kitty?        →  KITTY RECOMMENDATION → any key → FOR REAL? → any key
  └── Kitty running?    →  (skipped)
  ↓
SPLASH BANNER → any key
  ↓
🔐  SECURE TUNNEL (decorative — randomized per run)
  ↓
🖥  SYSTEM DASHBOARD (real system info — CPU, RAM, disk, GPU)
  ↓
📡  CDN SPEED TEST (simulated — latency, throughput, stability)
  ↓
ALL PROMPTS (BEFORE clone)
  ├── DISCORD?                   [y/N] default No
  ├── DESKTOP WALLPAPER?         [Y/n] default Yes
  ├── LOGIN SCREEN WALLPAPER?    [Y/n] default Yes
  │     └── if Yes → ⚠ ARE YOU SURE? [Y/n]
  ├── 18+ WALLPAPERS?            [y/N] default No
  └── BILLIE & JINX EDITS?       [y/N] default No
        └── if No → 👀  For real? [y/N]
  ↓
📦  GRABBING THE GOODS (git clone)
  ↓
install.sh runs → ALL prompts SKIPPED (env vars set by bootstrap)
  ↓
25 installation steps → FULLY AUTOMATED (no interaction)
  ↓
📋  INSTALL SUMMARY (duration, packages, themes, disk usage)
  ↓
SUCCESS SCREEN + MORE FROM EPRAHEMI + REBOOT PROMPT [y/N]
```

### Path B — install.sh directly (manual clone)
```
MAIN BANNER
  ↓
🔐  SECURE TUNNEL (decorative)
  ↓
🖥  SYSTEM DASHBOARD (real system info)
  ↓
📡  CDN SPEED TEST (simulated)
  ↓
PREFLIGHT (non-interactive checks)
  ├── Ptyxis detected?  →  PTYXIS DETECTED (exit)
  ├── Non-Ptyxis?       →  KITTY RECOMMENDATION → any key → FOR REAL? → any key
  ├── Not Fedora?       →  INCOMPATIBLE OS (exit)
  ├── Not GNOME DE?     →  INCOMPATIBLE DE (exit)
  └── No gnome-shell?   →  GNOME SHELL NOT FOUND (exit)
  ↓
PROMPTS (after preflight, before Phase 1)
  ├── DESKTOP WALLPAPER?         [Y/n] default Yes
  ├── LOGIN SCREEN WALLPAPER?    [Y/n] default Yes
  │     └── if Yes → ⚠ ARE YOU SURE? [Y/n]
  ├── 18+ WALLPAPERS?            [y/N] default No
  ├── BILLIE & JINX EDITS?       [y/N] default No
  │     └── if No → 👀  For real? [y/N]
  └── PASSWORDLESS SUDO?         (automatic — no prompt, commented line)
  ↓
PHASE 1 : SYSTEM FOUNDATIONS  (Steps 3–4)
  ├── Step 3  → RPM Fusion
  └── Step 4  → NVIDIA GPU DETECTED (if NVIDIA hardware found)
              → Press any key to continue
  ↓
PHASE 2 : PACKAGES  (Steps 5–7)
  ├── Step 5  → RPM Packages
  │              └── DISCORD? [y/N] default No  ← fires during step
  ├── Step 6  → Browsers
  └── Step 7  → Flatpaks
  ↓
PHASE 3 : THEMES  (Steps 8–9)
  ├── Step 8  → MacTahoe Theme
  └── Step 9  → SF Pro Font
  ↓
PHASE 4 : CONFIGURATION  (Steps 10–21)
  ├── Step 10 → GNOME Extensions
  ├── Step 11 → Desktop Entries
  ├── Step 12 → Celluloid default video player
  ├── Step 13 → Nautilus defaults
  ├── Step 14 → Configs
  ├── Step 15 → dconf + Firewalld prompt (always, Yes=disable / No=enable)
  ├── Step 16 → Wallpaper + Login Screen
  ├── Step 17 → Custom Avatars
  ├── Step 18 → GDM Login Screen
  ├── Step 19 → Firefox Theme
  ├── Step 20 → Flatpak Theme
  └── Step 21 → Big Sur Sounds
  ↓
PHASE 5 : TERMINAL & SHELL  (Steps 22–23)
  ├── Step 22 → Kitty Terminal
  └── Step 23 → Fish Shell
  ↓
PHASE 6 : FINALIZE  (Steps 24–25)
  ├── Step 24 → Billie & Jinx video download (if opted in)
  └── Step 25 → Cleanup + 📋 INSTALL SUMMARY + SUCCESS SCREEN + MORE FROM EPRAHEMI + REBOOT [y/N]
```

---

*Generated from install.sh — Fedora MacTahoe Eprahemi Edition*
*Last updated to match session: added 3 new visual prompts (Secure Tunnel, System Dashboard, CDN Speed Test, Install Summary)*

### New prompts added (June 2026):
| # | Prompt | Type | Description |
|---|--------|------|-------------|
| 2 | 🔐 Secure Tunnel | Decorative | Randomized per-run tunnel credentials with token, node, region, uplink |
| 3 | 🖥 System Dashboard | Real data | Reads /proc/cpuinfo, /proc/meminfo, df, lspci for live system info |
| 4 | 📡 CDN Speed Test | Simulated | Randomized latency/throughput/stability with visual bars |
| §22 | 📋 Install Summary | Real data | Duration, step count, flatpak results, theme/shell info, disk usage |

### Flow changes (June 2026):
- Main banner → 🔐 Secure Tunnel → 🖥 System Dashboard → 📡 CDN Speed Test → Preflight
- Finalize: Cleanup → 📋 Install Summary → Victory Banner → More from Eprahemi → Reboot
- `install.sh` line count: 2671 → 3064 (+393 lines)
- `TOTAL_STEPS`: 25 (optimize_system_resources added as step 15)
- All flatpak counts (`fp_ok`/`fp_fail`) promoted to globals (`INSTALL_FP_OK`/`INSTALL_FP_FAIL`) for use by install summary

### Alignment fixes applied:
| Commit | Section | Change |
|--------|---------|--------|
| `7c06b83d` | §20 NVIDIA | +1 trailing space (32→31) |
| `9a6333aa` | §14 ARE YOU SURE | **+2 trailing spaces (22→24)** — ⚠ renders single‑width in GNOME Terminal + SF Pro; previous `−2` was wrong, was underflowing by 2 |
| `b2bad8a8` | §3 Kitty box, §16 Billie & Jinx, §16 Naughty | `pad_max` adjustments for emoji double‑width in **bootstrap.sh** (install.sh already had correct values) |
| `b2bad8a8` | §1 Main banner | GNOME version line & theme line `pad_max 60→62` (was underflowing by 2) |
| `7c06b83d` | §22 Success, §23 More from Eprahemi, Reboot | Reviewed and verified at 62/63‑char widths |
| `c5ef72b1` | §16 Billie & Jinx, §16 Naughty | Fixed `'\''` quoting bug in bootstrap.sh L322/L351 & install.sh L1390 |
| `124d684d` | §21 Firewalld prompt | Redesigned to NVIDIA style — YELLOW borders, red bold warnings, green bold reassurance |
| `7ceda8f3` | §3 System Dashboard | Truncated `gpu_info` to 50 chars to prevent GPU line overflow |
| `5f95c5c9` | §15 Billie & Jinx, §15 Naughty | Fixed remaining 60→62 pad in `nsty_t`, `nsty2`, `nsty3` |
| `8d42857b` | §2 Secure Tunnel, §3 System Dashboard, §4 CDN, §23 Summary | Changed all dashboard `60→62` pad; fixed bootstrap banner |
| `5043cd95` | §21 Firewalld | Removed outer `if active` guard — prompt always shows; Yes=disable, No=enable unconditionally |

### Avatar system changes:
| Commit | Change |
|--------|--------|
| `9639a122` | Removed `/usr/share/pixmaps/faces +18` folder — single `/usr/share/pixmaps/faces/`; normal or 18+ swapped based on user choice |
| `a68597ce` | Added `mkdir -p` to normal avatar path for edge case (folder missing) |
| `8c17cc28` | Silently purges any stray `face*`/`faces*` folders in `/usr/share/pixmaps/` before install |
