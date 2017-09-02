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
	generic(
		FIRMWARE_DEVICE   :  std_logic := '1');
	port(
		rst_i					:	in	 std_logic;
		clk_i					:  in	 std_logic; --//core data clock
		clk_iface_i			:	in	 std_logic; --//slower interface clock
		pulse_refrsh_i		:	in	 std_logic;
		wr_busy_o			:	inout std_logic; --//
		
		phased_trig_i		:	in	 std_logic; 
		last_trig_beam_i	: 	in  std_logic_vector(define_num_beams-1 downto 0); --//last beam trigger
		last_trig_pow_i	:	in	 average_power_16samp_type; 
		ext_trig_i			:	in	 std_logic; --//external board trigger
		reg_i					:	in	 register_array_type; --//forced trig sent in register array
		reg_adr_i			:  in  std_logic_vector(define_address_size-1 downto 0);
				
		status_reg_o		:	inout	std_logic_vector(23 downto 0);
		status_reg_latched_o	:	out	std_logic_vector(23 downto 0);
		event_meta_o		:	out	event_metadata_type;

		--//waveform data	
		wfm_data_i				:	in	 	full_data_type;
		running_scalers_i		:  in 	std_logic_vector(23 downto 0);
		data_ram_at_current_adr_o :  out	ram_adr_chunked_data_type);
		
	end data_manager;

architecture rtl of data_manager is
--
type save_event_state_type is (buffer_sel_st, trig_st, adr_inc_st, done_st);
signal save_event_state 	: save_event_state_type;
--		
signal internal_forced_trigger : std_logic;

type internal_ram_write_adr_type is array(define_num_wfm_buffers-1 downto 0) of std_logic_vector(define_data_ram_depth-1 downto 0);
signal internal_ram_write_adrs : internal_ram_write_adr_type;
constant internal_address_max : std_logic_vector(define_data_ram_depth-1 downto 0) := (others=>'1');		

--//squeeze the powsum data into 16-bit chunks (basically just chop off MSB: don't really care here since
--//only time to read out power sum info is for debugging)
type internal_sum_power_type is array(define_num_beams-1 downto 0) of 
	std_logic_vector(define_num_power_sums*define_pow_sum_range-1 downto 0);  
signal internal_powsum_data : internal_sum_power_type;
--//RAM input data (on write clk)
signal internal_wfm_data : full_data_type;  --//delayed data for pre-trig window
signal internal_wfm_data_pipe_0a : full_data_type;
signal internal_wfm_data_pipe_0b : full_data_type;
signal internal_wfm_data_pipe_1 : full_data_type; --//first pipeline stage for fanout to four buffers
signal internal_wfm_data_pipe_2 : full_data_type; --//first pipeline stage for fanout to four buffers
signal internal_wfm_data_pipe_a : full_data_type; --//second pipeline stage for fanout to four buffers
signal internal_wfm_data_pipe_b : full_data_type; --//second pipeline stage for fanout to four buffers
signal internal_wfm_data_pipe_c : full_data_type; --//second pipeline stage for fanout to four buffers
signal internal_wfm_data_pipe_d : full_data_type; --//second pipeline stage for fanout to four buffers
--//////////////////////////////////////
--//RAM output data (on read clk)
--//data arrays:
signal internal_wfm_ram_0 : full_data_type; --//data buffer 1
signal internal_wfm_ram_1 : full_data_type; --//data buffer 2
signal internal_wfm_ram_2 : full_data_type; --//data buffer 3
signal internal_wfm_ram_3 : full_data_type; --//data buffer 4
signal internal_wfm_ram_0_chan_sel : std_logic_vector(define_ram_width-1 downto 0); --//data buffer 1, with channel sliced
signal internal_wfm_ram_1_chan_sel : std_logic_vector(define_ram_width-1 downto 0); --//data buffer 2, with channel sliced
signal internal_wfm_ram_2_chan_sel : std_logic_vector(define_ram_width-1 downto 0); --//data buffer 3, with channel sliced
signal internal_wfm_ram_3_chan_sel : std_logic_vector(define_ram_width-1 downto 0); --//data buffer 4, with channel sliced
----------------
signal internal_wfm_ram_write_en 	: std_logic_vector(define_num_wfm_buffers-1 downto 0);
signal internal_buffer_full  			: std_logic_vector(define_num_wfm_buffers-1 downto 0);
signal internal_clear_buffer 			: std_logic_vector(define_num_wfm_buffers-1 downto 0);
signal internal_write_busy				: std_logic_vector(define_num_wfm_buffers-1 downto 0);
signal internal_get_event_metadata  : std_logic;
signal internal_next_buffer			: std_logic_vector(1 downto 0);
signal the_write_buffer					: std_logic_vector(1 downto 0);
signal internal_current_buffer		: std_logic_vector(1 downto 0);
signal internal_buffer_reset_to_zero		: std_logic;
signal internal_buffer_reset_to_zero_wait : std_logic;

