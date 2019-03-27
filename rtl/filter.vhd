---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         filter.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         3/2019, 
--
-- DESCRIPTION:  FIR high-pass for surface trigger
--               
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;

entity filter is
	port(
		rst_i			:	in		std_logic;
		clk_i			: 	in		std_logic;
		clk_iface_i	:	in		std_logic;
			
		reg_i			: 	in		register_array_type;
		data_i		:	in	   surface_data_type;
		
		filtered_data_o :	out	surface_data_type);
		
end filter;

architecture rtl of filter is

type internal_buf_data_type is array (surface_channels-1 downto 0) of std_logic_vector(6*pdat_size-1 downto 0);
signal dat : internal_buf_data_type;
signal buf_data_0 		: 	surface_data_type;
signal buf_data_1 		:  surface_data_type;
signal buf_data_2 		: 	surface_data_type;
signal buf_data_3 		: 	surface_data_type;
signal buf_data_4 		: 	surface_data_type;
signal buf_data_5 		: 	surface_data_type;
signal wfm_data_pipe 	:  surface_data_type;

constant filter_taps : integer :=  21;
constant filter_coeff_size : integer :=  8; 
constant filter_result_length : integer := 20; 

-----------------------------------------------
----filter via conversion to integer:
---------------------------------------------
type filter_kernel_type is array (0 to filter_taps-1) of integer range -127 to 128; --
--constant kernel : filter_kernel_type := (-3,-4,-2,2,6,7,2,-8,-21,-31,96); --//F_c = 200MHz
--constant kernel : filter_kernel_type := (-1,-4,-4,-1,5,8,5,-5,-19,-32,90); --//F_c = 220MHz
constant kernel : filter_kernel_type := (-1,-4,-4,-1,5,8,5,-5,-19,-32,90,-32,-19,-5,5,8,5,-1,-4,-4,-1); --//F_c = 220MHz

-----------------------------------------------
----filter via conversion to integer:
-----------------------------------------------
type filter_result_int_type is array (surface_channels-1 downto 0, 2*define_serdes_factor-1 downto 0) of integer range -4096 to 8192;
signal filter_result : filter_result_int_type;
signal pre_filter_result_1 : filter_result_int_type;
signal pre_filter_result_2 : filter_result_int_type;
signal pre_filter_result_3 : filter_result_int_type;
signal pre_filter_result_4 : filter_result_int_type;
signal pre_filter_result_5 : filter_result_int_type;

signal buf_filter_result : surface_data_type;

--//
component signal_sync is
port
	(clkA			: in	std_logic;
   clkB			: in	std_logic;
   SignalIn_clkA	: in	std_logic;
   SignalOut_clkB	: out	std_logic);
end component;
--//
signal internal_filter_enable : std_logic := '0';
--//
begin
--//
--------------------------------------------
xFILTEN : signal_sync
port map(
	clkA				=> clk_iface_i,
	clkB				=> clk_i,
	SignalIn_clkA	=> reg_i(47)(3), 
	SignalOut_clkB	=> internal_filter_enable);
--------------------------------------------

