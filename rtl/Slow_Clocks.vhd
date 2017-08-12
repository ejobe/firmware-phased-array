---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         slow_clocks.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         1/2016
--
-- DESCRIPTION:  generate slow clocks for house-keeping
--
---------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Slow_Clocks is
	generic (clk_divide_by : integer := 500);  -- default output is 1kHz
	
	port(		IN_CLK	:	in		std_logic;  --nominally 1MHz
				Reset		:	in		std_logic;	--active hi
								
				
				OUT_CLK	: 	out	std_logic);
				
end Slow_Clocks;

architecture rtl of Slow_Clocks is
	type		STATE_TYPE 	is (CLK_HI, CLK_LO);
	signal	xCLK_STATE	:	STATE_TYPE;
	signal	xOUT_CLK		:	std_logic;
	
begin

	OUT_CLK <= xOUT_CLK;

	process(IN_CLK, Reset)
	variable i: integer range clk_divide_by downto 0 := 0;
	begin
		
		if	Reset = '1' then
			xOUT_CLK		<= '0';
			i 				:=  0;
			xCLK_STATE	<= CLK_HI;
			
		elsif rising_edge(IN_CLK) then
		
			case xCLK_STATE is
				
					when CLK_HI =>
						xOUT_CLK <= '1';
						i 	:= i + 1;
						
						if i = clk_divide_by then
							i	:= 0;
							xCLK_STATE <= CLK_LO;	
						end if;
							
					when CLK_LO =>
						xOUT_CLK <= '0';
						i 	:= i + 1;
						
						if i = clk_divide_by then
							i	:= 0;
							xCLK_STATE <= CLK_HI;	
						end if;
			
					when others =>
						xCLK_STATE <= CLK_LO;	
				
			end case;
		end if;
	end process;
	
end rtl;

	