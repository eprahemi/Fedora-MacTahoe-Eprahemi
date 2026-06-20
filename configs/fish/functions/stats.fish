# ══════════════════════════════════════════════════════════════
# stats 📊 — EPRAHEMI INC. 🏢 Statistics don't lie but I do 😈
# Eprahemi's system vitals > your entire PC 🖥️💰
# Fedora MacTahoe Eprahemi Edition © 2026 — flexing on you
# ══════════════════════════════════════════════════════════════
function stats --description 'System dashboard: uptime, RAM, disk, CPU, load'
    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    echo -e "\033[1;34m╔══════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;34m║          \033[1;36mSYSTEM VITALS - LIVE DASHBOARD\033[1;34m              ║\033[0m"
    echo -e "\033[1;34m╚══════════════════════════════════════════════════════════╝\033[0m"

    set -l host (hostname -s 2>/dev/null; or echo "unknown")
    set -l kernel (uname -r 2>/dev/null; or echo "—")
    set -l distro (awk -F= '/^NAME/{print $2}' /etc/os-release 2>/dev/null | tr -d '"'; or echo "Linux")

    echo -e "\n  \033[1;37m🖥️  HOST\033[0m         \033[1;36m$host\033[0m"
    echo -e "  \033[1;37m💿 KERNEL\033[0m        \033[1;35m$kernel\033[0m"
    echo -e "  \033[1;37m📀 DISTRO\033[0m        \033[1;33m$distro\033[0m"

    set -l uptime_str (uptime -p 2>/dev/null | sed 's/up //'; or uptime | awk -F'up ' '{split($2,a,", "); print a[1]}')
    echo -e "  \033[1;37m⏱️  UPTIME\033[0m        \033[1;32m$uptime_str\033[0m"

    set -l load (cat /proc/loadavg 2>/dev/null; or echo "—")
    echo -e "  \033[1;37m📊 LOAD\033[0m          \033[1;33m$load\033[0m"

    set -l cpu_model (lscpu 2>/dev/null | awk -F': +' '/Model name/ {print $2}')
    set -l cpu_count (nproc 2>/dev/null; or echo "?")
    if test -n "$cpu_model"
        echo -e "  \033[1;37m🧠 CPU\033[0m           \033[1;36m$cpu_model\033[0m"
        echo -e "  \033[1;37m🔢 CORES\033[0m         \033[1;35m$cpu_count\033[0m"
    end

    set -l mem_total (free -h 2>/dev/null | awk '/^Mem:/{print $2}')
    set -l mem_used (free -h 2>/dev/null | awk '/^Mem:/{print $3}')
    set -l mem_pct (free 2>/dev/null | awk '/^Mem:/{printf "%.1f", $3/$2 * 100}')
    if test -n "$mem_total"
        echo -e "  \033[1;37m💾 RAM\033[0m           \033[1;32m$mem_used\033[0m / \033[1;33m$mem_total\033[0m \033[1;30m($mem_pct%)\033[0m"
    end

    set -l disk_info (df -h / 2>/dev/null | tail -1)
    set -l disk_total (echo $disk_info | awk '{print $2}')
    set -l disk_used (echo $disk_info | awk '{print $3}')
    set -l disk_pct (echo $disk_info | awk '{print $5}')
    if test -n "$disk_total"
        echo -e "  \033[1;37m💽 DISK\033[0m          \033[1;32m$disk_used\033[0m / \033[1;33m$disk_total\033[0m \033[1;30m($disk_pct)\033[0m"
    end

    echo -e "\n\033[1;30m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\033[1;34m🔧 STATUS: \033[1;32mOPERATIONAL (system's feeling cute today fr fr)\033[0m    \033[1;37mUSER: \033[1;36m"(string upper "$USER")"\033[0m"
end
