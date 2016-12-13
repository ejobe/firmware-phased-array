---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      
-- FILE:         align_serdes
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         2/2016
--
-- DESCRIPTION:  state machine definition to align serdes links
---------------------------------------------------------------------------------

library IEEE; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity serdes_wrapper is
	generic (
		serial_factor 	: integer := 8);	
	port(
		CLK				: in	std_logic;  --master clk (100 Mhz)
		reset				: in	std_logic;  --reset
		do_alignment	: in	std_logic;  --flag to align the serdes bitstream
		ref_word			: in	std_logic_vector(serial_factor-1 downto 0); --reference word
		good_data_to_tx: in 	std_logic_vector(serial_factor-1 downto 0); --tx parallel data
		the_rx			: in	std_logic;  --rx serdes, to FPGA pin
		good_data_rx	: out	std_logic_vector(serial_factor-1 downto 0); --rx parallel data
		rx_outclk		: out	std_logic;  --rx parallel data clk
		the_tx			: out	std_logic;  --tx serdes, to FPGA pin
		aligned			: out	std_logic); --indicates bitsream aligned successfully 
		
end serdes_wrapper;
		
architecture Behavioral of serdes_wrapper is	
	type SERDES_ALIGN_TYPE is (CHECK, DOUBLE_CHECK, INCREMENT, ALIGN_DONE);
	signal BIT_ALIGN 				: SERDES_ALIGN_TYPE;
	
	signal ALIGN_SUCCESS			:	std_logic;
	signal RX_ALIGN_BITSLIP		:	std_logic;
	signal CHECK_WORD 			: 	std_logic_vector(serial_factor-1 downto 0);
	signal TX_DATA	 				: 	std_logic_vector(serial_factor-1 downto 0);
	signal RX_DATA	 				: 	std_logic_vector(serial_factor-1 downto 0);

	component rxSerial_Link
		PORT
		(
			pll_areset					: IN 	STD_LOGIC;
			rx_channel_data_align	: IN 	STD_LOGIC;
			rx_in							: IN 	STD_LOGIC;
			rx_inclock					: IN 	STD_LOGIC;
			rx_locked					: OUT STD_LOGIC;
			rx_out						: OUT STD_LOGIC_VECTOR(serial_factor-1 DOWNTO 0);
			rx_outclock					: OUT STD_LOGIC);
	end component;

	component txSerial_Link
		PORT
		(
			tx_in				: IN 	STD_LOGIC_VECTOR(serial_factor-1 DOWNTO 0);
			tx_inclock		: IN 	STD_LOGIC;
			tx_locked		: OUT STD_LOGIC;
			tx_out			: OUT STD_LOGIC);
			--tx_outclock		: OUT STD_LOGIC);
	end component;	
	
begin		

aligned 			<= ALIGN_SUCCESS;
good_data_rx 	<= RX_DATA;

RxSERDES : rxSerial_Link
port map(
	pll_areset					=> '0',
	rx_channel_data_align	=> RX_ALIGN_BITSLIP,
	rx_in							=> the_rx,
	rx_inclock					=> CLK,
	rx_locked					=> open,
	rx_out						=> RX_DATA,
	rx_outclock					=> rx_outclk);
	
TxSERDES : txSerial_Link
port map(
	tx_in				=> TX_DATA,
	tx_inclock		=> CLK,
	tx_locked		=> open,
	tx_out			=> the_tx);
	--tx_outclock		=> open);
	
proc_align_serdes: process(CLK, reset, do_alignment, RX_DATA)
variable i : integer range 5 downto 0 := 0;	
begin
	if reset = '1' then
		
		ALIGN_SUCCESS 		<= '0';
		TX_DATA 				<= (others=>'0');
		CHECK_WORD			<= (others=>'0');
		BIT_ALIGN 			<= CHECK;
		RX_ALIGN_BITSLIP 	<= '0';
		i := 0;
	
	elsif falling_edge(CLK) and do_alignment = '1' then
		TX_DATA <= ref_word;
		
		case BIT_ALIGN is
				
				when CHECK =>
					RX_ALIGN_BITSLIP	<= '0';
					CHECK_WORD 		  	<= rx_data;

					if RX_DATA = ref_word then
						i := 0;
						BIT_ALIGN <= DOUBLE_CHECK;
					else
   					ALIGN_SUCCESS <= '0';
						i := i + 1;
						if i > 3 then
							i := 0;
							BIT_ALIGN <= INCREMENT;
						end if;
					end if;
				
				when  DOUBLE_CHECK =>
					CHECK_WORD <= RX_DATA;
					
					if rx_data = ref_word then
						BIT_ALIGN <= ALIGN_DONE;
					else
						i := i + 1;
						if i > 3 then
							i := 0;
							BIT_ALIGN <= CHECK;
						end if;
					end if;
				
				when INCREMENT =>
					i := i+1;
					RX_ALIGN_BITSLIP <= '1';
					if i > 1 then
						i := 0;
						RX_ALIGN_BITSLIP <= '0';
						BIT_ALIGN <= CHECK;
					end if;
				
				when ALIGN_DONE =>
					ALIGN_SUCCESS <= '1';
					BIT_ALIGN <= CHECK;
					
				when others=>
					BIT_ALIGN <= CHECK;
		end case;
		
	elsif falling_edge(CLK) and ALIGN_SUCCESS = '1' 
			and do_alignment  = '0' then
		TX_DATA <= good_data_to_tx;

	end if;
end process;

end Behavioral;