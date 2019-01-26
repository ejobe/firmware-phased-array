---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         surface_trigger.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         12/14/2018...
--
-- DESCRIPTION:  surface trigger generation
--               
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
------
use work.defs.all;
use work.register_map.all;
------------------------------------------------------------------------------------------------------------------------------
--
-- surface channel mapping (slave board only):
--   ch3: Vpol1
--   ch4: Vpol2
--   ch5: Vpol3
--   ch6: Hpol1 (bicone)
--   ch7: Hpol2 (LPDA, ~grid EW)
--   ch8: Hpol3 (LPDA, ~grid NS)
--
---------------------------------------------------------------------------------

entity surface_trigger is
	generic(
		ENABLE_SURFACE_TRIGGER : std_logic := '1'); --//compile-time flag
	port(
		rst_i				:	in		std_logic;
		clk_i				:	in		std_logic; --//data clock ~93 MHz
		clk_iface_i		: 	in		std_logic; --//slow logic clock =7.5 MHz
					
		reg_i				: 	in		register_array_type;
		surface_data_i	:	in	   full_data_type;	
	
		trig_o			: 	out	std_logic;
		trig_slow_o		:	out	std_logic);

end surface_trigger;

architecture rtl of surface_trigger is
--//
function vector_or(s : std_logic_vector) return std_logic is
	variable temp : integer := 0;
begin
	for i in s'range loop
		if s(i) = '1' then temp := temp + 1; 
		end if;
	end loop;
  
	if temp > 0 then
		return '1';
	else	
		return '0';
	end if;
end function vector_or;
--//
function vector_sum(s : std_logic_vector) return integer is
	variable temp : integer := 0;
begin
	for i in s'range loop
		if s(i) = '1' then temp := temp + 1; 
		end if;
	end loop;
 
	return temp;
end function vector_sum;
--//
component signal_sync is
port(
	clkA			: in	std_logic;
   clkB			: in	std_logic;
   SignalIn_clkA	: in	std_logic;
   SignalOut_clkB	: out	std_logic);
end component;
component flag_sync is
port(
	clkA			: in	std_logic;
   clkB			: in	std_logic;
   in_clkA		: in	std_logic;
   busy_clkA	: out	std_logic;
   out_clkB		: out	std_logic);
end component;
-- signal definitions
signal internal_vpp_threshold : std_logic_vector(7 downto 0);
signal internal_trig_window_length : std_logic_vector(7 downto 0);
signal internal_trig_mask : std_logic_vector(surface_channels-1 downto 0);
signal internal_trig_min_abv_thresh : std_logic_vector(2 downto 0);
signal internal_trigger_bits : std_logic_vector(surface_channels-1 downto 0);
--
type internal_trigger_bit_counter_type is array(surface_channels-1 downto 0) of std_logic_vector(7 downto 0);
signal internal_trigger_bit_counter : internal_trigger_bit_counter_type;
--
type internal_trigger_bit_state_type is (idle_st, trig_st);
type internal_trigger_bit_state_array_type is array(surface_channels-1 downto 0) of internal_trigger_bit_state_type;
signal internal_trigger_bit_state : internal_trigger_bit_state_array_type;

signal internal_trigger_counter : std_logic_vector(7 downto 0); --//256 clk_i counts max window
signal internal_trig_enable : std_logic;
signal trig : std_logic;
signal trig_clear : std_logic;
--
type surface_trig_state_type is (idle_st, open_window_st, clear_st, check_pol_st, trig_st, holdoff_st);
signal surface_trig_state : surface_trig_state_type;
--
signal buf_data_0 		: 	surface_data_type;
signal buf_data_1 		: 	surface_data_type;

type internal_buf_data_type is array (surface_channels-1 downto 0) of std_logic_vector(2*pdat_size-1 downto 0); 
signal dat : internal_buf_data_type;

