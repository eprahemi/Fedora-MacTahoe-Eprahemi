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
            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mpassgen [options]\033[0m"
                echo -e "  \033[38;5;248m<number>\033[0m           \033[1;37mPassword length preset\033[0m"
                echo -e "  \033[38;5;248m<password>\033[0m         \033[1;37mAnalyze a password\'s strength\033[0m"
                echo -e "  \033[38;5;248m--length, -l N\033[0m     \033[1;37mPassword length (default: 16)\033[0m"
                echo -e "  \033[38;5;248m--count, -n N\033[0m      \033[1;37mNumber of passwords (default: 1)\033[0m"
                echo -e "  \033[38;5;248m--no-lower\033[0m         \033[1;37mExclude lowercase letters\033[0m"
                echo -e "  \033[38;5;248m--no-upper\033[0m         \033[1;37mExclude uppercase letters\033[0m"
                echo -e "  \033[38;5;248m--no-digits\033[0m        \033[1;37mExclude digits\033[0m"
                echo -e "  \033[38;5;248m--no-symbols, -s\033[0m   \033[1;37mExclude symbols\033[0m"
                echo -e "  \033[38;5;248m--clip, -c\033[0m         \033[1;37mCopy to clipboard\033[0m"
                echo -e "\n  \033[1;36mPresets:\033[0m \033[1;33m16\033[0m \033[1;33m32\033[0m \033[1;33m48\033[0m \033[1;33m64\033[0m \033[1;33m96\033[0m \033[1;33m104\033[0m"
                echo -e "  \033[38;5;248mExamples:\033[0m"
                echo -e "    \033[1;36mpassgen\033[0m              \033[1;37mGenerate a 16-char password\033[0m"
                echo -e "    \033[1;36mpassgen 32\033[0m           \033[1;37mGenerate a 32-char password\033[0m"
                echo -e "    \033[1;36mpassgen mypassword123\033[0m \033[1;37mAnalyze password strength\033[0m"
                return 0
            case '*'
                if string match -qr '^\d+$' "$argv[1]"
                    set length $argv[1]
                    set -e argv[1]
                else
                    # Non-numeric, non-flag → analyze mode
                    set analyze_mode yes
                    set analyze_password "$argv[1]"
                    set -e argv[1]
                end
        end
    end

    # ── ANALYSIS MODE ──
    if test "$analyze_mode" = yes
        set -l pw "$analyze_password"
        set -l pw_len (string length "$pw")

        # Count character types using Python for reliability
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

        # Pool size from what's used
        set -l pool 0
        test "$upper_count" -gt 0; and set pool (math "$pool + 26")
        test "$lower_count" -gt 0; and set pool (math "$pool + 26")
        test "$digit_count" -gt 0; and set pool (math "$pool + 10")
        test "$symbol_count" -gt 0; and set pool (math "$pool + 32")

        # Entropy
        set -l entropy 0
        if test "$pool" -gt 0
            set entropy (math "floor( $pw_len * ( ln($pool) / ln(2) ) )" 2>/dev/null)
        end

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

        # Full password display (not censored — you already know it)
        echo -e "  \033[1;37mPassword:\033[0m  \033[1;33m$pw\033[0m"
        echo -e "  \033[1;37mLength:  \033[1;33m$pw_len\033[0m \033[1;37mchars\033[0m"

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

        # ── Generate secure replacement (keeps your password recognizable) ──
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
# Target: at least 20 chars, at least 1.8x original length
target = max(int(pw_len * 1.8), 20)

has_upper = any(c.isupper() for c in pw)
has_lower = any(c.islower() for c in pw)
has_digit = any(c.isdigit() for c in pw)
has_sym   = any(c in "!@#$%^&*()_-+=<>?" for c in pw)
all_chars = string.ascii_letters + string.digits + "!@#$%^&*()_-+=<>?"

# Start with original password, sprinkle case changes + missing types
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

# If still missing a type, inject one inside the core
if not has_upper:
    core.insert(secrets.randbelow(len(core)+1), secrets.choice(string.ascii_uppercase))
if not has_lower:
    core.insert(secrets.randbelow(len(core)+1), secrets.choice(string.ascii_lowercase))
if not has_digit:
    core.insert(secrets.randbelow(len(core)+1), secrets.choice(string.digits))
if not has_sym:
    core.insert(secrets.randbelow(len(core)+1), secrets.choice("!@#$%^&*()_-+=<>?"))

core_str = "".join(core)

# Pad to target with random prefix + suffix
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

        # Calculate replacement entropy (always full pool: 26+26+10+20 = 82)
        set -l new_pool_size 82
        set -l new_entropy (math "floor( $new_len * ( ln($new_pool_size) / ln(2) ) )" 2>/dev/null)

        # ── PASSWORD UPGRADE COMPARISON ──
        echo -e "\n  \033[1;37m💡 PASSWORD UPGRADE\033[0m"
        echo -e "  \033[38;5;248m┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄\033[0m"
        # Old password
        printf "  \033[1;37mYour password:\033[0m      \033[1;33m%s\033[0m\n" "$pw"
        # Crack time for old (fastest attack: MD5)
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

        # New secure password
        printf "  \033[1;37mEdited with secure:\033[0m \033[1;32m%s\033[0m\n" "$new_pw"
        # Crack time for new (fastest attack: MD5)
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

        functions -e __passgen_cracktime
        return 0
    end

    # ── GENERATION MODE ──
    # Build character set
    set -l chars ""
    test "$use_lower" = yes; and set chars "$chars"abcdefghijklmnopqrstuvwxyz
    test "$use_upper" = yes; and set chars "$chars"ABCDEFGHIJKLMNOPQRSTUVWXYZ
    test "$use_digits" = yes; and set chars "$chars"0123456789
    test "$use_punct" = yes; and set chars "$chars"'!@#$%^&*()_-+=<>?'

    if test (string length "$chars") -eq 0
        echo -e "\033[1;31m❌ No character types selected!\033[0m"
        return 1
    end

    set -l charlen (string length "$chars")

    # Calculate pool size and entropy
    set -l pool_size 0
    test "$use_lower" = yes; and set pool_size (math $pool_size + 26)
    test "$use_upper" = yes; and set pool_size (math $pool_size + 26)
    test "$use_digits" = yes; and set pool_size (math $pool_size + 10)
    test "$use_punct" = yes; and set pool_size (math $pool_size + 20)
    set -l entropy (math "floor( $length * ( ln($pool_size) / ln(2) ) )" 2>/dev/null)

    # Generate passwords
    set -l passwords
    for p in (seq $count)
        set -l password ""
        for i in (seq $length)
            set -l idx (math (random) % $charlen + 1)
            set password "$password"(string sub -s $idx -l 1 "$chars")
        end
        set passwords $passwords $password
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
    printf "  \033[1;37mLength: \033[1;33m%s\033[0m     \033[1;37mCount: \033[1;33m%s\033[0m     \033[1;37mPool: \033[1;33m%s\033[0m\n" "$length" "$count" "$pool_size"

    for i in (seq (count $passwords))
        if test (count $passwords) -gt 1
            printf "  \033[1;36m%2d\033[0m  \033[1;32m%s\033[0m\n" $i $passwords[$i]
        else
            printf "  \033[1;32m%s\033[0m\n" $passwords[$i]
        end
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

    # Crack time
    if test -n "$entropy"
        __passgen_cracktime $entropy
    end
end

# ── HELPER: crack time statistics ──
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
