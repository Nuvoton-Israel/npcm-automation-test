*** Settings ***
Documentation	Basic function test for nuvoton chips
Resource	lib/test_utils.robot
Resource	lib/resource.robot
Resource	lib/log_collector.robot
Suite Setup		Check DUT Environment
Test Teardown   Collect Log On Test Case Fail

*** Variables ***
# test scripts
${GPIO_SCRIPT}		gpio_test.sh
${PWM_SCRIPT}		pwm_fan_test.sh
${CPU_SCRIPT}		drystone_on_off.sh
${RNG_SCRIPT}		rng_test.sh
${Net_SCRIPT}		net_test.sh
${DD_SCRIPT}		dd_test.sh
${ADC_SCRIPT}		adc_test.sh
${UDC_SCRIPT}		udc_dd_test.sh
${I2C_SCRIPT}		i2c_slave_eeprom.sh
${ignore_err}		${0}

*** Test Cases ***
Test Run Pwm and Fan
	[Documentation]  PWM and Fan tach test
	[Tags]  Basic  Onboard  HWsetup  PWM  FAN
	[Template]  Test Script And Verify

	# script
	${PWM_SCRIPT}

Test Run GPIO
	[Documentation]  GPIO function test
	[Tags]  Basic  Onboard  HWsetup  GPIO
	[Template]  Test Script And Verify

	# script
	${GPIO_SCRIPT}

CPU Stress Test
	[Documentation]  CPU stress test by running drystone
	[Tags]  Stress Test  Onboard  CPU

	# @{args}:
	# 10000000 => run 10 seconds
	# 500000   => stop and wait 0.5 second
	Run Stress Test Script And Verify  10000000  500000
	...  script=${CPU_SCRIPT}

RNG Stress Test
	[Documentation]  Test Random generater by ent tool
	[Tags]  Stress Test  Onboard RNG

	Run Stress Test Script And Verify
	...  script=${RNG_SCRIPT}

ADC Stress Test
	[Documentation]  Test ADC by access sysfs
	[Tags]  Stress Test  Onboard  ADC

	# @{args}:
	# 4 => use adc 4
	Run Stress Test Script And Verify  4
	...  script=${ADC_SCRIPT}

Gmac Net Stress Test
	[Documentation]  Test network by iperf3 via gmac
	[Tags]  Stress Test  Network  Onboard  Gmac

	Start Remote Iperf Server
	Should Not Be Empty  ${GMAC_IP}
	...  msg= Default test run via gmac, so gmac must be set
	Set Test Variable  ${TEST_THRESHOLD}  ${GMAC_THR}
	# disable eth0 to avoid getting confused result
	Enable Ethernet Interface  eth0  ${False}
	# @{args}:
	# -1 => unlimt execute
	# [1000 2000] => the test delay ms range
	# [8 12] => the test execute second range
	# 400 => the minimal speed (MBits/S) to pass test
	# GMAC_IP => run iperf with bind this IP
	# IPERF_SERVER  => the iperf server IP address
	Run Stress Test Script And Verify  -1  1000  2000
	...  8  12  ${GMAC_THR}  ${GMAC_IP}  ${IPERF_SERVER}
	...  script=${Net_SCRIPT}
	Enable Ethernet Interface  eth0  ${True}
	# kill iperf server after test finish
	[Teardown]  Net Test Teardown

Emac Net Stress Test
	[Documentation]  Test network by iperf3 via emac
	[Tags]  Stress Test  Network  Onboard  Emac

	# run test if EMAC IP not empty or cannot ignore this test
	Run Keyword If
	...  ${ALLOW_IGNORE_EMAC} and '${EMAC_IP}' == '${EMPTY}'
	...  Pass Execution
	...    message=Ignore Emac test because allow ignore test it

	Start Remote Iperf Server
	Should Not Be Empty  ${EMAC_IP}
	...  msg= IP address must set
	Set Emac IP address  ${EMAC_IP}
	SSHLibrary.Close All Connections
	${OPENBMC_HOST} =  Set Global Variable  ${EMAC_IP}
	# TODO: dynamic change BMC IP address may not stable...
	#Enable Ethernet Interface  eth1  ${False}
	# @{args}:
	# -1 => unlimt execute
	# [1000 2000] => the test delay ms range
	# [8 12] => the test execute second range
	# 60 => the minimal speed (MBits/S) to pass test
	# EMAC_IP => run iperf with bind this IP
	# IPERF_SERVER  => the iperf server IP address
	Run Stress Test Script And Verify  -1  1000  2000
	...  8  12  ${EMAC_THR}  ${EMAC_IP}  ${IPERF_SERVER}
	...  script=${Net_SCRIPT}

	#Enable Ethernet Interface  eth1  ${True}
	SSHLibrary.Close All Connections
	${OPENBMC_HOST} =  Set Global Variable  ${GMAC_IP}
	# kill iperf server after test finish
	[Teardown]  Net Test Teardown


