#!/bin/bash

# this script only used for partition and format eMMC

# var
PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin
temp_mount=/tmp/test
mmc_dev=mmcblk0
# prefer p7 on newer images, fallback to p6 on older images, then p1
mmc_test_part=
if [ -b "/dev/${mmc_dev}p7" ]; then
    mmc_test_part=${mmc_dev}p7
elif [ -b "/dev/${mmc_dev}p6" ]; then
    mmc_test_part=${mmc_dev}p6
elif [ -b "/dev/${mmc_dev}p1" ]; then
    mmc_test_part=${mmc_dev}p1
fi

if [ -z "${mmc_test_part}" ]; then
    echo "Cannot find usable eMMC partition under /dev/${mmc_dev}p[1,6,7]"
    exit 1
fi

echo "Use eMMC test partition: /dev/${mmc_test_part}"
udc_test=${temp_mount}/udc
mmc_usb=/sys/kernel/config/usb_gadget/mmc-storage
mmc_service=usb_emmc_storage.service

# umount
rs=`mount | grep ${temp_mount} | awk '{print $3}'`
if [ -n "${rs}" ];then
    umount $rs
fi

# f0833000.udc, disable UDC
if [ -d "$mmc_usb" ];then
    reg=`cat ${mmc_usb}/UDC`
    echo > ${mmc_usb}/UDC
fi

# format test partition selected by image layout
mke2fs /dev/${mmc_test_part} -F
if [ "$?" != "0" ];then
    echo "mke2fs failed"
    exit 1
fi

if [ ! -d "$temp_mount" ];then
    mkdir $temp_mount
fi

echo "start prepare udc folder for UDC test..."
mount -t ext4 /dev/${mmc_test_part} $temp_mount
mkdir -p ${udc_test}
chmod 777 ${udc_test}
sleep 1
umount $temp_mount

# Enable UDC
if [ -d "$mmc_usb" ];then
    echo $reg > ${mmc_usb}/UDC
fi

echo "format eMMC finished"
exit 0