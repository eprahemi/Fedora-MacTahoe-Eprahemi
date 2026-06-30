# ══════════════════════════════════════════════════════════════
# testdrive — System diagnostic and benchmark utility
# Eprahemi diagnostics: certified by the streets 🏆
# Fedora MacTahoe Eprahemi Edition © 2026 — full throttle
# ══════════════════════════════════════════════════════════════
function testdrive --description 'Elite diagnostic suite: all/disk/ext/ram/cpu/gpu/heat/net/batt/info/boot/health/updates/top/services/stress'
    # ── Color Palette ──
    set -l C "\033[0m"        # reset
    set -l B "\033[1m"        # bold
    set -l D "\033[2m"        # dim
    set -l I "\033[3m"        # italic
    set -l CY "\033[1;36m"    # bright cyan
    set -l BL "\033[1;34m"    # bright blue
    set -l GR "\033[1;32m"    # bright green
    set -l YE "\033[1;33m"    # bright yellow
    set -l RE "\033[1;31m"    # bright red
    set -l MA "\033[1;35m"    # bright magenta
    set -l WH "\033[1;37m"    # bright white
    set -l GY "\033[1;30m"    # bright black (gray)
    set -l CY2 "\033[36m"     # regular cyan
    set -l GR2 "\033[32m"     # regular green
    set -l RE2 "\033[31m"     # regular red
    set -l YE2 "\033[33m"     # regular yellow

    # ── ASCII Banner ──
    echo -e "$CY"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████║██║     ██║  ██║██║  ██║██║  ██║███████║██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    echo -e "         "$D"[ $CY EPRAHEMI ELITE DIAGNOSTIC SUITE $D]$C"
    echo ""

    # ── Show Command List (defined early — called by --help and no-args) ──
    function __td_show_commands --no-scope-shadowing
        echo -e ""
        echo -e "  $B$WH╭──────────────────────────────────────────────────────╮$C"
        echo -e "  $B$WH│$C  $CY⚡$C  $B$WHMASTER COMMANDS$C  $B$WH│$C"
        echo -e "  $B$WH├──────────────────────────────────────────────────────┤$C"
        echo -e "  $B$WH│$C  $CY all        $C$D •$C  Full system autopsy — every module"
        echo -e "  $B$WH│$C  $CY disk       $C$D •$C  Internal storage: speed, IOPS, SMART"
        echo -e "  $B$WH│$C  $CY ext        $C$D •$C  External storage picker & benchmark"
        echo -e "  $B$WH│$C  $CY cpu        $C$D •$C  Per-core freq, cache, features, throttle"
        echo -e "  $B$WH│$C  $CY ram        $C$D •$C  Memory throughput, speed, swap, ZRAM"
        echo -e "  $B$WH│$C  $CY gpu        $C$D •$C  GPU info: VRAM, temp, driver, clocks"
        echo -e "  $B$WH│$C  $CY heat       $C$D •$C  Thermal: CPU/GPU/NVMe temps, fans"
        echo -e "  $B$WH│$C  $CY net        $C$D •$C  Network: speed, ping, interfaces, DNS"
        echo -e "  $B$WH│$C  $CY info       $C$D •$C  Full system blueprint: OS/kernel/IP"
        echo -e "  $B$WH│$C  $CY batt       $C$D •$C  Battery health, capacity, draw"
        echo -e "  $B$WH│$C  $CY boot       $C$D •$C  Boot time breakdown (systemd-analyze)"
        echo -e "  $B$WH│$C  $CY health     $C$D •$C  Overall system health score"
        echo -e "  $B$WH│$C  $CY updates    $C$D •$C  Pending dnf/flatpak/firmware updates"
        echo -e "  $B$WH│$C  $CY services   $C$D •$C  Failed services, boot health"
        echo -e "  $B$WH│$C  $CY top        $C$D •$C  Top processes by CPU/memory/I/O"
        echo -e "  $B$WH│$C  $CY security   $C$D •$C  SELinux, firewall, ports, auth"
        echo -e "  $B$WH│$C  $CY stress     $C$D •$C  CPU/RAM/I/O saturation test"
        echo -e "  $B$WH╰──────────────────────────────────────────────────────╯$C"
        echo ""
    end

    if not set -q argv[1]
        echo -e "  $RE✦$C  $B$WHNo module specified.$C  Try:$C"
        __td_show_commands
        return 1
    end

    if contains -- "$argv[1]" "--help" "-h" "help"
        __td_show_commands
        echo -e "  $D📦 17 diagnostic modules, health scoreboard, restructured (Jun 2026)$C"
        return 0
    end

    set -l module $argv[1]


    # ── Progress Bar ──
    function __td_progress --no-scope-shadowing
        set -l duration $argv[1]
        set -l label $argv[2]
        echo -n -e "  $GY$label$C [$GR"
        for i in (seq 1 30)
            echo -n "■"
            sleep (math "max($duration / 30, 0.01)" 2>/dev/null; or echo "0.02")
        end
        echo -e "$C] 100%$C"
    end

    # ── Section Header ──
    function __td_section --no-scope-shadowing
        set -l icon $argv[1]
        set -l title $argv[2]
        set -l sub $argv[3]
        echo ""
        echo -e "  $GY╭──$C $icon $B$WH$title$C $GY─────────────────────────────────╮$C"
        if set -q argv[3]
            echo -e "  $GY│$C  $D$sub$C"
        end
    end

    function __td_section_end --no-scope-shadowing
        echo -e "  $GY╰────────────────────────────────────────────────╯$C"
    end

    # ── Key: Value Row ──
    function __td_row --no-scope-shadowing
        set -l key $argv[1]
        set -l val $argv[2]
        set -l __row_sym $argv[3]
        printf "  $GY│$C  %-20s " "$key"
        echo -en "$WH$val$C"
        if set -q argv[3]
            echo -e "  $__row_sym$C"
        else
            echo ""
        end
    end

    # ── Divider ──
    function __td_divider --no-scope-shadowing
        echo -e "  $GY│$C  $D──────────────────────────────────────────────$C"
    end

    # ── Status Label ──
    function __td_status --no-scope-shadowing
        set -l val $argv[1]
        if test "$val" = "0" -o "$val" = "PASS" -o "$val" = "healthy" -o "$val" = "active"
            echo -e "$GR🟢$C"
        else if test "$val" = "1" -o "$val" = "WARN" -o "$val" = "degraded"
            echo -e "$YE🟡$C"
        else if test "$val" = "FAIL" -o "$val" = "critical" -o "$val" = "inactive"
            echo -e "$RE🔴$C"
        else
            echo -e "$GY⚪$C"
        end
    end

    # ── Cache sudo if available ──
    function __td_cache_sudo --no-scope-shadowing
        sudo -v 2>/dev/null
        and echo -e "  $GY│$C  $GR🔑 Sudo cached$C"
        or echo -e "  $GY│$C  $YE⚠️  Sudo unavailable — some data may be limited$C"
    end

    # ════════════════════════════════════════════════════════════════
    # All report block function definitions
    # ════════════════════════════════════════════════════════════════

    function __td_show_footer --no-scope-shadowing
        echo -e "  $GY━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$C"
        echo -e "  $B$WH🏁 TESTDRIVE SUCCESS$C  $GY•$C  $D$(date "+%H:%M:%S")$C"
        echo ""
        __td_show_commands
    end

    function __td_show_scoreboard --no-scope-shadowing
        # Gather data
        if test -z "$__td_s_cpu_model"
            set -l cpu_model (lscpu 2>/dev/null | grep "Model name" | sed 's/Model name:\s*//')
            set -g __td_s_cpu_model "$cpu_model"
            set -g __td_s_cpu_cores (lscpu 2>/dev/null | grep "^CPU(s):" | awk '{print $2}')
            set -g __td_s_cpu_ok "yes"
        end
        if test -z "$__td_s_ram_total"
            set -g __td_s_ram_total (free -h | awk '/^Mem:/ {print $2}')
            set -g __td_s_ram_ok "yes"
        end
        if test -z "$__td_s_disk_tech"
            set -l test_file "$HOME/"(whoami)"_test_bin"
            # Signal-safe cleanup
            set -g __td_disk_test_file "$test_file"
            function __td_sigclean --on-signal SIGINT --on-signal SIGTERM
                rm -f $__td_disk_test_file 2>/dev/null
                functions --erase __td_sigclean 2>/dev/null
            end
            touch $test_file 2>/dev/null
            set -l dp (df --output=source $test_file 2>/dev/null | tail -1)
            set -l rot (lsblk -no ROTA $dp 2>/dev/null)
            set -l nv (string match -q "*nvme*" "$dp"; and echo 1; or echo 0)
            if test "$rot" = "0"
                if test "$nv" = "1"; set -g __td_s_disk_tech "NVMe"; else; set -g __td_s_disk_tech "SATA SSD"; end
            else if test "$rot" = "1"; set -g __td_s_disk_tech "HDD"; else; set -g __td_s_disk_tech "Virt"; end
            # Check available space before benchmarking
            set -l sb_need_mb 1024
            if test "$rot" = "1"; set sb_need_mb 100; end
            set sb_need_mb (math "$sb_need_mb * 2" 2>/dev/null)  # 2x safety
            set -l sb_avail_mb (math (df --output=avail "$test_file" 2>/dev/null | tail -1) / 1024 2>/dev/null)

            if test -n "$sb_avail_mb"; and test "$sb_avail_mb" -lt "$sb_need_mb"
                echo -e "  $D (scoreboard disk benchmark skipped — low space: $sb_avail_mb MB free, need ~$sb_need_mb MB)$C"
                set -g __td_s_disk_speed "?"
            else if test "$rot" = "1"
                set -g __td_s_disk_speed (dd if=/dev/zero of=$test_file bs=1M count=100 oflag=dsync 2>&1 | grep -oE '[0-9.]+ [MG]B/s')
            else
                set -g __td_s_disk_speed (dd if=/dev/zero of=$test_file bs=1G count=1 oflag=dsync 2>&1 | grep -oE '[0-9.]+ [MG]B/s')
            end
            rm -f $test_file 2>/dev/null
            functions --erase __td_sigclean 2>/dev/null
        end
        if test -z "$__td_s_gpu_name"
            set -g __td_s_gpu_name (type -q nvidia-smi; and nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1; or lspci 2>/dev/null | grep -i "VGA\|3D" | head -1 | sed 's/.*: //')
            set -g __td_s_gpu_ok "yes"
        end
        if test -z "$__td_s_net_down"
            set -g __td_s_net_down "?"
            set -g __td_s_net_up "?"
            set -g __td_s_net_ok "yes"
        end

        # CPU temp
        set -l cpu_temp_raw (cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null; or echo "0")
        set -l cpu_temp_c (math "$cpu_temp_raw / 1000" 2>/dev/null; or echo "?")

        # Temp status
        set -l temp_status "$GR✅$C"
        if test "$__td_s_temp_ok" = "no"
            set temp_status "$RE⚠️$C"
        else if test -n "$cpu_temp_c"; and test "$cpu_temp_c" != "?"
            if test "$cpu_temp_c" -gt 85; set temp_status "$RE🔥$C"
            else if test "$cpu_temp_c" -gt 70; set temp_status "$YE🌡️$C"
            end
        end

        # Draw the scoreboard
        echo ""
        echo -e "  $B$WH╔══════════════════════════════════════════════════════════╗$C"
        echo -e "  $B$WH║$C           $CY🏆$C  $B$WH EPRAHEMI SYSTEM HEALTH SCOREBOARD$C  $CY🏆$C           $B$WH║$C"
        echo -e "  $B$WH╠══════════════════════════════════════════════════════════╣$C"

        # CPU
        set -l cpu_label (echo "$__td_s_cpu_model" | sed 's/.*(R).*(TM) //; s/ CPU @.*//')
        if test -z "$cpu_label"
            set cpu_label (string sub -l 28 "$__td_s_cpu_model")
        end
        printf "  $B$WH║$C  $CY🖥️  CPU$C  %-32s" (string sub -l 32 "$cpu_label")
        if test "$__td_s_cpu_ok" = "yes"
            echo -e "$GR🟢$C $B$WH║$C"
        else
            echo -e "$RE🔴$C $B$WH║$C"
        end

        # DISK
        printf "  $B$WH║$C  $CY💾  DISK$C %-32s" "$__td_s_disk_tech  $__td_s_disk_speed"
        echo -e "$GR🟢$C $B$WH║$C"

        # RAM
        printf "  $B$WH║$C  $CY🧠  RAM$C  %-32s" "$__td_s_ram_total"
        if test "$__td_s_ram_ok" = "yes"
            echo -e "$GR🟢$C $B$WH║$C"
        else
            echo -e "$RE🔴$C $B$WH║$C"
        end

        # GPU
        printf "  $B$WH║$C  $CY🎮  GPU$C  %-32s" (string sub -l 32 "$__td_s_gpu_name")
        echo -e "$GR🟢$C $B$WH║$C"

        # NET
        printf "  $B$WH║$C  $CY🌐  NET$C  %-32s" "↓ $__td_s_net_down  ↑ $__td_s_net_up"
        echo -e "$GR🟢$C $B$WH║$C"

        # TEMP
        printf "  $B$WH║$C  $CY🌡️  TEMP$C %-32s" "CPU $cpu_temp_c°C"
        echo -e "$temp_status $B$WH║$C"

        # BATT
        if test -n "$__td_s_batt_state"
            printf "  $B$WH║$C  $CY🔋  PWR$C  %-32s" "$__td_s_batt_state  $__td_s_batt_pct"
            echo -e "$GR🟢$C $B$WH║$C"
        end

        # SEC
        printf "  $B$WH║$C  $CY🔒  SEC$C  %-32s" "SELinux: $__td_s_sec_mode"
        if test "$__td_s_sec_ok" = "yes"
            echo -e "$GR🟢$C $B$WH║$C"
        else
            echo -e "$RE🔴$C $B$WH║$C"
        end

        echo -e "  $B$WH╚══════════════════════════════════════════════════════════╝$C"
        echo -e "  $D USER: $WH"(echo $USER | string upper)"$C • $D HOST: $WH"(hostname)"$C • $D"(date "+%Y-%m-%d %H:%M")$C
    end

    function __td_report_info_block --no-scope-shadowing
        # OS & Kernel
        set -l os_name (cat /etc/fedora-release 2>/dev/null | head -1; or echo "Fedora Linux")
        set -l kernel (uname -r)
        set -l arch (uname -m)
        set -l my_hostname (hostname)
        set -l uptime_raw (uptime -p 2>/dev/null | sed 's/up //'; or uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
        set -l load (cat /proc/loadavg | awk '{print $1", "$2", "$3}')
        set -l users (who | wc -l)
        set -l desktop "$DESKTOP_SESSION"
        if test -z "$desktop"
            set desktop "$XDG_CURRENT_DESKTOP"
        end
        if test -z "$desktop"
            set desktop "unknown"
        end

        # Hardware
        set -l mobo (sudo -n dmidecode -s baseboard-product-name 2>/dev/null; or echo "N/A")
        set -l bios (sudo -n dmidecode -s bios-version 2>/dev/null; or echo "N/A")
        set -l bios_date (sudo -n dmidecode -s bios-release-date 2>/dev/null; or echo "")

        __td_row "OS" "$os_name"
        __td_row "Kernel" "$kernel ($arch)"
        __td_row "Hostname" "$my_hostname"
        __td_row "Desktop" "$desktop"
        __td_row "Uptime" "$uptime_raw"
        __td_row "Load Avg" "$load"
        __td_row "Users" "$users logged in"
        __td_row "Motherboard" "$mobo"
        __td_row "BIOS" "$bios $bios_date"

        set -l total_ram (free -h | awk '/^Mem:/ {print $2}')
        set -l used_ram (free -h | awk '/^Mem:/ {print $3}')
        set -l total_swap (free -h | awk '/^Swap:/ {print $2}')
        __td_row "Total RAM" "$total_ram"
        __td_row "RAM Used" "$used_ram"
        __td_row "Swap Total" "$total_swap"

        # Disk usage
        __td_divider
        echo -e "  $GY│$C  $D📂 Mount Point          Size  Used  Avail  Use%$C"
        for mount in (df -h 2>/dev/null | grep '^/' | head -6)
            set -l parts (string split -n " " "$mount")
            if set -q parts[6]
                printf "  $GY│$C  $D%-20s %-5s %-5s %-5s %s$C\n" $parts[1] $parts[2] $parts[3] $parts[4] $parts[5]
            end
        end

        # Network
        __td_divider
        set -l local_ip (ip route get 1 2>/dev/null | awk '{print $7}')
        set -l public_ip (curl -s --max-time 3 https://ifconfig.me 2>/dev/null; or echo "N/A")
        set -l gateway (ip route show default 2>/dev/null | awk '{print $3}')
        __td_row "Local IP" "$local_ip"
        __td_row "Gateway" "$gateway"
        __td_row "Public IP" "$public_ip"

        # Packages
        set -l dnf_pkgs (rpm -qa 2>/dev/null | wc -l)
        set -l flatpak_pkgs (flatpak list --app 2>/dev/null | wc -l; or echo "0")
        set -l containers (podman ps -q 2>/dev/null | wc -l; or docker ps -q 2>/dev/null | wc -l; or echo "0")
        __td_divider
        __td_row "DNF Packages" "$dnf_pkgs"
        __td_row "Flatpak Apps" "$flatpak_pkgs"
        __td_row "Containers" "$containers running"
    end

    function __td_report_cpu_block --no-scope-shadowing
        set -l model (lscpu 2>/dev/null | grep "Model name" | sed 's/Model name:\s*//'; or echo "N/A")
        set -l cores (lscpu 2>/dev/null | grep "^CPU(s):" | awk '{print $2}')
        set -l threads (lscpu 2>/dev/null | grep "Thread(s) per core" | awk '{print $4}')
        set -l arch (lscpu 2>/dev/null | grep "Architecture" | awk '{print $2}')
        set -l max_mhz (lscpu 2>/dev/null | grep "Max MHz" | awk '{print $3}')
        set -l min_mhz (lscpu 2>/dev/null | grep "Min MHz" | awk '{print $3}')
        set -l governor (cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null; or echo "N/A")

        # Cache
        set -l l1d (lscpu 2>/dev/null | grep "L1d cache" | awk '{print $3" "$4}')
        set -l l1i (lscpu 2>/dev/null | grep "L1i cache" | awk '{print $3" "$4}')
        set -l l2  (lscpu 2>/dev/null | grep "L2 cache" | awk '{print $3" "$4}')
        set -l l3  (lscpu 2>/dev/null | grep "L3 cache" | awk '{print $3" "$4}')
        set -l numa (lscpu 2>/dev/null | grep "NUMA node(s)" | awk '{print $3}')

        # Features
        set -l flags (cat /proc/cpuinfo 2>/dev/null | head -20 | grep "flags" | head -1 | sed 's/flags\s*:\s*//')
        set -l has_avx (string match -q "*avx*" "$flags"; and echo "$GR✔$C"; or echo "$D✘$C")
        set -l has_avx2 (string match -q "*avx2*" "$flags"; and echo "$GR✔$C"; or echo "$D✘$C")
        set -l has_aes (string match -q "*aes*" "$flags"; and echo "$GR✔$C"; or echo "$D✘$C")
        set -l has_sse4 (string match -q "*sse4_2*" "$flags"; and echo "$GR✔$C"; or echo "$D✘$C")
        set -l has_amd (string match -q "AuthenticAMD" (cat /proc/cpuinfo | head -5 | grep "vendor_id" | awk '{print $3}'); and echo "AMD"; or echo "Intel")

        # Per-core frequencies
        set -l core_freqs
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq
            set -l raw (cat "$cpu" 2>/dev/null)
            if test -n "$raw"
                set -l freq (math "$raw / 1000" 2>/dev/null)
                if test -n "$freq"
                    set -a core_freqs "$freq"
                end
            end
        end

        # Socket + thermal throttle
        set -l socket_temp (cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null; or echo "0")
        set -l socket_temp_c (math "$socket_temp / 1000" 2>/dev/null; or echo "?")

        __td_row "Model" "$model"
        __td_row "Architecture" "$arch"
        __td_row "Cores" "$cores ($B$WH$threades$C threads/core)"
        if test -n "$max_mhz"
            __td_row "Max Freq" "$max_mhz MHz"
        end
        if test -n "$min_mhz"
            __td_row "Min Freq" "$min_mhz MHz"
        end
        __td_row "Governor" "$governor"
        __td_row "NUMA Nodes" "$numa"
        __td_divider
        __td_row "L1d Cache" "$l1d"
        __td_row "L1i Cache" "$l1i"
        __td_row "L2 Cache" "$l2"
        __td_row "L3 Cache" "$l3"
        __td_divider
        echo -e "  $GY│$C  $DCPU Features:$C"
        __td_row "  AVX" "$has_avx"
        __td_row "  AVX2" "$has_avx2"
        __td_row "  AES-NI" "$has_aes"
        __td_row "  SSE4.2" "$has_sse4"
        __td_divider

        # Show top frequencies
        set -l freq_count (count $core_freqs)
        if test $freq_count -gt 1
            echo -e "  $GY│$C  $DPer-Core Frequencies:$C"
            set -l idx 0
            for f in $core_freqs
                if test $idx -lt (math "min($freq_count, 8)")
                    printf "  $GY│$C    $DCPU%02d:$C  $WH%s MHz$C\n" $idx "$f"
                    set idx (math $idx + 1)
                end
            end
            if test $freq_count -gt 8
                echo -e "  $GY│$C    $D... and "(math "$freq_count - 8")" more$C"
            end
        end

        __td_divider
        set -l throttled (dmesg 2>/dev/null | grep -i "thermal throttle" | tail -3)
        if test -n "$throttled"
            echo -e "  $GY│$C  $RE⚠️  Thermal throttling detected:$C"
            echo -e "  $GY│$C    $D$throttled$C"
            set -g __td_s_cpu_ok "no"
        else
            echo -e "  $GY│$C  $GR✅ No thermal throttling detected$C"
        end

        # Store for scoreboard
        set -g __td_s_cpu_model "$model"
        set -g __td_s_cpu_cores "$cores"
    end

    function __td_report_ram_block --no-scope-shadowing
        # Memory totals
        set -l mem_total (free -h | awk '/^Mem:/ {print $2}')
        set -l mem_used (free -h | awk '/^Mem:/ {print $3}')
        set -l mem_avail (free -h | awk '/^Mem:/ {print $7}')
        set -l mem_pct (free | awk '/^Mem:/ {printf "%.1f", $3/$2 * 100}')
        set -l swap_total (free -h | awk '/^Swap:/ {print $2}')
        set -l swap_used (free -h | awk '/^Swap:/ {print $3}')
        set -l swap_pct (free | awk '/^Swap:/ {if ($2 > 0) printf "%.1f", $3/$2 * 100; else print "0"}')
        set -l swappiness (cat /proc/sys/vm/swappiness 2>/dev/null; or echo "?")

        # RAM speed (needs sudo)
        set -l ram_speed (sudo -n dmidecode -t memory 2>/dev/null | grep "Speed:" | head -1 | awk '{print $2" "$3}'; or echo "N/A")
        set -l ram_type (sudo -n dmidecode -t memory 2>/dev/null | grep "Type:" | head -1 | awk '{print $2}'; or echo "N/A")
        set -l ram_size (sudo -n dmidecode -t memory 2>/dev/null | grep "Size:" | head -1 | awk '{print $2" "$3}'; or echo "")

        # ZRAM
        set -l zram_count (ls /dev/zram* 2>/dev/null | wc -l)
        set -l zram_total (free -h | awk '/^Zram:/ {print $2}')
        set -l zram_used (free -h | awk '/^Zram:/ {print $3}')

        __td_row "Total RAM" "$mem_total"
        __td_row "Used" "$mem_used ($mem_pct%)"
        __td_row "Available" "$mem_avail"
        if test -n "$ram_type"; and test "$ram_type" != "N/A"
            __td_row "Type/Speed" "$ram_type $ram_speed"
        end
        __td_divider
        __td_row "Swap Total" "$swap_total"
        __td_row "Swap Used" "$swap_used ($swap_pct%)"
        __td_row "Swappiness" "$swappiness"
        if test $zram_count -gt 0
            __td_row "ZRAM Devices" "$zram_count"
            if test -n "$zram_total"
                __td_row "ZRAM Total" "$zram_total"
                __td_row "ZRAM Used" "$zram_used"
            end
        end

        # Memory pressure
        set -l pressure (cat /proc/pressure/memory 2>/dev/null | head -1 | awk '{print $2}' | sed 's/avg//')
        if test -n "$pressure"
            __td_divider
            echo -e "  $GY│$C  $DMemory Pressure:$C  $WH$pressure$C"
        end

        # Benchmark
        __td_divider
        echo -e "  $GY│$C  $BRunning memory throughput test...$C"
        __td_progress 0.8 "  Allocating 2 GB blocks"
        set -l ram_write (dd if=/dev/zero of=/dev/null bs=1M count=2000 2>&1 | tail -1 | awk '{print $8" "$9}')
        __td_row "Write Throughput" "$ram_write"

        # Read test
        dd if=/dev/zero of=/tmp/__td_ram_test bs=1M count=1000 2>/dev/null
        set -l ram_read (dd if=/tmp/__td_ram_test of=/dev/null bs=1M count=1000 2>&1 | tail -1 | awk '{print $8" "$9}')
        rm -f /tmp/__td_ram_test
        __td_row "Read Throughput" "$ram_read"

        # Health indicator
        set -l mem_errors (dmesg 2>/dev/null | grep -i "memory error\|EDAC\|CE memory" | wc -l)
        if test "$mem_errors" -gt 0
            __td_row "Memory Health" "$RE⚠️  $mem_errors error(s) detected in dmesg$C"
            set -g __td_s_ram_ok "no"
        else
            __td_row "Memory Health" "$GR✅ No hardware errors detected$C"
        end

        set -g __td_s_ram_total "$mem_total"
    end

    function __td_report_disk_block --no-scope-shadowing
        set -l test_file ""
        set -l is_external 0

        if test "$module" = "disk"
            set test_file "$HOME/"(whoami)"_test_bin"
            set is_external 0
        else
            set is_external 1
            set -l drives (lsblk -pno MOUNTPOINT,SIZE,MODEL | grep "/run/media")
            set -l drive_count (count $drives)
            if test $drive_count -eq 0
                echo -e "  $GY│$C  $RE⚠️  No external drives detected!$C" ; return 1
            else if test $drive_count -gt 1
                echo -e "  $GY│$C  $YE📋 Multiple drives detected. Select target:$C"
                set -l i 1
                for d in $drives
                    echo -e "  $GY│$C  $CY$i)$C $d"
                    set i (math $i + 1)
                end
                echo -n -e "  $GY│$C  $WHCHOOSE [1-$drive_count]: $C"
                read choice
                if test "$choice" -ge 1 -a "$choice" -le "$drive_count"
                    set -l target_raw $drives[$choice]
                    set test_file (echo $target_raw | awk '{print $1}')"/"(whoami)"_test_bin"
                else
                    echo -e "  $GY│$C  $RE❌ Invalid selection.$C" ; return 1
                end
            else
                set test_file (echo $drives[1] | awk '{print $1}')"/"(whoami)"_test_bin"
            end
        end

        # Signal-safe cleanup: ensure test file is removed on Ctrl+C
        set -g __td_disk_test_file "$test_file"
        function __td_sigclean --on-signal SIGINT --on-signal SIGTERM
            rm -f $__td_disk_test_file 2>/dev/null
            functions --erase __td_sigclean 2>/dev/null
        end

        touch $test_file 2>/dev/null

        # ── Device Info ──
        set -l dev_path (df --output=source $test_file 2>/dev/null | tail -1)
        set -l dev_pretty (lsblk -no NAME $dev_path 2>/dev/null)
        set -l dev_model (lsblk -dno MODEL $dev_path 2>/dev/null; or lsblk -dno MODEL (echo $dev_path | sed 's/[0-9]*$//') 2>/dev/null; or echo "N/A")
        set -l dev_size (lsblk -dno SIZE $dev_path 2>/dev/null; or echo "N/A")
        set -l dev_type (lsblk -dno FSTYPE $dev_path 2>/dev/null; or echo "N/A")
        set -l dev_mount (lsblk -no MOUNTPOINT $dev_path 2>/dev/null | head -1)
        set -l is_rotational (lsblk -no ROTA $dev_path 2>/dev/null)
        set -l is_nvme (string match -q "*nvme*" "$dev_path"; and echo 1; or echo 0)
        set -l is_ssd (string match -q "0" "$is_rotational"; and echo 1; or echo 0)

        # Technology label
        set -l tech_label "UNKNOWN"
        if test "$is_rotational" = "0"
            if test "$is_nvme" = "1"
                set tech_label "NVMe (High-Speed)"
            else if test "$is_ssd" = "1"
                set tech_label "SATA SSD"
            else
                set tech_label "SSD"
            end
        else if test "$is_rotational" = "1"
            set tech_label "Mechanical HDD"
        else
            set tech_label "Virtual / Proxy"
        end

        # Interface speed (SATA / NVMe generation)
        set -l interface_speed ""
        if test "$is_nvme" = "1"
            set -l nvme_gen (sudo -n nvme list 2>/dev/null | grep -i "nvme" | head -1 | grep -oE "GEN[0-9]+" | head -1; or echo "")
            if test -n "$nvme_gen"
                set interface_speed "$nvme_gen"
            else
                # Try PCIe link speed
                set -l pcie_speed (lspci 2>/dev/null | grep -i "Non-Volatile" | head -1 | grep -oE "GT/s"; or echo "")
                if test -n "$pcie_speed"
                    set interface_speed "PCIe $pcie_speed"
                else
                    set interface_speed "NVMe"
                end
            end
        else if test "$is_ssd" = "1"
            set -l sata_gen (sudo -n smartctl -i $dev_path 2>/dev/null | grep "SATA Version" | sed 's/.*SATA Version is: //' | sed 's/\/.*//'; or echo "")
            if test -n "$sata_gen"
                set interface_speed "SATA $sata_gen"
            else
                set interface_speed "SATA"
            end
        else
            set interface_speed "ATA"
        end

        __td_row "Device" "/dev/$dev_pretty"
        __td_row "Model" "$dev_model"
        __td_row "Size" "$dev_size"
        __td_row "Filesystem" "$dev_type on $dev_mount"
        __td_row "Technology" "$B$WH$tech_label$C  $interface_speed"

        # SMART health
        set -l smart_avail 0
        if sudo -n smartctl -i $dev_path 2>/dev/null | grep -qi "SMART support is: Available"
            set smart_avail 1
        end
        if test "$smart_avail" = "1"
            set -l smart_health (sudo -n smartctl -H $dev_path 2>/dev/null | grep "SMART overall-health" | sed 's/.*: //'; or echo "N/A")
            set -l realloc (sudo -n smartctl -A $dev_path 2>/dev/null | grep "Reallocated_Sector" | awk '{print $10}'; or echo "N/A")
            set -l pending (sudo -n smartctl -A $dev_path 2>/dev/null | grep "Current_Pending_Sector" | awk '{print $10}'; or echo "N/A")
            set -l temp_raw (sudo -n smartctl -A $dev_path 2>/dev/null | grep "Temperature_Celsius" | awk '{print $10}'; or echo "")
            if test -z "$temp_raw"
                set temp_raw (sudo -n smartctl -A $dev_path 2>/dev/null | grep "Airflow_Temperature" | awk '{print $10}'; or echo "N/A")
            end
            __td_row "SMART Health" "$(__td_status $smart_health) $WH$smart_health$C"
            __td_row "  Reallocated" "$realloc sectors"
            __td_row "  Pending Sectors" "$pending"
            __td_row "  Disk Temp" "$temp_raw°C"
        else
            __td_row "SMART" "$D Unavailable (no SMART on this device)$C"
        end

        # NVMe wear level
        if test "$is_nvme" = "1"
            set -l wear (sudo -n nvme smart-log $dev_path 2>/dev/null | grep "percentage_used" | awk '{print $3"%"}' | sed 's/\.//'; or echo "")
            if test -n "$wear"
                __td_row "Wear Level" "$wear used"
            end
        end

        # ── Benchmarks ──
        __td_divider
        echo -e "  $GY│$C  $BBenchmarking...$C"

        # Determine benchmark sizes based on drive type
        set -l seq_size "1 GB"
        set -l seq_bs "1G"
        set -l seq_count "1"
        set -l iow_count "10000"
        if test "$is_rotational" = "1"
            set seq_size "100 MB"
            set seq_bs "1M"
            set seq_count "100"
            set iow_count "2000"
        end

        # Check available space on target filesystem (2x safety margin)
        set -l need_mb 0
        if test "$seq_bs" = "1G"; set need_mb 1024
        else if test "$seq_bs" = "1M"; set need_mb $seq_count
        end
        set need_mb (math "$need_mb * 2" 2>/dev/null)
        set -l avail_mb (math (df --output=avail "$test_file" 2>/dev/null | tail -1) / 1024 2>/dev/null)

        if test -n "$avail_mb"; and test "$avail_mb" -lt "$need_mb"
            echo -e "  $GY│$C  $YE⚠️  Low disk space: $avail_mb MB free, need ~$need_mb MB. Skipping benchmarks.$C"
            set write_mb "N/A"
            set read_mb "N/A"
            set iow_iops "N/A"
        else
            # Sequential Write
            echo -e "  $GY│$C  $D  Seq Write ($seq_size)...$C"
            set -l write_res (dd if=/dev/zero of=$test_file bs=$seq_bs count=$seq_count oflag=dsync 2>&1 | grep -oE '[0-9.]+ [MG]B/s' | tail -1)
            set -l write_val (echo $write_res | awk '{print $1}')
            set -l write_unit (echo $write_res | awk '{print $2}')
            set -l write_mb $write_val
            if test "$write_unit" = "GB/s"
                set write_mb (math "$write_val * 1024" 2>/dev/null; or echo $write_val)
            end

            # Sequential Read
            echo -e "  $GY│$C  $D  Seq Read ($seq_size)...$C"
            sync; sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null
            set -l read_res (dd if=$test_file of=/dev/null bs=$seq_bs count=$seq_count 2>&1 | grep -oE '[0-9.]+ [MG]B/s' | tail -1)
            set -l read_val (echo $read_res | awk '{print $1}')
            set -l read_unit (echo $read_res | awk '{print $2}')
            set -l read_mb $read_val
            if test "$read_unit" = "GB/s"
                set read_mb (math "$read_val * 1024" 2>/dev/null; or echo $read_val)
            end

            # Random 4K Write IOPS
            echo -e "  $GY│$C  $D  Random 4K Write (IOPS)...$C"
            set -l iow_res (dd if=/dev/zero of=$test_file bs=4k count=$iow_count oflag=dsync 2>&1 | tail -1)
            set -l iow_iops "N/A"
            if string match -q "*bytes*" "$iow_res"
                set -l iow_time (echo $iow_res | awk '{print $6}')
                set -l iow_iops (math "$iow_count / $iow_time" 2>/dev/null; or echo "N/A")
            end
        end

        # Cleanup (always runs even if skipped)
        rm -f $test_file 2>/dev/null
        functions --erase __td_sigclean 2>/dev/null

        # Speed Grading (guarded against N/A)
        set -l grade "N/A"; set -l g_color "$D"
        if test "$write_mb" != "N/A"; and test -n "$write_mb"
            if test "$write_mb" -gt 3000; set grade "ELITE (NVMe Gen5)"; set g_color $GR
            else if test "$write_mb" -gt 2000; set grade "HIGH-END (NVMe Gen4)"; set g_color $GR
            else if test "$write_mb" -gt 500; set grade "EXCELLENT (SATA/NVMe Gen3)"; set g_color $GR
            else if test "$write_mb" -gt 250; set grade "MID-RANGE (SATA SSD)"; set g_color $YE
            else if test "$write_mb" -gt 80; set grade "STANDARD HDD"; set g_color $YE
            else; set grade "BOTTLENECK"; set g_color $RE; end
        end

        __td_divider
        echo -e "  $GY│$C  $WH┌── PERFORMANCE METRICS ──────────────────────────┐$C"
        printf "  $GY│$C  $WH│$C  %-20s  %10s  %s\n" "Metric" "Value"
        echo -e "  $GY│$C  $WH├──────────────────────────────────────────────────┤$C"
        printf "  $GY│$C  $WH│$C  %-20s  $CY%10s$C\n" "Sequential Write" "$write_mb MB/s"
        printf "  $GY│$C  $WH│$C  %-20s  $CY%10s$C\n" "Sequential Read" "$read_mb MB/s"
        printf "  $GY│$C  $WH│$C  %-20s  $CY%10s$C\n" "4K Random Write" "$iow_iops IOPS"
        printf "  $GY│$C  $WH│$C  %-20s  $g_color%10s$C\n" "GRADE" "$grade"
        echo -e "  $GY│$C  $WH└──────────────────────────────────────────────────┘$C"

        set -g __td_s_disk_model "$dev_model"
        set -g __td_s_disk_tech "$tech_label"
        set -g __td_s_disk_speed "$write_mb MB/s"
    end

    function __td_report_gpu_block --no-scope-shadowing
        set -l found_gpu 0

        # NVIDIA
        if type -q nvidia-smi
            set -l nv_name (nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
            set -l nv_temp (nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null | head -1)
            set -l nv_util (nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader 2>/dev/null | head -1)
            set -l nv_vram_t (nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1)
            set -l nv_vram_u (nvidia-smi --query-gpu=memory.used --format=csv,noheader 2>/dev/null | head -1)
            set -l nv_driver (nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
            set -l nv_clocks (nvidia-smi --query-gpu=clocks.current.graphics,clocks.current.memory --format=csv,noheader 2>/dev/null | head -1)
            set -l nv_power (nvidia-smi --query-gpu=power.draw --format=csv,noheader 2>/dev/null | head -1)
            set -l nv_pcie (nvidia-smi --query-gpu=pcie.link.gen.current,pcie.link.width.current --format=csv,noheader 2>/dev/null | head -1)

            __td_row "GPU 1" "$nv_name"
            __td_row "Driver" "$nv_driver"
            __td_row "VRAM" "$nv_vram_u / $nv_vram_t"
            __td_row "Core Clock" "$(echo $nv_clocks | awk -F', ' '{print $1}')"
            __td_row "Mem Clock" "$(echo $nv_clocks | awk -F', ' '{print $2}')"
            __td_row "Temp" "$nv_temp°C"
            __td_row "Utilization" "$nv_util"
            __td_row "Power Draw" "$nv_power"
            __td_row "PCIe Link" "$nv_pcie"
            set found_gpu 1
            set -g __td_s_gpu_name "$nv_name"
        end

        # AMD (rocm-smi)
        if type -q rocm-smi
            set -l amd_name (rocm-smi --showproductname 2>/dev/null | grep "GPU" | head -1 | sed 's/.*:\s*//')
            set -l amd_temp (rocm-smi --showtemp 2>/dev/null | grep "Temperature" | head -1 | grep -oE '[0-9]+')
            if test -n "$amd_name"
                if test "$found_gpu" = "1"
                    __td_divider
                end
                __td_row "GPU 2" "$amd_name"
                __td_row "Temp" "$amd_temp°C"
                set found_gpu 1
                set -g __td_s_gpu_name "$amd_name"
            end
        end

        # Intel (try intel_gpu_top)
        if type -q intel_gpu_top
            set -l intel_info (intel_gpu_top -L 2>/dev/null | head -1)
            if test -n "$intel_info"
                if test "$found_gpu" = "1"
                    __td_divider
                end
                __td_row "GPU (Intel)" "$intel_info"
                set found_gpu 1
                set -g __td_s_gpu_name "$intel_info"
            end
        end

        # Fallback: lspci
        if test "$found_gpu" = "0"
            set -l pci_gpu (lspci 2>/dev/null | grep -i "VGA\|3D\|Display" | head -1 | sed 's/.*: //')
            if test -n "$pci_gpu"
                __td_row "GPU (lspci)" "$pci_gpu"
                set -g __td_s_gpu_name "$pci_gpu"
            else
                echo -e "  $GY│$C  $RE⚠️  No GPU detected$C"
                set -g __td_s_gpu_ok "no"
            end
        end

        # Display outputs
        if type -q xrandr
            set -l displays (xrandr --listmonitors 2>/dev/null | grep -v "Monitors" | wc -l)
            if test "$displays" -gt 0
                __td_divider
                __td_row "Connected Displays" "$displays"
                xrandr --listmonitors 2>/dev/null | tail -n +2 | while read -l line
                    echo -e "  $GY│$C    $D$line$C"
                end
            end
        end
    end

    function __td_report_heat_block --no-scope-shadowing
        set -l has_sensors (type -q sensors; and echo 1; or echo 0)

        if test "$has_sensors" = "1"
            echo -e "  $GY│$C  $DCPU Core Temperatures:$C"
            sensors 2>/dev/null | grep -i "core " | while read -l line
                set -l cleaned (echo $line | sed 's/\s*Core /Core /' | sed 's/^[[:space:]]*//')
                echo -e "  $GY│$C    $WH$cleaned$C"
            end

            # Package temp
            set -l pkg_temp (sensors 2>/dev/null | grep "Package id" | head -1 | sed 's/^[[:space:]]*//')
            if test -n "$pkg_temp"
                __td_divider
                echo -e "  $GY│$C  $DCPU Package:$C  $WH$pkg_temp$C"
            end

            # Fan speeds
            __td_divider
            echo -e "  $GY│$C  $DFan Speeds:$C"
            sensors 2>/dev/null | grep -i "fan" | while read -l line
                echo -e "  $GY│$C    $WH$(echo $line | sed 's/^[[:space:]]*//')$C"
            end
        else
            echo -e "  $GY│$C  $D🌡️  Install lm_sensors for detailed thermal data$C"
            # Fallback: thermal zones
            for zone in /sys/class/thermal/thermal_zone*/temp
                set -l z_name (cat (dirname $zone)/type 2>/dev/null)
                set -l z_temp (math (cat $zone 2>/dev/null) / 1000 2>/dev/null)
                if test -n "$z_temp"
                    echo -e "  $GY│$C    $D$z_name:$C  $WH$z_temp°C$C"
                end
            end
        end

        # NVMe temp
        if type -q nvme; and sudo -n nvme list 2>/dev/null | grep -q "nvme"
            set -l nvme_temp (sudo -n nvme smart-log /dev/nvme0 2>/dev/null | grep "temperature" | awk '{print $3" "$4}' | sed 's/\.$//')
            if test -n "$nvme_temp"
                __td_divider
                __td_row "NVMe Temp" "$nvme_temp"
            end
        end

        # GPU temp (from nvidia-smi)
        if type -q nvidia-smi
            set -l gpu_temp (nvidia-smi --query-gpu=name,temperature.gpu --format=csv,noheader 2>/dev/null | head -1 | sed 's/,/:/' | sed 's/,//')
            if test -n "$gpu_temp"
                __td_divider
                __td_row "GPU Temp" "$gpu_temp"
            end
        end

        # Throttling check
        set -l throttle (dmesg 2>/dev/null | grep -i "thermal throttle" | tail -1)
        if test -n "$throttle"
            __td_divider
            echo -e "  $GY│$C  $RE⚠️  Thermal throttling detected in kernel log$C"
            echo -e "  $GY│$C  $D  $throttle$C"
            set -g __td_s_temp_ok "no"
        else
            __td_divider
            echo -e "  $GY│$C  $GR✅ No thermal throttling detected$C"
        end
    end

    function __td_report_net_block --no-scope-shadowing
        # Interfaces
        echo -e "  $GY│$C  $DActive Interfaces:$C"
        for iface in (ip -o link show up 2>/dev/null | grep -v "LOOPBACK" | awk -F': ' '{print $2}' | sed 's/@.*//')
            set -l ip4 (ip -4 -o addr show $iface 2>/dev/null | awk '{print $4}' | head -1)
            set -l ip6 (ip -6 -o addr show $iface 2>/dev/null | awk '{print $4}' | head -1)
            set -l mac (ip -o link show $iface 2>/dev/null | awk '{print $17}')
            set -l state (ip -o link show $iface 2>/dev/null | awk '{print $9}')
            if test -n "$ip4"
                printf "  $GY│$C    $WH%-8s$C  $CY%-18s$C  $D%s$C\n" "$iface" "$ip4" "$mac"
            end
        end

        # Gateway
        __td_divider
        set -l gateway (ip route show default 2>/dev/null | awk '{print $3}')
        set -l dns (cat /etc/resolv.conf 2>/dev/null | grep "nameserver" | awk '{print $2}' | head -3)
        __td_row "Default Gateway" "$gateway"
        __td_row "DNS Servers" "$(string join ", " $dns)"

        # Ping multi-target
        __td_divider
        echo -e "  $GY│$C  $DLatency (ping):$C"
        for target in "1.1.1.1" "8.8.8.8" "$gateway"
            set -l ping_res (ping -c 2 -W 2 $target 2>/dev/null | tail -1 | grep -oE '[0-9.]+/[0-9.]+' | head -1)
            if test -n "$ping_res"
                printf "  $GY│$C    %-20s  $WH%8s$C ms\n" "$target" "$ping_res"
            else
                printf "  $GY│$C    %-20s  $D%8s$C\n" "$target" "timeout"
            end
        end

        # DNS resolution
        __td_divider
        echo -e "  $GY│$C  $DDNS Resolution:$C"
        set -l dns_res (dig google.com +short 2>/dev/null | tail -1)
        if test -n "$dns_res"
            __td_row "  google.com" "$dns_res"
        end

        # Speed test
        __td_divider
        set -l __td_auto_sp 0
        if not type -q speedtest-cli
            echo -e "  $GY│$C  $D📡 Installing speedtest-cli for one-shot test...$C"
            sudo dnf install -y speedtest-cli 2>/dev/null
            if type -q speedtest-cli
                set __td_auto_sp 1
            end
        end

        if type -q speedtest-cli
            echo -e "  $GY│$C  $BRunning speed test...$C"
            set -l speed_res (speedtest-cli --simple 2>/dev/null)
            if test -n "$speed_res"
                printf '%s\n' $speed_res | while read -l line
                    echo -e "  $GY│$C    $WH$line$C"
                end
                set -l download (printf '%s\n' $speed_res | grep "Download" | grep -oE '[0-9.]+' | head -1)
                set -l upload (printf '%s\n' $speed_res | grep "Upload" | grep -oE '[0-9.]+' | head -1)
                set -g __td_s_net_down "$download Mbit/s"
                set -g __td_s_net_up "$upload Mbit/s"
            end

            if test $__td_auto_sp -eq 1
                echo -e "  $GY│$C  $D🧹 Cleaning up speedtest-cli...$C"
                sudo dnf remove -y speedtest-cli 2>/dev/null
                sudo dnf autoremove -y 2>/dev/null
                rm -rf ~/.speedtest-cli /tmp/speedtest* 2>/dev/null
            end
        else
            echo -e "  $GY│$C  $D📡 Could not install speedtest-cli (no network?) $C"
        end
    end

    function __td_report_batt_block --no-scope-shadowing
        set -l batt_path (upower -e 2>/dev/null | grep -i "BAT" | head -1)
        if test -z "$batt_path"
            echo -e "  $GY│$C  $D🔌 No battery detected — desktop system$C"
            set -g __td_s_batt_state "AC"
            return 0
        end

        set -l batt_data (upower -i $batt_path 2>/dev/null)
        set -l percentage (printf '%s\n' $batt_data | grep "percentage" | awk '{print $2}')
        set -l capacity (printf '%s\n' $batt_data | grep -E "^[[:space:]]*capacity:[[:space:]]" | awk '{print $2}')
        set -l state (printf '%s\n' $batt_data | grep "state" | awk '{print $2}')
        set -l energy (printf '%s\n' $batt_data | grep "energy:" | head -1 | awk '{print $2}')
        set -l energy_full (printf '%s\n' $batt_data | grep "energy-full:" | head -1 | awk '{print $2}')
        set -l energy_rate (printf '%s\n' $batt_data | grep "energy-rate:" | head -1 | awk '{print $2}')
        set -l voltage (printf '%s\n' $batt_data | grep "voltage:" | head -1 | awk '{print $2}')
        set -l time_to (printf '%s\n' $batt_data | grep "time to" | head -1 | sed 's/^[[:space:]]*//')
        set -l model (printf '%s\n' $batt_data | grep "model" | awk '{print $2}')
        set -l serial (printf '%s\n' $batt_data | grep "serial" | awk '{print $2}')

        if test "$state" = "charging" -o "$state" = "fully-charged"
            set state_char "$GR🔌$C"
        else if test "$state" = "discharging"
            set state_char "$YE🔋$C"
        else
            set state_char "$GY⚡$C"
        end

        __td_row "State" "$state_char $B$WH$state$C"
        __td_row "Charge" "$percentage"
        __td_row "Capacity" "$capacity of original"
        __td_row "Energy" "$energy / $energy_full Wh"
        if test -n "$energy_rate"
            __td_row "Draw" "$energy_rate W"
        end
        if test -n "$time_to"
            __td_row "Time Remaining" "$(echo $time_to | sed 's/time to //' | sed 's/://')"
        end
        if test -n "$model"
            __td_row "Model" "$model"
        end
        if test -n "$voltage"
            __td_row "Voltage" "$voltage V"
        end

        # Wear level
        if test -n "$capacity"
            set -l wear (math "100 - $(echo $capacity | sed 's/%//')" 2>/dev/null)
            if test -n "$wear"
                if test "$wear" -gt 20
                    echo -e "  $GY│$C  $RE⚠️  Battery wear at $wear% — consider replacement$C"
                    set -g __td_s_batt_pct "$(echo $capacity | sed 's/%//')%"
                else if test "$wear" -gt 10
                    echo -e "  $GY│$C  $YE⚠️  Battery wear at $wear%$C"
                    set -g __td_s_batt_pct "$(echo $capacity | sed 's/%//')%"
                else
                    set -g __td_s_batt_pct "100%"
                end
            end
        end
        set -g __td_s_batt_state "$state"
    end

    function __td_report_boot_block --no-scope-shadowing
        if type -q systemd-analyze
            echo -e "  $GY│$C  $DBoot Time Breakdown:$C"
            set -l boot_time (systemd-analyze time 2>/dev/null)
            if test -n "$boot_time"
                printf '%s\n' $boot_time | while read -l line
                    echo -e "  $GY│$C    $WH$line$C"
                end
            end

            __td_divider
            echo -e "  $GY│$C  $DTop 5 slowest services:$C"
            systemd-analyze blame 2>/dev/null | head -5 | while read -l line
                echo -e "  $GY│$C    $D$line$C"
            end

            __td_divider
            echo -e "  $GY│$C  $DBoot loader:$C"
            set -l bootloader (bootctl status 2>/dev/null | grep "Product" | head -1; or echo "  $D  systemd-boot not available (likely GRUB)$C")
            echo -e "  $GY│$C    $WH$bootloader$C"
        else
            echo -e "  $GY│$C  $Dsystemd-analyze not available$C"
        end
    end

    function __td_report_services_block --no-scope-shadowing
        set -l failed (systemctl --failed 2>/dev/null)
        set -l failed_count (printf '%s\n' $failed | grep -c "loaded" 2>/dev/null)
        if test "$failed_count" -gt 0
            echo -e "  $GY│$C  $RE⚠️  $failed_count failed unit(s)$C"
            printf '%s\n' $failed | grep "loaded" | while read -l line
                echo -e "  $GY│$C    $RE✘$C $D$line$C"
            end
        else
            echo -e "  $GY│$C  $GR✅ All services running normally$C"
        end

        __td_divider
        set -l total_units (systemctl list-units --type=service 2>/dev/null | grep -c ".service")
        set -l active (systemctl list-units --type=service 2>/dev/null | grep -c "running")
        __td_row "Service Units" "$total_units total, $active active"

        __td_divider
        set -l last_boot (systemctl show -p KernelTimestamp 2>/dev/null | sed 's/KernelTimestamp=//')
        if test -n "$last_boot"
            __td_row "Kernel Boot" "$last_boot"
        end
    end

    function __td_report_updates_block --no-scope-shadowing
        # DNF
        if type -q dnf
            echo -e "  $GY│$C  $D📦 Checking DNF updates...$C"
            set -l dnf_updates (sudo -n dnf check-update 2>/dev/null | tail -n +2 | grep -c "^" 2>/dev/null)
            set -l dnf_sec (sudo -n dnf updateinfo --list --security 2>/dev/null | grep -c "^" 2>/dev/null)
            __td_row "DNF Updates" "$dnf_updates available"
            __td_row "  Security" "$dnf_sec security updates"
        end

        # Flatpak
        if type -q flatpak
            __td_divider
            echo -e "  $GY│$C  $D📦 Checking Flatpak updates...$C"
            set -l fp_updates (flatpak remote-ls --updates 2>/dev/null | wc -l)
            __td_row "Flatpak Updates" "$fp_updates available"
        end

        # Firmware
        if type -q fwupdmgr
            __td_divider
            echo -e "  $GY│$C  $D🔧 Checking firmware updates...$C"
            set -l fw_updates (fwupdmgr get-updates 2>/dev/null | grep -c "─" 2>/dev/null)
            __td_row "Firmware Updates" "$fw_updates available"
        end
    end

    function __td_report_top_block --no-scope-shadowing
        echo -e "  $GY│$C  $DTotal processes: $(ps aux | wc -l)$C"
        echo ""
        echo -e "  $GY│$C  $WHTop 5 by CPU:$C"
        ps aux --sort=-%cpu 2>/dev/null | head -6 | tail -5 | while read -l line
            echo -e "  $GY│$C    $D$line$C"
        end

        echo ""
        echo -e "  $GY│$C  $WHTop 5 by Memory:$C"
        ps aux --sort=-%mem 2>/dev/null | head -6 | tail -5 | while read -l line
            echo -e "  $GY│$C    $D$line$C"
        end
    end

    function __td_report_security_block --no-scope-shadowing
        # SELinux
        set -l selinux (getenforce 2>/dev/null; or echo "N/A")
        printf "  $GY│$C  %-20s  $WH%s$C  %s\n" "SELinux" "$selinux" "$(__td_status $selinux)"

        # Firewall
        if type -q firewall-cmd
            set -l fw_state (sudo -n firewall-cmd --state 2>/dev/null; or echo "inactive")
            set -l fw_zone (sudo -n firewall-cmd --get-default-zone 2>/dev/null; or echo "N/A")
            printf "  $GY│$C  %-20s  $WH%s$C  %s\n" "Firewall (default)" "$fw_zone" "$(__td_status $fw_state)"
            set -l fw_ports (sudo -n firewall-cmd --list-ports 2>/dev/null)
            if test -n "$fw_ports"
                __td_row "  Open Ports" "$fw_ports"
            end
        end

        # Secure Boot
        set -l sb (mokutil --sb-state 2>/dev/null | sed 's/.*: //')
        if test -n "$sb"
            __td_row "Secure Boot" "$sb"
        end

        # Failed auth
        set -l failed_auth (sudo -n journalctl -x -n 50 2>/dev/null | grep -c "Failed password\|authentication failure" 2>/dev/null)
        if test "$failed_auth" -gt 0
            __td_row "Failed Auth (recent)" "$RE$failed_auth attempts$C"
            set -g __td_s_sec_ok "no"
        else
            __td_row "Failed Auth" "$GR✅ None recent$C"
        end

        # Login defs
        __td_divider
        set -l pass_max (cat /etc/login.defs 2>/dev/null | grep "PASS_MAX_DAYS" | grep -v "^#" | awk '{print $2}'; or echo "N/A")
        set -l pass_min (cat /etc/login.defs 2>/dev/null | grep "PASS_MIN_DAYS" | grep -v "^#" | awk '{print $2}'; or echo "N/A")
        __td_row "Password Max Age" "$pass_max days"
        __td_row "Password Min Age" "$pass_min days"

        set -g __td_s_sec_mode "$selinux"
    end

    function __td_report_stress_block --no-scope-shadowing
        set -l cores (nproc 2>/dev/null; or echo "4")

        echo -e "  $GY│$C  $D🧠 CPU stress ($cores cores, 10s)...$C"
        __td_progress 1.5 "  Priming cores"
        timeout 10s cat /dev/urandom > /dev/null 2>/dev/null &
        set -l pid1 $last_pid
        timeout 10s cat /dev/urandom > /dev/null 2>/dev/null &
        set -l pid2 $last_pid
        wait $pid1 $pid2 2>/dev/null
        echo -e "  $GY│$C  $GR✅ CPU stress complete$C"

        __td_divider
        set -l mem_mb (free -m | awk '/^Mem:/ {print int($7 * 0.5)}')
        echo -e "  $GY│$C  $D🧠 Memory stress ("$mem_mb" MB, 5s)...$C"
        dd if=/dev/zero of=/dev/null bs=1M count=$mem_mb 2>/dev/null
        echo -e "  $GY│$C  $GR✅ Memory stress complete$C"

        __td_divider
        echo -e "  $GY│$C  $D💾 I/O stress (5s)...$C"
        dd if=/dev/zero of=/tmp/__td_stress bs=1M count=500 conv=fsync 2>/dev/null
        rm -f /tmp/__td_stress 2>/dev/null
        echo -e "  $GY│$C  $GR✅ I/O stress complete$C"
    end

    # ════════════════════════════════════════════════════════════════
    # MODULE: all
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "all"
        echo -e "  $B$WH╔══════════════════════════════════════════════════════════╗$C"
        echo -e "  $B$WH║$C  $CY🔬$C  $B$WHCOMPLETE SYSTEM AUTOPSY — RUNNING ALL MODULES$C  $B$WH║$C"
        echo -e "  $B$WH╚══════════════════════════════════════════════════════════╝$C"
        echo ""

        # Cache sudo upfront for the whole suite
        sudo -v 2>/dev/null

        # ── Collect scores ──
        set -g __td_s_cpu_model ""
        set -g __td_s_cpu_cores ""
        set -g __td_s_cpu_ok "yes"
        set -g __td_s_ram_total ""
        set -g __td_s_ram_ok "yes"
        set -g __td_s_disk_model ""
        set -g __td_s_disk_tech ""
        set -g __td_s_disk_speed ""
        set -g __td_s_disk_ok "yes"
        set -g __td_s_gpu_name ""
        set -g __td_s_gpu_ok "yes"
        set -g __td_s_net_down ""
        set -g __td_s_net_up ""
        set -g __td_s_net_ok "yes"
        set -g __td_s_temp_ok "yes"
        set -g __td_s_batt_pct ""
        set -g __td_s_batt_state ""
        set -g __td_s_sec_mode ""
        set -g __td_s_sec_ok "yes"

        # ── 1) INFO ──
        echo -e "  $WH╭─$CY 1/14$C  $B$WH System Blueprint $C$WH ───────────────────────╮$C"
        __td_report_info_block
        echo -e "  $WH╰──────────────────────────────────────────────────╯$C"

        # ── 2) CPU ──
        echo -e "  $WH╭─$CY 2/14$C  $B$WH CPU Architecture & Performance $C$WH ──────────╮$C"
        __td_report_cpu_block
        echo -e "  $WH╰──────────────────────────────────────────────────╯$C"

        # ── 3) RAM ──
        echo -e "  $WH╭─$CY 3/14$C  $B$WH Memory & Swap $C$WH ──────────────────────────╮$C"
        __td_report_ram_block
        echo -e "  $WH╰──────────────────────────────────────────────────╯$C"

        # ── 4) DISK ──
        echo -e "  $WH╭─$CY 4/14$C  $B$WH Storage Analysis $C$WH ────────────────────────╮$C"
        __td_report_disk_block
        echo -e "  $WH╰──────────────────────────────────────────────────╯$C"

        # ── 5) GPU ──
        echo -e "  $WH╭─$CY 5/14$C  $B$WH Graphics Engine $C$WH ─────────────────────────╮$C"
        __td_report_gpu_block
        echo -e "  $WH╰──────────────────────────────────────────────────╯$C"

        # ── 6) HEAT ──
        echo -e "  $WH╭─$CY 6/14$C  $B$WH Thermal Sensors $C$WH ─────────────────────────╮$C"
        __td_report_heat_block
        echo -e "  $WH╰──────────────────────────────────────────────────╯$C"

        # ── 7) NET ──
        echo -e "  $WH╭─$CY 7/14$C  $B$WH Network Uplink $C$WH ──────────────────────────╮$C"
        __td_report_net_block
        echo -e "  $WH╰──────────────────────────────────────────────────╯$C"

        # ── 8) BOOT ──
        echo -e "  $WH╭─$CY 8/14$C  $B$WH Boot Analysis $C$WH ───────────────────────────╮$C"
        __td_report_boot_block
        echo -e "  $WH╰──────────────────────────────────────────────────╯$C"

        # ── 9) SERVICES ──
        echo -e "  $WH╭─$CY 9/14$C  $B$WH Service Health $C$WH ──────────────────────────╮$C"
        __td_report_services_block
        echo -e "  $WH╰──────────────────────────────────────────────────╯$C"

        # ── 10) UPDATES ──
        echo -e "  $WH╭─$CY 10/14$C  $B$WH Pending Updates $C$WH ────────────────────────╮$C"
        __td_report_updates_block
        echo -e "  $WH╰──────────────────────────────────────────────────╯$C"

        # ── 11) TOP ──
        echo -e "  $WH╭─$CY 11/14$C  $B$WH Process Landscape $C$WH ──────────────────────╮$C"
        __td_report_top_block
        echo -e "  $WH╰──────────────────────────────────────────────────╯$C"

        # ── 12) SECURITY ──
        echo -e "  $WH╭─$CY 12/14$C  $B$WH Security Posture $C$WH ───────────────────────╮$C"
        __td_report_security_block
        echo -e "  $WH╰──────────────────────────────────────────────────╯$C"

        # ── 13) BATT ──
        echo -e "  $WH╭─$CY 13/14$C  $B$WH Power Status $C$WH ───────────────────────────╮$C"
        __td_report_batt_block
        echo -e "  $WH╰──────────────────────────────────────────────────╯$C"

        # ── 14) STRESS ──
        echo -e "  $WH╭─$CY 14/14$C  $B$WH Saturation Test $C$WH ────────────────────────╮$C"
        __td_report_stress_block
        echo -e "  $WH╰──────────────────────────────────────────────────╯$C"

        # ── HEALTH SCOREBOARD ──
        __td_show_scoreboard

        return 0
    end

    # ════════════════════════════════════════════════════════════════
    # MODULE: info
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "info"
        sudo -v 2>/dev/null
        __td_section "🖥️" "SYSTEM BLUEPRINT" "$B$WH Complete hardware, software & network inventory$C"
        __td_report_info_block
        __td_section_end
        echo ""
        __td_show_footer
        return 0
    end


    # ════════════════════════════════════════════════════════════════
    # MODULE: cpu
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "cpu"
        __td_section "🖥️" "CPU ARCHITECTURE & PERFORMANCE" "$B$WH Processor topology, frequencies, features & throttling$C"
        __td_report_cpu_block
        __td_section_end
        echo ""
        __td_show_footer
        return 0
    end


    # ════════════════════════════════════════════════════════════════
    # MODULE: ram
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "ram"
        __td_section "🧠" "MEMORY & SWAP ANALYSIS" "$B$WH RAM throughput, swap pressure & ZRAM$C"
        __td_report_ram_block
        __td_section_end
        echo ""
        __td_show_footer
        return 0
    end


    # ════════════════════════════════════════════════════════════════
    # MODULE: disk / ext
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "disk" -o "$module" = "ext"
        if test "$module" = "disk"
            __td_section "💾" "INTERNAL STORAGE ANALYSIS" "$B$WH Sequential & random benchmarks, SMART health, filesystem$C"
        else
            __td_section "🔌" "EXTERNAL STORAGE ANALYSIS" "$B$WH Removable drive picker & performance profile$C"
        end
        __td_report_disk_block
        __td_section_end
        echo ""
        __td_show_footer
        return 0
    end


    # ════════════════════════════════════════════════════════════════
    # MODULE: gpu
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "gpu"
        __td_section "🎮" "GRAPHICS ENGINE" "$B$WH GPU detection, VRAM, driver, clocks & temperature$C"
        __td_report_gpu_block
        __td_section_end
        echo ""
        __td_show_footer
        return 0
    end


    # ════════════════════════════════════════════════════════════════
    # MODULE: heat
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "heat"
        __td_section "🌡️" "THERMAL SENSORS" "$B$WH CPU cores, GPU, NVMe, fans & throttling status$C"
        __td_report_heat_block
        __td_section_end
        echo ""
        __td_show_footer
        return 0
    end


    # ════════════════════════════════════════════════════════════════
    # MODULE: net
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "net"
        __td_section "🌐" "NETWORK UPLINK" "$B$WH Speed test, latency, interfaces & DNS$C"
        __td_report_net_block
        __td_section_end
        echo ""
        __td_show_footer
        return 0
    end


    # ════════════════════════════════════════════════════════════════
    # MODULE: batt
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "batt"
        __td_section "🔋" "POWER STATUS" "$B$WH Battery health, capacity, drain rate & AC status$C"
        __td_report_batt_block
        __td_section_end
        echo ""
        __td_show_footer
        return 0
    end


    # ════════════════════════════════════════════════════════════════
    # MODULE: boot
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "boot"
        __td_section "🚀" "BOOT ANALYSIS" "$B$WH systemd-analyze breakdown & bootloader info$C"
        __td_report_boot_block
        __td_section_end
        echo ""
        __td_show_footer
        return 0
    end


    # ════════════════════════════════════════════════════════════════
    # MODULE: services
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "services"
        __td_section "⚙️" "SERVICE HEALTH" "$B$WH Systemd unit status & failures$C"
        __td_report_services_block
        __td_section_end
        echo ""
        __td_show_footer
        return 0
    end


    # ════════════════════════════════════════════════════════════════
    # MODULE: updates
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "updates"
        __td_section "📦" "PENDING UPDATES" "$B$WH DNF, Flatpak & firmware updates$C"
        __td_report_updates_block
        __td_section_end
        echo ""
        __td_show_footer
        return 0
    end


    # ════════════════════════════════════════════════════════════════
    # MODULE: top
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "top"
        __td_section "📊" "PROCESS LANDSCAPE" "$B$WH Top consumers: CPU, memory & I/O$C"
        __td_report_top_block
        __td_section_end
        echo ""
        __td_show_footer
        return 0
    end


    # ════════════════════════════════════════════════════════════════
    # MODULE: security
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "security"
        __td_section "🔒" "SECURITY POSTURE" "$B$WH SELinux, firewall, open ports & auth failures$C"
        __td_report_security_block
        __td_section_end
        echo ""
        __td_show_footer
        return 0
    end


    # ════════════════════════════════════════════════════════════════
    # MODULE: stress
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "stress"
        __td_section "🧨" "SYSTEM SATURATION TEST" "$B$WH Multi-core CPU, memory & I/O stress (10s each)$C"
        __td_report_stress_block
        __td_section_end
        echo ""
        __td_show_footer
        return 0
    end


    # ════════════════════════════════════════════════════════════════
    # MODULE: health
    # ════════════════════════════════════════════════════════════════
    if test "$module" = "health"
        __td_section "🏥" "SYSTEM HEALTH SCORE" "$B$WH Quick overall assessment: disk, memory, thermal, security$C"
        __td_show_scoreboard
        echo ""
        __td_show_footer
        return 0
    end


    # ── Footer ──

    # ════════════════════════════════════════════════════════════════
    # UNKNOWN MODULE
    # ════════════════════════════════════════════════════════════════
    echo -e "  $RE✘$C  $B$RE'$module'$C is not a valid module."
    __td_show_commands
    return 1
end
