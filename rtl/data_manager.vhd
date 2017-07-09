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
-- DESCRIPTION:  manage data, event-forming, etc
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
		clk_i					:  in	 std_logic; --//core data clock
		clk_iface_i			:	in	 std_logic; --//slower interface clock
		wr_busy_o			:	out std_logic; --//
		buffer_full_o		:	out std_logic_vector(0 downto 0); --//single buffer, for now
		
		phased_trig_i		:	in	 std_logic; 
		reg_i					:	in	 register_array_type; --//forced trig sent in register array
		
		read_clk_i 			:	in		std_logic;
		read_ram_adr_i		:	in  	std_logic_vector(define_data_ram_depth-1 downto 0);

		--//waveform data	
		wfm_data_i				:	in	 full_data_type;
		data_ram_read_en_i	:	in		std_logic_vector(7 downto 0);
		data_ram_o				:  out	full_data_type;
		
		--//beamforming data
		beam_data_i				:	in	 	array_of_beams_type; --//beams made w/ coherent sums of all 8 antennas (baseline every antenna)
		beam_data_4a_i			:	in	 	array_of_beams_type; --//beams made w/ 4 antennas, starting with 1st antenna (baseline every other antenna)
		beam_data_4b_i			:	in	 	array_of_beams_type; --//beams made w/ 4 antennas, starting with 2nd antenna (baseline every other antenna)

		beam_ram_read_en_i	:	in		std_logic_vector(define_num_beams-1 downto 0);
		beam_ram_o				:  out	array_of_beams_type;

		--//power data
		powsum_data_i			:	in	 	sum_power_type;
		powsum_ram_read_en_i	:	in		std_logic_vector(define_num_beams-1 downto 0);
		powsum_ram_o			:  out	array_of_beams_type);
	
	end data_manager;

architecture rtl of data_manager is

type save_event_state_type is (idle_st, adr_inc_st, done_st);
signal save_event_state 	: save_event_state_type;
		
signal internal_forced_trigger : std_logic;
signal internal_data_ram_write_en : std_logic;
signal internal_ram_write_adrs : std_logic_vector(define_data_ram_depth-1 downto 0);
constant internal_address_max : std_logic_vector(define_data_ram_depth-1 downto 0) := (others=>'1');		

--//squeeze the powsum data into 16-bit chunks (basically just chop off MSB: don't really care here since
--//only time to read out power sum info is for debugging)
type internal_sum_power_type is array(define_num_beams-1 downto 0) of 
	std_logic_vector(define_num_power_sums*define_pow_sum_range-1 downto 0);  
signal internal_powsum_data : internal_sum_power_type;
		
signal internal_wfm_data : full_data_type;
		
signal internal_beam_ram_8 		: array_of_beams_type;
signal internal_beam_ram_4a 		: array_of_beams_type;
signal internal_beam_ram_4b 		: array_of_beams_type;
signal internal_beam_ram_en_8		: std_logic_vector(define_num_beams-1 downto 0);
signal internal_beam_ram_en_4a	: std_logic_vector(define_num_beams-1 downto 0);
signal internal_beam_ram_en_4b	: std_logic_vector(define_num_beams-1 downto 0);

component flag_sync is
port(
	clkA			: in	std_logic;
   clkB			: in	std_logic;
   in_clkA		: in	std_logic;
   busy_clkA	: out	std_logic;
   out_clkB		: out	std_logic);
end component;

--//note saving beam/power sum info mainly for debugging. Might chop this out once things confirmed working
begin
--////////////////////////////////////////////////////////////////////////////////
--//chop off some of the pow_sum_data in order to fit in 16 bit word for readout
process(clk_i, powsum_data_i)
begin
	for i in 0 to define_num_beams-1 loop
		internal_powsum_data(i)(15 downto 0) 	<= powsum_data_i(i)(15 downto 0);
		internal_powsum_data(i)(31 downto 16) 	<= powsum_data_i(i)(32 downto 17);
		internal_powsum_data(i)(47 downto 32) 	<= powsum_data_i(i)(49 downto 34);
		internal_powsum_data(i)(63 downto 48) 	<= powsum_data_i(i)(66 downto 51);
		internal_powsum_data(i)(79 downto 64) 	<= powsum_data_i(i)(83 downto 68);
		internal_powsum_data(i)(95 downto 80) 	<= powsum_data_i(i)(100 downto 85);
		internal_powsum_data(i)(111 downto 96) <= powsum_data_i(i)(117 downto 102);
		internal_powsum_data(i)(127 downto 112)<= powsum_data_i(i)(134 downto 119);
	end loop;
end process;
--///////////////////////////////////////////////////////////////////////////////

--//////////////////////////////////////////////////////////
--//sync software trigger to faster data clk
xSOFTTRIGSYNC : flag_sync
port map(
		clkA 			=> clk_iface_i,
		clkB			=> clk_i,
		in_clkA		=> reg_i(base_adrs_rdout_cntrl+0)(0),
		busy_clkA	=> open,
		out_clkB		=> internal_forced_trigger);
--/////////////////////////////////////////////////////////

--//////////////////////////////////////
--//apply programmable pre-trigger window
PreTrigBlock : for i in 0 to 7 generate
	xPRETRIGBLOCK : entity work.pretrigger_window
	port map(
		rst_i		=> rst_i,
		clk_i		=>	clk_i,
		reg_i		=>	reg_i,
		data_i	=>	wfm_data_i(i),
		data_o	=>	internal_wfm_data(i));
