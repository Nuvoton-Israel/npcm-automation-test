#!/bin/bash
#set -e

# HW set up
: << END
PWM0 => TACH0
PWM1 => TACH1
PWM2 => TACH2
PWM3 => TACH3
PWM4 => LED4
PWM5 => LED5
PWM6 => LED6
PWM7 => LED7

J_FAN0:
GPIO80/PWM0 => GPIO64/FANIN0

J_FAN1:
GPIO81/PWM1 => GPIO65/FANIN1

J_FAN2:
GPIO82/PWM2 => GPIO66/FANIN2

J_FAN3:
GPIO83/PWM3 => GPIO67/FANIN3

GPIO144/PWM4 => LED_PWM4
GPIO145/PWM5 => LED_PWM5
GPIO146/PWM6 => LED_PWM6
GPIO147/PWM7 => LED_PWM7

END
devmem=/sbin/devmem

# functions
compare_rpm(){
    # remove ./fan?_input
    res=`echo $@ | grep -Eo " [0-9]+"`
    i=0
    for rpm in $res;
    do
        if [ "${res_data[$i]}" != "$rpm" ];then
            echo $msg >&2  # echo current status to stderr for get more clear infomation
            echo "data is wrong:${rpm} != ${res_data[$i]}, at index ${i}" >&2
            err=$(( err + 1 ))
        fi
        i=$(( i + 1))
    done
    if [ "$err" != "0" ];then
        exit $err
    fi
}

# global vars
res1_data=(3054 3054 3054 3054)
res2_data=(1533 1533 1533 1533)
res3_data=(3067 3067 3067 3067)
err=0

# do not report error if stop pid service failed or cannot find it
set +e
# lazy part for some DUT (not real for test)
rs=`systemctl --type=service | grep phosphor-pid-control`
if [ -n "${rs}" ];then
    # stop PID server
    systemctl stop phosphor-pid-control.service
fi
set -e
# get int to pwm fan sysfs
# TODO: find the hwmon named npcm7xx_pwm_fan
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
msg="3000 RPM test for PWMM1"
echo $msg
${devmem} 0xf0103004 w 0x00003333
${devmem} 0xf0103000 w 0x00007777
# sleep for make pwm signal and fan count ready
sleep 1
# here all fans reading should be 3054
# cat cat fan* to show
fan_rpms=`find . -name "fan*" -exec echo -en "{}\t" \; -exec cat {} \; |sort -V`
res_data=( ${res1_data[@]} )
compare_rpm $fan_rpms
sleep 1
# ./fan1_input    3054
# ./fan2_input    3054
# ./fan3_input    3054
# ./fan4_input    3054

# set PWM PPR ch 01 and 23 to 0xEE, RPM 1533
msg="1533 RPM test for PWMM1"
echo $msg
${devmem} 0xf0103000 w 0x0000eeee
sleep 1
fan_rpms=`find . -name "fan*" -exec echo -en "{}\t" \; -exec cat {} \; |sort -V`
res_data=( ${res2_data[@]} )
compare_rpm $fan_rpms
sleep 1
# ./fan1_input    1533
# ./fan2_input    1533
# ./fan3_input    1533
# ./fan4_input    1533

msg="3067 RPM for PWMM1"
echo $msg
$devmem 0xf0103004 w 0x00002222
sleep 1
fan_rpms=`find . -name "fan*" -exec echo -en "{}\t" \; -exec cat {} \; |sort -V`
res_data=( ${res3_data[@]} )
compare_rpm $fan_rpms
sleep 1
# ./fan1_input    3067
# ./fan2_input    3067
# ./fan3_input    3067
# ./fan4_input    3067

# test LED_PWM
echo "LED PWM medium"
echo 125 > pwm5
echo 125 > pwm6
echo 125 > pwm7
echo 125 > pwm8
sleep 2
echo "LED PWM dark"
echo 0 > pwm5
echo 0 > pwm6
echo 0 > pwm7
echo 0 > pwm8
sleep 2
echo "LED PWM light"
echo 255 > pwm5
echo 255 > pwm6
echo 255 > pwm7
echo 255 > pwm8
sleep 2
echo 15 > pwm5
echo 15 > pwm6
echo 15 > pwm7
echo 15 > pwm8