*** Settings ***
Documentation      Methods to execute commands on BMC and collect
...                data to a list of FFDC files

#Resource               openbmc_ffdc_utils.robot
Resource               log_collector_utils.robot
Resource               rest_client.robot
#Resource               utils.robot
Resource               list_utils.robot
Resource               logging_utils.robot
#Resource               bmc_redfish_resource.robot
Library                SSHLibrary
Library                OperatingSystem
Library                Collections
Library                String
Library                gen_print.py
Library                gen_cmd.py
Library                gen_robot_keyword.py
Library                dump_utils.py
Library                logging_utils.py
Library                gen_robot_print.py

*** Variables ***

${FFDC_CMD_TIMEOUT}    240

*** Keywords ***

# Method : Call FFDC Methods                                   #
#          Execute the user define keywords from the FFDC List #
#          Unlike any other keywords this will call into the   #
#          list of keywords defined in the FFDC list at one go #

Call FFDC Methods
    [Documentation]   Call into FFDC Keyword index list.
    [Arguments]  ${ffdc_function_list}=${EMPTY}

    # Description of argument(s):
    # ffdc_function_list  A colon-delimited list naming the kinds of FFDC that
    #                     are to be collected
    #                     (e.g. "FFDC Generic Report:BMC Specific Files").
    #                     Acceptable values can be found in the description
    #                     field of FFDC_METHOD_CALL in
    #                     lib/openbmc_ffdc_list.py.  Those values can be
    #                     obtained via a call to 'Get FFDC Method Desc' (also
    #                     from lib/openbmc_ffdc_list.py).

    @{entries}=  Get FFDC Method Index
    # Example entries:
    # entries:
    #   entries[0]:  BMC LOGS

    @{ffdc_file_list}=  Create List
    FOR  ${index}  IN  @{entries}
      ${ffdc_file_sub_list}=  Method Call Keyword List  ${index}  ${ffdc_function_list}
      ${ffdc_file_list}=  Smart Combine Lists  ${ffdc_file_list}  ${ffdc_file_sub_list}
    END

    Run Key U  SSHLibrary.Close All Connections

    [Return]  ${ffdc_file_list}


Method Call Keyword List
    [Documentation]  Process FFDC request and return a list of generated files.
    [Arguments]  ${index}  ${ffdc_function_list}=${EMPTY}

    # Description of argument(s):
    # index               The index into the FFDC_METHOD_CALL dictionary (e.g.
    #                     'BMC LOGS').
    # ffdc_function_list  See ffdc_function_list description in
    #                     "Call FFDC Methods" (above).

    @{method_list}=  Get FFDC Method Call  ${index}
    # Example method_list:
    # method_list:
    #   method_list[0]:
    #     method_list[0][0]: FFDC Generic Report
    #     method_list[0][1]: BMC FFDC Manifest
    #   method_list[1]:
    #     method_list[1][0]: Get Request FFDC
    #     method_list[1][1]: BMC FFDC Get Requests
    # (etc.)

    # If function list is empty assign default (i.e. a list of all allowable
    # values).  In either case, convert ffdc_function_list from a string to
    # a list.
    @{ffdc_function_list}=
    ...  Run Keyword If  '${ffdc_function_list}' == '${EMPTY}'
    ...    Get FFDC Method Desc  ${index}
    ...  ELSE
    ...    Split String  ${ffdc_function_list}  separator=:

    @{ffdc_file_list}=  Create List
    FOR  ${method}  IN  @{method_list}
      ${ffdc_file_sub_list}=  Execute Keyword Method  ${method[0]}  ${method[1]}  @{ffdc_function_list}
      ${ffdc_file_list}=  Smart Combine Lists  ${ffdc_file_list}  ${ffdc_file_sub_list}
    END

    [Return]  ${ffdc_file_list}


