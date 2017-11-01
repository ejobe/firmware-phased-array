--//EJO 10/2017
--//KICP
----------------------------
library ieee;
use ieee.std_logic_1164.all;

entity remote_update_writeFIFO_block is
  port (
    -- Control
    clock_i       : in  std_logic;
    rst_i      	: in  std_logic;
    empty_o       : out std_logic;    
    fifo_rden_i   : in  std_logic;
    valid_o       : out std_logic;
    data_o        : out std_logic_vector(31 downto 0);
    mode_i    		: in  std_logic;  --//mode=1 to write to fifo; mode=0 to read  
    fifo_wren_i   : in  std_logic;
    fifo_wrclk_i  : in  std_logic;
    fifo_data_i   : in  std_logic_vector(31 downto 0);
	 fifo_full_o	: out std_logic
  );
end entity remote_update_writeFIFO_block;

architecture rtl of remote_update_writeFIFO_block is
  ----------------
  -- Signals    --
  ----------------
  signal empty_int      : std_logic;
  signal wren_int       : std_logic;
  signal rden_int       : std_logic;

begin
  wren_int <= fifo_wren_i and mode_i;
  rden_int <= fifo_rden_i and not mode_i;
  empty_o  <= empty_int and not mode_i;
  
  xEPCQ_WRITEBUFFER_FIFO : entity work.remote_update_writeFIFO
    port map (
      aclr      => rst_i,
      wrclk     => fifo_wrclk_i,
      wrreq     => wren_int,
      data      => fifo_data_i,
      rdclk     => clock_i,
      rdreq     => rden_int,
		wrfull	 => fifo_full_o,	
      rdempty   => empty_int,
      q         => data_o
    );

  -- Delay empty signal by 1
  proc_valid : process(clock_i)
  begin
    if(rising_edge(clock_i)) then
      valid_o <= not empty_int and rden_int;
    end if;               
  end process proc_valid;

end rtl;
