ARCH    = powerpc
XARCH   = ppc
CPU    ?= generic
# Note: <2.6.37 kernel don't have __NR_socket implementation
LINUX  ?= 4.6
MEM    ?= 128M
NETDEV ?= pcnet
SERIAL ?= ttyS0
ORIIMG ?= vmlinux
ROOTDEV?= /dev/ram0
BIOS   ?= $(PREBUILT_BIOS)/$(XARCH)/$(MACH)/openbios-ppc
CCPRE  ?= powerpc-linux-gnu-
KIMAGE ?= $(PREBUILT_KERNEL)/$(XARCH)/$(MACH)/$(LINUX)/vmlinux
ROOTFS ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.cpio.gz
HROOTFS?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.ext2
