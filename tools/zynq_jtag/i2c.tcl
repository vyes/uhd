

# RPLL Peek/Poke ########################################################################
# #######################################################################################
proc poke_rpll { addr data } {
  set RPLL_BUS_NUM 4
  set_i2c_switch $RPLL_BUS_NUM
  set poke_l [list \
    [dict create           rd_flag 0  addr 0x54  data [list $addr $data]  len  2 ] \
  ]
  i2c_xfer $poke_l
}
proc peek_rpll { addr {verbosity "quiet"} } {
  set RPLL_BUS_NUM 4
  set_i2c_switch $RPLL_BUS_NUM
  set peek_l [list \
    [dict create           rd_flag 0  addr 0x54  data $addr  len  1 ] \
    [dict create           rd_flag 1  addr 0x54  data 0x00   len  1 ] \
  ]
  set rd_data [i2c_xfer $peek_l]
  # Since it's a two-stage read operation, throw away the high byte.
  set rd_data [lindex [lindex $rd_data 0] 0]
  if {$verbosity == "verbose"} {puts "\[RPLL\] Read ADDR: $addr DATA: $rd_data"}
  return $rd_data
}

# GPIO Peek/Poke ########################################################################
# #######################################################################################
proc poke_i2c_gpio { addr data } {
  set GPIO_BUS_NUM 6
  set_i2c_switch $GPIO_BUS_NUM
  set poke_l [list \
    [dict create           rd_flag 0  addr 0x20  data [list $addr $data]  len  2 ] \
  ]
  i2c_xfer $poke_l
}
proc peek_i2c_gpio { addr {verbosity "quiet"} } {
  set GPIO_BUS_NUM 6
  set_i2c_switch $GPIO_BUS_NUM
  set peek_l [list \
    [dict create           rd_flag 0  addr 0x20  data $addr  len  1 ] \
    [dict create           rd_flag 1  addr 0x20  data 0x00   len  1 ] \
  ]
  set rd_data [i2c_xfer $peek_l]
  # Since it's a two-stage read operation, throw away the high byte.
  set rd_data [lindex [lindex $rd_data 0] 0]
  if {$verbosity == "verbose"} {puts "\[GPIO\] Read ADDR: $addr DATA: $rd_data"}
  return $rd_data
}
proc mask_poke_i2c_gpio { addr mask data } {
  set curval [peek_i2c_gpio $addr]
  set curval [expr {$curval & ~($mask)}]
  set maskedval [expr {$data & $mask}]
  set maskedval [expr {$curval | $maskedval}]
  poke_i2c_gpio $addr $maskedval
}

# #### set_i2c_switch ####
# Directs the I2C switch to target a certain bus number.
proc set_i2c_switch { bus } {
  set data [expr {0x1 << $bus}]
  i2c_xfer [list [dict create    rd_flag 0  addr 0x70  data $data  len  1 ]]
}



#########################################################################################
## LOW LEVEL DRIVER #####################################################################
#########################################################################################

proc enable_interrupts {  } {
  set intr_en_reg 0xFF030024
  set mask 0xFF
  psu_mask_write $intr_en_reg $mask 0xFF
  # puts "\[INFO\] \[I2C\] enabled I2C interrupts"
}

proc i2c_init {  } {
  set conf_reg 0xFF030000
  set mask 0xFFFF
  psu_mask_write $conf_reg $mask 0xFF0E
  # puts "\[INFO\] \[I2C\] divisor and master config"
}

proc clear_fifo {  } {
  set conf_reg 0xFF030000
  set mask 0x40
  psu_mask_write $conf_reg $mask 0x40
  # puts "\[INFO\] \[I2C\] cleared I2C FIFO"
}

proc clear_interrupts {  } {
  set intr_reg 0xFF030010
  set mask 0xFF
  psu_mask_write $intr_reg $mask 0xFF
  # puts "\[INFO\] \[I2C\] cleared I2C interrupts"
}

proc set_master_direction { val } {
  set conf_reg 0xFF030000
  set mask 0x1
  if {$val == "transmit"} { set write_val 0 } else { set write_val 1 }
  psu_mask_write $conf_reg $mask $write_val
  # puts "\[INFO\] \[I2C\] setting I2C direction to $val"
}

