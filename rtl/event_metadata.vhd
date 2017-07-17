---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         event_metadata.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         3/2017
--
-- DESCRIPTION:  manage metadata for an event
--               
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

entity event_metadata is
	port(
		rst_i				:	in		std_logic;
		clk_i				:	in		std_logic;
		clk_iface_i		:	in		std_logic;
		
		clk_refrsh_i	:	in		std_logic; --//clock to refresh dead-time counter (1 Hz, pulsed on clk_iface_i)
		
		buffers_full_i	:	in		std_logic; --//for dead-time counting
		trig_i			:	in		std_logic; --//for event counting and time-stamping
		trig_type_i		:	in		std_logic_vector(1 downto 0);
		trig_last_beam_i :  in		std_logic_vector(define_num_beams-1 downto 0);
		last_trig_pow_i : in	average_power_16samp_type;
		
		get_metadata_i	:	in		std_logic_vector(define_num_wfm_buffers-1 downto 0); --//pulse determines when to register metadata 
		
		reg_i				:	in		register_array_type;
				
		event_header_o	:	out	event_metadata_type);
		
end event_metadata;


architecture rtl of event_metadata is

type internal_header_type is array(define_num_wfm_buffers-1 downto 0) of std_logic_vector(23 downto 0);
signal internal_header_0 : internal_header_type;
signal internal_header_1 : internal_header_type;
signal internal_header_2 : internal_header_type;
signal internal_header_3 : internal_header_type;
signal internal_header_4 : internal_header_type;
signal internal_header_5 : internal_header_type;
signal internal_header_6 : internal_header_type;
signal internal_header_7 : internal_header_type;
signal internal_header_8 : internal_header_type;
signal internal_header_9 : internal_header_type;
--//power:
signal internal_header_10 : internal_header_type;
signal internal_header_11 : internal_header_type;
signal internal_header_12 : internal_header_type;
signal internal_header_13 : internal_header_type;
signal internal_header_14 : internal_header_type;
signal internal_header_15 : internal_header_type;
signal internal_header_16 : internal_header_type;
signal internal_header_17 : internal_header_type;
signal internal_header_18 : internal_header_type;
signal internal_header_19 : internal_header_type;
signal internal_header_20 : internal_header_type;
signal internal_header_21 : internal_header_type;
signal internal_header_22 : internal_header_type;
signal internal_header_23 : internal_header_type;
signal internal_header_24 : internal_header_type;
--//

signal internal_buffer_full : std_logic; 
signal internal_deadtime_counter : std_logic_vector(23 downto 0);
signal internal_get_meta_data : std_logic_vector(define_num_wfm_buffers-1 downto 0);
signal internal_trig : std_logic;

signal internal_next_event_counter : std_logic_vector(47 downto 0);
signal internal_trig_counter : std_logic_vector(47 downto 0);

signal internal_running_timestamp : std_logic_vector(47 downto 0);
signal internal_event_timestamp : std_logic_vector(47 downto 0);

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
component scaler --// for dead-time counter
generic(
	WIDTH  : integer := 24);
port(
	rst_i 		: in 	std_logic;
	clk_i			: in	std_logic;
	refresh_i	: in	std_logic;
	count_i		: in	std_logic;
	scaler_o		: out std_logic_vector(23 downto 0));
end component;
--//
begin
--//
xTRIGSYNC : flag_sync
	port map(
		clkA 			=> clk_i,
		clkB			=> clk_iface_i,
		in_clkA		=> trig_i,
		busy_clkA	=> open,
		out_clkB		=> internal_trig);

GetMetaData : for i in 0 to define_num_wfm_buffers-1 generate
	xGETMETADATA : flag_sync
	port map(
		clkA 			=> clk_i,
		clkB			=> clk_iface_i,
		in_clkA		=> get_metadata_i(i),
		busy_clkA	=> open,
		out_clkB		=> internal_get_meta_data(i));
end generate;
	
xBUFFERFULLSYNC : signal_sync 
port map(
	clkA 			=> clk_i,
	clkB			=> clk_iface_i,
	SignalIn_clkA		=> buffers_full_i,
	SignalOut_clkB		=> internal_buffer_full);
		
xDEADTIMECOUNTER : scaler
generic map(
	WIDTH => 24)
