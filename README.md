# archiso-builder

Build your own Arch Linux ISO made with 'archiso' very simply using Docker[^1]

See what archiso is in the [ArchLinux wiki](https://wiki.archlinux.org/title/Archiso)

A built-in pacman cache[^2] is automatically used to prevent unnecessary downloads.

Please configure your preferred upstream mirror URLs in `pacoloco/pacoloco.yaml`

## How to use?

First, get a copy of the `releng` config by using the `new` command:

    ./cli.sh new foo

To build the image, run:

    ./cli.sh build foo

## Offline Installation

This tool facilitates offline installation.

The `custompkgs` command creates a custom repository with a list of packages (including from the AUR) to host within the live environment image[^3].

In order to use it, symlink or write a file in ./custompkgs/pkglist.txt with the list of packages you wish to host.

This needs to be a complete list of every package you might want. The best way to generate this is to customize a standard archlinux installation and then, when finished, extract the full package list with:

```
pacman -Q | awk '{print $1}' > pkglist.txt
```

To integrate AUR packages, symlink or create a directory `./custompkgs/aur` and in there you can add scripts. For example, to install bluez-alsa-git, you might create `./custompkgs/aur/001_bluez-alsa-git.sh` with the following content:

```
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

The final append to pacman.conf is important so that when we export the packages for adding to the local custom repo, they exist.

Finally, with an appropriate releng config, your installation can use this instead of the internet.[^4]:

```
# releng/pacman.conf and releng/airootfs/etc/pacman.conf
# comment out core and extra, and only specify custom:
[custom]
SigLevel = Optional TrustAll
Server = file:///root/custompkgs/Packages
```

The docker mounts ensure that this path makes sense within the context of the image build.

## Discussion

Alternatively to using the `new` command I recommend cloning the official[^6] archiso scripts repository and symlinking the configs directory.
This way, as you make changes, it will be more clear what you have done within the context of what others have done before you (as in, the git history is preserved) rather than taking the entire releng config as a clean slate.

# References

[^1]: Originally forked from https://github.com/nlhomme/archiso-builder
[^2]: Pacman cache facilitate by Pacoloco https://github.com/anatol/pacoloco
[^3]: ArchWiki: Adding repositories to the image https://wiki.archlinux.org/title/Archiso#Adding_repositories_to_the_image
[^4]: ArchWiki: Offline Installation https://wiki.archlinux.org/title/Offline_installation
[^5]: ArchWiki: Offline Wiki https://wiki.archlinux.org/title/Help:Browsing#Offline_viewing
[^6]: Official archiso scripts Repository https://gitlab.archlinux.org/archlinux/archiso