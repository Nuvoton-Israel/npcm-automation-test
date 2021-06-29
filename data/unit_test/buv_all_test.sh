#!/bin/sh

fail=0

#adc parameter
adc_threshold=5

#ethernet parameter
bmc_ip=0
server_ip=0
eth0_pass_val=0
eth1_pass_val=0

#test path
SYS_I2C="/sys/bus/i2c/devices"
I2C_node="/sys/bus/i2c/devices"
emmc_path=/dev/mmcblk0
usb_path=/dev/sda

#test gpioifcon
# seven segment
sgpio="90 24 88 137 11 141 87 25 138 231 139 140 9 89 143 142"
# IOEXP blue LED
bgpio=`echo {488..495}`
xgpio="4 5 6 7"
SYS_GPIO="/sys/class/gpio"

# set GPIOs value
# $1    :value
# $2..n :GPIOs
set_gpio() {
	val=$1
	shift
	for gpio in $@;
	do
	  echo $val > ${SYS_GPIO}/gpio${gpio}/value
	done
}

set_dir() {
	dir=$1
	shift
	for gpio in $@;
	do
	  echo $dir > ${SYS_GPIO}/gpio${gpio}/direction
	done
}

# export gpio and set direction out
export_gpio() {
	for gpio in $@;
	do
	  if [ ! -d "${SYS_GPIO}/gpio${gpio}" ];then
		echo "$gpio" > ${SYS_GPIO}/export
	  fi
	  echo out > ${SYS_GPIO}/gpio${gpio}/direction
	done
}

unexport_gpio() {
	for gpio in $@;
	do
	  echo "$gpio" > ${SYS_GPIO}/unexport
	done
}

check_gpio() {
	val=$1
	shift
	for gpio in $@;
	do
	  res=`cat ${SYS_GPIO}/gpio${gpio}/value`
	  if [ "$val" != "$res" ];then
		echo "check gpio$gpio fail, value: $val" >> ~/test_log
		fail=1
		#echo gpio_test: fail >> ~/log
		#return
	  fi
done
}
test_set() {
	
	export_gpio $xgpio
	set_dir "in" 5 7
	export_gpio $bgpio
	set_gpio 1 $bgpio
	export_gpio $sgpio

}

adc_test() {
	cd ~/
	pwd=`pwd`
	cd /sys/devices/platform/ahb/ahb:apb/f000c000.adc/iio:device0/
	cp -rf /usr/bin/adc_set ~/adc_set
	
	for test in voltage0 voltage1 voltage2 voltage3 voltage4 voltage5 voltage6 voltage7
	do
		channel="in_${test}_raw"
		ADC_VAL_RAW=`( cat $channel )`
		ADC_VAL_VOLT=$(((ADC_VAL_RAW * 2000) / 1024)) 
		temp=`expr $adc_threshold + 100`
		get_adc=`cat ${pwd}/adc_set | grep ${test} | awk {'print $2'}`
		up_val=`expr $get_adc \* $temp / 100`
		temp=`expr 100 - $adc_threshold`
		low_val=`expr $get_adc \* $temp / 100`
		if [ $ADC_VAL_VOLT -gt $up_val ]
		then
		  fail=1
		  echo "$channel : $ADC_VAL_VOLT is too high" >> ~/test_log
		  #echo adc_test_fail >> ~/log
		  #return
		fi
		if [ $ADC_VAL_VOLT -lt $low_val ]
		then
		  fail=1
		  echo "$channel : $ADC_VAL_VOLT is too low" >> ~/test_log
		  #echo adc_test: fail >> ~/log
		  #return
		fi
	done
}
 
set_i2c(){

	for I2C in 1 3 5 7 9 11;
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

	for I2C in 1 3 5 7 9 11;
	do
	  if [ -d "${I2C_node}/${I2C}-1064" ];then
		  num=$(($I2C+1))
		  i2cset -y ${num} 0x64 0x00 0x1234 w
		  val=`i2cget -y ${num} 0x64 0x00 w`
		  if [ "$val" != "0x1234" ];then
				fail=1
				echo "i2c "$I2C "fail" >> ~/test_log
				#echo i2c_test: fail >> ~/log
				#return
		  fi
	  fi
	done
}

pwm_test(){

	devmem=/sbin/devmem
	set +e

	rs=`systemctl --type=service | grep phosphor-pid-control`
	if [ -n "${rs}" ];then
		# stop PID server
		systemctl stop phosphor-pid-control.service
	fi

	set -e

	cd /sys/class/hwmon/hwmon4
	# set duty to 50 %
	echo 125 > pwm1
	echo 125 > pwm2
	echo 125 > pwm3
	echo 125 > pwm4

	# set clock to about 100HZ

	${devmem} 0xf0103004 w 0x00003333
	${devmem} 0xf0104004 w 0x00003333
	${devmem} 0xf0103000 w 0x00007777
	${devmem} 0xf0104000 w 0x00007777

	sleep 1
	pwm_num=`echo {1..4}`

	for PWM in $pwm_num;
	do
		pwm_val=`cat fan${PWM}_input`
		if [ $pwm_val != 3054 ]
		then
			echo "fan${PWM}_input != 3054" >> ~/test_log
			fail=1
			#echo pwm_test: fail >> ~/log
			#return
		fi
	done

}

