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
		last_trig_beam_i	: 	in  std_logic_vector(define_num_beams-1 downto 0); --//last beam trigger
		last_trig_pow_i	:	in	 average_power_16samp_type; 
		ext_trig_i			:	in	 std_logic; --//external board trigger
		reg_i					:	in	 register_array_type; --//forced trig sent in register array
		reg_adr_i			:  in  std_logic_vector(define_address_size-1 downto 0);
				
		status_reg_o		:	out	std_logic_vector(23 downto 0);
		event_meta_o		:	out	event_metadata_type;

		--//waveform data	
		wfm_data_i				:	in	 	full_data_type;
		data_ram_at_current_adr_o :  out	ram_adr_chunked_data_type);
		
	end data_manager;

architecture rtl of data_manager is
--
type save_event_state_type is (buffer_sel_st, trig_st, adr_inc_st, done_st);
signal save_event_state 	: save_event_state_type;
--		
signal internal_forced_trigger : std_logic;

signal internal_ram_write_adrs : std_logic_vector(define_data_ram_depth-1 downto 0);
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
signal internal_buffer_full  			: std_logic_vector(define_num_wfm_buffers-1 downto 0);
signal internal_clear_buffer 			: std_logic_vector(define_num_wfm_buffers-1 downto 0);
signal internal_write_busy				: std_logic_vector(define_num_wfm_buffers-1 downto 0);
signal internal_event_busy				: std_logic;
signal internal_get_event_metadata  : std_logic_vector(define_num_wfm_buffers-1 downto 0);
signal internal_next_buffer			: std_logic_vector(1 downto 0);
signal next_write_buffer				: std_logic_vector(1 downto 0);
signal internal_current_buffer		: std_logic_vector(1 downto 0);

--signal internal_data_manager_status : std_logic_vector(23 downto 0) := (others=>'0'); --//status register

signal internal_last_trigger_type : std_logic_vector(1 downto 0) := "00"; --//record trigger type
signal internal_last_beam_trigger : std_logic_vector(define_num_beams-1 downto 0);
signal event_trigger : std_logic;
signal buffers_full	: std_logic;

--//ram read signals
signal internal_ram_read_en : std_logic_vector(7 downto 0);
signal internal_ram_read_adr : std_logic_vector(define_data_ram_depth-1 downto 0);
signal internal_ram_read_clk_reg	: std_logic_vector(3 downto 0);
signal read_ch : integer range 0 to 7 := 0;
constant d_width : integer := 32;
constant word_size : integer := 8;


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
proc_reg_trig : process(rst_i, clk_i, internal_forced_trigger, phased_trig_i, ext_trig_i)
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
		--internal_last_trigger_type <= internal_last_trigger_type;
	end if;
end process;

--StatRegSync : for i in 0 to 23 generate
--	xSTATREGSYNC : signal_sync 
--	port map(
--		clkA 			=> clk_i,
--		clkB			=> clk_iface_i,
--		SignalIn_clkA		=> internal_data_manager_status(i),
--		SignalOut_clkB		=> status_reg_o(i));
--end generate;
--//////////////////////////////////////


proc_stat_reg : process(clk_iface_i, internal_buffer_full, next_write_buffer, internal_last_trigger_type)
begin
	status_reg_o(3 downto 0) <= internal_buffer_full;
	status_reg_o(8) <= internal_buffer_full(0) or internal_buffer_full(1) or internal_buffer_full(2) or internal_buffer_full(3);
	status_reg_o(13 downto 12) <= next_write_buffer;
	status_reg_o(17 downto 16) <= internal_last_trigger_type;
end process;


