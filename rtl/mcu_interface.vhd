---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         mcu_interface.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         5/2017...
--
-- DESCRIPTION:  Interface to LPC4088
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

entity mcu_interface is
	port(
		rst_i			:	in		std_logic;
			
		

		
		
end mcu_interface;


architecture rtl of mcu_interface is












	xSPI_SLAVE : entity work.spi_slave
	port map(
		sclk           	--spi clk from master
		reset_n        	not reset_global --active low reset
		ss_n           	--active low slave select
		mosi           	--master out, slave in
		rx_req         	--'1' while busy = '0' moves data to the rx_data output
		st_load_en     	--asynchronous load enable
		st_load_trdy   	--asynchronous trdy load input
		st_load_rrdy   	--asynchronous rrdy load input
		st_load_roe    	--asynchronous roe load input
		tx_load_en     	--asynchronous transmit buffer load enable
		tx_load_data   	--asynchronous tx data to load
		trdy           	--transmit ready bit
		rrdy           	--receive ready bit
		roe            	--receive overrun error bit
		rx_data        	--receive register output to logic
		busy           	--busy signal to logic ('1' during transaction)
		miso         		rdout_data_16bit; --master in, slave out