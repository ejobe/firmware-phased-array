---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         top_level.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         1/2016 --> 
--
-- DESCRIPTION:  design top level vhdl
--
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.defs.all;
use work.register_map.all;

entity top_level is
	--//specify firmware type using compile time flag (FIRMWARE_DEVICE is never overloaded):
	----- Master = 1 (all functionality) ; Slave = 0 (removes beamforming, the phased trigger, cal pulser output, ...)
	----------------------------------
	Generic(
		FIRMWARE_DEVICE : std_logic := '1');
	----------------------------------	
	Port(
		--//Master clocks (2 copies, 100 MHz)
		MClk_0			:	in		std_logic;
		MClk_1			:	in		std_logic;
		--//ADC data inputs (all LVDS)
		ADC_Dat_0     	:	in		std_logic_vector(27 downto 0);
		ADC_Clk_0		:	in		std_logic;
		ADC_Dat_1     	:	in		std_logic_vector(27 downto 0);
		ADC_Clk_1		:	in		std_logic;		
		ADC_Dat_2     	:	in		std_logic_vector(27 downto 0);
		ADC_Clk_2		:	in		std_logic;
		ADC_Dat_3     	:	in		std_logic_vector(27 downto 0);
		ADC_Clk_3		:	in		std_logic;	
		ADC_OvRange  	:	in	   std_logic_vector(3 downto 0); --//Out of Range indicator
		--//ADC programming pins
		ADC_SClk			: 	out	std_logic; 							--//serial programming clk
		ADC_SData		:  out	std_logic_vector(3 downto 0); --//serial programming data
		ADC_DES_SCSb  	: 	out	std_logic_vector(3 downto 0); --//CalDly / DES (active hi) / SCS (active lo)
		ADC_ECEb			:  out   std_logic; 							--//ext ended control (serial progamming) enable (active lo)
		ADC_PD			:  out   std_logic_vector(3 downto 0); --//power-down, active hi
		ADC_PDq			:  out   std_logic; 							--//power-down, q-channel only, tive hi
		ADC_Cal			:  out	std_logic;							--//initiates calibration cycle
		ADC_DCLK_RST	:	out	std_logic_vector(3 downto 0); --//ADC dclk sync, LVDS 
		ADC_DRST_SEL	:	out	std_logic; 							--//selects ^ single-ended or LVDS
		--//USB FX2 interface
		USB_IFCLK		: 	inout	std_logic;
		USB_WAKEUP		:	inout std_logic;
		USB_CTL     	:	inout	std_logic_vector(2 downto 0);
		USB_PA			: 	inout std_logic_vector(7 downto 0);	
		USB_FD			:	inout	std_logic_vector(15 downto 0);
		USB_RDY			:	out	std_logic_vector(1 downto 0);
		--//Trigger SMA's (all bi-directional, pin names match silkscreen label direction for clarity)
		SMA_in			: 	inout	std_logic;
		SMA_out0			: 	inout	std_logic;
		SMA_out1			: 	inout	std_logic;
		--//LMK04808 interface
		LMK_SYNC			:  inout std_logic;
		LMK_Stat_Hldov :  inout std_logic;
		LMK_Stat_LD		:	inout std_logic;
		LMK_Stat_Clk0	:	inout std_logic;
		LMK_Stat_Clk1	:  inout std_logic;
		LMK_LEu_uWire	:  inout	std_logic;
		LMK_CLK_uWire	:  inout	std_logic;
		LMK_DAT_uWire	:	inout	std_logic;
		--//Serial data links
		SYS_serial_in  :  in 	std_logic;
		SYS_serial_out	:  out	std_logic;
		LOC_serial_in0 :  in		std_logic;
		LOC_serial_in1 :  in		std_logic;
		--LOC_serial_in2 :  in		std_logic; --//wiring to this RJ45 jack broken on schematic
		--LOC_serial_in3 :  in		std_logic; --//wiring to this RJ45 jack broken on schematic
		LOC_serial_out0:  out	std_logic;
		LOC_serial_out1:  out	std_logic;
		--LOC_serial_out2:  out	std_logic; --//wiring to this RJ45 jack broken on schematic
		--LOC_serial_out3:  out	std_logic; --//wiring to this RJ45 jack broken on schematic
		SerialLinkTri0 : inout std_logic;  --//use these to tri-state the incorrectly wired (formerly) LVDS pairs
		SerialLinkTri1 : inout std_logic;
		SerialLinkTri2 : inout std_logic;
		SerialLinkTri3 : inout std_logic;
		SerialLinkTri4 : inout std_logic;
		SerialLinkTri5 : inout std_logic;
		SerialLinkTri6 : inout std_logic;
		SerialLinkTri7 : inout std_logic;
		--//clk select mux
		CLK_select 		:	out	std_logic_vector(1 downto 0) := "00"; --//set defaults
		--//uC
		uC_dig    		:  inout std_logic_vector(11 downto 0);
		--//Digital step-attenuator serial interface
		DSA_LE        	: 	inout	std_logic; --Latch enable
		DSA_SClk      	: 	inout	std_logic; --serial clk
		DSA_SI         : 	inout	std_logic; --serial data
		--//gpio
		DEBUG				:  inout std_logic_vector(11 downto 0);
		LED				:  out 	std_logic_vector(5 downto 0);  
		--//unused VME pins 
		address			:  inout	std_logic_vector(31 downto 2);
		ga					:  inout std_logic_vector(4 downto 0);
		lword				:  inout	std_logic;
		vme_write	   :  inout std_logic;
		am					:  inout	std_logic_vector(5 downto 0);
		as					: 	inout	std_logic;
		iack				:	inout	std_logic;
		ds					: 	inout	std_logic_vector(1 downto 0);
		sysclk			:  inout	std_logic;
		vme_data			:  inout	std_logic_vector(31 downto 0);
		dtack				:  out	std_logic;
		berr				:  out	std_logic;
		dir_trans		: 	out	std_logic;
		tranceivers_OE	:	out	std_logic);