--/////////////////////////////////////////////////////////	
--//manage buffers. if trigger, write to data ram
proc_save_triggered_event : process(rst_i, clk_i, event_trigger, internal_clear_buffer)
variable buf : integer range 0 to 3 := 0;
begin
	if rst_i = '1' then
		internal_wfm_ram_write_en	 	<= (others=>'0');
		internal_ram_write_adrs 		<= (others=>'0');
		internal_buffer_full		 		<= (others=>'0');
		internal_write_busy 				<= (others=>'0');
		internal_event_busy 				<= '0';
		internal_current_buffer 		<= "00";
		buf 									:= 0;
		internal_next_buffer 			<= "00";
		buffers_full 						<= '0';
		wr_busy_o 							<= '0';
		save_event_state 					<= buffer_sel_st;
	
	elsif rising_edge(clk_i) then
		buffers_full <= internal_buffer_full(0) and internal_buffer_full(1) and internal_buffer_full(2) and internal_buffer_full(3); --//deadtime
		wr_busy_o <= 	internal_write_busy(0) or internal_write_busy(1) or 
							internal_write_busy(2) or internal_write_busy(3);
							
		next_write_buffer <=	internal_next_buffer;
							
		--//clear buffer full signal, but only if write busy is not active for that buffer
		for i in 0 to define_num_wfm_buffers-1 loop
			if internal_clear_buffer(i) = '1' and internal_write_busy(i) = '0' then
				internal_buffer_full(i) <= '0';	
			end if;
		end loop;
		
		case save_event_state is
		
			--//idle, target the next open buffer 
			--//(either increment forward, or, if all buffers full, try buffer 0)
			when buffer_sel_st =>
				
				internal_wfm_ram_write_en     <= (others=>'0'); --//ram write enable off
				internal_ram_write_adrs		 	<= (others=>'0'); --//ram write address at 0x0
				internal_write_busy		 		<= (others=>'0');	--//write NOT busy
				internal_event_busy		 		<= '0';				--//event NOT busy
				
				--///////////////////////////////////////
				--//check buffer full flags
				--//////////////////////////////////////
				--//first, check buffer 0
				if internal_buffer_full(0) = '0' then
					internal_current_buffer <= "00";
					buf := 0;
					save_event_state <= trig_st;
				--//if buffer 0 is full, check the next buffer after the current buffer
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
				--------------
				internal_next_buffer <= internal_current_buffer + 1;  --//set the next buffer to the current_buffer + 1
				--------------
				internal_wfm_ram_write_en(buf)	<= '0';
				internal_ram_write_adrs 			<= (others=>'0');
				internal_write_busy(buf)	 		<= '0';
				internal_event_busy					<= '0'; --//event is busy
				internal_buffer_full(buf) 		  	<= '0'; --//buffer is empty
				
				if event_trigger = '1' then
					internal_wfm_ram_write_en(buf)<= '1'; --//enable the ram_wr_en 
					save_event_state <= adr_inc_st; --//go to address increment state
				else
					save_event_state <= trig_st;
				end if;
		
			--//push data to RAM block, increment address until max address is reached
			when adr_inc_st=>
				internal_wfm_ram_write_en(buf)<= '1';
				internal_ram_write_adrs 		<= internal_ram_write_adrs + 1;
				internal_write_busy(buf) 		<= '1';
				internal_event_busy				<= '1';
				internal_buffer_full(buf) 		<= '0';
				
				if internal_ram_write_adrs = internal_address_max then 
					internal_get_event_metadata(buf) <= '0';
					save_event_state <= done_st;
				else
					internal_get_event_metadata(buf) <= '0';
					save_event_state <= adr_inc_st;
				end if;
		
			--//saving is done, relax the wr_busy signal and go back to idle state 		
			when done_st =>
				internal_wfm_ram_write_en(buf)	<= '0'; --//disable ram_wr_en
				internal_ram_write_adrs		 		<= internal_address_max;
				internal_write_busy(buf)			<= '0';
				internal_event_busy					<= '1';
				internal_buffer_full(buf) 			<= '1';  --//buffer full!
				save_event_state						<= buffer_sel_st; --//back to buffer sel state
					
			when others=>
				save_event_state <= buffer_sel_st;
				
		end case;
	end if;
end process;


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
		internal_ram_read_clk_reg(3 downto 1) <= internal_ram_read_clk_reg(2 downto 0);
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
				internal_ram_read_en <= reg_i(base_adrs_rdout_cntrl+1)(7 downto 0);
			when "00000010" =>
				read_ch <= 1;
				internal_ram_read_en <= reg_i(base_adrs_rdout_cntrl+1)(7 downto 0);
			when "00000100" =>
				read_ch <= 2;
				internal_ram_read_en <= reg_i(base_adrs_rdout_cntrl+1)(7 downto 0);
			when "00001000" => 
				read_ch <= 3;
				internal_ram_read_en <= reg_i(base_adrs_rdout_cntrl+1)(7 downto 0);
			when "00010000" =>
				read_ch <= 4;
				internal_ram_read_en <= reg_i(base_adrs_rdout_cntrl+1)(7 downto 0);
			when "00100000" => 
				read_ch <= 5;
				internal_ram_read_en <= reg_i(base_adrs_rdout_cntrl+1)(7 downto 0);
			when "01000000" => 
				read_ch <= 6;
				internal_ram_read_en <= reg_i(base_adrs_rdout_cntrl+1)(7 downto 0);
			when "10000000" => 
				read_ch <= 7;
				internal_ram_read_en <= reg_i(base_adrs_rdout_cntrl+1)(7 downto 0);
			when others=>
				read_ch <= 0;
				internal_ram_read_en <= (others=>'0');
		end case;
	end if;
