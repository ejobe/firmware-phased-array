---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         beamform.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         3/2017...
--
-- DESCRIPTION:  first stab at forming beams from the timestream data
--
-----///////////////////////////////////////////////////////////////////
-- !!TODO!! : beams need to be updated since data as progressively deeper 
-- antennas will have +1m fiber length delay. Zero-delay beam will be
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

entity beamform is
	generic(
		ENABLE_BEAMFORMING : std_logic := '1'); --//compile-time flag
	port(
		rst_i			:	in		std_logic;
		clk_i			: 	in		std_logic;
		clk_iface_i	:	in		std_logic;
			
		reg_i			: 	in		register_array_type;
		data_i		:	in	   full_data_type;
		
		beams_4a_o	:	out	array_of_beams_type;   --//beams made w/ 4 antennas, starting with 1st antenna (baseline every other antenna)
		beams_4b_o	:	out	array_of_beams_type;   --//beams made w/ 4 antennas, starting with 2nd antenna (baseline every other antenna)
		beams_8_o	:	out	array_of_beams_type;  --//beams made w/ coherent sums of all 8 antennas (baseline every antenna)
		
		sum_pow_o	:	out	sum_power_type);
		
end beamform;

architecture rtl of beamform is

signal data_pipe			:  full_data_type;
signal buf_data_0 		: 	full_data_type;
signal buf_data_1 		: 	full_data_type;
signal buf_data_2 		: 	full_data_type;
signal buf_data_3 		: 	full_data_type;
signal buf_data_4 		: 	full_data_type;

--//buffer the data 5x every clock cycle --> allows beam-forming +/- the central buffer
type internal_buf_data_type is array (7 downto 0) of std_logic_vector(5*pdat_size-1 downto 0);
					
signal dat : internal_buf_data_type;

--//starting points for slicing 'dat' to form beams
constant slice_base : integer := 2*pdat_size;
constant slice_lo   : integer := define_wave2beam_lo_bit+slice_base;
constant slice_hi   : integer := define_wave2beam_hi_bit+slice_base;

constant zpad	: std_logic := '0';

--// we will form more downward-looking beams than upward
--// since there is a fixed added delay at each next antenna updwards
--//
--// the convention here is 'minus' indicates delaying the upper antennas 
--// relative to the lower (this forms beams looking up). 'Plus' indicates the opposite (beams looking down)
--signal beam_8_m7	:	beam_data_type; --//-7 sample delay beam
signal beam_8_m6	:	beam_data_type; --//-6 sample delay beam
signal beam_8_m5	:	beam_data_type; --//-5 sample delay beam
signal beam_8_m4	:	beam_data_type; --//-4 sample delay beam
signal beam_8_m3	:	beam_data_type; --//-3 sample delay beam
signal beam_8_m2	:	beam_data_type; --//-2 sample delay beam
signal beam_8_m1	:	beam_data_type; --//-1 sample delay beam
signal beam_8_0	:	beam_data_type; --// 0-delay beam
signal beam_8_p1	:	beam_data_type; --//+1 sample delay beam
signal beam_8_p2	:	beam_data_type; --//+2 sample delay beam
signal beam_8_p3	:	beam_data_type; --//+3 sample delay beam
signal beam_8_p4	:	beam_data_type; --//+4 sample delay beam
signal beam_8_p5	:	beam_data_type; --//+5 sample delay beam
signal beam_8_p6	:	beam_data_type; --//+6 sample delay beam
signal beam_8_p7	:	beam_data_type; --//+7 sample delay beam
signal beam_8_p8	:	beam_data_type; --//+7 sample delay beam

--//add odd beams of next-largest baseline to fill in gaps in coverage
signal beam_4a_m11	:	beam_data_type;
signal beam_4a_m9		:	beam_data_type;
signal beam_4a_m7		:	beam_data_type;
signal beam_4a_m5		:	beam_data_type; --//-5 sample delay beam
signal beam_4a_m3		:	beam_data_type; --//-3 sample delay beam
signal beam_4a_m1		:	beam_data_type; --//-1 sample delay beam
signal beam_4a_p1		:	beam_data_type; --//+1 sample delay beam
signal beam_4a_p3		:	beam_data_type; --//+3 sample delay beam
signal beam_4a_p5		:	beam_data_type; --//+5 sample delay beam
signal beam_4a_p7		:	beam_data_type; --//+7 sample delay beam
signal beam_4a_p9		:	beam_data_type;
signal beam_4a_p11	:	beam_data_type;
signal beam_4a_p13	:	beam_data_type;
signal beam_4a_p15	:	beam_data_type;
signal beam_4a_p17	:	beam_data_type;

