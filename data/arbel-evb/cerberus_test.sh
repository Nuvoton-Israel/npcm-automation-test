#!/bin/bash

log_file="/tmp/cerberus.log"

cerberus_utility fwversion > /dev/null
if [ "$?" == "0" ]; then
	cerberus_utility fwversion 0 | grep "Cerberus Version" > $log_file
	cerberus_utility fwversion 1 | grep "RIoT Core Version" >> $log_file
	if [ `cerberus_utility testerror | grep -i "fail|error|Invalid"` >> $log_file ]; then
		exit 1
	else
		echo "Test completed successfully." >> $log_file
	fi
	echo "Cerberus command completed successfully." >> $log_file
else
	echo "Cerberus command failed." > $log_file
	exit 1
fi

echo "cerberus test finished"
exit 0
