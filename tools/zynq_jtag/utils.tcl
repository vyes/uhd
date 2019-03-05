source ./x410/psu_init.tcl
source ./i2c.tcl
source ./spi.tcl
source ./gpio.tcl
source ./rpll_config.tcl
source ./spll_config.tcl
source ./rfdc.tcl


proc init {} {
  # Configure PS
  psu_init
  psu_post_config
  psu_ps_pl_isolation_removal
  psu_ps_pl_reset_config

  # Configure I2C and SPI engines
  blink_led; # hello?

  puts "\[I2C\] Initializing the I2C bus..."
  i2c_init
  i2c_reset "true"; after 100; i2c_reset "false"

  puts "\[SPI\] Initializing the SPI bus..."
  spi_init
}

proc init_clocks { {out_freq 3e9} } {
  rpll_init
  spll_init $out_freq
}


proc load_fpga {} {
  fpga {G:\fpgadev\usrp3\top\x400\build-X410_XG\x4xx.bit}
}




proc rpll_init { } {
  # Assert then de-assert RPLL reset
  puts "\[RPLL\] Toggling hard reset..."
  reset_rpll 1; after 100; reset_rpll 0
  rpll_config
}

proc spll_init { {out_freq 3e9} } {
  # hard reset toggle
  puts "\[SPLL\] Toggling hard reset..."
  reset_spll_hard 1; after 100; reset_spll_hard 0
  spll_config $out_freq
}



# Misc Helper Procs #####################################################################

proc poll { addr mask data {timeout 10000}} {
  set curval "0x[string range [mrd -force $addr] end-8 end]"
  set maskedval [expr {$curval & $mask}]
  set count 1
  while { $maskedval != $data } {
    set curval "0x[string range [mrd -force $addr] end-8 end]"
    set maskedval [expr {$curval & $mask}]
    set count [ expr { $count + 1 } ]
    if { $count == $timeout } {
      puts "Timeout Reached. Mask poll failed at ADDRESS: $addr MASK: $mask DATA: $curval"
      break
    }
  }
}

proc psu_mask_write { addr mask value } {
  set curval "0x[string range [mrd -force $addr] end-8 end]"
  # puts -nonewline "\[PSU MASK WRITE\] CurVal: $curval"
  set curval [expr {$curval & ~($mask)}]
  set maskedval [expr {$value & $mask}]
  set maskedval [expr {$curval | $maskedval}]
  # puts "\[PSU MASK WRITE\] WriteVal: [format 0x%x $maskedval]"
  mwr -force $addr $maskedval
}

proc mask_read { addr mask } {
  set curval "0x[string range [mrd -force $addr] end-8 end]"
  set maskedval [expr {$curval & $mask}]
  return $maskedval
}

