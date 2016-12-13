---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         registers.vhd
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

entity registers is
	port(
		rst_i				:	in		std_logic;
		clk_i				:	in		std_logic;
		status_i			:  in		std_logic_vector(define_register_size-define_address_size-1 downto 0);
		
		write_reg_i		:	in		std_logic_vector(define_register_size-1 downto 0);
		write_rdy_i		:	in		std_logic;
		
		read_reg_o 		:	out 	std_logic_vector(define_register_size-1 downto 0); --//set data here to be read out

		registers_io	:	inout	register_array_type;
		address_o		:	out	std_logic_vector(define_address_size-1 downto 0));
		
	end registers;
	
architecture rtl of registers is
signal internal_register_p1 	: std_logic_vector(31 downto 0); --//register the write_reg_i input
signal internal_rdy_flag		: std_logic_vector(1 downto 0);
signal internal_done_flag		: std_logic;
begin
--//clk transfer for register write:
--///first, latch on rising edge of ready strobe:
process(rst_i, clk_i, write_reg_i, write_rdy_i, internal_done_flag)
begin
	if rst_i = '1' or internal_done_flag = '1' then
		internal_rdy_flag(0) <= '0';
	elsif rising_edge(write_rdy_i) then  --//latch on rising edge
		internal_rdy_flag(0) <= '1';
	end if;
end process;
--///second, register it on the clk
process(rst_i, clk_i, internal_rdy_flag(0), write_reg_i)
begin
	if rst_i = '1' then
		internal_register_p1 <= (others=>'0');
		internal_rdy_flag(1) <= '0';
	elsif rising_edge(clk_i) and internal_rdy_flag(0) = '0' then
		internal_rdy_flag(1) <= '0';
	elsif rising_edge(clk_i) and internal_rdy_flag(0) = '1' then
		internal_register_p1 <= write_reg_i; --//set the register value one clock cycle before rdy flag
		internal_rdy_flag(1) <= '1';
	end if;
end process;

--//write registers:
proc_write_register : process(rst_i, clk_i, internal_rdy_flag, internal_register_p1)
begin
	if rst_i = '1' then
		--//read-only registers:
		registers_io(1) <= firmware_version; --//firmware version
		registers_io(2) <= firmware_date;  	 --//date  
		registers_io(3) <= status_i;      	 --//status register
		
		--//set some default values
		registers_io(0) <= (others=>'0');
		registers_io(base_adrs_rdout_cntrl+0) <= x"000000"; --//trigger register (software trigger LSB)
		registers_io(base_adrs_rdout_cntrl+1) <= x"000000"; --//data readout channel 
		registers_io(base_adrs_rdout_cntrl+3) <= x"000000"; --//start readout address
		registers_io(base_adrs_rdout_cntrl+4) <= x"000200"; --x"000600"; --//stop readout address
		registers_io(base_adrs_rdout_cntrl+6) <= x"000000"; --//initiate write to PC (register value)
		registers_io(base_adrs_rdout_cntrl+7) <= x"000000"; --//initiate write to PC (data)
		registers_io(base_adrs_rdout_cntrl+8) <= x"000000"; --//clear USB write

		registers_io(base_adrs_rdout_cntrl+10) <= x"001019"; --//length of data readout (16-bit words)
		registers_io(base_adrs_rdout_cntrl+11) <= x"000005"; --//length of register readout (16-bit words)
		
		registers_io(127)	<= x"000000"; --//software global reset LSB

		read_reg_o 	<= x"00" & registers_io(1); 
		address_o 	<= x"00";
		
		internal_done_flag <= '0';
		
	elsif rising_edge(clk_i) and internal_rdy_flag(1) = '1' then
		
		if internal_register_p1(31 downto 24) > x"0F" then --//exclude read-only registers
			registers_io(to_integer(unsigned(internal_register_p1(31 downto 24)))) <= internal_register_p1(23 downto 0);
			address_o <= internal_register_p1(31 downto 24);
		end if;
		
		if internal_register_p1(31 downto 24) = x"00" then
			read_reg_o <= x"00" & registers_io(to_integer(unsigned(internal_register_p1(7 downto 0))));
		end if;

		internal_done_flag <= '1';
		
	elsif rising_edge(clk_i) and internal_rdy_flag(1) = '0' then
		
		address_o <= x"00";
		registers_io(3) <= status_i; --//update status
		
		internal_done_flag <= '0';

	end if;
end process;
end rtl;
		
 