signal beam_4b_m11	:	beam_data_type;
signal beam_4b_m9		:	beam_data_type;
signal beam_4b_m7		:	beam_data_type;
signal beam_4b_m5		:	beam_data_type; --//-5 sample delay beam
signal beam_4b_m3		:	beam_data_type; --//-3 sample delay beam
signal beam_4b_m1		:	beam_data_type; --//-1 sample delay beam
signal beam_4b_p1		:	beam_data_type; --//+1 sample delay beam
signal beam_4b_p3		:	beam_data_type; --//+3 sample delay beam
signal beam_4b_p5		:	beam_data_type; --//+5 sample delay beam
signal beam_4b_p7		:	beam_data_type; --//+7 sample delay beam
signal beam_4b_p9		:	beam_data_type;
signal beam_4b_p11	:	beam_data_type;
signal beam_4b_p13	:	beam_data_type;
signal beam_4b_p15	:	beam_data_type;
signal beam_4b_p17	:	beam_data_type;

signal internal_beams_8 		: array_of_beams_type;
signal internal_beams_8_pipe	: array_of_beams_type;

signal internal_beams_4a 		: array_of_beams_type;
signal internal_beams_4a_pipe	: array_of_beams_type;

signal internal_beams_4b 		: array_of_beams_type;
signal internal_beams_4b_pipe	: array_of_beams_type;

signal internal_summed_power_8	:	sum_power_type;
signal internal_summed_power_4a	:	sum_power_type;
signal internal_summed_power_4b	:	sum_power_type;

signal internal_beam8_enable 			: std_logic := '0';
signal internal_beam4a_enable 		: std_logic := '0';
signal internal_beam4b_enable 		: std_logic := '0';
--//
component signal_sync is
port(
	clkA			: in	std_logic;
   clkB			: in	std_logic;
   SignalIn_clkA	: in	std_logic;
   SignalOut_clkB	: out	std_logic);
end component;
--//
begin
----------------------------------------------
xBEAM8ENABLE : signal_sync
port map(
	clkA				=> clk_iface_i,
	clkB				=> clk_i,
	SignalIn_clkA	=> reg_i(82)(2), 
	SignalOut_clkB	=> internal_beam8_enable);
xBEAM4AENABLE : signal_sync
port map(
	clkA				=> clk_iface_i,
	clkB				=> clk_i,
	SignalIn_clkA	=> reg_i(82)(3), 
	SignalOut_clkB	=> internal_beam4a_enable);
xBEAM4BENABLE : signal_sync
port map(
	clkA				=> clk_iface_i,
	clkB				=> clk_i,
	SignalIn_clkA	=> reg_i(82)(4), 
	SignalOut_clkB	=> internal_beam4b_enable);
--------------------------------------------
proc_buffer_data : process(rst_i, clk_i)
begin
	for i in 0 to 7 loop
		
		if rst_i = '1' or ENABLE_BEAMFORMING = '0' then
			buf_data_0(i)<= (others=>'0');
			buf_data_1(i)<= (others=>'0');
			buf_data_2(i)<= (others=>'0');
			buf_data_3(i)<= (others=>'0');		
			buf_data_4(i)<= (others=>'0');		
			data_pipe(i) <= (others=>'0');
			
			dat(i) <= (others=>'0');
			
		elsif rising_edge(clk_i) then
		
			dat(i) <= buf_data_0(i) & buf_data_1(i) & buf_data_2(i) & buf_data_3(i) & buf_data_4(i);	

			buf_data_4(i) <= buf_data_3(i);
			buf_data_3(i) <= buf_data_2(i);
			buf_data_2(i) <= buf_data_1(i);
			buf_data_1(i) <= buf_data_0(i);			
			buf_data_0(i) <= data_pipe(i);		
			data_pipe(i)  <= data_i(i);

		end if;
	end loop;
end process;

--//pipeline beams to output
proc_pipe_beams : process(rst_i, clk_i, internal_beam4a_enable, internal_beam4b_enable, internal_beam8_enable)
begin
	for i in 0 to define_num_beams-1 loop
		if rst_i = '1' or ENABLE_BEAMFORMING = '0' then
			internal_beams_8_pipe(i) <= (others=>'0');
			beams_8_o(i) <= (others=>'0');
			
			internal_beams_4a_pipe(i) <= (others=>'0');
			internal_beams_4b_pipe(i) <= (others=>'0');
			beams_4a_o(i) <= (others=>'0');
			beams_4b_o(i) <= (others=>'0');
			
			--//output beam power
			sum_pow_o(i) <= (others=>'0');
			
		elsif rising_edge(clk_i) then
			beams_8_o(i) <= internal_beams_8_pipe(i);
			beams_4a_o(i) <= internal_beams_4a_pipe(i);
			beams_4b_o(i) <= internal_beams_4b_pipe(i);
			--------------------------------------------------------
			if internal_beam8_enable = '1' then
				internal_beams_8_pipe(i) <= internal_beams_8(i);
			else
				internal_beams_8_pipe(i) <= (others=>'0');
			end if;
			--------------------------------------------------------
			if internal_beam4a_enable = '1' then
				internal_beams_4a_pipe(i) <= internal_beams_4a(i);
			else
				internal_beams_4a_pipe(i) <= (others=>'0');
			end if;
			--------------------------------------------------------
			if internal_beam4b_enable = '1' then
				internal_beams_4b_pipe(i) <= internal_beams_4b(i);
			else
				internal_beams_4b_pipe(i) <= (others=>'0');
			end if;
			--------------------------------------------------------
			--//output beam power. make effective beam using different baselines - for power-thresholding
			sum_pow_o(i) <= 	std_logic_vector(unsigned(internal_summed_power_8(i))) +
									std_logic_vector(unsigned(internal_summed_power_4a(i))) +
									std_logic_vector(unsigned(internal_summed_power_4b(i)));
		end if;
	end loop;
