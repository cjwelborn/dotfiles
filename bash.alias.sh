#!/bin/bash

# Large list of aliases/functions. Some are used every day, some are just
# "snippets" that I don't ever use.
# Alias Manager used to manage this file for me, but I don't really use it
# anymore.
#        Original: 1-1-14?
# Manual TakeOver: 1-16-17
# -Christopher Welborn

# Aliases:
# try to fix broken packages...
alias aptfix="sudo apt-get install -f"
# Shortcut to sudo apt-get install
alias aptinstall="sudo apt-get install"
# Use --force-overwrite with any apt-get command.
alias apt-get-force-overwrite="sudo apt-get -o Dpkg::Options::='--force-overwrite'"
# Use .agignore file always, if it exists.
[[ -e ~/.agignore ]] && alias ag="ag --path-to-agignore ~/.agignore"
# http://overthewire.org/wargames/bandit
alias banditgame="sshpass -p '8ZjyCRiBWFYkneahHwxCv3wb2a1ORpYL' ssh bandit13@bandit.labs.overthewire.org"
# BFG Repo-Cleaner for git.
alias bfg="java -jar ~/scripts/tools/bfg-1.12.12.jar"
# Print cjs aliases.
alias cjaliases="cj_aliases"
# Print cjs functions.
alias cjfunctions="cj_functions"
# Clears the BASH screen by trickery.
alias clearscreen='echo -e "\033[2J\033[?25l"'
# Vertical directory listing for 'dirs', with indexes.
alias dirs="dirs -v"
# Sudo update and dist-upgrade.
alias distupgrade="sudo apt-get update && sudo apt-get dist-upgrade"
# Echo $PATH, with newlines.
alias echo_path="echo \$PATH | tr ':' '\n'"
# Tell exa to always group directories first.
alias exa="exa --group-directories-first"
# Run green with -vv for more verbosity.
alias greenv="green -vv"
# use colors and regex for grep always
alias grep="grep -E --color=always"
# use colors for howdoi.
alias howdoi="howdoi -c"
# Start the cpython dev version Idle
alias idledev="pythondev \$Clones/cpython/Lib/idlelib/idle.py"
# logout command for KDE...
alias kdelogout="qdbus org.kde.ksmserver /KSMServer logout 0 0 2"
# Shortcut for ls (also helpful for my broken keyboard)
alias l="ls -a --color --group-directories-first"
# List all files in dir
alias la="ls -Fa --color"
# show current linux kernel info/version
alias linuxversion="uname -a"
# Long list dir
alias ll="ls -alh --group-directories-first --color=always"
# Load ps3 controller driver.
alias loadps3="sudo xboxdrv --detach-kernel-driver --silent"
# List dir
alias ls="ls -a --color=always --group-directories-first"
# Just lsof -i
alias lsofnet="lsof -i"
# List dir using tree
alias lt="tree -a -C --dirsfirst | more -s"
# List directories only, using tree (same as `treed`).
alias ltd="tree -a -C -d | more -s"
# A simple lynx dump, with minimal output.
alias lynxdump="lynx -dump -nonumbers -nolist -width=160"
# Prevents clobbering files
alias mkdir="mkdir -p"
# Sort 'ps' list of processes by CPU consumption.
alias mostcpu="ps aux | head -n1 && ps aux | sort -k 3"
# Sorts 'ps' list of processes by memory consumption.
alias mostmemory="ps aux | head -n1 && ps aux | sort -k 4"
# Use mypy, but auto ignore missing type imports (imports with no type info).
alias mypyi="mypy --ignore-missing-imports"
# shellcheck disable=SC2142
# Use netstat to count socket types that are currently open.
alias netstatcount="netstat -n | awk '{print \$1}' | egrep -v 'Proto|Active' | sort | uniq -c"
# Use netstat to show open net sockets.
alias netstatopen="netstat -n | egrep -v '^unix|Proto|Active' | sort -k 4,4"
# Use nmap to show open ports on this machine.
alias nmapopen="sudo nmap -sT -O localhost | grep 'open'"
# Use npm install with a prefix set to $HOME
alias npminstall="npm install --prefix=\$HOME"
# List all installed perl modules (shortcode for cpan -l)
alias perlmods="cpan -l | sort"
# Just a shortcut to php5 -a, thats all.
alias phpi="php5 -a"
# Search for pypi package by name
alias pipsearch="pip search"
# Profile a python 3 script using cProfile
alias profilepy3="python3 -m cProfile"
# Profile a python script using cProfile
alias profilepy="python -m cProfile"
# Profile a pypy script using cProfile
alias profilepypy="pypy -m cProfile"
# Profile a stackless script using cProfile
alias profilestackless="stackless -m cProfile"
# show actual directory (not symlink)
alias pwd="pwd -P"
# Views the documentation pages for PyKDE using chrome.
alias pykdedocpages='google-chrome "/usr/share/doc/python-kde4-doc/html/index.html"'
# Show all listening servers on this machine.
alias servers="sudo netstat -ltupn"
# Use 4 spaces always with shfmt.
alias shfmt="shfmt -i 4"
# SSH into koding.com vm (with XForwarding)
alias sshkoding="ssh -v -X vm-0.cjwelborn.koding.kd.io"
# Show temperature for machines with 'sensors' installed.
alias temp="which sensors &>/dev/null && sensors -f"
# Use 256 colors with tmux.
alias tmux="tmux -2"
# Shows directory tree, directories only...
alias treed="tree -a -C -d | more -s"
# Runs twisted console (reactor already running)
alias twistedconsole="python -m twisted.conch.stdio"
# shows current ubuntu distro version/codename
alias ubuntuversion="lsb_release -a"
# List local users from /etc/passwd
alias userslocal="cut -d: -f1 /etc/passwd | sort"
# Monitor who is pinging this machine.
alias watchpings="sudo tcpdump -i w0 icmp and icmp[icmptype]=icmp-echo"
# Opens a Postgres shell for welbornprod_db.
alias wpdb="psql welbornprod_db"
# Opens SFTP session for welbornprod.com
alias wpsftp="sftp cjwelborn@cjwelborn.webfactional.com"
# Opens SSH session on welbornprod.com
alias wpssh="ssh -X cjwelborn@cjwelborn.webfactional.com"

