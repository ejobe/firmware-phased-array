---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         pll_controller.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         10/2016
--
-- DESCRIPTION:  control block for LMK04808 clock generator
---------------------------------------------------------------------------------
--//
library IEEE; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity pll_controller is		
	port(
		rst_i			:	in		std_logic;
		clk_i			:	in		std_logic; --// stick with 1 MHz or less
		reg_i			: 	in		std_logic_vector(31 downto 0);
		
		write_i		:	in		std_logic;
		done_o		:	out	std_logic;
		
		lmk_sdata_o	:	out	std_logic;
		lmk_sclk_o	:	out	std_logic;
		lmk_le_o		: 	out	std_logic;
		
		pll_sync_o	:	out	std_logic); --//sync pll outputs, active low
		
end pll_controller;


architecture rtl of pll_controller is

type lmk_reg_type is array(31 downto 0) of std_logic_vector(31 downto 0);
signal lmk_reg  :	lmk_reg_type;
signal lmk_reg_init : std_logic_vector(31 downto 0);

signal current_reg 				: std_logic_vector(31 downto 0);
signal single_done_strobe 		: std_logic;
signal single_write_strobe 	: std_logic;
signal internal_spi_write 		: std_logic;

type lmk_write_state_type is (idle_st, write_st, wait_for_ack_st, done_st);
signal lmk_write_state : lmk_write_state_type;

type lmk_sync_state_type is (idle_st, sync_st, done_st);
signal lmk_sync_state : lmk_sync_state_type;

begin

--//process to sync clock outputs of lmk pll chip
--//toggles the sync pulse (active low) after spi programming is completed.
proc_pll_sync : process(rst_i, clk_i, lmk_write_state)
	variable j : integer range 0 to 10 := 0;
begin
	if rst_i = '1' then
		pll_sync_o <= '1';
		j := 0;
		lmk_sync_state <= idle_st;
	elsif rising_edge(clk_i) then 
		case lmk_sync_state is
			
			when idle_st =>
				pll_sync_o <= '1'; 
				if lmk_write_state = done_st then
					lmk_sync_state <= sync_st;
				end if;
			
			when sync_st =>
				j := j + 1;
				
				if j >= 9 then
					pll_sync_o <= '1';
					j := 0;
					lmk_sync_state <= done_st;
					
				elsif j > 4 then
					pll_sync_o <= '0';
					lmk_sync_state <= sync_st;
				end if;
				
			when done_st => 
				j := 0;
				pll_sync_o <= '1';
		end case;
	end if;
end process;

--//lmk serial programming:
proc_set_reg : process(rst_i, clk_i)
begin
	--if rst_i = '1' then
		--//set default code register values:
		--lmk_reg(0) <= x"80160180"; --//noted as 'init'
		lmk_reg_init <= x"80160180";
		lmk_reg(0) <= x"80140180"; --// clkout 0,1
		lmk_reg(1) <= x"80140181"; --// clkout 2,3
		lmk_reg(2) <= x"00140042";               --x"00140082"; --"x00140042"; --// clkout 4,5 :: adc 1.5 GHz clocks
		lmk_reg(3) <= x"00140043";               --x"00140083"; --x"00140043"; --// clkout 6,7 :: adc 1.5 GHz clocks
		lmk_reg(4) <= x"00140044"; --x"80140144";--x"00140044";--x"00140084"; --x"00140044"; --// clkout 8,9 
		lmk_reg(5) <= x"80140145"; --x"00140085"; --x"00140045"; --// clkout 10,11 :: 
		lmk_reg(6) <= x"04040006";
		lmk_reg(7) <= x"11110007";
		lmk_reg(8) <= x"04010008";
		lmk_reg(9) <= x"55555549";
		lmk_reg(10) <= x"9142498A";
		lmk_reg(11) <= x"4401100B";
		lmk_reg(12) <= x"110C006C"; --x"1B0C006C" --//set LD_MUX to PLL2 lock only
		lmk_reg(13) <= x"2302800D"; --x"2302806D" --//disable clkin0 and 1
		lmk_reg(14) <= x"0200000E";
		lmk_reg(15) <= x"8000800F";
		lmk_reg(16) <= x"C1550410";
		--//registers 17-22 not defined in datasheet
		--//register 23 defined as a read-only register
		lmk_reg(24) <= x"00000058";
		lmk_reg(25) <= x"02C9C419";
		lmk_reg(26) <= x"AFA8009A";
		lmk_reg(27) <= x"10001E1B";
		lmk_reg(28) <= x"00201E1C";
		lmk_reg(29) <= x"018001FD";
		lmk_reg(30) <= x"020001FE";
		lmk_reg(31) <= x"001F001F";
	--end if;
	--//eventually add in method to write registers
end process;

--//register write-start pulse 
--//(make sure write_i pulse isn't too long, otherwise will write multiple times!!)
proc_start_lmk_write : process(rst_i, clk_i, write_i, lmk_write_state)
begin
	if rst_i = '1' then
		internal_spi_write <= '0';
	elsif rising_edge(clk_i) and lmk_write_state = done_st then
		internal_spi_write <= '0';
	elsif rising_edge(clk_i) and write_i = '1' then
		internal_spi_write <= '1';
	end if;
end process;		
	
		
proc_lmk_write : process(rst_i, clk_i, write_i, internal_spi_write)
	variable j : integer range 0 to 26 := 0;
begin
	if rst_i = '1' or internal_spi_write = '0' then
		j := 0;
		current_reg <= (others=>'0');
		single_write_strobe <= '0';
		lmk_write_state <= idle_st;
		done_o <= '0';
	elsif rising_edge(clk_i) and internal_spi_write = '1' then
		
		case lmk_write_state is
			
			when idle_st=>
				j := 0;
				single_write_strobe <= '0';
				current_reg <= (others=>'0');
				lmk_write_state <= write_st;
				
			when write_st => 
				if j = 26 then  --//done!
					j:=0;
					done_o <= '1';
					current_reg <= (others=>'0');
					lmk_write_state <= done_st;
					
				elsif j = 0 then
					single_write_strobe <= '1';
					current_reg <= lmk_reg_init;
					lmk_write_state <= wait_for_ack_st;
				elsif j > 17 then
					single_write_strobe <= '1';
					current_reg <= lmk_reg(j+6);	
					lmk_write_state <= wait_for_ack_st;		
				else
					single_write_strobe <= '1';
					current_reg <= lmk_reg(j-1);
					lmk_write_state <= wait_for_ack_st;
				end if;
								
			when wait_for_ack_st =>
				single_write_strobe <= '0';
				if single_done_strobe = '1' then
					j := j + 1;
					lmk_write_state <= write_st;
				else
					lmk_write_state <= wait_for_ack_st;
				end if;
					
			when done_st =>
				done_o <= '1';
				
			when others=>
				lmk_write_state <= idle_st;
		end case;
	end if;
end process;

xSPI_WRITE : entity work.spi_write(rtl)
generic map(
		data_length => 32)
port map(
		rst_i		=> rst_i,
		clk_i		=> clk_i,
		pdat_i	=> current_reg,		
		write_i	=> single_write_strobe,
		done_o	=> single_done_strobe,		
		sdata_o	=> lmk_sdata_o,
		sclk_o	=> lmk_sclk_o,
		le_o		=> lmk_le_o);

end rtl;


		