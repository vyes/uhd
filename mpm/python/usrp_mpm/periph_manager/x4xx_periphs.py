#
# Copyright 2019 Ettus Research, a National Instruments Brand
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
"""
X4xx peripherals
"""

import datetime
import re
import struct
import time
from multiprocessing import Process
from statistics import mean
from usrp_mpm import lib  # Pulls in everything from C++-land
from usrp_mpm.sys_utils import i2c_dev
from usrp_mpm.sys_utils.gpio import Gpio
from usrp_mpm.sys_utils.uio import UIO
from usrp_mpm.mpmutils import poll_with_timeout
from usrp_mpm.sys_utils.sysfs_thermal import read_thermal_sensor_value

def parse_encoded_git_hash(encoded):
    git_hash = encoded & 0x0FFFFFFF
    tree_dirty = ((encoded & 0xF0000000) > 0)
    dirtiness_qualifier = 'dirty' if tree_dirty else 'clean'
    return (git_hash, dirtiness_qualifier)


class DioControl:
    """
    DioControl acts as front end for DIO AUX BOARD

    The DioControl class uses three hardware resources to control the behavior
    of the board, which are
     * I2C extender
     * MB registers
     * MB cpld registers

    DioControl supports arbitrary methods of addressing the pins on the
    frontend. The current implementation supports two ways of pin addressing:
    HDMI and DIO. Use set_port_mapping to switch between both of them.

    When using HDMI as pin addressing scheme you have to give the real pin
    number of the HDMI adapter like this::
        ┌───────────────────────────────┐
        └┐19 17 15 13 11 09 07 05 03 01┌┘
         └┐ 18 16 14 12 10 08 06 04 02┌┘
          └───────────────────────────┘
    Be aware that not all pins are accessible. The DioControl class will warn
    about the usage of unassigned pins.

    The second option is the DIO addressing scheme. Here all user accessible
    pins are numbered along the HDMI pin numbers which gives a pin table like
    this::
        ┌───────────────────────────────┐
        └┐11 -- 09 08 -- 05 04 -- 01 00┌┘
         └┐ -- 10 -- 07 06 -- 03 02 --┌┘
          └───────────────────────────┘

    Within the MPM shell one can query the state of the DIO board using
    dio_status. This gives an output like this::
         HDMI mapping | PORT A                  | PORT B
        --------------+-------------------------+-------------------------
         voltage      | OFF - PG:NO - EXT:OFF   | 1V8 - PG:YES - EXT:OFF
        --------------+-------------------------+-------------------------
         master       | 0.. 00.0 0.00 .00. 00.1 | 0.. 00.0 0.00 .00. 00.1
         direction    | 0.. 00.0 0.00 .00. 00.1 | 0.. 00.0 0.00 .00. 00.0
        --------------+-------------------------+-------------------------
         output       | 0.. 00.0 0.00 .00. 00.1 | 0.. 00.0 0.00 .00. 00.0
         input        | 0.. 00.0 0.00 .00. 00.1 | 0.. 00.0 0.00 .00. 00.0
    The table displays the current state of HDMI port A and B provided by the
    DIO board as well as the state of the corresponding register maps and GPIO
    pins in a user readable form.

    The header shows the active mapping and the port names. Change the
    mapping with set_port_mapping.

    The first row shows the voltage state of each port. Voltage can be one of
    the states in (OFF, 1V8, 2V5, 3V3). Change the power state by using
    set_voltage_level. When the voltage level is set to OFF, the corresponding
    GPIO pin EN_PORT is set low, high otherwise.
    When voltage is set to one of the other states EN_PORT<x> is set to high and
    EN_PORT<x>_<?V?> is set accordingly where 1V8 corresponds to 2V5 and 3V3
    being both low. PG shows whether the PG (power good) pin corresponding to
    the port (PORT<x>_PG) is high. This is NO if power is OFF and YES otherwise.
    EXT shows whether EN_EXT_PWR_<x> is enabled for the port. Change the
    external power using set_external_power.
    Note: A port must have a reasonable voltage level assigned to it before
          changes to the output register takes effect on the HDMI port pins or
          pin states of the HDMI port can be read in input register.

    The master row shows the pin assignments for the master register which
    decides whether PS (1) or FPGA (0) drives output register pins. Change
    values using set_master_pin(s).

    The direction row shows the pin assignments for the direction register which
    decides whether the pin is written (1) or read (0) by the FPGA. Change
    values using set_direction_pin(s).

    The output and input rows shows the pin assignments for the FPGAs input and
    output registers. Only the output register pins can be changed. Change
    values using set_output_pin(s).

    """

    # Available DIO ports
    DIO_PORTS = ("PORTA", "PORTB")
    # Available voltage levels
    DIO_VOLTAGE_LEVELS = ("OFF", "1V8", "2V5", "3V3")

    # For each mapping supported by DioControl the class needs the following
    # information
    # * map_name: name of the mapping (in uppercase)
    # * pin_names: names of the pins starting with smallest. Unassignable PINS
    #              must be named as well
    # * port_map: mapping table from FPGA register indices to pin indices. A
    #             mapping of (4, 2) means pin 4 is mapped to register bit 0 and
    #             pin2 is mapped to register bit 1. Only assignable pins
    #             may appear in the mapping.
    # * first_pin: index of the first pin for the mapping

    # HDMI mapping constants
    HDMI_MAP_NAME = "HDMI"
    HDMI_PIN_NAMES = ("Data2+", "Data2_SHD", "Data2-", "Data1+", "Data1_SHD",
                      "Data1-", "Data0+", "Data0_SHD", "Data0-", "CLK+",
                      "CLK_SHD", "CLK-", "RESERVED", "HEC_Data-", "SCL",
                      "SDA", "HEC_GND", "V+", "HEC_Data+")
    HDMI_PORT_MAP = {DIO_PORTS[0]:  (3,  1,  4,  6,  9,  7, 10, 12, 15, 13, 16, 19),
                     DIO_PORTS[1]: (16, 19, 15, 13, 10, 12,  9,  7,  4,  6,  3,  1)}
    HDMI_FIRST_PIN = 1

    # DIO mapping constants
    DIO_MAP_NAME = "DIO"
    DIO_PIN_NAMES = ("DIO0", "DIO1", "DIO2", "DIO3", "DIO4", "DIO5",
                      "DIO6", "DIO7", "DIO8", "DIO9", "DIO10", "DIO11")
    DIO_PORT_MAP = {DIO_PORTS[0]: (1, 0, 2, 3, 5, 4, 6, 7, 9, 8, 10, 11),
                     DIO_PORTS[1]: (10, 11, 9, 8, 6, 7, 5, 4, 2, 3, 1, 0)}
    DIO_FIRST_PIN = 0

    # Register layout/size constants
    PORT_BIT_SIZE       = 16    # number of bits used in register per port
    PORT_USED_BITS_MASK = 0xFFF # masks out lower 12 of 16 bits used per port

    # DIO registers addresses in FPGA
    FPGA_DIO_REGISTER_BASE = 0x2000
    FPGA_DIO_MASTER_REGISTER = FPGA_DIO_REGISTER_BASE
    FPGA_DIO_DIRECTION_REGISTER = FPGA_DIO_REGISTER_BASE + 0x4
    FPGA_DIO_INPUT_REGISTER = FPGA_DIO_REGISTER_BASE + 0x8
    FPGA_DIO_OUTPUT_REGISTER = FPGA_DIO_REGISTER_BASE + 0xC
    # DIO registers addresses in CPLD
    CPLD_DIO_DIRECTION_REGISTER = 0x30

    class _PortMapDescriptor:
        """
        Helper class to hold port mapping relevant information
        """
        def __init__(self, name, pin_names, map, first_pin):
            self.name = name
            self.pin_names = pin_names
            self.map = map
            self.first_pin = first_pin


    class _PortControl:
        """
        Helper class for controlling ports on the I2C expander
        """
        def __init__(self, port):
            assert port in DioControl.DIO_PORTS
            prefix = "DIOAUX_%s" % port

            self.enable = Gpio('%s_ENABLE' % prefix, Gpio.OUTPUT)
            self.en_3v3 = Gpio('%s_3V3' % prefix, Gpio.OUTPUT)
            self.en_2v5 = Gpio('%s_2V5' % prefix, Gpio.OUTPUT)
            self.ext_pwr = Gpio('%s_ENABLE_EXT_PWR' % prefix, Gpio.OUTPUT)
            self.power_good = Gpio('%s_PWR_GOOD' % prefix, Gpio.INPUT)


    def __init__(self, mboard_regs, mboard_cpld, log):
        """
        Initializes access to hardware components as well as creating known
        port mappings
        :param log: logger to be used for output
        """
        self.log = log.getChild(self.__class__.__name__)
        self.port_control = {port: self._PortControl(port) for port in self.DIO_PORTS}
        self.mboard_regs = mboard_regs
        self.mboard_cpld = mboard_cpld

        # initialize port mapping for HDMI and DIO
        self.port_mappings = {}
        self.mapping = None
        self.port_mappings[self.HDMI_MAP_NAME] = self._PortMapDescriptor(
            self.HDMI_MAP_NAME, self.HDMI_PIN_NAMES,
            self.HDMI_PORT_MAP, self.HDMI_FIRST_PIN)
        self.port_mappings[self.DIO_MAP_NAME] = self._PortMapDescriptor(
            self.DIO_MAP_NAME, self.DIO_PIN_NAMES,
            self.DIO_PORT_MAP, self.DIO_FIRST_PIN)
        self.set_port_mapping(self.HDMI_MAP_NAME)
        self.log.trace("Spawning DIO fault monitors...")
        self._dio0_fault_monitor = Process(
            target=self._monitor_dio_fault,
            args=('A', "DIO_INT0")
        )
        self._dio1_fault_monitor = Process(
            target=self._monitor_dio_fault,
            args=('B', "DIO_INT1")
        )
        self._dio0_fault_monitor.start()
        self._dio1_fault_monitor.start()

    def _monitor_dio_fault(self, dio_port, fault):
        self.log.trace("Launching monitor loop...")
        fault_line = Gpio(fault, Gpio.FALLING_EDGE)
        while True:
            if fault_line.event_wait():
                # If we saw a fault, disable the external power
                self.log.warning("DIO fault occurred on port {} - turning off external power"
                                .format(dio_port))
                self.set_external_power(dio_port, "0")

    # --------------------------------------------------------------------------
    # Helper methods
    # --------------------------------------------------------------------------
    def _map_to_register_bit(self, port, pin):
        """
        Maps a pin denoted in current mapping scheme to a corresponding bit in
        the register map.
        :param port: port to do the mapping on
        :param pin: pin (in current mapping scheme)
        :return: bit position in register map
        :raises RuntimeError: pin is not in range of current mapping scheme
                              or not user assignable.
        """
        assert isinstance(pin, int)
        port = self._normalize_port_name(port)
        first_pin = self.mapping.first_pin
        last_pin = first_pin + len(self.mapping.pin_names) - 1
        port_map = self.mapping.map[port]

        if not (first_pin <= pin <= last_pin):
            raise RuntimeError("Pin must be in range [%d,%d]. Given pin: %d" %
                               (first_pin, last_pin, pin))
        if pin not in port_map:
            raise RuntimeError("Pin %d (%s) is not a user assignable pin." %
                               (pin,
                                self.mapping.pin_names[pin - first_pin]))

        # map pin back to register bit
        bit = port_map.index(pin)
        # lift register bit up by PORT_BIT_SIZE for port b
        bit = bit if port == self.DIO_PORTS[0] else bit + self.PORT_BIT_SIZE
        return bit

    def _calc_register_value(self, register, port, pin, value):
        """
        Recalculates register value.

        Current register state is read and the bit that corresponds to the
        values given by port and pin is determined. The register content is
        changed at position of bit to what is given by value.

        Note: This routine only reads the current and calculates the new
              register value. It is up to the callee to set the register value.
        :param register: Address of the register value to recalculate
        :param port:     port associated with pin
        :param pin:      pin to change (will be mapped to bit according to
                         current mapping scheme an given port)
        :param value:    new bit value to set
        :return:         new register value.
        """
        assert value in [0, 1]

        content = self.mboard_regs.peek32(register)
        bit = self._map_to_register_bit(port, pin)
        content = (content | 1 << bit) if value == 1 else (content & ~(1 << bit))
        return content

    def _set_pin_values(self, port, values, set_method):
        """
        Helper method to assign multiple pins in one call.
        :param port: Port to set pins on
        :param values: New pin assignment represented by an integer. Each bit of
                       values corresponds to a pin on board according to current
                       mapping scheme. Bits that do not correspond to a pin in
                       the current mapping scheme are skipped.
        :param set_method: method to be used to set/unset a pin. Signature of
                           set_method is (port, pin).
        """
        first_pin = self.mapping.first_pin
        port = self._normalize_port_name(port)
        for i, pin_name in enumerate(self.mapping.pin_names):
            if i + first_pin in self.mapping.map[port]:
                set_method(port, i + first_pin, int(values & 1 << i != 0))

    # --------------------------------------------------------------------------
    # Helper to convert abbreviations to constants defined in DioControl
    # --------------------------------------------------------------------------

    def _normalize_pin_value(self, value):
        """
        Map a value to a pin state. For full flexibility the pin state can be
        given in different form which are (on, high, h, 1) for pin in high
        value and (off, low, l, 0) for a pin in low value.
        :param value: pin value
        :return: 1 for high and 0 for low pin value
        """
        assert isinstance(value, str)

        if value.upper() not in ("ON", "OFF", "1", "0", "HIGH", "LOW", "H", "L"):
            raise RuntimeError("Could not map value %s to pin state" % value)
        return 1 if value.upper() in ("ON", "HIGH", "H", "1") else 0

    def _normalize_mapping(self, mapping):
        """
        Map name to one of the key in self.port_mappings.
        :param mapping: mapping name or any abbreviation by removing letters
                        from the end of the name
        :return: Key found for mapping name
        :raises RuntimeError: no matching mapping could be found
        """
        assert isinstance(mapping, str)
        mapping = mapping.upper()
        mapping_names = self.port_mappings.keys()
        try:
            # search for abbr of mapping in mapping names
            index = [re.match("^%s" % mapping, name) is not None for name in mapping_names].index(True)
            return list(self.port_mappings.keys())[index]
        except ValueError:
            raise RuntimeError("Mapping %s not found in %s" % (mapping, mapping_names))

    def _normalize_port_name(self, name):
        """
        Map port name to the normalized form of self.DIO_PORTS
        :param name: port name or abbreviation with A or B, case insensitive
        :return: normalized port name
        :raises RuntimeError: name could not be normalized
        """
        assert isinstance(name, str)
        if not name.upper() in self.DIO_PORTS + ("A", "B"):
            raise RuntimeError("Could not map %s to port name" % name)
        return self.DIO_PORTS[0] if name.upper() in (self.DIO_PORTS[0], "A") \
                                    else self.DIO_PORTS[1]

    # --------------------------------------------------------------------------
    # Helper to format status output
    # --------------------------------------------------------------------------

    def _get_port_voltage(self, port):
        """
        Format voltage table cell value.
        """
        port_control = self.port_control[port]
        result = ""
        if port_control.enable.get() == 0:
            result += self.DIO_VOLTAGE_LEVELS[0]
        elif port_control.en_2v5.get() == 1:
            result += self.DIO_VOLTAGE_LEVELS[2]
        elif port_control.en_3v3.get() == 1:
            result += self.DIO_VOLTAGE_LEVELS[3]
        else:
            result += self.DIO_VOLTAGE_LEVELS[1]
        result += " - PG:"
        result += "YES" if port_control.power_good.get() else "NO"
        result += " - EXT:"
        result += "ON" if port_control.ext_pwr.get() else "OFF"
        return result

    def _get_voltage(self):
        """
        Format voltage table cells
        """
        return [self._get_port_voltage(port) for port in self.DIO_PORTS]

    def _format_register(self, port, content):
        """
        Format a port value according to current mapping scheme. Pins are
        grouped by 4. Pins which are not user assignable are marked with a dot.
        :param content: register content
        :return: register content as pin assignment according to current
                 mapping scheme
        """
        result = ""
        first_pin = self.mapping.first_pin
        pin_names = self.mapping.pin_names
        mapping = self.mapping.map[port]
        for i, _ in enumerate(pin_names):
            if i % 4 == 0 and i > 0:
                result = " " + result
            if i + first_pin in mapping:
                result = str(int(content & (1 << mapping.index(i + first_pin)) != 0)) + result
            else:
                result = "." + result
        return result

    def _format_registers(self, content):
        """
        Formats register content for port A and B
        :param content:
        :return:
        """
        port_a = content & self.PORT_USED_BITS_MASK
        port_b = (content >> self.PORT_BIT_SIZE) & self.PORT_USED_BITS_MASK
        return [self._format_register(self.DIO_PORTS[0], port_a),
                self._format_register(self.DIO_PORTS[1], port_b)]

    def _format_row(self, values, fill=" ", delim="|"):
        """
        Format a table row with fix colums widths. Generates row spaces using
        value list with empty strings and "-" as fill and "+" as delim.
        :param values: cell values (list of three elements)
        :param fill: fill character to use (space by default)
        :param delim: delimiter character between columns
        :return: formated row
        """
        col_widths = [14, 25, 25]
        return delim.join([
            fill + values[i].ljust(width - len(fill), fill)
            for i, width in enumerate(col_widths)
        ]) + "\n"

    # --------------------------------------------------------------------------
    # Public API
    # --------------------------------------------------------------------------

    def tear_down(self):
        """
        Terminate DIO monitoring processes
        """
        self._dio0_fault_monitor.terminate()
        self._dio1_fault_monitor.terminate()

    def set_port_mapping(self, mapping):
        """
        Change the port mapping to mapping. Mapping must denote a mapping found
        in this.port_mappings.keys() or any abbreviation allowed by
        _normalize_port_mapping. The mapping does not change the status of the
        FPGA registers. It only changes the status display and the way calls
        to set_pin_<register_name>(s) are interpreted.
        :param mapping: new mapping to be used
        :raises RuntimeError: mapping could not be found
        """
        assert isinstance(mapping, str)
        map_name = self._normalize_mapping(mapping)
        if not map_name in self.port_mappings.keys():
            raise RuntimeError("Could not map %s to port mapping" % mapping)
        self.mapping = self.port_mappings[map_name]

    def set_pin_master(self, port, pin, value=1):
        """
        Set master pin of a port. The master pin decides whether the DIO board
        pin is driven by the PS (1) or FPGA (0) register interface. To change
        the pin value the current register content is read first and modified
        before it is written back, so the register must be readable.
        :param port: port to change master assignment on
        :param pin: pin to change
        :param value: desired pin value
        """
        content = self._calc_register_value(self.FPGA_DIO_MASTER_REGISTER,
                                            port, pin, value)
        self.mboard_regs.poke32(self.FPGA_DIO_MASTER_REGISTER, content)

    def set_pin_masters(self, port, values):
        """
        Set all master pins of a port at once using a bit mask.
        :param port: port to change master pin assignment
        :param values: New pin assignment represented by an integer. Each bit of
                       values corresponds to a pin on board according to current
                       mapping scheme. Bits that do not correspond to a pin in
                       the current mapping scheme are skipped.
        """
        self._set_pin_values(port, values, self.set_pin_master)

    def set_pin_direction(self, port, pin, value=1):
        """
        Set direction pin of a port. The direction pin decides whether the DIO
        external pin is used as an output (write - value is 1) or input (read -
        value is 0). To change the pin value the current register content is
        read first and modified before it is written back, so the register must
        be readable.
        Besides the FPGA register map, the CPLD register map is also written. To
        prevent the internal line to be driven by FGPA and DIO board at the same
        time the CPLD register is written first if the direction will become an
        output. If direction will become an input the FPGA register is written
        first.
        :param port: port to change direction assignment on
        :param pin: pin to change
        :param value: desired pin value
        """
        content = self._calc_register_value(self.FPGA_DIO_DIRECTION_REGISTER,
                                            port, pin, value)
        # When setting direction pin, order matters. Always switch the component
        # first that will get the driver disabled.
        # This ensures that there wont be two drivers active at a time.
        if value == 1:  # FPGA is driver => write DIO register first
            self.mboard_cpld.poke32(self.CPLD_DIO_DIRECTION_REGISTER, content)
            self.mboard_regs.poke32(self.FPGA_DIO_DIRECTION_REGISTER, content)
        else:  # DIO is driver => write FPGA register first
            self.mboard_regs.poke32(self.FPGA_DIO_DIRECTION_REGISTER, content)
            self.mboard_cpld.poke32(self.CPLD_DIO_DIRECTION_REGISTER, content)
        # Read back values to ensure registers are in sync
        cpld_content = self.mboard_cpld.peek32(self.CPLD_DIO_DIRECTION_REGISTER)
        mbrd_content = self.mboard_regs.peek32(self.FPGA_DIO_DIRECTION_REGISTER)
        if not ((cpld_content == content) and (mbrd_content == content)):
            raise RuntimeError("Direction register content mismatch. Expected:"
                               "0x%0.8X, CPLD: 0x%0.8X, FPGA: 0x%0.8X." %
                               (content, cpld_content, mbrd_content))

    def set_pin_directions(self, port, values):
        """
        Set all direction pins of a port at once using a bit mask.
        :param port: port to change direction pin assignment
        :param values: New pin assignment represented by an integer. Each bit of
                       values corresponds to a pin on board according to current
                       mapping scheme. Bits that do not correspond to a pin in
                       the current mapping scheme are skipped.
        """
        self._set_pin_values(port, values, self.set_pin_direction)

    def set_pin_output(self, port, pin, value=1):
        """
        Set output value of a pin on a port. Setting this value only takes
        effect if the direction of the corresponding pin of this port is set
        accordingly. To change the pin value the current register content is
        read first and modified before it is written back, so the register must
        be readable.
        :param port: port to change output assignment on
        :param pin: pin to change
        :param value: desired pin value
        """
        content = self._calc_register_value(self.FPGA_DIO_OUTPUT_REGISTER,
                                            port, pin, value)
        self.mboard_regs.poke32(self.FPGA_DIO_OUTPUT_REGISTER, content)

    def set_pin_outputs(self, port, values):
        """
        Set all output pins of a port at once using a bit mask.
        :param port: port to change direction pin assignment
        :param values: New pin assignment represented by an integer. Each bit of
                       values corresponds to a pin on board according to current
                       mapping scheme. Bits that do not correspond to a pin in
                       the current mapping scheme are skipped.
        """
        self._set_pin_values(port, values, self.set_pin_output)

    def get_pin_input(self, port, pin):
        """
        Returns the input pin value of a port.
        If the pin is not assignable in the current mapping None is returned.

        :param port: port to read pin value from
        :param pin: pin value to read
        :returns: actual pin value or None if pin is not assignable
        """
        port = self._normalize_port_name(port)

        register = self.mboard_regs.peek32(self.FPGA_DIO_INPUT_REGISTER)
        if port == self.DIO_PORTS[1]:
            register = register >> self.PORT_BIT_SIZE
        register &= self.PORT_USED_BITS_MASK

        mapping = self.mapping.map[port]
        if not pin in mapping:
            raise RuntimeError("Pin %d (%s) is not a user readable pin." %
                               (pin,
                                self.mapping.pin_names[pin - self.mapping.first_pin]))
        return 0 if (register & (1 << mapping.index(pin)) == 0) else 1

    def get_pin_inputs(self, port):
        """
        Returns a bit mask of all pins for the given port.

        :param port: port to read input pins from
        :returns: Bit map of input pins, each bit of pins corresponds to a pin
                  on board according to current mapping scheme. Unused pins
                  stay zero
        """
        result = 0
        first_pin = self.mapping.first_pin
        pin_names = self.mapping.pin_names
        port = self._normalize_port_name(port)
        mapping = self.mapping.map[port]
        for i, name in enumerate(pin_names):
            if i + first_pin in mapping:
                if self.get_pin_input(port, i + first_pin):
                    result |= 1 << i
        return result

    def set_voltage_level(self, port, level):
        """
        Change voltage level of a port. This is how EN_<port>, EN_<port>_2V5 and
        EN_<port>_3V3 are set according to level::
            level EN_<port>   EN_<port>_2V5   EN_<port>_3V3
            off       0            0               0
            1V8       1            0               0
            2V5       1            1               0
            3V3       1            0               1
        If level is set to anything other than off this method waits for
        <port>_PG to go high. Waiting stops as soon as <port>_PG goes high or
        a timeout of 1s occurs.
        Note: All pins are set to zero first before the new level is applied.
        :param port: port to change power level for
        :param level: new power level
        :raises RuntimeError: power good pin did not go high
        """
        port = self._normalize_port_name(port)
        level = level.upper()
        assert port in self.DIO_PORTS
        assert level in self.DIO_VOLTAGE_LEVELS
        port_control = self.port_control[port]

        port_control.enable.set(0)
        port_control.en_2v5.set(0)
        port_control.en_3v3.set(0)
        if level == self.DIO_VOLTAGE_LEVELS[2]:
            port_control.en_2v5.set(1)
        elif level == self.DIO_VOLTAGE_LEVELS[3]:
            port_control.en_3v3.set(1)

        # wait for <port>_PG to go high
        if not level == self.DIO_VOLTAGE_LEVELS[0]: # off
            port_control.enable.set(1)
            if not poll_with_timeout(
                    lambda: port_control.power_good.get() == 1, 1000, 10):
                raise RuntimeError(
                    "Power good pin did not go high after power up")

    def set_external_power(self, port, value="1"):
        """
        Change EN_EXT_PWR_<port> to value.
        :param port: port to change external power level for
        :param value: 1 to enable external power, 0 to disable, or abbreviation
                      allowed by _normalize_pin_value.
        :raise RuntimeError: port or pin value could not be mapped
        """
        port = self._normalize_port_name(port)
        value = self._normalize_pin_value(value)
        assert port in self.DIO_PORTS
        self.port_control[port].ext_pwr.set(value)

    def status(self):
        """
        Build a full status string for the DIO AUX board, including
        I2C pin states and register content in a human readable form.
        :return: board status
        """
        result = "\n" \
               + self._format_row(["%s mapping" % self.mapping.name, self.DIO_PORTS[0], self.DIO_PORTS[1]]) \
               + self._format_row(["", "", ""], "-", "+") \
               + self._format_row(["voltage"] + self._get_voltage()) \
               + self._format_row(["", "", ""], "-", "+")

        register = self.mboard_regs.peek32(self.FPGA_DIO_MASTER_REGISTER)
        result += self._format_row(["master"] + self._format_registers(register))

        register = self.mboard_regs.peek32(self.FPGA_DIO_DIRECTION_REGISTER)
        result += self._format_row(["direction"] + self._format_registers(register))

        result += self._format_row(["", "", ""], "-", "+")

        register = self.mboard_regs.peek32(self.FPGA_DIO_OUTPUT_REGISTER)
        result += self._format_row(["output"] + self._format_registers(register))

        register = self.mboard_regs.peek32(self.FPGA_DIO_INPUT_REGISTER)
        result += self._format_row(["input"] + self._format_registers(register))
        return result

    def debug(self):
        """
        Create a debug string containing the FPGA register maps. The CPLD
        direction register is not part of the string as the DioControl maintains
        it in sync with the FPGA direction register.
        :return: register states for debug purpose in human readable form.
        """
        master = format(self.mboard_regs.peek32(self.FPGA_DIO_MASTER_REGISTER), "032b")
        direction = format(self.mboard_regs.peek32(self.FPGA_DIO_DIRECTION_REGISTER), "032b")
        output = format(self.mboard_regs.peek32(self.FPGA_DIO_OUTPUT_REGISTER), "032b")
        input = format(self.mboard_regs.peek32(self.FPGA_DIO_INPUT_REGISTER), "032b")
        return "\nmaster:    " + " ".join(re.findall('....', master)) + "\n" + \
            "direction: " + " ".join(re.findall('....', direction)) + "\n" + \
            "output:    " + " ".join(re.findall('....', output)) + "\n" + \
            "input:     " + " ".join(re.findall('....', input))


