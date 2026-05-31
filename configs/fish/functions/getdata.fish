function getdata --description 'High-End Data Science Suite Installer'
  # --- EPRAHEMI CUSTOM HEADER ---
    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    
    # 1. Branding & Intro
    echo (set_color -o cyan)"--------------------------------------------------"
    echo (set_color -o white)"  💎 EPRAHEMI MAIN DATABASE: LOADING..."
    echo (set_color -o cyan)"--------------------------------------------------"
    sleep 0.5

    # 2. Safety Check (reminds you to use the venv)
    if not set -q VIRTUAL_ENV
        echo (set_color yellow)"⚠️  Warning: No Virtual Environment detected."
        echo (set_color white)"System-wide installation initiated..."
    else
        echo (set_color green)"🔒 Virtual Environment Active: "(set_color -u)"$VIRTUAL_ENV"
    end
    echo ""

    # 3. Self-Upgrade Pip
    echo (set_color magenta)"⚡ Optimization: Upgrading Pip..."(set_color normal)
    pip install --upgrade pip

    # 4. Main Installation
    echo (set_color green)"🚀 Injecting Data Science Toolkit..."(set_color normal)
    pip install pandas numpy matplotlib seaborn scikit-learn jupyter openpyxl

  # --- EPRAHEMI CUSTOM HEADER ---
    echo -e "\033[1;36m"
    echo "  ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗"
    echo "  ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║"
    echo "  █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║"
    echo "  ██╔══╝  ██╔═══╝ ██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║"
    echo "  ███████╗██║     ██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║"
    echo "  ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝"
    
    # 5. Cool Outro
    echo ""
    echo (set_color -o blue)"✅ DATABASE SYNCHRONIZATION COMPLETE"
    echo (set_color white)"--------------------------------------------------"
    echo (set_color cyan)"📊 Stats: " (set_color white)"Pandas, Numpy, ML-Ready."
    echo (set_color cyan)"💡 Tip: " (set_color white)"Type 'jupyter notebook' to start coding."
    echo (set_color -o blue)"--------------------------------------------------"
end
