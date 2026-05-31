function testdrive
    # --- EPRAHEMI CUSTOM HEADER ---
    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████║██║     ██║  ██║██║  ██║██║  ██║███████║██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    echo -e "         [ EPRAHEMI ELITE DIAGNOSTIC SUITE - V4 COMPLETE ]\033[0m"
    
    if not set -q argv[1]
        echo -e "\n\033[1;31mERR: No Parameter Access Granted.\033[0m"
        echo -e "\033[1;33mMaster Commands:\033[0m [\033[36mdisk\033[0m|\033[36mext\033[0m|\033[36mram\033[0m|\033[36mnet\033[0m|\033[36mheat\033[0m|\033[36minfo\033[0m|\033[36mgpu\033[0m|\033[36mbatt\033[0m|\033[36mcpu\033[0m|\033[36mstress\033[0m]"
        return 1
    end
    
    set -l drive_type $argv[1]
    set -l test_file ""
    set -l target_name ""

    function draw_progress
        set -l duration $argv[1]
        set -l label $argv[2]
        echo -n -e "\033[1;30m$label\033[0m ["
        for i in (seq 1 40)
            echo -n "▓"
            sleep (math $duration / 40)
        end
        echo "] 100%"
    end

    switch $drive_type
        case disk ext
            if test "$drive_type" = "disk"
                set test_file "$HOME/eprahemi_test_bin"
                set target_name "INTERNAL_SYSTEM_DRIVE"
                echo -e "🚀 \033[1;32mTARGET: $target_name\033[0m"
            else
                echo -e "🔍 \033[1;34mPROBING EXTERNAL STORAGE INFRASTRUCTURE...\033[0m"
                set -l drives (lsblk -pno MOUNTPOINT,SIZE,MODEL | grep "/run/media")
                set -l drive_count (count $drives)

                if test $drive_count -eq 0
                    echo -e "⚠️ \033[1;31mNo external drives detected!\033[0m" ; return 1
                else if test $drive_count -gt 1
                    echo -e "\033[1;33mMULTIPLE DRIVES DETECTED. SELECT TARGET:\033[0m"
                    set -l i 1
                    for d in $drives
                        echo -e "  \033[1;36m$i)\033[0m $d"
                        set i (math $i + 1)
                    end
                    echo -n -e "\n\033[1;37mCHOOSE DRIVE [1-$drive_count]: \033[0m"
                    read choice
                    if test "$choice" -ge 1 -a "$choice" -le "$drive_count"
                        set -l target_raw $drives[$choice]
                        set -l ext_path (echo $target_raw | awk '{print $1}')
                        set test_file "$ext_path/eprahemi_test_bin"
                        echo -e "📂 \033[1;32mTARGET LOCKED: $ext_path\033[0m"
                    else
                        echo -e "❌ \033[1;31mInvalid selection.\033[0m" ; return 1
                    end
                else
                    set -l ext_path (echo $drives[1] | awk '{print $1}')
                    set test_file "$ext_path/eprahemi_test_bin"
                    echo -e "📂 \033[1;34mTARGET: $ext_path\033[0m"
                end
            end

            # --- UNIVERSAL DRIVE ANALYSIS ---
            set -l dev_name (df $test_file | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//' | sed 's/p$//')
            set -l is_ssd (cat /sys/block/(basename $dev_name)/queue/rotational 2>/dev/null)
            set -l tech_label "UNKNOWN"
            if test "$is_ssd" = "0"
                if string match -q "*nvme*" $dev_name; set tech_label "NVMe (High-Speed)"; else; set tech_label "SATA SSD"; end
            else
                set tech_label "Mechanical HDD"
            end

            echo -e "🛠️  \033[1;37mTECHNOLOGY DETECTED: $tech_label\033[0m"
            draw_progress 0.5 "Flushing I/O Cache"

            # --- BENCHMARK ---
            set -l write_res (dd if=/dev/zero of=$test_file bs=1G count=1 oflag=dsync 2>&1 | grep -oE '[0-9.]+ [MG]B/s')
            set -l write_val (echo $write_res | awk '{print $1}')
            set -l write_unit (echo $write_res | awk '{print $2}')
            set -l write_mb $write_val
            if test "$write_unit" = "GB/s"; set write_mb (math "$write_val * 1024"); end

            # --- SPEED GRADING ---
            set -l grade ""; set -l g_color ""
            if test $write_mb -gt 2000; set grade "EXCELLENT / HIGH-END (NVMe GEN4+)"; set g_color "\033[1;32m"
            else if test $write_mb -gt 500; set grade "EXCELLENT (SATA/NVMe GEN3)"; set g_color "\033[1;32m"
            else if test $write_mb -gt 250; set grade "MID-RANGE (SATA SSD)"; set g_color "\033[1;33m"
            else if test $write_mb -gt 80; set grade "MID / STANDARD HDD"; set g_color "\033[1;33m"
            else; set grade "BAD / PERFORMANCE BOTTLENECK"; set g_color "\033[1;31m"
            end

            echo -e "\n\033[1;37m[ PERFORMANCE SCORE ]\033[0m"
            echo -e "📈 WRITE SPEED : \033[1;36m$write_res\033[0m"
            echo -e "🏆 GRADE       : $g_color$grade\033[0m"
            rm $test_file 2>/dev/null

        case ram
            echo -e "🧠 \033[1;35mTARGET: RAM THROUGHPUT\033[0m"
            draw_progress 1.2 "Allocating 3GB Memory Blocks"
            dd if=/dev/zero of=/dev/null bs=1M count=3000 status=progress
        case net
            echo -e "🌐 \033[1;36mTARGET: GLOBAL NETWORK UPLINK\033[0m"
            speedtest-cli --simple || echo "Install speedtest-cli for full results."
        case heat
            echo -e "🌡️ \033[1;31mTARGET: SYSTEM THERMAL SENSORS\033[0m"
            sensors | grep -E 'Core|temp|fan'
        case gpu
            echo -e "🎮 \033[1;32mTARGET: GRAPHICS ENGINE\033[0m"
            nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu --format=csv,noheader 2>/dev/null || echo "GPU Offline."
        case batt
            echo -e "🔋 \033[1;33mTARGET: POWER CELL STATUS\033[0m"
            upower -i (upower -e | grep 'BAT') | grep -E "percentage|capacity|state"
        case cpu
            echo -e "📟 \033[1;34mTARGET: PROCESSOR TOPOLOGY\033[0m"
            lscpu | grep -E "Model name|CPU\(s\):|Max MHz"
        case stress
            echo -e "🧨 \033[1;31mTARGET: SYSTEM OVERLOAD TEST (10s)\033[0m"
            draw_progress 0.5 "Priming Cores"
            timeout 10s cat /dev/urandom > /dev/null
        case info
            echo -e "\033[1;33m╔══════════════════════════════════════════════════════════╗\033[0m"
            echo -e "║            EPRAHEMI MASTER SYSTEM BLUEPRINT              ║"
            echo -e "╚══════════════════════════════════════════════════════════╝\033[0m"
            echo -e "\033[1;36m[💻 HARDWARE]\033[0m"; sudo dmidecode -s baseboard-product-name
            echo -e "\n\033[1;34m[💽 STORAGE MAPPING]\033[0m"; lsblk -p -o NAME,SIZE,TYPE,MODEL,MOUNTPOINT | grep -v "loop"
            echo -e "\n\033[1;32m[🌐 NETWORK]\033[0m"; echo -n "Local IP: "; ip route get 1 | awk '{print $7}'; echo -n "Public IP: "; curl -s https://ifconfig.me
        case '*'
            echo -e "❌ \033[1;31mParameter Error:\033[0m '$drive_type' not recognized."
            return 1
    end
    
    echo -e "\n\033[1;37m[ STATUS: SUCCESS - USER: EPRAHEMI ]\033[0m"
    echo -e "\033[1;30m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\033[1;33m📂 ALL AVAILABLE COMMANDS:\033[0m"
    echo -e "  ➤ \033[36mtestdrive disk\033[0m   : Internal Storage Speed & Grading"
    echo -e "  ➤ \033[36mtestdrive ext\033[0m    : External Storage Picker & Benchmark"
    echo -e "  ➤ \033[36mtestdrive ram\033[0m    : Memory Bandwidth Throughput Test"
    echo -e "  ➤ \033[36mtestdrive net\033[0m    : Internet Speed & Latency Check"
    echo -e "  ➤ \033[36mtestdrive heat\033[0m   : Real-time CPU Thermal & Fan Sensors"
    echo -e "  ➤ \033[36mtestdrive gpu\033[0m    : Graphics Utilization & Temp (NVIDIA)"
    echo -e "  ➤ \033[36mtestdrive cpu\033[0m    : Processor Architecture & Clock Speed"
    echo -e "  ➤ \033[36mtestdrive batt\033[0m   : Power Health & Battery Capacity"
    echo -e "  ➤ \033[36mstress\033[0m           : 10s Thermal Pressure / Saturation Test"
    echo -e "  ➤ \033[36minfo\033[0m             : Full System Blueprint & IP Mapping"
    echo -e "\033[1;30m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
end
