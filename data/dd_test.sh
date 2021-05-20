#!/bin/sh

if [ -z "$9" ]
  then
	echo usage :
	echo '$1 core .'
	echo '$2 while interval lower delay (ms).'
	echo '$3 while interval upper delay (ms).'
	echo '$4 lower file number .'
	echo '$5 upper file number .'
	echo '$6 src /mnt/emmc/p1'
	echo '$7 des /tmp/emmc/p1'
	echo '$8 Partition size (MB) '
	echo '$9 1 - full capacity ,  0 - typical capacity'
	echo '$10 BS setting for test'
	exit
fi


#initialize  variables
BASEDIR=$(dirname "$0")
run_start_time=$(date +%s);
number_of_tests_run=0
number_of_tests_failed=0
seconds_passed=0
loop_num=0
WR_BIN=/usr/bin/wr_perf_test
RD_BIN=/usr/bin/rd_perf_test

created_file_suffix=_$(echo $6 | sed 's/\//./g').to_$(echo $7 | sed 's/\//./g')

results_log_file="$BASEDIR/log/dd_stress.$created_file_suffix.stat"
log_file="$BASEDIR/log/dd_stress.$created_file_suffix.log"
tmp_file="/tmp/dd_stress.$created_file_suffix.tmp"
result_log=PASS
minimal_write_speed=10000
minimal_read_speed=10000

echo "Statefile: $results_log_file"

echo  > $tmp_file
echo  > $log_file

BS=0x4000
# set BS to difference storage device for better performance
if [ -n "${10}" ];then
	BS=${10}
fi
echo "BS=${BS}" >> $log_file

echo "Start DD test over $6"
mkdir -p $7
if [ "$8" -lt "$4" ]; then
	echo -e "Warning : lower files count greater than partition size in MB resolution .\n\n"
	exit
fi

