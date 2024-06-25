#!/bin/sh

# GPIO0: output, GPIO1: input
rc=0

echo fff02000.i2c > /sys/bus/platform/drivers/nuvoton-i2c/unbind >& /dev/null
sleep 1

gpioset 0 0=1
val=`gpioget 0 1`
if [ $val -ne 1 ]; then
        echo "FAIL: gpio1 should be 1"
        rc=1
fi
gpioset 0 0=0
val=`gpioget 0 1`
if [ $val -ne 0 ]; then
        echo "FAIL: gpio1 should be 0"
        rc=1
fi

echo fff02000.i2c > /sys/bus/platform/drivers/nuvoton-i2c/bind >& /dev/null

echo "PASS"
exit $rc

