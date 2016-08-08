
# Linux Lab

This project aims to make a Qemu-based Linux development Lab to easier the
learning and development of the [Linux Kernel](http://www.kernel.org).

For Linux 0.11, please try our [Linux 0.11 Lab](http://github.com/tinyclub/linux-0.11-lab).

![Docker Qemu Linux Lab](doc/docker-qemu-linux-lab.jpg)

## Homepage

    See: <http://tinylab.org/linux-lab/>

## Download the lab

    $ git clone https://github.com/tinyclub/linux-lab.git
    $ cd /linux-lab/

## Build the Lab

    $ sudo tools/install-docker-lab.sh
    $ tools/run-docker-lab-daemon.sh
    $ tools/open-docker-lab.sh

## Quickstart

Login in `http://localhost:6080/vnc.html` with 'ubuntu' password, and then open a terminal:

    $ sudo -s
    $ cd /linux-lab
    $ make boot

## Usage

Check supported machines:

    $ make mach-list

Check the machine specifci configuration:

    $ make mach-list | grep Makefile
    * [machine/pc/Makefile]
    * [machine/versatilepb/Makefile]
    * [machine/g3beige/Makefile]
    * [machine/malta/Makefile]
    $ cat machine/versatilepb/Makefile
    ARCH=arm
    XARCH=$(ARCH)
    CPU=arm926t
    MEM=128M
    LINUX=2.6.35
    NETDEV=smc91c111
    SERIAL=ttyAMA0
    ROOTDEV=/dev/nfs
    ORIIMG=arch/$(ARCH)/boot/zImage
    CCPRE=arm-linux-gnueabi-
    KIMAGE=$(PREBUILT_KERNEL)/$(XARCH)/$(MACH)/$(LINUX)/zImage
    ROOTFS=$(PREBUILT_ROOTFS)/$(XARCH)/$(CPU)/rootfs.cpio.gz

Disable prebuilt kernel and rootfs via comment the `KIMAGE` and `ROOTFS`:

    $ vim machine/versatilepb/Makefile
    #KIMAGE=$(PREBUILT_KERNEL)/$(XARCH)/$(MACH)/$(LINUX)/zImage
    #ROOTFS=$(PREBUILT_ROOTFS)/$(XARCH)/$(CPU)/rootfs.cpio.gz

Download the sources:

    $ make source -j3     # All in one

    $ make kernel-source  # One by one
    $ make buildroot-source

Configure the sources:

    $ make config           # Configure all with defconfig

    $ make kernel-defconfig # Configure one by one
    $ make root-defconfig

    $ make kernel-defconfig KCO=0 # Disable checkout action

Manually configure the sources:

    $ make kernel-menuconfig
    $ make root-menuconfig

Build them:

    $ make build   # All in one

    $ make kernel  # One by one
    $ make root

    $ make kernel KP=0  # Disable kernel patch action

Boot it:

    $ make boot-ng  # Boot with serial port (no graphic), exit with 'pkill qemu'

    $ make boot     # Boot with graphic

    $ make boot PBK=0 PBR=0  # Disable prebuilt kernel and rootfs

    $ make boot U=1  # Boot with Uboot

Boot with NFS-rootfs or RamFs:

    $ make boot ROOTDEV=/dev/nfs
    $ make boot ROOTDEV=/dev/ram

Save your changes:

    $ make save         # Save all of the configs and rootfs/kernel images

    $ make kconfig-save # Save configs to machine/BOARD/, kernel config
    $ make rconfig-save # rootfs config

    $ make root-save    # Save images to prebuilt/
    $ make kernel-save

If NFS boot fails, please make sure `IP_PNP` and `ROOT_NFS` are configured in
kernel and if issue still exists, then try to fix up it:

    $ tools/restart-net-servers.sh

By default, the default machine: 'versatilepb' is used, we can configure, build
and boot for a specific machine with 'MACH', for example:

    $ make MACH=malta
    $ make root-defconfig
    $ make root
    $ make kernel-defconfig
    $ make kernel
    $ make boot


## More

Buildroot has provided many examples about buildroot and kernel configuration:

* buildroot: `configs/qemu_ARCH_BOARD_defconfig`
* kernel: `board/qemu/ARCH-BOARD/linux-VERSION.config`

To start a new ARCH, BOARD and linux VERSION test, please based on it.

Note, different qemu version uses different kernel VERSION, so, to find the
suitable kernel version, we can checkout different git tags.
