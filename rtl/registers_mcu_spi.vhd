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
library IEEE; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

entity registers_mcu_spi is
	port(
		rst_i				:	in		std_logic;  --//reset
		clk_i				:	in		std_logic;  --//internal register clock 
		--//////////////////////////////
		--//status registers:
		status_data_manager_i			:  in		std_logic_vector(define_register_size-define_address_size-1 downto 0); 
		--////////////////////////////
		write_reg_i		:	in		std_logic_vector(define_register_size-1 downto 0); --//input data
		write_rdy_i		:	in		std_logic; --//data ready to be written in spi_slave
		write_req_o		:	out	std_logic; --//request the data
		read_reg_o 		:	out 	std_logic_vector(define_register_size-1 downto 0); --//set data here to be read out
		registers_io	:	inout	register_array_type;
		--registers_dclk_o		:	out	register_array_type;  --//copy of registers on clk_data_i
		address_o		:	out	std_logic_vector(define_address_size-1 downto 0));
		
	end registers_mcu_spi;
	
architecture rtl of registers_mcu_spi is
--type read_request_state_type is (idle_st, read_rdy_st, read_req_st);
--signal read_request_state 	: read_request_state_type;

--signal internal_register 	: std_logic_vector(31 downto 0);
--signal internal_ready 		: std_logic;
signal unique_chip_id		: std_logic_vector(63 downto 0);
signal unique_chip_id_rdy	: std_logic;

begin
--/////////////////////////////////////////////////////////////////
--//write registers: 
proc_write_register : process(rst_i, clk_i, write_rdy_i, write_reg_i)
begin
	if rst_i = '1' then
		--////////////////////////////////////////////////////////////////////////////
		--//read-only registers:
		registers_io(1) <= firmware_version; --//firmware version (see defs.vhd)
		registers_io(2) <= firmware_date;  	 --//date             (see defs.vhd)
		registers_io(3) <= x"000000";       --//status register
		registers_io(4) <= x"000000"; 		--//chipID (lower 24 bits)
		registers_io(5) <= x"000000"; 		--//chipID (bits 48 to 25)
		registers_io(6) <= x"000000";			--//chipID (bits 64 to 49)
		registers_io(7) <= x"000000"; 
		
		
		--////////////////////////////////////////////////////////////////////////////
		--//set some default values
		registers_io(0)  <= x"000001"; --//set read register
		registers_io(32) <= x"000001"; --//set 100 MHz clock source: external LVDS input or local oscillator

		registers_io(base_adrs_rdout_cntrl+0) <= x"000000"; --//software trigger register (64)
		registers_io(base_adrs_rdout_cntrl+1) <= x"000000"; --//data readout channel (65)
		registers_io(base_adrs_rdout_cntrl+2) <= x"000000"; --//data readout mode- pick between wfms, beams, etc(66) 
		registers_io(base_adrs_rdout_cntrl+3) <= x"000001"; --//start readout address (67) NOT USED
		registers_io(base_adrs_rdout_cntrl+4) <= x"000100"; --//x"000600"; --//stop readout address (68) NOT USED
		registers_io(base_adrs_rdout_cntrl+5) <= x"000000"; --//current/target RAM address
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
		registers_io(base_adrs_rdout_cntrl+12) <= x"000000"; --//readout pre-trig window [76]
		registers_io(base_adrs_rdout_cntrl+13) <= x"000000"; --//clear data buffer [77]
		registers_io(base_adrs_rdout_cntrl+14) <= x"000000"; --//select readout waveform buffer [78]

		registers_io(127)	<= x"000000"; --//software global reset when LSB is toggled [127]
		 
		registers_io(base_adrs_adc_cntrl+0) <= x"000000"; --//nothing assigned yet (54)
		registers_io(base_adrs_adc_cntrl+1) <= x"000000"; --//pulse adr DCLK_RST   (55)
		registers_io(base_adrs_adc_cntrl+2) <= x"000000"; --//delay ADC0   (56)
		registers_io(base_adrs_adc_cntrl+3) <= x"000000"; --//delay ADC1   (57)
		registers_io(base_adrs_adc_cntrl+4) <= x"000000"; --//delay ADC2   (58)
		registers_io(base_adrs_adc_cntrl+5) <= x"000000"; --//delay ADC3   (59)
		registers_io(base_adrs_adc_cntrl+6) <= x"000000"; --//ADC PD control (60)

		--//step-attenuator:
		registers_io(base_adrs_dsa_cntrl+0) <= x"000000"; --//atten values for CH 0 & 1 & 2
		registers_io(base_adrs_dsa_cntrl+1) <= x"000000"; --//atten values for CH 3 & 4 & 5
		registers_io(base_adrs_dsa_cntrl+2) <= x"000000"; --//atten values for CH 6 & 7
		registers_io(base_adrs_dsa_cntrl+3) <= x"000000"; --//write attenuator spi interface (address toggle)
		
		--//electronics cal pulse:
		registers_io(42) <= x"000000"; --//enable cal pulse([LSB]=1) and set RF switch direction([LSB+1]=1 for cal pulse)   [42]
		--registers_io(43) <= x"000001"; --//cal pulse pattern, dunno maybe make this configurable? -> probably a timing nightmare since on 250 MHz clock? 
		
		registers_io(48) <= x"000000";  --//channel masking [48]
		
		
		registers_io(80) <= x"FFFFFF";   --// beam masks for trigger [80]
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
		
		read_reg_o 	<= x"00" & registers_io(1); 
		address_o 	<= x"00";
	--////////////////////////////////////////////////////////////////////////////
	elsif rising_edge(clk_i) and write_rdy_i= '1' then --write_rdy_i is sync with clk_i with newer spi_slave code
		--//write registers, but exclude read-only registers
		if write_reg_i(31 downto 24) > x"1F" then 
		
			registers_io(to_integer(unsigned(write_reg_i(31 downto 24)))) <= write_reg_i(23 downto 0);
			address_o <= write_reg_i(31 downto 24);
		
		end if;
		
		if write_reg_i(31 downto 24) = x"00" then
			read_reg_o <= x"00" & registers_io(to_integer(unsigned(write_reg_i(7 downto 0))));
		end if;
		
	--////////////////////////////////////////////////////////////////////////////
	elsif rising_edge(clk_i) then
		address_o <= x"00";
		--///////////////////////
		--//update status registers
		registers_io(7) <= status_data_manager_i; 
		--///////////////////////
		registers_io(127) <= x"000000"; --//clear the reset register
		registers_io(base_adrs_rdout_cntrl+0) <= x"000000"; --//clear the software trigger
		registers_io(base_adrs_rdout_cntrl+13)<= x"000000"; --//clear the 'buffer clear' register
		--////////////////////////////////////////////////////////////////////////////	
		--//these should be static, but keep updating every clk_i cycle
		if unique_chip_id_rdy = '1' then
			registers_io(4) <= unique_chip_id(23 downto 0);
			registers_io(5) <= unique_chip_id(47 downto 24);
			registers_io(6) <= x"00" & unique_chip_id(63 downto 48);	
		end if;
		--////////////////////////////////////////////////////////////////////////////
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