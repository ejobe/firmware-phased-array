## Generated SDC file "Rx.out.sdc"

## Copyright (C) 1991-2012 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 12.0 Build 263 08/02/2012 Service Pack 2 SJ Full Version"

## DATE    "Wed Sep 05 11:16:48 2012"

##
## DEVICE  "5AGXFB5H4F35C4"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3

#**************************************************************
# Create Clock
#**************************************************************
derive_pll_clocks -create_base_clocks -use_net_name
derive_clock_uncertainty -add

####
#set_false_path -from *vme_interface*
#set_false_path -to *vme_interface*
#set_false_path -from vme_interface*
#set_false_path -to vme_interface*

#set_false_path -from *VME_thing*
#set_false_path -to *VME_thing*
#set_false_path -from VME_thing*
#set_false_path -to VME_thing*
#set_false_path -from tdc_vme*
#set_false_path -to tdc_vme*
#set_false_path -from _iack
#set_false_path -from _as
#set_false_path -from _ds[1]
#set_false_path -from _ds[0]

#set_false_path -from *tdc_vme*
#set_false_path -to *tdc_vme*
#set_false_path -from [get_registers {tapdel_10*dff_one*}] -to [get_registers {tapdel_10*dff_one*}]
#set_false_path -from * -to trigger_control*vme_buffer*CLOCK0_ENABLE0_0
#set_false_path -from * -to trigger_control*vme_buffer*CLOCK1_ENABLE1_0
###

#set_false_path -from vme_data[*] -to sld_signaltap*
#set_false_path -from address[*] -to sld_signaltap*

#set_false_path -from *signaltap*
#set_false_path -to *signaltap*

##false paths for global resets
set_false_path -from {top_level:inst4|sys_reset:xGLOBAL_RESET|fpga_reset_pwr} 
set_false_path -from {top_level:inst4|sys_reset:xGLOBAL_RESET|pulse_stretcher:xUSER_RESET|pulse[2]} 

#Clock Generation for PLL clocks

#create_generated_clock -name The_clock  -source [get_nets {inst134|pll_new_inst|altera_pll_i|arriav_pll|divclk[0]}] -divide_by 1 -multiply_by 1 -duty_cycle 50 -phase 0 -offset 0 
#create_generated_clock -name vme_service_clock -source [get_nets {inst134|pll_new_inst|altera_pll_i|arriav_pll|divclk[2]}] -divide_by 1 -multiply_by 1 -duty_cycle 50 -phase 0 -offset 0 

#create_clock -name tapdel -period 40.000 [get_registers {tapdel_10:inst45|dff_one:inst*|lpm_ff:lpm_ff_component|dffs[0]}]
#create_clock -name tapdel10_del1 -period 40.000 [get_registers {tapdel10:inst13|del1}]
#create_clock -name tapdel10_del5 -period 40.000 [get_registers {tapdel10:inst13|del5}]
#create_clock -name vme_interface_del80 -period 40.000 [get_registers {vme_interface:inst2|del80}]
#create_clock -name _delayed_ds_in -period 40.000 [get_registers {dff_one:inst15|lpm_ff:lpm_ff_component|dffs[0]}]

create_clock -name master_clock 	-period 100.000MHz 	[get_ports {master_clock}]
create_clock -name master_clock1 -period 100.000MHz 	[get_ports {master_clock1}]
create_clock -name USB_IFCLK		-period 48.0MHz 		[get_ports {USB_IFCLK}]
create_clock -name GXB_ref_clk_0	-period 100.0MHz 		[get_ports {GXB_ref_clk_0}]

#create_clock -name ADC_CLK_0		-period 187.5MHz 	[get_ports {ADCclk0}]
#create_clock -name ADC_CLK_1		-period 187.5MHz 	[get_ports {ADCclk1}]
#create_clock -name ADC_CLK_2		-period 187.5MHz 	[get_ports {ADCclk2}]
#create_clock -name ADC_CLK_3		-period 187.5MHz 	[get_ports {ADCclk3}]

#create_clock -name _as -period 16.000 [get_ports {_as}]

#create_clock -name SPIclock1 -period 100.000 [get_registers {SPI_Interface:inst37|SPI_counter_5:inst27|lpm_counter:lpm_counter_component|cntr_aei:auto_generated|counter_reg_bit[3]}]
#create_clock -name SPIclock2 -period 100.000 [get_registers {SPI_Interface:inst47|SPI_counter_5:inst27|lpm_counter:lpm_counter_component|cntr_aei:auto_generated|counter_reg_bit[3]}]
#create_clock -name SPIclock3 -period 100.000 [get_registers {SPI_Interface:inst49|SPI_counter_5:inst27|lpm_counter:lpm_counter_component|cntr_aei:auto_generated|counter_reg_bit[3]}]
#create_clock -name SPIclock4 -period 100.000 [get_registers {SPI_Interface:inst56|SPI_counter_5:inst27|lpm_counter:lpm_counter_component|cntr_aei:auto_generated|counter_reg_bit[3]}]


#VME Interface    Asynchronous Interface I/O timing
#create_clock -period 40 -name vme_virtual_clock
#create_clock -period 40 -name _ds             -waveform { 0 20 } [get_ports {_ds[*]}]
#create_clock -period 40 -name _as              -waveform { 0 20 } [get_ports {_as}]


#set_input_delay  -clock { vme_virtual_clock } -max 10 [get_ports {address* am* _as _iack _ga* _lword _vme_write vme_data* _ds*}]
#set_input_delay  -clock { vme_virtual_clock } -min  1 [get_ports {address* am* _as _iack _ga* _lword _vme_write vme_data* _ds*}]

#set_input_delay  -clock { The_clock } -max  0 [get_ports {DigIn[*] CRC_ERROR_IN}]
#set_input_delay  -clock { The_clock } -min  0 [get_ports {DigIn[*] CRC_ERROR_IN}]
