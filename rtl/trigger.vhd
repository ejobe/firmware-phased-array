---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         trigger.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         6/2017...
--
-- DESCRIPTION:  trigger generation
--               this module takes in the power sums, adds additional smoothing/averaging
--					  compares to threshold
--
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

entity trigger is
	port(
		rst_i				:	in		std_logic;
		clk_data_i		:	in		std_logic; --//data clock ~93 MHz
		clk_iface_i		: 	in		std_logic; --//slow logic clock =7.5 MHz
			
		reg_i				: 	in		register_array_type;		
		powersums_i		:	in		sum_power_type;
		
		trig_out			:	out	std_logic;
		trig_scalers	:	out	std_logic);
		
end trigger;

architecture rtl of trigger is

type buffered_powersum_type is array(define_num_beams-1 downto 0) of 
	std_logic_vector(2*define_num_power_sums*(define_pow_sum_range+1)-1 downto 0);

signal buffered_powersum : buffered_powersum_type;
signal instantaneous_avg_power_0 : average_power_16samp_type;  --//defined in defs.vhd
signal instantaneous_avg_power_1 : average_power_16samp_type;  --//defined in defs.vhd

signal beam_trig			:	std_logic_vector(define_num_beams-1 downto 0); --//trigger in each beam
signal above_threshold	:	std_logic_vector(define_num_beams-1 downto 0); --//check in each beam

begin

proc_buf_powsum : process(rst_i, clk_data_i)
begin
	for i in 0 to define_num_beams-1 loop
		if rst_i = '1' then
			instantaneous_avg_power_0(i) <= (others=>'0');
			instantaneous_avg_power_1(i) <= (others=>'0');
			
			buffered_powersum(i) <= (others=>'0');
		
		--//there are 16 samples every clock cycle. We want to calculate the power in 16 sample units every 8 samples.
		--//So that's two power calculations every clk_data_i cycle
		elsif rising_edge(clk_data_i) then
		
			--//calculate first 16-sample power
			--//note that buffered_powersum already contains 2 samples, so we need to sum over 8 of these
			instantaneous_avg_power_0(i) <= 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(1*(define_pow_sum_range+1)-1 downto 0)), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(2*(define_pow_sum_range+1)-1 downto 1*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(3*(define_pow_sum_range+1)-1 downto 2*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(4*(define_pow_sum_range+1)-1 downto 3*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(5*(define_pow_sum_range+1)-1 downto 4*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(6*(define_pow_sum_range+1)-1 downto 5*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(7*(define_pow_sum_range+1)-1 downto 6*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(8*(define_pow_sum_range+1)-1 downto 7*(define_pow_sum_range+1))), define_16avg_pow_sum_range));
			
			--//calculate second 16-sample power, overlapping with first sample
			instantaneous_avg_power_1(i) <=
					std_logic_vector(resize(unsigned(buffered_powersum(i)(5*(define_pow_sum_range+1)-1 downto 4*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(6*(define_pow_sum_range+1)-1 downto 5*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(7*(define_pow_sum_range+1)-1 downto 6*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(8*(define_pow_sum_range+1)-1 downto 7*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(9*(define_pow_sum_range+1)-1 downto 8*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(10*(define_pow_sum_range+1)-1 downto 9*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(11*(define_pow_sum_range+1)-1 downto 10*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(12*(define_pow_sum_range+1)-1 downto 11*(define_pow_sum_range+1))), define_16avg_pow_sum_range));	
			
			buffered_powersum(i) <= buffered_powersum(i)(define_num_power_sums*(define_pow_sum_range+1)-1 downto 0) & powersums_i(i);	

		end if;
	end loop;
end process;



end rtl;