test_spi()
{
	test_num=0
	spi_flash=4
	for spi in spi2.0 spi2.1 spi4.0 spi3.0
	do
		dmesg | grep "${spi}:" > /dev/null
		if [ $? == 0 ]
		then
			test_num=$(($test_num+1))
		fi
	done
	if [ $test_num !=  $spi_flash ]
	then
		fail=1
	fi
}
test_usb()
{
	if [ -f "/tmp/ext.img" ]
	then
		echo ""
	else
		dd if=/dev/zero of=/tmp/ext.img bs=1M count=10
		mkfs.ext4 /tmp/ext.img
	fi
	
	dd if=/tmp/ext.img of=$usb_path
	mkdir -p ~/usb
	mount $usb_path ~/usb
	echo "usb_test" > ~/usb/log
	usb_read=`cat ~/usb/log`
	if [ $usb_read != "usb_test" ]
	then
		fail=1
	fi
	umount ~/usb
}
test_emmc()
{
	if [ -f "/tmp/ext.img" ]
	then
		echo ""
	else
		dd if=/dev/zero of=/tmp/ext.img bs=1M count=10
		mkfs.ext4 /tmp/ext.img
	fi
	
	dd if=/tmp/ext.img of=$emmc_path
	mkdir -p ~/emmc
	mount $emmc_path ~/emmc
	echo "emmc_test" > ~/emmc/log
	emmc_read=`cat ~/emmc/log`
	
	if [ $emmc_read != "emmc_test" ]
	then
		fail=1
	fi
	umount ~/emmc
}
test_check()
{

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
			#echo "[OK] eth1_speed: $speed"
			fail=0
		else
			echo "[fail] eth1_speed: $speed" >> ~/test_log
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
			#echo "[OK] eth0_speed: $speed"
			fail=0
		else
			echo "[fail] eth0_speed: $speed" >> ~/test_log
			fail=1
	fi
}


# -----Main function-----

	if [ "$#" -ne 4 ]; then
		echo "You must input 4 arguments"
		echo "buv_all_test.sh [bmc_ip] [server_ip] [eth0_pass_val] [eth1_pass_val]"
		exit 0
	fi
	rm -rf ~/result
	rm -rf ~/test_log
	sleep 1
# normal GPIO short test
	test_set $@
	set_gpio 1 $sgpio
	set_gpio 0 $bgpio
	set_gpio 1 4 6
	check_gpio 1 5 7
	set_gpio 0 4 6
	check_gpio 0 5 7
	
	if [ $fail == 1 ]
	then
		echo gpio_test: fail >> ~/result
		fail=0
	else
		echo gpio_test: pass >> ~/result
		fail=0
	fi
	
#adc test
	adc_test $@

	if [ $fail == 1 ]
	then
		echo adc_test: fail >> ~/result
		fail=0
	else
		echo adc_test: pass >> ~/result
		fail=0
	fi
	
#i2c test
	set_i2c $@
	test_i2c $@

	if [ $fail == 1 ]
	then
		echo i2c_test: fail >> ~/result
		fail=0
	else
		echo i2c_test: pass >> ~/result
		fail=0
	fi

# pwm test
	pwm_test $@

	if [ $fail == 1 ]
	then
		echo pwm_test: fail >> ~/result
		fail=0
	else
		echo pwm_test: pass >> ~/result
		fail=0
	fi

# spi test
	test_spi $@

	if [ $fail == 1 ]
	then
		echo spi_test: fail >> ~/result
		fail=0
	else
		echo spi_test: pass >> ~/result
		fail=0
	fi

#usb test
	test_usb $@

	if [ $fail == 1 ]
	then
		echo usb_test: fail >> ~/result
		fail=0
	else
		echo usb_test: pass >> ~/result
		fail=0
	fi

#emmc test
	test_emmc $@

	if [ $fail == 1 ]
	then
		echo emmc_test: fail >> ~/result
		fail=0
	else
		echo emmc_test: pass >> ~/result
		fail=0
	fi
# ethernet_0 test
	test_check $@
	eth0_test_result $@
	if [ $fail == 1 ]
	then
		echo eth0_test: fail >> ~/result
		fail=0
	else
		echo eth0_test: pass >> ~/result
		fail=0
	fi
# ethernet_1 test
	eth1_test_result $@
	
	if [ $fail == 1 ]
	then
		echo eth1_test: fail >> ~/result
		echo "---------test result--------"
		cat ~/result
		rm -rf ~/result
		rm -rf ~/usb
		rm -rf ~/emmc
		exit 0
	else
		echo eth1_test: pass >> ~/result
		echo "---------test result--------"
		cat ~/result
		rm -rf ~/result
		rm -rf ~/usb
		rm -rf ~/emmc
		exit 0
	fi

	