class MboardRegsControl:
    """
    Control the FPGA Motherboard registers
    """
    # Motherboard registers
    # pylint: disable=bad-whitespace
    MB_COMPAT_NUM        = 0x0000
    MB_DATESTAMP         = 0x0004
    MB_GIT_HASH          = 0x0008
    MB_SCRATCH           = 0x000C
    MB_DEVICE_ID         = 0x0010
    MB_RFNOC_INFO        = 0x0014
    MB_CLOCK_CTRL        = 0x0018
    MB_PPS_CTRL          = 0x001C
    MB_BUS_CLK_RATE      = 0x0020
    MB_BUS_COUNTER       = 0x0024
    MB_GPIO_CTRL         = 0x002C
    MB_GPIO_MASTER       = 0x0030
    MB_GPIO_RADIO_SRC    = 0x0034
    MB_GPS_CTRL          = 0x0038
    MB_GPS_STATUS        = 0x003C
    MB_DBOARD_CTRL       = 0x0040
    MB_DBOARD_STATUS     = 0x0044
    MB_NUM_TIMEKEEPERS   = 0x0048
    MB_SERIAL_NO_LO      = 0x004C
    MB_SERIAL_NO_HI      = 0x0050
    MB_MFG_TEST_CTRL     = 0x0054
    MB_MFG_TEST_STATUS   = 0x0058
    # QSFP port info consists of 2 ports of 4 lanes each,
    # both separated by their corresponding stride value
    MB_QSFP_PORT_INFO    = 0x0060
    MB_QSFP_LANE_STRIDE  = 0x4
    MB_QSFP_PORT_STRIDE  = 0x10
    # Versioning registers
    MB_VER_FPGA         = 0x0C00
    MB_VER_CPLD_IFC     = 0x0C10
    MB_VER_RF_CORE_DB0  = 0x0C20
    MB_VER_RF_CORE_DB1  = 0x0C30
    MB_VER_GPIO_IFC_DB0 = 0x0C40
    MB_VER_GPIO_IFC_DB1 = 0x0C50
    CURRENT_VERSION_OFFSET           = 0x0
    OLDEST_COMPATIBLE_VERSION_OFFSET = 0x4
    VERSION_LAST_MODIFIED_OFFSET     = 0x8
    # Timekeeper registers
    MB_TIME_NOW_LO         = 0x1000
    MB_TIME_NOW_HI         = 0x1004
    MB_TIME_EVENT_LO       = 0x1008
    MB_TIME_EVENT_HI       = 0x100C
    MB_TIME_CTRL           = 0x1010
    MB_TIME_LAST_PPS_LO    = 0x1014
    MB_TIME_LAST_PPS_HI    = 0x1018
    MB_TIME_BASE_PERIOD_LO = 0x101C
    MB_TIME_BASE_PERIOD_HI = 0x1020
    MB_TIMEKEEPER_OFFSET   = 12
    # Timekeeper control words
    MB_TIME_SET_NOW       = 0x0001
    MB_TIME_SET_NEXT_PPS  = 0x0002
    MB_TIME_SET_NEXT_SYNC = 0x0004

    # Clock control register bit masks
    CLOCK_CTRL_PLL_SYNC_DELAY   = 0x00FF0000
    CLOCK_CTRL_PLL_SYNC_DONE    = 0x00000200
    CLOCK_CTRL_PLL_SYNC_TRIGGER = 0x00000100
    CLOCK_CTRL_TRIGGER_IO_SEL   = 0x00000030
    CLOCK_CTRL_TRIGGER_PPS_SEL  = 0x00000003

    MFG_TEST_CTRL_GTY_RCV_CLK_EN = 0x00000001
    MFG_TEST_CTRL_FABRIC_CLK_EN  = 0x00000002
    MFG_TEST_AUX_REF_FREQ        = 0x03FFFFFF
    # Clock control register values
    CLOCK_CTRL_TRIG_IO_INPUT       = 0
    CLOCK_CTRL_PPS_INT_25MHz       = 0
    CLOCK_CTRL_TRIG_IO_PPS_OUTPUT  = 0x10
    CLOCK_CTRL_PPS_INT_10MHz       = 0x1
    CLOCK_CTRL_PPS_EXT             = 0x2
    # pylint: enable=bad-whitespace

    def __init__(self, label, log):
        self.log = log.getChild("MboardRegs")
        self.regs = UIO(
            label=label,
            read_only=False
        )

    def peek32(self, address):
        with self.regs as r:
            return r.peek32(address)

    def poke32(self, address, value):
        with self.regs as r:
            r.poke32(address, value)

    def set_serial_number(self, serial_number):
        """
        Set serial number register
        """
        assert len(serial_number) > 0
        assert len(serial_number) <= 8
        serial_number = serial_number + b'\x00' * (8 - len(serial_number))
        (sn_lo, sn_hi) = struct.unpack("II", serial_number)
        self.poke32(self.MB_SERIAL_NO_LO, sn_lo)
        self.poke32(self.MB_SERIAL_NO_HI, sn_hi)

    def get_compat_number(self):
        """get FPGA compat number

        This function reads back FPGA compat number.
        The return is a tuple of
        2 numbers: (major compat number, minor compat number )
        """
        #TODO: update this function to use MB_VER_FPGA and new bitfields
        compat_number = self.peek32(self.MB_COMPAT_NUM)
        minor = compat_number & 0xff
        major = (compat_number>>16) & 0xff
        return (major, minor)

    def get_db_gpio_ifc_version(self, slot_id):
        """
        Get the version of the DB GPIO interface for the corresponding slot
        """
        if slot_id == 0:
            current_version = self.peek32(self.MB_VER_GPIO_IFC_DB0)
        elif slot_id == 1:
            current_version = self.peek32(self.MB_VER_GPIO_IFC_DB1)
        else:
            raise RuntimeError("Invalid daughterboard slot id: {}".format(slot_id))

        major = (current_version>>23) & 0x1ff
        minor = (current_version>>12) & 0x7ff
        build = current_version & 0xfff
        return (major, minor, build)

    def set_device_id(self, device_id):
        """
        Set device ID
        """
        self.log.trace("Writing MB_DEVICE_ID with 0x{:08X}".format(device_id))
        return self.poke32(self.MB_DEVICE_ID, device_id)

    def get_device_id(self):
        """
        Get device ID
        """
        regs_val = self.peek32(self.MB_DEVICE_ID)
        device_id = regs_val & 0x0000ffff
        self.log.trace("Read MB_DEVICE_ID 0x{:08X}".format(device_id))
        return device_id

    def get_build_timestamp(self):
        """
        Returns the build date/time for the FPGA image.
        The return is datetime string with the  ISO 8601 format
        (YYYY-MM-DD HH:MM:SS.mmmmmm)
        """
        datestamp_rb = self.peek32(self.MB_DATESTAMP)
        if datestamp_rb > 0:
            dt_str = datetime.datetime(
                year=((datestamp_rb>>17)&0x3F)+2000,
                month=(datestamp_rb>>23)&0x0F,
                day=(datestamp_rb>>27)&0x1F,
                hour=(datestamp_rb>>12)&0x1F,
                minute=(datestamp_rb>>6)&0x3F,
                second=((datestamp_rb>>0)&0x3F))
            self.log.trace("FPGA build timestamp: {}".format(str(dt_str)))
            return str(dt_str)
        # Compatibility with FPGAs without datestamp capability
        return ''

    def get_git_hash(self):
        """
        Returns the GIT hash for the FPGA build.
        The return is a tuple of
        2 numbers: (short git hash, bool: is the tree dirty?)
        """
        git_hash_rb = self.peek32(self.MB_GIT_HASH)
        (git_hash, dirtiness_qualifier) = parse_encoded_git_hash(git_hash_rb)
        self.log.trace("FPGA build GIT Hash: {:07x} ({})".format(
            git_hash, dirtiness_qualifier))
        return (git_hash, dirtiness_qualifier)

    def _get_qsfp_lane_value(self, port, lane):
        addr = self.MB_QSFP_PORT_INFO + (port * self.MB_QSFP_PORT_STRIDE) \
                                      + (lane * self.MB_QSFP_LANE_STRIDE)
        return (self.peek32(addr) >> 8) & 0xFF

    def _get_qsfp_type(self, port=0):
        """
        Read the type of qsfp port is in the specified port
        """
        x4xx_qsfp_types = {
            0: "",    # Port not connected
            1: "1G",
            2: "10G",
            3: "A",   # Aurora
            4: "W",   # White Rabbit
            5: "100G"
        }

        lane_0_val = self._get_qsfp_lane_value(port, 0)
        num_lanes = 1

        # Because we have qsfp, we could have up to 4x connection at the port
        if lane_0_val > 0:
            for lane in range(1,4):
                lane_val = self._get_qsfp_lane_value(port, lane)
                if lane_val == lane_0_val:
                    num_lanes += 1

        if num_lanes > 1:
            return str(num_lanes) + "x" + x4xx_qsfp_types.get(lane_0_val, "")

        return x4xx_qsfp_types.get(lane_0_val, "")

    def get_fpga_type(self):
        """
        Reads the type of the FPGA image currently loaded
        Returns a string with the type (ie CG, XG, C2, etc.)
        """
        x4xx_fpga_types_by_qsfp = {
            ("", ""):          "",
            ("10G", "10G"):    "XG",
            ("10G", ""):       "X1",
            ("2x10G", ""):     "X2",
            ("4x10G", ""):     "X4",
            ("4x10G", "100G"): "X4C",
            ("100G", "100G"):  "CG",
            ("100G", ""):      "C1"
        }

        qsfp0_type = self._get_qsfp_type(0)
        qsfp1_type = self._get_qsfp_type(1)
        self.log.trace("QSFP types: ({}, {})".format(qsfp0_type, qsfp1_type))
        try:
            fpga_type = x4xx_fpga_types_by_qsfp[(qsfp0_type, qsfp1_type)]
        except KeyError:
            self.log.warning("Unrecognized QSFP type combination: ({}, {})"
                             .format(qsfp0_type, qsfp1_type))
            fpga_type = ""

        if not fpga_type and self.is_pcie_present():
            fpga_type = "LV"

        return fpga_type

    def get_num_timekeepers(self):
        """
        Return the number of timekeepers
        """
        return self.peek32(self.MB_NUM_TIMEKEEPERS)

    def get_timekeeper_time(self, tk_idx, last_pps):
        """
        Get the time in ticks

        Arguments:
        tk_idx: Index of timekeeper
        last_pps: If True, get time at last PPS. Otherwise, get time now.
        """
        addr_lo = \
            (self.MB_TIME_LAST_PPS_LO if last_pps else self.MB_TIME_NOW_LO) + \
            tk_idx * self.MB_TIMEKEEPER_OFFSET
        addr_hi = addr_lo + 4
        time_lo = self.peek32(addr_lo)
        time_hi = self.peek32(addr_hi)
        return time_hi << 32 | time_lo

    def set_timekeeper_time(self, tk_idx, ticks, next_pps):
        """
        Set the time in ticks

        Arguments:
        tk_idx: Index of timekeeper
        ticks: Time in ticks
        next_pps: If True, set time at next PPS. Otherwise, set time now.
        """
        addr_lo = \
            self.MB_TIME_EVENT_LO + tk_idx * self.MB_TIMEKEEPER_OFFSET
        addr_hi = addr_lo + 4
        addr_ctrl = \
            self.MB_TIME_CTRL + tk_idx * self.MB_TIMEKEEPER_OFFSET
        time_lo = ticks & 0xFFFFFFFF
        time_hi = (ticks >> 32) & 0xFFFFFFFF
        time_ctrl = self.MB_TIME_SET_NEXT_PPS if next_pps else self.MB_TIME_SET_NOW
        self.log.trace("Setting time on timekeeper %d to %d %s", tk_idx, ticks,
                       ("on next pps" if next_pps else "now"))
        self.poke32(addr_lo, time_lo)
        self.poke32(addr_hi, time_hi)
        self.poke32(addr_ctrl, time_ctrl)

    def set_tick_period(self, tk_idx, period_ns):
        """
        Set the time per tick in nanoseconds (tick period)

        Arguments:
        tk_idx: Index of timekeeper
        period_ns: Period in nanoseconds
        """
        addr_lo = self.MB_TIME_BASE_PERIOD_LO + tk_idx * self.MB_TIMEKEEPER_OFFSET
        addr_hi = addr_lo + 4
        period_lo = period_ns & 0xFFFFFFFF
        period_hi = (period_ns > 32) & 0xFFFFFFFF
        self.poke32(addr_lo, period_lo)
        self.poke32(addr_hi, period_hi)

    def get_rfnoc_protocol_version(self):
        """
        Gets the version of the RFNoC protocol
        """
        return self.peek32(self.MB_RFNOC_INFO) & 0xFFFF

    def get_chdr_width(self):
        """
        Gets the width of the CHDR crossbar
        """
        return self.peek32(self.MB_RFNOC_INFO) >> 16

    def is_pcie_present(self):
        """
        Return True in case the PCI_EXPRESS_BIT is set in the FPGA image, which
        means there is a PCI-Express core. False otherwise.
        """
        regs_val = self.peek32(self.MB_DEVICE_ID)
        return (regs_val & 0x80000000) != 0

