My personal dot files. Some are hardcoded with my home path, because I make
things available to other users sometimes. I may figure out a better way
to do that.

Included Files:
---------

* `bash.alias.sh`:
    Exported aliases and functions. One-liners, complex functions, etc.

* `bash.bashrc`:
    Main bash file, which includes these files. It also uses `fortune`,
    `todo`, and some other header apps if they are available.

* `bash.extras.interactive.sh`:
    Environment modifications that should only run in interactive mode.
    Like prompt changes, BASH welcome messages, etc.

* `bash.extras.non-interactive.sh`:
    Environment modifications that should always run.
    Like PATH modifications, BASH options, keyboard layout settings.

* `bash.variables.sh`:
    Exported variables, like frequently used dirs. No changes to the existing
    environment are made here.

* `./fresh-install/fresh-install.sh`:
    An install script for my new/fresh-installed machines.
