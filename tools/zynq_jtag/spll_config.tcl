# #### reset_spll ####
# 1 = reset
# 0 = no reset
proc reset_spll_hard { val } {
  set mask [expr {1 << 2}]
  set dat [expr {$val << 2}]; # active-high reset
  # Set bit to output (reg 0x3) bit 2 to 0x0
  mask_poke_i2c_gpio 0x03 $mask 0x0
  # Set bit high or low (reg 0x1, data $dat)
  mask_poke_i2c_gpio 0x01 $mask $dat
}

# #### select_vcxo ####
# options: 100e6 or 122.88e6
proc select_vcxo { vcxo_freq } {
  set mask [expr {1 << 3}]
  if {$vcxo_freq == 100e6} {
    set dat 0x0
  } elseif {$vcxo_freq == 122.88e6} {
    set dat [expr {1 << 3}]
  } else {
    puts "\[SPLL\] \[WARNING\] Invalid VCXO requested: $vcxo_freq"
    return
  }
  puts "\[SPLL\] Selecting $vcxo_freq VCXO..."
  # Set bit to output (reg 0x3) bit 3 to 0x0
  mask_poke_i2c_gpio 0x03 $mask 0x0
  # Set bit high or low (reg 0x1, data $dat)
  mask_poke_i2c_gpio 0x01 $mask $dat
}


proc reset_spll { } {
  set reset_addr 0x00
  set reset_bit 0x90    ;# reset=1, 3_wire_spi=1 (disabled)
  poke_spll $reset_addr $reset_bit
}
proc clear_reset_spll { } {
  set reset_addr 0x00
  set reset_bit 0x10    ;# reset=0, 3_wire_spi=1 (disabled)
  poke_spll $reset_addr $reset_bit
}

proc enable_spi_spll { } {
  # Enable 4-wire SPI readback from the CLKin_SEL0 pin
  set clkin_mux_addr 0x148
  set clkin_mux_val  0x33
  poke_spll $clkin_mux_addr $clkin_mux_val
}

