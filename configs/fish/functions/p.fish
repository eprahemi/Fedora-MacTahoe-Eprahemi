# ══════════════════════════════════════════════════════════════
# p 🔍 — Interactive file preview with fzf + bat 📂
# Preview files with syntax highlighting via bat
# Fedora MacTahoe Eprahemi Edition © 2026 — look but don't steal
# ══════════════════════════════════════════════════════════════
function p --wraps="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'" --description 'Interactive file preview with fzf + bat'
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
                echo -e "\033[1;33mUsage: \033[1;36mp\033[0m"
                echo -e "  \033[38;5;248m  Interactive file preview with fzf + bat\033[0m"
                echo -e "  \033[38;5;248m  Run without arguments to select a file interactively.\033[0m"
                echo -e "  \033[38;5;248m  --help, -h    📖 Show this help message\033[0m"
                echo -e "  \033[38;5;248m📦 Unknown flag handling (Jun 2026)\033[0m"
                return 0
        end
    end
  # --- EPRAHEMI CUSTOM HEADER ---
    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    echo -e "\033[1;33m🔍 Preview mode. Select a file to preview 📂\033[0m"
    fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' $argv
end
