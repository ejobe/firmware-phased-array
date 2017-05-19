---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         registers_mcu_spi.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         10/2016
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
		status_i			:  in		std_logic_vector(define_register_size-define_address_size-1 downto 0); --//status register
		
		write_reg_i		:	in		std_logic_vector(define_register_size-1 downto 0); --//input data
		write_rdy_i		:	in		std_logic; --//data ready to be written in spi_slave
		write_req_o		:	out	std_logic; --//request the data
		
		read_reg_o 		:	out 	std_logic_vector(define_register_size-1 downto 0); --//set data here to be read out

		registers_io	:	inout	register_array_type;
		address_o		:	out	std_logic_vector(define_address_size-1 downto 0));
		
	end registers_mcu_spi;
	
architecture rtl of registers_mcu_spi is
type read_request_state_type is (idle_st, read_rdy_st, read_req_st);
signal read_request_state 	: read_request_state_type;

signal internal_register 	: std_logic_vector(31 downto 0);
signal internal_ready 		: std_logic;
begin
--//handle rrdy interupts [write_rdy_i] from spi_slave and toggle read_request [write_req_o]
process(rst_i, clk_i, write_rdy_i)
begin
	if rst_i = '1' then
		internal_ready <= '0';
		internal_register <= (others=>'0');
		write_req_o <= '0';
		read_request_state <= idle_st;
	elsif rising_edge(clk_i) then
		case read_request_state is
			when idle_st =>
				internal_ready <= '0';
				internal_register <= (others=>'0');
				write_req_o <= '0';
				if write_rdy_i = '1' then  --//data available
					read_request_state <= read_rdy_st;
				end if;
			
			when read_rdy_st =>
				write_req_o <= '1';
				if write_rdy_i = '0' then --//data successfully read
					internal_register <= write_reg_i;
					internal_ready <= '1'; --//ready flag to register-setting process below
					read_request_state <= read_req_st;
				end if;
				
			when read_req_st =>
				write_req_o <= '0';
				internal_ready <= '0';
				read_request_state <= idle_st;
		end case;
	end if;
end process;
--/////////////////////////////////////////////////////////////////
--//write registers: 
proc_write_register : process(rst_i, clk_i, internal_ready, internal_register)
begin
	if rst_i = '1' then
		--////////////////////////////////////////////////////////////////////////////
		--//read-only registers:
		registers_io(1) <= firmware_version; --//firmware version (see defs.vhd)
		registers_io(2) <= firmware_date;  	 --//date             (see defs.vhd)
		registers_io(3) <= status_i;      	 --//status register
		--////////////////////////////////////////////////////////////////////////////
		--//set some default values
		registers_io(0)  <= x"000001"; --//set read register
		registers_io(16) <= x"000001"; --//set 100 MHz clock source

		registers_io(base_adrs_rdout_cntrl+0) <= x"000000"; --//software trigger register (64)
		registers_io(base_adrs_rdout_cntrl+1) <= x"000000"; --//data readout channel (65)
		registers_io(base_adrs_rdout_cntrl+2) <= x"000000"; --//data readout mode- pick between wfms, beams, etc(66) 
		registers_io(base_adrs_rdout_cntrl+3) <= x"000001"; --//start readout address (67) NOT USED
		registers_io(base_adrs_rdout_cntrl+4) <= x"000100"; --//x"000600"; --//stop readout address (68) NOT USED
		registers_io(base_adrs_rdout_cntrl+5) <= x"000000"; --//current/target RAM address
		registers_io(base_adrs_rdout_cntrl+6) <= x"000000"; --//initiate write to PC adr pulse (write 'read' register) (70) 
		registers_io(base_adrs_rdout_cntrl+7) <= x"000000"; --//initiate write to PC adr pulse (write data) (71)
		registers_io(base_adrs_rdout_cntrl+8) <= x"000000"; --//clear USB write (72)
		registers_io(base_adrs_rdout_cntrl+9) <= x"000000"; --//data chunk
		registers_io(base_adrs_rdout_cntrl+10) <= x"00010F"; --//length of data readout (16-bit ADCwords) (74)
		registers_io(base_adrs_rdout_cntrl+11) <= x"000004"; --//length of register readout (NOT USED, only signal word readouts) (75)
		
		registers_io(127)	<= x"000000"; --//software global reset when LSB is toggled [127]
		 
		registers_io(base_adrs_adc_cntrl+0) <= x"000000"; --//nothing assigned yet (54)
		registers_io(base_adrs_adc_cntrl+1) <= x"000000"; --//pulse adr DCLK_RST   (55)
		registers_io(base_adrs_adc_cntrl+2) <= x"000000"; --//delay ADC0   (56)
		registers_io(base_adrs_adc_cntrl+3) <= x"000000"; --//delay ADC1   (57)
		registers_io(base_adrs_adc_cntrl+4) <= x"000000"; --//delay ADC2   (58)
		registers_io(base_adrs_adc_cntrl+5) <= x"000000"; --//delay ADC3   (59)

		--//step-attenuator:
		registers_io(base_adrs_dsa_cntrl+0) <= x"000000"; --//atten values for CH 0 & 1 & 2
		registers_io(base_adrs_dsa_cntrl+1) <= x"000000"; --//atten values for CH 3 & 4 & 5
		registers_io(base_adrs_dsa_cntrl+2) <= x"000000"; --//atten values for CH 6 & 7
		registers_io(base_adrs_dsa_cntrl+3) <= x"000000"; --//write attenuator spi interface (address toggle)
		
		--//electronics cal pulse:
		registers_io(41) <= x"000000"; --//set RF switch direction(LSB) [41]
		registers_io(42) <= x"000000"; --//enable cal pulse(LSB)    [42]

		read_reg_o 	<= x"00" & registers_io(1); 
		address_o 	<= x"00";
		--////////////////////////////////////////////////////////////////////////////
	elsif rising_edge(clk_i) and internal_ready = '1' then
		--//write registers, but exclude read-only registers
		if internal_register(31 downto 24) > x"0F" then 
		
			registers_io(to_integer(unsigned(internal_register(31 downto 24)))) <= internal_register(23 downto 0);
			address_o <= internal_register(31 downto 24);
		
		end if;
		
		if internal_register(31 downto 24) = x"00" then
			read_reg_o <= x"00" & registers_io(to_integer(unsigned(internal_register(7 downto 0))));
		end if;
		--////////////////////////////////////////////////////////////////////////////
	elsif rising_edge(clk_i) then
		address_o <= x"00";
		registers_io(3) <= status_i; --//update status
		registers_io(127) <= x"000000"; --//clear the reset register
		--////////////////////////////////////////////////////////////////////////////		
	end if;
end process;
--/////////////////////////////////////////////////////////////////
end rtl;