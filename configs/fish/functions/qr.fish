# ══════════════════════════════════════════════════════════════
# qr 📱 — EPRAHEMI INC. 🏢 Terminal QR code generator
# QR code generation utility
# Fedora MacTahoe Eprahemi Edition © 2026
# ══════════════════════════════════════════════════════════════
function qr --description 'Generate a QR code in the terminal'
    if set -q argv[1]
        switch $argv[1]
            case --help -h
                echo -e "\033[1;36m"
                echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
                echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
                echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
                echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
                echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
                echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
                echo -e "\033[1;33mUsage: \033[1;36mqr <text-or-url>\033[0m"
                echo -e "  \033[38;5;248m  Generates a QR code in the terminal 📱\033[0m"
                echo -e "  \033[38;5;248m  --help, -h    📖 Show help\033[0m"
                echo -e "  \033[38;5;248mExamples:\033[0m"
                echo -e "    \033[1;36mqr https://github.com\033[0m"
                echo -e "    \033[1;36mqr \"Hello world\"\033[0m"
                echo -e "  \033[38;5;248m📦 Unknown flag handling (Jun 2026)\033[0m"
                return 0
            case '*'
                if string match -qr -- '^--?[a-zA-Z]' "$argv[1]"
                    echo -e "\033[1;31m✘ Error: Unknown flag '\033[1;33m$argv[1]\033[1;31m'\033[0m"
                    echo -e "  \033[38;5;248m  Try \033[1;36mqr --help\033[38;5;248m for available options 📋\033[0m"
                    return 1
                end
        end
    end

    if test (count $argv) -lt 1
        echo -e "\033[1;36m"
        echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
        echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
        echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
        echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
        echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
        echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
        echo -e "\033[1;31m╔══════════════════════════════════════════════════════════╗\033[0m"
        echo -e "\033[1;31m║            \033[1;33mUSAGE:  qr <text-or-url>\033[1;31m                  ║\033[0m"
        echo -e "\033[1;31m╚══════════════════════════════════════════════════════════╝\033[0m"
        echo -e "  \033[1;37mExamples:\033[0m"
        echo -e "    \033[1;36mqr https://github.com\033[0m"
        echo -e "    \033[1;36mqr \"Hello Eprahemi\"\033[0m"
        return 1
    end

    if not command -v qrencode &>/dev/null
        echo -e "\033[1;31m❌ qrencode is not installed\033[0m"
        echo -e "   \033[1;33mInstall it with:\033[0m \033[1;36msudo dnf install qrencode\033[0m"
        return 1
    end

    set -l input (string join -- " " $argv)

    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║█████╗  ██╔████╔██║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    echo -e "\033[1;32m╔══════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;32m║             \033[1;36mQR CODE GENERATOR ACTIVE\033[1;32m                ║\033[0m"
    echo -e "\033[1;32m╚══════════════════════════════════════════════════════════╝\033[0m"
    echo -e "  \033[1;37mENCODED:\033[0m \033[1;33m$input\033[0m\n"

    qrencode -t UTF8 "$input" 2>/dev/null

    if test $status -ne 0
        qrencode -t ANSI "$input" 2>/dev/null
    end

    if test $status -ne 0
        echo -e "\033[1;31m❌ Failed to generate QR code\033[0m"
        return 1
    end

    echo -e "\n\033[1;30m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\033[1;32m✅ QR code generated. Scan to view 📱\033[0m    \033[1;37mUSER: \033[1;36m"(string upper "$USER")"\033[0m"
end
