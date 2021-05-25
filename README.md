# Nuvoton BMC Automation Test

## Environment Setup ##
* [Robot Framework Install Instruction](https://github.com/robotframework/robotframework/blob/master/INSTALL.rst)
* [OpenBMC Test Automation Setup Guide](https://github.com/openbmc/openbmc-test-automation#installation-setup-guide)


## Run commands ##
### Before Test ###
Before test, you must set up DUT IP address, iperf server, usb device name.., etc.

You can use -v OPENBMC_HOST:${DUT IP} in robot command to set up DUT IP,
or just modify it in lib/resource.robot.

Currently we support two boards: buv-runbmc and arbel-evb. The variables
or scripts depend on board is under data/${BOARD}. It recommends modify
variables.py on test PC instead of setting up all variables by command line.

### Run Tests ###
Here are some examples to run test case

* Run all test items with default parameters:
    ```
    robot test_basic.robot
    ```

* Switch board to arbel-evb for test:
    ```
    robot -v BOARD:arbel-evb test_basic.robot
    ```

* Run stress test 20 minutes for each test case:
    ```
    robot -i "Stress Test" -v "STRESS_TIME:20 min" -v "TIMEOUT_TIME:21 min" test_basic.robot
    ```

* Run stress test with out network secondary interface cases:
    * arbel-evb:
    ```
    robot -i "Stress Test" -v BOARD:arbel-evb -v ALLOW_IGNORE_SECONDARY:True -v NET_SECONDARY_IP:"," test_basic.robot
    ```
    * buv-runbmc:
    ```
    robot -i "Stress Test" -v BOARD:buv-runbmc -v ALLOW_IGNORE_SECONDARY:True -v NET_SECONDARY_IP:"" test_basic.robot
    ```

    Note: the network test must set up Iperf server IP address, user name and password by variables:
    * IPERF_SERVER
    * IPERF_USER
    * IPERF_PASSWD

    And you must connect DUT each network interface and iperf server in same network.

    If you just want to perform RMII test and only connect RMII to local PC.
    You should set local PC as iperf server, set DUT IP as RMII IP like following example:
    ```
    robot -i RMII -v BOARD:arbel-evb -v ALLOW_IGNORE_SECONDARY:True -v NET_SECONDARY_IP:"10.1.1.11," -v OPENBMC_HOST:10.1.1.11 -v IPERF_SERVER:10.1.1.10 -v IPERF_USER:test -v IPERF_PASSWD:test test_basic.robot
    ```

* Run full network stress test cases for arbel-evb:

    Because arbel-evb has three ethernet phy, we should set up their eth name, IP address, and threshould for each.
    You can referenece the data/arbel-evb/variables.py to set them up:
    * NET_SECONDARY_IP = ["10.191.20.51", "10.191.20.52"]
    * NET_SECONDARY_INTF = ["eth3", "eth0"]
    * NET_SECONDARY_THR = ["60", "550"]

    Or change the variables by command line like:
    ```
    robot -i network -v NET_SECONDARY_IP:"192.168.56.11,192.168.56.12" test_basic.robot
    ```

* Run single test case:
    ```
    robot -t "Test Hello World" test_basic.robot
    ```
