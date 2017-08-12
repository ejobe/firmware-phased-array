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

entity RxData is
 	Port(
			rst_i					:	in		std_logic;
			rx_dat_valid_i		:  in		std_logic;   --//flag from ADC program block
			
			adc_dclk_i			:	in		std_logic;	--//adc data clock
			adc_data_i			:  in		std_logic_vector(27 downto 0);  --//adc serial data
			adc_ovrange_i		:  in		std_logic; --//adc overrange flag
			
			rx_fifo_read_clk_i:  in		std_logic;  --//core clock
			rx_fifo_read_req_i:	in		std_logic;
			rx_fifo_used_words0_o	:	out std_logic_vector(define_ram_depth-1 downto 0);
			rx_fifo_used_words1_o	:	out std_logic_vector(define_ram_depth-1 downto 0);

			ram_wr_adr_rst_i	: 	in		std_logic;
			
			rx_locked_o			:	out	std_logic;
			rx_ram_write_adr_o:	out	std_logic_vector(define_ram_depth-1 downto 0);  --//for debugging clock syncing issues
			data_ram_ch0_o		:	out	std_logic_vector(define_ram_width-1 downto 0);
			data_ram_ch1_o		:	out	std_logic_vector(define_ram_width-1 downto 0));

	end RxData;
			
architecture rtl of RxData is

	signal data				: 	std_logic_vector(define_deser_data_width-1 downto 0);
	signal data_p		 	: 	std_logic_vector(define_deser_data_width-1 downto 0);--//pipeline, for clk transfer
	
	type two_channel_data_type is array (1 downto 0) of std_logic_vector(define_ram_width-1 downto 0);
	signal data_two_chan		: 	two_channel_data_type;
	signal data_two_chan_p	:	two_channel_data_type;
	
	signal rx_out_clk		: 	std_logic;
	signal data_ram		: 	std_logic_vector(define_ram_width-1 downto 0);
	
	signal ram_write_adrs_rising_edge	:	std_logic_vector(define_ram_depth-1 downto 0);
	signal ram_write_en					:	std_logic; 

	type internal_ram_data_type is array (1 downto 0 ) of std_logic_vector(define_ram_width-1 downto 0);
	signal internal_ram_data : internal_ram_data_type;
	signal internal_rx_dat_valid : std_logic_vector(2 downto 0); --//for clk transfer
	
	signal internal_rx_fifo_used_words : two_chan_address_type;
	
	constant iq_split : integer := 112; --// = 28 * serdes_factor / 2 
	
	component signal_sync is
	port(
		clkA			: in	std_logic;
		clkB			: in	std_logic;
		SignalIn_clkA	: in	std_logic;
		SignalOut_clkB	: out	std_logic);
	end component;
	
	----//the following for DPA in SerDes block:
	--signal xRxFifoReset	: adc_data_type;
	--signal xRxReset		: adc_data_type;
	--signal xRxDPAlock		: adc_data_type;

begin
	data_ram_ch0_o <= internal_ram_data(0);
	data_ram_ch1_o <= internal_ram_data(1);
	rx_fifo_used_words0_o <= internal_rx_fifo_used_words(0);
	rx_fifo_used_words1_o <= internal_rx_fifo_used_words(1);
	
	----//receiver block for a single 7-bit ADC SDR
	----//no DPA 
	----//when ADC program OUTEDGE is 0 := 90 degree between rx_in and rx_inclock
	xRxLVDS	:	entity work.RxLVDS(syn)
		port map(
			--rx_channel_data_align => (others => '0'),
			pll_areset	=> rst_i,
			rx_in			=> adc_data_i,							
			rx_inclock	=> adc_dclk_i, 
			rx_locked	=> rx_locked_o,
			rx_out		=> data,
			rx_outclock	=> rx_out_clk);

	--// with DPA:
