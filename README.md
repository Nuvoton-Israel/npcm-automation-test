# Nuvoton BMC Automation Test

## Environment Setup ##
Users can reference the following links to understand the package we used.
* [Robot Framework Install Instruction](https://github.com/robotframework/robotframework/blob/master/INSTALL.rst)
* [OpenBMC Test Automation Setup Guide](https://github.com/openbmc/openbmc-test-automation#installation-setup-guide)

### Build environment example ###
For manager the python environment, there is a convenience program venv we can use.
* https://docs.python.org/3/library/venv.html

```bash
# install python3-venv
sudo apt instll python3-venv

# create env
python3 -m venv ~/venv/bmc

# activate env and install python packages
source ~/venv/bmc/bin/activate
pip install redfish==3 robotframework==4
pip install -U requests robotframework-httplibrary robotframework-requests robotframework-scplibrary robotframework-sshlibrary

# use the environment we create before run robot test
source ~/venv/bmc/bin/activate
```


## Run commands ##
### Before Test ###
Before test, you must set up DUT IP address, iperf server, usb device name.., etc.

You can use -v OPENBMC_HOST:${DUT IP} in robot command to set up DUT IP,
or just modify it in lib/resource.robot.

Currently we support two boards: buv-runbmc and arbel-evb. The variables
or scripts depend on board is under data/${BOARD}. It recommends modify
variables.py on test PC instead of setting up all variables by command line.

### DUT setup ###
The DUT may need make partitions for eMMC at first time, you can run robot script to fdisk and mkfs eMMC.

* Run partition command:
    ```
    robot -v OPENBMC_HOST:${DUT_IP} format_emmc.robot
    ```

The DUT environment must contains programs which listed below for run test,
user can porting these files by [change link](https://github.com/Nuvoton-Israel/openbmc/pull/221/files):
* ent:

    Pseudorandom Number Sequence Test Program, for RNG test case.
* wr_perf_test, rd_perf_test:

    Data read/write performance test, for storage relative test case.
* iperf3:

    Network bandwidth test program, for network relative test case.
* cc_dry2:

    Dhrystone benchmark, for CPU test case.
* i2cdetect, i2cset, i2cget, i2ctransfer:

    I2C tools, for I2C issue analyze.
* head, tr, awk, cut, sed, md5sum, taskset, timeout, sleep:

    Some busybox utils, for run bash script.
* fdisk, mke2fs
    Some busybox utils, for run format emmc robot.


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
