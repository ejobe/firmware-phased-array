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
-- DESCRIPTION:  resets
--
---------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;

entity sys_reset is
	Port(
		clk_i				:	in		std_logic;   --//25 MHz clock
		clk_rdy_i		:	in		std_logic;
		reg_i				:  in 	register_array_type;
		reset_o			:	out	std_logic;	--//active hi -- THIS IS THE GLOBAL RESET
		reset_sys_o		:  out   std_logic;  --//active hi -- THIS RESETS EVERYTHING EXCEPT THE REGISTER VALUES
		--//start-up signals for external circuits, only toggled on power-up
		pll_strtup_o	:  out	std_logic; 
		dsa_strtup_o	:	out	std_logic;
		adc_strtup_o	:	out	std_logic;
		adc_reset_o		:	out	std_logic);
		
end sys_reset;

architecture rtl of sys_reset is

	type 		power_on_reset_state_type is (CLEAR, READY);
	signal	power_on_reset_state	:	power_on_reset_state_type := CLEAR;
	
	signal	fpga_reset_count	:	std_logic_vector(31 downto 0) := (others=>'0');
	signal	fpga_reset_pwr		:	std_logic := '1';
	signal	fpga_reset_usr		:	std_logic := '0';
	signal 	fpga_reset_sys_usr:	std_logic := '0';
	signal 	adc_reset_usr		:	std_logic := '0';
	
	signal	power_seq_count	:	std_logic_vector(31 downto 0);
	signal 	adc_strtup			: 	std_logic;
	signal 	dsa_strtup			:	std_logic;
	signal	pll_strtup			:	std_logic;
	
begin

reset_o			<= fpga_reset_pwr or fpga_reset_usr; --//global full reset
reset_sys_o		<= fpga_reset_sys_usr;   --//aux user reset 
--//power-on RESET:
proc_reset_powerup : process(clk_i, fpga_reset_count)
begin
	if rising_edge(clk_i) then 
		case power_on_reset_state is
			when CLEAR =>
				fpga_reset_pwr <= '1';
				
				if fpga_reset_count >= x"028FFFE7" then --//about 1.7 sec at 25 MHz
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

--//user-initiated global reset
xUSER_RESET : entity work.pulse_stretcher_sync(rtl)
generic map(stretch => 50000000) --//2 second reset
port map(
	rst_i		=> fpga_reset_pwr,
	clk_i		=> clk_i,
	pulse_i	=> reg_i(127)(0), --//reset bit in reset register
	pulse_o	=> fpga_reset_usr);

--//reset everything except the register values
xUSER_SYS_RESET : entity work.pulse_stretcher_sync(rtl)
generic map(stretch => 50000000) --//2 second reset
port map(
	rst_i		=> fpga_reset_pwr or fpga_reset_usr,
	clk_i		=> clk_i,
	pulse_i	=> reg_i(127)(1), --// bit in reset register
	pulse_o	=> fpga_reset_sys_usr);	

--//user-initiated reset of ADCs only
xADC_RESET : entity work.pulse_stretcher_sync(rtl)
generic map(stretch => 2500000) --//0.1 second reset
port map(
	rst_i		=> fpga_reset_pwr or fpga_reset_usr,
	clk_i		=> clk_i,
	pulse_i	=> reg_i(127)(2), --//adc reset bit in reset register
	pulse_o	=> adc_reset_usr);

--//simple power-up sequence
--//start PLL before ADC to make sure ADC has correct clock
proc_power_sequence : process(clk_i, fpga_reset_pwr, fpga_reset_usr)
begin
	if fpga_reset_pwr = '1' or fpga_reset_usr = '1' then	
		power_seq_count <= (others=>'0');
		pll_strtup <= '0';	 
		dsa_strtup <= '0';
		adc_strtup <= '0';
	elsif rising_edge(clk_i) and (fpga_reset_pwr = '0' and fpga_reset_usr = '0') then
		power_seq_count <= power_seq_count + 1;
		
		if power_seq_count > x"031FFFE7" then
			adc_strtup <= '1';
		elsif power_seq_count > x"0018FFE7" then	
			pll_strtup <= '1';
			dsa_strtup <= '1';
		end if;
	end if;
end process;

xPLL_RESET : entity work.pulse_stretcher_sync(rtl)
generic map(stretch => 375)
port map(
	rst_i		=> fpga_reset_pwr,
	clk_i		=> clk_i,
	pulse_i	=> pll_strtup,
	pulse_o	=> pll_strtup_o);
	
xDSA_RESET : entity work.pulse_stretcher_sync(rtl)
generic map(stretch => 375)
port map(
	rst_i		=> fpga_reset_pwr,
	clk_i		=> clk_i,
	pulse_i	=> dsa_strtup,
	pulse_o	=> dsa_strtup_o);

adc_strtup_o <= adc_strtup;
adc_reset_o <=  adc_reset_usr;	
end rtl;

