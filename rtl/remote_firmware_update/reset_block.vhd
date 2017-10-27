-- reset consolidation and generation:

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity reset_block is
  generic (
    RESET_MAX           : integer       :=    10000000 -- Clock cycles to hold the reset for
  );
  port (
    clk_i   	        : in  std_logic;
    rst_i   	        : in  std_logic;
    consolidated_reset_o  : out std_logic := '1'
  );
end entity reset_block;

architecture behavioral of reset_block is
  -- local signals:
  signal auto_reset       : std_logic			:= '1';
  signal auto_reset_timer : integer range 0 to 10000000	:= 0;
  
begin
  -- small counter for the initial post-configuration automatic reset:
  proc_auto_reset_counter : process (clk_i,rst_i) is
  begin
    if(rst_i = '1') then
      auto_reset_timer  <= 0;
      auto_reset        <= '1';    
    elsif(rising_edge(clk_i)) then
      if (auto_reset_timer = RESET_MAX) then
        auto_reset_timer<= RESET_MAX;
        auto_reset      <= '0'; -- deassert auto reset
      else
        auto_reset_timer<= (auto_reset_timer + 1);
        auto_reset      <= '1'; -- continue asserting auto reset
      end if;
    end if;
  end process proc_auto_reset_counter;
  
  -- concurrent signal assignments:
  consolidated_reset_o    <= auto_reset or rst_i;
end architecture behavioral;