class CtrlportRegs:
    """
    Control the FPGA Ctrlport registers
    """
    # pylint: disable=bad-whitespace
    IPASS_OFFSET        = 0x000010
    MB_PL_SPI_CONFIG    = 0x000020
    DB_SPI_CONFIG       = 0x000024
    MB_PL_CPLD          = 0x008000
    DB_0_CPLD           = 0x010000
    DB_1_CPLD           = 0x018000
    # pylint: enable=bad-whitespace

    min_mb_cpld_spi_divider = 2
    min_db_cpld_spi_divider = 5
    class MbPlCpldIface:
        """ Exposes access to register mapped MB PL CPLD register space """
        SIGNATURE_OFFSET = 0x0000
        REVISION_OFFSET  = 0x0004

        SIGNATURE        = 0x3FDC5C47
        MIN_REQ_REVISION = 0x20082009

        def __init__(self, regs_iface, offset, log):
            self.log = log
            self.offset = offset
            self.regs = regs_iface

        def peek32(self, addr):
            return self.regs.peek32(addr + self.offset)

        def poke32(self, addr, val):
            self.regs.poke32(addr + self.offset, val)

        def check_signature(self):
            read_signature = self.peek32(self.SIGNATURE_OFFSET)
            if self.SIGNATURE != read_signature:
                self.log.error('MB PL CPLD signature {:X} does not match '
                               'expected value {:X}'.format(read_signature, self.SIGNATURE))
                raise RuntimeError('MB PL CPLD signature {:X} does not match '
                                   'expected value {:X}'.format(read_signature, self.SIGNATURE))

        def check_revision(self):
            read_revision = self.peek32(self.REVISION_OFFSET)
            if read_revision < self.MIN_REQ_REVISION:
                error_message = ('MB PL CPLD revision {:X} is out of date. '
                                'Expected value {:X}. Update your CPLD image.'
                                .format(read_revision, self.MIN_REQ_REVISION))
                self.log.error(error_message)
                raise RuntimeError(error_message)

    class DbCpldIface:
        """ Exposes access to register mapped DB CPLD register spaces """
        def __init__(self, regs_iface, offset):
            self.offset = offset
            self.regs = regs_iface

        def peek32(self, addr):
            return self.regs.peek32(addr + self.offset)

        def poke32(self, addr, val):
            self.regs.poke32(addr + self.offset, val)

    def __init__(self, label, log):
        self.log = log.getChild("CtrlportRegs")
        self._regs_uio_opened = False
        try:
            self.regs = UIO(
                label=label,
                read_only=False
            )
        except RuntimeError:
            self.log.warning('Ctrlport regs could not be found. ' \
                             'MPM Endpoint to the FPGA is not part of this image.')
            self.regs = None
        # Initialize SPI interface to MB PL CPLD and DB CPLDs
        self.set_mb_pl_cpld_divider(self.min_mb_cpld_spi_divider)
        self.set_db_divider_value(self.min_db_cpld_spi_divider)
        self.mb_pl_cpld_regs = self.MbPlCpldIface(self, self.MB_PL_CPLD, self.log)
        self.mb_pl_cpld_regs.check_signature()
        self.mb_pl_cpld_regs.check_revision()
        self.db_0_regs = self.DbCpldIface(self, self.DB_0_CPLD)
        self.db_1_regs = self.DbCpldIface(self, self.DB_1_CPLD)

    def init(self):
        if not self._regs_uio_opened:
            self.regs._open()
            self._regs_uio_opened = True

    def deinit(self):
        if self._regs_uio_opened:
            self.regs._close()
            self._regs_uio_opened = False

    def peek32(self, addr):
        if self.regs is None:
            raise RuntimeError('The ctrlport registers were never configured!')
        if self._regs_uio_opened:
            return self.regs.peek32(addr)
        else:
            with self.regs:
                return self.regs.peek32(addr)

    def poke32(self, addr, val):
        if self.regs is None:
            raise RuntimeError('The ctrlport registers were never configured!')
        if self._regs_uio_opened:
            return self.regs.poke32(addr, val)
        else:
            with self.regs:
                return self.regs.poke32(addr, val)

    def set_mb_pl_cpld_divider(self, divider_value):
        if not self.min_mb_cpld_spi_divider <= divider_value <= 0xFFFF:
            self.log.error('Cannot set MB CPLD SPI divider to invalid value {}'
                           .format(divider_value))
            raise RuntimeError('Cannot set MB CPLD SPI divider to invalid value {}'
                               .format(divider_value))
        self.poke32(self.MB_PL_SPI_CONFIG, divider_value)

    def set_db_divider_value(self, divider_value):
        if not self.min_db_cpld_spi_divider <= divider_value <= 0xFFFF:
            self.log.error('Cannot set DB SPI divider to invalid value {}'
                           .format(divider_value))
            raise RuntimeError('Cannot set DB SPI divider to invalid value {}'
                               .format(divider_value))
        self.poke32(self.DB_SPI_CONFIG, divider_value)

    def get_db_cpld_iface(self, db_id):
        return self.db_0_regs if db_id == 0 else self.db_1_regs

    def get_mb_pl_cpld_iface(self):
        return self.mb_pl_cpld_regs

    def enable_cable_present_forwarding(self, enable=True):
        value = 1 if enable else 0
        self.poke32(self.IPASS_OFFSET, value)

