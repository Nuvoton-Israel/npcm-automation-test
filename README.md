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

* Run Stress test 20 minutes for each test case:
    ```
    robot -i "Stress Test" -v "STRESS_TIME:20 min" -v "TIMEOUT_TIME:21 min" test_basic.robot
    ```

* Run Stress test with out network secondary interface cases:
    * arbel-evb:
    ```
    robot -i "Stress Test" -v BOARD:arbel-evb -v ALLOW_IGNORE_SECONDARY:True -v NET_SECONDARY_IP:"," test_basic.robot
    ```
    * buv-runbmc:
    ```
    robot -i "Stress Test" -v BOARD:buv-runbmc -v ALLOW_IGNORE_SECONDARY:True -v NET_SECONDARY_IP:"" test_basic.robot
    ```

* Run single test case:
    ```
    robot -t "Test Hello World" test_basic.robot
    ```
