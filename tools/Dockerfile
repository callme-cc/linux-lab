# https://github.com/fcwu/docker-ubuntu-vnc-desktop
FROM dorowu/ubuntu-desktop-lxde-vnc
MAINTAINER Falcon wuzhangjin@gmail.com

RUN sed -i -e "s%/archive.ubuntu.com%/cn.archive.ubuntu.com%g" /etc/apt/sources.list

#RUN bash -c 'echo deb http://www.emdebian.org/debian/ wheezy main > /etc/apt/sources.list.d/emdebian.list'
RUN bash -c 'echo deb http://mirrors.ustc.edu.cn/emdebian/toolchains/ wheezy main > /etc/apt/sources.list.d/emdebian.list'

RUN apt-get -y update

RUN apt-get install -y vim cscope exuberant-ctags build-essential

RUN apt-get install -y qemu-system-x86 qemu-system-arm qemu-system-mips qemu-system-ppc

RUN apt-get install -y bridge-utils

RUN apt-get install -y git ca-certificates

RUN apt-get install -y xz-utils

RUN apt-get install -y wget unzip bc

RUN apt-get install -y libncurses-dev

# For pre-built toolchains
RUN apt-get install -y libc6-i386 lib32stdc++6 lib32z1

# For Qemu compiling: need to compile the new targets like aarch64
# http://wiki.qemu.org/Hosts/Linux
RUN apt-get install -y pkg-config libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev libgtk-3-dev

RUN apt-get install -y gcc-powerpc-linux-gnu gcc-powerpc64le-linux-gnu openbios-ppc

RUN apt-get install -y gcc-arm-linux-gnueabi gcc-aarch64-linux-gnu

# Install mips toolchain

RUN apt-get install -y emdebian-archive-keyring
ADD cross/libgmp3c2_4.3.2+dfsg-2ubuntu1_amd64.deb /
ADD cross/libmpc2_0.9-4_amd64.deb /
RUN dpkg -i /libgmp3c2_4.3.2+dfsg-2ubuntu1_amd64.deb
RUN dpkg -i /libmpc2_0.9-4_amd64.deb
RUN rm /libgmp3c2_4.3.2+dfsg-2ubuntu1_amd64.deb
RUN rm /libmpc2_0.9-4_amd64.deb
#RUN apt-get install -y --force-yes gcc-4.3-mipsel-linux-gnu
RUN apt-get install -y --force-yes gcc-4.7-mipsel-linux-gnu
RUN update-alternatives --install /usr/bin/mipsel-linux-gnu-gcc gcc /usr/bin/mipsel-linux-gnu-gcc-4.7 50

# NFS server
RUN apt-get install -y nfs-kernel-server
ADD rootfs/nfs-server-exports /etc/exports

# TFTP Server
RUN apt-get install -y tftpd-hpa tftp-hpa
ADD tftpd-hpa.cfg /etc/default/tftpd-hpa

# Uboot tools for mkimage
RUN apt-get install -y u-boot-tools

# Bison
RUN apt-get install -y bison

# Qemu user static
RUN apt-get install -y qemu-user qemu-user-static

# For Qemu 0.10
RUN apt-get install -y libsdl1.2-dev

# Allow ubuntu user use sudo without password
ADD sudoers.d/ubuntu /etc/sudoers.d/
RUN chmod 440 /etc/sudoers.d/ubuntu

# Add shortcuts on Desktop
ADD linux-lab.desktop /

# Tune the screen size
ADD supervisord.conf /etc/supervisor/conf.d/

ADD enable_net_bridge.sh /
ADD restart-net-servers.sh /
ADD startup.sh /
ADD entrypoint.sh /

WORKDIR /linux-lab/

EXPOSE 6080
EXPOSE 5900
EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
