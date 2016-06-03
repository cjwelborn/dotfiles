#!/bin/bash

# My install script, that installs packages that I use frequently.
# -Christopher Welborn 05-31-2016

shopt -s nullglob

appname="fresh-install"
appversion="0.0.1"
apppath="$(readlink -f "${BASH_SOURCE[0]}")"
appscript="${apppath##*/}"
appdir="${apppath%/*}"

filename_pkgs="$appdir/fresh-install-pkgs.txt"
filename_pip2_pkgs="$appdir/fresh-install-pip2-pkgs.txt"
filename_pip3_pkgs="$appdir/fresh-install-pip3-pkgs.txt"
required_files=("$filename_pkgs" "$filename_pip2_pkgs" "$filename_pip3_pkgs")

# This can be set with the --debug flag.
debug_mode=0

function check_required_files {
    # Check for at least one required file before continuing.
    debug "Checking for required package list files."
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

function clone_repo {
    # Clone a repo into a temporary directory, and print the directory.
    # Arguments:
    #   $1 : Repo url.
    #   $2 : Arguments for git.
    local tmpdir
    local repo=$1
    shift
    local gitargs=("$@")
    if [[ -z "$repo" ]]; then
        echo_err "No repo given to clone_repo!"
        return 1
    fi
    if ! tmpdir="$(mktemp -d -p /tmp "${appname/ /-}.XXX")"; then
        echo_err "Failed to create temporary directory!"
        return 1
    fi
    debug "Cloning repo '$repo' to $tmpdir."
    if ! git clone "${gitargs[@]}" "$repo" "$tmpdir"; then
        echo_err "Failed to clone repo: $repo"
        return 1
    fi
    printf "%s" "$tmpdir"
}

function copy_file {
    # Copy a file, unless dry_run is set.
    local src=$1
    local dest=$2
    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for copy_file!"
        return 1
    fi
    if ((dry_run)); then
        printf "Copy %s -> %s\n" "$src" "$dest"
    else
        debug "Copy $src -> $dest"
        cp "$@"
    fi
}

function copy_file_sudo {
    # Copy a file using sudo, unless dry_run is set.
    local src=$1
    local dest=$2
    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for copy_file_sudo!"
        return 1
    fi
    if ((dry_run)); then
        printf "Copy (sudo) %s -> %s\n" "$src" "$dest"
    else
        debug "Copy (sudo) $src -> $dest"
        sudo cp "$@"
    fi
}

function copy_files {
    # Safely copy files from one directory to another.
    # Arguments:
    #   $1 : Source directory.
    #   $2 : Destination directory.
    #   $3 : Blacklist pattern, optional.
    local src=$1
    local dest=$2
    local blacklistpat=$3
    if [[ -n "$blacklistpat" ]]; then
        blacklistpat="($blacklistpat)|(README)"
    else
        blacklistpat="(README)"
    fi
    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for copy_files!"
        return 1
    fi
    local dirfiles=("$src"/*)
    echo "DIRFILES:" "${dirfiles[@]}"
    if ((${#dirfiles[@]} == 0)); then
        echo_err "No files to install in $repodir."
        return 1
    fi
    local srcfilepath
    local srcfilename

    for srcfilepath in "${dirfiles[@]}"; do
        srcfilename="${srcfilepath##*/}"
        debug "Checking $srcfilename against $blacklistpat"
        [[ -z "$srcfilename" ]] && continue
        [[ "$srcfilename" =~ $blacklistpat ]] && continue
        if [[ -e "${dest}/$srcfilename" ]]; then
            if [[ -f "$srcfilepath" ]]; then
                echo "Backing up existing file: ~/$srcfilename"
                if ! copy_file "${home}/${srcfilename}" "${home}/${srcfilename}~"; then
                    echo_err "Failed to backup file: ${home}/${srcfilename}"
                    echo_err "    I will not overwrite the existing file."
                    continue
                fi
            elif [[ -d "$srcfilepath" ]]; then
                echo "Backing up existing dir: ~/$srcfilename"
                if ! copy_file -r "${home}/${srcfilename}" "${home}/${srcfilename}~"; then
                    echo_err "Failed to backup directory: ${home}/${srcfilename}"
                    echo_err "    I will not overwrite the existing directory."
                    continue
                fi
            fi
        fi
        if [[ -f "$srcfilepath" ]]; then
            if ! copy_file "$srcfilepath" "${home}/${srcfilename}"; then
                echo_err "Failed to copy file: ${srcfilepath} -> ${home}/${srcfilename}"
            fi
        elif [[ -d "$srcfilepath" ]]; then
            if ! copy_file -r "$srcfilepath" "${home}/${srcfilename}"; then
                echo_err "Failed to copy directory: ${srcfilepath} -> ${home}/${srcfilename}"
            fi
        else
            echo_err "Unknown file type: $srcfilepath"
            continue
        fi
    done

    return 0
}
function debug {
    # Echo a debug message to stderr if debug_mode is set.
    if ((debug_mode)); then echo_err "$@"; fi
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

function generate_apt_cmds {
    # Generate an apt-get install command to install packages from
    # fresh-install-pkgs.txt
    if [[ ! -e "$filename_pkgs" ]]; then
        echo_err "Cannot install apt packages, missing $filename_pkgs."
        return 1
    fi
    local pkgs
    mapfile -t pkgs < "$filename_pkgs"
    printf "sudo apt-get -y --ignore-missing install %s;\n" "${pkgs[@]}"
}

function generate_pip_cmds {
    # Generate a pip install comand to install packages from
    # fresh-install-pip$1.txt
    local ver="${1:-3}"
    local varname="filename_pip${ver}_pkgs"
    local filename="${!varname}"
    if [[ ! -e "$filename" ]]; then
        echo_err "Cannot install pip${ver} packages, missing ${filename}."
        return 1
    elif ! which "pip${ver}" &>/dev/null; then
        echo_err "Cannot find pip${ver} executable!"
        return 1
    fi
    declare -a sudopkgs
    declare -a normalpkgs
    local sudopkgs
    local normalpkgs
    local pkgname
    local sudopat='^\*'
    local commentpat='^[ \t]+?#'
    while IFS=$'\n' read -r pkgname; do
        # Ignore comment lines.
        [[ "$pkgname" =~ $commentpat ]] && continue
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
        finalcmd="# Python $ver GLOBAL pip command:"$'\n'
        sudocmd="$(printf "sudo pip${ver} install %s;\n" "${sudopkgs[@]}")"
        finalcmd="${finalcmd}${sudocmd};"$'\n'
    fi
    if ((${#normalpkgs[@]})); then
        local normalcmd
        finalcmd="${finalcmd}"$'\n'"# Python $ver LOCAL pip command:"$'\n'
        normalcmd="$(printf "pip${ver} install %s;\n" "${normalpkgs[@]}")"
        finalcmd="${finalcmd}${normalcmd}"
    fi
    if [[ -z "$finalcmd" ]]; then
        echo_err "No pip${ver} packages to install."
        return 1
    fi
    echo "$finalcmd"
}

function install_config {
    # Install config files from github.com/cjwelborn/cj-config.git
    local repodir
    if ! repodir="$(clone_repo "https://github.com/cjwelborn/cj-config.git")"; then
        echo_err "Repo clone failed, cannot install config."
        return 1
    else
        debug "Changing to repo directory: $repodir"
        if ! cd "$repodir"; then
            echo_err "Failed to cd into repo: $repodir"
            return 1
        fi
        debug "Updating config submodules..."
        if ! git submodule update --init; then
            echo_err "Failed to update submodules!"
            return 1
        fi
    fi
    local home="${HOME:-/home/$USER}"
    debug "Copying config files..."
    if ! copy_files "$repodir" "$home"; then
        echo_err "Failed to copy files: $repodir -> $home"
        return 1
    fi
    if [[ -n "$repodir" ]] && [[ "$repodir" =~ $appname ]] && [[ -e "$repodir" ]]; then
        debug "Removing temporary repo dir: $repodir"
        if ! sudo rm -r "$repodir"; then
            echo_err "Failed to remove temporary dir: $repodir"
            return 1
        fi
    fi
    return 0
}

function install_dotfiles {
    # Install dotfiles files from github.com/cjwelborn/cj-dotfiles.git
    local repodir
    if ! repodir="$(clone_repo "https://github.com/cjwelborn/cj-dotfiles.git")"; then
        echo_err "Repo clone failed, cannot install dot files."
        return 1
    fi
    local home="${HOME:-/home/$USER}"
    debug "Copying dot files..."
    if ! copy_files "$repodir" "$home" 'fresh-install'; then
        echo_err "Failed to copy files: $repodir -> $home"
        return 1
    fi
    if [[ -e "${home}/bash.bashrc" ]]; then
        echo "Installing global bashrc."
        if [[ -e /etc/bash.bashrc ]]; then
            echo "Backing up global bashrc."
            copy_file_sudo '/etc/bash.bashrc' '/etc/bash.bashrc~'
        fi
        copy_file_sudo "${home}/bash.bashrc" "/etc/bash.bashrc"
    fi
    if [[ -n "$repodir" ]] && [[ "$repodir" =~ $appname ]] && [[ -e "$repodir" ]]; then
        debug "Removing temporary repo dir: $repodir"
        if ! sudo rm -r "$repodir"; then
            echo_err "Failed to remove temporary dir: $repodir"
            return 1
        fi
    fi
    return 0
}

function is_system_pip {
    # Returns a success exit status if the pip package is found in the
    # global dir.
    local ver="${1:-3}"
    local pkg=$2
    [[ -n "$pkg" ]] || fail "Expected a package name for is_system_pip!"
    local pkgloc
    if ! pkgloc="$(pip"$ver" show "$pkg" | grep Location | cut -d ' ' -f 2)"; then
        # Assume errors are system packages.
        return 0
    fi
    # Assume empty locations are system packages.
    [[ -n "$pkgloc" ]] || return 0
    # Package locations not starting with /home are considered system packages.
    [[ "$pkgloc" =~ ^/home ]] || return 0
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
    debug "Gathering installed apt packages ( ignoring" "${blacklisted[@]}" ")."
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
    debug "Listing pip${ver} packages..."
    local pkgname
    echo "# Packages marked with * are global packages, and require sudo to install."
    for pkgname in $($exepath list | cut -d' ' -f1); do
        debug "Checking for system/local package: $pkgname"
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
        $appscript -h | -v
        $appscript [-l] [-l2] [-l3] [-D]
        $appscript [-a] [-c] [-f] [-p2] [-p3] [-D]

    Options:
        -a,--apt        : Install apt packages.
        -c,--config     : Install config from cj-config repo.
        -D,--debug      : Print some debug info while running.
        -d,--dryrun     : Don't do anything, just print the commands.
        -f,--dotfiles   : Install dot files from cj-dotfiles repo.
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
        eval "$cmd"
    fi
}

# Make sure we have at least one package list to work with.
check_required_files || exit 1

declare -a nonflags
dry_run=0
do_all=1
do_apt=0
do_config=0
do_dotfiles=0
do_list=0
do_listpip2=0
do_listpip3=0
do_pip2=0
do_pip3=0

for arg; do
    case "$arg" in
        "-a"|"--apt" )
            do_apt=1
            do_all=0
            ;;
        "-c"|"--config" )
            do_config=1
            do_all=0
            ;;
        "-d"|"--dryrun" )
            dry_run=1
            ;;
        "-D"|"--debug" )
            debug_mode=1
            ;;
        "-f"|"--dotfiles" )
            do_dotfiles=1
            do_all=0
            ;;
        "-h"|"--help" )
            print_usage ""
            exit 0
            ;;
        "-l"|"--list" )
            do_list=1
            ;;
        "-l2"|"--listpip2" )
            do_listpip2=1
            ;;
        "-l3"|"--listpip3" )
            do_listpip3=1
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

if ((do_list || do_listpip2 || do_listpip3)); then
    ((do_list)) && list_packages
    ((do_listpip2)) && list_pip "2"
    ((do_listpip3)) && list_pip "3"
    exit
fi

if ((do_all || do_apt)); then
    run_cmd "sudo apt-get update" "Upgrading the packages list..."
    run_cmd "$(generate_apt_cmds)" "Installing apt packages..."
fi

if ((do_all || do_pip2)); then
    run_cmd "$(generate_pip_cmds 2)" "Installing pip2 packages..."
fi
if ((do_all || do_pip3)); then
    run_cmd "$(generate_pip_cmds 3)" "Installing pip3 packages..."
fi
if ((do_all || do_config)); then
    install_config || echo_err "Failed to install config files!"
fi
if ((do_all || do_dotfiles)); then
    install_dotfiles || echo_err "Failed to install dot files!"
fi
