---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         rdout_controller.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         10/2016
--
-- DESCRIPTION:  control block for board readout
---------------------------------------------------------------------------------

library IEEE; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

entity rdout_controller is		
	port(
		rst_i					:	in		std_logic;	
		clk_i					:  in		std_logic; --//data clock=>rdout_fpga_data_o set on falling edge of this clock
		clk_interface_i	:	in		std_logic; --//interface clock (USB_IFCLK when using usb, or microcontroller iface)
														 --//clk_interface_i => write on falling edge			
		rdout_reg_i			:	in		std_logic_vector(define_register_size-1 downto 0);
		reg_adr_i			:	in		std_logic_vector(define_address_size-1 downto 0);
		registers_i			:	in		register_array_type;         
		ram_data_i			:	in		full_data_type; --//data stored in fpga ram
		ram_beam_i			:	in		array_of_beams_type; --//data stored in fpga ram
		ram_powsum_i		:  in		sum_power_type;
		
		rdout_start_o		:	out	std_logic;
		
		rdout_ram_rd_en_o		:	out	std_logic_vector(7 downto 0);
		rdout_beam_rd_en_o	:  out	std_logic_vector(define_num_beams-1 downto 0);
		rdout_powsum_rd_en_o : 	out   std_logic_vector(define_num_beams-1 downto 0);
		
		rdout_pckt_size_o	:	out	std_logic_vector(15 downto 0); --//length of readout
		rdout_adr_o			:	inout	std_logic_vector(define_data_ram_depth-1 downto 0);
		rdout_fpga_data_o	:	out	std_logic_vector(15 downto 0));
		
end rdout_controller;

architecture rtl of rdout_controller is
type readout_state_type is (start_st, read_st, pckt_end_st, done_st);
signal readout_register_state : readout_state_type;
signal readout_data_state : readout_state_type;

signal data_mask			: std_logic_vector(15 downto 0); 
signal beam_mask			: std_logic_vector(15 downto 0); 
signal pow_mask			: std_logic_vector(15 downto 0);

signal start_reg_write : std_logic_vector(1 downto 0);
signal start_dat_write : std_logic_vector(1 downto 0);
signal read_ch : integer range 0 to 7 := 0;
signal beam_ch : integer range 0 to 10 := 0;

begin

--//flag to PC interface blocks that we want to write data from FPGA to PC
rdout_start_o <= start_dat_write(1) or start_reg_write(1);

process(registers_i(base_adrs_rdout_cntrl+1))
begin
	--//readout channel registers
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
end process;
		
--//define length of readout packet, depending on type of readout
process(rst_i, clk_interface_i, start_reg_write(0), start_dat_write(0))
begin
	if rst_i = '1' then
		rdout_pckt_size_o <= x"0005";
	elsif rising_edge(clk_interface_i) and start_reg_write(0) = '1' then
		rdout_pckt_size_o <= registers_i(base_adrs_rdout_cntrl+11)(15 downto 0);
	elsif rising_edge(clk_interface_i) and start_dat_write(0) = '1' then
		rdout_pckt_size_o <= registers_i(base_adrs_rdout_cntrl+10)(15 downto 0);
	end if;
end process;

--//map pulsed addresses into start write strobes
proc_start_reg_write : process(rst_i, reg_adr_i, clk_interface_i)
begin
	if rst_i = '1' or reg_adr_i = std_logic_vector(to_unsigned(base_adrs_rdout_cntrl+8, define_address_size)) then
		start_reg_write <= "00";
		start_dat_write <= "00";
		
		data_mask 		<= (others=>'0');
		beam_mask 		<= (others=>'0');
		pow_mask 		<= (others=>'0');

	elsif rising_edge(clk_interface_i) then
		start_reg_write(1) <= start_reg_write(0);
		start_dat_write(1) <= start_dat_write(0);
		
		data_mask         <= (others=> registers_i(base_adrs_rdout_cntrl+2)(0)); --//picks between data ram
		beam_mask         <= (others=> registers_i(base_adrs_rdout_cntrl+2)(1)); --//picks between beam ram
		pow_mask          <= (others=> registers_i(base_adrs_rdout_cntrl+2)(2)); --//picks between power ram

		--//this nested 'if' loop is bad vhdl, but clk_interface_i should be relatively slow
