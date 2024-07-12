BOARD_TEST_MSG = "hallo arble-evb"
# I2C
I2C_MASTER = "2"
I2C_SALVE = "1"
# Network
NET_PRIMARY_INTF = "eth1"
NET_PRIMARY_THR = "550"
NET_SECONDARY_IP = ["10.191.20.51", "10.191.20.52"]
#NET_SECONDARY_IP = ["", ""]
# Rev. B eth0 --> SGMII, eth3 -->RMII
NET_SECONDARY_INTF = ["eth3", "eth0"]
NET_SECONDARY_THR = ["60", "550"]
# Storage
SPI_DEV = "mtdblock7"
MMC_DEV = "mmcblk0p6"
USB_DEV = "sda6"
# GPIO, SMB18, J4, in linux 6.6, gpio num should add 512 (GPIO_DYNAMIC_BASE=512)
GPIO_PINS = ["512", "513"]
# ADC
ADC_CHANNEL = "5"
ADC_REF_VOLT = "1.2"
ADC_RESOLUTION = "4096"
ADC_UP_BOUND = "1020"
ADC_LOW_BOUND = "980"
JTAG_DEV = "jtag0"
CPLD_READID = "readid_arbelevb.svf"
PROGRAM_CPLD = "arbelevb_cpld.svf"
