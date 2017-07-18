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
		USB_IFCLK		: 	in		std_logic;
		USB_WAKEUP		:	in 	std_logic;
		USB_CTL     	:	in		std_logic_vector(2 downto 0);
		USB_PA			: 	inout std_logic_vector(7 downto 0);	
		USB_FD			:	inout	std_logic_vector(15 downto 0);
		USB_RDY			:	out	std_logic_vector(1 downto 0);
		--//Trigger SMA's
		SMA_in			: 	inout	std_logic;
		SMA_out0			: 	out	std_logic;
		SMA_out1			: 	out	std_logic;
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
		LOC_serial_in2 :  in		std_logic;
		LOC_serial_in3 :  in		std_logic;
		LOC_serial_out0:  out	std_logic;
		LOC_serial_out1:  out	std_logic;
		LOC_serial_out2:  out	std_logic;
		LOC_serial_out3:  out	std_logic;
		--//clk select mux
		CLK_select 		:	out	std_logic_vector(1 downto 0);
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
	signal clock_15MHz			:	std_logic;  
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
	signal adc_cal_sig			:	std_logic;
	signal adc_data_clock		:	std_logic_vector(3 downto 0);
	signal adc_data				:	adc_output_data_type;
	signal adc_pd_sig				:	std_logic_vector(3 downto 0);
	signal adc_rx_lvds_locked	:	std_logic_vector(3 downto 0);
	--//fpga RAM data
	signal powsum_ram_data		:  array_of_beams_type; --sum_power_type;
	signal beam_ram_data			:  array_of_beams_type;
	signal ram_data				:	full_data_type;
	signal ram_read_address		:  std_logic_vector(define_data_ram_depth-1 downto 0);
	--//signal to/from rx RAM
	signal rx_ram_data			:	full_data_type;
	signal rx_ram_read_address	:	std_logic_vector(define_ram_depth-1 downto 0);
	signal rx_ram_rd_en			:	std_logic;
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
	--//serial links:
	signal xAUX_0_tx_pin			: 	std_logic_vector(1 downto 0);
	signal xAUX_1_tx_pin			: 	std_logic_vector(1 downto 0);
	signal system_link_tx_data	:	std_logic_vector(7 downto 0);
	signal aux0_link_tx_data	:	aux_data_link_type;
	signal aux1_link_tx_data	:	aux_data_link_type;
	--//unused vme pins (used to simply set to Hi-Z):
	signal vme_unused_pins		: 	std_logic_vector(79 downto 0);
	--//data
	signal wfm_data				: full_data_type; --//registered on core clk
	signal beam_data_8			: array_of_beams_type; --//registered on core clk
	signal beam_data_4a			: array_of_beams_type; --//registered on core clk
	signal beam_data_4b			: array_of_beams_type; --//registered on core clk
	--//signal for power sums
	signal powsum_ev2samples	: sum_power_type;
	--//trigger signals
	signal the_phased_trigger		: std_logic;
	signal last_trig_beams			: std_logic_vector(define_num_beams-1 downto 0);
	signal last_trig_power			: average_power_16samp_type;
	--//module status registers
	signal status_reg_data_manager : std_logic_vector(23 downto 0);
	
	--//signals driven from the data manager module
	signal data_manager_write_busy : std_logic;
	signal event_meta_data	: event_metadata_type;
	--//signals for scalers
	signal scalers_beam_trigs	: std_logic_vector(define_num_beams-1 downto 0);
	signal scalers_trig			: std_logic;
	signal scaler_to_read		: std_logic_vector(23 downto 0);
	
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
	--CLK_select(0) <= '1'; --// board block selection: 1= use local oscillator
	--CLK_select(1) <= '0'; --// PLL clock selection: 0= one PLL mode, use ref clock 
	--///////////////////////////////////////
	--//allow clock selection to be programmable:
	proc_set_clock_ref : process(reset_global)
	begin
		if reset_global = '1' or reset_global_except_registers = '1' then
			CLK_select(0) <= registers(120)(0);   --//board clock
			CLK_select(1) <= not registers(120)(0);  --//input clock
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
		CLK_15MHz_o 	=> clock_15MHz,
		CLK_1MHz_o		=> clock_1MHz,		
		CLK_1Hz_o		=> clock_1Hz,
		CLK_10Hz_o		=> clock_10Hz,
		CLK_1kHz_o		=> clock_1kHz,	
		CLK_100kHz_o	=> clock_100kHz,
		refresh_1Hz_o		=> clock_rfrsh_pulse_1Hz,
		refresh_100mHz_o  => clock_rfrsh_pulse_100mHz, --//scaler refresh clock
		fpga_pllLock_o => clock_FPGA_PLLlock);
	--///////////////////////////////////////
	--//adc configuration and data-handling block
	xADC_CONTROLLER : entity work.adc_controller
	port map(
		clk_i					=> clock_1MHz,
		clk_core_i			=> clock_93MHz,
		clk_iface_i			=> clock_15MHz,
		clk_fast_i			=> clock_250MHz,
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
		rx_ram_rd_adr_o 	=> rx_ram_read_address,
		rx_ram_rd_en_o 	=> rx_ram_rd_en,
		timestream_data_o	=> wfm_data,
		dat_valid_o			=> adc_data_valid);
	--///////////////////////////////////////	
	xBEAMFORMER : entity work.beamform
	port map(
		rst_i			=> reset_global or reset_global_except_registers,
		clk_i			=>	clock_93MHz,		
		reg_i			=> registers,
		data_i		=>	wfm_data,
		beams_4a_o	=> beam_data_4a,
		beams_4b_o	=> beam_data_4b,
		beams_8_o	=> beam_data_8,
		sum_pow_o	=> powsum_ev2samples);
	--///////////////////////////////////////
	xTRIGGER : entity work.trigger
	port map(
		rst_i					=> reset_global or reset_global_except_registers,
		clk_data_i			=> clock_93MHz,
		clk_iface_i			=> clock_15MHz,
		reg_i					=> registers,
		powersums_i			=> powsum_ev2samples,
		data_write_busy_i => data_manager_write_busy,
		last_trig_pow_o	=> last_trig_power,
		trig_beam_o			=> scalers_beam_trigs, 	--//trigger on 7.5 MHz clock in each beam (for scalers, beam-tagging)
		trig_clk_data_o	=> the_phased_trigger,	--//OR of all beam triggers on 93 MHz clock, maskable. Triggers event saving in data_manager module
		last_trig_beam_clk_data_o => last_trig_beams,
		trig_clk_iface_o	=> scalers_trig);       --//trig_clk_data_o synced to 7p5 MHz clock
	--///////////////////////////////////////	
   xCALPULSE : entity work.electronics_calpulse 
	port map(
		rst_i			=> reset_global or reset_global_except_registers,
		clk_i			=> clock_250MHz,
		reg_i			=> registers,
		pulse_o		=> SMA_out1, --//pulse out in 'TRIG_OUT_AUX' SMA connector
		rf_switch_o => SMA_in);                      --DEBUG(0)); --//RF switch select wired to GPIO Pin
	--///////////////////////////////////////	
	--//pll configuration block	
	xPLL_CONTROLLER : entity work.pll_controller
	port map(
		rst_i			=> reset_global or reset_global_except_registers,
		clk_i			=> clock_1MHz,
		reg_i			=> (others=>'0'), --//set registers manually
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
		clk_i				=> clock_1MHz,
		clk_rdy_i		=> clock_FPGA_PLLlock,
		user_wakeup_i	=> not USB_WAKEUP, --//set this to 0 eventually when no longer using USB
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
			rst_i					=>	reset_global_except_registers or reset_global or not startup_adc,		
			rx_dat_valid_i		=>	adc_data_valid,
			adc_dclk_i			=>	adc_data_clock(i),	
			adc_data_i			=> adc_data(i),
			adc_ovrange_i	 	=> ADC_OvRange(i),
			ram_read_Clk_i		=> clock_93MHz,   
			ram_read_Adrs_i	=> rx_ram_read_address, 
			ram_read_en_i		=> rx_ram_rd_en,
			ram_wr_adr_rst_i	=> '0', --usb_done_write, --/restart ram write address
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
	port map(
		rst_i						=> reset_global or reset_global_except_registers,
		clk_i						=> clock_93MHz,
		clk_iface_i				=> clock_15MHz,
		pulse_refrsh_i			=> clock_rfrsh_pulse_1Hz,
		wr_busy_o				=> data_manager_write_busy,
		phased_trig_i			=> the_phased_trigger,
		last_trig_beam_i		=> last_trig_beams,
		last_trig_pow_i		=> last_trig_power,
		ext_trig_i				=> '0',
		reg_i						=> registers,
		read_clk_i 				=> rdout_clock,  
		read_ram_adr_i			=> ram_read_address,
		event_meta_o			=> event_meta_data,
		status_reg_o			=> status_reg_data_manager,
		wfm_data_i				=> wfm_data,
		data_ram_read_en_i	=> rdout_ram_rd_en,
		data_ram_o				=> ram_data,
		beam_data_i				=> beam_data_8,
		beam_data_4a_i			=> beam_data_4a,
		beam_data_4b_i 		=> beam_data_4b,
		beam_ram_read_en_i	=> rdout_beam_rd_en,
		beam_ram_o				=> beam_ram_data,
		powsum_data_i			=> powsum_ev2samples, --powsum_ev2samples,
		powsum_ram_read_en_i	=> rdout_powsum_rd_en,
		powsum_ram_o			=> powsum_ram_data);
	--///////////////////////////////////////
	--//readout controller using USB
	--//allows something like dynamic mem access (start + stop readout address)
--	xREADOUT_CONTROLLER : entity work.rdout_controller
--	port map(
--		--rst_i					=> reset_global or usb_done_write or reset_global_except_registers, --//for USB operation
--		rst_i					=> reset_global or reset_global_except_registers,
--		clk_i					=> usb_slwr,
--		clk_interface_i	=> USB_IFCLK,
--		rdout_reg_i			=> register_to_read,  --//read register
--		reg_adr_i			=> register_adr,
--		registers_i			=> registers,         
--		ram_data_i			=> ram_data, 
--		ram_beam_i			=> beam_ram_data, 
--		ram_powsum_i		=> powsum_ram_data, 
--		rdout_start_o		=> rdout_start_flag,
--		rdout_ram_rd_en_o => rdout_ram_rd_en, 
--		rdout_beam_rd_en_o=> rdout_beam_rd_en, 
--		rdout_powsum_rd_en_o => rdout_powsum_rd_en,
--		rdout_pckt_size_o	=> rdout_pckt_size,
--		rdout_adr_o			=> ram_read_address,
--		rdout_fpga_data_o	=> rdout_data_16bit);
--

	--//readout controller using MCU/BeagleBone
	xREADOUT_CONTROLLER : entity work.rdout_controller_mcu
	port map(
		rst_i						=> reset_global or reset_global_except_registers,
		clk_i						=> clock_15MHz,
		rdout_reg_i				=> register_to_read,  --//read register
		reg_adr_i				=> register_adr,
		registers_i				=> registers,         
		ram_data_i				=> ram_data, 
		ram_beam_i				=> beam_ram_data, 
		ram_powsum_i			=> powsum_ram_data, 
		read_clk_o				=> rdout_clock,
		tx_rdy_o					=> mcu_tx_flag, 
		--tx_rdy_spi_i			=> mcu_tx_rdy,
		tx_ack_i					=> mcu_spi_tx_ack,
		tx_rdy_spi_i			=> '0', --newer spi_slave code
		rdout_ram_rd_en_o 	=> rdout_ram_rd_en, 
		rdout_beam_rd_en_o	=> rdout_beam_rd_en, 
		rdout_powsum_rd_en_o => rdout_powsum_rd_en,
		rdout_adr_o				=> ram_read_address,
		rdout_fpga_data_o		=> rdout_data);
	--///////////////////////////////////////	
	xSCALERS : entity work.scalers_top
	port map(
		rst_i				=>	reset_global or reset_global_except_registers,	
		clk_i				=> clock_15MHz,
		pulse_refrsh_i	=> clock_rfrsh_pulse_100mHz,
		gate_i			=> '1',
		reg_i				=> registers,
		trigger_i		=> scalers_trig,
		beam_trig_i		=> scalers_beam_trigs,
		scaler_to_read_o  => scaler_to_read);
	--///////////////////////////////////////		
	xREGISTERS : entity work.registers_mcu_spi
	port map(
		rst_i				=> reset_global,
		clk_i				=> clock_15MHz,  --//clock for register interface
		--//////////////////////////
		--//status registers
		scaler_to_read_i => scaler_to_read,
		status_data_manager_i => status_reg_data_manager,
		event_metadata_i => event_meta_data,
		--//////////////////////////
		write_reg_i		=> mcu_data_pkt_32bit,
		write_rdy_i		=> mcu_rx_rdy,
		write_req_o		=> mcu_rx_req,
		read_reg_o 		=> register_to_read,
		registers_io	=> registers, --//system register space
		address_o		=> register_adr);
	--///////////////////////////////////////	
	xPCINTERFACE : entity work.mcu_interface
	port map(
		clk_i			 => clock_15MHz,
		rst_i			 => reset_global or reset_global_except_registers,	
		mcu_fpga_io	 => uC_dig,
		data_i		 => rdout_data,
		tx_load_i	 => mcu_tx_flag,
		data_o   	 => mcu_data_pkt_32bit,
		--rx_req_i		 => mcu_rx_req,
		--spi_busy_o	 => mcu_spi_busy,
		tx_ack_o		 => mcu_spi_tx_ack,
		rx_rdy_o		 => mcu_rx_rdy);
		--tx_rdy_o		 => mcu_tx_rdy);
	
