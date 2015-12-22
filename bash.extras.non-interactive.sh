#!/bin/bash

# This file includes exports that should be enabled in any mode,
# non-interactive, or interactive.
# To use it edit /etc/bash.bashrc (for all users) to include:
#   source bash.extras.non-interactive.sh
#   # If not running interactively, don't do anything --------------------
#   [ -z "$PS1" ] && return
#
# -Christopher Welborn 8-9-13 (not all pieces are original work)

# Shell options
# Allow using directory-variables as commands to cd into that directory.
# Example: $Scripts  (like: cd $Scripts)
shopt -s autocd
# Allow using directory-variables without the $.
# Example: cd Scripts (like: cd $Scripts)
shopt -s cdable_vars

function _echo {
    # Echo only in interactive mode.
    if [[ -n "$PS1" ]]; then
        echo "$@"
    fi
}

if [[ -d /home/cjwelborn ]]; then
    cjhome='/home/cjwelborn'
else
    if [[ -d "/home/cj" ]]; then
        cjhome="/home/cj"
    else
        # Not one of my main machines.
        if [[ -n "$HOME" ]] && [[ -d "$HOME" ]]; then
            cjhome=$HOME
        elif [[ -n "$USER" ]] && [[ -d "/home/$USER" ]]; then
            cjhome="/home/$USER"
        else
            _echo "Cannot find a suitable /home directory!"
            cjhome="/root"
        fi
    fi
fi

# Get Cj's Variables first, so they are available in other scripts.
variablefile="$cjhome/bash.variables.sh"
if [[ -f "$variablefile" ]]; then
    source "$variablefile"
else
    _echo "Variables file not found: $variablefile"
fi

# Use cj's .local bin for everyone
if [[ -d $cjhome/.local/bin ]]; then
    export PATH=$cjhome/.local/bin:$PATH
fi

if [[ -d $cjhome/bin ]]; then
    export PATH=$cjhome/bin:$PATH
fi

# Paths for go language.
#export GOROOT=/usr/bin
if [[ -d $cjhome/gocode ]]; then
    export GOPATH=$cjhome/gocode
    export PATH=$PATH:$GOPATH/bin
fi

# Paths for node.js executables.
if [[ -d $cjhome/node_modules/.bin ]]; then
    export PATH="$PATH:$cjhome/node_modules/.bin"
fi

# Node version manager.
if [[ -d "$cjhome/.nvm" ]]; then
    export NVM_DIR="$cjhome/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
    # Add all node version's bin directories to path.
    shopt -s nullglob
    nvmversions=("$cjhome"/.nvm/versions/*/*)
    if (( ${#nvmversions[@]} > 0 )); then
        for _nvm_verdir in "${nvmversions[@]}"; do
            _nvm_verbindir="${_nvm_verdir}/bin"
            if [[ -d "${_nvm_verbindir}" ]]; then
                export PATH="$PATH:${_nvm_verbindir}"
            fi
        done
    fi
    shopt -u nullglob
fi

# Install path for ruby gems.
export GEM_HOME=$cjhome/gems
# Paths for ruby/gem executables.
if [[ -d $cjhome/gems/bin ]]; then
    export PATH="$PATH:$cjhome/gems/bin"
fi

# Executables for Haskell/Cabal
if [[ -d $cjhome/.cabal/bin ]]; then
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
if [[ -d $cjhome/workspace/clones/rust/src ]] && [[ -z "$RUST_SRC_PATH" ]]; then
    export RUST_SRC_PATH=$cjhome/workspace/clones/rust/src
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
