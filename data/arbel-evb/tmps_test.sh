#!/bin/sh
set -e

# check the TMPS sysfs exist and show right value
echo "check TMPS sysfs exist"
t1=`cat /sys/class/thermal/thermal_zone0/temp`
t2=`cat /sys/class/thermal/thermal_zone1/temp`

echo "check TMPS value is correct"
# less than 100'C, larger than 10'C
test $t1 -lt 100000 -a $t1 -gt 10000
temp=`echo $t1 | awk '{print $1 / 1000}'`
echo "T1: $temp"
test $t2 -lt 100000 -a $t2 -gt 10000
temp=`echo $t2 | awk '{print $1 / 1000}'`
echo "T2: $temp"

echo "PASS"
exit 0