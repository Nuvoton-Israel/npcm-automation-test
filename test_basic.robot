*** Settings ***
Documentation	Basic function test for nuvoton chips
Resource	lib/test_utils.robot
Resource	lib/resource.robot
Resource	lib/log_collector.robot
Suite Setup		Basic Suite Setup
Test Setup		Set Test Variable  ${STATE_FILE}  ${EMPTY}
Test Teardown	Collect Log On Test Case Fail

*** Variables ***
# test scripts
${GPIO_SCRIPT}		gpio_test.sh
${PWM_SCRIPT}		pwm_fan_test.sh
${TMPS_SCRIPT}		tmps_test.sh
${CPU_SCRIPT}		drystone_on_off.sh
${RNG_SCRIPT}		rng_test.sh
${Net_SCRIPT}		net_test.sh
${DD_SCRIPT}		dd_test.sh
${ADC_SCRIPT}		adc_test.sh
${UDC_SCRIPT}		udc_dd_test.sh
${I2C_SCRIPT}		i2c_slave_eeprom.sh
${I2C_STRESS_BIN}	i2c_slave_rw
${GPIO_STRESS}		gpio_stress.sh
${GPIO_STRESS_BIN}	gpio_test
${I3C_SCRIPT}		i3c_test.sh
${FIU_SCRIPT}		fiu_test.sh
${AES_SCRIPT}		aes_test.sh
${PSPI_SCRIPT}		pspi_test.sh
${SGPIO_SCRIPT}		sgpio_test.sh
${SHA_SCRIPT}		sha_test.sh
${TPM_SCRIPT}		tpm_test.sh
${CERBERUS_SCRIPT}	cerberus_test.sh
${SSIF_SCRIPT}          ssif_test.sh
${ignore_err}		${0}

*** Test Cases ***
SHA Unit Test
	[Documentation]  SHA test
	[Tags]  Basic  Onboard  HWsetup  SHA
	[Template]  Test Script And Verify

	# script
	${SHA_SCRIPT}  @{BOARD_SUPPORTED}

SGPIO Unit Test
	[Documentation]  SGPIO test
	[Tags]  Basic  Onboard  HWsetup  SGPIO
	[Template]  Test Script And Verify

	# script
	${SGPIO_SCRIPT}  @{BOARD_SUPPORTED}

PSPI Unit Test
	[Documentation]  PSPI test
	[Tags]  Basic  Onboard  HWsetup  PSPI
	[Template]  Test Script And Verify

	# script
	${PSPI_SCRIPT}  @{BOARD_SUPPORTED}

AES Unit Test
	[Documentation]  AES test
	[Tags]  Basic  Onboard  HWsetup  AES
	[Template]  Test Script And Verify

	# script
	${AES_SCRIPT}  @{BOARD_SUPPORTED}

I3C Unit Test
	[Documentation]  I3C test
	[Tags]  Basic  Onboard  HWsetup  I3C
	[Template]  Test Script And Verify

	# script
	${I3C_SCRIPT}  arbel-evb

FIU Unit Test
	[Documentation]  FIU1 and FIU3 test
	[Tags]  Basic  Onboard  HWsetup  FIU
	[Template]  Test Script And Verify

	# script
	${FIU_SCRIPT}  @{BOARD_SUPPORTED}

Pwm and Fan Unit Test
	[Documentation]  PWM and Fan tach test
	[Tags]  Basic  Onboard  HWsetup  PWM  FAN
	[Template]  Test Script And Verify

	# script
	${PWM_SCRIPT}  @{BOARD_SUPPORTED}

GPIO Unit Test
	[Documentation]  GPIO function test
	[Tags]  Basic  Onboard  HWsetup  GPIO
	[Template]  Test Script And Verify

	# script
	${GPIO_SCRIPT}  @{BOARD_SUPPORTED}

TMPS Unit Test
	[Documentation]  TMPS function test
	[Tags]  Basic  Onboard  HWsetup  TMPS  Arbel
	[Template]  Test Script And Verify

	# script
	${TMPS_SCRIPT}  arbel-evb

TPM Unit Test
	[Documentation]  TPM test
	[Tags]  Basic  Onboard  HWsetup  TPM
	[Template]  Test Script And Verify

	# script
	${TPM_SCRIPT}  @{BOARD_SUPPORTED}

Cerberus Unit Test
	[Documentation]  Cerberus test
	[Tags]  Basic  Onboard  HWsetup  Cerberus
	[Template]  Test Script And Verify

	# script
	${CERBERUS_SCRIPT}  @{BOARD_SUPPORTED}

