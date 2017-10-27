---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         clock_manager.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         1/2016
--
-- DESCRIPTION:  clocks, top level manager
--
---------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity Clock_Manager is
	Port(
		Reset_i			:  in		std_logic;
		CLK0_i			:	in		std_logic;
		CLK1_i			:  in		std_logic;
		PLL_reset_i		:  in		std_logic;
		
		CLK_250MHz_o 	:  out	std_logic;
		CLK_93MHz_o		:  out	std_logic;  
		CLK_25MHz_o		:  inout	std_logic;  --//main logic clock
		CLK_10MHz_o		:	out	std_logic;
		CLK_1MHz_o		:  out	std_logic;
		CLK_1Hz_o		:  out	std_logic;
		CLK_10Hz_o		:  out	std_logic;
		CLK_1kHz_o		:	out	std_logic;
		CLK_100kHz_o	:	out	std_logic;
		
		refresh_1Hz_o		:	out	std_logic;  --//refresh pulse derived from CLK_15MHz_o
		refresh_100mHz_o 	:	out	std_logic;	--//refresh pulse derived from CLK_15MHz_o every 10 s

		fpga_fastpllLock_o : inout std_logic;
		fpga_pllLock_o	:	inout	std_logic);  --lock signal from main PLL on fpga

end Clock_Manager;

architecture rtl of Clock_Manager is
	
	signal clk_1MHz_sig	: 	std_logic;
	
	--//need to create a single pulse every Hz with width of 15 MHz clock period
	signal refresh_clk_counter_1Hz 	:	std_logic_vector(27 downto 0) := (others=>'0');
	signal refresh_clk_counter_100mHz:	std_logic_vector(27 downto 0) := (others=>'0');

	signal refresh_clk_1Hz				:	std_logic := '0';
	signal refresh_clk_100mHz			:	std_logic := '0';
	
	--//for 7.5 MHz
	--constant REFRESH_CLK_MATCH_1HZ 		: 	std_logic_vector(23 downto 0) := x"7270E0";  --//7.5e6
	--constant REFRESH_CLK_MATCH_100mHz 	: 	std_logic_vector(27 downto 0) := x"47868C0";  --//7.5e7
	--//for 15 MHz
	--constant REFRESH_CLK_MATCH_1HZ 		: 	std_logic_vector(27 downto 0) := x"0E4E1C0";  --//7.5e6
	--constant REFRESH_CLK_MATCH_100mHz 	: 	std_logic_vector(27 downto 0) := x"8F0D180";  --//7.5e7
	--//for 25 MHz
	--constant REFRESH_CLK_MATCH_1HZ 		: 	std_logic_vector(27 downto 0) := x"17D7840";  --//25e6
	--constant REFRESH_CLK_MATCH_100mHz 	: 	std_logic_vector(27 downto 0) := x"EE6B280";  --//25e7
	--//for 23.475 MHz
	constant REFRESH_CLK_MATCH_1HZ 		: 	std_logic_vector(27 downto 0) := x"165A0BC";  --//23.4375e6
	constant REFRESH_CLK_MATCH_100mHz 	: 	std_logic_vector(27 downto 0) := x"DF84758";  --//23.4375e6	
	
	
	component pll_block
		port( refclk, rst			: in 	std_logic;
				outclk_0, outclk_1, 
				outclk_2,
				locked				: out	std_logic);
	end component;
	
	component pll_block_2
		port( refclk, rst			: in 	std_logic;
				outclk_0, outclk_1,
				locked				: out	std_logic);
	end component;
	
	component Slow_Clocks
		generic(clk_divide_by   : integer := 500);
		port( IN_CLK, Reset		: in	std_logic;
				OUT_CLK				: out	std_logic);
	end component;	
	
begin
	CLK_1MHz_o			<=	clk_1MHz_sig;
	refresh_1Hz_o		<= refresh_clk_1Hz;
	refresh_100mHz_o	<=	refresh_clk_100mHz;
	
	xPLL_BLOCK : pll_block
		port map(CLK0_i, PLL_reset_i, CLK_93MHz_o, CLK_25MHz_o, 
					clk_1MHz_sig, fpga_pllLock_o);
					
	xPLL_BLOCK_2 : pll_block_2
		port map(CLK1_i, PLL_reset_i or Reset_i, CLK_250MHz_o, CLK_10MHz_o, 
					fpga_fastpllLock_o);
					
	xCLK_GEN_100kHz : Slow_Clocks
		generic map(clk_divide_by => 5)
		port map(clk_1MHz_sig, Reset_i, CLK_100kHz_o);
	
	xCLK_GEN_1kHz : Slow_Clocks
		generic map(clk_divide_by => 500)
		port map(clk_1MHz_sig, Reset_i, CLK_1kHz_o);

	xCLK_GEN_10Hz : Slow_Clocks
		generic map(clk_divide_by => 50000)
		port map(clk_1MHz_sig, Reset_i, CLK_10Hz_o);
		
	xCLK_GEN_1Hz : Slow_Clocks
		generic map(clk_divide_by => 500000)
		port map(clk_1MHz_sig, Reset_i, CLK_1Hz_o);
		
	--/////////////////////////////////////////////////////////////////////////////////
	--//make 1 Hz and 100mHz refresh pulses from the main iface clock (7.5 OR 15 MHz)
	proc_make_refresh_pulse : process(CLK_25MHz_o)
	begin
		if rising_edge(CLK_25MHz_o) then
			
			if refresh_clk_1Hz = '1' then
				refresh_clk_counter_1Hz <= (others=>'0');
			else
				refresh_clk_counter_1Hz <= refresh_clk_counter_1Hz + 1;
			end if;
			--//pulse refresh when refresh_clk_counter = REFRESH_CLK_MATCH
			case refresh_clk_counter_1Hz is
				when REFRESH_CLK_MATCH_1HZ =>
					refresh_clk_1Hz <= '1';
				when others =>
					refresh_clk_1Hz <= '0';
			end case;
			
			--//////////////////////////////////////
			
			if refresh_clk_100mHz = '1' then
				refresh_clk_counter_100mHz <= (others=>'0');
			else
				refresh_clk_counter_100mHz <= refresh_clk_counter_100mHz + 1;
			end if;
			--//pulse refresh when refresh_clk_counter = REFRESH_CLK_MATCH
			case refresh_clk_counter_100mHz is
				when REFRESH_CLK_MATCH_100mHz =>
					refresh_clk_100mHz <= '1';
				when others =>
					refresh_clk_100mHz <= '0';
			end case;
			
		end if;
	end process;
	
end rtl;