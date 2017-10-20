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
	generic(
		scaler_width   : integer := 12);
	port(
		rst_i				:		in		std_logic;
		clk_i				:		in 	std_logic;
		pulse_refrsh_i	:		in		std_logic;
		pulse_refrshHz_i	:	in		std_logic;
		
		gate_i			:		in		std_logic;
		
		reg_i				:		in		register_array_type;
		trigger_i		:		in		std_logic;
		beam_trig_i		:		in		std_logic_vector(define_num_beams-1 downto 0);

		running_scalers_o:		out	std_logic_vector(23 downto 0);
		
		scaler_to_read_o  :   out	std_logic_vector(23 downto 0));
end scalers_top;

architecture rtl of scalers_top is

constant num_scalers : integer := 48;
type scaler_array_type is array(num_scalers-1 downto 0) of std_logic_vector(scaler_width-1 downto 0);

signal internal_scaler_array : scaler_array_type;
signal latched_scaler_array : scaler_array_type; --//assigned after refresh pulse

component scaler
port(
	rst_i 		: in 	std_logic;
	clk_i			: in	std_logic;
	refresh_i	: in	std_logic;
	count_i		: in	std_logic;
	scaler_o		: out std_logic_vector(scaler_width-1 downto 0));
end component;
-------------------------------------------------------------------------------
begin
-------------------------------------------------------------------------------
proc_assign_scalers_to_metadata : running_scalers_o <= internal_scaler_array(32) & internal_scaler_array(0);
-------------------------------------------------------------------------------
--//scaler 1
xTRIGSCALER : scaler
	port map(
		rst_i => rst_i,
		clk_i => clk_i,
		refresh_i => pulse_refrsh_i,
		count_i => trigger_i,
		scaler_o => internal_scaler_array(0));
		
--//scalers 2 to 16
BeamTrigScalers : for i in 0 to define_num_beams-1 generate
	xBEAMTRIGSCALERS : scaler
	port map(
		rst_i => rst_i,
		clk_i => clk_i,
		refresh_i => pulse_refrsh_i,
		count_i => beam_trig_i(i),
		scaler_o => internal_scaler_array(i+1));
end generate;

--//scaler 17
xGATEDTRIGSCALER : scaler
	port map(
		rst_i => rst_i,
		clk_i => clk_i,
		refresh_i => pulse_refrsh_i,
		count_i => trigger_i and gate_i,
		scaler_o => internal_scaler_array(16));
		
--//scalers 18 to 32
GatedBeamTrigScalers : for i in 0 to define_num_beams-1 generate
	xGATEDBEAMTRIGSCALERS : scaler
	port map(
		rst_i => rst_i,
		clk_i => clk_i,
		refresh_i => pulse_refrsh_i,
		count_i => beam_trig_i(i) and gate_i,
		scaler_o => internal_scaler_array(i+1+16));
end generate;

--//scaler 33
xTRIGSCALERHz : scaler
	port map(
		rst_i => rst_i,
		clk_i => clk_i,
		refresh_i => pulse_refrshHz_i,
		count_i => trigger_i,
		scaler_o => internal_scaler_array(32));
		
--//scalers 34 to 48
BeamTrigScalersHz : for i in 0 to define_num_beams-1 generate
	xBEAMTRIGSCALERSHz : scaler
	port map(
		rst_i => rst_i,
		clk_i => clk_i,
		refresh_i => pulse_refrshHz_i,
		count_i => beam_trig_i(i),
		scaler_o => internal_scaler_array(i+1+32));
end generate;

proc_save_scalers : process(rst_i, clk_i, reg_i)
begin
	if rst_i = '1' then
		for i in 0 to num_scalers-1 loop
			latched_scaler_array(i) <= (others=>'0');
		end loop;
		scaler_to_read_o <= (others=>'0');
	elsif rising_edge(clk_i) and reg_i(40)(0) = '1' then
		latched_scaler_array <= internal_scaler_array;
	
	elsif rising_edge(clk_i) then
		case reg_i(41)(7 downto 0) is
			when x"00" =>
				scaler_to_read_o <= latched_scaler_array(1) & latched_scaler_array(0);
			when x"01" =>
				scaler_to_read_o <= latched_scaler_array(3) & latched_scaler_array(2);
			when x"02" =>
				scaler_to_read_o <= latched_scaler_array(5) & latched_scaler_array(4);
			when x"03" =>
				scaler_to_read_o <= latched_scaler_array(7) & latched_scaler_array(6);
			when x"04" =>
				scaler_to_read_o <= latched_scaler_array(9) & latched_scaler_array(8);
			when x"05" =>
				scaler_to_read_o <= latched_scaler_array(11) & latched_scaler_array(10);
			when x"06" =>
				scaler_to_read_o <= latched_scaler_array(13) & latched_scaler_array(12);
			when x"07" =>
				scaler_to_read_o <= latched_scaler_array(15) & latched_scaler_array(14);
			when x"08" =>
				scaler_to_read_o <= latched_scaler_array(17) & latched_scaler_array(16);
			when x"09" =>
				scaler_to_read_o <= latched_scaler_array(19) & latched_scaler_array(18);
			when x"0A" =>
				scaler_to_read_o <= latched_scaler_array(21) & latched_scaler_array(20);
			when x"0B" =>
				scaler_to_read_o <= latched_scaler_array(23) & latched_scaler_array(22);
			when x"0C" =>
				scaler_to_read_o <= latched_scaler_array(25) & latched_scaler_array(24);
			when x"0D" =>
				scaler_to_read_o <= latched_scaler_array(27) & latched_scaler_array(26);
			when x"0E" =>
				scaler_to_read_o <= latched_scaler_array(29) & latched_scaler_array(28);
			when x"0F" =>
				scaler_to_read_o <= latched_scaler_array(31) & latched_scaler_array(30);	
			--//second-updating scalers:
			when x"10" =>
				scaler_to_read_o <= latched_scaler_array(33) & latched_scaler_array(32);
			when x"11" =>
				scaler_to_read_o <= latched_scaler_array(35) & latched_scaler_array(34);
			when x"12" =>
				scaler_to_read_o <= latched_scaler_array(37) & latched_scaler_array(36);
			when x"13" =>
				scaler_to_read_o <= latched_scaler_array(39) & latched_scaler_array(38);
			when x"14" =>
				scaler_to_read_o <= latched_scaler_array(41) & latched_scaler_array(40);
			when x"15" =>
				scaler_to_read_o <= latched_scaler_array(43) & latched_scaler_array(42);
			when x"16" =>
				scaler_to_read_o <= latched_scaler_array(45) & latched_scaler_array(44);
			when x"17" =>
				scaler_to_read_o <= latched_scaler_array(47) & latched_scaler_array(46);
				
			when others =>
				scaler_to_read_o <= latched_scaler_array(1) & latched_scaler_array(0);
		end case;
	end if;
end process;
end rtl;
		