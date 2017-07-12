---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         scalers_top.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         7/2017
--
-- DESCRIPTION:  manage board scalers and readout of scalers 
--               
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;

entity scalers_top is
	port(
		rst_i				:		in		std_logic;
		clk_i				:		in 	std_logic;
		pulse_refrsh_i	:		in		std_logic;
		gate_i			:		in		std_logic);
end scalers_top;

architecture rtl of scalers_top is
begin
end rtl;
		