Execute Keyword Method
    [Documentation]  Call into BMC method keywords. Don't let one
    ...              failure skip the remaining. Get whatever data
    ...              it could gather at worse case scenario.
    [Arguments]  ${description}  ${keyword_name}  @{ffdc_function_list}

    # Description of argument(s):
    # description         The description of the FFDC to be collected.  This
    #                     would be any value returned by
    #                     'Get FFDC Method Desc' (e.g. "FFDC Generic Report").
    # keyword_name        The name of the keyword to call to collect the FFDC
    #                     data (again, see FFDC_METHOD_CALL).
    # ffdc_function_list  See ffdc_function_list description in
    #                     "Call FFDC Methods" (above).  The only difference is
    #                     in this case, it should be a list rather than a
    #                     colon-delimited value.

    @{ffdc_file_list}=  Create List

    ${index}=  Get Index From List  ${ffdc_function_list}  ${description}
    Run Keyword If  '${index}' == '${-1}'  Return from Keyword
    ...  ${ffdc_file_list}

    ${status}  ${ffdc_file_list}=  Run Key  ${keyword_name}  ignore=1
    [Return]  ${ffdc_file_list}

# Method : BMC FFDC Manifest                                   #
#          Execute command on BMC and write to ffdc_report.txt #

BMC FFDC Manifest
    [Documentation]  Run the ssh commands from FFDC_BMC_CMD and return a list
    ...              of generated files.

    @{ffdc_file_list}=  Create List  ${FFDC_FILE_PATH}
    @{entries}=  Get FFDC Cmd Index

    FOR  ${index}  IN  @{entries}
      Iterate BMC Command List Pairs  ${index}
    END

    [Return]  ${ffdc_file_list}


Iterate BMC Command List Pairs
    [Documentation]    Feed in key pair list from dictionary to execute
    [Arguments]        ${key_index}

    @{cmd_list}=      Get ffdc bmc cmd    ${key_index}
    Set Suite Variable   ${ENTRY_INDEX}   ${key_index}

    FOR  ${cmd}  IN  @{cmd_list}
      Execute Command and Write FFDC    ${cmd[0]}  ${cmd[1]}
    END

Execute Command and Write FFDC
    [Documentation]  Run a command on the BMC or OS, write the output to the
    ...              specified file and return a list of generated files.
    [Arguments]  ${key_index}  ${cmd}  ${logpath}=${FFDC_FILE_PATH}
    ...          ${target}=BMC

    Run Keyword If  '${logpath}' == '${FFDC_FILE_PATH}'
    ...    Write Cmd Output to FFDC File  ${key_index}  ${cmd}

    @{ffdc_file_list}=  Create List  ${log_path}

    ${cmd_buf}=  Catenate  ${target} Execute Command \ ${cmd} \ ignore_err=${1}
    ...  \ time_out=${FFDC_CMD_TIMEOUT}
    ${status}  ${ret_values}=  Run Key  ${cmd_buf}  ignore=${1}
    # If the command times out, status will be 'FAIL'.
    Return From Keyword If  '${status}' == 'FAIL'  ${ffdc_file_list}

    ${stdout}=  Set Variable  ${ret_values}[0]
    ${stderr}=  Set Variable  ${ret_values}[1]

    # Write stdout on success and stderr/stdout to the file on failure.
    Run Keyword If  $stderr == '${EMPTY}'
    ...    Write Data To File  ${stdout}${\n}  ${logpath}
    ...  ELSE  Write Data To File
    ...    ERROR output:${\n}${stderr}${\n}Output:${\n}${stdout}${\n}
    ...    ${logpath}

    [Return]  ${ffdc_file_list}


# Method : BMC FFDC Files                                      #
#          Execute command on BMC and write to individual file #
#          based on the file name pre-defined in the list      #

