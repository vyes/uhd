#
# Copyright 2019 Ettus Research, a National Instruments Company
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
"""
X400 implementation module
"""

import ast
import threading
import copy
from time import sleep
from os import path
from collections import namedtuple, OrderedDict
from pyudev import DeviceNotFoundByNameError
from usrp_mpm import lib # Pulls in everything from C++-land
from usrp_mpm import tlv_eeprom
from usrp_mpm.cores import WhiteRabbitRegsControl
from usrp_mpm.components import ZynqComponents
from usrp_mpm.sys_utils import dtoverlay
from usrp_mpm.sys_utils import ectool
from usrp_mpm.sys_utils import i2c_dev
from usrp_mpm.sys_utils.gpio import Gpio
from usrp_mpm.sys_utils.udev import dt_symbol_get_spidev
from usrp_mpm.rpc_server import no_claim, no_rpc
from usrp_mpm.mpmutils import assert_compat_number, poll_with_timeout
from usrp_mpm.periph_manager import PeriphManagerBase
from usrp_mpm.xports import XportMgrUDP
from usrp_mpm.periph_manager.x4xx_periphs import MboardRegsControl
from usrp_mpm.periph_manager.x4xx_periphs import CtrlportRegs
from usrp_mpm.periph_manager.x4xx_periphs import DioControl
from usrp_mpm.periph_manager.x4xx_periphs import MboardCPLD
from usrp_mpm.periph_manager.x4xx_periphs import QSFPModule
from usrp_mpm.periph_manager.x4xx_periphs import RfdcRegsControl
from usrp_mpm.periph_manager.x4xx_periphs import get_temp_sensor
from usrp_mpm.periph_manager.x4xx_clk_aux import ClockingAuxBrdControl
from usrp_mpm.periph_manager.x4xx_sample_pll import LMK04832Titanium
from usrp_mpm.periph_manager.x4xx_reference_pll import LMK03328Titanium
from usrp_mpm.periph_manager.x4xx_gps_mgr import X4xxGPSMgr
from usrp_mpm.dboard_manager.x4xx_db_iface import TitaniumDboardIface
from usrp_mpm.dboard_manager.zbx import ZBX

# Other clock sources are imported from ClockingAuxBrdControl
CLOCK_SOURCE_MBOARD = "mboard"

TIME_SOURCE_EXTERNAL = "external"
TIME_SOURCE_INTERNAL = "internal"
TIME_SOURCE_QSFP0 = "qsfp0"
TIME_SOURCE_GPSDO = "gpsdo"

X400_DEFAULT_INT_CLOCK_FREQ = 25e6
# this is not the frequency out of the GPSDO(GPS Lite, 20MHz) itself but
# the GPSDO on the CLKAUX board is used to fine tune the OCXO via EFC
# which is running at 10MHz
X400_DEFAULT_GPSDO_CLOCK_FREQ = 10e6
X400_DEFAULT_EXT_CLOCK_FREQ = 10e6
X400_DEFAULT_MGT_CLOCK_RATE = 156.25e6
X400_DEFAULT_MASTER_CLOCK_RATE = 122.88e6
X400_DEFAULT_TIME_SOURCE = 'internal'
X400_DEFAULT_CLOCK_SOURCE = 'internal'
X400_DEFAULT_ENABLE_PPS_EXPORT = True
X400_FPGA_COMPAT = (7, 2)
X400_DEFAULT_TRIG_DIRECTION = ClockingAuxBrdControl.DIRECTION_OUTPUT
X400_MONITOR_THREAD_INTERVAL = 1.0 # seconds
X400_RPLL_I2C_LABEL = 'rpll_i2c'
X400_DEFAULT_RPLL_REF_SOURCE = '100M_reliable_clk'
QSFPModuleConfig = namedtuple("QSFPModuleConfig", "modprs modsel devsymbol")
X400_QSFP_I2C_CONFIGS = [
        QSFPModuleConfig(modprs='QSFP0_MODPRS', modsel='QSFP0_MODSEL_n', devsymbol='qsfp0_i2c'),
        QSFPModuleConfig(modprs='QSFP1_MODPRS', modsel='QSFP1_MODSEL_n', devsymbol='qsfp1_i2c')]
RFDC_DEVICE_ID = 0
RPU_SUCCESS_REPORT = 'Success'
RPU_FAILURE_REPORT = 'Failure'
RPU_REMOTEPROC_FIRMWARE_PATH = '/lib/firmware'
RPU_REMOTEPROC_PREFIX_PATH = '/sys/class/remoteproc/remoteproc'
RPU_REMOTEPROC_PROPERTY_FIRMWARE = 'firmware'
RPU_REMOTEPROC_PROPERTY_STATE = 'state'
RPU_STATE_COMMAND_START = 'start'
RPU_STATE_COMMAND_STOP = 'stop'
RPU_STATE_OFFLINE = 'offline'
RPU_STATE_RUNNING = 'running'
RPU_MAX_FIRMWARE_SIZE = 0x100000
RPU_MAX_STATE_CHANGE_TIME_IN_MS = 10000
RPU_STATE_CHANGE_POLLING_INTERVAL_IN_MS = 100

DIOAUX_EEPROM = "dioaux_eeprom"
DIOAUX_PID = 0x4003

# pylint: disable=too-few-public-methods
class EepromTagMap:
    """
    Defines the tagmap for EEPROMs matching this magic.
    The tagmap is a dictionary mapping an 8-bit tag to a NamedStruct instance.
    The canonical list of tags and the binary layout of the associated structs
    is defined in mpm/tools/tlv_eeprom/usrp_eeprom.h. Only the subset relevant
    to MPM are included below.
    """
    magic = 0x55535250
    tagmap = {
        # 0x10: usrp_eeprom_board_info
        0x10: tlv_eeprom.NamedStruct('< H H H 7s 1x',
                                     ['pid', 'rev', 'rev_compat', 'serial']),
        # 0x11: usrp_eeprom_module_info
        0x11: tlv_eeprom.NamedStruct('< H H 7s 1x',
                                     ['module_pid', 'module_rev', 'module_serial']),
    }


###############################################################################
# Transport managers
###############################################################################
class X400XportMgrUDP(XportMgrUDP):
    "X400-specific UDP configuration"
    iface_config = {
        'sfp0': {
            'label': 'misc-enet-regs0',
            'type': 'sfp',
        },
        'sfp0_1': {
            'label': 'misc-enet-regs0-1',
            'type': 'sfp',
        },
        'sfp0_2': {
            'label': 'misc-enet-regs0-2',
            'type': 'sfp',
        },
        'sfp0_3': {
            'label': 'misc-enet-regs0-3',
            'type': 'sfp',
        },
        'sfp1': {
            'label': 'misc-enet-regs1',
            'type': 'sfp',
        },
        'sfp1_1': {
            'label': 'misc-enet-regs1-1',
            'type': 'sfp',
        },
        'sfp1_2': {
            'label': 'misc-enet-regs1-2',
            'type': 'sfp',
        },
        'sfp1_3': {
            'label': 'misc-enet-regs1-3',
            'type': 'sfp',
        },
        'int0': {
            'label': 'misc-enet-int-regs',
            'type': 'internal',
        },
        'eth0': {
            'label': '',
            'type': 'forward',
        }
    }
# pylint: enable=too-few-public-methods


