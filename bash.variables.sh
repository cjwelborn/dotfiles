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
export Home='/home/cj'

# Frequently used dirs/files
export Aliases="/etc/bash.alias.sh"
export Apps="$Home/apps"
export Dump="$Home/dump"
export Variables="$Home/bash.variables.sh"

# Script dirs
export Html="$Home/html"
export Scripts="$Home/scripts"
export Haskell="$Scripts/haskell"
export Js="$Scripts/js"
export Teststuff="$Scripts/teststuff"
export Snippets="$Scripts/snippets"
export Monoprojects="$Home/monoprojects"
export Mono="$Monoprojects"
export Rustprojects="$Scripts/rust"
export Rustprojs="$Rustprojects"

# Project locations
export Work=$Scripts
export Cedit="$Work/cedit/cedit"
export Clones="$Home/clones"
export Cram="$Work/cram/cram_site"
export Menuprops="$Work/eclipse/menuprops"
export Pyval="$Work/pyval"
export Wp="$Work/welbornprod/wp_site"
export Unimenu="$Work/eclipse/unimenu"
export Easysettings="$Work/eclipse/EasySettings"
export Webgui="$Work/webgui"
export Webapp=$Webgui

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

export Py3homepkgs="$Home/.local/lib/python3.5/site-packages"
export Py3userpkgs="$Py3homepkgs"
export Py3pkgs="/usr/local/lib/python3.5/dist-packages"
export Py3mainpkgs="/usr/lib/python3.5/"

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

[ -n "$PS1" ] && echo "Variables loaded... (bash.variables.sh)"
