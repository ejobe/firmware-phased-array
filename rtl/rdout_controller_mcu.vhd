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
		ram_data_i				:	in		full_data_type; --//data stored in fpga ram
		ram_beam_i				:	in		array_of_beams_type; --//data stored in fpga ram
		ram_powsum_i			:  in		array_of_beams_type; --//data stored in powersum ram
		read_clk_o				:	out	std_logic;
		
		tx_rdy_o					:	out	std_logic;  --// tx ready flag
		tx_rdy_spi_i			:	in		std_logic;  --// spi_slave tx_rdy signal
		tx_ack_i					:	in		std_logic;  --//tx ack from spi_slave (newer spi_slave module ONLY)
		
		rdout_ram_rd_en_o		:	out	std_logic_vector(7 downto 0); --//read enable for ram blocks holding waveforms (1 per channel)
		rdout_beam_rd_en_o	:  out	std_logic_vector(define_num_beams-1 downto 0); --//read enable for ram blocks holding beamforms (1 per beam)
		rdout_powsum_rd_en_o : 	out   std_logic_vector(define_num_beams-1 downto 0); --//read enable for ram blocks holding power info (1 per beam)
		
		rdout_adr_o				:	buffer	std_logic_vector(define_data_ram_depth-1 downto 0);
		rdout_fpga_data_o		:	out		std_logic_vector(d_width-1 downto 0)); --//data to send off-fpga
		
end rdout_controller_mcu;

architecture rtl of rdout_controller_mcu is
type readout_state_type is (idle_st, set_readout_reg_st, tx_st);
signal readout_state : readout_state_type;

--//masks to choose readout data type
signal register_mask		: std_logic_vector(d_width-1 downto 0); 
signal data_mask			: std_logic_vector(d_width-1 downto 0); 
signal beam_mask			: std_logic_vector(d_width-1 downto 0); 
signal pow_mask			: std_logic_vector(d_width-1 downto 0);

signal read_ch : integer range 0 to 7 := 0;
signal beam_ch : integer range 0 to 10 := 0; --update this when changing the number of beams
signal ram_chunk : integer range 0 to 3 := 0; --needs updating if spi_slave d_width changes, or ram_width changes

begin


--//////////////////////////////////////////////
--//update readout parameters from registers on clk_i
--//
process(clk_i, rst_i, registers_i)
begin

	if rst_i = '1' then
		read_ch <= 0;
		beam_ch <= 0;
		ram_chunk <= 0;
		rdout_adr_o <= (others=>'0');
		
		register_mask 	<= (others=>'0');
		data_mask 		<= (others=>'0');
		beam_mask 		<= (others=>'0');
		pow_mask 		<= (others=>'0');
		
		rdout_ram_rd_en_o 	<= (others=>'0'); --/wfm ram read en
		rdout_beam_rd_en_o 	<= (others=>'0'); --/beamform ram read en
		rdout_powsum_rd_en_o <= (others=>'0'); --/powsum ram read en
		
	elsif rising_edge(clk_i) then
		--//////////////////////////////////////
		--//update readout channel
		case registers_i(base_adrs_rdout_cntrl+1)(9 downto 0) is
			when "0000000001" => 
				read_ch <= 0;
				beam_ch <= 0;
			when "0000000010" =>
				read_ch <= 1;
				beam_ch <= 1;
			when "0000000100" =>
				read_ch <= 2;
				beam_ch <= 2;
			when "0000001000" => 
				read_ch <= 3;
				beam_ch <= 3;
			when "0000010000" => 
				read_ch <= 4;
				beam_ch <= 4;
			when "0000100000" => 
				read_ch <= 5;
				beam_ch <= 5;
			when "0001000000" => 
				read_ch <= 6;
				beam_ch <= 6;
			when "0010000000" => 
				read_ch <= 7;
				beam_ch <= 7;
			when "0100000000" => 
				read_ch <= 0;
				beam_ch <= 8;
			when "1000000000" => 
				read_ch <= 0;
				beam_ch <= 9;
			when others=>
				read_ch <= 0;
				beam_ch <= 0;
		end case;
		--//////////////////////////////////////
		--//update ram chunk
		case registers_i(base_adrs_rdout_cntrl+9)(1 downto 0) is
			when "00" =>
				ram_chunk <= 0;
			when "01" =>
				ram_chunk <= 1;			
			when "10" =>
				ram_chunk <= 2;
			when "11" =>
				ram_chunk <= 3;
			when others=>
				ram_chunk <= 0;
		end case;
		--//////////////////////////////////////
		--//update readout data type
		case registers_i(base_adrs_rdout_cntrl+2)(1 downto 0) is
			when "00" =>
				register_mask 	<= (others=>'1');
				data_mask 		<= (others=>'0');
				beam_mask 		<= (others=>'0');
				pow_mask 		<= (others=>'0');
			when "01" =>
				register_mask 	<= (others=>'0');
				data_mask 		<= (others=>'1');
				beam_mask 		<= (others=>'0');
				pow_mask 		<= (others=>'0');
			when "10" =>
				register_mask 	<= (others=>'0');
				data_mask 		<= (others=>'0');
				beam_mask 		<= (others=>'1');
				pow_mask 		<= (others=>'0');
			when "11" =>
				register_mask 	<= (others=>'0');
				data_mask 		<= (others=>'0');
				beam_mask 		<= (others=>'0');
				pow_mask 		<= (others=>'1');
			when others=>
				register_mask 	<= (others=>'0');
				data_mask 		<= (others=>'0');
				beam_mask 		<= (others=>'0');
				pow_mask 		<= (others=>'0');
		end case;
		--//////////////////////////////////////
		--//update ram address and ram read enables
		rdout_adr_o 			<= registers_i(base_adrs_rdout_cntrl+5)(define_data_ram_depth-1 downto 0);
		rdout_ram_rd_en_o  	<= registers_i(base_adrs_rdout_cntrl+1)(7 downto 0) and data_mask(7 downto 0);
		rdout_beam_rd_en_o 	<= registers_i(base_adrs_rdout_cntrl+1)(define_num_beams-1 downto 0) and beam_mask(define_num_beams-1 downto 0);
		rdout_powsum_rd_en_o <= registers_i(base_adrs_rdout_cntrl+1)(define_num_beams-1 downto 0) and pow_mask(define_num_beams-1 downto 0);
	end if;
