---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         RxData.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         2/2016
--
-- DESCRIPTION:  Receiver block for ADC data-stream
--               Handle high-speed LVDS data and write to FPGA RAM
---------------------------------------------------------------------------------

library IEEE; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.defs.all;

entity RxData_NoDeSer is
 	Port(
			clk_i					:	in		std_logic;  --//core clock
			rst_i					:	in		std_logic;
			rx_dat_valid_i		:  in		std_logic;   --//flag from ADC program block
			trigger_i			:  in		std_logic;   --//trigger input for this ADC
			trigger_dly_i		:  in		std_logic_vector(define_ram_depth-1 downto 0); --//trig delay count		
			
			adc_dclk_i			:	in		std_logic;		
			adc_data_i			:  in		std_logic_vector(27 downto 0);
			adc_ovrange_i		:  in		std_logic;
			ram_read_Clk_i		:  in		std_logic;
			ram_read_Adrs_i	:	in		std_logic_vector(define_ram_depth-1 downto 0);
			ram_read_en_ch0_i	:	in		std_logic;
			ram_read_en_ch1_i	:	in		std_logic;
			ram_wr_adr_rst_i	: 	in		std_logic;
			
			rx_serdes_clk_o	:	out	std_logic;
			rx_locked_o			:	out	std_logic;
			ram_write_adrs_o	:	out	std_logic_vector(define_ram_depth-1 downto 0);
			data_ram_ch0_o		:	out	std_logic_vector(define_ram_width-1 downto 0);
			data_ram_ch1_o		:	out	std_logic_vector(define_ram_width-1 downto 0));

	end RxData_NoDeSer;
			
architecture rtl of RxData_NoDeSer is

	type   write_ram_type is (WRITING, HOLD, DONE);
	signal rx_write_ram_state	:	write_ram_type;
	signal trig_ram_state		:	write_ram_type;
	
	signal data				: 	std_logic_vector(define_deser_data_width-1 downto 0);
	signal data_p		 	: 	std_logic_vector(define_deser_data_width-1 downto 0);--//pipeline, for clk transfer
	
	type two_channel_data_type is array (1 downto 0) of std_logic_vector(define_ram_width-1 downto 0);
	signal data_two_chan		: 	two_channel_data_type;
	signal data_two_chan_p	:	two_channel_data_type;
	
	signal rx_out_clk		: 	std_logic;
	signal data_ram		: 	std_logic_vector(define_ram_width-1 downto 0);
	
	signal ram_write_adrs_rising_edge	:	std_logic_vector(define_ram_depth-1 downto 0);
	signal ram_write_adrs_falling_edge	:	std_logic_vector(define_ram_depth-1 downto 0);
	signal ram_write_en	:	std_logic; 
	
	type internal_ram_data_type is array (1 downto 0 ) of std_logic_vector(define_ram_width-1 downto 0);
	signal internal_ram_data : internal_ram_data_type;
	signal internal_ram_rd_en	: std_logic_vector(1 downto 0);
	signal internal_rx_dat_valid : std_logic_vector(5 downto 0); --//for clk transfer
	
	signal trigger_count	:	std_logic_vector(define_ram_depth-1 downto 0);
	signal trig_flag		:	std_logic;
	signal internal_trigger : std_logic_vector(2 downto 0); --//for clk transfer
	----//the following for DPA in SerDes block:
	--signal xRxFifoReset	: adc_data_type;
	--signal xRxReset		: adc_data_type;
	--signal xRxDPAlock		: adc_data_type;
	
begin

	ram_write_adrs_o 	<= ram_write_adrs_falling_edge;           --//current write address pointer
	
	data_ram_ch0_o <= internal_ram_data(0);
	data_ram_ch1_o <= internal_ram_data(1);
	internal_ram_rd_en(0) <= ram_read_en_ch0_i;
	internal_ram_rd_en(1) <= ram_read_en_ch1_i;
	rx_serdes_clk_o <= rx_out_clk;
	----//receiver block for a single 7-bit ADC SDR
	----//no DPA 
	----//when ADC program OUTEDGE is 0 := 90 degree between rx_in and rx_inclock