class RfdcRegsControl:
    """
    Control the FPGA RFDC registers external to the XRFdc API
    """
    IQ_SWAP_OFFSET          = 0x10000
    MMCM_RESET_BASE_OFFSET  = 0x11000
    RF_RESET_CONTROL_OFFSET = 0x12000
    RF_RESET_STATUS_OFFSET  = 0x12008
    RF_STATUS_OFFSET        = 0x13000
    FABRIC_DSP_INFO_OFFSET  = 0x13008
    CAL_DATA_OFFSET         = 0x14000
    CAL_ENABLE_OFFSET       = 0x14008
    THRESHOLD_STATUS_OFFSET = 0x15000
    RF_PLL_CONTROL_OFFSET   = 0x16000
    RF_PLL_STATUS_OFFSET    = 0x16008

    def __init__(self, label, log):
        self.log = log.getChild("RfdcRegs")
        self.regs = UIO(
            label=label,
            read_only=False
        )
        self.poke32 = self.regs.poke32
        self.peek32 = self.regs.peek32

        # Index corresponds to dboard number.
        self._converter_chains_in_reset = True

    def get_threshold_status(self, slot_id, channel, threshold_idx):
        """
        Retrieves the status bit for the given threshold block
        """
        BITMASKS = {
            (0, 0, 0): 0x04,
            (0, 0, 1): 0x08,
            (0, 1, 0): 0x01,
            (0, 1, 1): 0x02,
            (1, 0, 0): 0x400,
            (1, 0, 1): 0x800,
            (1, 1, 0): 0x100,
            (1, 1, 1): 0x200,
        }
        assert (slot_id, channel, threshold_idx) in BITMASKS
        status = self.peek(self.THRESHOLD_STATUS_OFFSET)
        status_bool = (status & BITMASKS[(slot_id, channel, threshold_idx)]) != 0
        return 1 if status_bool else 0

    def set_cal_data(self, i, q):
        assert 0 <= i < 2**16
        assert 0 <= q < 2**16
        self.poke(self.CAL_DATA_OFFSET, (q << 16) | i)

    def set_cal_enable(self, channel, enable):
        assert 0 <= channel <= 3
        assert enable in [False, True]
        en = self.peek(self.CAL_ENABLE_OFFSET)
        bit_offsets = {
            0: 0,
            1: 1,
            2: 4,
            3: 5,
        }
        en_mask = 1 << bit_offsets[channel]
        en = en & ~en_mask
        self.poke(self.CAL_ENABLE_OFFSET, en | (en_mask if enable else 0))

    def enable_iq_swap(self, enable, db_id, block_id, is_dac):
        iq_swap_bit = (int(is_dac) * 8) + (db_id * 4) + block_id

        # Write IQ swap bit with a mask
        reg_val = self.peek(self.IQ_SWAP_OFFSET)
        reg_val = (reg_val & ~(1 << iq_swap_bit)) \
                    | (enable << iq_swap_bit)
        self.poke(self.IQ_SWAP_OFFSET, reg_val)

    def set_reset_mmcm(self, reset=True):
        if reset:
            # Put the MMCM in reset (active low)
            self.poke(self.MMCM_RESET_BASE_OFFSET, 0)
        else:
            # Take the MMCM out of reset
            self.poke(self.MMCM_RESET_BASE_OFFSET, 1)

    def wait_for_mmcm_locked(self, timeout=0.001):
        """
        Wait for MMCM to come to a stable locked state.
        The datasheet specifies a 100us max lock time
        """
        DATA_CLK_PLL_LOCKED = 1 << 20

        POLL_SLEEP = 0.0002
        for _ in range(int(timeout / POLL_SLEEP)):
            time.sleep(POLL_SLEEP)
            status = self.peek(self.RF_PLL_STATUS_OFFSET)
            if (status & DATA_CLK_PLL_LOCKED):
                self.log.trace("RF MMCM lock detected.")
                return
        self.log.error("MMCM failed to lock in the expected time.")
        raise RuntimeError("MMCM failed to lock within the expected time.")

    def set_gated_clock_enables(self, value=True):
        """
        Controls the clock enable for data_clk and
        data_clk_2x
        """
        ENABLE_DATA_CLK     = 1
        ENABLE_DATA_CLK_2X  = 1 << 4
        ENABLE_RF_CLK       = 1 << 8
        ENABLE_RF_CLK_2X    = 1 << 12
        if value:
            # Enable buffers gating the clocks
            self.poke(self.RF_PLL_CONTROL_OFFSET,
                ENABLE_DATA_CLK |
                ENABLE_DATA_CLK_2X |
                ENABLE_RF_CLK |
                ENABLE_RF_CLK_2X
            )
        else:
            # Disable clock buffers to have clocks gated.
            self.poke(self.RF_PLL_CONTROL_OFFSET, 0)

    def get_fabric_dsp_info(self, dboard):
        """
        Read the DSP information register and returns the
        DSP bandwidth, rx channel count and tx channel count
        """
        # Offsets
        DSP_BW     = 0 + 16*dboard
        DSP_RX_CNT = 12 + 16*dboard
        DSP_TX_CNT = 14 + 16*dboard
        # Masks
        DSP_BW_MSK = 0xFFF
        DSP_RX_CNT_MSK = 0x3
        DSP_TX_CNT_MSK = 0x3

        dsp_info = self.peek(self.FABRIC_DSP_INFO_OFFSET)
        self.log.trace("Fabric DSP for dboard %d...", dboard)
        dsp_bw = (dsp_info >> DSP_BW) & DSP_BW_MSK
        self.log.trace("  Bandwidth (MHz):  %d", dsp_bw)
        dsp_rx_cnt = (dsp_info >> DSP_RX_CNT) & DSP_RX_CNT_MSK
        self.log.trace("  Rx channel count: %d", dsp_rx_cnt)
        dsp_tx_cnt = (dsp_info >> DSP_TX_CNT) & DSP_TX_CNT_MSK
        self.log.trace("  Tx channel count: %d", dsp_tx_cnt)

        return [dsp_bw, dsp_rx_cnt, dsp_tx_cnt]

    def get_rfdc_resampling_factor(self, dboard):
        """
        Returns the appropriate decimation/interpolation factor to set in the RFDC.
        """
        # DSP vs. RFDC decimation/interpolation dictionary
        # Key: bandwidth in MHz
        # Value: (RFDC resampling factor, is Half-band resampling used?)
        RFDC_RESAMPLING_FACTOR = {
            100: (8, False), # 100 MHz BW requires 8x RFDC resampling
            200: (2, True),  # 200 MHz BW requires 2x RFDC resampling
                             # (400 MHz RFDC DSP used w/ half-band resampling)
            400: (2, False)  # 400 MHz BW requires 2x RFDC resampling
        }
        dsp_bw, _, _ = self.get_fabric_dsp_info(dboard)
        # When no RF fabric DSP is present (dsp_bw = 0), MPM should
        # simply use the default RFDC resampling factor (400 MHz).
        if dsp_bw in RFDC_RESAMPLING_FACTOR:
            rfdc_resampling_factor, halfband = RFDC_RESAMPLING_FACTOR[dsp_bw]
        else:
            rfdc_resampling_factor, halfband = RFDC_RESAMPLING_FACTOR[400]
            self.log.trace("  Using default resampling!")
        self.log.trace("  RFDC resampling:  %d", rfdc_resampling_factor)
        return (rfdc_resampling_factor, halfband)

    def set_reset_adc_dac_chains(self, reset=True):
        """ Resets or enables the ADC and DAC chain for the given dboard """

        def _wait_for_done(done_bit, timeout=5):
            """
            Wait for the specified sequence done bit when resetting or
            enabling an ADC or DAC chain. Throws an error on timeout.
            """
            status = self.peek(self.RF_RESET_STATUS_OFFSET)
            if (status & done_bit):
                return
            for _ in range(0, timeout):
                time.sleep(0.001) # 1 ms
                status = self.peek(self.RF_RESET_STATUS_OFFSET)
                if (status & done_bit):
                    return
            self.log.error("Timeout while resetting or enabling ADC/DAC chains.")
            raise RuntimeError("Timeout while resetting or enabling ADC/DAC chains.")

        # CONTROL OFFSET
        ADC_RESET   = 1 << 4
        DAC_RESET   = 1 << 8
        # STATUS OFFSET
        ADC_SEQ_DONE    = 1 << 7
        DAC_SEQ_DONE    = 1 << 11

        if reset:
            if self._converter_chains_in_reset:
                self.log.warning('Converters are already in reset. '
                                 'The reset bit will NOT be toggled.')
                return
            # Reset the ADC and DAC chains
            self.log.trace('Resetting ADC chain')
            self.poke(self.RF_RESET_CONTROL_OFFSET, ADC_RESET)
            _wait_for_done(ADC_SEQ_DONE)
            self.poke(self.RF_RESET_CONTROL_OFFSET, 0x0)

            self.log.trace('Resetting DAC chain')
            self.poke(self.RF_RESET_CONTROL_OFFSET, DAC_RESET)
            _wait_for_done(DAC_SEQ_DONE)
            self.poke(self.RF_RESET_CONTROL_OFFSET, 0x0)

            self._converter_chains_in_reset = True
        else: # enable
            self._converter_chains_in_reset = False

    def log_status(self):
        status = self.peek(self.RF_STATUS_OFFSET)
        self.log.debug("Daughterboard 0")
        self.log.debug("  @RFDC")
        self.log.debug("    DAC(1:0) TREADY    : {:02b}".format((status >> 0) & 0x3))
        self.log.debug("    DAC(1:0) TVALID    : {:02b}".format((status >> 2) & 0x3))
        self.log.debug("    ADC(1:0) I TREADY  : {:02b}".format((status >> 6) & 0x3))
        self.log.debug("    ADC(1:0) I TVALID  : {:02b}".format((status >> 10) & 0x3))
        self.log.debug("    ADC(1:0) Q TREADY  : {:02b}".format((status >> 4) & 0x3))
        self.log.debug("    ADC(1:0) Q TVALID  : {:02b}".format((status >> 8) & 0x3))
        self.log.debug("  @USER")
        self.log.debug("    ADC(1:0) OUT TVALID: {:02b}".format((status >> 12) & 0x3))
        self.log.debug("    ADC(1:0) OUT TREADY: {:02b}".format((status >> 14) & 0x3))
        self.log.debug("Daughterboard 1")
        self.log.debug("  @RFDC")
        self.log.debug("    DAC(1:0) TREADY    : {:02b}".format((status >> 16) & 0x3))
        self.log.debug("    DAC(1:0) TVALID    : {:02b}".format((status >> 18) & 0x3))
        self.log.debug("    ADC(1:0) I TREADY  : {:02b}".format((status >> 22) & 0x3))
        self.log.debug("    ADC(1:0) I TVALID  : {:02b}".format((status >> 26) & 0x3))
        self.log.debug("    ADC(1:0) Q TREADY  : {:02b}".format((status >> 20) & 0x3))
        self.log.debug("    ADC(1:0) Q TVALID  : {:02b}".format((status >> 24) & 0x3))
        self.log.debug("  @USER")
        self.log.debug("    ADC(1:0) OUT TVALID: {:02b}".format((status >> 28) & 0x3))
        self.log.debug("    ADC(1:0) OUT TREADY: {:02b}".format((status >> 30) & 0x3))

    def poke(self, addr, val):
        with self.regs:
            self.regs.poke32(addr, val)

    def peek(self, addr):
        with self.regs:
            result = self.regs.peek32(addr)
            return result

