#!/bin/bash

# This file includes exports that should be enabled in any mode,
# non-interactive, or interactive.
# To use it edit /etc/bash.bashrc (for all users) to include:
#   source bash.extras.non-interactive.sh
#   # If not running interactively, don't do anything --------------------
#   [ -z "$PS1" ] && return
#
# -Christopher Welborn 8-9-13

if [[ -d "/home/cjwelborn" ]]; then
    # Remote
    cjhome="/home/cjwelborn"
elif [[ -d "/home/cj" ]]; then
    # Local
    cjhome="/home/cj"
elif [[ -n "$HOME" ]] && [[ -d "$HOME" ]]; then
    # Not one of my main machines.
    cjhome=$HOME
elif [[ -n "$USER" ]] && [[ -d "/home/$USER" ]]; then
    # It would be weird to have USER and no HOME, but whatever.
    cjhome="/home/$USER"
else
    _echo "Cannot find a suitable /home directory!"
    cjhome="/root"
fi

# Log some debug info while loading this script.
if [[ -w "$cjhome" ]]; then
  bashextraslogfile="$cjhome/extras.non-interactive.log"
else
  echo_safe "No log file to write to."
fi

function bashextraslog {
    # Write to the bash.extras.interactive.log
    if [[ -n "$2" ]]; then
        # label/value pair.
        printf "%-40s: %s\n" "$1" "$2" >> "$bashextraslogfile"
    else
        echo -e "$@" >> "$bashextraslogfile"
    fi
}
echo "Loading ${BASH_SOURCE[0]}, cjhome=$cjhome" > "$bashextraslogfile"

# Shell options
declare -a shopts=(
    # Allow using directory-variables as commands to cd into that directory.
    # Example: $Scripts  (like: cd $Scripts)
    autocd
    # Allow using directory-variables without the $.
    # Example: cd Scripts (like: cd $Scripts)
    cdable_vars
    # Allow recursive star patterns (**/*)
    globstar
)
for shoptname in "${shopts[@]}"; do
    shopt -s "$shoptname"
done
unset shoptname
bashextraslog "shopt set ${#shopts[@]} options" "${shopts[*]}"
unset shopts

# Ignore duplicate entries in bash history, but keep the most recent.
export HISTCONTROL=ignoreboth:erasedups
bashextraslog "Set HISTCONTROL" "$HISTCONTROL"
# Use english UTF8 everywhere.
export LC_ALL=en_US.UTF-8
bashextraslog "Set LC_ALL" "$LC_ALL"
hash ksshaskpass &>/dev/null && export SSH_ASKPASS="/usr/bin/ksshaskpass"


# Get Cj's Variables first, so they are available in other scripts.
variablefile="$cjhome/bash.variables.sh"
if [[ -f "$variablefile" ]]; then
    # shellcheck source=/home/cj/bash.variables.sh
    source "$variablefile"
    bashextraslog "Sourced variables file" "$variablefile"
else
    echo_safe "Variables file not found" "$variablefile"
    bashextraslog "Variables file not found" "$variablefile"
fi

# Basic environment variables.
if hash cedit &>/dev/null; then
    # Use whatever my favorite editor is set to.
    export EDITOR="cedit"
elif hash vim &>/dev/null; then
    export EDITOR="vim"
elif hash nano &>/dev/null; then
    # If worse comes to worse...
    export EDITOR="nano"
fi
bashextraslog "Set EDITOR" "$EDITOR"

# Use cj's .local bin for everyone with permissions.
if [[ -d $cjhome/.local/bin ]] && [[ -x $cjhome/.local/bin ]]; then
    export PATH=$cjhome/.local/bin:$PATH
fi

if [[ -d $cjhome/bin ]] &&  [[ -x $cjhome/bin ]]; then
    export PATH=$cjhome/bin:$PATH
fi

# Paths for go language.
if [[ -d $cjhome/scripts/go ]] && [[ -x $cjhome/scripts/go ]]; then
    export GOPATH=$cjhome/scripts/go
    export PATH=$PATH:$GOPATH/bin
    bashextraslog "Set GOPATH" "$GOPATH"
else
    bashextraslog "No GOPATH set, missing" "$cjhome/scripts/go"
fi

# Paths for node.js executables.
nodemod_bin="$cjhome/node_modules/.bin"
if [[ -d "$nodemod_bin" ]] && [[ -x "$nodemod_bin" ]]; then
    export PATH="$PATH:$nodemod_bin"
    bashextraslog "Set global node_modules bin path" "$nodemod_bin"
else
    bashextraslog "No node bin path set, missing" "$nodemod_bin"
fi
unset nodemod_bin

# Cargo installed binaries.
cargo_bin_dir="$cjhome/.cargo/bin"
if [[ -d "$cargo_bin_dir" ]]; then
    export PATH="$PATH:$cargo_bin_dir"
    bashextraslog "Set cargo bin path" "$cargo_bin_dir"
else
    bashextraslog "No cargo bin path set, missing" "$cargo_bin_dir"
fi
unset cargo_bin_dir