--	xRxLVDS	:	entity work.RxLVDS(syn)
--		port map(
--			pll_areset	=> rst_i or not rx_dat_valid_i,
--			rx_in			=> adc_data_i,							
--			rx_inclock	=> adc_dclk_i,
--			rx_locked	=> rx_locked_o,
--			rx_out		=> data,
--			rx_outclock	=> rx_out_clk);

	data <= x"000000000000000000000000" & x"000000000000000000000000" & "0000" & adc_data_i;
	rx_out_clk <= adc_dclk_i;
	rx_locked_o <= '0';
		
	-- //altera megafunction RAM (`RAM 2-PORT')
	TwoChanRamBlock : for i in 0 to 1 generate
		xRxRAM 	:	entity work.RxRAM(syn)
		port map(
			data			=>	data_two_chan_p(i),--//pipelined data, split into 2 channels
			rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
			rdaddress	=> ram_read_Adrs_i,
			rdclock		=> ram_read_Clk_i,
			rden			=> internal_ram_rd_en(i),
			wraddress	=> ram_write_adrs_rising_edge, --ram_write_adrs_falling_edge,
			wrclock		=> rx_out_clk,
			wren			=>	ram_write_en,
			q				=>	internal_ram_data(i));
	end generate TwoChanRamBlock;
		
	--// re-organize data and pipeline	
	proc_pipeline_data : process(rx_out_clk, rst_i, rx_dat_valid_i)
	begin
		if rst_i = '1' or rx_dat_valid_i = '0' then
			data_p	 		<= (others => '0');
			for i in 0 to 1 loop
				data_two_chan(i) 		<= (others => '0');
				data_two_chan_p(i) 	<= (others => '0');

			end loop;
			
			internal_rx_dat_valid <= (others =>'0');
			internal_trigger 	<= (others=>'0');
		
		elsif falling_edge(rx_out_clk) then
			data_two_chan_p <= data_two_chan;

			data_two_chan(0)(7 downto 0)  <= '0' & data_p(6 downto 0);
			data_two_chan(0)(15 downto 8)  <= '0' & data_p(13 downto 7);
			data_two_chan(1)(7 downto 0)  <= '0' & data_p(20 downto 14);
			data_two_chan(1)(15 downto 8)  <= '0' & data_p(27 downto 21);

			data_p 				<= data;

			--//second reorgz step
--			for i in 0 to 1 loop
--				data_two_chan_p(i)(7 downto 0) 		<= data_two_chan(i)(71 downto 64); --data_two_chan(i)(7 downto 0);
--				data_two_chan_p(i)(15 downto 8) 		<= data_two_chan(i)(7 downto 0); --data_two_chan(i)(71 downto 64);
--				data_two_chan_p(i)(23 downto 16)		<= data_two_chan(i)(79 downto 72); --data_two_chan(i)(15 downto 8);
--				data_two_chan_p(i)(31 downto 24)		<= data_two_chan(i)(15 downto 8); --data_two_chan(i)(79 downto 72);
--				data_two_chan_p(i)(39 downto 32)		<= data_two_chan(i)(87 downto 80); --data_two_chan(i)(23 downto 16);
--				data_two_chan_p(i)(47 downto 40)		<= data_two_chan(i)(23 downto 16); --data_two_chan(i)(87 downto 80);
--				data_two_chan_p(i)(55 downto 48)		<= data_two_chan(i)(95 downto 88); --data_two_chan(i)(31 downto 24);
--				data_two_chan_p(i)(63 downto 56)		<= data_two_chan(i)(31 downto 24); --data_two_chan(i)(95 downto 88);
--				data_two_chan_p(i)(71 downto 64)		<= data_two_chan(i)(103 downto 96); --data_two_chan(i)(39 downto 32);
--				data_two_chan_p(i)(79 downto 72)		<= data_two_chan(i)(39 downto 32); --data_two_chan(i)(103 downto 96);
--				data_two_chan_p(i)(87 downto 80)		<= data_two_chan(i)(111 downto 104); --data_two_chan(i)(47 downto 40);
--				data_two_chan_p(i)(95 downto 88)		<= data_two_chan(i)(47 downto 40); --data_two_chan(i)(111 downto 104);
--				data_two_chan_p(i)(103 downto 96)	<= data_two_chan(i)(119 downto 112); --data_two_chan(i)(55 downto 48);
--				data_two_chan_p(i)(111 downto 104)	<= data_two_chan(i)(55 downto 48); --data_two_chan(i)(119 downto 112);
--				data_two_chan_p(i)(119 downto 112)	<= data_two_chan(i)(127 downto 120); --data_two_chan(i)(63 downto 56);
--				data_two_chan_p(i)(127 downto 120)	<= data_two_chan(i)(63 downto 56); --data_two_chan(i)(127 downto 120);	
--			end loop;

			--//uncomment to test ram read/write