###############################################################################
# Main Class
###############################################################################
class x4xx(ZynqComponents, PeriphManagerBase):
    """
    Holds X400 specific attributes and methods
    """
    #########################################################################
    # Overridables
    #
    # See PeriphManagerBase for documentation on these fields. We try and keep
    # them in the same order as they are in PeriphManagerBase for easier lookup.
    #########################################################################
    pids = {0x0410: 'x410'}
    description = "X400-Series Device"
    eeprom_search = PeriphManagerBase._EepromSearch.SYMBOL
    # This is not in the overridables section from PeriphManagerBase, but we use
    # it below
    eeprom_magic = EepromTagMap.magic
    mboard_eeprom_offset = 0
    mboard_eeprom_max_len = 256
    mboard_eeprom_magic = eeprom_magic
    mboard_info = {"type": "x4xx"}
    mboard_max_rev = 5  # RevE
    max_num_dboards = 2
    mboard_sensor_callback_map = {
        # List of motherboard sensors that are always available. There are also
        # GPS sensors, but they get added during __init__() only when there is
        # a GPS available.
        'ref_locked': 'get_ref_lock_sensor',
        'fan0': 'get_fan0_sensor',
        'fan1': 'get_fan1_sensor',
        'temp_fpga' : 'get_fpga_temp_sensor',
        'temp_internal' : 'get_internal_temp_sensor',
        'temp_main_power' : 'get_main_power_temp_sensor',
        'temp_scu_internal' : 'get_scu_internal_temp_sensor',
    }
    db_iface = TitaniumDboardIface
    dboard_eeprom_magic = eeprom_magic
    updateable_components = {
        'fpga': {
            'callback': "update_fpga",
            'path': '/lib/firmware/{}.bin',
            'reset': True,
            'check_dts_for_compatibility': True,
            'compatibility': {
                'fpga': {
                    'current': X400_FPGA_COMPAT,
                    'oldest': (7, 0),
                },
                'cpld_ifc' : {
                    'current': (2, 0),
                    'oldest': (2, 0),
                },
                'db_gpio_ifc': {
                    'current': (1, 0),
                    'oldest': (1, 0),
                },
                'rf_core_100m': {
                    'current': (1, 0),
                    'oldest': (1, 0),
                },
                'rf_core_400m': {
                    'current': (1, 0),
                    'oldest': (1, 0),
                },
            }
        },
        'dts': {
            'callback': "update_dts",
            'path': '/lib/firmware/{}.dts',
            'output': '/lib/firmware/{}.dtbo',
            'reset': False,
        },
    }
    discoverable_features = ["ref_clk_calibration", "time_export"]
    #
    # End of overridables from PeriphManagerBase
    ###########################################################################


    # X400-specific settings
    # Label for the mboard UIO
    mboard_regs_label = "mboard-regs"
    ctrlport_regs_label = "ctrlport-mboard-regs"
    # Label for RFDC UIO
    rfdc_regs_label = "rfdc-regs"
    # Label for the white rabbit UIO
    wr_regs_label = "wr-regs"
    # Override the list of updateable components
    # X4xx specific discoverable features

    # All valid sync_sources for X4xx in the form of (clock_source, time_source)
    valid_sync_sources = {
        (CLOCK_SOURCE_MBOARD, TIME_SOURCE_INTERNAL),
        (ClockingAuxBrdControl.SOURCE_INTERNAL, TIME_SOURCE_INTERNAL),
        (ClockingAuxBrdControl.SOURCE_EXTERNAL, TIME_SOURCE_EXTERNAL),
        (ClockingAuxBrdControl.SOURCE_EXTERNAL, TIME_SOURCE_INTERNAL),
        (ClockingAuxBrdControl.SOURCE_GPSDO, TIME_SOURCE_GPSDO),
        (ClockingAuxBrdControl.SOURCE_GPSDO, TIME_SOURCE_INTERNAL),
        (ClockingAuxBrdControl.SOURCE_NSYNC, TIME_SOURCE_INTERNAL),
    }

    # Maps all possible master_clock_rate (data clk rate * data SPC) values to the
    # corresponding sample rate, expected FPGA decimation, whether to configure
    # the SPLL in legacy mode (which uses a different divider), and whether half-band
    # resampling is used.
    # Using an OrderedDict to use the first rates as a preference for the default
    # rate for its corresponding decimation.
    master_to_sample_clk = OrderedDict({
        #      MCR:    (SPLL, decimation, legacy mode, half-band resampling)
        122.88e6*4:    (2.94912e9, 2, False, False), # RF (1M-8G)
        122.88e6*2:    (2.94912e9, 2, False, True),  # RF (1M-8G)
        122.88e6*1:    (2.94912e9, 8, False, False), # RF (1M-8G)
        125e6*4:       (3.00000e9, 2, False, False), # RF (1M-8G)
        200e6:         (3.00000e9, 4, True,  False), # RF (Legacy Mode)
    })

    # Describes the mapping of ADC/DAC Tiles and Blocks to DB Slot IDs
    # Follows the below structure:
    #   <slot_idx>
    #       'adc': [ (<tile_number>, <block_number>), ... ]
    #       'dac': [ (<tile_number>, <block_number>), ... ]
    RFDC_DB_MAP = [
        {
            'adc': [(0, 1), (0, 0)],
            'dac': [(0, 0), (0, 1)],
        },
        {
            'adc': [(2, 1), (2, 0)],
            'dac': [(1, 0), (1, 1)],
        },
    ]

    @classmethod
    def generate_device_info(cls, eeprom_md, mboard_info, dboard_infos):
        """
        Hard-code our product map
        """
        # Add the default PeriphManagerBase information first
        device_info = super().generate_device_info(
            eeprom_md, mboard_info, dboard_infos)
        # Then add X4xx-specific information
        mb_pid = eeprom_md.get('pid')
        device_info['product'] = cls.pids.get(mb_pid, 'unknown')
        module_serial = eeprom_md.get('module_serial')
        if module_serial is not None:
            device_info['serial'] = module_serial
        return device_info

    @staticmethod
    def list_required_dt_overlays(device_info):
        """
        Lists device tree overlays that need to be applied before this class can
        be used. List of strings.
        Are applied in order.

        eeprom_md -- Dictionary of info read out from the mboard EEPROM
        device_args -- Arbitrary dictionary of info, typically user-defined
        """
        return [device_info['product']]

    def _init_mboard_overlays(self):
        """
        Load all required overlays for this motherboard
        Overriden from the base implementation to force apply even if
        the overlay was already loaded.
        """
        requested_overlays = self.list_required_dt_overlays(
            self.device_info,
        )
        self.log.debug("Motherboard requests device tree overlays: {}".format(
            requested_overlays
        ))
        # Remove all overlays before applying new ones
        for overlay in requested_overlays:
            dtoverlay.rm_overlay_safe(overlay)
        for overlay in requested_overlays:
            dtoverlay.apply_overlay_safe(overlay)
        # Need to wait here a second to make sure the ethernet interfaces are up
        # TODO: Fine-tune this number, or wait for some smarter signal.
        sleep(1)

    ###########################################################################
    # Ctor and device initialization tasks
    ###########################################################################
    def __init__(self, args):
        super(x4xx, self).__init__()

        self._tear_down = False
        self._rpu_initialized = False
        self._status_monitor_thread = None
        self._ext_clock_freq = X400_DEFAULT_EXT_CLOCK_FREQ
        self._int_clock_freq = X400_DEFAULT_INT_CLOCK_FREQ
        self._time_source = X400_DEFAULT_TIME_SOURCE
        self._clock_source = X400_DEFAULT_CLOCK_SOURCE
        self._master_clock_rate = None
        self._sample_pll = None
        self._reference_pll = None
        self._rpll_reference_sources = {}
        self._gps_mgr = None
        self._rfdc_regs = None
        self._rfdc_ctrl = None
        self.mboard_regs_control = None
        self.ctrlport_regs = None
        self.cpld_control = None
        self.dio_control = None
        try:
            self._init_peripherals(args)
            self.init_dboards(args)
        except Exception as ex:
            self.log.error("Failed to initialize motherboard: %s", str(ex), exc_info=ex)
            self._initialization_status = str(ex)
            self._device_initialized = False
        if not self._device_initialized:
            # Don't try and figure out what's going on. Just give up.
            return
        try:
            if not args.get('skip_boot_init', False):
                self.init(args)
        except Exception as ex:
            self.log.warning("Failed to initialize device on boot: %s", str(ex))

    # The parent class versions of these functions require access to self, but
    # these versions don't.
    # pylint: disable=no-self-use
    def _read_mboard_eeprom_data(self, eeprom_path):
        """ Returns a tuple (eeprom_dict, eeprom_rawdata) for the motherboard
        EEPROM.
        """
        return tlv_eeprom.read_eeprom(eeprom_path, EepromTagMap.tagmap,
                                      EepromTagMap.magic, None)

    def _read_dboard_eeprom_data(self, eeprom_path):
        """ Returns a tuple (eeprom_dict, eeprom_rawdata) for a daughterboard
        EEPROM.
        """
        return tlv_eeprom.read_eeprom(eeprom_path, EepromTagMap.tagmap,
                                      EepromTagMap.magic, None)
    # pylint: enable=no-self-use

    def _check_fpga_compat(self):
        " Throw an exception if the compat numbers don't match up "
        actual_compat = self.mboard_regs_control.get_compat_number()
        self.log.debug("Actual FPGA compat number: {:d}.{:d}".format(
            actual_compat[0], actual_compat[1]
        ))
        assert_compat_number(
            X400_FPGA_COMPAT,
            actual_compat,
            component="FPGA",
            fail_on_old_minor=False,
            log=self.log
        )

    def _init_ref_clock_and_time(self, default_args):
        """
        Initialize clock and time sources. After this function returns, the
        reference signals going to the FPGA are valid.

        This is only called once, from _init_peripherals().
        """
        # Create SPI and I2C interfaces to the LMK registers
        spll_spi_node = dt_symbol_get_spidev('spll')
        sample_lmk_regs_iface = lib.spi.make_spidev_regs_iface(
            spll_spi_node,
            1000000,    # Speed (Hz)
            0x3,        # SPI mode
            8,          # Addr shift
            0,          # Data shift
            1<<23,      # Read flag
            0,          # Write flag
        )
        reference_lmk_regs_iface = lib.i2c.make_i2cdev_regs_iface(
            self._rpll_i2c_bus,
            0x54,   # addr
            False,  # ten_bit_addr
            100,    # timeout_ms
            1       # reg_addr_size
        )
        self._sample_pll = LMK04832Titanium(sample_lmk_regs_iface, self.log)
        self._reference_pll = LMK03328Titanium(reference_lmk_regs_iface, self.log)

        # A dictionary of tuples (source #, rate) corresponding to each
        # available RPLL reference source.
        # source # 1 => PRIREF source
        # source # 2 => SECREF source
        if int(self.mboard_info.get('rev')) == 2:
            # Only Rev B motherboards have an on-board White Rabbit DAC reference.
            self._rpll_reference_sources = {'wr_dac': (1, 25e6), X400_DEFAULT_RPLL_REF_SOURCE: (2, 100e6)}
        else:
            self._rpll_reference_sources = {X400_DEFAULT_RPLL_REF_SOURCE: (2, 100e6)}
        reference_rates = [None, None]
        for source, rate in self._rpll_reference_sources.values():
            reference_rates[source-1] = rate
        self._reference_pll.reference_rates = reference_rates

        self.init_clocks(
            clock_source=default_args.get('clock_source', self._clock_source),
            ref_clock_freq=float(default_args.get('ext_clock_freq', X400_DEFAULT_EXT_CLOCK_FREQ)),
            master_clock_rate=float(
                default_args.get('master_clock_rate', X400_DEFAULT_MASTER_CLOCK_RATE))
        )

    def _init_meas_clock(self):
        """
        Initialize the TDC measurement clock. After this function returns, the
        FPGA TDC meas_clock is valid.
        """
        # This may or may not be used for X400. Leave as a place holder
        self.log.debug("TDC measurement clock not yet implemented.")

    def _init_gps_mgr(self):
        """
        Initialize the GPS manager and the sensors.
        Note that mpmd_impl queries all available sensors at initialization
        time, in order to populate the property tree. That means we can't
        dynamically load/unload sensors. Instead, we have to make sure that
        the sensors can handle the GPS sensors, even when it's disabled. That
        is pushed into the GPS manager class.
        """
        self.log.debug("Found GPS, adding sensors.")
        gps_mgr = X4xxGPSMgr(self._clocking_auxbrd, self.log)
        # We can't use _add_public_methods(), because we only want a subset of
        # the public methods. Also, we want to know which sensors were added so
        # we can also add them to mboard_sensor_callback_map.
        new_methods = gps_mgr.extend(self)
        self.mboard_sensor_callback_map.update(new_methods)
        return gps_mgr

    def _monitor_status(self):
        """
        Status monitoring thread: This should be executed in a thread. It will
        continuously monitor status of the following peripherals:

        - REF lock (update back-panel REF LED)
        """
        self.log.trace("Launching monitor loop...")
        cond = threading.Condition()
        cond.acquire()
        while not self._tear_down:
            ref_locked = self.get_ref_lock_sensor()['value'] == 'true'
            if self._clocking_auxbrd is not None:
                self._clocking_auxbrd.set_ref_lock_led(ref_locked)
            # Now wait
            if cond.wait_for(
                    lambda: self._tear_down,
                    X400_MONITOR_THREAD_INTERVAL):
                break
        cond.release()
        self.log.trace("Terminating monitor loop.")

    def _check_rfdc_powered(self):
        if not self._rfdc_powered:
            err_msg = "RFDC is not powered on"
            self.log.error(err_msg)
            raise RuntimeError(err_msg)

    def _init_peripherals(self, args):
        """
        Turn on all peripherals. This may throw an error on failure, so make
        sure to catch it.

        Peripherals are initialized in the order of least likely to fail, to most
        likely.
        """
        # Sanity checks
        assert self.mboard_info.get('product') in self.pids.values(), \
            "Device product could not be determined!"
        # Init peripherals
        self._rpll_i2c_bus = i2c_dev.dt_symbol_get_i2c_bus(X400_RPLL_I2C_LABEL)
        if self._rpll_i2c_bus is None:
            raise RuntimeError("RPLL I2C bus could not be found")

        self._base_ref_clk_select = Gpio('BASE-REFERENCE-CLOCK-SELECT', Gpio.OUTPUT, 1)
        self._rfdc_powered = Gpio('RFDC_POWERED', Gpio.INPUT)

        # Init RPU Manager
        self.log.trace("Initializing RPU manager peripheral...")
        self.init_rpu()

        self.log.trace("Initializing Clocking Aux Board controls...")
        has_gps = False
        try:
            self._clocking_auxbrd = ClockingAuxBrdControl()
            self.log.trace("Initialized Clocking Aux Board controls")
            has_gps = self._clocking_auxbrd.is_gps_supported()
        except RuntimeError:
            self.log.warning(
                "GPIO I2C bus could not be found for the Clocking Aux Board, "
                "disabling Clocking Aux Board functionality.")
            self._clocking_auxbrd = None

        if self._clocking_auxbrd is not None:
            self._clock_source = ClockingAuxBrdControl.SOURCE_INTERNAL
            self._add_public_methods(self._clocking_auxbrd, "clkaux")
        else:
            self._clock_source = CLOCK_SOURCE_MBOARD

        # Init CPLD before talking to clocking ICs
        cpld_spi_node = dt_symbol_get_spidev('mb_cpld')
        self.cpld_control = MboardCPLD(cpld_spi_node, self.log)
        self.cpld_control.check_signature()
        self.cpld_control.check_compat_version()
        self.cpld_control.trace_git_hash()

        # Init clocking after CPLD as the SPLL communication is relying on it.
        self._check_rfdc_powered()
        self._init_ref_clock_and_time(args)
        self._init_meas_clock()
        self.cpld_control.enable_pll_ref_clk()

        # Overlay must be applied after clocks have been configured
        self.overlay_apply()

        # Init Mboard Regs
        self.log.trace("Initializing MBoard reg controls...")
        serial_number = self._eeprom_head.get("module_serial")
        if serial_number is None:
            self.log.warning(
                'Module serial number not programmed, falling back to motherboard serial')
            serial_number = self._eeprom_head["serial"]
        self.mboard_regs_control = MboardRegsControl(
            self.mboard_regs_label, self.log)
        self._check_fpga_compat()
        self.mboard_regs_control.set_serial_number(serial_number)
        self.mboard_regs_control.get_git_hash()
        self.mboard_regs_control.get_build_timestamp()

        # Create control for RFDC Regs
        self._rfdc_regs = RfdcRegsControl(self.rfdc_regs_label, self.log)
        # Instantiate XRFdc Control API
        self._rfdc_ctrl = lib.rfdc.rfdc_ctrl()
        self._rfdc_ctrl.init(RFDC_DEVICE_ID)

        self._update_fpga_type()

        # Force reset the RFDC to ensure it is in a good state
        self.set_reset_rfdc(reset=True)
        self.set_reset_rfdc(reset=False)

        # Synchronize SYSREF and clock distributed to all converters
        self.rfdc_sync()

        # The initial default mcr only works if we have an FPGA with
        # a decimation of 2. But we need the overlay applied before we
        # can detect decimation, and that requires clocks to be initialized.
        self.set_master_clock_rate(self._get_default_mcr())

        # PPS to Timekeeper configuration
        self._config_pps_to_timekeeper()

        # Init ctrlport endpoint
        self.ctrlport_regs = CtrlportRegs(
            self.ctrlport_regs_label, self.log)

        # Init IPass cable status forwarding and CMI
        self.cpld_control.set_serial_number(serial_number)
        self.cpld_control.set_cmi_device_ready(
            self.mboard_regs_control.is_pcie_present())
        # The CMI transmission can be disabled by setting the cable status
        # to be not connected. All images except for the LV PCIe variant
        # provide a fixed "cables are unconnected" status. The LV PCIe image
        # reports the correct status. As the FPGA holds this information it
        # is possible to always enable the iPass cable present forwarding.
        self.ctrlport_regs.enable_cable_present_forwarding(True)

        # Init DIO
        if self._check_compat_aux_board(DIOAUX_EEPROM, DIOAUX_PID):
            self.dio_control = DioControl(self.mboard_regs_control,
                                          self.cpld_control, self.log)
            # add dio_control public methods to MPM API
            self._add_public_methods(self.dio_control, "dio")

        # Init QSFP modules
        for idx, config in enumerate(X400_QSFP_I2C_CONFIGS):
            attr = QSFPModule(
                config.modprs, config.modsel, config.devsymbol, self.log)
            setattr(self, "_qsfp_module{}".format(idx), attr)
            self._add_public_methods(attr, "qsfp{}".format(idx))

        # Init GPS
        if has_gps:
            self._gps_mgr = self._init_gps_mgr()
        # Init CHDR transports
        self._xport_mgrs = {
            'udp': X400XportMgrUDP(self.log, args),
        }
        # Spawn status monitoring thread
        self.log.trace("Spawning status monitor thread...")
        self._status_monitor_thread = threading.Thread(
            target=self._monitor_status,
            name="X4xxStatusMonitorThread",
            daemon=True,
        )
        self._status_monitor_thread.start()
        # Init complete.
        self.log.debug("Device info: {}".format(self.device_info))

    def _find_converters(self, slot, direction, channel):
        """
        Returns a list of (tile_id, block_id, is_dac) tuples describing
        the data converters associated with a given channel and direction.
        """
        if direction not in ('rx', 'tx', 'both'):
            self.log.error('Invalid direction "{}". Cannot find '
                           'associated data converters'.format(direction))
            raise RuntimeError('Invalid direction "{}". Cannot find '
                               'associated data converters'.format(direction))
        if str(channel) not in ('0', '1', 'both'):
            self.log.error('Invalid channel "{}". Cannot find '
                           'associated data converters'.format(channel))
            raise RuntimeError('Invalid channel "{}". Cannot find '
                               'associated data converters'.format(channel))
        data_converters = []
        rfdc_map = self.RFDC_DB_MAP[slot]

        if direction in ('rx', 'both'):
            if str(channel) == '0' or str(channel) == 'both':
                (tile_id, block_id) = rfdc_map['adc'][0]
                data_converters.append((tile_id, block_id, False))
            if str(channel) == '1' or str(channel) == 'both':
                (tile_id, block_id) = rfdc_map['adc'][1]
                data_converters.append((tile_id, block_id, False))
        if direction in ('tx', 'both'):
            if str(channel) == '0' or str(channel) == 'both':
                (tile_id, block_id) = rfdc_map['dac'][0]
                data_converters.append((tile_id, block_id, True))
            if str(channel) == '1' or str(channel) == 'both':
                (tile_id, block_id) = rfdc_map['dac'][1]
                data_converters.append((tile_id, block_id, True))

        return data_converters

    def _check_compat_aux_board(self, name, pid):
        """
        Check whether auxiliary board given by name and pid can be found
        :param name: symbol name of the auxiliary board which is used as
                     lookup for the dictionary of available boards.
        :param pid:  PID the board must have to be considered compatible
        :return True if board is available with matching PID,
                False otherwise
        """
        assert(isinstance(self._aux_board_infos, dict)), "No EEPROM data"
        board_info = self._aux_board_infos.get(name, None)
        if board_info is None:
            self.log.warning("Board for %s not present" % name)
            return False
        if board_info.get("pid", 0) != pid:
            self.log.error("Expected PID for board %s to be 0x%04x but found "
                           "0x%04x" % (name, pid, board_info["pid"]))
            return False
        self.log.debug("Found compatible board for %s "
                       "(PID: 0x%04x)" % (name, board_info["pid"]))
        return True

    def _set_interpolation_decimation(self, tile, block, is_dac, factor):
        """
        Set the provided interpolation/decimation factor to the
        specified ADC/DAC tile, block

        Only gets called from set_reset_rfdc().
        """
        # Map the interpolation/decimation factor to fabric words.
        # Keys: is_dac (False -> ADC, True -> DAC) and factor
        FABRIC_WORDS_ARRAY = { # [is_dac][factor]
            False: {0: 16, 1: 16, 2: 8, 4: 4, 8: 2}, # ADC
            True: {0: -1, 1: -1, 2: 16, 4: 8, 8: 4} # DAC
        }
        # Disable FIFO
        self._rfdc_ctrl.set_data_fifo_state(tile, is_dac, False)
        # Define fabric rate based on given factor.
        fab_words = FABRIC_WORDS_ARRAY[is_dac].get(int(factor))
        if fab_words == -1:
            raise RuntimeError('Unsupported dec/int factor in RFDC')
        # Define dec/int constant based on integer factor
        if factor == 0:
            int_dec = lib.rfdc.interp_decim_options.INTERP_DECIM_OFF
        elif factor == 1:
            int_dec = lib.rfdc.interp_decim_options.INTERP_DECIM_1X
        elif factor == 2:
            int_dec = lib.rfdc.interp_decim_options.INTERP_DECIM_2X
        elif factor == 4:
            int_dec = lib.rfdc.interp_decim_options.INTERP_DECIM_4X
        elif factor == 8:
            int_dec = lib.rfdc.interp_decim_options.INTERP_DECIM_8X
        else:
            raise RuntimeError('Unsupported dec/int factor in RFDC')
        # Update tile, block settings...
        self.log.debug(
            "Setting %s for %s tile %d, block %d to %dx",
            ('interpolation' if is_dac else 'decimation'),
            'DAC' if is_dac else 'ADC', tile, block, factor)
        if is_dac:
            # Set interpolation
            self._rfdc_ctrl.set_interpolation_factor(tile, block, int_dec)
            self.log.trace(
                "  interpolation: %s",
                self._rfdc_ctrl.get_interpolation_factor(tile, block).name)
            # Set fabric write rate
            self._rfdc_ctrl.set_data_write_rate(tile, block, fab_words)
            self.log.trace(
                "  Read words: %d",
                self._rfdc_ctrl.get_data_write_rate(tile, block, True))
        else: # ADC
            # Set decimation
            self._rfdc_ctrl.set_decimation_factor(tile, block, int_dec)
            self.log.trace(
                "  Decimation: %s",
                self._rfdc_ctrl.get_decimation_factor(tile, block).name)
            # Set fabric read rate
            self._rfdc_ctrl.set_data_read_rate(tile, block, fab_words)
            self.log.trace(
                "  Read words: %d",
                self._rfdc_ctrl.get_data_read_rate(tile, block, False))
        # Clear interrupts
        self._rfdc_ctrl.clear_data_fifo_interrupts(tile, block, is_dac)
        # Enable FIFO
        self._rfdc_ctrl.set_data_fifo_state(tile, is_dac, True)

    def set_reset_rfdc(self, reset=True):
        """
        Resets the RFDC FPGA components or takes them out of reset.
        """
        if reset:
            # Assert RFDC AXI-S, filters and associated gearbox reset.
            self._rfdc_regs.set_reset_adc_dac_chains(reset=True)
            self._rfdc_regs.log_status()
            # Assert Radio clock PLL reset
            self._rfdc_regs.set_reset_mmcm(reset=True)
            # Resetting the MMCM will automatically disable clock buffers
            return

        # Take upstream MMCM out of reset
        self._rfdc_regs.set_reset_mmcm(reset=False)

        # Once the MMCM has locked, enable driving the clocks
        # to the rest of the design. Poll lock status for up
        # to 1 ms
        self._rfdc_regs.wait_for_mmcm_locked(timeout=0.001)
        self._rfdc_regs.set_gated_clock_enables(value=True)

        # De-assert RF signal chain reset
        self._rfdc_regs.set_reset_adc_dac_chains(reset=False)

        # Restart tiles in XRFdc
        # All ADC Tiles
        if not self._rfdc_ctrl.reset_tile(-1, False):
            self.log.warning('Error starting up ADC tiles')
        # All DAC Tiles
        if not self._rfdc_ctrl.reset_tile(-1, True):
            self.log.warning('Error starting up DAC tiles')

        # Set sample rate for all active tiles
        active_converters = set()
        for db_idx, db_info in enumerate(self.RFDC_DB_MAP):
            db_rfdc_resamp, _ = self._rfdc_regs.get_rfdc_resampling_factor(db_idx)
            for converter_type, tile_block_set in db_info.items():
                for tile, block in tile_block_set:
                    is_dac = converter_type != 'adc'
                    active_converter_tuple = (tile, block, db_rfdc_resamp, is_dac)
                    active_converters.add(active_converter_tuple)
        for tile, block, resampling_factor, is_dac in active_converters:
            self._rfdc_ctrl.reset_mixer_settings(tile, block, is_dac)
            self._rfdc_ctrl.set_sample_rate(tile, is_dac, self.get_spll_freq())
            self._set_interpolation_decimation(tile, block, is_dac, resampling_factor)

        self._rfdc_regs.log_status()

        # Set RFDC NCO reset event source to analog SYSREF
        for tile, block, _, is_dac in active_converters:
            self._rfdc_ctrl.set_nco_event_src(tile, block, is_dac)

    def init_rpu(self):
        """
        Initializes the RPU image manager
        """
        if self._rpu_initialized:
            return

        # Check presence/state of RPU cores
        try:
            for core_number in [0, 1]:
                self.log.trace(
                    "RPU Core %d state: %s",
                    core_number,
                    self.get_rpu_state(core_number))
                # TODO [psisterh, 5 Dec 2019]
                # Should we force core to
                #   stop if running or in error state?
            self.log.trace("Initialized RPU cores successfully.")
            self._rpu_initialized = True
        except FileNotFoundError:
            self.log.warning(
                "Failed to initialize RPU: remoteproc sysfs not present.")

    def rfdc_sync(self):
        """
        Multi-tile Synchronization on both ADC and DAC
        """
        # These numbers are determined from the procedure mentioned in
        # PG269 section "Advanced Multi-Tile Synchronization API use".
        adc_latency = 1228  # ADC delay in sample clocks
        dac_latency = 800   # DAC delay in sample clocks

        # Ideally, this would be a set to avoiding duplicate indices,
        # but we need to use a list for compatibility with the rfdc_ctrl
        # C++ interface (std::vector)
        adc_tiles_to_sync = []
        dac_tiles_to_sync = []

        rfdc_map = self.RFDC_DB_MAP
        for db_id in rfdc_map:
            for converter_type, tile_block_set in db_id.items():
                for tile, _ in tile_block_set:
                    if converter_type == 'adc':
                        if tile not in adc_tiles_to_sync:
                            adc_tiles_to_sync.append(tile)
                    else:  # dac
                        if tile not in dac_tiles_to_sync:
                            dac_tiles_to_sync.append(tile)

        self._rfdc_ctrl.sync_tiles(adc_tiles_to_sync, False, adc_latency)
        self._rfdc_ctrl.sync_tiles(dac_tiles_to_sync, True, dac_latency)

        # We expect all sync'd tiles to have equal latencies
        # Sets don't add duplicates, so we can use that to look
        # for erroneous tiles
        adc_tile_latency_set = set()
        for tile in adc_tiles_to_sync:
            adc_tile_latency_set.add(
                self._rfdc_ctrl.get_tile_latency(tile, False))
        if len(adc_tile_latency_set) != 1:
            raise RuntimeError("ADC tiles failed to sync properly")

        dac_tile_latency_set = set()
        for tile in dac_tiles_to_sync:
            dac_tile_latency_set.add(
                self._rfdc_ctrl.get_tile_latency(tile, True))
        if len(dac_tile_latency_set) != 1:
            raise RuntimeError("DAC tiles failed to sync properly")

    def rfdc_set_nco_freq(self, direction, slot_id, channel, freq):
        """
        Sets the RFDC NCO Frequency for the specified channel
        """
        converters = self._find_converters(slot_id, direction, channel)
        assert len(converters) == 1
        (tile_id, block_id, is_dac) = converters[0]

        if not self._rfdc_ctrl.set_if(tile_id, block_id, is_dac, freq):
            raise RuntimeError("Error setting RFDC IF Frequency")
        return self._rfdc_ctrl.get_nco_freq(tile_id, block_id, is_dac)

    def rfdc_get_nco_freq(self, direction, slot_id, channel):
        """
        Gets the RFDC NCO Frequency for the specified channel
        """
        converters = self._find_converters(slot_id, direction, channel)
        assert len(converters) == 1
        (tile_id, block_id, is_dac) = converters[0]

        return self._rfdc_ctrl.get_nco_freq(tile_id, block_id, is_dac)

    ###########################################################################
    # Session init and deinit
    ###########################################################################
    def init(self, args):
        """
        Calls init() on the parent class, and then programs the Ethernet
        dispatchers accordingly.
        """
        if not self._device_initialized:
            self.log.warning(
                "Cannot run init(), device was never fully initialized!")
            return False

        # We need to disable the PPS out during clock and dboard initialization in order
        # to avoid glitches.
        if self._clocking_auxbrd is not None:
            self._clocking_auxbrd.set_trig(False)

        # If the caller has not specified clock_source or time_source, set them
        # to the values currently configured.
        args['clock_source'] = args.get('clock_source', self._clock_source)
        args['time_source'] = args.get('time_source', self._time_source)
        self.set_sync_source(args)

        # If a Master Clock Rate was specified,
        # re-configure the Sample PLL and all downstream clocks
        if 'master_clock_rate' in args:
            self.set_master_clock_rate(float(args['master_clock_rate']))

        # Initialize CtrlportRegs (manually opens the UIO resource for faster access)
        self.ctrlport_regs.init()

        # Note: The parent class takes care of calling init() on all the
        # daughterboards
        result = super(x4xx, self).init(args)

        # Now the clocks are all enabled, we can also enable PPS export:
        if self._clocking_auxbrd is not None:
            self._clocking_auxbrd.set_trig(
                args.get('pps_export', X400_DEFAULT_ENABLE_PPS_EXPORT),
                args.get('trig_direction', X400_DEFAULT_TRIG_DIRECTION)
                )

        for xport_mgr in self._xport_mgrs.values():
            xport_mgr.init(args)
        return result

    def deinit(self):
        """
        Clean up after a UHD session terminates.
        """
        if not self._device_initialized:
            self.log.warning(
                "Cannot run deinit(), device was never fully initialized!")
            return

        if self.get_ref_lock_sensor()['unit'] != 'locked':
            self.log.error("ref clocks aren't locked, falling back to default")
            source = {"clock_source": X400_DEFAULT_CLOCK_SOURCE,
                      "time_source": X400_DEFAULT_TIME_SOURCE
                     }
            self.set_sync_source(source)
        super(x4xx, self).deinit()
        self.ctrlport_regs.deinit()
        for xport_mgr in self._xport_mgrs.values():
            xport_mgr.deinit()

    def tear_down(self):
        """
        Tear down all members that need to be specially handled before
        deconstruction.
        For X400, this means the overlay.
        """
        self.log.trace("Tearing down X4xx device...")
        self._tear_down = True
        if self._device_initialized:
            self._status_monitor_thread.join(3 * X400_MONITOR_THREAD_INTERVAL)
            if self._status_monitor_thread.is_alive():
                self.log.error("Could not terminate monitor thread! "
                               "This could result in resource leaks.")
        # call tear_down on daughterboards first
        super(x4xx, self).tear_down()
        if self.dio_control is not None:
            self.dio_control.tear_down()
        # remove x4xx overlay
        active_overlays = self.list_active_overlays()
        self.log.trace("X4xx has active device tree overlays: {}".format(
            active_overlays
        ))
        for overlay in active_overlays:
            dtoverlay.rm_overlay(overlay)

    ###########################################################################
    # Transport API
    ###########################################################################
    # pylint: disable=no-self-use
    def get_chdr_link_types(self):
        """
        This will only ever return a single item (udp).
        """
        return ["udp"]
    # pylint: enable=no-self-use

    def get_chdr_link_options(self, xport_type):
        """
        Returns a list of dictionaries. Every dictionary contains information
        about one way to connect to this device in order to initiate CHDR
        traffic.

        The interpretation of the return value is very highly dependant on the
        transport type (xport_type).
        For UDP, the every entry of the list has the following keys:
        - ipv4 (IP Address)
        - port (UDP port)
        - link_rate (bps of the link, e.g. 10e9 for 10GigE)
        """
        if xport_type not in self._xport_mgrs:
            self.log.warning("Can't get link options for unknown link type: `{}'.")
            return []
        if xport_type == "udp":
            return self._xport_mgrs[xport_type].get_chdr_link_options(
                self.mboard_info['rpc_connection'])
        # else:
        return self._xport_mgrs[xport_type].get_chdr_link_options()

    ###########################################################################
    # Device info
    ###########################################################################
    def get_device_info_dyn(self):
        """
        Append the device info with current IP addresses.
        """
        if not self._device_initialized:
            return {}
        device_info = self._xport_mgrs['udp'].get_xport_info()
        device_info.update({
            'fpga_version': "{}.{}".format(
                *self.mboard_regs_control.get_compat_number()),
            'fpga_version_hash': "{:x}.{}".format(
                *self.mboard_regs_control.get_git_hash()),
            'fpga': self.updateable_components.get('fpga', {}).get('type', ""),
        })
        return device_info

    def set_device_id(self, device_id):
        """
        Sets the device ID for this motherboard.
        The device ID is used to identify the RFNoC components associated with
        this motherboard.
        """
        self.mboard_regs_control.set_device_id(device_id)

    def get_device_id(self):
        """
        Gets the device ID for this motherboard.
        The device ID is used to identify the RFNoC components associated with
        this motherboard.
        """
        return self.mboard_regs_control.get_device_id()

    @no_claim
    def get_proto_ver(self):
        """
        Return RFNoC protocol version
        """
        return self.mboard_regs_control.get_rfnoc_protocol_version()

    @no_claim
    def get_chdr_width(self):
        """
        Return RFNoC CHDR width
        """
        return self.mboard_regs_control.get_chdr_width()

    def is_db_gpio_ifc_present(self, slot_id):
        """
        Return if daughterboard GPIO interface at 'slot_id' is present in the FPGA
        """
        db_gpio_version = self.mboard_regs_control.get_db_gpio_ifc_version(slot_id)
        return db_gpio_version[0] > 0

    ###########################################################################
    # Clock/Time API
    ###########################################################################
    def get_clock_sources(self):
        """
        Lists all available clock sources.
        """
        avail_clk_sources = [CLOCK_SOURCE_MBOARD]
        if self._clocking_auxbrd:
            avail_clk_sources.extend([ClockingAuxBrdControl.SOURCE_INTERNAL,
                                      ClockingAuxBrdControl.SOURCE_EXTERNAL])
            if self._clocking_auxbrd.is_nsync_supported():
                avail_clk_sources.append(ClockingAuxBrdControl.SOURCE_NSYNC)
            if self._gps_mgr:
                avail_clk_sources.append(ClockingAuxBrdControl.SOURCE_GPSDO)
        self.log.trace("Available clock sources are: {}".format(avail_clk_sources))
        return avail_clk_sources

    def get_clock_source(self):
        """
        Returns the currently selected clock source
        """
        return self._clock_source

    def set_clock_source(self, *args):
        """
        Ensures the new reference clock source and current
        time source pairing is valid and sets both.
        """
        clock_source = args[0]
        time_source = self._time_source
        assert clock_source is not None
        assert time_source is not None
        if (clock_source, time_source) not in self.valid_sync_sources:
            old_time_source = time_source
            if clock_source in (CLOCK_SOURCE_MBOARD, ClockingAuxBrdControl.SOURCE_INTERNAL):
                time_source = TIME_SOURCE_INTERNAL
            elif clock_source == ClockingAuxBrdControl.SOURCE_EXTERNAL:
                time_source = TIME_SOURCE_EXTERNAL
            elif clock_source == ClockingAuxBrdControl.SOURCE_GPSDO:
                time_source = TIME_SOURCE_GPSDO
            self.log.warning(
                f"Time source '{old_time_source}' is an invalid selection with "
                f"clock source '{clock_source}'. "
                f"Coercing time source to '{time_source}'")
        source = {"clock_source": clock_source, "time_source": time_source}
        try:
            self.set_sync_source(source)
        except RuntimeError:
            err = f"Setting clock source to {clock_source} " \
                  f"failed, falling back to {X400_DEFAULT_CLOCK_SOURCE}"
            self.log.error(err)
            source = {"clock_source": X400_DEFAULT_CLOCK_SOURCE,
                      "time_source": X400_DEFAULT_TIME_SOURCE
                     }
            self.set_sync_source(source)
            raise RuntimeError(err)

    def set_ref_clock_freq(self, freq):
        """
        Tell our USRP what the frequency of the external reference clock is.

        Will throw if it's not a valid value.
        """
        if (freq < 1e6) or (freq > 50e6):
            raise RuntimeError('External reference clock frequency is out of the valid range.')
        if (freq % 40e3) != 0:
            # TODO: implement exception of a 50e3 step size for 200MSPS
            raise RuntimeError('External reference clock frequency is of incorrect step size.')
        self._ext_clock_freq = freq
        # If the external source is currently selected we also need to re-apply the
        # time_source. This call also updates the dboards' rates.
        if self.get_clock_source() == ClockingAuxBrdControl.SOURCE_EXTERNAL:
            self.set_time_source(self.get_time_source())

    def get_ref_clock_freq(self):
        " Returns the currently active reference clock frequency"
        clock_source = self.get_clock_source()
        if clock_source == CLOCK_SOURCE_MBOARD:
            return self._int_clock_freq
        if clock_source == ClockingAuxBrdControl.SOURCE_GPSDO:
            return X400_DEFAULT_GPSDO_CLOCK_FREQ
        # clock_source == "external":
        return self._ext_clock_freq

    def get_time_sources(self):
        " Returns list of valid time sources "
        avail_time_sources = [
            TIME_SOURCE_INTERNAL, TIME_SOURCE_EXTERNAL, TIME_SOURCE_QSFP0]
        if self._gps_mgr:
            avail_time_sources.append(TIME_SOURCE_GPSDO)
        self.log.trace("Available time sources are: {}".format(avail_time_sources))
        return avail_time_sources

    def get_time_source(self):
        " Return the currently selected time source "
        return self._time_source

    def set_time_source(self, time_source):
        """
        Set a time source

        This will call set_sync_source() internally, and use the current clock
        source as a clock source. If the current clock source plus the requested
        time source is not a valid combination, it will coerce the clock source
        to a valid choice and print a warning.
        """
        clock_source = self._clock_source
        assert clock_source is not None
        assert time_source is not None
        if (clock_source, time_source) not in self.valid_sync_sources:
            old_clock_source = clock_source
            if time_source == TIME_SOURCE_QSFP0:
                clock_source = CLOCK_SOURCE_MBOARD
            elif time_source == TIME_SOURCE_INTERNAL:
                clock_source = CLOCK_SOURCE_MBOARD
            elif time_source == TIME_SOURCE_EXTERNAL:
                clock_source = ClockingAuxBrdControl.SOURCE_EXTERNAL
            elif time_source == TIME_SOURCE_GPSDO:
                clock_source = ClockingAuxBrdControl.SOURCE_GPSDO
            self.log.warning(
                'Clock source {} is an invalid selection with time source {}. '
                'Coercing clock source to {}'
                .format(old_clock_source, time_source, clock_source))
        self.set_sync_source(
            {"time_source": time_source, "clock_source": clock_source})

    def get_sync_sources(self):
        """
        Enumerates permissible sync sources.
        """
        return [{
            "time_source": time_source,
            "clock_source": clock_source
        } for (clock_source, time_source) in self.valid_sync_sources]

    def set_sync_source(self, args):
        """
        Selects reference clock and PPS sources. Unconditionally re-applies the
        time source to ensure continuity between the reference clock and time
        rates.
        Note that if we change the source such that the time source is changed
        to 'external', then we need to also disable exporting the reference
        clock (RefOut and PPS-In are the same SMA connector).
        """
        # Check the clock source, time source, and combined pair are valid:
        clock_source = args.get('clock_source', self._clock_source)
        if clock_source not in self.get_clock_sources():
            raise ValueError(f'Clock source {clock_source} is not a valid selection')
        time_source = args.get('time_source', self._time_source)
        if time_source not in self.get_time_sources():
            raise ValueError(f'Time source {time_source} is not a valid selection')
        if (clock_source, time_source) not in self.valid_sync_sources:
            raise ValueError(
                f'Clock and time source pair ({clock_source}, {time_source}) is '
                'not a valid selection')
        # Sanity checks complete.
        # Now see if we can keep the current settings, or if we need to run an
        # update of sync sources:
        if (clock_source == self._clock_source) and (time_source == self._time_source):
            spll_status = self._sample_pll.get_status()
            rpll_status = self._reference_pll.get_status()
            if (spll_status['PLL1 lock'] and spll_status['PLL2 lock'] and
                    rpll_status['PLL1 lock'] and rpll_status['PLL2 lock']):
                # Nothing change no need to do anything
                self.log.trace("New sync source assignment matches "
                               "previous assignment. Ignoring update command.")
                return
            self.log.debug(
                "Although the clock source has not changed, some PLLs "
                "are not locked. Setting clock source again...")
            self.log.trace("- SPLL status: {}".format(spll_status))
            self.log.trace("- RPLL status: {}".format(rpll_status))
        # Start setting sync source
        self.log.debug(
            f"Setting sync source to time_source={time_source}, "
            f"clock_source={clock_source}")
        self._time_source = time_source
        # Reset downstream clocks (excluding RPLL)
        self.reset_clocks(value=True, reset_list=('db_clock', 'cpld', 'rfdc', 'spll'))
        self.set_brc_source(clock_source)
        self.set_master_clock_rate(self._master_clock_rate)
        # Reminder: RefOut and PPSIn share an SMA. Besides, you can't export an
        # external clock. We are thus not checking for time_source == 'external'
        # because that's a subset of clock_source == 'external'.
        # We also disable clock exports for 'mboard', because the mboard clock
        # does not get routed back to the clocking aux board and thus can't be
        # exported either.
        if clock_source in (ClockingAuxBrdControl.SOURCE_EXTERNAL, CLOCK_SOURCE_MBOARD):
            self._clocking_auxbrd.export_clock(enable=False)

    def init_clocks(self,
                    clock_source,
                    ref_clock_freq,
                    master_clock_rate=X400_DEFAULT_MASTER_CLOCK_RATE,
                    internal_brc_rate=X400_DEFAULT_INT_CLOCK_FREQ,
                    internal_brc_source=X400_DEFAULT_RPLL_REF_SOURCE,
                    usr_mgt_clk_rate=X400_DEFAULT_MGT_CLOCK_RATE):
        """
        Initializes and reconfigures all clocks.
        If clock_source and ref_clock_freq are not provided, they will not be changed.
        If any other parameters are not provided, they will be configured with default values.

        Only called once, during device/MPM initialization.
        """
        self.reset_clocks(value=True, reset_list=['cpld'])
        if clock_source is not None:
            self.set_brc_source(clock_source)
        if ref_clock_freq is not None:
            self.set_ref_clock_freq(ref_clock_freq)

        self.config_rpll(usr_mgt_clk_rate, internal_brc_rate,
                         internal_brc_source)
        self._config_spll(master_clock_rate)
        self.reset_clocks(value=False, reset_list=['cpld'])

    def _get_default_mcr(self):
        """
        Gets the default master clock rate based on FPGA decimation
        """
        fpga_decimation, fpga_halfband = self._rfdc_regs.get_rfdc_resampling_factor(0)
        for master_clock_rate in self.master_to_sample_clk:
            _, decimation, _, halfband = self.master_to_sample_clk[master_clock_rate]
            if decimation == fpga_decimation and fpga_halfband == halfband:
                return master_clock_rate

        raise RuntimeError('No master clock rate acceptable for current fpga '
                           'with decimation of {}'.format(fpga_decimation))

    def set_master_clock_rate(self, master_clock_rate):
        """
        Sets the master clock rate by configuring the SPLL and
        resetting downstream clocks.
        """
        if master_clock_rate not in self.master_to_sample_clk:
            self.log.error('Unsupported master clock rate selection {}'
                           .format(master_clock_rate))
            raise RuntimeError('Unsupported master clock rate selection')

        _, decimation, _, halfband = self.master_to_sample_clk[master_clock_rate]
        for db_idx, _ in enumerate(self.RFDC_DB_MAP):
            db_rfdc_resamp, db_halfband = self._rfdc_regs.get_rfdc_resampling_factor(db_idx)
            if db_rfdc_resamp != decimation or db_halfband != halfband:
                msg = (f'master_clock_rate {master_clock_rate} is not compatible '
                       f'with FPGA which expected decimation {db_rfdc_resamp}')
                self.log.error(msg)
                raise RuntimeError(msg)

        self.log.trace("Set master clock rate to: {}".format(master_clock_rate))
        self.reset_clocks(value=True, reset_list=('rfdc', 'cpld', 'db_clock'))
        self._config_spll(master_clock_rate)
        self.reset_clocks(value=False, reset_list=('rfdc', 'cpld', 'db_clock'))
        self.rfdc_sync()
        self._config_pps_to_timekeeper()

    def _config_spll(self, master_clock_rate):
        """
        Configures the SPLL for the specified master clock rate.
        """
        (sample_clock_freq, _, is_legacy_mode, _) = self.master_to_sample_clk[master_clock_rate]
        self._sample_pll.init()
        self._sample_pll.config(sample_clock_freq, self.get_ref_clock_freq(),
                                is_legacy_mode)
        self._master_clock_rate = master_clock_rate

    def _config_pps_to_timekeeper(self):
        """ Configures the path from the PPS to the timekeeper"""
        pps_source = "internal_pps" if self._time_source == TIME_SOURCE_INTERNAL else "external_pps"
        self.sync_spll_clocks(pps_source)
        self.configure_pps_forwarding(True)

    def get_spll_freq(self):
        """ Returns the output frequency setting of the SPLL """
        return self._sample_pll.output_freq

    def get_spll_legacy_mode(self):
        """ Returns whether or not the SPLL is in Legacy Mode"""
        return self._sample_pll.is_legacy_mode

    def get_prc_rate(self):
        """
        Returns the rate of the PLL Reference Clock (PRC) which is
        routed to the daughterboards.
        Note: The ref clock will change if the sample clock frequency
        is modified.
        """
        prc_clock_map = {
            2.94912e9:  61.44e6,
            3e9:        62.5e6,
            # 3e9:      50e6, RF Legacy mode will be checked separately
            3.072e9:    64e6,
        }

        # RF Legacy Mode always has a PRC rate of 50 MHz
        if self.get_spll_legacy_mode():
            return 50e6
        # else:
        return prc_clock_map[self.get_spll_freq()]

    def sync_spll_clocks(self, pps_source="internal_pps"):
        """
        Synchronize base reference clock (BRC) and PLL reference clock (PRC)
        at start of PPS trigger.

        Uses the LMK 04832 pll1_r_divider_sync to synchronize BRC with PRC.
        This sync method uses a callback to actual trigger the sync. Before
        the trigger is pulled (CLOCK_CTRL_PLL_SYNC_TRIGGER) PPS source is
        configured base on current reference clock and pps_source. After sync
        trigger the method waits for 1sec for the CLOCK_CTRL_PLL_SYNC_DONE
        to go high.

        :param pps_source: select whether internal ("internal_pps") or external
                           ("external_pps") PPS should be used. This parameter
                           is taken into account when the current clock source
                           is external. If the current clock source is set to
                           internal then this parameter is not taken into
                           account.
        :return:           success state of sync call
        :raises RuntimeError: for invalid combinations of reference clock and
                              pps_source
        """
        def is_pll_sync_done():
            """
            Check whether PLL sync is done by reading PLL sync bit from
            motherboard clock control register
            """
            return bool(
                self.mboard_regs_control.peek32(MboardRegsControl.MB_CLOCK_CTRL) & \
                   MboardRegsControl.CLOCK_CTRL_PLL_SYNC_DONE)

        def select_pps():
            """
            Select PPS source based on current clock source and pps_source.

            This returns the bits for the motherboard CLOCK_CTRL register that
            control the PPS source.
            """
            EXT_PPS = "external_pps"
            INT_PPS = "internal_pps"
            PPS_SOURCES = (EXT_PPS, INT_PPS)
            assert pps_source in PPS_SOURCES, \
                "%s not in %s" % (pps_source, PPS_SOURCES)

            supported_configs = {
                (10E6, EXT_PPS): MboardRegsControl.CLOCK_CTRL_PPS_EXT,
                (10E6, INT_PPS): MboardRegsControl.CLOCK_CTRL_PPS_INT_10MHz,
                (25E6, INT_PPS): MboardRegsControl.CLOCK_CTRL_PPS_INT_25MHz
            }

            config = (self.get_ref_clock_freq(), pps_source)
            if config not in supported_configs:
                raise RuntimeError("Unsupported combination of reference clock "
                                   "(%.2E) and PPS source (%s) for PPS sync." %
                                   config)
            return supported_configs[config]

        def pll_sync_trigger():
            """
            Callback for LMK04832 driver to actually trigger the sync. Set PPS
            source accordingly.
            """
            # Update clock control config register to use the currently relevant
            # PPS source
            config = self.mboard_regs_control.peek32(
                MboardRegsControl.MB_CLOCK_CTRL)
            trigger_config = \
                (config & ~MboardRegsControl.CLOCK_CTRL_TRIGGER_PPS_SEL) \
                | select_pps()
            # trigger sync with appropriate configuration
            self.mboard_regs_control.poke32(
                MboardRegsControl.MB_CLOCK_CTRL,
                MboardRegsControl.CLOCK_CTRL_PLL_SYNC_TRIGGER | trigger_config)
            # wait for sync done indication from FPGA
            # The following value is in ms, it was experimentally picked.
            pll_sync_timeout = 1500 # ms
            result = poll_with_timeout(is_pll_sync_done, pll_sync_timeout, 10)
            # de-assert sync trigger signal
            self.mboard_regs_control.poke32(
                MboardRegsControl.MB_CLOCK_CTRL, trigger_config)
            if not result:
                self.log.error("PLL_SYNC_DONE not received within timeout")
            return result

        return self._sample_pll.pll1_r_divider_sync(pll_sync_trigger)

    def config_rpll(self,
                    usr_clk_rate=X400_DEFAULT_MGT_CLOCK_RATE,
                    internal_brc_rate=X400_DEFAULT_INT_CLOCK_FREQ,
                    internal_brc_source=X400_DEFAULT_RPLL_REF_SOURCE):
        """
        Configures the LMK03328 to generate the desired MGT reference clocks
        and internal BRC rate.

        Currently, the MGT protocol selection is not supported, but a custom usr_clk_rate
        can be generated from PLL1.

        usr_clk_rate - the custom clock rate to generate from PLL1
        internal_brc_rate - the rate to output as the BRC
        internal_brc_source - the reference source which drives the RPLL
        """
        # This uses a guard file to prevent configuration that will break the PCIe link on
        # Rev B motherboards. This can be removed if the rpll is no longer initialized every
        # time the FPGA is loaded
        if int(self.mboard_info.get('rev')) == 2:
            rpll_guard_file = "/tmp/rpll_configured"
            if path.exists(rpll_guard_file):
                self.log.warning('Not reconfiguring the RPLL to prevent PCIe errors')
                return
            open(rpll_guard_file, 'w').close()

        if internal_brc_source not in self._rpll_reference_sources:
            self.log.error('Invalid internal BRC source of {} was selected.'
                           .format(internal_brc_source))
            raise RuntimeError('Invalid internal BRC source of {} was selected.'
                               .format(internal_brc_source))
        ref_select = self._rpll_reference_sources[internal_brc_source][0]

        # If the desired rate matches the rate of the primary reference source,
        # directly passthrough that reference source
        if internal_brc_rate == self._reference_pll.reference_rates[0]:
            brc_select = 'bypass'
        else:
            brc_select = 'PLL'

        self._reference_pll.init()
        self._reference_pll.config(ref_select, internal_brc_rate, usr_clk_rate, brc_select)
        # The internal BRC rate will only change when config_rpll is called
        # with a new internal BRC rate
        self._int_clock_freq = internal_brc_rate

    def reset_clocks(self, value, reset_list):
        """
        Shuts down all clocks downstream to upstream or clears reset on all
        clocks upstream to downstream. Specify the list of clocks to reset in
        reset_list. The order of clocks specified in the reset_list does not
        affect the order in which the clocks are reset.
        """
        if value:
            self.log.trace("Reset clocks: {}".format(reset_list))
            if 'db_clock' in reset_list:
                for dboard in self.dboards:
                    dboard.reset_clock(value)
            if 'cpld' in reset_list:
                if self.cpld_control is not None:
                    self.cpld_control.enable_pll_ref_clk(enable=False)
            if 'rfdc' in reset_list:
                if self._rfdc_regs is not None and self._rfdc_ctrl is not None:
                    self.set_reset_rfdc(reset=True)
            if 'spll' in reset_list:
                self._sample_pll.reset(value, hard=True)
            if 'rpll' in reset_list:
                self._reference_pll.reset(value, hard=True)
        else:
            self.log.trace("Bring clocks out of reset: {}".format(reset_list))
            if 'rpll' in reset_list:
                self._reference_pll.reset(value, hard=True)
            if 'spll' in reset_list:
                self._sample_pll.reset(value, hard=True)
            if 'rfdc' in reset_list:
                if self._rfdc_regs is not None and self._rfdc_ctrl is not None:
                    self.set_reset_rfdc(reset=False)
            if 'cpld' in reset_list:
                if self.cpld_control is not None:
                    self.cpld_control.enable_pll_ref_clk(enable=True)
            if 'db_clock' in reset_list:
                for dboard in self.dboards:
                    dboard.reset_clock(value)

    def set_brc_source(self, clock_source):
        """
        Switches the Base Reference Clock Source between internal, external,
        mboard, and gpsdo using the GPIO pin and clocking aux board control.
        internal is a clock source internal to the clocking aux board, but
        external to the motherboard.
        Should not be called outside of set_sync_source or init_clocks without
        proper reset and reconfig of downstream clocks.
        """
        if clock_source == CLOCK_SOURCE_MBOARD:
            self._base_ref_clk_select.set(1)
            if self._clocking_auxbrd is not None:
                self._clocking_auxbrd.export_clock(False)
        else:
            if self._clocking_auxbrd is None:
                self.log.error('Invalid BRC selection {}. No clocking aux '
                               'board was found.'.format(clock_source))
                raise RuntimeError('Invalid BRC selection {}'.format(clock_source))
            self._base_ref_clk_select.set(0)
            if clock_source == ClockingAuxBrdControl.SOURCE_EXTERNAL:
                # This case is a bit special: We also need to tell the clocking
                # aux board if we plan to consume the external time reference or
                # not.
                time_src_board = \
                    ClockingAuxBrdControl.SOURCE_EXTERNAL \
                    if self._time_source == TIME_SOURCE_EXTERNAL \
                    else ClockingAuxBrdControl.SOURCE_INTERNAL
                self._clocking_auxbrd.set_source(
                    ClockingAuxBrdControl.SOURCE_EXTERNAL, time_src_board)
            elif clock_source == ClockingAuxBrdControl.SOURCE_INTERNAL:
                self._clocking_auxbrd.set_source(ClockingAuxBrdControl.SOURCE_INTERNAL)
            elif clock_source == ClockingAuxBrdControl.SOURCE_GPSDO:
                self._clocking_auxbrd.set_source(ClockingAuxBrdControl.SOURCE_GPSDO)
            elif clock_source == ClockingAuxBrdControl.SOURCE_NSYNC:
                self._clocking_auxbrd.set_source(ClockingAuxBrdControl.SOURCE_NSYNC)
            else:
                self.log.error('Invalid BRC selection {}'.format(clock_source))
                raise RuntimeError('Invalid BRC selection {}'.format(clock_source))
        self._clock_source = clock_source
        self.log.debug(f"Base reference clock source is: {clock_source}")

    def set_trigger_io(self, direction):
        """
        Switch direction of clocking board Trigger I/O SMA socket.
        IMPORTANT! Ensure downstream devices depending on TRIG I/O's output ignore
        this signal when calling this method or re-run their synchronization routine
        after calling this method. The output-enable control is async. to the output.
        :param self:
        :param direction: "off" trigger io socket unused
                          "pps_output" device will output PPS signal
                          "input" PPS is fed into the device from external
        :return: success status as boolean
        """
        OFF = "off"
        INPUT = "input"
        PPS_OUTPUT = "pps_output"
        directions = [OFF, INPUT, PPS_OUTPUT]

        if not self._clocking_auxbrd:
            raise RuntimeError("No clocking aux board available")
        if not direction in directions:
            raise RuntimeError("Invalid trigger io direction (%s). Use one of %s"
                               % (direction, directions))

        # prepare clock control FPGA register content
        clock_ctrl_reg = self.mboard_regs_control.peek32(
            MboardRegsControl.MB_CLOCK_CTRL)
        clock_ctrl_reg &= ~MboardRegsControl.CLOCK_CTRL_TRIGGER_IO_SEL
        if direction == PPS_OUTPUT:
            clock_ctrl_reg |= MboardRegsControl.CLOCK_CTRL_TRIG_IO_PPS_OUTPUT
        else:
            # for both input and off ensure FPGA does not drive trigger IO line
            clock_ctrl_reg |= MboardRegsControl.CLOCK_CTRL_TRIG_IO_INPUT

        # Switching order of trigger I/O lines depends on requested direction.
        # Always turn on new driver last so both drivers cannot be active
        # simultaneously.
        if direction == INPUT:
            self.mboard_regs_control.poke32(MboardRegsControl.MB_CLOCK_CTRL,
                                            clock_ctrl_reg)
            self._clocking_auxbrd.set_trig(1, ClockingAuxBrdControl.DIRECTION_INPUT)
        elif direction == PPS_OUTPUT:
            self._clocking_auxbrd.set_trig(1, ClockingAuxBrdControl.DIRECTION_OUTPUT)
            self.mboard_regs_control.poke32(MboardRegsControl.MB_CLOCK_CTRL,
                                            clock_ctrl_reg)
        else:
            self.mboard_regs_control.poke32(MboardRegsControl.MB_CLOCK_CTRL,
                                            clock_ctrl_reg)
            self._clocking_auxbrd.set_trig(0)

        return True

    def configure_pps_forwarding(self, enable, delay=1.0):
        """
        Configures the PPS forwarding to the sample clock domain (master
        clock rate). This function assumes sync_spll_clocks function has
        already been executed.

        :param enable: Boolean to choose whether PPS is forwarded to the
                       sample clock domain.

        :param delay:  Delay in seconds from the PPS rising edge to the edge
                       occurence in the application. This value has to be in
                       range 0 < x <= 1. In order to forward the PPS signal
                       from base reference clock to sample clock an aligned
                       rising edge of the clock is required. This can be
                       created by the sync_spll_clocks function. Based on the
                       greatest common divisor of the two clock rates there
                       are multiple occurences of an aligned edge each second.
                       One of these aligned edges has to be chosen for the
                       PPS forwarding by setting this parameter.

        :return:       None, Exception on error
        """

        # delay range check 0 < x <= 1
        if (delay <= 0 or delay > 1):
            raise RuntimeError("The delay has to be in range 0 < x <= 1")

        # configure delay in BRC clock domain
        value = self.mboard_regs_control.peek32(MboardRegsControl.MB_CLOCK_CTRL)
        pll_sync_delay = (value >> 16) & 0xFF
        # pps_brc_delay constants required by HDL implementation
        pps_brc_delay = pll_sync_delay + 2 - 1
        value = (value & 0x00FFFFFF) | (pps_brc_delay << 24)
        self.mboard_regs_control.poke32(MboardRegsControl.MB_CLOCK_CTRL, value)

        # configure delay in PRC clock domain
        # reduction by 4 required by HDL implementation
        pps_prc_delay = (int(delay * self.get_prc_rate()) - 4) & 0x3FFFFFF
        if pps_prc_delay == 0:
            # limitation from HDL implementation
            raise RuntimeError("The calculated delay has to be greater than 0")
        value = pps_prc_delay

        # configure clock divider
        # reduction by 2 required by HDL implementation
        prc_rc_divider = (int(self.get_master_clock_rate()/self.get_prc_rate()) - 2) & 0x3
        value = value | (prc_rc_divider << 28)

        # write configuration to PPS control register (with PPS disabled)
        self.mboard_regs_control.poke32(MboardRegsControl.MB_PPS_CTRL, value)

        # enables PPS depending on parameter
        if enable:
            # wait for 1 second to let configuration settle for any old PPS pulse
            sleep(1)
            # update value with enabled PPS
            value = value | (1 << 31)
            # write final configuration to PPS control register
            self.mboard_regs_control.poke32(MboardRegsControl.MB_PPS_CTRL, value)

        return True

    def set_ref_clk_tuning_word(self, tuning_word, out_select=0):
        """
        Set the tuning word for the clocking aux board DAC. This wull update the
        tuning word used by the DAC.
        """
        if self._clocking_auxbrd is not None:
            self._clocking_auxbrd.config_dac(tuning_word, out_select)
        else:
            raise RuntimeError("No clocking aux board available")

    def get_ref_clk_tuning_word(self, out_select=0):
        """
        Get the tuning word configured for the clocking aux board DAC.
        """
        if self._clocking_auxbrd is None:
            raise RuntimeError("No clocking aux board available")
        return self._clocking_auxbrd.read_dac(out_select)

    def set_clock_source_out(self, enable=True):
        """
        Allows routing the clock configured as source on the clk aux board to
        the RefOut terminal. This only applies to internal, gpsdo and nsync.
        """
        clock_source = self.get_clock_source()
        if self.get_time_source() == TIME_SOURCE_EXTERNAL:
            raise RuntimeError(
                'Cannot export clock when using external time reference!')
        if clock_source not in self._clocking_auxbrd.VALID_CLK_EXPORTS:
            raise RuntimeError(f"Invalid source to export: `{clock_source}'")
        if self._clocking_auxbrd is None:
            raise RuntimeError("No clocking aux board available")
        return self._clocking_auxbrd.export_clock(enable)

    def store_ref_clk_tuning_word(self, tuning_word):
        """
        Store the given tuning word in the clocking aux board ID EEPROM.
        """
        if self._clocking_auxbrd is not None:
            self._clocking_auxbrd.store_tuning_word(tuning_word)
        else:
            raise RuntimeError("No clocking aux board available")

    def enable_ecpri_clocks(self, enable=True, clock='both'):
        """
        Enable or disable the export of FABRIC and GTY_RCV eCPRI
        clocks. Main use case until we support eCPRI is manufacturing
        testing.
        """
        valid_clocks_list = ['gty_rcv', 'fabric', 'both']
        assert clock in valid_clocks_list

        clock_ctrl_reg = self.mboard_regs_control.peek32(
            MboardRegsControl.MB_MFG_TEST_CTRL)

        if enable:
            if clock == 'gty_rcv':
                clock_ctrl_reg |= self.mboard_regs_control.MFG_TEST_CTRL_GTY_RCV_CLK_EN
            elif clock == 'fabric':
                clock_ctrl_reg |= self.mboard_regs_control.MFG_TEST_CTRL_FABRIC_CLK_EN
            else:# 'both' case
                clock_ctrl_reg |= (self.mboard_regs_control.MFG_TEST_CTRL_GTY_RCV_CLK_EN |
                                    self.mboard_regs_control.MFG_TEST_CTRL_FABRIC_CLK_EN)
        else:
            if clock == 'gty_rcv':
                clock_ctrl_reg &= ~self.mboard_regs_control.MFG_TEST_CTRL_GTY_RCV_CLK_EN
            elif clock == 'fabric':
                clock_ctrl_reg &= ~self.mboard_regs_control.MFG_TEST_CTRL_FABRIC_CLK_EN
            else:# 'both' case
                clock_ctrl_reg &= ~(self.mboard_regs_control.MFG_TEST_CTRL_GTY_RCV_CLK_EN |
                                    self.mboard_regs_control.MFG_TEST_CTRL_FABRIC_CLK_EN)

        self.mboard_regs_control.poke32(MboardRegsControl.MB_MFG_TEST_CTRL,
            clock_ctrl_reg)

    def get_fpga_aux_ref_freq(self):
        """
        Return the tick count of an FPGA counter which measures the width of
        the PPS signal on the FPGA_AUX_REF FPGA input using a 40 MHz clock.
        Main use case until we support eCPRI is manufacturing testing.
        A return value of 0 indicates absence of a valid PPS signal on the
        FPGA_AUX_REF line.
        """
        status_reg = self.mboard_regs_control.peek32(
            MboardRegsControl.MB_MFG_TEST_STATUS)
        return status_reg & self.mboard_regs_control.MFG_TEST_AUX_REF_FREQ

    ###########################################################################
    # EEPROMs
    ###########################################################################
    def get_db_eeprom(self, dboard_idx):
        """
        See PeriphManagerBase.get_db_eeprom() for docs.
        """
        try:
            dboard = self.dboards[dboard_idx]
        except IndexError:
            error_msg = "Attempted to access invalid dboard index `{}' " \
                        "in get_db_eeprom()!".format(dboard_idx)
            self.log.error(error_msg)
            raise RuntimeError(error_msg)
        db_eeprom_data = copy.copy(dboard.device_info)
        return db_eeprom_data

    ###########################################################################
    # Component updating
    ###########################################################################
    # Note: Component updating functions defined by ZynqComponents
    @no_rpc
    def _update_fpga_type(self):
        """Update the fpga type stored in the updateable components"""
        fpga_type = self.mboard_regs_control.get_fpga_type()
        dsp_bw, _, _ = self._rfdc_regs.get_fabric_dsp_info(0)
        fpga_string = fpga_type + "_" + str(dsp_bw)
        self.log.debug("Updating mboard FPGA type info to {}".format(fpga_string))
        self.updateable_components['fpga']['type'] = fpga_string

    #######################################################################
    # Timekeeper API
    #######################################################################
    def get_master_clock_rate(self):
        """ Return the master clock rate set during init """
        return self._master_clock_rate

    def get_num_timekeepers(self):
        """
        Return the number of timekeepers
        """
        return self.mboard_regs_control.get_num_timekeepers()

    def get_timekeeper_time(self, tk_idx, last_pps):
        """
        Get the time in ticks

        Arguments:
        tk_idx: Index of timekeeper
        next_pps: If True, get time at last PPS. Otherwise, get time now.
        """
        return self.mboard_regs_control.get_timekeeper_time(tk_idx, last_pps)

    def set_timekeeper_time(self, tk_idx, ticks, next_pps):
        """
        Set the time in ticks

        Arguments:
        tk_idx: Index of timekeeper
        ticks: Time in ticks
        next_pps: If True, set time at next PPS. Otherwise, set time now.
        """
        self.mboard_regs_control.set_timekeeper_time(tk_idx, ticks, next_pps)

    def set_tick_period(self, tk_idx, period_ns):
        """
        Set the time per tick in nanoseconds (tick period)

        Arguments:
        tk_idx: Index of timekeeper
        period_ns: Period in nanoseconds
        """
        self.mboard_regs_control.set_tick_period(tk_idx, period_ns)

    def get_clocks(self):
        """
        Gets the RFNoC-related clocks present in the FPGA design
        """
        # TODO: The 200 and 40 MHz clocks should not be hard coded, and ideally
        # be linked to the FPGA image somehow
        return [
            {
                'name': 'radio_clk',
                'freq': str(self.get_master_clock_rate()),
                'mutable': 'true'
            },
            {
                'name': 'bus_clk',
                'freq': str(200e6),
            },
            {
                'name': 'ctrl_clk',
                'freq': str(40e6),
            }
        ]


    ###########################################################################
    # Utility for validating RPU core number
    ###########################################################################
    @no_rpc
    def _validate_rpu_core_number(self, core_number):
        if ((core_number < 0) or (core_number > 1)):
            raise RuntimeError("RPU core number must be 0 or 1.")


    ###########################################################################
    # Utility for validating RPU state change command
    ###########################################################################
    @no_rpc
    def _validate_rpu_state(self, new_state_command, previous_state):
        if ((new_state_command != RPU_STATE_COMMAND_START)
                and (new_state_command != RPU_STATE_COMMAND_STOP)):
            raise RuntimeError("RPU state command must be start or stop.")
        if ((new_state_command == RPU_STATE_COMMAND_START)
                and (previous_state == RPU_STATE_RUNNING)):
            raise RuntimeError("RPU already running.")
        if ((new_state_command == RPU_STATE_COMMAND_STOP)
                and (previous_state == RPU_STATE_OFFLINE)):
            raise RuntimeError("RPU already offline.")

    ###########################################################################
    # Utility for validating RPU firmware
    ###########################################################################
    @no_rpc
    def _validate_rpu_firmware(self, firmware):
        file_path = path.join(RPU_REMOTEPROC_FIRMWARE_PATH, firmware)
        if not path.isfile(file_path):
            raise RuntimeError("Specified firmware does not exist.")

    ###########################################################################
    # Utility for reading contents of a file
    ###########################################################################
    @no_rpc
    def _read_file(self, file_path):
        self.log.trace("_read_file: file_path= %s", file_path)
        with open(file_path, 'r') as f:
            return f.read().strip()


    ###########################################################################
    # Utility for writing contents of a file
    ###########################################################################
    @no_rpc
    def _write_file(self, file_path, data):
        self.log.trace("_write_file: file_path= %s, data= %s", file_path, data)
        with open(file_path, 'w') as f:
            f.write(data)


    ###########################################################################
    # RPU Image Deployment API
    ###########################################################################
    def get_rpu_state(self, core_number, validate=True):
        """ Report the state for the specified RPU core """
        if validate:
            self._validate_rpu_core_number(core_number)
        return self._read_file(
            path.join(
                RPU_REMOTEPROC_PREFIX_PATH + str(core_number),
                RPU_REMOTEPROC_PROPERTY_STATE))


    def set_rpu_state(self, core_number, new_state_command, validate=True):
        """ Set the specified state for the specified RPU core """
        if not self._rpu_initialized:
            self.log.warning(
                "Failed to set RPU state: RPU peripheral not "\
                "initialized.")
            return RPU_FAILURE_REPORT
        # OK, RPU is initialized, now go set its state:
        if validate:
            self._validate_rpu_core_number(core_number)
        previous_state = self.get_rpu_state(core_number, False)
        if validate:
            self._validate_rpu_state(new_state_command, previous_state)
        self._write_file(
            path.join(
                RPU_REMOTEPROC_PREFIX_PATH + str(core_number),
                RPU_REMOTEPROC_PROPERTY_STATE),
            new_state_command)

        # Give RPU core time to change state (might load new fw)
        poll_with_timeout(
            lambda: previous_state != self.get_rpu_state(core_number, False),
            RPU_MAX_STATE_CHANGE_TIME_IN_MS,
            RPU_STATE_CHANGE_POLLING_INTERVAL_IN_MS)

        # Quick validation of new state
        resulting_state = self.get_rpu_state(core_number, False)
        if ((new_state_command == RPU_STATE_COMMAND_START)
                and (resulting_state != RPU_STATE_RUNNING)):
            raise RuntimeError('Unable to start specified RPU core.')
        if ((new_state_command == RPU_STATE_COMMAND_STOP)
                and (resulting_state != RPU_STATE_OFFLINE)):
            raise RuntimeError('Unable to stop specified RPU core.')
        return RPU_SUCCESS_REPORT

    def get_rpu_firmware(self, core_number):
        """ Report the firmware for the specified RPU core """
        self._validate_rpu_core_number(core_number)
        return self._read_file(
            path.join(
                RPU_REMOTEPROC_PREFIX_PATH + str(core_number),
                RPU_REMOTEPROC_PROPERTY_FIRMWARE))


    def set_rpu_firmware(self, core_number, firmware, start=0):
        """ Deploy the image at the specified path to the RPU """
        self.log.trace("set_rpu_firmware")
        self.log.trace(
            "image path: %s, core_number: %d, start?: %d",
            firmware,
            core_number,
            start)

        if not self._rpu_initialized:
            self.log.warning(
                "Failed to deploy RPU image: "\
                "RPU peripheral not initialized.")
            return RPU_FAILURE_REPORT
        # RPU is initialized, now go set firmware:
        self._validate_rpu_core_number(core_number)
        self._validate_rpu_firmware(firmware)

        # Stop the core if necessary
        if self.get_rpu_state(core_number, False) == RPU_STATE_RUNNING:
            self.set_rpu_state(core_number, RPU_STATE_COMMAND_STOP, False)

        # Set the new firmware path
        self._write_file(
            path.join(
                RPU_REMOTEPROC_PREFIX_PATH + str(core_number),
                RPU_REMOTEPROC_PROPERTY_FIRMWARE),
            firmware)

        # Start the core if requested
        if start != 0:
            self.set_rpu_state(core_number, RPU_STATE_COMMAND_START, False)
        return RPU_SUCCESS_REPORT

    #######################################################################
    # Debugging
    # Provides temporary methods for arbitrary hardware access while
    # development for these components is ongoing.
    #######################################################################
    def peek_ctrlport(self, addr):
        """ Peek the MPM Endpoint to ctrlport registers on the FPGA """
        return '0x{:X}'.format(self.ctrlport_regs.peek32(addr))

    def poke_ctrlport(self, addr, val):
        """ Poke the MPM Endpoint to ctrlport registers on the FPGA """
        self.ctrlport_regs.poke32(addr, val)

    def peek_cpld(self, addr):
        """ Peek the PS portion of the MB CPLD """
        return '0x{:X}'.format(self.cpld_control.peek32(addr))

    def poke_cpld(self, addr, val):
        """ Poke the PS portion of the MB CPLD """
        self.cpld_control.poke32(addr, val)

    def peek_db(self, db_id, addr):
        """ Peek the DB CPLD, even if the DB is not discovered by MPM """
        assert db_id in (0, 1)
        self.cpld_control.enable_daughterboard(db_id)
        return '0x{:X}'.format(
            self.ctrlport_regs.get_db_cpld_iface(db_id).peek32(addr))

    def poke_db(self, db_id, addr, val):
        """ Poke the DB CPLD, even if the DB is not discovered by MPM """
        assert db_id in (0, 1)
        self.cpld_control.enable_daughterboard(db_id)
        self.ctrlport_regs.get_db_cpld_iface(db_id).poke32(addr, val)

    def peek_clkaux(self, addr):
        """Peek the ClkAux DB over SPI"""
        return '0x{:X}'.format(self._clocking_auxbrd.peek8(addr))

    def poke_clkaux(self, addr, val):
        """Poke the ClkAux DB over SPI"""
        self._clocking_auxbrd.poke8(addr, val)

    def nsync_change_input_source(self, source):
        """
        Switches the input reference source of the clkaux lmk
        valid options are fabric_clk, gty_rcv_clk, and sec_ref
        fabric_clk and gty_rcv_clk are clock sources from the mboard
        they are both inputs to the primary reference source of the
        clkaux lmk
        sec_ref is the default reference select for the clkaux lmk, it has
        two inputs: Ref in or internal and GPS mode
        """
        valid_source_list = ['fabric_clk', 'gty_rcv_clk', 'sec_ref']
        assert source in valid_source_list

        if source == self._clocking_auxbrd.SOURCE_NSYNC_LMK_PRI_FABRIC_CLK:
            self.enable_ecpri_clocks(True, 'fabric')
            self._clocking_auxbrd.set_nsync_ref_select(self._clocking_auxbrd.NSYNC_PRI_REF)
            self._clocking_auxbrd.set_nsync_pri_ref_source(source)

        elif source == self._clocking_auxbrd.SOURCE_NSYNC_LMK_PRI_GTY_RCV_CLK:
            self.enable_ecpri_clocks(True, 'gty_rcv')
            self._clocking_auxbrd.set_nsync_ref_select(self._clocking_auxbrd.NSYNC_PRI_REF)
            self._clocking_auxbrd.set_nsync_pri_ref_source(source)

        else:
            self._clocking_auxbrd.set_nsync_ref_select(self._clocking_auxbrd.NSYNC_SEC_REF)

    def config_rpll_to_nsync(self):
        """
        Configures the rpll to use the LMK28PRIRefClk output
        by the clkaux LMK
        """
        # LMK28PRIRefClk only available when nsync is source, as lmk
        # is powered off otherwise
        self.set_clock_source('nsync')

        # Add LMK28PRIRefClk as an available RPLL reference source
        # 1 => PRIREF source; source is output at 25 MHz
        # TODO: enable out4 on LMK
        previous_ref_rate = self._reference_pll.reference_rates[0]
        self._rpll_reference_sources['clkaux_nsync_clk'] = (1, 25e6)
        self._reference_pll.reference_rates[0] = 25e6

        self.config_rpll(X400_DEFAULT_MGT_CLOCK_RATE,
                         X400_DEFAULT_INT_CLOCK_FREQ,
                         'clkaux_nsync_clk')

        # remove clkaux_nsync_clk as a valid reference source for later calls
        # to config_rpll(), it is only valid in this configuration
        self._reference_pll.reference_rates[0] = previous_ref_rate
        del self._rpll_reference_sources['clkaux_nsync_clk']



    ###########################################################################
    # Sensors
    ###########################################################################
    def get_ref_lock_sensor(self):
        """
        Return main refclock lock status. This is the lock status of the
        reference and sample PLLs.
        """
        ref_pll_status = self._reference_pll.get_status()
        sample_pll_status = self._sample_pll.get_status()
        lock_status = (ref_pll_status['PLL1 lock'] and
                       ref_pll_status['PLL2 lock'] and
                       sample_pll_status['PLL1 lock'] and
                       sample_pll_status['PLL2 lock']
                       )
        return {
            'name': 'ref_locked',
            'type': 'BOOLEAN',
            'unit': 'locked' if lock_status else 'unlocked',
            'value': str(lock_status).lower(),
        }

    def get_fpga_temp_sensor(self):
        """ Get temperature sensor reading of the X4xx FPGA. """
        self.log.trace("Reading FPGA temperature.")
        return get_temp_sensor(["RFSoC"], log=self.log)

    def get_main_power_temp_sensor(self):
        """
        Get temperature sensor reading of PM-BUS devices which supply
        0.85V power supply to RFSoC.
        """
        self.log.trace("Reading PMBus Power Supply Chip(s) temperature.")
        return get_temp_sensor(["PMBUS-0", "PMBUS-1"], log=self.log)

    def get_scu_internal_temp_sensor(self):
        """ Get temperature sensor reading of STM32 SCU's internal sensor. """
        self.log.trace("Reading SCU internal temperature.")
        return get_temp_sensor(["EC Internal"], log=self.log)

    def get_internal_temp_sensor(self):
        """ TODO: Determine how to interpret this function """
        self.log.warning("Reading internal temperature is not yet implemented.")
        return {
            'name': 'temperature',
            'type': 'REALNUM',
            'unit': 'C',
            'value': '-1'
        }

    def _get_fan_sensor(self, fan='fan0'):
        """ Get fan speed. """
        self.log.trace("Reading {} speed sensor.".format(fan))
        fan_rpm = -1
        try:
            fan_rpm_all = ectool.get_fan_rpm()
            fan_rpm = fan_rpm_all[fan]
        except Exception as ex:
            self.log.warning(
                "Error occurred when getting {} speed value: {} "
                .format(fan, str(ex)))
        return {
            'name': fan,
            'type': 'INTEGER',
            'unit': 'rpm',
            'value': str(fan_rpm)
        }

    def get_fan0_sensor(self):
        """ Get fan0 speed. """
        return self._get_fan_sensor('fan0')

    def get_fan1_sensor(self):
        """ Get fan1 speed."""
        return self._get_fan_sensor('fan1')

    def get_gps_sensor_status(self):
        """
        Get all status of GPS as sensor dict
        """
        assert self._gps_mgr
        self.log.trace("Reading all GPS status pins")
        return f"""
            {self.get_gps_lock_sensor()}
            {self.get_gps_alarm_sensor()}
            {self.get_gps_warmup_sensor()}
            {self.get_gps_survey_sensor()}
            {self.get_gps_phase_lock_sensor()}
        """

    ###########################################################################
    # ADCs/DACs
    ###########################################################################
    def set_cal_frozen(self, frozen, slot_id, channel):
        """
        Set the freeze state for the ADC cal blocks

        Usage:
        > set_cal_frozen <frozen> <slot_id> <channel>

        <frozen> should be 0 to unfreeze the calibration blocks or 1 to freeze them.
        """
        for tile_id, block_id, _ in self._find_converters(slot_id, "rx", channel):
            self._rfdc_ctrl.set_cal_frozen(tile_id, block_id, frozen)

    def get_cal_frozen(self, slot_id, channel):
        """
        Get the freeze states for each ADC cal block in the channel

        Usage:
        > get_cal_frozen <slot_id> <channel>
        """
        return [
            1 if self._rfdc_ctrl.get_cal_frozen(tile_id, block_id) else 0
            for tile_id, block_id, is_dac in self._find_converters(slot_id, "rx", channel)
        ]

    def set_cal_coefs(self, channel, slot_id, cal_block, coefs):
        """
        Manually override calibration block coefficients. You probably don't need to use this.
        """
        self.log.trace(
            "Setting ADC cal coefficients for channel={} slot_id={} cal_block={}".format(
                channel, slot_id, cal_block))
        for tile_id, block_id, _ in self._find_converters(slot_id, "rx", channel):
            self._rfdc_ctrl.set_adc_cal_coefficients(
                tile_id, block_id, cal_block, ast.literal_eval(coefs))

    def get_cal_coefs(self, channel, slot_id, cal_block):
        """
        Manually retrieve raw coefficients for the ADC calibration blocks.

        Usage:
        > get_cal_coefs <channel, 0-1> <slot_id, 0-1> <cal_block, 0-3>
        e.g.
        > get_cal_coefs 0 1 3
        Retrieves the coefficients for the TSCB block on channel 0 of DB 1.

        Valid values for cal_block are:
        0 - OCB1 (Unaffected by cal freeze)
        1 - OCB2 (Unaffected by cal freeze)
        2 - GCB
        3 - TSCB
        """
        self.log.trace(
            "Getting ADC cal coefficients for channel={} slot_id={} cal_block={}".format(
                channel, slot_id, cal_block))
        result = []
        for tile_id, block_id, _ in self._find_converters(slot_id, "rx", channel):
            result.append(self._rfdc_ctrl.get_adc_cal_coefficients(tile_id, block_id, cal_block))
        return result

    def set_dac_mux_data(self, i_val, q_val):
        """
        Sets the data which is muxed into the DACs when the DAC mux is enabled

        Usage:
        > set_dac_mux_data <I> <Q>
        e.g.
        > set_dac_mux_data 123 456
        """
        self._rfdc_regs.set_cal_data(i_val, q_val)

    def set_dac_mux_enable(self, channel, enable):
        """
        Sets whether the DAC mux is enabled for a given channel

        Usage:
        > set_dac_mux_enable <channel, 0-3> <enable, 1=enabled>
        e.g.
        > set_dac_mux_enable 1 0
        """
        self._rfdc_regs.set_cal_enable(channel, bool(enable))

    def setup_threshold(self, slot_id, channel, threshold_idx, mode, delay, under, over):
        """
        Configure the given ADC threshold block.

        Usage:
        > setup_threshold <slot_id> <channel> <threshold_idx> <mode> <delay> <under> <over>

        slot_id: Slot ID to configure, 0 or 1
        channel: Channel on the slot to configure, 0 or 1
        threshold_idx: Threshold block index, 0 or 1
        mode: Mode to configure, one of ["sticky_over", "sticky_under", "hysteresis"]
        delay: In hysteresis mode, number of samples before clearing flag.
        under: 0-16384, ADC codes to set the "under" threshold to
        over: 0-16384, ADC codes to set the "over" threshold to
        """
        for tile_id, block_id, _ in self._find_converters(slot_id, "rx", channel):
            THRESHOLDS = {
                0: lib.rfdc.threshold_id_options.THRESHOLD_0,
                1: lib.rfdc.threshold_id_options.THRESHOLD_1,
            }
            MODES = {
                "sticky_over": lib.rfdc.threshold_mode_options.TRSHD_STICKY_OVER,
                "sticky_under": lib.rfdc.threshold_mode_options.TRSHD_STICKY_UNDER,
                "hysteresis": lib.rfdc.threshold_mode_options.TRSHD_HYSTERESIS,
            }
            if mode not in MODES:
                raise RuntimeError(f"Mode {mode} is not one of the allowable modes {list(MODES.keys())}")
            if threshold_idx not in THRESHOLDS:
                raise RuntimeError("threshold_idx must be 0 or 1")
            delay = int(delay)
            under = int(under)
            over = int(over)
            assert 0 <= under <= 16383
            assert 0 <= over <= 16383
            self._rfdc_ctrl.set_threshold_settings(tile_id, block_id,
                lib.rfdc.threshold_id_options.THRESHOLD_0,
                MODES[mode],
                delay,
                under,
                over)

    def get_threshold_status(self, slot_id, channel, threshold_idx):
        """
        Read the threshold status bit for the given threshold block from the device.

        Usage:
        > get_threshold_status <slot_id> <channel> <threshold_idx>
        e.g.
        > get_threshold_status 0 1 0
        """

        if self.mboard_regs_control.get_compat_number() < (6, 2):
            raise RuntimeError("get_threshold_status requires FPGA 6.2 or newer!")

        return self._rfdc_regs.get_threshold_status(slot_id, channel, threshold_idx) != 0
