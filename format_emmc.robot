*** Settings ***
Documentation	Format eMMC tool
Resource	lib/test_utils.robot
Resource	lib/resource.robot
Suite Setup		Check DUT Environment

*** Variables ***
# test scripts
${FDISK_EMMC_SCRIPT}     fdisk_emmc.sh

*** Test Cases ***
# usage: robot format_emmc.robot
Format Emmc
	[Documentation]  run format eMMC script
	[Tags]  eMMC  Format

    Copy Data To BMC  ${DIR_SCRIPT}/${FDISK_EMMC_SCRIPT}    /tmp
    ${cmd}=  Catenate  /bin/bash /tmp/${FDISK_EMMC_SCRIPT}
    BMC Execute Command  ${cmd}  print_out=${1}