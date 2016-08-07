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
PREBUILT_ROOTFS = $(PREBUILT_DIR)/rootfs/
PREBUILT_KERNEL = $(PREBUILT_DIR)/kernel/
PREBUILT_BIOS = $(PREBUILT_DIR)/bios/
PREBUILT_UBOOT = $(PREBUILT_DIR)/uboot/

include $(MACH_DIR)/Makefile

# Allow to disable prebuilt things
# PBK = prebuilt kernel; PBR = prebuilt rootfs
PBK ?= 1
PBR ?= 1
PBU ?= 1

QEMU_GIT ?= https://github.com/qemu/qemu.git
QEMU ?= $(TOP_DIR)/qemu/

BOOTLOADER_GIT ?= https://github.com/u-boot/u-boot.git
BOOTLOADER ?= $(TOP_DIR)/u-boot/

KERNEL_GIT ?= git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL ?= $(TOP_DIR)/linux-stable/

# Use faster mirror instead of git://git.buildroot.net/buildroot.git
BUILDROOT_GIT ?= https://github.com/buildroot/buildroot
BUILDROOT ?= $(TOP_DIR)/buildroot/

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

# Boot with u-boot?
ifneq ($(UBOOT),)
  U ?= 0
else
  U = 0
endif

# TODO: kernel defconfig for $ARCH with $LINUX
LINUX_KIMAGE = $(KERNEL_OUTPUT)/$(ORIIMG)
LINUX_UKIMAGE = $(KERNEL_OUTPUT)/$(UORIIMG)

KIMAGE ?= $(LINUX_KIMAGE)
UKIMAGE ?= $(LINUX_UKIMAGE)
ifeq ($(PBK),0)
  KIMAGE = $(LINUX_KIMAGE)
  UKIMAGE = $(LINUX_UKIMAGE)
endif

# Uboot image
UBOOT_BIMAGE = $(BOOTLOADER_OUTPUT)/u-boot
BIMAGE ?= $(UBOOT_BIMAGE)
ifeq ($(PBU),0)
  BIMAGE = $(UBOOT_BIMAGE)
endif

ifneq ($(U),0)
  KIMAGE = $(BIMAGE)
endif

# TODO: buildroot defconfig for $ARCH

ROOTDEV ?= /dev/ram0
HROOTFS_SUFFIX   ?= gz
BUILDROOT_UROOTFS = $(BUILDROOT_OUTPUT)/images/rootfs.cpio.uboot
BUILDROOT_HROOTFS = $(BUILDROOT_OUTPUT)/images/rootfs.ext2
BUILDROOT_ROOTFS = $(BUILDROOT_OUTPUT)/images/rootfs.cpio.gz
PREBUILT_ROOTDIR = $(PREBUILT_ROOTFS)/$(XARCH)/$(CPU)/rootfs/

ifneq ($(ROOTFS),)
  ROOTDIR = $(PREBUILT_ROOTDIR)
else
  ROOTDIR = $(BUILDROOT_OUTPUT)/target/
endif

ifeq ($(U),0)
  ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
    ROOTFS ?= $(BUILDROOT_ROOTFS)
  endif
else
  ROOTFS = $(UROOTFS)
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
endif

ifeq ($(findstring /dev/sda,$(ROOTDEV)),/dev/sda)
  ifeq ($(PBR),0)
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
env:
	@echo "[$(MACH)]:"
	@echo "   $(XARCH)"
	@echo "   $(CPU)"
	@echo "   $(NETDEV)"
	@echo "   $(SERIAL)"
	@echo "   $(LINUX)"
	@echo "   $(MEM)"
	@echo "   $(ROOTDEV)"
	@echo "   $(CCPRE)"
	@echo "   $(ROOTFS)"
	@echo "   $(CCPATH)"

mach-config:
	@echo $(MACH) > $(TOP_DIR)/.config
	@find machine/$(MACH) -name "Makefile" -printf "* [%p]\n" -exec cat -n {} \;

mach-list:
	@find machine/ -name "Makefile" -printf "* [%p]\n" -exec cat -n {} \;

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

emulator:
	mkdir -p $(QEMU_OUTPUT)
	cd $(QEMU_OUTPUT) && $(QEMU)/configure --target-list=$(XARCH)-softmmu && cd $(TOP_DIR)
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
	cp $(MACH_DIR)/buildroot_$(CPU)_defconfig $(BUILDROOT)/configs/
	make O=$(BUILDROOT_OUTPUT) -C $(BUILDROOT) buildroot_$(CPU)_defconfig

