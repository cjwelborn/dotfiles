#!/bin/bash

# This file includes exports that should be enabled in any mode,
# non-interactive, or interactive.
# To use it edit /etc/bash.bashrc (for all users) to include:
#   source bash.extras.non-interactive.sh
#   # If not running interactively, don't do anything --------------------
#   [ -z "$PS1" ] && return
#
# -Christopher Welborn 8-9-13

# Shell options
# Allow using directory-variables as commands to cd into that directory.
# Example: $Scripts  (like: cd $Scripts)
shopt -s autocd
# Allow using directory-variables without the $.
# Example: cd Scripts (like: cd $Scripts)
shopt -s cdable_vars
# Allow recursive star patterns (**/*)
shopt -s globstar

function _echo {
    # Echo only in interactive mode.
    if [[ -n "$PS1" ]]; then
        echo "$@"
    fi
}

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


# Get Cj's Variables first, so they are available in other scripts.
variablefile="$cjhome/bash.variables.sh"
if [[ -f "$variablefile" ]]; then
    source "$variablefile"
else
    _echo "Variables file not found: $variablefile"
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
fi

# Paths for node.js executables.
if [[ -d $cjhome/node_modules/.bin ]] && [[ -x $cjhome/node_modules/.bin ]]; then
    export PATH="$PATH:$cjhome/node_modules/.bin"
fi

# Cargo installed binaries.
# /home/cj/.multirust/toolchains/nightly/cargo/bin
if [[ -d "$cjhome/.multirust/toolchains" ]] && [[ -x "$cjhome/.multirust/toolchains" ]]; then
    export MULTIRUST_TOOLCHAIN_DIR="$cjhome/.multirust/toolchains"
    shopt -s nullglob
    # Get all multirust toolchain dirs.
    multirust_dirs=("$MULTIRUST_TOOLCHAIN_DIR"/*)
    if (( ${#multirust_dirs[@]} > 0 )); then
        for multirust_dir in "${multirust_dirs[@]}"; do
            multirust_bin_dir="$multirust_dir/cargo/bin"
            if [[ -d "$multirust_bin_dir" ]]; then
                # Add this multirust toolchain's bin dir to PATH.
                export PATH="$PATH:${multirust_bin_dir}"
            fi
        done
        # Shouldn't be available after init.
        unset multirust_dir multirust_bin_dir
    fi
    # These shouldn't be available after init.
    unset multirust_dirs
    shopt -u nullglob
fi

# Node version manager.
if [[ -d "$cjhome/.nvm" ]] && [[ -x "$cjhome/.nvm" ]]; then
    export NVM_DIR="$cjhome/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
    # Add all node version's bin directories to path.
    shopt -s nullglob
    nvmversions=("$cjhome"/.nvm/versions/*/*)
    if (( ${#nvmversions[@]} > 0 )); then
        for node_ver_dir in "${nvmversions[@]}"; do
            node_bin_dir="${node_ver_dir}/bin"
            if [[ -d "${node_bin_dir}" ]]; then
                # Add this version of node's /bin directory for executables.
                export PATH="$PATH:${node_bin_dir}"
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
            fi
        done
        # These shouldn't be available after init.
        unset node_bin_dir node_modules_dir
    fi
    # Nvm node versions array isn't needed after init.
    unset nvmversions
    shopt -u nullglob
fi

# Install path for ruby gems.
export GEM_HOME=$cjhome/gems
# Paths for ruby/gem executables.
if [[ -d $cjhome/gems/bin ]] && [[ -x $cjhome/gems/bin ]]; then
    export PATH="$PATH:$cjhome/gems/bin"
fi

# Executables for Haskell/Cabal
if [[ -d $cjhome/.cabal/bin ]] && [[ -x $cjhome/.cabal/bin ]]; then
    export PATH=$PATH:$cjhome/.cabal/bin
fi

# Export python startup file to enable auto-complete/startup features.
pystartupfile=$cjhome/.pystartup
if [[ -f $pystartupfile ]]; then
    export PYTHONSTARTUP=$cjhome/.pystartup
else
    _echo "Python startup file not found: ${pystartupfile}"
fi

# Rust source path for racer.
if [[ -d $cjhome/clones/rust/src ]] && [[ -z "$RUST_SRC_PATH" ]]; then
    export RUST_SRC_PATH=$cjhome/clones/rust/src
fi

# Options for Scratchbox (cross-compilation setup for raspberry-pi)
if [[ -d /srv/chroot/wheezy_raspbian ]]; then
    export SB2=/srv/chroot/wheezy_raspbian
    export SB2OPT='-t ARM'
fi

# Make alt + shift toggle us/greek layout (enables using chars like λ)
setxkbmap -option "grp:switch,grp:alt_shift_toggle,grp_led:scroll" -layout "us,gr"

# Set limit for number of processes.
# ..helps to prevent fork-bombs, accidental or intentional.
# This is a 'soft' limit (-S), which can be increased by a non-root user.
#         Default setting: 62312
# Usual running processes: 252
ulimit -S -u 5000
