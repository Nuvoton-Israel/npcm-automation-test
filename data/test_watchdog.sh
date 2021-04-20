#!/bin/bash

set -e

if [ -z "$1" ];then
	echo "cannot set up watchdog"
	exit 1
fi

STOP_FLAG=/tmp/stop_stress_test

if [ -f "$STOP_FLAG" ];then
	rm $STOP_FLAG
fi

echo "wait $1 seconds for run test..."
sleep $1
echo "time's up!"
touch $STOP_FLAG
echo 0 > $STOP_FLAG
sync
exit 0