# Functions:
function apache {
    # Runs /etc/init.d/apache2 with args
    if [[ -z "$1" ]]; then
        echo "apache2 will want an argument."
        return
    fi
    # run apache2 with args
    sudo /etc/init.d/apache2 "$@"
}

function apachelog {
    # Views apache2 logs (error.log by default)
    # shellcheck disable=SC2154
    if [[ -n "$Logs" ]]; then
        local logdir=$Logs
        local logname="${1:-error}_wp_${2:-site}.log"
    else
        local logdir="/var/log/apache2"
        local logname="${1:-error}.log"
    fi
    local logfile="$logdir/$logname"
    echo "Opening apache log: $logfile"
    cat "$logfile"
}

function aptinstall {
    # Install apt package by name
    if [[ -z "$1" ]] ; then
        echo "Usage: aptinstall packagename"
    else
        sudo apt-get install "$@"
    fi
}

function argclinic {
    # Runs argument clinic on a file.
    if [[ -z "$1" ]]; then
        echo "usage: argclinic <file.c>"
        return
    fi
    # shellcheck disable=SC2154
    python3 "$Clones/cpython/Tools/clinic/clinic.py" "$@"
}

function asciimovie {
    # Play a movie in mplayer with the ASCII driver...
    if [[ -z "$1" ]]; then
        printf "usage: asciimovie <filename>\n"
        return
    fi
    printf "playing movie in ascii mode: %s" "$1"
    mplayer -vo caca "$1"
}

function ask {
    # Ask a question
    read -r -p "$* [y/N]:" ans
    case "$ans" in
        y*|Y*) return 0 ;;
        *) return 1 ;;
    esac
}

function birthday {
    # Show this machine's "birth day".
    date --date="$(stat --printf '%y' /lost+found)"
}

function camrecord {
    # record an uncrompressed avi with webcam
    if [[ -z "$1" ]]; then
        echo "Usage: camrecord newfilename.avi"
    else
        mencoder tv:// -tv driver=v4l:width=320:height=240:device=/dev/video0 -nosound -ovc lavc -o "$1"
    fi
}

function ccatp {
    # Use fzfp to select a file, and then ccat it.
    fzfcmd ccat
}

function cdgodir {
    # Change to dir reported by godir.
    if [[ -z "$1" ]]; then
        echo "usage: cdgodir <packagename>"
        echo "see: godir --help"
        return 1
    fi

    local godirname
    godirname="$(godir "$1")"
    if (( $? == 0 )); then
        cd "$godirname" || return 1
        return 0
    fi
    return 1

}

function cdsym {
    # Cd to actual target directory for symlink.
    cd "$(pwd -P)" || return 1
    # This is only here for alias manager. :(
    : :
}

