#!/bin/bash

# Clone fzf and install it.
# -Christopher Welborn 12-17-2016
appname="Fzf Installer"
appversion="0.0.1"
apppath="$(readlink -f "${BASH_SOURCE[0]}")"
appscript="${apppath##*/}"
# appdir="${apppath%/*}"


function echo_err {
    # Echo to stderr.
    echo -e "$@" 1>&2
}

function fail {
    # Print a message to stderr and exit with an error status code.
    echo_err "$@"
    exit 1
}

function fail_usage {
    # Print a usage failure message, and exit with an error status code.
    print_usage "$@"
    exit 1
}

function print_usage {
    # Show usage reason if first arg is available.
    [[ -n "$1" ]] && echo_err "\n$1\n"

    echo "$appname v. $appversion

    Clones fzf into ~/clones/fzf, and runs ./install.

    Usage:
        $appscript -d| -h | -v

    Options:
        -d|--dryrun   : Don't do anything, just print the commands that would
                        run.
        -h,--help     : Show this message.
        -v,--version  : Show $appname version and exit.
    "
}

function run_cmd {
    local cmd=$1
    shift
    declare -a cmdargs=("$@")
    if ((do_dryrun)); then
        echo "run: $cmd" "${cmdargs[@]}"
    else
        $cmd "${cmdargs[@]}"
    fi
}

declare -a nonflags
do_dryrun=0

for arg; do
    case "$arg" in
        "-d"|"--dryrun" )
            do_dryrun=1
            ;;
        "-h"|"--help" )
            print_usage ""
            exit 0
            ;;
        "-v"|"--version" )
            echo -e "$appname v. $appversion\n"
            exit 0
            ;;
        -*)
            fail_usage "Unknown flag argument: $arg"
            ;;
        *)
            nonflags+=("$arg")
    esac
done
hash fzf &>/dev/null && {
    echo_err "\`fzf\` is already installed!"
    if hash whichfile &>/dev/null; then
        whichfile fzf
    elif hash which &>/dev/null; then
        which fzf
    else
        type fzf
    fi
    exit 1
}

fzf_url="https://github.com/junegunn/fzf"


run_cmd mkdir -p ~/clones || fail "Unable to create clones directory!"
run_cmd cd ~/clones
run_cmd git clone "$fzf_url" || fail "Unable to clone fzf: $fzf_url"
run_cmd cd fzf || fail "Unable to cd into ~/clones/fzf!"
if [[ -e ~/clones/fzf/install ]]; then
    run_cmd .~/clones/fzf/install || fail "Installer failed!"
else
    fail "Install script was missing: ./install"
fi

compsrc=~/clones/fzf/shell/completion.bash
compdest=/etc/bash_completion.d/fzf
if [[ -e "$compdest" ]]; then
    echo_err "Completion file already exists: $compdest"
else
    if [[ -e "$compsrc" ]]; then
        run_cmd sudo cp "$compsrc" "$compdest" || fail "Failed to copy bash completions!"
    else
        echo_err "Missing bash completion file: $compsrc"
    fi
fi

