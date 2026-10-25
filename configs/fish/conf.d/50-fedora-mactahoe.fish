# Fedora MacTahoe — project Fish settings.
#
# fish sources this file automatically, before ~/.config/fish/config.fish.
# Your aliases, environment variables, functions and startup commands belong
# in config.fish (or another conf.d file). The installer never writes
# config.fish, so everything you put there survives every install and update.

if status is-interactive
    fastfetch
end

# ── Override unknown-command handler with did-you-mean ──
if test -f ~/.config/fish/functions/__fish_default_command_not_found_handler.fish
    source ~/.config/fish/functions/__fish_default_command_not_found_handler.fish
end

starship init fish | source
set -gx TERMINAL kitty
set -gx TERM kitty
set -gx ANI_CLI_PLAYER vlc

# ── Privacy: kitty control sockets are created 0755 in /tmp — tighten to user-only ──
# Runs on every fish start, so any new kitty socket is locked down within ms.
find /tmp -maxdepth 1 -type s -name 'kitty-*' -user $USER -exec chmod 600 {} + 2>/dev/null
