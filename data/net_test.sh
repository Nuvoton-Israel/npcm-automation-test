#!/bin/sh

if [ -z "$8" ]
  then
	echo usage :
	echo '$1 core . -1 for auto cpu selection'
	echo '$2 while lower delay interval  (ms) .'
	echo '$3 while  upper delay interval(ms).'
	echo '$4 -t : lower time in seconds to transmit for (default 10 secs) .'
	echo '$5 -t : higher time in seconds to transmit for (default 10 secs) .'
	echo '$6 client threshold bandwidth , if test result is less than threshold then test will be signed as failed'
	echo '$7 client bind address, for emac and gmac '
	echo '$8 server address 192.168.10.1.'
	exit
fi


#initialize  variables
BASEDIR=$(dirname "$0")
run_start_time=$(date +%s);
number_of_tests_run=-1
number_of_tests_failed=0
seconds_passed=0
client_threshold_bandwidth=$6
client_address=$7
client_minimal_bandwidth=10000
server_minimal_bandwidth=10000
results_log_file="$BASEDIR/log/net_stress.$7_$8.stat"
log_file="$BASEDIR/log/net_stress.$7_$8.log"
tmp_file="/tmp/net_stress.$8.tmp"
result_log=PASS
# iperf2 or iperf3 use different port
IPERF=/usr/bin/iperf3
# IPERF=/usr/tests/iperf_arm

echo "Statefile: $results_log_file"

echo  > $tmp_file
echo  > $log_file

