---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         remote_update_control.vhd
-- AUTHOR:       
-- EMAIL         ejo@uchicago.edu
-- DATE:         10/2017
--
-- DESCRIPTION:  
--
--       adapted from FTK AUX code
-----///////////////////////////////////////////////////////////////////
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity remote_update_control IS
  PORT (
    clock_i         	: in  std_logic;
    reset_i	        	: in  std_logic;
    busy_o           : out std_logic;
    reconfig_i	     	: in  std_logic;
    param_i	        	: in  std_logic_vector(2 DOWNTO 0);
    toggle_write_i  	: in  std_logic;
    data_i			  	: in  std_logic_vector(31 DOWNTO 0);
    data_o		 		: out std_logic_vector(31 DOWNTO 0)
  );
end entity remote_update_control;

architecture rtl of remote_update_control is
  ----------------
  -- COMPONENTS --
  ----------------
  component remote_update
    port (
      clock	      : in  std_logic;
      data_in		: in  std_logic_vector(31 downto 0);
      param			: in  std_logic_vector( 2 downto 0);
      read_param	: in  std_logic;
      reconfig		: in  std_logic;
      reset       : in  std_logic;
      reset_timer	: in  std_logic;
      write_param	: in  std_logic;
      busy			: out std_logic;
      data_out		: out std_logic_vector(31 downto 0)
    );
  end component;
  ----------------
  -- SIGNALS    --
  ----------------
  signal reconfig_int   : std_logic;
  signal busy_int       : std_logic;

  signal curparam	: std_logic_vector(2 downto 0);

  signal watchdog	: std_logic;
  signal watchdog_counter : std_logic_vector(7 downto 0) := (others=>'0');

  type read_fsm_t is (idle, doneread);
  signal read_fsm       : read_fsm_t	:=	idle;
  signal read_param	: std_logic;

  type write_fsm_t is (idle, donewrite);
  signal write_fsm      : write_fsm_t	:=	idle;
  signal write_param    : std_logic;

begin
  busy_o <= busy_int;
  reconfig_int <= reconfig_i and not reset_i;
        
  -- ALTERA IP blcok
  xREMOTE_UPDATE : remote_update
    PORT MAP (
      clock             => clock_i,
      data_in           => data_i,
      param             => param_i,
      read_param        => read_param,
      reconfig	        	=> reconfig_int,
      reset	        		=> reset_i,
      write_param       => write_param,
      busy              => busy_int,
      data_out          => data_o,
      reset_timer       => watchdog
    );
  
  ---------------
  -- WATCHDOG  --
  ---------------
  -- Kick the remote_update block every once in a while to make sure the watchdog does not expire
  watchdog_proc	: process(clock_i) IS
  BEGIN
    IF(RISING_EDGE(clock_i)) THEN
      watchdog_counter <= watchdog_counter + 1;
      IF(watchdog_counter = 255) THEN
        watchdog <= '1';
      ELSE
        watchdog <= '0';
      end IF;
    end IF;
  end process watchdog_proc;

  ---------------
  -- READ CODE --
  ---------------
  fsm_read_proc	:	process(clock_i,reset_i,param_i) IS
  BEGIN
    IF(reset_i='1') THEN
      read_param	<= '0';
      curparam		<= (others => '1');
      read_fsm		<= idle;
    ELSIF(RISING_EDGE(clock_i)) THEN
      CASE read_fsm IS
        WHEN idle =>
          IF(param_i /= curparam AND busy_int = '0') THEN
            curparam    <= param_i;
            read_param  <= '1';
            read_fsm    <= doneread;
          ELSE
            read_param  <= '0';
            read_fsm    <= idle;
          end IF;
          
        WHEN doneread =>
          read_param    <= '0';
          IF(busy_int='0') THEN
            read_fsm    <= idle;
          ELSE
            read_fsm    <= doneread;
          end IF;
      end CASE;
    end IF;
  end process fsm_read_proc;


  ----------------
  -- WRITE CODE --
  ----------------
  fsm_write_proc	:	process(clock_i,reset_i,toggle_write_i) IS
    VARIABLE prevtoggle_write	:	std_logic;
  BEGIN
    IF(reset_i='1') THEN
      write_param	<= '0';
      write_fsm		<= idle;
      prevtoggle_write := '0';
    ELSIF(RISING_EDGE(clock_i)) THEN
      CASE write_fsm IS
        WHEN idle =>
          IF(prevtoggle_write='0' AND toggle_write_i='1' AND busy_int = '0') THEN
            write_param <= '1';
            write_fsm <= donewrite;
          ELSE
            write_param <= '0';
            write_fsm <= idle;
          end IF;
          
        WHEN donewrite =>
          write_param <= '0';
          IF(busy_int='0') THEN
            write_fsm <= idle;
          ELSE
            write_fsm <= donewrite;
          end IF;
      end CASE;
      prevtoggle_write := toggle_write_i;
    end IF;
  end process fsm_write_proc;

end architecture rtl;
