#!/bin/sh

if [ -z "$1" ]
  then
	#using only one thread , after 24h run the maximal rms reach 0.000996
	threshold=0.001
    echo "rng test is using default threshold = $threshold"
  else
    echo "usage :rng_stress.sh threshold"
	threshold=$1
fi

#initialize  variables
BASEDIR=$(dirname "$0")
run_start_time=$(date +%s);
average_result=0
number_of_tests_run=0
number_of_tests_failed=0
seconds_passed=0
loop_num=0
result_log=PASS
results_log_file="$BASEDIR/log/rng_stress.stat"
log_file="$BASEDIR/log/rng_stress.log"
ENT_BIN=/usr/bin/ent
ENT_DATA=/tmp/ent_data

echo "Statefile: $results_log_file"
echo "Statefile: $results_log_file" > $log_file

while [ ! -f /tmp/stop_stress_test ]
do
	number_of_tests_run=$(($number_of_tests_run + 1))
	run_end_time=$(date +%s);
	seconds_passed=$(($run_end_time-$run_start_time))

	#update log file
	echo " number of tests run $number_of_tests_run, failed $number_of_tests_failed" > $results_log_file
	#echo dbg: number_of_tests_run=$number_of_tests_run

	minutes_passed="$(($seconds_passed / 60))"
	hours_passed="$(($minutes_passed / 60))"
	log_timestamp="$hours_passed hours $((minutes_passed % 60)) minutes and $(($seconds_passed % 60)) seconds elapsed."
	#echo dbg: log_timestamp=$log_timestamp
	echo "$log_timestamp">> $results_log_file
	echo "$result_log">> $results_log_file


	#gather new random data
	rm -f $ENT_DATA
    if [ $(( $RANDOM % 2)) -eq 0 ];then
		#echo dbg: multi thread
		head -c 1000000 /dev/random >> $ENT_DATA & head -c 1000000 /dev/random >> $ENT_DATA & head -c 1000000 /dev/random >> $ENT_DATA &
	else
		#echo dbg: single thread
		head -c 1000000 /dev/random >> $ENT_DATA                 # to test randomness from single thread
	fi
	wait

	#run ent test and get result of Serial Correlation Coefficient
	curr_result=$(${ENT_BIN} ${ENT_DATA} | grep Serial | awk '{print $5}')


#	curr_result=$(awk '{delta=$2; avg+=$2/NR;} END {print sqrt(((delta-avg)^2)/NR);}' /tmp/ent)

	#calculation of curr_result=abs(curr_result)     :
	curr_result=$(awk -v curr_result=$curr_result 'BEGIN {printf "%0.10f", 0<curr_result ? curr_result:-curr_result; exit}')

	#echo dbg: average_result=$average_result
	echo dbg: curr_result=$curr_result >> $log_file

	if [ "$curr_result" == "0" ]; then
		curr_result=$(awk '{delta=$3; avg+=$3/NR;} END {print sqrt(((delta-avg)^2)/NR);}' ${ENT_DATA})
		echo dbg: curr_result=$curr_result
		echo "ERROR : curr_result == 0 ! .\n\n"
		touch $BASEDIR/log/ent$loop_num
		cp ${ENT_DATA}  $BASEDIR/log/ent$loop_num
	fi

	#calculation of rms rms=(a*current_value) + ( (1-a)*rms)     :
	average_result=$(awk -v curr_result=$curr_result -v average_result=$average_result 'BEGIN {printf "%0.10f",(curr_result*0.1 + average_result*0.9); exit}')

	#echo dbg: new_average_result=$average_result


	#echo dbg: $average_result
	average_is_greater_then_threshold=$(awk -v threshold=$threshold -v average_result=$average_result 'BEGIN{ print threshold<average_result }')
	if [ "$average_is_greater_then_threshold" == "1" ]
	then
		number_of_tests_failed=$(($number_of_tests_failed + 1))
		echo ent test FAIL
		result_log=FAIL
	fi

	loop_num=$(($loop_num + 1))
	echo "rng_stress loop = $loop_num" >> $log_file

done
