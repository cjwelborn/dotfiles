#!/bin/bash

# My install script, that installs packages that I use frequently.
# -Christopher Welborn 05-31-2016
appname="fresh-install"
appversion="0.0.1"
apppath="$(readlink -f "${BASH_SOURCE[0]}")"
appscript="${apppath##*/}"
appdir="${apppath%/*}"

filename_pkgs="$appdir/fresh-install-pkgs.txt"
filename_pip2_pkgs="$appdir/fresh-install-pip2-pkgs.txt"
filename_pip3_pkgs="$appdir/fresh-install-pip3-pkgs.txt"
required_files=("$filename_pkgs" "$filename_pip2_pkgs" "$filename_pip3_pkgs")

function check_required_files {
    # Check for at least one required file before continuing.
    required_cnt=0
    for requiredfile in "${required_files[@]}"; do
        [[ -e "$requiredfile" ]] && let required_cnt+=1
    done
    if ((required_cnt == 0)); then
        echo_err "Missing all required package list files!"
        for requiredfile in "${required_files[@]}"; do
            echo_err "    $requiredfile"
        done
        return 1
    fi
    if ((required_cnt != ${#required_files[@]})); then
        echo_err "Missing some required package list files,"
        echo_err "...some packages may not be installed."
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

function generate_apt_cmd {
    # Generate an apt-get install command to install packages from
    # fresh-install-pkgs.txt
    if [[ ! -e "$filename_pkgs" ]]; then
        echo_err "Cannot install apt packages, missing $filename_pkgs."
        return 1
    fi
    local pkgs
    mapfile -t pkgs < "$filename_pkgs"
    printf "sudo apt-get install %s" "$(printf "%s " "${pkgs[@]}")"
}

function generate_pip_cmd {
    # Generate a pip install comand to install packages from
    # fresh-install-pip$1.txt
    local ver="${1:-3}"
    local varname="filename_pip${ver}_pkgs"
    local filename="${!varname}"
    if [[ ! -e "$filename" ]]; then
        echo_err "Cannot install pip${ver} packages, missing ${filename}."
        return 1
    fi
    declare -a sudopkgs
    declare -a normalpkgs
    local sudopkgs
    local normalpkgs
    local pkgname
    local sudopat='^\*'
    while IFS=$'\n' read -r pkgname; do
        if [[ "$pkgname" =~ $sudopat ]]; then
            sudopkgs=("${sudopkgs[@]}" "${pkgname:1}")
        else
            normalpkgs=("${normalpkgs[@]}" "$pkgname")
        fi
    done < "$filename"
    if ((${#sudopkgs[@]} == 0 && ${#normalpkgs[@]} == 0)); then
        echo_err "No pip${ver} packages found in $filename."
        return 1
    fi
    local finalcmd=""
    if ((${#sudopkgs[@]})); then
        local sudocmd
        sudocmd="sudo pip${ver} install $(printf "%s " "${sudopkgs[@]}")"
        finalcmd="$sudocmd;"
    fi
    if ((${#normalpkgs[@]})); then
        local normalcmd
        normalcmd="pip${ver} install $(printf "%s " "${normalpkgs[@]}")"
        finalcmd="${finalcmd}$normalcmd"
    fi
    if [[ -z "$finalcmd" ]]; then
        echo_err "No pip${ver} packages to install."
        return 1
    fi
    printf "%s" "$finalcmd"
}

function is_system_pip {
    # Returns a success exit status if the pip package is found in the
    # global dir.
    local ver="${1:-3}"
    local pkg=$2
    [[ -n "$pkg" ]] || fail "Expected a package name for is_system_pip!"
    local pkgdirs=("/usr/lib" "/usr/local/lib")
    for pkgdir in "${pkgdirs[@]}"; do
        if ls -d "${pkgdir}/python${ver}"*"/dist-packages/${pkg}" &>/dev/null; then
            return 0
        elif ls "${pkgdir}/python${ver}"*"/dist-packages/${pkg}.py" &>/dev/null; then
            return 0
        fi
    done
    return 1
}

function list_packages {
    # List installed packages on this machine.
    local blacklisted=("linux-image" "linux-signed" "nvidia")
    local blacklistpat=""
    for pkgname in "${blacklisted[@]}"; do
        [[ -n "$blacklistpat" ]] && blacklistpat="${blacklistpat}|"
        blacklistpat="${blacklistpat}($pkgname)"
    done
    # shellcheck disable=SC2016
    # ...single-quotes are intentional.
    comm -13 \
      <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort) \
      <(comm -23 \
        <(dpkg-query -W -f='${Package}\n' | sed 1d | sort) \
        <(apt-mark showauto | sort) \
      ) | grep -E -v "$blacklistpat"
}

function list_pip {
    # List installed pip packages.
    local ver="${1:-3}"
    local exe="pip${ver}"
    local exepath
    if ! exepath="$(which "$exe" 2>/dev/null)"; then
        fail "Failed to locate $exe!"
    else
        [[ -n "$exepath" ]] || fail "Failed to locate $exe"
    fi
    local pkgname
    for pkgname in $($exepath list | cut -d' ' -f1); do
        if is_system_pip "$ver" "$pkgname"; then
            echo "*${pkgname}"
        else
            echo "$pkgname"
        fi
    done
}

function print_usage {
    # Show usage reason if first arg is available.
    [[ -n "$1" ]] && echo_err "\n$1\n"

    echo "$appname v. $appversion

    Usage:
        $appscript -h | -l | -l2 | -l3 | -v
        $appscript [-a] [-p2] [-p3]

    Options:
        -a,--apt        : Install apt packages.
        -h,--help       : Show this message.
        -l,--list       : List installed packages on this machine.
                          Used to build this/other install scripts.
        -l2,--listpip2  : List installed pip 2.7 packages on this machine.
                          Used to build this/other install scripts.
        -l3,--listpip3  : List installed pip 3 packages on this machine.
                          Used to build this/other install scripts.
        -p2,--pip2      : Install pip2 packages.
        -p3,--pip3      : Install pip3 packages.
        -v,--version    : Show $appname version and exit.
    "
}

function run_cmd {
    # Run a command, unless dry_run is set (then just print it).
    local cmd=$1
    local desc="${2:-Running $1}"
    ((${#desc} > 80)) && desc="${desc:0:80}..."
    echo -e "\n\n$desc\n"
    if ((dry_run)); then
        echo "$cmd"
    else
        $cmd
    fi
}

# Make sure we have at least one package list to work with.
check_required_files || exit 1

declare -a nonflags
dry_run=0
do_all=1
do_apt=0
do_pip2=0
do_pip3=0

for arg; do
    case "$arg" in
        "-a"|"--apt" )
            do_apt=1
            do_all=0
            ;;
        "-d"|"--dryrun" )
            dry_run=1
            ;;
        "-h"|"--help" )
            print_usage ""
            exit 0
            ;;
        "-l"|"--list" )
            list_packages
            exit
            ;;
        "-l2"|"--listpip2" )
            list_pip "2"
            exit
            ;;
        "-l3"|"--listpip3" )
            list_pip "3"
            exit
            ;;
        "-p2"|"--pip2" )
            do_pip2=1
            do_all=0
            ;;
        "-p3"|"--pip3" )
            do_pip3=1
            do_all=0
            ;;
        "-v"|"--version" )
            echo -e "$appname v. $appversion\n"
            exit 0
            ;;
        -*)
            fail_usage "Unknown flag argument: $arg"
            ;;
        *)
            nonflags=("${nonflags[@]}" "$arg")
    esac
done

if ((do_all || do_apt)); then
    echo "Updating package list..."
    sudo apt-get update || fail "Failed to update the packages list!"
    run_cmd "$(generate_apt_cmd)" "Installing apt packages..."
fi
((do_all || do_pip2)) && run_cmd "$(generate_pip_cmd 2)" "Installing pip2 packages..."
((do_all || do_pip3)) && run_cmd "$(generate_pip_cmd 3)" "Installing pip3 packages..."
