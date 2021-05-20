#!/bin/bash

if [ -z "$3" ] ; then
    echo "usage:  sh `basename $0` <master bus> <slave bus> <slave address>"
    echo "\t ex: `basename $0` 2 1 0x64"
    exit 1
fi

#initialize  variables
count=0
fail=0
BASEDIR=$(dirname "$0")
run_start_time=$(date +%s);
seconds_passed=0
results_log_file="$BASEDIR/log/i2c_eeprom_stress.stat"
run_log="$BASEDIR/log/i2c_eeprom_stress.log"
tmp_file="/tmp/i2c_eeprom_stress.tmp"
result_log=PASS
i2c_master="/dev/i2c-$1"
slave_bus=$2
i2c_slave="/dev/i2c-$slave_bus"
i2c_slave_addr="$3"
# 0x64 => 0x1064
i2c_slave_dev_addr=0x10${i2c_slave_addr#0x}
test_bin=/tmp/i2c_slave_rw

echo "Statefile: $results_log_file"
echo -e "i2c_master=$i2c_master\ni2c_slave=$i2c_slave\ni2c_slave_addr=$i2c_slave_addr" > $run_log
echo "test_bin=$test_bin" >> $run_log

dump_info(){
    echo " number of tests run $count , failed $fail" > $results_log_file

    minutes_passed="$(($seconds_passed / 60))"
    hours_passed="$(($minutes_passed / 60))"
    log_timestamp="$hours_passed hours $((minutes_passed % 60)) minutes and $(($seconds_passed % 60)) seconds elapsed."
    echo "$log_timestamp" >> $results_log_file
    echo "$result_log" >> $results_log_file
}
# check device address is correct
t_addr=`echo ${i2c_slave_addr} | grep -oe 0x..`
if [ "${i2c_slave_addr}" != "${t_addr}" ];then
    >&2 echo "slave adress format not correct, must be hex, but ${i2c_slave_addr}."
    exit 1
fi
# export i2c slave eeprom
cmd="2>&1 echo slave-24c02 ${i2c_slave_dev_addr} > /sys/bus/i2c/devices/i2c-${slave_bus}/new_device"
echo "$cmd" >> $run_log
res=`2>&1 echo slave-24c02 ${i2c_slave_dev_addr} > /sys/bus/i2c/devices/i2c-${slave_bus}/new_device`
if [ "$?" != 0 -o -n "$res" ];then
    # collect i2c device to log
    ls /sys/bus/i2c/devices >> $run_log
    if [ -f "/sys/bus/i2c/devices/${slave_bus}-${i2c_slave_dev_addr#0x}/slave-eeprom" ];then
        echo "i2c slave eeprom already exist!" | tee -a $run_log
    else
        echo "cannot add new i2c slave eeprom device..." | tee -a $run_log
        # echo error to stderr and log
        >&2 echo "$res"
        echo "$res" >> $run_log
        exit 1
    fi
fi
if [ ! -f "$test_bin" ];then
    echo "No test binary file!" | tee -a $run_log
    exit 1
fi

# 10 time cost about 1 seconds
while [ ! -f /tmp/stop_stress_test ]
do
    result_log=PASS
    cmd="${test_bin} -d ${i2c_master} -a ${i2c_slave_addr} -i 100 1"
    echo "$cmd" >> $run_log
    $cmd > $tmp_file
    if [ "$?" != "0" ];	then
        fail=$(( fail + 1 ))
        result_log=FAIL
        # echo message to stderr
        >&2 echo "test failed, count:$count, fail:$fail"
        >&2 cat $tmp_file
    fi

    count=$(( count+1 ))
    run_end_time=$(date +%s);
    seconds_passed=$(($run_end_time-$run_start_time))
    cat $tmp_file >> $run_log

    dump_info

done

echo "$result_log"
dump_info
sync
# delete i2c slave eeprom after test
cmd="echo ${i2c_slave_dev_addr} > /sys/bus/i2c/devices/i2c-${slave_bus}/delete_device"
echo "$cmd" >> $run_log
echo ${i2c_slave_dev_addr} > /sys/bus/i2c/devices/i2c-${slave_bus}/delete_device

exit 0