end process;

--//interpret register to assign data buffer to readout
proc_select_wfm_ram : process(reg_i(78), read_ch, internal_wfm_ram_0, internal_wfm_ram_1, internal_wfm_ram_2, internal_wfm_ram_3, internal_ram_read_clk_reg)
begin
	----------------------------------------------
	--//read clk was pulsed at internal_ram_read_clk_reg(2),
	--//so data should be valid at the next clock cycle
	----------------------------------------------
	if rising_edge(clk_iface_i) and internal_ram_read_clk_reg(3) = '1' then 
		case reg_i(78)(1 downto 0) is
			--//NOTE: byte reordering in each 'chunk' to make software-world easier
			-----------------------------
			--//1st buffer:
			when "00" =>
				data_ram_at_current_adr_o(0) <= internal_wfm_ram_0(read_ch)(word_size-1+0*d_width downto 0*d_width) &  
												internal_wfm_ram_0(read_ch)(2*word_size-1+0*d_width downto 0*d_width+word_size) &
												internal_wfm_ram_0(read_ch)(3*word_size-1+0*d_width downto 0*d_width+word_size*2) &
												internal_wfm_ram_0(read_ch)(4*word_size-1+0*d_width downto 0*d_width+word_size*3);   --//1st chunk
				data_ram_at_current_adr_o(1) <= internal_wfm_ram_0(read_ch)(word_size-1+1*d_width downto 1*d_width) &  
												internal_wfm_ram_0(read_ch)(2*word_size-1+1*d_width downto 1*d_width+word_size) &
												internal_wfm_ram_0(read_ch)(3*word_size-1+1*d_width downto 1*d_width+word_size*2) &
												internal_wfm_ram_0(read_ch)(4*word_size-1+1*d_width downto 1*d_width+word_size*3);   --//2nd chunk  							
				data_ram_at_current_adr_o(2) <= internal_wfm_ram_0(read_ch)(word_size-1+2*d_width downto 2*d_width) &  
												internal_wfm_ram_0(read_ch)(2*word_size-1+2*d_width downto 2*d_width+word_size) &
												internal_wfm_ram_0(read_ch)(3*word_size-1+2*d_width downto 2*d_width+word_size*2) &
												internal_wfm_ram_0(read_ch)(4*word_size-1+2*d_width downto 2*d_width+word_size*3);   --//3rd chunk    							
				data_ram_at_current_adr_o(3) <= internal_wfm_ram_0(read_ch)(word_size-1+3*d_width downto 3*d_width) &  
												internal_wfm_ram_0(read_ch)(2*word_size-1+3*d_width downto 3*d_width+word_size) &
												internal_wfm_ram_0(read_ch)(3*word_size-1+3*d_width downto 3*d_width+word_size*2) &
												internal_wfm_ram_0(read_ch)(4*word_size-1+3*d_width downto 3*d_width+word_size*3);   --//4th chunk   
			--//2nd buffer:
			when "01" =>
				data_ram_at_current_adr_o(0) <= internal_wfm_ram_1(read_ch)(word_size-1+0*d_width downto 0*d_width) &  
												internal_wfm_ram_1(read_ch)(2*word_size-1+0*d_width downto 0*d_width+word_size) &
												internal_wfm_ram_1(read_ch)(3*word_size-1+0*d_width downto 0*d_width+word_size*2) &
												internal_wfm_ram_1(read_ch)(4*word_size-1+0*d_width downto 0*d_width+word_size*3);   --//1st chunk
				data_ram_at_current_adr_o(1) <= internal_wfm_ram_1(read_ch)(word_size-1+1*d_width downto 1*d_width) &  
												internal_wfm_ram_1(read_ch)(2*word_size-1+1*d_width downto 1*d_width+word_size) &
												internal_wfm_ram_1(read_ch)(3*word_size-1+1*d_width downto 1*d_width+word_size*2) &
												internal_wfm_ram_1(read_ch)(4*word_size-1+1*d_width downto 1*d_width+word_size*3);   --//2nd chunk  							
				data_ram_at_current_adr_o(2) <= internal_wfm_ram_1(read_ch)(word_size-1+2*d_width downto 2*d_width) &  
												internal_wfm_ram_1(read_ch)(2*word_size-1+2*d_width downto 2*d_width+word_size) &
												internal_wfm_ram_1(read_ch)(3*word_size-1+2*d_width downto 2*d_width+word_size*2) &
												internal_wfm_ram_1(read_ch)(4*word_size-1+2*d_width downto 2*d_width+word_size*3);   --//3rd chunk    							
				data_ram_at_current_adr_o(3) <= internal_wfm_ram_1(read_ch)(word_size-1+3*d_width downto 3*d_width) &  
												internal_wfm_ram_1(read_ch)(2*word_size-1+3*d_width downto 3*d_width+word_size) &
												internal_wfm_ram_1(read_ch)(3*word_size-1+3*d_width downto 3*d_width+word_size*2) &
												internal_wfm_ram_1(read_ch)(4*word_size-1+3*d_width downto 3*d_width+word_size*3);   --//4th chunk  
			--//3rd buffer:
			when "10" =>
				data_ram_at_current_adr_o(0) <= internal_wfm_ram_2(read_ch)(word_size-1+0*d_width downto 0*d_width) &  
												internal_wfm_ram_2(read_ch)(2*word_size-1+0*d_width downto 0*d_width+word_size) &
												internal_wfm_ram_2(read_ch)(3*word_size-1+0*d_width downto 0*d_width+word_size*2) &
												internal_wfm_ram_2(read_ch)(4*word_size-1+0*d_width downto 0*d_width+word_size*3);   --//1st chunk
				data_ram_at_current_adr_o(1) <= internal_wfm_ram_2(read_ch)(word_size-1+1*d_width downto 1*d_width) &  
												internal_wfm_ram_2(read_ch)(2*word_size-1+1*d_width downto 1*d_width+word_size) &
												internal_wfm_ram_2(read_ch)(3*word_size-1+1*d_width downto 1*d_width+word_size*2) &
												internal_wfm_ram_2(read_ch)(4*word_size-1+1*d_width downto 1*d_width+word_size*3);   --//2nd chunk  							
				data_ram_at_current_adr_o(2) <= internal_wfm_ram_2(read_ch)(word_size-1+2*d_width downto 2*d_width) &  
												internal_wfm_ram_2(read_ch)(2*word_size-1+2*d_width downto 2*d_width+word_size) &
												internal_wfm_ram_2(read_ch)(3*word_size-1+2*d_width downto 2*d_width+word_size*2) &
												internal_wfm_ram_2(read_ch)(4*word_size-1+2*d_width downto 2*d_width+word_size*3);   --//3rd chunk    							
				data_ram_at_current_adr_o(3) <= internal_wfm_ram_2(read_ch)(word_size-1+3*d_width downto 3*d_width) &  
												internal_wfm_ram_2(read_ch)(2*word_size-1+3*d_width downto 3*d_width+word_size) &
												internal_wfm_ram_2(read_ch)(3*word_size-1+3*d_width downto 3*d_width+word_size*2) &
												internal_wfm_ram_2(read_ch)(4*word_size-1+3*d_width downto 3*d_width+word_size*3);   --//4th chunk 
			--//4th buffer:
			when "11" =>
				data_ram_at_current_adr_o(0) <= internal_wfm_ram_3(read_ch)(word_size-1+0*d_width downto 0*d_width) &  
												internal_wfm_ram_3(read_ch)(2*word_size-1+0*d_width downto 0*d_width+word_size) &
												internal_wfm_ram_3(read_ch)(3*word_size-1+0*d_width downto 0*d_width+word_size*2) &
												internal_wfm_ram_3(read_ch)(4*word_size-1+0*d_width downto 0*d_width+word_size*3);   --//1st chunk
				data_ram_at_current_adr_o(1) <= internal_wfm_ram_3(read_ch)(word_size-1+1*d_width downto 1*d_width) &  
												internal_wfm_ram_3(read_ch)(2*word_size-1+1*d_width downto 1*d_width+word_size) &
												internal_wfm_ram_3(read_ch)(3*word_size-1+1*d_width downto 1*d_width+word_size*2) &
												internal_wfm_ram_3(read_ch)(4*word_size-1+1*d_width downto 1*d_width+word_size*3);   --//2nd chunk  							
				data_ram_at_current_adr_o(2) <= internal_wfm_ram_3(read_ch)(word_size-1+2*d_width downto 2*d_width) &  
												internal_wfm_ram_3(read_ch)(2*word_size-1+2*d_width downto 2*d_width+word_size) &
												internal_wfm_ram_3(read_ch)(3*word_size-1+2*d_width downto 2*d_width+word_size*2) &
												internal_wfm_ram_3(read_ch)(4*word_size-1+2*d_width downto 2*d_width+word_size*3);   --//3rd chunk    							
				data_ram_at_current_adr_o(3) <= internal_wfm_ram_3(read_ch)(word_size-1+3*d_width downto 3*d_width) &  
												internal_wfm_ram_3(read_ch)(2*word_size-1+3*d_width downto 3*d_width+word_size) &
												internal_wfm_ram_3(read_ch)(3*word_size-1+3*d_width downto 3*d_width+word_size*2) &
												internal_wfm_ram_3(read_ch)(4*word_size-1+3*d_width downto 3*d_width+word_size*3);   --//4th chunk  	
		
			when others=>
				for j in 0 to 3 loop
					data_ram_at_current_adr_o(j) <= (others=>'0');
				end loop;
		end case;
	end if;
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
	get_metadata_i	 	=> internal_event_busy, 
	current_buffer_i	=> internal_current_buffer,
	reg_i				 	=> reg_i,		
	event_header_o	 	=> event_meta_o);

