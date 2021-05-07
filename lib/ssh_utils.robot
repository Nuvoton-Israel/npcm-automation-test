*** Settings ***
Documentation	Utilities for ssh

Library		bmc_ssh_utils.py

*** Keywords ***
PC Execute Command
    [Documentation]  execute shell command on remote PC
    [Arguments]  ${cmd}  ${ip}  ${user}  ${passwd}  ${fork}=0  ${ignore_err}=0

    # Description of argument(s):
    # ${cmd}    The command string to be run in an SSH session.
    # ${ip}     The remote PC IP address
    # ${user}   The remote PC user name
    # ${fork}   Wait for execute shell command return or not
    # ${ignore_err} Do not set test fail if shell command error

    ${OS_HOST}=  Set Variable  ${ip}
    ${OS_USERNAME}=  Set Variable  ${user}
    ${OS_PASSWORD}=  Set Variable  ${passwd}

    Run Keyword And Return  OS Execute Command  ${cmd}
    ...  fork=${fork}  ignore_err=${ignore_err}  time_out=${15}