--	xRxLVDS	:	entity work.RxLVDS(syn)
--		port map(
--			pll_areset	=> rst_i,
--			rx_fifo_reset => (others=>rst_i),
--			rx_reset => (others=>rst_i),
--			rx_in			=> adc_data_i,							
--			rx_inclock	=> adc_dclk_i, 
--			rx_dpa_locked => open,
--			rx_locked	=> rx_locked_o,
--			rx_out		=> data,
--			rx_outclock	=> rx_out_clk);
			
	TwoChanFIFOBlock : for i in 0 to 1 generate
		xRXFIFO : entity work.rx_fifo(syn)
		port map(
			aclr			=> rst_i or (not internal_rx_dat_valid(1)),
			data			=> data_two_chan_p(i),
			rdclk			=> rx_fifo_read_clk_i,
			rdreq			=> rx_fifo_read_req_i,
			wrclk			=> rx_out_clk,
			wrreq			=> ram_write_en,
			q				=> internal_ram_data(i),
			rdempty		=> open,
			rdusedw		=> internal_rx_fifo_used_words(i),
			wrfull		=> open,
			wrusedw		=> open);
	end generate;
	-- //altera megafunction RAM (`RAM 2-PORT')
--	TwoChanRamBlock : for i in 0 to 1 generate
--		xRxRAM 	:	entity work.RxRAM(syn)
--		port map(
--			data			=>	data_two_chan_p(i),--//pipelined data, split into 2 channels
--			rd_aclr		=>	rst_i,  --//this clears the registered data output (not the RAM itself)
--			rdaddress	=> ram_read_Adrs_i,
--			rdclock		=> ram_read_Clk_i,
--			rden			=> internal_ram_rd_en(i),
--			wraddress	=> ram_write_adrs_rising_edge, --ram_write_adrs_falling_edge,
--			wrclock		=> rx_out_clk,
--			wren			=>	ram_write_en,
--			q				=>	internal_ram_data(i));
--	end generate TwoChanRamBlock;
	
	xDATVALIDSYNC : signal_sync
	port map(
		clkA				=> rx_fifo_read_clk_i,
		clkB				=> rx_out_clk,
		SignalIn_clkA	=> rx_dat_valid_i,
		SignalOut_clkB	=> internal_rx_dat_valid(0));
	
		
