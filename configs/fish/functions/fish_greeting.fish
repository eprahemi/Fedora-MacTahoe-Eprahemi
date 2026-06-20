# ══════════════════════════════════════════════════════════════
# fish_greeting 👋 — EPRAHEMI INC. 🏢 Greetings programs!
# Eprahemi welcomes you to the best shell (no cap) 🐟
# Fedora MacTahoe Eprahemi Edition © 2026 — hello world fr
# ══════════════════════════════════════════════════════════════
function fish_greeting --description 'Greeting: figlet user art'
    set -l user (whoami | string upper)
    set_color -o cyan
    figlet "$user" 2>/dev/null
    set_color normal
end
