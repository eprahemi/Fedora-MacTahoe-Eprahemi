function c
    if test (count $argv) -gt 0
        celluloid $argv & disown
    else
        celluloid & disown
    end
end
