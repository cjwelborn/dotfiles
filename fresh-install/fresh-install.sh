#!/bin/bash

# My install script for new machines. Currently installs:
#   apt packages, using apt-get (from a list.txt)
#   apt package files, using dpkg (from ./debs/*.deb)
#   remote apt package files, using wget and dpkg (from a list.txt).
#   python 2 packages, using pip2 (from a list.txt) (uses sudo for sys pkgs)
#   python 3 packages, using pip3 (from a list.txt) (uses sudo for sys pkgs)
#   app config files (from github.com/cjwelborn/cj-config)
#   bash config files (from github.com/cjwelborn/cj-dotfiles)
#   ruby gems (from a list.txt)
#   atom packages (from a list.txt)
#   git clones (from a list.txt)
#
# -Christopher Welborn 05-31-2016
shopt -s dotglob
shopt -s nullglob

# App name should be filename-friendly.
appname="fresh-install"
appversion="0.2.9"
apppath="$(readlink -f "${BASH_SOURCE[0]}")"
appscript="${apppath##*/}"
appdir="${apppath%/*}"

# Apt install command with safer args.
aptinstallcmd="sudo apt-get -y --ignore-missing --no-remove install"

# Packages needed to run this script.
# These should be in $appname-pkgs.txt, but just incase I'll try to install
# them anyway after the initial apt-get commands.
declare -A script_depends=(
    #[executable]=parent-package-name
    ["which"]="debianutils"
    ["git"]="git"
)

filename_apm="$appdir/apm-pkgs.txt"
filename_gems="$appdir/gems.txt"
filename_git_clones="$appdir/clones.txt"
filename_pkgs="$appdir/pkgs.txt"
filename_pip2_pkgs="$appdir/pip2-pkgs.txt"
filename_pip3_pkgs="$appdir/pip3-pkgs.txt"
filename_remote_debs="$appdir/remote-debs.txt"
required_files=(
    "$filename_apm"
    "$filename_gems"
    "$filename_pkgs"
    "$filename_pip2_pkgs"
    "$filename_pip3_pkgs"
    "$filename_remote_debs"
)

# Location for third-party deb packages.
debdir="$appdir/debs"