signal flag_hi : std_logic_vector(surface_channels-1 downto 0);
signal flag_lo : std_logic_vector(surface_channels-1 downto 0);
type sample_flag_type is array(surface_channels-1 downto 0) of std_logic_vector(4*define_serdes_factor-1 downto 0);
signal sample_flag_hi : sample_flag_type;
signal sample_flag_lo : sample_flag_type;
--
type surface_wfm_pow_type is array(surface_channels-1 downto 0) of std_logic_vector(define_num_power_sums*(define_pow_sum_range+1)-1 downto 0); 
signal surface_wfm_pow : surface_wfm_pow_type;
--
type buffered_powersum_type is array(define_num_beams-1 downto 0) of std_logic_vector(2*define_num_power_sums*(define_pow_sum_range+1)-1 downto 0);
signal buffered_powersum : buffered_powersum_type;	
--
signal instantaneous_avg_power : average_power_16samp_type;  --//defined in defs.vhd
--//
signal hpol_power : std_logic_vector(23 downto 0);
signal vpol_power : std_logic_vector(23 downto 0);
signal internal_require_pol_check_trigger : std_logic;
signal internal_hpol_trig_satisfied : std_logic;
signal internal_hpol_pow_thresh : std_logic_vector(23 downto 0);
--//
begin
--//
------clock in some programmable settings:
--//
GetThreshold	:	 for i in 0 to 7 generate	
	xGET_THRESHOLD : signal_sync
	port map(
		clkA				=> clk_iface_i,
		clkB				=> clk_i,
		SignalIn_clkA	=> reg_i(46)(i), 
		SignalOut_clkB	=> internal_vpp_threshold(i));
end generate;
GetWindow	:	 for i in 0 to 7 generate	
	xGET_WINDOW : signal_sync
	port map(
		clkA				=> clk_iface_i,
		clkB				=> clk_i,
		SignalIn_clkA	=> reg_i(46)(i+8), 
		SignalOut_clkB	=> internal_trig_window_length(i));
end generate;
GetMask	:	 for i in 0 to surface_channels-1 generate	
	xGET_MASK : signal_sync
	port map(
		clkA				=> clk_iface_i,
		clkB				=> clk_i,
		SignalIn_clkA	=> reg_i(46)(i+16), 
		SignalOut_clkB	=> internal_trig_mask(i));
end generate;
GetCondition	:	 for i in 0 to 2 generate	
	xGET_CONDITION : signal_sync
	port map(
		clkA				=> clk_iface_i,
		clkB				=> clk_i,
		SignalIn_clkA	=> reg_i(47)(i), 
		SignalOut_clkB	=> internal_trig_min_abv_thresh(i));
end generate;
xGET_POL_REQUIREMENT : signal_sync
port map(
		clkA				=> clk_iface_i,
		clkB				=> clk_i,
		SignalIn_clkA	=> reg_i(47)(4), 
		SignalOut_clkB	=> internal_require_pol_check_trigger);
HpolPowerThreshold	:	 for i in 0 to 23 generate	
	xHPOL_THRESH: signal_sync
	port map(
		clkA				=> clk_iface_i,
		clkB				=> clk_i,
		SignalIn_clkA	=> reg_i(47)(i), 
		SignalOut_clkB	=> internal_hpol_pow_thresh(i));
end generate;
xENABLE : signal_sync
	port map(
		clkA				=> clk_iface_i,
		clkB				=> clk_i,
		SignalIn_clkA	=> reg_i(47)(16), 
		SignalOut_clkB	=> internal_trig_enable);
xTRIGOUT : flag_sync
	port map(
		clkA 			=> clk_i,
		clkB			=> clk_iface_i,
		in_clkA		=> trig,
		busy_clkA	=> open,
		out_clkB		=> trig_slow_o);
--------------------------------------------
--------- fsm's:
--//
proc_buffer_data : process(rst_i, clk_i, surface_data_i, internal_trig_enable)
begin
	--//loop over trigger channels
	for i in 0 to surface_channels-1 loop
		
		if rst_i = '1' or ENABLE_SURFACE_TRIGGER = '0' then
		
			buf_data_0(i)<= (others=>'0');
			buf_data_1(i)<= (others=>'0');	

			dat(i) <= (others=>'0');
			
		elsif rising_edge(clk_i) and internal_trig_enable = '1' then
			--//buffer data
			dat(i) <= buf_data_0(i) & buf_data_1(i);
		
			buf_data_1(i) <= buf_data_0(i);
			buf_data_0(i) <= surface_data_i(i+2);

		end if;
	end loop;
