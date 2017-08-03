#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3

#**************************************************************
# Constraints
#**************************************************************
derive_pll_clocks -create_base_clocks -use_net_name
derive_clock_uncertainty -add


set_false_path -thru {top_level:inst4|sys_reset:xGLOBAL_RESET|fpga_reset_pwr} 
set_false_path -thru {top_level:inst4|sys_reset:xGLOBAL_RESET|pulse_stretcher:xUSER_RESET|pulse[2]} 
set_false_path -thru {top_level:inst4|sys_reset:xGLOBAL_RESET|pulse_stretcher:xADC_RESET|pulse[2]} 
set_false_path -thru {top_level:inst4|sys_reset:xGLOBAL_RESET|adc_startup}
set_false_path -thru {top_level:inst4|sys_reset:xGLOBAL_RESET|pll_startup}
set_false_path -thru {top_level:inst4|sys_reset:xGLOBAL_RESET|dsa_startup}


create_clock -name master_clock 	-period 100.000MHz 	[get_ports {master_clock}]
create_clock -name master_clock1 -period 100.000MHz 	[get_ports {master_clock1}]

set_net_delay -from [get_ports {ADC_PIN15_PIN14_RST[0]}] -to [get_ports {ADC_PIN15_PIN14_RST[1]}] -max 0.05
set_net_delay -from [get_ports {ADC_PIN15_PIN14_RST[0]}] -to [get_ports {ADC_PIN15_PIN14_RST[2]}] -max 0.05
set_net_delay -from [get_ports {ADC_PIN15_PIN14_RST[0]}] -to [get_ports {ADC_PIN15_PIN14_RST[3]}] -max 0.05