BMC FFDC Files
    [Documentation]  Run the commands from FFDC_BMC_FILE and return a list of
    ...              generated files.

    @{entries}=  Get FFDC File Index
    # Example of entries:
    # entries:
    #   entries[0]: BMC FILES

    scp.Open Connection
    ...  ${OPENBMC_HOST}  username=${OPENBMC_USERNAME}  password=${OPENBMC_PASSWORD}  port=${SSH_PORT}

    @{ffdc_file_list}=  Create List

    FOR  ${index}  IN  @{entries}
      ${ffdc_file_sub_list}=  Create File and Write Data  ${index}
      ${ffdc_file_list}=  Smart Combine Lists  ${ffdc_file_list}  ${ffdc_file_sub_list}
    END

    BMC Execute Command  rm -rf /tmp/BMC_*
    scp.Close Connection

    [Return]  ${ffdc_file_list}


Create File and Write Data
    [Documentation]  Run commands from FFDC_BMC_FILE to create FFDC files and
    ...              return a list of generated files.
    [Arguments]  ${key_index}

    # Description of argument(s):
    # key_index  The index into the FFDC_BMC_FILE dictionary.

    @{ffdc_file_list}=  Create List
    @{cmd_list}=  Get FFDC BMC File  ${key_index}

    FOR  ${cmd}  IN  @{cmd_list}
      ${logpath}=  Catenate  SEPARATOR=  ${LOG_PREFIX}  ${cmd[0]}
      ${ffdc_file_sub_list}=  Execute Command and Write FFDC  ${cmd[0]}  ${cmd[1]}  ${logpath}
      Run Key U  scp.Get File \ /tmp/${cmd[0]} \ ${LOG_PREFIX}${cmd[0]}
      ${ffdc_file_list}=  Smart Combine Lists  ${ffdc_file_list}  ${ffdc_file_sub_list}
    END

    [Return]  ${ffdc_file_list}


# Method : Log Test Case Status                                #
#          Creates test result history footprint for reference #

Log Test Case Status
    [Documentation]  Test case execution result history.
    ...  Create once and append to this file
    ...  logs/test_history.txt
    ...  Format   Date:Test suite:Test case:Status
    ...  20160909214053719992:Test Warmreset:Test WarmReset via REST:FAIL

    # ${FFDC_DIR_PATH_STYLE}=  Get Variable Value  ${FFDC_DIR_PATH_STYLE}
    # ...  ${EMPTY}
    # ${FFDC_DIR_PATH}=  Get Variable Value  ${FFDC_DIR_PATH}  ${EMPTY}

    # Run Keyword If  '${FFDC_DIR_PATH}' == '${EMPTY}'  Set FFDC Defaults

    # Run Keyword If  '${FFDC_DIR_PATH_STYLE}' == '${1}'  Run Keywords
    # ...  Set Global Variable  ${FFDC_LOG_PATH}  ${FFDC_DIR_PATH}  AND
    # ...  Set Global Variable  ${TEST_HISTORY}  ${FFDC_DIR_PATH}test_history.txt

    # Create Directory   ${FFDC_LOG_PATH}
    Create Directory   ${LOG_PATH}

    ${exist}=   Run Keyword and Return Status
    ...   OperatingSystem.File Should Exist   ${TEST_HISTORY}

    Run Keyword If  '${exist}' == '${False}'
    ...   Create File  ${TEST_HISTORY}

    Rpvars  TEST_HISTORY

    ${cur_time}=      Get Current Time Stamp

    Append To File    ${TEST_HISTORY}
    ...   ${cur_time}:${SUITE_NAME}:${TEST_NAME}:${TEST_STATUS}${\n}


Log FFDC Get Requests
    [Documentation]  Run the get requests associated with the key and return a
    ...              list of generated files.
    [Arguments]  ${key_index}

    # Note: Output will be in JSON pretty_print format.

    # Description of argument(s):
    # key_index  The key to the FFDC_GET_REQUEST dictionary that contains the
    #            get requests that are to be run.

    @{ffdc_file_list}=  Create List
    @{cmd_list}=  Get FFDC Get Request  ${key_index}

    FOR  ${cmd}  IN  @{cmd_list}
      ${logpath}=  Catenate  SEPARATOR=  ${LOG_PREFIX}  ${cmd[0]}
      ${resp}=  OpenBMC Get Request  ${cmd[1]}  quiet=${1}  timeout=${30}
      ${status}=  Run Keyword and Return Status  Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
      Run Keyword If  '${status}' == '${False}'  Continue For Loop
      ${jsondata}=  to json  ${resp.content}  pretty_print=True
      Write Data To File  ${\n}${jsondata}${\n}  ${logpath}
      Append To List  ${ffdc_file_list}  ${logpath}
    END

    [Return]  ${ffdc_file_list}