signal internal_phase_trigger_data_enable : std_logic := '0';

--signal internal_data_manager_status : std_logic_vector(23 downto 0) := (others=>'0'); --//status register
signal status_reg_update_reg 	: std_logic_vector(2 downto 0) := (others=>'0');

signal internal_last_trigger_type : std_logic_vector(1 downto 0) := "00"; --//record trigger type
signal internal_last_beam_trigger : std_logic_vector(define_num_beams-1 downto 0);
signal event_trigger_reg : std_logic_vector(2 downto 0) := (others=>'0');
signal buffers_full	: std_logic;

--//ram read signals
signal internal_ram_read_en : std_logic_vector(7 downto 0);
signal internal_ram_read_adr : std_logic_vector(define_data_ram_depth-1 downto 0);
signal internal_ram_read_clk_reg	: std_logic_vector(4 downto 0);
signal read_ch : integer range 0 to 7 := 0;
constant d_width : integer := 32;
constant word_size : integer := 8;

--//pretrig window sync:
signal internal_pre_trig_window_select : std_logic_vector(2 downto 0);

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
--//////////////////////////////////////////////////////////
--//sync reset buffer number flag to 0
xBUFNUMRESETSYNC : flag_sync
port map(
		clkA 			=> clk_iface_i,
		clkB			=> clk_i,
		in_clkA		=> reg_i(base_adrs_rdout_cntrl+13)(8),
		busy_clkA	=> open,
		out_clkB		=> internal_buffer_reset_to_zero);
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
--/////////////////////////////////////////////////////////
--//sync pretrig window register values
PreTrigSync : for i in 0 to 2 generate
	xPRETRIGSYNC : signal_sync
	port map(
		clkA 			=> clk_iface_i,
		clkB			=> clk_i,
		SignalIn_clkA		=> reg_i(76)(i),
		SignalOut_clkB		=> internal_pre_trig_window_select(i));
end generate;
--/////////////////////////////////////////////////////////
xPHASEDTRIGENABLESYNC : signal_sync
port map(
	clkA 			=> clk_iface_i,
	clkB			=> clk_i,
	SignalIn_clkA		=> reg_i(84)(0),
	SignalOut_clkB		=> internal_phase_trigger_data_enable);
------------------------------------------------------------------
--//////////////////////////////////////
--//apply programmable pre-trigger window and pipeline the output data into 4 buffers using 2 extra clk cycles
PreTrigBlock : for i in 0 to 7 generate
	xPRETRIGBLOCK : entity work.pretrigger_window
	port map(
		rst_i		=> rst_i,
		clk_i		=>	clk_i,
		pretrig_sel_i =>	internal_pre_trig_window_select,
		data_i	=>	wfm_data_i(i),
		data_o	=>	internal_wfm_data(i));
end generate;
proc_pipe_multibuffer_data : process(clk_i, internal_wfm_data, 
												internal_wfm_data_pipe_1, internal_wfm_data_pipe_2)
--//limit fanout of data arrays to 2 per clk_i cycle:
begin
	if rising_edge(clk_i) then
		internal_wfm_data_pipe_a <= internal_wfm_data_pipe_1; 
		internal_wfm_data_pipe_b <= internal_wfm_data_pipe_1; 
		internal_wfm_data_pipe_c <= internal_wfm_data_pipe_2; 
		internal_wfm_data_pipe_d <= internal_wfm_data_pipe_2; 
		internal_wfm_data_pipe_1 <= internal_wfm_data_pipe_0b;
		internal_wfm_data_pipe_2 <= internal_wfm_data_pipe_0b;
		internal_wfm_data_pipe_0b <= internal_wfm_data_pipe_0a;
		internal_wfm_data_pipe_0a <= internal_wfm_data;
	end if;
