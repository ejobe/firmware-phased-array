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
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.defs.all;
use work.register_map.all;

entity beamform is
	port(
		rst_i			:	in		std_logic;
		clk_i			: 	in		std_logic;
			
		reg_i			: 	in		register_array_type;
		data_i		:	in	   full_data_type;
		
		beams_8_o	:	out	array_of_beams_type);
		
end beamform;

architecture rtl of beamform is

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

signal beam_8_m4	:	beam_data_type; --//-4 sample delay beam
signal beam_8_m3	:	beam_data_type; --//-3 sample delay beam
signal beam_8_m2	:	beam_data_type; --//-2 sample delay beam
signal beam_8_m1	:	beam_data_type; --//-1 sample delay beam
signal beam_8_0	:	beam_data_type; --// 0-delay beam
signal beam_8_p1	:	beam_data_type; --//+1 sample delay beam
signal beam_8_p2	:	beam_data_type; --//+2 sample delay beam
signal beam_8_p3	:	beam_data_type; --//+3 sample delay beam
signal beam_8_p4	:	beam_data_type; --//+4 sample delay beam

signal internal_beams 		: array_of_beams_type;
signal internal_beams_pipe	: array_of_beams_type;

--//
begin

proc_buffer_data : process(rst_i, clk_i)
begin
	for i in 0 to 7 loop
		
		if rst_i = '1' then
			buf_data_0(i)<= (others=>'0');
			buf_data_1(i)<= (others=>'0');
			buf_data_2(i)<= (others=>'0');
			buf_data_3(i)<= (others=>'0');		
			buf_data_4(i)<= (others=>'0');		

			dat(i) <= (others=>'0');
			
		elsif rising_edge(clk_i) then
		
			dat(i) <= buf_data_0(i) & buf_data_1(i) & buf_data_2(i) & buf_data_3(i) & buf_data_4(i);	

			buf_data_4(i) <= buf_data_3(i);
			buf_data_3(i) <= buf_data_2(i);
			buf_data_2(i) <= buf_data_1(i);
			buf_data_1(i) <= buf_data_0(i);			
			buf_data_0(i) <= data_i(i);			

		end if;
	end loop;
end process;

--//pipeline beams to output
proc_pipe_beams : process(rst_i, clk_i)
begin
	for i in 0 to define_num_beams-1 loop
		if rst_i = '1' then
			internal_beams_pipe(i) <= (others=>'0');
			beams_8_o(i) <= (others=>'0');
		elsif rising_edge(clk_i) then
			beams_8_o(i) <= internal_beams_pipe(i);
			internal_beams_pipe(i) <= internal_beams(i);
		end if;
	end loop;
end process;
		
proc_delay_and_sum : process(rst_i, clk_i)
begin
	--//loop over individual samples
	for i in 0 to 2*define_serdes_factor-1 loop
	
		if rst_i = '1' then
			beam_8_m4(i) 	<= (others=>'0');
			beam_8_m3(i) 	<= (others=>'0');
			beam_8_m2(i) 	<= (others=>'0');
			beam_8_m1(i) 	<= (others=>'0');
			beam_8_0(i) 	<= (others=>'0');
			beam_8_p1(i) 	<= (others=>'0');
			beam_8_p2(i) 	<= (others=>'0');
			beam_8_p3(i) 	<= (others=>'0');
			beam_8_p4(i) 	<= (others=>'0');
			
			for k in 0 to define_num_beams-1 loop
				internal_beams(k)((i+1)*define_beam_bits-1 downto i*define_beam_bits) <= (others=>'0');
			end loop;

		elsif rising_edge(clk_i) then
		
			internal_beams(0)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m4(i);
			internal_beams(1)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m3(i);
			internal_beams(2)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m2(i);
			internal_beams(3)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_m1(i);
			internal_beams(4)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_0(i);
			internal_beams(5)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p1(i);
			internal_beams(6)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p2(i);
			internal_beams(7)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p3(i);
			internal_beams(8)((i+1)*define_word_size-1 downto i*define_word_size) <= beam_8_p4(i);

			--/////////////////////////////////////
			--// Delay-and-Sum here:
			--///////////////////////////////////
			--// resize data chunks from ADC before adding in order to get proper sign extension
			--///////////////////////////////////////////////////////////////////////////////////
			
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
					
								
		end if;
	end loop;
end process;

end rtl;
		
		