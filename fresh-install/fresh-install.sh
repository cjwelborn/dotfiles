#!/bin/bash

# My install script, that installs packages that I use frequently.
# -Christopher Welborn 05-31-2016
shopt -s dotglob
shopt -s nullglob

# App name should be filename-friendly.
appname="fresh-install"
appversion="0.1.0"
apppath="$(readlink -f "${BASH_SOURCE[0]}")"
appscript="${apppath##*/}"
appdir="${apppath%/*}"

filename_pkgs="$appdir/$appname-pkgs.txt"
filename_pip2_pkgs="$appdir/$appname-pip2-pkgs.txt"
filename_pip3_pkgs="$appdir/$appname-pip3-pkgs.txt"
filename_remote_debs="$appdir/$appname-remote-debs.txt"
required_files=(
    "$filename_pkgs"
    "$filename_pip2_pkgs"
    "$filename_pip3_pkgs"
    "$filename_remote_debs"
)

# Location for third-party deb packages.
debdir="$appdir/debs"

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
    local repo=$1
    shift
    local gitargs=("$@")
    if [[ -z "$repo" ]]; then
        echo_err "No repo given to clone_repo!"
        return 1
    fi
    local tmpdir
    tmpdir="$(make_temp_dir)" || return 1
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
    shift; shift
    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for copy_file!"
        return 1
    fi
    local msg="cp"
    [[ "${dest/$src}" == "~" ]] && msg="backup"
    if ((dry_run)); then
        status "$msg $*" "$src" "$dest"
    else
        debug_status "$msg $*" "$src" "$dest"
        cp "$@" "$src" "$dest"
    fi
}

function copy_file_sudo {
    # Copy a file using sudo, unless dry_run is set.
    local src=$1
    local dest=$2
    shift; shift
    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for copy_file_sudo!"
        return 1
    fi
    local msg="sudo cp"
    [[ "${dest/$src}" == "~" ]] && msg="sudo backup"
    if ((dry_run)); then
        status "$msg $*" "$src" "$dest"
    else
        debug_status "$msg $*" "$src" "$dest"
        sudo cp "$@" "$src" "$dest"
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

    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for copy_files!"
        return 1
    fi
    local dirfiles=("$src"/*)

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
        [[ -n "$blacklistpat" ]] && [[ "$srcfilename" =~ $blacklistpat ]] && continue
        if [[ -e "${dest}/$srcfilename" ]]; then
            if [[ -f "$srcfilepath" ]]; then
                if ! copy_file "${home}/${srcfilename}" "${home}/${srcfilename}~"; then
                    echo_err "Failed to backup file: ${home}/${srcfilename}"
                    echo_err "    I will not overwrite the existing file."
                    continue
                fi
            elif [[ -d "$srcfilepath" ]]; then
                if ! copy_file "${home}/${srcfilename}" "${home}/${srcfilename}~" -r; then
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
            if ! copy_file "$srcfilepath" "${home}/${srcfilename}" -r; then
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
    ((debug_mode)) && echo_err "$@"
}

function debug_status {
    # Print status message about file operations, if debug_mode is set.
    ((debug_mode)) && status "$@"
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
    # $appname-pkgs.txt
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
    # $appname-pip$1.txt
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
    while IFS=$'\n' read -r pkgname; do
        # Ignore comment lines.
        is_skipped_line "$pkgname" && continue
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

function get_deb_desc {
    # Retrieve a short description for a .deb package.
    local debfmt="\${package} v\${version} : \${description}\n"
    local debdesc
    if ! debdesc="$(dpkg-deb -W --showformat="$debfmt" "$1" 2>/dev/null)"; then
        echo_err "Unable to retrieve version for: $1"
        return 1
    fi
    local debline="${debdesc%%$'\n'*}"
    ((${#debline} > 77)) && debline="${debline:0:77}..."
    printf "%s" "$debline"
}

function get_deb_ver {
    # Retrieve the version number for a .deb package.
    if ! dpkg -f "$1" version 2>/dev/null; then
        echo_err "Unable to retrieve version for: $1"
        return 1
    fi
    return 0
}

function get_debfiles {
    # Print deb files available in ./debs
    if [[ ! -d "$debdir" ]]; then
        echo_err "No debs directory found: $debdir"
        return 1
    fi
    local debfiles=("$debdir"/*.deb)
    if ((${#debfiles[@]} == 0)); then
        echo_err "No .deb files in $debdir."
        return 1
    fi
    local debfile
    for debfile in "${debfiles[@]}"; do
        printf "%s\n" "$debfile"
    done
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
            cd -
            return 1
        fi
        cd -
    fi
    local home="${HOME:-/home/$USER}"
    debug "Copying config files..."
    if ! copy_files "$repodir" "$home" "(.gitmodules)|(README)|(^\.git$)"; then
        echo_err "Failed to copy files: $repodir -> $home"
        return 1
    fi
    if [[ -n "$repodir" ]] && [[ "$repodir" =~ $appname ]] && [[ -e "$repodir" ]]; then
        debug "Removing temporary repo dir: $repodir"
        if ! remove_file_sudo "$repodir" -r; then
            echo_err "Failed to remove temporary dir: $repodir"
            return 1
        fi
    fi
    return 0
}

function install_debfiles {
    # Install all .deb files in $appdir/debs/ (unless dry_run is set).
    local debfiles=($(get_debfiles))
    local debfile
    for debfile in "${debfiles[@]}"; do
        run_cmd "sudo dpkg -i \"$debfile\"" "Installing ${debfile##*/}..."
    done
}

