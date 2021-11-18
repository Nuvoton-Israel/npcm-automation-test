#!/bin/sh
set -e

mtd_info=`cat /proc/mtd | grep spi1_spare0`
arr=(${mtd_info//:/ })
devpath="/dev/${arr[0]}"
echo "pspi=$devpath"
dd if=/dev/random of=/tmp/tmp.img bs=1K count=1 >& /dev/null
/usr/sbin/flashcp /tmp/tmp.img $devpath

echo "PASS"
exit 0
