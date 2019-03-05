

# PDAC Poke #############################################################################
# #######################################################################################

# spi_cmd dict :
#   rd_flag
#   slave
#   message

proc poke_pdac { data } {
  set_mode 1
  set cmd    0x3
  set addr_3 0x0
  set data_12 [expr {$data & 0xFFF}]
  set message [expr {$cmd << 19} | {$addr_3 << 16} | {$data_12 << 4} ]
  set poke_l [dict create   rd_flag 0  slave 2 message $message]
  spi_xfer $poke_l
}

# Need to turn on the internal reference before using the chip.
proc pdac_init { } {
  set_mode 1
  set cmd    0x7
  set addr_3 0x0
  set data 0x0001
  set message [expr {$cmd << 19} | {$addr_3 << 16} | {$data} ]
  set poke_l [dict create   rd_flag 0  slave 2 message $message]
  spi_xfer $poke_l
}

# SPLL Peek/Poke ########################################################################
# #######################################################################################

# spi_cmd dict :
#   rd_flag
#   slave
#   message

proc poke_spll { addr data } {
  set_mode 3
  set addr_15 [expr {$addr & 0xEFFF}]
  set data_8 [expr {$data & 0xFF}]
  set rd_flag 0x0
  set message [expr {$rd_flag << 23} | {$addr_15 << 8} | $data_8 ]
  set poke_l [dict create   rd_flag $rd_flag  slave 0 message $message]
  spi_xfer $poke_l
}

proc peek_spll { addr {verbosity "quiet"} } {
  set_mode 3
  set addr_15 [expr {$addr & 0xEFFF}]
  set rd_flag 0x1
  set message [expr {$rd_flag << 15} | $addr_15]
  set peek_l [dict create   rd_flag $rd_flag  slave 0 message $message]
  set rd_data [format 0x%x [spi_xfer $peek_l]]
  if {$verbosity == "verbose"} {puts "\[SPLL\] Read ADDR: $addr DATA: $rd_data"}
  return $rd_data
}

# SPI Driver ############################################################################
# #######################################################################################

# Basic register map for Xilinx SPI registers.
# Note: These are the registers for SPI 1.
# It can be later expanded to support SPI 0 as well.
set CONFIG_REG_1    0xFF050000
set INTR_STAT_REG_1 0xFF050004
set INTR_EN_REG_1   0xFF050008
set INTR_DIS_REG_1  0xFF05000C
set INTR_MSK_REG_1  0xFF050010
set SPI_EN_REG_1    0xFF050014
set CLK_DEL_REG_1   0xFF050018
set TX_DATA_REG_1   0xFF05001C
set RX_DATA_REG_1   0xFF050020
set SLV_IDL_REG_1   0xFF050024
set TX_THRES_REG_1  0xFF050028
set RX_THRES_REG_1  0xFF05002C
set MOD_ID_REG_1    0xFF0500FC

proc spi_init { } {
  spi_enable 0         ;# disable SPI
  spi_enable_intr 0x0  ;# disable interrupts
  spi_clr_rx_fifo
  spi_clr_intr

  # Config chip select to manual, chip select disabled, and master mode
  set config_mask [expr {0x4000 | 0x3C00 | 0x0001}]
  # Config auto-start mode
  set config_mask [expr {$config_mask & ~0x8000}]
  global CONFIG_REG_1
  psu_mask_write $CONFIG_REG_1 0xFFFFFFFF $config_mask

  set_div
  set_mode 3

  spi_enable 1
}

proc set_mode { mode } {
  switch $mode {
    0 {
      set CPHA 0
      set CPOL 0
    }
    1 {
      set CPHA 1
      set CPOL 0
    }
    2 {
      set CPHA 0
      set CPOL 1
    }
    default {
      set CPHA 1
      set CPOL 1
    }
  }
  set mask [expr {(0x1 << 2) | (0x1 << 1)}]
  set value [expr {($CPHA << 2) | ($CPOL << 1)}]
  global CONFIG_REG_1
  psu_mask_write $CONFIG_REG_1 $mask $value
}

proc spi_enable { is_enable } {
  set mask 0x01
  set value 0
  if { $is_enable == 1 } {
    set value $mask
  }
  global SPI_EN_REG_1
  psu_mask_write $SPI_EN_REG_1 $mask $value
}