SSIF Unit Test
	[Documentation]  SSIF test
	[Tags]  Basic  Onboard  HWsetup  SSIF

	Copy Data To BMC  ${DIR_SCRIPT}/${SSIF_SCRIPT}  /tmp
	${cmd}=  Catenate  /bin/bash /tmp/${SSIF_SCRIPT}
	BMC Execute Command  ${cmd}  quiet=1

SHA Stress Test
	[Documentation]  SHA stress test
	[Tags]  Stress Test  Onboard  HWsetup  SHA

	${start}=  Get Time  epoch
	${stress_time_sec}=  Convert Time  ${STRESS_TIME}
	Rprint Vars  stress_time_sec
	FOR  ${count}  IN RANGE  1  99999
		Test Script And Verify  ${SHA_SCRIPT}  @{BOARD_SUPPORTED}  quiet=1
		${now}=  Get Time  epoch
		${diff}=  Evaluate  ${now} - ${start}
		Exit For Loop If    ${diff} > ${stress_time_sec}
	END

I3C Stress Test
	[Documentation]  I3C stress test
	[Tags]  Stress Test  Onboard  HWsetup  I3C  Arbel

	Pass Test If Not Support  arbel-evb
	${start}=  Get Time  epoch
	${stress_time_sec}=  Convert Time  ${STRESS_TIME}
	Rprint Vars  stress_time_sec
	FOR  ${count}  IN RANGE  1  99999
		Test Script And Verify  ${I3C_SCRIPT}  arbel-evb  quiet=1
		${now}=  Get Time  epoch
		${diff}=  Evaluate  ${now} - ${start}
		Exit For Loop If    ${diff} > ${stress_time_sec}
	END

AES Stress Test
	[Documentation]  AES stress test
	[Tags]  Stress Test  Onboard  HWsetup  AES

	${start}=  Get Time  epoch
	${stress_time_sec}=  Convert Time  ${STRESS_TIME}
	Rprint Vars  stress_time_sec
	FOR  ${count}  IN RANGE  1  99999
		Test Script And Verify  ${AES_SCRIPT}  @{BOARD_SUPPORTED}  quiet=1
		${now}=  Get Time  epoch
		${diff}=  Evaluate  ${now} - ${start}
		Exit For Loop If    ${diff} > ${stress_time_sec}
	END

SGPIO Stress Test
	[Documentation]  SGPIO stress test
	[Tags]  Stress Test  Onboard  HWsetup  SGPIO

	${start}=  Get Time  epoch
	${stress_time_sec}=  Convert Time  ${STRESS_TIME}
	Rprint Vars  stress_time_sec
	FOR  ${count}  IN RANGE  1  99999
		Test Script And Verify  ${SGPIO_SCRIPT}  @{BOARD_SUPPORTED}  quiet=1
		${now}=  Get Time  epoch
		${diff}=  Evaluate  ${now} - ${start}
		Exit For Loop If    ${diff} > ${stress_time_sec}
	END

PSPI Stress Test
	[Documentation]  PSPI stress test
	[Tags]  Stress Test  Onboard  HWsetup  PSPI

	${start}=  Get Time  epoch
	${stress_time_sec}=  Convert Time  ${STRESS_TIME}
	Rprint Vars  stress_time_sec
	FOR  ${count}  IN RANGE  1  99999
		Test Script And Verify  ${PSPI_SCRIPT}  @{BOARD_SUPPORTED}  quiet=1
		${now}=  Get Time  epoch
		${diff}=  Evaluate  ${now} - ${start}
		Exit For Loop If    ${diff} > ${stress_time_sec}
	END

JTAGM Stress Test
	[Documentation]  JTAG Master stress test
	[Tags]  Stress Test  Onboard  HWsetup  JTAGM  Arbel

	Pass Test If Not Support  arbel-evb
	Copy Data To BMC  ${DIR_SCRIPT}/${BOARD}/${CPLD_READID}  /tmp

	${start}=  Get Time  epoch
	${stress_time_sec}=  Convert Time  ${STRESS_TIME}
	Rprint Vars  stress_time_sec
	${cmd}=  Catenate  loadsvf -d /dev/${JTAG_DEV} -s /tmp/${CPLD_READID}
	FOR  ${count}  IN RANGE  1  99999
		${output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}  quiet=1
		Should Not Contain  ${stderr}  tdo check error
		${now}=  Get Time  epoch
		${diff}=  Evaluate  ${now} - ${start}
		Exit For Loop If    ${diff} > ${stress_time_sec}
	END

