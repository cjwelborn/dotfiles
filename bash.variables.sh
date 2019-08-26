#!/usr/bin/env bash
# Bash Global Variables for Cj
# Purposely hardcoded '/home/cj/' into this,
# though easily changeable through $Home.

# ...these variables always start with a capital letter, and a lowercase tail.
#    for easy typing, and collision avoidance.
# Source from /etc/bash.bashrc or other globally sourced file:
#   source bash.variables.sh
#
# -Christopher Welborn 8-9-14

# Root for frequently used dirs.
if [[ -d "/home/cj" ]]; then
    export Home='/home/cj'
elif [[ -d "/home/cjwelborn" ]]; then
    # Remote/welbornprod server.
    export Home="/home/cjwelborn"
fi

# Frequently used dirs/files
export Aliases="/etc/bash.alias.sh"
export Apps="$Home/apps"
export Dump="$Home/dump"
export Variables="$Home/bash.variables.sh"
export Sublimeconfig="$Home/.config/sublime-text-3"
export Sublimepackages="$Sublimeconfig/Packages"

# Remote-only dirs.
[[ -d "$Home/logs/user" ]] && export Logs="$Home/logs/user"
# Script dirs
export Html="$Home/html"
export Scripts="$Home/scripts"
export Cprojects="$Scripts/c"
export Clibs="$Cprojects/libs"
export Haskell="$Scripts/haskell"
export Js="$Scripts/js"
export Teststuff="$Scripts/teststuff"
export Snippets="$Scripts/snippets"
export Monoprojects="$Home/monoprojects"
export Rustprojects="$Scripts/rust"

# Project locations
export Work=$Scripts
export Bash="$Work/bash"
export Cedit="$Work/cedit/cedit"
export Clones="$Home/clones"
export Colr="$Work/colr"
export Colrc="$Work/c/libs/colr"
export Pyval="$Work/pyval"
export Textcmd="$Bash/textcmd"

if [[ -d "$Work/welbornprod/wp_site" ]]; then
    export Wp="$Work/welbornprod/wp_site"
elif [[ -d "$Home/webapps/wp_site/wp_site" ]]; then
    export Wp="$Home/webapps/wp_site/wp_site"
fi
[[ -d "$Home/webapps/wp_test/wp_site" ]] && export Wp_test="$Home/webapps/wp_test/wp_site"
export Easysettings="$Work/EasySettings"

# Popular clones
export Cpython="$Clones/cpython"

# home dirs
export Dl="$Home/Downloads"
export Installers="$Dl/installers"
export Homebin="$Home/.local/bin"
export Music="$Home/Music"
export Pictures="$Home/Pictures"
export Pics=$Pictures
export Screenshots="$Pictures/screenshots"
export Videos="$Home/Videos"
export Docs="$Home/Documents"
export Doc=$Docs

# known dirs (long to type)
export Py2homepkgs="$Home/.local/lib/python2.7/site-packages"
export Py2userpkgs="$Py2homepkgs"
export Py2pkgs="/usr/local/lib/python2.7/dist-packages"
export Py2mainpkgs="/usr/lib/python2.7/"

export Py3version="3.6"
export Py3homepkgs="$Home/.local/lib/python${Py3version}/site-packages"
export Py3userpkgs="$Py3homepkgs"
export Py3pkgs="/usr/local/lib/python${Py3version}/dist-packages"
export Py3mainpkgs="/usr/lib/python${Py3version}/"

# KDE ServiceMenu directories
export Servicemenus_local_old="$Home/.kde/share/kde4/services/ServiceMenus/"
export Servicemenus_global_old="/usr/share/kde4/services/ServiceMenus/"
export Servicemenus_local="$Home/.local/share/kservices5/ServiceMenus/"
export Servicemenus_global="/usr/share/kservices5/ServiceMenus/"

# Theme dirs
export Winthemes="$Home/.kde/share/apps"
export Winthemessystem="/usr/share/kde4/apps"
export Winthemessys="$Winthemessystem"
export Plasmathemes="$Home/.kde/share/apps/desktoptheme"
export Plasmathemessystem="/usr/share/kde4/apps/desktoptheme"
export Plasmathemessys="$Plasmathemessystem"
export Gtkthemes="$Home/.themes"
export Gtkthemessystem="/usr/share/themes"
export Gtkthemessys="$Gtkthemessystem"
# Beep sound file to play with the new 'beep' alias.
export BEEP="/usr/share/sounds/KDE-Im-Message-In.ogg"

echo_safe "Variables loaded" "bash.variables.sh"

