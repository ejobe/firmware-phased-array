---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         remote_firmware_update_top.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         10/2017
--
-- DESCRIPTION:  TOP level of remote firmware upgrade stuff
--
-----///////////////////////////////////////////////////////////////////
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;

entity remote_firmware_update_top is
port(
	rst_i				: in	std_logic;
	clk_10MHz_i		: in	std_logic; --// 10MHz clock used solely for this block
	clk_i				: in	std_logic; --// interface clock
	registers_i		: in 	register_array_type;
	stat_reg_o		: out	std_logic_vector(23 downto 0);
	epcq_rd_data_o : out std_logic_vector(31 downto 0);
	data_o			: out std_logic_vector(31 downto 0));
end remote_firmware_update_top;

architecture rtl of remote_firmware_update_top is

type reg_internal_type is array (11 downto 0) of std_logic_vector(23 downto 0);
signal reg_internal_pipe 	: reg_internal_type; --//move to 10 MHz clk domain
signal reg_internal 			: reg_internal_type; --//move to 10 MHz clk domain

signal stat_reg_internal : std_logic_vector(23 downto 0);
signal remote_update_out_reg_internal : std_logic_vector(31 downto 0);

signal epcq_wr_addr_int : std_logic_vector(31 downto 0);
signal epcq_rd_addr_int : std_logic_vector(31 downto 0);
signal epcq_data_int	: std_logic_vector(31 downto 0);
signal epcq_data_valid_int : std_logic;
signal epcq_read_data_int : std_logic_vector(31 downto 0);

begin
------------------------------------------------------------------------
proc_clk_domain_xfer_1 : process(clk_10MHz_i)
begin
	for i in 0 to 11 loop
		if rising_edge(clk_10MHz_i) then
			reg_internal(i) <= reg_internal_pipe(i);
			reg_internal_pipe(i) <= registers_i(i+110); --//only re-clock the REMOTE UPGRADE registers
		end if;
	end loop;
end process;
------------------------------------------------------------------------
proc_clk_domain_xfer_2 : process(clk_i)
begin
	if rising_edge(clk_i) then
		stat_reg_o <= stat_reg_internal;
		data_o <= remote_update_out_reg_internal;
		epcq_rd_data_o <= epcq_read_data_int;
	end if;
end process;
------------------------------------------------------------------------
xREMOTE_UPDATE_CONTROL : entity work.remote_update_control
port map(
    clock_i        	=> clk_10MHz_i, 					--: in  std_logic;
    reset_i	       	=> not reg_internal(0)(0),	--: in  std_logic;
    busy_o           => stat_reg_internal(0),
    reconfig_i	     	=> reg_internal(7)(16), --: in  std_logic;
    param_i	        	=> reg_internal(7)(2 downto 0),--: in  std_logic_vector(2 DOWNTO 0);
    toggle_write_i  	=> reg_internal(7)(8),--: in  std_logic;
    data_i			  	=> reg_internal(9)(15 downto 0) & reg_internal(8)(15 downto 0),--: in  std_logic_vector(31 DOWNTO 0);
    data_o		 		=> remote_update_out_reg_internal);--: out std_logic_vector(31 DOWNTO 0)
------------------------------------------------------------------------
xEPCQ256_CONTROL : entity work.epcq256_control
port map(
    clk_i				=> clk_10MHz_i,					--: in  std_logic	:= '0';
    reset_i				=> not reg_internal(0)(0),	--: in  std_logic	:= '0';
    cmd_i				=> reg_internal(4)(2 downto 0),		--: in  std_logic_vector( 2 downto 0);
    addr_i				=> reg_internal(6)(15 downto 0) & reg_internal(5)(15 downto 0),--: in  std_logic_vector(31 downto 0);
    test_mode_i		=> reg_internal(4)(8),   --//"test mode" used to designate writing to EPCQ (1), or sending cmds to this firmware block and reading from ASMI_parallel (0)
    busy_status_o		=> stat_reg_internal(1),--: out std_logic;
    done_status_o		=> stat_reg_internal(2),--: out std_logic;
    rdaddr_o			=> epcq_rd_addr_int,		
    data_o				=> epcq_data_int,
    data_valid_o		=> epcq_data_valid_int,  
    clear_i				=> reg_internal(4)(16),--: in  std_logic;
    fifo_wren_i    	=> reg_internal(1)(0),---: in  std_logic;
    fifo_ds_i      	=> reg_internal(1)(1),--: in  std_logic;
    fifo_data_i    	=> reg_internal(3)(15 downto 0) & reg_internal(2)(15 downto 0),--: in  std_logic_vector(31 downto 0)
	 fifo_empty_o 		=> stat_reg_internal(3),
	 fifo_full_o		=> stat_reg_internal(4));
------------------------------------------------------------------------
xEPCQ256_READ_BUFFER : entity work.epcq_read_buffer
port map(
	data      => epcq_data_int,
   wraddress => epcq_rd_addr_int(11 downto 0),
   wren      => epcq_data_valid_int,
   rdaddress => reg_internal(10)(11 downto 0),
   wrclock   => clk_10MHz_i,
   wrclocken => epcq_data_valid_int,
   rdclock   => reg_internal(11)(1),
   rdclocken => reg_internal(11)(0),
   q         => epcq_read_data_int);

end rtl;