end process;
		
proc_delay_and_sum : process(rst_i, clk_i)
begin
	--//loop over individual samples
	for i in 0 to 2*define_serdes_factor-1 loop
	
		if rst_i = '1' or ENABLE_BEAMFORMING = '0' then
		
--			beam_8_m7(i) 	<= (others=>'0');
			beam_8_m6(i) 	<= (others=>'0');
			beam_8_m5(i) 	<= (others=>'0');
			beam_8_m4(i) 	<= (others=>'0');
			beam_8_m3(i) 	<= (others=>'0');
			beam_8_m2(i) 	<= (others=>'0');
			beam_8_m1(i) 	<= (others=>'0');
			beam_8_0(i) 	<= (others=>'0');
			beam_8_p1(i) 	<= (others=>'0');
			beam_8_p2(i) 	<= (others=>'0');
			beam_8_p3(i) 	<= (others=>'0');
			beam_8_p4(i) 	<= (others=>'0');
			beam_8_p5(i) 	<= (others=>'0');
			beam_8_p6(i) 	<= (others=>'0');
			beam_8_p7(i) 	<= (others=>'0');
			beam_8_p8(i) 	<= (others=>'0');
			
			beam_4a_m11(i)	<= (others=>'0');
			beam_4a_m9(i)	<= (others=>'0');
			beam_4a_m7(i)	<= (others=>'0');
			beam_4a_m5(i)	<= (others=>'0');
			beam_4a_m3(i)	<= (others=>'0');
			beam_4a_m1(i)	<= (others=>'0');
			beam_4a_p1(i)	<= (others=>'0');
			beam_4a_p3(i)	<= (others=>'0');
			beam_4a_p5(i)	<= (others=>'0');
			beam_4a_p7(i)	<= (others=>'0');
			beam_4a_p9(i)	<= (others=>'0');
			beam_4a_p11(i)	<= (others=>'0');
			beam_4a_p13(i)	<= (others=>'0');
			beam_4a_p15(i)	<= (others=>'0');
			beam_4a_p17(i)	<= (others=>'0');

			beam_4b_m11(i)	<= (others=>'0');
			beam_4b_m9(i)	<= (others=>'0');
			beam_4b_m7(i)	<= (others=>'0');
			beam_4b_m5(i)	<= (others=>'0');
			beam_4b_m3(i)	<= (others=>'0');
			beam_4b_m1(i)	<= (others=>'0');
			beam_4b_p1(i)	<= (others=>'0');
			beam_4b_p3(i)	<= (others=>'0');
			beam_4b_p5(i)	<= (others=>'0');
			beam_4b_p7(i)	<= (others=>'0');
			beam_4b_p9(i)	<= (others=>'0');
			beam_4b_p11(i)	<= (others=>'0');
			beam_4b_p13(i)	<= (others=>'0');
			beam_4b_p15(i)	<= (others=>'0');
			beam_4b_p17(i)	<= (others=>'0');
		
			for k in 0 to define_num_beams-1 loop
				internal_beams_8(k)((i+1)*define_beam_bits-1 downto i*define_beam_bits) <= (others=>'0');
				internal_beams_4a(k)((i+1)*define_beam_bits-1 downto i*define_beam_bits) <= (others=>'0');
				internal_beams_4a(k)((i+1)*define_beam_bits-1 downto i*define_beam_bits) <= (others=>'0');
			end loop;
			
		elsif rising_edge(clk_i) then
									
