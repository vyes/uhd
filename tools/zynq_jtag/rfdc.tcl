set RF_BASE_OFFSET      0x001000100000
set ADC_FIFO_0_OFFSET   0x001000190000
set ADC_FIFO_1_OFFSET   0x0010001A0000

set MMCM_BASE_OFFSET 0x40000
set MMCM_RESET_BASE_OFFSET 0x51000
set RF_RESET_OFFSET         0x52000
set RF_STATUS_OFFSET         0x53000

# RFDC Common Regs
set IP_VER         0x0000
set MASTER_RESET   0x0004
set COMMON_ISR     0x0100
set COMMON_IER     0x0104


# RFDC Per-Tile Regs (must add offset)
set RESTART_STATE  0x0008
set CURRENT_STATE  0x000C
set COMMON_STATUS  0x0228
set ADC_NCO_FQWD_UPP_OFFSET	0x094
set ADC_NCO_FQWD_MID_OFFSET	0x098
set ADC_NCO_FQWD_LOW_OFFSET	0x09C
set NCO_UPDT_OFFSET 0x8C
set NCO_RST_OFFSET 0x90


# Bringup ###############################################################################
# #######################################################################################
proc init_rf {} {
  if {[fpga -state] != "FPGA is configured"} {
    puts "Load a bitfile!!!"
    return
  }
  rf_mmcm_reset
  rfdc_version
  rfdc_reset
  # enable the signal chain
  all_seq_reset
  reset_dac_chain 1
  reset_dac_chain 0
  reset_adc_chain 1
  reset_adc_chain 0
  # check the status
  rfdc_status ADC 0
  rfdc_status ADC 1
  rfdc_status DAC 0
  rfdc_status DAC 1
  # and the config states
  rfdc_config_state ADC 0
  rfdc_config_state ADC 1
  rfdc_config_state DAC 0
  rfdc_config_state DAC 1
  # report AXI-Stream status for RFDC
  get_axis_status
}




# Detailed Access #######################################################################
# #######################################################################################

proc rfdc_version { } {
  global IP_VER
  # report version info
  set version [peek_rfdc $IP_VER]
  if {$version == 0x02010000} {
    puts "\[RFDC\] RFDC version check passed!"
  } else {
    puts -nonewline "\[RFDC\] \[ERROR\] Failed version check. Actual: $version"
  }
}

proc rfdc_reset {} {
  global MASTER_RESET
  poke_rfdc $MASTER_RESET 0x1
  after 1000
}

proc get_conv_addr { conv num } {
  if { $num > 3} {
    puts "ERROR: Converters are only numbered 0-3"
    exit 2
  }
  if {$conv == "ADC"} {
    return [expr {0x14000 + ($num * 0x4000)}]
  } elseif {$conv == "DAC"} {
    return [expr {0x4000 + ($num * 0x4000)}]
  } else {
    puts "invalid converter request: must be ADC or DAC"
    exit
  }
}

proc get_drp_conv_addr { conv num } {
  if { $num > 3} {
    puts "ERROR: Converters are only numbered 0-3"
    exit 2
  }
  if {$conv == "ADC"} {
    return [expr {0x16000 + ($num * 0x4000)}]
  } elseif {$conv == "DAC"} {
    return [expr {0x6000 + ($num * 0x4000)}]
  } else {
    puts "invalid converter request: must be ADC or DAC"
    exit
  }
}

proc rfdc_config_state { conv num } {
  global CURRENT_STATE

  set raw_state [peek_rfdc [expr {$CURRENT_STATE + [get_conv_addr $conv $num]}] ]

  if {$raw_state <= 2} {
    set cur_state "Device Power-up and Configuration"
  } elseif {$raw_state <= 5} {
    set cur_state "Power Supply Adjustment"
  } elseif {$raw_state <= 10} {
    set cur_state "Clock Configuration"
  } elseif {$raw_state <= 13} {
    set cur_state "Converter Calibration"
  } elseif {$raw_state == 14} {
    set cur_state "Wait for De-assertion of AXI4-Stream Reset"
  } elseif {$raw_state == 15} {
    set cur_state "Done!"
  }

  # puts -nonewline "\[RFDC\] Current State (raw): $raw_state"
  puts "\[RFDC\] Config Status \[$conv\]\[$num\]: $cur_state"
}

