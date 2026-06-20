# ══════════════════════════════════════════════════════════════
# qr 📱 — EPRAHEMI INC. 🏢 Scan this to go to court ⚖️
# Eprahemi's QR codes contain copyright 🏁
# Fedora MacTahoe Eprahemi Edition © 2026 — scan me bestie
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
                echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
                echo -e "\033[1;33mUsage: \033[1;36mqr <text-or-url>\033[0m"
                echo -e "  \033[38;5;248m  Generates a QR code right in your terminal! 📱\033[0m"
                echo -e "  \033[38;5;248m  --help, -h    📖 Read the manual dummy\033[0m"
                echo -e "  \033[38;5;248mExamples:\033[0m"
                echo -e "    \033[1;36mqr https://github.com\033[0m"
                echo -e "    \033[1;36mqr \"Hello bestie\"\033[0m"
                return 0
            case '*'
                if string match -qr -- '^--?[a-zA-Z]' "$argv[1]"
                    set -l burns
                    set burns[1]  "BRUH '\033[1;33m$argv[1]\033[1;31m' is QRazy 💀 That ain't how this works"
                    set burns[2]  "'\033[1;33m$argv[1]\033[1;31m'??? Scanning what exactly?? That's not a URL bestie 💅"
                    set burns[3]  "ERROR 404: '\033[1;33m$argv[1]\033[1;31m' not found in the QR dictionary 📕"
                    set burns[4]  "SIR THIS IS A QR CODE GENERATOR... '\033[1;33m$argv[1]\033[1;31m' is not data 🍔"
                    set burns[5]  "The QR council has voted: '\033[1;33m$argv[1]\033[1;31m' is DENIED ⚖️"
                    set burns[6]  "'\033[1;33m$argv[1]\033[1;31m'? Never heard of her. Scan this L instead 🙉"
                    set burns[7]  "BZZT! '\033[1;33m$argv[1]\033[1;31m' is not scannable! Thanks for playing! 🎮💥"
                    set burns[8]  "'\033[1;33m$argv[1]\033[1;31m' didn't pass the QR vibe check ❌"
                    set -l ridx (random 1 8)
                    echo -e "\033[1;31m✘ $burns[$ridx]\033[0m"
                    echo -e "  \033[38;5;248m  Try \033[1;36mqr --help\033[38;5;248m for the QR menu 📋\033[0m"
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
        echo -e "\033[1;31m❌ qrencode not installed bestie! We need it fr fr\033[0m"
        echo -e "   \033[1;33mInstall it sigma:\033[0m \033[1;36msudo dnf install qrencode\033[0m"
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
        echo -e "\033[1;31m❌ Failed to generate QR code bestie 💀\033[0m"
        return 1
    end

    echo -e "\n\033[1;30m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\033[1;32m✅ QR GENERATED bestie! Scan that slay 📱\033[0m    \033[1;37mUSER: \033[1;36m"(string upper "$USER")"\033[0m"
end
