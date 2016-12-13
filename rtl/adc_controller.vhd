---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         adc_controller.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         10/2016
--
-- DESCRIPTION:  control bits for TI 7-bit ADC
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity adc_controller is
	Port(
		clk_i				:	in		std_logic; --// slow clock
		clk_core_i		:	in		std_logic; --// data clock for syncing ADC data outputs
		rst_i				:	in		std_logic; --// reset
		pwr_up_i 		:	in		std_logic; --// pwr-up signal (pwr up when=1). ADC's should be started after the PLL

		pd_o					: 	out	std_logic_vector(3 downto 0); --//power-down (active high)
		sdat_oedge_ddr_o	:	out	std_logic_vector(3 downto 0);	--//sdata OR manage ddr settings
		caldly_scs_o		:	out	std_logic_vector(3 downto 0);	--//calibration setup delay OR serial cs
		drst_sel_o			:	out	std_logic; --//drst select single-ende or differential
		pd_q_o				:	out	std_logic; --//power-down q-channel only, board-common
		sclk_outv_o			:	out	std_logic; --//serial clk OR lvds data output voltage
		ece_o					: 	out	std_logic; --//extended-control enable, board-common
		cal_o					:	out	std_logic; --//toggle calibration cycle, board-common
		dclk_rst_lvds_o	:	out	std_logic_vector(3 downto 0); --//lvds dclk rst to sync data stream from ADCs
		
		dat_valid_o			:	inout	std_logic);
		
end adc_controller;		
		
architecture rtl of adc_controller is
type adc_startup_state_type is (pwr_st, cal_st, rdy_st, done_st);
signal adc_startup_state : adc_startup_state_type;

signal internal_dclk_rst : std_logic;

begin
pd_o <= not pwr_up_i & not pwr_up_i & not pwr_up_i & not pwr_up_i;

ece_o <= '1'; --'1';  --//for now, disable extended control mode
pd_q_o <= '0'; --//won't turn off q channel independently, so keep this low
--cal_o <= '0';  --//if uncommented, only calibrate upon power-up
drst_sel_o <= '0'; --//use drst in differential mode
sclk_outv_o	<= '0'; --//when ece is disabled, '1'=normal LVDS voltage; '0'=reduced (might try this for lower power)
sdat_oedge_ddr_o <= "0000"; --//when ece is disabled, '0'= outedge is SDR + 90 degrees from data edge (not DDR!)
caldly_scs_o <= "0000"; --//when ece is disabled, set caldly to 0
--dclk_rst_lvds_o <= "1111"; 

--//---------------------------------------------------------------
--//when caldly = 0, corresponds to 2^26 clock cycles
--//when caldly = 1, corresponds  to 2^32 clock cycles
--//cal pin assert/de-assert: allot ~3000 clock cycles (1280 + 1280 + extra)
--//
--//let's just wait for 1 whole second before setting dat_valid_o
proc_wait_for_cal_cycle : process(rst_i, pwr_up_i, clk_i)
variable i : integer range 0 to 10000001 := 0;
begin
	if rst_i='1' or pwr_up_i='0' then
		i:= 0;
		dat_valid_o <= '0';
		cal_o <= '0';
		internal_dclk_rst <= '0';
		adc_startup_state <= pwr_st;
	elsif rising_edge(clk_i) and pwr_up_i = '1' then
		case adc_startup_state is
			when pwr_st => 
				if i >= 8000000 then	--//wait 8 seconds
					i := 0;
					adc_startup_state <= cal_st;
				else 
					i:= i + 1;
				end if;
				
			when cal_st =>
				if i >= 1200 then	--//cal pulse >1280 clock cycles in length
					i := 0;
					cal_o <= '0';  --// set cal pin low again
					adc_startup_state <= rdy_st;
				elsif i >= 1000 then
					cal_o <= '1'; --//set cal pin high
					i := i + 1;
				else
					cal_o <= '0'; --// set cal pin low
					i := i + 1;
				end if;
				
			when rdy_st => 
				cal_o <= '0';
				if i >= 3000000 then  --//cal cycle takes 1.4e6 clock cycles
					i := 0;
					adc_startup_state <= done_st;
				elsif i >= 2999999 then
					internal_dclk_rst <= '1'; --//to sync up data clocks, toggle the process below
					i := i + 1;
				else 
					i := i + 1;
				end if;
			
			when done_st =>
				dat_valid_o <= '1';
			
		end case;
	end if;
end process;

proc_dclk_rst : process(rst_i, clk_core_i, internal_dclk_rst, dat_valid_o)
variable i : integer range 1000 downto 0 := 0;
begin
	if rst_i = '1' or pwr_up_i='0' then
		i := 0;
		dclk_rst_lvds_o <= "1111";
	elsif rising_edge(clk_core_i) and internal_dclk_rst = '1' and dat_valid_o = '1' then
		
		if i >= 100 then
			dclk_rst_lvds_o <= "1111"; --//de-assert pulse
		else
			dclk_rst_lvds_o <= "0000";
			i := i + 1;
		end if;
	elsif rising_edge(clk_core_i) and internal_dclk_rst = '1' and dat_valid_o = '0' then	
		i := 0;
		dclk_rst_lvds_o <= "0000";  --//send pulse (active low)
	end if;
end process;
end rtl;