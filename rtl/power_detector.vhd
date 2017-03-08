---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         power_detector.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         3/2017...
--
-- DESCRIPTION:  first stab at calculating power in beams/waveforms
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

entity power_detector is
	port(
		rst_i			:	in		std_logic;
		clk_i			: 	in		std_logic;
			
		reg_i			: 	in		register_array_type;		
		beams_i		:	in		array_of_beams_type);
		
end power_detector;

architecture rtl of power_detector



begin

