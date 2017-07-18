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
		pulse_refrsh_i		:	in	 std_logic;
		wr_busy_o			:	out std_logic; --//
		
		phased_trig_i		:	in	 std_logic; 
		last_trig_beam_i	: 	in std_logic_vector(define_num_beams-1 downto 0); --//last beam trigger
		last_trig_pow_i	:	in	 average_power_16samp_type; 
		ext_trig_i			:	in	 std_logic; --//external board trigger
		reg_i					:	in	 register_array_type; --//forced trig sent in register array
		
		read_clk_i 			:	in		std_logic;
		read_ram_adr_i		:	in  	std_logic_vector(define_data_ram_depth-1 downto 0);
		
		status_reg_o		:	out	std_logic_vector(23 downto 0);
		event_meta_o		:	out	event_metadata_type;

		--//waveform data	
		wfm_data_i				:	in	 	full_data_type;
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

type save_event_state_type is (idle_st, trig_st, adr_inc_st, done_st);
type save_event_state_type_array is array(define_num_wfm_buffers-1 downto 0) of save_event_state_type;
signal save_event_state 	: save_event_state_type_array;
--		
signal internal_forced_trigger : std_logic;

type internal_ram_write_adrs_type is array(define_num_wfm_buffers-1 downto 0) of std_logic_vector(define_data_ram_depth-1 downto 0);
signal internal_ram_write_adrs : internal_ram_write_adrs_type;
constant internal_address_max : std_logic_vector(define_data_ram_depth-1 downto 0) := (others=>'1');		

--//squeeze the powsum data into 16-bit chunks (basically just chop off MSB: don't really care here since
--//only time to read out power sum info is for debugging)
type internal_sum_power_type is array(define_num_beams-1 downto 0) of 
	std_logic_vector(define_num_power_sums*define_pow_sum_range-1 downto 0);  
signal internal_powsum_data : internal_sum_power_type;
		
signal internal_wfm_data : full_data_type;  --//delayed data for pre-trig window
signal internal_wfm_ram_0 : full_data_type; --//data buffer 1
signal internal_wfm_ram_1 : full_data_type; --//data buffer 2
signal internal_wfm_ram_2 : full_data_type; --//data buffer 3
signal internal_wfm_ram_3 : full_data_type; --//data buffer 4
signal internal_wfm_ram_write_en 	: std_logic_vector(define_num_wfm_buffers-1 downto 0);
signal next_write_buffer				: std_logic_vector(2 downto 0) := "000";
signal internal_buffer_full  			: std_logic_vector(define_num_wfm_buffers-1 downto 0);
signal internal_clear_buffer 			: std_logic_vector(define_num_wfm_buffers-1 downto 0);
signal internal_write_busy				: std_logic_vector(define_num_wfm_buffers-1 downto 0);
signal internal_event_busy				: std_logic_vector(define_num_wfm_buffers-1 downto 0);
signal internal_get_event_metadata  : std_logic_vector(define_num_wfm_buffers-1 downto 0);

signal internal_beam_ram_8 		: array_of_beams_type;
signal internal_beam_ram_4a 		: array_of_beams_type;
signal internal_beam_ram_4b 		: array_of_beams_type;
signal internal_beam_ram_en_8		: std_logic_vector(define_num_beams-1 downto 0);
signal internal_beam_ram_en_4a	: std_logic_vector(define_num_beams-1 downto 0);
signal internal_beam_ram_en_4b	: std_logic_vector(define_num_beams-1 downto 0);

signal internal_data_manager_status : std_logic_vector(23 downto 0) := (others=>'0'); --//status register

signal internal_last_trigger_type : std_logic_vector(1 downto 0) := "00"; --//record trigger type
signal internal_last_beam_trigger : std_logic_vector(define_num_beams-1 downto 0);
signal event_trigger : std_logic;
signal buffers_full	: std_logic;

--//declare components, since verilog modules:
component flag_sync is
port(
	clkA			: in	std_logic;
   clkB			: in	std_logic;
   in_clkA		: in	std_logic;
   busy_clkA	: out	std_logic;
   out_clkB		: out	std_logic);
end component;
component signal_sync is
port(
	clkA			: in	std_logic;
   clkB			: in	std_logic;
   SignalIn_clkA	: in	std_logic;
   SignalOut_clkB	: out	std_logic);
end component;

--//note saving beam/power sum info mainly for debugging. Might chop this out once things confirmed working
begin
--////////////////////////////////////////////////////////////////////////////////
--//THIS DOES NOTHING AS OF 7/7/17
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

