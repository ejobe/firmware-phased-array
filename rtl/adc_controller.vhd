---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         adc_controller.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         10/2016, and onwards...
--
-- DESCRIPTION:  control bits for TI 7-bit ADC
--               also handle + combine ADC data: 
--                  put the ADc data on the core_clk, apply delays to line up timestreams
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

entity adc_controller is
	Port(
		clk_i				:	in		std_logic; --// slow clock
		clk_core_i		:	in		std_logic;
		clk_fast_i		:	in		std_logic; --// fast clock for syncing ADC data outputs
		rst_i				:	in		std_logic; --// reset
		pwr_up_i 		:	in		std_logic; --// pwr-up signal (pwr up when=1). ADC's should be started after the PLL
		rx_locked_i		:	in		std_logic;

		--//ADC control pins
		pd_o					: 	out	std_logic_vector(3 downto 0); --//power-down (active high)
		sdat_oedge_ddr_o	:	out	std_logic_vector(3 downto 0);	--//sdata OR manage ddr settings
		caldly_scs_o		:	out	std_logic_vector(3 downto 0);	--//calibration setup delay OR serial cs
		drst_sel_o			:	out	std_logic; --//drst select single-ende or differential
		pd_q_o				:	out	std_logic; --//power-down q-channel only, board-common
		sclk_outv_o			:	out	std_logic; --//serial clk OR lvds data output voltage
		ece_o					: 	out	std_logic; --//extended-control enable, board-common
		cal_o					:	out	std_logic; --//toggle calibration cycle, board-common
		dclk_rst_lvds_o	:	out	std_logic_vector(3 downto 0); --//lvds dclk rst to sync data stream from ADCs
		
		--//sw controls
		reg_addr_i			:  in 	std_logic_vector(define_address_size-1 downto 0);
		reg_i					: 	in		register_array_type; --//phased_array programmable registers

		--//write to data ram:
		rx_adc_data_i		:  in  full_data_type;
		rx_ram_rd_adr_o	:	inout std_logic_vector(define_ram_depth-1 downto 0);
		rx_ram_rd_en_o    :	out std_logic;
	
		--//timestream data to beamform module
		timestream_data_o		:	out full_data_type;
		
		dat_valid_o				:	inout	std_logic);
		
end adc_controller;		
		
architecture rtl of adc_controller is
type adc_startup_state_type is (pwr_st, cal_st, rdy_st, done_st);
signal adc_startup_state : adc_startup_state_type := pwr_st;

signal user_dclk_rst	: std_logic;
signal internal_dclk_rst : std_logic;
signal internal_data_valid : std_logic;

signal internal_rx_dat_valid : std_logic_vector(2 downto 0); --//for clk transfer

--//signals for adding relative delays between ADCs in order to align data
signal delay_en   	: std_logic_vector(7 downto 0);
signal delay_chan 	: rx_data_delay_type;
signal data_pipe   	: buffered_data_type;
signal data_pipe_2 	: full_data_type;
signal channel_mask	: full_data_type;

--////////////////////////////////////

begin
pd_o <= (not pwr_up_i or reg_i(base_adrs_adc_cntrl+6)(3)) &     --//ADC3
		  (not pwr_up_i or reg_i(base_adrs_adc_cntrl+6)(2)) &     --//ADC2
		  (not pwr_up_i or reg_i(base_adrs_adc_cntrl+6)(1)) &     --//ADC1
		  (not pwr_up_i or reg_i(base_adrs_adc_cntrl+6)(0));      --//ADC0

--pd_o <= not pwr_up_i & not pwr_up_i & not pwr_up_i & not pwr_up_i;
		  
--/////////////////////////////////////////////////////////////
--//set static values when *not* using extended-control mode:
--/////////////////////////////////////////////////////////////
ece_o <= '1'; --'1';  --//for now, disable extended control mode
pd_q_o <= '0'; --//won't turn off q channel independently, so keep this low
--cal_o <= '0';  --//if uncommented, only calibrate upon power-up
drst_sel_o <= '0'; --//use drst in differential mode
sclk_outv_o	<= '0'; --//when ece is disabled, '1'=normal LVDS voltage; '0'=reduced (might try this for lower power)
sdat_oedge_ddr_o <= "1111"; --//when ece is disabled, '0'= outedge is SDR + 90 degrees from data edge (not DDR!)
caldly_scs_o <= "0000"; --//when ece is disabled, set caldly to 0

