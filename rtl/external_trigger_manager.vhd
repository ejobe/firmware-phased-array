---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         external_trigger_manager.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         8/2017
--					  		
--
-- DESCRIPTION:  manage external triggering, both input and output
--
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

entity external_trigger_manager is
	generic(
		FIRMWARE_DEVICE : std_logic := '1');
	port(
		rst_i			:	in		std_logic; --//async reset
		trig_clk_i	:	in		std_logic;
		clk_i			:	in		std_logic; --//clock
		ext_i			:	in		std_logic; --//external gate/trigger input
		sys_trig_i	:	in		std_logic; --//firmware generated phased trigger
		reg_i			:  in 	register_array_type; --//programmable registers
		refrsh_pulse_1Hz_i : in std_logic;
		
		sys_trig_o  :  out	std_logic; --//trigger to firmware
		sys_gate_o	:	out	std_logic; --//scaler gate\
		pps_gate_o	:	out	std_logic_vector(1 downto 0); --//can be used to latch firmware timstamp for syncing off-line to PPS
		ext_trig_o	:	out	std_logic); --//external trigger output
end external_trigger_manager;

architecture rtl of external_trigger_manager is

signal internal_gate_reg 		: std_logic_vector(2 downto 0);
signal internal_exttrig_reg 	: std_logic_vector(2 downto 0);
signal internal_exttrig_edge 	: std_logic;
signal internal_gate_generator_output : std_logic;
signal internal_trig_generator_output : std_logic;

begin
--//if PPS plugged on ext trigger input, use to latch timestamp
pps_gate_o <= internal_gate_reg(2 downto 1);
--//external trigger to firmware core:
sys_trig_o <= internal_exttrig_reg(1) and reg_i(75)(0);
--//external trigger off-board assignment:
proc_trig_out_assign : process(reg_i(83), internal_gate_reg, internal_gate_generator_output)
begin
	case reg_i(83)(2) is
		when '0' =>
			ext_trig_o <= internal_trig_generator_output;
		when '1' =>
			ext_trig_o <= refrsh_pulse_1Hz_i;
	end case;
end process;
--//gate generator to firmware core:
proc_gate_out_assign : process(reg_i(75), internal_gate_reg, internal_gate_generator_output)
begin
	case reg_i(75)(1) is
		when '0' =>
			sys_gate_o <= internal_gate_reg(2);
		when '1' =>
			sys_gate_o <= internal_gate_generator_output;
	end case;
end process;

proc_reg_ext : process(rst_i, clk_i, ext_i, internal_gate_reg, internal_exttrig_reg, internal_exttrig_edge)
begin	
	if rst_i = '1' then
		internal_gate_reg <= (others=>'0');
		internal_exttrig_reg <= (others=>'0');
	elsif rising_edge(clk_i) then
		internal_gate_reg <= internal_gate_reg(1 downto 0) & ext_i;
		if internal_exttrig_reg(2) = '1' then
			internal_exttrig_reg <= (others=>'0');
		else
			internal_exttrig_reg <= internal_exttrig_reg(1 downto 0) & internal_exttrig_edge;
		end if;
	end if;
end process;

--//Right now, looks for rising edge only
proc_reg_ext_trigger : process(rst_i, ext_i, internal_exttrig_reg)
begin
	if rst_i = '1' or internal_exttrig_reg(2) = '1' then	
		internal_exttrig_edge <= '0';
	elsif rising_edge(ext_i) then
		internal_exttrig_edge <= '1';
	end if;
end process;

--//gate generator
xGATE_GENERATOR : entity work.pulse_stretcher_sync_programmable(rtl)
generic map(
	stretch_width => 16)
port map(
	rst_i		=> rst_i or (not FIRMWARE_DEVICE),
	clk_i		=> clk_i,
	stretch_i => reg_i(75)(23 downto 8),
	out_pol_i => '1',
	pulse_i	=> internal_gate_reg(1),
	pulse_o	=> internal_gate_generator_output);
	
--//old version used phased trigger on 25Mhz clock:
----//send trigger out:
--xEXT_TRIG_OUT : entity work.pulse_stretcher_sync_programmable(rtl)
--generic map(
--	stretch_width => 8)
--port map(
--	rst_i		=> rst_i or (not reg_i(83)(0)) or (not FIRMWARE_DEVICE),
--	clk_i		=> clk_i,
--	stretch_i => reg_i(83)(15 downto 8),
--	out_pol_i => reg_i(83)(1),
--	pulse_i	=> sys_trig_i,
--	pulse_o	=> internal_trig_generator_output);

--//new version used phased trigger on 93Mhz clock to get it out quicker:
--//send trigger out:
xEXT_TRIG_OUT : entity work.pulse_stretcher_sync_programmable(rtl)
generic map(
	stretch_width => 8)
port map(
	rst_i		=> rst_i or (not reg_i(83)(0)) or (not FIRMWARE_DEVICE),
	clk_i		=> trig_clk_i,
	stretch_i => reg_i(83)(15 downto 8),
	out_pol_i => reg_i(83)(1),
	pulse_i	=> sys_trig_i,
	pulse_o	=> internal_trig_generator_output);

end rtl;