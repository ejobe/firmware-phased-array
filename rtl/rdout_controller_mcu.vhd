---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         rdout_controller_mcu.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         5/2017
--
-- DESCRIPTION:  control block for board readout via microcontroller
--             This block basically interfaces the fpga registers (registers.vhd) to the 
--	              spi_slave block.
---------------------------------------------------------------------------------

library IEEE; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

entity rdout_controller_mcu is	
	generic(
		d_width : INTEGER := 32);
	port(
		rst_i						:	in		std_logic;	--//asynch reset to block
		clk_i						:  in		std_logic; 	--//clock (probably 1-10 MHz, same freq range as registers.vhd and spi_slave.vhd)					
		rdout_reg_i				:	in		std_logic_vector(define_register_size-1 downto 0); --//register to readout
		reg_adr_i				:	in		std_logic_vector(define_address_size-1 downto 0);  --//firmware register addresses
		registers_i				:	in		register_array_type;   --//firmware register array      
		
		tx_rdy_o					:	out	std_logic;  --// tx ready flag
		tx_rdy_spi_i			:	in		std_logic;  --// spi_slave tx_rdy signal
		tx_ack_i					:	in		std_logic;  --//tx ack from spi_slave (newer spi_slave module ONLY)
	
		rdout_fpga_data_o		:	out		std_logic_vector(d_width-1 downto 0)); --//data to send off-fpga
		
end rdout_controller_mcu;

architecture rtl of rdout_controller_mcu is

type readout_state_type is (idle_st, set_readout_reg_st, tx_st, wait_for_ack_st);
signal readout_state : readout_state_type;

signal readout_timeout : std_logic_vector(11 downto 0) := (others=>'0');

begin

--///////////////////////////////
--//readout process	
proc_read : process(rst_i, clk_i, reg_adr_i, tx_rdy_spi_i)
variable i : integer range 0 to 10 := 0;
begin
	if rst_i = '1' or reg_adr_i = x"48" then 
		rdout_fpga_data_o		<= (others=>'0'); --/fpga readout data
		tx_rdy_o <= '0'; 								--//tx flag to spi_slave
		readout_timeout <= (others=>'0');
		i := 0;
		readout_state <= idle_st;
		
	elsif rising_edge(clk_i) then
		
		case readout_state is
			--// wait for start-readout register to be written
			when idle_st =>
				readout_timeout <= (others=>'0');
				tx_rdy_o <= '0';
				i := 0;
				rdout_fpga_data_o		<= x"1234DEAD"; --dummy data
				--///////////////////////////////////////////////
				--//if readout register is written, and spi interface is done with last transfer we initiate a transfer:
				if reg_adr_i = x"47" then
					rdout_fpga_data_o		<= x"1234BEEF";  --dummy data
					readout_state <= set_readout_reg_st;
				else 
					readout_state <= idle_st;
				end if;
			
			--//assign the readout register to the appropriate data
			when set_readout_reg_st =>
				tx_rdy_o <= '0';
				rdout_fpga_data_o <= rdout_reg_i;
				if i > 1 then
					i := 0;
					readout_state <= tx_st;
				else 
					i := i + 1;
					readout_state <= set_readout_reg_st;
				end if;

			when tx_st =>
				i := 0;
				tx_rdy_o <= '1';  --//pulse tx ready for a single clk cycle
				readout_state <= wait_for_ack_st;
			
			when wait_for_ack_st =>
				i := 0;
				tx_rdy_o <= '0';
				rdout_fpga_data_o <= x"DEADBEEF";
				readout_timeout <= readout_timeout + 1;
				--if tx_ack_i = '1' then
				--	readout_state <= idle_st;
				--//timeout waiting for an ack:
				if readout_timeout = x"F" then --//wait 16 clock cycles
					readout_timeout <= (others=>'0');
					readout_state <= idle_st;
				else
					readout_state <= wait_for_ack_st;
				end if;
				
			when others=>
				readout_state <= idle_st;
				
		end case;
	end if;
end process;

end rtl;