function cj_aliases {
    # Print current aliases.
    local filename=~/bash.alias.sh
    local userpat="${1:-.+}"
    [[ "$userpat" =~ ^(-h)|(--help)$ ]] && {
        printf "Usage: cj_aliases [PATTERN]\n"
        return 0
    }
    local blue="${blue:-$'\e[0;34m'}"
    local cyan="${cyan:-$'\e[0;36m'}"
    local green="${green:-$'\e[0;32m'}"
    local NC="${NC:-$'\e[0m'}"
    local line name cmd cmdfmt cmdname cmdargs
    local prepend="" tryprepend quotepat='^"'
    declare -a prepends=("{" "(")
    while read -r line; do
        cmd="${line#*=}"
        name="${line%%=*}"
        [[ "$name" =~ $userpat ]] || continue
        # Strip quotes from command.
        if [[ "$cmd" =~ $quotepat ]]; then
            cmdfmt="${cmd#\"}"
            cmdfmt="${cmdfmt%\"}"
        else
            # Single quotes.
            cmdfmt="${cmd#\'}"
            cmdfmt="${cmdfmt%\'}"
        fi

        cmdname="${cmdfmt%% *}"
        cmdargs="${cmdfmt#* }"
        prepend=""
        for tryprepend in "${prepends[@]}"; do
            if [[ "$cmdname" == "$tryprepend" ]]; then
                # Special case a couple aliases with brackets.
                cmdname="${cmdargs%% *}"
                cmdargs="${cmdargs#* }"
                prepend="$tryprepend"
            fi
        done
        [[ -n "$prepend" ]] && cmdargs="$prepend $cmdargs"

        printf "%s%24s%s: " "$blue" "$name" "$NC"
        if hash highlight &>/dev/null; then
            printf "%s\n" \
                "$(highlight --style=solarized-dark --syntax=bash --out-format=xterm256  <<<"$cmdname $cmdargs")"
        else
            printf "%s%s%s " "$green" "$cmdname" "$NC"
            printf "%s%s%s\n" "$cyan" "$cmdargs" "$NC"
        fi
    done < <(egrep '^alias' "$filename" | cut -d ' ' -f2-)
}

function cj_functions {
    # Print current functions.
    local filename=~/bash.alias.sh
    local userpat="${1:-.+}"
    [[ "$userpat" =~ ^(-h)|(--help)$ ]] && {
        printf "Usage: cj_functions [PATTERN]\n"
        return 0
    }
    local blue="${blue:-$'\e[0;34m'}"
    local cyan="${cyan:-$'\e[0;36m'}"
    local green="${green:-$'\e[0;32m'}"
    local NC="${NC:-$'\e[0m'}"
    local name body
    while read -r name; do
        # Get the function body from `type`, and indent it.
        [[ "$name" =~ $userpat ]] || continue
        if ! body="$(type "$name" | tail -n +3 | awk '{ print "    "$0 }')"; then
            echo_err "Can't get function body for: $name"
            continue
        fi
        printf "\n%s%s%s:\n" "$blue" "$name" "$NC"
        if hash highlight &>/dev/null; then
            # The molokai (not monokai) style is nice too.
            highlight --style=solarized-dark --syntax=bash --out-format=xterm256  <<<"$body"
        else
            printf "%s%s%s\n" "$cyan" "$body" "$NC"
        fi
    done < <(egrep '^function' "$filename" | cut -d ' ' -f2)
}

function diff {
    # Colorize diffs if stdout is a tty.
    if [[ -t 1 ]]; then
        {
            set -o pipefail
            command diff "$@" | colordiff
        }
    else
        command diff "$@"
    fi
}

function echo_err {
    # Echo to stderr (with escape codes).
    echo -e "$@" 1>&2
}

