function v
    if test (count $argv) -gt 0
        vlc $argv & disown
    else
        vlc & disown
    end
end
