#!/bin/sh

SYS_I2C="/sys/bus/i2c/devices"
I2C_node="/sys/bus/i2c/devices"
i2c_com_check=0

check_i2c()
{
	if [ "$1" = "" ];then
		echo "enter bus num"
		exit 0
	fi
	for I2C in $@;
	do
		check=`expr $I2C % 2`
		if [ "$check" == 0 ]
		then
		i2c_com_check=1
		fi
		if [ $I2C -gt 12 ];then
		i2c_com_check=1
	fi
	done
}

set_i2c(){

	for I2C in $@;
	do
	  if [ -d "${I2C_node}/${I2C}-1064" ]
		then
		  now=$(($I2C+1))
		else
		  echo slave-24c02 0x1064 > ${SYS_I2C}/i2c-${I2C}/new_device
	  fi
	done
}

test_i2c(){

	for I2C in $@;
	do
	  if [ -d "${I2C_node}/${I2C}-1064" ];then
		  num=$(($I2C+1))
		  i2cset -y ${num} 0x64 0x00 0x1234 w
		  val=`i2cget -y ${num} 0x64 0x00 w`
		  if [ "$val" == "0x1234" ];then
			   echo "i2c_${I2C}_${num}_pass"
		  else
			   echo "i2c_${I2C}_${num}_failed"
		  fi
	   else
		  echo I2C_SET_FAILED
	  fi
	done
}

check_i2c $@
if [ "$i2c_com_check" == 0 ];then
	set_i2c $@
	test_i2c $@
else
	echo "command : ./i2c_test.sh [bus_num]"
	echo "bus_num can select 1 3 5 7 9 11"
fi