--////////////////////////////////////////////////////////////////
--//---------------------------------------------------------------
--//when caldly = 0, corresponds to 2^26 clock cycles
--//when caldly = 1, corresponds  to 2^32 clock cycles
--//cal pin assert/de-assert: allot ~3000 clock cycles (1280 + 1280 + extra)
--//
--//let's just wait for 1 whole second before setting dat_valid_o
proc_startup_cycle : process(rst_i, pwr_up_i, clk_i, user_dclk_rst)
variable i : integer range 0 to 10000001 := 0;
begin
	if rst_i='1' or pwr_up_i='0' then
		i:= 0;
		--dat_valid_o <= '0';
		internal_data_valid <= '0';
		cal_o <= '0';
		internal_dclk_rst <= '0';
		adc_startup_state <= pwr_st;
	
	elsif rising_edge(clk_i) and pwr_up_i = '1' then
		case adc_startup_state is
			when pwr_st => 
				if i >= 8000000 then	--//wait 8 seconds
					i := 0;
					adc_startup_state <= cal_st; --//skip spi write state
				else 
					i:= i + 1;
				end if;
				
			when cal_st =>
				if i >= 1200 then	--//cal pulse >1280 clock cycles in length
					i := 0;
					cal_o <= '0';  --// set cal pin low again
					adc_startup_state <= rdy_st;
				elsif i >= 1000 then
					cal_o <= '1'; --//set cal pin high
					i := i + 1;
				else
					cal_o <= '0'; --// set cal pin low
					i := i + 1;
				end if;
				
			when rdy_st => 
				internal_data_valid <= '0';
				cal_o <= '0';
				if i >= 3000000 then  --//cal cycle takes 1.4e6 clock cycles
					i := 0;
					adc_startup_state <= done_st;
				elsif i >= 2999999 then
					internal_dclk_rst <= '1'; --//to sync up data clocks, toggle the process below
					i := i + 1;
				else 
					internal_dclk_rst <= '0';
					i := i + 1;
				end if;
			
			when done_st =>
				internal_data_valid <= '1';
				i := 0;
				--dat_valid_o <= '1';
				--//pulse for dclk_rst again
				if user_dclk_rst = '1' then 
					i := 0;
					adc_startup_state <= rdy_st;
				end if;			
			 
		end case;
	end if;
end process;
--//
proc_user_dclk_rst : process(rst_i, reg_addr_i, adc_startup_state)
begin
	if rst_i = '1'  or adc_startup_state = rdy_st then
		user_dclk_rst <= '0';
	elsif reg_addr_i = std_logic_vector(to_unsigned(base_adrs_adc_cntrl+1, define_address_size)) then
		user_dclk_rst <= '1';
	end if;
end process;


--////////////////////////////////////////////////////////////////////////////////
--//this is a one-shot process. rst_i or pwr_up_i need to be asserted to re-start
--////////////////////////////////////////////////////////////////////////////////
--//NOTE + REMINDER: dclk_rst_lvds_o is active LOW due to schematic error switching lvds pairs
--////////////////////////////////////////////////////////////////////////////////
proc_dclk_rst : process(rst_i, clk_fast_i, internal_dclk_rst, internal_data_valid, rx_locked_i)
variable i : integer range 1000 downto 0 := 0;
begin
	if rst_i = '1' or pwr_up_i='0' then
		i := 0;
		dat_valid_o <='0';
		dclk_rst_lvds_o <= "1111"; --//dclk should not be asserted when CAL is running (blocks cal cycle)
	elsif rising_edge(clk_fast_i) and internal_dclk_rst = '1' and internal_data_valid = '1' then

		--dat_valid_o <= '1';
		if i >= 100 then
			dclk_rst_lvds_o <= "1111"; --//de-assert pulse
			
			if rx_locked_i = '1' then  --//then wait for data clocks to reappear and lock the serdes receiver
				dat_valid_o <= '1';     --// send 'data valid' flag to RxData FPGA blocks
			end if;
			--i := i + 1;
		else
			dat_valid_o <= '0';
			dclk_rst_lvds_o <= "0000";
			i := i + 1;
		end if;
	elsif rising_edge(clk_fast_i) and internal_dclk_rst = '1' and internal_data_valid = '0' then	
		i := 0;		
		dat_valid_o <='0';
		dclk_rst_lvds_o <= "0000";  --//send pulse (active low) This CLEARS the DCLK lines while active.
	end if;
end process;