end process;
--//////////////////////////////////////
------------------------------------------------------------------------------------------------------------------------------
--//////////////////////////////////////
--//register trigger signal
--//trigger types: 1 = software trigger, 2 = beam trigger, 3 = ext trigger
proc_reg_trig : process(rst_i, clk_i, internal_forced_trigger, phased_trig_i, ext_trig_i, internal_phase_trigger_data_enable)
begin
	if rst_i = '1' then
		event_trigger_reg(0) <= '0';
		internal_last_beam_trigger <= (others=>'0');
		internal_last_trigger_type <= (others=>'0');
	elsif rising_edge(clk_i) and internal_forced_trigger = '1' then
		event_trigger_reg(0) <= '1';
		internal_last_trigger_type <= "01";
	elsif rising_edge(clk_i) and phased_trig_i = '1' and internal_phase_trigger_data_enable = '1'  then 
		event_trigger_reg(0) <= '1';
		internal_last_beam_trigger <= last_trig_beam_i; --//update the beam trigger info
		internal_last_trigger_type <= "10";
	elsif rising_edge(clk_i) and ext_trig_i = '1' then 
		event_trigger_reg(0) <= '1';
		internal_last_trigger_type <= "11";
	elsif rising_edge(clk_i) then
		event_trigger_reg(0) <= '0';
	end if;
	
	if rising_edge(clk_i) then
		event_trigger_reg(2 downto 1) <= event_trigger_reg(1 downto 0);
	end if;
end process;

------------------------------------------------------------------------------------------------------------------------------
--//data manager status register: 
--//note this register is re-clocked in the registers module before read, so no metastability issues 
-----------------------
proc_stat_reg : process(rst_i, clk_iface_i, reg_adr_i, internal_buffer_full, the_write_buffer, internal_last_trigger_type,
								status_reg_update_reg, status_reg_o)
begin
	if rst_i = '1' then
		status_reg_o <= (others=>'0');
		status_reg_latched_o <= (others=>'0');
		
	elsif rising_edge(clk_iface_i) then
		status_reg_o(3 downto 0) <= internal_buffer_full;
		status_reg_o(8) <= buffers_full;
		status_reg_o(13 downto 12) <= the_write_buffer;
		status_reg_o(17 downto 16) <= internal_last_trigger_type;
		status_reg_update_reg(2 downto 1) <= status_reg_update_reg(1 downto 0);
		if reg_adr_i  = x"4D" then
			status_reg_update_reg(0) <= '1';
		end if;
		if status_reg_update_reg(2) = '1' then
			status_reg_latched_o <= status_reg_o;
		end if;
	end if;
end process;
------------------------------------------------------------------------------------------------------------------------------
--/////////////////////////////////////////////////////////	
--//manage buffers. if trigger, write to data ram
proc_save_triggered_event : process(rst_i, clk_i, event_trigger_reg, internal_clear_buffer, wr_busy_o, internal_write_busy,
												internal_buffer_full, save_event_state)
variable buf : integer range 0 to 3 := 0;
begin
	if rst_i = '1' then
		internal_wfm_ram_write_en	 	<= (others=>'0');
		for i in 0 to define_num_wfm_buffers-1 loop
			internal_ram_write_adrs(i) <= (others=>'0');
		end loop;
		internal_buffer_full		 		<= (others=>'0');
		internal_write_busy 				<= (others=>'0');
		internal_get_event_metadata	<= '0';
		internal_current_buffer 		<= "00";
		internal_buffer_reset_to_zero_wait <= '0';
		buf 									:= 0;
		--internal_next_buffer 			<= "00";
		buffers_full 						<= '0';
		wr_busy_o 							<= '0';
		save_event_state 					<= buffer_sel_st;
	
	elsif rising_edge(clk_i) then
		buffers_full <= internal_buffer_full(0) and internal_buffer_full(1) and internal_buffer_full(2) and internal_buffer_full(3); --//deadtime
		wr_busy_o <= 	internal_write_busy(0) or internal_write_busy(1) or 
							internal_write_busy(2) or internal_write_busy(3);
							
		the_write_buffer <=	internal_current_buffer;
								
		case save_event_state is
		
			--//idle, target the next open buffer 
			--//(either increment forward, or, if all buffers full, try buffer 0)
			when buffer_sel_st =>
				
				internal_wfm_ram_write_en     <= (others=>'0'); --//ram write enable off
				for i in 0 to define_num_wfm_buffers-1 loop
					internal_ram_write_adrs(i) <= (others=>'0');  --//all ram write addresses at 0x0
				end loop;
				internal_write_busy		 		<= (others=>'0');	--//write NOT busy
				internal_get_event_metadata	<= '0';				--//save metadata flag
				
				--//clear buffer full signal if toggled
				for i in 0 to define_num_wfm_buffers-1 loop
					internal_buffer_full(i) <= internal_buffer_full(i) and (not internal_clear_buffer(i));	
				end loop;
				
				--///////////////////////////////////////
				--//check buffer full flags
				--//////////////////////////////////////
				--//first, check buffer 0
