#!/bin/bash

if [ -z "$5" ] ; then
    echo "usage:  sh adc_test.sh <ch> <ref Volt> <resolution> <boundary>"
	echo '$1: the ADC channel'
	echo '$2: the ADC reference voltage'
	echo '$3: the ADC resolution'
	echo '$4: the ADC upper bound'
	echo '$5: the ADC lower bound'
	exit 1
fi

#initialize  variables
channel="in_voltage$1_raw"
ref_volt=`echo $2 | awk '{print ($1 * 1000)}'` # V => mV, 2 * 1000
resolution=$3  # poleg 1024, arbel 4096
upbound=$4     # 1809
lowbound=$5    # 1760
count=0
fail=0
BASEDIR=$(dirname "$0")
run_start_time=$(date +%s);
seconds_passed=0
results_log_file="$BASEDIR/log/adc_stress.stat"
log_file="$BASEDIR/log/adc_stress.log"
result_log=PASS

echo "Statefile: $results_log_file"
echo "$channel, $ref_volt, $resolution, $upbound, $lowbound" | tee $log_file

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
#while [ $count -le 10 ]
do

	ADC_VAL_RAW=`( cat $channel )`
	ADC_VAL_VOLT=$(((ADC_VAL_RAW * $ref_volt) / $resolution))
	#echo $ADC_VAL_VOLT

	result_log=PASS
	if [ $ADC_VAL_VOLT -gt $upbound -o $ADC_VAL_VOLT -lt $lowbound ]
	then
		echo channel=$channel count=$count fail=$fail ADC_VAL_RAW=$ADC_VAL_RAW  ADC_VAL_VOLT=$ADC_VAL_VOLT >> $log_file
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