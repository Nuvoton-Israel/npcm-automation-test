BOARD_TEST_MSG = "Hello buv-runbmc"
# I2C
I2C_MASTER = "2"
I2C_SALVE = "1"
# Network
NET_PRIMARY_INTF = "eth1"
NET_PRIMARY_THR = "550"
NET_SECONDARY_IP = ["192.168.56.109"]
#NET_SECONDARY_IP = [""]
NET_SECONDARY_INTF = ["eth0"]
NET_SECONDARY_THR = ["60"]
# Storage
SPI_DEV = "mtdblock8"
USB_DEV = "sda6"
# GPIO pin pairs, [[out, in], [out, in], ...]
GPIO_PINS = ["6", "5", "4", "7", "22", "23"]
# ADC
ADC_CHANNEL = "4"
ADC_REF_VOLT = "2"
ADC_RESOLUTION = "1024"
ADC_UP_BOUND = "1820"
ADC_LOW_BOUND = "1760"