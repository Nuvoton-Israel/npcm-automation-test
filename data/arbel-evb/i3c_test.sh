#!/bin/sh
set -e
log_file="/tmp/log/i3c_test.log"

# attach LSM6DSO to i3c bus#1

echo "fff11000.i3c" > /sys/bus/platform/drivers/silvaco-i3c-master/unbind
sleep 1
echo "fff11000.i3c" > /sys/bus/platform/drivers/silvaco-i3c-master/bind
sleep 1

echo "check I3C pid sysfs exist" > $log_file
pid=`cat /sys/bus/i3c/devices/1-208006c100b/pid`

echo "check pid value is correct" >> $log_file
echo "pid=$pid" >> $log_file
test $pid == 208006c100b

echo "PASS" >> $log_file
echo "PASS"
exit 0
