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
-- DESCRIPTION:  Interface to LPC4088 or BeagleBone
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

entity mcu_interface is
	generic(
		data_width 	: 	integer := 8);
	port(
		rst_i			:	in		std_logic;	
		mcu_fpga_io	:  inout	std_logic_vector(11 downto 0);  --// FPGA pins to MCU header
		data_i		:  in		std_logic_vector(data_width-1 downto 0); --// tx data
		tx_load_i	:	in		std_logic; --//tx data send
		data_o   	:	out	std_logic_vector(data_width-1 downto 0); --// rx data
		rx_req_i		:	in		std_logic; --//rx data request
		spi_busy_o	:	out	std_logic);

end mcu_interface;

architecture rtl of mcu_interface is

begin

--/////////////////////////////////////////////////////////
--//primary interface to MCU / BeagleBone is SPI coms
xSPI_SLAVE : entity work.spi_slave
generic map(
	d_width := data_width);
port map(
	sclk           	=> mcu_fpga_io(3),	--spi clk from master
	reset_n        	=> not rst_i, 			--active low reset
	ss_n           	=> '0', --mcu_fpga_io(7),	--active low slave select
	mosi           	=> mcu_fpga_io(1),	--master out, slave in
	rx_req         	=> rx_req_i,			--'1' while busy = '0' moves data to the rx_data output
	st_load_en     	=> '0',					--asynchronous load enable
	st_load_trdy   	=> '0',					--asynchronous trdy load input
	st_load_rrdy   	=> '0',					--asynchronous rrdy load input
	st_load_roe    	=> '0',					--asynchronous roe load input
	tx_load_en     	=> tx_load_i,			--asynchronous transmit buffer load enable
	tx_load_data   	=> data_i,				--asynchronous tx data to load
	trdy           	=> open,					--transmit ready bit
	rrdy           	=> open,					--receive ready bit
	roe            	=> open,					--receive overrun error bit
	rx_data        	=> data_o				--receive register output to logic
	busy           	=> spi_busy_o,			--busy signal to logic ('1' during transaction)
	miso         		=> mcu_fpga_io(2))	--master in, slave out
	

--//
end rtl;