--	xPCINTERFACE : entity work.mcu_interface
--	port map(
--		rst_i			 => reset_global or reset_global_except_registers,	
--		mcu_fpga_io	 => uC_dig,
--		data_i		 => rdout_data,
--		tx_load_i	 => mcu_tx_flag,
--		data_o   	 => mcu_data_pkt_32bit,
--		rx_req_i		 => mcu_rx_req,
--		spi_busy_o	 => mcu_spi_busy,
--		rx_rdy_o		 => mcu_rx_rdy,
--		tx_rdy_o		 => mcu_tx_rdy);
	--///////////////////////////////////////	
--	xUSB	:	entity work.usb_32bit(Behavioral)
--	port map(
--		USB_IFCLK		=> USB_IFCLK,
--		USB_RESET    	=> '1', --(not USB_WAKEUP) or reset_global,
--		USB_BUS  		=> USB_FD,
--		FPGA_DATA		=> (others=>'0'), --rdout_data_16bit, 
--      USB_FLAGB    	=>	USB_CTL(1),
--      USB_FLAGC    	=> USB_CTL(2),
--		USB_START_WR	=> '0', --rdout_start_flag,--//start write to PC
--		USB_NUM_WORDS	=> rdout_pckt_size, --//num words in write
--      USB_DONE  		=> usb_done_write, --//usb done with write to PC
--      USB_PKTEND     => USB_PA(6),
--      USB_SLWR  		=> usb_slwr, --//USB write clock
--      USB_WBUSY 		=> usb_write_busy, --//USB writing
--      USB_FLAGA    	=> USB_CTL(0),
--      USB_FIFOADR  	=>	USB_PA(5 downto 4),
--      USB_SLOE     	=> USB_PA(2),
--      USB_SLRD     	=> USB_RDY(0),
--      USB_RBUSY 		=>	usb_read_busy, --//FPGA reading from PC
--      USB_INSTRUCTION=> usb_read_packet_32bit, --//FPGA read word
--		USB_INSTRUCT_RDY=>usb_read_packet_rdy);	

