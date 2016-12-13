---------------------------------------------------------------------------------
-- Univ. of Chicago HEP / electronics design group
--    -- + KICP 2015 --
--
-- PROJECT:      
-- FILE:         usb.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         2012 + edits thereafter..
--
-- DESCRIPTION:  usb CYPRESS interface  read/write driver
--
---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity usb_32bit is
	generic(
			data_width		: integer := 32;
			timeout_write  : integer := 10000000);
   port ( 
			USB_IFCLK		: in		std_logic;   	--//usb clock 48 Mhz
			USB_RESET    	: in  	std_logic;	   --//reset signal to usb block 
			USB_BUS  		: inout  std_logic_vector (15 downto 0);  --//usb data bus to PHY
			FPGA_DATA		: in		std_logic_vector (15 downto 0);  --//data bus from firmware

			--//usb write to pc		
         USB_FLAGB    	: in  	std_logic;		--//usb flag b (unused)
         USB_FLAGC    	: in  	std_logic;		--//usb flag c 
			USB_START_WR	: in  	std_logic;		--//usb start write cycle
			USB_NUM_WORDS	: in		std_logic_vector(15 downto 0);
         USB_DONE  		: out 	std_logic; 	   --//usb done with write cycle to PC flag
         USB_PKTEND    	: out 	std_logic;		--//usb packet end flag
         USB_SLWR  		: out 	std_logic;		--//usb signal-low write (generated clock)
         USB_WBUSY 		: out 	std_logic;     --//usb write-busy indicator (not a PHY pin)
			
			--//usb read from pc	
         USB_FLAGA    	: in    	std_logic;     --//usb flag a
         USB_FIFOADR  	: out   	std_logic_vector (1 downto 0);
         USB_SLOE     	: out   	std_logic;    	--//usb signal-low output enable
         USB_SLRD     	: out   	std_logic;		--//usb signal-low read (generated clock)
         USB_RBUSY 		: out   	std_logic;		--//usb read-busy indicator (not a PHY pin)
         USB_INSTRUCTION: out   	std_logic_vector(data_width-1 downto 0);
			USB_INSTRUCT_RDY:out		std_logic);		--//flag hi = packet read from PC is ready
			
	end usb_32bit;

architecture Behavioral of usb_32bit is
	
	--USB write signals
	type USB_write_type is ( IDLE, RCHECK, STATE1, STATE2, STATE3, 
								RD_DONE, SYNC1, SYNC2, SYNC3);
	signal 	write_state	: USB_write_type;
	signal 	NEXT_STATE 	: USB_write_type;
	signal 	column 		: std_logic_vector(23 downto 0);
	constant DELAY_HI 	: integer:= 5;
	constant DELAY_LO 	: integer:= 5;
	signal 	sync 			: std_logic;
	signal 	STARTRD		: std_logic;
	signal 	STARTSNC		: std_logic;
	signal 	LoHi			: std_logic;
	signal 	SLWR			: std_logic;
	signal 	DONE			: std_logic;
	signal 	WBUSY			: std_logic;
	signal 	PKTEND		: std_logic;
	signal 	LRAD 			: std_logic_vector(23 downto 0);
	
	--USB read signals
	type USB_read_type is(st1_WAIT,
							st1_READ, st2_READ, st3_READ,st4_READ,
							st1_SAVE, st1_TARGET, ENDDELAY);
	signal 	read_state	: USB_read_type;
	signal 	dbuffer		: std_logic_vector (15 downto 0);
	signal 	Locmd			: std_logic_vector (15 downto 0);
	signal 	Hicmd			: std_logic_vector (15 downto 0);
	signal 	again			: std_logic_vector (1 downto 0);
	signal 	TOGGLE		: std_logic_vector (15 downto 0); 
	signal 	SLRD			: std_logic;
	signal	SLOE			: std_logic;
	signal 	RBUSY			: std_logic;
	signal 	FIFOADR    	: std_logic_vector (1 downto 0);
	constant delay_inst	: integer := 6;  --//clock cycles instruction is asserted
	
	signal	USB_DATA		: std_logic_vector(15 downto 0);
	signal   instruction	: std_logic_vector(data_width-1 downto 0);
	signal	instruct_rdy: std_logic;

	component iobuf
	port(
		datain		: IN 		STD_LOGIC_VECTOR (15 DOWNTO 0);
		oe				: IN  	STD_LOGIC_VECTOR (15 DOWNTO 0);
		dataio		: INOUT 	STD_LOGIC_VECTOR (15 DOWNTO 0);
		dataout		: OUT 	STD_LOGIC_VECTOR (15 DOWNTO 0));
	end component;
	
begin

USB_WBUSY			<=	WBUSY; 
USB_RBUSY			<=	RBUSY; 
USB_PKTEND			<= PKTEND;
USB_DONE				<= DONE;
USB_SLOE				<= SLOE;
USB_SLWR				<= SLWR;
USB_SLRD				<= SLRD;
USB_FIFOADR 		<= FIFOADR;
USB_INSTRUCTION 	<= instruction;
USB_INSTRUCT_RDY	<= instruct_rdy;

	xUSB_IO_BUFFER	: iobuf
	port map(
		datain	=>	FPGA_DATA,		
		oe			=> TOGGLE,	
		dataio	=> USB_BUS,	
		dataout	=> USB_DATA);

