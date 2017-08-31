---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         atten_controller.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         10/2016
--
-- DESCRIPTION:  control block for RFSA3713 digital-step attenuators
---------------------------------------------------------------------------------

library IEEE; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

entity atten_controller is		
	port(
		rst_i			:	in		std_logic;
		clk_i			:	in		std_logic; --// stick with 1 MHz or less
		reg_i			: 	in		register_array_type; --//phased_array registers: for programmable attenuation levels
		addr_i		:  in 	std_logic_vector(define_address_size-1 downto 0);
		
		write_i		:	in		std_logic;
		done_o		:	out	std_logic;
		
		dsa_sdata_o	:	out	std_logic;
		dsa_sclk_o	:	out	std_logic;
		dsa_le_o		: 	out	std_logic);
		
end atten_controller;

architecture rtl of atten_controller is

type dsa_reg_type is array(7 downto 0) of std_logic_vector(15 downto 0);
signal dsa_reg  :	dsa_reg_type;

signal current_reg 	: std_logic_vector(15 downto 0);
signal single_done_strobe 		: std_logic;
signal single_write_strobe 	: std_logic;
signal internal_spi_write 		: std_logic;
signal internal_spi_write_from_software 		: std_logic;

type dsa_write_state_type is (idle_st, write_st, wait_for_ack_st, done_st);
signal dsa_write_state : dsa_write_state_type;

begin

--//attenuator register is written in this order: data<0:7>, then address<0:7>
dsa_reg(0) <= reg_i(base_adrs_dsa_cntrl+0)(7 downto 0)   & "0000" & x"0";
dsa_reg(1) <= reg_i(base_adrs_dsa_cntrl+0)(15 downto 8)  & "1000" & x"0"; 
dsa_reg(2) <= reg_i(base_adrs_dsa_cntrl+0)(23 downto 16) & "0100" & x"0"; 
dsa_reg(3) <= reg_i(base_adrs_dsa_cntrl+1)(7 downto 0) 	& "1100" & x"0"; 
dsa_reg(4) <= reg_i(base_adrs_dsa_cntrl+1)(15 downto 8) 	& "0010" & x"0"; 
dsa_reg(5) <= reg_i(base_adrs_dsa_cntrl+1)(23 downto 16) & "1010" & x"0";
dsa_reg(6) <= reg_i(base_adrs_dsa_cntrl+2)(7 downto 0) 	& "0110" & x"0"; 
dsa_reg(7) <= reg_i(base_adrs_dsa_cntrl+2)(15 downto 8) 	& "1110" & x"0";	

--proc_set_reg : process(rst_i, clk_i)
--begin
--	if rst_i = '1' then
--		--//set default code register values:
--		--//attenuator register is written in this order: data<0:7>, then address<0:7>
--		dsa_reg(0) <= x"00" & "0000" & x"0";
--		dsa_reg(1) <= x"00" & "1000" & x"0"; 
--		dsa_reg(2) <= x"00" & "0100" & x"0"; 
--		dsa_reg(3) <= x"00" & "1100" & x"0"; 
--		dsa_reg(4) <= x"00" & "0010" & x"0"; 
--		dsa_reg(5) <= x"00" & "1010" & x"0";
--		dsa_reg(6) <= x"00" & "0110" & x"0"; 
--		dsa_reg(7) <= x"00" & "1110" & x"0";	
--	end if;
--	--//eventually add in method to write registers
--end process;

proc_software_write : process(addr_i, rst_i, dsa_write_state)
begin
	if rst_i = '1' or dsa_write_state = done_st  then
		internal_spi_write_from_software <= '0';
	elsif to_integer(unsigned(addr_i)) =  (base_adrs_dsa_cntrl+3) then
		internal_spi_write_from_software <= '1';
	end if;
end process;
	

proc_start_dsa_write : process(rst_i, clk_i, write_i, dsa_write_state, internal_spi_write_from_software)
begin
	if rst_i = '1' then
		internal_spi_write <= '0';
	elsif rising_edge(clk_i) and dsa_write_state = done_st then
		internal_spi_write <= '0';
	elsif rising_edge(clk_i) and (write_i = '1' or internal_spi_write_from_software = '1') then
		internal_spi_write <= '1';
	end if;
end process;		
	
		
proc_dsa_write : process(rst_i, clk_i, write_i, internal_spi_write)
	variable j : integer range 0 to 8 := 0;
begin
	if rst_i = '1' or internal_spi_write = '0' then
		j := 0;
		current_reg <= (others=>'0');
		single_write_strobe <= '0';
		dsa_write_state <= idle_st;
		done_o <= '0';
	elsif rising_edge(clk_i) and internal_spi_write = '1' then
		
		case dsa_write_state is
			
			when idle_st=>
				j := 0;
				single_write_strobe <= '0';
				current_reg <= (others=>'0');
				dsa_write_state <= write_st;
				
			when write_st => 
				if j = 8 then  --//done (when j = number of registers + 1)
					j:=0;
					done_o <= '1';
					current_reg <= (others=>'0');
					dsa_write_state <= done_st;
						
				else
					single_write_strobe <= '1';
					current_reg <= dsa_reg(j);
					dsa_write_state <= wait_for_ack_st;
				end if;
								
			when wait_for_ack_st =>
				single_write_strobe <= '0';
				if single_done_strobe = '1' then
					j := j + 1;
					dsa_write_state <= write_st;
				else
					dsa_write_state <= wait_for_ack_st;
				end if;
					
			when done_st =>
				done_o <= '1';
				
			when others=>
				dsa_write_state <= idle_st;
		end case;
	end if;
end process;

xSPI_WRITE : entity work.spi_write(rtl)
generic map(
		data_length => 16)
port map(
		rst_i		=> rst_i,
		clk_i		=> clk_i,
		pdat_i	=> current_reg,		
		write_i	=> single_write_strobe,
		done_o	=> single_done_strobe,		
		sdata_o	=> dsa_sdata_o,
		sclk_o	=> dsa_sclk_o,
		le_o		=> dsa_le_o);

end rtl;