proc set_i2c_hold { val } {
  set conf_reg 0xFF030000
  set bit 4
  set mask [expr {0x1 << $bit}]
  if {$val == "true"} { set write_val 1 } else { set write_val 0 }
  psu_mask_write $conf_reg $mask [expr {$write_val << $bit}]
  # puts "\[INFO\] \[I2C\] setting I2C hold to $write_val"
}

proc set_i2c_transfer_size { size } {
  set tran_reg 0xFF030014
  set mask 0x00FF
  psu_mask_write $tran_reg $mask $size
  # puts "\[INFO\] \[I2C\] setting I2C transfer count to $size"
}

proc set_i2c_address { addr } {
  set addr_reg 0xFF030008
  set mask 0x01FF
  psu_mask_write $addr_reg $mask $addr
  # puts "\[INFO\] \[I2C\] setting I2C address to $addr"
}

proc set_i2c_data { data } {
  set data_reg 0xFF03000C
  set mask 0x0FF
  psu_mask_write $data_reg $mask $data
  # puts "\[INFO\] \[I2C\] setting I2C data register to $data"
}

proc get_i2c_data { } {
  set data_reg 0xFF03000C
  set data [format 0x%X [mask_read $data_reg 0xFF]]
  # puts "Raw read data: $data"
  return $data
}

# polls on the specified interrupt bit
proc i2c_wait { bit data } {
  set intr_reg 0xFF030010
  set mask [expr {0x1 << $bit}]
  set data [expr {$data << $bit}]
  poll $intr_reg $mask $data 1000
}

proc get_status { } {
  set stat_reg 0xFF030004
  return [mask_read $stat_reg 0xFF]
}



proc i2c_write { addr data len } {
  clear_fifo
  set_master_direction "transmit"
  # WARNING: skipping bus hold
  clear_interrupts
  # puts "\[INFO\] \[I2C\] executing write..."
  for {set x 0} {$x < $len} {incr x} {
    set_i2c_data [lindex $data $x]
  }
  # set_i2c_transfer_size $len
  set_i2c_address $addr
  # WARNING: skipping bus hold release
  # wait for data to be sent
  set comp_bit 0
  i2c_wait $comp_bit 0x1
  # puts "\[INFO\] \[I2C\] i2c_write complete for $len bytes of data"
  # return 0
}

proc i2c_read { addr recv_count } {
  set curr_recv_count $recv_count
  clear_fifo
  set_master_direction "receive"
  # WARNING: skipping bus hold
  # start reading the data
  set_i2c_address $addr
  set_i2c_transfer_size $recv_count
  set I2C_STATUS_RXDV 5
  set x 0
  set count 0
  set rd_data [list]
  while {$x < $recv_count} {
    while {[get_status] && $I2C_STATUS_RXDV} {
      lappend rd_data [get_i2c_data]
      incr x
      after 100
    }
    after 100
    incr count
    if {$count > 100} { break }
  }
  # WARNING: skipping bus hold release
  # wait for data to be received
  set comp_bit 0
  i2c_wait $comp_bit 0x1
  # puts "\[INFO\] \[I2C\] i2c_read complete for $recv_count bytes of data"
  return $rd_data
}


# msg dict :
#   rd_flag
#   addr
#   data
#   len

proc i2c_xfer { msg } {
  set nmsgs [llength $msg]
  if {$nmsgs > 1} {
    set hold_flag 1
    set_i2c_hold "true"
  } else {
    set hold_flag 0
    set_i2c_hold "false"
  }

  # Empty list for storing read data
  set rd_data [list]

  for {set n 0} {$n < $nmsgs} {incr n} {
    set msg_i [lindex $msg $n]
    set addr [dict get $msg_i addr]
    set len [dict get $msg_i len]
    if {[dict get $msg_i rd_flag]} {
      lappend rd_data [i2c_read $addr $len]
    } else {
      set data [dict get $msg_i data]
      i2c_write $addr $data $len
    }
  }

  if {$hold_flag == 1} {
    set_i2c_hold "false"
  }

  return $rd_data

}
