*** Variables ***
${SSH_PORT}             22
${HELLO_MESSAGE}        Hello, world!
${OPENBMC_HOST}         192.168.56.130
${OPENBMC_USERNAME}     root
${OPENBMC_PASSWORD}     0penBmc

# test scripts
${DIR_SCRIPT}       data
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
${UDC_DEV}          sdc1  # the USB mass storage on PC

# net test
${GMAC_IP}          ${OPENBMC_HOST}
${ALLOW_IGNORE_EMAC}    ${False}
# if not real connect to EMAC, set EMAC to EMPTY
#${EMAC_IP}          ${EMPTY}
${EMAC_IP}          192.168.56.109
${IPERF_SERVER}     192.168.56.102