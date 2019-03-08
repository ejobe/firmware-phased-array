---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         registers_mcu_spi.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         10/2016 + onwards
--
-- DESCRIPTION:  setting registers
---------------------------------------------------------------------------------
--////////////////////////////////////////////////////////////////////////////
library IEEE; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

--////////////////////////////////////////////////////////////////////////////
entity registers_mcu_spi is
	generic(
		FIRMWARE_DEVICE : std_logic);
	port(
		rst_powerup_i	:	in		std_logic;
		rst_i				:	in		std_logic;  --//reset
		clk_i				:	in		std_logic;  --//internal register clock 
		sync_slave_i	:	in		std_logic;  --//signal to sync specific register assignments between boards (SLAVE only)
		sync_from_master_o : out std_logic;	--// ^sync signal from master to slave
		--//////////////////////////////
		--//status/system read-only registers:
		fpga_temp_i							:  in		std_logic_vector(7 downto 0);
		scaler_to_read_i					:  in		std_logic_vector(define_register_size-define_address_size-1 downto 0);
		status_data_manager_i			:  in		std_logic_vector(define_register_size-define_address_size-1 downto 0); 
		status_data_manager_surface_i	:  in		std_logic_vector(define_register_size-define_address_size-1 downto 0); 
		status_data_manager_latched_i :  in		std_logic_vector(define_register_size-define_address_size-1 downto 0);
		status_adc_i						:  in		std_logic_vector(define_register_size-define_address_size-1 downto 0); 
		event_metadata_i					:	in		event_metadata_type;
		event_metadata_surface_i		:	in		event_metadata_type;
		current_ram_adr_data_i			:	in		ram_adr_chunked_data_type;
		current_ram_adr_data_surface_i:	in		ram_adr_chunked_data_type;
		remote_upgrade_data_i			:  in		std_logic_vector(31 downto 0);
		remote_upgrade_epcq_data_i    :  in		std_logic_vector(31 downto 0);
		remote_upgrade_status_i			:  in		std_logic_vector(23 downto 0);
		pps_timestamp_to_read_i			:	in		std_logic_vector(47 downto 0);
		--////////////////////////////
		write_reg_i		:	in		std_logic_vector(define_register_size-1 downto 0); --//input data
		write_rdy_i		:	in		std_logic; --//data ready to be written in spi_slave
		read_reg_o 		:	out 	std_logic_vector(define_register_size-1 downto 0); --//set data here to be read out
		registers_io	:	inout	register_array_type;
		--registers_dclk_o		:	out	register_array_type;  --//copy of registers on clk_data_i
		sync_active_o	:  inout	std_logic := '0'; --//for debugging
		address_o		:	out	std_logic_vector(define_address_size-1 downto 0));
		
	end registers_mcu_spi;

--////////////////////////////////////////////////////////////////////////////
architecture rtl of registers_mcu_spi is

signal internal_sync_slave : std_logic;
signal internal_sync_master: std_logic;
signal internal_sync_reg   : std_logic_vector(1 downto 0);
signal internal_sync_timeout_counter : std_logic_vector(23 downto 0);
signal internal_sync_register  : std_logic_vector(define_register_size-1 downto 0);
signal unique_chip_id		: std_logic_vector(63 downto 0);
signal unique_chip_id_rdy	: std_logic;

begin
--////////////////////////////////////////////////////////////////////////////
proc_master_slave: process(internal_sync_master, sync_slave_i)
begin
	case FIRMWARE_DEVICE is
		when '1' =>
			internal_sync_slave <= '0';  --//master device
			sync_from_master_o <= internal_sync_master;
		when '0' =>
			internal_sync_slave <= sync_slave_i;  --//slave device
			sync_from_master_o <= '0';
	end case;
