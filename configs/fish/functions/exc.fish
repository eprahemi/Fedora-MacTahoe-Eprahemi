# exc — Auto-chmod and run/open executables
# Fedora MacTahoe Eprahemi System Configuration (c) 2026
function exc --description 'Auto-chmod and run/open executables'

    # ── Colors ──
    set -l R    (printf "\e[1;31m")
    set -l G    (printf "\e[1;32m")
    set -l Y    (printf "\e[1;33m")
    set -l B    (printf "\e[1;34m")
    set -l C    (printf "\e[1;36m")
    set -l W    (printf "\e[1;37m")
    set -l D    (printf "\e[0;37m")
    set -l N    (printf "\e[0m")
    set -l BOLDG (printf "\e[1;32m")
    set -l BOLDY (printf "\e[1;33m")
    set -l BOLDR (printf "\e[1;31m")
    set -l BOLDC (printf "\e[1;36m")

    # ── No args → help ──
    if test (count $argv) -eq 0
        printf "\n"
        printf "  $BOLDC exc$N — Auto-chmod and run/open executables\n"
        printf "  $D Fedora MacTahoe  $N\n"
        printf "\n"
        printf "  $BOLDY USAGE$N\n"
        printf "    $W exc <file> [args]$N         Auto-chmod and run\n"
        printf "    $W exc open <file>$N           Open with default app\n"
        printf "    $W exc help$N                  Show this help\n"
        printf "    $W exc list$N                  List executables in current dir\n"
        printf "    $W exc recent$N                Show recent downloads\n"
        printf "    $W exc find <name>$N           Search for executables\n"
        printf "    $W exc info <file>$N           Show file details\n"
        printf "    $W exc --dry-run <file>$N      Preview without running\n"
        printf "\n"
        printf "  $BOLDG EXAMPLES$N\n"
        printf "    $W exc ./Equilotl$N            Make executable and run\n"
        printf "    $W exc open image.png$N        Open image with default viewer\n"
        printf "    $W exc open script.sh$N        Make executable, then open\n"
        printf "    $W exc find Equilotl$N         Search for Equilotl binary\n"
        printf "    $W exc info ./Equilotl$N       Show file type and details\n"
        printf "    $W exc recent$N                Show what you downloaded today\n"
        printf "\n"
        printf "  $BOLDY SAFETY$N\n"
        printf "    Unknown files ask for confirmation before running.\n"
        printf "    Files in PATH or already executable run directly.\n"
        printf "\n"
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # HELP
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "help"; or test "$argv[1]" = "-help"; or test "$argv[1]" = "--help"
        exc
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # OPEN — open file with default app
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "open"
        if test (count $argv) -lt 2
            printf "  $R✗$N  Missing file argument.\n"
            printf "  Usage: exc open <file>\n"
            return 1
        end
        set -l file "$argv[2]"

        # Find the file
        if test -f "$file"
            # found as-is
        else if test -f "./$file"
            set file "./$file"
        else
            printf "  $R✗$N  File not found: %s\n" "$file"
            return 1
        end

        if test -d "$file"
            printf "  $R✗$N  %s is a directory, not a file.\n" "$file"
            return 1
        end

        # Make executable if needed
        if not test -x "$file"
            printf "  $Y*$N  Making executable: %s\n" (basename "$file")
            chmod +x "$file"
        end

        # Open with default app
        printf "  $G✓$N  Opening: %s\n" (basename "$file")
        xdg-open "$file" >/dev/null 2>&1 &
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # LIST — list executables in current dir
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "list"
        echo ""
        set -l found 0
        for f in *
            if test -f "$f"; and test -x "$f"
                set -l sz (du -h "$f" 2>/dev/null | awk '{print $1}')
                printf "  $G✓$N  %-30s  $D%s$N\n" "$f" "$sz"
                set found (math $found + 1)
            end
        end
        if test $found -eq 0
            printf "  $D No executable files in current directory.$N\n"
        else
            echo ""
            printf "  $D%d executable(s) found.$N\n" "$found"
        end
        echo ""
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # RECENT — show recent downloads
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "recent"
        echo ""
        set -l dl_dir "$HOME/Downloads"
        if not test -d "$dl_dir"
            printf "  $R✗$N  Downloads directory not found.\n"
            return 1
        end
        # Get files modified in last 7 days, sorted by time
        set -l files (find "$dl_dir" -maxdepth 1 -type f -mtime -7 2>/dev/null | sort -t/ -k5 | tail -20)
        if test (count $files) -eq 0
            printf "  $D No recent downloads (last 7 days).$N\n"
            echo ""
            return 0
        end
        printf "  $BOLDG RECENT DOWNLOADS$N (last 7 days)\n"
        echo ""
        set -l idx 1
        for f in $files
            set -l name (basename "$f")
            set -l sz (du -h "$f" 2>/dev/null | awk '{print $1}')
            set -l dt (stat -c '%y' "$f" 2>/dev/null | cut -d. -f1)
            set -l mark ""
            if test -x "$f"
                set mark "$G✓$N"
            else
                set mark "$D-$N"
            end
            printf "  %s  $W%-3s$N  %-35s  $D%-8s$N  %s\n" "$mark" "$idx" "$name" "$sz" "$dt"
            set idx (math $idx + 1)
        end
        echo ""
        printf "  $D✓ = executable  Run 'exc <file>' to make executable and run$N\n"
        echo ""
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # FIND — search for executables
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "find"
        if test (count $argv) -lt 2
            printf "  $R✗$N  Missing search term.\n"
            printf "  Usage: exc find <name>\n"
            return 1
        end
        set -l query "$argv[2]"
        echo ""
        printf "  $BOLDG SEARCHING$N for '$W$query$N'...\n"
        echo ""

        set -l found 0

        # Search PATH
        for dir in (string split ':' $PATH)
            if test -d "$dir"
                for f in "$dir"/*$query*
                    if test -f "$f"; and test -x "$f"
                        set -l name (basename "$f")
                        printf "  $G✓$N  $W%-20s$N  $D%s$N\n" "$name" "$f"
                        set found (math $found + 1)
                    end
                end
            end
        end

        # Search ~/Downloads
        set -l dl_dir "$HOME/Downloads"
        if test -d "$dl_dir"
            for f in "$dl_dir"/*$query*
                if test -f "$f"
                    set -l name (basename "$f")
                    set -l mark ""
                    if test -x "$f"
                        set mark "$G✓$N"
                    else
                        set mark "$Y*$N"
                    end
                    printf "  %s  $W%-20s$N  $D%s$N\n" "$mark" "$name" "$f"
                    set found (math $found + 1)
                end
            end
        end

        # Search current dir
        for f in ./*$query*
            if test -f "$f"; and test -x "$f"
                set -l name (basename "$f")
                printf "  $G✓$N  $W%-20s$N  $D./%s$N\n" "$name" "$name"
                set found (math $found + 1)
            end
        end

        if test $found -eq 0
            printf "  $D No executables found matching '$query'.$N\n"
        else
            echo ""
            printf "  $D%d result(s) found.$N\n" "$found"
        end
        echo ""
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # INFO — show file details
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "info"
        if test (count $argv) -lt 2
            printf "  $R✗$N  Missing file argument.\n"
            printf "  Usage: exc info <file>\n"
            return 1
        end
        set -l file "$argv[2]"

        # Find the file
        if test -f "$file"
            # found
        else if test -f "./$file"
            set file "./$file"
        else
            printf "  $R✗$N  File not found: %s\n" "$file"
            return 1
        end

        echo ""
        printf "  $BOLDG FILE INFO$N\n"
        echo ""

        # Basic info
        set -l name (basename "$file")
        set -l sz (du -h "$file" 2>/dev/null | awk '{print $1}')
        set -l full_sz (stat -c '%s' "$file" 2>/dev/null)
        set -l dt (stat -c '%y' "$file" 2>/dev/null | cut -d. -f1)
        set -l perms (stat -c '%A' "$file" 2>/dev/null)

        printf "  $W Name:$N     %s\n" "$name"
        printf "  $W Path:$N     %s\n" "$file"
        printf "  $W Size:$N     %s ($D%s bytes$N)\n" "$sz" "$full_sz"
        printf "  $W Modified:$N %s\n" "$dt"
        printf "  $W Perms:$N    %s\n" "$perms"

        # File type
        set -l ftype (file -b "$file" 2>/dev/null)
        printf "  $W Type:$N     %s\n" "$ftype"

        # Executable?
        if test -x "$file"
            printf "  $W Exec:$N     $GYes$N\n"
        else
            printf "  $W Exec:$N     $RNo$N (run 'exc %s' to fix)\n" "$name"
        end

        # ELF info
        if string match -q "ELF*" "$ftype"
            set -l arch (file "$file" 2>/dev/null | grep -o 'x86-64\|aarch64\|i686' | head -1)
            set -l linked (file "$file" 2>/dev/null | grep -o 'dynamically linked\|statically linked' | head -1)
            if test -n "$arch"
                printf "  $W Arch:$N     %s\n" "$arch"
            end
            if test -n "$linked"
                printf "  $W Linking:$N  %s\n" "$linked"
            end
        end

        # Script info
        if string match -q "script*" "$ftype"; or string match -q "*text*" "$ftype"
            set -l sheadd (head -1 "$file" 2>/dev/null)
            if string match -q "#!*" "$sheadd"
                printf "  $W Shebang:$N  %s\n" "$sheadd"
            end
            set -l lines (wc -l < "$file" 2>/dev/null | string trim)
            printf "  $W Lines:$N    %s\n" "$lines"
        end

        echo ""
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # DRY-RUN — preview without running
    # ════════════════════════════════════════════════════════════

    if test "$argv[1]" = "--dry-run"
        if test (count $argv) -lt 2
            printf "  $R✗$N  Missing file argument.\n"
            printf "  Usage: exc --dry-run <file>\n"
            return 1
        end
        set -l file "$argv[2]"

        # Find the file
        if test -f "$file"
            # found
        else if test -f "./$file"
            set file "./$file"
        else
            printf "  $R✗$N  File not found: %s\n" "$file"
            return 1
        end

        echo ""
        printf "  $BOLDY DRY RUN$N — would do the following:\n"
        echo ""

        if test -x "$file"
            printf "  $G✓$N  Already executable: %s\n" (basename "$file")
        else
            printf "  $Y*$N  Would run: $D chmod +x %s$N\n" "$file"
        end

        printf "  $G✓$N  Would run: $W%s$N\n" "$file"
        if test (count $argv) -gt 2
            printf "  $D   With args: %s$N\n" (string join ' ' $argv[3..-1])
        end
        echo ""
        return 0
    end

    # ════════════════════════════════════════════════════════════
    # RUN FILE — exc <file> [args]
    # ════════════════════════════════════════════════════════════

    set -l file "$argv[1]"
    set -l rest $argv[2..-1]

    # Find the file
    if test -f "$file"
        # found as-is
    else if test -f "./$file"
        set file "./$file"
    else
        printf "  $R✗$N  File not found: %s\n" "$file"
        printf "  Use 'exc find %s' to search for it.\n" "$file"
        return 1
    end

    if test -d "$file"
        printf "  $R✗$N  %s is a directory, not a file.\n" "$file"
        return 1
    end

    # Get file type
    set -l ftype (file -b "$file" 2>/dev/null)

    # Check if already executable
    set -l was_exec 1
    if not test -x "$file"
        set was_exec 0
        printf "  $Y*$N  Not executable. Making executable: %s\n" (basename "$file")
        chmod +x "$file"
        printf "  $G✓$N  chmod +x applied\n"
    end

    # If already executable (or just made executable), ask for confirmation
    # on unknown files (not in PATH, first time)
    set -l needs_confirm 0

    # Check if it's a known/safe file type
    set -l safe 0
    if string match -q "ELF*" "$ftype"
        set safe 1
    end
    if string match -q "*script*" "$ftype"; or string match -q "*text*" "$ftype"
        set safe 1
    end
    if string match -q "*Python*" "$ftype"; or string match -q "*Perl*" "$ftype"
        set safe 1
    end

    # If file was already executable and is ELF, it's probably been run before
    if test $was_exec -eq 1
        # Already executable — run directly
        printf "  $G✓$N  Running: %s\n" (basename "$file")
        command $file $rest
        return $status
    end

    # File was just made executable — ask for confirmation
    echo ""
    printf "  $BOLDY RUN FILE$N\n"
    printf "  File:  $W%s$N\n" (basename "$file")
    printf "  Type:  %s\n" "$ftype"
    printf "  Size:  %s\n" (du -h "$file" 2>/dev/null | awk '{print $1}')
    echo ""
    printf "  Run this file? [Y/n]: "
    read -l confirm
    echo ""

    if test "$confirm" = "n"; or test "$confirm" = "N"
        printf "  $D Cancelled.$N\n"
        return 0
    end

    printf "  $G✓$N  Running: %s\n" (basename "$file")
    echo ""
    command $file $rest
    return $status
end