# Any failing command that passes through run_cmd will be stored here.
declare -A failed_cmds

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
        print_required_files "missing" 1>&2
        return 1
    fi
    if ((required_cnt != ${#required_files[@]})); then
        echo_err "Missing some required package list files,"
        echo_err "...some packages may not be installed."
        print_required_files "missing" 1>&2
        local missingcnt=$?
        return $missingcnt
    fi
    return 0
}

function clone_repo {
    # Clone a repo into a directory, and print the directory.
    # Arguments:
    #   $1    : Repo url.
    #   $2    : Destination directory.
    #   $3... : Git args.
    local repo=$1 destdir=$2
    shift 2
    if [[ -z "$repo" || -z "$destdir" ]]; then
        echo_err "Expected \$repo and \$destdir for clone_repo!"
        return 1
    elif [[ ! -d "$destdir" ]]; then
        echo_err "Destination directory does not exist: $destdir"
        return 1
    fi

    local gitargs=("$@")

    debug "Cloning repo '$repo' to $destdir."
    if ! git clone "${gitargs[@]}" "$repo" "$destdir"; then
        echo_err "Failed to clone repo: $repo"
        return 1
    fi
    printf "%s" "$destdir"
}

function clone_repo_tmp {
    # Clone a repo into a temporary directory, and print the directory.
    # Arguments:
    #   $1 : Repo url.
    #   $2 : Arguments for git.
    local repo=$1
    shift
    local gitargs=("$@")
    if [[ -z "$repo" ]]; then
        echo_err "No repo given to clone_repo_tmp!"
        return 1
    fi
    local tmpdir
    tmpdir="$(make_temp_dir)" || return 1
    clone_repo "${gitargs[@]}" "$repo" "$tmpdir"
}

function cmd_exists {
    # Shortcut to hash $1 &>/dev/null, with a better message on failure.
    if ! hash "$1" &>/dev/null; then
        echo_err "Executable not found: $1"
        return 1
    fi
    return 0
}

function copy_file {
    # Copy a file, unless dry_run is set.
    local src=$1 dest=$2
    shift 2
    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for copy_file!"
        return 1
    fi
    local msg="cp"
    [[ "${dest//$src}" == "~" ]] && msg="backup"
    if ((dry_run)); then
        status "$msg $*" "$src" "$dest"
    else
        debug_status "$msg $*" "$src" "$dest"
        cp "$@" "$src" "$dest"
    fi
}

function copy_file_sudo {
    # Copy a file using sudo, unless dry_run is set.
    local src=$1 dest=$2
    shift 2
    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for copy_file_sudo!"
        return 1
    fi
    local msg="sudo cp"
    [[ "${dest//$src}" == "~" ]] && msg="sudo backup"
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
    local src=$1 dest=$2 blacklistpat=$3

    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for copy_files!"
        return 1
    fi
    local dirfiles=("$src"/*)

    if ((${#dirfiles[@]} == 0)); then
        echo_err "No files to install in $src."
        return 1
    fi
    local srcfilepath srcfilename errs=0
    for srcfilepath in "${dirfiles[@]}"; do
        srcfilename="${srcfilepath##*/}"
        [[ -z "$srcfilename" ]] && continue
        [[ -n "$blacklistpat" ]] && [[ "$srcfilename" =~ $blacklistpat ]] && continue
        if [[ -e "${dest}/$srcfilename" ]]; then
            if [[ -f "$srcfilepath" ]]; then
                if ! copy_file "${dest}/${srcfilename}" "${dest}/${srcfilename}~"; then
                    echo_err "Failed to backup file: ${dest}/${srcfilename}"
                    echo_err "    I will not overwrite the existing file."
                    let errs+=1
                    continue
                fi
            elif [[ -d "$srcfilepath" ]]; then
                if ! copy_file "${dest}/${srcfilename}" "${dest}/${srcfilename}~" -r; then
                    echo_err "Failed to backup directory: ${dest}/${srcfilename}"
                    echo_err "    I will not overwrite the existing directory."
                    let errs+=1
                    continue
                fi
            fi
        fi
        if [[ -f "$srcfilepath" ]]; then
            if ! copy_file "$srcfilepath" "${dest}/${srcfilename}"; then
                echo_err "Failed to copy file: ${srcfilepath} -> ${dest}/${srcfilename}"
                let errs+=1
                continue
            fi
        elif [[ -d "$srcfilepath" ]]; then
            if ! copy_file "$srcfilepath" "${dest}/${srcfilename}" -r; then
                echo_err "Failed to copy directory: ${srcfilepath} -> ${dest}/${srcfilename}"
                let errs+=1
                continue
            fi
        else
            echo_err "File does not exist: $srcfilepath"
            let errs+=1
            continue
        fi
    done

    return $errs
}

function debug {
    # Echo a debug message to stderr if debug_mode is set.
    ((debug_mode)) && echo_err "$@"
}

function debugf {
    # Printf a debug message to stderr if debug_mode is set.
    # shellcheck disable=SC2059
    # ...using a variable in printf on purpose shellcheck.
    ((debug_mode)) && printf "$@" 1>&2
}

function debug_depends {
    # Check script dependencies and print some debug info about them.
    local cmdname msgfmt
    for cmdname in "${!script_depends[@]}"; do
        if cmd_exists "$cmdname"; then
            msgfmt="Dependency exists:  %12s (%s)\n"
        else
            msgfmt="Missing dependency: %12s (%s will be installed)\n"
        fi
        debugf "$msgfmt" "$cmdname" "${script_depends[$cmdname]}"
    done
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

function find_apm_packages {
    # List installed apm packages on this machine.
    cmd_exists "apm" || return 1
    debug "Gathering installed apm packages."
    echo "# These are atom package names (apm)."
    echo -e "# These packages will be apm installed by $appscript.\n"
    # List names only, so the latest version is downloaded on install.
    # Using array/loop to remove extra newlines at the end of `apm ls`.
    local names
    names=($(apm ls --bare --installed | cut -d'@' -f1))
    local name
    for name in "${names[@]}"; do
        is_skipped_line "$name" && continue
        printf "%s\n" "$name"
    done
}

function find_packages {
    # List installed packages on this machine.
    local blacklisted=("linux-image" "linux-signed" "nvidia")
    local blacklistpat=""
    for pkgname in "${blacklisted[@]}"; do
        [[ -n "$blacklistpat" ]] && blacklistpat="${blacklistpat}|"
        blacklistpat="${blacklistpat}($pkgname)"
    done
    debug "Gathering installed apt packages ( ignoring" "${blacklisted[@]}" ")."
    echo "# These are apt/debian packages."
    echo -e "# These packages will be apt-get installed by $appscript\n"
    # shellcheck disable=SC2016
    # ...single-quotes are intentional.
    comm -13 \
      <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort) \
      <(comm -23 \
        <(dpkg-query -W -f='${Package}\n' | sed 1d | sort) \
        <(apt-mark showauto | sort) \
      ) | grep -E -v "$blacklistpat"
}

function find_pip {
    # List installed pip packages on this machine.
    # Arguments:
    #   $1 : Pip version (2 or 3).
    local ver="${1:-3}"
    local exe="pip${ver}"
    local exepath
    if ! exepath="$(which "$exe" 2>/dev/null)"; then
        fail "Failed to locate $exe!"
    else
        [[ -n "$exepath" ]] || fail "Failed to locate $exe"
    fi
    declare -A pippkgs
    local pkgname
    # All packages are considered global until `pip list --user` runs.
    # TODO: This 'cut -d' '-f1' may fail in the future, when pip switches to columns.
    debug "Listing pip${ver} packages with \`$exepath list\`..."
    for pkgname in $($exepath list 2>/dev/null | cut -d' ' -f1); do
        pippkgs[$pkgname]="global"
    done
    debug "Listing local user packages with \`$exepath list --user\`..."
    for pkgname in $($exepath list --user 2>/dev/null | cut -d' ' -f1); do
        pippkgs[$pkgname]="local"
    done

    echo "# These are python $ver package names."
    echo "# These packages will be installed with pip${ver} by $appscript."
    echo -e "# Packages marked with * are global packages, and require sudo to install.\n"
    for pkgname in "${!pippkgs[@]}"; do
        if [[ "${pippkgs[$pkgname]}" == "global" ]]; then
            echo "*${pkgname}"
        else
            echo "$pkgname"
        fi
    # Using `sort --version` to separate local/global packages.
    done | sort -V
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

function install_apm_packages {
    # Install apm packages from $appname-apm.txt.
    cmd_exists "apm" || return 1
    local apmnames
    apmnames=($(list_file "$filename_apm")) || return 1
    ((${#apmnames[@]})) || return 1
    local apmname installcmd installdesc errs=0
    for apmname in "${apmnames[@]}"; do
        installcmd="apm install '$apmname'"
        installdesc="Installing apm package: $apmname"
        run_cmd "$installcmd" "$installdesc" || let errs+=1
    done
    return $errs
}

function install_apt_depends {
    # Install all script dependencies.
    ((${#script_depends[@]})) || return 1
    local errs=0 cmdname pkgname installcmd installdesc
    for cmdname in "${!script_depends[@]}"; do
        cmd_exists "$cmdname" && {
            debug "Command dependency already exists: $cmdname"
            continue
        }
        pkgname="${script_depends[$cmdname]}"
        installdesc="Installing script-dependency package: $pkgname"
        run_cmd "$aptinstallcmd '$pkgname'" "$installdesc" || let errs+=1
    done
    return $errs
}

function install_apt_packages {
    # Install packages from $appname-pkgs.txt.
    local pkgnames
    pkgnames=($(list_file "$filename_pkgs")) || return 1;
    ((${#pkgnames[@]})) || return 1
    local errs=0 pkgname installcmd installdesc
    for pkgname in "${pkgnames[@]}"; do
        installdesc="Installing apt package: $pkgname"
        run_cmd "$aptinstallcmd '$pkgname'" "$installdesc" || let errs+=1
    done
    return $errs
}

function install_config {
    # Install config files from github.com/cjwelborn/cj-config.git
    local repodir=~/clones/cj-config
    if ((dry_run)); then
        echo "Creating real directory for dry run."
        mkdir -p "$repodir" || return 1
    else
        make_dir "$repodir" || return 1
    fi
    if ! repodir="$(clone_repo "https://github.com/cjwelborn/cj-config.git" "$repodir")"; then
        echo_err "Repo clone failed, cannot install config."
        [[ -n "$repodir" && -e "$repodir" ]] && rm -r "$repodir"
        return 1
    else
        debug "Changing to repo directory: $repodir"
        if ! cd "$repodir"; then
            echo_err "Failed to cd into repo: $repodir"
            [[ -n "$repodir" && -e "$repodir" ]] && rm -r "$repodir"
            return 1
        fi
        debug "Updating config submodules..."
        if ! git submodule update --init; then
            echo_err "Failed to update submodules!"
            cd -
            [[ -n "$repodir" && -e "$repodir" ]] && rm -r "$repodir"
            return 1
        fi
        cd -
    fi
    local home="${HOME:-/home/$USER}"
    debug "Copying config files..."
    if ! symlink_files "$repodir" "$home" "(.gitmodules)|(README)|(^\.git$)"; then
        echo_err "Failed to symlink files: $repodir -> $home"
        return 1
    fi
    if ((dry_run)); then
        # Remove clone dir on dry runs..
        if [[ -n "$repodir" && -e "$repodir" ]]; then
            debug "Removing temporary repo dir: $repodir"
            if ! sudo rm -r "$repodir"; then
                echo_err "Failed to remove temporary dir: $repodir"
                return 1
            fi
        else
            echo_err "Can't find repo dir: $repodir"
            return 1
        fi
    fi
    return 0
}

function install_debfiles {
    # Install all .deb files in $appdir/debs/ (unless dry_run is set).
    local debfiles=($(get_debfiles))
    local errs=0 debfile installcmd installdesc
    for debfile in "${debfiles[@]}"; do
        installcmd="sudo dpkg -i '$debfile'"
        installdesc="Installing ${debfile##*/}..."
        run_cmd "$installcmd" "$installdesc" || let errs+=1
    done
    return $errs
}

function install_debfiles_remote {
    # Install remote debian packages from $appname-remote-debs.txt
    local deblines
    deblines=($(list_file "$filename_remote_debs")) || return 1
    ((${#deblines[@]})) || return 1
    local dldir
    if ! dldir="$(make_temp_dir)"; then
        echo_err "Unable to create a temporary directory!"
        return 1
    fi
    local errs=0 debline pkgname pkgurl pkgpath pkgmsgs installcmd installdesc
    for debline in "${deblines[@]}"; do
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
            let errs+=1
            continue
        fi
        if [[ ! -e "$pkgpath" ]]; then
            echo_err "No package found after download: $pkgurl"
            let errs+=1
            continue
        fi
        pkgmsgs=("Installing third-party package: ${pkgpath##*/}")
        pkgmsgs+=("$(get_deb_desc "$pkgpath")")
        installcmd="sudo dpkg -i '$pkgpath'"
        installdesc="$(strjoin $'\n' "${pkgmsgs[@]}")"
        run_cmd "$installcmd" "$installdesc" || let errs+=1
    done
    if ! remove_file_sudo "$dldir" -r; then
        echo_err "Failed to remove temporary directory: $dldir"
        let errs+=1
    fi
    return $errs
}

function install_dotfiles {
    # Install dotfiles files from $appdir/../
    local home="${HOME:-/home/$USER}" srcdir="$appdir"/..
    debug "Copying dot files from $srcdir ..."
    if ! symlink_files "$srcdir" "$home" '('"$appname"')|(README)|(^\.git$)'; then
        echo_err "Failed to symlink files: $srcdir -> $home"
        return 1
    fi
    if [[ -e "${srcdir}/bash.bashrc" ]]; then
        echo "Installing global bashrc."
        if [[ -e /etc/bash.bashrc ]]; then
            echo "Backing up global bashrc."
            move_file_sudo '/etc/bash.bashrc' '/etc/bash.bashrc~'
        fi
        symlink_file_sudo "${srcdir}/bash.bashrc" "/etc/bash.bashrc"
    fi
    local disablefiles=("${home}/.bashrc" "${home}/.profile")
    local disablefile
    for disablefile in "${disablefiles[@]}"; do
        if [[ ! -e "$disablefile" ]]; then
            if [[ -e "${disablefile}~" ]]; then
                debug "Already backed up/disabled: $disablefile"
            else
                debug "Not found, not disabling: $disablefile"
            fi
            continue
        fi
        echo "Backing up existing config file to disable: $disablefile"
        if ! move_file "$disablefile" "${disablefile}~"; then
            echo_err "Failed to disable existing file: $disablefile\n  It my interfere with new config files..."
            continue
        fi
    done
    return 0
}

function install_gems {
    # Install gem packages found in $appname-gems.txt.
    cmd_exists "gem" || return 1
    local gemnames
    if ! gemnames=($(list_gems)); then
        echo_err "Unable to install gems."
        return 1
    fi
    local gemname
    local errs=0
    for gemname in "${gemnames[@]}"; do
        run_cmd "gem install $gemname" "Installing gem: $gemname" || let errs+=1
    done
    return $errs
}

function install_git_clone {
    # Clone a repo into ~/clones, and symlink it's main executable to
    # ~/.local/bin.
    # Arguments:
    #   $1    : relative executable path (relative to git repo)
    #   $2    : repo url
    #   $3... : git args
    local relexepath=$1 repourl=$2
    shift 2
    if [[ -z "$relexepath" || -z "$repourl" ]]; then
        echo_err "Expected \$relexepath and \$repourl in install_git_repo!"
        return 1
    fi
    local exename="${relexepath##*/}" gitargs=("$@") clonedir=~/clones
    make_dir "$clonedir/$exename" || return 1
    local homebin=~/.local/bin
    make_dir "$homebin" || return 1
    local repodir
    if ((dry_run)); then
        echo "    clone_repo \"$repourl\" \"$clonedir/$exename\" ${gitargs[*]}"
        echo "    ln -s \$exepath $homebin/$exename"
        echo_err "Dry run, cannot continue with repo cloning: $repourl"
        return 1
    fi
    repodir="$(clone_repo "$repourl" "$clonedir/$exename" "${gitargs[@]}")" || return 1
    local exepath="$repodir/$relexepath"
    local lnargs=("$exepath" "$homebin/$exename")
    if [[ ! -e "$exepath" ]]; then
        echo_err "Missing executable after cloning: $exepath"
        echo_err "The project may need to be compiled..."
        # Add this to failed cmds, to remind about it later.
        local lncmd="ln -s ${lnargs[*]}"
        failed_cmds[$lncmd]=("Missing clone executable: $exepath")
        return 1
    fi
    if ! ln -s "${lnargs[@]}"; then
        echo_err "Failed to create symlink: $homebin/$exename"
        return 1
    fi
    return 0
}

function install_git_clones {
    # Install all git repo/executables from $appname-clones.txt
    local gitlines
    gitlines=($(list_file "$filename_git_clones")) || return 1
    ((${#gitlines[@]})) || return 1
    local errs=0 gitline relexepath repourl errs=0
    for gitline in "${gitlines[@]}"; do
        relexepath="${gitline%%=*}"
        repourl="${gitline##*=}"
        if [[ -z "$relexepath" || -z "$repourl" || ! "$gitline" =~ = ]]; then
            echo_err \
                "Bad config in ${filename_git_clones}!" \
                "\n    Expecting RELEXEPATH=REPOURL, got:\n        $gitline"
            continue
        fi
        install_git_clone "$relexepath" "$repourl" || let errs+=1
    done
    return $errs
}

function install_pip_packages {
    # Install pip packages from $appname-pip${1}.txt.
    local ver="${1:-3}"
    local varname="filename_pip${ver}_pkgs"
    local filename="${!varname}"
    if [[ ! -e "$filename" ]]; then
        echo_err "Cannot install pip${ver} packages, missing ${filename}."
        return 1
    fi
    cmd_exists "pip${ver}" || return 1

    declare -a sudopkgs
    declare -a normalpkgs
    local sudopkgs normalpkgs pkgnames
    pkgnames=($(list_file "$filename")) || return 1
    ((${#pkgnames[@]})) || return 1
    local pkgname sudopat='^\*'
    for pkgname in "${pkgnames[@]}"; do
        if [[ "$pkgname" =~ $sudopat ]]; then
            sudopkgs+=("${pkgname:1}")
        else
            normalpkgs+=("$pkgname")
        fi
    done
    if ((${#sudopkgs[@]} == 0 && ${#normalpkgs[@]} == 0)); then
        echo_err "No pip${ver} packages found in $filename."
        return 1
    fi
    local errs=0 installcmd installdesc
    if ((${#sudopkgs[@]})); then
        echo "Installing global pip${ver} packages..."
        local sudopkg

        for sudopkg in "${sudopkgs[@]}"; do
            installcmd="sudo pip${ver} install '$sudopkg'"
            installdesc="Installing global pip${ver} package: $sudopkg"
            run_cmd "$installcmd" "$installdesc" || let errs+=1
        done
    fi
    if ((${#normalpkgs[@]})); then
        echo "Installing local pip${ver} packages..."
        local normalpkg
        for normalpkg in "${normalpkgs[@]}"; do
            installcmd="pip${ver} install '$normalpkg'"
            installdesc="Installing local pip${ver} package: $normalpkg"
            run_cmd "$installcmd" "$installdesc" || let errs+=1
        done
    fi
    return $errs
}

function is_skipped_line {
    # Returns a success exit status if $1 is a line that should be skipped
    # in all config files (comments, blank lines, etc.)
    [[ -z "${1// }" ]] && return 0
    # Regexp for matching comment lines.
    local commentpat='^[ \t]+?#'
    [[ "$1" =~ $commentpat ]] && return 0
    # Regexp for matching whitespace only.
    local whitespacepat='^[ \t]+$'
    [[ "$1" =~ $whitespacepat ]] && return 0
    # Line should not be skipped.
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
    local debline pkgname pkgurl
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

function list_failures {
    # List any failed commands in $failed_cmds[@].
    # Returns a success status code if there are failures.
    ((${#failed_cmds[@]})) || return 1
    echo -e "\nFailed commands (${#failed_cmds[@]}):"
    local cmd
    for cmd in "${!failed_cmds[@]}"; do
        printf "\n    Failed: %s\n        %s\n" "${failed_cmds[$cmd]}" "$cmd"
    done
    return 0
}

function list_file {
    # List all names from one of the $appname-*.txt lists.
    if [[  ! -e "$1" ]]; then
        echo_err "No list file found: $1"
        return 1
    fi
    local lines
    if ! mapfile -t lines <"$1"; then
        echo_err "Unable to read from: $1"
        return 1
    fi
    if ((${#lines[@]} == 0)); then
        echo_err "List is empty: $1"
        return 1
    fi
    local line
    for line in "${lines[@]}"; do
        is_skipped_line "$line" && continue
        printf "%s\n" "$line"
    done
}

function make_dir {
    # Make a directory if it doesn't exist alredy, unless dry_run is set.
    local dirpath=$1
    if [[ -z "$dirpath" ]]; then
        echo_err "Expected \$dirpath in make_dir!"
        return 1
    fi
    if [[ -d "$dirpath" ]]; then
        debug "Directory already exists: $dirpath"
        return 0
    fi
    run_cmd "mkdir -p '$dirpath'" "Creating directory: $dirpath"
}

function make_temp_dir {
    # Make a temporary directory and print it's path.
    local tmproot="/tmp"
    if ! mktemp -d -p "$tmproot" "${appname// /-}.XXX"; then
        echo_err "Unable to create a temporary directory in ${tmproot}!"
        return 1
    fi
    return 0
}

function move_file {
    # Move a file, unless dry_run is set.
    local src=$1 dest=$2
    shift 2
    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for move_file!"
        return 1
    fi
    if ((dry_run)); then
        status "mv $*" "$src" "$dest"
    else
        debug_status "mv $*" "$src" "$dest"
        mv "$@" "$src" "$dest"
    fi
}

function move_file_sudo {
    # Move a file using sudo, unless dry_run is set.
    local src=$1 dest=$2
    shift 2
    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for move_file!"
        return 1
    fi
    if ((dry_run)); then
        status "sudo mv $*" "$src" "$dest"
    else
        debug_status "sudo mv $*" "$src" "$dest"
        sudo mv "$@" "$src" "$dest"
    fi
}

function print_required_files {
    # Print all required file names in ${required_files[@]}, with their
    # missing/existing status.
    # Returns the number of missing files as an exit status.
    local fname status lbl="Required" foundcnt=0 missingcnt=0 expected=$1
    [[ -n "$expected" ]] && lbl="${expected^} required"
    # Save missing/existing status for each file, counting along the way.
    declare -A filestats
    for fname in "${required_files[@]}"; do
        status="missing"
        if [[ -e "$fname" ]]; then
            status="existing"
            let foundcnt+=1
        else
            let missingcnt+=1
        fi
        filestats[$fname]=$status
    done
    # What kind of count are we showing? (missing/total) or (found/total)?
    local cntof=$missingcnt
    [[ "$expected" == "existing" ]] && cntof=$foundcnt
    printf "\n%s files (%s/%s):\n" "$lbl" "$cntof" "${#required_files[@]}"

    for fname in "${!filestats[@]}"; do
        status="${filestats[$fname]}"
        if [[ -z "$expected" ]] || [[ "$expected" == "$status" ]]; then
            printf "%12s: %s\n" "$status" "$fname"
        fi
    done
    return $missingcnt
}

function print_usage {
    # Show usage reason if first arg is available.
    [[ -n "$1" ]] && echo_err "\n$1\n"

    echo "$appname v. $appversion

    Usage:
        $appscript -h | -v
        $appscript (-C | -u) [-D]
        $appscript [-f2] [-f3] [-fp] [-D]
        $appscript [-l] [-l2] [-l3] [-lc] [-ld] [-lg] [-D]
        $appscript [-a] [-ap] [-c] [-f] [-g] [-gc] [-p] [-p2] [-p3] [-D]

    Options:
        -a,--apt            : Install apt packages.
        -ap,--apm           : Install apm packages.
        -C,--checkfiles     : Just check for required list files.
        -c,--config         : Install config from cj-config repo.
        -D,--debug          : Print some debug info while running.
        -d,--dryrun         : Don't do anything, just print the commands.
                              Files will be downloaded to a temporary
                              directory, but deleted soon after (or at least
                              on reboot).
                              Nothing will be installed to the system.
        -f,--dotfiles       : Install dot files from cj-dotfiles repo.
        -f2,--findpip2      : List installed pip 2.7 packages on this machine.
                              Used to build ${filename_pip2_pkgs##*/}.
        -f3,--findpip3      : List installed pip 3 packages on this machine.
                              Used to build ${filename_pip3_pkgs##*/}.
        -fa,--findapm       : List installed apm packages on this machine.
                              Used to build ${filename_apm##*/}.
        -fp,--findpackages  : List installed packages on this machine.
                              Used to build ${filename_pkgs##*/}.
        -g,--gems           : Install ruby gem packages.
        -gc,--gitclones     : Install git clones.
        -h,--help           : Show this message.
        -l,--list           : List apt packages in ${filename_pkgs##*/}.
        -l2,--listpip2      : List pip2 packages in ${filename_pip2_pkgs##*/}.
        -l3,--listpip3      : List pip3 packages in ${filename_pip3_pkgs##*/}.
        -la,--listapm       : List apm packages in ${filename_apm##*/}.
        -lc,--listclones    : List git clones in ${filename_git_clones##*/}.
        -ld,--listdebs      : List all .deb files in ./debs, and remote
                              packages in ${filename_remote_debs##*/}.
        -lg,--listgems      : List gem package names in ${filename_gems##*/}.
        -p,--debfiles       : Install ./debs/*.deb packages.
        -p2,--pip2          : Install pip2 packages.
        -p3,--pip3          : Install pip3 packages.
        -u,--update         : Update package lists with packages from this
                              machine.
        -v,--version        : Show $appname version and exit.
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
    if [[ -z "${cmd// }" ]]; then
        echo_err "run_cmd: No command to run. ${2:-No description either.}"
        return 1
    fi

    local desc="${2:-Running $1}"
    ((${#desc} > 80)) && desc="${desc:0:80}..."
    echo -e "\n$desc"
    if ((dry_run)); then
        echo "    $cmd"
    else
        # Run command and add it to failed_cmds if it fails.
        eval "$cmd" || failed_cmds[$cmd]=$2
    fi
}

function status {
    # Print a message about a file/directory operation.
    # Arguments:
    #   $1 : Operation (BackUp, Copy File, Copy Dir)
    #   $2 : File 1
    #   $3 : File 2
    printf "%-15s: %-55s\n" "$1" "$2"
    if [[ -n "$3" ]]; then
        printf "%15s: %s\n" "->" "$3"
    else
        printf "\n"
    fi
}

function strjoin {
    local IFS="$1"
    shift
    echo "$*"
}

function symlink_file {
    # Symlink a file, unless dry_run is set.
    local src=$1 dest=$2
    shift 2
    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for symlink_file!"
        return 1
    fi
    if ((dry_run)); then
        status "ln $*" "$src" "$dest"
    else
        debug_status "ln $*" "$src" "$dest"
        ln -s "$@" "$src" "$dest"
    fi
}

function symlink_file_sudo {
    # Symlink a file, unless dry_run is set.
    local src=$1 dest=$2
    shift 2
    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for symlink_file!"
        return 1
    fi
    if ((dry_run)); then
        status "sudo ln $*" "$src" "$dest"
    else
        debug_status "sudo ln $*" "$src" "$dest"
        sudo ln -s "$@" "$src" "$dest"
    fi
}

function symlink_files {
    # Safely symlink files from one directory to another.
    # Arguments:
    #   $1 : Source directory.
    #   $2 : Destination directory.
    #   $3 : Blacklist pattern, optional.
    local src=$1 dest=$2 blacklistpat=$3

    if [[ -z "$src" ]] || [[ -z "$dest" ]]; then
        echo_err "Expected \$src and \$dest for copy_files!"
        return 1
    fi
    local dirfiles=("$src"/*)

    if ((${#dirfiles[@]} == 0)); then
        echo_err "No files to install in $src."
        return 1
    fi
    local errs=0 srcfilepath srcfilename
    for srcfilepath in "${dirfiles[@]}"; do
        srcfilename="${srcfilepath##*/}"
        [[ -z "$srcfilename" ]] && continue
        [[ -n "$blacklistpat" ]] && [[ "$srcfilename" =~ $blacklistpat ]] && continue
        if [[ -e "${dest}/$srcfilename" ]]; then
            # Backup existing file.
            if ! move_file "${dest}/${srcfilename}" "${dest}/${srcfilename}~"; then
                echo_err "Failed to move existing file/dir: ${dest}/${srcfilename}"
                let errs+=1
                continue
            fi
        fi
        if [[ -e "$srcfilepath" ]]; then
            if ! symlink_file "$srcfilepath" "${dest}/${srcfilename}"; then
                echo_err "Failed to symlink file: ${srcfilepath} -> ${dest}/${srcfilename}"
                let errs+=1
                continue
            fi
        else
            echo_err "File does not exist: $srcfilepath"
            let errs+=1
            continue
        fi
    done

    return $errs
}


function update_pkg_lists {
    # Update the $appname-<pkg>.txt files with packages from this machine.
    local errs=0
    printf "\nUpdating packages list...\n"
    find_packages > "$filename_pkgs" || let errs+=1
    printf "\nUpdating pip2 packages list...\n"
    find_pip "2" > "$filename_pip2_pkgs" || let errs+=1
    printf "\nUpdating pip3 packages list...\n"
    find_pip "3" > "$filename_pip3_pkgs" || let errs+=1
    printf "\nUpdating apm packages list...\n"
    find_apm_packages > "$filename_apm" || let errs+=1
    return $errs
}

# Switches for script actions, set by arg parsing.
declare -a nonflags
dry_run=0
do_all=1
do_apm=0
do_apt=0
do_check=0
do_config=0
do_debfiles=0
do_dotfiles=0
do_find=0
do_findapm=0
do_findpackages=0
do_findpip2=0
do_findpip3=0
do_gems=0
do_gitclones=0
do_listing=0
do_list=0
do_listapm=0
do_listclones=0
do_listdebs=0
do_listgems=0
do_listpip2=0
do_listpip3=0
do_pip2=0
do_pip3=0
do_update=0

for arg; do
    case "$arg" in
        "-a"|"--apt" )
            do_apt=1
            do_all=0
            ;;
        "-ap"|"--apm" )
            do_apm=1
            do_all=0
            ;;
        "-c"|"--config" )
            do_config=1
            do_all=0
            ;;
        "-C"|"--checkfiles" )
            do_check=1
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
        "-f2"|"--findpip2" )
            do_find=1
            do_findpip2=1
            ;;
        "-f3"|"--findpip3" )
            do_find=1
            do_findpip3=1
            ;;
        "-fa"|"--findapm" )
            do_find=1
            do_findapm=1
            ;;
        "-fp"|"--findpackages" )
            do_find=1
            do_findpackages=1
            ;;
        "-g"|"--gems" )
            do_gems=1
            do_all=0
            ;;
        "-gc"|"--gitclones" )
            do_gitclones=1
            do_all=0
            ;;
        "-h"|"--help" )
            print_usage ""
            exit 0
            ;;
        "-l"|"--list" )
            do_listing=1
            do_list=1
            ;;
        "-l2"|"--listpip2" )
            do_listing=1
            do_listpip2=1
            ;;
        "-l3"|"--listpip3" )
            do_listing=1
            do_listpip3=1
            ;;
        "-la"|"--listapm" )
            do_listing=1
            do_listapm=1
            ;;
        "-lc"|"--listclones" )
            do_listing=1
            do_listclones=1
            ;;
        "-lg"|"--listgems" )
            do_listing=1
            do_listgems=1
            ;;
        "-ld"|"--listdebs" )
            do_listing=1
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
        "-u"|"--update" )
            do_update=1
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

debug_depends

if ((do_check)); then
    check_required_files || {
        # Missing files are printed on error.
        exit 1
    }
    # All files were found.
    print_required_files "existing"
    exit 0
elif ((do_update)); then
    update_pkg_lists || {
        echo_err "Failed to update some package lists ($?)."
        exit 1
    }
    exit 0
elif ((do_find)); then
    ((do_findapm)) && {
        find_apm_packages || echo_err "Failed to find apm packages."
    }
    ((do_findpackages)) && {
        find_packages || echo_err "Failed to find apt packages."
    }
    ((do_findpip2)) && {
        find_pip "2" || echo_err "Failed to find pip2 packages."
    }
    ((do_findpip3)) && {
        find_pip "3" || echo_err "Failed to find pip3 packages."
    }

    list_failures && exit 1
    exit
elif ((do_listing)); then
    ((do_list)) && {
        list_file "$filename_pkgs" || echo_err "Failed to list apt packages."
    }
    ((do_listapm)) && {
        list_file "$filename_apm" || echo_err "Failed to list apm packages."
    }
    ((do_listclones)) && {
        list_file "$filename_git_clones" || echo_err "Failed to list git clones."
    }
    ((do_listdebs)) && {
        list_debfiles || echo_err "Failed to list .deb files."
        list_debfiles_remote || echo_err "Failed to list remote .deb files."
    }
    ((do_listgems)) && {
        list_file "$filename_gems" || echo_err "Failed to list gems."
    }
    ((do_listpip2)) && {
        list_file "$filename_pip2_pkgs" || echo_err "Failed to list pip2 packages."
    }
    ((do_listpip3)) && {
        list_file "$filename_pip3_pkgs" || echo_err "Failed to list pip3 packages."
    }

    list_failures && exit 1
    exit
fi

# Make sure we have at least one package list to work with.
check_required_files || exit 1

# System apt packages.
if ((do_all || do_apt)); then
    run_cmd "sudo apt-get update" "Upgrading the packages list..."
    install_apt_packages || {
        echo_err "Failed to install some apt packages ($?)\n    ...this may be okay though."
    }
    install_apt_depends || {
        echo_err "Failed to install some script dependencies ($?)\n    ...future installs may fail."
    }
fi
# Local/remote apt packages.
if ((do_all || do_debfiles)); then
    install_debfiles || {
        echo_err "Failed to install third-party deb packages (~$?)!"
    }
    install_debfiles_remote || {
        echo_err "Failed to install remote third-party deb packages (~$?)!"
    }
fi
# Pip2 packages.
if ((do_all || do_pip2)); then
    install_pip_packages "2" || {
        echo_err "Failed to install some pip2 packages ($?)\n    ...this may be okay though."
    }
fi
# Pip3 packages.
if ((do_all || do_pip3)); then
    install_pip_packages "3" || {
        echo_err "Failed to install some pip3 packages ($?)\n    ...this may be okay though."
    }
fi
# App config files.
if ((do_all || do_config)); then
    install_config || echo_err "Failed to install config files!"
fi
# Bash config/dotfiles.
if ((do_all || do_dotfiles)); then
    install_dotfiles || echo_err "Failed to install dot files!"
fi
# Ruby-gems
if ((do_all || do_gems)); then
    install_gems || echo_err "Failed to install some gem files ($?)!"
fi
# Atom packages
if ((do_all || do_apm)); then
    install_apm_packages || echo_err "Failed to install some apm packages ($?)!"
fi
# Git clones with executables.
if ((do_all || do_gitclones)); then
    install_git_clones || {
        echo_err "Failed to install some git clone executables ($?)!"
        ((dry_run)) && echo_err "...git clones will always fail on a dry run."
    }
fi
# Pre-compiled binaries.
if ((do_all)); then
    # Add a note about pre-compiled binaries that fresh-install doesn't handle yet.
    declare -A compiledexes=(
        [hub]="https://github.com/github/hub/releases/download/v2.2.3/hub-linux-amd64-2.2.3.tgz"
        [cling]="https://root.cern.ch/download/cling//cling_2016-05-29_ubuntu14.tar.bz2"
    )
    printf "\nThere are still some pre-compiled binaries missing!\n"
    printf "You can download them from here:\n"
    for exename in "${!compiledexes[@]}"; do
        printf "    %-16s: %s\n" "$exename" "${compiledexes[$exename]}"
    done
fi

list_failures && exit 1
exit