proc spi_enable_intr { is_enable } {
  global INTR_DIS_REG_1
  global INTR_EN_REG_1
  set mask 0x7F             ;# all interrupts
  if { $is_enable == 0 } {  ;# disable
    psu_mask_write $INTR_DIS_REG_1 $mask $mask
  } else { ;# enable
    psu_mask_write $INTR_EN_REG_1 $mask $mask
  }
}

proc spi_clr_rx_fifo { {timeout 10000} } {
  # Clear the SPI RX FIFO by reading until it is empty
  global INTR_STAT_REG_1
  set mask 0x10             ;# bit 4 = RX_FIFO_not_empty
  set count 1
  set rx_not_empty [ mask_read $INTR_STAT_REG_1 $mask ]
  while { $rx_not_empty } {
    set rd_data [spi_rd_rxdr]
    set rx_not_empty [ mask_read $INTR_STAT_REG_1 $mask ]
    set count [ expr { $count + 1 } ]
    if { $count == $timeout } {
      puts "Timeout Reached while trying to empty RX FIFO"
      break
    }
  }
}

proc set_div { } {
    global CONFIG_REG_1
    set mask 0x38
    set value [expr 0x5 << 3]
    psu_mask_write $CONFIG_REG_1 $mask $value
}

proc spi_clr_intr { } {
  # Clear all interrupts by writing to the status register
  global INTR_STAT_REG_1
  set mask 0x7F             ;# all interrupts
  psu_mask_write $INTR_STAT_REG_1 $mask $mask
}

proc spi_rd_rxdr {  } {
  # Read data from the SPI RX FIFO
  global RX_DATA_REG_1
  set mask 0x0FF
  return [ mask_read $RX_DATA_REG_1 $mask ]
}

proc spi_wr_txdr { data } {
  # Write data to the SPI TX FIFO
  global TX_DATA_REG_1
  set mask 0x0FF
  set data_8 [expr {$data & 0xFF}]
  psu_mask_write $TX_DATA_REG_1 $mask $data_8
}

proc spi_cs_activate { slave } {
  # TODO: Wait for transaction delay to be satisfied
  global CONFIG_REG_1
  set mask 0x3C00
  set value 0x0F
  if { $slave == 0 } {
    set value 0x00
  } elseif { $slave == 1 } {
    set value 0x01
  } elseif { $slave == 2 } {
    set value 0x03
  }
  set value [expr {$value << 10}]
  psu_mask_write $CONFIG_REG_1 $mask $value
  # TODO: Wait for activation delay to be satisfied
}

proc spi_cs_deactivate {  } {
  global CONFIG_REG_1
  set mask 0x3C00
  psu_mask_write $CONFIG_REG_1 $mask $mask
}

# spi_cmd dict :
#   rd_flag
#   slave
#   data

proc spi_xfer { spi_cmd } {
  # Empty list for storing read data
  set rd_data [list]

  set rd_flag [dict get $spi_cmd rd_flag]
  set slave [dict get $spi_cmd slave]
  set message [dict get $spi_cmd message]

  spi_cs_activate $slave

  if {$rd_flag} {
    # spi read message is [15]rd_flag,[14:0]addr (LMK Specific)
    # put addr_hi in tx fifo
    spi_wr_txdr [expr {$message >> 8} & 0xFF]
    # put addr_lo in tx fifo
    spi_wr_txdr [expr $message & 0xFF]
    # fill last byte with zeros (ignored by LMK)
    spi_wr_txdr 0x00
  } else {
    # spi write message is [24]rd_flag,[23:8]addr,[7:0]data (LMK Specific)
    # put addr_hi in tx fifo
    spi_wr_txdr [expr {$message >> 16} & 0xFF]
    # put addr_lo in tx fifo
    spi_wr_txdr [expr {$message >> 8} & 0xFF]
    # put data in tx fifo
    spi_wr_txdr [expr $message & 0xFF]
  }

  # Read three bytes (but only the last will be data)
  for {set n 0} {$n < 40} {incr n} {
    set read_data [spi_rd_rxdr]
    lappend rd_data $read_data
  }

  spi_cs_deactivate
  return [lindex $rd_data 2]
}
