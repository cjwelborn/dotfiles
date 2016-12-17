This install script installs my most used applications from:
* `debian/apt`: Installs Debian packages using `apt` from a package list, local `.deb.`
files using `dpkg`, and remote `.deb.` files by downloading and installing with `dpkg`.

    * `./pkgs.txt`: List of debian package names to install with `apt`.
    * `./debs`: Debian package files to install with `dpkg`.
    * `./remote-debs.txt`: List of names/urls to download debian packages and install with `dpkg`.


* `apm`: Installs Atom packages from a list using `apm`.

    * `./apm-pkgs.txt`: List of atom package names to install with `apm`.

* `pip`: Installs Python packages using `pip`, with separate lists for Python
2.7 and 3+.

    * `./pip2-pkgs.txt`: List of PyPi package names to install with `pip2`.
    * `./pip3-pkgs.txt`: List of PyPi package names to install with `pip3`.


* `gem`: Installs Ruby gems from a list using `gem`.

    * `./gems.txt`: List of gem names to install with `gem`.


* `git`: Installs simple git clones, and symlinks the main executable to
`~/.local/bin`.

    * `./clones.txt`: List of executables/urls to clone and symlink.


* install scripts: Runs various install scripts in `./installscripts`
to download and install applications that need configuring (like rustup).
