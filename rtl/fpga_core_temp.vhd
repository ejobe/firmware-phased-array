---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         fpga_core_temp.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         9/2017
--
-- DESCRIPTION:  reading FPGA core temp value
---------------------------------------------------------------------------------
library IEEE; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;

entity fpga_core_temp is
	port(
		clk_i			:	in		std_logic;
		clk_reg_i	:	in		std_logic;
		rst_i			:	in		std_logic;
		enable_i		:	in		std_logic;
		update_i		:	in		std_logic;
		temp_o		:	out	std_logic_vector(7 downto 0));
end fpga_core_temp;

architecture rtl of fpga_core_temp is
signal internal_update_flag : std_logic;
component flag_sync is
port(
	clkA			: in	std_logic;
   clkB			: in	std_logic;
   in_clkA		: in	std_logic;
   busy_clkA	: out	std_logic;
   out_clkB		: out	std_logic);
end component;

begin

xUPDATESYNC : flag_sync
	port map(
		clkA 			=> clk_reg_i,
		clkB			=> clk_i,
		in_clkA		=> update_i,
		busy_clkA	=> open,
		out_clkB		=> internal_update_flag);
	
xFPGATEMP : entity work.fpga_temp
	port map(
		ce				=> enable_i,
		clk			=> clk_i,
		clr 			=> rst_i or internal_update_flag,	
		tsdcaldone 	=> open,
		tsdcalo 		=> temp_o); 
		
end rtl;


		