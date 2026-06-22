# ══════════════════════════════════════════════════════════════
# getdata 📊 — EPRAHEMI INC. 🏢 Data hoarder since 2026 🗄️
# Eprahemi's dataset > your dataset. Stay mad 💅
# Fedora MacTahoe Eprahemi Edition © 2026 — big data energy
# ══════════════════════════════════════════════════════════════
function getdata --description 'Data science toolkit: install or list packages'
    if set -q argv[1]
        switch $argv[1]
            case --list -l
                echo -e "\033[1;36m"
                echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
                echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
                echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
                echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
                echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
                echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
                echo -e "\n  \033[1;34m── DATA SCIENCE PACKAGES ──\033[0m"
                echo -e "  \033[1;37mpandas\033[0m       \033[1;30m→\033[0m  Data manipulation & analysis"
                echo -e "  \033[1;37mnumpy\033[0m        \033[1;30m→\033[0m  Numerical computing"
                echo -e "  \033[1;37mmatplotlib\033[0m   \033[1;30m→\033[0m  Plotting & visualization"
                echo -e "  \033[1;37mseaborn\033[0m      \033[1;30m→\033[0m  Statistical data viz"
                echo -e "  \033[1;37mscikit-learn\033[0m \033[1;30m→\033[0m  Machine learning"
                echo -e "  \033[1;37mjupyter\033[0m      \033[1;30m→\033[0m  Notebook environment"
                echo -e "  \033[1;37mopenpyxl\033[0m     \033[1;30m→\033[0m  Excel file support"
                echo -e "\n  \033[1;33mRun \033[1;36mgetdata\033[1;33m to install all\033[0m"
                return 0

            case --venv -v
                echo -e "\033[1;36m"
                echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
                echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
                echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
                echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
                echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
                echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
                echo -e "\n  \033[1;34m── CREATING VIRTUAL ENV ──\033[0m"
                set -l venv_dir "./.venv"
                if test -d "$venv_dir"
                echo -e "  \033[1;33m⚠️  Girlll... virtual env already exists at $venv_dir\033[0m"
                echo -n "  \033[1;33mYou sure about that? Recreate? [y/N]: \033[0m"
                read -l resp
                if test "$resp" = "y" -o "$resp" = "Y"
                    rm -rf "$venv_dir"
                else
                    return 0
                end
            end
                python3 -m venv "$venv_dir"
                and echo -e "  \033[1;32m✅ Virtual env created at $venv_dir bestie! 💅\033[0m"
                and echo -e "  \033[1;33m💡 Activate it fam: \033[1;36msource $venv_dir/bin/activate.fish\033[0m"
                return 0

            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mgetdata [flags]\033[0m"
                echo -e "  \033[38;5;248m  --list, -l    Show data-science package list\033[0m"
                echo -e "  \033[38;5;248m  --venv, -v    Set up Python virtual environment\033[0m"
                echo -e "  \033[38;5;248m  (no args)     Install full data-science stack\033[0m"
                echo -e "  \033[38;5;248m  --help, -h    Show this help\033[0m"
                echo -e "  \033[38;5;248m📦 Unknown flag handling + rotating burns (Jun 2026)\033[0m"
                return 0
            case '-*'
                set -l gd_burns
                set gd_burns[1] "BRUH '\\033[1;33m$argv[1]\\033[1;33m' is not a getdata option 💀"
                set gd_burns[2] "'\\033[1;33m$argv[1]\\033[1;33m'??? That's not data bestie 💅"
                set gd_burns[3] "SIR THIS IS DATA CENTRAL... '\\033[1;33m$argv[1]\\033[1;33m' is not a flag 🍔"
                set gd_burns[4] "The data council voted: '\\033[1;33m$argv[1]\\033[1;33m' is DENIED ⚖️"
                set gd_burns[5] "BZZT! '\\033[1;33m$argv[1]\\033[1;33m' is corrupt data! 🎮💥"
                set -l gd_idx (random 1 5)
                echo -e "\\033[1;31m✘ $gd_burns[$gd_idx]\\033[0m"
                echo -e "  \\033[38;5;248m  Try \\033[1;36mgetdata --help\\033[38;5;248m bestie 📋\\033[0m"
                return 1
        end
    end

    # ── Default: full install ──
    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"

    echo -e "\n\033[1;34m── EPRAHEMI DATA SCIENCE SUITE ──\033[0m"

    if not set -q VIRTUAL_ENV
        echo -e "  \033[1;33m⚠️  No virtual env detected bestie — installing system-wide (no cap)\033[0m"
    else
        echo -e "  \033[1;32m🔒 Virtual env locked in: \033[1;36m$VIRTUAL_ENV\033[0m"
    end
    echo ""

    echo -n "  \033[1;37m⚡ Upgrading pip like it's hot...\033[0m "
    pip install --upgrade pip 2>/dev/null
    echo -e "\033[1;32m✅\033[0m"

    echo -n "  \033[1;37m🚀 Installing pandas, numpy, matplotlib...\033[0m "
    pip install pandas numpy matplotlib seaborn scikit-learn jupyter openpyxl 2>/dev/null
    echo -e "\033[1;32m✅\033[0m"

    echo ""
    echo -e "  \033[1;34m── COMPLETE ──\033[0m"
    echo -e "  \033[1;32m✅ Data science toolkit installed bestie! Time to analyze all the things 📊\033[0m"
    echo -e "  \033[1;33m💡 Type \033[1;36mjupyter notebook\033[1;33m to start cooking 🔥\033[0m"
end