port map(
	rst_i => rst_i,
	clk_i => clk_iface_i,
	refresh_i => clk_refrsh_i,
	count_i => internal_buffer_full,
	scaler_o => internal_deadtime_counter);
	
proc_timestamp: process(rst_i, clk_iface_i, reg_i)
begin
	if rst_i = '1' then
		internal_running_timestamp <= (others=>'0');
	elsif rising_edge(clk_iface_i) and reg_i(126)(0) = '1' then
		internal_running_timestamp <= (others=>'0');
	elsif rising_edge(clk_iface_i) then
		internal_running_timestamp <= internal_running_timestamp + 1;
	end if;
end process;

proc_trig_tag: process(rst_i, clk_iface_i, reg_i, internal_trig)
begin
	if rst_i = '1' then
		internal_trig_counter <= (others=>'0');
		internal_event_timestamp <= (others=>'0');
	elsif rising_edge(clk_iface_i) and reg_i(126)(0) = '1' then
		internal_trig_counter <= (others=>'0');
		internal_event_timestamp <= (others=>'0');
	elsif rising_edge(clk_iface_i) and internal_trig = '1' then
		internal_trig_counter <= internal_trig_counter + 1;
		internal_event_timestamp <= internal_running_timestamp;
	elsif rising_edge(clk_iface_i) then
		internal_trig_counter <= internal_trig_counter;
		internal_event_timestamp <= internal_event_timestamp;
	end if;
end process;

proc_evt_count_tag : process(rst_i, clk_iface_i, reg_i, internal_get_meta_data)
begin
	if rst_i = '1' then
		internal_next_event_counter <= (others=>'0');
	elsif rising_edge(clk_iface_i) and reg_i(126)(0) = '1' then
		internal_next_event_counter <= (others=>'0');
	elsif rising_edge(clk_iface_i) and (internal_get_meta_data(0) = '1' or internal_get_meta_data(1) = '1' or
													internal_get_meta_data(2) = '1' or internal_get_meta_data(3) = '1') then
		internal_next_event_counter <= internal_next_event_counter + 1;
	elsif rising_edge(clk_iface_i) then
		internal_next_event_counter <= internal_next_event_counter;
	end if;
end process;

proc_register_meta_data : process(rst_i, clk_iface_i, internal_get_meta_data)
begin
	for i in 0 to define_num_wfm_buffers-1 loop
		if rst_i = '1' then
			internal_header_0(i) <= (others=>'0');
			internal_header_1(i) <= (others=>'0');
			internal_header_2(i) <= (others=>'0');
			internal_header_3(i) <= (others=>'0');
			internal_header_4(i) <= (others=>'0');
			internal_header_5(i) <= (others=>'0');			
			internal_header_6(i) <= (others=>'0');			
			internal_header_7(i) <= (others=>'0');
			internal_header_8(i) <= (others=>'0');
			internal_header_9(i) <= (others=>'0');

			internal_header_10(i) <= (others=>'0');
			internal_header_11(i) <= (others=>'0');
			internal_header_12(i) <= (others=>'0');
			internal_header_13(i) <= (others=>'0');
			internal_header_14(i) <= (others=>'0');
			internal_header_15(i) <= (others=>'0');			
			internal_header_16(i) <= (others=>'0');			
			internal_header_17(i) <= (others=>'0');
			internal_header_18(i) <= (others=>'0');
			internal_header_19(i) <= (others=>'0');
			internal_header_20(i) <= (others=>'0');
			internal_header_21(i) <= (others=>'0');
			internal_header_22(i) <= (others=>'0');
			internal_header_23(i) <= (others=>'0');
			internal_header_24(i) <= (others=>'0');
	
		elsif rising_edge(clk_iface_i) and internal_get_meta_data(i)= '1' then
			internal_header_0(i) <= internal_next_event_counter(23 downto 0);
			internal_header_1(i) <= internal_next_event_counter(47 downto 24);
			internal_header_2(i) <= internal_trig_counter(23 downto 0);
			internal_header_3(i) <= internal_trig_counter(47 downto 24);
			internal_header_4(i) <= internal_event_timestamp(23 downto 0);
			internal_header_5(i) <= internal_event_timestamp(47 downto 24);
			internal_header_6(i) <= internal_deadtime_counter;
			internal_header_7(i) <= std_logic_vector(to_unsigned(i,2)) & reg_i(42)(1) & '0' & reg_i(76)(2 downto 0) & trig_type_i & trig_last_beam_i;
			internal_header_8(i) <= '0' & reg_i(48)(7 downto 0) & reg_i(80)(define_num_beams-1 downto 0);
			
			internal_header_10(i) <= x"0" & last_trig_pow_i(0);
			internal_header_11(i) <= x"0" & last_trig_pow_i(1);
			internal_header_12(i) <= x"0" & last_trig_pow_i(2);
			internal_header_13(i) <= x"0" & last_trig_pow_i(3);
			internal_header_14(i) <= x"0" & last_trig_pow_i(4);
			internal_header_15(i) <= x"0" & last_trig_pow_i(5);		
			internal_header_16(i) <= x"0" & last_trig_pow_i(6);			
			internal_header_17(i) <= x"0" & last_trig_pow_i(7);
			internal_header_18(i) <= x"0" & last_trig_pow_i(8);
			internal_header_19(i) <= x"0" & last_trig_pow_i(9);
			internal_header_20(i) <= x"0" & last_trig_pow_i(10);
			internal_header_21(i) <= x"0" & last_trig_pow_i(11);
			internal_header_22(i) <= x"0" & last_trig_pow_i(12);
			internal_header_23(i) <= x"0" & last_trig_pow_i(13);
			internal_header_24(i) <= x"0" & last_trig_pow_i(14);
			
		end if;
	end loop;
