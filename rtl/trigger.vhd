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
		
		beam_trigger_out	:	out	std_logic_vector(define_num_beams-1 downto 0);
		
		trig_clk_data_o	:	inout	std_logic;  --//trig flag on faster clock
		trig_o				:	out	std_logic); --//trigger on clk_iface_i
		
end trigger;

architecture rtl of trigger is

type buffered_powersum_type is array(define_num_beams-1 downto 0) of 
	std_logic_vector(2*define_num_power_sums*(define_pow_sum_range+1)-1 downto 0);

signal buffered_powersum : buffered_powersum_type;
signal instantaneous_avg_power_0 : average_power_16samp_type;  --//defined in defs.vhd
signal instantaneous_avg_power_1 : average_power_16samp_type;  --//defined in defs.vhd

signal instantaneous_above_threshold	:	std_logic_vector(define_num_beams-1 downto 0); --//check if beam above threshold at each clk_data_i edge
signal thresholds  : average_power_16samp_type;

--//here's the trigger state machine, which looks for power-above-threshold in each beam and checks for stuck-on beams
type trigger_state_machine_state_type is (idle_st, trig_hold_st, trig_done_st);
type trigger_state_machine_state_array_type is array(define_num_beams-1 downto 0) of trigger_state_machine_state_type;
signal trigger_state_machine_state : trigger_state_machine_state_array_type;

type trig_hold_counter_type is array(define_num_beams-1 downto 0) of std_logic_vector(7 downto 0);
signal trigger_holdoff_counter		:	trig_hold_counter_type;

component flag_sync is
port(
	clkA			: in	std_logic;
   clkB			: in	std_logic;
   in_clkA		: in	std_logic;
   busy_clkA	: out	std_logic;
   out_clkB		: out	std_logic);
end component;

begin

proc_get_thresholds : process(clk_data_i, reg_i)
begin
	for i in 0 to define_num_beams-1 loop
		if rising_edge(clk_data_i) then
			thresholds(i)  <= reg_i(base_adrs_trig_thresh+i)(define_16avg_pow_sum_range-1 downto 0);
		end if;
	end loop;
end process;

proc_buf_powsum : process(rst_i, clk_data_i)
begin
	for i in 0 to define_num_beams-1 loop
		if rst_i = '1' then
			instantaneous_avg_power_0(i) <= (others=>'0');
			instantaneous_avg_power_1(i) <= (others=>'0');
			
			buffered_powersum(i) <= (others=>'0');
			
			trigger_state_machine_state(i) 	<= idle_st;
			trigger_holdoff_counter(i) 		<= (others=>'0');
		
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
			
			--/////////////////////////////////////////////////
			--// THE TRIGGER
			case trigger_state_machine_state(i) is
			
				--//waiting for trigger
				when idle_st => 
					trigger_holdoff_counter(i) <= (others=>'0');
				
					if (instantaneous_avg_power_0(i) > thresholds(i)) or (instantaneous_avg_power_1(i) > thresholds(i)) then
						instantaneous_above_threshold(i) <= '1'; --// high for one clk_data_i cycle
						trigger_state_machine_state(i) <= trig_hold_st;
						
					else
						instantaneous_above_threshold(i) <= '0';
						trigger_state_machine_state(i) <= idle_st;
					end if;
					
				--//keep trig high for a bit
				when trig_hold_st =>
					instantaneous_above_threshold(i) <= '0';
					
					--//need to limit trigger burst rate in order to register on 15MHz interface clock
					if trigger_holdoff_counter(i) = x"0F" then
						trigger_holdoff_counter(i) <= (others=>'0');
						trigger_state_machine_state(i) <= trig_done_st;
						
					else
						trigger_holdoff_counter(i) <= trigger_holdoff_counter(i) + 1;
						trigger_state_machine_state(i) <= trig_hold_st;
					end if;
					
				--//trig done, go back to idle_st
				when trig_done_st =>
					instantaneous_above_threshold(i) <= '0';
					trigger_holdoff_counter(i) <= (others=>'0');
					trigger_state_machine_state(i) <= idle_st;
			
			end case;

		end if;
	end loop;
end process;

process(clk_data_i, rst_i)
begin
	if rst_i = '1' then
		trig_clk_data_o <= '0';
	elsif rising_edge(clk_data_i) then
		
		trig_clk_data_o	<=	(instantaneous_above_threshold(0) and reg_i(80)(0)) or
									(instantaneous_above_threshold(1) and reg_i(80)(1)) or
									(instantaneous_above_threshold(2) and reg_i(80)(2)) or
									(instantaneous_above_threshold(3) and reg_i(80)(3)) or
									(instantaneous_above_threshold(4) and reg_i(80)(4)) or
									(instantaneous_above_threshold(5) and reg_i(80)(5)) or
									(instantaneous_above_threshold(6) and reg_i(80)(6)) or
									(instantaneous_above_threshold(7) and reg_i(80)(7)) or
									(instantaneous_above_threshold(8) and reg_i(80)(8)) or
									(instantaneous_above_threshold(9) and reg_i(80)(9)) or
									(instantaneous_above_threshold(10) and reg_i(80)(10)) or
									(instantaneous_above_threshold(11) and reg_i(80)(11)) or
									(instantaneous_above_threshold(12) and reg_i(80)(12)) or
									(instantaneous_above_threshold(13) and reg_i(80)(13)) or
									(instantaneous_above_threshold(14) and reg_i(80)(14));
	end if;
end process;

--/////////////////////////////////////////////////////
--/////////////////////////////////////////////////////
--//now, sync beam triggers to slower clock
--//note, these do not get masked, in order to keep counting in scalers
TrigSync	:	 for i in 0 to define_num_beams-1 generate
	xBEAMTRIGSYNC : flag_sync
	port map(
		clkA 			=> clk_data_i,
		clkB			=> clk_iface_i,
		in_clkA		=> instantaneous_above_threshold(i),
		busy_clkA	=> open,
		out_clkB		=> beam_trigger_out(i));
end generate TrigSync;

xTRIGSYNC : flag_sync
	port map(
		clkA 			=> clk_data_i,
		clkB			=> clk_iface_i,
		in_clkA		=> trig_clk_data_o,
		busy_clkA	=> open,
		out_clkB		=> trig_o);

--//////////////////////
end rtl;