proc rfdc_status { conv num } {
  global COMMON_STATUS
  set raw_status [peek_rfdc [expr {$COMMON_STATUS + [get_conv_addr $conv $num]}] ]
  if {($raw_status & 0xF) == 0x7} {
    puts "\[RFDC\] Converter Boot Status \[$conv\]\[$num\] : OK!"
  } else {
    puts "\[RFDC\] Converter Boot Status \[$conv\]\[$num\] : FAIL! $raw_status"
  }
  # puts "\[RFDC\]   >> PLL LOCKED:    [expr {($raw_status & 0x8) >> 3}]"
  # puts "\[RFDC\]   >> POWERUP STATE: [expr {($raw_status & 0x4) >> 2}]"
  # puts "\[RFDC\]   >> SUPPLIES UP:   [expr {($raw_status & 0x2) >> 1}]"
  # puts "\[RFDC\]   >> CLOCK PRESET:  [expr {($raw_status & 0x1) >> 0}]"
}


proc rfdc_get_nco { conv num } {
  global ADC_NCO_FQWD_UPP_OFFSET
  global ADC_NCO_FQWD_MID_OFFSET
  global ADC_NCO_FQWD_LOW_OFFSET
  puts "\[RFDC\] >> ADC_NCO_FQWD_UPP_OFFSET:  [peek_rfdc [expr {$ADC_NCO_FQWD_UPP_OFFSET + [get_drp_conv_addr $conv $num]}]]"
  puts "\[RFDC\] >> ADC_NCO_FQWD_MID_OFFSET:  [peek_rfdc [expr {$ADC_NCO_FQWD_MID_OFFSET + [get_drp_conv_addr $conv $num]}]]"
  puts "\[RFDC\] >> ADC_NCO_FQWD_LOW_OFFSET:  [peek_rfdc [expr {$ADC_NCO_FQWD_LOW_OFFSET + [get_drp_conv_addr $conv $num]}]]"
}

# set NCO_UPDT_OFFSET 0x8C
# set NCO_RST_OFFSET 0x90
proc rfdc_set_nco { conv num freq } {
  global ADC_NCO_FQWD_UPP_OFFSET
  global ADC_NCO_FQWD_MID_OFFSET
  global ADC_NCO_FQWD_LOW_OFFSET
  global NCO_UPDT_OFFSET
  global NCO_RST_OFFSET
  poke_rfdc [expr {$ADC_NCO_FQWD_UPP_OFFSET + [get_drp_conv_addr $conv $num]}] 0x01DE
  poke_rfdc [expr {$ADC_NCO_FQWD_MID_OFFSET + [get_drp_conv_addr $conv $num]}] 0x38E3
  poke_rfdc [expr {$ADC_NCO_FQWD_LOW_OFFSET + [get_drp_conv_addr $conv $num]}] 0x8E38

  # poke_rfdc [expr {$NCO_RST_OFFSET +  [get_drp_conv_addr $conv $num]}] 0x0
  poke_rfdc [expr {$NCO_RST_OFFSET +  [get_drp_conv_addr $conv $num]}] 0x1
  # poke_rfdc [expr {$NCO_RST_OFFSET +  [get_drp_conv_addr $conv $num]}] 0x0

  poke_rfdc [expr {$NCO_UPDT_OFFSET + [get_drp_conv_addr $conv $num]}] 0x2 0x7

}



# RFDC Access ###########################################################################
# #######################################################################################

proc poke_rfdc { addr data {mask 0xFFFFFFFF} } {
  global RF_BASE_OFFSET
  set addr [expr {$addr + $RF_BASE_OFFSET}]
  psu_mask_write $addr $mask $data
}

proc peek_rfdc { addr } {
  global RF_BASE_OFFSET
  set addr [expr {$addr + $RF_BASE_OFFSET}]
  set curval "0x[string range [mrd -force $addr] end-8 end]"
  return $curval
}

# MMCM Access ###########################################################################
# #######################################################################################

