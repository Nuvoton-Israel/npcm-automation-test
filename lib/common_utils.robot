*** Settings ***
Documentation	Utilities for unit test

Library		bmc_ssh_utils.py
Resource	resource.robot

*** Keywords ***
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

Get BMC System Model
    [Documentation]  Get the BMC model from the device tree and return it.

    ${bmc_model}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat ${devicetree_base} | cut -d " " -f 1  return_stderr=True
    ...  test_mode=0
    Should Be Empty  ${stderr}
    Should Not Be Empty  ${bmc_model}  msg=BMC model is empty.
    [Return]  ${bmc_model}

Get URL List
    [Documentation]  Return list of URLs under given URL.
    [Arguments]  ${openbmc_url}

    # Description of argument(s):
    # openbmc_url  URL for list operation (e.g.
    #              /xyz/openbmc_project/inventory).

    ${url_list}=  Read Properties  ${openbmc_url}list  quiet=${1}
    Sort List  ${url_list}

    [Return]  ${url_list}