end process;
--///////////////////////////////
--//readout process	
proc_read : process(rst_i, clk_i, reg_adr_i, tx_rdy_spi_i)
begin
	if rst_i = '1' or reg_adr_i = std_logic_vector(to_unsigned(base_adrs_rdout_cntrl+8, define_address_size)) then
		rdout_fpga_data_o		<= (others=>'0'); --/fpga readout data
		tx_rdy_o <= '0'; 								--//tx flag to spi_slave
		readout_state <= idle_st;
		read_clk_o <= '0';
		
	elsif rising_edge(clk_i) then
		case readout_state is
			--// wait for start-readout register to be written
			when idle_st =>
				read_clk_o <= '0';

				tx_rdy_o <= '0';
				rdout_fpga_data_o		<= x"1234DEAD"; --dummy data
				--///////////////////////////////////////////////
				--//if readout register is written, and spi interface is done with last transfer we initiate a transfer:
				if reg_adr_i = std_logic_vector(to_unsigned(base_adrs_rdout_cntrl+7, define_address_size)) and tx_rdy_spi_i = '0' then
					read_clk_o <= '1'; --//pulse the read clock
					rdout_fpga_data_o		<= x"1234BEEF";  --dummy data
					readout_state <= set_readout_reg_st;
				else 
					readout_state <= idle_st;
				end if;
			
			--//assign the readout register to the appropriate data
			when set_readout_reg_st =>
				--//real data assigned here:
				rdout_fpga_data_o <= (ram_data_i(read_ch)((ram_chunk+1)*d_width-1 downto ram_chunk*d_width) and data_mask) or  --//readout wfm
											(ram_beam_i(beam_ch)((ram_chunk+1)*d_width-1 downto ram_chunk*d_width) and beam_mask) or  --//readout beamform
											(ram_powsum_i(beam_ch)((ram_chunk+1)*d_width-1 downto ram_chunk*d_width) and pow_mask) or --//readout power sum
											(rdout_reg_i and register_mask); --//readout register value
				tx_rdy_o <= '1';
				readout_state <= tx_st;
				
--			when tx_st =>
--				read_clk_o <= '0';
--				if i > 2 then
--					tx_rdy_o <= '0';
--					i := 0;
--					readout_state <= idle_st;
--				else
--					i := i+1;
--					tx_rdy_o <= '1';
--				end if;

			when tx_st =>
				read_clk_o <= '0';
				if tx_ack_i = '1' then
					tx_rdy_o <= '0';
					readout_state <= idle_st;
				else
					tx_rdy_o <= '1';
				end if;
		end case;
	end if;
end process;

end rtl;