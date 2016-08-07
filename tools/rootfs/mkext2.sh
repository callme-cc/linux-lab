#!/bin/bash

ROOTDIR=$1
ROOTFS_EXT2=${ROOTDIR}/../rootfs.ext2

if [ -f ${ROOTDIR}/../rootfs.cpio.gz ]; then
  ROOTFS_SIZE=`ls -s ${ROOTDIR}/../rootfs.cpio.gz | cut -d' ' -f1`
  ROOTFS_SIZE=$((${ROOTFS_SIZE} * 5))
else
  ROOTFS_SIZE=`ls -s ${ROOTDIR}/../rootfs.cpio | cut -d' ' -f1`
  ROOTFS_SIZE=$((${ROOTFS_SIZE} * 2))
fi

echo $ROOTFS_SIZE

dd if=/dev/zero of=${ROOTFS_EXT2} bs=1024 count=$ROOTFS_SIZE
yes | mkfs.ext2 ${ROOTFS_EXT2}

mkdir -p ${ROOTDIR}

sudo mount ${ROOTFS_EXT2} ${ROOTDIR}

pushd ${ROOTDIR}
[ -f ../rootfs.cpio.gz ] && gunzip -f ../rootfs.cpio.gz
sudo cpio --quiet -idmv < ../rootfs.cpio 2>&1 >/dev/null
sync
popd
git checkout -- ${ROOTDIR}/../rootfs.cpio.gz

sudo umount ${ROOTDIR}
