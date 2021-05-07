from robot.libraries.BuiltIn import BuiltIn
# load basic variables first
BuiltIn().import_variables("variables.py")
# board configurations
test_board = BuiltIn().get_variable_value("${BOARD}")
if test_board in BuiltIn().get_variable_value("${BOARD_SUPPORTED}"):
    BuiltIn().import_variables(test_board + "/variables.py")