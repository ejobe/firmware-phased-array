---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         sys_reset.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         1/2016
--
-- DESCRIPTION:  global resets
--               a numver of typical firmware 'good design techniques' are 
--               abandoned here due to the nature of asynch resets
---------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity sys_reset is
	Port(
		clk_i				:	in		std_logic;  --//1 MHz from FPGA PLL
		clk_rdy_i		:	in		std_logic;
		user_wakeup_i	:	in		std_logic;	--//user input, rising edge
		reset_o			:	out	std_logic;	--//active hi
		--//start-up signals for external circuits, only toggled on power-up
		pll_strtup_o	:  out	std_logic; 
		dsa_strtup_o	:	out	std_logic;
		adc_strtup_o	:	out	std_logic);
		
end sys_reset;

architecture Behavioral of sys_reset is

	type 		power_on_reset_state_type is (CLEAR, READY);
	signal	power_on_reset_state	:	power_on_reset_state_type := CLEAR;
	
	type 		power_on_seq_state_type	is (PLL, ADC);
	signal	power_on_seq_state : power_on_seq_state_type;
	
	signal	fpga_reset_count	:	std_logic_vector(31 downto 0) := (others=>'0');
	signal	fpga_reset_pwr		:	std_logic := '1';
	signal	fpga_reset_usr		:	std_logic;
	
	signal	power_seq_count	:	std_logic_vector(31 downto 0);
	signal 	adc_strtup	: 	std_logic;
	signal 	dsa_strtup	:	std_logic;
	signal	pll_strtup	:	std_logic;
	
begin

reset_o	<= fpga_reset_pwr or fpga_reset_usr; 
--//
proc_reset_powerup : process(clk_i, fpga_reset_count)
begin
	if rising_edge(clk_i) then 
		case power_on_reset_state is
			when CLEAR =>
				fpga_reset_pwr <= '1';
				
				if fpga_reset_count >= x"000FFFFF" then --//about 1 sec at 1 MHz
					power_on_reset_state <= READY;
				else
					fpga_reset_count <= fpga_reset_count + 1;
					power_on_reset_state <= CLEAR;
				end if;
				
			when READY =>
				fpga_reset_pwr <= '0';
			
			when others=>
				null;
		end case;
	end if;
end process;

xUSER_RESET : entity work.pulse_stretcher(rtl)
generic map(stretch => 2000000) --//2 second reset
port map(
	rst_i		=> fpga_reset_pwr,
	clk_i		=> clk_i,
	pulse_i	=> user_wakeup_i,
	pulse_o	=> fpga_reset_usr);

--//simple power-up sequence
--//start PLL before ADC to make sure ADC has correct clock
proc_power_sequence : process(clk_i, fpga_reset_pwr)
begin
	if fpga_reset_pwr = '1' then	
		power_seq_count <= (others=>'0');
		pll_strtup <= '0';	 
		dsa_strtup <= '0';
		adc_strtup <= '0';
	elsif rising_edge(clk_i) and fpga_reset_pwr = '0' then
		power_seq_count <= power_seq_count + 1;
		
		if power_seq_count > x"0001FFFFF" then
			adc_strtup <= '1';
		elsif power_seq_count > x"0000FFFF" then
			pll_strtup <= '1';
			dsa_strtup <= '1';
		end if;
	end if;
end process;

xPLL_RESET : entity work.pulse_stretcher(rtl)
generic map(stretch => to_integer(x"F"))
port map(
	rst_i		=> fpga_reset_pwr,
	clk_i		=> clk_i,
	pulse_i	=> pll_strtup,
	pulse_o	=> pll_strtup_o);
	
xDSA_RESET : entity work.pulse_stretcher(rtl)
generic map(stretch => to_integer(x"F"))
port map(
	rst_i		=> fpga_reset_pwr,
	clk_i		=> clk_i,
	pulse_i	=> dsa_strtup,
	pulse_o	=> dsa_strtup_o);

adc_strtup_o <= adc_strtup;
--xADC_RESET : entity work.pulse_stretcher(rtl)
--generic map(stretch => to_integer(x"F"))
--port map(
--	rst_i		=> fpga_reset_pwr,
--	clk_i		=> clk_i,
--	pulse_i	=> adc_strtup,
--	pulse_o	=> adc_strtup_o);
	
end Behavioral;

