#!/bin/sh
set -e

if [ -z "$8" ]
  then
	echo usage :
	echo '$1 core . -1 for auto cpu selection'
	echo '$2 while interval lower delay (ms).'
	echo '$3 while interval upper delay (ms).'
	echo '$4 Edge'
	echo '$5 Iterations'
	echo '$6 msSleep'
	echo '$7 gpio loop1 number'
	echo '$8 gpio loop2 number'
	exit 1
fi


#initialize  variables
BASEDIR=$(dirname "$0")
run_start_time=$(date +%s)
number_of_tests_run=0
number_of_tests_failed=0
seconds_passed=0
loop_num=0
GPIO_BIN=/tmp/gpio_test

results_log_file="$BASEDIR/log/gpio_stress.$7.$8.stat"
log_file="$BASEDIR/log/gpio_stress.$7.$8.log"
tmp_file="/tmp/gpio_stress.$7.$8.tmp"
result_log=PASS

echo "Statefile: $results_log_file"

echo  > $tmp_file
echo  > $log_file

#Export gpios
echo $7 > /sys/class/gpio/export 2> /dev/null
echo $8 > /sys/class/gpio/export 2> /dev/null


while [ ! -f /tmp/stop_stress_test ]
do

	range=$(($3-$2))
	pick=$(($RANDOM%range))
	sleep_interval=$((($2+pick)*1000))
	usleep $sleep_interval
	result_log=PASS

	#### update of log file should be done just at the beginning of global 'while' loop
	number_of_tests_run=$(($number_of_tests_run + 1))
	run_end_time=$(date +%s);
	seconds_passed=$(($run_end_time-$run_start_time))

	echo " number of tests run $number_of_tests_run , failed $number_of_tests_failed" > $results_log_file
	#echo dbg: number_of_tests_run=$number_of_tests_run

	minutes_passed="$(($seconds_passed / 60))"
	hours_passed="$(($minutes_passed / 60))"
	log_timestamp="$hours_passed hours $((minutes_passed % 60)) minutes and $(($seconds_passed % 60)) seconds elapsed."
	#echo dbg: log_timestamp=$log_timestamp
	echo "$log_timestamp">> $results_log_file

	echo  > $tmp_file
	### end of updating log file

	gpio_test_cmd="${GPIO_BIN} $7 $8 $4 $5 $6"
	if [ "$1" -eq -1 ]; then
		echo $gpio_test_cmd >> $tmp_file
		$gpio_test_cmd >> $tmp_file 2>&1
	else
		echo taskset $1 $gpio_test_cmd >> $tmp_file
		taskset $1 $gpio_test_cmd >> $tmp_file 2>&1
	fi

	Channel_Errors=$(awk 'BEGIN {count=0;} /__FAIL__/ {++count} END {print count}' $tmp_file)

	#echo dbg: Channel_Errors=$Channel_Errors
	if [ "$Channel_Errors" -ge "1" ]
	then
		number_of_tests_failed=$(($number_of_tests_failed + $Channel_Errors))
	fi

	Fail_Threshold=$((4*$7/100))
	if [ "$number_of_tests_failed" -ge "$Fail_Threshold" ]
	then
		result_log=FAIL
	fi


	echo  >> $log_file
	echo "timestamp = $run_end_time sec">> $log_file
	cat $tmp_file >> $log_file
	### end of updating log file


	loop_num=$(($loop_num + 1))
	echo "gpio_stress.$7.$8 loop = $loop_num"


done

#Unexport gpios
echo $7 > /sys/class/gpio/unexport 2> /dev/null
echo $8 > /sys/class/gpio/unexport 2> /dev/null

sync
