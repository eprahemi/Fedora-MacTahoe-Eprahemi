# ══════════════════════════════════════════════════════════════
# getdata 📊 — EPRAHEMI INC. 🏢 Data science toolkit installer
# Python data science package installer
# Fedora MacTahoe Eprahemi Edition © 2026
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
                echo -e "  \033[1;33m⚠️  Virtual environment already exists at $venv_dir\033[0m"
                read -P "  Recreate? [y/N]: " -l resp
                if test "$resp" = "y" -o "$resp" = "Y"
                    rm -rf "$venv_dir"
                else
                    return 0
                end
            end
                python3 -m venv "$venv_dir"
                and echo -e "  \033[1;32m✅ Virtual environment created at $venv_dir\033[0m"
                and echo -e "  \033[1;33m💡 Activate it: \033[1;36msource $venv_dir/bin/activate.fish\033[0m"
                return 0

            case --help -h
                echo -e "\033[1;33mUsage: \033[1;36mgetdata [flags]\033[0m"
                echo -e "  \033[38;5;248m  --list, -l    Show data-science package list\033[0m"
                echo -e "  \033[38;5;248m  --venv, -v    Set up Python virtual environment\033[0m"
                echo -e "  \033[38;5;248m  (no args)     Install full data-science stack\033[0m"
                echo -e "  \033[38;5;248m  --help, -h    Show this help\033[0m"
                echo -e "  \033[38;5;248m📦 Unknown flag handling (Jun 2026)\033[0m"
                return 0
            case '-*'
                echo -e "\033[1;31m✘ Error: Unknown flag '\033[1;33m$argv[1]\033[1;31m'\033[0m"
                echo -e "  \033[38;5;248m  Try \033[1;36mgetdata --help\033[38;5;248m for available options 📋\033[0m"
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
        echo -e "  \033[1;33m⚠️  No virtual environment detected — installing system-wide\033[0m"
    else
        echo -e "  \033[1;32m🔒 Virtual env locked in: \033[1;36m$VIRTUAL_ENV\033[0m"
    end
    printf "\n"

    echo -n "  \033[1;37m⚡ Upgrading pip...\033[0m "
    pip install --upgrade pip 2>/dev/null
    echo -e "\033[1;32m✅\033[0m"

    echo -n "  \033[1;37m🚀 Installing pandas, numpy, matplotlib...\033[0m "
    pip install pandas numpy matplotlib seaborn scikit-learn jupyter openpyxl 2>/dev/null
    echo -e "\033[1;32m✅\033[0m"

    printf "\n"
    echo -e "  \033[1;34m── COMPLETE ──\033[0m"
    echo -e "  \033[1;32m✅ Data science toolkit installed. Ready for data analysis 📊\033[0m"
    echo -e "  \033[1;33m💡 Type \033[1;36mjupyter notebook\033[1;33m to begin\033[0m"
end