end top_level;

architecture rtl of top_level is
	--///////////////////////////////////////
	--//system resets/startup
	signal reset_global			:	std_logic;	--//system-wide reset signal
	signal reset_global_except_registers : std_logic;  --//system-wide reset signal EXCEPT register values
	signal startup_adc			: 	std_logic;  --//startup adc circuit after reset
	signal startup_pll			: 	std_logic;  --//startup pll circuit after reset
	signal startup_dsa			: 	std_logic;  --//startup dsa circuit after reset
	signal reset_adc				:	std_logic;  --//signal to reset just the ADC firmware blocks
	--//the following signals to/from Clock_Manager--
	signal clock_250MHz			:	std_logic;		
	signal clock_93MHz			:	std_logic;		
	signal clock_25MHz			:	std_logic;  
	signal clock_1MHz				:	std_logic;		
	signal clock_1Hz				:	std_logic;		
	signal clock_10Hz				:	std_logic;		
	signal clock_1kHz				:	std_logic;
	signal clock_100kHz			:	std_logic;
	signal clock_rfrsh_pulse_1Hz		:	std_logic;
	signal clock_rfrsh_pulse_100mHz	:	std_logic;
	signal clock_FPGA_PLLlock	:	std_logic;
	signal clock_FPGA_PLLrst	:	std_logic;
	--//signals for usb, specifically
