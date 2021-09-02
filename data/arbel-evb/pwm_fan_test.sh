#!/bin/sh
set -e
systemctl stop phosphor-pid-control.service

echo "Set pwm to 0"
echo 0 > /sys/class/hwmon/hwmon1/pwm1
sleep 5
fanin=`cat /sys/class/hwmon/hwmon1/fan1_input`
echo "Fanin: $fanin"
test $fanin -lt 1100 -a $fanin -gt 900

echo "Set pwm to 125"
echo 125 > /sys/class/hwmon/hwmon1/pwm1
sleep 5
fanin=`cat /sys/class/hwmon/hwmon1/fan1_input`
echo "Fanin: $fanin"
test $fanin -lt 1450 -a $fanin -gt 1250

echo "Set pwm to 255"
echo 255 > /sys/class/hwmon/hwmon1/pwm1
sleep 5
fanin=`cat /sys/class/hwmon/hwmon1/fan1_input`
echo "Fanin: $fanin"
test $fanin -lt 2000 -a $fanin -gt 1800

systemctl start phosphor-pid-control.service

echo "PASS"
exit 0
