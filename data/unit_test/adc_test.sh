#!/bin/sh

fail=0
pwd=`pwd`
cd /sys/devices/platform/ahb/ahb:apb/f000c000.adc/iio:device0/

if [ "$1" = "" ];then
        echo "please add the test threshold : 1->1% 2->2%"
        exit 0
fi

cp -rf /usr/bin/adc_set ~/adc_set

for test in voltage0 voltage1 voltage2 voltage3 voltage4 voltage5 voltage6 voltage7
do
channel="in_${test}_raw"
ADC_VAL_RAW=`( cat $channel )`
ADC_VAL_VOLT=$(((ADC_VAL_RAW * 2000) / 1024)) 

temp=`expr $1 + 100`
get_adc=`cat ${pwd}/adc_set | grep ${test} | awk {'print $2'}`
up_val=`expr $get_adc \* $temp / 100`
temp=`expr 100 - $1`
low_val=`expr $get_adc \* $temp / 100`

if [ $ADC_VAL_VOLT -gt $up_val ]
then
  fail=1
  echo "$channel : $ADC_VAL_VOLT is too high"
fi
if [ $ADC_VAL_VOLT -lt $low_val ]
then
  fail=1
  echo "$channel : $ADC_VAL_VOLT is too low"
fi
done


if [ $fail == 1 ]
then
  echo "adc_test_failed"
else
  echo "adc_test_pass"
fi

