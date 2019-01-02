---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         trigger_v4.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         6/2017...
--
-- DESCRIPTION:  trigger generation
--               this module takes in the power sums, adds additional smoothing/averaging
--					  compares to threshold
--
--					  ADDED in v2 file [10/2017]: ability to trigger on ONLY the beam with the maximum power, in the cases
--					  with a high SNR pulse that might fire all beams. Add copies of trig flag outputs to send
--					  to another set of scalers with this 'max power' capability
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
------
use work.defs.all;
use work.register_map.all;
------------------------------------------------------------------------------------------------------------------------------
entity trigger_v4 is
	generic(
		ENABLE_PHASED_TRIGGER : std_logic := '1'); --//compile-time flag
	port(
		rst_i				:	in		std_logic;
		clk_data_i		:	in		std_logic; --//data clock ~93 MHz
		clk_iface_i		: 	in		std_logic; --//slow logic clock =7.5 MHz
			
		reg_i				: 	in		register_array_type;		
		powersums_i		:	in		sum_power_type;
		
		data_write_busy_i	:	in	std_logic; --//prevent triggers if triggered event is already being written to ram
		 
		last_trig_pow_o	:	inout	average_power_16samp_type; 
		 
		trig_beam_o						:	out	std_logic_vector(define_num_beams-1 downto 0); --//for scalers

		trig_clk_data_o				:	inout	std_logic;  --//trig flag on faster clock
		trig_clk_data_copy_o			:	out	std_logic;  --//trig flag on faster clock, delayed by one clk cycle
		last_trig_beam_clk_data_o 	: 	inout std_logic_vector(define_num_beams-1 downto 0); --//register the beam trigger 
		trig_clk_iface_o				:	out	std_logic); --//trigger on clk_iface_i [trig_o is high for one clk_iface_i cycle (use for scalers)]
		
end trigger_v4;
------------------------------------------------------------------------------------------------------------------------------
architecture rtl of trigger_v4 is
------------------------------------------------------------------------------------------------------------------------------
type buffered_powersum_type is array(define_num_beams-1 downto 0) of 
	std_logic_vector(2*define_num_power_sums*(define_pow_sum_range+1)-1 downto 0);

signal buffered_powersum : buffered_powersum_type;
signal instantaneous_avg_power_0 : average_power_16samp_type;  --//defined in defs.vhd
signal instantaneous_avg_power_1 : average_power_16samp_type;  --//defined in defs.vhd

signal instant_power_0_buf : average_power_16samp_type;
signal instant_power_1_buf : average_power_16samp_type;
signal instant_power_0_buf2 : average_power_16samp_type;
signal instant_power_1_buf2 : average_power_16samp_type;
signal instant_power_0_buf3 : average_power_16samp_type;
signal instant_power_1_buf3 : average_power_16samp_type;
signal instant_power_0_buf4 : average_power_16samp_type;
signal instant_power_1_buf4 : average_power_16samp_type;

signal instantaneous_above_threshold	:	std_logic_vector(define_num_beams-1 downto 0); --//check if beam above threshold at each clk_data_i edge
signal instantaneous_above_threshold_buf	:	std_logic_vector(define_num_beams-1 downto 0); 
signal internal_last_trig_latched_beam_pattern :  std_logic_vector(define_num_beams-1 downto 0);
signal internal_last_trig_latched_beam_pattern_buf :  std_logic_vector(define_num_beams-1 downto 0);

signal thresholds_meta : average_power_16samp_type;
signal thresholds  : average_power_16samp_type;
signal internal_trig_en_reg : std_logic_vector(2 downto 0) := (others=>'0'); --//for clk transfer

--//here's the trigger state machine, which looks for power-above-threshold in each beam and checks for stuck-on beams
type trigger_state_machine_state_type is (idle_st, trig_high_st, trig_hold_1_st, trig_hold_2_st, trig_done_st);
type trigger_state_machine_state_array_type is array(define_num_beams-1 downto 0) of trigger_state_machine_state_type;
signal trigger_state_machine_state : trigger_state_machine_state_array_type;

