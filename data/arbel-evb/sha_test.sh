#!/bin/sh

modprobe=/sbin/modprobe
# Set printk priority to maximum to catch all kernel messages
echo 8 > /proc/sys/kernel/printk

# Ensure the log directory exists
mkdir -p /tmp/log

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

    # Clear previous dmesg logs
    dmesg -c > /dev/null

    # Run the speed test.
    # Ignore modprobe exit code since Kernel 6.13+ returns -EAGAIN
    # (Resource temporarily unavailable) by design.
    ${modprobe} tcrypt mode=$mode sec=1 dyndbg > /dev/null 2>&1

    # Capture the kernel log output
    dmesg_output=$(dmesg -c)

    # Check for "tcrypt: testing speed" because "all tests passed" is no
    # longer printed in speed tests on newer kernels.
    echo "$dmesg_output" | grep -q "tcrypt: testing speed"

    if [ $? == 0 ];then
       echo "PASS" >> $log_file
       # Optional: Append the detailed benchmark results into the log file.
       echo "$dmesg_output" | grep "opers/sec" >> $log_file 2>&1
    else
       echo "FAIL"
       echo "FAIL" >> $log_file
       # Restore default printk priority before exiting on failure
       echo 7 > /proc/sys/kernel/printk
       exit 1
    fi
done

# Restore default printk priority on success
echo 7 > /proc/sys/kernel/printk
# Keep one stdout line for Robot's script-output check.
echo PASS
exit 0

