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
-- DESCRIPTION:  calculate power in beams (waveforms, too, at some point?)
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;
use work.pow_lut.all;  --//lut for power calculations

entity power_detector_single is
	port(
		rst_i			:	in		std_logic;
		clk_i			: 	in		std_logic;
			
		reg_i			: 	in		register_array_type;		
		data_i		:	in		std_logic_vector(2*define_serdes_factor*define_word_size-1 downto 0);
		
		sum_pow_o	:	out	std_logic_vector(define_num_power_sums*(define_pow_sum_range+1)-1 downto 0));
		
end power_detector_single;

architecture rtl of power_detector_single is

signal internal_instant_power 		: inst_power_array_type;
signal internal_instant_power_pipe 	: std_logic_vector(4*define_serdes_factor*define_pow_sum_range-1 downto 0);
signal instantaneous_power			 	: std_logic_vector(4*define_serdes_factor*define_pow_sum_range-1 downto 0);

signal internal_beams					: std_logic_vector(2*define_serdes_factor*define_word_size-1 downto 0);

constant ref : integer := define_serdes_factor*define_pow_sum_range;

begin

--//sum_power holds the summed power in adjacent samples (every 2 samples)
--//note that define_pow_sum_range (defined in defs) is 16
proc_sum_power : process(rst_i, clk_i)
begin
	if rst_i = '1' then
		sum_pow_o <= (others=>'0');

	elsif rising_edge(clk_i) then
	
	 				
		for j in 0 to define_num_power_sums-1 loop

			--//sum_power at each step is 17 bits wide (define_pow_sum_range+1)
			sum_pow_o((j+1)*(define_pow_sum_range+1)-1 downto j*(define_pow_sum_range+1)) <=
		std_logic_vector(resize(unsigned(instantaneous_power( ref+(2*j+1)*define_pow_sum_range-1 downto ref+(2*j)*define_pow_sum_range) ), define_pow_sum_range+1)) + 
		std_logic_vector(resize(unsigned(instantaneous_power( ref+(2*j+2)*define_pow_sum_range-1 downto ref+(2*j+1)*define_pow_sum_range)), define_pow_sum_range+1)); 
				
		end loop;
	end if;
end process;

proc_pipe : process(rst_i, clk_i)
begin
		if rst_i = '1' then
			internal_beams <= (others=>'0');
			internal_instant_power_pipe <= (others=>'0');
			instantaneous_power <= (others=>'0');

		elsif rising_edge(clk_i) then
			--//pipeline stage for data
			internal_beams <= data_i;
			--//final assignment of power calc.
			instantaneous_power <= internal_instant_power_pipe;
			--//pipeline stage for power calc.
			internal_instant_power_pipe(2*define_serdes_factor*define_pow_sum_range-1 downto 0)
				<= internal_instant_power_pipe(4*define_serdes_factor*define_pow_sum_range-1 downto 2*define_serdes_factor*define_pow_sum_range);
			
			for j in 2*define_serdes_factor to 4*define_serdes_factor-1 loop
				internal_instant_power_pipe((j+1)*define_pow_sum_range-1 downto j*define_pow_sum_range) <= 
					internal_instant_power(j-2*define_serdes_factor);
			end loop;		
			
		end if;
end process;

--//calculate instantaneous power using LUT
proc_power_calc : process(rst_i, clk_i, internal_beams)
begin
		--//loop over samples in parallel data
		for j in 0 to 2*define_serdes_factor-1 loop
		
			if rst_i = '1' then
				internal_instant_power(j) <= (others=>'0');
			
			elsif rising_edge(clk_i) then

					internal_instant_power(j) <= std_logic_vector(to_unsigned(
						lut_power(to_integer(unsigned(internal_beams((j+1)*define_word_size-1 downto j*define_word_size))) - 63),
						define_pow_sum_range));
								
			end if;
		end loop;
end process;
				
end rtl;