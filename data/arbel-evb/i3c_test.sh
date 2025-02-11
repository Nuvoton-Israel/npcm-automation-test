#!/bin/sh
set -e
log_file="/tmp/log/i3c_test.log"

# attach OpenBIC to i3c bus#0

echo "fff11000.i3c" > /sys/bus/platform/drivers/silvaco-i3c-master/unbind
sleep 1
echo "fff11000.i3c" > /sys/bus/platform/drivers/silvaco-i3c-master/bind
sleep 1

echo "check I3C pid sysfs exist" > $log_file
pid=`cat /sys/bus/i3c/devices/0-63212345607/pid`

echo "check pid value is correct" >> $log_file
echo "pid=$pid" >> $log_file
test $pid == 63212345607

echo "PASS" >> $log_file
echo "PASS"
exit 0
