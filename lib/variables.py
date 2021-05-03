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