--				if internal_buffer_full(0) = '0' then
--					internal_current_buffer <= "00";
--					buf := 0;
--					save_event_state <= trig_st;
--				--//if buffer 0 is full, check the next buffer after the current buffer
--				elsif internal_buffer_full(to_integer(unsigned(internal_next_buffer))) = '0' then
				
				internal_buffer_reset_to_zero_wait <= '0';
				--//software option to reset next buffer to 0. 
				if internal_buffer_reset_to_zero = '1' or internal_buffer_reset_to_zero_wait = '1' then
					internal_next_buffer <= "00";
					internal_current_buffer <= "00";
					save_event_state <= buffer_sel_st;
				elsif internal_buffer_full(to_integer(unsigned(internal_next_buffer))) = '0' then
					internal_current_buffer <= internal_next_buffer;
					buf := to_integer(unsigned(internal_next_buffer));
					save_event_state 			<= trig_st;
				--//otherwise, buffers are full
				else
					save_event_state <= buffer_sel_st;
				end if;		
				
			--//wait for trigger
			when trig_st=>
				internal_wfm_ram_write_en(buf)	<= '0';
				internal_ram_write_adrs(buf)		<= (others=>'0');
				internal_write_busy(buf)	 		<= '0';
				internal_get_event_metadata		<= '0'; --//
				internal_buffer_full(buf) 		  	<= '0'; --//buffer is empty
				internal_buffer_reset_to_zero_wait <= '0';
				
				for i in 0 to define_num_wfm_buffers-1 loop
					internal_buffer_full(i) <= internal_buffer_full(i) and (not internal_clear_buffer(i));	
				end loop;
				
				if event_trigger_reg(1) = '1' or event_trigger_reg(2) = '1' then
					internal_wfm_ram_write_en(buf)<= '1'; --//enable the ram_wr_en 
					save_event_state <= adr_inc_st; --//go to address increment state
				elsif internal_buffer_reset_to_zero = '1'  then
					internal_next_buffer <= "00";
					internal_current_buffer <= "00";
					save_event_state <= buffer_sel_st;
				else
					save_event_state <= trig_st;
				end if;
		
			--//push data to RAM block, increment address until max address is reached
			when adr_inc_st=>
				internal_wfm_ram_write_en(buf)<= '1';
				internal_ram_write_adrs(buf) 	<= internal_ram_write_adrs(buf) + 1;
				internal_write_busy(buf) 		<= '1';

				for i in 0 to define_num_wfm_buffers-1 loop
					if i /= buf then
						internal_buffer_full(i) <= internal_buffer_full(i) and (not internal_clear_buffer(i));	
					end if;
				end loop;
				
				--//if request to reset buffer to 0, need to wait until trigger has been processed:
				if internal_buffer_reset_to_zero = '1'  then
					internal_buffer_reset_to_zero_wait <= '1';
				else
					internal_buffer_reset_to_zero_wait <= internal_buffer_reset_to_zero_wait;
				end if;
				
				if internal_ram_write_adrs(buf) = internal_address_max then 
					internal_get_event_metadata <= '0';
					internal_buffer_full(buf) 	 <= '1'; --//buffer full
					--------------
					internal_next_buffer <= internal_current_buffer + 1;  --//set the next buffer to the current_buffer + 1
					--------------
					save_event_state <= done_st;
				elsif internal_ram_write_adrs(buf) = x"0F" then
					internal_get_event_metadata <= '1';     --//assert the get_event_metadata flag
					internal_buffer_full(buf) 	 <= '0';
					save_event_state <= adr_inc_st;
				else
					internal_get_event_metadata <= '0';
					internal_buffer_full(buf) 	<= '0';
					save_event_state <= adr_inc_st;
				end if;
				
			--//saving is done, relax the wr_busy signal and go back to idle state 		
			when done_st =>
				internal_wfm_ram_write_en(buf)	<= '0'; --//disable ram_wr_en
				internal_ram_write_adrs(buf) 		<= internal_address_max;
				internal_write_busy(buf)			<= '1';
				internal_get_event_metadata		<= '0';
				internal_buffer_full(buf) 			<= '1';  --//buffer full!
				save_event_state						<= buffer_sel_st; --//back to buffer sel state
					
				for i in 0 to define_num_wfm_buffers-1 loop
					if i /= buf then
						internal_buffer_full(i) <= internal_buffer_full(i) and (not internal_clear_buffer(i));	
					end if;
				end loop;
				
				if internal_buffer_reset_to_zero = '1'  then
					internal_buffer_reset_to_zero_wait <= '1';
				else
					internal_buffer_reset_to_zero_wait <= internal_buffer_reset_to_zero_wait;
				end if;
				
			when others=>
				save_event_state <= buffer_sel_st;
				
		end case;
	end if;
