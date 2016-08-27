#
# Core Makefile
#

TOP_DIR = $(CURDIR)

CONFIG = $(shell cat $(TOP_DIR)/.config 2>/dev/null)

ifeq ($(CONFIG),)
  MACH = versatilepb
else
  MACH = $(CONFIG)
endif

MACH_DIR = $(TOP_DIR)/machine/$(MACH)/
TFTPBOOT = $(TOP_DIR)/tftpboot/

PREBUILT_DIR = $(TOP_DIR)/prebuilt/
PREBUILT_TOOLCHAINS = $(PREBUILT_DIR)/toolchains/
PREBUILT_ROOT = $(PREBUILT_DIR)/root/
PREBUILT_KERNEL = $(PREBUILT_DIR)/kernel/
PREBUILT_BIOS = $(PREBUILT_DIR)/bios/
PREBUILT_UBOOT = $(PREBUILT_DIR)/uboot/

ifneq ($(MACH),)
  include $(MACH_DIR)/Makefile
endif

QEMU_GIT ?= https://github.com/qemu/qemu.git
QEMU_SRC ?= $(TOP_DIR)/qemu/

BOOTLOADER_GIT ?= https://github.com/u-boot/u-boot.git
BOOTLOADER_SRC ?= $(TOP_DIR)/u-boot/

KERNEL_GIT ?= git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_SRC ?= $(TOP_DIR)/linux-stable/

# Use faster mirror instead of git://git.buildroot.net/buildroot.git
BUILDROOT_GIT ?= https://github.com/buildroot/buildroot
BUILDROOT_SRC ?= $(TOP_DIR)/buildroot/

QEMU_OUTPUT = $(TOP_DIR)/output/$(XARCH)/qemu/
BOOTLOADER_OUTPUT = $(TOP_DIR)/output/$(XARCH)/uboot-$(UBOOT)-$(MACH)/
KERNEL_OUTPUT = $(TOP_DIR)/output/$(XARCH)/linux-$(LINUX)-$(MACH)/
BUILDROOT_OUTPUT = $(TOP_DIR)/output/$(XARCH)/buildroot-$(CPU)/

CCPATH ?= $(BUILDROOT_OUTPUT)/host/usr/bin/
TOOLCHAIN = $(PREBUILT_TOOLCHAINS)/$(XARCH)

HOST_CPU_THREADS = $(shell grep processor /proc/cpuinfo | wc -l)

MISC = $(TOP_DIR)/misc/

ifneq ($(BIOS),)
  BIOS_ARG = -bios $(BIOS)
endif

EMULATOR = qemu-system-$(XARCH) $(BIOS_ARG)

# prefer new binaries to the prebuilt ones
# PBK = prebuilt kernel; PBR = prebuilt rootfs; PBD= prebuilt dtb

# TODO: kernel defconfig for $ARCH with $LINUX
LINUX_DTB    = $(KERNEL_OUTPUT)/$(ORIDTB)
LINUX_KIMAGE = $(KERNEL_OUTPUT)/$(ORIIMG)
LINUX_UKIMAGE = $(KERNEL_OUTPUT)/$(UORIIMG)
ifeq ($(LINUX_KIMAGE),$(wildcard $(LINUX_KIMAGE)))
  PBK ?= 0
else
  PBK = 1
endif
ifeq ($(LINUX_DTB),$(wildcard $(LINUX_DTB)))
  PBD ?= 0
else
  PBD = 1
endif

KIMAGE ?= $(LINUX_KIMAGE)
UKIMAGE ?= $(LINUX_UKIMAGE)
DTB     ?= $(LINUX_DTB)
ifeq ($(PBK),0)
  KIMAGE = $(LINUX_KIMAGE)
  UKIMAGE = $(LINUX_UKIMAGE)
endif
ifeq ($(PBD),0)
  DTB = $(LINUX_DTB)
endif

# Uboot image
UBOOT_BIMAGE = $(BOOTLOADER_OUTPUT)/u-boot
ifeq ($(UBOOT_BIMAGE),$(wildcard $(UBOOT_BIMAGE)))
  PBU ?= 0
else
  PBU = 1
endif

ifeq ($(UBOOT_BIMAGE),$(wildcard $(UBOOT_BIMAGE)))
  U ?= 1
else
  ifeq ($(PREBUILT_UBOOTDIR)/u-boot,$(wildcard $(PREBUILT_UBOOTDIR)/u-boot))
    U ?= 1
  else
    U = 0
  endif
