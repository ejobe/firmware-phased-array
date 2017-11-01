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
		clk_i			:	in		std_logic; --//clock
		ext_i			:	in		std_logic; --//external gate/trigger input
		sys_trig_i	:	in		std_logic; --//firmware generated phased trigger
		reg_i			:  in 	register_array_type; --//programmable registers
		
		sys_trig_o  :  out	std_logic; --//trigger to firmware
		sys_gate_o	:	out	std_logic; --//scaler gate
		ext_trig_o	:	out	std_logic); --//external trigger output
end external_trigger_manager;

architecture rtl of external_trigger_manager is

signal internal_gate_reg 		: std_logic_vector(2 downto 0);
signal internal_exttrig_reg 	: std_logic_vector(2 downto 0);
signal internal_exttrig_edge 	: std_logic;

begin

sys_trig_o <= internal_exttrig_reg(1) and reg_i(82)(1);

proc_reg_ext : process(rst_i, clk_i, ext_i, internal_gate_reg, internal_exttrig_reg, internal_exttrig_edge)
begin	
	if rst_i = '1' then
		internal_gate_reg <= (others=>'0');
		internal_exttrig_reg <= (others=>'0');
		sys_gate_o <= '0';
	elsif rising_edge(clk_i) then
		sys_gate_o <= internal_gate_reg(2);
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

--//send trigger out:
xEXT_TRIG_OUT : entity work.pulse_stretcher_sync_programmable(rtl)
generic map(
	stretch_width => 8)
port map(
	rst_i		=> rst_i or (not reg_i(83)(0)) or (not FIRMWARE_DEVICE),
	clk_i		=> clk_i,
	stretch_i => reg_i(83)(15 downto 8),
	out_pol_i => reg_i(83)(1),
	pulse_i	=> sys_trig_i or (internal_exttrig_reg(1) and reg_i(83)(2)),
	pulse_o	=> ext_trig_o);

end rtl;