end process;
------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////
--//RAM Read process definitions here
process(clk_iface_i, rst_i, reg_i)
begin

	if rst_i = '1' then
		read_ch <= 0;
		internal_ram_read_en <= (others=>'0'); --/wfm ram read en	
		internal_ram_read_clk_reg <= (others=>'0');
	elsif rising_edge(clk_iface_i) then
	
		--///////////////////
		--//update read address and pulse the read clk
		--------------------------------------------------
		--//delay the ram read clock by one clock cycle after the address is set
		internal_ram_read_clk_reg(4 downto 1) <= internal_ram_read_clk_reg(3 downto 0);
		if internal_ram_read_clk_reg(0) = '1' then
			internal_ram_read_adr <= reg_i(69)(define_data_ram_depth-1 downto 0);
		end if;
		case reg_adr_i is
			when x"45" =>
				internal_ram_read_clk_reg(0) <= '1';
			when others=>
				internal_ram_read_clk_reg(0) <= '0';
		end case;
	
		--//////////////////////////////////////
		--//update readout channel
		case reg_i(base_adrs_rdout_cntrl+1)(7 downto 0) is
			when "00000001" => 
				read_ch <= 0;
				internal_ram_read_en <= "00000001";
			when "00000010" =>
				read_ch <= 1;
				internal_ram_read_en <= "00000010";
			when "00000100" =>
				read_ch <= 2;
				internal_ram_read_en <= "00000100";
			when "00001000" => 
				read_ch <= 3;
				internal_ram_read_en <= "00001000";
			when "00010000" =>
				read_ch <= 4;
				internal_ram_read_en <= "00010000";
			when "00100000" => 
				read_ch <= 5;
				internal_ram_read_en <= "00100000";
			when "01000000" => 
				read_ch <= 6;
				internal_ram_read_en <= "01000000";
			when "10000000" => 
				read_ch <= 7;
				internal_ram_read_en <= "10000000";
			when others=>
				read_ch <= 0;
				internal_ram_read_en <= (others=>'0');
		end case;
	end if;
end process;
------------------------------------------------------------------------------------------------------------------------------
--//interpret register to assign data buffer to readout
proc_select_wfm_ram : process(clk_iface_i, reg_i(78), read_ch, internal_wfm_ram_0, internal_wfm_ram_1, 
										internal_wfm_ram_2, internal_wfm_ram_3, internal_wfm_ram_0_chan_sel, internal_wfm_ram_1_chan_sel, 
										internal_wfm_ram_2_chan_sel, internal_wfm_ram_3_chan_sel,internal_ram_read_clk_reg)
