ARCH=x86
XARCH=i386
CPU?=i686
MEM?=128M
LINUX?=2.6.35
NETDEV?=ne2k_pci
SERIAL=ttyS0
ORIIMG=arch/$(ARCH)/boot/bzImage
ROOTDEV?=/dev/ram0
#CCPRE=i686-pc-linux-gnu-
KIMAGE?=$(PREBUILT_KERNEL)/$(XARCH)/$(MACH)/$(LINUX)/bzImage
ROOTFS?=$(PREBUILT_ROOTFS)/$(XARCH)/$(CPU)/rootfs.cpio.gz
# Fixup: MP-BIOS bug: 8254 timer not connected to IO-APIC
EXT_CMDLINE?=noapic
