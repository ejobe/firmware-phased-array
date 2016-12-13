---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         defs.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         1/2016
--
-- DESCRIPTION:  type defs // register mapping
--
---------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

package defs is

constant define_serdes_factor 			: 	integer := 8;
constant define_adc_data_width			: 	integer := 28; 
constant define_deser_data_width			: 	integer := define_serdes_factor*define_adc_data_width;
constant define_ram_width  				: 	integer := 128;
constant define_ram_depth					: 	integer := 11; --//2048 words
constant define_address_size				:	integer := 8; --//8 bits for now
constant define_register_size				:	integer := 32;

type adc_output_data_type is array (3 downto 0) of std_logic_vector(define_adc_data_width-1 downto 0);
type full_data_type	is array	(7 downto 0) of std_logic_vector(define_ram_width-1 downto 0);	
type full_address_type	is array	(7 downto 0) of std_logic_vector(define_ram_depth-1 downto 0);	
type aux_data_link_type is array (1 downto 0) of std_logic_vector(7 downto 0);

type register_array_type is array (127 downto 0) 
	of std_logic_vector(define_register_size-define_address_size-1 downto 0); --//8 bit address, 24 bit data
	
constant firmware_version : std_logic_vector(define_register_size-define_address_size-1 downto 0) := x"000001";
constant firmware_date : std_logic_vector(define_register_size-define_address_size-1 downto 0) := x"7e0" & x"A" & x"12";

end defs;


package register_map is

constant base_adrs_pll_cntrl		:	integer := 16;

--constant base_adrs_adc_cntrl		:	integer := 64;
--	constant adrs_trig				:  integer := base_adrs_adc_cntrl + 0; --//pulsed

constant base_adrs_rdout_cntrl 	:  integer := 64;

	
end register_map;
	
	
