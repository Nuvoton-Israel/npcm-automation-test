#!/bin/bash
set -e

# HW set up 
: << END
J712:
GPIO5_SGPMCK => GPIO0_SGPMLD
GPIO3_SGPMO => GPIO1_SGPMI

END

#test gpio
# seven segment
sgpio="90 24 88 137 11 141 87 25 138 231 139 140 9 89 143 142"
# IOEXP blue LED
bgpio=`echo {488..495}`
# iox
xgpio="4 5 6 7"
SYS_GPIO="/sys/class/gpio"

# set GPIOs value
# $1    :value
# $2..n :GPIOs
set_gpio() {
val=$1
shift
for gpio in $@;
do
  echo $val > ${SYS_GPIO}/gpio${gpio}/value
done
}

set_dir() {
dir=$1
shift
for gpio in $@;
do
  echo $dir > ${SYS_GPIO}/gpio${gpio}/direction
done
}

# export gpio and set direction out
export_gpio() {
for gpio in $@;
do
  if [ ! -d "${SYS_GPIO}/gpio${gpio}" ];then
    echo "$gpio" > ${SYS_GPIO}/export
  fi
  echo out > ${SYS_GPIO}/gpio${gpio}/direction
done
}

unexport_gpio() {
for gpio in $@;
do
  echo "$gpio" > ${SYS_GPIO}/unexport
done
}

check_gpio() {
val=$1
shift
for gpio in $@;
do
  res=`cat ${SYS_GPIO}/gpio${gpio}/value`
  if [ "$val" != "$res" ];then
    echo "check gpio$gpio fail, value: $val"
    exit 1
  fi
done
}

# Main function

# normal GPIO short test
export_gpio $xgpio
set_dir "in" 5 7
set_gpio 1 4 6
check_gpio 1 5 7
set_gpio 0 4 6
check_gpio 0 5 7
echo "xgpio test done"
unexport_gpio $xgpio


# export GPIO before use it
echo "sgpio test start"
export_gpio $sgpio $bgpio

# test seven segment GPIO first
set_gpio 1 $sgpio
sleep 1
set_gpio 0 $sgpio
sleep 1
set_gpio 1 $sgpio
sleep 1
set_gpio 0 $sgpio
sleep 1
# test blue LED in expend GPIO
echo "bgpio test start"
set_gpio 0 $bgpio
sleep 1
set_gpio 1 $bgpio
sleep 1
set_gpio 0 $bgpio
sleep 1
set_gpio 1 $bgpio
sleep 1

unexport_gpio $sgpio $bgpio
echo "sgpio and bgpio test done"

