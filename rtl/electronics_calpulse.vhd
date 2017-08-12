---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         electronics_calpulse.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         5/2017...
--
-- DESCRIPTION:  Pulse and enable for plug-in-line cal pulse board, which
--               allows user to line up ADC timestreams
--					  --//managed by register 42
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.defs.all;

entity electronics_calpulse is
	generic(
		ENABLE_CALIBRATION_PULSE : std_logic := '1');
	port(
		rst_i			:	in		std_logic;  --//async reset
		clk_i			: 	in		std_logic;  --//fast clock to run DDR output		
		reg_i			: 	in		register_array_type;		--//system registers		
		pulse_o		:	out	std_logic;  --//fast pulse to board SMA
		rf_switch_o :	out	std_logic); --//pick RF switch input
end electronics_calpulse;

architecture rtl of electronics_calpulse is
--//with input clock, clk_i
-----//Repetition Period  is 2*d_length / (2*clk_i) 
constant d_length : integer := 128;
signal data_h : std_logic_vector(d_length-1 downto 0) := (others=>'0');
signal data_l : std_logic_vector(d_length-1 downto 0) := (others=>'0');
signal index  : std_logic_vector(7 downto 0) := (others=>'0'); --//matches d_length, number of bits 
signal data_h_current_value : std_logic_vector(0 downto 0);
signal data_l_current_value : std_logic_vector(0 downto 0);
signal data_out_current_value : std_logic_vector(0 downto 0);
--//
begin
data_h(0) <= '1'; --//single hi bit for pulse
----///////////
rf_switch_o <= not (reg_i(42)(1)); --//set rf switch input selection [reg(42)(1) = 1 --> switch to pulse ;; reg(42)(1) = 0 --> switch to signal chain] 
--/////////////
pulse_o <= data_out_current_value(0);
--/////////////
proc_cycle_data : process(rst_i, reg_i, clk_i)
begin
	if rst_i = '1' or reg_i(42)(0) = '0' or ENABLE_CALIBRATION_PULSE = '0' then
		data_h_current_value(0) <= '0';
		data_l_current_value(0) <= '0';
		index <= (others=>'0');
	elsif rising_edge(clk_i) then
		data_h_current_value(0) <= data_h(to_integer(unsigned(index)));
		data_l_current_value(0) <= data_l(to_integer(unsigned(index)));
		index <= index + 1;
	end if;
end process;
--/////////////////////////////////////////
--//pulse generated using DDR output buffer
xDDRPULSEGENERATOR : entity work.DDRout
port map(
	aclr			=>	rst_i or (not ENABLE_CALIBRATION_PULSE),
	datain_h		=> data_h_current_value,
	datain_l		=> data_l_current_value,
	outclock		=> clk_i,
	outclocken	=> reg_i(42)(0) and ENABLE_CALIBRATION_PULSE,
	dataout		=>	data_out_current_value);
end rtl;