endif

BIMAGE ?= $(UBOOT_BIMAGE)
ifeq ($(PBU),0)
  BIMAGE = $(UBOOT_BIMAGE)
endif

ifneq ($(U),0)
  KIMAGE = $(BIMAGE)
endif

# TODO: buildroot defconfig for $ARCH

ROOTDEV ?= /dev/ram0
FSTYPE  ?= ext2
BUILDROOT_UROOTFS = $(BUILDROOT_OUTPUT)/images/rootfs.cpio.uboot
BUILDROOT_HROOTFS = $(BUILDROOT_OUTPUT)/images/rootfs.$(FSTYPE)
BUILDROOT_ROOTFS = $(BUILDROOT_OUTPUT)/images/rootfs.cpio.gz

PREBUILT_ROOTDIR = $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/
PREBUILT_KERNELDIR = $(PREBUILT_KERNEL)/$(XARCH)/$(MACH)/$(LINUX)/
PREBUILT_UBOOTDIR = $(PREBUILT_UBOOT)/$(XARCH)/$(MACH)/$(UBOOT)/

ifeq ($(BUILDROOT_ROOTFS),$(wildcard $(BUILDROOT_ROOTFS)))
  PBR ?= 0
else
  PBR = 1
endif

ifneq ($(ROOTFS),)
  PREBUILT_ROOTFS = $(PREBUILT_ROOTDIR)/rootfs.cpio.gz
  ROOTDIR = $(PREBUILT_ROOTDIR)/rootfs
else
  ROOTDIR = $(BUILDROOT_OUTPUT)/target/
  PREBUILT_ROOTFS = $(ROOTFS)
endif

ifeq ($(U),0)
  ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
    ROOTFS ?= $(BUILDROOT_ROOTFS)
  endif
else
  ROOTFS = $(UROOTFS)
endif

HD = 0
ifeq ($(findstring /dev/sda,$(ROOTDEV)),/dev/sda)
  HD = 1
endif
ifeq ($(findstring /dev/hda,$(ROOTDEV)),/dev/hda)
  HD = 1
endif
ifeq ($(findstring /dev/mmc,$(ROOTDEV)),/dev/mmc)
  HD = 1
endif

ifeq ($(PBR),0)
  ROOTDIR = $(BUILDROOT_OUTPUT)/target/
  ifeq ($(U),0)
    ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
      ROOTFS = $(BUILDROOT_ROOTFS)
    endif
  else
    ROOTFS = $(BUILDROOT_UROOTFS)
  endif

  ifeq ($(HD),1)
    HROOTFS = $(BUILDROOT_HROOTFS)
  endif
endif

# TODO: net driver for $BOARD
#NET = " -net nic,model=smc91c111,macaddr=DE:AD:BE:EF:3E:03 -net tap"
NET =  -net nic,model=$(NETDEV) -net tap

# Common
ROUTE = $(shell ifconfig br0 | grep "inet addr" | cut -d':' -f2 | cut -d' ' -f1)

SERIAL ?= ttyS0
CONSOLE?= tty0

CMDLINE = route=$(ROUTE) root=$(ROOTDEV) $(EXT_CMDLINE)
TMP = $(shell bash -c 'echo $$(($$RANDOM%230+11))')
IP = $(shell echo $(ROUTE)END | sed -e 's/\.\([0-9]*\)END/.$(TMP)/g')

ifeq ($(ROOTDEV),/dev/nfs)
  CMDLINE += nfsroot=$(ROUTE):$(ROOTDIR) ip=$(IP)
endif

CMDLINE_NG = $(CMDLINE) console=$(SERIAL)
CMDLINE_G = $(CMDLINE) console=$(CONSOLE)

# For debug
mach:
	@find machine/$(MACH) -name "Makefile" -printf "[ %p ]:\n" -exec cat -n {} \; \
		| sed -e "s%machine/\(.*\)/Makefile%\1%g" \
		| sed -e "s/[[:digit:]]\{2,\}\t/  /g;s/[[:digit:]]\{1,\}\t/ /g"
ifneq ($(MACH),)
	@echo $(MACH) > $(TOP_DIR)/.config
endif

list: mach-list

mach-list:
	make mach MACH=

# Please makesure docker, git are installed
# TODO: Use gitsubmodule instead, ref: http://tinylab.org/nodemcu-kickstart/
uboot-source:
	git submodule update --init u-boot

qemu-source:
	git submodule update --init qemu

kernel-source:
	git submodule update --init linux-stable

