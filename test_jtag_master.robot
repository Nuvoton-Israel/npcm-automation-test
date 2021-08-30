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

    Program CPLD  ${cpld_firmware}


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
    Set Suite Variable  ${cpld_firmware}       ${cpld_json["npcm8xx"]["cpld"]["fw"]}
    Set Suite Variable  ${readid_svf}           ${cpld_json["npcm8xx"]["cpld"]["readid"]}
    Set Suite Variable  ${jtag_dev}             ${cpld_json["npcm8xx"]["jtag_dev"]}

    Get CPLD Files  ${readid_svf}
    Run KeyWord If  ${program_cpld} == 1
    ...    Get CPLD Files    ${cpld_firmware}
    Sleep  1s

Program CPLD
    [Documentation]  Program CPLD.
    [Arguments]      ${svf_file}

    # Description of argument(s):
    # svf_file   The firmware file.

    Copy Data To BMC  ${svf_file}  /tmp
    ${cmd}=  Catenate  loadsvf -d ${jtag_dev} -s /tmp/${svf_file}
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    Should Not Contain  ${stderr}  tdo check error

