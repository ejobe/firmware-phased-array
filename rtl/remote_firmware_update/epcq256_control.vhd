---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         epcq2556_control.vhd
-- AUTHOR:       
-- EMAIL         ejo@uchicago.edu
-- DATE:         10/2017
--
-- DESCRIPTION:  
--
--       adapted from FTK AUX code
-----///////////////////////////////////////////////////////////////////
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity epcq256_control is
  port (
    clk_i			: in  std_logic	:= '0';
    reset_i			: in  std_logic	:= '0';
    cmd_i			: in  std_logic_vector( 2 downto 0);
    addr_i			: in  std_logic_vector(31 downto 0);
    test_mode_i	: in  std_logic;
    -- Data out
    busy_status_o	: out std_logic;
    done_status_o	: out std_logic;
    rdaddr_o		: out std_logic_vector(31 downto 0);		
    data_o			: out std_logic_vector(31 downto 0);
    data_valid_o	: out std_logic;
    -- Input data
    clear_i			: in  std_logic;
    fifo_wren_i   : in  std_logic;
    fifo_ds_i     : in  std_logic;
    fifo_data_i   : in  std_logic_vector(31 downto 0);
	 fifo_empty_o	: out std_logic;
	 fifo_full_o	: out std_logic
  );
end entity epcq256_control;

architecture behaviour OF epcq256_control is
  ------------------
  -- Components   --    
  ------------------
  component epcqio_block
    port (
      addr		: in  std_logic_vector (31 downto 0);
      bulk_erase       	: in  std_logic;
      clkin		: in  std_logic;
      datain		: in  std_logic_vector ( 7 downto 0);
      en4b_addr		: in  std_logic;
      rden		: in  std_logic;
      read		: in  std_logic;
      reset		: in  std_logic;
      sector_erase	: in  std_logic;
      shift_bytes	: in  std_logic;
      wren		: in  std_logic;
      write		: in  std_logic;
      busy		: out std_logic;
      data_valid	: out std_logic;
      dataout		: out std_logic_vector ( 7 downto 0);
      illegal_erase	: out std_logic;
      illegal_write	: out std_logic;
      read_address	: out std_logic_vector (31 downto 0)
    );
  end component;
	
  component reset_block is
    port (
      clk_i   	        		: in  std_logic;
      rst_i   	   			: in  std_logic;
      consolidated_reset_o	: out std_logic := '1'
    );
  end component reset_block;

  ------------------
  -- Signals      --
  ------------------
  type fsm_t is (idle_fromop,idle,start4byte,do4byte,startread,doread,startwrite,startwriteparse,dowrite0,dowrite1,dowrite2,dowrite3,donewrite,starterase,doerase,startserase,doserase,waitbusy,done);
  signal fsm	                : fsm_t	:= idle;
  signal currcmd		: std_logic_vector(2 downto 0);
  
  signal reset_int		: std_logic;
  signal busy_int		: std_logic;
  signal wren_int		: std_logic;
  
  -- 4-byte addressing mode specific signals
  signal mode4byte		: std_logic;
  signal en4b_addr		: std_logic;
  signal wren_4byte_int	        : std_logic;
  
  -- Read specific signals
  signal byte_read		: integer range 0 to 16384 := 0;
  signal data_int 		: std_logic_vector(7 downto 0);
  signal data_int_rev 		: std_logic_vector(7 downto 0);  
  signal data_valid_int 	: std_logic;
  signal rden 			: std_logic;
  signal read_int 		: std_logic;
  signal rdaddr_int		: std_logic_vector(31 downto 0);
  
  -- Write specific signals
  signal byte_writ		: integer range 0 to 16384 := 0;
  signal wren_write_int	        : std_logic;
  signal write_int		: std_logic;
  signal shift_bytes_int	: std_logic;
  signal datain_int		: std_logic_vector(7 downto 0);
  signal datain_int_rev	        : std_logic_vector(7 downto 0);
  
  -- Erase specific signals
  signal wren_erase_int	        : std_logic;
  signal bulk_erase_int	        : std_logic;
  
  -- Erase specific signals
  signal wren_serase_int	: std_logic;
  signal sector_erase_int	: std_logic;
  
  -- Program buffer
  signal buffclear		: std_logic;
  signal buffread_int		: std_logic;
  signal buffdata_int		: std_logic_vector(31 downto 0);
  signal buffempty_int		: std_logic;
