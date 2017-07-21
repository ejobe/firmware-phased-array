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
		gate_i			:		in		std_logic;
		
		reg_i				:		in		register_array_type;
		trigger_i		:		in		std_logic;
		beam_trig_i		:		in		std_logic_vector(define_num_beams-1 downto 0);
		
		scaler_to_read_o  :   out	std_logic_vector(23 downto 0));
end scalers_top;

architecture rtl of scalers_top is

constant num_scalers : integer := 32;
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

begin
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
		case reg_i(41)(3 downto 0) is
			when x"0" =>
				scaler_to_read_o <= latched_scaler_array(1) & latched_scaler_array(0);
			when x"1" =>
				scaler_to_read_o <= latched_scaler_array(3) & latched_scaler_array(2);
			when x"2" =>
				scaler_to_read_o <= latched_scaler_array(5) & latched_scaler_array(4);
			when x"3" =>
				scaler_to_read_o <= latched_scaler_array(7) & latched_scaler_array(6);
			when x"4" =>
				scaler_to_read_o <= latched_scaler_array(9) & latched_scaler_array(8);
			when x"5" =>
				scaler_to_read_o <= latched_scaler_array(11) & latched_scaler_array(10);
			when x"6" =>
				scaler_to_read_o <= latched_scaler_array(13) & latched_scaler_array(12);
			when x"7" =>
				scaler_to_read_o <= latched_scaler_array(15) & latched_scaler_array(14);
			when x"8" =>
				scaler_to_read_o <= latched_scaler_array(17) & latched_scaler_array(16);
			when x"9" =>
				scaler_to_read_o <= latched_scaler_array(19) & latched_scaler_array(18);
			when x"A" =>
				scaler_to_read_o <= latched_scaler_array(21) & latched_scaler_array(20);
			when x"B" =>
				scaler_to_read_o <= latched_scaler_array(23) & latched_scaler_array(22);
			when x"C" =>
				scaler_to_read_o <= latched_scaler_array(25) & latched_scaler_array(24);
			when x"D" =>
				scaler_to_read_o <= latched_scaler_array(27) & latched_scaler_array(26);
			when x"E" =>
				scaler_to_read_o <= latched_scaler_array(29) & latched_scaler_array(28);
			when x"F" =>
				scaler_to_read_o <= latched_scaler_array(31) & latched_scaler_array(30);	
		end case;
	end if;
end process;
end rtl;
		