proc poke_rf_mmcm { addr data {mask 0xFFFFFFFF} } {
  global RF_BASE_OFFSET
  global MMCM_BASE_OFFSET
  set addr [expr {$addr + $RF_BASE_OFFSET + $MMCM_BASE_OFFSET}]
  psu_mask_write $addr $mask $data
}

proc peek_rf_mmcm { addr } {
  global RF_BASE_OFFSET
  global MMCM_BASE_OFFSET
  set addr [expr {$addr + $RF_BASE_OFFSET + $MMCM_BASE_OFFSET}]
  set curval "0x[string range [mrd -force $addr] end-8 end]"
  return $curval
}

proc rf_mmcm_reset {} {
  puts "\[RFDC\] Resetting RF MMCM..."
  # hard reset
  global RF_BASE_OFFSET
  global MMCM_RESET_BASE_OFFSET
  set addr [expr {$RF_BASE_OFFSET + $MMCM_RESET_BASE_OFFSET}]
  # in then out of reset (active-low)
  psu_mask_write $addr 0x1 0x0
  after 100
  psu_mask_write $addr 0x1 0x1
  after 100
  # poke the soft reset
  poke_rf_mmcm 0x0 0xA
  after 500
  set locked [peek_rf_mmcm 0x4]
  if {$locked == 0x1} {
    puts "\[RFDC\] RF MMCM is locked!"
  } else {
    puts "\[RFDC\] \[ERROR\] RF MMCM is unlocked!"
  }
}



# RF Control Access #####################################################################
# #######################################################################################

proc get_axis_status { } {
  set val [peek_rf_status_reg 0x0]
  puts "\[AXI-S\] DAC(3:0) TREADY @RFDC:     [format 0x%X [expr {($val >> 0) & 0xF}]]"
  puts "\[AXI-S\] DAC(3:0) TVALID @RFDC:     [format 0x%X [expr {($val >> 4) & 0xF}]]"
  puts "\[AXI-S\] ADC(3:0) Q TREADY @RFDC:   [format 0x%X [expr {($val >> 8) & 0xF}]]"
  puts "\[AXI-S\] ADC(3:0) Q TVALID @RFDC:   [format 0x%X [expr {($val >> 16) & 0xF}]]"
  puts "\[AXI-S\] ADC(3:0) I TREADY @RFDC:   [format 0x%X [expr {($val >> 12) & 0xF}]]"
  puts "\[AXI-S\] ADC(3:0) I TVALID @RFDC:   [format 0x%X [expr {($val >> 20) & 0xF}]]"
  puts "\[AXI-S\] ADC(3:0) OUT TVALID @USER: [format 0x%X [expr {($val >> 24) & 0xF}]]"
  puts "\[AXI-S\] ADC(3:0) OUT TREADY @USER: [format 0x%X [expr {($val >> 28) & 0xF}]]"
}

proc all_seq_reset { } {
  # all sequence reset on, then off
    puts "\[RF RST\] Resetting Reset Sequence..."
  poke_rf_reset_reg 0x0 [expr {1 << 0}]
  if {[expr {(1 << 3) & [peek_rf_reset_reg 0x8]}] == 0} {
    puts "\[RF RST\] \[ERROR\] All Sequence Reset Failed to Start!!!"
    return
  }
  poke_rf_reset_reg 0x0 [expr {0 << 0}] [expr {1 << 0}]
  if {[expr {(0 << 3) & [peek_rf_reset_reg 0x8]}] != 0} {
    puts "\[RF RST\] \[ERROR\] All Sequence Reset Failed to End!!!"
    return
  }
}