end process;
--/////////////////////////////////////////////////////////////////
--//write registers: 
proc_write_register : process(rst_i, clk_i, write_rdy_i, write_reg_i, registers_io, rst_powerup_i)
begin

	if rst_i = '1' then
		--////////////////////////////////////////////////////////////////////////////
		--//for a few registers, only set defaults on power up:
		if rst_powerup_i = '1' then
			
			--//setting clock source:
			registers_io(124) <= x"000000"; --//set 100 MHz clock source: external LVDS input (LSB=0) or local oscillator (LSB=1) [124]
			case FIRMWARE_DEVICE is 
				when '1' =>
					registers_io(base_adrs_adc_cntrl+6) <= x"000000"; --//ADC PD control (60)
					registers_io(1) <= ("0000000" & FIRMWARE_DEVICE & x"0000") or master_firmware_version; --//firmware version (see defs.vhd)
					registers_io(2) <= master_firmware_date;  	 --//date             (see defs.vhd)
				when '0' =>
					registers_io(base_adrs_adc_cntrl+6) <= x"000000"; --//ADC PD control (60) NO longer turn off any ADCs on slave board
					registers_io(1) <= ("0000000" & FIRMWARE_DEVICE & x"0000") or slave_firmware_version; --//firmware version (see defs.vhd)
					registers_io(2) <= slave_firmware_date;  	 --//date             (see defs.vhd)
			end case;
		end if;
		
		--////////////////////////////////////////////////////////////////////////////
		--//read-only registers:
		registers_io(3) <= x"000000";       --//status register
		registers_io(4) <= x"000000"; 		--//chipID (lower 24 bits)
		registers_io(5) <= x"000000"; 		--//chipID (bits 48 to 25)
		registers_io(6) <= x"000000";			--//chipID (bits 64 to 49)
		registers_io(7) <= x"000000"; 
		registers_io(8) <= x"000000";
		registers_io(9) <= x"000000";
		registers_io(10) <= x"000000";
		registers_io(11) <= x"000000";
		registers_io(12) <= x"000000";
		registers_io(13) <= x"000000";
		registers_io(14) <= x"000000";
		registers_io(15) <= x"000000";
		registers_io(16) <= x"000000";
		registers_io(17) <= x"000000";
		registers_io(18) <= x"000000";
		registers_io(19) <= x"000000";
		registers_io(20) <= x"000000";
		registers_io(21) <= x"000000";
		registers_io(22) <= x"000000";
		registers_io(23) <= x"000000";
		registers_io(24) <= x"000000";
		registers_io(25) <= x"000000";
		registers_io(26) <= x"000000";
		registers_io(27) <= x"000000";
		registers_io(28) <= x"000000";
		registers_io(29) <= x"000000";
		registers_io(30) <= x"000000";
		registers_io(31) <= x"000000";
		registers_io(32) <= x"000000";
		registers_io(33) <= x"000000";
		registers_io(34) <= x"000000";
		registers_io(39) <= x"000000"; --//sync command register [39]

		--////////////////////////////////////////////////////////////////////////////
		--//set some default values
		registers_io(109) <= x"000001"; --//set read register
		
		registers_io(base_adrs_rdout_cntrl+0) <= x"000000"; --//software trigger register (64)
		registers_io(base_adrs_rdout_cntrl+1) <= x"000000"; --//data readout channel (65)
		registers_io(base_adrs_rdout_cntrl+2) <= x"000000"; --//data readout mode- pick between wfms, beams, etc(66) 
		registers_io(base_adrs_rdout_cntrl+3) <= x"000001"; --//start readout address (67) NOT USED
		registers_io(base_adrs_rdout_cntrl+4) <= x"000100"; --//x"000600"; --//stop readout address (68) NOT USED
		registers_io(base_adrs_rdout_cntrl+5) <= x"000000"; --//current/target RAM address [69]
		--//////////////////////////////////////////////////////////////////////////////////////////////////
		--//note differentiating between the following 2 readout types only used when using USB readout
		--//otherwise only base_adrs_rdout_cntrl+7 is used
		registers_io(base_adrs_rdout_cntrl+6) <= x"000000"; --//initiate write to PC adr pulse (write 'read' register) (70) --only used when USB readout
		registers_io(base_adrs_rdout_cntrl+7) <= x"000000"; --//initiate write to PC adr pulse (write data) (71) --use this ONLY when MCU/BeagleBone to initiate write to PC
		--///////////////////////////////////////
		registers_io(base_adrs_rdout_cntrl+8)  <= x"000000"; --//clear USB write (72)
		registers_io(base_adrs_rdout_cntrl+9)  <= x"000000"; --//data chunk
		registers_io(base_adrs_rdout_cntrl+10) <= x"00010F"; --//length of data readout (16-bit ADCwords) (74)
		registers_io(base_adrs_rdout_cntrl+11) <= x"000004"; --//length of register readout (NOT USED, only signal word readouts) (75)
		registers_io(base_adrs_rdout_cntrl+12) <= x"000404"; --//readout pre-trig window [76]
		registers_io(base_adrs_rdout_cntrl+13) <= x"000000"; --//clear data buffer + Reset Buffer Number to 0 [77]
		registers_io(base_adrs_rdout_cntrl+14) <= x"000000"; --//select readout waveform buffer [78]

		registers_io(126) <= x"000000"; --//reset event counter 
		registers_io(127)	<= x"000000"; --//software global reset when LSB is toggled [127]
		 
		registers_io(base_adrs_adc_cntrl+0) <= x"000000"; --//nothing assigned yet (54)
		registers_io(base_adrs_adc_cntrl+1) <= x"000000"; --//write a one to pulse DCLK RST   (55)
		registers_io(base_adrs_adc_cntrl+2) <= x"000000"; --//delay ADC0   (56)
		registers_io(base_adrs_adc_cntrl+3) <= x"000000"; --//delay ADC1   (57)
		registers_io(base_adrs_adc_cntrl+4) <= x"000000"; --//delay ADC2   (58)
		registers_io(base_adrs_adc_cntrl+5) <= x"000000"; --//delay ADC3   (59)

		--//step-attenuator:
		registers_io(base_adrs_dsa_cntrl+0) <= x"000000"; --//atten values for CH 0 & 1 & 2 [n.b., 1 byte each, need to be bit-reversed in sw]
		registers_io(base_adrs_dsa_cntrl+1) <= x"000000"; --//atten values for CH 3 & 4 & 5
		registers_io(base_adrs_dsa_cntrl+2) <= x"000000"; --//atten values for CH 6 & 7
		registers_io(base_adrs_dsa_cntrl+3) <= x"000000"; --//write attenuator spi interface (address toggle)
		
		--//scalers
		registers_io(40) <= x"000000"; --//update scaler pulse
		registers_io(41) <= x"000000"; --//scaler-to-read
		
		--//trigger channel delays
		registers_io(61) <= x"000000"; --//delay CH0,1,2
		registers_io(62) <= x"000000"; --//delay CH3,4,5
		registers_io(63) <= x"000000"; --//delay CH6,7
		
		--//electronics cal pulse:
		registers_io(42) <= x"000000"; --//enable cal pulse([LSB]=1) and set RF switch direction([LSB+1]=1 for cal pulse)   [42]
		--registers_io(43) <= x"000001"; --//cal pulse pattern, maybe make this configurable? -> probably a timing nightmare since on 250 MHz clock? 
		
		--//surface trigger stuff
		registers_io(46) <= x"380914"; --//lower byte = vpp threshold ; 
		registers_io(47) <= x"01000A"; --//
		
		--//masking + trigger configurations
		registers_io(48) <= x"0000FF";   --// channel masking [48]
		registers_io(80) <= x"FFFFFF";   --// beam masks for trigger [80]
		registers_io(81) <= x"0001FF";   --// trig holdoff - lower 16 bits [81]
		registers_io(82) <= x"000300";	--// phased trigger/beam enables [82]
		registers_io(75) <= x"00FF00";   --// external trigger input configuration [75]
		registers_io(83) <= x"000C03";   --// external trigger output configuration [83]
		registers_io(84) <= x"000000";   --// enable phased trigger to data manager (LSB=1 to enable)
		registers_io(85) <= x"000001";   --// trigger verification mode (LSB=1 to enable)
		
		registers_io(108) <= x"000000"; --//write LSB to update internal temp sensor; LSB+1 to enable[108]

		--//trigger thresholds:
		registers_io(base_adrs_trig_thresh+0) <= x"0FFFFF";   --//[86]
		registers_io(base_adrs_trig_thresh+1) <= x"0FFFFF";   --//[87]
		registers_io(base_adrs_trig_thresh+2) <= x"0FFFFF";   --//[88]
		registers_io(base_adrs_trig_thresh+3) <= x"0FFFFF";   --//[89]
		registers_io(base_adrs_trig_thresh+4) <= x"0FFFFF";   --//[90]
		registers_io(base_adrs_trig_thresh+5) <= x"0FFFFF";   --//[91]
		registers_io(base_adrs_trig_thresh+6) <= x"0FFFFF";   --//[92]
		registers_io(base_adrs_trig_thresh+7) <= x"0FFFFF";   --//[93]
		registers_io(base_adrs_trig_thresh+8) <= x"0FFFFF";   --//[94]
		registers_io(base_adrs_trig_thresh+9) <= x"0FFFFF";   --//[95]
		registers_io(base_adrs_trig_thresh+10) <= x"0FFFFF";   --//[96]
		registers_io(base_adrs_trig_thresh+11) <= x"0FFFFF";   --//[97]
		registers_io(base_adrs_trig_thresh+12) <= x"0FFFFF";   --//[98]
		registers_io(base_adrs_trig_thresh+13) <= x"0FFFFF";   --//[99]
		registers_io(base_adrs_trig_thresh+14) <= x"0FFFFF";   --//[100]
		registers_io(base_adrs_trig_thresh+15) <= x"0FFFFF";   --//[101]
		
		registers_io(base_adrs_trig_thresh+16) <= x"0FFFFF";   --//[102] --hpol surface trig threshold

		--//remote upgrade registers
		registers_io(110) <= x"000000"; --//LSB = 1 to enable remote upgrade block
		registers_io(111) <= x"000000";
		registers_io(112) <= x"000000";
		registers_io(113) <= x"000000";
		registers_io(114) <= x"000000";
		registers_io(115) <= x"000000";
		registers_io(116) <= x"000000";
		registers_io(117) <= x"000000";
		registers_io(118) <= x"000000";
		registers_io(119) <= x"000000";
		registers_io(120) <= x"000000";
		registers_io(121) <= x"000000";
		registers_io(122) <= x"000000";		
		--//end remote upgrade registers
		
		read_reg_o 	<= x"00" & registers_io(1); 
		address_o 	<= x"00";
		internal_sync_master <= '0';
		internal_sync_register <= (others=>'0');
		internal_sync_reg <= (others=>'0');
		sync_active_o <= '0';
		
	--//////////////////////////////////////////////////////////////////////////////////////////
	--lots of if/else statements here, not awesome, but meets timing (only running this @25 MHz)
	-------------------------------------------------------------
	elsif rising_edge(clk_i) then 
		sync_active_o <= internal_sync_reg(0);
		internal_sync_reg <= internal_sync_reg(0) & (internal_sync_slave or internal_sync_master);	

		--//read only REMOTE UPGRADE registers (doesn't fit in read only allotment, so assign here continuously)
		registers_io(103) <= remote_upgrade_status_i;
		registers_io(104) <= x"00" & remote_upgrade_data_i(15 downto 0);
		registers_io(105) <= x"00" & remote_upgrade_data_i(31 downto 16);
		registers_io(106) <= x"00" & remote_upgrade_epcq_data_i(15 downto 0);
		registers_io(107) <= x"00" & remote_upgrade_epcq_data_i(31 downto 16);
		--//read only latched timestamp register (doesn't fit in read only allotment, so assign here continuously)
		registers_io(44)	<= pps_timestamp_to_read_i(23 downto 0);
		registers_io(45)	<= pps_timestamp_to_read_i(47 downto 24);
		--//------------------------------------------------------------------------------
		
		--//handle sync event, falling edge condition of internal_sync_reg (i.e. the sync is 'released')
		if internal_sync_reg = "10" then
			registers_io(to_integer(unsigned(internal_sync_register(31 downto 24)))) <= internal_sync_register(23 downto 0);
			address_o <= internal_sync_register(31 downto 24);
		
		--//read register command
		elsif write_rdy_i = '1' and write_reg_i(31 downto 24) = x"6D" then
			read_reg_o <=  write_reg_i(7 downto 0) & registers_io(to_integer(unsigned(write_reg_i(7 downto 0))));
			address_o <= x"47";  --//initiate a read	
		
		--//read data chunk 0
		elsif write_rdy_i = '1' and write_reg_i(31 downto 24) = x"23" then
			case registers_io(47)(8) is 
				when '0' => read_reg_o <= current_ram_adr_data_i(0);
				when '1' =>	read_reg_o <= current_ram_adr_data_surface_i(0);
			end case;
			address_o <= x"47";  --//initiate a read
		--//read data chunk 1
		elsif write_rdy_i = '1' and write_reg_i(31 downto 24) = x"24" then
			case registers_io(47)(8) is 
				when '0' => read_reg_o <= current_ram_adr_data_i(1);
				when '1' =>	read_reg_o <= current_ram_adr_data_surface_i(1);
			end case;
			address_o <= x"47";  --//initiate a read			
		--//read data chunk 2
		elsif write_rdy_i = '1' and write_reg_i(31 downto 24) = x"25" then
			case registers_io(47)(8) is 
				when '0' => read_reg_o <= current_ram_adr_data_i(2);
				when '1' =>	read_reg_o <= current_ram_adr_data_surface_i(2);
			end case;
			address_o <= x"47";  --//initiate a read				
		--//read data chunk 3	
		elsif write_rdy_i = '1' and write_reg_i(31 downto 24) = x"26" then
			case registers_io(47)(8) is 
				when '0' => read_reg_o <= current_ram_adr_data_i(3);
				when '1' =>	read_reg_o <= current_ram_adr_data_surface_i(3);
			end case;
			address_o <= x"47";  --//initiate a read
			
		--//catch a sync command, if master board. 
		elsif write_rdy_i = '1' and write_reg_i(31 downto 24) = x"27" then
			internal_sync_master <= write_reg_i(0) and FIRMWARE_DEVICE;
			address_o <= (others=>'0');
			
		--//write register value
		elsif write_rdy_i = '1' and write_reg_i(31 downto 24) > x"27" then  --//read/write registers
			--//if sync high, don't immediatly write the register value:
			if internal_sync_reg = "11" then
				internal_sync_register <= write_reg_i;
				address_o <= (others=>'0');
			else
				registers_io(to_integer(unsigned(write_reg_i(31 downto 24)))) <= write_reg_i(23 downto 0);
				address_o <= write_reg_i(31 downto 24);
			end if;

		else
			address_o <= x"00";
			--////////////////////////////////////////////////
			--//update status/system read-only registers
			registers_io(3) <= scaler_to_read_i;
			registers_io(7) <= status_data_manager_i(23 downto 5) & status_data_manager_surface_i(0) & status_data_manager_i(3 downto 0); 
			registers_io(8) <= status_adc_i; 
			registers_io(9) <= status_data_manager_latched_i; 
			--//assign event meta data
			for j in 0 to 24 loop
				case registers_io(47)(8) is 
					when '0' => registers_io(j+10) <= event_metadata_i(j);
					when '1' => registers_io(j+10) <= event_metadata_surface_i(j);
				end case;
			end loop;
			--////////////////////////////////////////////////
			--//clear pulsed registers
			registers_io(127) <= x"000000"; --//clear the reset register
			registers_io(126) <= x"000000"; --//clear the event counter reset
			registers_io(108)(0) <= '0'; --//clear the temp-update register LSB
			registers_io(base_adrs_rdout_cntrl+0) <= x"000000"; --//clear the software trigger
			registers_io(base_adrs_rdout_cntrl+13)<= x"000000"; --//clear the 'buffer clear' register
			registers_io(base_adrs_adc_cntrl+1)   <= x"000000"; --//clear the DCLK Reset pulse
			registers_io(40) <= x"000000"; --//clear the update scalers pulse
			--////////////////////////////////////////////////////////////////////////////	
			--//these should be static, but keep updating every clk_i cycle
			if unique_chip_id_rdy = '1' then
				registers_io(4) <= unique_chip_id(23 downto 0);
				registers_io(5) <= unique_chip_id(47 downto 24);
				registers_io(6) <= fpga_temp_i & unique_chip_id(63 downto 48);	
			end if;
		end if;
		
		--//turn off surface ADCs if specified
		if registers_io(47)(16) = '0' and FIRMWARE_DEVICE = '0' then
			registers_io(base_adrs_adc_cntrl+6) <= x"00000E";
		end if;
		--/requires power cycle to turn them back on	
		
	end if;
end process;
--/////////////////////////////////////////////////////////////////
--//get silicon ID:
xUNIQUECHIPID : entity work.ChipID
port map(
	clkin      => clk_i,
	reset      => rst_i,
	data_valid => unique_chip_id_rdy,
	chip_id    => unique_chip_id);
end rtl;
--////////////////////////////////////////////////////////////////////////////