--//sync buffer clear flag
ClearBufSync : for i in 0 to define_num_wfm_buffers-1 generate
	xCLEARBUFSYNC : flag_sync
	port map(
		clkA 			=> clk_iface_i,
		clkB			=> clk_i,
		in_clkA		=> reg_i(base_adrs_rdout_cntrl+13)(i),
		busy_clkA	=> open,
		out_clkB		=> internal_clear_buffer(i));
end generate;
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

--//////////////////////////////////////
--//clock trigger 
proc_reg_trig : process(rst_i, clk_i)
begin
	if rst_i = '1' then
		event_trigger <= '0';
		internal_last_beam_trigger <= (others=>'0');
		internal_last_trigger_type <= (others=>'0');
	elsif rising_edge(clk_i) and internal_forced_trigger = '1' then
		event_trigger <= '1';
		internal_last_trigger_type <= "01";
	elsif rising_edge(clk_i) and phased_trig_i = '1' then 
		event_trigger <= '1';
		internal_last_beam_trigger <= last_trig_beam_i; --//update the beam trigger info
		internal_last_trigger_type <= "10";
	elsif rising_edge(clk_i) and ext_trig_i = '1' then 
		event_trigger <= '1';
		internal_last_trigger_type <= "11";
	elsif rising_edge(clk_i) then
		event_trigger <= '0';
		internal_last_trigger_type <= internal_last_trigger_type;
	end if;
end process;

StatRegSync : for i in 0 to 23 generate
	xSTATREGSYNC : signal_sync 
	port map(
		clkA 			=> clk_i,
		clkB			=> clk_iface_i,
		SignalIn_clkA		=> internal_data_manager_status(i),
		SignalOut_clkB		=> status_reg_o(i));
end generate;
--//////////////////////////////////////

--////////////////////
proc_manage_buffers : process(rst_i, clk_i, internal_event_busy, internal_buffer_full(0))
begin
	if rst_i = '0' then
		wr_busy_o <= '0';
		next_write_buffer <= (others=>'0');
		internal_data_manager_status <= (others=>'0');
		buffers_full <= '0';
		
	elsif rising_edge(clk_i) then
	
		internal_data_manager_status(3 downto 0) <= internal_buffer_full;
		internal_data_manager_status(4) <= internal_buffer_full(0) or internal_buffer_full(1) or internal_buffer_full(2) or internal_buffer_full(3);
		internal_data_manager_status(7 downto 5) <= next_write_buffer;
		
		buffers_full <= internal_buffer_full(0) and internal_buffer_full(1) and internal_buffer_full(2) and internal_buffer_full(3); --//deadtime
		
		wr_busy_o <= 	internal_write_busy(0) or internal_write_busy(1) or 
							internal_write_busy(2) or internal_write_busy(3);
		
		--//assign the next buffer to write when the trig_busy (waiting for trig) line goes high
		--//otherwise, wait for buffer(0) to clear (see "others=>" declaration)
		case internal_event_busy is
			when "0001" =>
				next_write_buffer <= "001"; --// 1
			when "0010" =>
				if internal_buffer_full(0) = '0' then --//check if 1st buffer is clear, if not increment the buffer
					next_write_buffer <= "000"; --// 0
				else
					next_write_buffer <= "010"; --// 2
				end if;
			when "0100" =>
				if internal_buffer_full(0) = '0' then
					next_write_buffer <= "000";
				else
					next_write_buffer <= "011";	--// 3
				end if;
			when "1000" =>
				if internal_buffer_full(0) = '0' then
					next_write_buffer <= "000";
				else
					next_write_buffer <= "100"; --// 4 : not a valid buffer, will prevent further data-taking	
				end if;
			when "0000" =>
				if internal_buffer_full(0) = '0' then
					next_write_buffer <= "000"; --// back to 0
				else
					next_write_buffer <= next_write_buffer;
				end if;
			when others=>
				next_write_buffer <= next_write_buffer;

		end case;
	end if;
end process;
--/////////////////

