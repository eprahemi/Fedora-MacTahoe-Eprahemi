function passgen --description 'Generate passwords or analyze a password\'s strength'
    set -l length 16
    set -l use_lower yes
    set -l use_upper yes
    set -l use_digits yes
    set -l use_punct yes
    set -l copy_clip no
    set -l count 1
    set -l analyze_mode no
    set -l analyze_password ""
    set -l passphrase_mode no
    set -l word_count 4
    set -l pwned_check no
    set -l save_label ""
    set -l get_label ""
    set -l force_mode no

    # ── Parse arguments ──
    while set -q argv[1]
        switch $argv[1]
            case --length -l
                set length $argv[2]
                set -e argv[1..2]
            case --no-lower
                set use_lower no
                set -e argv[1]
            case --no-upper
                set use_upper no
                set -e argv[1]
            case --no-digits
                set use_digits no
                set -e argv[1]
            case --no-symbols -s
                set use_punct no
                set -e argv[1]
            case --clip -c
                set copy_clip yes
                set -e argv[1]
            case --count -n
                set count $argv[2]
                set -e argv[1..2]
            case --passphrase -P
                set passphrase_mode yes
                set -e argv[1]
            case --words -w
                set word_count $argv[2]
                set passphrase_mode yes
                set -e argv[1..2]
            case --pwned
                set pwned_check yes
                set -e argv[1]
            case --save
                set save_label $argv[2]
                set -e argv[1..2]
            case --get
                set get_label $argv[2]
                set -e argv[1..2]
            case --force -f
                set force_mode yes
                set -e argv[1]
            case --list
                __passgen_vault_list
                return 0
            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mpassgen [options]\033[0m"
                echo -e "  \033[38;5;248m<number>\033[0m           \033[1;37mPassword length preset\033[0m"
                echo -e "  \033[38;5;248m<password>\033[0m         \033[1;37mAnalyze a password\'s strength\033[0m"
                echo -e "  \033[38;5;248m--length, -l N\033[0m     \033[1;37mPassword length (default: 16)\033[0m"
                echo -e "  \033[38;5;248m--count, -n N\033[0m      \033[1;37mNumber of passwords (default: 1)\033[0m"
                echo -e "  \033[38;5;248m--passphrase, -P\033[0m   \033[1;37mGenerate a passphrase (words)\033[0m"
                echo -e "  \033[38;5;248m--words, -w N\033[0m      \033[1;37mNumber of words for passphrase (default: 4)\033[0m"
                echo -e "  \033[38;5;248m--force, -f\033[0m        \033[1;37mOverride max-length limit\033[0m"
                echo -e "  \033[38;5;248m--no-lower\033[0m         \033[1;37mExclude lowercase letters\033[0m"
                echo -e "  \033[38;5;248m--no-upper\033[0m         \033[1;37mExclude uppercase letters\033[0m"
                echo -e "  \033[38;5;248m--no-digits\033[0m        \033[1;37mExclude digits\033[0m"
                echo -e "  \033[38;5;248m--no-symbols, -s\033[0m   \033[1;37mExclude symbols\033[0m"
                echo -e "  \033[38;5;248m--clip, -c\033[0m         \033[1;37mCopy to clipboard\033[0m"
                echo -e "  \033[38;5;248m--pwned\033[0m            \033[1;37mCheck password against known breaches\033[0m"
                echo -e "  \033[38;5;248m--save <label>\033[0m     \033[1;37mSave a password to encrypted vault\033[0m"
                echo -e "  \033[38;5;248m--get <label>\033[0m      \033[1;37mRetrieve a password from vault\033[0m"
                echo -e "  \033[38;5;248m--list\033[0m             \033[1;37mList saved vault entries\033[0m"
                echo -e "\n  \033[1;36mPresets:\033[0m \033[1;33m16\033[0m \033[1;33m32\033[0m \033[1;33m48\033[0m \033[1;33m64\033[0m \033[1;33m96\033[0m \033[1;33m104\033[0m"
                echo -e "  \033[38;5;248mExamples:\033[0m"
                echo -e "    \033[1;36mpassgen\033[0m               \033[1;37mGenerate a 16-char password\033[0m"
                echo -e "    \033[1;36mpassgen 32\033[0m            \033[1;37mGenerate a 32-char password\033[0m"
                echo -e "    \033[1;36mpassgen -P\033[0m            \033[1;37mGenerate a 4-word passphrase\033[0m"
                echo -e "    \033[1;36mpassgen -P -w 6\033[0m       \033[1;37mGenerate a 6-word passphrase\033[0m"
                echo -e "    \033[1;36mpassgen -f 100000\033[0m     \033[1;37mFORCE 100k-char (dare you)\033[0m"
                echo -e "    \033[1;36mpassgen mypassword123\033[0m  \033[1;37mAnalyze password strength\033[0m"
                echo -e "    \033[1;36mpassgen mypassword123 --pwned\033[0m \033[1;37mAnalyze + check breaches\033[0m"
                echo -e "    \033[1;36mpassgen --save email\033[0m  \033[1;37mSave last password as 'email'\033[0m"
                echo -e "    \033[1;36mpassgen --get email\033[0m   \033[1;37mRetrieve 'email' password\033[0m"
                return 0
            case '*'
                if string match -qr '^\d+$' "$argv[1]"
                    set length $argv[1]
                    set -e argv[1]
                else
                    set analyze_mode yes
                    set analyze_password "$argv[1]"
                    set -e argv[1]
                end
        end
    end

    # ── Sanity check: no one needs a 100k-char password ──
    if test "$length" -gt 99999
        if test "$force_mode" = yes
            echo -e "  \033[1;33m🔥 FORCE MODE ACTIVATED! You asked for it fam...\033[0m"
            echo -e "  \033[38;5;248m  Generating \033[1;33m$length\033[38;5;248m characters... hope you got RAM for days 💀\033[0m"
        else
            echo -e "\033[1;31m✘ CALM DOWN FELLA! \033[1;33m$length\033[1;31m-character password?!\033[0m"
            echo -e "  \033[38;5;248m  We ain't got that kinda server speed, this ain't NASA 🚀\033[0m"
            echo -e "  \033[38;5;248m  Before your computer crash and bluescreen:\033[0m"
            echo -e "  \033[38;5;248m  Max is \033[1;33m99,999\033[38;5;248m. Pick something smaller, sigma. ✋😤\033[0m"
            echo -e "  \033[38;5;248m  OR if you REALLY wanna destroy your PC: \033[1;36mpassgen -f $length\033[0m"
            echo -e "  \033[38;5;248m  Usage: \033[1;36mpassgen --help\033[0m"
            return 1
        end
    end

    # ── MEME NUMBER DATA CENTER 🎰 ──
    # If you think of another one, add it bestie. This is a NO JUDGEMENT ZONE.
    switch $length
        case 7
            echo -e "  \033[1;35m🎰 7 7 7 — JACKPOT LINE! Somebody hit the slots fr fr\033[0m"
        case 11
            echo -e "  \033[1;33m🔊 THIS ONE GOES TO 11! \033[38;5;248mSpinal Tap would be proud 🎸\033[0m"
        case 13
            echo -e "  \033[1;31m🍀 13... unlucky? OR IS IT? \033[38;5;248mFriday the 13th vibes bestie 👻\033[0m"
        case 21
            echo -e "  \033[1;32m🃏 21! BLACKJACK! \033[38;5;248mDealer hits? Dealer stays? We stay WINNING 💰\033[0m"
        case 42
            echo -e "  \033[1;36m🌌 42 — The Answer to the Ultimate Question of Life, the Universe, and Everything\033[0m"
            echo -e "  \033[38;5;248m  Douglas Adams would be proud. Don't forget your towel 🧖\033[0m"
        case 67
            echo -e "  \033[1;33m67?! 67!! DANGEROUS ITCHY NUMBER FELLA!\033[0m"
            echo -e "  \033[38;5;248m  67 67 67 67 67... just kidding (or am I?) 👀\033[0m"
        case 69
            echo -e "  \033[1;35m( ͡° ͜ʖ ͡°) nice... you typed 69... hehehe\033[0m"
            echo -e "  \033[38;5;248m  ayo what you planning with that length bestie? 🤨\033[0m"
        case 88
            echo -e "  \033[1;31m🧧 88! DOUBLE HAPPINESS! \033[38;5;248mChinese lucky number gang rise up 🐉\033[0m"
        case 99
            echo -e "  \033[1;33m🎵 99 PROBLEMS BUT A PASSWORD AIN'T ONE! \033[38;5;248mJay-Z nodded 🎤\033[0m"
        case 100
            echo -e "  \033[1;33m💯 100! PERFECT SCORE ENERGY! \033[38;5;248mNo cap, you're literally HIM 🔥\033[0m"
        case 101
            echo -e "  \033[1;36m🐕 101 Dalmatians! \033[38;5;248mCruella de Vil could never 💅\033[0m"
        case 111
            echo -e "  \033[1;33m🔮 111 — ANGEL NUMBER! \033[38;5;248mThe universe is telling you something bestie ✨\033[0m"
        case 222
            echo -e "  \033[1;34m🌊 222 — BALANCE & HARMONY... \033[38;5;248mor just a cool number idk 🤷\033[0m"
        case 333
            echo -e "  \033[1;35m👁️ 333 — ASCENDED MASTERS WATCHING... \033[38;5;248mor maybe it's just schizophrenia 💀\033[0m"
        case 404
            echo -e "  \033[1;31m🚫 404 — PASSWORD NOT FOUND! \033[38;5;248mError 418: I'm a teapot (jk)\033[0m"
        case 420
            echo -e "  \033[1;32m🌿 420 blaze it! Someone's feeling relaxed today 🚬\033[0m"
            echo -e "  \033[38;5;248m  Remember: with great power comes great responsibility (and munchies) 🍕\033[0m"
        case 500
            echo -e "  \033[1;31m💀 500 — INTERNAL SERVER ERROR! \033[38;5;248mYour PC is having an existential crisis\033[0m"
        case 666
            echo -e "  \033[1;31m😈 666... THE NUMBER OF THE BEAST! \033[1;33mRIP your GPU\033[0m"
            echo -e "  \033[38;5;248m  \\m/ (>.<) \\m/  \033[0m"
        case 777
            echo -e "  \033[1;33m🍀 777 LUCKY STREAK! Hit the jackpot with this one!\033[0m"
            echo -e "  \033[38;5;248m  Vegas called, they want their number back 🎰\033[0m"
        case 800
            echo -e "  \033[1;35m📞 800 — TOLL FREE BABY! \033[38;5;248mCall me maybe? 📱\033[0m"
        case 888
            echo -e "  \033[1;31m🧧🧧 888! TRIPLE LUCK! \033[38;5;248mIn Chinese this means 'fa fa fa' = GET RICH 💰\033[0m"
        case 911
            echo -e "  \033[1;31m🚨 911 — EMERGENCY! \033[38;5;248mWhat did you do bestie? I'm not snitching but... 👀\033[0m"
        case 999
            echo -e "  \033[1;33m🌟 999 — COMPLETION! \033[38;5;248mOne chapter ends, another begins. Deep bestie hours 🧘\033[0m"
        case 1001
            echo -e "  \033[1;35m📖 1001 Arabian Nights! \033[38;5;248mScheherazade could never generate this password fr 🧞\033[0m"
        case 1337
            echo -e "  \033[1;32m👾 1337 — LEET SPEAK! \033[38;5;248my0u'r3 4 r34l h4ck3r n0w b35713 💻\033[0m"
        case 4200
            echo -e "  \033[1;32m🌿🌿 4200 — BLAZE IT TWICE! \033[38;5;248mDouble the weed, double the speed 🚬🚬\033[0m"
        case 8008
            echo -e "  \033[1;35m🫣 8008... hehe you typed BOOB \033[38;5;248mgrow up bestie (but same lol) 💀\033[0m"
        case 8675309
            echo -e "  \033[1;33m🎵 867-5309! JENNY DON'T CHANGE YOUR NUMBER! \033[38;5;248mTommy Tutone gang 🎸\033[0m"
    end

    # ── PASSWORD MANAGER: --save ──
    if test -n "$save_label"
        __passgen_vault_save "$save_label"
        return 0
    end

    # ── PASSWORD MANAGER: --get ──
    if test -n "$get_label"
        __passgen_vault_get "$get_label"
        return 0
    end

    # ── ANALYSIS MODE ──
    if test "$analyze_mode" = yes
        set -l pw "$analyze_password"
        set -l pw_len (string length "$pw")

        set -l counts (python3 -c "
import sys
pw = sys.argv[1]
upper = sum(1 for c in pw if c.isupper())
lower = sum(1 for c in pw if c.islower())
digit = sum(1 for c in pw if c.isdigit())
symbol = len(pw) - upper - lower - digit
print(upper)
print(lower)
print(digit)
print(symbol)
" "$pw" 2>/dev/null)
        set -l upper_count $counts[1]
        set -l lower_count $counts[2]
        set -l digit_count $counts[3]
        set -l symbol_count $counts[4]

        set -l pool 0
        test "$upper_count" -gt 0; and set pool (math "$pool + 26")
        test "$lower_count" -gt 0; and set pool (math "$pool + 26")
        test "$digit_count" -gt 0; and set pool (math "$pool + 10")
        test "$symbol_count" -gt 0; and set pool (math "$pool + 32")

        set -l entropy 0
        if test "$pool" -gt 0
            set entropy (math "floor( $pw_len * ( ln($pool) / ln(2) ) )" 2>/dev/null)
        end

        # ── Score ──
        set -l score (__passgen_score $entropy $pw_len $upper_count $lower_count $digit_count $symbol_count "$pw")

        # ── Banner ──
        echo -e "\033[1;36m"
        echo "  ██████╗  █████╗ ███████╗███████╗ ██████╗ ███████╗███╗   ██╗"
        echo "  ██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝ ██╔════╝████╗  ██║"
        echo "  ██████╔╝███████║███████╗███████╗██║  ███╗█████╗  ██╔██╗ ██║"
        echo "  ██╔═══╝ ██╔══██║╚════██║╚════██║██║   ██║██╔══╝  ██║╚██╗██║"
        echo "  ██║     ██║  ██║███████║███████║╚██████╔╝███████╗██║ ╚████║"
        echo "  ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝"
        echo -e "\033[38;5;248m┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄\033[0m"
        printf "  \033[1;33m🔎 PASSWORD ANALYSIS\033[0m\n\n"

        echo -e "  \033[1;37mPassword:\033[0m  \033[1;33m$pw\033[0m"
        echo -e "  \033[1;37mLength:  \033[1;33m$pw_len\033[0m \033[1;37mchars\033[0m"

        # Score badge
        __passgen_show_score $score

        # Composition bar
        echo -e "\n  \033[1;37m📊 CHARACTER COMPOSITION\033[0m"
        if test "$pw_len" -gt 0
            set -l bar_w 30
            printf "  \033[1;31mUppercase: \033[1;33m%3d\033[0m  %s\n" $upper_count (string repeat -n (math "max(1, round( $upper_count * $bar_w / $pw_len ))") "█")
            printf "  \033[1;32mLowercase: \033[1;33m%3d\033[0m  %s\n" $lower_count (string repeat -n (math "max(1, round( $lower_count * $bar_w / $pw_len ))") "█")
            printf "  \033[1;34mDigits:    \033[1;33m%3d\033[0m  %s\n" $digit_count (string repeat -n (math "max(1, round( $digit_count * $bar_w / $pw_len ))") "█")
            printf "  \033[1;35mSymbols:   \033[1;33m%3d\033[0m  %s\n" $symbol_count (string repeat -n (math "max(1, round( $symbol_count * $bar_w / $pw_len ))") "█")
        end

        # Crack time
        if test "$entropy" -gt 0
            __passgen_cracktime $entropy
        end

        # ── PWNED CHECK ──
        if test "$pwned_check" = yes
            __passgen_pwned "$pw" $pw_len
        end

        # ── Generate secure replacement ──
        set -l new_len $pw_len
        if test (math "$pw_len * 2") -lt 20
            set new_len 20
        else
            set new_len (math "floor($pw_len * 1.8)")
        end
        set -l new_pw (python3 -c '
import secrets, string, sys

pw = sys.argv[1]
pw_len = len(pw)
target = max(int(pw_len * 1.8), 20)

has_upper = any(c.isupper() for c in pw)
has_lower = any(c.islower() for c in pw)
has_digit = any(c.isdigit() for c in pw)
has_sym   = any(c in "!@#$%^&*()_-+=<>?" for c in pw)
all_chars = string.ascii_letters + string.digits + "!@#$%^&*()_-+=<>?"

core = list(pw)
for i in range(len(core)):
    ch = core[i]
    if not has_upper and ch.islower() and secrets.randbelow(3) == 0:
        core[i] = ch.upper()
        has_upper = True
    elif not has_digit and ch.isalpha() and secrets.randbelow(3) == 0:
        core[i] = secrets.choice(string.digits)
        has_digit = True
    elif not has_sym and ch.isalnum() and secrets.randbelow(3) == 0:
        core[i] = secrets.choice("!@#$%^&*()_-+=<>?")
        has_sym = True

if not has_upper:
    core.insert(secrets.randbelow(len(core)+1), secrets.choice(string.ascii_uppercase))
if not has_lower:
    core.insert(secrets.randbelow(len(core)+1), secrets.choice(string.ascii_lowercase))
if not has_digit:
    core.insert(secrets.randbelow(len(core)+1), secrets.choice(string.digits))
if not has_sym:
    core.insert(secrets.randbelow(len(core)+1), secrets.choice("!@#$%^&*()_-+=<>?"))

core_str = "".join(core)
need = target - len(core_str)
if need > 0:
    prefix_len = secrets.randbelow(need + 1)
    suffix_len = need - prefix_len
else:
    prefix_len = suffix_len = 0
prefix = "".join(secrets.choice(all_chars) for _ in range(prefix_len))
suffix = "".join(secrets.choice(all_chars) for _ in range(suffix_len))
print(prefix + core_str + suffix)
' "$pw" 2>/dev/null)

        set -l new_pool_size 82
        set -l new_entropy (math "floor( $new_len * ( ln($new_pool_size) / ln(2) ) )" 2>/dev/null)
        set -l new_score (__passgen_score $new_entropy $new_len 1 1 1 1 "")

        # ── PASSWORD UPGRADE COMPARISON ──
        echo -e "\n  \033[1;37m💡 PASSWORD UPGRADE\033[0m"
        echo -e "  \033[38;5;248m┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄\033[0m"
        printf "  \033[1;37mYour password:\033[0m      \033[1;33m%s\033[0m\n" "$pw"
        __passgen_show_score $score
        set -l old_fastest (python3 -c "
import sys
e = $entropy
if e <= 0: print('instantly'); sys.exit(0)
g = 2 ** (e - 1)
rates = [('MD5', 10**11)]
for name, rate in rates:
    t = g // rate
    if t < 1: s = 'instantly'
    elif t < 60: s = f'{int(t)} second' + ('s' if int(t) != 1 else '')
    elif t < 3600: s = f'{int(t//60)} minute' + ('s' if int(t//60) != 1 else '')
    elif t < 86400: s = f'{int(t//3600)} hour' + ('s' if int(t//3600) != 1 else '')
    elif t < 31536000: s = f'{int(t//86400)} day' + ('s' if int(t//86400) != 1 else '')
    elif t < 3153600000: s = f'{int(t//31536000)} year' + ('s' if int(t//31536000) != 1 else '')
    elif t < 315360000000: s = f'{int(t//3153600000)} centur' + ('y' if int(t//3153600000) == 1 else 'ies')
    else: s = '∞ forever'
    print(s)
" 2>/dev/null)
        printf "  \033[38;5;248mCrack time (MD5):\033[0m  \033[1;31m%s\033[0m\n" "$old_fastest"

        echo -e "\n  \033[38;5;248m                      ⬇\033[0m\n"

        printf "  \033[1;37mEdited with secure:\033[0m \033[1;32m%s\033[0m\n" "$new_pw"
        __passgen_show_score $new_score
        set -l new_fastest (python3 -c "
import sys
e = $new_entropy
if e <= 0: print('instantly'); sys.exit(0)
g = 2 ** (e - 1)
rates = [('MD5', 10**11)]
for name, rate in rates:
    t = g // rate
    if t < 1: s = 'instantly'
    elif t < 60: s = f'{int(t)} second' + ('s' if int(t) != 1 else '')
    elif t < 3600: s = f'{int(t//60)} minute' + ('s' if int(t//60) != 1 else '')
    elif t < 86400: s = f'{int(t//3600)} hour' + ('s' if int(t//3600) != 1 else '')
    elif t < 31536000: s = f'{int(t//86400)} day' + ('s' if int(t//86400) != 1 else '')
    elif t < 3153600000: s = f'{int(t//31536000)} year' + ('s' if int(t//31536000) != 1 else '')
    elif t < 315360000000: s = f'{int(t//3153600000)} centur' + ('y' if int(t//3153600000) == 1 else 'ies')
    else: s = '∞ forever'
    print(s)
" 2>/dev/null)
        printf "  \033[38;5;248mCrack time (MD5):\033[0m  \033[1;32m%s\033[0m\n" "$new_fastest"

        # Tips
        echo -e "\n  \033[1;37m💡 WHAT WE FIXED\033[0m"
        set -l tips 0
        if test "$pw_len" -lt 12
            set tips (math $tips + 1)
            echo -e "  \033[1;33m$tips.\033[0m \033[1;37mLength\033[0m — \033[38;5;248m$pw_len → $new_len chars (at least 12 recommended)\033[0m"
        end
        if test "$upper_count" -eq 0
            set tips (math $tips + 1)
            echo -e "  \033[1;33m$tips.\033[0m \033[1;37mUppercase\033[0m — \033[38;5;248madded A-Z\033[0m"
        end
        if test "$lower_count" -eq 0
            set tips (math $tips + 1)
            echo -e "  \033[1;33m$tips.\033[0m \033[1;37mLowercase\033[0m — \033[38;5;248madded a-z\033[0m"
        end
        if test "$digit_count" -eq 0
            set tips (math $tips + 1)
            echo -e "  \033[1;33m$tips.\033[0m \033[1;37mDigits\033[0m — \033[38;5;248madded 0-9\033[0m"
        end
        if test "$symbol_count" -eq 0
            set tips (math $tips + 1)
            echo -e "  \033[1;33m$tips.\033[0m \033[1;37mSymbols\033[0m — \033[38;5;248madded !@#\$%%^&*()_-+=<>?\033[0m"
        end
        if test "$pw_len" -ge 8
            and string match -qr '(.)\1{2,}' "$pw"
            set tips (math $tips + 1)
            echo -e "  \033[1;33m$tips.\033[0m \033[1;37mRepeats\033[0m — \033[38;5;248mremoved repeated character patterns\033[0m"
        end
        if string match -qr '^(password|123456|qwerty|letmein|admin|welcome)' (string lower "$pw")
            set tips (math $tips + 1)
            echo -e "  \033[1;33m$tips.\033[0m \033[1;37mCommon word\033[0m — \033[38;5;248mswitched to random characters\033[0m"
        end
        if test "$tips" -eq 0
            echo -e "  \033[1;32m  ✔ This password is already strong! \033[38;5;248mBut here's a secure version anyway:\033[0m"
        end

        return 0
    end

    # ── GENERATION MODE ──
    set -g pool_size 0
    set -g passwords
    set -g entropy 0
    if test "$passphrase_mode" = yes
        # ── Passphrase generation ──
        set -l passphrase (python3 -c '
import secrets, sys

words = """abandon ability able about above absent absorb abstract abuse
accident account accuse achieve acid acquire across act action actor
adapt add address adjust admit adult advance advice affair afford
afraid after again age agent agree ahead aid aim air airport
alarm album alert alien align alive all alley allow almost alone
along already also alter always amount analyze ancient angle animal
announce annual another answer antenna antique anxiety any apart
apology appear apple apply area argue arm army around arrange
arrest arrive arrow art article ask aspect assault assess asset
assist assume attack attempt attend attitude attract auction audit
aunt author auto autumn average avoid awake award aware baby
back bad bag balance ball banana band bank bar barely barrel
base basic basket battery beach bean bear beat beauty because
become before begin behave behind belief bell belong below belt
bench berry best better beyond bicycle big bike bill bind bird
birth bit bite bitter black blade blame blanket blast blaze bleed
blend bless blind block blood bloom blow blue board boast boat
body bold bolt bomb bond bone bonus book boost border bore
born borrow boss both bother bottle bottom bounce box boy brain
brand brass brave bread break breath breed brick bride bridge
brief bright bring broad broken brother brown brush bubble bucket
budget buffer build bulb bulk bullet bunch burden bureau burn
burst bus business busy butter button buy cabin cable cactus
cage cake call calm camera camp campaign cancel candle candy
cap capital captain capture carbon card care career carpet carry
case cash catch category cattle cause cave ceiling cell cement
center cereal certain chain chair chalk chance change channel
chaos chapter charge charm chart chase cheap check cheek cheese
chef cherry chest chicken chief child chimney chocolate choice
choose chronic chunk cigar circle citizen city civil claim clap
clarify clasp class clean clear clerk click client cliff climb
cling clinic clip clock clone close cloth cloud clue cluster
clutch coach coal coast coconut code coffee coil coin collect
colony color column combat combine come comfort comic commit
common company compare compel compete complex computer concept
concern condition conduct confirm congress connect consider control
convert coordinate copy corner correct costume cotton couch council
count country county couple course court cousin cover crack craft
crash crazy cream create credit crew crop cross crowd crucial
crystal cube culture cure curious current curtain curve custom
cute cycle dad damage damp dance danger dare dark dawn day deal
dear death debate debt decade decide decimal deep defeat defend
define degree delay deliver demand deny depart depend deposit
depress derive describe desert design desk despair despite destroy
detail detect develop device devote diamond diary dice diet differ
digital dignity dilemma dilute dimension dinner direct dirt disable
disaster disc discover discuss disease dish dismiss disorder
display dissolve distance distinct district divide dizzy doctor
document dollar domain donate door double doubt dove draft dragon
drama draw dream dress drift drill drink drip drive drop drug
drum dry duck dumb dump during dust duty dye dynamic eager eagle
early earn earth ease east easy eat echo ecology edge edit educate
effect effort egg either elastic elder election element elephant
elite else emerge emotion emperor emphasis empire employ empty
enable enclose encourage end enemy energy enforce engage engine
enhance enjoy enlist enormous enough enrich enroll ensure enter
entertain entire entry envelope episode equal equator equipment
era erase error erupt escape essay essence estate eternal ethical
ethnic evaluate even event ever every evidence evil evolve exact
example exceed excel exchange excite exclude excuse execute exercise
exhibit exist exit exotic expand expect expense expert explain
explicit exploit export expose extend extra extreme eye fabric
face facility fact factor factory faculty fade fail fair fake
fall false family famous fan fancy fantasy farm fashion fat fate
father fault favor feast feature federal fee feed feel female
fence festival fetch fever few fiber fiction field fierce fifteen
fight file fill film final finance find fine finger finish fire
firm first fiscal fish fit five fix flag flame flash flat flavor
flee flesh flight flip float flock flood floor flow flower fly
foam focus fog foil fold folk food fool foreign forest forever
forget form fortune forum forward fossil foster found fox fragile
frame frequent fresh friend fringe frog front frost frozen fruit
fuel fun function fund funny fury future gadget gain galaxy
gallery game gap garage garden garlic gas gate gather gauge gaze
gear gender gene general generate genius genre gentle genuine
gesture giant gift giggle ginger girl give glad glance glass
glide glimpse global globe glory glove glow glucose glue goal
gold golf good govern grab grace grade grain grand grant graph
grasp grass grave gravity great green grid grief grill grin grip
grocery ground group grow growth guard guess guest guide guilt
guitar gun gut gym habit hair half hall hammer hand handle
happen happy harbor hard harmony harvest hat hate have hazard
head health heart heavy hedge height hello help herb here hero
hidden high highlight hike hill hint hip hire history hit hobby
hold hole holiday home honey honor hook hope horizon horn horror
horse hospital host hotel hour house hover human humor hundred
hungry hunt hurdle hurry hurt husband hybrid icon idea identify
ignore illusion image imagine immune impact import impose improve
impulse include income increase index indicate industry infant
infinite inflate influence inform initial inject injury inmate
inner innocent input inquiry insect insert inside insight inspect
install instant instead intact integrate intense interact interest
internal internet interpret interval interview intimate invade
invest invite involve island isolate issue item jacket jail jam
jar jazz jealous jeans jelly jewel job join joke journey joy
judge juice jump jungle junior jury just justice keen keep key
kick kid kill kind king kitchen knee knife knock know label
labor lack ladder lady lake lamp land lane language laptop large
laser last late launch law lawn layer lazy lead leader leaf league
leak learn lease leave lecture left leg legal legend leisure
lemon lend length lesson letter level lever library license life
lift light like limb limit link lion liquid list little live
lizard load loan lobby local locate lock lodge logic lonely long
loop lord lose loss lost lot loud love lower loyal lucky luggage
lump lunch luxury machine mad magic magnet maid mail main major
make mammal manage mandate mango mansion manual maple marble
margin marine mark market marriage mask mass master match material
matter mature maximum mayor maze meal mean measure meat mechanic
media medium meet melody melt member memory mentor menu mercy
mere merge merit mesh message metal method middle might mild
mile milk million mind mineral minimum minor minute miracle mirror
missile mission mistake mix mixture mobile model modify moment
monitor monkey monster month moon moral more morning mortal most
mother motion motor mountain mouse mouth move movie much muscle
museum music mutual mystery myth naive name narrow nasty nation
native natural nature navy near neat necessary neck need negative
neighbor neither nerve nest network net neutral never new nice
night noble noise nominee noodle normal north nose notable note
nothing notice novel now nuclear number nurse nut oak object
observe obtain obvious occupy ocean odd offer office oil okay
old olive olympic omit once onion online open operate opinion
oppose option orange orbit order organ organic origin ornament
other outcome outlet outside oven overall owner oxygen pace pack
package pad page pain paint pair palace palm pan panel panic
paper parade parent park part party pass passage passion past
paste path patient pattern pause pave payment peace peak peanut
pear peasant peer penalty pencil people pepper perfect period
permit person pest pet phone photo phrase physical piano pick
picture piece pig pile pilot pin pink pioneer pipeline pistol
pitch pizza place planet plastic plate platform player pleasant
please pledge plenty plot plug plus pocket poem poet poetry point
polar pole police policy polish political pool popular population
portion portrait pose position positive possess possible post potato
potential poultry pound pour poverty powder power practice praise
pray preach precise predict prefer prepare present preserve press
pressure pretend prevent price pride primary print prior prison
privacy private prize probably problem process produce profit
program project promise promote proof property protect protein
protest proud prove provide province psyche public pull pulse
pump punch punish pupil purchase pure purple purpose purse push
put puzzle quality quantity quarter queen question quick quiet
quit quite quote race radical radio rail rain raise rally ranch
random range rapid rare rate rather ratio raw reach react read
ready real realm rebel receive recipe record recover recruit
reduce reflect reform region regret reject relate relax release
relief rely remain remedy remember remind remote remove render
rent repair repeat replace report represent republic request rescue
reserve reside resign resist resolve resort resource respond rest
restore result retire retreat return reveal revenue reverse review
revolution reward rhythm rice rich ride ridge rifle right rigid
ring riot rip ripe rise risk rival river road roast robe robot
robust rocket rod romance roof room root rope rose rotate rough
round route royal rubber rude rug ruin rule run rural rush rust
sabotage sack sacred sad safe safety salad salmon salt same sample
sand satisfy sauce save say scale scan scare scene schedule school
science scissors screen script sea search season seat second secret
section security seed seek segment select self sell seminar senior
sense serious serve service session settle setup seven severe
shade shadow shaft shake shallow shape share sharp shatter shed
sheet shelf shell shelter shield shift shine ship shirt shock
shoe shoot shop shore short shot should shoulder shout show shower
shrug shut side siege sight sign signal silence silk silly silver
similar simple since sing single sink sister site situation size
ski skill skin skip skirt skull sky slam slave sleep slice slide
slip slow small smart smell smile smoke smooth snack snake snap
snow soap soccer social sock soda soft solar soldier solid solution
solve someone song soon sorry sort soul sound source south space
spare speak special specific speech speed spell spend sphere spider
spill spin spirit split spoke sport spot spray spread spring squad
square stable stadium staff stage stain stair stake stale stamp
stand star stare start state statue status stay steady steak steal
steam steel step stick stiff still sting stock stomach stone stool
store storm story stove strange strategy stream street strength
stress stretch strike string strip stroke strong structure struggle
studio stuff stupid style subject submit substance succeed such
sudden suffer sugar suggest suit sum summer summit sun super supply
support suppose supreme sure surface surgery surprise surround
survey survive suspect sustain swallow swear sweep sweet swim swing
switch symbol symptom system table tablet tackle tactic tail talent
talk tank tape target task taste tax teach teacher team tech
temple tenant tend tennis tension tent term test text thank theme
theory therapy thick thin thing think third this thought thread
threat three throat through throw thumb ticket tide tight till
time tiny tip tire tissue title toast tobacco today toddler toe
together toilet token tolerance tomato tomorrow tone tongue tonight
tool tooth top topic torch tornado tortoise toss total touch tough
tour tourist toward towel tower town toy track trade tradition
traffic train transfer transform transit travel treat tree trend
trial tribe trick trigger trim trip trophy trouble truck true
truly trumpet trust truth try tube tulip tune tunnel turkey turn
turtle twelve twenty twice twin twist two type typical ugly ultra
umbrella unable unaware uncle uncover understand unit universe
unknown unlike unlock unusual update upgrade uphold upon upper
urban urge usage use used useful user utility vacation vacuum valid
valley valuable valve van vanish vapor variable vast vehicle velvet
vendor venture venue verb verify version veteran viable vibrant
victory victim video view village vintage violin virtual virus
visible vision visit visual vital vivid vocal voice volcano volume
vote voyage wage wagon wait walk wall want war warm warn warrior
wash waste watch water wave way wealth weapon wear weaver web
wedding weed week weekend weight welcome welfare well west wet
whale wheat wheel when where which while whisper white whole why
wide wife wild will win window wine wing winner winter wire wisdom
wise wish witness wolf woman wonder wood wool word work world
worry worth wrap wreck wrestle wrist write wrong yard year yellow
yes yesterday yield young youth zebra zero zone""".split()

def pick(n, sep, cap):
    chosen = [secrets.choice(words) for _ in range(n)]
    if cap:
        chosen = [w.capitalize() for w in chosen]
    return sep.join(chosen)

import argparse
sep = secrets.choice("-_!?@#$%&")
cap = secrets.randbelow(2) == 0
n = int(sys.argv[1]) if len(sys.argv) > 1 else 4
print(pick(n, sep, cap))
' $word_count 2>/dev/null)
        set passwords $passphrase
        set length (string length "$passphrase")
        # Calculate entropy for passphrase: log2(wordlist_size^word_count)
        # wordlist ~ 600 words ≈ 9.2 bits per word
        set entropy (math "floor( $word_count * ( ln(600) / ln(2) ) )" 2>/dev/null)
    else
        # ── Random password generation ──
        set -g chars ""
        test "$use_lower" = yes; and set chars "$chars"abcdefghijklmnopqrstuvwxyz
        test "$use_upper" = yes; and set chars "$chars"ABCDEFGHIJKLMNOPQRSTUVWXYZ
        test "$use_digits" = yes; and set chars "$chars"0123456789
        test "$use_punct" = yes; and set chars "$chars"'!@#$%^&*()_-+=<>?'

        if test (string length "$chars") -eq 0
            echo -e "\033[1;31m❌ No character types selected!\033[0m"
            return 1
        end

        set -g charlen (string length "$chars")

        set -g pool_size 0
        test "$use_lower" = yes; and set pool_size (math $pool_size + 26)
        test "$use_upper" = yes; and set pool_size (math $pool_size + 26)
        test "$use_digits" = yes; and set pool_size (math $pool_size + 10)
        test "$use_punct" = yes; and set pool_size (math $pool_size + 20)
        set -g entropy (math "floor( $length * ( ln($pool_size) / ln(2) ) )" 2>/dev/null)

        set -g passwords
        for p in (seq $count)
            set -l password ""
            for i in (seq $length)
                set -l idx (math (random) % $charlen + 1)
                set password "$password"(string sub -s $idx -l 1 "$chars")
            end
            set passwords $passwords $password
        end
    end

    # ── OUTPUT ──
    echo -e "\033[1;36m"
    echo "  ██████╗  █████╗ ███████╗███████╗ ██████╗ ███████╗███╗   ██╗"
    echo "  ██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝ ██╔════╝████╗  ██║"
    echo "  ██████╔╝███████║███████╗███████╗██║  ███╗█████╗  ██╔██╗ ██║"
    echo "  ██╔═══╝ ██╔══██║╚════██║╚════██║██║   ██║██╔══╝  ██║╚██╗██║"
    echo "  ██║     ██║  ██║███████║███████║╚██████╔╝███████╗██║ ╚████║"
    echo "  ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝"
    echo -e "\033[38;5;248m┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄\033[0m"
    if test "$passphrase_mode" = yes
        printf "  \033[1;37mWords: \033[1;33m%s\033[0m     \033[1;37mLength: \033[1;33m%s\033[0m\n" "$word_count" "$length"
    else
        printf "  \033[1;37mLength: \033[1;33m%s\033[0m     \033[1;37mCount: \033[1;33m%s\033[0m     \033[1;37mPool: \033[1;33m%s\033[0m\n" "$length" "$count" "$pool_size"
    end

    if test (count $passwords) -gt 1
        # ── Table output for bulk ──
        printf "  \033[1;30m%s\033[0m\n" "  #  Password                           Score  Crack (MD5)"
        for i in (seq (count $passwords))
            set -l pw_s $passwords[$i]
            set -l pw_score (__passgen_compute_score_for_pw "$pw_s")
            set -l pw_grade (string sub -l 1 "$pw_score")
            set -l pw_time (python3 -c "
import sys, math
# rough entropy: check char types present
pw = sys.argv[1]
l = len(pw)
p = 0
if any(c.isupper() for c in pw): p += 26
if any(c.islower() for c in pw): p += 26
if any(c.isdigit() for c in pw): p += 10
if any(c in '!@#\\\$%^&*()_-+=<>?' for c in pw): p += 32
if p == 0: print('?'); sys.exit(0)
e = int(l * (p**0.5))
g = 2 ** (max(e-1, 0))
t = g // 10**11
if t < 1: print('inst'); sys.exit(0)
if t < 60: print(f'{int(t)}s'); sys.exit(0)
if t < 3600: print(f'{int(t//60)}m'); sys.exit(0)
if t < 86400: print(f'{int(t//3600)}h'); sys.exit(0)
if t < 31536000: print(f'{int(t//86400)}d'); sys.exit(0)
if t < 3153600000: print(f'{int(t//31536000)}y'); sys.exit(0)
print('∞')
" "$pw_s" 2>/dev/null)
            printf "  \033[1;36m%2d\033[0m  \033[1;32m%-32s\033[0m \033[1;33m%s\033[0m  \033[38;5;248m%s\033[0m\n" $i "$pw_s" "$pw_score" "$pw_time"
        end
    else
        # ── Single password output ──
        printf "  \033[1;32m%s\033[0m\n" "$passwords[1]"
        # Show score for single
        set -l single_score (__passgen_score $entropy $length \
            (count (string match -ra '[A-Z]' "$passwords[1]") ) \
            (count (string match -ra '[a-z]' "$passwords[1]") ) \
            (count (string match -ra '[0-9]' "$passwords[1]") ) \
            (count (string match -ra '[^a-zA-Z0-9]' "$passwords[1]") ) \
            "$passwords[1]")
        __passgen_show_score $single_score
    end

    # Copy to clipboard
    if test "$copy_clip" = yes -a (count $passwords) -eq 1
        printf "%s" $passwords[1] | wl-copy 2>/dev/null
        if test $status -eq 0
            echo -e "\n  \033[1;36m📋 Copied to clipboard\033[0m"
        end
    else if test "$copy_clip" = yes
        printf "%s\n" $passwords | wl-copy 2>/dev/null
        if test $status -eq 0
            echo -e "\n  \033[1;36m📋 All passwords copied to clipboard\033[0m"
        end
    end

    # Crack time (single pw only)
    if test (count $passwords) -eq 1; and test -n "$entropy"
        __passgen_cracktime $entropy
    end
end

# ══════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════

# ── STRENGTH SCORE ──
function __passgen_score --description 'Calculate score 0-100 + grade from entropy and factors'
    set -l entropy $argv[1]
    set -l len $argv[2]
    set -l upper_c $argv[3]
    set -l lower_c $argv[4]
    set -l digit_c $argv[5]
    set -l symbol_c $argv[6]
    set -l pw $argv[7]

    # Base from entropy (entropy / 2.5 gives rough 0-80 range for up to 200 bits)
    set -l base 0
    if test "$entropy" -gt 0
        set base (math "min(80, round($entropy * 0.4))" 2>/dev/null)
    end

    # Diversity bonus (up to 15)
    set -l div_bonus 0
    if test "$upper_c" -gt 0; set div_bonus (math "$div_bonus + 4"); end
    if test "$lower_c" -gt 0; set div_bonus (math "$div_bonus + 3"); end
    if test "$digit_c" -gt 0; set div_bonus (math "$div_bonus + 4"); end
    if test "$symbol_c" -gt 0; set div_bonus (math "$div_bonus + 4"); end

    # Length bonus (up to 5)
    set -l len_bonus 0
    if test "$len" -ge 16; set len_bonus 5
    else if test "$len" -ge 12; set len_bonus 3
    else if test "$len" -ge 8; set len_bonus 1
    end

    # Penalties
    set -l penalty 0
    if test -n "$pw"
        # Repeated chars
        if string match -qr '(.)\1{2,}' "$pw"; set penalty (math "$penalty + 5"); end
        # Common passwords
        if string match -qr '^(password|123456|qwerty|letmein|admin|welcome)' (string lower "$pw")
            set penalty (math "$penalty + 20")
        end
    end

    set -l score (math "max(0, min(100, $base + $div_bonus + $len_bonus - $penalty))" 2>/dev/null)
    echo $score
end

function __passgen_show_score --description 'Display score badge with grade'
    set -l score $argv[1]
    if test "$score" -ge 90
        set grade "A+"
        set color "1;32m"
    else if test "$score" -ge 80
        set grade "A"
        set color "1;32m"
    else if test "$score" -ge 70
        set grade "B"
        set color "1;33m"
    else if test "$score" -ge 60
        set grade "C"
        set color "1;33m"
    else if test "$score" -ge 40
        set grade "D"
        set color "1;31m"
    else
        set grade "F"
        set color "1;31m"
    end

    # Build a 10-block progress bar
    set -l filled (math "max(1, round($score / 10))" 2>/dev/null)
    set -l empty (math "10 - $filled" 2>/dev/null)

    # Fun comment for special scores 🎰
    set -l fun ""
    switch $score
        case 0
            set fun "  \033[1;31m💀 literally 0... did you type 'password'?\033[0m"
        case 7
            set fun "  \033[1;35m🎰 Lucky 7! Slot machine energy!\033[0m"
        case 11
            set fun "  \033[1;33m🔊 This score goes to 11!\033[0m"
        case 13
            set fun "  \033[1;33m🍀 unlucky score? or lucky? who knows\033[0m"
        case 21
            set fun "  \033[1;32m🃏 21! BLACKJACK! Dealer busts!\033[0m"
        case 42
            set fun "  \033[1;36m🌌 Ultimate Answer score!\033[0m"
        case 67
            set fun "  \033[1;33m67?! DANGEROUS ITCHY SCORE FELLA!\033[0m"
        case 69
            set fun "  \033[1;35m( ͡° ͜ʖ ͡°) nice score bro\033[0m"
        case 88
            set fun "  \033[1;31m🧧 Double happiness score!\033[0m"
        case 99
            set fun "  \033[1;33m🎵 99 problems but the score ain't one!\033[0m"
        case 100
            set fun "  \033[1;33m🏆 PERFECT SCORE! YOU WIN PASSWORDS!\033[0m"
        case 101
            set fun "  \033[1;36m🐕 101 Dalmatians score! Cruella could never\033[0m"
        case 111
            set fun "  \033[1;33m🔮 Angel number score! ✨\033[0m"
        case 404
            set fun "  \033[1;31m🚫 Score not found! Error 404\033[0m"
        case 420
            set fun "  \033[1;32m🌿 Blaze it score!\033[0m"
        case 500
            set fun "  \033[1;31m💀 Internal Server Error score!\033[0m"
        case 666
            set fun "  \033[1;31m😈 Evil score! \\m/\033[0m"
        case 777
            set fun "  \033[1;33m🍀 Jackpot score! Lucky you!\033[0m"
        case 911
            set fun "  \033[1;31m🚨 Emergency! That score is fire!\033[0m"
        case 999
            set fun "  \033[1;33m🌟 Completionist score! \033[0m"
        case 1337
            set fun "  \033[1;32m👾 1337 — l33t h4x0r score!\033[0m"
    end

    printf "  \033[1;37mScore:\033[0m  \033[%s%3d/100 %s\033[0m  \033[38;5;248m[" $color $score $grade
    printf "\033[%s%s\033[38;5;248m" $color (string repeat -n $filled "█")
    if test "$empty" -gt 0
        printf "░"(string repeat -n (math "$empty - 1") "░")
    end
    printf "]\033[0m$fun\n"
end

# ── CRACK TIME ──
function __passgen_cracktime --description 'Display crack time estimates for given entropy'
    set -l entropy $argv[1]
    python3 -c '
import sys, math
e = int(sys.argv[1])
g = 2 ** (e - 1)
ESC = chr(27)
GRAY = f"{ESC}[38;5;248m"
BOLD = f"{ESC}[1;37m"
CYAN = f"{ESC}[1;36m"
RESET = f"{ESC}[0m"
sup = str.maketrans("0123456789", "⁰¹²³⁴⁵⁶⁷⁸⁹")
d = chr(0x2504)
print(f"\n  {BOLD}🔐 {CYAN}{e} bits{RESET}    {GRAY}(2{str(e).translate(sup)} possible combinations){RESET}")
print(f"  {GRAY}{d*45}{RESET}")
scenarios = [
    ("Online attack (throttled)",      1000),
    ("Argon2id / bcrypt (slow hash)",  1000),
    ("SHA256 (medium hash)",           10**9),
    ("MD5 / NTLM (fast GPU)",          10**11),
    ("Theoretical max (perfect)",      10**15),
]
def fmt(t):
    if t < 1: return "instantly"
    if t < 60: return f"{int(t)} second" + ("s" if int(t) != 1 else "")
    if t < 3600: m = int(t//60); return f"{m} minute" + ("s" if m != 1 else "")
    if t < 86400: h = int(t//3600); return f"{h} hour" + ("s" if h != 1 else "")
    if t < 31536000: d = int(t//86400); return f"{d} day" + ("s" if d != 1 else "")
    if t < 3153600000: y = int(t//31536000); return f"{y} year" + ("s" if y != 1 else "")
    if t < 315360000000: c = int(t//3153600000); return f"{c} centur" + ("y" if c == 1 else "ies")
    return "∞ forever"
for name, rate in scenarios:
    print(f"  {name:35s}  {fmt(g // rate)}")
' $entropy 2>/dev/null
end

# ── PWNED CHECK ──
function __passgen_pwned --description 'Check password against Have I Been Pwned API'
    set -l pw $argv[1]
    set -l pw_len $argv[2]

    # Check if curl is available
    if not command -v curl >/dev/null 2>&1
        echo -e "\n  \033[1;31m⚠ curl not installed — cannot check breach status\033[0m"
        return 1
    end

    echo -e "\n  \033[1;37m🔍 BREACH CHECK\033[0m"
    echo -e "  \033[38;5;248m┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄\033[0m"

    set -l sha1 (printf "%s" "$pw" | sha1sum | cut -d' ' -f1 | string upper)
    set -l prefix (string sub -l 5 "$sha1")
    set -l suffix (string sub -s 6 "$sha1")

    set -l response (curl -s "https://api.pwnedpasswords.com/range/$prefix" 2>/dev/null)
    if test $status -ne 0 -o -z "$response"
        echo -e "  \033[1;31m✘ Could not reach HIBP API (check your internet)\033[0m"
        return 1
    end

    # Search for our suffix in the response (format: SUFFIX:COUNT)
    # NOTE: $response is an array — must NOT quote it, so each line becomes a separate arg
    set -l match (printf "%s\n" $response | string match -r "^$suffix:(\d+)" 2>/dev/null)
    if test -n "$match"
        set -l count $match[2]
        if test -n "$count" -a "$count" -gt 0
            echo -e "  \033[1;31m⚠ This password has been \033[1;33m$count\033[1;31m times in known breaches!\033[0m"
            echo -e "  \033[38;5;248m  Do not use this password anywhere. Generate a new one.\033[0m"
        else
            echo -e "  \033[1;32m✔ Not found in known breaches\033[0m"
        end
    else
        echo -e "  \033[1;32m✔ Not found in known breaches\033[0m"
    end
end

# ── PASSWORD VAULT ──
function __passgen_vault_path
    printf "%s/.passgen_vault" "$HOME"
end

function __passgen_vault_save --description 'Save a password to encrypted vault'
    set -l label $argv[1]
    set -l vault (__passgen_vault_path)

    if not command -v openssl >/dev/null 2>&1
        echo -e "\033[1;31m❌ openssl is required for the vault\033[0m"
        return 1
    end

    # Read password (from clipboard or stdin)
    echo -e "\033[1;33mEnter the password to save (paste or type, then Enter):\033[0m"
    set -l pw (read -P "> ")
    if test -z "$pw"
        echo -e "\033[1;31m❌ No password entered\033[0m"
        return 1
    end

    echo -e "\033[1;33mEnter vault master password:\033[0m"
    set -l mp (read -s -P "> ")
    echo ""
    if test -z "$mp"
        echo -e "\033[1;31m❌ Master password cannot be empty\033[0m"
        return 1
    end

    # Decrypt existing vault if it exists, add entry, re-encrypt
    set -l entries ""
    if test -f "$vault"
        set -l decrypt (openssl enc -aes-256-cbc -d -base64 -in "$vault" -pass pass:"$mp" 2>/dev/null)
        if test $status -eq 0
            set entries "$decrypt\n"
        end
    end

    # Remove old entry with same label
    set -l new_entries ""
    if test -n "$entries"
        for line in (string split "\n" "$entries")
            if not string match -qr "^$label:" "$line"
                if test -n "$new_entries"; set new_entries "$new_entries\n$line"
                else; set new_entries "$line"
                end
            end
        end
    end
    if test -n "$new_entries"; set new_entries "$new_entries\n$label:$pw"
    else; set new_entries "$label:$pw"
    end

    printf "%s" "$new_entries" | openssl enc -aes-256-cbc -salt -base64 -out "$vault" -pass pass:"$mp" 2>/dev/null
    if test $status -eq 0
        echo -e "\033[1;32m✔ Saved as '\033[1;33m$label\033[1;32m'\033[0m"
    else
        echo -e "\033[1;31m❌ Failed to save vault\033[0m"
        return 1
    end
end

function __passgen_vault_get --description 'Retrieve a password from encrypted vault'
    set -l label $argv[1]
    set -l vault (__passgen_vault_path)

    if not test -f "$vault"
        echo -e "\033[1;31m❌ No vault found at $vault\033[0m"
        return 1
    end

    echo -e "\033[1;33mEnter vault master password:\033[0m"
    set -l mp (read -s -P "> ")
    echo ""

    set -l decrypt (openssl enc -aes-256-cbc -d -base64 -in "$vault" -pass pass:"$mp" 2>/dev/null)
    if test $status -ne 0
        echo -e "\033[1;31m❌ Wrong master password or corrupted vault\033[0m"
        return 1
    end

    for line in (string split "\n" "$decrypt")
        if string match -qr "^$label:" "$line"
            set -l pw (echo "$line" | string replace -r '^[^:]*:' '')
            echo -e "\033[1;37m$label:\033[0m \033[1;32m$pw\033[0m"
            # Copy to clipboard
            printf "%s" "$pw" | wl-copy 2>/dev/null
            if test $status -eq 0
                echo -e "\033[1;36m📋 Copied to clipboard\033[0m"
            end
            return 0
        end
    end

    echo -e "\033[1;31m❌ No entry found for '\033[1;33m$label\033[1;31m'\033[0m"
    return 1
end

function __passgen_vault_list --description 'List saved vault entries'
    set -l vault (__passgen_vault_path)

    if not test -f "$vault"
        echo -e "\033[1;31m❌ No vault found at $vault\033[0m"
        return 1
    end

    echo -e "\033[1;33mEnter vault master password:\033[0m"
    set -l mp (read -s -P "> ")
    echo ""

    set -l decrypt (openssl enc -aes-256-cbc -d -base64 -in "$vault" -pass pass:"$mp" 2>/dev/null)
    if test $status -ne 0
        echo -e "\033[1;31m❌ Wrong master password or corrupted vault\033[0m"
        return 1
    end

    echo -e "\n  \033[1;37m📂 VAULT ENTRIES\033[0m"
    echo -e "  \033[38;5;248m┄┄┄┄┄┄┄┄┄┄┄┄┄┄\033[0m"
    set -l count 0
    for line in (string split "\n" "$decrypt")
        if string match -qr '^(.+?):(.+)$' "$line"
            set -l lbl (echo "$line" | string replace -r '^(.+?):.*$' '$1')
            echo -e "  \033[1;36m◉\033[0m \033[1;37m$lbl\033[0m"
            set count (math "$count + 1")
        end
    end
    if test "$count" -eq 0
        echo -e "  \033[38;5;248m(empty)\033[0m"
    else
        echo -e "  \033[38;5;248m$count entr" (test "$count" -eq 1; and echo "y"; or echo "ies") "\033[0m"
    end
end

# ── COMPUTE SCORE FOR A RAW PASSWORD (bulk table) ──
function __passgen_compute_score_for_pw --description 'Quick score 0-100 for a raw password string'
    set -l pw $argv[1]
    set -l len (string length "$pw")
    set -l upper_c (count (string match -ra '[A-Z]' "$pw") )
    set -l lower_c (count (string match -ra '[a-z]' "$pw") )
    set -l digit_c (count (string match -ra '[0-9]' "$pw") )
    set -l symbol_c (count (string match -ra '[^a-zA-Z0-9]' "$pw") )

    # Approximate pool
    set -l pool 0
    test "$upper_c" -gt 0; and set pool (math "$pool + 26")
    test "$lower_c" -gt 0; and set pool (math "$pool + 26")
    test "$digit_c" -gt 0; and set pool (math "$pool + 10")
    test "$symbol_c" -gt 0; and set pool (math "$pool + 32")

    set -l entropy 0
    if test "$pool" -gt 0
        set entropy (math "floor( $len * ( ln($pool) / ln(2) ) )" 2>/dev/null)
    end

    set -l base 0
    if test "$entropy" -gt 0
        set base (math "min(80, round($entropy * 0.4))" 2>/dev/null)
    end

    set -l div_bonus 0
    if test "$upper_c" -gt 0; set div_bonus (math "$div_bonus + 4"); end
    if test "$lower_c" -gt 0; set div_bonus (math "$div_bonus + 3"); end
    if test "$digit_c" -gt 0; set div_bonus (math "$div_bonus + 4"); end
    if test "$symbol_c" -gt 0; set div_bonus (math "$div_bonus + 4"); end

    set -l len_bonus 0
    if test "$len" -ge 16; set len_bonus 5
    else if test "$len" -ge 12; set len_bonus 3
    else if test "$len" -ge 8; set len_bonus 1
    end

    set -l penalty 0
    if string match -qr '(.)\1{2,}' "$pw"; set penalty (math "$penalty + 5"); end
    if string match -qr '^(password|123456|qwerty|letmein|admin|welcome)' (string lower "$pw")
        set penalty (math "$penalty + 20")
    end

    set -l score (math "max(0, min(100, $base + $div_bonus + $len_bonus - $penalty))" 2>/dev/null)
    echo $score
end
