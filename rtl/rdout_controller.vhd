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
	generic(
		readout_mode		:	string := "USB");
	port(
		rst_i					:	in		std_logic;	
		clk_i					:  in		std_logic; --//data clock=>rdout_fpga_data_o set on falling edge of this clock
		clk_interface_i	:	in		std_logic; --//interface clock (always running, USB_IFCLK when using usb)
		
		rdout_reg_i			:	in		std_logic_vector(define_register_size-1 downto 0);
		reg_adr_i			:	in		std_logic_vector(define_address_size-1 downto 0);
		registers_i			:	in		register_array_type;         
		ram_data_i			:	in		full_data_type; --//data stored in fpga ram
		cur_ram_adr_i		:	in		full_address_type; --//current pointer to ram address (should be static if triggered)
		
		rdout_start_o		:	out	std_logic;
		rdout_ram_rd_en_o	:	out	std_logic_vector(7 downto 0);
		rdout_pckt_size_o	:	out	std_logic_vector(15 downto 0); --//length of readout
		rdout_adr_o			:	inout	std_logic_vector(define_ram_depth-1 downto 0);
		rdout_fpga_data_o	:	out	std_logic_vector(15 downto 0));
		
end rdout_controller;

architecture rtl of rdout_controller is
type readout_state_type is (start_st, read_st, done_st);
signal readout_register_state : readout_state_type;
signal readout_data_state : readout_state_type;

signal start_reg_write : std_logic_vector(1 downto 0);
signal start_dat_write : std_logic_vector(1 downto 0);
signal read_ch : integer range 0 to 7 := 0;

begin

--//flag to PC interface blocks that we want to write data from FPGA to PC
rdout_start_o <= start_dat_write(1) or start_reg_write(1);

process(registers_i(base_adrs_rdout_cntrl+1))
begin
case registers_i(base_adrs_rdout_cntrl+1)(7 downto 0) is
	when "00000001" => 
		read_ch <= 0;
	when "00000010" =>
		read_ch <= 1;
	when "00000100" =>
		read_ch <= 2;
	when "00001000" => 
		read_ch <= 3;
	when "00010000" => 
		read_ch <= 4;
	when "00100000" => 
		read_ch <= 5;
	when "01000000" => 
		read_ch <= 6;
	when "10000000" => 
		read_ch <= 7;
	when others=>
		read_ch <= 0;
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
proc_start_reg_write : process(clk_i, rst_i, reg_adr_i, clk_interface_i)
begin
	if rst_i = '1' or reg_adr_i = std_logic_vector(to_unsigned(base_adrs_rdout_cntrl+8, define_address_size)) then
		start_reg_write <= "00";
		start_dat_write <= "00";
	elsif rising_edge(clk_interface_i) then
		start_reg_write(1) <= start_reg_write(0);
		start_dat_write(1) <= start_dat_write(0);

		case reg_adr_i is
			when std_logic_vector(to_unsigned(base_adrs_rdout_cntrl+6, define_address_size)) =>
				start_reg_write(0) <= '1';
			when std_logic_vector(to_unsigned(base_adrs_rdout_cntrl+7, define_address_size)) =>
				start_dat_write(0) <= '1';
			when others=>
				null;
		end case;
	end if;	
end process;

proc_read : process(rst_i, clk_i, reg_adr_i, start_reg_write(1), start_dat_write(1), rdout_reg_i)
variable i : integer range 0 to 1 := 0;
variable j : integer range -1 to 7 := 0;

begin
	if rst_i = '1' or reg_adr_i = std_logic_vector(to_unsigned(base_adrs_rdout_cntrl+8, define_address_size)) then
		rdout_fpga_data_o <= (others=>'0');
		rdout_adr_o <= (others=>'0');
		i := 0;
		j := 0;
		rdout_ram_rd_en_o <= (others=>'0');
		readout_register_state <= start_st;
		readout_data_state <= start_st;

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
					readout_register_state <= done_st;
				else
					rdout_fpga_data_o <= rdout_reg_i(15 downto 0);
					i := i+1;
					readout_register_state <= read_st;
				end if;
			when done_st =>
				i:=0;
				rdout_fpga_data_o <= x"4321";
			when others=>
				readout_register_state <= start_st;
		end case;
	
	--//read ram data
	elsif falling_edge(clk_i) and start_dat_write(1) = '1' then
		case readout_data_state is
			when start_st =>
				--//set start readout address:
				rdout_adr_o <= registers_i(base_adrs_rdout_cntrl+3)(define_ram_depth-1 downto 0);
				--//enable ram read enable on specified channel:
				rdout_ram_rd_en_o <= registers_i(base_adrs_rdout_cntrl+1)(7 downto 0) ;
				
				if j = 1 then
					j := -1;
					rdout_fpga_data_o <= "00000" & cur_ram_adr_i(read_ch);
					readout_data_state <= read_st;
				else
					rdout_fpga_data_o <= x"1234";
					j := j+1;
					readout_register_state <= start_st;
				end if;
			
			when read_st=>
				--//Some complicated stuff particular to the deserialization scheme and RAM size.
				--//Basically, each ram address holds eight 16-bit words. We need to cycle through 8 readout
				--//clocks at each ram read address.
				j := j + 1;
				if j = 0 then
					rdout_fpga_data_o <= ram_data_i(read_ch)(15 downto 0);
					readout_data_state <= read_st;
				elsif j = 1 then
					rdout_fpga_data_o <= ram_data_i(read_ch)(31 downto 16);
					readout_data_state <= read_st;
				elsif j = 2 then
					rdout_fpga_data_o <= ram_data_i(read_ch)(47 downto 32);
					readout_data_state <= read_st;
				elsif j = 3 then
					rdout_fpga_data_o <= ram_data_i(read_ch)(63 downto 48);
					readout_data_state <= read_st;
				elsif j = 4 then
					rdout_fpga_data_o <= ram_data_i(read_ch)(79 downto 64);
					readout_data_state <= read_st;
				elsif j = 5 then
					rdout_fpga_data_o <= ram_data_i(read_ch)(95 downto 80);
					readout_data_state <= read_st;
				elsif j = 6 then
					rdout_fpga_data_o <= ram_data_i(read_ch)(111 downto 96);
					readout_data_state <= read_st;
				elsif j = 7 then
					rdout_fpga_data_o <= ram_data_i(read_ch)(127 downto 112);
					
					if rdout_adr_o >= registers_i(base_adrs_rdout_cntrl+4)(define_ram_depth-1 downto 0) then
						j := 0;
						readout_data_state <= done_st;
					else
						rdout_adr_o <= rdout_adr_o + 1;
						j := -1;
						readout_data_state <= read_st;
					end if;
				
				end if;
				
			when done_st =>
				j:=0;
				rdout_ram_rd_en_o <= (others=>'0'); --//disable ram read enable
				rdout_fpga_data_o <= x"4321";
				rdout_adr_o <= registers_i(base_adrs_rdout_cntrl+3)(define_ram_depth-1 downto 0);
			when others =>
				readout_data_state <= start_st;
		end case;
	end if;
end process;

end rtl;