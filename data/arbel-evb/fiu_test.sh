#!/bin/sh
set -e

mtd_info=`cat /proc/mtd | grep spi3-system`
arr=(${mtd_info//:/ })
devpath="/dev/${arr[0]}"
echo "spi3=$devpath"
flashcp /tmp/tmp.img $devpath

mtd_info=`cat /proc/mtd | grep spi1-system`
arr=(${mtd_info//:/ })
devpath="/dev/${arr[0]}"
echo "spi1=$devpath"
# spi1 flash store u-boot ENV, save and resotre it later
dd if=$devpath of=/tmp/spi1.img bs=1M count=4
dd if=/dev/random of=/tmp/tmp.img bs=1K count=1
flashcp /tmp/tmp.img $devpath
# resotre u-boot ENV
flashcp /tmp/spi1.img $devpath


echo "PASS"
exit 0
