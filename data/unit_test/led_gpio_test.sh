# HW set up
: << END
J712:
GPIO5_SGPMCK => GPIO0_SGPMLD
GPIO3_SGPMO => GPIO1_SGPMI

END

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
		echo "check gpio$gpio fail, value: $val"
		exit 1
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
# Main function

# normal GPIO short test


case "$1" in
	0)  #set led dark and gpio 0
		test_set $@
		set_gpio 0 $sgpio
		set_gpio 1 $bgpio
		set_gpio 1 4 6
		check_gpio 1 5 7
		set_gpio 0 4 6
		check_gpio 0 5 7
		;;
	1)  #set led bright and gpio 1
		test_set $@
		set_gpio 1 $sgpio
		set_gpio 0 $bgpio
		set_gpio 1 4 6
		check_gpio 1 5 7
		set_gpio 0 4 6
		check_gpio 0 5 7
		;;
	*)
		echo "enter 1(bright) or 0(dark)"
		;;

esac

