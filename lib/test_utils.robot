*** Settings ***
Documentation	Utilities for unit test and stress test

Library		bmc_ssh_utils.py
Library		gen_cmd.py
Library		SCPLibrary    WITH NAME   scp
Library		String
Library		OperatingSystem
Library		DateTime
Resource	resource.robot
Resource	ssh_utils.robot


*** Keywords ***
Open Connection for SCP
    [Documentation]  Open a connection for SCP.
    Run Keyword If  '${SSH_PORT}' == '${EMPTY}'  scp.Open connection  ${OPENBMC_HOST}
    ...  username=${OPENBMC_USERNAME}  password=${OPENBMC_PASSWORD}
    ...  ELSE   Run Keyword    scp.Open connection  ${OPENBMC_HOST}  port=${SSH_PORT}
    ...  username=${OPENBMC_USERNAME}  password=${OPENBMC_PASSWORD}


Copy Data To BMC
    [Documentation]  Copy data to BMC
    [Arguments]  ${source}  ${dest}

    OperatingSystem.File Should Exist  ${source}
    Open Connection for SCP
    Log    Copying ${source} to ${dest}
    scp.Put File    ${source}    ${dest}
    scp.Close Connection

Run Script With Args On BMC
    [Documentation]  run script with arguments on BMC
    [Arguments]  @{args}  ${script}

    Copy Data To BMC  ${DIR_SCRIPT}/${script}    /tmp
    ${cmd}=  Catenate  /tmp/${script}   @{args}
    Log  Execute command: ${cmd}
    ${stdout}  ${stderr}  ${rc}=
    ...  BMC Execute Command  ${cmd}  print_out=${0}
    [Return]  ${rc}  ${stdout}  ${stderr}

Run Script With Args On PC
    [Documentation]  run script with arguments on PC
    [Arguments]  @{args}  ${script}

    OperatingSystem.Copy File  ${DIR_SCRIPT}/${script}    /tmp
    ${cmd}=  Catenate  bash /tmp/${script}   @{args}
    Log  Execute command: ${cmd}
    ${rc}  ${stdout}  ${stderr}=
    ...  Shell Cmd   ${cmd}  return_stderr=${1}
    [Return]  ${rc}  ${stdout}  ${stderr}

Setup Monitor
    [Documentation]  set timer for set stop signal
    [Arguments]  ${exec_time}  ${bmc}=True

    # Description of argument(s):
    # ${exec_time}  the executing time
    # ${bmc}        set up timer on bmc or PC when set False
    ${exec_time_sec}=  Convert Time  ${exec_time}
    ${cmd}=  Set Variable  sleep ${exec_time_sec} && touch /tmp/stop_stress_test
    # run keywords need "AND" to separate echo KW+ARGs
    Run Keyword If  ${bmc}  Run Keywords
    ...    BMC Execute Command  rm -f /tmp/stop_stress_test  AND
    ...    BMC Execute Command  ${cmd}  fork=${1}
    ...  ELSE  Run Keywords
    ...    Shell Cmd  rm -f /tmp/stop_stress_test  AND
    ...    Shell Cmd  ${cmd}  fork=${1}


Run Stress Test Script And Verify
    [Documentation]  run stress test script and check result
    [Arguments]  @{args}  ${script}  ${exec_time}=${STRESS_TIME}
    ...  ${timeout}=${TIMEOUT_TIME}  ${bmc}=True
    [Timeout]    ${timeout}

    # Description of argument(s):
    # @{args}       the argurments for run script
    # ${script}     test script path
    # ${exec_time}  how much time we should set stop flag to script
    #               please note the script will not terminate immediately when we ask it to stop
    # ${timeout}    how much time we consider the test is timeout fail
    # ${bmc}        run script on BMC, or run on PC is set False

    Setup Monitor  ${exec_time}  ${bmc}
    ${rc}  ${stdout}  ${stderr}=  Run Keyword If  ${bmc}
    ...    Run Script With Args On BMC  @{args}  script=${script}
    ...  ELSE
    ...    Run Script With Args On PC  @{args}  script=${script}
    # Should Be Empty  ${stderr} # some process will generate stderr, just check rc
    Should Not Be Empty  ${stdout}  msg=Must print information during run script
    Should Be Equal    ${rc}    ${0}
    # Check the failed count from log state (xxx_stress.xxx.stat)
    Run Keyword If    ${bmc}    Check Fail In State File  ${stdout}