function install_debfiles_remote {
    if [[ ! -e "$filename_remote_debs" ]]; then
        echo_err "No remote deb file list: $filename_remote_debs"
        return 1
    fi
    local dldir
    if ! dldir="$(make_temp_dir)"; then
        echo_err "Unable to create a temporary directory!"
        return 1
    fi
    local deblines
    if ! mapfile -t deblines <"$filename_remote_debs"; then
        echo_err "Failed to read remote deb file list: $filename_remote_debs"
        return 1
    fi
    local debline
    local pkgname
    local pkgurl
    local pkgpath
    local pkgmsgs
    for debline in "${deblines[@]}"; do
        is_skipped_line "$debline" && continue
        pkgname="${debline%%=*}"
        pkgurl="${debline##*=}"
        if [[ -z "$pkgname" || -z "$pkgurl" || ! "$debline" =~ = ]]; then
            echo_err \
                "Bad config in ${filename_remote_debs}!" \
                "\n    Expecting NAME=URL, got:\n        $debline"
            continue
        fi
        pkgpath="${dldir}/${pkgname}.deb"
        echo -e "Downloading $pkgname from: $pkgurl\n"
        if ! wget "$pkgurl" -O "$pkgpath"; then
            echo_err "Failed to download deb package from: $pkgurl"
            continue
        fi
        if [[ ! -e "$pkgpath" ]]; then
            echo_err "No package found after download: $pkgurl"
            continue
        fi
        pkgmsgs=("Installing third-party package: ${pkgpath##*/}")
        pkgmsgs+=("$(get_deb_desc "$pkgpath")")

        run_cmd "sudo dpkg -i \"$pkgpath\"" "$(strjoin $'\n' "${pkgmsgs[@]}")"
    done
    if ! remove_file_sudo "$dldir" -r; then
        echo_err "Failed to remove temporary directory: $dldir"
        return 1
    fi
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
    if ! copy_files "$repodir" "$home" '('"$appname"')|(README)|(^\.git$)'; then
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
        if ! remove_file_sudo "$repodir" -r; then
            echo_err "Failed to remove temporary dir: $repodir"
            return 1
        fi
    fi
    return 0
}

