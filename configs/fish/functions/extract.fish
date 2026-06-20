# ══════════════════════════════════════════════════════════════
# extract 📦 — EPRAHEMI INC. 🏢 Extraction is an art form 🎨
# Unauthorized copying? I'll extract your kneecaps 🦵💥
# Fedora MacTahoe Eprahemi Edition © 2026 — decompress this
# ══════════════════════════════════════════════════════════════
function extract --description 'Extract any archive file — auto-detects format'
    if set -q argv[1]
        switch $argv[1]
            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mextract <archive> [destination]\033[0m"
                echo -e "  \033[38;5;248m  Auto-detects format and extracts it.\033[0m"
                echo -e "  \033[38;5;248m  Supported: .tar.gz/.tgz .tar.bz2/.tbz2 .tar.xz/.txz .tar.zst .tar .gz .bz2 .xz .zst .zip .rar .7z .lz4\033[0m"
                echo -e "  \033[38;5;248m  Examples:\033[0m"
                echo -e "    \033[1;36mextract file.tar.gz\033[0m"
                echo -e "    \033[1;36mextract file.zip ~/target/\033[0m"
                echo -e "  \033[38;5;248m  --help, -h     Show this help\033[0m"
                return 0
        end
    else
        echo -e "\033[1;33mUsage bestie: \033[1;36mextract <archive> [destination]\033[0m"
        echo -e "  \033[38;5;248m  Supported: .tar.gz/.tgz .tar.bz2/.tbz2 .tar.xz/.txz .tar.zst .tar .gz .bz2 .xz .zst .zip .rar .7z .lz4\033[0m"
        echo -e "  \033[38;5;248m  Run \033[1;36mextract --help\033[38;5;248m for the deets 💅\033[0m"
        return 1
    end

    set -l file "$argv[1]"
    set -l dest "$argv[2]"

    if not test -f "$file"
        echo -e "\033[1;31m❌ Oopsie bestie! File not found: \033[1;33m$file\033[0m"
        return 1
    end

    set -l ext (string lower "$file")

    # Determine the extract command
    set -l cmd
    set -l outdir ""

    if string match -qr '\.tar\.gz$|\.tgz$' "$ext"
        set cmd "tar -xzf \"$file\""
    else if string match -qr '\.tar\.bz2$|\.tbz2$' "$ext"
        set cmd "tar -xjf \"$file\""
    else if string match -qr '\.tar\.xz$|\.txz$' "$ext"
        set cmd "tar -xJf \"$file\""
    else if string match -qr '\.tar\.zst$' "$ext"
        set cmd "tar --zstd -xf \"$file\""
    else if string match -qr '\.tar$' "$ext"
        set cmd "tar -xf \"$file\""
    else if string match -qr '\.gz$' "$ext"
        set cmd "gunzip -k \"$file\""
    else if string match -qr '\.bz2$' "$ext"
        set cmd "bunzip2 -k \"$file\""
    else if string match -qr '\.xz$' "$ext"
        set cmd "unxz -k \"$file\""
    else if string match -qr '\.zst$' "$ext"
        set cmd "unzstd -k \"$file\""
    else if string match -qr '\.zip$' "$ext"
        set cmd "unzip -o \"$file\""
    else if string match -qr '\.rar$' "$ext"
        set cmd "unrar x -o+ \"$file\""
    else if string match -qr '\.7z$' "$ext"
        set cmd "7z x \"$file\" -y"
    else if string match -qr '\.lz4$' "$ext"
        set cmd "lz4 -d \"$file\""
    else
        echo -e "\033[1;31m❌ Unsupported archive format bestie: \033[1;33m$ext\033[0m"
        return 1
    end

    # If destination specified, add -C or equivalent
    if test -n "$dest"
        if test -d "$dest"
            if string match -qr '\.(tar\.|tgz|tbz2|txz|tar)' "$ext"
                set cmd "$cmd -C \"$dest\""
            else if string match -qr '\.zip$' "$ext"
                set cmd "$cmd -d \"$dest\""
            else if string match -qr '\.rar$' "$ext"
                set cmd "unrar x -o+ \"$file\" \"$dest/\""
            else if string match -qr '\.7z$' "$ext"
                set cmd "$cmd -o\"$dest\""
            end
        else
            echo -e "\033[1;31m❌ That's not a directory bestie: \033[1;33m$dest\033[0m"
            return 1
        end
    end

    echo -e "\033[1;36m"
    echo "  ███████╗██╗  ██╗████████╗██████╗  █████╗  ██████╗████████╗"
    echo "  ██╔════╝╚██╗██╔╝╚══██╔══╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝"
    echo "  █████╗   ╚███╔╝    ██║   ██████╔╝███████║██║        ██║   "
    echo "  ██╔══╝   ██╔██╗    ██║   ██╔══██╗██╔══██║██║        ██║   "
    echo "  ███████╗██╔╝ ██╗   ██║   ██║  ██║██║  ██║╚██████╗   ██║   "
    echo "  ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝   ╚═╝   "
    echo -e "\033[1;30m┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄\033[0m"
    printf "  \033[1;37m📦 \033[1;33m%s\033[0m\n" (basename "$file")

    set -l start (date +%s)
    eval $cmd
    set -l exit_code $status
    set -l elapsed (math (date +%s) - $start)

    if test $exit_code -eq 0
        echo -e "  \033[1;32m✔ Extracted in $elapsed"s" bestie! 🔥\033[0m"
        if test -z "$dest"
            set -l dirname (string replace -r '\\.(tar\\.gz|tgz|tar\\.bz2|tbz2|tar\\.xz|txz|tar\\.zst|tar|zip|rar|7z|lz4)$' '' (basename "$file"))
            if test -d "$dirname"
                echo -e "  \033[1;36m📂 Contents:\033[0m"
                ls -la "$dirname" 2>/dev/null | head -15
            end
        else
            echo -e "  \033[1;36m📂 Extracted to: \033[1;37m$dest\033[0m"
        end
    else
        echo -e "  \033[1;31m❌ Extraction failed bestie (exit $exit_code) 💀\033[0m"
        return 1
    end
end
