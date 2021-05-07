#!/bin/sh

val=$1
spi_flash=4
emmc_path=/dev/mmcblk0
usb_path=/dev/sda

# detect spi flash to check spi bus is work fine 
#if you don't want to detect J1702 flash please modify spi_flash=3
test_spi()
{
	test_num=0
	for spi in spi2.0 spi2.1 spi4.0 spi3.0
	do
		dmesg | grep "${spi}:" > /dev/null
		if [ $? == 0 ]
		then
			test_num=$(($test_num+1))
		fi
	done
	if [ $test_num ==  $spi_flash ]
	then
		echo "spi_test_pass"
	else
		echo "spi_test_failed"
	fi
}

# emmc read/write test
test_emmc()
{
	if [ -f "/tmp/ext.img" ]
	then
		echo ""
	else
		dd if=/dev/zero of=/tmp/ext.img bs=1M count=10
		mkfs.ext4 /tmp/ext.img
	fi
	
	dd if=/tmp/ext.img of=$emmc_path
	mkdir -p ~/emmc
	mount $emmc_path ~/emmc
	echo "emmc_test" > ~/emmc/log
	emmc_read=`cat ~/emmc/log`
	
	if [ $emmc_read = "emmc_test" ]
	then
		echo "emmc_test_pass"
	else
		echo "emmc_test_failed"
	fi
	umount ~/emmc
}

#usb host/device test
test_usb()
{
	if [ -f "/tmp/ext.img" ]
	then
		echo ""
	else
		dd if=/dev/zero of=/tmp/ext.img bs=1M count=10
		mkfs.ext4 /tmp/ext.img
	fi
	
	dd if=/tmp/ext.img of=$usb_path
	mkdir -p ~/usb
	mount $usb_path ~/usb
	echo "usb_test" > ~/usb/log
	usb_read=`cat ~/usb/log`
	
	if [ $usb_read = "usb_test" ]
	then
		echo "usb_test_pass"
	else
		echo "usb_test_failed"
	fi
	umount ~/usb
}

test_option()
{
case "$val" in
   1)
      test_spi $@
      ;;
   2)
      test_emmc $@
      ;;
   3)
      test_usb $@
      ;;
   4)
      test_spi $@
      test_emmc $@
      test_usb $@
      ;;
   *)
      echo "useage"
      echo "storage_test.sh 1 -> test spi flash"
      echo "storage_test.sh 2 -> test mmc"
      echo "storage_test.sh 3 -> test usb"
      echo "storage_test.sh 4 -> test all"
      ;;

esac
}

test_option $@

