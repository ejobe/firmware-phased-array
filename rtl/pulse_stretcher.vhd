--//pulse-stretcher
--//ejo 5/2015
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity pulse_stretcher is
	generic(
		stretch	:	integer;
		edge		:	std_logic := '1'); --//1=rising edge, 0=falling
	port(
		rst_i			:	in		std_logic;
		clk_i			:	in		std_logic;
		pulse_i		:	in		std_logic;
		pulse_o		:	out	std_logic);
		
end pulse_stretcher;

architecture rtl of pulse_stretcher is
signal pulse	:	std_logic_vector(2 downto 0) 	:= (others=>'0');
type 	 pulse_state_type is (stretch_st, done_st);
signal pulse_state : pulse_state_type;

begin

pulse_o <= pulse(2);
--//pulse(0) => de-asserts (1), set active 1-clock cycle after (2) 
--//pulse(1) => signal latched on user input
--//pulse(2) => clocked signal
proc_latch : process(clk_i, pulse_i)
begin
	if edge = '1' then
		if pulse(0) = '1' or rst_i = '1' then
			pulse(1) <= '0';
		
		elsif rising_edge(pulse_i) then
			pulse(1) <= '1';		
		end if;
	end if;
	
	if edge = '0' then
		if pulse(0) = '1' or rst_i = '1' then
			pulse(1) <= '0';
		elsif falling_edge(pulse_i) then
			pulse(1) <= '1';		
		end if;
	end if;
end process;

proc_stretch : process(rst_i, clk_i, pulse_i, pulse)
variable i : integer range stretch+2 downto 0 := 0;	
begin
	if rst_i = '1' or pulse(1) = '0' then
		pulse(2) 	<= '0';
		pulse(0) 	<= '0';
		i := 0;
		pulse_state	<= stretch_st;
	elsif rising_edge(clk_i) and pulse(1) = '1' then
		case pulse_state is
			when stretch_st =>
				if i > stretch then
					i := 0;
					pulse(2) <= '0';
					pulse_state  <= done_st;
				else
					i := i + 1;
					pulse(2) <= '1';
				end if;
				
			when done_st =>
				pulse(0) <= '1';
				
			when others =>
				null;
				
		end case;
	end if;
end process;
end rtl;