proc_filter : process(rst_i, clk_i)
begin
	for j in 0 to surface_channels-1 loop

		if rst_i = '1' then
		
			dat(j) <= (others=>'0');
			buf_data_0(j) <= (others=>'0');
			buf_data_1(j) <= (others=>'0');
			buf_data_2(j) <= (others=>'0');
			buf_data_3(j) <= (others=>'0');
			
			for i in 0 to 2*define_serdes_factor-1 loop
				
				-----------------------------------------------
				----filter via conversion to integer:
				-----------------------------------------------
				filter_result(j,i) <= 0;
				pre_filter_result_1(j,i) <= 0;
				pre_filter_result_2(j,i) <= 0;

			end loop;
			
	
		elsif rising_edge(clk_i) then

			dat(j) <= buf_data_0(j) & buf_data_1(j) & buf_data_2(j) & buf_data_3(j) & buf_data_4(j) & buf_data_5(j);

			buf_data_5(j) <= buf_data_4(j);
			buf_data_4(j) <= buf_data_3(j);	
			buf_data_3(j) <= buf_data_2(j);	
			buf_data_2(j) <= buf_data_1(j);	
			buf_data_1(j) <= buf_data_0(j);
			buf_data_0(j) <= wfm_data_pipe(j);
			wfm_data_pipe(j) <= data_i(j);
							  
			case internal_filter_enable is
				when '0' => filtered_data_o(j) <= buf_data_3(j);
				when '1' => filtered_data_o(j) <= buf_filter_result(j);
			end case;
	
		for i in 0 to 2*define_serdes_factor-1 loop

		---------------------------------------------
		--filter via conversion to integer:
		---------------------------------------------
		
				buf_filter_result(j)((i+1)*define_word_size-1 downto i*define_word_size) <= '0' & 
													std_logic_vector(to_unsigned((filter_result(j,i) + 4096), filter_result_length))(12 downto 6); --//get value	

				--//--
				filter_result(j,i) <= pre_filter_result_1(j,i) + pre_filter_result_2(j,i) + pre_filter_result_3(j,i) + pre_filter_result_4(j,i);
				--//--									
				pre_filter_result_1(j,i) <=						
					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*0 + define_word_size*i downto 3*pdat_size-define_word_size*1 + define_word_size*i ))) - 64) *
					kernel(0) + 
				
					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*1 + define_word_size*i downto 3*pdat_size-define_word_size*2 + define_word_size*i ))) - 64) *
					kernel(1) + 			

					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*2 + define_word_size*i downto 3*pdat_size-define_word_size*3 + define_word_size*i ))) - 64) *
					kernel(2) + 	
			
					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*3 + define_word_size*i downto 3*pdat_size-define_word_size*4 + define_word_size*i ))) - 64) *
					kernel(3) + 		

					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*4 + define_word_size*i downto 3*pdat_size-define_word_size*5 + define_word_size*i ))) - 64) *
					kernel(4);
				
				pre_filter_result_2(j,i) <=						
					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*5 + define_word_size*i downto 3*pdat_size-define_word_size*6 + define_word_size*i ))) - 64) *
					kernel(5) + 
					
					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*6 + define_word_size*i downto 3*pdat_size-define_word_size*7 + define_word_size*i ))) - 64) *
					kernel(6) +
					
					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*7 + define_word_size*i downto 3*pdat_size-define_word_size*8 + define_word_size*i ))) - 64) *
					kernel(7) + 			

					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*8 + define_word_size*i downto 3*pdat_size-define_word_size*9 + define_word_size*i ))) - 64) *
					kernel(8) + 	
			
					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*9 + define_word_size*i downto 3*pdat_size-define_word_size*10 + define_word_size*i ))) - 64) *
					kernel(9);
					
				pre_filter_result_3(j,i) <=
					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*10 + define_word_size*i downto 3*pdat_size-define_word_size*11 + define_word_size*i ))) - 64) *
					kernel(10) +
									
					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*11 + define_word_size*i downto 3*pdat_size-define_word_size*12 + define_word_size*i ))) - 64) *
					kernel(11) +
					
					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*12 + define_word_size*i downto 3*pdat_size-define_word_size*13 + define_word_size*i ))) - 64) *
					kernel(12)+
					
					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*13 + define_word_size*i downto 3*pdat_size-define_word_size*14 + define_word_size*i ))) - 64) *
					kernel(13) +			

					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*14 + define_word_size*i downto 3*pdat_size-define_word_size*15 + define_word_size*i ))) - 64) *
					kernel(14);
			
				pre_filter_result_4(j,i) <=	
					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*15 + define_word_size*i downto 3*pdat_size-define_word_size*16 + define_word_size*i ))) - 64) *
					kernel(15) + 		

					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*16 + define_word_size*i downto 3*pdat_size-define_word_size*17 + define_word_size*i ))) - 64) *
					kernel(16) +
									
					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*17 + define_word_size*i downto 3*pdat_size-define_word_size*18 + define_word_size*i ))) - 64) *
					kernel(17) + 
					
					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*18 + define_word_size*i downto 3*pdat_size-define_word_size*19 + define_word_size*i ))) - 64) *
					kernel(18) + 
				
					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*19 + define_word_size*i downto 3*pdat_size-define_word_size*20 + define_word_size*i ))) - 64) *
					kernel(19) + 			

					(to_integer(unsigned(dat(j)(3*pdat_size-2-define_word_size*20 + define_word_size*i downto 3*pdat_size-define_word_size*21 + define_word_size*i ))) - 64) *
					kernel(20);
			
	

				
			end loop;
		end if;
	end loop;
end process;

end rtl;