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
		clk_data_i		:	in		std_logic; --//data clock ~93 MHz
		clk_iface_i		: 	in		std_logic; --//slow logic clock =7.5 MHz
					
		reg_i				: 	in		register_array_type;
		
		surface_data_i	:	in	   surface_data_type);		

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
==//
--//get_vpp function. argument vector 's' is unsigned
function get_vpp(s : std_logic_vector) return integer is
	variable temp_min : integer := 64;
	variable temp_max : integer := 128;
	variable vpp : integer := 1;
begin
	for j in 0 to 4*define_serdes_factor-1 loop
		if s((j+1)*define_word_size-1 downto j*define_word_size) > temp_max then
			temp_max := to_integer(unsigned(s((j+1)*define_word_size-1 downto j*define_word_size)));
		end if;
		if s((j+1)*define_word_size-1 downto j*define_word_size) < temp_min then
			temp_min := to_integer(unsigned(s((j+1)*define_word_size-1 downto j*define_word_size)));
		end if;	
		
	end loop;
  
	if temp_max <= temp_min then
		return 1;
	else
		vpp := temp_max - temp_min; 
		return vpp;
	end if;
end function get_vpp;
---//
type internal_vpp_type is array (surface_channels-1 downto 0) of integer range -1 to 512;
signal internal_vpp: internal_vpp_type;
signal internal_vpp_threshold : std_logic_vector(7 downto 0);
signal internal_trigger_bits : std_logic_vector(surface_channels-1 downto 0);

signal buf_data_0 		: 	surface_data_type;
signal buf_data_1 		: 	surface_data_type;

type internal_buf_data_type is array (surface_channels-1 downto 0) of std_logic_vector(2*pdat_size-1 downto 0); 
signal dat : internal_buf_data_type;

begin
--//
GetThreshold	:	 for i in 0 to 7 generate	
	xGET_THRESHOLD : signal_sync
	port map(
		clkA				=> clk_iface_i,
		clkB				=> clk_i,
		SignalIn_clkA	=> reg_i(46)(i), 
		SignalOut_clkB	=> internal_vpp_threshold(i));
end generate;
--------------------------------------------
--------------//
proc_buffer_data : process(rst_i, clk_i, data_i)
begin
	--//loop over trigger channels
	for i in 0 to surface_channels loop
		
		if rst_i = '1' then
		
			buf_data_0(i)<= (others=>'0');
			buf_data_1(i)<= (others=>'0');	

			dat(i) <= (others=>'0');
			
		elsif rising_edge(clk_i) then
			--//buffer data
			dat(i) <= buf_data_0(i) & buf_data_1(i);
		
			buf_data_1(i) <= buf_data_0(i);
			buf_data_0(i) <= data_i(i);

		end if;
	end loop;
end process;
--------------//
proc_trigger_bits: process(rst_i, clk_i, dat, internal_vpp_threshold)
begin
	for i in 0 to surface_channels loop
		if rst_i = '1' then
			internal_vpp(i) <= 0;
			internal_trigger_bits(i) <= '0';
		elsif rising_edge(clk_i) then
			internal_vpp(i) <= get_vpp(dat(i));
			
			if internal_vpp(i) >= internal_vpp_threshold then
				internal_trigger_bits <= '1';
			else
				internal_trigger_bits <= '0';
			end if;
		end if;
		
	end loop;
end process;
-----------//

	


end rtl;