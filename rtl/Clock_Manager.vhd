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
		
		CLK_187p5MHz_o :  out	std_logic;
		CLK_75MHz_o		:  out	std_logic;  
		CLK_15MHz_o		:  out	std_logic;
		CLK_1MHz_o		:  out	std_logic;
		CLK_1Hz_o		:  out	std_logic;
		CLK_10Hz_o		:  out	std_logic;
		CLK_1kHz_o		:	out	std_logic;
		CLK_100kHz_o	:	out	std_logic;

		fpga_pllLock_o	:	out	std_logic);  --lock signal from PLL on fpga

end Clock_Manager;

architecture Structural of Clock_Manager is
	
	signal clk_1MHz_sig	: 	std_logic;
	
	component pll_block
		port( refclk, rst			: in 	std_logic;
				outclk_0, outclk_1, 
				outclk_2,
				locked				: out	std_logic);
	end component;
	
	component pll_block_2
		port( refclk, rst			: in 	std_logic;
				outclk_0, 
				locked				: out	std_logic);
	end component;
	
	component Slow_Clocks
		generic(clk_divide_by   : integer := 500);
		port( IN_CLK, Reset		: in	std_logic;
				OUT_CLK				: out	std_logic);
	end component;	
	
begin
	CLK_1MHz_o	<=	clk_1MHz_sig;

	xPLL_BLOCK : pll_block
		port map(CLK0_i, PLL_reset_i, CLK_75MHz_o, CLK_15MHz_o, 
					clk_1MHz_sig, fpga_pllLock_o);
					
	xPLL_BLOCK_2 : pll_block_2
		port map(CLK1_i, PLL_reset_i, CLK_187p5MHz_o, open);
					
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
		
end Structural;

		
	