proc_data_valid : process(rx_out_clk, rst_i)
begin
	if rst_i = '1' then	
		internal_rx_dat_valid(internal_rx_dat_valid'length-1 downto 1) <= (others =>'0');
	elsif rising_edge(rx_out_clk) then
		internal_rx_dat_valid <= internal_rx_dat_valid(internal_rx_dat_valid'length-2 downto 0) & internal_rx_dat_valid(0);
	end if;
end process;

	--// re-organize data and pipeline	
	proc_pipeline_data : process(rx_out_clk, rst_i, internal_rx_dat_valid)
	begin
		if rst_i = '1' or internal_rx_dat_valid(0) = '0' then
		
			data_p	 		<= (others => '0');
			for i in 0 to 1 loop
				data_two_chan(i) 		<= (others => '0');
				data_two_chan_p(i) 	<= (others => '0');
			end loop;	
		
		elsif rising_edge(rx_out_clk) then --and internal_rx_dat_valid(internal_rx_dat_valid'length-1) = '1' then
		
			for i in 0 to 1 loop
				data_two_chan_p(i)(127 downto 112) 	<= data_two_chan(i)(15 downto 0);
				data_two_chan_p(i)(111 downto 96) 	<= data_two_chan(i)(31 downto 16);
				data_two_chan_p(i)(95 downto 80) 	<= data_two_chan(i)(47 downto 32);
				data_two_chan_p(i)(79 downto 64) 	<= data_two_chan(i)(63 downto 48);
				data_two_chan_p(i)(63 downto 48) 	<= data_two_chan(i)(79 downto 64);
				data_two_chan_p(i)(47 downto 32) 	<= data_two_chan(i)(95 downto 80);
				data_two_chan_p(i)(31 downto 16) 	<= data_two_chan(i)(111 downto 96);
				data_two_chan_p(i)(15 downto 0) 		<= data_two_chan(i)(127 downto 112);
								
				--//uncomment to test RAM read/write:
--				data_two_chan_p(i)(127 downto 112) 	<= x"0202";
--				data_two_chan_p(i)(111 downto 96) 	<= x"0202";
--				data_two_chan_p(i)(95 downto 80) 	<= x"0F0F";
--				data_two_chan_p(i)(79 downto 64) 	<= x"0202";
--				data_two_chan_p(i)(63 downto 48) 	<= x"0F0F";
--				data_two_chan_p(i)(47 downto 32) 	<= x"0202";
--				data_two_chan_p(i)(31 downto 16) 	<= x"0F0F";
--				data_two_chan_p(i)(15 downto 0) 		<= x"AFAF";
			--end loop;

				for j in 0 to define_serdes_factor-1 loop

				--/////////////////////////////////////////////////////////
				--//this is for the full 7 bits, 8-bit word size:
				--/////////////////////////////////////////////////////////
					data_two_chan(i)(16*(j+1)-1 downto 16*j) <= 	
												'0'  & data_p(define_serdes_factor*6+j+iq_split*i) & 
												data_p(define_serdes_factor*5+j+iq_split*i) & data_p(define_serdes_factor*4+j+iq_split*i) & 
												data_p(define_serdes_factor*3+j+iq_split*i) & data_p(define_serdes_factor*2+j+iq_split*i) & 
												data_p(define_serdes_factor*1 +j+iq_split*i) & data_p(0+j+iq_split*i) &
												'0'  & data_p(define_serdes_factor*13+j+iq_split*i) & 
												data_p(define_serdes_factor*12+j+iq_split*i) & data_p(define_serdes_factor*11+j+iq_split*i) & 
												data_p(define_serdes_factor*10+j+iq_split*i) &  data_p(define_serdes_factor*9+j+iq_split*i) & 
												data_p(define_serdes_factor*8+j+iq_split*i) &	data_p(define_serdes_factor*7+j+iq_split*i);

				--/////////////////////////////////////////////////////////
				--//this is for 5-bit operation (8-bit word size):
				--/////////////////////////////////////////////////////////
--					data_two_chan(i)(16*(j+1)-1 downto 16*j) <= 	
--												"000" &  data_p(define_serdes_factor*4+j+iq_split*i) & 
--												data_p(define_serdes_factor*3+j+iq_split*i) & data_p(define_serdes_factor*2+j+iq_split*i) & 
--												data_p(define_serdes_factor*1 +j+iq_split*i) & data_p(0+j+iq_split*i) &
--												"000" &  data_p(define_serdes_factor*11+j+iq_split*i) &
--												data_p(define_serdes_factor*10+j+iq_split*i) &  data_p(define_serdes_factor*9+j+iq_split*i) & 
--												data_p(define_serdes_factor*8+j+iq_split*i) &	data_p(define_serdes_factor*7+j+iq_split*i);

				end loop;		
			end loop;
			
			data_p  <= data;
			
		end if;
	end process;
	
	--// write ADC data to fpga rx buffer ram
	proc_write_data : process(rx_out_clk, rst_i, internal_rx_dat_valid, ram_wr_adr_rst_i)
	begin	
		if rst_i = '1' or internal_rx_dat_valid(0) = '0' or ram_wr_adr_rst_i = '1' then
			ram_write_adrs_rising_edge 	<= (others => '0');
			rx_ram_write_adr_o <= (others=>'0');
			ram_write_en						<= '0';
					
		elsif rising_edge(rx_out_clk) and internal_rx_dat_valid(internal_rx_dat_valid'length-1) = '1' then
		--elsif rising_edge(rx_out_clk) then --and rx_dat_valid_i = '1' then
		--elsif rising_edge(rx_out_clk) then
			ram_write_en	<= '1';
			rx_ram_write_adr_o <= ram_write_adrs_rising_edge;
			ram_write_adrs_rising_edge <= ram_write_adrs_rising_edge + 1;
		end if;		
	end process;

end rtl;