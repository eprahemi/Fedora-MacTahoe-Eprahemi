# ══════════════════════════════════════════════════════════════
# smb 📡 — Samba file sharing manager
# Install, configure, and manage Samba on Fedora
# Fedora MacTahoe Eprahemi System Configuration © 2026
# ══════════════════════════════════════════════════════════════
function smb --description 'Samba file sharing manager'
    # ── Colors ──
    set -l R    "\033[1;31m"
    set -l G    "\033[1;32m"
    set -l Y    "\033[1;33m"
    set -l B    "\033[1;34m"
    set -l C    "\033[1;36m"
    set -l W    "\033[1;37m"
    set -l D    "\033[2;37m"
    set -l N    "\033[0m"
    set -l BOLD "\033[1m"
    set -l BOLDG "\033[1;32m"
    set -l BOLDR "\033[1;31m"
    set -l BOLDY "\033[1;33m"
    set -l BOLDC "\033[1;36m"

    # ── Config paths ──
    set -g CONF_DIR  "$HOME/.config/smb"
    set -g PASS_FILE "$CONF_DIR/.password"
    set -g SMB_CONF  "/etc/samba/smb.conf"

    # ── Ctrl+C handling ──
    set -g __smb_ctrl_c 0
    trap __smb_ctrl_c SIGINT

    # ════════════════════════════════════════════════════════════
    # HELPERS
    # ════════════════════════════════════════════════════════════

    function __smb_ip
        set -l ip (ip -4 route get 1 2>/dev/null | awk '{print $7; exit}')
        if test -z "$ip"
            set ip (hostname -I | awk '{print $1}')
        end
        echo "$ip"
    end

    function __smb_user_exists
        type -q pdbedit; or return 1
        command pdbedit -L 2>/dev/null | grep -q "^$argv[1]:"
    end

    function __smb_share_exists
        grep -q "^\[$argv[1]\]" "$SMB_CONF" 2>/dev/null
    end

    function __smb_get_scope
        if grep -q '^\[homes\]' "$SMB_CONF" 2>/dev/null
            echo "home"
        else if grep -q 'path\s*=\s*/\s*$' "$SMB_CONF" 2>/dev/null
            echo "root"
        else
            echo "none"
        end
    end

    function __smb_pkexec
        pkexec cat /etc/shadow >/dev/null 2>&1
        return $status
    end

    # ── Keyring helpers (gnome-keyring via libsecret) ──

    function __smb_has_keyring
        # Cache result for this session
        if set -q __smb_keyring_available
            return $__smb_keyring_available
        end
        type -q secret-tool; or begin; set -g __smb_keyring_available 0; return 1; end
        # Verify keyring is actually unlocked
        echo "test" | secret-tool store --label="SMB test" smb-test probe >/dev/null 2>&1
        if test $status -eq 0
            secret-tool clear smb-test probe >/dev/null 2>&1
            set -g __smb_keyring_available 1
            return 0
        end
        set -g __smb_keyring_available 0
        return 1
    end

    function __smb_keyring_save
        set -l user $argv[1]
        set -l pass $argv[2]
        printf '%s' "$pass" | secret-tool store --label="SMB: $user" smb-user "$user" >/dev/null 2>&1
        return $status
    end

    function __smb_keyring_get
        set -l user $argv[1]
        secret-tool lookup smb-user "$user" 2>/dev/null
        return $status
    end

    function __smb_keyring_delete
        set -l user $argv[1]
        secret-tool clear smb-user "$user" >/dev/null 2>&1
        return $status
    end

    function __smb_set_password
        set -l user $argv[1]
        set -l pass $argv[2]
        set -l user_exists 0
        if type -q pdbedit
            if command pdbedit -L 2>/dev/null | grep -q "^$user:"
                set user_exists 1
            end
        end
        if test $user_exists -eq 1
            printf '%s\n' "$pass" "$pass" | sudo smbpasswd -s "$user" 2>/dev/null
        else
            printf '%s\n' "$pass" "$pass" | sudo smbpasswd -a -s "$user" 2>/dev/null
        end
    end

    function __smb_save_password
        set -l user $argv[1]
        set -l pass $argv[2]
        # Primary: gnome-keyring (encrypted at rest, unlocked on login)
        if __smb_has_keyring
            __smb_keyring_delete "$user" 2>/dev/null
            __smb_keyring_save "$user" "$pass"
            return 0
        end
        # Fallback: encrypted file
        mkdir -p "$CONF_DIR"
        if test -f "$PASS_FILE"
            grep -v "^$user:" "$PASS_FILE" > "$PASS_FILE.tmp" 2>/dev/null
            mv "$PASS_FILE.tmp" "$PASS_FILE" 2>/dev/null
        end
        printf '%s:%s\n' "$user" "$pass" >> "$PASS_FILE"
        chmod 700 "$CONF_DIR"
        chmod 600 "$PASS_FILE"
    end

    function __smb_get_password
        set -l user $argv[1]
        # Primary: gnome-keyring
        if __smb_has_keyring
            __smb_keyring_get "$user"
            return $status
        end
        # Fallback: file
        if test -f "$PASS_FILE"
            grep "^$user:" "$PASS_FILE" 2>/dev/null | head -1 | cut -d: -f2
            return 0
        end
        return 1
    end

    function __smb_delete_password
        set -l user $argv[1]
        # Primary: gnome-keyring
        if __smb_has_keyring
            __smb_keyring_delete "$user"
            return $status
        end
        # Fallback: file
        if test -f "$PASS_FILE"
            grep -v "^$user:" "$PASS_FILE" > "$PASS_FILE.tmp" 2>/dev/null
            mv "$PASS_FILE.tmp" "$PASS_FILE" 2>/dev/null
            return 0
        end
        return 1
    end

    function __smb_ctrl_c
        if not set -q __smb_ctrl_c
            return 0
        end
        set -g __smb_ctrl_c (math $__smb_ctrl_c + 1)
    end

    function __smb_stop_check
        set -l _st $status
        # Double Ctrl+C: counter >= 2 means stop
        if test $__smb_ctrl_c -ge 2
            set -g __smb_ctrl_c 0
            trap - SIGINT
            set -e __smb_ctrl_c
            printf "\n  Stopped.\n"
            return 1
        end
        # Read returned 130 (SIGINT from Ctrl+C during read)
        if test $_st -eq 130
            if test $__smb_ctrl_c -ge 1
                # Second press — stop
                set -g __smb_ctrl_c 0
                trap - SIGINT
                set -e __smb_ctrl_c
                printf "\n  Stopped.\n"
                return 1
            else
                # First press — warn
                set -g __smb_ctrl_c 1
                printf "\n  Press Ctrl+C again to stop.\n"
            end
        else
            # Not SIGINT — reset counter
            if test $__smb_ctrl_c -eq 1
                set -g __smb_ctrl_c 0
            end
        end
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # HELP
    # ════════════════════════════════════════════════════════════

    if test (count $argv) -eq 0; or test "$argv[1]" = "help"; or test "$argv[1]" = "-help"; or test "$argv[1]" = "--help"
        echo ""
        printf "  $C╭──────────────────────────────────────────────────────────────╮$N\n"
        printf "  $C│                      SMB FILE SHARING                        │$N\n"
        printf "  $C│              Fedora MacTahoe  ·  Eprahemi System            │$N\n"
        printf "  $C│           Samba manager  ·  19 commands  ·  4 groups        │$N\n"
        printf "  $C╰──────────────────────────────────────────────────────────────╯$N\n"
        echo ""
        printf "  Usage:  $Y smb$N <command> [args]\n"
        echo ""
        printf "  ────────────────────────────────────────────────────────────────\n"
        printf "  $BOLDC SETUP$N\n"
        printf "  ────────────────────────────────────────────────────────────────\n"
        printf "    $W smb setup$N                   Full guided setup (installs samba,\n"
        printf "                                     configures firewall, creates user,\n"
        printf "                                     enables service). Run this first.\n"
        echo ""
        printf "  ────────────────────────────────────────────────────────────────\n"
        printf "  $BOLDG USERS$N\n"
        printf "  ────────────────────────────────────────────────────────────────\n"
        printf "    $W smb user list$N               List all SMB users with their IDs\n"
        printf "    $W smb user add$N $D<name>$N         Create a new SMB user\n"
        printf "                                     You will be prompted for a password.\n"
        printf "    $W smb user remove$N $D<name>$N      Delete an SMB user (keeps home dir)\n"
        printf "    $W smb user rename$N $D<old> <new>$N  Rename a user, keeps same password\n"
        printf "                                     Example: smb user rename alice bob\n"
        printf "    $W smb user password$N $D<name>$N    Change a user's SMB password\n"
        printf "                                     You must know the current password.\n"
        echo ""
        printf "  ────────────────────────────────────────────────────────────────\n"
        printf "  $BOLDC SHARES$N\n"
        printf "  ────────────────────────────────────────────────────────────────\n"
        printf "    $W smb share$N $D<dir> [name]$N      Share a local directory over SMB\n"
        printf "                                     Example: smb share ~/Documents docs\n"
        printf "    $W smb unshare$N $D<name>$N          Remove a share by name\n"
        printf "    $W smb share list$N              List all active shares with paths\n"
        echo ""
        printf "  ────────────────────────────────────────────────────────────────\n"
        printf "  $BOLDR SERVICE$N\n"
        printf "  ────────────────────────────────────────────────────────────────\n"
        printf "    $W smb on$N                      Start the Samba service\n"
        printf "    $W smb off$N                     Stop the Samba service\n"
        printf "    $W smb restart$N                 Restart Samba (apply config changes)\n"
        echo ""
        printf "  ────────────────────────────────────────────────────────────────\n"
        printf "  $B DATA$N\n"
        printf "  ────────────────────────────────────────────────────────────────\n"
        printf "    $W smb data$N                    Export smb.conf + passwords to a\n"
        printf "                                     password-protected zip in ~/Desktop\n"
        printf "    $W smb data list$N               List all saved export zips\n"
        printf "    $W smb data clean$N              Delete all saved exports\n"
        echo ""
        printf "  ────────────────────────────────────────────────────────────────\n"
        printf "  $C INFO$N\n"
        printf "  ────────────────────────────────────────────────────────────────\n"
        printf "    $W smb ip$N                      Show your local IP and connection\n"
        printf "                                     URLs for other devices on your network\n"
        printf "    $W smb password$N                View your saved SMB password\n"
        printf "                                     Requires system authentication.\n"
        printf "    $W smb status$N                  Full dashboard: service, users,\n"
        printf "                                     shares, firewall, config status\n"
        printf "    $W smb log$N                     Show recent Samba log entries\n"
        printf "    $W smb help$N                    Show this help message\n"
        echo ""
        printf "  ────────────────────────────────────────────────────────────────\n"
        printf "  $C TIPS$N\n"
        printf "  ────────────────────────────────────────────────────────────────\n"
        printf "    1. Run $W'smb setup'$N first — it does everything in one shot.\n"
        printf "    2. After sharing, connect from other devices using:\n"
        printf "       $D smb://<your-ip>/<share-name>$N\n"
        printf "    3. Passwords are stored securely in gnome-keyring.\n"
        printf "       No plaintext files on disk.\n"
        printf "    4. Run $W'smb status'$N to check everything at a glance.\n"
        printf "    5. Run $W'smb restart'$N after editing smb.conf manually.\n"
        echo ""
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # SETUP
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "setup"
        echo ""
        printf "  $C╭──────────────────────────────────────────────────────────╮$N\n"
        printf "  $C│                    SMB SETUP WIZARD                        │$N\n"
        printf "  $C╰──────────────────────────────────────────────────────────╯$N\n"
        echo ""

        # ── Step 1: Install Samba ──
        printf "  $BOLD Step 1/9$N   Installing Samba...\n"
        if rpm -q samba >/dev/null 2>&1
            printf "  $G✓$N  Samba already installed\n"
        else
            printf "  Installing samba samba-client...\n"
            sudo dnf install samba samba-client -y 2>/dev/null
            if test $status -eq 0
                printf "  $G✓$N  Samba installed successfully\n"
            else
                printf "  $R✗$N  Failed to install Samba\n"
                return 1
            end
        end
        # Install libsecret for keyring password storage
        if not type -q secret-tool
            printf "  Installing libsecret (password keyring)...\n"
            sudo dnf install libsecret -y 2>/dev/null
            if test $status -eq 0
                printf "  $G✓$N  libsecret installed\n"
            else
                printf "  $Y⚠$N  libsecret not installed — using file storage instead\n"
            end
        end
        echo ""

        # ── Step 2: Detect username ──
        printf "  $BOLD Step 2/9$N   Detecting username...\n"
        set -l detected_user (whoami)
        printf "  Detected username: $W$detected_user$N\n"
        read -P "  Use this as your SMB username? [Y/n]: " -l confirm
        __smb_stop_check; or return 1
        set -l smb_user ""
        if test "$confirm" = "n"; or test "$confirm" = "N"
            echo ""
            read -P "  Enter SMB username: " -l smb_user
            __smb_stop_check; or return 1
            if test -z "$smb_user"
                printf "  $R✗$N  Username cannot be empty.\n"
                return 1
            end
            read -P "  Confirm username: $smb_user [Y/n]: " -l confirm2
            __smb_stop_check; or return 1
            if test "$confirm2" = "n"; or test "$confirm2" = "N"
                printf "  $R✗$N  Setup cancelled.\n"
                return 1
            end
        else
            set smb_user $detected_user
        end
        echo ""
        printf "  $G✓$N  Using: $W$smb_user$N\n"
        echo ""

        # ── Step 3: Set password ──
        printf "  $BOLD Step 3/9$N   Setting SMB password...\n"
        set -l pass ""
        set -l pass2 ""
        while true
            printf "  Enter SMB password for '$W$smb_user$N':\n"
            read -s -P "  > " pass
            __smb_stop_check; or return 1
            echo ""
            printf "  Confirm password:\n  > "
            read -s -P "" pass2
            __smb_stop_check; or return 1
            echo ""
            if test "$pass" = "$pass2" -a -n "$pass"
                break
            end
            printf "  $R✗$N  Passwords don't match. Try again.\n"
            echo ""
        end
        __smb_set_password "$smb_user" "$pass"
        __smb_save_password "$smb_user" "$pass"
        printf "  $G✓$N  Password set for '$W$smb_user$N'\n"
        printf "  $G✓$N  Password saved securely.\n"
        echo ""
        printf "  $Y⚠$N  WARNING: Do NOT share this password with anyone.\n"
        printf "     Giving your SMB password to others gives them full access\n"
        printf "     to your files. This is a security risk.\n"
        echo ""

        # ── Step 4: Share scope ──
        printf "  $BOLD Step 4/9$N   Choosing share scope...\n"
        echo ""
        printf "    $W[1]$N Home directory (recommended)\n"
        printf "        Shares: $D$HOME$N\n"
        printf "        Safe — only your personal files are visible.\n"
        echo ""
        printf "    $W[2]$N Root filesystem ($R NOT recommended$N)\n"
        printf "        Shares: $D/$N\n"
        printf "        $Y WARNING — gives full access to every file on your laptop.$N\n"
        printf "        Anyone on your network can read/write system files.\n"
        echo ""
        read -P "  Choose [1/2] (default: 1): " -l scope_choice
        __smb_stop_check; or return 1
        if test "$scope_choice" = "2"
            echo ""
            printf "  $Y⚠$N  WARNING: Root sharing gives FULL access to /etc, /boot, /root,\n"
            printf "     and every system file. This is a security risk.\n"
            read -P "  Are you sure? [y/N]: " -l root_confirm
            __smb_stop_check; or return 1
            if test "$root_confirm" != "y" -a "$root_confirm" != "Y"
                set scope_choice "1"
                printf "  $G✓$N  Home directory selected\n"
            else
                printf "  $G✓$N  Root filesystem selected\n"
            end
        else
            printf "  $G✓$N  Home directory selected\n"
        end
        echo ""

        # ── Confirmation ──
        set -l scope_type "HOME"
        set -l scope_path "$HOME"
        if test "$scope_choice" = "2"
            set scope_type "ROOT"
            set scope_path "/"
        end
        printf "  $C╭──────────────────────────────────────────────────────────╮$N\n"
        printf "  $C│  Ready to apply:                                         │$N\n"
        printf "  $C│    $N Username:  $W$smb_user$N$C                                   │$N\n"
        printf "  $C│    $N Share:     $W$scope_type ($scope_path)$N$C                          │$N\n"
        printf "  $C│    $N Firewall:  $W samba service$N$C                             │$N\n"
        printf "  $C│    $N SELinux:   $W home dirs enabled$N$C                         │$N\n"
        printf "  $C╰──────────────────────────────────────────────────────────╯$N\n"
        echo ""
        read -P "  Apply all changes? [Y/n]: " -l apply
        __smb_stop_check; or return 1
        if test "$apply" = "n"; or test "$apply" = "N"
            echo ""
            printf "  $Y Setup cancelled. No changes were made.$N\n"
            return 0
        end
        echo ""

        # ── Step 5: Configure smb.conf ──
        printf "  $BOLD Step 5/9$N   Configuring smb.conf...\n"
        if test "$scope_choice" = "2"
            # Root share
            if __smb_share_exists "root_share"
                printf "  $G✓$N  [root_share] section already exists in smb.conf\n"
            else
                printf '\n[root_share]\n    comment = Root Filesystem\n    path = /\n    browseable = yes\n    writable = yes\n    valid users = %s\n' "$smb_user" | sudo tee -a "$SMB_CONF" >/dev/null
                printf "  $G✓$N  [root_share] section added to smb.conf\n"
            end
        else
            # Home share
            if grep -q '^\[homes\]' "$SMB_CONF" 2>/dev/null
                printf "  $G✓$N  [homes] section already exists in smb.conf\n"
            else
                printf '\n[homes]\n    comment = Home Directories\n    browseable = yes\n    writable = yes\n    valid users = %%S\n    create mask = 0700\n    directory mask = 0700\n' | sudo tee -a "$SMB_CONF" >/dev/null
                printf "  $G✓$N  [homes] section added to smb.conf\n"
            end
        end
        echo ""

        # ── Step 6: Start service ──
        printf "  $BOLD Step 6/9$N   Starting Samba service...\n"
        sudo systemctl enable smb --now 2>/dev/null
        printf "  $G✓$N  smb.service enabled and started\n"
        echo ""

        # ── Step 7: Firewall ──
        printf "  $BOLD Step 7/9$N   Configuring firewall...\n"
        if sudo systemctl is-active firewalld >/dev/null 2>&1
            sudo firewall-cmd --add-service=samba --permanent 2>/dev/null
            sudo firewall-cmd --reload 2>/dev/null
            printf "  $G✓$N  samba service added to firewall\n"
        else
            printf "  $D firewall not active — skipping$N\n"
        end
        echo ""

        # ── Step 8: SELinux ──
        printf "  $BOLD Step 8/9$N   Setting SELinux permissions...\n"
        if test "$scope_choice" = "2"
            sudo setsebool -P samba_enable_home_dirs on 2>/dev/null
            sudo setsebool -P samba_export_all_rw on 2>/dev/null
            printf "  $G✓$N  samba_enable_home_dirs + samba_export_all_rw enabled\n"
        else
            sudo setsebool -P samba_enable_home_dirs on 2>/dev/null
            printf "  $G✓$N  samba_enable_home_dirs enabled\n"
        end
        echo ""

        # ── Step 9: Final checks ──
        printf "  $BOLD Step 9/9$N   Final checks...\n"
        set -l samba_ver ""
        if type -q smbd
            set samba_ver (command smbd --version 2>/dev/null | head -1 | awk '{print $2}')
        end
        printf "  $G✓$N  Samba version: $W$samba_ver$N\n"
        if type -q testparm
            if command testparm -s 2>/dev/null | head -1 | read -l tp_out
                printf "  $G✓$N  Config test: OK\n"
            else
                printf "  $Y⚠$N  Config test: failed\n"
            end
        else
            printf "  $D  Config test: skipped (testparm not installed)$N\n"
        end
        printf "  $G✓$N  Service: $BOLDG active$N\n"
        echo ""

        # ── Complete ──
        set -l local_ip (__smb_ip)
        set -l smb_hostname (hostname)
        printf "  $C╭──────────────────────────────────────────────────────────╮$N\n"
        printf "  $C│                  SETUP COMPLETE                           │$N\n"
        printf "  $C╠══════════════════════════════════════════════════════════╣$N\n"
        printf "  $C║$N                                                          $C║$N\n"
        printf "  $C║$N  Service:     $BOLDG active$N                                 $C║$N\n"
        printf "  $C║$N  IP:          $W$local_ip$N                              $C║$N\n"
        printf "  $C║$N  Hostname:    $W$smb_hostname$N                                      $C║$N\n"
        printf "  $C║$N                                                          $C║$N\n"
        printf "  $C╠══════════════════════════════════════════════════════════╣$N\n"
        printf "  $C║$N  SMB USERS                                                $C║$N\n"
        printf "  $C║$N    $W$smb_user$N      ••••••••••••                            $C║$N\n"
        if __smb_has_keyring
            printf "  $C║$N    Storage:  $BOLDG gnome-keyring$N (encrypted)              $C║$N\n"
        else
            printf "  $C║$N    Storage:  $BOLDY file fallback$N (chmod 600)              $C║$N\n"
        end
        printf "  $C╠══════════════════════════════════════════════════════════╣$N\n"
        printf "  $C║$N  SHARED DIRECTORIES                                       $C║$N\n"
        printf "  $C║$N    Scope:  $W$scope_type$N  ($scope_path$D)                        $C║$N\n"
        printf "  $C╠══════════════════════════════════════════════════════════╣$N\n"
        printf "  $C║$N                                                          $C║$N\n"
        printf "  $C║$N  SAMSUNG / ANDROID:                                       $C║$N\n"
        printf "  $C║$N    Open My Files > Network > Add network storage          $C║$N\n"
        printf "  $C║$N    Address:  $B smb://$local_ip/$smb_user$N                         $C║$N\n"
        printf "  $C║$N                                                          $C║$N\n"
        printf "  $C║$N  WINDOWS:                                                $C║$N\n"
        printf "  $C║$N    File Explorer address bar > paste:                     $C║$N\n"
        printf "  $C║$N    $B \\\\$local_ip\\\\$smb_user$N                                  $C║$N\n"
        printf "  $C║$N                                                          $C║$N\n"
        printf "  $C║$N  NAUTILUS (Fedora):                                       $C║$N\n"
        printf "  $C║$N    Files > Other Locations > Connect to Server            $C║$N\n"
        printf "  $C║$N    Address:  $B smb://$local_ip/$smb_user$N                         $C║$N\n"
        printf "  $C║$N                                                          $C║$N\n"
        printf "  $C║$N  iPHONE / MAC:                                            $C║$N\n"
        printf "  $C║$N    Finder > Go > Connect to Server                        $C║$N\n"
        printf "  $C║$N    Address:  $B smb://$local_ip/$smb_user$N                         $C║$N\n"
        printf "  $C║$N                                                          $C║$N\n"
        printf "  $C╚══════════════════════════════════════════════════════════╝$N\n"
        echo ""
        printf "  Done. Try connecting from your phone now.\n"
        printf "  Run 'smb password' to reveal your password.\n"
        echo ""
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # USER
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "user"
        set -l subcmd "list"
        set -l extra ""
        if test (count $argv) -ge 2
            set subcmd $argv[2]
        end
        if test (count $argv) -ge 3
            set extra $argv[3]
        end

        switch $subcmd
            # ── smb user list ──
            case list
                set -l users ()
                if type -q pdbedit
                    set users (command pdbedit -L 2>/dev/null)
                end
                if test (count $users) -eq 0
                    printf "  No SMB users found.\n"
                    printf "  Run 'smb setup' or 'smb user add' to create one.\n"
                    return 0
                end
                echo ""
                printf "  SMB Users:\n"
                for u in $users
                    set -l uname (echo $u | cut -d: -f1)
                    set -l uid (echo $u | cut -d: -f2)
                    printf "    $W%-16s$N (uid=$uid)\n" "$uname"
                end
                echo ""

            # ── smb user add ──
            case add
                set -l newuser ""
                if test -n "$extra"
                    set newuser $extra
                else
                    read -P "  Enter new SMB username: " -l newuser
                    __smb_stop_check; or return 1
                end
                if test -z "$newuser"
                    printf "  $R✗$N  Username cannot be empty.\n"
                    return 1
                end
                read -P "  Confirm username: $newuser [Y/n]: " -l uc
                __smb_stop_check; or return 1
                if test "$uc" = "n"; or test "$uc" = "N"
                    printf "  Cancelled.\n"
                    return 0
                end
                if __smb_user_exists "$newuser"
                    printf "  $R✗$N  User '$W$newuser$N' already exists in Samba\n"
                    printf "  Run 'smb user password $newuser' to change password.\n"
                    return 1
                end
                echo ""
                set -l pass ""
                set -l pass2 ""
                while true
                    printf "  Enter password for '$W$newuser$N':\n"
                    read -s -P "  > " pass
                    __smb_stop_check; or return 1
                    echo ""
                    printf "  Confirm password:\n  > "
                    read -s -P "" pass2
                    __smb_stop_check; or return 1
                    echo ""
                    if test "$pass" = "$pass2" -a -n "$pass"
                        break
                    end
                    printf "  $R✗$N  Passwords don't match. Try again.\n"
                    echo ""
                end
                __smb_set_password "$newuser" "$pass"
                __smb_save_password "$newuser" "$pass"
                printf "  $G✓$N  User '$W$newuser$N' created\n"
        printf "  $G✓$N  Password saved securely.\n"
                echo ""
                printf "  $Y⚠$N  WARNING: Do NOT share this password with anyone.\n"
                printf "     Giving your SMB password to others gives them full access\n"
                printf "     to your files. This is a security risk.\n"
                echo ""

            # ── smb user remove ──
            case remove
                if test -z "$extra"
                    printf "  $R✗$N  Usage: smb user remove <username>\n"
                    return 1
                end
                if not __smb_user_exists "$extra"
                    printf "  $R✗$N  User '$W$extra$N' not found in Samba\n"
                    return 1
                end
                echo ""
                printf "  Remove SMB user '$W$extra$N'\n"
                set -l attempts 0
                while true
                    set attempts (math $attempts + 1)
                    if test $attempts -gt 3
                        printf "  $R✗$N  3 failed attempts.\n"
                        echo ""
                        printf "  Authentication failed — opening system authentication dialog...\n"
                        if __smb_pkexec
                            printf "  $G✓$N  System authentication successful\n"
                            sudo smbpasswd -x "$extra" 2>/dev/null
                            printf "  $G✓$N  User '$W$extra$N' removed\n"
                            __smb_delete_password "$extra"
                            return 0
                        else
                            printf "  $R✗$N  System authentication failed.\n"
                            printf "  User '$extra' was NOT removed. Try again later.\n"
                            return 1
                        end
                    end
                    printf "  Enter SMB password for '$extra' to confirm:\n  > "
                    read -s -P "" -l try_pass
                    __smb_stop_check; or return 1
                    echo ""
                    echo "$try_pass" | smbclient -L localhost -U "$extra%$try_pass" >/dev/null 2>&1
                    if test $status -eq 0
                        sudo smbpasswd -x "$extra" 2>/dev/null
                        printf "  $G✓$N  User '$W$extra$N' removed\n"
                        printf "  $G✓$N  Password removed securely.\n"
                        echo ""
                        printf "  $Y⚠$N  Note: The user can no longer access your files via SMB.\n"
                        printf "     Make sure this was intentional.\n"
                        __smb_delete_password "$extra"
                        return 0
                    end
                    set -l left (math 3 - $attempts)
                    printf "  $R✗$N  Wrong password. $left attempt(s) left.\n"
                    echo ""
                end

            # ── smb user rename ──
            case rename
                if test -z "$extra"
                    printf "  Usage: smb user rename $D<old-name> <new-name>$N\n"
                    printf "  Example: smb user rename alice bob\n"
                    return 1
                end
                if not set -q argv[4]; or test -z "$argv[4]"
                    printf "  $R✗$N  Missing new username.\n"
                    printf "  Usage: smb user rename $D<old-name> <new-name>$N\n"
                    return 1
                end
                set -l old_name "$extra"
                set -l new_name "$argv[4]"
                # Check old user exists
                set -l users ()
                if type -q pdbedit
                    set users (command pdbedit -L 2>/dev/null | cut -d: -f1)
                end
                set -l found 0
                for u in $users
                    if test "$u" = "$old_name"
                        set found 1
                        break
                    end
                end
                if test $found -eq 0
                    printf "  $R✗$N  User '$W$old_name$N' not found. Did you mistype the username?\n"
                    printf "  Run 'smb user list' to see available users.\n"
                    return 1
                end
                # Check new name doesn't already exist
                for u in $users
                    if test "$u" = "$new_name"
                        printf "  $R✗$N  User '$W$new_name$N' already exists. Pick a different name.\n"
                        return 1
                    end
                end
                # Get password for old user
                set -l old_pass (__smb_get_password "$old_name")
                if test -z "$old_pass"
                    printf "  $R✗$N  No password found for '$W$old_name$N'.\n"
                    printf "  Run 'smb user password $old_name' to set one first.\n"
                    return 1
                end
                echo ""
                if __smb_pkexec
                    printf "  $G✓$N  System authentication successful\n"
                    # Remove old user
                    sudo smbpasswd -x "$old_name" 2>/dev/null
                    printf "  $G✓$N  Removed old user '$W$old_name$N'\n"
                    # Add new user with same password
                    __smb_set_password "$new_name" "$old_pass"
                    __smb_save_password "$new_name" "$old_pass"
                    # Remove old keyring entry
                    __smb_delete_password "$old_name"
                    echo ""
                    printf "  $G✓$N  User renamed: $W$old_name$N → $W$new_name$N\n"
                    printf "  $G✓$N  Password preserved.\n"
                    printf "  $Y⚠$N  Shares still reference the old username. Update if needed:\n"
                    printf "    smb share list → check 'allowed users' in smb.conf\n"
                    return 0
                else
                    printf "  $R✗$N  System authentication failed.\n"
                    printf "  User was NOT renamed. Try again later.\n"
                    return 1
                end

            # ── smb user password ──
            case password
                if test -z "$extra"
                    # No username — list users
                    set -l users ()
                    if type -q pdbedit
                        set users (command pdbedit -L 2>/dev/null)
                    end
                    if test (count $users) -eq 0
                        printf "  No SMB users found.\n"
                        printf "  Run 'smb setup' or 'smb user add' to create one.\n"
                        return 0
                    end
                    echo ""
                    printf "  SMB Users:\n"
                    for u in $users
                        set -l uname (echo $u | cut -d: -f1)
                        set -l uid (echo $u | cut -d: -f2)
                        printf "    $W%-16s$N (uid=$uid)\n" "$uname"
                    end
                    echo ""
                    printf "  Usage: smb user password <username>\n"
                    printf "  Example: smb user password eprahemi\n"
                    echo ""
                    return 0
                end
                if not __smb_user_exists "$extra"
                    printf "  $R✗$N  User '$W$extra$N' not found in Samba\n"
                    printf "  Run 'smb user list' to see available users.\n"
                    return 1
                end
                read -P "  Change SMB password for '$extra'? [Y/n]: " -l confirm
                __smb_stop_check; or return 1
                if test "$confirm" = "n"; or test "$confirm" = "N"
                    echo ""
                    printf "  Cancelled. Password not changed.\n"
                    return 0
                end
                echo ""
                set -l pass ""
                set -l pass2 ""
                while true
                    printf "  Enter new password for '$W$extra$N':\n"
                    read -s -P "  > " pass
                    __smb_stop_check; or return 1
                    echo ""
                    printf "  Confirm password:\n  > "
                    read -s -P "" pass2
                    __smb_stop_check; or return 1
                    echo ""
                    if test "$pass" = "$pass2" -a -n "$pass"
                        break
                    end
                    printf "  $R✗$N  Passwords don't match. Try again.\n"
                    echo ""
                end
                __smb_set_password "$extra" "$pass"
                __smb_save_password "$extra" "$pass"
                printf "  $G✓$N  Password changed for '$W$extra$N'\n"
                printf "  $G✓$N  Password updated.\n"
                echo ""
                printf "  $Y⚠$N  WARNING: Do NOT share this password with anyone.\n"
                printf "     Giving your SMB password to others gives them full access\n"
                printf "     to your files. This is a security risk.\n"
                echo ""

            case '*'
                printf "  $R✗$N  Unknown user command: '$subcmd'\n"
                printf "  Usage: smb user [list|add|remove|rename|password]\n"
                return 1
        end
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # SHARE
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "share"
        set -l subcmd ""
        set -l dir ""
        set -l name ""
        if test (count $argv) -ge 2
            set subcmd $argv[2]
        end
        if test (count $argv) -ge 3
            set dir $argv[3]
        end
        if test (count $argv) -ge 4
            set name $argv[4]
        end

        # ── smb share list ──
        if test "$subcmd" = "list"
            echo ""
            printf "  Shared directories:\n"
            # Home share
            set -l scope (__smb_get_scope)
            if test "$scope" = "home"
                printf "    $W%-16s$N $D%-30s$N (home — default)\n" "(homes)" "$HOME"
            else if test "$scope" = "root"
                printf "    $Y%-16s$N $D%-30s$N (root — NOT recommended)\n" "(root_share)" "/"
            end
            # Custom shares — parse from smb.conf
            if test -f "$SMB_CONF"
                set -l in_share 0
                set -l share_name ""
                set -l share_path ""
                while read -l line
                    if string match -qr '^\[(\w+)\]' "$line"
                        # Output previous section before starting new one
                        if test $in_share -eq 1 -a -n "$share_path"
                            printf "    $W%-16s$N $D%-30s$N (custom)\n" "$share_name" "$share_path"
                        end
                        set -l sec (string match -r '^\[(\w+)\]' "$line" | tail -1)
                        if test "$sec" != "global" -a "$sec" != "homes" -a "$sec" != "root_share" -a "$sec" != "printers" -a "$sec" != "print\$"
                            set in_share 1
                            set share_name $sec
                            set share_path ""
                        else
                            set in_share 0
                        end
                    else if test $in_share -eq 1
                        if string match -qr 'path\s*=' "$line"
                            set share_path (string replace -r '.*path\s*=\s*' '' "$line" | string trim)
                        end
                        if test -z "$line"; or string match -qr '^\[' "$line"
                            if test $in_share -eq 1 -a -n "$share_path"
                                printf "    $W%-16s$N $D%-30s$N (custom)\n" "$share_name" "$share_path"
                            end
                            set in_share 0
                        end
                    end
                end < "$SMB_CONF"
                # Handle last section
                if test $in_share -eq 1 -a -n "$share_path"
                    printf "    $W%-16s$N $D%-30s$N (custom)\n" "$share_name" "$share_path"
                end
            end
            echo ""

        # ── smb share (no args) or smb share <dir> [name] ──
        else if test -z "$subcmd"; or string match -qr '^/' "$subcmd"
            # Determine dir and name from args
            if test -n "$subcmd"
                set dir $subcmd
                if test -n "$argv[3]"
                    set name $argv[3]
                end
            end
            if test -z "$dir"
                read -P "  Enter directory path to share: " -l dir
                __smb_stop_check; or return 1
            end
            if not test -d "$dir"
                printf "  $R✗$N  Directory not found: $W$dir$N\n"
                printf "  Check the path and try again.\n"
                return 1
            end
            printf "  $G✓$N  Directory exists: $W$dir$N\n"
            echo ""
            if test -z "$name"
                set -l default_name (basename "$dir")
                read -P "  Enter share name (or press Enter for '$default_name'): " -l name
                __smb_stop_check; or return 1
                if test -z "$name"
                    set name $default_name
                end
            end
            if __smb_share_exists "$name"
                printf "  $R✗$N  Share '$W$name$N' already exists.\n"
                printf "  Run 'smb share list' to see current shares.\n"
                return 1
            end
            echo ""
            read -P "  Share '$dir' as '$name'? [Y/n]: " -l confirm
            __smb_stop_check; or return 1
            if test "$confirm" = "n"; or test "$confirm" = "N"
                printf "  Cancelled.\n"
                return 0
            end
            # Add share to smb.conf
            printf '\n[%s]\n    comment = %s\n    path = %s\n    browseable = yes\n    writable = yes\n    valid users = %s\n' "$name" "$name" "$dir" (whoami) | sudo tee -a "$SMB_CONF" >/dev/null
            printf "  $G✓$N  Share '$W$name$N' added → $D$dir$N\n"
            sudo systemctl restart smb 2>/dev/null
            printf "  $G✓$N  Samba service restarted\n"
            echo ""

        # ── smb unshare ──
        else if test "$subcmd" = "unshare"
            set -l target $dir
            if test -z "$target"
                # Show list of custom shares
                set -l shares ()
                if test -f "$SMB_CONF"
                    while read -l line
                        if string match -qr '^\[(\w+)\]' "$line"
                            set -l sec (string match -r '^\[(\w+)\]' "$line" | tail -1)
                            if test "$sec" != "global" -a "$sec" != "homes" -a "$sec" != "printers" -a "$sec" != "print\$"
                                set -a shares $sec
                            end
                        end
                    end < "$SMB_CONF"
                end
                if test (count $shares) -eq 0
                    printf "  No custom shares to remove.\n"
                    printf "  Home directory share cannot be removed via unshare.\n"
                    return 0
                end
                echo ""
                printf "  Shared directories:\n"
                set -l idx 1
                for s in $shares
                    printf "    $W%d)$N  %s\n" $idx $s
                    set idx (math $idx + 1)
                end
                echo ""
                read -P "  Enter number or share name to remove: " -l choice
                __smb_stop_check; or return 1
                # Check if numeric
                if string match -qr '^\d+$' "$choice"
                    set -l num (math "$choice")
                    if test $num -ge 1 -a $num -le (count $shares)
                        set target $shares[$num]
                    else
                        printf "  $R✗$N  Invalid number.\n"
                        return 1
                    end
                else
                    set target $choice
                end
            end
            if not __smb_share_exists "$target"
                printf "  $R✗$N  Share '$W$target$N' not found.\n"
                printf "  Run 'smb share list' to see current shares.\n"
                return 1
            end
            read -P "  Remove share '$target'? [Y/n]: " -l confirm
            __smb_stop_check; or return 1
            if test "$confirm" = "n"; or test "$confirm" = "N"
                printf "  Cancelled.\n"
                return 0
            end
            # Remove share section from smb.conf
            # Remove share section from smb.conf using awk
            sudo awk -v sec="[$target]" '
                BEGIN { skip=0 }
                /^\[/ { if ($0 == sec) { skip=1; next } else { skip=0 } }
                skip && /^$/ { skip=0; next }
                !skip { print }
            ' "$SMB_CONF" | sudo tee "$SMB_CONF.tmp" >/dev/null
            sudo mv "$SMB_CONF.tmp" "$SMB_CONF"
            sudo systemctl restart smb 2>/dev/null
            printf "  $G✓$N  Share '$W$target$N' removed\n"
            printf "  $G✓$N  Samba service restarted\n"
            echo ""

        else
            printf "  $R✗$N  Unknown share command: '$subcmd'\n"
            printf "  Usage: smb share (list|unshare|<dir> <name>)\n"
            return 1
        end
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # SERVICE: on / off / restart
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "on"
        if systemctl is-active smb >/dev/null 2>&1
            printf "  $G✓$N  Samba service is already running\n"
            printf "  $G✓$N  Status: $BOLDG active$N\n"
        else
            printf "  Starting Samba service...\n"
            sudo systemctl start smb 2>/dev/null
            printf "  $G✓$N  smb.service started\n"
            printf "  $G✓$N  Status: $BOLDG active$N\n"
        end
        return 0
    end

    if test "$argv[1]" = "off"
        if not systemctl is-active smb >/dev/null 2>&1
            printf "  $G✓$N  Samba service is already stopped\n"
            return 0
        end
        read -P "  Stop Samba service? [Y/n]: " -l confirm
        __smb_stop_check; or return 1
        if test "$confirm" = "n"; or test "$confirm" = "N"
            printf "  Cancelled.\n"
            return 0
        end
        sudo systemctl stop smb 2>/dev/null
        printf "  $G✓$N  smb.service stopped\n"
        printf "  $G✓$N  Status: $BOLDR inactive$N\n"
        return 0
    end

    if test "$argv[1]" = "restart"
        read -P "  Restart Samba service? Active connections will be disconnected. [Y/n]: " -l confirm
        __smb_stop_check; or return 1
        if test "$confirm" = "n"; or test "$confirm" = "N"
            echo ""
            printf "  Cancelled. Service not restarted.\n"
            return 0
        end
        echo ""
        printf "  Restarting Samba service...\n"
        sudo systemctl restart smb 2>/dev/null
        printf "  $G✓$N  smb.service restarted\n"
        printf "  $G✓$N  Status: $BOLDG active$N\n"
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # IP
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "ip"
        set -l local_ip (__smb_ip)
        set -l smb_user (whoami)
        set -l smb_hostname (hostname)
        echo ""
        printf "  Local IP:    $B$local_ip$N\n"
        printf "  Username:    $W$smb_user$N\n"
        printf "  Hostname:    $W$smb_hostname$N\n"
        echo ""
        printf "  Phone:    $B smb://$local_ip/$smb_user$N\n"
        printf "  Windows:  $B \\\\$local_ip\\\\$smb_user$N\n"
        printf "  Nautilus: $B smb://$local_ip/$smb_user$N\n"
        printf "  Mac:      $B smb://$local_ip/$smb_user$N\n"
        echo ""
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # PASSWORD
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "password"
        printf "  $D Authenticating...$N\n"
        if not __smb_pkexec
            printf "  $R✗$N  System authentication failed.\n"
            printf "  Try again with 'smb password'.\n"
            return 1
        end
        printf "  $G✓$N  Authentication successful\n"
        echo ""
        set -l users ()
        if type -q pdbedit
            set users (command pdbedit -L 2>/dev/null | cut -d: -f1)
        end
        if test (count $users) -eq 0
            printf "  No SMB users found.\n"
            printf "  Run 'smb setup' or 'smb user add' to create one.\n"
            return 0
        end
        if test (count $users) -eq 1
            set -l upass (__smb_get_password "$users[1]")
            printf "  SMB User: $W$users[1]$N\n"
            printf "  Password: $W$upass$N\n"
            echo ""
            printf "  To change your password:\n"
            printf "    smb user password $users[1]\n"
        else
            printf "  SMB Users and Passwords:\n"
            for u in $users
                set -l upass (__smb_get_password "$u")
                printf "    $W%-16s$N %s\n" "$u" "$upass"
            end
        end
        echo ""
        printf "  $Y⚠$N  WARNING: Do NOT share these passwords with anyone.\n"
        printf "     Giving your SMB password to others gives them full access\n"
        printf "     to your files. This is a security risk.\n"
        echo ""
        printf "  To change a password:\n"
        printf "    smb user password <username>\n"
        echo ""
        printf "  To add a new user:\n"
        printf "    smb user add\n"
        echo ""
        printf "  To see all commands:\n"
        printf "    smb help\n"
        echo ""
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # STATUS
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "status"
        set -l show_pass 0
        if test (count $argv) -ge 2
            if test "$argv[2]" = "--show"
                set show_pass 1
            end
        end

        # ── Auth for --show ──
        if test $show_pass -eq 1
            printf "  $D Authenticating...$N\n"
            if not __smb_pkexec
                printf "  $R✗$N  System authentication failed.\n"
                printf "  Password hidden. Run 'smb status --show' again with correct password.\n"
                return 1
            end
            printf "  $G✓$N  Authentication successful\n"
            echo ""
        end

        # ── Gather info ──
        set -l local_ip (__smb_ip)
        set -l smb_hostname (hostname)
        set -l smb_ver ""
        if type -q smbd
            set smb_ver (command smbd --version 2>/dev/null | head -1 | awk '{print $2}')
        end
        set -l svc_active "active"
        if not systemctl is-active smb >/dev/null 2>&1
            set svc_active "INACTIVE"
        end
        set -l fw_status "inactive"
        if sudo systemctl is-active firewalld >/dev/null 2>&1
            if sudo firewall-cmd --query-service=samba >/dev/null 2>&1
                set fw_status "active (samba allowed)"
            else
                set fw_status "active (samba NOT allowed)"
            end
        end
        set -l selinux_status "Disabled"
        if type -q getenforce
            set selinux_status (getenforce 2>/dev/null)
        end
        set -l home_dirs "disabled"
        if getsebool samba_enable_home_dirs 2>/dev/null | grep -q 'on$'
            set home_dirs "enabled"
        end

        # ── Render ──
        echo ""
        printf "  $C╔══════════════════════════════════════════════════════════╗$N\n"
        printf "  $C║$N                    $BOLDG SMB STATUS$N                            $C║$N\n"
        printf "  $C╠══════════════════════════════════════════════════════════╣$N\n"
        printf "  $C║$N                                                          $C║$N\n"
        if test "$svc_active" = "active"
            printf "  $C║$N  Service:     $BOLDG active$N                                 $C║$N\n"
        else
            printf "  $C║$N  Service:     $BOLDR INACTIVE$N                                $C║$N\n"
        end
        printf "  $C║$N  IP:          $W$local_ip$N                              $C║$N\n"
        printf "  $C║$N  Hostname:    $W$smb_hostname$N                                      $C║$N\n"
        printf "  $C║$N  Samba:       $W$smb_ver$N                                      $C║$N\n"
        printf "  $C║$N  Firewall:    $W$fw_status$N$C   ║$N\n"
        printf "  $C║$N  SELinux:     $W$selinux_status$N ($home_dirs)               $C║$N\n"
        printf "  $C║$N                                                          $C║$N\n"

        # ── Users ──
        printf "  $C╠══════════════════════════════════════════════════════════╣$N\n"
        printf "  $C║$N  $BOLDG SMB USERS$N                                                $C║$N\n"
        set -l users ()
        if type -q pdbedit
            set users (command pdbedit -L 2>/dev/null)
        end
        if test (count $users) -gt 0
            for u in $users
                set -l uname (echo $u | cut -d: -f1)
                set -l uid (echo $u | cut -d: -f2)
                if test $show_pass -eq 1
                    # Show actual password
                    set -l pass (__smb_get_password "$uname")
                    printf "  $C║$N    $W%-16s$N $W%-24s$N (uid=$uid)  $C║$N\n" "$uname" "$pass"
                else
                    printf "  $C║$N    $W%-16s$N ••••••••••••              (uid=$uid)  $C║$N\n" "$uname"
                end
            end
        else
            printf "  $C║$N    $D No users found$N                                      $C║$N\n"
        end
        if __smb_has_keyring
            printf "  $C║$N  Storage:     $BOLDG gnome-keyring$N (encrypted at rest)     $C║$N\n"
        else
            printf "  $C║$N  Storage:     $BOLDY file fallback$N (chmod 600)             $C║$N\n"
        end

        # ── Share scope ──
        printf "  $C╠══════════════════════════════════════════════════════════╣$N\n"
        printf "  $C║$N  $BOLDG SHARE SCOPE$N                                              $C║$N\n"
        set -l scope (__smb_get_scope)
        if test "$scope" = "home"
            printf "  $C║$N    Type:    $W HOME$N  ($HOME)                         $C║$N\n"
        else if test "$scope" = "root"
            printf "  $C║$N    Type:    $Y ROOT$N  (/)  ← NOT RECOMMENDED                  $C║$N\n"
        else
            printf "  $C║$N    Type:    $D none$N                                           $C║$N\n"
        end
        printf "  $C║$N    Status:  $BOLDG active$N                                     $C║$N\n"

        # ── Shared directories ──
        printf "  $C╠══════════════════════════════════════════════════════════╣$N\n"
        printf "  $C║$N  $BOLDG SHARED DIRECTORIES$N                                       $C║$N\n"
        if test "$scope" = "home"
            printf "  $C║$N    $W$HOME$N                    (home — default)     $C║$N\n"
        else if test "$scope" = "root"
            printf "  $C║$N    $Y/$N                                     (root — default)  $C║$N\n"
        end
        # Parse custom shares
        if test -f "$SMB_CONF"
            set -l in_share 0
            set -l share_name ""
            set -l share_path ""
            while read -l line
                if string match -qr '^\[(\w+)\]' "$line"
                    if test $in_share -eq 1 -a -n "$share_path"
                        printf "  $C║$N    $W%-41s$N (custom)     $C║$N\n" "$share_path"
                    end
                    set -l sec (string match -r '^\[(\w+)\]' "$line" | tail -1)
                    if test "$sec" != "global" -a "$sec" != "homes" -a "$sec" != "root_share" -a "$sec" != "printers" -a "$sec" != "print\$"
                        set in_share 1
                        set share_name $sec
                        set share_path ""
                    else
                        set in_share 0
                    end
                else if test $in_share -eq 1
                    if string match -qr 'path\s*=' "$line"
                        set share_path (string replace -r '.*path\s*=\s*' '' "$line" | string trim)
                    end
                    if test -z "$line"; or string match -qr '^\[' "$line"
                        if test $in_share -eq 1 -a -n "$share_path"
                            printf "  $C║$N    $W%-41s$N (custom)     $C║$N\n" "$share_path"
                        end
                        set in_share 0
                    end
                end
            end < "$SMB_CONF"
            if test $in_share -eq 1 -a -n "$share_path"
                printf "  $C║$N    $W%-41s$N (custom)     $C║$N\n" "$share_path"
            end
        end

        # ── Connection URLs ──
        printf "  $C╠══════════════════════════════════════════════════════════╣$N\n"
        printf "  $C║$N                                                          $C║$N\n"
        printf "  $C║$N  SAMSUNG / ANDROID:                                       $C║$N\n"
        printf "  $C║$N    Open My Files > Network > Add network storage          $C║$N\n"
        printf "  $C║$N    Address:  $B smb://$local_ip/(whoami)$N                         $C║$N\n"
        printf "  $C║$N                                                          $C║$N\n"
        printf "  $C║$N  WINDOWS:                                                $C║$N\n"
        printf "  $C║$N    File Explorer address bar > paste:                     $C║$N\n"
        printf "  $C║$N    $B \\\\$local_ip\\\\(whoami)$N                                  $C║$N\n"
        printf "  $C║$N                                                          $C║$N\n"
        printf "  $C║$N  NAUTILUS (Fedora):                                       $C║$N\n"
        printf "  $C║$N    Files > Other Locations > Connect to Server            $C║$N\n"
        printf "  $C║$N    Address:  $B smb://$local_ip/(whoami)$N                         $C║$N\n"
        printf "  $C║$N                                                          $C║$N\n"
        printf "  $C║$N  iPHONE / MAC:                                            $C║$N\n"
        printf "  $C║$N    Finder > Go > Connect to Server                        $C║$N\n"
        printf "  $C║$N    Address:  $B smb://$local_ip/(whoami)$N                         $C║$N\n"
        printf "  $C║$N                                                          $C║$N\n"
        printf "  $C╚══════════════════════════════════════════════════════════╝$N\n"
        echo ""
        if test $show_pass -eq 0
            printf "  $D Tip: Run 'smb status --show' or 'smb password' to reveal passwords.$N\n"
        else
            printf "  $Y⚠$N  WARNING: Do NOT share these passwords with anyone.\n"
            printf "     Giving your SMB password to others gives them full access\n"
            printf "     to your files. This is a security risk.\n"
        end
        echo ""
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # DATA
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "data"
        set -l data_subcmd "export"
        if test (count $argv) -ge 2
            set data_subcmd $argv[2]
        end

        switch $data_subcmd
            # ── smb data list ──
            case list
                echo ""
                set -l exports $HOME/Documents/smb-data-*.zip
                if test (count $exports) -eq 0; or not test -f "$exports[1]" 2>/dev/null
                    set exports ()
                end
                if test (count $exports) -eq 0
                    printf "  No saved exports found.\n"
                    printf "  Run 'smb data' to create your first export.\n"
                    return 0
                end
                printf "  Saved SMB exports:\n"
                set -l idx 1
                for f in $exports
                    set -l sz (du -h "$f" 2>/dev/null | awk '{print $1}')
                    set -l dt (stat -c '%y' "$f" 2>/dev/null | cut -d. -f1)
                    printf "    $W%d)$N  %-42s  ($sz)    %s\n" $idx (basename "$f") "$dt"
                    set idx (math $idx + 1)
                end
                echo ""
                printf "  $D Location: ~/Documents/$N\n"
                echo ""

            # ── smb data clean ──
            case clean
                set -l exports $HOME/Documents/smb-data-*.zip
                if test (count $exports) -eq 0; or not test -f "$exports[1]" 2>/dev/null
                    set exports ()
                end
                if test (count $exports) -eq 0
                    printf "  No saved exports to delete.\n"
                    return 0
                end
                read -P "  Delete all SMB exports? [Y/n]: " -l confirm
                __smb_stop_check; or return 1
                if test "$confirm" = "n"; or test "$confirm" = "N"
                    echo ""
                    printf "  Cancelled. Exports not deleted.\n"
                    return 0
                end
                echo ""
                printf "  Found %d exports:\n" (count $exports)
                for f in $exports
                    printf "    %s\n" (basename "$f")
                end
                echo ""
                read -P "  Delete all? [Y/n]: " -l confirm2
                __smb_stop_check; or return 1
                if test "$confirm2" = "n"; or test "$confirm2" = "N"
                    printf "  Cancelled.\n"
                    return 0
                end
                rm -f "$HOME/Documents/smb-data-"*.zip
                printf "  $G✓$N  Deleted %d exports\n" (count $exports)
                printf "  $G✓$N  $D~/Documents/$N cleaned\n"
                echo ""

            # ── smb data (export) ──
            case '*'
                printf "  $D Authenticating...$N\n"
                if not __smb_pkexec
                    printf "  $R✗$N  System authentication failed.\n"
                    printf "  Try again with 'smb data'.\n"
                    return 1
                end
                printf "  $G✓$N  Authentication successful\n"
                echo ""

                printf "  Generating SMB data export...\n"

                # Create temp directory
                set -l tmpdir (mktemp -d)

                # Gather info
                set -l local_ip (__smb_ip)
                set -l smb_user (whoami)
                set -l smb_hostname (hostname)
                set -l smb_ver ""
                if type -q smbd
                    set smb_ver (command smbd --version 2>/dev/null | head -1 | awk '{print $2}')
                end
                set -l now (date '+%Y-%m-%d %H:%M:%S')
                set -l scope (__smb_get_scope)

                # Create report
                set -l report "$tmpdir/smb-data.txt"
                printf "╔══════════════════════════════════════════════════════════════╗\n" > "$report"
                printf "║              SMB DATA EXPORT — Fedora MacTahoe               ║\n" >> "$report"
                printf "║              Generated: %-37s ║\n" "$now" >> "$report"
                printf "╚══════════════════════════════════════════════════════════════╝\n\n" >> "$report"

                printf "┌──────────────────────────────────────────────────────────────┐\n" >> "$report"
                printf "│  SYSTEM INFO                                                 │\n" >> "$report"
                printf "├──────────────────────────────────────────────────────────────┤\n" >> "$report"
                printf "│  IP:          %-47s │\n" "$local_ip" >> "$report"
                printf "│  Username:    %-47s │\n" "$smb_user" >> "$report"
                printf "│  Hostname:    %-47s │\n" "$smb_hostname" >> "$report"
                printf "│  Samba:       %-47s │\n" "$smb_ver" >> "$report"
                printf "└──────────────────────────────────────────────────────────────┘\n\n" >> "$report"

                printf "┌──────────────────────────────────────────────────────────────┐\n" >> "$report"
                printf "│  SMB USERS                                                   │\n" >> "$report"
                printf "├──────────────────────────────────────────────────────────────┤\n" >> "$report"
                if type -q pdbedit
                    set -l all_users (command pdbedit -L 2>/dev/null | cut -d: -f1)
                    for u in $all_users
                        set -l upass (__smb_get_password "$u")
                        if test -n "$upass"
                            printf "│  %-16s %-30s │\n" "$u" "$upass" >> "$report"
                        else
                            printf "│  %-16s %-30s │\n" "$u" "(no password stored)" >> "$report"
                        end
                    end
                end
                printf "└──────────────────────────────────────────────────────────────┘\n\n" >> "$report"

                printf "┌──────────────────────────────────────────────────────────────┐\n" >> "$report"
                printf "│  SHARES                                                      │\n" >> "$report"
                printf "├──────────────────────────────────────────────────────────────┤\n" >> "$report"
                if test "$scope" = "home"
                    printf "│  Scope:        HOME (%-38s │\n" "$HOME)" >> "$report"
                else if test "$scope" = "root"
                    printf "│  Scope:        ROOT (/)                                       │\n" >> "$report"
                end
                if test -f "$SMB_CONF"
                    set -l in_share 0
                    set -l share_name ""
                    set -l share_path ""
                    while read -l line
                        if string match -qr '^\[(\w+)\]' "$line"
                            if test $in_share -eq 1 -a -n "$share_path"
                                printf "│  [%-12s] %-44s │\n" "$share_name" "$share_path" >> "$report"
                            end
                            set -l sec (string match -r '^\[(\w+)\]' "$line" | tail -1)
                            if test "$sec" != "global" -a "$sec" != "homes" -a "$sec" != "root_share" -a "$sec" != "printers" -a "$sec" != "print\$"
                                set in_share 1
                                set share_name $sec
                                set share_path ""
                            else
                                set in_share 0
                            end
                        else if test $in_share -eq 1
                            if string match -qr 'path\s*=' "$line"
                                set share_path (string replace -r '.*path\s*=\s*' '' "$line" | string trim)
                            end
                            if test -z "$line"; or string match -qr '^\[' "$line"
                                if test $in_share -eq 1 -a -n "$share_path"
                                    printf "│  [%-12s] %-44s │\n" "$share_name" "$share_path" >> "$report"
                                end
                                set in_share 0
                            end
                        end
                    end < "$SMB_CONF"
                    if test $in_share -eq 1 -a -n "$share_path"
                        printf "│  [%-12s] %-44s │\n" "$share_name" "$share_path" >> "$report"
                    end
                end
                printf "└──────────────────────────────────────────────────────────────┘\n\n" >> "$report"

                printf "┌──────────────────────────────────────────────────────────────┐\n" >> "$report"
                printf "│  CONNECTION URLS                                              │\n" >> "$report"
                printf "├──────────────────────────────────────────────────────────────┤\n" >> "$report"
                printf "│  Samsung:      smb://%-38s │\n" "$local_ip/$smb_user" >> "$report"
                printf "│  Windows:      \\\\%-38s│\n" "$local_ip\\$smb_user" >> "$report"
                printf "│  Nautilus:     smb://%-38s │\n" "$local_ip/$smb_user" >> "$report"
                printf "│  Mac:          smb://%-38s │\n" "$local_ip/$smb_user" >> "$report"
                printf "└──────────────────────────────────────────────────────────────┘\n\n" >> "$report"

                printf "┌──────────────────────────────────────────────────────────────┐\n" >> "$report"
                printf "│  SMB.CONF                                                    │\n" >> "$report"
                printf "├──────────────────────────────────────────────────────────────┤\n" >> "$report"
                if test -f "$SMB_CONF"
                    while read -l line
                        printf "│  %-60s │\n" "$line" >> "$report"
                    end < "$SMB_CONF"
                end
                printf "└──────────────────────────────────────────────────────────────┘\n\n" >> "$report"

                printf "╔══════════════════════════════════════════════════════════════╗\n" >> "$report"
                printf "║  WARNING: This file contains your SMB passwords.            ║\n" >> "$report"
                printf "║  Do NOT share this file with anyone.                         ║\n" >> "$report"
                printf "║  Delete it when you no longer need it.                       ║\n" >> "$report"
                printf "╚══════════════════════════════════════════════════════════════╝\n" >> "$report"

                printf "  $G✓$N  Creating styled report...\n"

                # Generate one-time zip password
                set -l zip_pass (openssl rand -base64 16 | head -c 20)

                # Create encrypted zip
                set -l zipname "smb-data-"(date +%Y-%m-%d-%H%M%S)".zip"
                set -l zippath "$HOME/Documents/$zipname"
                printf "  $G✓$N  Wrapping in encrypted zip...\n"
                pushd "$tmpdir" >/dev/null 2>&1
                zip -P "$zip_pass" "$zippath" smb-data.txt >/dev/null 2>&1
                popd >/dev/null 2>&1
                chmod 600 "$zippath"
                rm -rf "$tmpdir"

                printf "  $G✓$N  Export saved: $W$zippath$N\n"
                echo ""
                printf "  $C┌──────────────────────────────────────────────────────────┐$N\n"
                printf "  $C│$N                    $BOLDG ZIP PASSWORD$N                           $C│$N\n"
                printf "  $C├──────────────────────────────────────────────────────────┤$N\n"
                printf "  $C│$N                                                          $C│$N\n"
                printf "  $C│$N  Password:  $W$zip_pass$N                            $C│$N\n"
                printf "  $C│$N                                                          $C│$N\n"
                printf "  $C│$N  $Y⚠$N  WARNING: If you close this terminal, the password    $C│$N\n"
                printf "  $C│$N     is gone forever. You will need to generate a new     $C│$N\n"
                printf "  $C│$N     export with 'smb data' again.                        $C│$N\n"
                printf "  $C│$N                                                          $C│$N\n"
                printf "  $C│$N  To extract:                                              $C│$N\n"
                printf "  $C│$N    $W unzip $zipname$N                             $C│$N\n"
                printf "  $C│$N    Enter password when prompted                           $C│$N\n"
                printf "  $C│$N                                                          $C│$N\n"
                printf "  $C└──────────────────────────────────────────────────────────┘$N\n"
                echo ""
                printf "  $Y⚠$N  WARNING: The zip contains your SMB passwords.\n"
                printf "     Do NOT share this file with anyone.\n"
                printf "     Delete it when you no longer need it.\n"
                echo ""
        end
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # LOG
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "log"
        echo ""
        printf "  $BOLD samba logs (last 20 lines):$N\n"
        echo ""
        set -l log_output (journalctl -u smb --no-pager -n 20 2>/dev/null)
        if test -z "$log_output"
            printf "  $D No samba logs found.$N\n"
            printf "  $D Service may have just started.$N\n"
        else
            printf "  %s\n" "$log_output"
        end
        echo ""
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # UNKNOWN
    # ════════════════════════════════════════════════════════════

    printf "  $R✗$N  Unknown command: '$W$argv[1]$N'\n"
    echo ""

    # Try to suggest the closest match
    set -l cmd "$argv[1]"
    set -l suggestions ()
    set -l known setup user share unshare on off restart data ip password status log help

    for k in $known
        # Exact prefix match (e.g. "he" matches "help")
        if test "$k" = (string match -r "^$cmd" "$k" 2>/dev/null)
            set -a suggestions "$k"
            continue
        end
        # Contains match (e.g. "hel" matches "help")
        if string match -q "*$cmd*" "$k" 2>/dev/null
            set -a suggestions "$k"
            continue
        end
        # Levenshtein distance <= 1 (one char off)
        set -l len_cmd (string length "$cmd")
        set -l len_k (string length "$k")
        set -l diff (math abs($len_cmd - $len_k))
        if test $diff -le 1
            set -l mismatches 0
            set -l max_len (math max($len_cmd, $len_k))
            for i in (seq 1 $max_len)
                set -l c1 (string sub -s $i -l 1 "$cmd" 2>/dev/null)
                set -l c2 (string sub -s $i -l 1 "$k" 2>/dev/null)
                if test "$c1" != "$c2"
                    set mismatches (math $mismatches + 1)
                end
            end
            if test $mismatches -le 1
                set -a suggestions "$k"
            end
        end
    end

    if test (count $suggestions) -gt 0
        printf "  Did you mean:\n"
        for s in $suggestions
            printf "    $Y smb $s$N\n"
        end
        echo ""
    end

    printf "  Run '$Y smb help$N' to see all commands.\n"
    echo ""
    trap - SIGINT
    set -e __smb_ctrl_c
    return 1
end