--	signal usb_start_write			:	std_logic;
-- signal usb_done_write			:	std_logic;
--	signal usb_write_busy			:	std_logic;
--	signal usb_slwr					:  std_logic;
--	signal usb_read_busy				:	std_logic;
--	signal usb_read_packet_32bit	:	std_logic_vector(31 downto 0);
--	signal usb_read_packet_rdy		:	std_logic;
	--//mcu spi interface
	signal mcu_data_pkt_32bit	:	std_logic_vector(31 downto 0);
	signal mcu_tx_flag			: 	std_logic;
	signal mcu_tx_rdy				:	std_logic;
	signal mcu_spi_tx_ack		:	std_logic;
	signal mcu_rx_rdy				:	std_logic;
	signal mcu_rx_req				:	std_logic;
	signal mcu_spi_busy			:	std_logic;
	--//signals from ADC chips
	signal adc_data_valid		:	std_logic;
	signal adc_data_good			:  std_logic;
	signal adc_cal_sig			:	std_logic;
	signal adc_data_clock		:	std_logic_vector(3 downto 0);
	signal adc_data				:	adc_output_data_type;
	signal adc_pd_sig				:	std_logic_vector(3 downto 0);
	signal adc_rx_lvds_locked	:	std_logic_vector(3 downto 0);
	--//fpga RAM data
	signal powsum_ram_data		:  array_of_beams_type; --sum_power_type;
	signal beam_ram_data			:  array_of_beams_type;
	--signal ram_data				:	full_data_type;
	signal ram_data				:	ram_adr_chunked_data_type;
	signal ram_read_address		:  std_logic_vector(define_data_ram_depth-1 downto 0);
	--//signal to/from rx RAM
	signal rx_ram_data			:	full_data_type;
	signal rx_ram_read_address	:	std_logic_vector(define_ram_depth-1 downto 0);
	signal rx_fifo_usedwords	:  full_address_type;
	signal rx_ram_wr_address	:  half_address_type;
	signal rx_ram_rd_en			:	std_logic;
	signal rx_pll_reset			:	std_logic;
	--//pll control signals
	signal lmk_start_write		:	std_logic := '0';
	signal lmk_done_write		:	std_logic;
	--//data readout signals
	--signal rdout_pckt_size		:	std_logic_vector(15 downto 0);
	signal rdout_data				:	std_logic_vector(31 downto 0);
	signal rdout_start_flag		:	std_logic;
	signal rdout_ram_rd_en		:	std_logic_vector(7 downto 0);
	signal rdout_beam_rd_en		:	std_logic_vector(define_num_beams-1 downto 0);
	signal rdout_powsum_rd_en	:	std_logic_vector(define_num_beams-1 downto 0);
	signal rdout_clock			:	std_logic;
	--//register stuff
	signal register_to_read		:	std_logic_vector(define_register_size-1 downto 0);
	signal registers				:	register_array_type;
	signal register_adr			:	std_logic_vector(define_address_size-1 downto 0);
	--//unused vme pins (used to simply set to Hi-Z):
	signal vme_unused_pins		: 	std_logic_vector(79 downto 0);
	--//other unused pins to tri-state
	signal unused_pins			:  std_logic_vector(45 downto 0);
	--//data
	signal wfm_data				: full_data_type; --//registered on core clk
	signal beam_data_8			: array_of_beams_type; --//registered on core clk
	signal beam_data_4a			: array_of_beams_type; --//registered on core clk
	signal beam_data_4b			: array_of_beams_type; --//registered on core clk
	--//signal for power sums
	signal powsum_ev2samples	: sum_power_type;
	--//trigger signals
	signal the_phased_trigger		: std_logic;
	signal the_phased_trigger_from_master : std_logic := '0';
	signal external_trigger			: std_logic;
	signal last_trig_beams			: std_logic_vector(define_num_beams-1 downto 0);
	signal last_trig_power			: average_power_16samp_type;
	--//module status registers
	signal status_reg_data_manager : std_logic_vector(23 downto 0);
	signal status_reg_latched_data_manager :  std_logic_vector(23 downto 0);
	signal status_reg_adc	: std_logic_vector(23 downto 0);
	--//self-generated cal pulse signals
	signal cal_pulse_rf_switch_ctl : std_logic;
	signal cal_pulse_the_pulse	: std_logic;
	--//signals driven from the data manager module
	signal data_manager_write_busy : std_logic;
	signal event_meta_data	: event_metadata_type;
	--//signals for scalers
	signal scalers_beam_trigs	: std_logic_vector(define_num_beams-1 downto 0);
	signal scalers_beam_verified_trigs	: std_logic_vector(define_num_beams-1 downto 0);
	signal scalers_trig			: std_logic;
	signal scaler_to_read		: std_logic_vector(23 downto 0);
	signal scalers_gate			: std_logic;
	signal running_scalers		: std_logic_vector(23 downto 0);
	--//sync signals 
	signal board_sync : std_logic; --//for debugging
	signal sync_from_master_device : std_logic;
	signal sync_to_slave_device : std_logic;
	--//stuff for LEDs
	signal led_trig : std_logic;
	signal led_sync : std_logic;
	signal led_gate : std_logic;
	--//fpga temp
	signal fpga_temp : std_logic_vector(7 downto 0);