BMC FFDC Get Requests
    [Documentation]  Iterate over get request list and return a list of
    ...              generated files.

    @{ffdc_file_list}=  Create List

    @{entries}=  Get ffdc get request index
    # Example of entries:
    # entries:
    #  entries[0]:  GET REQUESTS

    FOR  ${index}  IN  @{entries}
      ${ffdc_file_sub_list}=  Log FFDC Get Requests  ${index}
      ${ffdc_file_list}=  Smart Combine Lists  ${ffdc_file_list}  ${ffdc_file_sub_list}
    END

    [Return]  ${ffdc_file_list}


System Inventory Files
    [Documentation]  Copy systest os_inventory files and return a list of
    ...              generated files..
    # The os_inventory files are the result of running
    # systest/htx_hardbootme_test.  If these files exist
    # they are copied to the FFDC directory.
    # Global variable ffdc_dir_path is the path name of the
    # directory they are copied to.

    @{ffdc_file_list}=  Create List

    ${globex}=  Set Variable  os_inventory_*.json

    @{file_list}=  OperatingSystem.List Files In Directory  .  ${globex}

    Copy Files  ${globex}  ${ffdc_dir_path}

    FOR  ${file_name}  IN  @{file_list}
      Append To List  ${ffdc_file_list}  ${ffdc_dir_path}${file_name}
    END

    Run Keyword and Ignore Error  Remove Files  ${globex}

    [Return]  ${ffdc_file_list}


SCP Coredump Files
    [Documentation]  Copy core dump files from BMC to local system and return a
    ...              list of generated file names.

    @{ffdc_file_list}=  Create List

    # Check if core dump exist in the /tmp
    ${core_files}  ${stderr}  ${rc}=  BMC Execute Command  ls /tmp/core_*
    ...  ignore_err=${1}
    Run Keyword If  '${rc}' != '${0}'  Return From Keyword  ${ffdc_file_list}

    @{core_list}=  Split String  ${core_files}
    # Copy the core files
    Run Key U  Open Connection for SCP

    FOR  ${index}  IN  @{core_list}
      ${ffdc_file_path}=  Catenate  ${LOG_PREFIX}${index.lstrip("/tmp/")}
      ${status}=  Run Keyword and Return Status  scp.Get File  ${index}  ${ffdc_file_path}
      Run Keyword If  '${status}' == '${False}'  Continue For Loop
      Append To List  ${ffdc_file_list}  ${ffdc_file_path}

      # Remove the file from remote to avoid re-copying on next FFDC call

      BMC Execute Command  rm ${index}  ignore_err=${1}
      # I can't find a way to do this: scp.Close Connection

    END

    [Return]  ${ffdc_file_list}


SCP Dump Files
    [Documentation]  Copy all dump files from BMC to local system.

    # Check if dumps exist
    ${ffdc_file_list}=  Scp Dumps  ${FFDC_DIR_PATH}  ${FFDC_PREFIX}

    [Return]  ${ffdc_file_list}


Collect Dump Log
    [Documentation]  Collect dumps from dump entry.
    [Arguments]  ${log_prefix_path}=${LOG_PREFIX}

    ${data}=  Read Properties  ${DUMP_ENTRY_URI}enumerate  quiet=${1}  timeout=${30}

    # Grab the list of entries from dump/entry/
    # The data shown below is the result of the "Get Dictionary Keys".
    # Example:
    # /xyz/openbmc_project/dump/entry/1
    # /xyz/openbmc_project/dump/entry/2

    ${dump_list}=  Get Dictionary Keys  ${data}