Start Remote Iperf Server
    [Documentation]  run iperf3 on remote PC

    ${msg}=  Set Variable  Iperf server IP, user name and password should not be empty.
    Should Not Be Empty  ${IPERF_SERVER}  msg=${msg}
    Should Not Be Empty  ${IPERF_USER}  msg=${msg}
    Should Not Be Empty  ${IPERF_PASSWD}  msg=${msg}
    PC Execute Command  iperf3 -s      fork=${1}
    ...  ip=${IPERF_SERVER}  user=${IPERF_USER}  passwd=${IPERF_PASSWD}
    Sleep  1
    # make fail if cannot start iperf server
    PC Execute Command  pgrep iperf3
    ...  ip=${IPERF_SERVER}  user=${IPERF_USER}  passwd=${IPERF_PASSWD}

PC Kill Process By name
    [Documentation]  kill process by process name on remote PC
    [Arguments]  ${name}

    # Description of argument(s):
    # ${name}       the process name we want to kill

    ${cmd}=  Catenate  pkill -9 -e iperf
    # check PC parameters are valid
    ${is_bad}=  Evaluate  len("${IPERF_SERVER}") == 0 or len("${IPERF_USER}") == 0 or len("${IPERF_PASSWD}") == 0
    Return From Keyword If  ${is_bad}
    ${stdout}  ${stderr}  ${rc}=
    ...  PC Execute Command  ${cmd}  ip=${IPERF_SERVER}
    ...    user=${IPERF_USER}  passwd=${IPERF_PASSWD}  ignore_err=${1}

Mount SPI Folder
    [Documentation]  mount SPI flash to folder
    [Arguments]  ${device}

    # Description of argument(s):
    # ${device}     the SPI flash device, like mtdblock6
    # in currnet DTS, SPI2.0 MTD(0~5) SPI2.1 MTD(6~7) SPI3.0 MTD(8)

    ${folder}=  Remove String  ${device}  block
    ${folder}=  Set Variable  /mnt/flash/${folder}
    Log  Mount point: ${folder}
    Clean Mounted Folder    ${folder}
    BMC Execute Command    mkdir -vp ${folder}  ignore_err=${1}
    # note, BMC Execute Command will report error if rc != 0 unless we set ignore_err
    ${cmd}=  Catenate  mount -t jffs2 /dev/${device}  ${folder}
    BMC Execute Command  ${cmd}
    [Return]  ${folder}

Mount USB Folder
    [Documentation]  mount USB storage to folder
    [Arguments]  ${device}

    # Description of argument(s):
    # ${device}     the USB storage device, like sda1

    ${folder}=  Set Variable  /mnt/usb/p1
    Log  Mount point: ${folder}
    Clean Mounted Folder    ${folder}
    BMC Execute Command    mkdir -vp ${folder}  ignore_err=${1}
    ${cmd}=  Catenate  mount -t ext4 /dev/${device}  ${folder}
    BMC Execute Command  ${cmd}
    [Return]  ${folder}

Mount EMMC Folder
    [Documentation]  mount eMMC device to folder
    [Arguments]  ${device}

    # Description of argument(s):
    # ${device}     the eMMC flash device, like mmcblk0p1

    ${folder}=  Set Variable  /mnt/emmc/p1
    Log  Mount point: ${folder}
    Clean Mounted Folder    ${folder}
    BMC Execute Command    mkdir -vp ${folder}  ignore_err=${1}
    ${cmd}=  Catenate  mount -t ext4 /dev/${device}  ${folder}
    BMC Execute Command  ${cmd}
    [Return]  ${folder}

Prepare Mount Folder
    [Documentation]  create folder and mount device
    [Arguments]  ${flash}  ${device}

    # Description of argument(s):
    # ${flash}      flash type, should be one of spi, usb, or emmc
    # ${device}     the device name, which can be access under /dev/
    #
    # mount ex: eMMC/SPI/USB
    # mount -t jffs2 /dev/mtdblock6 /mnt/flash/mtd6
    # mount -t ext4 /dev/mmcblk0p1 /mnt/emmc/p1
    # mount -t vfat /dev/sda1 /mnt/usb/p1
    Should Not Be Empty  ${device}
    ${folder}=  Run Keyword If  '${flash}' == 'spi'
    ...     Mount SPI Folder  ${device}
    ...  ELSE IF  '${flash}' == 'usb'
    ...     Mount USB Folder  ${device}
    ...  ELSE IF  '${flash}' == 'emmc'
    ...     Mount EMMC Folder  ${device}
    ...  ELSE
    ...     Fail  msg=flash must be one of spi, usb, or emmc
    [Return]  ${folder}

Unmount Folder
    [Documentation]  unmount folder
    [Arguments]  ${folder}

    # Description of argument(s):
    # ${folder}     the folder mounted storage device

    BMC Execute Command    umount ${folder}
    BMC Execute Command    rm -rf ${folder}

Clean Mounted Folder
    [Documentation]  unmount folder if it mounted
    [Arguments]  ${folder}

    # Description of argument(s):
    # ${folder}     the folder mount storage device

    ${stdout}  ${stderr}  ${rc}=  BMC Execute Command
    ...  mount | grep ${folder}    ignore_err=${1}
    Run Keyword If  '${rc}' == '${0}'
    ...  Unmount Folder   ${folder}

