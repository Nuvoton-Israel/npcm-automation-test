#!/bin/sh
bmc_ip=0
server_ip=0
eth0_pass_val=0
eth1_pass_val=0
fail=0

test_check()
{
	if [ "$#" -ne 4 ]; then
		echo "You must input 4 arguments"
		echo "/eth_test.sh [bmc_ip] [server_ip] [eth0_pass_val] [eth1_pass_val]"
		exit 0
	else

	#reset the ethernet and do the default setting
	bmc_ip=$1
	server_ip=$2
	eth0_pass_val=$3
	eth1_pass_val=$4
	ifconfig eth0 down
	ifconfig eth1 down
	ifconfig eth0 up
	ifconfig eth1 up
	ifconfig eth0 $bmc_ip
	ifconfig eth1 $bmc_ip
fi
}

eth1_test_result()
{
	ifconfig eth1 $bmc_ip
	ifconfig eth0 down
	sleep 3
	speed=`iperf3 -B $bmc_ip -c $server_ip -t 1 | grep "sender" | awk  {'print $7'} | sed -n '1p'` > /dev/null
	speed=`echo $speed | awk -F"." {'print $1'}`

	if [ $speed  -gt $eth1_pass_val ]
		then
			echo "[OK] eth1_speed: $speed"
		else
			echo "[fail] eth1_speed: $speed"
			fail=1
	fi
}
eth0_test_result()
{
	ifconfig eth0 $bmc_ip
	ifconfig eth1 down
	sleep 3
	speed=`iperf3 -B $bmc_ip -c $server_ip -t 1 | grep "sender" | awk  {'print $7'} | sed -n '1p'` > /dev/null
	speed=`echo $speed | awk -F"." {'print $1'}`

	if [ $speed  -gt $eth0_pass_val ]
		then
			echo "[OK] eth0_speed: $speed"
		else
			echo "[fail] eth0_speed: $speed"
			fail=1
	fi
}
test_check $@
eth0_test_result $@
eth1_test_result $@

if [ $fail == 1 ]
then
  echo "eth_test_failed"
else
  echo "eth_test_pass"
fi


