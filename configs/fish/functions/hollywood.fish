function hollywood --wraps='podman run -it --rm cgr.dev/chainguard/hollywood' --description 'alias hollywood=podman run -it --rm cgr.dev/chainguard/hollywood'
    if set -q argv[1]
        switch $argv[1]
            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mhollywood\033[0m"
                echo -e "  \033[38;5;248m  Makes your terminal look like a Hollywood hacker movie 🎬\033[0m"
                echo -e "  \033[38;5;248m  No flags needed, just run it sigma!\033[0m"
                echo -e "  \033[38;5;248m  --help, -h    📖 Read the manual dummy\033[0m"
                return 0
        end
    end
    echo -e "\033[1;35m🎬 Matrix mode activated... look like a hacker bestie! 💻\033[0m"
    podman run -it --rm cgr.dev/chainguard/hollywood $argv
end
