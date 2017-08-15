#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3

#**************************************************************
# Constraints
#**************************************************************
derive_pll_clocks -create_base_clocks -use_net_name
derive_clock_uncertainty -add

create_clock -name master_clock 	-period 100.000MHz 	[get_ports {master_clock}]
create_clock -name master_clock1 -period 100.000MHz 	[get_ports {master_clock1}]

set_net_delay -from [get_ports {ADC_PIN15_PIN14_RST[0]}] -to [get_ports {ADC_PIN15_PIN14_RST[1]}] -max 0.050
set_net_delay -from [get_ports {ADC_PIN15_PIN14_RST[0]}] -to [get_ports {ADC_PIN15_PIN14_RST[2]}] -max 0.050
set_net_delay -from [get_ports {ADC_PIN15_PIN14_RST[0]}] -to [get_ports {ADC_PIN15_PIN14_RST[3]}] -max 0.050

#set false paths from async. resets
set_false_path -from {top_level:inst|sys_reset:xGLOBAL_RESET|pulse_stretcher_sync:xUSER_RESET|pulse_o} -to *
set_false_path -from {top_level:inst|sys_reset:xGLOBAL_RESET|pulse_stretcher_sync:xUSER_SYS_RESET|pulse_o} -to *
set_false_path -from {top_level:inst|sys_reset:xGLOBAL_RESET|fpga_reset_pwr} -to *
set_false_path -from {top_level:inst|sys_reset:xGLOBAL_RESET|pulse_stretcher_sync:xADC_RESET|pulse_o} -to *


#set_multicycle_path -from {top_level:inst4|adc_controller:xADC_CONTROLLER|internal_data_valid_fast_clk} -to {top_level:inst4|adc_controller:xADC_CONTROLLER|Signal_Sync:xDATAVALIDSYNC|SyncA_clkB[0]} -setup -start 4
#set_multicycle_path -from {top_level:inst4|adc_controller:xADC_CONTROLLER|Signal_Sync:xDATAVALIDSYNC|SyncA_clkB[1]} -to {top_level:inst4|RxData:\ReceiverBlock:0:xDATA_RECEIVER|Signal_Sync:xDATVALIDSYNC|SyncA_clkB[0]} -setup -start 4
#set_multicycle_path -from {top_level:inst4|adc_controller:xADC_CONTROLLER|Signal_Sync:xDATAVALIDSYNC|SyncA_clkB[1]} -to {top_level:inst4|RxData:\ReceiverBlock:1:xDATA_RECEIVER|Signal_Sync:xDATVALIDSYNC|SyncA_clkB[0]} -setup -start 4
#set_multicycle_path -from {top_level:inst4|adc_controller:xADC_CONTROLLER|Signal_Sync:xDATAVALIDSYNC|SyncA_clkB[1]} -to {top_level:inst4|RxData:\ReceiverBlock:2:xDATA_RECEIVER|Signal_Sync:xDATVALIDSYNC|SyncA_clkB[0]} -setup -start 4
#set_multicycle_path -from {top_level:inst4|adc_controller:xADC_CONTROLLER|Signal_Sync:xDATAVALIDSYNC|SyncA_clkB[1]} -to {top_level:inst4|RxData:\ReceiverBlock:3:xDATA_RECEIVER|Signal_Sync:xDATVALIDSYNC|SyncA_clkB[0]} -setup -start 4

