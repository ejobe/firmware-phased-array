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
use work.pow_lut.all;

entity power_detector is
	port(
		rst_i			:	in		std_logic;
		clk_i			: 	in		std_logic;
			
		reg_i			: 	in		register_array_type;		
		beams_i		:	in		array_of_beams_type;
		
		sum_pow_o	:	out	sum_power_type);
		
end power_detector;

architecture rtl of power_detector is

signal internal_instant_power 		: full_inst_power_array_type;
signal internal_instant_power_pipe 	: pipe_full_inst_power_array_type;
signal instantaneous_power			 	: pipe_full_inst_power_array_type;

signal internal_beams					: array_of_beams_type;

signal sum_power	: sum_power_type;
constant ref : integer := define_serdes_factor*define_pow_sum_range;

begin

proc_sum_power : process(rst_i, clk_i)
begin
	for i in 0 to define_num_beams-1 loop
		if rst_i = '1' then
			sum_power(i) <= (others=>'0');
			sum_pow_o(i) <= (others=>'0');

		elsif rising_edge(clk_i) then
	
			sum_pow_o(i) <= sum_power(i);
	
			for j in 0 to define_num_power_sums-1 loop
				
				sum_power(i)((j+1)*define_pow_sum_range-1 downto j*define_pow_sum_range) <=
					instantaneous_power(i)( ref+(2*j+1)*define_pow_sum_range-1 downto ref + (2*j)*define_pow_sum_range   ) + 
					instantaneous_power(i)( ref+(2*j+2)*define_pow_sum_range-1 downto ref + (2*j+1)*define_pow_sum_range ) + 
					instantaneous_power(i)( ref+(2*j+3)*define_pow_sum_range-1 downto ref + (2*j+2)*define_pow_sum_range ) + 
					instantaneous_power(i)( ref+(2*j+4)*define_pow_sum_range-1 downto ref + (2*j+3)*define_pow_sum_range ); 
			end loop;
		end if;
	end loop;
end process;

proc_pipe : process(rst_i, clk_i)
begin
	for i in 0 to define_num_beams-1 loop
		if rst_i = '1' then
			internal_beams(i) <= (others=>'0');
			internal_instant_power_pipe(i) <= (others=>'0');
			instantaneous_power(i) <= (others=>'0');

		elsif rising_edge(clk_i) then
			internal_beams(i) <= beams_i(i);
			
			instantaneous_power(i) <= internal_instant_power_pipe(i);
			internal_instant_power_pipe(i)(2*define_serdes_factor*define_pow_sum_range-1 downto 0)
				<= internal_instant_power_pipe(i)(4*define_serdes_factor*define_pow_sum_range-1 downto 2*define_serdes_factor*define_pow_sum_range);
			
			for j in 2*define_serdes_factor to 4*define_serdes_factor-1 loop
				internal_instant_power_pipe(i)((j+1)*define_pow_sum_range-1 downto j*define_pow_sum_range) <= 
					internal_instant_power(i)(j-2*define_serdes_factor);
			end loop;		
			
		end if;
	end loop;
end process;

proc_power_calc : process(rst_i, clk_i, internal_beams)
begin
	--//loop over beams
	for i in 0 to define_num_beams-1 loop
		--//loop over samples in parallel data
		for j in 0 to 2*define_serdes_factor-1 loop
		
			if rst_i = '1' then
				internal_instant_power(i)(j) <= (others=>'0');
			
			elsif rising_edge(clk_i) then
			
				--//////////////////////
				--//check sign bit
				case internal_beams(i)(define_sign_bit+j*define_beam_bits-1) is
					
					when '1'=>
						internal_instant_power(i)(j) <= std_logic_vector(to_unsigned(
							lut_power_neg(to_integer(unsigned(
								internal_beams(i)((j+1)*define_beam_bits-1 downto j*define_beam_bits)))),
							define_pow_sum_range));
							
					when '0'=>
						internal_instant_power(i)(j) <= std_logic_vector(to_unsigned(
							lut_power_pos(to_integer(unsigned(
								internal_beams(i)((j+1)*define_beam_bits-1 downto j*define_beam_bits)))),
							define_pow_sum_range));
				end case;
								
			end if;
		end loop;
	end loop;
end process;
				

		
	




end rtl;