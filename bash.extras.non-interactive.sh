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

# Get Cj's Variables first, so they are available in other scripts.
variablefile="/home/cj/bash.variables.sh"
if [[ -f "$variablefile" ]]; then
    source "$variablefile"
else
    _echo "Variables file not found: $variablefile"
fi

# Use cj's .local bin for everyone
if [[ -d /home/cj/.local/bin ]]; then
    export PATH=/home/cj/.local/bin:$PATH
fi

if [[ -d /home/cj/bin ]]; then
    export PATH=/home/cj/bin:$PATH
fi

# Paths for go language.
#export GOROOT=/usr/bin
if [[ -d /home/cj/gocode ]]; then
    export GOPATH=/home/cj/gocode
    export PATH=$PATH:$GOPATH/bin
fi

# Paths for node.js executables.
if [[ -d /home/cj/node_modules/.bin ]]; then
    export PATH=$PATH:/home/cj/node_modules/.bin
fi

# Install path for ruby gems.
export GEM_HOME=/home/cj/gems
# Paths for ruby/gem executables.
if [[ -d /home/cj/gems/bin ]]; then
    export PATH=$PATH:/home/cj/gems/bin
fi

# Executables for Haskell/Cabal
if [[ -d /home/cj/.cabal/bin ]]; then
    export PATH=$PATH:/home/cj/.cabal/bin
fi

# Export python startup file to enable auto-complete/startup features.
pystartupfile=/home/cj/.pystartup
if [[ -f $pystartupfile ]]; then
    export PYTHONSTARTUP=/home/cj/.pystartup
else
    _echo "Python startup file not found: ${pystartupfile}"
fi

# Rust source path for racer.
if [[ -d /home/cj/workspace/clones/rust/src ]] && [[ -z "$RUST_SRC_PATH" ]]; then
    export RUST_SRC_PATH=/home/cj/workspace/clones/rust/src
fi

# Options for Scratchbox (cross-compilation setup for raspberry-pi)
if [[ -d /srv/chroot/wheezy_raspbian ]]; then
    export SB2=/srv/chroot/wheezy_raspbian
    export SB2OPT='-t ARM'
fi

# Make alt + shift toggle us/greek layout (enables using chars like λ)
setxkbmap -option "grp:switch,grp:alt_shift_toggle,grp_led:scroll" -layout "us,gr"
