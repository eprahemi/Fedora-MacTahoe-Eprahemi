# ══════════════════════════════════════════════════════════════
# fish_greeting — Display figlet user greeting
# Fedora MacTahoe Eprahemi Edition © 2026
# ══════════════════════════════════════════════════════════════
function fish_greeting --description 'Greeting: figlet user art'
    set -l user (whoami | string upper)
    set_color -o cyan
    figlet "$user" 2>/dev/null
    set_color normal
end
