#!/bin/sh
set -e

for ((i=1;i<=10;i++))
do
	log_file="/tmp/log/sgpio_test.$i.log"
	gpiomon -n 24 8 64 65 70 71 72 73 74 75 76 77 78 79  > $log_file &

	t=0
	while [ "$t" != "13" ]
	do
		t=$(ps |  grep  "gpiomon]" | wc -l)
	done

	gpioset 8 0=1 1=1 6=1 7=1 8=1 9=1 10=1 11=1 12=1 13=1 14=1 15=1
	gpioset 8 0=0 1=0 6=0 7=0 8=0 9=0 10=0 11=0 12=0 13=0 14=0 15=0

	Pin_Count=$(awk 'BEGIN{x=0;y=0}{ y++ ; x+=$5 ; if(y==24) print x ;}' $log_file)
	echo $i:$Pin_Count
	if [ "$Pin_Count" != "1748" ]
	then
		echo FAIL  >> $log_file
		exit 1
	else
		echo PASS  >> $log_file
	fi

	t=2
	while [ "$t" != "1" ]
	do
		t=$(ps |  grep  "gpiomon]" | wc -l)
	done
done

exit 0
