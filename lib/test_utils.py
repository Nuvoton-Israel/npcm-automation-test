from robot.libraries.BuiltIn import BuiltIn
import gen_print as gp

def make_gpio_pin_pairs():
    pins = BuiltIn().get_variable_value("${GPIO_PINS}")
    #gp.qprint_var(pins)
    mod = len(pins) % 2
    if mod != 0:
        BuiltIn().fail("GPIO pins must be even")
    pairs = []
    count = len(pins) >> 1
    #gp.qprint_var(count)
    for i in range(count):
        pairs.append([pins[i*2], pins[i*2+1]])

    #gp.qprint_var(pairs)
    return pairs

def get_gpio_state_file(pins):
    state_header = BuiltIn().get_variable_value("${GPIO_SATE}")
    return "Statefile: /tmp/log/{}.{}.{}.stat".format(state_header, pins[0], pins[1])

# return pass status, error message
def check_state_files(files):
    err_msgs = []
    passed = "PASS"
    check_cmd = "Check Fail In State File"
    for state_file in files:
        cmd_buf = [check_cmd, state_file]
        status, error = BuiltIn().run_keyword_and_ignore_error(*cmd_buf)
        gp.qprint_vars(status, error)
        if status != "PASS":
            passed = status
            err_msgs.append(state_file + ", " + error)

    return passed, ", ".join(err_msgs)
