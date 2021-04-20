*** Settings ***
Documentation	Utilities for unit test and stress test

Library		bmc_ssh_utils.py
Library		gen_cmd.py
Library		SCPLibrary    WITH NAME   scp
Library		String
Library		OperatingSystem
Resource	resource.robot


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

    Open Connection for SCP
    Log    Copying ${source} to ${dest}
    scp.Put File    ${source}    ${dest}
    Close Connection

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
    ${cmd}=  Set Variable  sleep ${exec_time} && touch /tmp/stop_stress_test
    # run keywords need "AND" to separate echo KW+ARGs
    Run Keyword If  ${bmc}  Run Keywords
    ...    BMC Execute Command  rm -f /tmp/stop_stress_test  AND
    ...    BMC Execute Command  ${cmd}  fork=${1}
    ...  ELSE  Run Keywords
    ...    Shell Cmd  rm -f /tmp/stop_stress_test  AND
    ...    Shell Cmd  ${cmd}  fork=${1}


Run Stress Test Script And Verify
    [Documentation]  run stress test script and check result
    [Arguments]  @{args}  ${script}  ${exec_time}  ${timeout}  ${bmc}=True
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

Start Iperf Server
    [Documentation]  run iperf3 and return popen object

    ${popen}=  Shell Cmd  iperf3 -s  fork=${1}
    Should Be True    ${popen.returncode} is ${None}
    [Return]  ${popen}

Kill Process By Handle
    [Documentation]  kill process by popen handle object
    [Arguments]  ${popen}

    # Description of argument(s):
    # @{popen}      the popen object created by fork subprocess

    ${shell_rc}=  Kill Cmd  popen=${popen}

Kill Process
    [Documentation]  kill process by pid
    [Arguments]  @{pids}

    # Description of argument(s):
    # @{pids}       the pid we want to kill

    ${pid_list}=  Catenate  @{pids}
    ${shell_rc}  ${stdout}=  Shell Cmd  kill -s SIGTERM ${pid_list}
    Should Be Equal    ${shell_rc}    ${0}

Kill Process By name
    [Documentation]  kill process by process name
    [Arguments]  ${name}

    # Description of argument(s):
    # ${name}       the process name we want to kill

    ${cmd}=  Catenate  pgrep iperf
    ${rc}  ${output}=  Run And Return Rc And Output  ${cmd}
    Return From Keyword If  '${output}' == '${EMPTY}'
    ${pids}=  Replace String  ${output}  ${\n}  ${SPACE}
    Log  kill process: ${pids}
    OperatingSystem.Run  kill -9 ${pids}


Create Log Folder
    [Documentation]  create log folder for stress test access

    BMC Execute Command  mkdir -v ${DIR_STAT}  ignore_err=${1}

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
    ${cmd}=  Catenate  mount -t vfat /dev/${device}  ${folder}
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
    Log  "state file: " ${stat_file}
    ${cmd}=  Set Variable  cat ${stat_file} | grep -o failed.* | awk '{print $2}'
    ${failed_count}  ${stderr}  ${rc}=
    ...  BMC Execute Command  cmd_buf=${cmd}
    Should Be Equal  ${failed_count}  0  msg=failed count must be zero

Set Emac IP address
    [Documentation]  Set up emac IP address via SSH from gamc
    [Arguments]  ${ip_address}

    ${cmd}=  Catenate  /sbin/ifconfig eth0 ${ip_address}
    ${stdout}  ${stderr}  ${rc}=
    ...  BMC Execute Command  ${cmd}  ignore_err=${1}
    Log  rc: ${rc}, out: ${stdout}, err: ${stderr}
    Sleep  5
    Wait For Host To Ping  ${ip_address}


Wait For Host To Ping
    [Documentation]  Wait for the given host to ping.
    [Arguments]  ${host}  ${timeout}=30 sec  ${interval}=5 sec

    # Description of argument(s):
    # host      The host name or IP of the host to ping.
    # timeout   The amount of time after which ping attempts cease.
    #           This should be expressed in Robot Framework's time format
    #           (e.g. "10 seconds").
    # interval  The amount of time in between attempts to ping.
    #           This should be expressed in Robot Framework's time format
    #           (e.g. "5 seconds").

    Wait Until Keyword Succeeds
    ...  ${timeout}  ${interval}  Ping Host  ${host}

Ping Host
    [Documentation]  Ping the given host.
    [Arguments]     ${host}

    # Description of argument(s):
    # host      The host name or IP of the host to ping.

    Should Not Be Empty    ${host}   msg=No host provided
    ${RC}   ${output}=     Run and return RC and Output    ping -c 4 ${host}
    Log     RC: ${RC}\nOutput:\n${output}
    Should be equal     ${RC}   ${0}

Check DUT Environment
	[Documentation]  check DUT image contains necessary tools

	# BMC Execute Command  env  print_out=${1}
	${cmd}=  Catenate  PATH=$PATH:/usr/sbin:/sbin which   @{TEST_TOOLS}
	${stdout}  ${stderr}  ${rc}=
    ...  BMC Execute Command  ${cmd}  print_out=${0}
	Should Be Equal    ${rc}    ${0}