--///////////////////
--//FPGA RAM blocks defined here:
--///////////////////
--//Multiple buffers for waveform data only [unwieldly to include multi-buffering for beams+powsum, as those are mostly for debugging purposes]
DataRamBlock_0 : for i in 0 to 7 generate
	xDataRAM 	:	entity work.DataRAM
	port map(
		data			=> internal_wfm_data(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> internal_ram_read_adr,
		rdclock		=> internal_ram_read_clk_reg(2),
		rden			=> internal_ram_read_en(i),
		wraddress	=> internal_ram_write_adrs, 
		wrclock		=> clk_i,
		wren			=>	internal_wfm_ram_write_en(0),
		q				=>	internal_wfm_ram_0(i));
end generate DataRamBlock_0;
DataRamBlock_1 : for i in 0 to 7 generate
	xDataRAM 	:	entity work.DataRAM
	port map(
		data			=> internal_wfm_data(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> internal_ram_read_adr,
		rdclock		=> internal_ram_read_clk_reg(2),
		rden			=> internal_ram_read_en(i),
		wraddress	=> internal_ram_write_adrs, 
		wrclock		=> clk_i,
		wren			=>	internal_wfm_ram_write_en(1),
		q				=>	internal_wfm_ram_1(i));
end generate DataRamBlock_1;
DataRamBlock_2 : for i in 0 to 7 generate
	xDataRAM 	:	entity work.DataRAM
	port map(
		data			=> internal_wfm_data(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> internal_ram_read_adr,
		rdclock		=> internal_ram_read_clk_reg(2),
		rden			=> internal_ram_read_en(i),
		wraddress	=> internal_ram_write_adrs, 
		wrclock		=> clk_i,
		wren			=>	internal_wfm_ram_write_en(2),
		q				=>	internal_wfm_ram_2(i));
end generate DataRamBlock_2;
DataRamBlock_3 : for i in 0 to 7 generate
	xDataRAM 	:	entity work.DataRAM
	port map(
		data			=> internal_wfm_data(i), 
		rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
		rdaddress	=> internal_ram_read_adr,
		rdclock		=> internal_ram_read_clk_reg(2),
		rden			=> internal_ram_read_en(i),
		wraddress	=> internal_ram_write_adrs, 
		wrclock		=> clk_i,
		wren			=>	internal_wfm_ram_write_en(3),
		q				=>	internal_wfm_ram_3(i));
end generate DataRamBlock_3;

--//end RAM blocks for waveform data

--////////////////////////////////////////////////////////////////////////////
end rtl;