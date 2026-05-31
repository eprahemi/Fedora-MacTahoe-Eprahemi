function n
    if test (count $argv) -gt 0
        # Opens a specific file if you provide a name
        gnome-text-editor $argv & disown
    else
        # Opens a fresh, empty note
        gnome-text-editor --new-window & disown
    end
end
