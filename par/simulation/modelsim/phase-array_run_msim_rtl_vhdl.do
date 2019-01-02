transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/altera_ip/pll_block.vho}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/altera_ip/pll_block.vhd}
vlog -vlog01compat -work work +incdir+C:/Users/eric/Desktop/firmware-phased-array/rtl/altera_ip/pll_block {C:/Users/eric/Desktop/firmware-phased-array/rtl/altera_ip/pll_block/pll_block_0002.v}
vlog -vlog01compat -work work +incdir+C:/Users/eric/Desktop/firmware-phased-array/rtl/verilog_lib {C:/Users/eric/Desktop/firmware-phased-array/rtl/verilog_lib/flag_sync.v}
vlog -vlog01compat -work work +incdir+C:/Users/eric/Desktop/firmware-phased-array/par/db {C:/Users/eric/Desktop/firmware-phased-array/par/db/rxlvds_lvds_rx.v}
vlog -vlog01compat -work work +incdir+C:/Users/eric/Desktop/firmware-phased-array/par/db {C:/Users/eric/Desktop/firmware-phased-array/par/db/rxserial_link_lvds_rx.v}
vlog -vlog01compat -work work +incdir+C:/Users/eric/Desktop/firmware-phased-array/par/db {C:/Users/eric/Desktop/firmware-phased-array/par/db/txserial_link_lvds_tx.v}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/altera_ip/vme_unused_pin_driver.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/altera_ip/txSerial_Link.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/altera_ip/rxSerial_Link.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/altera_ip/RxRAM.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/altera_ip/RxLVDS.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/usb/usb.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/usb/iobuf.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/sys_reset.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/spi_write.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/Slow_Clocks.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/serdes_wrapper.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/pulse_stretcher.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/pll_controller.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/defs.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/Clock_Manager.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/adc_controller.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/top_level.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/SerialLinks.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/RxData.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/registers.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/rdout_controller.vhd}
vcom -93 -work work {C:/Users/eric/Desktop/firmware-phased-array/rtl/atten_controller.vhd}