end process;
--------------//
proc_trigger_bits: process(rst_i, clk_i, dat, internal_vpp_threshold, internal_trig_mask, trig_clear)
begin
	for i in 0 to surface_channels-1 loop
		if rst_i = '1' or ENABLE_SURFACE_TRIGGER = '0' then
			--internal_vpp(i) <= 0;
			internal_trigger_bits(i) <= '0';
			flag_hi(i) <= '0';
			flag_lo(i) <= '0';
			internal_trigger_bit_state (i) <= idle_st;
			
			for j in 0 to 4*define_serdes_factor-1 loop
				sample_flag_hi(i)(j) <= '0';
				sample_flag_lo(i)(j) <= '0';
			end loop;
			
		elsif rising_edge(clk_i) then
			---
			
			case internal_trigger_bit_state(i) is
				when idle_st=>
					internal_trigger_bits(i) <= '0';
					internal_trigger_bit_counter(i) <= (others=>'0');
					
					if flag_hi(i) = '1' and flag_lo(i) = '1'	and internal_trig_mask(i) = '1' then
						internal_trigger_bit_state(i) <= trig_st;
					else
						internal_trigger_bit_state(i) <= idle_st;
					end if;
				---
				when trig_st=>
					internal_trigger_bits(i) <= '1';
					internal_trigger_bit_counter(i) <= internal_trigger_bit_counter(i) + 1;
					if internal_trigger_bit_counter(i) > internal_trig_window_length then
						internal_trigger_bit_state(i) <= idle_st;
					else
						internal_trigger_bit_state(i) <= trig_st;
					end if;
			end case;
			---
			--//--
			flag_hi(i) <= vector_or(sample_flag_hi(i));
			flag_lo(i) <= vector_or(sample_flag_lo(i));
				
			for j in 0 to 4*define_serdes_factor-1 loop
				-- 0x3F is the baseline
				if dat(i)((j+1)*define_word_size-1 downto j*define_word_size) > ((internal_vpp_threshold) + x"3F") then
					sample_flag_hi(i)(j) <= '1';
				else
					sample_flag_hi(i)(j) <= '0';
				end if;
				if dat(i)((j+1)*define_word_size-1 downto j*define_word_size) < ((internal_vpp_threshold) + x"3F") then
					sample_flag_lo(i)(j) <= '1';
				else
					sample_flag_lo(i)(j) <= '0';
				end if;
			end loop;
		

		end if;
		
	end loop;