proc reset_dac_chain { val } {
  if {$val == 0} {
    # poke the DAC enable, then unpoke
    puts "\[RF RST\] Enabling the DAC chains..."
    poke_rf_reset_reg 0x0 [expr {1 << 9}] [expr {0x3 << 8}]
    if {[expr {(1 << 11) & [peek_rf_reset_reg 0x8]}] == 0} {
      puts "\[RF RST\] \[ERROR\] DAC Sequence Enable Failed to Start!!!"
      return
    }
    poke_rf_reset_reg 0x0 [expr {0 << 9}] [expr {0x3 << 8}]
    if {[expr {(0 << 11) & [peek_rf_reset_reg 0x8]}] != 0} {
      puts "\[RF RST\] \[ERROR\] DAC Sequence Enable Failed to End!!!"
      return
    }
  } else {
    # poke the DAC reset, then unpoke
    puts "\[RF RST\] Resetting the DAC chains..."
    poke_rf_reset_reg 0x0 [expr {1 << 8}] [expr {0x3 << 8}]
    if {[expr {(1 << 11) & [peek_rf_reset_reg 0x8]}] == 0} {
      puts "\[RF RST\] \[ERROR\] DAC Sequence Reset Failed to Start!!!"
      return
    }
    poke_rf_reset_reg 0x0 [expr {0 << 8}] [expr {0x3 << 8}]
    if {[expr {(0 << 11) & [peek_rf_reset_reg 0x8]}] != 0} {
      puts "\[RF RST\] \[ERROR\] DAC Sequence Reset Failed to End!!!"
      return
    }
  }
}

proc reset_adc_chain { val } {
  if {$val == 0} {
    # poke the ADC enable, then unpoke
    puts "\[RF RST\] Enabling the ADC chains..."
    poke_rf_reset_reg 0x0 [expr {1 << 5}] [expr {0x3 << 4}]
    if {[expr {(1 << 7) & [peek_rf_reset_reg 0x8]}] == 0} {
      puts "\[RF RST\] \[ERROR\] DAC Sequence Enable Failed to Start!!!"
      return
    }
    poke_rf_reset_reg 0x0 [expr {0 << 5}] [expr {0x3 << 4}]
    if {[expr {(0 << 7) & [peek_rf_reset_reg 0x8]}] != 0} {
      puts "\[RF RST\] \[ERROR\] ADC Sequence Enable Failed to End!!!"
      return
    }
  } else {
    # poke the ADC reset, then unpoke
    puts "\[RF RST\] Resetting the ADC chains..."
    poke_rf_reset_reg 0x0 [expr {1 << 4}] [expr {0x3 << 4}]
    if {[expr {(1 << 7) & [peek_rf_reset_reg 0x8]}] == 0} {
      puts "\[RF RST\] \[ERROR\] ADC Sequence Reset Failed to Start!!!"
      return
    }
    poke_rf_reset_reg 0x0 [expr {0 << 4}] [expr {0x3 << 4}]
    if {[expr {(0 << 7) & [peek_rf_reset_reg 0x8]}] != 0} {
      puts "\[RF RST\] \[ERROR\] ADC Sequence Reset Failed to End!!!"
      return
    }
  }
}

proc poke_rf_reset_reg { addr data {mask 0xFFFFFFFF} } {
  global RF_RESET_OFFSET
  global RF_BASE_OFFSET
  set addr [expr {$addr + $RF_RESET_OFFSET+ $RF_BASE_OFFSET}]
  psu_mask_write $addr $mask $data
}

proc peek_rf_reset_reg { addr } {
  global RF_RESET_OFFSET
  global RF_BASE_OFFSET
  set addr [expr {$addr + $RF_RESET_OFFSET+ $RF_BASE_OFFSET}]
  set curval "0x[string range [mrd -force $addr] end-8 end]"
  return $curval
}


proc peek_rf_status_reg { addr } {
  global RF_STATUS_OFFSET
  global RF_BASE_OFFSET
  set addr [expr {$addr + $RF_STATUS_OFFSET+ $RF_BASE_OFFSET}]
  set curval "0x[string range [mrd -force $addr] end-8 end]"
  return $curval
}


# ADC Data FIFO #########################################################################
# #######################################################################################
set ADC_FIFO_REG_ISR    0x00
set ADC_FIFO_REG_IER    0x04
set ADC_FIFO_REG_RDFR   0x18
set ADC_FIFO_REG_RDFO   0x1C
set ADC_FIFO_REG_RDFD   0x20
set ADC_FIFO_REG_RLR    0x24
set ADC_FIFO_REG_SRR    0x28




