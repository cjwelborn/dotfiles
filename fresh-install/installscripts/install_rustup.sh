#!/bin/bash

# Downloads rustup.sh, and then runs it.
# This is a little safer than just `curl "$rustup_url" -Ssf | sh`.
# -Christopher Welborn 12-17-2016
appname="Rustup Installer"
appversion="0.0.2"
apppath="$(readlink -f "${BASH_SOURCE[0]}")"
appscript="${apppath##*/}"
appdir="${apppath%/*}"

# Url serving up rustup.sh.
rustup_url="https://sh.rustup.rs"
# Where rustup.sh is downloaded to by default.
rustup_script="$appdir/rustup.sh"
# Args for curl, when no confirmation is wanted.
unsafe_curl_args="-sSf"

# Use ccat if available.
cat_cmd='ccat'
hash ccat || cat_cmd='cat'

function confirm {
    # Confirm a yes/no question.
    local answer
    echo -e "\n${2:-Type C to exit the program.}"
    printf "%s (y/N/c):" "${1:-Continue?}"
    read -r -p " " answer
    if [[ "$answer" =~ ^[cC] ]]; then
        echo_err "\nUser cancelled.\n"
        exit 2
    elif [[ ! "$answer" =~ ^[yY] ]]; then
        return 2
    fi
    return 0
}

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

function get_rustup_sh {
    # Download rustup from $rustup_url using optional args, $1.
    echo_err "Downloading rustup.sh from: $rustup_url"
    curl "$@" "$rustup_url" > "$rustup_script"
}

function print_usage {
    # Show usage reason if first arg is available.
    [[ -n "$1" ]] && echo_err "\n$1\n"

    echo "$appname v. $appversion

    Usage:
        $appscript -h | -v
        $appscript [-d] [-y]

    Options:
        -d,--download : Download only, do not run rustup.sh.
        -h,--help     : Show this message.
        -y,--yes      : Say yes to any confirmation questions,
                        do not review rustup.sh before running (dangerous).
        -v,--version  : Show $appname version and exit.
    "
}

declare -a nonflags
do_dl=0
do_dl_only=0
do_yes=0

for arg; do
    case "$arg" in
        "-d"|"--download" )
            do_dl_only=1
            ;;
        "-h"|"--help" )
            print_usage ""
            exit 0
            ;;
        "-v"|"--version" )
            echo -e "$appname v. $appversion\n"
            exit 0
            ;;
        "-y"|"--yes" )
            do_yes=1
            ;;
        -*)
            fail_usage "Unknown flag argument: $arg"
            ;;
        *)
            nonflags+=("$arg")
    esac
done

do_dl=1
did_dl=0
if ((!do_yes)) && [[ -e "$rustup_script" ]]; then
    confirm "Overwrite it?" "The install script already exists: $rustup_script" || do_dl=0
fi

if ((do_dl)); then
    # Download rustup.sh, overwriting any existing file.
    ((do_yes)) || {
        confirm "Continue?" "This will download rustup.sh from $rustup_url." || fail "User cancelled."
    }

    curlargs=""
    ((do_yes)) && curlargs=$unsafe_curl_args
    get_rustup_sh "$curlargs" > "$rustup_script" || fail "Failed to download rustup.sh!"
    did_dl=1
fi

[[ -e "$rustup_script" ]] || fail "No rustup.sh to review/run!"

((do_yes)) || {
    if confirm "Would you like to review rustup.sh?"; then
        $cat_cmd "$rustup_script" || fail "Failed to view $rustup_script with \`$cat_cmd\`!"
    fi
}

if ((do_dl_only && did_dl)); then
    # No further action needed.
    echo -e "\nDownload completed: $rustup_script"
    exit 0
fi

((do_yes)) || {
    confirm "Continue with installation?" || fail "User cancelled."
}

# Run the install script.
bash "$rustup_script"