--			internal_beams(0)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m7(i);
--			internal_beams(1)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m6(i);
--			internal_beams(2)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m5(i);
--			internal_beams(3)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m4(i);
--			internal_beams(4)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m3(i);
--			internal_beams(5)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m2(i);
--			internal_beams(6)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m1(i);
--			internal_beams(7)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_0(i);
--			internal_beams(8)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p1(i);
--			internal_beams(9)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p2(i);
--			internal_beams(10)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p3(i);
--			internal_beams(11)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p4(i);
--			internal_beams(12)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p5(i);
--			internal_beams(13)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p6(i);
--			internal_beams(14)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p7(i);

			internal_beams_8(0)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m6(i);
			internal_beams_8(1)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m5(i);
			internal_beams_8(2)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m4(i);
			internal_beams_8(3)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m3(i);
			internal_beams_8(4)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m2(i);
			internal_beams_8(5)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m1(i);
			internal_beams_8(6)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_0(i);
			internal_beams_8(7)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p1(i);
			internal_beams_8(8)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p2(i);
			internal_beams_8(9)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p3(i);
			internal_beams_8(10)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p4(i);
			internal_beams_8(11)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p5(i);
			internal_beams_8(12)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p6(i);
			internal_beams_8(13)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p7(i);
			internal_beams_8(14)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p8(i);
			
			internal_beams_4a(0)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4a_m11(i);
			internal_beams_4a(1)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4a_m9(i);
			internal_beams_4a(2)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4a_m7(i);
			internal_beams_4a(3)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4a_m5(i);
			internal_beams_4a(4)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4a_m3(i);
			internal_beams_4a(5)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4a_m1(i);
			internal_beams_4a(6)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4a_p1(i);
			internal_beams_4a(7)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4a_p3(i);
			internal_beams_4a(8)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4a_p5(i);
			internal_beams_4a(9)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4a_p7(i);
			internal_beams_4a(10)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4a_p9(i);
			internal_beams_4a(11)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4a_p11(i);
			internal_beams_4a(12)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4a_p13(i);
			internal_beams_4a(13)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4a_p15(i);
			internal_beams_4a(14)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4a_p17(i);
			
			internal_beams_4b(0)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4b_m11(i);
			internal_beams_4b(1)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4b_m9(i);
			internal_beams_4b(2)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4b_m7(i);
			internal_beams_4b(3)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4b_m5(i);
			internal_beams_4b(4)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4b_m3(i);
			internal_beams_4b(5)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4b_m1(i);
			internal_beams_4b(6)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4b_p1(i);
			internal_beams_4b(7)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4b_p3(i);
			internal_beams_4b(8)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4b_p5(i);
			internal_beams_4b(9)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4b_p7(i);
			internal_beams_4b(10)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4b_p9(i);
			internal_beams_4b(11)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4b_p11(i);
			internal_beams_4b(12)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4b_p13(i);
			internal_beams_4b(13)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4b_p15(i);
			internal_beams_4b(14)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_4b_p17(i);		
			
			--/////////////////////////////////////
			--// Delay-and-Sum here:
			--///////////////////////////////////
			--// resize data chunks from ADC before adding in order to get proper sign extension
			--///////////////////////////////////////////////////////////////////////////////////
			--// NOTE: we will have fixed time offsets between channels:
			--//       lowest antenna will have +1m extra fiber more than the next-lowest, and so on...
			--//   So, at 0-degree incidence, the relative delays in the recorded data will appear as if 
			--//       the wave came from above (bottom antennas delayed relative to the upper antennas)
			--//      
			--// 
			
			beam_8_0(i) <= --//8 antenna, 0 delay
				std_logic_vector(resize(signed(dat(0)(i*define_word_size+slice_hi-1 downto i*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(1)(i*define_word_size+slice_hi-1 downto i*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)(i*define_word_size+slice_hi-1 downto i*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)(i*define_word_size+slice_hi-1 downto i*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)(i*define_word_size+slice_hi-1 downto i*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)(i*define_word_size+slice_hi-1 downto i*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)(i*define_word_size+slice_hi-1 downto i*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)(i*define_word_size+slice_hi-1 downto i*define_word_size+slice_lo )),define_beam_bits));
			
			beam_8_m1(i) <= --//8 antenna, -1 delay
				std_logic_vector(resize(signed(dat(0)((i-4)*define_word_size+slice_hi-1 downto (i-4)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(1)((i-3)*define_word_size+slice_hi-1 downto (i-3)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i-2)*define_word_size+slice_hi-1 downto (i-2)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i-1)*define_word_size+slice_hi-1 downto (i-1)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i+1)*define_word_size+slice_hi-1 downto (i+1)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i+2)*define_word_size+slice_hi-1 downto (i+2)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i+3)*define_word_size+slice_hi-1 downto (i+3)*define_word_size+slice_lo )),define_beam_bits));		

			beam_8_p1(i) <= --//8 antenna, +1 delay
				std_logic_vector(resize(signed(dat(0)((i+4)*define_word_size+slice_hi-1 downto (i+4)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(1)((i+3)*define_word_size+slice_hi-1 downto (i+3)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+2)*define_word_size+slice_hi-1 downto (i+2)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+1)*define_word_size+slice_hi-1 downto (i+1)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-1)*define_word_size+slice_hi-1 downto (i-1)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-2)*define_word_size+slice_hi-1 downto (i-2)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-3)*define_word_size+slice_hi-1 downto (i-3)*define_word_size+slice_lo )),define_beam_bits));		

			beam_8_m2(i) <= --//8 antenna, -2 delay
				std_logic_vector(resize(signed(dat(0)((i-8)*define_word_size+slice_hi-1 downto (i-8)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(1)((i-6)*define_word_size+slice_hi-1 downto (i-6)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i-4)*define_word_size+slice_hi-1 downto (i-4)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i-2)*define_word_size+slice_hi-1 downto (i-2)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i+2)*define_word_size+slice_hi-1 downto (i+2)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i+4)*define_word_size+slice_hi-1 downto (i+4)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i+6)*define_word_size+slice_hi-1 downto (i+6)*define_word_size+slice_lo )),define_beam_bits));		

			beam_8_p2(i) <= --//8 antenna, +2 delay
				std_logic_vector(resize(signed(dat(0)((i+8)*define_word_size+slice_hi-1 downto (i+8)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(1)((i+6)*define_word_size+slice_hi-1 downto (i+6)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+4)*define_word_size+slice_hi-1 downto (i+4)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+2)*define_word_size+slice_hi-1 downto (i+2)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-2)*define_word_size+slice_hi-1 downto (i-2)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-4)*define_word_size+slice_hi-1 downto (i-4)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-6)*define_word_size+slice_hi-1 downto (i-6)*define_word_size+slice_lo )),define_beam_bits));		

			beam_8_m3(i) <= --//8 antenna, -3 delay
				std_logic_vector(resize(signed(dat(0)((i-12)*define_word_size+slice_hi-1 downto (i-12)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(1)((i-9)*define_word_size+slice_hi-1 downto (i-9)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i-6)*define_word_size+slice_hi-1 downto (i-6)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i-3)*define_word_size+slice_hi-1 downto (i-3)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i+3)*define_word_size+slice_hi-1 downto (i+3)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i+6)*define_word_size+slice_hi-1 downto (i+6)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i+9)*define_word_size+slice_hi-1 downto (i+9)*define_word_size+slice_lo )),define_beam_bits));		

			beam_8_p3(i) <= --//8 antenna, +3 delay
				std_logic_vector(resize(signed(dat(0)((i+12)*define_word_size+slice_hi-1 downto (i+12)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(1)((i+9)*define_word_size+slice_hi-1 downto (i+9)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+6)*define_word_size+slice_hi-1 downto (i+6)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+3)*define_word_size+slice_hi-1 downto (i+3)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-3)*define_word_size+slice_hi-1 downto (i-3)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-6)*define_word_size+slice_hi-1 downto (i-6)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-9)*define_word_size+slice_hi-1 downto (i-9)*define_word_size+slice_lo )),define_beam_bits));		

			beam_8_m4(i) <= --//8 antenna, -4 delay
				std_logic_vector(resize(signed(dat(0)((i-16)*define_word_size+slice_hi-1 downto (i-16)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(1)((i-12)*define_word_size+slice_hi-1 downto (i-12)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i-8)*define_word_size+slice_hi-1 downto (i-8)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i-4)*define_word_size+slice_hi-1 downto (i-4)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i+4)*define_word_size+slice_hi-1 downto (i+4)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i+8)*define_word_size+slice_hi-1 downto (i+8)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i+12)*define_word_size+slice_hi-1 downto (i+12)*define_word_size+slice_lo )),define_beam_bits));		

			beam_8_p4(i) <= --//8 antenna, +4 delay
				std_logic_vector(resize(signed(dat(0)((i+16)*define_word_size+slice_hi-1 downto (i+16)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(1)((i+12)*define_word_size+slice_hi-1 downto (i+12)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+8)*define_word_size+slice_hi-1 downto (i+8)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+4)*define_word_size+slice_hi-1 downto (i+4)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-4)*define_word_size+slice_hi-1 downto (i-4)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-8)*define_word_size+slice_hi-1 downto (i-8)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-12)*define_word_size+slice_hi-1 downto (i-12)*define_word_size+slice_lo )),define_beam_bits));		
					
			beam_8_m5(i) <= --//8 antenna, -5 delay
				std_logic_vector(resize(signed(dat(0)((i-20)*define_word_size+slice_hi-1 downto (i-20)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(1)((i-15)*define_word_size+slice_hi-1 downto (i-15)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i-10)*define_word_size+slice_hi-1 downto (i-10)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i-5)*define_word_size+slice_hi-1 downto (i-5)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i+5)*define_word_size+slice_hi-1 downto (i+5)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i+10)*define_word_size+slice_hi-1 downto (i+10)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i+15)*define_word_size+slice_hi-1 downto (i+15)*define_word_size+slice_lo )),define_beam_bits));		

			beam_8_p5(i) <= --//8 antenna, +5 delay
				std_logic_vector(resize(signed(dat(0)((i+20)*define_word_size+slice_hi-1 downto (i+20)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(1)((i+15)*define_word_size+slice_hi-1 downto (i+15)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+10)*define_word_size+slice_hi-1 downto (i+10)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+5)*define_word_size+slice_hi-1 downto (i+5)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-5)*define_word_size+slice_hi-1 downto (i-5)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-10)*define_word_size+slice_hi-1 downto (i-10)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-15)*define_word_size+slice_hi-1 downto (i-15)*define_word_size+slice_lo )),define_beam_bits));		
			
			beam_8_m6(i) <= --//8 antenna, -6 delay
				std_logic_vector(resize(signed(dat(0)((i-24)*define_word_size+slice_hi-1 downto (i-24)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(1)((i-18)*define_word_size+slice_hi-1 downto (i-18)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i-12)*define_word_size+slice_hi-1 downto (i-12)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i-6)*define_word_size+slice_hi-1 downto (i-6)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i+6)*define_word_size+slice_hi-1 downto (i+6)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i+12)*define_word_size+slice_hi-1 downto (i+12)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i+18)*define_word_size+slice_hi-1 downto (i+18)*define_word_size+slice_lo )),define_beam_bits));		

			beam_8_p6(i) <= --//8 antenna, +6 delay
				std_logic_vector(resize(signed(dat(0)((i+24)*define_word_size+slice_hi-1 downto (i+24)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(1)((i+18)*define_word_size+slice_hi-1 downto (i+18)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+12)*define_word_size+slice_hi-1 downto (i+12)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+6)*define_word_size+slice_hi-1 downto (i+6)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-6)*define_word_size+slice_hi-1 downto (i-6)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-12)*define_word_size+slice_hi-1 downto (i-12)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-18)*define_word_size+slice_hi-1 downto (i-18)*define_word_size+slice_lo )),define_beam_bits));		