end process;
--------------//
proc_wfm_power : process(rst_i, clk_i)
begin
	if rst_i = '1' then
		for i in 0 to surface_channels-1 loop
			instantaneous_avg_power(i) <= (others=>'0');
			buffered_powersum(i) 		<= (others=>'0');
		end loop;
		
		hpol_power <= (others=>'0');		
		vpol_power <= (others=>'0');
		internal_hpol_trig_satisfied <= '0';
		
	elsif rising_edge(clk_i) then
		
		if (hpol_power > vpol_power) and (hpol_power > internal_hpol_pow_thresh) then
			internal_hpol_trig_satisfied <= '1';
		else
			internal_hpol_trig_satisfied <= '0';
		end if;
		
		hpol_power <= 	std_logic_vector(resize(unsigned(instantaneous_avg_power(3)), 24)) + 
							std_logic_vector(resize(unsigned(instantaneous_avg_power(4)), 24)) + 
							std_logic_vector(resize(unsigned(instantaneous_avg_power(5)), 24));
		vpol_power <= 	std_logic_vector(resize(unsigned(instantaneous_avg_power(0)), 24)) + 
							std_logic_vector(resize(unsigned(instantaneous_avg_power(1)), 24)) + 
							std_logic_vector(resize(unsigned(instantaneous_avg_power(2)), 24));
							
		for i in 0 to surface_channels-1 loop
			--//power in 32 samples
			instantaneous_avg_power(i) <= 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(1*(define_pow_sum_range+1)-1 downto 0)), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(2*(define_pow_sum_range+1)-1 downto 1*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(3*(define_pow_sum_range+1)-1 downto 2*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(4*(define_pow_sum_range+1)-1 downto 3*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(5*(define_pow_sum_range+1)-1 downto 4*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(6*(define_pow_sum_range+1)-1 downto 5*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(7*(define_pow_sum_range+1)-1 downto 6*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(8*(define_pow_sum_range+1)-1 downto 7*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) +
					std_logic_vector(resize(unsigned(buffered_powersum(i)(9*(define_pow_sum_range+1)-1 downto 8*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(10*(define_pow_sum_range+1)-1 downto 9*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(11*(define_pow_sum_range+1)-1 downto 10*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(12*(define_pow_sum_range+1)-1 downto 11*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) +
					std_logic_vector(resize(unsigned(buffered_powersum(i)(13*(define_pow_sum_range+1)-1 downto 12*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(14*(define_pow_sum_range+1)-1 downto 13*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(15*(define_pow_sum_range+1)-1 downto 14*(define_pow_sum_range+1))), define_16avg_pow_sum_range)) + 
					std_logic_vector(resize(unsigned(buffered_powersum(i)(16*(define_pow_sum_range+1)-1 downto 15*(define_pow_sum_range+1))), define_16avg_pow_sum_range));	
			--//double the vector length so we can add 32 samples
			buffered_powersum(i) <= buffered_powersum(i)(define_num_power_sums*(define_pow_sum_range+1)-1 downto 0) & surface_wfm_pow(i);	
		end loop;
	end if;
end process;

-----------//
prog_gen_trig: process(rst_i, clk_i, internal_trigger_bits, internal_trig_min_abv_thresh)
begin
	if rst_i = '1' or ENABLE_SURFACE_TRIGGER = '0' then
		internal_trigger_counter <= (others=>'0');
		trig <= '0';
		trig_clear <= '0';
		surface_trig_state <= idle_st;
		
	elsif rising_edge(clk_i) then
		-----------
		case surface_trig_state is
			-------------
			when idle_st => 
				internal_trigger_counter <= (others=>'0');
				trig <= '0';
				trig_clear <= '0';
				
				if internal_trigger_bits > 0 then
					surface_trig_state <= open_window_st;
				else
					surface_trig_state <= idle_st;
				end if;
			-------------
			when open_window_st =>
				internal_trigger_counter <= (others=>'0');
				trig <= '0';
				trig_clear <= '0';
						
				--//check if minimum number of channels above threshold
				if (vector_sum(internal_trigger_bits)) >=  to_integer(unsigned(internal_trig_min_abv_thresh)) then
					surface_trig_state <= check_pol_st;
				else
					surface_trig_state <= open_window_st;
				end if;
			-------------
			when clear_st=>
				internal_trigger_counter <= (others=>'0');
				trig <= '0';
				trig_clear <= '1';
				surface_trig_state <= idle_st;
			-------------
			when check_pol_st =>
				internal_trigger_counter <=internal_trigger_counter + 1;
				trig <= '0';
				trig_clear <= '0';
				--if pol check is disabled:
				if internal_require_pol_check_trigger = '0' then
					surface_trig_state <= trig_st;
				--timeout:
				elsif internal_trigger_counter > 8 then
					surface_trig_state <= clear_st;
				--hpol>vpol satisfied:
				elsif internal_hpol_trig_satisfied = '1' then
					surface_trig_state <= trig_st;
				else
					surface_trig_state <= check_pol_st;
				end if;
			-------------
			when trig_st=>
				internal_trigger_counter <= (others=>'0');
				trig <= '1';
				trig_clear <= '0';
				surface_trig_state <= holdoff_st;
			-------------
			when holdoff_st=>
				internal_trigger_counter <=internal_trigger_counter + 1;
				trig <= '0';
				trig_clear <= '0';
				if internal_trigger_counter > 48 then
					surface_trig_state <= clear_st;
				else 
					surface_trig_state <= holdoff_st;
				end if;
		
			when others=> surface_trig_state <= idle_st;
			
		end case;
	end if;
end process;	
				
trig_o <= trig;
--//
SurfacePower	:	 for i in 0 to surface_channels-1 generate
	xPOWER_SUM : entity work.power_detector_single
		port map(
			rst_i  	=> rst_i,
			clk_i	 	=> clk_i,
			reg_i		=> reg_i,
			data_i	=> dat(i)(pdat_size-1 downto 0),
			sum_pow_o=> surface_wfm_pow(i));
end generate;
				
end rtl;