Find UDC On PC
    [Documentation]  unmount folder if it mounted

    # usb device vid:pid fixed to 1d6b:0104
    ${rc}  ${stdout}=  Shell Cmd
    ...  lsusb -d 1d6b:0104  ignore_err=${1}
    # try to enable usb gadget service to connect udc
    ${cmd}=  Catenate  systemctl start usb_emmc_storage.service
    Run Keyword If  '${rc}' == '${1}'   Run Keywords
    ...  BMC Execute Command  ${cmd}   AND
    ...  Sleep 10    AND
    # try to access again
    ...  Shell Cmd
    ...    lsusb -d 1d6b:0104  ignore_err=${0}

    # check dev path
    Shell Cmd
    ...  ls /dev/${UDC_DEV}  ignore_err=${0}
    # check mount point
    # robot cannot auto mount it, so error when not mouted
    ${rc}  ${stdout}=  Shell Cmd
    ...  mount | grep ${UDC_DEV}    ignore_err=${0}
    ${rc}  ${udc_path}=  Shell Cmd
    ...  echo '${stdout}' | awk '{print $3}'    ignore_err=${0}
    [Return]   ${udc_path}

Check Fail In State File
    [Documentation]  check there is any error while stress test
    [Arguments]  ${stdout}

    # find state file from stdout
    ${rc}  ${stat_file}=  Shell Cmd
    ...  echo '${stdout}' | grep Statefile | awk '{print $2}' | tr -d '\n'
    Should Not Be Empty  ${stat_file}
    Set Test Variable  ${STATE_FILE}  ${stat_file}
    Log  state file: ${stat_file}
    ${cmd}=  Set Variable  cat ${stat_file} | grep -o failed.* | awk '{print $2}'
    ${failed_count}  ${stderr}  ${rc}=
    ...  BMC Execute Command  cmd_buf=${cmd}
    ${err_msg}=  Set Variable  'failed count must be zero'
    ${msg}=  Set Variable IF  "${stderr}" != "${EMPTY}"
    ...  ${err_msg}, error: ${stderr}
    ...  ${err_msg}
    Should Be Equal  ${failed_count}  0  msg=${msg}

Get State Speed Information
    [Documentation]  utility for get speed information from state file
    [Arguments]  ${file}  ${keyword}

    # Description of argument(s):
    # ${file}       the state file we want get information
    # ${keyword}    the speed keyword we want to get

    ${cmd}=  Catenate  cat ${file} |
    ...  grep -oE "${keyword}.[0-9.]+" | grep -oE "[0-9.]+"
    ${res}  ${stderr}  ${rc}=
    ...  BMC Execute Command  cmd_buf=${cmd}  ignore_err=${1}  time_out=${10}
    ${res}=  Set Variable If  '${rc}' != '${0}'  unknown  ${res}
    [Return]  ${res}

Get Net Test State information
    [Documentation]  get net test speed information

    Return From Keyword If  '${STATE_FILE}' == '${EMPTY}'
    ...  msg=Skip get more information because get state file failed

    ${rms_bandwidth}=  Get State Speed Information  ${STATE_FILE}  rms_bandwidth
    ${min_bandwidth}=  Get State Speed Information  ${STATE_FILE}  minimal_bandwidth
    ${test_run}=  Get State Speed Information  ${STATE_FILE}  tests.run
    ${message}=  Catenate  RMS bandwidth: ${rms_bandwidth},
    ...  minimal bandwidth: ${min_bandwidth},
    ...  thredshold: ${TEST_THRESHOLD} Mbits/sec, test runs: ${test_run}
    Set Test Message  ${message}  append=yes

Net Test Teardown
    [Documentation]  teardown function for net test

    Get Net Test State information
    PC Kill Process By name    iperf

Get Storage Test State information
    [Documentation]  get storage test speed information

    Return From Keyword If  '${STATE_FILE}' == '${EMPTY}'
    ...  msg=Skip get more information because get state file failed
    ${rms_write}=  Get State Speed Information  ${STATE_FILE}  rms_write_speed
    ${min_write}=  Get State Speed Information  ${STATE_FILE}  minimal_write_speed
    ${rms_read}=  Get State Speed Information  ${STATE_FILE}  rms_read_speed
    ${min_read}=  Get State Speed Information  ${STATE_FILE}  minimal_read_speed
    ${test_run}=  Get State Speed Information  ${STATE_FILE}  tests.run
    ${message}=  Catenate  RMS write: ${rms_write},
    ...  minimal write: ${min_write}, RMS read: ${rms_read},
    ...  minimal read: ${min_read} MB/s, test runs: ${test_run}
    Set Test Message  ${message}  append=yes