--			beam_8_m7(i) <= --//8 antenna, -7 delay
--				std_logic_vector(resize(signed(dat(0)((i-28)*define_word_size+slice_hi-1 downto (i-28)*define_word_size+slice_lo )),define_beam_bits)) +
--				std_logic_vector(resize(signed(dat(1)((i-21)*define_word_size+slice_hi-1 downto (i-21)*define_word_size+slice_lo )),define_beam_bits)) +
--				std_logic_vector(resize(signed(dat(2)((i-14)*define_word_size+slice_hi-1 downto (i-14)*define_word_size+slice_lo )),define_beam_bits)) +
--				std_logic_vector(resize(signed(dat(3)((i-7)*define_word_size+slice_hi-1 downto (i-7)*define_word_size+slice_lo )),define_beam_bits)) +
--				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
--				std_logic_vector(resize(signed(dat(5)((i+7)*define_word_size+slice_hi-1 downto (i+7)*define_word_size+slice_lo )),define_beam_bits)) +
--				std_logic_vector(resize(signed(dat(6)((i+14)*define_word_size+slice_hi-1 downto (i+14)*define_word_size+slice_lo )),define_beam_bits)) +
--				std_logic_vector(resize(signed(dat(7)((i+21)*define_word_size+slice_hi-1 downto (i+21)*define_word_size+slice_lo )),define_beam_bits));							

			beam_8_p7(i) <= --//8 antenna, +7 delay
				std_logic_vector(resize(signed(dat(0)((i+28)*define_word_size+slice_hi-1 downto (i+28)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(1)((i+21)*define_word_size+slice_hi-1 downto (i+21)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+14)*define_word_size+slice_hi-1 downto (i+14)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+7)*define_word_size+slice_hi-1 downto (i+7)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-7)*define_word_size+slice_hi-1 downto (i-7)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-14)*define_word_size+slice_hi-1 downto (i-14)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-21)*define_word_size+slice_hi-1 downto (i-21)*define_word_size+slice_lo )),define_beam_bits));	
				
			beam_8_p8(i) <= --//8 antenna, +8 delay
				std_logic_vector(resize(signed(dat(0)((i+32)*define_word_size+slice_hi-1 downto (i+32)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(1)((i+24)*define_word_size+slice_hi-1 downto (i+24)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+16)*define_word_size+slice_hi-1 downto (i+16)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+8)*define_word_size+slice_hi-1 downto (i+8)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-8)*define_word_size+slice_hi-1 downto (i-8)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-16)*define_word_size+slice_hi-1 downto (i-16)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-24)*define_word_size+slice_hi-1 downto (i-24)*define_word_size+slice_lo )),define_beam_bits));	

				
			--//////////////////////////////////////////////////////////////////////////////////////	
			--//next-largest baseline (every-other antenna)
			beam_4a_p17(i) <= 
				std_logic_vector(resize(signed(dat(0)((i+29)*define_word_size+slice_hi-1 downto (i+29)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+12)*define_word_size+slice_hi-1 downto (i+12)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-5)*define_word_size+slice_hi-1 downto (i-5)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-22)*define_word_size+slice_hi-1 downto (i-22)*define_word_size+slice_lo )),define_beam_bits));
			beam_4b_p17(i) <= 
				std_logic_vector(resize(signed(dat(1)((i+29)*define_word_size+slice_hi-1 downto (i+29)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+12)*define_word_size+slice_hi-1 downto (i+12)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-5)*define_word_size+slice_hi-1 downto (i-5)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-22)*define_word_size+slice_hi-1 downto (i-22)*define_word_size+slice_lo )),define_beam_bits));
				
			beam_4a_p15(i) <=
				std_logic_vector(resize(signed(dat(0)((i+30)*define_word_size+slice_hi-1 downto (i+30)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+15)*define_word_size+slice_hi-1 downto (i+15)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-15)*define_word_size+slice_hi-1 downto (i-15)*define_word_size+slice_lo )),define_beam_bits));
			beam_4b_p15(i) <=
				std_logic_vector(resize(signed(dat(1)((i+30)*define_word_size+slice_hi-1 downto (i+30)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+15)*define_word_size+slice_hi-1 downto (i+15)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-15)*define_word_size+slice_hi-1 downto (i-15)*define_word_size+slice_lo )),define_beam_bits));	
				
			beam_4a_p13(i) <=
				std_logic_vector(resize(signed(dat(0)((i+26)*define_word_size+slice_hi-1 downto (i+26)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+13)*define_word_size+slice_hi-1 downto (i+13)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-13)*define_word_size+slice_hi-1 downto (i-13)*define_word_size+slice_lo )),define_beam_bits));
			beam_4b_p13(i) <=
				std_logic_vector(resize(signed(dat(1)((i+26)*define_word_size+slice_hi-1 downto (i+26)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+13)*define_word_size+slice_hi-1 downto (i+13)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-13)*define_word_size+slice_hi-1 downto (i-13)*define_word_size+slice_lo )),define_beam_bits));
				
			beam_4a_p11(i) <=
				std_logic_vector(resize(signed(dat(0)((i+22)*define_word_size+slice_hi-1 downto (i+22)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+11)*define_word_size+slice_hi-1 downto (i+11)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-11)*define_word_size+slice_hi-1 downto (i-11)*define_word_size+slice_lo )),define_beam_bits));
			beam_4b_p11(i) <=
				std_logic_vector(resize(signed(dat(1)((i+22)*define_word_size+slice_hi-1 downto (i+22)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+11)*define_word_size+slice_hi-1 downto (i+11)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-11)*define_word_size+slice_hi-1 downto (i-11)*define_word_size+slice_lo )),define_beam_bits));	
				
			beam_4a_p9(i) <=
				std_logic_vector(resize(signed(dat(0)((i+18)*define_word_size+slice_hi-1 downto (i+18)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+9)*define_word_size+slice_hi-1 downto (i+9)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-9)*define_word_size+slice_hi-1 downto (i-9)*define_word_size+slice_lo )),define_beam_bits));
			beam_4b_p9(i) <=
				std_logic_vector(resize(signed(dat(1)((i+18)*define_word_size+slice_hi-1 downto (i+18)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+9)*define_word_size+slice_hi-1 downto (i+9)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-9)*define_word_size+slice_hi-1 downto (i-9)*define_word_size+slice_lo )),define_beam_bits));
			
			beam_4a_p7(i) <=
				std_logic_vector(resize(signed(dat(0)((i+14)*define_word_size+slice_hi-1 downto (i+14)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+7)*define_word_size+slice_hi-1 downto (i+7)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-7)*define_word_size+slice_hi-1 downto (i-7)*define_word_size+slice_lo )),define_beam_bits));
			beam_4b_p7(i) <=
				std_logic_vector(resize(signed(dat(1)((i+14)*define_word_size+slice_hi-1 downto (i+14)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+7)*define_word_size+slice_hi-1 downto (i+7)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-7)*define_word_size+slice_hi-1 downto (i-7)*define_word_size+slice_lo )),define_beam_bits));
			
			beam_4a_p5(i) <=
				std_logic_vector(resize(signed(dat(0)((i+10)*define_word_size+slice_hi-1 downto (i+10)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+5)*define_word_size+slice_hi-1 downto (i+5)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-5)*define_word_size+slice_hi-1 downto (i-5)*define_word_size+slice_lo )),define_beam_bits));
			beam_4b_p5(i) <=
				std_logic_vector(resize(signed(dat(1)((i+10)*define_word_size+slice_hi-1 downto (i+10)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+5)*define_word_size+slice_hi-1 downto (i+5)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-5)*define_word_size+slice_hi-1 downto (i-5)*define_word_size+slice_lo )),define_beam_bits));				
			
			beam_4a_p3(i) <=
				std_logic_vector(resize(signed(dat(0)((i+6)*define_word_size+slice_hi-1 downto (i+6)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+3)*define_word_size+slice_hi-1 downto (i+3)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-3)*define_word_size+slice_hi-1 downto (i-3)*define_word_size+slice_lo )),define_beam_bits));
			beam_4b_p3(i) <=
				std_logic_vector(resize(signed(dat(1)((i+6)*define_word_size+slice_hi-1 downto (i+6)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+3)*define_word_size+slice_hi-1 downto (i+3)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-3)*define_word_size+slice_hi-1 downto (i-3)*define_word_size+slice_lo )),define_beam_bits));
				
			beam_4a_p1(i) <=
				std_logic_vector(resize(signed(dat(0)((i+2)*define_word_size+slice_hi-1 downto (i+2)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i+1)*define_word_size+slice_hi-1 downto (i+1)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i-1)*define_word_size+slice_hi-1 downto (i-1)*define_word_size+slice_lo )),define_beam_bits));
			beam_4b_p1(i) <=
				std_logic_vector(resize(signed(dat(1)((i+2)*define_word_size+slice_hi-1 downto (i+2)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i+1)*define_word_size+slice_hi-1 downto (i+1)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i-1)*define_word_size+slice_hi-1 downto (i-1)*define_word_size+slice_lo )),define_beam_bits));
				
			beam_4a_m1(i) <=
				std_logic_vector(resize(signed(dat(0)((i-2)*define_word_size+slice_hi-1 downto (i-2)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i-1)*define_word_size+slice_hi-1 downto (i-1)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i+1)*define_word_size+slice_hi-1 downto (i+1)*define_word_size+slice_lo )),define_beam_bits));			
			beam_4b_m1(i) <=
				std_logic_vector(resize(signed(dat(1)((i-2)*define_word_size+slice_hi-1 downto (i-2)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i-1)*define_word_size+slice_hi-1 downto (i-1)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i+1)*define_word_size+slice_hi-1 downto (i+1)*define_word_size+slice_lo )),define_beam_bits));					
			
			beam_4a_m3(i) <=
				std_logic_vector(resize(signed(dat(0)((i-6)*define_word_size+slice_hi-1 downto (i-6)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i-3)*define_word_size+slice_hi-1 downto (i-3)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i+3)*define_word_size+slice_hi-1 downto (i+3)*define_word_size+slice_lo )),define_beam_bits));		
			beam_4b_m3(i) <=
				std_logic_vector(resize(signed(dat(1)((i-6)*define_word_size+slice_hi-1 downto (i-6)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i-3)*define_word_size+slice_hi-1 downto (i-3)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i+3)*define_word_size+slice_hi-1 downto (i+3)*define_word_size+slice_lo )),define_beam_bits));	
				
			beam_4a_m5(i) <=
				std_logic_vector(resize(signed(dat(0)((i-10)*define_word_size+slice_hi-1 downto (i-10)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i-5)*define_word_size+slice_hi-1 downto (i-5)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i+5)*define_word_size+slice_hi-1 downto (i+5)*define_word_size+slice_lo )),define_beam_bits));				
			beam_4b_m5(i) <=
				std_logic_vector(resize(signed(dat(1)((i-10)*define_word_size+slice_hi-1 downto (i-10)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i-5)*define_word_size+slice_hi-1 downto (i-5)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i+5)*define_word_size+slice_hi-1 downto (i+5)*define_word_size+slice_lo )),define_beam_bits));	
				
			beam_4a_m7(i) <=
				std_logic_vector(resize(signed(dat(0)((i-14)*define_word_size+slice_hi-1 downto (i-14)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i-7)*define_word_size+slice_hi-1 downto (i-7)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i+7)*define_word_size+slice_hi-1 downto (i+7)*define_word_size+slice_lo )),define_beam_bits));
			beam_4b_m7(i) <=
				std_logic_vector(resize(signed(dat(1)((i-14)*define_word_size+slice_hi-1 downto (i-14)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i-7)*define_word_size+slice_hi-1 downto (i-7)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i+7)*define_word_size+slice_hi-1 downto (i+7)*define_word_size+slice_lo )),define_beam_bits));

			beam_4a_m9(i) <=
				std_logic_vector(resize(signed(dat(0)((i-18)*define_word_size+slice_hi-1 downto (i-18)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i-9)*define_word_size+slice_hi-1 downto (i-9)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i+9)*define_word_size+slice_hi-1 downto (i+9)*define_word_size+slice_lo )),define_beam_bits));				
			beam_4b_m9(i) <=
				std_logic_vector(resize(signed(dat(1)((i-18)*define_word_size+slice_hi-1 downto (i-18)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i-9)*define_word_size+slice_hi-1 downto (i-9)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i+9)*define_word_size+slice_hi-1 downto (i+9)*define_word_size+slice_lo )),define_beam_bits));				
				
			beam_4a_m11(i) <=
				std_logic_vector(resize(signed(dat(0)((i-22)*define_word_size+slice_hi-1 downto (i-22)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(2)((i-11)*define_word_size+slice_hi-1 downto (i-11)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(4)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(6)((i+11)*define_word_size+slice_hi-1 downto (i+11)*define_word_size+slice_lo )),define_beam_bits));			
			beam_4b_m11(i) <=
				std_logic_vector(resize(signed(dat(1)((i-22)*define_word_size+slice_hi-1 downto (i-22)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(3)((i-11)*define_word_size+slice_hi-1 downto (i-11)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(5)((i-0)*define_word_size+slice_hi-1 downto (i-0)*define_word_size+slice_lo )),define_beam_bits)) +
				std_logic_vector(resize(signed(dat(7)((i+11)*define_word_size+slice_hi-1 downto (i+11)*define_word_size+slice_lo )),define_beam_bits));
				
		end if;
	end loop;
end process;
	
xPOWER_SUM_8 : entity work.power_detector
	port map(
		rst_i  	=> rst_i or (not ENABLE_BEAMFORMING),
		clk_i	 	=> clk_i,
		reg_i		=> reg_i,
		beams_i	=> internal_beams_8_pipe,
		sum_pow_o=> internal_summed_power_8);
		
xPOWER_SUM_4a : entity work.power_detector
	port map(
		rst_i  	=> rst_i or (not ENABLE_BEAMFORMING),
		clk_i	 	=> clk_i,
		reg_i		=> reg_i,
		beams_i	=> internal_beams_4a_pipe,
		sum_pow_o=> internal_summed_power_4a);
		
xPOWER_SUM_4b : entity work.power_detector
	port map(
		rst_i  	=> rst_i or (not ENABLE_BEAMFORMING),
		clk_i	 	=> clk_i,
		reg_i		=> reg_i,
		beams_i	=> internal_beams_4b_pipe,
		sum_pow_o=> internal_summed_power_4b);

--//calculate power

end rtl;
		
		