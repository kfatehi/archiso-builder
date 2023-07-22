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
