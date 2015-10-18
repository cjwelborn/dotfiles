#!/bin/bash
# This file includes prompts, colors, and possibly other stuff for a
# bash interactive session.
# To use it edit /etc/bash.bashrc (for all users) to include:
#   source bash.extras.interactive.sh
# -Christopher Welborn 8-9-13 (not all pieces are original work)

# ---------------------------------- COLORS ----------------------------------
if [[ -d "/home/cjwelborn" ]]; then
    cjhome="/home/cjwelborn"
else
    cjhome="/home/cj"
fi
# Log some debug info while loading this script.
bashextraslogfile="$cjhome/bash.extras.interactive.log"
function bashextraslog {
    # Write to the bash.extras.interactive.log
    echo -e "$@" >> "$bashextraslogfile"
}
echo "Loading bash.extras.interactive.sh, cjhome=$cjhome" > "$bashextraslogfile"

# Set dir_colors if it exists.
dircolorsfile="$cjhome/.dir_colors"
if [[ -e "$dircolorsfile" ]]; then
    eval "$(dircolors "$dircolorsfile")"
    bashextraslog "dir_colors set from: $dircolorsfile"
fi
unset -v dircolorsfile

# Define some colors first: (SC2034 = Unused vars (they are exported though))
            red='\e[0;31m'     # shellcheck disable=SC2034
      redprompt='\[e[0;31m\]'
            RED='\e[1;31m'
      REDPROMPT='\[\e[1;31m\]' # shellcheck disable=SC2034
           blue='\e[0;34m    ' # shellcheck disable=SC2034
           BLUE='\e[1;34m'
     BLUEPROMPT='\[\e[1;34m\]' # shellcheck disable=SC2034
           cyan='\e[0;36m'     # shellcheck disable=SC2034
     cyanprompt='\[\e[0;36m\]'
           CYAN='\e[1;36m'
     CYANPROMPT='\[\e[1;36m\]' # shellcheck disable=SC2034
             NC='\e[0m'        # No Color
       NCPROMPT='\[\e[0m\]'
          black='\e[0;30m'     # shellcheck disable=SC2034
       DARKGRAY='\e[1;30m'     # shellcheck disable=SC2034
      LIGHTBLUE='\e[1;34m'     # shellcheck disable=SC2034
LIGHTBLUEPROMPT='\[\e[1;34m\]'
          green='\e[0;32m'     # shellcheck disable=SC2034
     LIGHTGREEN='\e[1;32m'     # shellcheck disable=SC2034
         purple='\e[0;35m'     # shellcheck disable=SC2034
    LIGHTPURPLE='\e[1;35m'     # shellcheck disable=SC2034
         YELLOW='\e[1;33m'     # shellcheck disable=SC2034
    lightyellow='\e[0;33m'     # shellcheck disable=SC2034
      lightgray='\e[0;37m'     # shellcheck disable=SC2034
          WHITE='\e[1;37m'     # shellcheck disable=SC2034


#Set Hilite Color for 3rd Party Prompts
if [[ "${DISPLAY%%:0*}" != "" ]]; then
    HILIT=${redprompt}   # remote machine: prompt will be partly red
else
    HILIT=${cyanprompt}  # local machine: prompt will be partly cyan
fi

# ------------------------------- PROMPT FUNCTIONS ----------------------------
# This is needed for the simple/default prompts.
if [[ -z "${debian_chroot:-}" ]] && [[ -r /etc/debian_chroot ]]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Following simple/default prompt function from original simple/fancy prompts...
function simpleprompt()
{
    # depends on debian_chroot being available:
    # shellcheck disable=SC2154
    unset -v PROMPT_COMMAND
    # Sets the prompt to (chroot name)user@host: workingdir $
    # If debian_chroot is not set, it is not used.
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
}

function defaultprompt()
{
    # depends on debian_chroot being available:
    # shellcheck disable=SC2154
    unset -v PROMPT_COMMAND
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
}

# Following 3rd party 'Power Prompt' & 'Fast Prompt' added by Cj
function fastprompt()
{
    unset PROMPT_COMMAND
    case $TERM in
        *term | rxvt )
        PS1="${HILIT}[\h]$NCPROMPT \W > \[\033]0;\${TERM} [\u@\h] \w\007\]" ;;
    linux )
        PS1="${HILIT}[\h]$NCPROMPT \W > " ;;
        *)
        PS1="[\h] \W > " ;;
    esac
}
_powerprompt()
{
       # shellcheck disable=SC2034
        LOAD=$(uptime|sed -e "s/.*: \([^,]*\).*/\1/" -e "s/ //g")
}

function powerprompt()
{

    PROMPT_COMMAND="_powerprompt"
    case $TERM in
        *term | rxvt  )
            PS1="${HILIT}[\A - \$LOAD]${NCPROMPT}\n[\u@\h \#] \W > \
                 \[\033]0;\${TERM} [\u@\h] \w\007\]" ;;
        linux )
            PS1="${HILIT}[\A - \$LOAD]${NCPROMPT}\n[\u@\h \#] \W > " ;;
        * )
            PS1="[\A - \$LOAD]\n[\u@\h \#] \W > " ;;
    esac
}

