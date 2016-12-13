---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         SerialLinks.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         2/2016
--
-- DESCRIPTION:  Rx / Tx Block for serial links
---------------------------------------------------------------------------------


library IEEE; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.defs.all;

entity SerialLinks is
	generic (
		serial_factor 	: integer := 8);	
	Port(
		CLK				: in	std_logic;
		reset				: in	std_logic;
		
		System_RX_pin	: in	std_logic;
		System_TX_pin	: out	std_logic;
		System_RX_outclk:out std_logic;
		System_RX_data	: out	std_logic_vector(serial_factor-1 downto 0);	
		System_TX_data	: in	std_logic_vector(serial_factor-1 downto 0);		
		Sys_setup		: in	std_logic;
		Sys_aligned		: out	std_logic;
		Sys_loopback	: in	std_logic;

		Aux0_RX_pin		: in	std_logic_vector(1 downto 0);
		Aux0_TX_pin		: out	std_logic_vector(1 downto 0);
		Aux0_RX_outclk	: out	std_logic_vector(1 downto 0);
		Aux0_RX_data	: out	aux_data_link_type;
		Aux0_TX_data	: in	aux_data_link_type;		
		Aux0_setup		: in	std_logic;
		Aux0_aligned	: out	std_logic_vector(1 downto 0);
		Aux0_loopback	: in	std_logic;
		
		Aux1_RX_pin		: in	std_logic_vector(1 downto 0);
		Aux1_TX_pin		: out	std_logic_vector(1 downto 0);
		Aux1_RX_outclk	: out	std_logic_vector(1 downto 0);
		Aux1_RX_data	: out	aux_data_link_type;
		Aux1_TX_data	: in	aux_data_link_type;		
		Aux1_setup		: in	std_logic;
		Aux1_aligned	: out	std_logic_vector(1 downto 0);
		Aux1_loopback	: in	std_logic);
		
end SerialLinks;

architecture Behavioral of SerialLinks is

signal ref_word	:	std_logic_vector(serial_factor-1 downto 0);

signal xSystem_Tx_data	: std_logic_vector(serial_factor-1 downto 0);
signal xSystem_RX_data	: std_logic_vector(serial_factor-1 downto 0);	
signal xAux0_RX_data		: aux_data_link_type;
signal xAux0_TX_data		: aux_data_link_type;		
signal xAux1_RX_data		: aux_data_link_type;
signal xAux1_TX_data		: aux_data_link_type;

begin


SystemTranceiver : entity work.serdes_wrapper(Behavioral)
	generic map(serial_factor => serial_factor)
	port map(
		CLK				=> CLK,			
		reset				=> reset,
		do_alignment	=> Sys_setup,
		ref_word			=> ref_word,
		good_data_to_tx=> xSystem_Tx_data,
		the_rx			=> System_RX_pin,
		good_data_rx	=> xSystem_RX_data,
		rx_outclk		=> System_RX_outclk,
		the_tx			=> System_TX_pin,
		aligned			=> Sys_aligned);


AuxTranceiver0 : for i in 1 downto 0 generate
	xAUX0link: entity work.serdes_wrapper(Behavioral)
		generic map(serial_factor => serial_factor)
		port map(
			CLK				=> CLK,			
			reset				=> reset,
			do_alignment	=> Aux0_setup,
			ref_word			=> ref_word,
			good_data_to_tx=> xAux0_Tx_data(i),
			the_rx			=> Aux0_RX_pin(i),
			good_data_rx	=> xAux0_RX_data(i),
			rx_outclk		=> Aux0_RX_outclk(i),
			the_tx			=> Aux0_TX_pin(i),
			aligned			=> Aux0_aligned(i));
	end generate;
	
AuxTranceiver1 : for i in 1 downto 0 generate
	xAUX1link:	entity work.serdes_wrapper(Behavioral)
		generic map(serial_factor => serial_factor)
		port map(
			CLK				=> CLK,			
			reset				=> reset,
			do_alignment	=> Aux1_setup,
			ref_word			=> ref_word,
			good_data_to_tx=> xAux1_Tx_data(i),
			the_rx			=> Aux1_RX_pin(i),
			good_data_rx	=> xAux1_RX_data(i),
			rx_outclk		=> Aux1_RX_outclk(i),
			the_tx			=> Aux1_TX_pin(i),
			aligned			=> Aux1_aligned(i));
	end generate;
	
	
proc_loopback_test : process(CLK, Sys_loopback, Aux0_loopback, Aux1_loopback, reset)
begin
	if reset = '1' then
		xSystem_Tx_data 	<= (others=>'0'); --System_Tx_data;
		System_Rx_data 	<= xSystem_Rx_data;
		xAux0_Tx_data(0)	<= (others=>'0'); --Aux0_Tx_data;
		xAux0_Tx_data(1)	<= (others=>'0');
		Aux0_Rx_data 		<= xAux0_Rx_data;
		xAux1_Tx_data(0)	<= (others=>'0'); --Aux1_Tx_data;
		xAux1_Tx_data(1)	<= (others=>'0');
		Aux1_Rx_data 		<= xAux1_Rx_data;
		
	elsif falling_edge(CLK) then
		if Sys_loopback = '1' then
			xSystem_Tx_data<= xSystem_Rx_data;
			System_Rx_data <= xSystem_Rx_data;
		else
			xSystem_Tx_data<= System_Tx_data;
			System_Rx_data <= xSystem_Rx_data;
		end if;
		
		if Aux0_loopback = '1' then
			xAux0_Tx_data 	<= xAux0_Rx_data;
			Aux0_Rx_data 	<= xAux0_Rx_data;
		else
			xAux0_Tx_data 	<= Aux0_Tx_data;
			Aux0_Rx_data 	<= xAux0_Rx_data;
		end if;		

		if Aux1_loopback = '1' then
			xAux1_Tx_data 	<= xAux1_Rx_data;
			Aux1_Rx_data 	<= xAux1_Rx_data;
		else
			xAux1_Tx_data 	<= Aux1_Tx_data;
			Aux1_Rx_data 	<= xAux1_Rx_data;
		end if;				
	end if;
end process;
	

end Behavioral;