begin
	--//pin to signal assignments
	adc_data_clock(0)	<= ADC_Clk_0;
	adc_data_clock(1)	<= ADC_Clk_1;
	adc_data_clock(2)	<= ADC_Clk_2;
	adc_data_clock(3)	<= ADC_Clk_3;
	adc_data(0)			<= ADC_Dat_0;
	adc_data(1)			<= ADC_Dat_1;
	adc_data(2)			<= ADC_Dat_2;
	adc_data(3)			<= ADC_Dat_3;	
	
	--///////////////////////////////////////
	--//master 100 MHz clock input
	--///////////////////////////////////////
	--// hardcode default constant clock mux selection:
	--CLK_select(0) <= '0'; --// board block selection: 1= use local oscillator, 0= external LVDS input
	CLK_select(1) <= '0'; --// PLL clock selection: 0= in one PLL mode, probably want to use ref clock 
	                      --// (UPDATE: do not set this to '1', as PLL VCXO disabled to save power)
	--///////////////////////////////////////
	--//allow clock selection to be programmable:
	proc_set_clock_ref : process(reset_global, reset_global_except_registers, registers)
	begin
		if reset_global = '1' or reset_global_except_registers = '1' then
			CLK_select(0) <= registers(120)(0);   --//board clock
			--CLK_select(1) <= registers(120)(1);   --//PLL clock source
		end if;
	end process;
	--///////////////////////////////////////
	--//system-wide clocks
	xCLOCKS : entity work.Clock_Manager
	port map(
		Reset_i			=> reset_global or reset_global_except_registers,
		CLK0_i			=> MClk_0,
		CLK1_i			=> MClk_1,
		PLL_reset_i		=>	'0',--clock_FPGA_PLLrst,		
		CLK_250MHz_o 	=> clock_250MHz,
		CLK_93MHz_o		=> clock_93MHz,
		CLK_25MHz_o 	=> clock_25MHz,
		CLK_1MHz_o		=> clock_1MHz,		
		CLK_1Hz_o		=> clock_1Hz,
		CLK_10Hz_o		=> clock_10Hz,
		CLK_1kHz_o		=> clock_1kHz,	
		CLK_100kHz_o	=> clock_100kHz,
		refresh_1Hz_o		=> clock_rfrsh_pulse_1Hz,
		refresh_100mHz_o  => clock_rfrsh_pulse_100mHz, --//scaler refresh clock
		fpga_pllLock_o => clock_FPGA_PLLlock);

	--//status register for ADC and PLL chip stuff:
	proc_stat_reg_adc : status_reg_adc <= LMK_Stat_Hldov & LMK_Stat_LD & LMK_Stat_Clk0 & LMK_Stat_Clk1 & 
								clock_FPGA_PLLlock & "00" & startup_adc & x"0" & adc_pd_sig & "000" & adc_data_good &
								adc_rx_lvds_locked(3) & adc_rx_lvds_locked(2) & adc_rx_lvds_locked(1) & adc_rx_lvds_locked(0); 

		--///////////////////////////////////////
	--//adc configuration and data-handling block
	xADC_CONTROLLER : entity work.adc_controller
	port map(
		clk_i					=> clock_25MHz,
		clk_core_i			=> clock_93MHz,
		clk_iface_i			=> clock_25MHz,
		clk_fast_i			=> clock_93MHz, --clock_250MHz,
		rst_i					=> reset_global or reset_adc,
		pwr_up_i 			=> startup_adc,
		rx_locked_i			=> (adc_rx_lvds_locked(0) and 
									 adc_rx_lvds_locked(1) and 
									 adc_rx_lvds_locked(2) and 
									 adc_rx_lvds_locked(3)),
		pd_o 					=> adc_pd_sig,
		sclk_outv_o 		=> ADC_SClk,
		sdat_oedge_ddr_o	=> ADC_SData,
		caldly_scs_o		=> ADC_DES_SCSb,
		drst_sel_o			=> ADC_DRST_SEL,	
		pd_q_o				=> ADC_PDq,
		ece_o					=> ADC_ECEb,
		cal_o					=> adc_cal_sig,
		dclk_rst_lvds_o	=> ADC_DCLK_RST,
		reg_addr_i			=> register_adr,
		reg_i					=> registers,
		rx_adc_data_i		=> rx_ram_data,
		rx_ram_rd_en_o 	=> rx_ram_rd_en,
		rx_fifo_usedwrd_i => rx_fifo_usedwords,
		timestream_data_o	=> wfm_data,
		data_good_o			=> adc_data_good,
		rx_pll_reset_o		=> rx_pll_reset,
		dat_valid_o			=> adc_data_valid);
	--///////////////////////////////////////	
	xBEAMFORMER : entity work.beamform
	generic map( ENABLE_BEAMFORMING => FIRMWARE_DEVICE)
	port map(
		rst_i			=> reset_global or reset_global_except_registers,
		clk_i			=>	clock_93MHz,
		clk_iface_i	=> clock_25MHz,
		reg_i			=> registers,
		data_i		=>	wfm_data,
		beams_4a_o	=> beam_data_4a,
		beams_4b_o	=> beam_data_4b,
		beams_8_o	=> beam_data_8,
		sum_pow_o	=> powsum_ev2samples);
	--///////////////////////////////////////
	xPHASEDTRIGGER : entity work.trigger_v2
	generic map( ENABLE_PHASED_TRIGGER => FIRMWARE_DEVICE)
	port map(
		rst_i					=> reset_global or reset_global_except_registers,
		clk_data_i			=> clock_93MHz,
		clk_iface_i			=> clock_25MHz,
		reg_i					=> registers,
		powersums_i			=> powsum_ev2samples,
		data_write_busy_i => data_manager_write_busy,
		last_trig_pow_o	=> last_trig_power,
		trig_beam_o			=> scalers_beam_trigs, 	--//trigger on sloower MHz clock in each beam (for scalers, beam-tagging)
		trig_clk_data_o	=> the_phased_trigger,	--//OR of all beam triggers on 93 MHz data clock, maskable. Triggers event saving in data_manager module
		last_trig_beam_clk_data_o => last_trig_beams,
		trig_clk_iface_o	=> scalers_trig);       --//trig_clk_data_o synced to slower clock
	--///////////////////////////////////////	
	xEXT_TRIG_MANAGER : entity work.external_trigger_manager
	generic map( FIRMWARE_DEVICE => FIRMWARE_DEVICE)
	port map(
		rst_i			=> reset_global or reset_global_except_registers,
		clk_i			=> clock_25MHz, --//clock
		ext_i			=> SYS_serial_in, --//external gate/trigger input, distributed by clock fanout board over RJ45
		sys_trig_i	=> scalers_trig, --//firmware generated phased trigger
		reg_i			=> registers, --//programmable registers
		sys_trig_o  => external_trigger, --//trigger to firmware
		sys_gate_o	=> scalers_gate, --//scaler gate
		ext_trig_o	=> uC_dig(9)); --//external trigger output
	--///////////////////////////////////////	
   xCALPULSE : entity work.electronics_calpulse 
	generic map( ENABLE_CALIBRATION_PULSE => FIRMWARE_DEVICE)
	port map(
		rst_i			=> reset_global or reset_global_except_registers,
		clk_i			=> clock_250MHz,
		reg_i			=> registers,
		pulse_o		=> cal_pulse_the_pulse,  
		rf_switch_o => cal_pulse_rf_switch_ctl); 
	--///////////////////////////////////////	
	--//pll configuration block	
	xPLL_CONTROLLER : entity work.pll_controller
	port map(
		rst_i			=> reset_global or reset_global_except_registers,
		clk_i			=> clock_1MHz,
		reg_i			=> (others=>'0'),
		write_i		=> lmk_start_write or startup_pll,
		done_o		=> lmk_done_write,
		lmk_sdata_o	=> LMK_DAT_uWire,
		lmk_sclk_o	=> LMK_CLK_uWire,
		lmk_le_o		=> LMK_LEu_uWire,
		pll_sync_o	=> LMK_SYNC);
	--///////////////////////////////////////
	--//attenuator configuration block	
	xDSA_CONTROLLER : entity work.atten_controller
	port map(
		rst_i			=> reset_global or reset_global_except_registers,
		clk_i			=> clock_1MHz,
		reg_i			=> registers,
		addr_i		=> register_adr,
		write_i		=> startup_dsa,
		done_o		=> open,
		dsa_sdata_o	=> DSA_SI,
		dsa_sclk_o	=> DSA_SClk,
		dsa_le_o		=> DSA_LE);
	--///////////////////////////////////////	
	--//system resets and power-on cycle
	xGLOBAL_RESET : entity work.sys_reset
	port map( 
		clk_i				=> clock_25MHz,
		clk_rdy_i		=> clock_FPGA_PLLlock,
		reg_i				=> registers,
		reset_sys_o		=> reset_global_except_registers,
		reset_o			=> reset_global,
		pll_strtup_o	=> startup_pll,
		dsa_strtup_o	=> startup_dsa,
		adc_strtup_o	=> startup_adc,
		adc_reset_o		=> reset_adc);
	--///////////////////////////////////////	
	--//ADC data receiver block
	ReceiverBlock	:	 for i in 0 to 3 generate
		xDATA_RECEIVER : entity work.RxData
		port map(
			rst_i					=>	reset_global_except_registers or reset_global or (not startup_adc) or rx_pll_reset or adc_pd_sig(i),		
			rx_dat_valid_i		=>	adc_data_valid,
			adc_dclk_i			=>	adc_data_clock(i),	
			adc_data_i			=> adc_data(i),
			adc_ovrange_i	 	=> ADC_OvRange(i),
			rx_fifo_read_clk_i		=> clock_93MHz,   
			rx_fifo_read_req_i		=> rx_ram_rd_en,
			rx_fifo_used_words0_o	=> rx_fifo_usedwords(2*i),
			rx_fifo_used_words1_o   => rx_fifo_usedwords(2*i+1),
			ram_wr_adr_rst_i	=> '0', 
			rx_ram_write_adr_o=> rx_ram_wr_address(i),
			rx_locked_o		   => adc_rx_lvds_locked(i),
			data_ram_ch0_o		=> rx_ram_data(2*i), 
			data_ram_ch1_o		=> rx_ram_data(2*i+1));
	end generate ReceiverBlock;
	