---------------------------------------------------------------------------------
--USB write to PC
---------------------------------------------------------------------------------
proc_usb_write : process(USB_IFCLK, USB_RESET, STARTSNC, STARTRD)
	variable j: integer range 0 to 15 :=0;	-- Integer for delay	
	variable timeout : integer range 0 to 10000003:=0;	
	begin
		if USB_RESET = '1' then
			DONE			<= '0';
			sync			<= '0';
			LRAD 			<= (others=>'0');
			LoHi 			<= '0';
         SLWR 			<=	'1';
         PKTEND 		<=	'1';
			WBUSY 		<=	'0';
			write_state	<= IDLE;
			NEXT_STATE	<= IDLE;	
		elsif rising_edge(USB_IFCLK) then
			DONE			<= '0';
			WBUSY 		<=	'1';
			SLWR 		   <=	'1';
         PKTEND 		<=	'1';
--------------------------------------------------------------------------------
			case write_state is
--------------------------------------------------------------------------------
				when IDLE =>
					WBUSY <=	'0';
						if STARTRD = '1' then  	
							write_STATE  	<= RCHECK;
							column 	<= (others=>'0');
							LRAD	 	<= (others=>'0');
						end if;
						--if xSYNC_USB = '1' then
						--	if STARTSNC = '1'  then
						--		sync 			<= '1';
						--		write_state	<= SYNC1;
						--		NEXT_STATE 	<= IDLE;		 
						--	end if;
						--end if;						
--------------------------------------------------------------------------------										
				when RCHECK	=>					  		-- Check if READ module is readin data from USB			
					if RBUSY = '0' then		  		-- If not, send sync packet first
						WBUSY <= '1';  
						write_state <= STATE1;
					else							 		-- Else wait here and allow reading
						WBUSY <= '0';
						write_state <= IDLE;
					end if;
--------------------------------------------------------------------------------										
				when STATE1 =>										-- Check Full flag	
					WBUSY <= '0';
					if USB_FLAGC = '1' and RBUSY = '0' then	 	-- 1 = Empty
						timeout := 0;
						WBUSY <= '1';
						write_state <= STATE2;
					elsif timeout = timeout_write-2 then
						DONE <= '1';
					elsif timeout = timeout_write then
						DONE <= '0';
						timeout := 0;
						write_state <= IDLE;
					else
						timeout := timeout+1;
					end if;
--------------------------------------------------------------------------------
				when STATE2 =>				
					j := j + 1;					
					if j = (DELAY_LO + DELAY_HI) then
						j 		:= 0;
						SLWR 	<= '1';
						write_state <= STATE3;
					elsif j <= DELAY_LO then 
						SLWR 	<= '0';
					elsif j > DELAY_LO and j <= (DELAY_LO + DELAY_HI) then
						SLWR 	<= '1';
					end if;
--------------------------------------------------------------------------------
				when STATE3 =>									  	
					if column >= USB_NUM_WORDS-1 then 
						column 	<= (others=>'0');
						LRAD	 	<= (others=>'0');
						DONE 		<= '1';
						write_state		<= RD_DONE;			
					else 
						write_state 	<= STATE1;
						LRAD		<= column;
						column 	<= column + 1;		
					end if;
--------------------------------------------------------------------------------
				when RD_DONE =>	
					DONE 		<= '1';
					if j = 4 then
						j := 0;
						write_state 	<= SYNC3;
						NEXT_STATE <= IDLE;
					else
						j:= j + 1;
					end if;	
--------------------------------------------------------------------------------
				when SYNC1 =>
					sync 	<= '1';
					if USB_FLAGC = '1' and RBUSY ='0' then	 
						if j = DELAY_LO + DELAY_HI then
							j 		:= 0;
							SLWR 	<= '1';
							write_state <= SYNC2;
						elsif j <= DELAY_LO then 
							SLWR 	<= '0';
						elsif j > DELAY_LO and j <= (DELAY_LO + DELAY_HI) then
							SLWR 	<= '1';
						end if;
					j := j + 1;
					else
						WBUSY <= '0';
					end if;
--------------------------------------------------------------------------------
				when SYNC2 =>
					if LoHi = '0' then		-- LoHi = 0
						LoHi 	<= '1';			--> LoHi = '1'
						write_state <= SYNC1;
					elsif LoHi = '1' then	-- LoHi = 1
						LoHi 	<= '0';			--> LoHi = '1'
						write_state <= SYNC3;
					end if;
--------------------------------------------------------------------------------	
				when SYNC3 =>	-- PKTEND
					if RBUSY ='0' then
						WBUSY <='1';
						if j = 7 then
							PKTEND <= '1';
							j := 0;
							sync	<= '0';
							write_state <= NEXT_STATE;						
						elsif j > 3 then
							PKTEND <= '1';
							j := j + 1;
						else
							PKTEND <= '0';
							j := j + 1;
						end if;
					else
						WBUSY <='0';
					end if;
				when others =>	write_state<=IDLE;																
			end case;
		end if;
	end process;
