ARCH     = x86
XARCH    = i386
CPU     ?= i686
MEM     ?= 128M
#QEMU    ?= 0.10
LINUX   ?= 4.6
NETDEV  ?= ne2k_pci
SERIAL  ?= ttyS0
ORIIMG  ?= arch/$(ARCH)/boot/bzImage
ROOTDEV ?= /dev/ram0
#CCPRE   = i686-pc-linux-gnu-
KIMAGE  ?= $(PREBUILT_KERNEL)/$(XARCH)/$(MACH)/$(LINUX)/bzImage
ROOTFS  ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.cpio.gz
HROOTFS ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.ext2
# Fixup: MP-BIOS bug: 8254 timer not connected to IO-APIC
EXT_CMDLINE ?= noapic
