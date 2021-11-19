#!/bin/sh

# GPIO0: output, GPIO1: input
rc=0

echo fff02000.i2c > /sys/bus/platform/drivers/nuvoton-i2c/unbind >& /dev/null
sleep 1

echo 0 > /sys/class/gpio/export 2>/dev/null
echo 1 > /sys/class/gpio/export 2>/dev/null

set -e
echo out > /sys/class/gpio/gpio0/direction
echo in  > /sys/class/gpio/gpio1/direction

echo 1 > /sys/class/gpio/gpio0/value
val=`cat /sys/class/gpio/gpio1/value`
if [ $val -ne 1 ]; then
        echo "FAIL: gpio1 should be 1"
        rc=1
fi
echo 0 > /sys/class/gpio/gpio0/value
val=`cat /sys/class/gpio/gpio1/value`
if [ $val -ne 0 ]; then
        echo "FAIL: gpio1 should be 0"
        rc=1
fi

echo 0 > /sys/class/gpio/unexport
echo 1 > /sys/class/gpio/unexport
echo fff02000.i2c > /sys/bus/platform/drivers/nuvoton-i2c/bind >& /dev/null

echo "PASS"
exit $rc