class MboardCPLD:
    """
    Control for the CPLD.
    """
    # pylint: disable=bad-whitespace
    SIGNATURE_OFFSET         = 0x0000
    COMPAT_REV_OFFSET        = 0x0004
    OLDEST_COMPAT_REV_OFFSET = 0x0008
    GIT_HASH_OFFSET          = 0x0010
    DB_ENABLE_OFFSET         = 0x0020
    SERIAL_NO_LO_OFFSET      = 0x0034
    SERIAL_NO_HI_OFFSET      = 0x0038
    CMI_OFFSET               = 0x003C

    # change these revisions only on breaking changes
    OLDEST_REQ_COMPAT_REV   = 0x20122114
    REQ_COMPAT_REV          = 0x20122114
    SIGNATURE 				= 0x0A522D27
    PLL_REF_CLOCK_ENABLED   = 1 << 2
    ENABLE_CLK_DB0          = 1 << 8
    ENABLE_CLK_DB1          = 1 << 9
    ENABLE_PRC              = 1 << 10
    DISABLE_CLK_DB0         = 1 << 12
    DISABLE_CLK_DB1         = 1 << 13
    DISABLE_PRC             = 1 << 14
    RELEASE_RST_DB0         = 1 << 16
    RELEASE_RST_DB1         = 1 << 17
    ASSERT_RST_DB0          = 1 << 20
    ASSERT_RST_DB1          = 1 << 21
    # pylint: enable=bad-whitespace

    def __init__(self, spi_dev_node, log):
        self.log = log.getChild("CPLD")
        self.regs = lib.spi.make_spidev_regs_iface(
            spi_dev_node,
            1000000, # Speed (Hz)
            0,       # SPI mode
            32,      # Addr shift
            0,       # Data shift
            0,       # Read flag
            1<<47     # Write flag
        )
        self.poke32 = self.regs.poke32
        self.peek32 = self.regs.peek32

    def enable_pll_ref_clk(self, enable=True):
        """ Enables or disables the PLL reference clock """
        def check_pll_enabled():
            return self.peek32(self.DB_ENABLE_OFFSET) \
                   & self.PLL_REF_CLOCK_ENABLED

        if enable:
            if check_pll_enabled():
                self.log.warning('PRC is already enabled. '
                                 'Writing enable anyway.')
            self.poke32(self.DB_ENABLE_OFFSET, self.ENABLE_PRC)
            if not check_pll_enabled():
                # TODO: Make this an error when the CPLD image with PRC
                # enable is readily available
                self.log.warning('PRC enable failed!')
                # raise RuntimeError('PRC enable failed!')
        else:
            if not check_pll_enabled():
                self.log.warning('PRC is already in reset. '
                                 'Writing reset anyway.')
            self.poke32(self.DB_ENABLE_OFFSET, self.DISABLE_PRC)
            if check_pll_enabled():
                # TODO: Make this an error when the CPLD image with PRC
                # enable is readily available
                self.log.warning('PRC reset failed!')
                # raise RuntimeError('PRC reset failed!')

    def enable_daughterboard(self, db_id, enable=True):
        """ Enable or disable clock forwarding to a given DB """
        if db_id == 0:
            release_reset = self.RELEASE_RST_DB0
            assert_reset = self.ASSERT_RST_DB0
        else:
            release_reset = self.RELEASE_RST_DB1
            assert_reset = self.ASSERT_RST_DB1
        value = self.peek32(self.DB_ENABLE_OFFSET)
        if enable:
            # De-assert reset
            value = (value | release_reset) & (~assert_reset)
        else: #disable
            # Assert reset
            value = (value | assert_reset) & (~release_reset)
        self.poke32(self.DB_ENABLE_OFFSET, value)

    def enable_daughterboard_support_clock(self, db_id, enable=True):
        """ Enable or disable clock forwarding to a given DB """
        if db_id == 0:
            clk_enable = self.ENABLE_CLK_DB0
            clk_disable = self.DISABLE_CLK_DB0
        else:
            clk_enable = self.ENABLE_CLK_DB1
            clk_disable = self.DISABLE_CLK_DB1
        value = self.peek32(self.DB_ENABLE_OFFSET)
        if enable:
            # Enable clock
            value = (value | clk_enable) & (~clk_disable)
        else: #disable
            # Disable clock
            value = (value | clk_disable) & (~clk_enable)
        self.poke32(self.DB_ENABLE_OFFSET, value)

    def check_signature(self):
        read_signature = self.peek32(self.SIGNATURE_OFFSET)
        if self.SIGNATURE != read_signature:
            self.log.error('MB PS CPLD signature {:X} does not match '
                           'expected value {:X}'.format(read_signature, self.SIGNATURE))
            raise RuntimeError('MB PS CPLD signature {:X} does not match '
                               'expected value {:X}'.format(read_signature, self.SIGNATURE))

    def check_compat_version(self):
        cpld_image_compat_revision = self.peek32(self.OLDEST_COMPAT_REV_OFFSET)
        if cpld_image_compat_revision < self.OLDEST_REQ_COMPAT_REV:
            self.log.error('MB CPLD oldest compatible revision is out of date. Update your CPLD image.')
            raise RuntimeError('MB CPLD oldest compatible revision is out of date. Update your CPLD image.')
        elif cpld_image_compat_revision > self.REQ_COMPAT_REV:
            self.log.error('MB CPLD oldest compatible revision is unknown. Downgrade your CPLD image.')
            raise RuntimeError('MB CPLD oldest compatible revision is unknown. Downgrade your CPLD image.')
        return True

    def has_compat_version(self, min_required_version):
        """
        Check for a minimum required version.
        """
        cpld_image_compat_revision = self.peek32(self.COMPAT_REV_OFFSET)
        return cpld_image_compat_revision >= min_required_version

    def trace_git_hash(self):
        """
        Trace build of MB CPLD
        """
        # TODO: remove check for release
        if not self.has_compat_version(0x20100809):
            self.log.trace("MB CPLD build GIT Hash register not present")
            return
        git_hash_rb = self.peek32(self.GIT_HASH_OFFSET)
        (git_hash, dirtiness_qualifier) = parse_encoded_git_hash(git_hash_rb)
        self.log.trace("MB CPLD build GIT Hash: {:07x} ({})".format(
            git_hash, dirtiness_qualifier))

    def set_serial_number(self, serial_number):
        """
        Set serial number register
        """
        assert len(serial_number) > 0
        assert len(serial_number) <= 8
        serial_number_string = str(serial_number, 'ascii')
        serial_number_string = serial_number_string.rstrip('\x00')
        serial_number_int = int(serial_number_string, 16)
        self.poke32(self.SERIAL_NO_LO_OFFSET, serial_number_int & 0xFFFFFFFF)
        self.poke32(self.SERIAL_NO_HI_OFFSET, serial_number_int >> 32)

    def set_cmi_device_ready(self, ready=True):
        """
        Inform CMI partner that this device is ready for PCI-Express communication.
        """
        value = 1 if ready else 0
        self.poke32(self.CMI_OFFSET, value)

    def get_cmi_status(self):
        """
        Return true if upstream CMI device was found.
        """
        return bool(self.peek32(self.CMI_OFFSET))

