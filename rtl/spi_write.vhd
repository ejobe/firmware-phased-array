--//spi_write.vhd		
--//writes pdat(data_length-1): MSB 1st -> LSB last

library IEEE; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity spi_write is
	generic( 
		data_length : integer := 32;
		le_init_lev : std_logic := '0'); --//specify if LE should be low or high in idle/startup state
		
	port(
		rst_i			:	in		std_logic;
		clk_i			:	in		std_logic; 
		pdat_i		: 	in		std_logic_vector(data_length-1 downto 0);
		
		write_i		:	in		std_logic;
		done_o		:	out	std_logic;
		
		sdata_o		:	out	std_logic;
		sclk_o		:	out	std_logic;
		le_o			: 	out	std_logic);
		
end spi_write;

architecture rtl of spi_write is

type spi_state_type is (idle_st, write_st, clock_st, latch_st, done_st);
signal spi_state : spi_state_type := idle_st;
signal internal_reg 	: 	std_logic_vector(data_length-1 downto 0);
signal internal_wr	:	std_logic;

begin

proc_reg_data : process(rst_i, clk_i, write_i, spi_state)
begin
	if rst_i = '1' then
		internal_reg <= (others=>'0');
		internal_wr <= '0';
	elsif rising_edge(clk_i) and spi_state = done_st then
		internal_reg <= (others=>'0');
		internal_wr <= '0';
	elsif rising_edge(clk_i) and write_i = '1' then
		internal_reg <= pdat_i;
		internal_wr <= '1';
	end if;
end process;
		
proc_spi_write : process(rst_i, clk_i, write_i, internal_wr)
	variable j : integer range 0 to data_length := 0;
begin

	if rst_i = '1' or internal_wr = '0' then
		j := 0;
		le_o <= le_init_lev;
		sdata_o <= '0';
		sclk_o <= '0';
		done_o <= '0';

		spi_state <= idle_st;
	
	elsif rising_edge(clk_i) and internal_wr = '1' then
		
		case spi_state is
			
			when idle_st =>
				le_o 	<= le_init_lev;
				sclk_o <= '0';
				sdata_o <= '0';
				spi_state <= write_st;
			
			when write_st =>
				le_o 	<='0';
				sclk_o <= '0'; --//clock low
				
				if j > data_length-1 then
					j := 0;
					spi_state <= latch_st;
				else
					sdata_o <= internal_reg(data_length-1-j); 
					j := j + 1;
					spi_state <= clock_st;
				end if;
				
			when clock_st =>
				sclk_o <= '1'; --//clock high
				spi_state <= write_st;			
				
			when latch_st =>
				sclk_o <= '0';
				sdata_o <= '0';
				
				if j > 1 then
					le_o <= '0';
					j := 0;
					done_o <= '1';
					spi_state <= done_st;
					
				else
					le_o <= '1';
					j := j + 1;
				end if;
					
			when done_st =>
				le_o <= '0';

			when others=>	
				spi_state <= idle_st;
		end case;
	end if;
end process;
				
end rtl;