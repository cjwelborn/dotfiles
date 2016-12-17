# fresh-install

This is an install script to help me move from one machine to another.
It can be ran on a machine that is already set up to create the package
lists. With existing package lists, the packages can be installed on
another machine.

It has lists for several package managers, and can also download package
files, git clone, symlink, and run custom scripts. Specifics are listed
[below](#current-install-methods-lists-and-directories-).

There are plenty of fail-safes and error messages if something goes
wrong, and `--dryrun` can be used to test the waters. With `--debug` enabled,
extra information is printed while running, so you can see what's going on
behind the scenes.

## Current install methods, lists, and directories:

### Debian

Installs Debian packages using `apt` from a package list,
local `.deb.` files using `dpkg`, and remote `.deb.` files by downloading and
installing with `dpkg`.

File|Desc.
---:|---
`./pkgs.txt` | List of debian package names to install with `apt`. This list can be generated with `--update` or `--findpackages`.
`./debs` | Directory containing Debian package files to install with `dpkg`. These files must be placed manually.
`./remote-debs.txt` | List of names/urls to download debian packages and
install with `dpkg`. This list must be created manually.

### Apm

Installs Atom packages from a list using `apm`.

File|Desc.
---:|---
`./apm-pkgs.txt` | List of atom package names to install with `apm`. This list can be generated with `--update` or `--findapm`.


### Pip

Installs Python packages using `pip`, with separate lists for Python
2.7 and 3+.

File|Desc.
---:|---
`./pip2-pkgs.txt` | List of PyPi package names to install with `pip2`.
`./pip3-pkgs.txt` | List of PyPi package names to install with `pip3`.

These lists can be generated with `--update`, `--findpip2`, or `--findpip3`.

### Gem

Installs Ruby gems from a list using `gem`.

File|Desc.
---:|---
`./gems.txt` | List of gem names to install with `gem`. This list must be created manually.


### Git

Installs simple git clones, and symlinks the main executable to
`~/.local/bin`. For more complicated clones/installs, an
[install script](#install-scripts) must be used.

File|Desc.
---:|---
`./clones.txt` | List of executables/urls to clone and symlink. This list must be created manually.


### Install Scripts

Runs various install scripts in `./installscripts` to download and install
applications that need help (like rustup). The install script can be anything.
It is made executable (`chmod +x`), if it is not executable already, and
executed in BASH as if `./installscripts/myscript.sh` was typed into the
terminal.
