ARCH    = mips
XARCH   = mipsel
CPU    ?= mips32r2
LINUX  ?= 4.6
MEM    ?= 128M
NETDEV ?= pcnet
SERIAL ?= ttyS0
FSTYPE ?= ext2
ORIIMG ?= vmlinuz
ROOTDEV?= /dev/ram0
CCPRE  ?= mipsel-linux-gnu-
KIMAGE ?= $(PREBUILT_KERNEL)/$(XARCH)/$(MACH)/$(LINUX)/vmlinuz
CCPATH ?= $(PREBUILT_TOOLCHAINS)/$(XARCH)/cross-loongson-4.5.2/bin/
ROOTFS ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.cpio.gz
HROOTFS ?= $(PREBUILT_ROOT)/$(XARCH)/$(CPU)/rootfs.$(FSTYPE)
