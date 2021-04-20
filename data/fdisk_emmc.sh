#!/bin/bash

# this script only used for partition and format eMMC

# var
PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin
temp_mount=/tmp/test
mmc_dev=mmcblk0
udc_test=${temp_mount}/udc
mmc_usb=/sys/kernel/config/usb_gadget/mmc-storage
mmc_service=usb_emmc_storage.service

# umount
rs=`mount | grep ${temp_mount} | awk '{print $3}'`
if [ -n "${rs}" ];then
    umount $rs
fi

# f0833000.udc
if [ -d "$mmc_usb" ];then
    reg=`cat ${mmc_usb}/UDC`
    echo > ${mmc_usb}/UDC
fi

# fdisk
fdisk /dev/${mmc_dev} <<EOF
n
p
1


w
EOF
sleep 1
mke2fs /dev/${mmc_dev}p1 -F

if [ ! -d "$temp_mount" ];then
    mkdir $temp_mount
fi

echo "start prepare udc folder for UDC test..."
mount -t ext4 /dev/${mmc_dev}p1 $temp_mount
mkdir -p ${udc_test}
chmod 777 ${udc_test}
sleep 1
umount $temp_mount


if [ -d "$mmc_usb" ];then
    echo $reg > ${mmc_usb}/UDC
fi

echo "format eMMC finished"
exit 0