root-menuconfig:
	make O=$(BUILDROOT_OUTPUT) -C $(BUILDROOT) menuconfig

# Build Buildroot
root:
	make O=$(BUILDROOT_OUTPUT) -C $(BUILDROOT) -j$(HOST_CPU_THREADS)
	cp $(MISC)/if-pre-up.d/config_iface $(BUILDROOT_OUTPUT)/target/etc/network/if-pre-up.d/config_iface
	make O=$(BUILDROOT_OUTPUT) -C $(BUILDROOT)
ifeq ($(U),1)
ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
	make $(BUILDROOT_UROOTFS)
endif
endif

# Configure Kernel
KCO ?= 1
kernel-checkout:
ifneq ($(KCO),0)
	cd $(KERNEL) && git checkout -f linux-$(LINUX).y && cd $(TOP_DIR)
endif

kernel-defconfig: $(MACH_DIR)/linux_$(LINUX)_defconfig kernel-checkout
	mkdir -p $(KERNEL_OUTPUT)
	cp $(MACH_DIR)/linux_$(LINUX)_defconfig $(KERNEL)/arch/$(ARCH)/configs/
	make O=$(KERNEL_OUTPUT) -C $(KERNEL) ARCH=$(ARCH) linux_$(LINUX)_defconfig

kernel-menuconfig:
	make O=$(KERNEL_OUTPUT) -C $(KERNEL) ARCH=$(ARCH) menuconfig

# Build Kernel

KPD=$(TOP_DIR)/patch/linux/$(LINUX)/

KP ?= 1
kernel-patch:
ifneq ($(KP),0)
	# Kernel 2.6.x need include/linux/compiler-gcc5.h
ifeq ($(findstring 2.6.,$(LINUX)),2.6.)
	-$(foreach p,$(shell ls $(KPD)),$(shell echo patch -r- -N -l -d $(KERNEL) -p1 \< $(KPD)/$p\;))
endif
endif

ifeq ($(U),1)
  IMAGE=uImage
endif

kernel: kernel-patch
	PATH=$(PATH):$(CCPATH) make O=$(KERNEL_OUTPUT) -C $(KERNEL) ARCH=$(ARCH) CROSS_COMPILE=$(CCPRE) -j$(HOST_CPU_THREADS) $(IMAGE)

# Configure Uboot
BCO ?= 1
uboot-checkout:
ifneq ($(BCO),0)
	cd $(BOOTLOADER) && git checkout -f $(UBOOT) && cd $(TOP_DIR)
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
ifeq ($(findstring /dev/sda,$(ROOTDEV)),/dev/sda)
	sed -i "s%root=/dev/ram%root=$(ROOTDEV)%g" $(UPD_MACH)/$(UPATCH)
	sed -i "s/tftpboot 0x00807fc0 rootfs.cpio.uboot;//g" $(UPD_MACH)/$(UPATCH)
	sed -i "s/bootm 0x7fc0 0x807fc0/bootm 0x7fc0/g" $(UPD_MACH)/$(UPATCH)