function exal {
    # Use `exa` to list files in the directory. Use -T for tree view.
    local exal_name="${FUNCNAME[0]}"
    local exal_file="${BASH_SOURCE[0]}"
    # Make sure exa is available, otherwise print some helpful info.
    hash exa 2>/dev/null || {
        printf "
\`exa\` is not installed.
You can get it at: https://github.com/ogham/exa
Or run: \`cargo install --git https://github.com/ogham/exa\`
" 1>&2
        return 1
    }
    declare -a user_args
    # Options for all views, created from try_opts if an alias has not set them.
    declare -a default_opts
    # These options can only be used once,
    # and may already be added to some `exa` alias.
    declare -A try_opts=(
        ["--sort"]="name"
        ["--group-directories-first"]=""
    )
    local optflag optval
    for optflag in "${!try_opts[@]}"; do
        # If this option is not found in some `exa` alias, add it.
        if [[ ! "$(type exa 2>/dev/null)" =~ $optflag ]]; then
            default_opts+=("$optflag")
            optval="${try_opts[$optflag]}"
            # If this option has a value, add it too.
            [[ -n "$optval" ]] && default_opts+=("$optval")
        fi
    done

    # Extra +a,--nohidden option for disabling --all.
    # Also, debug mode flag for `exal`.
    local arg do_all=1 debug_mode=0
    for arg in "$@"; do
        if [[ "$arg" == "+a" ]] || [[ "$arg" == "--nohidden" ]]; then
            do_all=0
        else
            if [[ "$arg" == "--help" ]]; then
                ((debug_mode)) && printf "Running exa --help\n" 1>&2
                printf "Help for \`exa\` via the \`%s\` function in %s\n" "$exal_name" "$exal_file"
                exa --help
                printf "
Extra arguments provided by the \`exal\` function:
  +a, --nohidden     don't use --all, or don't show hidden files.
  -D,--debug         show the command that \`exal\` is running.
"
                return
            elif [[ "$arg" =~ ^(-D)|(--debug)$ ]]; then
                # Don't add this to the exa args, this is for exal only.
                debug_mode=1
            else
                user_args+=("$arg")
            fi
        fi
    done
    if ((do_all)) && [[ ! "${user_args[*]}" =~ --all ]]; then
        default_opts+=("--all")
    fi
    # Columns to show for long-views.
    declare -a try_long_opts=(
        "--long"
        "--binary"
        "--blocks"
        "--group"
        "--header"
        "--inode"
        "--links"
    )
    # Build exa options to use.
    declare -a exa_args
    exa_args+=("${default_opts[@]}")
    # Conflicting --long view args.
    # 	-1, --oneline      display one entry per line
    # 	-x, --across       sort multi-column view entries across
    local long_conflict_pat='(-1)|(--oneline)|(-x)|(--across)'
    if [[ ! "$*" =~ $long_conflict_pat ]]; then
        # User is not passing any conflicting --long args,
        # try some default --long options.
        for optflag in "${try_long_opts[@]}"; do
            # If this option is not found in some `exa` alias, and it's
            # not in the user_args, add it.
            if [[ ! "$(type exa 2>/dev/null)" =~ $optflag ]] && [[ ! "${user_args[*]}" =~ $optflag ]]; then
                exa_args+=("$optflag")
            fi
        done

    fi

    ((debug_mode)) && printf "Running: exa %s %s\n" "${exa_args[*]}" "${user_args[*]}" 1>&2
    if ! exa "${exa_args[@]}" "${user_args[@]}"; then
        # exa failed, add some better help messages for "extra options" errors.
        local exitcode=$?
        local erroutput
        erroutput="$(exa "${exa_args[@]}" "${user_args[@]}" 2>&1)"
        if [[ "$erroutput" == Option* ]]; then
            printf "\nThe \`exal\` function already adds some options to \`exa\`.\n" 1>&2
            if [[ "$erroutput" == *'header'* ]]; then
                printf "If you are looking for help, use --help instead of -h.\n" 1>&2
            fi
        fi
        return $exitcode
    fi
}


function fe {
    # find file and execute command on it
    local pattern=$1
    shift
    local args=("$@")
    ((${#args[@]})) || args=("echo")
    find . -type f -iname "*${pattern}*" -exec "${args[@]}" '{}' ';'
}

function ff {
    # find file
    find . -type f -iname "*${1:-}*" -ls ;
}

function fzfcmd {
    # Use fzfp to select a file, and then run cmd with it.
    local cmd=$1
    shift
    declare -a cmdargs=("$@")
    declare -a filenames
    filenames=($(fzfp --multi))
    # If no filename is selected, don't run it.
    ((${#filenames[@]})) && "$cmd" "${cmdargs[@]}" "${filenames[@]}"
}

function fzfcmddir {
    # Use fzfp to select a file from a certain dir, and then run cmd with it.
    local userdir=$1 cmd=$2
    shift 2
    if [[ ! -d "$userdir" ]] || [[ -z "$cmd" ]]; then
        echo_err "Usage: fzfcmddir DIR CMD [CMD_ARGS...]"
        return 1
    fi
    declare -a cmdargs=("$@")
    declare -a filenames
    filenames=($(fzfdir "$userdir"))
    # If no filename is selected, don't run it.
    ((${#filenames[@]})) && "$cmd" "${cmdargs[@]}" "${filenames[@]}"
}

function fzfco {
    # use fzf to git checkout a branch. Arguments are passed to `git branch`.
    local branches branch
    # Using colr to strip codes from the branch names.
    hash colr &>/dev/null || {
        echo_err "This function requires \`colr\`. Install it with \`pip\`."
        return 1
    }
    if [[ "$*" =~ (-h)|(--help) ]]; then
        echo "This is the \`${cyan}fzfco${NC}\` function from ${cyan}${BASH_SOURCE[0]}${NC}.
It runs ${blue}git checkout [selection]${NC} if you select a branch."
        return 0
    fi
    branches=$(git branch "$@" | grep -v HEAD | colr -x) || {
        echo_err "${RED}No branches found.${NC}"
        return 1
    }
    branch=$(echo "$branches" | fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m)
    [[ -z "$branch" ]] && {
        echo_err "${RED}No branch selected.${NC}"
        return 1
    }
    # Remove leading spaces.
    branch="$(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")"
    [[ -z "$branch" ]] && {
        echo_err "${RED}Something happened while trimming spaces from the
branch name on line ${blue}$((LINENO - 3)){$RED}, function \`${cyan}fzfco${RED}\` \
in ${cyan}${BASH_SOURCE[0]}${RED}.${NC}"
        return 1
    }
    git checkout "$branch"
}

# shellcheck disable=SC2120
function fzfp {
    # Use fzf to select a file, with preview.
    # Number of lines to show in the preview.
    local linecnt=$((${LINES:-$(tput lines)} - 2))
    local highlighter="highlight -O ansi"
    # Ccat is slower, there is a noticeable delay when previewing :(.
    # highlighter="ccat --format terminal --colors"

    # Tell fzf how to preview the file, {} is replaced with the filepath.
    # Don't highlight binary files, if highlight fails, fallback to cat.
    local highlightcmd
    highlightcmd="(
        $highlighter {} || \
        if [[ \$(file {}) =~ text ]]; then \
            cat {}; \
        else \
            echo 'Binary file, no preview available.'; \
        fi\
        ) 2>/dev/null | head -n${linecnt}
    "
    printf "%s" "$(fzf "$@" --preview "$highlightcmd")"
}

function fzfdir {
    # Use fzf to select a file in a certain directory, and print the filename.
    # Uses the fzfp function to select the file.
    if [[ -z "$1" ]] || [[ "$1" =~ ^(-h)|(--help)$ ]]; then
        printf "
Selects files with fzf in a certain directory.

    Usage: fzfdir DIR
    \n"
        [[ -z "$1" ]] && return 1
        return 0
    fi
    find "${1:-$PWD}" | fzfp --multi
}

fzfkill_LINENO=$((LINENO + 1))
function fzfkill {
    # Use fzf to kill a process.
    local a pid aliasfile do_sudo=0
    aliasfile="$(readlink -f "${BASH_SOURCE[0]}")"
    declare -a args
    for a; do
        case "$a" in
            "-h" | "--help")
                echo "Function \`${FUNCNAME[0]}\` in: $aliasfile:$fzfkill_LINENO

    This selects a pid with fzf, and allows you to kill it.

    Usage:
        fzfkill -h
        fzfkill [-s] SIGNAL

    Options:
        SIGNAL     : Signal to send the process.
                     Default: 9
        -h,--help  : Show this message and exit.
        -s,--sudo  : Use \`sudo xargs kill\` instead of \`xargs kill\`."
                return 0
                ;;
            "-s" | "--sudo" )
                do_sudo=1
                ;;
            *)
                args+=("$a")
                ;;
        esac
    done
    ((${#args[@]} == 0)) && args+=("9")
    ((${#args[@]} > 1)) && {
        echo_err "Too many arguments, expecting a SIGNAL or --help."
        return 1
    }
    pid="$(ps -ef | sed 1d | fzf -m | awk '{print $2}')"
    [[ -z "$pid" ]] && return 1
    local xargscmd='xargs'
    ((do_sudo)) && xargscmd="sudo $xargscmd"
    echo "$pid" | $xargscmd kill "-${args[0]}" || {
        local procname
        procname=$(< "/proc/$pid/comm")
        local procinfo
        [[ -n "$procname" ]] && procinfo="$procname "
        if [[ -n "$procinfo" ]]; then
            procinfo="${procinfo} (${pid})"
        else
            procinfo=$pid
        fi
        echo_err "Unable to kill process: $procinfo"$'\n'"..maybe try --sudo?"
        return 1
    }
}


function inetinfo {
    # show current internet information
    echo -e "\nYou are logged on ${RED}$HOST"
    echo -e "\nAdditionnal information:$NC "
    uname -a
    echo -e "\n${RED}Users logged on:$NC "
    w -h
    echo -e "\n${RED}Current date :$NC "
    date
    echo -e "\n${RED}Machine stats :$NC "
    uptime
    echo -e "\n${RED}Memory stats :$NC "
    free
    my_ip 2>&-
    echo -e "\n${RED}Local IP Address :$NC"
    echo "${MY_IP:-"Not connected"}"
    echo -e "\n${RED}ISP Address :$NC"
    echo "${MY_ISP:-"Not connected"}"
    echo -e "\n${RED}Open connections :$NC "
    netstat -pan --inet
    echo
}

function kd {
    # change dir and list contents
    if [[ -z "$1" ]] ; then
        echo "Usage: kd directory_name"
    else
        cd "$1" || return 1
        pwd -P
        ls -a --group-directories-first --color=always
    fi

}

function mkdircd {
    # Make dir and cd to it
    # mkdir -p "$@" && eval cd "\"\$$#\""
    if [[ -z "$1" ]] ; then
        printf "
    Usage: mkdircd [ARGS...] DIR
    Options:
        ARGS  : Arguments for \`mkdir\`. '-p' is already used.
        DIR   : Directory to create and \`cd\` to.
    "
        return 1
    fi
    declare -a args=("$@")
    local lastargi=$((${#args[@]} - 1))
    local dir="${args[$lastargi]}"
    if ! mkdir -p "${args[@]}"; then
        echo_err "Failed to make dir with: ${args[*]}"
        return 1
    fi
    echo "Created $dir"
    if ! cd "$dir"; then
        echo_err "Failed to cd to dir: $dir"
        return 1
    fi
    echo "Moved to $PWD"
    return 0
}

function move_to_col {
    # Move cursor to a certain column number.
    local colnum="${1-0}"
    echo -en "\\033[${colnum}G"
}

function my_ip {
    # set MY_IP variable
    MY_IP=$(/sbin/ifconfig w0 | awk '/inet/ { print $2 } ' | \
    sed -e s/addr://)
    MY_ISP=$(/sbin/ifconfig w0 | awk '/P-t-P/ { print $3 } ' | \
    sed -e s/P-t-P://)
    echo " ip: ${MY_IP}"
    if [[ -n "$MY_ISP" ]]; then
        echo "isp: ${MY_ISP}"
    fi

}

function pip3install {
    # install package for python3 using pip (sudo auto-used)
    if [[ -z "$1" ]]; then
        echo "Usage: pip3install <pkgname> [-g | pipargs]"
        echo "Options:"
        echo "    -g,--global  : Install globally."
        echo "    pipargs      : Send any arguments to pip."
        return
    fi

    if [[ -z "$2" ]]; then
        # Install the package under user by default.
        pip3 install "$@" --user
    elif [[ "$2" =~ ^(-g)|(--global)$ ]]; then
        # Install globally.
        sudo pip3 install "$1"
    else
        # Install with user args.
        pip3 install "$@"
    fi
}

function pipall {
    # Run all pips with arguments.
    if [[ -z "$1" ]]; then
        echo "Usage: pipall [pip args]"
        return
    fi

    pips=("pip" "pip3" "pip-pypy")
    for pipcmd in "${pips[@]}"
    do
        printf "\nrunning: %s %s\n" "${pipcmd}" "${*}"
        if ! sudo "$pipcmd" "$@"; then
            printf "\n\n%s failed!\n" "$pipcmd $*"
            return
        fi
    done
}

function pipinstall {
    # install pip package by name
    if [[ -z "$1" ]]; then
        echo "Usage: pipinstall <pkgname> [-g | pipargs]"
        echo "Options:"
        echo "    -g,--global  : Install globally."
        echo "    pipargs      : Send any arguments to pip."
        return
    fi

    if [[ -z "$2" ]]; then
        # Install the package under user by default.
        pip install "$@" --user
    elif [[ "$2" =~ ^(-g)|(--global)$ ]]; then
        # Install globally.
        sudo pip install "$1"
    else
        # Install with user args.
        pip install "$@"
    fi
}

function pipinstallall {
    # Trys to install a package using all known pip versions..
    if [[ -z "$1" ]]; then
        echo "Usage: pipallinstall <packagename>"
        return
    fi

    pips=("pip" "pip3" "pip-pypy")
    for pipcmd in "${pips[@]}"
    do
        printf "\nrunning: %s install %s\n" "$pipcmd" "$1"
        if ! $pipcmd install "$1" --user; then
            printf "\n\n%s failed!\n" "$pipcmd"
            return
        fi
    done

}

function portscan {
    # scan simple ports 1-255
    if [[ -z "$1" ]]; then
        echo 'usage: portscan [ip or hostname] [nmap options]'
    else
        nmap "$1" -p1-255
    fi
}

function print_failure {
    # display a custom failure message using write_failure
    echo -e -n "$@"
    write_failure "$((${COLUMNS:-80} - 10))"
}

function print_status {
    # Display a status msg with colored marker (success, failure, warning)
    # using the print_success type functions
    # get type of marker to display (success, failure, warning)
    local statustype="${1:-success}"
    # no message will just print the status marker.
    local statusmsg="${2:- }"


    # display msg using print_ functions...
    case $statustype in
        "success"|"ok"|"s"|"-")
            print_success "$statusmsg" ;;
        "failure"|"fail"|"f"|"error"|"err"|"e"|'!')
            print_failure "$statusmsg" ;;
        "warning"|"warn"|"w"|"?")
            print_warning "$statusmsg" ;;
        *)
            # Default, success.
            print_success "$statusmsg" ;;
    esac
}

function print_success {
    # displays a custom success msg using write_success
    echo -e -n "$@"
    write_success "$((${COLUMNS:-80} - 10))"
}

function print_warning {
    # displays custom warning message using write_warning
    echo -e -n "$@"
    write_warning "$((${COLUMNS:-80} - 10))"
}

function pscores {
    # Show which cores a process is using (PSR column in ps), by name
    if [[ -z "$1" ]]; then
        echo "Usage: pscoresname <name_or_pid>"
        return
    fi
    local pname
    if ! pname="$(pidname "$1" --pidonly)"; then
        echo_err "Unable to get pid for: $1"
        return 1
    fi
    ps -p "$pname" -L -o command,pid,tid,psr,pcpu
}

function pylite {
    # highlite a python file, output to console
    if [[ -z "$1" ]]; then
        echo "usage: pylite_ [pythonfile.py]"
    else
        pygmentize -l python -f terminal -P style=borland -O full "$1"
    fi
}

function pylitegif {
    # highlite a python file, output to gif file.
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo "usage: pylitegif [srcfile.py] [output.gif]"
        return 1
    fi
    pygmentize -l python -f gif -P style=borland -O full -o "$2" "$1"
}

function pylitepng {
    # highlite a python file, output to png file.
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo "usage: pylitepng [srcfile.py] [output.png]"
        return 1
    fi
    pygmentize -l python -f png -P style=borland -O full -o "$2" "$1"
}

function shead {
    # 'Smart' head, or 'screen' head. uses screen height for -n.
    head -n "$(($(tput lines) - 1))" "$@"
    :
}

function showmyip {
    # shows current IP address
    echo "Gathering IP Address..."
    # Setting a global here on purpose.
    MY_IP="$(/sbin/ifconfig w0 | awk '/inet/ { print $2 } ' | \
    sed -e s/addr://)"
    echo " ip: $MY_IP"
}

function sshver {
    # connect to ssh server and get version, then disconnect
    telnet "$1" 22 | grep "SSH"
    # Force alias manager to make this a function :(
    : :
}

function stail {
    # 'Smart' tail, or 'screen' tail. uses screen height for -n.
    tail -n "$(($(tput lines) - 1))" "$@"
    :
}

function switchroot {
    # Use the chroot's that are setup.
    defaultname="wheezy_raspbian" # the only chroot setup right now.
    usingname=""
    chrootargs=""

    if [[ -z "$1" ]]; then
        echo "Using default chroot: ${defaultname}"
        usingname=$defaultname
    elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        # Show usage.
        echo "usage: switchroot <name> [other args]"
        return
    fi
        # Have args.
        args=("$@")
        usingname="${args[0]}"
    if [[ "$1" =~ ^- ]]; then
        # args passed without name.
        usingname=$defaultname
        chrootargs=("$@")
    else
        # name was passed, trim the rest of the args.
        chrootargs=("${args[@]:1}")
    fi


    if (( ${#chrootargs[@]} == 0 )); then
        echo "Opening chroot $usingname..."
        schroot -c "$usingname"
    else
        echo "Opening chroot $usingname with args: ${chrootargs[*]}"
        schroot -c "$usingname" "${chrootargs[@]}"
    fi


}

function symlink {
    # create a symbolic link arg2 = arg1
    if [[ -z "$1" ]] ; then
        echo_err "expecting path to linked file. (source)"
        echo_err "usage: symlink sourcefile destfile"
        return 1
    elif [[ -z "$2" ]] ; then
        echo_err "expecting path to link. (destination)"
        echo_err "usage: symlink sourcefile destfile"
        return 1
    fi
    # Create the link
    ln -s "$1" "$2"
}

function tarlist {
    # list files in a tar archive...
    if (( $# == 0 )); then
        echo 'usage: tarlist [tarfile.tar]'
        return 1
    fi
    tar -tvf "$@"

}

function userslogin {
    # List all users with login capabilities.
    # shellcheck disable=SC2016
    # ..These are awk parameters, not bash parameter.. shellcheck :(
    sudo awk -F':' '$2 ~ "\\$" {print $1}' /etc/shadow | sort

}

function weatherday {
    # display weather per zipcode
    if [[ -z "$1" ]]; then
        # echo "Usage: weather 90210"
        lynx -dump -nonumbers -width=160 "http://weather.unisys.com/forecast.php?Name=35501" | grep -A13 'Latest Observation'
    else
        lynx -dump -nonumbers -width=160 "http://weather.unisys.com/forecast.php?Name=$1" | grep -A13 'Latest Observation'
    fi
}

function weatherweek {
    # show weather for the week per zipcode
    if [[ -z "$1" ]] ; then
        # echo "Usage: weatherweek [Your ZipCode]"
        lynx -dump -nonumbers -width=160 "http://weather.unisys.com/forecast.php?Name=35501" | grep -A30 'Forecast Summary'
    else
        lynx -dump -nonumbers -width=160 "http://weather.unisys.com/forecast.php?Name=$1" | grep -A30 'Forecast Summary'
    fi
}

function wmswitch {
    # switch window managers
    if [[ -z "$1" ]] ; then
        echo "Usage: wmswitch windowmanager"
        echo " Like: wmswitch lightdm"
        return 1
    fi

    sudo dpkg-reconfigure "$1"
}

function wpcd {
    # cd to wp development dir if not already there.
    # shellcheck disable=SC2154
    if [[ "$PWD" != "$Wp" ]]; then
        echo "Moving to wp development dir: $Wp"
        cd "$Wp" || return 1
    fi
}

function wpfcgi {
    # run welbornprod as fcgi [old]...
    wpcd
    python3 manage.py runfcgi "method=threaded" "host=127.0.0.1" "port=3033" "debug=true" "daemonize=false" "pidfile=fcgi_pid"
}

function wpmemory {
    # Shows processes and memory usage for apache.
    # shellcheck disable=SC2009
    ps aux | head -n1 && ps aux | grep 'www-data' | grep -v 'grep'

}

function wpprofile {
    # Runs a profile server at 127.0.0.1:8080, data in ~/dump/wp-profile
    if [[ -d /home/cj/dump/wp-profile ]]; then
        echo "Deleting files in ~/dump/wp-profile"
        rm /home/cj/dump/wp-profile/*
    else
        echo "Creating dir ~/dump/wp-profile"
        mkdir /home/cj/dump/wp-profile
    fi


    wpcd
    echo "Starting server..."
    ./manage runprofileserver --kcachegrind "--prof-path=/home/cj/dump/wp-profile" "127.0.0.1:8080"
}


function write_failure {
    # print a red FAILURE message about 71 columns in
    # all of these were inspired by Fedora's (i think) init.d/functions"
    local colnumber="${1:-71}"
    # move to position
    echo -en "\\033[${colnumber}G"
    # shellcheck disable=SC2154
    echo -en "$red"
    echo -n '['
    echo -en "$RED"
    echo -n 'FAILURE'
    echo -en "$red"
    echo ']'
}

function write_success {
    # print a green 'SUCCESS' msg about 71 columns in
    # all of these were inspired by Fedora's (i think) init.d/functions"
    local colnumber="${1:-71}"
    # move to position
    echo -en "\\033[${colnumber}G"
    # shellcheck disable=SC2154
    echo -en "$green"
    echo -n '['
    echo -en "$LIGHTGREEN"
    echo -n 'SUCCESS'
    echo -en "$green"
    echo ']'

}

function write_warning {
    # print a yellow WARNING msg about 71 columns in
    # all of these were inspired by Fedora's (i think) init.d/functions"
    local colnumber="${1:-71}"
    # move to position
    echo -en "\\033[${colnumber}G"
    # shellcheck disable=SC2154
    echo -en "$lightyellow"
    echo -n '['
    echo -en "$YELLOW"
    echo -n 'WARNING'
    echo -en "$lightyellow"
    echo ']'
}

function ziplist {
    # list files in a zip file
    if (( $# == 0 )); then
        echo "Usage: ziplist <filename.zip>"
        return 1
    fi

    unzip -l "$@"
}

# Exports:
export apache
export apachelog
export aptinstall
export argclinic
export asciimovie
export ask
export birthday
export camrecord
export ccatp
export cdgodir
export cdsym
export cj_aliases
export cj_functions
export diff
export echo_err
export exal
export fe
export ff
export fzfcmd
export fzfcmddir
export fzfdir
export fzfp
export fzfkill
export inetinfo
export kd
export mkdircd
export move_to_col
export my_ip
export pip3install
export pipall
export pipinstall
export pipinstallall
export portscan
export print_failure
export print_status
export print_success
export print_warning
export pscores
export pylite
export pylitegif
export pylitepng
export shead
export showmyip
export sshver
export stail
export switchroot
export symlink
export tarlist
export userslogin
export weatherday
export weatherweek
export wmswitch
export wpcd
export wpfcgi
export wpmemory
export wpprofile
export write_failure
export write_success
export write_warning
export ziplist
