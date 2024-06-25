#!/bin/bash

log_file="/tmp/ftpm.log"

if test -e "/dev/tpm0";	then
	echo "ftpm device exist." > $log_file
else
	echo "ftpm device does not exist!!" > $log_file
	exit 1
fi

# Full test - TPM will test all functions regardless of what has already been tested
tpm2_selftest -f
if [ "$?" == "0" ]; then
	echo "tpm2 selftest passed" >> $log_file
else
	echo "tpm2 selftest failed!!" >> $log_file
	exit 1
fi

echo "ftpm test finished"
exit 0
