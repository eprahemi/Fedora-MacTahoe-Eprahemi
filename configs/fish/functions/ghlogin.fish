# ══════════════════════════════════════════════════════════════
# ghlogin — GitHub CLI login + git config setup
# Install gh, authenticate, and set global git user.email/user.name
# Fedora MacTahoe Eprahemi Edition © 2026
# ══════════════════════════════════════════════════════════════
function ghlogin --description 'Login to GitHub CLI and configure git'
    set -l sep "══════════════════════════════════════════════════════════"

    # ── Help (show on no args OR any help flag) ──
    if test (count $argv) -eq 0
        printf "\n"
        printf "  \033[1;36m╔%s╗\033[0m\n" "$sep"
        printf "  \033[1;36m║\033[0m              \033[1;37m🐙  GITHUB  LOGIN\033[0m\n"
        printf "  \033[1;36m╠%s╣\033[0m\n" "$sep"
        printf "  \033[1;36m║\033[0m\n"
        printf "  \033[1;36m║\033[0m  \033[2;37mOne command to set up GitHub on any new machine.\033[0m\n"
        printf "  \033[1;36m║\033[0m  \033[2;37mInstalls the GitHub CLI, authenticates via browser,\033[0m\n"
        printf "  \033[1;36m║\033[0m  \033[2;37mand configures your git identity for all future commits.\033[0m\n"
        printf "  \033[1;36m║\033[0m\n"
        printf "  \033[1;36m║\033[0m  \033[1;37mUSAGE:\033[0m\n"
        printf "  \033[1;36m║\033[0m\n"
        printf "  \033[1;36m║\033[0m    \033[1;36mghlogin\033[0m              \033[2;37m→\033[0m  \033[1;37mShow this help message\033[0m\n"
        printf "  \033[1;36m║\033[0m    \033[1;36mghlogin start\033[0m        \033[2;37m→\033[0m  \033[1;37mRun the full setup wizard\033[0m\n"
        printf "  \033[1;36m║\033[0m    \033[1;36mghlogin status\033[0m       \033[2;37m→\033[0m  \033[1;37mCheck current GitHub + git config state\033[0m\n"
        printf "  \033[1;36m║\033[0m\n"
        printf "  \033[1;36m║\033[0m  \033[2;37mStart aliases:\033[0m \033[1;36ms\033[0m \033[2;37m|\033[0m \033[1;36mstart\033[0m \033[2;37m|\033[0m \033[1;36m-s\033[0m \033[2;37m|\033[0m \033[1;36m--start\033[0m \033[2;37m|\033[0m \033[1;36mrun\033[0m \033[2;37m|\033[0m \033[1;36mgo\033[0m \033[2;37m|\033[0m \033[1;36mlogin\033[0m \033[2;37m|\033[0m \033[1;36msetup\033[0m\n"
        printf "  \033[1;36m║\033[0m  \033[2;37mStatus aliases:\033[0m \033[1;36mstatus\033[0m \033[2;37m|\033[0m \033[1;36mst\033[0m \033[2;37m|\033[0m \033[1;36mwho\033[0m \033[2;37m|\033[0m \033[1;36mam\033[0m\n"
        printf "  \033[1;36m║\033[0m  \033[2;37mHelp aliases:\033[0m  \033[1;36m-h\033[0m \033[2;37m|\033[0m \033[1;36m--help\033[0m \033[2;37m|\033[0m \033[1;36mhelp\033[0m \033[2;37m|\033[0m \033[1;36mh\033[0m \033[2;37m|\033[0m \033[1;36mH\033[0m \033[2;37m|\033[0m \033[1;36m?\033[0m\n"
        printf "  \033[1;36m║\033[0m\n"
        printf "  \033[1;36m║\033[0m  \033[1;37mWHAT HAPPENS:\033[0m\n"
        printf "  \033[1;36m║\033[0m\n"
        printf "  \033[1;36m║\033[0m    \033[1;33m1.\033[0m \033[1;37mInstall gh\033[0m          \033[2;37mGitHub CLI installed via dnf (skipped if present)\033[0m\n"
        printf "  \033[1;36m║\033[0m    \033[1;33m2.\033[0m \033[1;37mBrowser login\033[0m      \033[2;37mOpens browser to authorize your GitHub account\033[0m\n"
        printf "  \033[1;36m║\033[0m    \033[1;33m3.\033[0m \033[1;37mGit identity\033[0m       \033[2;37mSets user.email + user.name for all git commits\033[0m\n"
        printf "  \033[1;36m║\033[0m\n"
        printf "  \033[1;36m║\033[0m  \033[1;37mNOTES:\033[0m\n"
        printf "  \033[1;36m║\033[0m\n"
        printf "  \033[1;36m║\033[0m    \033[2;37m• Safe to run multiple times — skips steps already done\033[0m\n"
        printf "  \033[1;36m║\033[0m    \033[2;37m• Works on any Fedora machine with any GitHub account\033[0m\n"
        printf "  \033[1;36m║\033[0m    \033[2;37m• Requires sudo for gh install (prompts if needed)\033[0m\n"
        printf "  \033[1;36m║\033[0m\n"
        printf "  \033[1;36m║\033[0m  \033[2;37mVersion: July 2026\033[0m\n"
        printf "  \033[1;36m╚%s╝\033[0m\n" "$sep"
        printf "\n"
        return 0
    end

    switch $argv[1]
        case --help -help -h --h -H --H help h H '?' '??'
            printf "\n"
            printf "  \033[1;36m╔%s╗\033[0m\n" "$sep"
            printf "  \033[1;36m║\033[0m              \033[1;37m🐙  GITHUB  LOGIN\033[0m\n"
            printf "  \033[1;36m╠%s╣\033[0m\n" "$sep"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mOne command to set up GitHub on any new machine.\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mInstalls the GitHub CLI, authenticates via browser,\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mand configures your git identity for all future commits.\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[1;37mUSAGE:\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m    \033[1;36mghlogin\033[0m              \033[2;37m→\033[0m  \033[1;37mShow this help message\033[0m\n"
            printf "  \033[1;36m║\033[0m    \033[1;36mghlogin start\033[0m        \033[2;37m→\033[0m  \033[1;37mRun the full setup wizard\033[0m\n"
            printf "  \033[1;36m║\033[0m    \033[1;36mghlogin status\033[0m       \033[2;37m→\033[0m  \033[1;37mCheck current GitHub + git config state\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mStart aliases:\033[0m \033[1;36ms\033[0m \033[2;37m|\033[0m \033[1;36mstart\033[0m \033[2;37m|\033[0m \033[1;36m-s\033[0m \033[2;37m|\033[0m \033[1;36m--start\033[0m \033[2;37m|\033[0m \033[1;36mrun\033[0m \033[2;37m|\033[0m \033[1;36mgo\033[0m \033[2;37m|\033[0m \033[1;36mlogin\033[0m \033[2;37m|\033[0m \033[1;36msetup\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mStatus aliases:\033[0m \033[1;36mstatus\033[0m \033[2;37m|\033[0m \033[1;36mst\033[0m \033[2;37m|\033[0m \033[1;36mwho\033[0m \033[2;37m|\033[0m \033[1;36mam\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mHelp aliases:\033[0m  \033[1;36m-h\033[0m \033[2;37m|\033[0m \033[1;36m--help\033[0m \033[2;37m|\033[0m \033[1;36mhelp\033[0m \033[2;37m|\033[0m \033[1;36mh\033[0m \033[2;37m|\033[0m \033[1;36mH\033[0m \033[2;37m|\033[0m \033[1;36m?\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[1;37mWHAT HAPPENS:\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m    \033[1;33m1.\033[0m \033[1;37mInstall gh\033[0m          \033[2;37mGitHub CLI installed via dnf (skipped if present)\033[0m\n"
            printf "  \033[1;36m║\033[0m    \033[1;33m2.\033[0m \033[1;37mBrowser login\033[0m      \033[2;37mOpens browser to authorize your GitHub account\033[0m\n"
            printf "  \033[1;36m║\033[0m    \033[1;33m3.\033[0m \033[1;37mGit identity\033[0m       \033[2;37mSets user.email + user.name for all git commits\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[1;37mNOTES:\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m    \033[2;37m• Safe to run multiple times — skips steps already done\033[0m\n"
            printf "  \033[1;36m║\033[0m    \033[2;37m• Works on any Fedora machine with any GitHub account\033[0m\n"
            printf "  \033[1;36m║\033[0m    \033[2;37m• Requires sudo for gh install (prompts if needed)\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mVersion: July 2026\033[0m\n"
            printf "  \033[1;36m╚%s╝\033[0m\n" "$sep"
            printf "\n"
            return 0

        case start -start --start -s s --s run -run --run go -go --go login -login --login setup -setup --setup
            # ══════════════════════════════════════════════════════════════
            # STEP 1: Install GitHub CLI
            # ══════════════════════════════════════════════════════════════
            printf "\n"
            printf "  \033[1;36m╔%s╗\033[0m\n" "$sep"
            printf "  \033[1;36m║\033[0m              \033[1;37m🐙  GITHUB  LOGIN\033[0m\n"
            printf "  \033[1;36m╠%s╣\033[0m\n" "$sep"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[1;37mSTEP 1:\033[0m \033[2;37mChecking GitHub CLI (gh)...\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"

            if command -q gh
                set -l gh_ver (gh --version 2>/dev/null | head -1)
                printf "  \033[1;36m║\033[0m  \033[1;32m✓\033[0m  \033[2;37mAlready installed:\033[0m \033[1;37m%s\033[0m\n" "$gh_ver"
            else
                printf "  \033[1;36m║\033[0m  \033[1;33m●\033[0m  \033[2;37mInstalling GitHub CLI...\033[0m\n"
                if sudo dnf install gh -y 2>/dev/null
                    printf "  \033[1;36m║\033[0m  \033[1;32m✓\033[0m  \033[2;37mInstalled successfully\033[0m\n"
                else
                    printf "  \033[1;36m║\033[0m  \033[1;31m✗\033[0m  \033[2;37mFailed to install — check your internet or dnf\033[0m\n"
                    printf "  \033[1;36m║\033[0m\n"
                    printf "  \033[1;36m╚%s╝\033[0m\n" "$sep"
                    printf "\n"
                    return 1
                end
            end

            printf "  \033[1;36m║\033[0m\n"

            # ══════════════════════════════════════════════════════════════
            # STEP 2: Check if already logged in
            # ══════════════════════════════════════════════════════════════
            printf "  \033[1;36m║\033[0m  \033[1;37mSTEP 2:\033[0m \033[2;37mChecking login status...\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"

            if gh auth status >/dev/null 2>&1
                set -l gh_user (gh api user 2>/dev/null | jq -r '.login' 2>/dev/null)
                if test -n "$gh_user"
                    printf "  \033[1;36m║\033[0m  \033[1;32m✓\033[0m  \033[2;37mAlready logged in as\033[0m \033[1;37m%s\033[0m\n" "$gh_user"
                else
                    printf "  \033[1;36m║\033[0m  \033[1;32m✓\033[0m  \033[2;37mAlready authenticated with GitHub\033[0m\n"
                end
                printf "  \033[1;36m║\033[0m\n"
                printf "  \033[1;36m║\033[0m  \033[2;37mSkipping browser login — proceeding to git config\033[0m\n"
            else
                printf "  \033[1;36m║\033[0m  \033[1;33m●\033[0m  \033[2;37mNot logged in — starting browser authentication\033[0m\n"
                printf "  \033[1;36m║\033[0m\n"
                printf "  \033[1;36m║\033[0m  \033[1;33mWhen prompted, select:\033[0m\n"
                printf "  \033[1;36m║\033[0m    \033[2;37m1.\033[0m \033[1;37mGitHub.com\033[0m\n"
                printf "  \033[1;36m║\033[0m    \033[2;37m2.\033[0m \033[1;37mHTTPS\033[0m\n"
                printf "  \033[1;36m║\033[0m    \033[2;37m3.\033[0m \033[1;37mY\033[0m \033[2;37m/authenticate with browser\033[0m\n"
                printf "  \033[1;36m║\033[0m\n"

                gh auth login --hostname github.com --git-protocol https --web </dev/tty

                if test $status -ne 0
                    printf "\n"
                    printf "  \033[1;31m╔%s╗\033[0m\n" "$sep"
                    printf "  \033[1;31m║\033[0m  \033[1;31m✗\033[0m  Login failed — try again or check your connection\n"
                    printf "  \033[1;31m╚%s╝\033[0m\n" "$sep"
                    printf "\n"
                    return 1
                end

                printf "  \033[1;36m║\033[0m  \033[1;32m✓\033[0m  \033[2;37mLogin successful\033[0m\n"
            end

            printf "  \033[1;36m║\033[0m\n"

            # ══════════════════════════════════════════════════════════════
            # STEP 3: Configure git global user (auto-set from GitHub)
            # ══════════════════════════════════════════════════════════════
            printf "  \033[1;36m║\033[0m  \033[1;37mSTEP 3:\033[0m \033[2;37mFetching your GitHub profile...\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"

            # Fetch GitHub profile
            set -l gh_profile_email (gh api user 2>/dev/null | jq -r '.email // empty' 2>/dev/null)
            set -l gh_profile_name (gh api user 2>/dev/null | jq -r '.name // empty' 2>/dev/null)

            # ── Auto-set email from GitHub ──
            if test -n "$gh_profile_email"
                git config --global user.email "$gh_profile_email"
                printf "  \033[1;36m║\033[0m  \033[1;32m✓\033[0m  \033[2;37mEmail:\033[0m \033[1;37m%s\033[0m \033[2;37m(set from GitHub account)\033[0m\n" "$gh_profile_email"
            else
                printf "  \033[1;36m║\033[0m  \033[1;33m⚠\033[0m  \033[2;37mGitHub account has no email —\033[0m \033[1;37mset manually below\033[0m\n"
            end

            # ── Auto-set name from GitHub ──
            if test -n "$gh_profile_name"
                git config --global user.name "$gh_profile_name"
                printf "  \033[1;36m║\033[0m  \033[1;32m✓\033[0m  \033[2;37mName:\033[0m  \033[1;37m%s\033[0m \033[2;37m(set from GitHub profile)\033[0m\n" "$gh_profile_name"
            else
                printf "  \033[1;36m║\033[0m  \033[1;33m⚠\033[0m  \033[2;37mGitHub profile has no name —\033[0m \033[1;37mset manually below\033[0m\n"
            end

            printf "  \033[1;36m║\033[0m\n"

            # ── One prompt: accept or edit ──
            read -P "  ║  Continue with recommended? [Y/e] " -l choice

            if test "$choice" = "e" -o "$choice" = "E"
                # ── Edit email ──
                if test -n "$gh_profile_email"
                    read -P "  ║  Change email? [y/N] " -l reply
                    if test "$reply" = "y" -o "$reply" = "Y"
                        set -l valid_email 0
                        while test "$valid_email" -eq 0
                            read -P "  ║  Enter new email: " -l new_email
                            if test -z "$new_email"
                                printf "  \033[1;36m║\033[0m  \033[1;31m✗\033[0m  \033[2;37mEmail cannot be empty\033[0m\n"
                            else if string match -qr '^[^@]+@[^@]+\.[^@]+$' "$new_email"
                                if test "$new_email" != "$gh_profile_email"
                                    printf "  \033[1;36m║\033[0m  \033[1;33m⚠\033[0m  \033[2;37mThis doesn't match your GitHub account email:\033[0m \033[1;37m%s\033[0m\n" "$gh_profile_email"
                                end
                                printf "  \033[1;36m║\033[0m  \033[2;37mYou entered:\033[0m \033[1;37m%s\033[0m\n" "$new_email"
                                read -P "  ║  [R]etry or [C]onfirm? " -l rc
                                if test "$rc" = "c" -o "$rc" = "C"
                                    git config --global user.email "$new_email"
                                    printf "  \033[1;36m║\033[0m  \033[1;32m✓\033[0m  \033[2;37mEmail changed to\033[0m \033[1;37m%s\033[0m\n" "$new_email"
                                    set valid_email 1
                                end
                            else
                                printf "  \033[1;36m║\033[0m  \033[1;31m✗\033[0m  \033[2;37mInvalid email — must contain @ and . (e.g. user@domain.com)\033[0m\n"
                            end
                        end
                    end
                else
                    # No GitHub email — must enter manually
                    set -l valid_email 0
                    while test "$valid_email" -eq 0
                        read -P "  ║  Enter your email: " -l new_email
                        if test -z "$new_email"
                            printf "  \033[1;36m║\033[0m  \033[1;31m✗\033[0m  \033[2;37mEmail cannot be empty\033[0m\n"
                        else if string match -qr '^[^@]+@[^@]+\.[^@]+$' "$new_email"
                            git config --global user.email "$new_email"
                            printf "  \033[1;36m║\033[0m  \033[1;32m✓\033[0m  \033[2;37mEmail set to\033[0m \033[1;37m%s\033[0m\n" "$new_email"
                            set valid_email 1
                        else
                            printf "  \033[1;36m║\033[0m  \033[1;31m✗\033[0m  \033[2;37mInvalid email — must contain @ and . (e.g. user@domain.com)\033[0m\n"
                        end
                    end
                end

                printf "  \033[1;36m║\033[0m\n"

                # ── Edit name ──
                if test -n "$gh_profile_name"
                    read -P "  ║  Change name?  [y/N] " -l reply
                    if test "$reply" = "y" -o "$reply" = "Y"
                        set -l valid_name 0
                        while test "$valid_name" -eq 0
                            read -P "  ║  Enter new name: " -l new_name
                            if test -z "$new_name"
                                printf "  \033[1;36m║\033[0m  \033[1;31m✗\033[0m  \033[2;37mName cannot be empty\033[0m\n"
                            else if string match -qr '^[^ ]+$' "$new_name"
                                if test "$new_name" != "$gh_profile_name"
                                    printf "  \033[1;36m║\033[0m  \033[1;33m⚠\033[0m  \033[2;37mThis doesn't match your GitHub profile name:\033[0m \033[1;37m%s\033[0m\n" "$gh_profile_name"
                                end
                                printf "  \033[1;36m║\033[0m  \033[2;37mYou entered:\033[0m \033[1;37m%s\033[0m\n" "$new_name"
                                read -P "  ║  [R]etry or [C]onfirm? " -l rc
                                if test "$rc" = "c" -o "$rc" = "C"
                                    git config --global user.name "$new_name"
                                    printf "  \033[1;36m║\033[0m  \033[1;32m✓\033[0m  \033[2;37mName changed to\033[0m \033[1;37m%s\033[0m\n" "$new_name"
                                    set valid_name 1
                                end
                            else
                                printf "  \033[1;36m║\033[0m  \033[1;31m✗\033[0m  \033[2;37mInvalid name — no spaces allowed (e.g. JohnDoe)\033[0m\n"
                            end
                        end
                    end
                else
                    # No GitHub name — must enter manually
                    set -l valid_name 0
                    while test "$valid_name" -eq 0
                        read -P "  ║  Enter your name: " -l new_name
                        if test -z "$new_name"
                            printf "  \033[1;36m║\033[0m  \033[1;31m✗\033[0m  \033[2;37mName cannot be empty\033[0m\n"
                        else if string match -qr '^[^ ]+$' "$new_name"
                            git config --global user.name "$new_name"
                            printf "  \033[1;36m║\033[0m  \033[1;32m✓\033[0m  \033[2;37mName set to\033[0m \033[1;37m%s\033[0m\n" "$new_name"
                            set valid_name 1
                        else
                            printf "  \033[1;36m║\033[0m  \033[1;31m✗\033[0m  \033[2;37mInvalid name — no spaces allowed (e.g. JohnDoe)\033[0m\n"
                        end
                    end
                end
            end

            # ══════════════════════════════════════════════════════════════
            # SUMMARY
            # ══════════════════════════════════════════════════════════════
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m╠%s╣\033[0m\n" "$sep"
            printf "  \033[1;36m║\033[0m\n"

            set -l final_email (git config --global user.email 2>/dev/null)
            set -l final_name (git config --global user.name 2>/dev/null)

            printf "  \033[1;36m║\033[0m  \033[1;32m✓\033[0m  \033[1;37mGitHub setup complete\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            if test -n "$final_email"
                printf "  \033[1;36m║\033[0m    \033[2;37mEmail:\033[0m  \033[1;37m%s\033[0m\n" "$final_email"
            end
            if test -n "$final_name"
                printf "  \033[1;36m║\033[0m    \033[2;37mName:\033[0m   \033[1;37m%s\033[0m\n" "$final_name"
            end
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m║\033[0m  \033[2;37mYou can now clone, pull, and push to GitHub.\033[0m\n"
            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m╚%s╝\033[0m\n" "$sep"
            printf "\n"

        case status -status --status st -st --st who -who --who am -am --am
            # ══════════════════════════════════════════════════════════════
            # STATUS: Show current GitHub CLI + git identity state
            # ══════════════════════════════════════════════════════════════
            printf "\n"
            printf "  \033[1;36m╔%s╗\033[0m\n" "$sep"
            printf "  \033[1;36m║\033[0m              \033[1;37m🐙  GITHUB  STATUS\033[0m\n"
            printf "  \033[1;36m╠%s╣\033[0m\n" "$sep"
            printf "  \033[1;36m║\033[0m\n"

            # ── gh CLI ──
            if command -q gh
                set -l gh_ver (gh --version 2>/dev/null | head -1)
                printf "  \033[1;36m║\033[0m  \033[1;37mGitHub CLI:\033[0m   \033[1;32m✓\033[0m  \033[1;37m%s\033[0m\n" "$gh_ver"
            else
                printf "  \033[1;36m║\033[0m  \033[1;37mGitHub CLI:\033[0m   \033[1;31m✗\033[0m  \033[2;37mNot installed\033[0m\n"
            end

            # ── Auth status ──
            set -l gh_user ""
            if command -q gh; and gh auth status >/dev/null 2>&1
                set gh_user (gh api user 2>/dev/null | jq -r '.login' 2>/dev/null)
                if test -n "$gh_user"
                    printf "  \033[1;36m║\033[0m  \033[1;37mLogged in as:\033[0m \033[1;32m✓\033[0m  \033[1;37m%s\033[0m\n" "$gh_user"
                else
                    printf "  \033[1;36m║\033[0m  \033[1;37mLogged in as:\033[0m \033[1;32m✓\033[0m  \033[2;37mAuthenticated (could not fetch username)\033[0m\n"
                end
            else
                printf "  \033[1;36m║\033[0m  \033[1;37mLogged in as:\033[0m \033[1;31m✗\033[0m  \033[2;37mNot logged in\033[0m\n"
            end

            # ── Git email ──
            set -l git_email (git config --global user.email 2>/dev/null)
            set -l gh_email ""
            if command -q gh
                set gh_email (gh api user 2>/dev/null | jq -r '.email // empty' 2>/dev/null)
            end
            set -l email_ok 0
            if test -n "$git_email"
                if string match -qr '^[^@]+@[^@]+\.[^@]+$' "$git_email"
                    # Cross-check against GitHub account email
                    if test -n "$gh_email"; and test "$git_email" = "$gh_email"
                        printf "  \033[1;36m║\033[0m  \033[1;37mGit email:\033[0m    \033[1;32m✓\033[0m  \033[1;37m%s\033[0m \033[2;37mmatches GitHub account\033[0m\n" "$git_email"
                        set email_ok 1
                    else if test -n "$gh_email"
                        printf "  \033[1;36m║\033[0m  \033[1;37mGit email:\033[0m    \033[1;33m⚠\033[0m  \033[1;37m%s\033[0m \033[2;37m(git: \"%s\")\033[0m\n" "$git_email" "$gh_email"
                        set email_ok 1
                    else
                        printf "  \033[1;36m║\033[0m  \033[1;37mGit email:\033[0m    \033[1;32m✓\033[0m  \033[1;37m%s\033[0m \033[2;37m(valid format)\033[0m\n" "$git_email"
                        set email_ok 1
                    end
                else
                    printf "  \033[1;36m║\033[0m  \033[1;37mGit email:\033[0m    \033[1;31m✗\033[0m  \033[1;37m%s\033[0m \033[2;37m(invalid format — needs user@domain.com)\033[0m\n" "$git_email"
                end
            else
                printf "  \033[1;36m║\033[0m  \033[1;37mGit email:\033[0m    \033[1;31m✗\033[0m  \033[2;37mNot configured\033[0m\n"
            end

            # ── Git name (check against GitHub) ──
            set -l git_name (git config --global user.name 2>/dev/null)
            set -l name_ok 0
            if test -n "$git_name"
                # Check if the name exists as a GitHub user
                if test -n "$gh_user"; and command -q gh; and gh api "users/$gh_user" >/dev/null 2>&1
                    set -l gh_full_name (gh api "users/$gh_user" 2>/dev/null | jq -r '.name // empty' 2>/dev/null)
                    if test -n "$gh_full_name"; and test "$git_name" = "$gh_full_name"
                        printf "  \033[1;36m║\033[0m  \033[1;37mGit name:\033[0m     \033[1;32m✓\033[0m  \033[1;37m%s\033[0m \033[2;37mmatches GitHub profile\033[0m\n" "$git_name"
                        set name_ok 1
                    else if test -n "$gh_full_name"
                        printf "  \033[1;36m║\033[0m  \033[1;37mGit name:\033[0m     \033[1;33m⚠\033[0m  \033[1;37m%s\033[0m \033[2;37m(git: \"%s\")\033[0m\n" "$git_name" "$gh_full_name"
                        set name_ok 1
                    else
                        printf "  \033[1;36m║\033[0m  \033[1;37mGit name:\033[0m     \033[1;32m✓\033[0m  \033[1;37m%s\033[0m \033[2;37m(GitHub profile has no name set)\033[0m\n" "$git_name"
                        set name_ok 1
                    end
                else
                    printf "  \033[1;36m║\033[0m  \033[1;37mGit name:\033[0m     \033[1;32m✓\033[0m  \033[1;37m%s\033[0m \033[2;37m(cannot verify — not logged in)\033[0m\n" "$git_name"
                    set name_ok 1
                end
            else
                printf "  \033[1;36m║\033[0m  \033[1;37mGit name:\033[0m     \033[1;31m✗\033[0m  \033[2;37mNot configured\033[0m\n"
            end

            printf "  \033[1;36m║\033[0m\n"

            # ── Overall verdict ──
            set -l all_good 1
            command -q gh; or set all_good 0
            set -l is_logged_in 0
            if command -q gh; gh auth status >/dev/null 2>&1; and set is_logged_in 1; end
            test "$is_logged_in" -eq 1; or set all_good 0
            test "$email_ok" -eq 1; or set all_good 0
            test "$name_ok" -eq 1; or set all_good 0

            if test "$all_good" -eq 1
                printf "  \033[1;36m║\033[0m  \033[1;32m✓\033[0m  \033[1;37mEverything is set up — ready to go!\033[0m\n"
            else if test "$is_logged_in" -eq 0
                printf "  \033[1;36m║\033[0m  \033[1;31m✗\033[0m  \033[1;37mYou need to login to GitHub — run\033[0m \033[1;36mghlogin start\033[0m\n"
            else
                printf "  \033[1;36m║\033[0m  \033[1;33m⚠\033[0m  \033[2;37mSome things need fixing — run\033[0m \033[1;36mghlogin start\033[0m\n"
            end

            printf "  \033[1;36m║\033[0m\n"
            printf "  \033[1;36m╚%s╝\033[0m\n" "$sep"
            printf "\n"

        case '*'
            printf "\n"
            printf "  \033[1;31m╔%s╗\033[0m\n" "$sep"
            printf "  \033[1;31m║\033[0m  \033[1;31m✗\033[0m  Unknown command: $argv[1]\n"
            printf "  \033[1;31m║\033[0m  \033[2;37mTry\033[0m \033[1;36mghlogin --help\033[0m\n"
            printf "  \033[1;31m╚%s╝\033[0m\n" "$sep"
            printf "\n"
            return 1
    end
end