end process;

proc_assign_metadata : process(rst_i, clk_iface_i, reg_i(78))
begin
	if rising_edge(clk_iface_i) then
		event_header_o(0) <= internal_header_0(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(1) <= internal_header_1(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(2) <= internal_header_2(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(3) <= internal_header_3(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(4) <= internal_header_4(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(5) <= internal_header_5(to_integer(unsigned(reg_i(78)(1 downto 0))));	--//channel mask + beam mask
		event_header_o(6) <= internal_header_6(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(7) <= internal_header_7(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(8) <= internal_header_8(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(9) <= internal_header_9(to_integer(unsigned(reg_i(78)(1 downto 0))));
		
		event_header_o(10) <= internal_header_0(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(11) <= internal_header_1(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(12) <= internal_header_2(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(13) <= internal_header_3(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(14) <= internal_header_4(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(15) <= internal_header_5(to_integer(unsigned(reg_i(78)(1 downto 0))));	
		event_header_o(16) <= internal_header_6(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(17) <= internal_header_7(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(18) <= internal_header_8(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(19) <= internal_header_9(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(20) <= internal_header_9(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(21) <= internal_header_9(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(22) <= internal_header_9(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(23) <= internal_header_9(to_integer(unsigned(reg_i(78)(1 downto 0))));
		event_header_o(24) <= internal_header_9(to_integer(unsigned(reg_i(78)(1 downto 0))));
--		case reg_i(78)(1 downto 0) is
--			when "00" =>
--				event_header_0 <= internal_header_0(0);
--				event_header_1 <= internal_header_1(0);
--				event_header_2 <= internal_header_2(0);
--				event_header_3 <= internal_header_3(0);
--				event_header_4 <= internal_header_4(0);
--				event_header_5 <= internal_header_5(0);
--			when "01" =>
--				event_header_0 <= internal_header_0(1);
--				event_header_1 <= internal_header_1(1);
--				event_header_2 <= internal_header_2(1);
--				event_header_3 <= internal_header_3(1);
--				event_header_4 <= internal_header_4(1);
--				event_header_5 <= internal_header_5(1);
--			when "10" =>
--				event_header_0 <= internal_header_0(2);
--				event_header_1 <= internal_header_1(2);
--				event_header_2 <= internal_header_2(2);
--				event_header_3 <= internal_header_3(2);
--				event_header_4 <= internal_header_4(2);
--				event_header_5 <= internal_header_5(2);
--			when "11" =>
--				event_header_0 <= internal_header_0(3);
--				event_header_1 <= internal_header_1(3);
--				event_header_2 <= internal_header_2(3);
--				event_header_3 <= internal_header_3(3);
--				event_header_4 <= internal_header_4(3);
--				event_header_5 <= internal_header_5(3);
--		end case;
	end if;
end process;			
end rtl;