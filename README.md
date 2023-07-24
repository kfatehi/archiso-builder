# archiso-builder

Build your own Arch Linux ISO made with 'archiso' very simply using Docker[^1]

See what archiso is in the [ArchLinux wiki](https://wiki.archlinux.org/title/Archiso)

A built-in pacman cache[^2] is automatically used to prevent unnecessary downloads.

Please configure your preferred upstream mirror URLs in `pacoloco/pacoloco.yaml`

The project may also integrate additional proxies.

## How to use?

First, get a copy of the `releng` config by using the `new` command:

```bash
    ./cli.sh new foo
```

To build the image, run:

```bash
    ./cli.sh build ./foo
```

## Offline Installation

This tool facilitates offline installation.

The `custompkgs` command creates a custom repository with a list of packages (including from the AUR) to host within the live environment image[^3].

In order to use it, specify the the directory containing the following structure as an argument to the command.


```bash
./cli.sh custompkgs ./my_custom_packages_dir
```

```
my_custom_packages_dir/
  |__pkglist.txt
  |__create.sh
```

Where create.sh is a script like this:

```bash
#!/bin/bash
set -euxo pipefail

if [[ -d ./aur ]]; then
    for file in $(ls ./aur/*.sh | sort -V); do
        echo "Sourcing $file"
        source $file
    done
fi

# Creating custom repo with everything we need for an offline installation including what we've built above
# https://wiki.archlinux.org/title/Offline_installation
mkdir -p Packages /tmp/blankdb
cd Packages
pacman -Syw --cachedir . --dbpath /tmp/blankdb base base-devel linux linux-firmware mkinitcpio vim $(cat ../pkglist.txt) --noconfirm
repo-add ./custom.db.tar.gz ./*[^sig]
```

And pkglist.txt contains the list of packages you wish to host. At the very least it should contain:

```
base
linux
linux-firmware
```

But it can also contain packages you have prebuilt from the AUR. It must be a complete list of every package you might want.

The best way to generate this is to customize a standard archlinux installation and then, when finished, extract the full package list with:

```bash
pacman -Q | awk '{print $1}' > pkglist.txt
```

If you're using the create.sh script provided above, then integrating AUR packages can be done by dreating a `aur` directory inside your custom packages directory and in there you can add scripts. For example, to install bluez-alsa-git, you might create `bluezalsa.sh` with the following content:

```bash
# In order to build from AUR, we need a non-root user
useradd -m arch

# Building bluez-alsa-git from AUR
pacman -Sy base base-devel linux-headers alsa-lib bluez-libs libfdk-aac sbc python-docutils --noconfirm
runuser -l arch -c "git clone https://aur.archlinux.org/bluez-alsa-git.git"
runuser -l arch -c "cd bluez-alsa-git && makepkg -f --cleanbuild"
runuser -l arch -c "cd bluez-alsa-git && repo-add bluezalsa.db.tar.gz *.zst"
cat <<EOF >> /etc/pacman.conf
[bluezalsa]
SigLevel = Optional TrustAll
Server = file:///home/arch/bluez-alsa-git
EOF
```

The final append to pacman.conf is important so that when we export the packages for adding to the local custom repo, the package can be found.

Finally, with an appropriate releng config, your installation can use this instead of the internet.[^4]:

```bash
# releng/pacman.conf and releng/airootfs/etc/pacman.conf
# comment out core and extra, and only specify custom:
[custom]
SigLevel = Never
Server = file:///root/custompkgs/Packages
```

The docker mounts ensure that this path makes sense within the context of the image build. Be sure to pass the custompackages directory again to build if using this mechanism. e.g. you will now use:

```bash
./cli.sh build ./foo ./my_custom_packages
```

## Discussion

Alternatively to using the `new` command I recommend cloning the upstream[^6] archiso scripts repository and symlinking the configs directory.
This way, as you make changes, it will be more clear what you have done within the context of what others have done before you (as in, the git history is preserved) rather than taking the entire releng config as a clean slate.

[^1]: Originally forked from https://github.com/nlhomme/archiso-builder
[^2]: Pacman cache facilitate by Pacoloco https://github.com/anatol/pacoloco
[^3]: ArchWiki: Adding repositories to the image https://wiki.archlinux.org/title/Archiso#Adding_repositories_to_the_image
[^4]: ArchWiki: Offline Installation https://wiki.archlinux.org/title/Offline_installation
[^5]: ArchWiki: Offline Wiki https://wiki.archlinux.org/title/Help:Browsing#Offline_viewing
[^6]: Official archiso scripts Repository https://gitlab.archlinux.org/archlinux/archiso