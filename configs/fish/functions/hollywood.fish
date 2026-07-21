# ══════════════════════════════════════════════════════════════
# hollywood — Hollywood hacker terminal simulator
# Runs Hollywood typer effect in a container
# Fedora MacTahoe Eprahemi Edition © 2026 — starring Eprahemi
# ══════════════════════════════════════════════════════════════
function hollywood --wraps='podman run -it --rm cgr.dev/chainguard/hollywood' --description 'Hollywood hacking terminal simulator'
    if set -q argv[1]
        switch $argv[1]
            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mhollywood\033[0m"
                echo -e "  \033[38;5;248m  Makes your terminal look like a Hollywood hacker movie\033[0m"
                echo -e "  \033[38;5;248m  No flags needed.\033[0m"
                echo -e "  \033[38;5;248m  --help, -h    📖 Show this help message\033[0m"
                echo -e "  \033[38;5;248m📦 Unknown flag handling (Jun 2026)\033[0m"
                return 0
        end
    end
    echo -e "\033[1;35mHollywood mode activated.\033[0m"
    podman run -it --rm cgr.dev/chainguard/hollywood $argv
end