# QSFP Adapter IDs according to SFF-8436 rev 4.9 table 30
QSFP_IDENTIFIERS = {
    0x00: "Unknown or unspecified",
    0x01: "GBIC",
    0x02: "Module/connector soldered to motherboard (using SFF-8472)",
    0x03: "SFP/SFP+/SFP28",
    0x04: "300 pin XBI",
    0x05: "XENPAK",
    0x06: "XFP",
    0x07: "XFF",
    0x08: "XFP-E",
    0x09: "XPAK",
    0x0A: "X2",
    0x0B: "DWDM-SFP/SFP+ (not using SFF-8472)",
    0x0C: "QSFP (INF-8438)",
    0x0D: "QSFP+ or later (SFF-8436, SFF-8635, SFF-8665, SFF-8685 et al)",
    0x0E: "CXP or later",
    0x0F: "Shielded Mini Multilane HD0x4X",
    0x10: "Shielded Mini Multilane HD0x8X",
    0x11: "QSFP28 or later (SFF-8665 et al)",
    0x12: "CXP2 (aka CXP28) or later",
    0x13: "CDFP (Style0x1/Style2)",
    0x14: "Shielded Mini Multilane HD0x4X Fanout Cable",
    0x15: "Shielded Mini Multilane HD0x8X Fanout Cable",
    0x16: "CDFP (Style0x3)"
}

