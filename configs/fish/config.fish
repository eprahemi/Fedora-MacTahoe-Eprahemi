if status is-interactive

    # Commands to run in interactive sessions can go here

end

if status is-interactive

    fastfetch

end

starship init fish | source
set -gx TERMINAL kitty
set -gx TERM kitty
set -gx ANI_CLI_PLAYER vlc

