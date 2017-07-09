---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         pretrigger_window.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         7/2017
--
-- DESCRIPTION:  buffering to allow for pre-trigger window of data
--               
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;

entity pretrigger_window is
	port(
		rst_i					:	in	 std_logic;
		clk_i					:  in	 std_logic;
		reg_i					:	in	 register_array_type; 	
		data_i				:	in	 std_logic_vector(127 downto 0);
		data_o				:	out std_logic_vector(127 downto 0));
	end pretrigger_window;
	
--//data comes in bunches of 16 samples, which fill 10.66 ns (One clk_i period)
--//this module buffers these data to allow the system to save waveform information from
--//before the trigger signal..

architecture rtl of pretrigger_window is
	type internal_data_buffer_type is array(7 downto 0) of std_logic_vector(127 downto 0);
	signal internal_data_buffer_0 : internal_data_buffer_type;
	signal internal_data_buffer_1 : internal_data_buffer_type;
	signal internal_data_buffer_2 : internal_data_buffer_type;
	signal internal_data_buffer_3 : internal_data_buffer_type;
	signal internal_data_buffer_4 : internal_data_buffer_type;

begin

proc_buf_dat : process(rst_i, clk_i)
begin
	if rst_i = '1' then
		for i in 0 to 7 loop
			internal_data_buffer_0(i) <= (others=>'0');
			internal_data_buffer_1(i) <= (others=>'0');
			internal_data_buffer_2(i) <= (others=>'0');
			internal_data_buffer_3(i) <= (others=>'0');
			internal_data_buffer_4(i) <= (others=>'0');
		end loop;
	elsif rising_edge(clk_i) then
		
		for i in 1 to 7 loop
			internal_data_buffer_4(i) <= internal_data_buffer_4(i-1);
			internal_data_buffer_3(i) <= internal_data_buffer_3(i-1);
			internal_data_buffer_2(i) <= internal_data_buffer_2(i-1);
			internal_data_buffer_1(i) <= internal_data_buffer_1(i-1);
			internal_data_buffer_0(i) <= internal_data_buffer_0(i-1);
		end loop;
		
		internal_data_buffer_4(0) <= internal_data_buffer_3(7);
		internal_data_buffer_3(0) <= internal_data_buffer_2(7);
		internal_data_buffer_2(0) <= internal_data_buffer_1(7);
		internal_data_buffer_1(0) <= internal_data_buffer_0(7);
		internal_data_buffer_0(0) <= data_i;
	end if;
end process;

proc_assign_data_o : process(rst_i, clk_i, reg_i(76))
begin
	case reg_i(76)(2 downto 0) is
		
		when "000"=>
			data_o <= data_i; --//0 pre-trigger delay
		when "001"=> 
			data_o <= internal_data_buffer_0(7);
		when "010"=>
			data_o <= internal_data_buffer_1(7);
		when "011"=>
			data_o <= internal_data_buffer_2(7);
		when "100"=>
			data_o <= internal_data_buffer_3(7);
		when "101"=>
			data_o <= internal_data_buffer_4(7);
		when others=>
			data_o <= data_i;
	end case;
end process;
end rtl;