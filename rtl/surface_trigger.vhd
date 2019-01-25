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
type internal_vpp_type is array (surface_channels-1 downto 0) of integer range -1 to 512;
signal internal_vpp: internal_vpp_type;
signal internal_vpp_threshold : std_logic_vector(7 downto 0);
signal internal_trig_window_length : std_logic_vector(7 downto 0);
signal internal_trig_mask : std_logic_vector(surface_channels-1 downto 0);
signal internal_trig_fsm_block : std_logic_vector(surface_channels-1 downto 0);
signal internal_trig_min_abv_thresh : std_logic_vector(2 downto 0);
signal internal_trigger_bits : std_logic_vector(surface_channels-1 downto 0);
signal internal_trigger_count : std_logic_vector(2 downto 0);
signal internal_trigger_counter : std_logic_vector(7 downto 0); --//256 clk_i counts max window
signal internal_trig_enable : std_logic;
signal trig : std_logic;
signal trig_clear : std_logic;
--
type surface_trig_state_type is (idle_st, open_window_st, clear_st, trig_st, holdoff_st);
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
signal surface_wfm_pow : surface_wfm_pow_type

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
			internal_trig_fsm_block(i) <= '0';
			flag_hi(i) <= '0';
			flag_lo(i) <= '0';
			
			for j in 0 to 4*define_serdes_factor-1 loop
				sample_flag_hi(i)(j) <= '0';
				sample_flag_lo(i)(j) <= '0';
			end loop;
			
		elsif rising_edge(clk_i) then
			--internal_vpp(i) <= get_vpp(dat(i));
			--internal_vpp(i) <= 10; 
			
			--if (internal_vpp(i) >= to_integer(unsigned(internal_vpp_threshold)))
			
--			if (internal_vpp(i) > (to_integer(unsigned(internal_vpp_threshold))+1))	and internal_trig_mask(i) = '1' --//mask from sw
--																											and internal_trig_fsm_block(i) = '0' then --//'block', see below
			if flag_hi(i) = '1' and flag_lo(i) = '1'	and internal_trig_mask(i) = '1' --//mask from sw
																	and internal_trig_fsm_block(i) = '0' then --//'block', see below
				internal_trigger_bits(i) <= '1';
			else
				internal_trigger_bits(i) <= '0';
			end if;
			--//----------------------------
			-- this blocks the same channel from re-triggering the state machine that follows. 
			-- It gets reset when the fsm either trigs or resets
			--
			-- latch the block signal:		
			if internal_trigger_bits(i) = '1' then
				internal_trig_fsm_block(i) <= '1';
			-- clear the block signal based on fsm state condition
			elsif trig_clear = '1' then
				internal_trig_fsm_block(i) <= '0';
			else
				internal_trig_fsm_block(i) <= internal_trig_fsm_block(i);
			end if;
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

-----------//
prog_gen_trig: process(rst_i, clk_i, internal_trigger_bits, internal_trig_window_length)
begin
	if rst_i = '1' or ENABLE_SURFACE_TRIGGER = '0' then
		internal_trigger_count <= (others=>'0');
		internal_trigger_counter <= (others=>'0');
		trig <= '0';
		trig_clear <= '0';
		surface_trig_state <= idle_st;
		
	elsif rising_edge(clk_i) then
		-----------
		case surface_trig_state is
			-------------
			when idle_st => 
				internal_trigger_count <= (others=>'0');
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
				internal_trigger_counter <= internal_trigger_counter + 1;
				trig <= '0';
				trig_clear <= '0';
				
				if internal_trigger_bits > 0 then
					internal_trigger_count <= internal_trigger_count + 1;
				end if;
								
				--//check if minimum number of channels above threshold
				if (internal_trigger_count + 1) >= internal_trig_min_abv_thresh then
					surface_trig_state <= trig_st;
				--//check trigger window length, if exceeds settable length goto reset
				elsif internal_trigger_counter >= internal_trig_window_length then
					surface_trig_state <= clear_st;
				else
					surface_trig_state <= open_window_st;
				end if;
			-------------
			when clear_st=>
				internal_trigger_count <= (others=>'0');
				internal_trigger_counter <= (others=>'0');
				trig <= '0';
				trig_clear <= '1';
				surface_trig_state <= idle_st;
			-------------
			when trig_st=>
				internal_trigger_count <= (others=>'0');
				internal_trigger_counter <= (others=>'0');
				trig <= '1';
				trig_clear <= '0';
				surface_trig_state <= holdoff_st;
			-------------
			when holdoff_st=>
				internal_trigger_count <= (others=>'0');
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
	xPOWER_SUM : entity work.power_detector
		port map(
			rst_i  	=> rst_i,
			clk_i	 	=> clk_i,
			reg_i		=> reg_i,
			data_i	=> dat_i(i)(2*define_serdes_factor-1 downto 0),
			sum_pow_o=> surface_wfm_pow(i));
end generate;
				
end rtl;