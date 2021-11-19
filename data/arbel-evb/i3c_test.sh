#!/bin/sh
set -e

# attach LSM6DSO to i3c bus#1

echo "fff11000.i3c" > /sys/bus/platform/drivers/silvaco-i3c-master/unbind
sleep 1
echo "fff11000.i3c" > /sys/bus/platform/drivers/silvaco-i3c-master/bind
sleep 1

echo "check I3C pid sysfs exist"
pid=`cat /sys/bus/i3c/devices/1-208006c100b/pid`

echo "check pid value is correct"
echo "pid=$pid"
test $pid == 208006c100b

echo "PASS"
exit 0