# Node version manager.
if [[ -d "$cjhome/.nvm" ]] && [[ -x "$cjhome/.nvm" ]]; then
    export NVM_DIR="$cjhome/.nvm"
    # shellcheck source=/home/cj/.nvm/nvm.sh
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"  # This loads nvm
    # Add all node version's bin directories to path.
    shopt -s nullglob
    nvmversions=("$cjhome"/.nvm/versions/*/*)
    if (( ${#nvmversions[@]} > 0 )); then
        for node_ver_dir in "${nvmversions[@]}"; do
            node_bin_dir="${node_ver_dir}/bin"
            if [[ -d "${node_bin_dir}" ]]; then
                # Add this version of node's /bin directory for executables.
                export PATH="$PATH:${node_bin_dir}"
                bashextraslog "Set nvm bin dir path" "$node_bin_dir"
            fi
            node_modules_dir="${node_ver_dir}/lib/node_modules"
            if [[ -d "${node_modules_dir}" ]]; then
                # Add /node_modules to node's path, so they are require()able.
                if [[ -z "$NODE_PATH" ]]; then
                    # First path added, no colon needed.
                    export NODE_PATH=$node_modules_dir
                else
                    export NODE_PATH="$NODE_PATH:${node_modules_dir}"
                fi
                bashextraslog "Added NODE_PATH" "$node_modules_dir"
            fi
        done
        # These shouldn't be available after init.
        unset node_bin_dir node_modules_dir
    fi
    # Nvm node versions array isn't needed after init.
    unset nvmversions
    shopt -u nullglob
else
    bashextraslog "No nvm bin paths set, missing" "$cjhome/.nvm"
fi

# Install path for ruby gems.
export GEM_HOME=$cjhome/gems
gem_bin_dir="$GEM_HOME/bin"
# Paths for ruby/gem executables.
if [[ -d "$gem_bin_dir" ]] && [[ -x "$gem_bin_dir" ]]; then
    export PATH="$PATH:$gem_bin_dir"
    bashextraslog "Set \`gem\` bin path" "$gem_bin_dir"
else
    bashextraslog "No gem bin path set, missing" "$gem_bin_dir"
fi
unset gem_bin_dir

# Executables for Haskell/Cabal
cabal_bin_dir="$cjhome/.cabal/bin"
if [[ -d $cabal_bin_dir ]] && [[ -x $cabal_bin_dir ]]; then
    export PATH="$PATH:$cabal_bin_dir"
    bashextraslog "Set \`cabal\` bin dir path" "$cabal_bin_dir"
else
    bashextraslog "No cabal bin path set, missing" "$cabal_bin_dir"
fi
unset cabal_bin_dir

# Export python startup file to enable auto-complete/startup features.
pystartupfile=$cjhome/.pystartup
if [[ -f "$pystartupfile" ]]; then
    export PYTHONSTARTUP="$pystartupfile"
    bashextraslog "Set python startup file" "$pystartupfile"
else
    echo_safe "Python startup file not found" "${pystartupfile}"
    bashextraslog "Python startup file not found" "$pystartupfile"
fi

# Rust source path for racer.
rust_src_dir="$cjhome/clones/rust/src"
if [[ -d "$rust_src_dir" ]] && [[ -z "$RUST_SRC_PATH" ]]; then
    export RUST_SRC_PATH=$rust_src_dir
    bashextraslog "Set rust src dir (for racer)" "$rust_src_dir"
else
    bashextraslog "No rust src dir set, missing" "$rust_src_dir"
fi
unset rust_src_dir

# Options for Scratchbox (cross-compilation setup for raspberry-pi)
if [[ -d /srv/chroot/wheezy_raspbian ]]; then
    export SB2=/srv/chroot/wheezy_raspbian
    export SB2OPT='-t ARM'
    bashextraslog "Set Scratchbox cross-compilation vars" "SB2=$SB2, SB2OPT=$SB2OPT."
else
    bashextraslog "No Scratchbox vars set, missing" "/srv/chroot/wheezy_raspbian"
fi

# Make alt + shift toggle us/greek layout (enables using chars like λ)
if hash setxkbmap &>/dev/null; then
    kblayout="us,gr"
    kbopts="grp:switch,grp:alt_caps_toggle,grp_led:scroll"
    if setxkbmap -query | grep 'alt_caps_toggle' &>/dev/null; then
        bashextraslog "Keyboard layout already set" "$kblayout"
        bashextraslog "Keyboard layout options" "$kbopts"
    else
        if setxkbmap -option "$kbopts" -layout "$kblayout"; then
            bashextraslog "Set keyboard layout options" "$kbopts"
            bashextraslog "Set keyboard layouts" "$kblayout"
        else
            bashextraslog "Unable to set keyboard layout options!"
        fi
    fi
    unset kblayout
    unset kbopts
else
    # This can happen on Linux Subsystem for Windows.
    bashextraslog "Unable to set keyboard layout, missing" "setxkbmap"
fi
# Set limit for number of processes.
# ..helps to prevent fork-bombs, accidental or intentional.
# This is a 'soft' limit (-S), which can be increased by a non-root user.
#         Default setting: 62312
# Usual running processes: 252
ulimit_proc_max=5000
if ulimit -S -u "$ulimit_proc_max" 2>/dev/null; then
    echo_safe "Set process limit" "$ulimit_proc_max"
    bashextraslog "Set process limit" "$ulimit_proc_max"
else
    bashextraslog "Failed to set process limit."
fi
unset -v ulimit_proc_max

# Auto LetsEncrypt cert renewel program. Not being used right now.
acme_env_file="$cjhome/.acme.sh/acme.sh.env"
if [[ -f "$acme_env_file" ]]; then
    # shellcheck source=/home/cjwelborn/.acme.sh/acme.sh.env
    # shellcheck disable=SC1091
    # ..this file doesn't always exist shellcheck.
    source "$acme_env_file"
    echo_safe "Sourced acme.sh file" "$acme_env_file"
    bashextraslog "Sourced acme.sh file" "$acme_env_file"
fi
