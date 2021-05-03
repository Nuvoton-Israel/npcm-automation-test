#!/bin/bash
#set -e

# HW set up 
: << END
PWM0 => TACH0, TACH8~11
PWM1 => TACH1, TACH12~15
PWM2 => TACH2
PWM3 => TACH3
PWM4 => TACH4
PWM5 => TACH5
PWM6 => TACH6
PWM7 => TACH7

J1901 : GPION0_PWM0_R => J714 :
TACH0_GPIO46, TACH8_GPIO62, TACH9_GPIO64, TACH10_GPIO65, TACH11_GPIO66

J1902 : GPION1_PWM1_R => J714 :
TACH1_GPIO48, TACH12_GPIO68, TACH13_GPIO70, TACH14_GPIO72, TACH14_GPIO72

J1903 : GPION2_PWM2_R => TACH2_GPIO50

J1904 : GPION3_PWM3_R => TACH3_GPIO52

J713:
PWM4_GPIO11 => TACH4_GPIO54
PWM5_GPIO16 => TACH5_GPIO56
PWM6_GPIO13 => TACH6_GPIO58
PWM7_GPIO18 => TACH7_GPIO60

END
devmem=/sbin/devmem

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
echo "3000 RPM test"
${devmem} 0xf0103004 w 0x00003333
${devmem} 0xf0104004 w 0x00003333

${devmem} 0xf0103000 w 0x00007777
${devmem} 0xf0104000 w 0x00007777
# sleep for make pwm signal and fan count ready
sleep 1
# here all fans reading should be 3054
# cat cat fan* to show
find . -name "fan*" -exec echo -en "{}\t" \; -exec cat {} \; |sort -V
sleep 1
# ./fan1_input    3054
# ./fan2_input    3054
# ./fan3_input    3054
# ./fan4_input    3054
# ./fan5_input    3054
# ./fan6_input    3054
# ./fan7_input    3054
# ./fan8_input    3054
# ./fan9_input    3054
# ./fan10_input   3054
# ./fan11_input   3054
# ./fan12_input   3054
# ./fan13_input   3054
# ./fan14_input   3054
# ./fan15_input   3054
# ./fan16_input   3054

# set PWM PPR ch 01 and 23 to 0xEE, RPM 1533
echo "1533 RPM test part1"
${devmem} 0xf0103000 w 0x0000eeee
sleep 1
find . -name "fan*" -exec echo -en "{}\t" \; -exec cat {} \; |sort -V
sleep 1
# ./fan1_input    1533
# ./fan2_input    1533
# ./fan3_input    1533
# ./fan4_input    1533
# ./fan5_input    3054
# ./fan6_input    3054
# ./fan7_input    3054
# ./fan8_input    3054
# ./fan9_input    1533
# ./fan10_input   1533
# ./fan11_input   1533
# ./fan12_input   1533
# ./fan13_input   1533
# ./fan14_input   1533
# ./fan15_input   1533
# ./fan16_input   1533

echo "1533 RPM test part2 and 3067 RPM"
$devmem 0xf0104000 w 0x0000eeee
$devmem 0xf0103004 w 0x00002222
sleep 1
find . -name "fan*" -exec echo -en "{}\t" \; -exec cat {} \; |sort -V
sleep 1
# ./fan1_input    3067
# ./fan2_input    3067
# ./fan3_input    3067
# ./fan4_input    3067
# ./fan5_input    1533
# ./fan6_input    1533
# ./fan7_input    1533
# ./fan8_input    1533
# ./fan9_input    3067
# ./fan10_input   3067
# ./fan11_input   3067
# ./fan12_input   3067
# ./fan13_input   3067
# ./fan14_input   3067
# ./fan15_input   3067
# ./fan16_input   3067
