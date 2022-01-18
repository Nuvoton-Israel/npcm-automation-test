#!/bin/sh

modprobe=/sbin/modprobe
echo 8 > /proc/sys/kernel/printk

for ((mode=403;mode<=406;mode++))
do
    if [ $mode == 403 ];then
       log_file="/tmp/log/sha1_test.log"
    elif [ $mode == 404 ];then
       log_file="/tmp/log/sha256_test.log"
    elif [ $mode == 405 ];then
       log_file="/tmp/log/sha384_test.log"
    elif [ $mode == 406 ];then
       log_file="/tmp/log/sha512_test.log"
    fi

    dmesg -c > /dev/null
    ${modprobe} tcrypt mode=$mode sec=1 dyndbg 2>&1
    dmesg -c | grep "tcrypt: all tests passed"

    if [ $? == 0 ];then
       echo PASS  >> $log_file
    else
       echo FAIL  >> $log_file
       echo 7 > /proc/sys/kernel/printk
       exit 1
    fi
done

echo 7 > /proc/sys/kernel/printk
exit 0

