*** Settings ***
Documentation   Helper for collect log for failed cases

Library         OperatingSystem
Library         openbmc_ffdc_list.py
Resource        log_collector_utils.robot
Resource        resource.robot
Resource	    common_utils.robot  # ping function
Resource        openbmc_ffdc_methods.robot
Resource        dump_utils.robot
Resource        logging_utils.robot

*** Variables ***
${PRINT_LINE}      ------------------------------------------------------------------------
${FOOTER_MSG}      ${\n}${PRINT_LINE} ${\n}
${MSG_INTRO}       This report contains the following information:


*** Keywords ***
Test Setup Info
    [Documentation]      BMC IP, Model and other information

    Write Data To File  ${\n}-----------------------${\n}
    Write Data To File  Test Setup Information:
    Write Data To File  ${\n}-----------------------${\n}
    Write Data To File  OPENBMC HOST \t: ${OPENBMC_HOST}${\n}
    ${model_name}=  Get BMC System Model
    Write Data To File  SYSTEM TYPE \t: ${model_name}

Write Cmd Output to FFDC File
    [Documentation]      Write cmd output data to the report document
    [Arguments]          ${name_str}   ${cmd}

    Write Data To File   ${FOOTER_MSG}
    Write Data To File   ${ENTRY_INDEX.upper()} : ${name_str}\t
    Write Data To File   Executed : ${cmd}
    Write Data To File   ${FOOTER_MSG}

Run Collect Log
    [Documentation]     log collector main process

    # check we can connect DUT first
    ${l_ping}=   Run Keyword And Return Status
    ...    Ping Host  ${OPENBMC_HOST}
    Return From Keyword If  '${l_ping}' == '${False}'
    ...    Log  Cannot access DUT, collect log fail

    Log  Starting collect DUT fail log  console=${True}
    Set Default Variable
    Log  ${LOG_PATH}, ${TEST_LOG_DIR}  console=${True}
    Create Log Directory
    Log   INFO_FILE: ${INFO_FILE}  console=${True}

    Test Setup Info
    Write Data To File  ${\n}${MSG_INTRO}${\n}
    ${ffdc_file_list}=  Create List  ${INFO_FILE}

    Call FFDC Methods

    [Return]  ${ffdc_file_list}

Collect Log On Test Case Fail
    [Documentation]  Log collector entry point, from OpenBMC_ffdc.
    [Arguments]  ${clean_up}=${TRUE}

    Run Keyword If  '${TEST_STATUS}' == 'FAIL'  Run Collect Log
    Log Test Case Status

    Run Keyword If  '${TEST_STATUS}' == 'FAIL' and ${clean_up}
    ...  Run Keywords  Delete All Error Logs  AND  Delete All Dumps