signal trigger_holdoff_counter	  : std_logic_vector(15 downto 0);
signal internal_trig_holdoff_count : std_logic_vector(15 downto 0);
signal internal_global_trigger_holdoff : std_logic; --//OR of all the bits in the internal_per_beam_trigger_holdoff

signal internal_data_manager_write_busy_reg : std_logic_vector(2 downto 0) := (others=>'0');

signal internal_trig_pow_latch_0 : std_logic_vector(define_num_beams-1 downto 0) := (others=>'0'); --//flag to record last beam power values
signal internal_trig_pow_latch_1 : std_logic_vector(define_num_beams-1 downto 0) := (others=>'0'); --//flag to record last beam power values
signal internal_trig_pow_latch_0_reg : std_logic_vector(1 downto 0) := (others=>'0');
signal internal_trig_pow_latch_1_reg : std_logic_vector(1 downto 0) := (others=>'0');

signal internal_trigger_beam_mask :  std_logic_vector(define_num_beams-1 downto 0);

signal internal_trig_clk_data : std_logic;

--//trig verification signals (new in v2 trig module)
type trig_verification_state_type is (idle_st, trig_start_st, trig_verify_1_st, trig_verify_2_st, trig_high_st, trig_hold_st, done_st);
signal trig_verification_state : trig_verification_state_type;
signal verfication_trig_flag : std_logic;
signal internal_trig_verification_mode : std_logic := '1';
signal verification_counter : std_logic_vector(3 downto 0);
signal verification_current_max_beam : std_logic_vector(3 downto 0);
signal verified_latched_trig_beam : std_logic_vector(define_num_beams-1 downto 0);
signal verified_instantaneous_above_threshold : std_logic_vector(define_num_beams-1 downto 0);
signal verified_instantaneous_above_threshold_buf : std_logic_vector(define_num_beams-1 downto 0);
signal verified_instantaneous_above_threshold_buf2 : std_logic_vector(define_num_beams-1 downto 0);
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
component flag_sync is
port(
	clkA			: in	std_logic;
   clkB			: in	std_logic;
   in_clkA		: in	std_logic;
   busy_clkA	: out	std_logic;
   out_clkB		: out	std_logic);
end component;
component signal_sync is
port(
	clkA			: in	std_logic;
   clkB			: in	std_logic;
   SignalIn_clkA	: in	std_logic;
   SignalOut_clkB	: out	std_logic);
end component;
-------------------------------------------------------------------------------------
begin
-------------------------------------------------------------------------------------
TrigMaskSync : for i in 0 to define_num_beams-1 generate
	xTRIGMASKSYNC : signal_sync
	port map(
		clkA				=> clk_iface_i,
		clkB				=> clk_data_i,
		SignalIn_clkA	=> reg_i(80)(i), --//reg 80 has the beam mask
		SignalOut_clkB	=> internal_trigger_beam_mask(i));
end generate;
-------------------------------------------------------------------------------------
TrigHoldoffSync : for i in 0 to 15 generate
	xTRIGHOLDOFFSYNC : signal_sync
	port map(
		clkA				=> clk_iface_i,
		clkB				=> clk_data_i,
		SignalIn_clkA	=> reg_i(81)(i), --//reg 81 has the programmable trig holdoff (lowest 16 bits)
		SignalOut_clkB	=> internal_trig_holdoff_count(i));
end generate;
-------------------------------------------------------------------------------------	
xTRIGHOLDOFFMODESYNC : signal_sync
port map(
	clkA				=> clk_iface_i,
	clkB				=> clk_data_i,
	SignalIn_clkA	=> reg_i(85)(0), 
	SignalOut_clkB	=> internal_trig_verification_mode);
