#!/bin/bash
# System-wide .bashrc file for interactive bash(1) shells.

# To enable the settings / commands in this file for login shells as well,
# this file has to be sourced in /etc/profile.

if [[ -d "/home/cjwelborn" ]]; then
	cjhome="/home/cjwelborn"
elif [[ -d "/home/cj" ]]; then
	cjhome="/home/cj"
elif [[ -d "$HOME" ]]; then
	cjhome=$HOME
elif [[ -n "$USER" ]] && [[ -d "/home/$USER" ]]; then
	cjhome="/home/$USER"
else
	cjhome="/root"
fi

# Enable cj's non-interactive bash stuff.
nonactive_extras_name="bash.extras.non-interactive.sh"
nonactive_extras_path="$cjhome/$nonactive_extras_name"
if [[ -f "$nonactive_extras_path" ]]; then
    source "$nonactive_extras_path"
else
    [ -n "$PS1" ] && echo "Non-interactive bash file not found: $nonactive_extras_path"
fi

# If not running interactively, don't do anything --------------------
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi



# Commented out, don't overwrite xterm -T "title" -n "icontitle" by default.
# If this is an xterm set the title to user@host:dir
#case "$TERM" in
#xterm*|rxvt*)
#    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
#    ;;
#*)
#    ;;
#esac

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# enable bash completion in interactive shells
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# sudo hint
if [ ! -e "$HOME/.sudo_as_admin_successful" ]; then
    case " $(groups) " in *\ admin\ *)
    if [ -x /usr/bin/sudo ]; then
    cat <<-EOF
    To run a command as administrator (user "root"), use "sudo <command>".
    See "man sudo_root" for details.

EOF
    fi
    esac
fi

# if the command-not-found package is installed, use it
if [ -x /usr/lib/command-not-found -o -x /usr/share/command-not-found ]; then
    function command_not_found_handle {
        # check because c-n-f could've been removed in the meantime
        if [ -x /usr/lib/command-not-found ]; then
           /usr/bin/python /usr/lib/command-not-found -- "$1"
           return $?
        elif [ -x /usr/share/command-not-found ]; then
           /usr/bin/python /usr/share/command-not-found -- "$1"
           return $?
        else
           return 127
        fi
    }
fi

# Enable cj's bash extras. (prompts, colors, etc.)
active_extras_name="bash.extras.interactive.sh"
active_extras_path="$cjhome/$active_extras_name"
if [[ -f "$active_extras_path" ]]; then
    source "$active_extras_path"
elif [[ -f "$HOME/$active_extras_name" ]]; then
	source "$HOME/$active_extras_name"
fi
