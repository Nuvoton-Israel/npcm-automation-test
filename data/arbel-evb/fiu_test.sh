#!/bin/sh
set -e

find_mtd_dev() {
	# support both legacy and newer DTS naming conventions
	awk -F'[:"]' -v pat="$1" '$0 ~ pat {print $1; exit}' /proc/mtd
}

mtd_dev="$(find_mtd_dev 'spi3[_-]system')"
if [ -z "$mtd_dev" ]; then
	echo "Cannot find spi3-system partition in /proc/mtd"
	exit 1
fi

devpath="/dev/${mtd_dev}"
echo "spi3=$devpath"
dd if=/dev/random of=/tmp/tmp.img bs=1K count=1 >& /dev/null
/usr/sbin/flashcp /tmp/tmp.img $devpath

mtd_dev="$(find_mtd_dev 'spi1[_-]system')"
if [ -z "$mtd_dev" ]; then
	echo "Cannot find spi1-system partition in /proc/mtd"
	exit 1
fi

devpath="/dev/${mtd_dev}"
echo "spi1=$devpath"
# spi1 flash store u-boot ENV, save and resotre it later
dd if=$devpath of=/tmp/spi1.img bs=1M count=4 >& /dev/null
/usr/sbin/flashcp /tmp/tmp.img $devpath
# resotre u-boot ENV
/usr/sbin/flashcp /tmp/spi1.img $devpath


echo "PASS"
exit 0