buildroot-source:
	git submodule update --init buildroot

source: qemu-source kernel-source buildroot-source

# Qemu

QCO ?= 1
emulator-checkout:
ifneq ($(QEMU),)
ifneq ($(QCO),0)
	cd $(QEMU_SRC) && git checkout -f stable-$(QEMU) && cd $(TOP_DIR)
endif
endif

QPD=$(TOP_DIR)/patch/qemu/$(QEMU)/
QP ?= 1
emulator-patch: emulator-checkout
ifneq ($(QEMU),)
ifneq ($(QP),0)
	-$(foreach p,$(shell ls $(QPD)),$(shell echo patch -r- -N -l -d $(QEMU_SRC) -p1 \< $(QPD)/$p\;))
endif
endif

emulator: emulator-patch
	mkdir -p $(QEMU_OUTPUT)
	cd $(QEMU_OUTPUT) && $(QEMU_SRC)/configure --target-list=$(XARCH)-softmmu --disable-kvm && cd $(TOP_DIR)
	make -C $(QEMU_OUTPUT) -j$(HOST_CPU_THREADS)

# Toolchains

toolchain:
	make -C $(TOOLCHAIN)

toolchain-clean:
	make -C $(TOOLCHAIN) clean

# Rootfs
# Configure Buildroot
root-defconfig: $(MACH_DIR)/buildroot_$(CPU)_defconfig
	mkdir -p $(BUILDROOT_OUTPUT)
	cp $(MACH_DIR)/buildroot_$(CPU)_defconfig $(BUILDROOT_SRC)/configs/
	make O=$(BUILDROOT_OUTPUT) -C $(BUILDROOT_SRC) buildroot_$(CPU)_defconfig

root-menuconfig:
	make O=$(BUILDROOT_OUTPUT) -C $(BUILDROOT_SRC) menuconfig

# Build Buildroot
root:
	make O=$(BUILDROOT_OUTPUT) -C $(BUILDROOT_SRC) -j$(HOST_CPU_THREADS)
	cp $(MISC)/if-pre-up.d/config_iface $(BUILDROOT_OUTPUT)/target/etc/network/if-pre-up.d/config_iface
	make O=$(BUILDROOT_OUTPUT) -C $(BUILDROOT_SRC)
ifeq ($(U),1)
ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
	make $(BUILDROOT_UROOTFS)
endif
endif

# Configure Kernel
KCO ?= 1
kernel-checkout:
ifneq ($(KCO),0)
	cd $(KERNEL_SRC) && git checkout -f linux-$(LINUX).y && cd $(TOP_DIR)
endif

kernel-defconfig: $(MACH_DIR)/linux_$(LINUX)_defconfig kernel-checkout
	mkdir -p $(KERNEL_OUTPUT)
	cp $(MACH_DIR)/linux_$(LINUX)_defconfig $(KERNEL_SRC)/arch/$(ARCH)/configs/
	make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) ARCH=$(ARCH) linux_$(LINUX)_defconfig

kernel-menuconfig:
	make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) ARCH=$(ARCH) menuconfig

# Build Kernel

KPD_MACH=$(TOP_DIR)/machine/$(MACH)/patch/linux/$(LINUX)/
KPD=$(TOP_DIR)/patch/linux/$(LINUX)/

KP ?= 1
kernel-patch:
ifneq ($(KP),0)
	# Kernel 2.6.x need include/linux/compiler-gcc5.h
	-$(foreach p,$(shell ls $(KPD_MACH)),$(shell echo patch -r- -N -l -d $(KERNEL_SRC) -p1 \< $(KPD_MACH)/$p\;))
	-$(foreach p,$(shell ls $(KPD)),$(shell echo patch -r- -N -l -d $(KERNEL_SRC) -p1 \< $(KPD)/$p\;))
endif

IMAGE = $(shell basename $(ORIIMG))

ifeq ($(U),1)
  IMAGE=uImage
endif

kernel: kernel-patch
	PATH=$(PATH):$(CCPATH) make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) ARCH=$(ARCH) CROSS_COMPILE=$(CCPRE) -j$(HOST_CPU_THREADS) $(IMAGE)

# Configure Uboot
BCO ?= 1
uboot-checkout:
ifneq ($(BCO),0)
	cd $(BOOTLOADER_SRC) && git checkout -f $(UBOOT) && cd $(TOP_DIR)
endif

