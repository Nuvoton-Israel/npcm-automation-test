#!/bin/sh
set -e
log_file="/tmp/log/pspi_test.log"

find_mtd_dev() {
	# support both legacy and newer DTS naming conventions
	awk -F'[:"]' '$2 == "spi1_spare0" || $2 == "spi1-spare0" {print $1; exit}' /proc/mtd
}

mtd_dev="$(find_mtd_dev)"
if [ -z "$mtd_dev" ]; then
	echo "Cannot find PSPI target partition in /proc/mtd" > "$log_file"
	cat /proc/mtd >> "$log_file"
	echo "FAIL: cannot find PSPI target partition"
	exit 1
fi

devpath="/dev/${mtd_dev}"
echo "pspi=$devpath"

PSPI_TEST_READY=/tmp/pspi_stress_test_ready
if [ ! -f "$PSPI_TEST_READY" ]
then
	echo "write test image to SPI flash" > $log_file
	dd if=/dev/random of=/tmp/pspi_test.img bs=1K count=1 >> $log_file 2>&1
	/usr/sbin/flashcp /tmp/pspi_test.img $devpath
	touch $PSPI_TEST_READY
else
	echo "SPI flash is ready for test" > $log_file
fi

echo "read SPI flash" >> $log_file
dd if=$devpath of=/tmp/pspi_test_out.img bs=1K count=1 >> $log_file 2>&1
diff /tmp/pspi_test.img /tmp/pspi_test_out.img >> $log_file
rm /tmp/pspi_test_out.img

echo "PASS" >> $log_file
echo "PASS"
exit 0
