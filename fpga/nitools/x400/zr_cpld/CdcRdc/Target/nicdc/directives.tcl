# --------------------------------------------
#   CLOCK DOMAINS
# --------------------------------------------

set prc_clock_period 15.62
netlist clock -group CPLD_REFCLK -period $prc_clock_period CPLD_REFCLK
# The next instance is the input port past a PLL
netlist clock -group CPLD_REFCLK -period $prc_clock_period pll_ref_clk_ctrl_i.altclkctrl_0.clkctrl_altclkctrl_0_sub_component.clkctrl1.outclk
netlist clock -group MB_CTRL_SCK -period [expr {3 * $prc_clock_period}] MB_CTRL_SCK
netlist clock -group CTRL_REG_CLK -period 20.000 CTRL_REG_CLK
netlist clock -group OSC_CLK -period 8.6 int_osc_clk_ctrl_i.altclkctrl_0.clkctrl_altclkctrl_0_sub_component.clkctrl1.outclk
#Flash primitive instantiation uses CTRL_REG_CLK as base clock
netlist clock -group CTRL_REG_CLK -period 20.000 flash_i.onchip_flash_0.altera_onchip_flash_block.osc

netlist reset -group aReset -async -sync -active_high  CTRL_REG_ARST
netlist reset -group aReset -async -active_high  flash_i.onchip_flash_0.avmm_data_controller.genblk6.ufm_data_shiftreg.aset
netlist reset -group spi_reset -async -active_high  MB_CTRL_CS

# Port Domains
netlist port domain -clock MB_CTRL_SCK [list MB_CTRL_MOSI MB_CTRL_MISO MB_CTRL_CS]
netlist port domain -clock CPLD_REFCLK [list MB_FPGA_GPIO]
netlist port domain -clock CPLD_REFCLK [list TX*_LO*  RX*_LO*]
netlist port domain -clock CPLD_REFCLK [list TX*_SW*  RX*_SW*]
netlist port domain -clock CPLD_REFCLK [list TX*_DSA* RX*_DSA*]
netlist port domain -clock CPLD_REFCLK [list CH*_LED ]
netlist port domain -clock CPLD_REFCLK [list MB_SYNTH_SYNC ]
netlist port domain -clock OSC_CLK [list P7V_PG_* P7V_ENABLE_* P3D3VA_ENABLE]

# Asynchronous ports
netlist clock -group VAsyncClk -period 100.000 -virtual VAsyncClk
netlist port domain -clock VAsyncClk [list CTRL_REG_ARST]

cdc reconvergence on
cdc preference reconvergence -depth 1

# --------------------------------------------
#   RESET DECLARATION
# --------------------------------------------
# This reset is used asynchronously in the ctrlport crossing block, and
# synchronously everywhere else in the design(SPI, Power control)
netlist reset -group ctrlport_rst_osc -sync -async -active_high ctrlport_rst_osc

#This reset is used asynchronously in the ctrlport crossing block, and
# synchronously everywhere else in the design(DB Control)
netlist reset -group ctrlport_rst_prc -sync -async -active_high ctrlport_rst_prc

#The following derived reset is used synchronously for the register interface
#(reconfiguration engine), but asynchronously in the Flash IP
netlist reset -group ctrlport_rst_crc -sync -async -active_high ctrlport_rst_crc

netlist port resetdomain -reset ctrlport_rst_prc -async -active_high \
  [list TX*_LO*  RX*_LO*  TX*_SW*  RX*_SW* TX*_DSA* RX*_DSA*\
        CH*_LED ]

netlist port resetdomain -reset ctrlport_rst_crc -async -active_high \
  [list MB_CTRL_MISO ]

netlist port resetdomain -reset ctrlport_rst_osc -async -active_high \
  [list P7V_ENABLE_* P3D3VA_ENABLE ]

netlist port resetdomain -reset spi_reset -async -active_high \
  [list MB_CTRL_MOSI]

netlist reset -group VAsyncReset -async -sync -active_high -virtual VAsyncReset
netlist port resetdomain -reset VAsyncReset -async -active_high \
  [list P7V_PG_*]

netlist reset -group FpgaRefClkReset -async -sync -active_high -virtual FpgaRefClkReset
netlist port resetdomain -reset FpgaRefClkReset -async -active_high \
  [list MB_FPGA_GPIO MB_SYNTH_SYNC]

# --------------------------------------------
#   MODEL DECLARATION
# --------------------------------------------

# Handshake model declaration
hier block handshake -user_specified
hier clock -module handshake clk_a
hier clock -module handshake clk_b
hier reset -module handshake rst_a -async -active_high
hier port domain -module handshake -clock clk_a \
  [list valid_a data_a busy_a]
hier port domain -module handshake -clock clk_b \
  [list valid_b data_b]
hier port resetdomain -module handshake -reset rst_a \
  [list valid_a data_a busy_a]


hier block synchronizer -user_specified
hier clock -module synchronizer clk
hier reset -module synchronizer rst -async -active_high
hier port domain -module synchronizer -clock clk \
  [list out]
hier port resetdomain -module synchronizer -reset rst \
  [list out]

hier block reset_sync -user_specified
hier clock -module reset_sync clk
hier reset -module reset_sync reset_in -async -active_high
hier port domain -module reset_sync -clock clk \
  [list reset_out]
hier port resetdomain -module reset_sync -reset reset_in \
  [list reset_out]