-------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////
-------------------------------------------------------------------------------------
proc_clk_xfer : process(clk_data_i, reg_i, internal_trig_en_reg)
begin
	if rising_edge(clk_data_i) then
		for i in 0 to define_num_beams-1 loop
			thresholds(i) <= thresholds_meta(i);
			thresholds_meta(i)  <= reg_i(base_adrs_trig_thresh+i)(define_16avg_pow_sum_range-1 downto 0);
		end loop;
		internal_trig_en_reg <= internal_trig_en_reg(1 downto 0) & reg_i(82)(0); --//phased trig enable
	end if;
end process;
-------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////
-------------------------------------------------------------------------------------
proc_get_last_beam_trigger_pattern : process(rst_i, clk_data_i, internal_last_trig_latched_beam_pattern, data_write_busy_i, 
															internal_data_manager_write_busy_reg, internal_trig_pow_latch_0_reg, internal_trig_pow_latch_1_reg)
begin	
	if rst_i = '1' then
		internal_last_trig_latched_beam_pattern_buf <= (others=>'0');
		for i in 0 to define_num_beams-1 loop
			last_trig_pow_o(i) <= (others=>'0');
		end loop;
		internal_trig_pow_latch_0_reg <= (others=>'0');
		internal_trig_pow_latch_1_reg <= (others=>'0');
		internal_data_manager_write_busy_reg <= (others=>'0');
		verfication_trig_flag <= '0';
	---------------------------------------------------------------------------------------------
	elsif rising_edge(clk_data_i) then
	
		--save last trig beam powers
		internal_trig_pow_latch_0_reg(1) <= internal_trig_pow_latch_0_reg(0);
		internal_trig_pow_latch_1_reg(1) <= internal_trig_pow_latch_1_reg(0);
		
		internal_trig_pow_latch_0_reg(0) <= internal_trig_pow_latch_0(0) or internal_trig_pow_latch_0(1) or internal_trig_pow_latch_0(2) or
													internal_trig_pow_latch_0(3) or internal_trig_pow_latch_0(4) or internal_trig_pow_latch_0(5) or
													internal_trig_pow_latch_0(6) or internal_trig_pow_latch_0(7) or internal_trig_pow_latch_0(8) or
													internal_trig_pow_latch_0(9) or internal_trig_pow_latch_0(10) or internal_trig_pow_latch_0(11) or
													internal_trig_pow_latch_0(12) or internal_trig_pow_latch_0(13) or internal_trig_pow_latch_0(14);
		internal_trig_pow_latch_1_reg(0) <= internal_trig_pow_latch_1(0) or internal_trig_pow_latch_1(1) or internal_trig_pow_latch_1(2) or
													internal_trig_pow_latch_1(3) or internal_trig_pow_latch_1(4) or internal_trig_pow_latch_1(5) or
													internal_trig_pow_latch_1(6) or internal_trig_pow_latch_1(7) or internal_trig_pow_latch_1(8) or
													internal_trig_pow_latch_1(9) or internal_trig_pow_latch_1(10) or internal_trig_pow_latch_1(11) or
													internal_trig_pow_latch_1(12) or internal_trig_pow_latch_1(13) or internal_trig_pow_latch_1(14);
													
		if internal_trig_pow_latch_0_reg = "01" then
			last_trig_pow_o <= instant_power_0_buf2;
			internal_last_trig_latched_beam_pattern_buf <= internal_last_trig_latched_beam_pattern; --//register the triggered beam pattern
			verfication_trig_flag <= '1';
		elsif internal_trig_pow_latch_1_reg = "01" then
			last_trig_pow_o <= instant_power_1_buf2;
			internal_last_trig_latched_beam_pattern_buf <= internal_last_trig_latched_beam_pattern; --//register the triggered beam pattern
			verfication_trig_flag <= '1';
		else
			verfication_trig_flag <= '0';
		end if;
	
	end if;
end process;
------------------------------------------------------------------------------------------------------------------------------
--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
------------------------------------------------------------------------------------------------------------------------------
proc_trig_verify : process(rst_i, clk_data_i, thresholds, verfication_trig_flag, last_trig_pow_o, internal_trig_holdoff_count,
									internal_last_trig_latched_beam_pattern_buf)
