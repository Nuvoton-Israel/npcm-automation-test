import os
from robot.libraries.BuiltIn import BuiltIn

OPENBMC_BASE_URI = '/xyz/openbmc_project/'

# Logging URI variables
BMC_LOGGING_URI = OPENBMC_BASE_URI + 'logging/'
BMC_LOGGING_ENTRY = BMC_LOGGING_URI + 'entry/'

# Dump URI variables.
DUMP_URI = OPENBMC_BASE_URI + 'dump/bmc/'
DUMP_ENTRY_URI = DUMP_URI + 'entry/'
DUMP_DOWNLOAD_URI = "/download/dump/"
# The path on the BMC where dumps are stored.
DUMP_DIR_PATH = "/var/lib/phosphor-debug-collector/dumps/"

AUTH_SUFFIX = ":" + BuiltIn().get_variable_value("${HTTPS_PORT}", os.getenv('HTTPS_PORT', '443'))

# Host control URI variables.
CONTROL_HOST_URI = OPENBMC_BASE_URI + 'control/host0/'

# Power restore variables.
POWER_RESTORE_URI = CONTROL_HOST_URI + 'power_restore_policy'
CONTROL_DBUS_BASE = 'xyz.openbmc_project.Control.'

RESTORE_LAST_STATE = CONTROL_DBUS_BASE + 'Power.RestorePolicy.Policy.Restore'
ALWAYS_POWER_ON = CONTROL_DBUS_BASE + 'Power.RestorePolicy.Policy.AlwaysOn'
ALWAYS_POWER_OFF = CONTROL_DBUS_BASE + 'Power.RestorePolicy.Policy.AlwaysOff'