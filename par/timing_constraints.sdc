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

#set_false_path -from [get_clocks {top_level:inst4|Clock_Manager:xCLOCKS|pll_block:xPLL_BLOCK|pll_block_0002:pll_block_inst|altera_pll:altera_pll_i|outclk_wire[1]}] -to [get_clocks {USB_IFCLK}] 
#set_multicycle_path 4 -setup -end -from [get_clocks {top_level:inst4|Clock_Manager:xCLOCKS|pll_block:xPLL_BLOCK|pll_block_0002:pll_block_inst|altera_pll:altera_pll_i|outclk_wire[1]}] -to [get_clocks {USB_IFCLK}] 


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

set_net_delay -from [get_ports {ADC_PIN15_PIN14_RST[0]}] -to [get_ports {ADC_PIN15_PIN14_RST[1]}] -max 0.05
set_net_delay -from [get_ports {ADC_PIN15_PIN14_RST[0]}] -to [get_ports {ADC_PIN15_PIN14_RST[2]}] -max 0.05
set_net_delay -from [get_ports {ADC_PIN15_PIN14_RST[0]}] -to [get_ports {ADC_PIN15_PIN14_RST[3]}] -max 0.05

