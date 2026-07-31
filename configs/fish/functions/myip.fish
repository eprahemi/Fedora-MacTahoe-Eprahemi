# ══════════════════════════════════════════════════════════════
# myip 🌐 — EPRAHEMI INC. Network identity panel
# Display public and local IP addresses
# Fedora MacTahoe Eprahemi Edition © 2026
# ══════════════════════════════════════════════════════════════
function myip --description 'Show public IP, local IP & DNS servers in a styled panel'
    if set -q argv[1]
        switch $argv[1]
            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mmyip\033[0m"
                echo -e "  \033[38;5;248m  (no args)     Show public IP, local IP & DNS\033[0m"
                echo -e "  \033[38;5;248m  --help, -h    Show this help\033[0m"
                echo -e "\n  \033[38;5;248mNetwork identity panel — June 2026\033[0m"
                return 0
            case '-*'
                echo -e "\033[1;31m✘ Error: '\033[1;33m$argv[1]\033[1;31m' is not a valid myip option\033[0m"
                echo -e "  \033[38;5;248m  Try \033[1;36mmyip --help\033[38;5;248m for usage information 📋\033[0m"
                return 1
        end
    end

    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    echo -e "\033[1;33m╔══════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;33m║           \033[1;36mNETWORK IDENTITY - IP COMPASS\033[1;33m              ║\033[0m"
    echo -e "\033[1;33m╚══════════════════════════════════════════════════════════╝\033[0m"

    __loading "Contacting the network" "curl -s --max-time 5 https://ifconfig.me"
    set -l pub_ip "$__loading_result"
    set -e __loading_result
    if test -z "$pub_ip"
        set pub_ip "\033[1;31mUNREACHABLE\033[0m"
    else
        set pub_ip "\033[1;36m$pub_ip\033[0m"
    end

    set -l local_ip (ip route get 1 2>/dev/null | awk '{print $7}')
    if test -z "$local_ip"
        set local_ip "\033[1;31mUNKNOWN\033[0m"
    else
        set local_ip "\033[1;32m$local_ip\033[0m"
    end

    set -l iface (ip route get 1 2>/dev/null | awk '{print $5}')
    if test -z "$iface"; set iface "—"; end

    set -l dns_servers (string join ", " (awk '/^nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null))
    if test -z "$dns_servers"
        set dns_servers "\033[1;31mUNKNOWN\033[0m"
    else
        set dns_servers "\033[1;33m$dns_servers\033[0m"
    end

    echo -e "\n  \033[1;37m🌐 PUBLIC IP\033[0m      $pub_ip"
    echo -e "  \033[1;37m🏠 LOCAL IP\033[0m       $local_ip"
    echo -e "  \033[1;37m🔌 INTERFACE\033[0m      \033[1;35m$iface\033[0m"
    echo -e "  \033[1;37m📡 DNS SERVERS\033[0m    $dns_servers"
    echo -e "\n\033[1;30m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\033[1;33m🔒 STATUS: \033[1;32mLIVE\033[0m    \033[1;37mUSER: \033[1;36m"(string upper "$USER")"\033[0m"
end
