*** Settings ***
Documentation	Basic function test for nuvoton chips
Resource	lib/test_utils.robot
Resource	lib/resource.robot
Resource	lib/log_collector.robot
Library		lib/load_var_utils.py  WITH NAME  VAR_UTILS
Suite Setup		Basic Suite Setup
Test Setup		Set Test Variable  ${STATE_FILE}  ${EMPTY}
Test Teardown	Collect Log On Test Case Fail

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

Primary Interface Net Stress Test
	[Documentation]  Test network by iperf3 via RGMII
	[Tags]  Stress Test  Network  Onboard  Gmac  RGMII  eth1

	Net Stress Test  ${NET_PRIMARY_IP}  ${NET_PRIMARY_INTF}  ${NET_PRIMARY_THR}
	# kill iperf server after test finish
	[Teardown]  Net Test Teardown

RMII Net Stress Test
	[Documentation]  Test network by iperf3 via RMII
	[Tags]  Stress Test  Network  Onboard  Emc  RMII  eth0

	Secondary Interface Net Stress Test
	...  @{NET_SECONDARY_IP}[0]  @{NET_SECONDARY_INTF}[0]  @{NET_SECONDARY_THR}[0]
	[Teardown]  Net Test Teardown

SGMII Net Stress Test
	[Documentation]  Test network by iperf3 via SGMII
	[Tags]  Stress Test  Network  Onboard  Emc  SGMII  eth3

	${length}=  Get Length  ${NET_SECONDARY_INTF}
	Pass Execution If  ${length} < 2
	...  This board:${BOARD} does not support SGMII test, just ignore.
	Secondary Interface Net Stress Test
	...  @{NET_SECONDARY_IP}[1]  @{NET_SECONDARY_INTF}[1]  @{NET_SECONDARY_THR}[1]
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
	# 0x100000 => BS, read/write data each BS at a time

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

	${msg}=  Set Variable  I2C master and slave bus should not be empty.
	Should Not Be Empty  ${I2C_MASTER}  msg=${msg}
	Should Not Be Empty  ${I2C_SALVE}  msg=${msg}
	# copy test binary to DUT
	Copy Data To BMC  ${DIR_SCRIPT}/i2c_slave_rw  /tmp
	# @{args}:
	# I2C bus as master,  2
	# I2C bus as slave,   1
	# I2C eeprom address, 0x64

	Run Stress Test Script And Verify
	...  ${I2C_MASTER}  ${I2C_SALVE}  ${I2C_EEPROM_ADDR}
	...  script=${I2C_SCRIPT}
	[Teardown]  Simple Get Test State information

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

Load Board Variables
    [Documentation]  load variables by board

	Should Contain  ${BOARD_SUPPORTED}  ${BOARD}
	...  msg=Not supported board: ${BOARD},
	VAR_UTILS.Load Vars  data/${BOARD}/variables.py

Basic Suite Setup
    [Documentation]  this basic test suite setup function

	Load Board Variables
	Check DUT Environment

Secondary Interface Net Stress Test
    [Documentation]  run ethernet secondary interface test
    [Arguments]  ${IP}  ${interface}  ${thredshold}

    # Description of argument(s):
    # ${IP}         the ethernet interface IP address
    # ${interface}  the interface we want to test
    # ${thredshold} the thredshold speed to pass test

    # run test if interface IP not empty or cannot ignore this test
    Run Keyword If
    ...  ${ALLOW_IGNORE_SECONDARY} and '${IP}' == '${EMPTY}'
    ...  Pass Execution
    ...    message=Ignore secondary interface test because allow to ignore test it
    Net Stress Test  ${IP}  ${interface}  ${thredshold}