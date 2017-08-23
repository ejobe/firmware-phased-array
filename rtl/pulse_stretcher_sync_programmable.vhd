--//pulse-stretcher
--//ejo 5/2015
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
------------
entity pulse_stretcher_sync_programmable is
	generic(
		stretch_width	:	integer); 
	port(
		rst_i			:	in		std_logic;
		clk_i			:	in		std_logic;
		stretch_i   :  in		std_logic_vector(stretch_width-1 downto 0);
		out_pol_i	:  in		std_logic;
		pulse_i		:	in		std_logic;
		pulse_o		:	out	std_logic);
		
end pulse_stretcher_sync_programmable;
------------
architecture rtl of pulse_stretcher_sync_programmable is
type 	 pulse_state_type is (idle_st, stretch_st);
signal pulse_state : pulse_state_type;
signal internal_stretch_counter : std_logic_vector(stretch_width-1 downto 0) := (others=>'0');
signal internal_pulse : std_logic_vector(1 downto 0) := "00";
begin
------------
proc_get_edge : process(rst_i, clk_i, pulse_i, internal_pulse)
begin
if rst_i = '1' then
	internal_pulse <= "00";
elsif rising_edge(clk_i) then
	internal_pulse(1) <= internal_pulse(0);
	if pulse_i = '1' then
		internal_pulse(0) <= '1';
	elsif pulse_i = '0' then
		internal_pulse(0) <= '0';
	end if;
end if;
end process;
------------
proc_stretch : process(rst_i, clk_i, internal_pulse, out_pol_i)
begin
if rst_i = '1' then
	internal_stretch_counter <= (others=>'0');
	pulse_o <= not out_pol_i;
	pulse_state <= idle_st;
	
elsif rising_edge(clk_i) then
	case pulse_state is
		when idle_st=>
			internal_stretch_counter <= (others=>'0');
			pulse_o <= not out_pol_i;
			if internal_pulse = "01" then
				pulse_state <= stretch_st;
			else 
				pulse_state <= idle_st;
			end if;
		when stretch_st =>
			pulse_o <= out_pol_i;
			if internal_stretch_counter = stretch_i then
				internal_stretch_counter <= (others=>'0');
				pulse_state <= idle_st;
			else	
				internal_stretch_counter <= internal_stretch_counter + 1;
				pulse_state <= stretch_st;
			end if;
		when others=>
			internal_stretch_counter <= (others=>'0');
			pulse_state <= idle_st;
	end case;
end if;
end process;
end rtl;