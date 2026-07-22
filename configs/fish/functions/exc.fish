function exc --description 'Make file executable and run it'
    if test (count $argv) -eq 0
        printf "  Usage: exc <file> [args...]\n"
        printf "  Makes a file executable and runs it.\n"
        echo ""
        printf "  Examples:\n"
        printf "    exc ./Equilotl\n"
        printf "    exc ~/Downloads/some-binary --flag\n"
        printf "    exc EquilotlCli-linux\n"
        return 1
    end

    set -l file "$argv[1]"
    set -l rest $argv[2..-1]

    # Expand ~ and relative paths
    if test -f "$file"
        # File found as-is
    else if test -f "./$file"
        set file "./$file"
    else
        printf "  File not found: %s\n" "$file"
        return 1
    end

    # Check if it's actually a file (not a directory)
    if test -d "$file"
        printf "  %s is a directory, not a file.\n" "$file"
        return 1
    end

    # Make executable if not already
    if not test -x "$file"
        chmod +x "$file"
        printf "  Made executable: %s\n" "$file"
    end

    # Run it
    command $file $rest
end