Storage Test Teardown
    [Documentation]  teardown function for storage test
    [Arguments]  ${folder}

    # Description of argument(s):
    # ${folder}     the folder mount storage device
    Clean Mounted Folder  ${folder}
    Get Storage Test State information

Simple Get Test State information
    [Documentation]  get simple test run information

    Return From Keyword If  '${STATE_FILE}' == '${EMPTY}'
    ...  msg=Skip get more information because get state file failed
    ${test_run}=  Get State Speed Information  ${STATE_FILE}  tests.run
    Set Test Message  test runs: ${test_run}  append=yes

Set Secondary Interface IP address
    [Documentation]  Set up IP address via SSH from primary ethernet interface
    [Arguments]  ${ip_address}  ${interface}

    # Description of argument(s):
    # ${ip_address} the ethernet interface IP address
    # ${interface}  the interface we want to test

    Return From Keyword If  '${OPENBMC_HOST}' == '${ip_address}'
    SSHLibrary.Close All Connections
    ${cmd}=  Catenate  /sbin/ifconfig ${interface} ${ip_address}
    ${stdout}  ${stderr}  ${rc}=
    ...  BMC Execute Command  ${cmd}  ignore_err=${1}  time_out=${10}
    Log  rc: ${rc}, out: ${stdout}, err: ${stderr}
    Sleep  5
    Wait For Host To Ping  ${ip_address}

Enable Ethernet Interface
    [Documentation]  disable ethernet interface to aviod test result error
    [Arguments]  ${eth}  ${enable}
    [Timeout]  15

    # Description of argument(s):
    # ${eth}        the ethernet interface
    # ${enable}     enable or set false to disable ethernet interface

    SSHLibrary.Close All Connections
    Sleep  3
    ${cmd}=  Run Keyword If  '${enable}' == '${True}'
    ...    Catenate  /sbin/ifconfig   ${eth}   up
    ...  ELSE
    ...    Catenate  /sbin/ifconfig   ${eth}   down
    BMC Execute Command  ${cmd}  time_out=${10}

Check DUT Environment
    [Documentation]  check DUT image contains necessary tools

    # check board setting first
    Should Contain  ${BOARD_SUPPORTED}  ${BOARD}
    ...  msg=board:${BOARD} is not supported
    # prepare state file folder
    BMC Execute Command  mkdir -v ${DIR_STAT}  ignore_err=${1}  time_out=${10}
    # BMC Execute Command  env  print_out=${1}
    ${cmd}=  Catenate  PATH=$PATH:/usr/sbin:/sbin which   @{TEST_TOOLS}
    ${stdout}  ${stderr}  ${rc}=
    ...  BMC Execute Command  ${cmd}  print_out=${0}  time_out=${10}
    Should Be Equal    ${rc}    ${0}

Net Stress Test
	[Documentation]  Test network interface by iperf3
	[Arguments]  ${IP}  ${interface}  ${thredshold}

	# Description of argument(s):
	# ${IP}         the ethernet interface IP address
	# ${interface}  the interface we want to test
	# ${thredshold} the thredshold speed to pass test

	Start Remote Iperf Server
	Should Not Be Empty  ${IP}
	...  msg=Network interface IP cannot be empty.
	Set Test Variable  ${TEST_THRESHOLD}  ${thredshold}
	# disable secondary interfaces to avoid getting confused result
	@{disable_interfaces}=  Create List
	FOR  ${eth}  IN  @{NET_SECONDARY_INTF}
		Run Keyword If  '${eth}' != '${interface}'
		...  Append To List  ${disable_interfaces}  ${eth}
	END
	Log  disable interfaces: ${disable_interfaces}  console=${True}
	FOR  ${eth}  IN  @{disable_interfaces}
		Enable Ethernet Interface  ${eth}  ${False}
	END
	# set up IP address if not primary interface
	# Note: if not real connect eth to network, this action may cause
	# whole bmc connection hang, restart service systemd-networkd
	# to solve it.
	Run Keyword If  '${NET_PRIMARY_INTF}' != '${interface}'
	...  Set Secondary Interface IP address  ${IP}  ${interface}

	# @{args}:
	# -1 => unlimt execute
	# [1000 2000] => the test delay ms range
	# [8 12] => the test execute second range
	# 400 => the minimal speed (MBits/S) to pass test
	# RGMII_IP => run iperf with bind this IP
	# IPERF_SERVER  => the iperf server IP address
	Run Stress Test Script And Verify  -1  1000  2000
	...  8  12  ${thredshold}  ${IP}  ${IPERF_SERVER}
	...  script=${Net_SCRIPT}
	FOR  ${eth}  IN  @{disable_interfaces}
		Enable Ethernet Interface  ${eth}  ${True}
	END