proc poke_adc_fifo { stream addr data {mask 0xFFFFFFFF} } {
  global ADC_FIFO_0_OFFSET
  global ADC_FIFO_1_OFFSET
  if {$stream == 0} {
    set addr [expr {$addr + $ADC_FIFO_0_OFFSET}]
  } else {
    set addr [expr {$addr + $ADC_FIFO_1_OFFSET}]
  }
  psu_mask_write $addr $mask $data
}
proc peek_adc_fifo { stream addr } {
  global ADC_FIFO_0_OFFSET
  global ADC_FIFO_1_OFFSET
  if {$stream == 0} {
    set addr [expr {$addr + $ADC_FIFO_0_OFFSET}]
  } else {
    set addr [expr {$addr + $ADC_FIFO_1_OFFSET}]
  }
  set curval "0x[string range [mrd -force $addr] end-8 end]"
  return $curval
}

proc get_adc_fifo_data {{stream 0}} {
  global ADC_FIFO_REG_ISR
  global ADC_FIFO_REG_IER
  global ADC_FIFO_REG_RDFR
  global ADC_FIFO_REG_RDFO
  global ADC_FIFO_REG_RDFD
  global ADC_FIFO_REG_RLR
  global ADC_FIFO_REG_SRR

  # clear ISR
  # poke_adc_fifo $stream $ADC_FIFO_REG_ISR 0xFFFFFFFF
  # after 500
  # puts -nonewline "\[ADC FIFO\]\[$stream\] ISR: [peek_adc_fifo $stream $ADC_FIFO_REG_ISR]"

  # hit the reset bit on the RX to clear it (self-clearing)
  puts "\[ADC FIFO\]\[$stream\] Resetting RX..."
  poke_adc_fifo $stream $ADC_FIFO_REG_SRR 0xA5
  after 100
  set reset_complete [expr {([peek_adc_fifo $stream $ADC_FIFO_REG_ISR] >> 23) & 0x1}]
  if {$reset_complete == 0} {
    puts "\[ADC FIFO\]\[$stream\] Reset Failed!"
    return
  }

  # clear ISR
  # poke_adc_fifo $stream $ADC_FIFO_REG_ISR 0xFFFFFFFF

  # report receive FIFO occupancy
  # puts -nonewline "\[ADC FIFO\]\[$stream\] RDFO: [peek_adc_fifo $stream $ADC_FIFO_REG_RDFO]"
  # after 1000

  # report ISR
  # puts -nonewline "\[ADC FIFO\]\[$stream\] ISR: [peek_adc_fifo $stream $ADC_FIFO_REG_ISR]"

  # read FIFO occupancy and then read out that # of words
  set num_words [peek_adc_fifo $stream $ADC_FIFO_REG_RDFO]
  puts "\[ADC FIFO\]\[$stream\] Reading [expr {$num_words & 0xFFFFFFFF}] Samples from device..."

  if {$num_words == 0} {
    puts "\[ADC FIFO\]\[$stream\] WARNING: No samples in FIFO!"
    return
  }

  # open output file and then read!
  set fp [open "adc_$stream.txt" w+]
  # set num_words 1024
  for {set a 0} {$a < $num_words} {incr a} {
    set data [peek_adc_fifo $stream $ADC_FIFO_REG_RDFD]
    set dataI [expr {$data & 0xFFFF}]
    set dataI [binary format s $dataI]
    binary scan $dataI s dataI

    set dataQ [expr {($data >> 16) & 0xFFFF}]
    set dataQ [binary format s $dataQ]
    binary scan $dataQ s dataQ

    puts $fp "$dataI, $dataQ"

    set rd_string "\[ADC FIFO\]\[$stream\] DATA: $data"
    # puts -nonewline $rd_string
  }

  close $fp
  puts "\[ADC FIFO\]\[$stream\] Done reading data!"

}

proc fetch_data {} {

  set fp_stop [open "stop.txt" r]
  set stop_bit [read $fp_stop]
  close $fp_stop

  while {$stop_bit == 0} {
    get_adc_fifo_data 0

    set fp_stop [open "stop.txt" r]
    set stop_bit [read $fp_stop]
    close $fp_stop
    after 2000
  }
  


}