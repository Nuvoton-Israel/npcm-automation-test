#!/bin/sh

fail=0
devmem=/sbin/devmem
set +e

rs=`systemctl --type=service | grep phosphor-pid-control`
if [ -n "${rs}" ];then
	# stop PID server
	systemctl stop phosphor-pid-control.service
fi

set -e

cd /sys/class/hwmon/hwmon4
# set duty to 50 %
echo 125 > pwm1
echo 125 > pwm2
echo 125 > pwm3
echo 125 > pwm4
echo 125 > pwm5
echo 125 > pwm6
echo 125 > pwm7
echo 125 > pwm8

# set clock to about 100HZ

${devmem} 0xf0103004 w 0x00003333
${devmem} 0xf0104004 w 0x00003333
${devmem} 0xf0103000 w 0x00007777
${devmem} 0xf0104000 w 0x00007777

sleep 1
pwm_num=`echo {1..16}`

for PWM in $pwm_num;
do
	pwm_val=`cat fan${PWM}_input`
	if [ $pwm_val != 3054 ]
	then
		echo "fan${PWM}_input != 3054"
		fail=1
	fi
done

if [ $fail == 1 ]
then
	echo "pwm_test_failed"
else
	echo "pwm_test_pass"
fi

