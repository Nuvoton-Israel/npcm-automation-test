*** Settings ***
Documentation   Utils for log collectos

Library         OperatingSystem
Library         String
Resource        resource.robot

*** Variables ***
${LOG_DIR}          ${EXECDIR}
${LOG_PATH}         ${LOG_DIR}${/}logs
${TEST_HISTORY}     ${LOG_PATH}${/}test_history.txt

${devicetree_base}  /sys/firmware/devicetree/base/model
# bmc info commands
${bmc_file_system_usage_cmd}=  df -h | cut -c 52-54 | grep 100 | wc -l
${total_bmc_ro_file_system_cmd}=  df -h | grep /media/rofs | wc -l
${bmc_cpu_usage_cmd}=   top -n 1  | grep CPU: | cut -c 7-9

*** Keywords ***
Get Test Dir and Name
    [Documentation]    SUITE_NAME and TEST_NAME are automatic variables
    ...                and is populated dynamically by the robot framework
    ...                during execution
    ${suite_name}=     Strip String   ${SUITE_NAME}
    ${suite_name}=     Replace String  ${suite_name}  ${SPACE}  _
    ${suite_name}=     Catenate  SEPARATOR=    ${LOG_TIME}_   ${suite_name}
    ${test_name}=      Strip String   ${TEST_NAME}
    ${test_name}=      Replace String  ${test_name}  ${SPACE}  _
    ${test_name}=      Catenate  SEPARATOR=  ${LOG_TIME}_   ${test_name}
    [Return]  ${suite_name}   ${test_name}

Create Log Directory
    [Documentation]    Creates directory and report file
    Create Directory   ${TEST_LOG_DIR}
    Create Log Report File


Create Log Report File
    [Documentation]     Create a generic log file name
    Set Suite Variable
    ...  ${INFO_FILE}   ${TEST_LOG_DIR}${/}${LOG_TIME}_BMC_general.txt
    Create File         ${INFO_FILE}
    Set Global Variable  ${FFDC_FILE_PATH}  ${INFO_FILE}
    Set Global Variable  ${FFDC_DIR_PATH}  ${TEST_LOG_DIR}


Write Data To File
    [Documentation]     Write data to the report document
    [Arguments]         ${data}=      ${filepath}=${INFO_FILE}
    Append To File      ${filepath}   ${data}


Get Current Time Stamp
    [Documentation]     Get the current time stamp data
    #${cur_time}=    Get Current Date   result_format=%Y-%m-%d %H:%M:%S:%f
    ${cur_time}=    Get Current Date   result_format=%Y%m%d%H%M%S%f
    ${cur_time}=    Strip String   ${cur_time}
    [Return]   ${cur_time}

Set Default Variable
    [Documentation]     Set up some log variable

    ${LOG_TIME}=  Get Current Time Stamp
    Set Global Variable  ${LOG_TIME}
    ${suite_name}  ${test_name}=  Get Test Dir and Name
    Set Global Variable  ${TEST_LOG_DIR}  ${LOG_PATH}/${suite_name}/${test_name}
    Set Global Variable  ${LOG_PREFIX}  ${TEST_LOG_DIR}/${LOG_TIME}_
    Set Global Variable  ${FFDC_PREFIX}  ${LOG_TIME}_