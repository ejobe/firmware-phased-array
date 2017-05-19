---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         data_manager.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         3/2017
--
-- DESCRIPTION:  manage data, RAMs, etc
--               
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

entity data_manager is
	port(
		rst_i					:	in	 std_logic;
		clk_i					:  in	 std_logic;
		
		trig_i				:	in	 std_logic; --//forced trigger
		
		read_clk_i 			:	in		std_logic;
		read_ram_adr_i		:	in  	std_logic_vector(define_data_ram_depth-1 downto 0);

		--//waveform data	
		wfm_data_i				:	in	 full_data_type;
		data_ram_read_en_i	:	in		std_logic_vector(7 downto 0);
		data_ram_o				:  out	full_data_type;
		
		--//beamforming data
		beam_data_i				:	in	 	array_of_beams_type;
		beam_ram_read_en_i	:	in		std_logic_vector(define_num_beams-1 downto 0);
		beam_ram_o				:  out	array_of_beams_type;
		
		--//power data
		powsum_data_i			:	in	 	sum_power_type;
		powsum_ram_read_en_i	:	in		std_logic_vector(define_num_beams-1 downto 0);
		powsum_ram_o			:  out	sum_power_type);
	
	end data_manager;

architecture rtl of data_manager is
		
signal internal_trigger_reg : std_logic_vector(3 downto 0);
signal internal_data_ram_write_en : std_logic;
signal internal_ram_write_adrs : std_logic_vector(define_data_ram_depth-1 downto 0);
constant internal_address_max : std_logic_vector(define_data_ram_depth-1 downto 0) := (others=>'1');		
		
begin

proc_trig : process(rst_i, clk_i, trig_i)
begin
	if rst_i = '1' then	
		internal_trigger_reg <= (others=>'0');	
	elsif rising_edge(clk_i) then
		internal_trigger_reg <= internal_trigger_reg(internal_trigger_reg'length-2 downto 0) & trig_i;
	end if;
end process;	
	
--//if trigger, write to data ram
proc_forced_trigger : process(rst_i, clk_i, internal_trigger_reg)
begin
	if rst_i = '1' or internal_trigger_reg(0) <= '0' then	
		internal_data_ram_write_en <= '0';
		internal_ram_write_adrs <= (others=>'0');
		
	elsif rising_edge(clk_i) and internal_trigger_reg(2) = '1' and	
		internal_ram_write_adrs < internal_address_max then
		
		internal_data_ram_write_en <= '1';
		internal_ram_write_adrs <= internal_ram_write_adrs + 1;
	
	elsif rising_edge(clk_i) and internal_ram_write_adrs = internal_address_max then
				
		internal_data_ram_write_en <= '0';
		internal_ram_write_adrs <= internal_address_max;
	end if;
end process;

DataRamBlock : for i in 0 to 7 generate
	xDataRAM 	:	entity work.DataRAM(syn)
	port map(
		data			=> wfm_data_i(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> read_ram_adr_i,
		rdclock		=> read_clk_i,
		rden			=> data_ram_read_en_i(i),
		wraddress	=> internal_ram_write_adrs, 
		wrclock		=> clk_i,
		wren			=>	internal_data_ram_write_en,
		q				=>	data_ram_o(i));
end generate DataRamBlock;

BeamRamBlock : for i in 0 to define_num_beams-1 generate
	xBeamRAM 	:	entity work.DataRAM(syn)
	port map(
		data			=> beam_data_i(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> read_ram_adr_i,
		rdclock		=> read_clk_i,
		rden			=> beam_ram_read_en_i(i),
		wraddress	=> internal_ram_write_adrs, 
		wrclock		=> clk_i,
		wren			=>	internal_data_ram_write_en,
		q				=>	beam_ram_o(i));
end generate BeamRamBlock;

PowRamBlock : for i in 0 to define_num_beams-1 generate
	xPowRAM 	:	entity work.DataRAM(syn)
	port map(
		data			=> powsum_data_i(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> read_ram_adr_i,
		rdclock		=> read_clk_i,
		rden			=> powsum_ram_read_en_i(i),
		wraddress	=> internal_ram_write_adrs, 
		wrclock		=> clk_i,
		wren			=>	internal_data_ram_write_en,
		q				=>	powsum_ram_o(i));
end generate PowRamBlock;
--////////////////////////////////////////////////////////////////////////////
end rtl;