--//////////////////////////////////////////////////////////////////////////
--//use this block if running ADC at slow rate (i.e. debugging) and using ADC DClk directly 
--// (no deserialization of data)
--//////////////////////////////////////////////////////////////////////////
--	xOTHER_DATA_RECEIVER : entity work.RxData_NoDeSer(rtl)
--	port map(
--			clk_i					=> '0',
--			rst_i					=>	reset_global or not startup_adc,		
--			rx_dat_valid_i		=>	adc_data_valid,
--			trigger_i			=>	registers(base_adrs_rdout_cntrl+0)(0), --//software trigger
--			trigger_dly_i		=> (others=>'0'),
--			adc_dclk_i			=>	adc_data_clock(3),	
--			adc_data_i			=> adc_data(3),
--			adc_ovrange_i	 	=> ADC_OvRange(3),
--			ram_read_Clk_i		=> usb_slwr,    --//USB readout clock, for now
--			ram_read_Adrs_i	=> ram_read_address, 
--			ram_read_en_ch0_i	=> rdout_ram_rd_en(6),
--			ram_read_en_ch1_i => rdout_ram_rd_en(7),
--			ram_wr_adr_rst_i	=> usb_done_write, --/restart ram write address
--			rx_serdes_clk_o	=> open, --adc_rx_serdes_clk(3),
--			rx_locked_o		   => adc_rx_lvds_locked(3),
--			ram_write_adrs_o	=> ram_write_address(3),
--			data_ram_ch0_o		=> ram_data(6), 
--			data_ram_ch1_o		=> ram_data(7));
	--///////////////////////////////////////
	xDATA_MANAGER : entity work.data_manager
	generic map( FIRMWARE_DEVICE => FIRMWARE_DEVICE)
	port map(
		rst_i						=> reset_global or reset_global_except_registers,
		clk_i						=> clock_93MHz,
		clk_iface_i				=> clock_25MHz,
		pulse_refrsh_i			=> clock_rfrsh_pulse_1Hz,
		wr_busy_o				=> data_manager_write_busy,
		phased_trig_i			=> (the_phased_trigger and FIRMWARE_DEVICE) or the_phased_trigger_from_master,
		last_trig_beam_i		=> last_trig_beams,
		last_trig_pow_i		=> last_trig_power,
		ext_trig_i				=> external_trigger,
		reg_i						=> registers,
		reg_adr_i				=> register_adr,
		event_meta_o			=> event_meta_data,
		status_reg_o			=> status_reg_data_manager,
		status_reg_latched_o => status_reg_latched_data_manager,
		wfm_data_i				=> wfm_data,
		running_scalers_i		=> running_scalers,
		data_ram_at_current_adr_o => ram_data);
		
	--//readout controller using MCU/BeagleBone
	xREADOUT_CONTROLLER : entity work.rdout_controller_mcu
	port map(
		rst_i						=> reset_global or reset_global_except_registers,
		clk_i						=> clock_25MHz,
		rdout_reg_i				=> register_to_read,  --//read register
		reg_adr_i				=> register_adr,
		registers_i				=> registers,         
		tx_rdy_o					=> mcu_tx_flag, 
		--tx_rdy_spi_i			=> mcu_tx_rdy,
		tx_ack_i					=> mcu_spi_tx_ack,
		tx_rdy_spi_i			=> '0', --newer spi_slave code
		rdout_fpga_data_o		=> rdout_data);
		
	--///////////////////////////////////////	
	xSCALERS : entity work.scalers_top
	port map(
		rst_i				=>	reset_global or reset_global_except_registers,	
		clk_i				=> clock_25MHz,
		pulse_refrsh_i	=> clock_rfrsh_pulse_100mHz,
		pulse_refrshHz_i=> clock_rfrsh_pulse_1Hz,
		gate_i			=> scalers_gate,
		reg_i				=> registers,
		trigger_i		=> scalers_trig,
		beam_trig_i		=> scalers_beam_trigs,
		running_scalers_o => running_scalers,
		scaler_to_read_o  => scaler_to_read);
	--///////////////////////////////////////		
	xREGISTERS : entity work.registers_mcu_spi
	generic map( FIRMWARE_DEVICE => FIRMWARE_DEVICE)
	port map(
		rst_i				=> reset_global,
		clk_i				=> clock_25MHz,  --//clock for register interface
		sync_slave_i	=> sync_to_slave_device,
		sync_from_master_o	=> sync_from_master_device,
		--//////////////////////////
		--//status registers
		fpga_temp_i	=> fpga_temp,
		scaler_to_read_i => scaler_to_read,
		status_data_manager_i => status_reg_data_manager,
		status_data_manager_latched_i => status_reg_latched_data_manager,
		status_adc_i	  => status_reg_adc,
		event_metadata_i => event_meta_data,
		current_ram_adr_data_i => ram_data,
		--//////////////////////////
		write_reg_i		=> mcu_data_pkt_32bit,
		write_rdy_i		=> mcu_rx_rdy,
		read_reg_o 		=> register_to_read,
		registers_io	=> registers, --//system register space
		sync_active_o	=> board_sync,
		address_o		=> register_adr);
	--///////////////////////////////////////	
	----------------------------------------------------------------
	--General purpose interface using uC_dig bi-directional pins. Four assigned to dedicated SPI coms:
	xPCINTERFACE : entity work.mcu_interface
	port map(
		clk_i			 => clock_25MHz,
		rst_i			 => reset_global or reset_global_except_registers,	
		spi_cs_i	 	 => uC_dig(7),	
		spi_sclk_i	 => uC_dig(4),	
		spi_mosi_i	 => uC_dig(2),	
		spi_miso_o	 => uC_dig(0),
		data_i		 => rdout_data,
		tx_load_i	 => mcu_tx_flag,
		data_o   	 => mcu_data_pkt_32bit,
		--rx_req_i		 => mcu_rx_req,
		--spi_busy_o	 => mcu_spi_busy,
		tx_ack_o		 => mcu_spi_tx_ack,
		rx_rdy_o		 => mcu_rx_rdy);
		--tx_rdy_o		 => mcu_tx_rdy);
		
	--uC_dig(1) <= 'X';  --//GPIO to BBB, may be driven by BBB or firmware
	--uC_dig(3) <= 'X';  --//GPIO to BBB, may be driven by BBB or firmware
	--uC_dig(5) <= '0'; --//not connected
	--uC_dig(6) <= '0'; --//not connected
	--uC_dig(8) <= '0'; --//not connected
	--uC_dig(9) <= clock_rfrsh_pulse_1Hz;  --//external trigger (boosted on SPI_linker board)
	--uC_dig(10) <= '0'; --//not connected
	--uC_dig(11) <= '0'; --//not connected
   -----------------------------------------------------------------------------
	--FPGA core temp
	xFPGACORETEMP : entity work.fpga_core_temp
	port map(
		enable_i		=> registers(108)(1),
		clk_i			=> clock_1MHz,
		clk_reg_i	=> clock_25MHz,
		rst_i 		=> reset_global or reset_global_except_registers,	
		update_i		=> registers(108)(0),
		temp_o 		=> fpga_temp); 
	
	--//Other output pin assignments
	-----------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	--MASTER BOARD:
	-- --SMA_out0 => the DDR cal pulse
	-- --SMA_out1 => the phased trigger to the slave board
	-- --SMA_in => the sync signal to the slave board
	--SLAVE BOARD:
	-- --SMA_out0 => the cal pulse enable
	-- --SMA_out1 => the phased trigger from the master board
	-- --SMA_in => the sync signal from the master board
	proc_assign_sma_pins : process(cal_pulse_rf_switch_ctl, cal_pulse_the_pulse, the_phased_trigger, SMA_in, SMA_out1, sync_from_master_device)
	begin
	case FIRMWARE_DEVICE is
		when '1' => --//master board
			SMA_out0 <= cal_pulse_the_pulse;  
			SMA_out1 <= the_phased_trigger;
			SMA_in	<= sync_from_master_device;
			the_phased_trigger_from_master <= '0';
			sync_to_slave_device <= '0';
		when '0' => --//slave board
			SMA_out0 <= cal_pulse_rf_switch_ctl;
			the_phased_trigger_from_master <= SMA_out1;
			sync_to_slave_device <= SMA_in;
	end case;
	end process;
	
	--//unused RJ45 serial links:
	LOC_serial_out1  	<= '0'; 
	LOC_serial_out0	<= '0'; 
	SYS_serial_out 	<= '0';
	--------------------------------------------------------------
	--//unused pins:
	USB_FD 	<=  unused_pins(15 downto 0);
	USB_PA 	<=  unused_pins(23 downto 16);
	USB_CTL 	<=  unused_pins(26 downto 24);
	USB_RDY  <=  unused_pins(28 downto 27);
	USB_WAKEUP <= unused_pins(29);
	USB_IFCLK  <= unused_pins(30);
	uC_dig(5) <= unused_pins(31);
	uC_dig(6) <= unused_pins(32);
	uC_dig(8) <= unused_pins(33);
	uC_dig(10) <= unused_pins(34);
	uC_dig(11) <= unused_pins(35);
	SerialLinkTri0 <= unused_pins(36);
	SerialLinkTri1 <= unused_pins(37);
	SerialLinkTri2 <= unused_pins(38);
	SerialLinkTri3 <= unused_pins(39);
	SerialLinkTri4 <= unused_pins(40);
	SerialLinkTri5 <= unused_pins(41);
	SerialLinkTri6 <= unused_pins(42);
	SerialLinkTri7 <= unused_pins(43);
	uC_dig(1) <= unused_pins(44); --//note: this pin may be used at some point; it is wired to the breakout board MiniFit Jr connector
	uC_dig(3) <= unused_pins(45); --//note: this pin may be used at some point; it is wired to the breakout board MiniFit Jr connector
	xUNUSED_TRISTATE : entity work.unused_pin_driver(RTL)
	port map(
		oe			=> (others=>'0'), 
		datain	=> (others=>'0'),
		dataout 	=> unused_pins);
	--------------------------------------------------------------
	
	--//ADC
	ADC_Cal 		<= adc_cal_sig; --//adc calibration init pulse
	ADC_PD		<= adc_pd_sig;	 --//adc power-down
	
	--//for debugging ADC/core clock syncing
	process(clock_93MHz, reset_global)
	begin
		if reset_global = '1' then
			rx_ram_read_address <= (others=>'0');
		elsif rising_edge(clock_93MHz) then
			rx_ram_read_address <= rx_ram_read_address + 1;
		end if;
	end process;
	--///////////////////////////////////////////////////////////////
	--//debug headers & LEDs
	--///////////////////////////////////////////////////////////////
	--DEBUG(0) <=  '0'; --LMK_DAT_uWire;
	DEBUG(1) <=  rx_ram_wr_address(0)(0); --clock_rfrsh_pulse_1Hz;--ram_write_address(1)(0); -- LMK_CLK_uWire;
	DEBUG(2) <=  rx_ram_wr_address(0)(1); --clock_15MHz;--ram_write_address(2)(0); --LMK_LEu_uWire;
	DEBUG(3) <=  rx_ram_wr_address(2)(0);--ram_write_address(3)(0); --lmk_start_write;
	DEBUG(4) <=  rx_ram_wr_address(3)(0);--adc_rx_serdes_clk(0); --adc_data_clock(0); --lmk_done_write;
	DEBUG(5) <=  clock_10Hz;--adc_rx_serdes_clk(1);--adc_data_clock(1);--USB_CTL(2);
	DEBUG(6) <=  rx_ram_read_address(0); --adc_rx_serdes_clk(2);--adc_data_clock(2);--ram_write_address(3)(3);
	DEBUG(7) <=  rx_ram_read_address(1);--adc_rx_serdes_clk(3);--adc_data_clock(3);--ram_read_address(3);
	DEBUG(8) <=  '0';
	DEBUG(9) <=  '0'; --DSA_LE;--usb_read_packet_rdy;
	DEBUG(10)<=  clock_25MHz;--adc_pd_sig(1); --rdout_start_flag;--registers(127)(0); --
	DEBUG(11)<=  mcu_spi_busy;--adc_cal_sig; --usb_slwr;
	--/////////////////////////////////
	
	-------------------------------------------------------------
	--//LEDs active low
	xLED_TRIG_PULSE : entity work.pulse_stretcher_sync(rtl)
	generic map(stretch => 50000)
	port map(
		rst_i		=> reset_global or reset_global_except_registers,
		clk_i		=> clock_25MHz,
		pulse_i	=> scalers_trig,
		pulse_o	=> led_trig);
	xLED_SYNC_PULSE : entity work.pulse_stretcher_sync(rtl)
	generic map(stretch => 50000)
	port map(
		rst_i		=> reset_global or reset_global_except_registers,
		clk_i		=> clock_25MHz,
		pulse_i	=> board_sync,
		pulse_o	=> led_sync);
	xLED_GATE_PULSE : entity work.pulse_stretcher_sync(rtl)
	generic map(stretch => 100000)
	port map(
		rst_i		=> reset_global or reset_global_except_registers,
		clk_i		=> clock_25MHz,
		pulse_i	=> scalers_gate,
		pulse_o	=> led_gate);
		
	LED(0) <= not led_gate;
	LED(1) <= not (reset_global or reset_global_except_registers);
	LED(2) <= not (reset_global or reset_global_except_registers or led_trig);
	
	LED(3) <= not led_sync;
	process(clock_10Hz)
	begin
	case FIRMWARE_DEVICE is
		when '1' =>
			LED(4) <= not clock_10Hz;
		when '0' =>
			LED(4) <= clock_10Hz;
	end case;
	end process;
	--//assign LED(5) to the rx locked signals or the ADC PD, if programmed as such
	LED(5) <= not ((adc_rx_lvds_locked(0) or registers(base_adrs_adc_cntrl+6)(0)) and 
						(adc_rx_lvds_locked(1) or registers(base_adrs_adc_cntrl+6)(1)) and 
						(adc_rx_lvds_locked(2) or registers(base_adrs_adc_cntrl+6)(2)) and 
						(adc_rx_lvds_locked(3) or registers(base_adrs_adc_cntrl+6)(3)) and clock_10Hz);
	-------------------------------------------------------------
	--/////////////////////////////////////////////////////////////////////////////
	--//define unused VME interface pins
	dtack			 	<= '0';
	berr				<= '0';
	dir_trans		<= '0';
	tranceivers_OE	<= '0';
	xVME_UNUSED_TRISTATE : entity work.vme_unused_pin_driver(RTL)
	port map(
		oe			=> (others=>'0'), 
		datain	=> (others=>'0'),
		dataout 	=> vme_unused_pins);
		
	address 		<= vme_unused_pins(29 downto 0);
	ga	  			<= vme_unused_pins(34 downto 30);
	lword  		<= vme_unused_pins(35);
	vme_write	<= vme_unused_pins(36);
	am				<= vme_unused_pins(42 downto 37);
	as				<= vme_unused_pins(43);
	iack			<= vme_unused_pins(44);
	ds				<= vme_unused_pins(46 downto 45);
	sysclk		<= vme_unused_pins(47);
	vme_data		<= vme_unused_pins(79 downto 48);
   --/////////////////////////////////////////////////////////////////////////////

end rtl;	