# QSFP revison compliance according to SFF-8636 rev 2.9 table 6-3
QSFP_REVISION_COMPLIANCE = {
    0x00: "Not specified.",
    0x01: "SFF-8436 Rev 4.8 or earlier",
    0x02: "SFF-8436 Rev 4.8 or earlier (except 0x186-0x189)",
    0x03: "SFF-8636 Rev 1.3 or earlier",
    0x04: "SFF-8636 Rev 1.4",
    0x05: "SFF-8636 Rev 1.5",
    0x06: "SFF-8636 Rev 2.0",
    0x07: "SFF-8636 Rev 2.5, 2.6 and 2.7",
    0x08: "SFF-8636 Rev 2.8 or later"
}

# QSFP connector types according to SFF-8029 rev 3.2 table 4-3
QSFP_CONNECTOR_TYPE = {
    0x00: "Unknown or unspecified",
    0x01: "SC (Subscriber Connector)",
    0x02: "Fibre Channel Style 1 copper connector",
    0x03: "Fibre Channel Style 2 copper connector",
    0x04: "BNC/TNC (Bayonet/Threaded Neill-Concelman)",
    0x05: "Fibre Channel coax headers",
    0x06: "Fiber Jack",
    0x07: "LC (Lucent Connector)",
    0x08: "MT-RJ (Mechanical Transfer - Registered Jack)",
    0x09: "MU (Multiple Optical)",
    0x0A: "SG",
    0x0B: "Optical Pigtail",
    0x0C: "MPO 1x12 (Multifiber Parallel Optic)",
    0x0D: "MPO 2x16",
    0x20: "HSSDC II (High S peed Serial Data Connector)",
    0x21: "Copper pigtail",
    0x22: "RJ45 (Registered Jack)",
    0x23: "No separable connector",
    0x24: "MXC 2x16"
}

