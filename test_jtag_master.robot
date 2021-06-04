*** Settings ***
Documentation    Module to test npcmxxx JTAG Master.

Resource         lib/log_collector.robot
Resource         lib/resource.robot
Resource         lib/test_utils.robot

Suite Setup      Suite Setup Execution

*** Variables ***
${wrong_cpld}         0
${program_cpld}       0
# TODO: remove after get CPLD FW ready
${SKIP_VER_VERIFY}    1

*** Test Cases ***

Test Read CPLD ID
    [Documentation]  Test Read CPLD ID.
    [Tags]  Test_Read_CPLD_ID  CPLD

    Pass Test If Not Support  arbel-evb
    Copy Data To BMC  ${readid_svf}  /tmp
    ${cmd}=  Catenate  loadsvf -d ${jtag_dev} -s /tmp/${readid_svf}
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    Set Global Variable  ${wrong_cpld}  1
    Should Not Contain  ${stderr}  tdo check error
    Set Global Variable  ${wrong_cpld}  0


Test Program CPLD
    [Documentation]  Test Program CPLD.
    [Tags]  Test_Program_CPLD  CPLD

    Pass Test If Not Support  arbel-evb
    Pass Execution If  ${wrong_cpld}==1  Wrong CPLD chip
    Pass Execution If  ${program_cpld}==0  Skip programming CPLD

    #Program CPLD  ${cpld_firmware2}  ${firmware_version2}
    # we get only one firmware now, just test program progress
    Program CPLD  ${cpld_firmware1}  ${firmware_version1}

Test Hello World
    [Documentation]  Hello world
    [Tags]  Hello

    Log  Hello world!

*** Keywords ***
Get CPLD Files
    [Documentation]  SCP Get File.
    [Arguments]      @{files}

    # Description of argument(s):
    # filename   The file to be downloaded.

    Check Empty Variables   SFTP_SERVER   SFTP_USER
    ...  msg=SFTP server parameters must set
    Get Files From SFTP Server  ${SFTP_SERVER}  ${SFTP_USER}  /tftpboot
    ...  @{files}

Suite Setup Execution
    [Documentation]  Suite Setup Exection.

    Load Board Variables
    Check DUT Environment  loadsvf
    # if not set TEST_PROGRAM_CPLD, only perform read CPLD ID test
    ${status}=  Run Keyword And Return Status  Variable Should Exist
    ...  ${TEST_PROGRAM_CPLD}
    ${value}=  Set Variable if  ${status} == ${TRUE}  ${TEST_PROGRAM_CPLD}  0
    Set Global Variable  ${program_cpld}  ${value}

    ${code_base_dir_path}=  Get Code Base Dir Path
    ${cpld_json}=  Evaluate
    ...  json.load(open('${code_base_dir_path}data/cpld.json'))  modules=json

    # Note: must get right svf file
    Set Suite Variable  ${cpld_firmware1}       ${cpld_json["npcm8xx"]["cpld"]["fw1"]}
    Set Suite Variable  ${cpld_firmware2}       ${cpld_json["npcm8xx"]["cpld"]["fw2"]}
    Set Suite Variable  ${firmware_version1}    ${cpld_json["npcm8xx"]["cpld"]["fw1ver"]}
    Set Suite Variable  ${firmware_version2}    ${cpld_json["npcm8xx"]["cpld"]["fw2ver"]}
    Set Suite Variable  ${readusercode_svf}     ${cpld_json["npcm8xx"]["cpld"]["readusercode"]}
    Set Suite Variable  ${readid_svf}           ${cpld_json["npcm8xx"]["cpld"]["readid"]}
    Set Suite Variable  ${jtag_dev}             ${cpld_json["npcm8xx"]["jtag_dev"]}
    Set Suite Variable  ${power_cycle_cmd}      ${cpld_json["npcm8xx"]["power_cycle_cmd"]}

    Get CPLD Files  ${readid_svf}
    Run KeyWord If  ${program_cpld} == 1
    ...    Get CPLD Files    ${readusercode_svf}  ${cpld_firmware1}  ${cpld_firmware2}
    Sleep  1s

Program CPLD
    [Documentation]  Program CPLD.
    [Arguments]      ${svf_file}  ${version}

    # Description of argument(s):
    # svf_file   The firmware file.
    # version    The firmware version.

    Copy Data To BMC  ${svf_file}  /tmp
    ${cmd}=  Catenate  loadsvf -d ${jtag_dev} -s /tmp/${svf_file}
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    Should Not Contain  ${stderr}  tdo check error
    Pass Execution If  ${SKIP_VER_VERIFY} == 1
    ...    CPLD firmware not ready for verify version

    # control hot swap controller to power cycle whole system
    BMC Execute Command  ${power_cycle_cmd}  ignore_err=1  fork=1

    Sleep  10s
    Run Keyword  Wait For Host To Ping  ${OPENBMC_HOST}  5 mins
    Copy Data To BMC  ${readusercode_svf}  /tmp
    ${cmd}=  Catenate  loadsvf -d ${jtag_dev} -s /var/${readusercode_svf}
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    Should Contain  ${output}  ${version}