endif
	cp -r $(UPD_MACH)/* $(UPD)/
endif
	-$(foreach p,$(shell ls $(UPD)),$(shell echo patch -r- -N -l -d $(BOOTLOADER) -p1 \< $(UPD)/$p\;))
	git checkout -- $(UPD_MACH)/$(UPATCH)
endif

uboot-defconfig: $(MACH_DIR)/uboot_$(UBOOT)_defconfig uboot-checkout uboot-patch
	mkdir -p $(BOOTLOADER_OUTPUT)
	cp $(MACH_DIR)/uboot_$(UBOOT)_defconfig $(BOOTLOADER)/configs/
	make O=$(BOOTLOADER_OUTPUT) -C $(BOOTLOADER) ARCH=$(ARCH) uboot_$(UBOOT)_defconfig

uboot-menuconfig:
	make O=$(BOOTLOADER_OUTPUT) -C $(BOOTLOADER) ARCH=$(ARCH) menuconfig

# Build Uboot
uboot:
	PATH=$(PATH):$(CCPATH) make O=$(BOOTLOADER_OUTPUT) -C $(BOOTLOADER) ARCH=$(ARCH) CROSS_COMPILE=$(CCPRE) -j$(HOST_CPU_THREADS)

# Config Kernel and Rootfs
config: root-defconfig kernel-defconfig

# Build Kernel and Rootfs
build: root kernel

# Save the built images
root-save:
	mkdir -p $(PREBUILT_ROOTFS)/$(XARCH)/$(CPU)/
	cp $(BUILDROOT_ROOTFS) $(PREBUILT_ROOTFS)/$(XARCH)/$(CPU)/
	-cp $(BUILDROOT_HROOTFS).$(HROOTFS_SUFFIX) $(PREBUILT_ROOTFS)/$(XARCH)/$(CPU)/
	-cp $(BUILDROOT_UROOTFS) $(PREBUILT_ROOTFS)/$(XARCH)/$(CPU)/

kernel-save:
	mkdir -p $(PREBUILT_KERNEL)/$(XARCH)/$(MACH)/$(LINUX)/
	cp $(LINUX_KIMAGE) $(PREBUILT_KERNEL)/$(XARCH)/$(MACH)/$(LINUX)/
	-cp $(LINUX_UKIMAGE) $(PREBUILT_KERNEL)/$(XARCH)/$(MACH)/$(LINUX)/

uboot-save:
	mkdir -p $(PREBUILT_UBOOT)/$(XARCH)/$(MACH)/$(UBOOT)/
	cp $(UBOOT_BIMAGE) $(PREBUILT_UBOOT)/$(XARCH)/$(MACH)/$(UBOOT)/

uconfig-save:
	cp $(BOOTLOADER_OUTPUT)/.config $(MACH_DIR)/uboot_$(UBOOT)_defconfig

kconfig-save:
	cp $(KERNEL_OUTPUT)/.config $(MACH_DIR)/linux_$(LINUX)_defconfig

rconfig-save:
	cp $(BUILDROOT_OUTPUT)/.config $(MACH_DIR)/buildroot_$(CPU)_defconfig


save: root-save kernel-save rconfig-save kconfig-save

# Launch Qemu, prefer our own instead of the prebuilt one
BOOT_CMD = PATH=$(QEMU_OUTPUT)/$(ARCH)-softmmu/:$(PATH) $(EMULATOR) -M $(MACH) -m $(MEM) $(NET) -kernel $(KIMAGE)
ifeq ($(U),0)
  ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
    BOOT_CMD += -initrd $(ROOTFS)
  endif
endif
ifeq ($(findstring /dev/sda,$(ROOTDEV)),/dev/sda)
  BOOT_CMD += -hda $(HROOTFS)
endif


rootdir:
ifeq ($(ROOTDIR),$(PREBUILT_ROOTDIR))
ifneq ($(PREBUILT_ROOTDIR),$(wildcard $(PREBUILT_ROOTDIR)))
	mkdir -p $(ROOTDIR) && cd $(ROOTDIR)/ && cp ../rootfs.cpio.gz ./ && gunzip -f rootfs.cpio.gz && cpio -idmv < rootfs.cpio
endif
endif

rootdir-clean:
ifeq ($(ROOTDIR),$(PREBUILT_ROOTDIR))
	-rm -rf $(ROOTDIR)
endif

ifeq ($(U),1)
$(BUILDROOT_UROOTFS): $(BUILDROOT_ROOTFS)
ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
	mkimage -A $(ARCH) -O linux -T ramdisk -C none -d $< $@
endif

$(UKIMAGE):
	make kernel IMAGE=uImage

tftp: $(BUILDROOT_UROOTFS) $(UKIMAGE)
ifeq ($(findstring /dev/ram,$(ROOTDEV)),/dev/ram)
	cp $(ROOTFS) $(TFTPBOOT)
endif
	cp $(UKIMAGE) $(TFTPBOOT)
else
tftp:
endif

decompress:
ifeq ($(findstring /dev/sda,$(ROOTDEV)),/dev/sda)
ifneq ($(PBR),0)
ifneq ($(HROOTFS),$(wildcard $(HROOTFS)))
	cd $(PREBUILT_ROOTFS)/$(XARCH)/$(CPU)/ && gunzip rootfs.ext2.$(HROOTFS_SUFFIX) && cd $(TOP_DIR)
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
	make O=$(BUILDROOT_OUTPUT) -C $(BUILDROOT) clean

uboot-clean:
	make O=$(BOOTLOADER_OUTPUT) -C $(BOOTLOADER) clean

kernel-clean:
	make O=$(KERNEL_OUTPUT) -C $(KERNEL) clean

clean: emulator-clean root-clean kernel-clean rootdir-clean uboot-clean

help:
	@cat $(TOP_DIR)/README.md