begin
  buffclear <= clear_i OR reset_i;
  fifo_empty_o <= buffempty_int;
  
  proc_reverse_datain : process(datain_int)
  begin
    FOR i IN datain_int'range LOOP
      datain_int_rev(datain_int_rev'left - i) <= datain_int(i);
    end LOOP;
  end process;

  proc_reverse_data : process(data_int)
  begin
    FOR i IN data_int'range LOOP
      data_int_rev(data_int_rev'left - i) <= data_int(i);
    end LOOP;
  end process;

  -- reset
  xRESET_BLOCK : reset_block
    port map (
      clk_i                => clk_i,
      rst_i                => reset_i,
      consolidated_reset_o => reset_int);

  -- Buffer for write operations
  xEPCQ_WRITEBUFFER_FIFO_BLOCK : entity work.remote_update_writeFIFO_block
    port map (
      clock_i   		=> clk_i,
      rst_i     		=> buffclear,      
      mode_i  	 		=> test_mode_i,
      fifo_wren_i  	=> fifo_wren_i,
      fifo_wrclk_i   => fifo_ds_i,
      fifo_data_i  	=> fifo_data_i,
      fifo_rden_i	 	=> buffread_int,
		fifo_full_o		=> fifo_full_o,
      data_o			=> buffdata_int,
      empty_o     	=> buffempty_int);
  
  -- Make an epcq io using
  -- Altera ASMI Parallel IP block
  xEPCQIO_BLOCK : epcqio_block
    port map (
      clkin          => clk_i,
      reset	        	=> reset_int,
      en4b_addr      => en4b_addr,
      busy           => busy_int,
      addr           => addr_i,
      rden 	        	=> rden,
      read 	        	=> read_int,		
      data_valid    	=> data_valid_int,
      dataout 	     	=> data_int,
      read_address  	=> rdaddr_int,     
      wren				=> wren_int,   
      write				=> write_int,
      shift_bytes		=> shift_bytes_int,
      datain			=> datain_int_rev,   
      bulk_erase		=> bulk_erase_int,    
      sector_erase	=> sector_erase_int
    );
  
		
  -- FSM
  fsm_proc : process (clk_i, reset_int, cmd_i, test_mode_i)
    variable idle_wait : integer range 0 to 2 := 0;
  begin
    if (reset_int = '1' ) then
      fsm <= idle_fromop;
      idle_wait := 0;
      currcmd <= "000";
      mode4byte <= '0';
    elsif(rising_edge(clk_i)) then
      case fsm is
        when idle_fromop =>
          if(idle_wait = 2) then
            idle_wait := 0;
            if(mode4byte='0') then
              fsm <= start4byte;
              currcmd <= "101";
            else
              fsm <= idle;
            end if;
          else
            idle_wait := idle_wait + 1;
            fsm <= idle_fromop;
          end if;
        when idle =>
          if(test_mode_i='0') then
            case cmd_i is
              when "000" =>
                fsm <= idle;
              when "001" =>
                fsm <= startread;
              when "010" =>
                if(buffempty_int='1') then
                  fsm <= idle; -- Don't bother starting write on empty buffer
                else
                  fsm <= startwrite;
                end if;
              when "011" =>
                fsm <= idle; --starterase; --mask off ability to bulk erase EPCQ
              when "100" =>
                fsm <= startserase;
              when "101" =>
                fsm <= start4byte;							
              when others =>
                fsm <= idle;
            end case;
            currcmd <= cmd_i;
          else
            fsm <= idle;
          end if;
        when start4byte =>
          fsm <= do4byte;
        when do4byte =>
          mode4byte <= NOT mode4byte;
          fsm <= waitbusy;
        when startread =>
          fsm <= doread;
        when doread =>
          if (byte_read = 16384) then
            fsm <= waitbusy;
          else
            fsm <= doread;
          end if;
          
        -- write
        when startwrite =>
          fsm <= startwriteparse;
        when startwriteparse =>
          fsm <= dowrite0;
        when dowrite0 =>
          fsm <= dowrite1;
        when dowrite1 =>
          fsm <= dowrite2;
        when dowrite2 =>
          fsm <= dowrite3;
        when dowrite3 =>
          if (buffempty_int = '1') then
            fsm <= donewrite;
          else
            fsm <= startwrite;
          end if;
        when donewrite =>
          fsm <= waitbusy;
          
        -- bulk erase
        when starterase =>
          fsm <= doerase;
        when doerase =>
          fsm <= waitbusy;
          
        -- sector erase
        when startserase =>
          fsm <= doserase;
        when doserase =>
          fsm <= waitbusy;

        -- done management
        when waitbusy =>
          if(busy_int = '1') then
            fsm <= done;
          else
            fsm <= waitbusy;
          end if;
          
        when done =>
          if (busy_int = '1' or cmd_i/="000") then
            fsm <= done;
          else
            fsm <= idle_fromop;
          end if;
      end case;
    end if;
  end process fsm_proc;
  
  -- to be done, one must be in done state and not busy
  busy_status_o <= busy_int;
  done_proc : process (clk_i, reset_int)
  begin
    if (reset_int = '1' ) then
      done_status_o <= '0';
    elsif(rising_edge(clk_i)) then
      case fsm is
        when done =>
          done_status_o <= not busy_int;
        when others =>
          done_status_o <= '0';
      end case;
    end if;
  end process done_proc;
  
	-- Controls common signals	
  with currcmd select
    wren_int <= wren_write_int  when "010",
                wren_erase_int	when "011",
                wren_serase_int	when "100",
                wren_4byte_int	when "101",
                '0'		when others;
  
  -- Set 4byte addressing mode	
  proc_4byte : process (clk_i,reset_int)
  begin
    if (reset_int = '1' ) then
      en4b_addr         <= '0';
      wren_4byte_int    <= '0';
    elsif(rising_edge(clk_i)) then
      case fsm is
        when idle =>
          en4b_addr     <= '0';
          wren_4byte_int<= '0';
        when start4byte =>
          en4b_addr     <= '1';
          wren_4byte_int<= '1';
        when do4byte =>
          en4b_addr     <= '0';
          wren_4byte_int<= '0';
        when others =>
          en4b_addr     <= '0';
          wren_4byte_int<= '0';
      end case;
    end if;
  end process proc_4byte;
  
  -- Read from the thing	
  proc_read : process (clk_i,reset_int)
  begin
    if (reset_int = '1' ) then
      data_o            <= (others => '0');
      data_valid_o      <= '0';
      rdaddr_o          <= (others => '0');
      byte_read         <= 0;
    elsif(rising_edge(clk_i)) then
      case fsm is
        when idle =>
          byte_read     <= 0;
          data_o        <= (others => '0');
          data_valid_o  <= '0';
          rden          <= '0';
          read_int      <= '0';
          rdaddr_o      <= (others => '0');
        when startread =>
          read_int      <= '1';
          rden          <= '1';
        when doread =>
          read_int      <= '0';
          if (byte_read = 16384) then
            rden        <= '0';
          elsif (data_valid_int='1') then
            case rdaddr_int(1 downto 0) is
              when "00" =>
                data_o(31 downto 24)      <= data_int_rev;
                data_o(23 downto 0)       <= (others => '0');
              when "01" =>
                data_o(23 downto 16)      <= data_int_rev;
                data_o(15 downto 0)       <= (others => '0');
              when "10" =>
                data_o(15 downto 8)       <= data_int_rev;
                data_o(7 downto 0)        <= (others => '0');
              when "11" =>
                data_o(7 downto 0)        <= data_int_rev;
              when others =>
                data_o                    <= (others => '0');
            end case;							
            if(rdaddr_int(1 downto 0)="11") then
              data_valid_o                <= '1';
            else
              data_valid_o                <= '0';
            end if;
            rdaddr_o(29 downto 0)         <= rdaddr_int(31 downto 2);
            rdaddr_o(31 downto 30)        <= (others => '0');
            byte_read   <= byte_read + 1;
          else
            data_valid_o  <= '0';
          end if;
        when others =>
          data_o        <= (others => '0');
          data_valid_o  <= '0';
          rdaddr_o      <= (others => '0');					
          byte_read     <= 0;
      end case;
    end if;
  end process proc_read;
  
  
  -- Write to the thing	
  proc_write : process (clk_i,reset_int)
  begin
    if (reset_int = '1' ) then
      buffread_int      <= '0';
      write_int         <= '0';
      wren_write_int    <= '0';
      shift_bytes_int   <= '0';
      datain_int	<= (others =>'0');
    elsif(rising_edge(clk_i)) then
      case fsm is
        when idle =>
          buffread_int          <= '0';
          write_int             <= '0';
          wren_write_int        <= '0';
          shift_bytes_int       <= '0';
          datain_int	        <= (others =>'0');
        when startwrite =>
          shift_bytes_int       <= '0';
          wren_write_int        <= '1';          
          buffread_int          <= '1';        
        when startwriteparse =>
          buffread_int          <= '0';          
          datain_int            <= (others => '0');
        when dowrite0 =>
          shift_bytes_int       <= '1';
          datain_int            <= buffdata_int(31 downto 24);
        when dowrite1 =>
          datain_int            <= buffdata_int(23 downto 16);
        when dowrite2 =>
          datain_int            <= buffdata_int(15 downto 8);
        when dowrite3 =>
          datain_int            <= buffdata_int(7 downto 0);
        when donewrite =>
          buffread_int          <= '0';
          write_int             <= '1';
          wren_write_int        <= '1';
          shift_bytes_int       <= '0';
          datain_int            <= (others => '0');
        when others =>
          buffread_int          <= '0';
          write_int             <= '0';
          wren_write_int        <= '0';
          shift_bytes_int       <= '0';
          datain_int	        <= (others =>'0');
      end case;
    end if;
  end process proc_write;
  
  -- Erase from the thing	
--  proc_erase : process (clk_i,reset_int)
--  begin
--    if (reset_int = '1' ) then
--      wren_erase_int    <= '0';
--      bulk_erase_int    <= '0';
--    elsif(rising_edge(clk_i)) then
--      case fsm is
--        when idle =>
--          wren_erase_int <= '0';
--          bulk_erase_int <= '0';
--        when starterase =>
--          wren_erase_int <= '1';
--          bulk_erase_int <= '1';
--        when doerase =>
--          wren_erase_int <= '1';
--          bulk_erase_int <= '1';
--        when others =>
--          wren_erase_int <= '0';
--          bulk_erase_int <= '0';
--      end case;
--    end if;
--  end process proc_erase;
  
  -- Erase a specific sector	
  proc_serase : process (clk_i,reset_int)
  begin
    if (reset_int = '1' ) then
      wren_serase_int           <= '0';
      sector_erase_int          <= '0';
    elsif(rising_edge(clk_i)) then
      case fsm is
        when idle =>
          wren_serase_int       <= '0';
          sector_erase_int      <= '0';
        when startserase =>
          wren_serase_int       <= '1';
          sector_erase_int      <= '1';
        when doserase =>
          wren_serase_int       <= '1';
          sector_erase_int      <= '1';
        when others =>
          wren_serase_int       <= '0';
          sector_erase_int      <= '0';
      end case;
    end if;
  end process proc_serase;
  
end;