proc_read_adr : process(rst_i, clk_core_i, internal_data_valid)
begin
	if rst_i = '1' or internal_data_valid = '0' then	
	
		--//define initial rx ram read address as mid-scale
		rx_ram_rd_adr_o(rx_ram_rd_adr_o'length-1) <= '1';
		rx_ram_rd_adr_o(rx_ram_rd_adr_o'length-2 downto 0) <=  (others=>'0');
		internal_rx_dat_valid <= (others=>'0'); 
		rx_ram_rd_en_o <= '0';
		
		for j in 0 to 7 loop
			delay_en(j) 	<= '0';
			delay_chan(j)  <= (others=>'0');
			channel_mask(j)<= (others=>'0'); --(others=> not reg_i(48)(j));
		end loop;
		
	elsif rising_edge(clk_core_i) then
		
		--//register the delay enable and value here:
		for j in 0 to 3 loop
			delay_en(2*j)   	<= reg_i(base_adrs_adc_cntrl+2+j)(4);
			delay_en(2*j+1)   <= reg_i(base_adrs_adc_cntrl+2+j)(9);

			delay_chan(2*j) 	<= reg_i(base_adrs_adc_cntrl+2+j)(3 downto 0); 
			delay_chan(2*j+1) <= reg_i(base_adrs_adc_cntrl+2+j)(8 downto 5);
		end loop;
		--////////////////
		
		for j in 0 to 7 loop
			channel_mask(j)<= (others=> not reg_i(48)(j));
		end loop;
		
		internal_rx_dat_valid <= internal_rx_dat_valid(internal_rx_dat_valid'length-2 downto 0) & dat_valid_o;
		
		if internal_rx_dat_valid(internal_rx_dat_valid'length-1) = '1' then
			rx_ram_rd_en_o <= '1';
			rx_ram_rd_adr_o <= rx_ram_rd_adr_o + 1;
		end if;
	end if;
end process;

--////////////////////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////////////////////

--//apply relative delays to data_pipe_2 
proc_align_samples : process(rst_i, clk_core_i, delay_en)
begin
	for i in 0 to 7 loop
		
		if rst_i = '1' then
			data_pipe(i) <= (others=>'0');
			data_pipe_2(i) <= (others=>'0');
			timestream_data_o(i) <= (others=>'0');
		elsif rising_edge(clk_core_i) then
			
			timestream_data_o(i) <= data_pipe_2(i);
			
			case delay_en(i) is
				when '1' =>
				--////////////////////////////////////////////////////////
				--// add in sample-level delays here
				--////////////////////////////////////////////////////////			
				case delay_chan(i) is
					when "0000" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1+15*define_word_size downto 15*define_word_size);
					when "0001" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1+14*define_word_size downto 14*define_word_size);
					when "0010" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1+13*define_word_size downto 13*define_word_size);				
					when "0011" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1+12*define_word_size downto 12*define_word_size);	
					when "0100" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1+11*define_word_size downto 11*define_word_size);
					when "0101" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1+10*define_word_size downto 10*define_word_size);	
					when "0110" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1+9*define_word_size downto 9*define_word_size);
					when "0111" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1+8*define_word_size downto 8*define_word_size);
					when "1000" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1+7*define_word_size downto 7*define_word_size);
					when "1001" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1+6*define_word_size downto 6*define_word_size);
					when "1010" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1+5*define_word_size downto 5*define_word_size);
					when "1011" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1+4*define_word_size downto 4*define_word_size);
					when "1100" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1+3*define_word_size downto 3*define_word_size);
					when "1101" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1+2*define_word_size downto 2*define_word_size);
					when "1110" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1+1*define_word_size downto 1*define_word_size);
					when "1111" =>
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1 downto 0); --//full delay: 2*define_serdes_factor samples
					when others=> 
						data_pipe_2(i) <= data_pipe(i)(16*define_word_size-1 downto 0); --//should never toggle 'others'
				end case;
				--////////////////////////////////////////////////////////			
				
				when '0' =>
					data_pipe_2(i) <= data_pipe(i)(16*define_word_size*2-1 downto 16*define_word_size);
			end case;
		
			--////////////////////////////////////////////////
			--//first pipeline stage
			data_pipe(i)(define_ram_width-1 downto 0) <= data_pipe(i)(2*define_ram_width-1 downto define_ram_width);
			--//apply channel-level mask here
			data_pipe(i)(2*define_ram_width-1 downto define_ram_width) <= rx_adc_data_i(i) and channel_mask(i); 
			
		end if;
	end loop;
end process;


end rtl;