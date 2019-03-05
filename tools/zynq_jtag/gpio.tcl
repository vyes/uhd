
proc blink_led { } {
  # tell me you're alive.
  set_gpio_mio1 14 0
  after 100
  set_gpio_mio1 14 1
  after 100
  set_gpio_mio1 14 0
  after 100
  set_gpio_mio1 14 1
  after 100
  set_gpio_mio1 14 0
}

proc i2c_reset { val } {
  set val [expr {!($val && "true")}]
  # puts "\[INFO\] \[GPIO\] Setting active-low I2C reset to $val"
  set_gpio_mio1 13 $val
}

proc set_gpio_mio0 { mio val } {
  set data_addr 0xFF0A0040
  set dir_addr  0xFF0A0204
  set oen_addr  0xFF0A0208
  psu_mask_write $dir_addr  [expr {1 << $mio}] [expr {$val << $mio}]
  psu_mask_write $oen_addr  [expr {1 << $mio}] [expr {$val << $mio}]
  psu_mask_write $data_addr [expr {1 << $mio}] [expr {$val << $mio}]
  # puts "\[INFO\] \[GPIO\] Set gpio MIO0[$mio] to $val"
}

proc set_gpio_mio1 { mio val } {
  set data_addr 0xFF0A0044
  set dir_addr  0xFF0A0244
  set oen_addr  0xFF0A0248
  psu_mask_write $dir_addr  [expr {1 << $mio}] [expr {$val << $mio}]
  psu_mask_write $oen_addr  [expr {1 << $mio}] [expr {$val << $mio}]
  psu_mask_write $data_addr [expr {1 << $mio}] [expr {$val << $mio}]
  # puts "\[INFO\] \[GPIO\] Set gpio MIO1[$mio] to $val"
}

proc set_gpio_mio2 { mio val } {
  set data_addr 0xFF0A0048
  set dir_addr  0xFF0A0284
  set oen_addr  0xFF0A0288
  psu_mask_write $dir_addr  [expr {1 << $mio}] [expr {$val << $mio}]
  psu_mask_write $oen_addr  [expr {1 << $mio}] [expr {$val << $mio}]
  psu_mask_write $data_addr [expr {1 << $mio}] [expr {$val << $mio}]
  # puts "\[INFO\] \[GPIO\] Set gpio MIO2[$mio] to $val"
}