JTAGM Program CPLD Test
	[Documentation]  Test Program CPLD.
	[Tags]  Stress Test  Onboard  HWsetup  JTAGM  Arbel

	Pass Test If Not Support  arbel-evb
	Copy Data To BMC  ${DIR_SCRIPT}/${BOARD}/${PROGRAM_CPLD}  /tmp

	${start}=  Get Time  epoch
	${stress_time_sec}=  Convert Time  ${STRESS_TIME}
	Rprint Vars  stress_time_sec
	${cmd}=  Catenate  loadsvf -d /dev/${JTAG_DEV} -s /tmp/${PROGRAM_CPLD}
	FOR  ${count}  IN RANGE  1  99999
		${output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}  quiet=1
		Should Not Contain  ${stderr}  tdo check error
		${now}=  Get Time  epoch
		${diff}=  Evaluate  ${now} - ${start}
		Exit For Loop If    ${diff} > ${stress_time_sec}
	END

CPU Stress Test
	[Documentation]  CPU stress test by running drystone
	[Tags]  Stress Test  Onboard  CPU

	# @{args}:
	# 10000000 => run 10 seconds
	# 500000   => stop and wait 0.5 second
	Run Stress Test Script And Verify  10000000  500000
	...  script=${CPU_SCRIPT}

RNG Stress Test
	[Documentation]  Test Random generator by ent tool
	[Tags]  Stress Test  Onboard  RNG

	Run Stress Test Script And Verify
	...  script=${RNG_SCRIPT}

ADC Stress Test
	[Documentation]  Test ADC by access sysfs
	[Tags]  Stress Test  Onboard  ADC

	# @{args}:
	# example 4  2  1024  1820  1760
	# 4 => use adc 4
	# 2 => the reference voltage to calculate real voltage
	# 1024 => resolution for ADC raw data
	# [1820 1760] => the expected voltage boundary, fail if out of boundary
	Check Empty Variables  ADC_CHANNEL  ADC_REF_VOLT  ADC_RESOLUTION
	...  ADC_UP_BOUND  ADC_LOW_BOUND    msg=ADC vars cannot be empty
	Run Stress Test Script And Verify  ${ADC_CHANNEL}  ${ADC_REF_VOLT}
	...  ${ADC_RESOLUTION}  ${ADC_UP_BOUND}  ${ADC_LOW_BOUND}
	...  script=${ADC_SCRIPT}

GPIO Stress Test
	[Documentation]  Random set up gpio value and verify value
	[Tags]  Stress Test  Onboard  GPIO

	Should Not Be Empty  ${GPIO_PINS}  msg=gpio pins must defined
	# copy test binary to DUT
	Copy Data To BMC  ${DIR_SCRIPT}/${BOARD}/${GPIO_STRESS_BIN}  /tmp
	# @{args}:
	# example -1  4000  8000 1 10 1000 22  23
	# [4000  8000] => the test delay ms range
	# 1  => edge, IRQ_TYPE_EDGE_RISING	1, not used currently
	# 10 => Iterations
	# 1000 => msSleep, each iterations delay
	# 22 => gpio out
	# 23 => gpio in
	@{pairs}=  Make GPIO Pin Pairs
	Run Multiple Stress Test Scripts And Verify  -1  4000  8000
	...  1 10 1000  script=${GPIO_STRESS}
	...  var_list=${pairs}   state_fn=Get Gpio State File

Primary Interface Net Stress Test
	[Documentation]  Test network by iperf3 via RGMII
	[Tags]  Stress Test  Network  Onboard  Gmac  RGMII  eth1

	Net Stress Test  ${NET_PRIMARY_IP}  ${NET_PRIMARY_INTF}  ${NET_PRIMARY_THR}
	# kill iperf server after test finish
	[Teardown]  Net Test Teardown

RMII Net Stress Test
	[Documentation]  Test network by iperf3 via RMII
	[Tags]  Stress Test  Network  Onboard  RMII

	Secondary Interface Net Stress Test
	...  ${NET_SECONDARY_IP}[0]  ${NET_SECONDARY_INTF}[0]  ${NET_SECONDARY_THR}[0]
	[Teardown]  Net Test Teardown

SGMII Net Stress Test
	[Documentation]  Test network by iperf3 via SGMII
	[Tags]  Stress Test  Network  Onboard  SGMII  Arbel

	${length}=  Get Length  ${NET_SECONDARY_INTF}
	Pass Execution If  ${length} < 2
	...  This board:${BOARD} does not support SGMII test, just ignore.
	Secondary Interface Net Stress Test
	...  ${NET_SECONDARY_IP}[1]  ${NET_SECONDARY_INTF}[1]  ${NET_SECONDARY_THR}[1]
	[Teardown]  Net Test Teardown