--/////////////////////////////////////////////////////////	
--//if trigger, write to data ram
proc_save_triggered_event : process(rst_i, clk_i, event_trigger, internal_clear_buffer, next_write_buffer)
begin
	
	for j in 0 to define_num_wfm_buffers-1 loop

		if rst_i = '1' then
			internal_wfm_ram_write_en(j) 	<= '0';
			internal_ram_write_adrs(j) 	<= (others=>'0');
			internal_buffer_full(j) 		<= '0';
			internal_write_busy(j)			<= '0';
			internal_event_busy(j)			<= '0';
			internal_get_event_metadata(j)<= '0';
			save_event_state(j) 				<= idle_st;
	
		elsif rising_edge(clk_i) then
			
			--//clear buffer full signal, but only if write busy is not active
			if internal_clear_buffer(j) = '1' and internal_write_busy(j) = '0' then
				internal_buffer_full(j) <= '0';	
			end if;
				
			case save_event_state(j) is
		
				--//idle
				when idle_st =>
				
					internal_wfm_ram_write_en(j) 	<= '0';
					internal_ram_write_adrs(j) 	<= (others=>'0');
					internal_write_busy(j)	 		<= '0';
					internal_event_busy(j)	 		<= '0';
					internal_get_event_metadata(j)<= '0';
					
					--//go to trig state, if buffer is assigned and buffer is empty
					if next_write_buffer = std_logic_vector(to_unsigned(j, next_write_buffer'length)) and internal_buffer_full(j) = '0' then 
						save_event_state(j) <= trig_st;
					else
						save_event_state(j) <= idle_st;
					end if;
			
				--//wait for trigger
				when trig_st=>
					internal_wfm_ram_write_en(j) 	<= '0';
					internal_ram_write_adrs(j) 	<= (others=>'0');
					internal_write_busy(j)	 		<= '0';
					internal_event_busy(j)			<= '1';
					internal_buffer_full(j) 		<= '0';
					internal_get_event_metadata(j)<= '0';
					
					if event_trigger = '1' then
						internal_wfm_ram_write_en(j) 	<= '1';
						save_event_state(j) <= adr_inc_st;
					else
						save_event_state(j) <= trig_st;
					end if;
			
				--//push data to RAM block, increment address until max address is reached
				when adr_inc_st=>
					internal_wfm_ram_write_en(j) 	<= '1';
					internal_ram_write_adrs(j) 	<= internal_ram_write_adrs(j) + 1;
					internal_write_busy(j) 			<= '1';
					internal_event_busy(j)			<= '1';
					internal_buffer_full(j) 		<= '0';
					
					if internal_ram_write_adrs(j) = internal_address_max then 
						internal_get_event_metadata(j) <= '0';
						save_event_state(j) <= done_st;
					elsif internal_ram_write_adrs(j) = 32 then
						internal_get_event_metadata(j) <= '1';
						save_event_state(j) <= adr_inc_st;
					else
						internal_get_event_metadata(j) <= '0';
						save_event_state(j) <= adr_inc_st;
					end if;
			
				--//saving is done, relax the wr_busy signal and go back to idle state 		
				when done_st =>
					internal_wfm_ram_write_en(j) 	<= '0';
					internal_ram_write_adrs(j) 	<= internal_address_max;
					internal_write_busy(j) 			<= '0';
					internal_event_busy(j)			<= '1';
					internal_buffer_full(j) 		<= '1';
					internal_get_event_metadata(j)<= '0';
					save_event_state(j) 				<= idle_st;
				
			end case;
		end if;
	end loop;
end process;


--//simple block that interprets register to pick which data buffer is being read out
proc_select_wfm_ram : process(reg_i(78))
begin
	case reg_i(78)(1 downto 0) is
		when "00" =>
			data_ram_o <= internal_wfm_ram_0;
		when "01" =>
			data_ram_o <= internal_wfm_ram_1;
		when "10" =>
			data_ram_o <= internal_wfm_ram_2;
		when "11" =>
			data_ram_o <= internal_wfm_ram_3;
	end case;
end process;

xEVENTMETADATA : entity work.event_metadata
port map(
	rst_i					=> rst_i,
	clk_i					=> clk_i,
	clk_iface_i			=> clk_iface_i,
	clk_refrsh_i		=> pulse_refrsh_i,
	buffers_full_i		=> buffers_full,
	trig_i				=> event_trigger,
	trig_type_i			=> internal_last_trigger_type,
	trig_last_beam_i 	=> internal_last_beam_trigger,
	last_trig_pow_i	=> last_trig_pow_i,
	get_metadata_i	 	=> internal_get_event_metadata, 
	reg_i				 	=> reg_i,		
	event_header_o	 	=> event_meta_o);

--//AS OF 7/11/17 this process does not do anything - beam RAM removed --//
--//simple block that interprets register to pick which beam RAM block to readout 
proc_select_beam_ram : process(reg_i(base_adrs_rdout_cntrl+2))
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
--//Multiple buffers for waveform data only [unwieldly to include multi-buffering for beams+powsum, as those are mostly for debugging purposes]
DataRamBlock_0 : for i in 0 to 7 generate
	xDataRAM 	:	entity work.DataRAM
	port map(
		data			=> internal_wfm_data(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> read_ram_adr_i,
		rdclock		=> read_clk_i,
		rden			=> data_ram_read_en_i(i),
		wraddress	=> internal_ram_write_adrs(0), 
		wrclock		=> clk_i,
		wren			=>	internal_wfm_ram_write_en(0),
		q				=>	internal_wfm_ram_0(i));
end generate DataRamBlock_0;
DataRamBlock_1 : for i in 0 to 7 generate
	xDataRAM 	:	entity work.DataRAM
	port map(
		data			=> internal_wfm_data(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> read_ram_adr_i,
		rdclock		=> read_clk_i,
		rden			=> data_ram_read_en_i(i),
		wraddress	=> internal_ram_write_adrs(1), 
		wrclock		=> clk_i,
		wren			=>	internal_wfm_ram_write_en(1),
		q				=>	internal_wfm_ram_1(i));
end generate DataRamBlock_1;
DataRamBlock_2 : for i in 0 to 7 generate
	xDataRAM 	:	entity work.DataRAM
	port map(
		data			=> internal_wfm_data(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> read_ram_adr_i,
		rdclock		=> read_clk_i,
		rden			=> data_ram_read_en_i(i),
		wraddress	=> internal_ram_write_adrs(2), 
		wrclock		=> clk_i,
		wren			=>	internal_wfm_ram_write_en(2),
		q				=>	internal_wfm_ram_2(i));
end generate DataRamBlock_2;
DataRamBlock_3 : for i in 0 to 7 generate
	xDataRAM 	:	entity work.DataRAM
	port map(
		data			=> internal_wfm_data(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> read_ram_adr_i,
		rdclock		=> read_clk_i,
		rden			=> data_ram_read_en_i(i),
		wraddress	=> internal_ram_write_adrs(3), 
		wrclock		=> clk_i,
		wren			=>	internal_wfm_ram_write_en(3),
		q				=>	internal_wfm_ram_3(i));
end generate DataRamBlock_3;

--//end RAM blocks for waveform data

----//////////////////////////////////////////////////////
----//RAM blocks for beams/power sum data
----//note: to save space, these only recorded when buffer=0 (not multi-buffered)
----///////////////////
--BeamRamBlock1 : for i in 0 to define_num_beams-1 generate
--	xBeamRAM 	:	entity work.DataRAM
--	port map(
--		data			=> beam_data_i(i), 
--		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
--		rdaddress	=> read_ram_adr_i,
--		rdclock		=> read_clk_i,
--		rden			=> internal_beam_ram_en_8(i),
--		wraddress	=> internal_ram_write_adrs, 
--		wrclock		=> clk_i,
--		wren			=>	internal_wfm_ram_write_en(0),
--		q				=>	internal_beam_ram_8(i));
--end generate BeamRamBlock1;
--BeamRamBlock2 : for i in 0 to define_num_beams-1 generate
--	xBeamRAM 	:	entity work.DataRAM
--	port map(
--		data			=> beam_data_4a_i(i), 
--		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
--		rdaddress	=> read_ram_adr_i,
--		rdclock		=> read_clk_i,
--		rden			=> internal_beam_ram_en_4a(i),
--		wraddress	=> internal_ram_write_adrs, 
--		wrclock		=> clk_i,
--		wren			=>	internal_wfm_ram_write_en(0),
--		q				=>	internal_beam_ram_4a(i));
--end generate BeamRamBlock2;
--BeamRamBlock3 : for i in 0 to define_num_beams-1 generate
--	xBeamRAM 	:	entity work.DataRAM
--	port map(
--		data			=> beam_data_4b_i(i), 
--		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
--		rdaddress	=> read_ram_adr_i,
--		rdclock		=> read_clk_i,
--		rden			=> internal_beam_ram_en_4b(i),
--		wraddress	=> internal_ram_write_adrs, 
--		wrclock		=> clk_i,
--		wren			=>	internal_wfm_ram_write_en(0),
--		q				=>	internal_beam_ram_4b(i));
--end generate BeamRamBlock3;
----///////////////////
--PowRamBlock : for i in 0 to define_num_beams-1 generate
--	xPowRAM 	:	entity work.DataRAM
--	port map(
--		data			=> internal_powsum_data(i), 
--		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
--		rdaddress	=> read_ram_adr_i,
--		rdclock		=> read_clk_i,
--		rden			=> powsum_ram_read_en_i(i),
--		wraddress	=> internal_ram_write_adrs, 
--		wrclock		=> clk_i,
--		wren			=>	internal_wfm_ram_write_en(0),
--		q				=>	powsum_ram_o(i));
--end generate PowRamBlock;
--////////////////////////////////////////////////////////////////////////////
end rtl;