begin
	----------------------------------------------
	--//read clk was pulsed at internal_ram_read_clk_reg(2),
	--//so data should be valid at the next clock cycle
	----------------------------------------------
	--//first, pipeline process by slicing out channel selected:
	if rising_edge(clk_iface_i) and internal_ram_read_clk_reg(3) = '1' then 
		internal_wfm_ram_0_chan_sel <= internal_wfm_ram_0(read_ch);
		internal_wfm_ram_1_chan_sel <= internal_wfm_ram_1(read_ch);
		internal_wfm_ram_2_chan_sel <= internal_wfm_ram_2(read_ch);
		internal_wfm_ram_3_chan_sel <= internal_wfm_ram_3(read_ch);
	end if;
	-------------------------------------------------------
	--//second, cut data into chunks and reorder bytes. Assign to output:
	if rising_edge(clk_iface_i) and internal_ram_read_clk_reg(4) = '1' then 
		case reg_i(78)(1 downto 0) is
			--//NOTE: byte reordering in each 'chunk' to make software-world easier
			-----------------------------
			--//1st buffer:
			when "00" =>
				data_ram_at_current_adr_o(0) <= internal_wfm_ram_0_chan_sel(word_size-1+0*d_width downto 0*d_width) &  
												internal_wfm_ram_0_chan_sel(2*word_size-1+0*d_width downto 0*d_width+word_size) &
												internal_wfm_ram_0_chan_sel(3*word_size-1+0*d_width downto 0*d_width+word_size*2) &
												internal_wfm_ram_0_chan_sel(4*word_size-1+0*d_width downto 0*d_width+word_size*3);   --//1st chunk
				data_ram_at_current_adr_o(1) <= internal_wfm_ram_0_chan_sel(word_size-1+1*d_width downto 1*d_width) &  
												internal_wfm_ram_0_chan_sel(2*word_size-1+1*d_width downto 1*d_width+word_size) &
												internal_wfm_ram_0_chan_sel(3*word_size-1+1*d_width downto 1*d_width+word_size*2) &
												internal_wfm_ram_0_chan_sel(4*word_size-1+1*d_width downto 1*d_width+word_size*3);   --//2nd chunk  							
				data_ram_at_current_adr_o(2) <= internal_wfm_ram_0_chan_sel(word_size-1+2*d_width downto 2*d_width) &  
												internal_wfm_ram_0_chan_sel(2*word_size-1+2*d_width downto 2*d_width+word_size) &
												internal_wfm_ram_0_chan_sel(3*word_size-1+2*d_width downto 2*d_width+word_size*2) &
												internal_wfm_ram_0_chan_sel(4*word_size-1+2*d_width downto 2*d_width+word_size*3);   --//3rd chunk    							
				data_ram_at_current_adr_o(3) <= internal_wfm_ram_0_chan_sel(word_size-1+3*d_width downto 3*d_width) &  
												internal_wfm_ram_0_chan_sel(2*word_size-1+3*d_width downto 3*d_width+word_size) &
												internal_wfm_ram_0_chan_sel(3*word_size-1+3*d_width downto 3*d_width+word_size*2) &
												internal_wfm_ram_0_chan_sel(4*word_size-1+3*d_width downto 3*d_width+word_size*3);   --//4th chunk   
			--//2nd buffer:
			when "01" =>
				data_ram_at_current_adr_o(0) <= internal_wfm_ram_1_chan_sel(word_size-1+0*d_width downto 0*d_width) &  
												internal_wfm_ram_1_chan_sel(2*word_size-1+0*d_width downto 0*d_width+word_size) &
												internal_wfm_ram_1_chan_sel(3*word_size-1+0*d_width downto 0*d_width+word_size*2) &
												internal_wfm_ram_1_chan_sel(4*word_size-1+0*d_width downto 0*d_width+word_size*3);   --//1st chunk
				data_ram_at_current_adr_o(1) <= internal_wfm_ram_1_chan_sel(word_size-1+1*d_width downto 1*d_width) &  
												internal_wfm_ram_1_chan_sel(2*word_size-1+1*d_width downto 1*d_width+word_size) &
												internal_wfm_ram_1_chan_sel(3*word_size-1+1*d_width downto 1*d_width+word_size*2) &
												internal_wfm_ram_1_chan_sel(4*word_size-1+1*d_width downto 1*d_width+word_size*3);   --//2nd chunk  							
				data_ram_at_current_adr_o(2) <= internal_wfm_ram_1_chan_sel(word_size-1+2*d_width downto 2*d_width) &  
												internal_wfm_ram_1_chan_sel(2*word_size-1+2*d_width downto 2*d_width+word_size) &
												internal_wfm_ram_1_chan_sel(3*word_size-1+2*d_width downto 2*d_width+word_size*2) &
												internal_wfm_ram_1_chan_sel(4*word_size-1+2*d_width downto 2*d_width+word_size*3);   --//3rd chunk    							
				data_ram_at_current_adr_o(3) <= internal_wfm_ram_1_chan_sel(word_size-1+3*d_width downto 3*d_width) &  
												internal_wfm_ram_1_chan_sel(2*word_size-1+3*d_width downto 3*d_width+word_size) &
												internal_wfm_ram_1_chan_sel(3*word_size-1+3*d_width downto 3*d_width+word_size*2) &
												internal_wfm_ram_1_chan_sel(4*word_size-1+3*d_width downto 3*d_width+word_size*3);   --//4th chunk  
			--//3rd buffer:
			when "10" =>
				data_ram_at_current_adr_o(0) <= internal_wfm_ram_2_chan_sel(word_size-1+0*d_width downto 0*d_width) &  
												internal_wfm_ram_2_chan_sel(2*word_size-1+0*d_width downto 0*d_width+word_size) &
												internal_wfm_ram_2_chan_sel(3*word_size-1+0*d_width downto 0*d_width+word_size*2) &
												internal_wfm_ram_2_chan_sel(4*word_size-1+0*d_width downto 0*d_width+word_size*3);   --//1st chunk
				data_ram_at_current_adr_o(1) <= internal_wfm_ram_2_chan_sel(word_size-1+1*d_width downto 1*d_width) &  
												internal_wfm_ram_2_chan_sel(2*word_size-1+1*d_width downto 1*d_width+word_size) &
												internal_wfm_ram_2_chan_sel(3*word_size-1+1*d_width downto 1*d_width+word_size*2) &
												internal_wfm_ram_2_chan_sel(4*word_size-1+1*d_width downto 1*d_width+word_size*3);   --//2nd chunk  							
				data_ram_at_current_adr_o(2) <= internal_wfm_ram_2_chan_sel(word_size-1+2*d_width downto 2*d_width) &  
												internal_wfm_ram_2_chan_sel(2*word_size-1+2*d_width downto 2*d_width+word_size) &
												internal_wfm_ram_2_chan_sel(3*word_size-1+2*d_width downto 2*d_width+word_size*2) &
												internal_wfm_ram_2_chan_sel(4*word_size-1+2*d_width downto 2*d_width+word_size*3);   --//3rd chunk    							
				data_ram_at_current_adr_o(3) <= internal_wfm_ram_2_chan_sel(word_size-1+3*d_width downto 3*d_width) &  
												internal_wfm_ram_2_chan_sel(2*word_size-1+3*d_width downto 3*d_width+word_size) &
												internal_wfm_ram_2_chan_sel(3*word_size-1+3*d_width downto 3*d_width+word_size*2) &
												internal_wfm_ram_2_chan_sel(4*word_size-1+3*d_width downto 3*d_width+word_size*3);   --//4th chunk 
			--//4th buffer:
			when "11" =>
				data_ram_at_current_adr_o(0) <= internal_wfm_ram_3_chan_sel(word_size-1+0*d_width downto 0*d_width) &  
												internal_wfm_ram_3_chan_sel(2*word_size-1+0*d_width downto 0*d_width+word_size) &
												internal_wfm_ram_3_chan_sel(3*word_size-1+0*d_width downto 0*d_width+word_size*2) &
												internal_wfm_ram_3_chan_sel(4*word_size-1+0*d_width downto 0*d_width+word_size*3);   --//1st chunk
				data_ram_at_current_adr_o(1) <= internal_wfm_ram_3_chan_sel(word_size-1+1*d_width downto 1*d_width) &  
												internal_wfm_ram_3_chan_sel(2*word_size-1+1*d_width downto 1*d_width+word_size) &
												internal_wfm_ram_3_chan_sel(3*word_size-1+1*d_width downto 1*d_width+word_size*2) &
												internal_wfm_ram_3_chan_sel(4*word_size-1+1*d_width downto 1*d_width+word_size*3);   --//2nd chunk  							
				data_ram_at_current_adr_o(2) <= internal_wfm_ram_3_chan_sel(word_size-1+2*d_width downto 2*d_width) &  
												internal_wfm_ram_3_chan_sel(2*word_size-1+2*d_width downto 2*d_width+word_size) &
												internal_wfm_ram_3_chan_sel(3*word_size-1+2*d_width downto 2*d_width+word_size*2) &
												internal_wfm_ram_3_chan_sel(4*word_size-1+2*d_width downto 2*d_width+word_size*3);   --//3rd chunk    							
				data_ram_at_current_adr_o(3) <= internal_wfm_ram_3_chan_sel(word_size-1+3*d_width downto 3*d_width) &  
												internal_wfm_ram_3_chan_sel(2*word_size-1+3*d_width downto 3*d_width+word_size) &
												internal_wfm_ram_3_chan_sel(3*word_size-1+3*d_width downto 3*d_width+word_size*2) &
												internal_wfm_ram_3_chan_sel(4*word_size-1+3*d_width downto 3*d_width+word_size*3);   --//4th chunk  	
		
			when others=>
				for j in 0 to 3 loop
					data_ram_at_current_adr_o(j) <= (others=>'0');
				end loop;
		end case;
	end if;