FIU Stress Test
	[Documentation]  Test FIU by read write SPI flash
	[Tags]  Stress Test  Storage  Onboard  SPI

	# mount parition first
	# Mount SPI  mtdn
	# @{args}:
	# example -1  4000  8000  2  6  /mnt/flash/mtd6  /tmp/flash/mtd6  2  0
	# -1 => unlimit execute
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
	${tmp_folder}=  Replace String  ${folder}  var  tmp
	Log  test folders ${folder} ${tmp_folder}
	Run Stress Test Script And Verify  -1  4000  8000  2  6
	...  ${folder}  ${tmp_folder}  2  0
	...  script=${DD_SCRIPT}
	Sleep  3
	#Unmount Folder  ${folder}
	[Teardown]  Storage Test Teardown

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
	${tmp_folder}=  Replace String  ${folder}  var  tmp
	Log  test folders ${folder} ${tmp_folder}
	Run Stress Test Script And Verify  -1  4000  8000  4  10
	...  ${folder}  ${tmp_folder}  10  0  0x100000
	...  script=${DD_SCRIPT}
	Sleep  3
	#Unmount Folder  ${folder}
	[Teardown]  Storage Test Teardown

USB Host Stress Test
	[Documentation]  Test USB host by read write USB mass storage
	[Tags]  Stress Test  Storage  USB  UDC

	# @{args}:
	# example -1  4000  8000  5  10  /mnt/usb/p1   /tmp/usb/p1  100  0

	# Note. we should format and partition flash before mount it!
	${folder}=  Prepare Mount Folder  flash=usb  device=${USB_DEV}
	${tmp_folder}=  Replace String  ${folder}  var  tmp
	Log  test folders ${folder} ${tmp_folder}
	Run Stress Test Script And Verify  -1  4000  8000  5  10
	...  ${folder}  ${tmp_folder}  100  0  0x100000
	...  script=${DD_SCRIPT}
	Sleep  3
	[Teardown]  Storage Test Teardown

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
	Copy Data To BMC  ${DIR_SCRIPT}/${BOARD}/${I2C_STRESS_BIN}  /tmp
	# @{args}:
	# I2C bus as master,  2
	# I2C bus as slave,   1
	# I2C eeprom address, 0x64

	Run Stress Test Script And Verify
	...  ${I2C_MASTER}  ${I2C_SALVE}  ${I2C_EEPROM_ADDR}
	...  script=${I2C_SCRIPT}
	[Teardown]  Run Keywords  Simple Get Test State information  Collect Log On Test Case Fail

TPM Stress Test
	[Documentation]  TPM stress test
	[Tags]  Stress Test  Onboard  HWsetup  TPM

	${start}=  Get Time  epoch
	${stress_time_sec}=  Convert Time  ${STRESS_TIME}
	Rprint Vars  stress_time_sec
	FOR  ${count}  IN RANGE  1  99999
		Test Script And Verify  ${TPM_SCRIPT}  @{BOARD_SUPPORTED}  quiet=1
		${now}=  Get Time  epoch
		${diff}=  Evaluate  ${now} - ${start}
		Exit For Loop If    ${diff} > ${stress_time_sec}
	END

Cerberus Stress Test
	[Documentation]  Cerberus stress test
	[Tags]  Stress Test  Onboard  HWsetup  Cerberus

	${start}=  Get Time  epoch
	${stress_time_sec}=  Convert Time  ${STRESS_TIME}
	Rprint Vars  stress_time_sec
	FOR  ${count}  IN RANGE  1  99999
		Test Script And Verify  ${CERBERUS_SCRIPT}  @{BOARD_SUPPORTED}  quiet=1
		${now}=  Get Time  epoch
		${diff}=  Evaluate  ${now} - ${start}
		Exit For Loop If    ${diff} > ${stress_time_sec}
	END

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
    [Arguments]  ${script}  @{BOARDS}  ${quiet}=0

    # Description of argument(s):
    # ${script}    test script path
    # @{BOARDS}    this test support boards

    Pass Test If Not Support  @{BOARDS}
    Copy Data To BMC  ${DIR_SCRIPT}/${BOARD}/${script}    /tmp
    ${stdout}  ${stderr}  ${rc}=
    ...  BMC Execute Command  /bin/bash /tmp/${script}  quiet=${quiet}
    Should Be Empty  ${stderr}
    Should Not Be Empty  ${stdout}  msg=Must print information during run script
    Should Be Equal    ${rc}    ${0}

Basic Suite Setup
    [Documentation]  this basic test suite setup function

	Load Board Variables
	Run Keyword If  '${CHECK_TOOLS}' == '${True}'
	...  Check DUT Environment  @{TEST_TOOLS}

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
