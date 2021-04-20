# Nuvoton BMC Automation Test

## Environment Setup ##
* [Robot Framework Install Instruction](https://github.com/robotframework/robotframework/blob/master/INSTALL.rst)
* [OpenBMC Test Automation Setup Guide](https://github.com/openbmc/openbmc-test-automation#installation-setup-guide)


## Run commands ##
### Before Test ###
Before test, you must set up DUT IP address, iperf server, usb device name.., etc.
You can use -v OPENBMC_HOST:${DUT IP} in robot command, or modify lib/resource.robot.

### Run Tests ###
Run all test items with default parameters:
    ```
    robot test_basic.robot
    ```

Run Stress test 20 minutes for each test case:
    ```
    robot -i "Stress Test" -v "STRESS_TIME:20 min" -v "TIMEOUT_TIME:21 min" test_basic.robot
    ```

Run Stress test with out Emac case:
    ```
    robot -i "Stress Test" -v ALLOW_IGNORE_EMAC:True -v EMAC_IP:"" test_basic.robot
    ```

Run single test case:
    ```
    robot -t "Test Hello World" test_basic.robot
    ```