end process;
------------------------------------------------------------------------------------------------------------------------------
xEVENTMETADATA : entity work.event_metadata
port map(
	rst_i					=> rst_i,
	clk_i					=> clk_i,
	clk_iface_i			=> clk_iface_i,
	clk_refrsh_i		=> pulse_refrsh_i,
	buffers_full_i		=> buffers_full,
	trig_i				=> event_trigger_reg(1),
	trig_type_i			=> internal_last_trigger_type,
	trig_last_beam_i 	=> internal_last_beam_trigger,
	last_trig_pow_i	=> last_trig_pow_i,
	running_scaler_i  => running_scalers_i,
	get_metadata_i	 	=> internal_get_event_metadata, 
	current_buffer_i	=> internal_current_buffer,
	reg_i				 	=> reg_i,		
	event_header_o	 	=> event_meta_o);
------------------------------------------------------------------------------------------------------------------------------
--///////////////////
--//FPGA RAM blocks defined here:
--///////////////////
--//Multiple buffers for waveform data only [unwieldly to include multi-buffering for beams+powsum, as those are mostly for debugging purposes]
DataRamBlock_0 : for i in 0 to 7 generate
	xDataRAM 	:	entity work.DataRAM
	port map(
		data			=> internal_wfm_data_pipe_a(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> internal_ram_read_adr,
		rdclock		=> internal_ram_read_clk_reg(2),
		rden			=> internal_ram_read_en(i),
		wraddress	=> internal_ram_write_adrs(0), 
		wrclock		=> clk_i,
		wren			=>	internal_wfm_ram_write_en(0),
		q				=>	internal_wfm_ram_0(i));
end generate DataRamBlock_0;
DataRamBlock_1 : for i in 0 to 7 generate
	xDataRAM 	:	entity work.DataRAM
	port map(
		data			=> internal_wfm_data_pipe_b(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> internal_ram_read_adr,
		rdclock		=> internal_ram_read_clk_reg(2),
		rden			=> internal_ram_read_en(i),
		wraddress	=> internal_ram_write_adrs(1), 
		wrclock		=> clk_i,
		wren			=>	internal_wfm_ram_write_en(1),
		q				=>	internal_wfm_ram_1(i));
end generate DataRamBlock_1;
DataRamBlock_2 : for i in 0 to 7 generate
	xDataRAM 	:	entity work.DataRAM
	port map(
		data			=> internal_wfm_data_pipe_c(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> internal_ram_read_adr,
		rdclock		=> internal_ram_read_clk_reg(2),
		rden			=> internal_ram_read_en(i),
		wraddress	=> internal_ram_write_adrs(2), 
		wrclock		=> clk_i,
		wren			=>	internal_wfm_ram_write_en(2),
		q				=>	internal_wfm_ram_2(i));
end generate DataRamBlock_2;
DataRamBlock_3 : for i in 0 to 7 generate
	xDataRAM 	:	entity work.DataRAM
	port map(
		data			=> internal_wfm_data_pipe_d(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> internal_ram_read_adr,
		rdclock		=> internal_ram_read_clk_reg(2),
		rden			=> internal_ram_read_en(i),
		wraddress	=> internal_ram_write_adrs(3), 
		wrclock		=> clk_i,
		wren			=>	internal_wfm_ram_write_en(3),
		q				=>	internal_wfm_ram_3(i));
end generate DataRamBlock_3;

--//end RAM blocks for waveform data

--////////////////////////////////////////////////////////////////////////////
end rtl;