end generate;
--//////////////////////////////////////

--/////////////////////////////////////////////////////////	
--//if trigger, write to data ram
proc_save_triggered_event : process(rst_i, clk_i, internal_forced_trigger, phased_trig_i)
begin
	if rst_i = '1' then
		internal_data_ram_write_en <= '0';
		internal_ram_write_adrs <= (others=>'0');
		wr_busy_o <= '0';
		save_event_state <= idle_st;
	
	elsif rising_edge(clk_i) then
		
		case save_event_state is
		
			--//idle state, sit around wait for forced or beam trigger
			when idle_st =>
				internal_data_ram_write_en <= '0';
				internal_ram_write_adrs <= (others=>'0');
				wr_busy_o <= '0';
				
				if internal_forced_trigger = '1' or phased_trig_i = '1' then
					save_event_state <= adr_inc_st;
				else
					save_event_state <= idle_st;
				end if;
			
			--//push data to RAM block, increment address until max address is reached
			when adr_inc_st=>
				internal_data_ram_write_en <= '1';
				internal_ram_write_adrs <= internal_ram_write_adrs + 1;
				wr_busy_o <= '1';
				
				if internal_ram_write_adrs = internal_address_max then 
					save_event_state <= done_st;
				else
					save_event_state <= adr_inc_st;
				end if;
			
			--//saving is done, relax the wr_busy signal and go back to idle state 		
			when done_st =>
					internal_data_ram_write_en <= '0';
					internal_ram_write_adrs <= internal_address_max;
					wr_busy_o <= '0';
					save_event_state <= idle_st;
				
		end case;
	end if;
end process;

--//simple block to interpret registers to pick which beam RAM block to readout 
proc_select_beam_ram : process(reg_i)
begin
	for i in 0 to define_num_beams-1 loop
		case reg_i(base_adrs_rdout_cntrl+2)(3 downto 2) is		
			when "00" =>
				beam_ram_o(i) <= internal_beam_ram_8(i);
				internal_beam_ram_en_8(i)	<= beam_ram_read_en_i(i);
				internal_beam_ram_en_4a(i)	<= '0';
				internal_beam_ram_en_4a(i)	<= '0';
			when "01" =>
				beam_ram_o(i) <= internal_beam_ram_4a(i);
				internal_beam_ram_en_8(i)	<= '0';
				internal_beam_ram_en_4a(i)	<= beam_ram_read_en_i(i);
				internal_beam_ram_en_4a(i)	<= '0';
			when "10" =>
				beam_ram_o(i) <= internal_beam_ram_4b(i);
				internal_beam_ram_en_8(i)	<= '0';
				internal_beam_ram_en_4a(i)	<= '0';
				internal_beam_ram_en_4a(i)	<= beam_ram_read_en_i(i);
			when others=>
				beam_ram_o(i) <= (others=>'0');
				internal_beam_ram_en_8(i)	<= '0';
				internal_beam_ram_en_4a(i)	<= '0';
				internal_beam_ram_en_4a(i)	<= '0';
		end case;
	end loop;
end process;

--///////////////////
--//FPGA RAM blocks defined here:
--///////////////////
DataRamBlock : for i in 0 to 7 generate
	xDataRAM 	:	entity work.DataRAM
	port map(
		data			=> internal_wfm_data(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> read_ram_adr_i,
		rdclock		=> read_clk_i,
		rden			=> data_ram_read_en_i(i),
		wraddress	=> internal_ram_write_adrs, 
		wrclock		=> clk_i,
		wren			=>	internal_data_ram_write_en,
		q				=>	data_ram_o(i));
end generate DataRamBlock;
--///////////////////
BeamRamBlock1 : for i in 0 to define_num_beams-1 generate
	xBeamRAM 	:	entity work.DataRAM
	port map(
		data			=> beam_data_i(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> read_ram_adr_i,
		rdclock		=> read_clk_i,
		rden			=> internal_beam_ram_en_8(i),
		wraddress	=> internal_ram_write_adrs, 
		wrclock		=> clk_i,
		wren			=>	internal_data_ram_write_en,
		q				=>	internal_beam_ram_8(i));
end generate BeamRamBlock1;
BeamRamBlock2 : for i in 0 to define_num_beams-1 generate
	xBeamRAM 	:	entity work.DataRAM
	port map(
		data			=> beam_data_4a_i(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> read_ram_adr_i,
		rdclock		=> read_clk_i,
		rden			=> internal_beam_ram_en_4a(i),
		wraddress	=> internal_ram_write_adrs, 
		wrclock		=> clk_i,
		wren			=>	internal_data_ram_write_en,
		q				=>	internal_beam_ram_4a(i));
end generate BeamRamBlock2;
BeamRamBlock3 : for i in 0 to define_num_beams-1 generate
	xBeamRAM 	:	entity work.DataRAM
	port map(
		data			=> beam_data_4b_i(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> read_ram_adr_i,
		rdclock		=> read_clk_i,
		rden			=> internal_beam_ram_en_4b(i),
		wraddress	=> internal_ram_write_adrs, 
		wrclock		=> clk_i,
		wren			=>	internal_data_ram_write_en,
		q				=>	internal_beam_ram_4b(i));
end generate BeamRamBlock3;
--///////////////////
PowRamBlock : for i in 0 to define_num_beams-1 generate
	xPowRAM 	:	entity work.DataRAM
	port map(
		data			=> internal_powsum_data(i), 
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