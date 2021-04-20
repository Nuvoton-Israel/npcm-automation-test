#!/bin/bash

if [ -z "$1" ] ; then
    echo "usage:  sh adc_test.sh <ch>"
	exit 1
fi

#initialize  variables
channel="in_voltage$1_raw"
count=-1
fail=0
BASEDIR=$(dirname "$0")
run_start_time=$(date +%s);
seconds_passed=0
results_log_file="$BASEDIR/log/adc_stress.stat"
result_log=PASS

echo "Statefile: $results_log_file"

cd /sys/devices/platform/ahb/ahb:apb/f000c000.adc/iio:device0/

dump_info(){
	echo " number of tests run $count , failed $fail" > $results_log_file
	#echo dbg: number_of_tests_run=$count

	minutes_passed="$(($seconds_passed / 60))"
	hours_passed="$(($minutes_passed / 60))"
	log_timestamp="$hours_passed hours $((minutes_passed % 60)) minutes and $(($seconds_passed % 60)) seconds elapsed."
	#echo dbg: log_timestamp=$log_timestamp
	echo "$log_timestamp" >> $results_log_file
	echo "$result_log" >> $results_log_file
}

# 10000 time cost about 104 seconds
# original use count -le 1000000
while [ ! -f /tmp/stop_stress_test ]
do

	ADC_VAL_RAW=`( cat $channel )`
	ADC_VAL_VOLT=$(((ADC_VAL_RAW * 2000) / 1024))

	result_log=PASS
	if [ $ADC_VAL_VOLT -gt 1809 ] | [ $ADC_VAL_VOLT -lt 1760 ]
	then
		echo channel=$channel count=$count fail=$fail ADC_VAL_RAW=$ADC_VAL_RAW  ADC_VAL_VOLT=$ADC_VAL_VOLT
		fail=$(( fail + 1 ))
		result_log=FAIL
	fi

	count=$(( count+1 ))
	run_end_time=$(date +%s);
	seconds_passed=$(($run_end_time-$run_start_time))

	# ignore write stat every run
	if [ "$result_log" != "FAIL" -a $(($count % 50)) != 0 ];then
		continue
	fi

	dump_info

done

echo "$result_log"
dump_info
sync
exit 0