begin
	if rst_i = '1' then
		internal_global_trigger_holdoff <= '0';
		trigger_holdoff_counter <= (others=>'0');
		-----------------
		verified_instantaneous_above_threshold <= (others=>'0');
		verified_instantaneous_above_threshold_buf <= (others=>'0');
		verified_instantaneous_above_threshold_buf2 <= (others=>'0');
		-----------------
		last_trig_beam_clk_data_o <= (others=>'0');
		verification_counter <= (others=>'0');
		verification_current_max_beam <= (others=>'0');
		verified_latched_trig_beam <= (others=>'0');
		trig_verification_state <= idle_st;
	---------------------------------------------------------------------------------------------
	elsif rising_edge(clk_data_i) then
		verified_instantaneous_above_threshold_buf2 <= verified_instantaneous_above_threshold_buf;
		verified_instantaneous_above_threshold_buf <= verified_instantaneous_above_threshold;
		--////////////////////////////////////////////////////////////////////////////
		case trig_verification_state is		
			
			when idle_st=>
				internal_global_trigger_holdoff <= '0';
				trigger_holdoff_counter <= (others=>'0');
				verification_counter <= (others=>'0');
				verified_instantaneous_above_threshold <= (others=>'0');
				verification_current_max_beam <= (others=>'0');
				
				if verfication_trig_flag = '1' then
					trig_verification_state <= trig_start_st;
				else
					trig_verification_state <= idle_st;
				end if;
					
			--/ assign trigger to beam with max power
			when trig_start_st =>
				internal_global_trigger_holdoff <= '1';
				trigger_holdoff_counter <= (others=>'0');
				verification_counter <= (others=>'0');
				verification_current_max_beam <= (others=>'0');

				case internal_trig_verification_mode is 
					when '0' =>
						verified_instantaneous_above_threshold <= internal_last_trig_latched_beam_pattern_buf;
						trig_verification_state <= trig_high_st;
					
					when '1' =>
						verified_instantaneous_above_threshold <= (others=>'0');
						trig_verification_state <= trig_verify_1_st;
				end case;
			
			--// loop thru beams, find beam w/ max power
			------- this adds 5 extra clk_data_i cycles to trigger (assumes 15 beams, need adjusted if define_num_beams changes.. 0--
			when trig_verify_1_st =>
				internal_global_trigger_holdoff <= '1';
				trigger_holdoff_counter <= (others=>'0');

				verified_instantaneous_above_threshold <= (others=>'0');
				
				--//added 2/21/2018: check 2 beams per clock cycle to reduce output latency (see trigger_v2.vhd for previous FSM
				
				if (last_trig_pow_o(to_integer(unsigned(verification_counter))+2) > last_trig_pow_o(to_integer(unsigned(verification_current_max_beam)))) and
							(last_trig_pow_o(to_integer(unsigned(verification_counter))+2) > (last_trig_pow_o(to_integer(unsigned(verification_counter))+1)))  then
					verification_current_max_beam <= (verification_counter + 2);			

				elsif last_trig_pow_o(to_integer(unsigned(verification_counter))+1) > last_trig_pow_o(to_integer(unsigned(verification_current_max_beam))) then
					verification_current_max_beam <= (verification_counter + 1);
				
				else
					verification_current_max_beam <= verification_current_max_beam;
				end if;

				if verification_counter = (define_num_beams-3) then 
					verification_counter <= (others=>'0');
					trig_verification_state <= trig_verify_2_st;
				else
					verification_counter <= verification_counter +2;
					trig_verification_state <= trig_verify_1_st;
				end if;
			
			--// verify beam with max power is above threshold
			------- this adds another clk_data_i cycle, for 15 clk_data_i total cycles longer than over non-verified trigger
			when trig_verify_2_st =>
				internal_global_trigger_holdoff <= '1';
				trigger_holdoff_counter <= (others=>'0');
				verification_counter <= (others=>'0');

				if last_trig_pow_o(to_integer(unsigned(verification_current_max_beam))) >= thresholds(to_integer(unsigned(verification_current_max_beam))) then
					verified_instantaneous_above_threshold(to_integer(unsigned(verification_current_max_beam))) <= '1';
					trig_verification_state <= trig_high_st;
				else
					verified_instantaneous_above_threshold <= (others=>'0');
					trig_verification_state <= idle_st;
				end if;
										
			when trig_high_st =>
				last_trig_beam_clk_data_o <= verified_instantaneous_above_threshold;
				--verified_instantaneous_above_threshold <= verified_instantaneous_above_threshold; --//trigger still high
				internal_global_trigger_holdoff <= '1';
				trigger_holdoff_counter <= (others=>'0');
				verification_counter <= (others=>'0');

				trig_verification_state <= trig_hold_st;

			when trig_hold_st=>
				verified_instantaneous_above_threshold <= (others=>'0');
				internal_global_trigger_holdoff <= '1';
				verification_counter <= (others=>'0');
				
				if trigger_holdoff_counter = internal_trig_holdoff_count then
					trigger_holdoff_counter <= (others=>'0');
					trig_verification_state <= done_st;	
				elsif trigger_holdoff_counter = x"FFFF" then --// max hold off 2^16 * 1/(93 MHz) ~ 700 microsecs
					trigger_holdoff_counter <= (others=>'0');
					trig_verification_state <= done_st;			
				else
					trigger_holdoff_counter <= trigger_holdoff_counter + 1;
					trig_verification_state <= trig_hold_st;
				end if;
				
			when done_st =>
				verified_instantaneous_above_threshold <= (others=>'0');
				internal_global_trigger_holdoff <= '0';
				verification_counter <= (others=>'0');
				verification_current_max_beam <= (others=>'0');
				trig_verification_state <= idle_st;
		end case;
	end if;
end process;
------------------------------------------------------------------------------------------------------------------------------
--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
------------------------------------------------------------------------------------------------------------------------------
proc_buf_powsum : process(rst_i, clk_data_i, data_write_busy_i, internal_trig_en_reg, internal_trig_holdoff_count, internal_global_trigger_holdoff,
									instantaneous_avg_power_0, instantaneous_avg_power_1, thresholds)
begin
	for i in 0 to define_num_beams-1 loop
		if rst_i = '1' or ENABLE_PHASED_TRIGGER = '0' then
			instantaneous_avg_power_0(i) <= (others=>'0');
			instantaneous_avg_power_1(i) <= (others=>'0');
			instant_power_0_buf(i) <= (others=>'0');
			instant_power_1_buf(i) <= (others=>'0');
			instant_power_0_buf2(i) <= (others=>'0');
			instant_power_1_buf2(i) <= (others=>'0');
			instant_power_0_buf3(i) <= (others=>'0');
			instant_power_1_buf3(i) <= (others=>'0');		
			instant_power_0_buf4(i) <= (others=>'0');
			instant_power_1_buf4(i) <= (others=>'0');	
			
			internal_last_trig_latched_beam_pattern(i) <= '0';
			
			instantaneous_above_threshold(i) <= '0';
			instantaneous_above_threshold_buf(i) <= '0';
			
			internal_trig_pow_latch_0(i) <= '0';  --//flag to record last beam power values
			internal_trig_pow_latch_1(i) <= '0';  --//flag to record last beam power values

			buffered_powersum(i) <= (others=>'0');
			
			trigger_state_machine_state(i) 	<= idle_st;
		
		elsif rising_edge(clk_data_i) and internal_trig_en_reg(2) = '0' then
			instantaneous_avg_power_0(i) <= (others=>'0');
			instantaneous_avg_power_1(i) <= (others=>'0');
			instant_power_0_buf(i) <= (others=>'0');
			instant_power_1_buf(i) <= (others=>'0');
			instant_power_0_buf2(i) <= (others=>'0');
			instant_power_1_buf2(i) <= (others=>'0');
			instant_power_0_buf3(i) <= (others=>'0');
			instant_power_1_buf3(i) <= (others=>'0');	
			instant_power_0_buf4(i) <= (others=>'0');
			instant_power_1_buf4(i) <= (others=>'0');				
			
			internal_last_trig_latched_beam_pattern(i) <= '0';
			
			instantaneous_above_threshold(i) <= '0';
			instantaneous_above_threshold_buf(i) <= '0';
			
			internal_trig_pow_latch_0(i) <= '0';
			internal_trig_pow_latch_1(i) <= '0';
			
			buffered_powersum(i) <= (others=>'0');
			
			trigger_state_machine_state(i) 	<= idle_st;
		
		--//there are 16 samples every clock cycle. We want to calculate the power in 16 sample units every 8 samples.
		--//So that's two power calculations every clk_data_i cycle
		elsif rising_edge(clk_data_i) then
			instant_power_0_buf4(i) <= instant_power_0_buf3(i);
			instant_power_1_buf4(i) <= instant_power_1_buf3(i);
			instant_power_0_buf3(i) <= instant_power_0_buf2(i);
			instant_power_1_buf3(i) <= instant_power_1_buf2(i);
			instant_power_0_buf2(i) <= instant_power_0_buf(i);
			instant_power_1_buf2(i) <= instant_power_1_buf(i);
			instant_power_0_buf(i) <= instantaneous_avg_power_0(i);
			instant_power_1_buf(i) <= instantaneous_avg_power_1(i);
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
			
			instantaneous_above_threshold_buf(i)	<= instantaneous_above_threshold(i);
			--/////////////////////////////////////////////////
			--// THE TRIGGER
			case trigger_state_machine_state(i) is
			
				--//waiting for trigger
				when idle_st => 
					internal_trig_pow_latch_0(i) <= '0';
					internal_trig_pow_latch_1(i) <= '0';
					internal_last_trig_latched_beam_pattern(i) <= '0';

					if data_write_busy_i = '1' or internal_global_trigger_holdoff = '1' then
						instantaneous_above_threshold(i) <= '0';
						trigger_state_machine_state(i) <= idle_st;
					
					elsif instantaneous_avg_power_0(i) > thresholds(i) then
						instantaneous_above_threshold(i) <= '1'; --// high for two clk_data_i cycles
						-----------FLAG power in sum 0 ------------------------
						internal_trig_pow_latch_0(i) <= '1';
						--------------------------------------------------------
						trigger_state_machine_state(i) <= trig_high_st;
						
					elsif instantaneous_avg_power_1(i) > thresholds(i) then
						instantaneous_above_threshold(i) <= '1'; --// high for two clk_data_i cycles
						-----------FLAG power in sum 1 ------------------------
						internal_trig_pow_latch_1(i) <= '1';
						--------------------------------------------------------
						trigger_state_machine_state(i) <= trig_high_st;
						
					else
						instantaneous_above_threshold(i) <= '0';
						trigger_state_machine_state(i) <= idle_st;
					end if;
					
				when trig_high_st =>
					internal_last_trig_latched_beam_pattern(i) <= '1'; --//active for holdoff cycle
					instantaneous_above_threshold(i) <= '1';
					trigger_state_machine_state(i) <= trig_hold_1_st;
					
				--//indiv beam small trig hold off
				when trig_hold_1_st =>
					internal_trig_pow_latch_0(i) <= '0';
					internal_trig_pow_latch_1(i) <= '0';
					instantaneous_above_threshold(i) <= '0';
					trigger_state_machine_state(i) <= trig_hold_2_st;
				
				when trig_hold_2_st =>
					internal_trig_pow_latch_0(i) <= '0';
					internal_trig_pow_latch_1(i) <= '0';
					instantaneous_above_threshold(i) <= '0';
					trigger_state_machine_state(i) <= trig_done_st;

				--//trig done, go back to idle_st
				when trig_done_st =>
					internal_trig_pow_latch_0(i) <= '0';
					internal_trig_pow_latch_1(i) <= '0';
					instantaneous_above_threshold(i) <= '0';
					trigger_state_machine_state(i) <= idle_st;
			
			end case;

		end if;
	end loop;
end process;
------------------------------------------------------------------------------------------------------------------------------
process(clk_data_i, rst_i)
begin
	if rst_i = '1'  or ENABLE_PHASED_TRIGGER = '0' then
		internal_trig_clk_data <= '0';
		trig_clk_data_o <= '0';
		trig_clk_data_copy_o <= '0';
	elsif rising_edge(clk_data_i) then
		trig_clk_data_copy_o   <=  trig_clk_data_o;
		internal_trig_clk_data <=  trig_clk_data_o;
		trig_clk_data_o	<=	(verified_instantaneous_above_threshold(0) and internal_trigger_beam_mask(0)) or
									(verified_instantaneous_above_threshold(1) and internal_trigger_beam_mask(1)) or
									(verified_instantaneous_above_threshold(2) and internal_trigger_beam_mask(2)) or
									(verified_instantaneous_above_threshold(3) and internal_trigger_beam_mask(3)) or
									(verified_instantaneous_above_threshold(4) and internal_trigger_beam_mask(4)) or
									(verified_instantaneous_above_threshold(5) and internal_trigger_beam_mask(5)) or
									(verified_instantaneous_above_threshold(6) and internal_trigger_beam_mask(6)) or
									(verified_instantaneous_above_threshold(7) and internal_trigger_beam_mask(7)) or
									(verified_instantaneous_above_threshold(8) and internal_trigger_beam_mask(8)) or
									(verified_instantaneous_above_threshold(9) and internal_trigger_beam_mask(9)) or
									(verified_instantaneous_above_threshold(10) and internal_trigger_beam_mask(10)) or
									(verified_instantaneous_above_threshold(11) and internal_trigger_beam_mask(11)) or
									(verified_instantaneous_above_threshold(12) and internal_trigger_beam_mask(12)) or
									(verified_instantaneous_above_threshold(13) and internal_trigger_beam_mask(13)) or
									(verified_instantaneous_above_threshold(14) and internal_trigger_beam_mask(14));
	end if;
end process;
------------------------------------------------------------------------------------------------------------------------------
--/////////////////////////////////////////////////////
--/////////////////////////////////////////////////////
--//now, sync beam triggers to slower clock
--//note, these do not get masked, in order to keep counting in scalers
--TrigSync	:	 for i in 0 to define_num_beams-1 generate
--	xBEAMTRIGSYNC : flag_sync
--	port map(
--		clkA 			=> clk_data_i,
--		clkB			=> clk_iface_i,
--		in_clkA		=> instantaneous_above_threshold_buf(i),
--		busy_clkA	=> open,
--		out_clkB		=> trig_beam_o(i));
--end generate TrigSync;
VerifiedTrigSync	:	 for i in 0 to define_num_beams-1 generate
	xBEAMTRIGSYNC : flag_sync
	port map(
		clkA 			=> clk_data_i,
		clkB			=> clk_iface_i,
		in_clkA		=> verified_instantaneous_above_threshold_buf2(i),
		busy_clkA	=> open,
		out_clkB		=> trig_beam_o(i));
end generate VerifiedTrigSync;
------------------------------------------------------------------------------------------------------------------------------
xTRIGSYNC : flag_sync
	port map(
		clkA 			=> clk_data_i,
		clkB			=> clk_iface_i,
		in_clkA		=> internal_trig_clk_data,
		busy_clkA	=> open,
		out_clkB		=> trig_clk_iface_o); --//trig_o is high for one clk_iface_i cycle (use for scalers and to send off-board)

--//////////////////////
end rtl;