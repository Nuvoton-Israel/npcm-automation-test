#!/bin/bash

log_file="/tmp/ssif.log"

if test -e "/dev/ipmi0";	then
	echo "/dev/ipmi0 device existed." > $log_file
else
	echo "/dev/ipmi0 device does not exist!!" > $log_file
	exit 1
fi

ipmitool -I open sdr list
if [ "$?" == "0" ]; then
	echo "ssif bridge test passed" >> $log_file
else
	echo "ssif bridge test failed!!" >> $log_file
	exit 1
fi

echo "ssif test finished"
exit 0