proc spll_config { {out_freq 3000e6} } {

  pdac_init
  set pdac_value 0x7FF
  puts "\[PDAC\] Setting PDAC to $pdac_value"
  poke_pdac $pdac_value

  if { $out_freq == 3072e6 } {
    set SYSREF_div_7_0          0x00B0
    set CLKin0_R_13_8           0x0002
    set CLKin0_R_7_0            0x0071
    set PLL1_N_7_0              0x0040
    set PLL2_pre                0x00A4
    set PLL2_N_cal_7_0          0x0005
    set PLL2_N_7_0              0x0005
    set VCXO_FREQ               122.88e6
  } elseif { $out_freq == 2949.12e6 } {
    set SYSREF_div_7_0          0x0080
    set CLKin0_R_13_8           0x0002
    set CLKin0_R_7_0            0x0071
    set PLL1_N_7_0              0x0040
    set PLL2_pre                0x0044
    set PLL2_N_cal_7_0          0x000C
    set PLL2_N_7_0              0x000C
    set VCXO_FREQ               122.88e6
  } elseif { $out_freq == 3000e6 } {
    set SYSREF_div_7_0          0x00B0
    set CLKin0_R_13_8           0x0001
    set CLKin0_R_7_0            0x00F4
    set PLL1_N_7_0              0x0032
    set PLL2_pre                0x0064
    set PLL2_N_cal_7_0          0x000A
    set PLL2_N_7_0              0x000A
    set VCXO_FREQ               100e6
  } else {
    puts "\[SPLL\] Invalid output rate requested: $out_freq ..."
    return
  }
  puts "\[SPLL\] Configuring output frequency to $out_freq ..."

  
  
  # Reset
  reset_spll
  select_vcxo $VCXO_FREQ; # Set the VCXO switch
  clear_reset_spll
  enable_spi_spll

  # Check Chip ID (should be 6)
  set chip_id [format 0x%X [peek_spll 0x0003]]
  # Check Product ID (0x4=hi 0x5=low should be 0xD163)
  set product_id_hi [peek_spll 0x0004]
  set product_id_lo [peek_spll 0x0005]
  set product_id [format 0x%X [expr {$product_id_hi << 8} | $product_id_lo]]
  puts "\[SPLL\] Chip ID: $chip_id, Product ID: $product_id"

  # Config sequence begins
  # CLKout Config
  poke_spll 0x0100 0x0001
  poke_spll 0x0101 0x000A
  poke_spll 0x0102 0x0060
  poke_spll 0x0103 0x000C
  poke_spll 0x0104 0x0010
  poke_spll 0x0105 0x0000
  poke_spll 0x0106 0x0000
  poke_spll 0x0107 0x0099
  poke_spll 0x0108 0x0001
  poke_spll 0x0109 0x000A
  poke_spll 0x010A 0x0060
  poke_spll 0x010B 0x000C
  poke_spll 0x010C 0x0010
  poke_spll 0x010D 0x0000
  poke_spll 0x010E 0x0000
  poke_spll 0x010F 0x0099
  poke_spll 0x0110 0x0030
  poke_spll 0x0111 0x000A
  poke_spll 0x0112 0x0060
  poke_spll 0x0113 0x0040
  poke_spll 0x0114 0x0010
  poke_spll 0x0115 0x0000
  poke_spll 0x0116 0x0000
  poke_spll 0x0117 0x0044
  poke_spll 0x0118 0x0030
  poke_spll 0x0119 0x000A
  poke_spll 0x011A 0x0060
  poke_spll 0x011B 0x0040
  poke_spll 0x011C 0x0010
  poke_spll 0x011D 0x0000
  poke_spll 0x011E 0x0000
  poke_spll 0x011F 0x0044
  poke_spll 0x0120 0x0030
  poke_spll 0x0121 0x000A
  poke_spll 0x0122 0x0060
  poke_spll 0x0123 0x0040
  poke_spll 0x0124 0x0020
  poke_spll 0x0125 0x0000
  poke_spll 0x0126 0x0000
  poke_spll 0x0127 0x0044
  poke_spll 0x0128 0x0001
  poke_spll 0x0129 0x000A
  poke_spll 0x012A 0x0060
  poke_spll 0x012B 0x0060
  poke_spll 0x012C 0x0020
  poke_spll 0x012D 0x0000
  poke_spll 0x012E 0x0000
  poke_spll 0x012F 0x0094
  poke_spll 0x0130 0x0001
  poke_spll 0x0131 0x000A
  poke_spll 0x0132 0x0060
  poke_spll 0x0133 0x000C
  poke_spll 0x0134 0x0010
  poke_spll 0x0135 0x0000
  poke_spll 0x0136 0x0000
  poke_spll 0x0137 0x0099

  # PLL Config
  poke_spll 0x0138 0x0020
  poke_spll 0x0139 0x0012
  poke_spll 0x013A 0x0004           ;# SYSREF Divide [12:8]
  poke_spll 0x013B $SYSREF_div_7_0  ;# SYSREF Divide [7:0]
  poke_spll 0x013C 0x0000
  poke_spll 0x013D 0x0008
  poke_spll 0x013E 0x0000
  poke_spll 0x013F 0x000F
  poke_spll 0x0140 0x0000
  poke_spll 0x0141 0x0000
  poke_spll 0x0142 0x0001
  poke_spll 0x0143 0x00D3
  poke_spll 0x0144 0x0063
  poke_spll 0x0145 0x0010
  poke_spll 0x0146 0x0018
  poke_spll 0x0147 0x0006
  poke_spll 0x0149 0x0002
  poke_spll 0x014A 0x0000
  poke_spll 0x014B 0x0002
  poke_spll 0x014C 0x0000
  poke_spll 0x014D 0x0000
  poke_spll 0x014E 0x00C0
  poke_spll 0x014F 0x007F
  poke_spll 0x0150 0x0000
  poke_spll 0x0151 0x0002
  poke_spll 0x0152 0x0000
  poke_spll 0x0153 $CLKin0_R_13_8 ;# CLKin0_R divider [13:8], default = 0
  poke_spll 0x0154 $CLKin0_R_7_0  ;# CLKin0_R divider [7:0], default = d120
  poke_spll 0x0155 0x0000
  poke_spll 0x0156 0x0001
  poke_spll 0x0157 0x0000
  poke_spll 0x0158 0x0001
  poke_spll 0x0159 0x0000       ;# PLL1 N divider [13:8], default = 0
  poke_spll 0x015A $PLL1_N_7_0  ;# PLL1 N divider [7:0], default = d120
  poke_spll 0x015B 0x00C8
  poke_spll 0x015C 0x0020
  poke_spll 0x015D 0x0000
  poke_spll 0x015E 0x001E
  poke_spll 0x015F 0x001B
  poke_spll 0x0160 0x0000
  poke_spll 0x0161 0x0001
  poke_spll 0x0162 $PLL2_pre        ;# PLL2 prescaler; OSCin freq; Lower nibble must be 0x4!!!
  poke_spll 0x0163 0x0000           ;# PLL2 N Cal [17:16]
  poke_spll 0x0164 0x0000           ;# PLL2 N Cal [15:8]
  poke_spll 0x0165 $PLL2_N_cal_7_0  ;# PLL2 N Cal [7:0]
  poke_spll 0x0169 0x0059           ;# Write this val after x165
  poke_spll 0x016A 0x0020
  poke_spll 0x016B 0x0000
  poke_spll 0x016C 0x0000
  poke_spll 0x016D 0x0000
  poke_spll 0x016E 0x0013
  poke_spll 0x0173 0x0010
  poke_spll 0x0177 0x0000
  poke_spll 0x0182 0x0000
  poke_spll 0x0183 0x0000
  poke_spll 0x0166 0x0000       ;# PLL2 N[17:16]
  poke_spll 0x0167 0x0000       ;# PLL2 N[15:8]
  poke_spll 0x0168 $PLL2_N_7_0  ;# PLL2 N[7:0]

  # Synchronize Output and SYSREF Dividers
  poke_spll 0x0143 0x00D3
  poke_spll 0x0144 0x0063
  poke_spll 0x0139 0x0012
  poke_spll 0x0140 0x0000
  poke_spll 0x013E 0x0000
  poke_spll 0x0144 0x00FF
  poke_spll 0x0139 0x0013
  poke_spll 0x0143 0x0013

  # Clear lost sticky
  poke_spll 0x0182 0x0003
  poke_spll 0x0182 0x0000
  # Check for Lock
  peek_spll 0x0183 "verbose"

  # Synchronize PLL1 N Divider
  poke_spll 0x0145 0x0050
  poke_spll 0x0177 0x0020
  poke_spll 0x0177 0x0000
  # Clear lost sticky
  poke_spll 0x0182 0x0003
  poke_spll 0x0182 0x0000
  # Check for Lock
  # peek_spll 0x0183
  after 2000
  puts "\[SPLL\] Checking for PLL Lock..."
  set locked_value [peek_spll 0x0183 "verbose"]
  if {($locked_value & 0xC) == 0x04} { puts "\[SPLL\] PLL1 Locked"} else \
    {puts "\[WARNING\] \[SPLL\] PLL1 Unlocked!!!"}
  if {($locked_value & 0x3) == 0x01} { puts "\[SPLL\] PLL2 Locked"} else \
    {puts "\[WARNING\] \[SPLL\] PLL2 Unlocked!!!"}

}
