if status is-interactive

    # Commands to run in interactive sessions can go here

end

if status is-interactive

    fastfetch

end

# ── Override unknown-command handler with funny errors + did-you-mean ──
if test -f ~/.config/fish/functions/__fish_default_command_not_found_handler.fish
    source ~/.config/fish/functions/__fish_default_command_not_found_handler.fish
end

starship init fish | source
set -gx TERMINAL kitty
set -gx TERM kitty
set -gx ANI_CLI_PLAYER vlc

