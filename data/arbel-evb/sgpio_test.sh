#!/bin/sh
set -e

for ((i=1;i<=10;i++))
do
	gpioset 8 0=0 1=0 8=0 9=0 10=0 11=0 12=0 13=0 14=0 15=0
	log_file="/tmp/log/sgpio_test.$i.log"
	gpiomon -n 20 8 64 65 72 73 74 75 76 77 78 79  > $log_file &

	t=0
	while [ "$t" != "11" ]
	do
		t=$(ps |  grep  "gpiomon]" | wc -l)
	done

	gpioset 8 0=1 1=1 8=1 9=1 10=1 11=1 12=1 13=1 14=1 15=1
	gpioset 8 0=0 1=0 8=0 9=0 10=0 11=0 12=0 13=0 14=0 15=0

	t=11
	c=10
	while [ "$t" != "1" ] &&  [ "$c" != "0" ]
	do
		(( c-- ))
		t=$(ps |  grep  "gpiomon]" | wc -l)
	done

	if [ "$t" != "1" ]
	then
		echo FAIL  >> $log_file
		echo $i:FAIL
		exit 1
	else
		echo PASS  >> $log_file
		echo $i:PASS
	fi

done

exit 0
