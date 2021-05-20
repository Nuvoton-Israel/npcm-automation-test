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

# test scripts
${DIR_SCRIPT}       data
# Note, currently no test case depend on platform architecture
${PLATFORM}         poleg
# choose board as arbel-evb, unit test is depend on baord,
# but stress test does not
${BOARD}            buv-runbmc
@{BOARD_SUPPORTED}  buv-runbmc  arbel-evb
${DIR_STAT}         /tmp/log
@{TEST_TOOLS}       timeout  ent  iperf3  wr_perf_test  rd_perf_test
                    ...  cc_dry2  i2cdetect  i2cset  i2cget  i2ctransfer
                    ...  head  tr  awk  cut  sed  md5sum  taskset
                    ...  fdisk  mke2fs  sleep
${CPU_STAT}         cpu_stress
${RNG_STAT}         rng_stress
${NET_STAT}         net_stress
${SPI_DEV}          mtdblock8
${MMC_DEV}          mmcblk0p1
${USB_DEV}          sda1  # the USB mass storage on DUT
${UDC_DEV}          sdb1  # the USB mass storage on PC
${I2C_MASTER}       ${EMPTY}  # the i2c master bus
${I2C_SALVE}        ${EMPTY}  # the i2c slave bus
${I2C_EEPROM_ADDR}  0x64

# net test
${GMAC_IP}          ${OPENBMC_HOST}
${ALLOW_IGNORE_EMAC}    ${False}
# if not real connect to EMAC, set EMAC to EMPTY
#${EMAC_IP}          ${EMPTY}
${EMAC_IP}          192.168.56.109
${IPERF_SERVER}     192.168.56.102
${IPERF_USER}       ${EMPTY}
${IPERF_PASSWD}     ${EMPTY}
${GMAC_THR}         350  # pass stree test min MB/s
${EMAC_THR}         60

# stress test
#${STRESS_TIME}      20 minutes
#${TIMEOUT_TIME}     21 minutes
${STRESS_TIME}      30 seconds
${TIMEOUT_TIME}     60 seconds

${ENABLE_LOG_COLLECT}   ${False}