# ══════════════════════════════════════════════════════════════
# __fish_default_command_not_found_handler
# Displays error + did-you-mean suggestions for unknown commands
# ══════════════════════════════════════════════════════════════

function fish_command_not_found --on-event fish_command_not_found --description 'Display error + did-you-mean suggestions for unknown commands'
    set -l cmd "$argv[1]"

    # ── MacTahoe custom functions ──
    set -l our_funcs c calc cat clean cleanreset extract fish_greeting func getdata hollywood l matrix mkgif myip n p passgen qr refresh stats stayawake testdrive v weather

    # ── Get similar commands via Python difflib ──
    set -l suggestions ""
    if command -v python3 >/dev/null 2>&1
        set suggestions (python3 -c "
import sys, difflib, os

cmd = sys.argv[1]

# Start with our functions
known = ['c','calc','cat','clean','cleanreset','extract','fish_greeting','func',
         'getdata','hollywood','l','matrix','mkgif','myip','n','p','passgen',
         'qr','refresh','stats','stayawake','testdrive','v','weather']

# Add common Linux commands
common = ['ls','cd','pwd','cat','grep','find','less','more','head','tail',
          'echo','printf','touch','mkdir','rm','cp','mv','chmod','chown',
          'sudo','apt','dnf','yum','pacman','flatpak','snap','pip','npm',
          'git','vim','nano','emacs','code','nvim','fish','bash','zsh',
          'python','python3','node','gcc','g++','make','cmake','cargo',
          'systemctl','journalctl','service','ps','top','htop','btop',
          'df','du','free','uname','neofetch','fastfetch','screenfetch',
          'ip','ifconfig','ping','curl','wget','ssh','scp','rsync',
          'tar','gzip','gunzip','zip','unzip','xz','bzip2',
          'date','cal','bc','expr','seq','sort','uniq','wc','tee']
known += common

# Deduplicate while preserving order
seen = set()
unique = []
for k in known:
    if k not in seen:
        seen.add(k)
        unique.append(k)

matches = difflib.get_close_matches(cmd, unique, n=4, cutoff=0.35)
for m in matches:
    print(m)
" "$cmd" 2>/dev/null)
    end

    # ── Display error message ──
    echo -e "\033[1;31m✘ Command not found: '$cmd'\033[0m" >&2

    # ── Custom hints for common mistypes (skip generic suggestions) ──
    switch "$cmd"
        case connect
            echo -e "  \033[1;33mDid you mean \033[1;36msmb connect\033[1;33m?\033[0m" >&2
            echo -e "  \033[38;5;248m  Use \033[1;36msmb connect --scan\033[38;5;248m to auto-detect SMB servers.\033[0m" >&2
            echo -e "  \033[38;5;248m  Type \033[1;36mfunc\033[38;5;248m to see all available MacTahoe functions.\033[0m" >&2
            return 0
        case scan
            echo -e "  \033[1;33mDid you mean \033[1;36msmb connect --scan\033[1;33m?\033[0m" >&2
            echo -e "  \033[38;5;248m  Use \033[1;36msmb connect --scan\033[38;5;248m to auto-detect SMB servers.\033[0m" >&2
            echo -e "  \033[38;5;248m  Type \033[1;36mfunc\033[38;5;248m to see all available MacTahoe functions.\033[0m" >&2
            return 0
    end

    # ── Show suggestions ──
    if set -q suggestions[1]
        echo -e "  \033[1;33mDid you mean...\033[0m" >&2
        for s in $suggestions
            set -l is_ours 0
            for f in $our_funcs
                if test "$f" = "$s"
                    set is_ours 1
                    break
                end
            end
            if test "$is_ours" = 1
                echo -e "    \033[1;36m$s\033[0m  \033[38;5;248m(MacTahoe function)\033[0m" >&2
            else
                echo -e "    \033[1;33m$s\033[0m" >&2
            end
        end
    else
        echo -e "  \033[38;5;248m  No similar commands found.\033[0m" >&2
    end

    # ── Common command corrections ──
    if test -d "$cmd"
        echo -e "  \033[38;5;248m  Note: '$cmd' is a directory. Use \033[1;36mls $cmd\033[38;5;248m or \033[1;36mcd $cmd\033[38;5;248m to access it.\033[0m" >&2
    else if test -f "$cmd"
        echo -e "  \033[38;5;248m  Note: '$cmd' is a file. Use \033[1;36mcat $cmd\033[38;5;248m or \033[1;36mp $cmd\033[38;5;248m to view it.\033[0m" >&2
    end

    # ── Footer: remind them about our functions ──
    echo -e "  \033[38;5;248m  Type \033[1;36mfunc\033[38;5;248m to see all available MacTahoe functions.\033[0m" >&2

    return 0
end