# Powerline-shell prompt.
function _update_powerline_ps1() {
  # Maximum number of directories to show. -Set by Cj.
  # If --cwd-max-depth isn't working, --cwd-only will.
  local pline_maxdepth=3
  # Display style. Patched is fancy, flat is plain, compatible is in between.
  local pline_mode="patched" # patched, compatible, or flat.

  # Final args to use with powerline-shell.
  local pline_args=("--cwd-max-depth" "$pline_maxdepth" "--mode" "$pline_mode" "--shell" "bash")
  # Last command's return code is always the last arg ($?).
  local pline_ps1
  pline_ps1="$("$cjhome/powerline-shell.py" "${pline_args[@]}" $? 2>/dev/null)"
  export PS1=$pline_ps1
}

function powerlineprompt {
    # Load the powerline prompt.
    export PROMPT_COMMAND="_update_powerline_ps1"
}

# Following prompt created by Cj...
function cjprompt()
{
    unset -v PROMPT_COMMAND
    PS1="${LIGHTBLUEPROMPT}\u${NCPROMPT}:${BLUEPROMPT}\W ${NCPROMPT}\$ "
}

# Function to list prompts that are available.
function listprompts()
{
    echo "cjprompt        - minimal prompt with user:/dir with color."
    echo "defaultprompt   - standard user@host:/dir prompt with color."
    echo "fastprompt      - minimal prompt with [hostname] dir > ."
    echo "powerprompt     - long prompt with extra info like time."
    echo "powerlineprompt - powerline-shell prompt with icons and info."
    echo "simpleprompt    - standard user@host:/dir prompt without color."
}


# Use powerline shell prompt if available -------------------------------------
if [[ -e "$cjhome/powerline-shell.py" ]]; then
    powerlineprompt
else
    # Fall back to cj's prompt where powerline-shell is not available.
    bashextraslog "Falling back to cjprompt (missing $cjhome/powerline-shell.py)"
    cjprompt || {
        simpleprompt
        bashextraslog "Even cj's prompt failed, falling back to simple prompt."
    }
fi

# ---------------------------------- GOODBYE ---------------------------------
# Setup Exit Message
function _exit_message() {
    echo -e "\n${RED}Goodbye ${USER:-.}...$NC"
}
# Trap/Set Exit Function
trap _exit_message EXIT

# --------------------------- AUTO-LOADED PROGRAMS ---------------------------

function favor_fortune {
    # Try displaying a fortune filtered by lolcat (rainbow colored),
    # which favors the 'irc_debian_hackers', 'ascii-art', and 'computers'
    # databases.
    # Falls back to no color if lolcat is missing.
    # Falls back to normal distribution if favorites are missing.
    if which fortune &>/dev/null; then
        local filtercmd
        if which lolcat &>/dev/null; then
            # Filter the fortunes through lolcat.
            filtercmd='lolcat'
        else
            # Plain output (using cat).
            filtercmd='cat'
        fi
        local fortunefiles
        fortunefiles=($(find /usr/share/games/fortunes/ -iregex '[^\.]+$'))

        declare -a fortunedbs
        local filepath
        local dbname
        for filepath in "${fortunefiles[@]}"; do
            dbname="${filepath##*/}"
            [[ -z "$dbname" ]] && continue
            fortunedbs=("${fortunedbs[@]}" "$dbname")
        done

        # Favorite fortune dbs, with a percentage showing their chance at display.
        # The rest are split equally.
        # All of them together must not equal 100%, to give the others a chance.
        declare -A fortunefavs
        fortunefavs=(
            ["50%"]="irc_debian_hackers"
            ["25%"]="ascii-art"
            ["10%"]="computers")
        declare -a fortuneargs
        local favorchance
        local favordb
        for favorchance in "${!fortunefavs[@]}"; do
            favordb="${fortunefavs[$favorchance]}"
            if [[ -e "/usr/share/games/fortunes/$favordb" ]]; then
                fortuneargs=("${fortuneargs[@]}" "$favorchance" "$favordb")
            fi
        done
        fortune "${fortuneargs[@]}" "${fortunedbs[@]}" | "$filtercmd"
    fi
}

# Alias Manager scripts.
aliasmgrfile="/usr/share/aliasmgr/aliasmgr_scripts.sh"
if [[ -f "$aliasmgrfile" ]]; then
    echo ""
    source "$aliasmgrfile"
    bashextraslog "Loaded aliasmgr scripts: $aliasmgrfile"
elif [[ -f "$cjhome/bash.alias.sh" ]]; then
    source "$cjhome/bash.alias.sh"
    bashextraslog "Loaded plain alias script: $cjhome/bash.alias.sh"
fi
unset -v aliasmgrfile

# Show fortune, 'favor_fortune' will be available globally.
favor_fortune

# Print cj's todo list.
if ! which todo &>/dev/null; then
    bashextraslog "Can't find the 'todo' app."
else
    # print todo list
    echo ""
    todo
fi

# Welcome message.
welcomemsg="${BLUE}Bash ${RED}${BASH_VERSION%.*} ${CYAN}Loaded${NC}"
hoststr="${CYAN}$(hostname)${NC}"
ips=($(hostname -I))
ipstr="${RED}${ips[0]}${NC}"
echo -e "\n$welcomemsg  ${BLUE}$(date)${NC}  $hoststr ($ipstr)"
# These vars are not needed globally.
unset -v welcomemsg hoststr ips ipstr

# Remove logging vars/funcs.
unset -v bashextraslogfile
unset -f bashextraslog

# Go Home Cj!
cd