UPD_MACH=$(TOP_DIR)/machine/$(MACH)/patch/uboot/$(UBOOT)/
UPD=$(TOP_DIR)/patch/uboot/$(UBOOT)/

UP ?= 1
uboot-patch:
ifneq ($(UP),0)
ifneq ($(UPATCH),)
	git checkout -- $(UPD_MACH)/$(UPATCH)
	sed -i "s/ROUTE_ADDR/$(ROUTE)/g" $(UPD_MACH)/$(UPATCH)
	sed -i "s/IP_ADDR/$(IP)/g" $(UPD_MACH)/$(UPATCH)
ifeq ($(ROOTDEV),/dev/nfs)
	sed -i "s%root=/dev/ram%root=/dev/nfs nfsroot=$(ROUTE):$(ROOTDIR) ip=$(IP)%g" $(UPD_MACH)/$(UPATCH)
	sed -i "s/tftpboot 0x00807fc0 rootfs.cpio.uboot;//g" $(UPD_MACH)/$(UPATCH)
	sed -i "s/bootm 0x7fc0 0x807fc0/bootm 0x7fc0/g" $(UPD_MACH)/$(UPATCH)
endif
ifeq ($(HD),1)
	sed -i "s%root=/dev/ram%root=$(ROOTDEV)%g" $(UPD_MACH)/$(UPATCH)
	sed -i "s/tftpboot 0x00807fc0 rootfs.cpio.uboot;//g" $(UPD_MACH)/$(UPATCH)
	sed -i "s/bootm 0x7fc0 0x807fc0/bootm 0x7fc0/g" $(UPD_MACH)/$(UPATCH)
