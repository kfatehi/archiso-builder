FROM archlinux:latest
RUN pacman -Syu --noconfirm
RUN pacman -S git archiso --noconfirm
ADD ./mirrorlist /etc/pacman.d/mirrorlist