while [ ! -f /tmp/stop_stress_test ]
do

	range=$(($3-$2))
	pick=$(($RANDOM%range))
	sleep_interval=$((($2+pick)*1000))
	usleep $sleep_interval

	range=$(($5-$4))
	pick=$(($RANDOM%range))
	files_count=$(($4+pick))

	min_chunk_count=$((($8*1024*1024) / (files_count*BS*1024) + 1))
	max_chunk_count=$((($8*1024*1024) / (files_count*BS) -2))

	for I in `seq 1 $files_count`;
	do


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

		#clear  $tmp_file   file :
		echo  > $tmp_file
		### end of updating log file

		if [ "$9" -eq 0 ]; then
			range=$(($max_chunk_count-$min_chunk_count))
			pick=$(($RANDOM%range))
			count=$(($min_chunk_count+pick))
		else
			count=$max_chunk_count
		fi


		wr_perf_cmd="${WR_BIN} $6/ bigfile$I $BS $count"
		rd_perf_cmd="${RD_BIN} $6/ $7/ bigfile$I $BS $count"
		#echo dbg: wr_perf_cmd=$wr_perf_cmd

		if [ "$1" -eq -1 ]; then
				echo >> $tmp_file
				echo $wr_perf_cmd  >> $tmp_file
				echo >> $tmp_file
			$wr_perf_cmd >> $tmp_file 2>&1
				echo >> $tmp_file
				echo $rd_perf_cmd  >> $tmp_file
				echo >> $tmp_file
			$rd_perf_cmd >> $tmp_file 2>&1
		else
				echo >> $tmp_file
				echo taskset $1 $wr_perf_cmd  >> $tmp_file
				echo >> $tmp_file
			taskset $1 $wr_perf_cmd >> $tmp_file 2>&1
				echo >> $tmp_file
				echo taskset $1 $rd_perf_cmd  >> $tmp_file
				echo >> $tmp_file
			taskset $1 $rd_perf_cmd >> $tmp_file 2>&1
		fi

		md_f1=$(md5sum $6/bigfile$I)
		md_f2=$(md5sum $7/bigfile$I)

		md_f1=$(echo $md_f1 |cut -d' ' -f1)

		md_f2=$(echo $md_f2 |cut -d' ' -f1)

		if [ "$md_f1" != "$md_f2" ]; then
			echo "ERROR : files are not identical! .\n\n" >> $tmp_file
			result_log=FAIL
			number_of_tests_failed=$(($number_of_tests_failed + 1))
			touch $BASEDIR/log/fail_src $BASEDIR/log/fail_dst
			cp $6/bigfile$I $BASEDIR/log/fail_src
			cp $7/bigfile$I $BASEDIR/log/fail_dst
		fi
		rm $7/bigfile*


		#extract  0.963801 : Write speed: 0.963801KB/s
		# [Brian] current Write speed: 0.17MB/s, change K to M
		curr_write_speed=$(cat $tmp_file  | grep 'Write speed' | sed 's/M/ /g' | awk '{print $3}')
		#echo dbg: curr_write_speed=$curr_write_speed
		curr_read_speed=$(cat $tmp_file  | grep 'Read speed' | sed 's/M/ /g' | awk '{print $3}')
		#echo dbg: curr_read_speed=$curr_read_speed

		#calculation of rms : rms=(a*current_value) + ( (1-a)*rms)     :
		if test $number_of_tests_run -eq 1
		then
			rms_write_speed=$curr_write_speed
			rms_read_speed=$curr_read_speed
		else
			rms_write_speed=$(awk -v curr_write_speed=$curr_write_speed -v rms_write_speed=$rms_write_speed 'BEGIN {printf "%0.2f",(curr_write_speed*0.1 + rms_write_speed*0.9); exit}')
			rms_read_speed=$(awk -v curr_read_speed=$curr_read_speed -v rms_read_speed=$rms_read_speed 'BEGIN {printf "%0.2f",(curr_read_speed*0.1 + rms_read_speed*0.9); exit}')
		fi
		#echo dbg: rms_write_speed=$rms_write_speed
		#echo dbg: rms_read_speed=$rms_read_speed

		#calculation of minimal client bandwidth    :
		minimal_write_speed=$(awk -v curr_write_speed=$curr_write_speed -v minimal_write_speed=$minimal_write_speed \
						'BEGIN {printf "%0.2f",(curr_write_speed < minimal_write_speed ? curr_write_speed : minimal_write_speed ); exit}')
		#echo dbg: minimal_write_speed=$minimal_write_speed
		#calculation of minimal server bandwidth    :
		minimal_read_speed=$(awk -v curr_read_speed=$curr_read_speed -v minimal_read_speed=$minimal_read_speed \
						'BEGIN {printf "%0.2f",(curr_read_speed < minimal_read_speed ? curr_read_speed : minimal_read_speed ); exit}')
		#echo dbg: minimal_read_speed=$minimal_read_speed


		if test $number_of_tests_run -eq 1
		then
			echo write statistic : >> $results_log_file
			echo "rms_write_speed=unknown ,  minimal_write_speed=unknown" >> $results_log_file

			echo read statistic : >> $results_log_file
			echo "rms_read_speed=unknown ,  minimal_read_speed=unknown" >> $results_log_file
		else
			echo write statistic : >> $results_log_file
			echo "rms_write_speed=$rms_write_speed ,  minimal_write_speed=$minimal_write_speed" >> $results_log_file

			echo read statistic : >> $results_log_file
			echo "rms_read_speed=$rms_read_speed ,  minimal_read_speed=$minimal_read_speed" >> $results_log_file
		fi


		echo  >> $log_file
		echo "timestamp = $run_end_time sec">> $log_file
		echo "$result_log" >> $log_file
		cat $tmp_file >> $log_file

	done

	rm $6/*

	wait

	loop_num=$(($loop_num + 1))
	echo "dd_stress.$created_file_suffix loop = $loop_num"


done
