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
--
--  TODO: add master interupt line (GPIO) when system is self-triggered
--   (OR, run MCU/beagle bone in polling mode (~few Hz) and suffeciently buffer data on FPGA to handle bursts/Poisson 
--
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

entity mcu_interface is
	generic(
		data_width 	: 	integer := 32);
	port(
		clk_i			:	in		std_logic;											--//interface clock
		rst_i			:	in		std_logic;	
		spi_cs_i  	:	in		std_logic;
		spi_sclk_i	:	in		std_logic;
		spi_mosi_i	:  in		std_logic;
		spi_miso_o	:  out	std_logic;
		data_i		:  in		std_logic_vector(data_width-1 downto 0); 	--// tx data
		tx_load_i	:	in		std_logic; 											--//tx data send
		data_o   	:	out	std_logic_vector(data_width-1 downto 0); 	--// rx data
		--rx_req_i		:	in		std_logic; 											--//rx data request (old spi_slave module ONLY)
		--spi_busy_o	:	out	std_logic; 											--//interface is busy (old spi_slave module ONLY)
		tx_ack_o		:	out	std_logic; 						
		rx_rdy_o		:	out	std_logic);                                --//rx data is ready
		--tx_rdy_o		:	out	std_logic);											--//tx data is ready
end mcu_interface;

architecture rtl of mcu_interface is
begin
--/////////////////////////////////////////////////////////
--//interface to BeagleBone is SPI coms
xSPI_SLAVE : entity work.spi_slave
generic map(
	N => 32)
port map(	
	clk_i 			=> clk_i,             -- internal interface clock (clocks di/do registers)
	spi_ssel_i   	=> spi_cs_i or rst_i, -- spi bus slave select line
	spi_sck_i      => spi_sclk_i,		    -- spi bus sck clock (clocks the shift register core)
	spi_mosi_i     => spi_mosi_i,		    -- spi bus mosi input
	spi_miso_o     => spi_miso_o,			 -- spi bus spi_miso_o output
	di_req_o       => open,              -- preload lookahead data request line
	di_i   			=> data_i,				 -- parallel load data in (clocked in on rising edge of clk_i)
	wren_i         => tx_load_i,         -- user data write enable
	wr_ack_o       => tx_ack_o,          -- write acknowledge
	do_valid_o     => rx_rdy_o,          -- do_o data valid strobe, valid during one clk_i rising edge.
	do_o        	=> data_o, 				 -- parallel output (clocked out on falling clk_i)
	--- debug ports: can be removed for the application circuit ---
	do_transfer_o  => open,       -- debug: internal transfer driver
	wren_o         => open,       -- debug: internal state of the wren_i pulse stretcher
	rx_bit_next_o  => open,       -- debug: internal rx bit
	state_dbg_o    => open,       -- debug: internal state register
	sh_reg_dbg_o	=> open);

--Below was original interface: required 8 bits of header data for each transaction (spi_slave_old.vhd in /rtl).
--and required syncing data output to clk_i
--
--xSPI_SLAVE : entity work.spi_slave
--generic map(
--	d_width => data_width)
--port map(
--	sclk           	=> mcu_fpga_io(3),	--spi clk from master
--	reset_n        	=> not rst_i, 			--active low reset
--	ss_n           	=> mcu_fpga_io(7),	--active low slave select
--	mosi           	=> mcu_fpga_io(1),	--master out, slave in
--	rx_req         	=> rx_req_i,			--'1' while busy = '0' moves data to the rx_data output
--	st_load_en     	=> '0',					--asynchronous load enable
--	st_load_trdy   	=> '0',					--asynchronous trdy load input
--	st_load_rrdy   	=> '0',					--asynchronous rrdy load input
--	st_load_roe    	=> '0',					--asynchronous roe load input
--	tx_load_en     	=> tx_load_i,			--asynchronous transmit buffer load enable
--	tx_load_data   	=> data_i,				--asynchronous tx data to load
--	trdy           	=> tx_rdy_o,			--transmit ready bit
--	rrdy           	=> rx_rdy_o,			--receive ready bit
--	roe            	=> open,					--receive overrun error bit
--	rx_data        	=> data_o,				--receive register output to logic
--	busy           	=> spi_busy_o,			--busy signal to logic ('1' during transaction)
--	miso         		=> mcu_fpga_io(2));	--master in, slave out
--//
end rtl;