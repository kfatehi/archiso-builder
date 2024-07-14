FROM archlinux:base-devel-20240101.0.204074
RUN pacman -Syu --noconfirm
RUN pacman -S git archiso --noconfirm
ADD ./mirrorlist /etc/pacman.d/mirrorlist