#!/bin/bash
# 10000000 500000 for run 10 seconds, stop 0.5 second

set -e

Usage(){
    echo `basename $0` "[on usec] [off usec]"
    echo ""
    exit 1
}

if [ -z "$2" ];then
    Usage
fi

on_usec=$1
off_usec=$2
#initialize  variables
BASEDIR=$(dirname "$0")
run_start_time=$(date +%s);
average_result=0
number_of_tests_run=0
number_of_tests_failed=0
seconds_passed=0
#loop_num=0
result_log=PASS
log_file="$BASEDIR/log/cpu_stress.stat"
cc_dry2=/usr/bin/cc_dry2

echo "Statefile: $log_file"

if [ ! -d "$BASEDIR/log" ];then
    mkdir -v "$BASEDIR/log"
fi

if [ -f /tmp/stop_stress_test ];then
    echo "please remove stop_stress_test before starting test"
    exit 1
fi

while [ ! -f /tmp/stop_stress_test ]
do
    number_of_tests_run=$(($number_of_tests_run + 1))
    run_end_time=$(date +%s);
    seconds_passed=$(($run_end_time-$run_start_time))
    echo " number of tests run $number_of_tests_run, failed $number_of_tests_failed" > $log_file
    minutes_passed="$(($seconds_passed / 60))"
    hours_passed="$(($minutes_passed / 60))"
    log_timestamp="$hours_passed hours $((minutes_passed % 60)) minutes and $(($seconds_passed % 60)) seconds elapsed."
    #echo dbg: log_timestamp=$log_timestamp
    echo "$log_timestamp">> $log_file
    echo "$result_log">> $log_file

    process_id=""
    ${cc_dry2}  -1 0 &
    process_id=$!

    ${cc_dry2}  -1 0 &
    process_id="$! $process_id"
    usleep $on_usec
    # may use pgrep to get PID?
    #process_id=`/bin/ps -C cc_dry2 -o pid=`
    kill -9 $process_id 2>&1
    usleep $off_usec
    echo "cpu stress loop = $number_of_tests_run"

done