--			for i in 0 to 1 loop
--				data_two_chan_p(i)(7 downto 0) 		<= x"00";
--				data_two_chan_p(i)(15 downto 8) 		<= x"01";
--				data_two_chan_p(i)(23 downto 16)		<= x"02";
--				data_two_chan_p(i)(31 downto 24)		<= x"03";
--				data_two_chan_p(i)(39 downto 32)		<= x"04";
--				data_two_chan_p(i)(47 downto 40)		<= x"05";
--				data_two_chan_p(i)(55 downto 48)		<= x"06";
--				data_two_chan_p(i)(63 downto 56)		<= x"07";
--				data_two_chan_p(i)(71 downto 64)		<= x"08";
--				data_two_chan_p(i)(79 downto 72)		<= x"09";
--				data_two_chan_p(i)(87 downto 80)		<= x"0A";
--				data_two_chan_p(i)(95 downto 88)		<= x"0B";
--				data_two_chan_p(i)(103 downto 96)	<= x"0C";
--				data_two_chan_p(i)(111 downto 104)	<= x"0D";
--				data_two_chan_p(i)(119 downto 112)	<= x"0E";
--				data_two_chan_p(i)(127 downto 120)	<= x"0F";	
--			end loop;
			
			internal_rx_dat_valid <= internal_rx_dat_valid(internal_rx_dat_valid'length-2 downto 0) & rx_dat_valid_i;
			internal_trigger <= internal_trigger(internal_trigger'length-2 downto 0) & trigger_i;

		end if;
	end process;
	
	--// write ADC data to fpga ram
	proc_write_data : process(rx_out_clk, rst_i, internal_rx_dat_valid, trig_flag)
	begin	
		if rst_i = '1' or rx_dat_valid_i = '0' or ram_wr_adr_rst_i = '1' then
			ram_write_adrs_falling_edge 	<= (others => '0');
			ram_write_adrs_rising_edge 	<= (others => '0');
			ram_write_en				<= '0';
			rx_write_ram_state		<= WRITING;
					
			elsif rising_edge(rx_out_clk) and internal_rx_dat_valid(internal_rx_dat_valid'length-1) = '1' then
				case rx_write_ram_state is
				
					when WRITING =>
						ram_write_en	<= '1';
						ram_write_adrs_rising_edge <= ram_write_adrs_rising_edge + 1;
						
						if trig_flag = '1' then
							rx_write_ram_state	<= HOLD;
						else
							rx_write_ram_state	<= WRITING;
						end if;
							
					when HOLD =>
						ram_write_en <= '0';
						rx_write_ram_state	<= DONE;
						
					when DONE =>
						ram_write_en <= '0';
						
						if trig_flag = '0' then
							ram_write_adrs_rising_edge <= (others => '0');
							rx_write_ram_state 	<= WRITING;
						else
							ram_write_adrs_rising_edge <= ram_write_adrs_rising_edge;
							rx_write_ram_state	<= DONE;
						end if;
				end case;

						
			elsif falling_edge(rx_out_clk) and internal_rx_dat_valid(internal_rx_dat_valid'length-1) = '1' then		
				ram_write_adrs_falling_edge <= ram_write_adrs_rising_edge;
			end if;
	end process;
			
			
	proc_trigger : process(rx_out_clk, rst_i, rx_dat_valid_i, internal_rx_dat_valid, 
									internal_trigger, trigger_dly_i, trigger_i)
		variable hold_trig_length 	: integer range 0 to 1000000 := 0;
		variable max_trig_length 	: integer := 500000;
		begin
			if rst_i = '1' or rx_dat_valid_i = '0'  or trigger_i = '0' then
				trigger_count		<= (others=>'0');
				trig_flag			<= '0';
				hold_trig_length 	:= 0;
				trig_ram_state		<=	WRITING;
			
			elsif falling_edge(rx_out_clk) and internal_rx_dat_valid(internal_rx_dat_valid'length-1) = '1' then
				
				case trig_ram_state is 
					
					when WRITING =>
						trigger_count	<= (others=>'0');
						trig_flag		<= '0';
						
						if internal_trigger(internal_trigger'length-1) = '1' then
							trig_ram_state		<=	HOLD;
						else
							trig_ram_state		<=	WRITING;
						end if;
					
					when HOLD =>
						if trigger_count > trigger_dly_i then
							trig_flag 			<= '1';
							trig_ram_state		<=	DONE;
						else
							trig_flag		<= '0';
							trigger_count <= trigger_count + 1;
							trig_ram_state		<=	HOLD;
						end if;
						
					when DONE=>
						trigger_count <= (others=>'0');
						
					when others=>
						trig_ram_state <= WRITING;
				end case;
			end if;
		end process;

end rtl;