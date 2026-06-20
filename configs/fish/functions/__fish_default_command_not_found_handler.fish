# ══════════════════════════════════════════════════════════════
# __fish_default_command_not_found_handler 🚫 — EPRAHEMI INC. 🏢
# You typed something dumb, and NOW what? 🤨
# Fedora MacTahoe Eprahemi Edition © 2026 — skill issue fr
# ══════════════════════════════════════════════════════════════

function fish_command_not_found --on-event fish_command_not_found --description '🚫 Replace: funny errors + did-you-mean for unknown commands'
    set -l cmd "$argv[1]"

    # ── Pool of 40 funny reactions (rotating humiliation per attempt) ──
    set -l insults
    set insults[1]  "BRUH WHAT EVEN IS '$cmd'??? 💀 That ain't a thing bestie."
    set insults[2]  "GIRL WHO TAUGHT YOU TO TYPE? '$cmd' ain't real and it never was 💅"
    set insults[3]  "'$cmd'??? Are you ok bestie? Do we need to call someone? 🚑"
    set insults[4]  "ERROR 404: '$cmd' not found (and honestly? good riddance) 🗑️"
    set insults[5]  "SIR THIS IS A WENDY'S... there's no '$cmd' here 🍔"
    set insults[6]  "'$cmd' is NOT a command. You are NOT a developer. Sit down. 🪑"
    set insults[7]  "I DO NOT KNOW '$cmd' AND AT THIS POINT I'M AFRAID TO ASK 👁️👄👁️"
    set insults[8]  "You typed '$cmd'. My disappointment is immeasurable. 📉"
    set insults[9]  "AIYO '$cmd'?! Your terminal is crying rn bestie 😭"
    set insults[10] "Skill issue. '$cmd' doesn't exist. Try again but better. 🎮"
    set insults[11] "'$cmd'? Never heard of her. And I don't WANNA hear of her. 🙉"
    set insults[12] "Computer says no. '$cmd' is not in the database. 🤖🇬🇧"
    set insults[13] "You had ONE job and you typed '$cmd'. Unreal. 😤"
    set insults[14] "'$cmd' is about as real as my will to live rn 🥲"
    set insults[15] "I'm not saying '$cmd' is fake but... actually that IS what I'm saying. FAKE. 🚨"
    set insults[16] "ERROR: '$cmd' — maybe lay off the keyboard bestie? 🥴"
    set insults[17] "Hold on I'm consulting the spirits... and they say '$cmd' is NOT IT 🔮"
    set insults[18] "'$cmd'??? In THIS economy??? 📉📈📉"
    set insults[19] "The council has voted: '$cmd' is not a command. 24-0. No appeals. ⚖️"
    set insults[20] "I would explain why '$cmd' doesn't work but I don't have that kind of time 💁"
    set insults[21] "'$cmd' walked into the wrong neighborhood and got COOKED 🍳"
    set insults[22] "Fatal error: '$cmd' is trash 🔥 Accept it bestie."
    set insults[23] "Bestie. BESTIE. '$cmd'? We need to talk. 🫤"
    set insults[24] "I ran a background check on '$cmd' and it came back: NOT FOUND. Classic. 🕵️"
    set insults[25] "McDonald's ice cream machine works more than '$cmd' 🍦"
    set insults[26] "'$cmd' is not a command. It's a cry for help. 📞"
    set insults[27] "You really typed '$cmd' and thought you ATE that? No. 💀"
    set insults[28] "The matrix crashed because of '$cmd'. Thanks. 💻"
    set insults[29] "Error 418: I'm a teapot and even I know '$cmd' ain't real 🫖"
    set insults[30] "'$cmd' didn't pass the vibe check. Not even close. ❌"
    set insults[31] "I checked 3 times. '$cmd' doesn't exist. It's giving delulu. 🎀"
    set insults[32] "BZZT! Wrong! '$cmd' is incorrect! Thanks for playing! 🎮💥"
    set insults[33] "Privilege Error: '$cmd' requires a brain which you apparently lack 🧠"
    set insults[34] "You typed '$cmd'. I'm not mad, I'm just disappointed. (Jk, I'm mad) 😡"
    set insults[35] "'$cmd' is the reason we can't have nice things bestie 🙃"
    set insults[36] "Bestie that's NOT a command. That's a war crime. Stop. 🛑"
    set insults[37] "Terminal says: '$cmd' who? Never met her. And I don't want to. 🚫"
    set insults[38] "'$cmd'? More like '$cmd'-n't. Got em! 🔥"
    set insults[39] "You're typing '$cmd' and I'm losing braincells. Please stop. 🧠💀"
    set insults[40] "The ghost of UNIX past is weeping because of '$cmd' 👻"

    # ── Our 24 MacTahoe custom functions ──
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

    # ── Pick a random insult ──
    set -l idx (random 1 40)
    echo -e "\033[1;31m✘ $insults[$idx]\033[0m" >&2

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
        echo -e "  \033[38;5;248m  No similar commands found bestie you're on your own 🫡\033[0m" >&2
    end

    # ── Extra brainrot for common mistakes ──
    if test -d "$cmd"
        echo -e "  \033[38;5;248m  PS that's a DIRECTORY not a command. Use \033[1;36mls $cmd\033[38;5;248m or \033[1;36mcd $cmd\033[38;5;248m smh 📁\033[0m" >&2
    else if test -f "$cmd"
        echo -e "  \033[38;5;248m  PS that's a FILE not a command. Use \033[1;36mcat $cmd\033[38;5;248m or \033[1;36mp $cmd\033[38;5;248m to check it 📄\033[0m" >&2
    end

    # ── Footer: remind them about our functions ──
    echo -e "  \033[38;5;248m  Type \033[1;36mfunc\033[38;5;248m to see all 24 MacTahoe functions bestie 📦\033[0m" >&2

    return 0
end