while [ ! -f /tmp/stop_stress_test ]
do

	range=$(($3-$2))
	pick=$(($RANDOM%range))
	sleep_interval=$((($2+pick)*1000))
	usleep $sleep_interval


	range=$(($5-$4))
	pick=$(($RANDOM%range))
	time=$(($4+pick))
	timeout_time=$(($time+10))

	if [ "$1" -eq -1 ]; then
		iperf_cmd="/bin/busybox timeout $timeout_time $IPERF -c $8 -t$time -i2 -f m -B $7"
		#iperf_cmd="/usr/tests/iperf_arm -c $8 -t$time -d -f 'm'"
	else
		#iperf_cmd="taskset $1 /usr/tests/iperf_arm -c $8 -t$time -d -f 'm'"
		iperf_cmd="/bin/busybox timeout $timeout_time taskset $1 $IPERF -c $8 -t$time -i2 -d -f m -B $7"
	fi

	#echo dbg: iperf_cmd=$iperf_cmd


	#$iperf_cmd > /dev/null 2>&1 &
	#usleep 1000000
	#$iperf_cmd > /dev/null 2>&1 &
	#usleep 1000000
	#$iperf_cmd > /dev/null 2>&1 &
	#usleep 1000000
	$iperf_cmd &> $tmp_file
	if [ "$?" != "0" ];then
		echo "cannot execute iperf"
		exit 1
	fi
	wait

	#extract id1 from : [ id1] local 10.191.20.111 port 56272 connected with 10.191.10.136 port 5001
	#client_process_id=$(cat $tmp_file  | grep '^\[' | grep  '5001$' | sed 's/\(\[\|\]\)//g' | awk 'BEGIN{F="[ \\\[]+"} {print $1}')
	# iperf3 form: [  5] local 192.168.56.151 port 35846 connected to 192.168.56.102 port 5201
	client_process_id=$(cat $tmp_file  | grep '^\[' | grep  '5201$' | sed 's/\(\[\|\]\)//g' | awk 'BEGIN{F="[ \\\[]+"} {print $1}')
	#echo dbg: client_process_id=$client_process_id
	#extract id2 from : [ id2] local 10.191.20.111 port 5001 connected with 10.191.10.136 port 50224
	#server_process_id=$(cat $tmp_file  | grep '^\[' | grep '5001' | grep -v '5001$' | sed 's/\(\[\|\]\)//g' | awk 'BEGIN{F="[ \\\[]+"} {print $1}')
	# iperf3 form: Connecting to host 192.168.56.102, port 5201
	server_process_ip=$(cat $tmp_file | grep host | cut -f 4 -d " " | tr -d ",")
	#echo dbg: server_process_id=$server_process_id

	# [Brian] We cannot get server transfer data from temp_file,just ignore it
	#extract  83.9 : [  5]  0.0- 0.2 sec  2.50 MBytes  83.9 Mbits/sec
	#curr_client_bandwidth=$(cat $tmp_file  | grep 'Mbits' | grep $client_process_id\] | sed 's/\(\[\|\]\)//g' | awk '{print $7}')
	# iperf3 from: [  5]   1.00-2.00   sec  51.4 MBytes   431 Mbits/sec    0   67.0 KBytes
	# [  5]   0.00-4.00   sec   211 MBytes   442 Mbits/sec    0             sender
	curr_client_bandwidth=$(cat $tmp_file  | grep 'Mbits' | grep sender | awk '{print $7}')
	#echo dbg: curr_client_bandwidth=$curr_client_bandwidth
	#curr_server_bandwidth=$(cat $tmp_file  | grep 'Mbits' | grep $server_process_id\] | sed 's/\(\[\|\]\)//g' | awk '{print $7}')
	#echo dbg: curr_server_bandwidth=$curr_server_bandwidth

	#calculation of rms : rms=(a*current_value) + ( (1-a)*rms)     :
	if test $number_of_tests_run -eq 0
	then
		client_rms_bandwidth=$curr_client_bandwidth
		#server_rms_bandwidth=$curr_server_bandwidth
	else
		client_rms_bandwidth=$(awk -v curr_client_bandwidth=$curr_client_bandwidth -v client_rms_bandwidth=$client_rms_bandwidth 'BEGIN {printf "%0.2f",(curr_client_bandwidth*0.1 + client_rms_bandwidth*0.9); exit}')
		#server_rms_bandwidth=$(awk -v curr_server_bandwidth=$curr_server_bandwidth -v server_rms_bandwidth=$server_rms_bandwidth 'BEGIN {printf "%0.2f",(curr_server_bandwidth*0.1 + server_rms_bandwidth*0.9); exit}')
	fi
	#echo dbg: client_rms_bandwidth=$client_rms_bandwidth
	#echo dbg: server_rms_bandwidth=$server_rms_bandwidth

	#calculation of minimal client bandwidth    :
	client_minimal_bandwidth=$(awk -v curr_client_bandwidth=$curr_client_bandwidth -v client_minimal_bandwidth=$client_minimal_bandwidth \
					'BEGIN {printf "%0.2f",(curr_client_bandwidth < client_minimal_bandwidth ? curr_client_bandwidth : client_minimal_bandwidth ); exit}')
	#echo dbg: client_minimal_bandwidth=$client_minimal_bandwidth
	#calculation of minimal server bandwidth    :
	#server_minimal_bandwidth=$(awk -v curr_server_bandwidth=$curr_server_bandwidth -v server_minimal_bandwidth=$server_minimal_bandwidth \
	#				'BEGIN {printf "%0.2f",(curr_server_bandwidth < server_minimal_bandwidth ? curr_server_bandwidth : server_minimal_bandwidth ); exit}')
	#echo dbg: server_minimal_bandwidth=$server_minimal_bandwidth


	result_log=PASS
	result_is_less_then_threshold=$(awk -v curr_client_bandwidth=$curr_client_bandwidth -v client_threshold_bandwidth=$client_threshold_bandwidth 'BEGIN{ print curr_client_bandwidth<client_threshold_bandwidth }')
	if [ "$result_is_less_then_threshold" == "1" ]
	then
		echo net test failed on $8
		result_log=FAIL
	fi
	#result_is_less_then_threshold=$(awk 'BEGIN{ print "'$curr_server_bandwidth'"<"'$server_threshold_bandwidth'" }')
	#if [ "$result_is_less_then_threshold" == "1" ]
	#then
	#	echo net test failed on $8
	#	result_log=FAIL
	#fi

	if [ "$result_log" == "FAIL" ]
	then
		number_of_tests_failed=$(($number_of_tests_failed + 1))
	fi

	wait

	number_of_tests_run=$(($number_of_tests_run + 1))
	run_end_time=$(date +%s);
	seconds_passed=$(($run_end_time-$run_start_time))

	#### update of log file should be done just at the beginning of global 'while' loop

	echo " number of tests run $number_of_tests_run , failed $number_of_tests_failed" > $results_log_file
	#echo dbg: number_of_tests_run=$number_of_tests_run

	minutes_passed="$(($seconds_passed / 60))"
	hours_passed="$(($minutes_passed / 60))"
	log_timestamp="$hours_passed hours $((minutes_passed % 60)) minutes and $(($seconds_passed % 60)) seconds elapsed."
	#echo dbg: log_timestamp=$log_timestamp
	echo "$log_timestamp">> $results_log_file

	if test $number_of_tests_run -eq 0
	then
		echo client link statistic : >> $results_log_file
		echo "client_rms_bandwidth=unknown ,  client_minimal_bandwidth=unknown" >> $results_log_file

		#echo server link statistic : >> $results_log_file
		#echo "server_rms_bandwidth=unknown ,  server_minimal_bandwidth=unknown" >> $results_log_file
	else
		echo client link statistic : >> $results_log_file
		echo "client_rms_bandwidth=$client_rms_bandwidth ,  client_minimal_bandwidth=$client_minimal_bandwidth" >> $results_log_file

		#echo server link statistic : >> $results_log_file
		#echo "server_rms_bandwidth=$server_rms_bandwidth ,  server_minimal_bandwidth=$server_minimal_bandwidth" >> $results_log_file
	fi

	echo $result_log >> $results_log_file
	echo  >> $log_file
	echo "timestamp = $run_end_time sec">> $log_file
	echo $iperf_cmd >> $log_file
	cat $tmp_file | tee -a $log_file
	### end of updating log file

done