--		if readout_register_state = done_st then
--			start_reg_write(0) <= '0';
--		elsif readout_data_state = done_st then
--			start_dat_write(0) <= '0';
--		else
			case reg_adr_i is
				--//readout registers to PC
				when std_logic_vector(to_unsigned(base_adrs_rdout_cntrl+6, define_address_size)) =>
					start_dat_write(0) <= '0';
					start_dat_write(1) <= '0';

					start_reg_write(0) <= '1';
				--//readout data to PC
				when std_logic_vector(to_unsigned(base_adrs_rdout_cntrl+7, define_address_size)) =>
					start_dat_write(0) <= '1';
					
					start_reg_write(0) <= '0';
					start_reg_write(1) <= '0';

				when others=>
					null;
					--start_reg_write(0) <= start_reg_write(0);
					--start_dat_write(0) <= start_dat_write(0);
		
			end case;
--		end if;
	end if;	
end process;

proc_read : process(rst_i, clk_i, reg_adr_i, start_reg_write(1), start_dat_write(1), rdout_reg_i)
variable i : integer range 0 to 1 := 0;
variable j : integer range -1 to define_serdes_factor-1:= 0;

begin
	if rst_i = '1' or (start_reg_write(1) = '0' and start_dat_write(1) = '0') then
		
		rdout_fpga_data_o <= (others=>'0');
		rdout_adr_o <= (others=>'0');
		i := 0;
		j := 0;
		rdout_ram_rd_en_o 	<= (others=>'0');
		rdout_beam_rd_en_o 	<= (others=>'0');
		readout_register_state <= start_st;
		readout_data_state <= start_st;
   --/////////////////////////////////////////////////////
	--//read register data
	elsif falling_edge(clk_i) and start_reg_write(1) = '1' then
		case readout_register_state is
			when start_st =>
				i:=0;
				rdout_fpga_data_o <= x"1234";
				readout_register_state <= read_st;
			when read_st =>
				if i = 1 then
					rdout_fpga_data_o <= rdout_reg_i(31 downto 16);
					i := 0;
					readout_register_state <= pckt_end_st;
				else
					rdout_fpga_data_o <= rdout_reg_i(15 downto 0);
					i := i+1;
					readout_register_state <= read_st;
				end if;
			when pckt_end_st =>
				i:=0;
				rdout_fpga_data_o <= x"4321";
				readout_register_state <= done_st;
			when done_st =>
				i:=0;
				rdout_fpga_data_o <= x"FFFF";
			when others=>
				readout_register_state <= start_st;
		end case;
	--/////////////////////////////////////////////////////
	--//read ram data
	elsif falling_edge(clk_i) and start_dat_write(1) = '1' then
		case readout_data_state is
			when start_st =>
				--//set start readout address:
				rdout_adr_o <= registers_i(base_adrs_rdout_cntrl+3)(define_data_ram_depth-1 downto 0);
				
				--//enable ram read enable on specified data (or beam) RAM channel:
				rdout_ram_rd_en_o  <= registers_i(base_adrs_rdout_cntrl+1)(7 downto 0) and data_mask(7 downto 0);
				rdout_beam_rd_en_o <= registers_i(base_adrs_rdout_cntrl+1)(define_num_beams-1 downto 0) and beam_mask(define_num_beams-1 downto 0);
				rdout_powsum_rd_en_o <= registers_i(base_adrs_rdout_cntrl+1)(define_num_beams-1 downto 0) and pow_mask(define_num_beams-1 downto 0);

				if j = 1 then
					j := -1;
					rdout_fpga_data_o <= "0001" & x"ABC";
					readout_data_state <= read_st;
				else
					rdout_fpga_data_o <= x"1234";
					j := j+1;
					readout_data_state <= start_st;
				end if;
			
			when read_st=>
				--//Some complicated stuff particular to the deserialization scheme and RAM size.
				--//Basically, each ram address holds define_serdes_factor 16-bit words. We need to cycle through 8 readout
				--//clocks at each ram read address.
				j := j + 1;
				if j = 0 then
					rdout_fpga_data_o <= (ram_data_i(read_ch)(15 downto 0) and data_mask) or 
												(ram_beam_i(beam_ch)(15 downto 0) and beam_mask) or
												(ram_powsum_i(beam_ch)(15 downto 0) and pow_mask);
					readout_data_state <= read_st;
				elsif j = 1 then
					rdout_fpga_data_o <= (ram_data_i(read_ch)(31 downto 16) and data_mask) or 
												(ram_beam_i(beam_ch)(31 downto 16) and beam_mask) or
												(ram_powsum_i(beam_ch)(31 downto 16) and pow_mask);
					readout_data_state <= read_st;
				elsif j = 2 then
					rdout_fpga_data_o <= (ram_data_i(read_ch)(47 downto 32) and data_mask) or 
												(ram_beam_i(beam_ch)(47 downto 32) and beam_mask) or
												(ram_powsum_i(beam_ch)(47 downto 32) and pow_mask);
					readout_data_state <= read_st;
				elsif j = 3 then
					rdout_fpga_data_o <= (ram_data_i(read_ch)(63 downto 48) and data_mask) or 
												(ram_beam_i(beam_ch)(63 downto 48) and beam_mask) or
												(ram_powsum_i(beam_ch)(63 downto 48) and pow_mask);
					readout_data_state <= read_st;
				elsif j = 4 then
					rdout_fpga_data_o <= (ram_data_i(read_ch)(79 downto 64) and data_mask) or 
												(ram_beam_i(beam_ch)(79 downto 64) and beam_mask) or
												(ram_powsum_i(beam_ch)(79 downto 64) and pow_mask);
					readout_data_state <= read_st;
				elsif j = 5 then
					rdout_fpga_data_o <= (ram_data_i(read_ch)(95 downto 80) and data_mask) or 
												(ram_beam_i(beam_ch)(95 downto 80) and beam_mask) or
												(ram_powsum_i(beam_ch)(95 downto 80) and pow_mask);
					readout_data_state <= read_st;
				elsif j = (define_serdes_factor-2) then
					rdout_fpga_data_o <= (ram_data_i(read_ch)(111 downto 96) and data_mask) or 
												(ram_beam_i(beam_ch)(111 downto 96) and beam_mask) or
												(ram_powsum_i(beam_ch)(111 downto 96) and pow_mask);
					rdout_adr_o <= rdout_adr_o + 1; --//toggle next ram adr
					readout_data_state <= read_st;
				elsif j = (define_serdes_factor-1) then
					rdout_fpga_data_o <= (ram_data_i(read_ch)(127 downto 112) and data_mask) or 
												(ram_beam_i(beam_ch)(127 downto 112) and beam_mask) or
												(ram_powsum_i(beam_ch)(127 downto 112) and pow_mask);
					
					if rdout_adr_o >= registers_i(base_adrs_rdout_cntrl+4)(define_data_ram_depth-1 downto 0) then
						j := 0;
						readout_data_state <= pckt_end_st;
					else
--						rdout_adr_o <= rdout_adr_o + 1;
						j := -1;
						readout_data_state <= read_st;
					end if;
				
				end if;
			
			when pckt_end_st =>
				j:=0;
				rdout_ram_rd_en_o <= (others=>'0'); --//disable ram read enable
				rdout_fpga_data_o <= x"4321";	
				rdout_adr_o <= registers_i(base_adrs_rdout_cntrl+3)(define_data_ram_depth-1 downto 0);
				readout_data_state <= done_st;
				
			when done_st =>
				rdout_fpga_data_o <= x"FFFF";
			when others =>
				readout_data_state <= start_st;
		end case;
	end if;
end process;

end rtl;