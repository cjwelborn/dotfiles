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

# Set dir_colors if it exists.
dircolorsfile="$cjhome/.dir_colors"
if [[ -e "$dircolorsfile" ]]; then
    eval "$(dircolors "$dircolorsfile")"
    echo "dir_colors set from: $dircolorsfile"
fi

# Define some colors first: (SC2034 = Unused vars (they are exported))
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
# --> Nice. Has the same effect as using "ansi.sys" in DOS.

#Set Hilite Color for 3rd Party Prompts
if [[ "${DISPLAY%%:0*}" != "" ]]; then
    HILIT=${redprompt}   # remote machine: prompt will be partly red
else
    HILIT=${cyanprompt}  # local machine: prompt will be partly cyan
fi

# ------------------------------- PROMPT FUNCTIONS ----------------------------

# Following simple/default prompt function from original simple/fancy prompts...
    function simpleprompt()
    {
        # depends on debian_chroot being available:
        # shellcheck disable=SC2154
        PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
    }

    function defaultprompt()
    {
        # depends on debian_chroot being available:
        # shellcheck disable=SC2154
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

        PROMPT_COMMAND=_powerprompt
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
# Following prompt created by Cj...
    function cjprompt()
    {
         PROMPT_COMMAND=
         PS1="${LIGHTBLUEPROMPT}\u${NCPROMPT}:${BLUEPROMPT}\W ${NCPROMPT}\$ "
    }

# Function to list prompts that are available.
    function listprompts()
    {
        echo "cjprompt       - minimal prompt with user:/dir with color."
        echo "defaultprompt  - standard user@host:/dir prompt with color."
        echo "fastprompt     - minimal prompt with [hostname] dir > ."
        echo "powerprompt    - long prompt with extra info like time."
        echo "simpleprompt   - standard user@host:/dir prompt without color."
    }

# Use Cj's Preferred Prompt! -------------------------------------------------
# cjprompt # Ditched for powerline-shell instead. (if available, see below)

# Use powerline shell prompt. ------------------------------------------------
function _update_ps1() {
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
if [[ -f "$cjhome/powerline-shell.py" ]]; then
  export PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
else
  # Fall back to cj's prompt where powerline-shell is not available.
  cjprompt
fi

# ---------------------------------- GOODBYE ---------------------------------
# Setup Exit Message
function _exit_message() {
    echo -e "\n${RED}Goodbye ${USER:-.}...$NC"
}
# Trap/Set Exit Function
trap _exit_message EXIT

# --------------------------- AUTO-LOADED PROGRAMS ---------------------------

# Alias Manager scripts.
aliasmgrfile="/usr/share/aliasmgr/aliasmgr_scripts.sh"
if [[ -f "$aliasmgrfile" ]]; then
  echo ""
  source "$aliasmgrfile"
elif [[ -f "$cjhome/bash.alias.sh" ]]; then
    source "$cjhome/bash.alias.sh"
fi

# Show fortune
if [[ -x /usr/games/fortune ]]; then
    if [[ -x "$cjhome/gems/bin/lolcat" ]]; then
        # Add rainbow color if available.
        fortune -a | lolcat
    else
        fortune -a
    fi
fi

# Print cj's todo list.
if ! which todo &>/dev/null; then
    echo "todo: Can't find the todo app."
else
    # print todo list
    echo ""
    todo
fi

# Welcome message.
welcomemsg="${BLUE}Bash ${RED}${BASH_VERSION%.*} ${CYAN}Loaded${NC}"
hoststr="${CYAN}$(hostname)"
ipstr="${RED}$(hostname -I)"
if (( ${#ipstr} > 24 )); then
  ipstr="${ipstr:0:24}${NC} ..."
fi
echo -e "\n$welcomemsg  $(date)  $hoststr ( $ipstr)"

# Go Home Cj!
cd