FIU Stress Test
	[Documentation]  Test FIU by read write SPI flash
	[Tags]  Stress Test  Storage  Onboard  SPI

	# mount parition first
	# Mount SPI  mtdn
	# @{args}:
	# example -1  4000  8000  2  6  /mnt/flash/mtd6  /tmp/flash/mtd6  2  0
	# -1 => unlimt execute
	# [4000  8000] => the test delay ms range
	# [2  6] => the test file count number range
	# /mnt/flash/mtd6 => the flash mounted path
	# /tmp/flash/mtd6 => the temp path we put big file for test
	# 2 => test file size
	# 0 => capacity, see dd_test.sh

	# Note. we should format flash before mount it!
	# flash_eraseall -j /dev/mtd8
	# and this will take such long time, should we erase it everytime?
	${folder}=  Prepare Mount Folder  flash=spi  device=${SPI_DEV}
	${tmp_folder}=  Replace String  ${folder}  mnt  tmp
	Log  test folders ${folder} ${tmp_folder}
	Run Stress Test Script And Verify  -1  4000  8000  2  6
	...  ${folder}  ${tmp_folder}  2  0
	...  script=${DD_SCRIPT}
	Sleep  3
	#Unmount Folder  ${folder}
	[Teardown]  Storage Test Teardown  ${folder}

EMMC Stress Test
	[Documentation]  Test eMMC by read write eMMC partition
	[Tags]  Stress Test  Storage  Onboard  EMMC

	# @{args}:
	# example -1  4000  8000  5  10  /mnt/emmc/p1   /tmp/emmc/p1  100  0

	# Note. we should format and partition flash before mount it!
	# fdisk /dev/mmcblk0, n, p, 1, \n, \n, w
	# mkfs.ext4 /dev/mmcblk0p1
	${folder}=  Prepare Mount Folder  flash=emmc  device=${MMC_DEV}
	${tmp_folder}=  Replace String  ${folder}  mnt  tmp
	Log  test folders ${folder} ${tmp_folder}
	Run Stress Test Script And Verify  -1  4000  8000  5  10
	...  ${folder}  ${tmp_folder}  100  0  0x100000
	...  script=${DD_SCRIPT}
	Sleep  3
	#Unmount Folder  ${folder}
	[Teardown]  Storage Test Teardown  ${folder}

USB Host Stress Test
	[Documentation]  Test USB host by read write USB mass storage
	[Tags]  Stress Test  Storage  USB  UDC

	# @{args}:
	# example -1  4000  8000  5  10  /mnt/usb/p1   /tmp/usb/p1  100  0

	# Note. we should format and partition flash before mount it!
	${folder}=  Prepare Mount Folder  flash=usb  device=${USB_DEV}
	${tmp_folder}=  Replace String  ${folder}  mnt  tmp
	Log  test folders ${folder} ${tmp_folder}
	Run Stress Test Script And Verify  -1  4000  8000  5  10
	...  ${folder}  ${tmp_folder}  100  0  0x100000
	...  script=${DD_SCRIPT}
	Sleep  3
	[Teardown]  Storage Test Teardown  ${folder}

I2C Slave EEPROM Stress Test
	[Documentation]  Test I2C master and slave as EEPROM
	[Tags]  Stress Test  I2C  EEPROM
	# In this test, we probe a I2C slave EEPROM on one I2C bus, and connect
	# it to another I2C bus as master. Then perform read/write data, also
	# compare data is mached or not.

	# copy test binary to DUT
	Copy Data To BMC  ${DIR_SCRIPT}/i2c_slave_rw  /tmp
	# @{args}:
	# I2C bus as master,  2
	# I2C bus as slave,   1
	# I2C eeprom address, 0x64

	Run Stress Test Script And Verify  2  1  0x64
	...  script=${I2C_SCRIPT}

Test Hello World
	[Documentation]  Hello world
	[Tags]  Hello

	Log  Hello world!
	${exec}=  Set Variable  Shell Cmd
	Run Keyword  ${exec}  ls
	# Fail
	Log  ${BOARD_TEST_MSG}  console=${True}
	Set Test Message  Just hello world test case  append=yes

# We Connect DUT USB host and USB client, so we don't need test client again
# USB Device Stress Test
# 	[Documentation]  Test USB device by binding eMMC as USB mass storage
# 	[Tags]  Stress Test  Storage  USB  UDC

# 	# confirm test PC connect the UDC mass storage
# 	${udc_path}=  Find UDC On PC
# 	Log  udc mount point: ${udc_path}
# 	Run Stress Test Script And Verify  ${udc_path}
# 	...  script=${UDC_SCRIPT}  bmc=False


*** Keywords ***

Test Script And Verify
    [Documentation]  run test script and check result
    [Arguments]  ${script}

    # Description of argument(s):
    # ${script}    test script path

    Copy Data To BMC  ${DIR_SCRIPT}/${BOARD}/${script}    /tmp
    ${stdout}  ${stderr}  ${rc}=
    ...  BMC Execute Command  /bin/bash /tmp/${script}
    Should Be Empty  ${stderr}
    Should Not Be Empty  ${stdout}  msg=Must print information during run script
    Should Be Equal    ${rc}    ${0}
