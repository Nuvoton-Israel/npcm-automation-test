*** Settings ***
Variables           ../data/variables.py

*** Variables ***
${SSH_PORT}            22
${HELLO_MESSAGE}       Hello, world!
${DBUS_PREFIX}         ${EMPTY}
${OPENBMC_HOST}        192.168.56.130
${AUTH_URI}            https://${OPENBMC_HOST}${AUTH_SUFFIX}
${OPENBMC_USERNAME}    root
${OPENBMC_PASSWORD}    0penBmc
${REST_USERNAME}       root
${REST_PASSWORD}       0penBmc
# the file server for jtag master robot, and we login it by SSH public key
${SFTP_USER}           ${EMPTY}
${SFTP_SERVER}         ${EMPTY}

# test scripts
${DIR_SCRIPT}       data
# Note, currently no test case depend on platform architecture
${PLATFORM}         poleg
# choose board as arbel-evb, unit test is depend on baord,
# but stress test does not
${BOARD}            buv-runbmc
@{BOARD_SUPPORTED}  buv-runbmc  arbel-evb
${DIR_STAT}         /tmp/log
${CHECK_TOOLS}      ${False}
@{TEST_TOOLS}       timeout  ent  iperf3  wr_perf_test  rd_perf_test
                    ...  cc_dry2  i2cdetect  i2cset  i2cget  i2ctransfer
                    ...  head  tr  awk  cut  sed  md5sum  taskset
                    ...  fdisk  mke2fs  sleep  pgrep
${SPI_DEV}          ${EMPTY}
${MMC_DEV}          ${EMPTY}
${USB_DEV}          ${EMPTY}  # the USB mass storage on DUT
${UDC_DEV}          sdb1  # the USB mass storage on PC
${I2C_MASTER}       ${EMPTY}  # the i2c master bus
${I2C_SALVE}        ${EMPTY}  # the i2c slave bus
${I2C_EEPROM_ADDR}  0x64
@{GPIO_PINS}
${GPIO_SATE}        gpio_stress

# === Network ===
#${ALLOW_IGNORE_SECONDARY}    ${False}
${ALLOW_IGNORE_SECONDARY}    ${True}

# the iperf server PC ip address, user name and login password
# Should NOT be empty, please fill up
${IPERF_SERVER}     192.168.56.102
${IPERF_USER}       ${EMPTY}
${IPERF_PASSWD}     ${EMPTY}

# the DUT IP address, and you must set one connected ehternet as primary
${NET_PRIMARY_IP}       ${OPENBMC_HOST}
# Please set up these variables under ${BOARD}/variables.py
${NET_PRIMARY_INTF}     ${EMPTY}
${NET_PRIMARY_THR}      ${EMPTY}  # pass stree test min MB/s
# If not real connect to secondary interface, leave IP to EMPTY
@{NET_SECONDARY_IP}
@{NET_SECONDARY_INTF}   # the network secondary interfaces
@{NET_SECONDARY_THR}

# === Stress Test ===
#${STRESS_TIME}      20 minutes
#${TIMEOUT_TIME}     21 minutes
${STRESS_TIME}      30 seconds
${TIMEOUT_TIME}     60 seconds

${ENABLE_LOG_COLLECT}   ${False}