--------------------------------------------------------------------------------	
	process(USB_IFCLK, USB_RESET, STARTRD)
	variable i: integer range 0 to 131071 :=0;	
	begin
		if USB_RESET = '1' then
			i := 0;
		elsif rising_edge(USB_IFCLK) then
			i := i + 1;			
			if i > 131063 and STARTRD = '0' then
				STARTSNC <= '1';
			else
			 	STARTSNC <= '0';
			end if;	
		end if;
	end process;
--------------------------------------------------------------------------------
	process(USB_IFCLK, USB_RESET, USB_START_WR)
	begin
		if USB_RESET ='1' then
			STARTRD <= '0';	
		elsif rising_edge(USB_IFCLK) then
			if USB_START_WR = '1' then
				STARTRD <= '1';
			else 
				STARTRD <= '0';
			end if;
		end if;
	end process;
--------------------------------------------------------------------------------
---------------------------------------------------------------------------------
--USB read from PC
---------------------------------------------------------------------------------
proc_usb_read : process(USB_IFCLK, USB_RESET)
	variable delay : integer range 0 to 50;
	begin
		if USB_RESET = '1' then
			--SYNC_USB		<= '0';
			SLRD 			<= '1'; 
			SLOE 			<= '1';
			FIFOADR 		<= "10";
			TOGGLE 		<= (others=>'1');
			again 		<= "00";
			RBUSY 		<= '1';
			delay 		:= 0;	
			instruction <= (others=>'0');
			instruct_rdy<= '0';
			read_state  <= st1_WAIT;
		elsif rising_edge(USB_IFCLK) then
			SLOE 			   <= '1';
			SLRD 			   <= '1';
			FIFOADR 		   <= "10";
			--instruction 	<= (others=>'0');
			instruct_rdy	<= '0';
			TOGGLE 			<= (others=>'1');
			RBUSY 		   <= '1';
--------------------------------------------------------------------------------				
			case	read_state is	
--------------------------------------------------------------------------------
				when st1_WAIT =>
					RBUSY <= '0';						 
					if USB_FLAGA = '1' then	
						RBUSY <= '1';
						if WBUSY = '0' then		
							RBUSY <= '1';
							read_state <= st1_READ;
						end if;
					end if;		 
--------------------------------------------------------------------------------		
				when st1_READ =>
					FIFOADR <= "00";	
					TOGGLE <= (others=>'0');
					if delay = 2 then
						delay := 0;
						read_state <= st2_READ;
					else
						delay := delay +1;
					end if;
--------------------------------------------------------------------------------					
				when st2_READ =>	
					FIFOADR <= "00";
					TOGGLE <= (others=>'0');
					SLOE <= '0';
					if delay = 2 then
						delay := 0;
						read_state <= st3_READ;
					else
						delay := delay +1;
					end if;				
--------------------------------------------------------------------------------						
				when st3_READ =>					
					FIFOADR <= "00";
					TOGGLE <= (others=>'0');
					SLOE <= '0';
					SLRD <= '0';
					dbuffer <= USB_DATA;
					if delay = 2 then
						delay := 0;
						read_state <= st4_READ;
					else
						delay := delay +1;
					end if;					
--------------------------------------------------------------------------------					   
				when st4_READ =>					
					FIFOADR <= "00";
					TOGGLE <= (others=>'0');
					SLOE <= '0';
					if delay = 2 then
						delay := 0;
						read_state <= st1_SAVE;
					else
						delay := delay +1;
					end if;				
--------------------------------------------------------------------------------	
				when st1_SAVE	=>
					FIFOADR <= "00";
					TOGGLE <= (others=>'0');
--------------------------------------------------------------------------------						
					case again is 
						when "00" =>	
							again <="01";	
							Locmd <= dbuffer;
							read_state <= ENDDELAY;
--------------------------------------------------------------------------------	
						when "01" =>
							again <="00";	
							Hicmd <= dbuffer;	
							read_state <= st1_TARGET;
--------------------------------------------------------------------------------	
						when others =>				
							read_state <= st1_WAIT;
					end case;
--------------------------------------------------------------------------------	
				when st1_TARGET =>
					instruction <= Hicmd & Locmd; --the usb word from PC
					instruct_rdy<= '1';
					if delay > delay_inst then
						RBUSY <= '0';
						delay := 0;
						read_state <= st1_WAIT;
					else
						RBUSY <= '1';
						delay := delay + 1;
					end if;		
						
--------------------------------------------------------------------------------	
				when ENDDELAY =>	
					FIFOADR <= "00"; 
					if delay > 1 then
						if USB_FLAGA = '1' then
							delay := 0;
							read_state <= st1_READ;
						else
							delay := 0;
							read_state <= st1_WAIT;
						end if;
					else
						delay := delay +1;
					end if;
--------------------------------------------------------------------------------						
				when others =>
					read_state <= st1_WAIT;
			end case;	  
		end if;
	end process;
--------------------------------------------------------------------------------

end Behavioral;