class QSFPModule:
    """
    QSFPModule enables access to the I2C register interface of an QSFP module.

    The class queries the module register using I2C commands according to
    SFF-8486 rev 4.9 specification.
    """

    def __init__(self, gpio_modprs, gpio_modsel, devsymbol, log):
        """
        modprs: Name of the GPIO pin that reports module presence
        modsel: Name of the GPIO pin that controls ModSel of QSFP module
        devsymbol: Symbol name of the device used for I2C communication
        """

        self.log = log.getChild('QSFP')

        # Hold the ModSelL GPIO low for communication over I2C. Because X4xx
        # uses a I2C switch to communicate with the QSFP modules we can keep
        # ModSelL low all the way long, because each QSFP module has
        # its own I2C address (see SFF-8486 rev 4.9, chapter 4.1.1.1).
        self.modsel = Gpio(gpio_modsel, Gpio.OUTPUT, 0)

        # ModPrs pin read pin MODPRESL from QSFP connector
        self.modprs = Gpio(gpio_modprs, Gpio.INPUT, 0)

        # resolve device node name for I2C communication
        devname = i2c_dev.dt_symbol_get_i2c_bus(devsymbol)

        # create an object to access I2C register interface
        self.qsfp_regs = lib.i2c.make_i2cdev_regs_iface(
            devname, # dev node name
            0x50,    # start address according to SFF-8486 rev 4.9 chapter 7.6
            False,   # use 7 bit address schema
            100,     # timeout_ms
            1        # reg_addr_size
        )

    def _peek8(self, address):
        """
        Helper method to read bytes from the I2C register interface.

        This helper returns None in case of failed communication
        (e.g. missing or broken adapter).
        """
        try:
            return self.qsfp_regs.peek8(address)
        except RuntimeError as err:
            self.log.debug("Could not read QSFP register ({})".format(err))
            return None

    def _revision_compliance(self, status):
        """
        Map the revison compliance status byte to a human readable string
        according to SFF-8636 rev 2.9 table 6-3
        """
        assert isinstance(status, int)
        assert 0 <= status <= 255
        if status > 0x08:
            return "Reserved"
        return QSFP_REVISION_COMPLIANCE[status]

    def is_available(self):
        """
        Checks whether QSFP adapter is available by checking modprs pin
        """
        return self.modprs.get() == 0 #modprs is active low

    def enable_i2c(self, enable):
        """
        Enable or Disable I2C communication with QSFP module. Use with
        care. Because X4xx uses an I2C switch to address the QSFP ports
        there is no need to drive the modsel high (inactive). Disabled
        I2C communication leads to unwanted result when query module
        state even if the module reports availability.
        """
        self.modsel.set("0" if enable else "1") #modsel is active low

    def adapter_id(self):
        """
        Returns QSFP adapter ID as a byte (None if not present)
        """
        return self._peek8(0)

    def adapter_id_name(self):
        """
        Maps QSFP adapter ID to a human readable string according
        to SFF-8436 rev 4.9 table 30
        """
        adapter_id = self.adapter_id()
        if adapter_id is None:
            return adapter_id
        assert isinstance(adapter_id, int)
        assert 0 <= adapter_id <= 255
        if adapter_id > 0x7F:
            return "Vendor Specific"
        if adapter_id > 0x16:
            return "Reserved"
        return QSFP_IDENTIFIERS[adapter_id]

    def status(self):
        """
        Return the 2 byte QSFP adapter status according to SFF-8636
        rev 2.9 table 6-2
        """
        compliance = self._peek8(1)
        status = self._peek8(2)
        if compliance is None or status is None:
            return None
        assert isinstance(compliance, int)
        assert isinstance(status, int)
        return (compliance, status)

    def decoded_status(self):
        """
        Decode the 2 status bytes of the QSFP adapter into a tuple
        of human readable strings. See SFF-8436 rev 4.9 table 17
        """
        status = self.status()
        if not status:
            return None
        return (
            self._revision_compliance(status[0]),
            "Flat mem" if status[1] & 0b100 else "Paged mem",
            "IntL asserted" if status[1] & 0b010 else "IntL not asserted",
            "Data not ready" if status[1] & 0b001 else "Data ready"
        )

    def vendor_name(self):
        """
        Return vendor name according to SFF-8436 rev 4.9 chapter 7.6.2.14
        """
        content = [self._peek8(i) for i in range(148, 163)]

        if all(content): # list must not contain any None values
            # convert ASCII codes to string and strip whitespaces at the end
            return "".join([chr(i) for i in content]).rstrip()

        return None

    def connector_type(self):
        """
        Return connector type according to SFF-8029 rev 3.2 table 4-3
        """
        ctype = self._peek8(130)
        if ctype is None:
            return None
        assert isinstance(ctype, int)
        assert 0 <= ctype <= 255

        if (0x0D < ctype < 0x20) or (0x24 < ctype < 0x80):
            return "Reserved"
        if ctype > 0x7F:
            return "Vendor Specific"
        return QSFP_CONNECTOR_TYPE[ctype]

    def info(self):
        """
        Human readable string of important QSFP module information
        """
        if self.is_available():
            status = self.decoded_status()
            return "Vendor name:    {}\n" \
                   "id:             {}\n" \
                   "Connector type: {}\n" \
                   "Compliance:     {}\n" \
                   "Status:         {}".format(
                       self.vendor_name(), self.adapter_id_name(),
                       self.connector_type(), status[0], status[1:])

        return "No module detected"

def get_temp_sensor(sensor_names, reduce_fn=mean, log=None):
    """ Get temperature sensor reading from X4xx. """
    temps = []
    try:
        for sensor_name in sensor_names:
            temp_raw = read_thermal_sensor_value(
                sensor_name, 'in_temp_raw', 'iio', 'name')
            temp_offset = read_thermal_sensor_value(
                sensor_name, 'in_temp_offset', 'iio', 'name')
            temp_scale = read_thermal_sensor_value(
                sensor_name, 'in_temp_scale', 'iio', 'name')
            # sysfs-bus-iio linux kernel API reports temp in milli deg C
            # https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-bus-iio
            temp_in_deg_c = (temp_raw + temp_offset) * temp_scale / 1000
            temps.append(temp_in_deg_c)
    except ValueError:
        if log:
            log.warning("Error when converting temperature value.")
        temps = [-1]
    except KeyError:
        if log:
            log.warning("Can't read %s temp sensor fron iio sub-system.",
                        str(sensor_name))
        temps = [-1]
    return {
        'name': 'temperature',
        'type': 'REALNUM',
        'unit': 'C',
        'value': str(reduce_fn(temps))
    }