endif
	cp -r $(UPD_MACH)/* $(UPD)/
endif
	-$(foreach p,$(shell ls $(UPD)),$(shell echo patch -r- -N -l -d $(BOOTLOADER_SRC) -p1 \< $(UPD)/$p\;))
	git checkout -- $(UPD_MACH)/$(UPATCH)
endif

uboot-defconfig: $(MACH_DIR)/uboot_$(UBOOT)_defconfig uboot-checkout uboot-patch
	mkdir -p $(BOOTLOADER_OUTPUT)
	cp $(MACH_DIR)/uboot_$(UBOOT)_defconfig $(BOOTLOADER_SRC)/configs/
	make O=$(BOOTLOADER_OUTPUT) -C $(BOOTLOADER_SRC) ARCH=$(ARCH) uboot_$(UBOOT)_defconfig

uboot-menuconfig:
	make O=$(BOOTLOADER_OUTPUT) -C $(BOOTLOADER_SRC) ARCH=$(ARCH) menuconfig

# Build Uboot
uboot:
	PATH=$(PATH):$(CCPATH) make O=$(BOOTLOADER_OUTPUT) -C $(BOOTLOADER_SRC) ARCH=$(ARCH) CROSS_COMPILE=$(CCPRE) -j$(HOST_CPU_THREADS)

# Config Kernel and Rootfs
config: root-defconfig kernel-defconfig

# Build Kernel and Rootfs
build: root kernel

# Save the built images
root-save:
	mkdir -p $(PREBUILT_ROOTDIR)/
	-cp $(BUILDROOT_ROOTFS) $(PREBUILT_ROOTDIR)/

kernel-save:
	mkdir -p $(PREBUILT_KERNELDIR)
	-cp $(LINUX_KIMAGE) $(PREBUILT_KERNELDIR)
	-cp $(LINUX_UKIMAGE) $(PREBUILT_KERNELDIR)
ifeq ($(LINUX_DTB),$(wildcard $(LINUX_DTB)))
	-cp $(LINUX_DTB) $(PREBUILT_KERNELDIR)
endif

uboot-save:
	mkdir -p $(PREBUILT_UBOOTDIR)
	-cp $(UBOOT_BIMAGE) $(PREBUILT_UBOOTDIR)

uconfig-save:
	-cp $(BOOTLOADER_OUTPUT)/.config $(MACH_DIR)/uboot_$(UBOOT)_defconfig

# kernel < 2.6.36 doesn't support: `make savedefconfig`
kconfig-save:
	-PATH=$(PATH):$(CCPATH) make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) ARCH=$(ARCH) savedefconfig
ifeq ($(KERNEL_OUTPUT)/defconfig,$(wildcard $(KERNEL_OUTPUT)/defconfig))
	-cp $(KERNEL_OUTPUT)/defconfig $(MACH_DIR)/linux_$(LINUX)_defconfig
else
	-cp $(KERNEL_OUTPUT)/.config $(MACH_DIR)/linux_$(LINUX)_defconfig
endif

rconfig-save:
	make O=$(BUILDROOT_OUTPUT) -C $(BUILDROOT_SRC) -j$(HOST_CPU_THREADS) savedefconfig
ifeq ($(BUILDROOT_OUTPUT)/defconfig,$(wildcard $(BUILDROOT_OUTPUT)/defconfig))
	-cp $(BUILDROOT_OUTPUT)/defconfig $(MACH_DIR)/buildroot_$(CPU)_defconfig
else
	-cp $(BUILDROOT_OUTPUT)/.config $(MACH_DIR)/buildroot_$(CPU)_defconfig
endif


save: root-save kernel-save rconfig-save kconfig-save

# Launch Qemu, prefer our own instead of the prebuilt one
BOOT_CMD = PATH=$(QEMU_OUTPUT)/$(ARCH)-softmmu/:$(PATH) $(EMULATOR) -M $(MACH) -m $(MEM) $(NET) -kernel $(KIMAGE)
ifeq ($(U),0)
  ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
    BOOT_CMD += -initrd $(ROOTFS)
  endif
endif
ifeq ($(findstring /dev/hda,$(ROOTDEV)),/dev/hda)
  BOOT_CMD += -hda $(HROOTFS)
endif
ifeq ($(findstring /dev/sda,$(ROOTDEV)),/dev/sda)
  BOOT_CMD += -hda $(HROOTFS)
endif
ifeq ($(findstring /dev/mmc,$(ROOTDEV)),/dev/mmc)
  BOOT_CMD += -sd $(HROOTFS)
endif
ifeq ($(DTB),$(wildcard $(DTB)))
  BOOT_CMD += -dtb $(DTB)
endif


rootdir:
ifeq ($(ROOTDIR),$(PREBUILT_ROOTDIR)/rootfs)
ifneq ($(PREBUILT_ROOTDIR)/rootfs,$(wildcard $(PREBUILT_ROOTDIR)/rootfs))
	mkdir -p $(ROOTDIR) && cd $(ROOTDIR)/ && gunzip -f ../rootfs.cpio.gz && cpio -idmv < ../rootfs.cpio
	git checkout -- $(PREBUILT_ROOTFS)
endif
endif

rootdir-clean:
ifeq ($(ROOTDIR),$(PREBUILT_ROOTDIR)/rootfs)
	-rm -rf $(ROOTDIR)
endif

ifeq ($(U),1)
$(ROOTFS):
ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
  ifeq ($(PBR),0)
	mkimage -A $(ARCH) -O linux -T ramdisk -C none -d $(BUILDROOT_ROOTFS) $@
  else
	mkimage -A $(ARCH) -O linux -T ramdisk -C none -d $(PREBUILT_ROOTFS) $@
  endif
endif

$(UKIMAGE):
	make kernel IMAGE=uImage

tftp: $(ROOTFS) $(UKIMAGE)
ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
	-cp $(ROOTFS) $(TFTPBOOT)
endif
	-cp $(UKIMAGE) $(TFTPBOOT)
else
tftp:
endif

decompress:
ifeq ($(HD),1)
ifneq ($(PBR),0)
ifneq ($(HROOTFS),$(wildcard $(HROOTFS)))
	tools/rootfs/mkfs.sh $(ROOTDIR) $(FSTYPE)
	git checkout -- ${PREBUILT_ROOTFS}
endif
endif
endif

boot-ng: rootdir tftp decompress
ifneq ($(U),0)
	$(BOOT_CMD) -nographic
else
	$(BOOT_CMD) -append "$(CMDLINE_NG)" -nographic
endif


boot: rootdir tftp decompress
ifneq ($(U),0)
	$(BOOT_CMD)
else
	$(BOOT_CMD) -append "$(CMDLINE_G)"
endif

# Allinone
all: config build boot

# Clean up

emulator-clean:
	make -C $(QEMU_OUTPUT) clean

root-clean:
	make O=$(BUILDROOT_OUTPUT) -C $(BUILDROOT_SRC) clean

uboot-clean:
	make O=$(BOOTLOADER_OUTPUT) -C $(BOOTLOADER_SRC) clean

kernel-clean:
	make O=$(KERNEL_OUTPUT) -C $(KERNEL_SRC) clean

clean: emulator-clean root-clean kernel-clean rootdir-clean uboot-clean

help:
	@cat $(TOP_DIR)/README.md
