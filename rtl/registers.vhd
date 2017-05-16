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
		rst_i				:	in		std_logic;  --//reset
		clk_i				:	in		std_logic;  --//internal register clock 
		ioclk_i			:  in		std_logic;  --//interface clock
		status_i			:  in		std_logic_vector(define_register_size-define_address_size-1 downto 0); --//status register
		
		write_reg_i		:	in		std_logic_vector(define_register_size-1 downto 0);
		write_rdy_i		:	in		std_logic;
		
		read_reg_o 		:	out 	std_logic_vector(define_register_size-1 downto 0); --//set data here to be read out

		registers_io	:	inout	register_array_type;
		address_o		:	out	std_logic_vector(define_address_size-1 downto 0));
		
	end registers;
	
architecture rtl of registers is
signal internal_register_p0 	: std_logic_vector(31 downto 0); --//pline stage 0 the write_reg_i input
signal internal_register_p1 	: std_logic_vector(31 downto 0); --//pline stage 1 the write_reg_i input
signal internal_rdy_flag		: std_logic_vector(3 downto 0);
signal internal_done_flag		: std_logic;
signal interface_notbusy		: std_logic;

component flag_sync port(
	clkA 		: in	std_logic;
	clkB		: in	std_logic;
	in_clkA	: in	std_logic;
	busy_clkA: out	std_logic;
	out_clkB	: out std_logic);
end component;
	
begin
--/////////////////////////////////////////////////////
--//clk transfer for register write:

--//flag transfer block:
--xCLK_XFER : flag_sync port map(
--	clkA => ioclk_i,
--	clkB => clk_i,
--	in_clkA => write_rdy_i,
--	busy_clkA => open,
--	out_clkB => internal_rdy_flag(0));

--// to bypass clk transfer clock, uncomment this:
--internal_rdy_flag(0) <= write_rdy_i;
	
--//first, latch register value given a write_rdy_i flag	
process(rst_i, write_rdy_i, internal_done_flag)
begin
	if rst_i = '1' or internal_done_flag = '1' then
		internal_register_p0 <= (others=>'0');
	elsif rising_edge(write_rdy_i) then  
		internal_register_p0 <= write_reg_i;
	end if;
end process;

--//second, given a flag on clk_i, assert internal_rdy_flag(1) on rising edge
--// (latch on rising edge to prevent registers from being written several times:
--//  ==> do only once on detection of rising edge)
process(rst_i, internal_done_flag, write_rdy_i)
begin
	if rst_i = '1' or internal_done_flag = '1' then
		internal_rdy_flag(0) <= '0'; --//latched value
	elsif rising_edge(write_rdy_i) then
		internal_rdy_flag(0) <= '1'; 
	end if;
end process;
--//last, register it on the clock
process(rst_i, clk_i)
begin
	if rst_i = '1'  then
		internal_register_p1 <= (others=>'0');
		internal_rdy_flag(3 downto 1) <= "000"; --//(1) is meta-stable
	elsif rising_edge(clk_i) then
		internal_rdy_flag(3 downto 1) <= internal_rdy_flag(2 downto 0);
		
		if internal_rdy_flag(2) = '1' then
			internal_register_p1 <= internal_register_p0; --//set the register value one clock cycle before rdy flag
			--internal_rdy_flag(3) <= '1';
		end if;
	end if;
end process;
--/////////////////////////////////////////////////////////////////

--/////////////////////////////////////////////////////////////////
--//write registers: 
proc_write_register : process(rst_i, clk_i, internal_rdy_flag(3), internal_register_p1)
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
		registers_io(base_adrs_rdout_cntrl+2) <= x"000001"; --//data readout mode- pick between wfms, beams, etc(66) 
		registers_io(base_adrs_rdout_cntrl+3) <= x"000001"; --//start readout address (67)
		registers_io(base_adrs_rdout_cntrl+4) <= x"000100"; --x"000600"; --//stop readout address (68)
		registers_io(base_adrs_rdout_cntrl+6) <= x"000000"; --//initiate write to PC adr pulse (write 'read' register) (70) 
		registers_io(base_adrs_rdout_cntrl+7) <= x"000000"; --//initiate write to PC adr pulse (write data) (71)
		registers_io(base_adrs_rdout_cntrl+8) <= x"000000"; --//clear USB write (72)

		registers_io(base_adrs_rdout_cntrl+10) <= x"00010F";
		--//length of data readout (16-bit ADCwords) (74)
		registers_io(base_adrs_rdout_cntrl+11) <= x"000004"; --//length of register readout (16-bit words) (75)
		
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
		
		read_reg_o 	<= x"00" & registers_io(1); 
		address_o 	<= x"00";
		
		--////////////////////////////////////////////////////////////////////////////
		internal_done_flag <= '0';
		
	elsif rising_edge(clk_i) and internal_rdy_flag(3) = '1' then
		
		--//write registers, but exclude read-only registers
		if internal_register_p1(31 downto 24) > x"0F" then 
		
			registers_io(to_integer(unsigned(internal_register_p1(31 downto 24)))) <= internal_register_p1(23 downto 0);
			address_o <= internal_register_p1(31 downto 24);
		
		end if;
		
		if internal_register_p1(31 downto 24) = x"00" then
		
			read_reg_o <= x"00" & registers_io(to_integer(unsigned(internal_register_p1(7 downto 0))));
		
		end if;

		internal_done_flag <= '1';
		
	elsif rising_edge(clk_i) and internal_rdy_flag(3) = '0' then
		
		address_o <= x"00";
		registers_io(3) <= status_i; --//update status
		registers_io(127) <= x"000000"; --//clear the reset register
		
		internal_done_flag <= '0';

	end if;
end process;
--/////////////////////////////////////////////////////////////////
end rtl;
		
 