--	xSERIAL_LINKS	:	entity work.SerialLinks(Behavioral)
--	port map(
--		CLK					=> clock_75MHz,
--		reset					=> reset_global,
--		System_RX_pin		=> SYS_serial_in,
--		System_TX_pin		=> SYS_serial_out,	
--		System_RX_outclk	=> open,
--		System_RX_data		=> open,
--		System_TX_data		=> system_link_tx_data,
--		Sys_setup			=> '0',
--		Sys_aligned			=> open,
--		Sys_loopback		=> '0',
--		Aux0_RX_pin			=> LOC_serial_in1 &  LOC_serial_in0, 
--		Aux0_TX_pin		   => xAUX_0_tx_pin, 
--		Aux0_RX_outclk		=> open,
--		Aux0_RX_data		=> open,
--		Aux0_TX_data		=> aux0_link_tx_data,
--		Aux0_setup			=> '0',
--		Aux0_aligned		=> open,
--		Aux0_loopback		=> '0',
--		Aux1_RX_pin			=> LOC_serial_in3 &  LOC_serial_in2, 
--		Aux1_TX_pin		   => xAUX_1_tx_pin, 
--		Aux1_RX_outclk		=> open,
--		Aux1_RX_data		=> open,
--		Aux1_TX_data		=> aux1_link_tx_data,
--		Aux1_setup			=> '0',
--		Aux1_aligned		=> open,
--		Aux1_loopback		=> '0');
--	
	--//output pin assignments
	-----------------------------------------------------------------------
	--//serial links:
	LOC_serial_out1  	<= xAUX_0_tx_pin(1); 
	LOC_serial_out0	<= xAUX_0_tx_pin(0);
	LOC_serial_out3  	<= xAUX_1_tx_pin(1); 
	LOC_serial_out2	<= xAUX_1_tx_pin(0);
	
	--//USB
	--USB_RDY(1)	<=	usb_slwr;	--//usb signal-low write
	USB_RDY(1) <= '0';
	
	--//ADC
	ADC_Cal 		<= adc_cal_sig; --//adc calibration init pulse
	ADC_PD		<= adc_pd_sig;	 --//adc power-down
	--///////////////////////////////////////////////////////////////
	--//debug headers & LEDs
	--///////////////////////////////////////////////////////////////
	--DEBUG(0) <=  '0'; --LMK_DAT_uWire;
	DEBUG(1) <=  '0'; --clock_rfrsh_pulse_1Hz;--ram_write_address(1)(0); -- LMK_CLK_uWire;
	DEBUG(2) <=  '0'; --clock_15MHz;--ram_write_address(2)(0); --LMK_LEu_uWire;
	DEBUG(3) <=  '0';--ram_write_address(3)(0); --lmk_start_write;
	DEBUG(4) <=  '0';--adc_rx_serdes_clk(0); --adc_data_clock(0); --lmk_done_write;
	DEBUG(5) <=  clock_10Hz;--adc_rx_serdes_clk(1);--adc_data_clock(1);--USB_CTL(2);
	DEBUG(6) <=  ram_read_address(0);--adc_rx_serdes_clk(2);--adc_data_clock(2);--ram_write_address(3)(3);
	DEBUG(7) <=  '0';--adc_rx_serdes_clk(3);--adc_data_clock(3);--ram_read_address(3);
	DEBUG(8) <=  rdout_start_flag;
	DEBUG(9) <=  '0'; --DSA_LE;--usb_read_packet_rdy;
	DEBUG(10)<=  '0';--adc_pd_sig(1); --rdout_start_flag;--registers(127)(0); --
	DEBUG(11)<=  mcu_spi_busy;--adc_cal_sig; --usb_slwr;
	--/////////////////////////////////
	
	
	
	
	
	LED(0) <= '1'; --not registers(base_adrs_rdout_cntrl+0)(0); --not clock_10Hz; --not registers(base_adrs_rdout_cntrl+0)(0);
	LED(1) <= '1';
	LED(2) <= '1';
	
	LED(3) <= '1';
	LED(4) <= '1';
	LED(5) <= not (adc_rx_lvds_locked(0) and adc_rx_lvds_locked(1) and 
						adc_rx_lvds_locked(2) and adc_rx_lvds_locked(2) and adc_data_valid and clock_10Hz);
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
	
	
		
			