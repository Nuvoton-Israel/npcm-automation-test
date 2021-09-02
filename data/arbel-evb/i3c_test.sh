#!/bin/sh
set -e

echo "check I3C pid sysfs exist"
pid=`cat /sys/bus/i3c/devices/1-208006c100b/pid`

echo "check pid value is correct"
echo "pid=$pid"
test $pid == 208006c100b

echo "PASS"
exit 0