function is_skipped_line {
    # Returns a success exit status if $1 is a line that should be skipped
    # in all config files (comments, blank lines, etc.)
    [[ -z "$1" ]] && return 0
    # Regexp for matching comment lines.
    local commentpat='^[ \t]+?#'
    [[ "$1" =~ $commentpat ]] && return 0
    # Regexp for matching whitespace only.
    local whitespacepat='^[ \t]+$'
    [[ "$1" =~ $whitespacepat ]] && return 0
    # Line should not be skipped.
    return 1
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

function list_debfiles {
    local debfiles=($(get_debfiles))
    if ((${#debfiles[@]} == 0)); then
        echo_err "No deb files to list!"
        return 1
    fi
    local debfile
    echo -e "\nLocal debian packages:"
    for debfile in "${debfiles[@]}"; do
        printf "\n%s\n    %s\n" "$debfile" "$(get_deb_desc "$debfile")"
    done
}

function list_debfiles_remote {
    # List third-party deb files from $appname-remote_debs.txt
    local deblines
    if ! mapfile -t deblines <"$filename_remote_debs"; then
        echo_err "Failed to read remote deb file list: $filename_remote_debs"
        return 1
    fi
    local debline
    local pkgname
    local pkgurl
    echo -e "\nRemote debian packages:"
    for debline in "${deblines[@]}"; do
        is_skipped_line "$debline" && continue
        pkgname="${debline%%=*}"
        pkgurl="${debline##*=}"
        if [[ -z "$pkgname" || -z "$pkgurl" || ! "$debline" =~ = ]]; then
            echo_err \
                "Bad config in ${filename_remote_debs}!" \
                "\n    Expecting NAME=URL, got:\n        $debline"
            continue
        fi
        printf "\n%-20s: %s\n" "$pkgname" "$pkgurl"
    done
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
    echo "# These are apt/debian packages."
    echo -e "# These packages will be apt-get installed by $appname.sh\n"
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
    echo "# These are python $ver package names."
    echo "# These packages will be installed with pip${ver} by $appname.sh."
    echo -e "# Packages marked with * are global packages, and require sudo to install.\n"
    for pkgname in $($exepath list | cut -d' ' -f1); do
        debug "Checking for system/local package: $pkgname"
        if is_system_pip "$ver" "$pkgname"; then
            echo "*${pkgname}"
        else
            echo "$pkgname"
        fi
    done
}

function make_temp_dir {
    # Make a temporary directory and print it's path.
    local tmproot="/tmp"
    if ! mktemp -d -p "$tmproot" "${appname/ /-}.XXX"; then
        echo_err "Unable to create a temporary directory in ${tmproot}!"
        return 1
    fi
    return 0
}

function print_usage {
    # Show usage reason if first arg is available.
    [[ -n "$1" ]] && echo_err "\n$1\n"

    echo "$appname v. $appversion

    Usage:
        $appscript -h | -v
        $appscript [-l] [-l2] [-l3] [-lp] [-D]
        $appscript [-a] [-c] [-f] [-p] [-p2] [-p3] [-D]

    Options:
        -a,--apt        : Install apt packages.
        -c,--config     : Install config from cj-config repo.
        -D,--debug      : Print some debug info while running.
        -d,--dryrun     : Don't do anything, just print the commands.
                          Files will be downloaded to a temporary directory,
                          but deleted soon after (or at least on reboot).
                          Nothing will be installed to the system.
        -f,--dotfiles   : Install dot files from cj-dotfiles repo.
        -h,--help       : Show this message.
        -l,--list       : List installed packages on this machine.
                          Used to build this/other install scripts.
        -l2,--listpip2  : List installed pip 2.7 packages on this machine.
                          Used to build this/other install scripts.
        -l3,--listpip3  : List installed pip 3 packages on this machine.
                          Used to build this/other install scripts.
        -lp,--listdebs  : List all .deb files in ./debs.
        -p,--debfiles   : Install ./debs/*.deb packages.
        -p2,--pip2      : Install pip2 packages.
        -p3,--pip3      : Install pip3 packages.
        -v,--version    : Show $appname version and exit.
    "
}

function remove_file {
    # Remove a file/dir, and print a status message about it.
    local file=$1
    if [[ -z "$file" ]]; then
        echo_err "Expected \$file for remove_file!"
        return 1
    fi
    shift
    # Temp files (with the appname in them) are still removed during dry runs.
    if ((dry_run)) && [[ ! "$file" =~ $appname ]]; then
        debug_status "rm $*" "$file"
        return 0
    fi

    status "rm $*" "$file"
    rm "$@" "$file"
}

function remove_file_sudo {
    # Remove a file/dir, and print a status message about it.
    local file=$1
    if [[ -z "$file" ]]; then
        echo_err "Expected \$file for remove_file!"
        return 1
    fi
    shift
    # Temp files (with the appname in them) are still removed during dry runs.
    if ((dry_run)) && [[ ! "$file" =~ $appname ]]; then
        debug_status "rm $*" "$file"
        return 0
    fi
    status "sudo rm $*" "$file"
    sudo rm "$@" "$file"
}

function run_cmd {
    # Run a command, unless dry_run is set (then just print it).
    local cmd=$1
    local desc="${2:-Running $1}"
    ((${#desc} > 80)) && desc="${desc:0:80}..."
    echo -e "\n$desc"
    if ((dry_run)); then
        echo "    $cmd"
    else
        eval "$cmd"
    fi
}

function status {
    # Print a message about a file/directory operation.
    # Arguments:
    #   $1 : Operation (BackUp, Copy File, Copy Dir)
    #   $2 : File 1
    #   $3 : File 2
    printf "%-15s: %-40s" "$1" "$2"
    if [[ -n "$3" ]]; then
        printf " -> %s\n" "$3"
    else
        printf "\n"
    fi
}

function strjoin {
    local IFS="$1"
    shift
    echo "$*"
}

# Make sure we have at least one package list to work with.
check_required_files || exit 1

declare -a nonflags
dry_run=0
do_all=1
do_apt=0
do_config=0
do_debfiles=0
do_dotfiles=0
do_list=0
do_listdebs=0
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
        "-lp"|"--listdebs" )
            do_listdebs=1
            ;;
        "-p"|"--debfiles" )
            do_debfiles=1
            do_all=0
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

if ((do_list || do_listdebs || do_listpip2 || do_listpip3)); then
    ((do_list)) && list_packages
    ((do_listpip2)) && list_pip "2"
    ((do_listpip3)) && list_pip "3"
    ((do_listdebs)) && {
        list_debfiles
        list_debfiles_remote
    }
    exit
fi

# System apt packages.
if ((do_all || do_apt)); then
    run_cmd "sudo apt-get update" "Upgrading the packages list..."
    run_cmd "$(generate_apt_cmds)" "Installing apt packages..."
fi
# Local/remote apt packages.
if ((do_all || do_debfiles)); then
    install_debfiles || "Failed to install third-party deb packages!"
    install_debfiles_remote || "Failed to install remote third-party deb packages!"
fi
# Pip2 packages.
if ((do_all || do_pip2)); then
    run_cmd "$(generate_pip_cmds 2)" "Installing pip2 packages..."
fi
# Pip3 packages.
if ((do_all || do_pip3)); then
    run_cmd "$(generate_pip_cmds 3)" "Installing pip3 packages..."
fi
# App config files.
if ((do_all || do_config)); then
    install_config || echo_err "Failed to install config files!"
fi
# Bash config/dotfiles.
if ((do_all || do_dotfiles)); then
    install_dotfiles || echo_err "Failed to install dot files!"
fi
