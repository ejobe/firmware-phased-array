---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         defs.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         1/2016
--
-- DESCRIPTION:  type defs // register mapping
--
---------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--////////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////////

--////////////////////////////////////////////////////////////////
package defs is
--////////////////////////////////////////////////////////////////

--//properties for Rx data interface from ADCs:
constant define_adc_resolution			:	integer := 7; --//no. bits
constant define_word_size					:	integer := 8; --//no. bits, size of each sample in the data array
constant define_serdes_factor 			: 	integer := 8;
constant define_adc_data_width			: 	integer := 28; 
constant define_deser_data_width			: 	integer := define_serdes_factor*define_adc_data_width;
constant pdat_size							:  integer := 2*define_serdes_factor*define_word_size; --//parallel data chunk size

--//waveform acq RAM:
constant define_ram_width  				: 	integer := 128;
constant define_ram_depth					: 	integer := 5; --// words for Rx receiving RAM
constant define_data_ram_depth			: 	integer := 7; --// words for block RAM -- sets time window for triggered and saved event
constant define_num_wfm_buffers			:	integer := 4; --// number of independent buffers for event waveform data

--//firmware registers:
constant define_address_size				:	integer := 8; --//8 bits for now
constant define_register_size				:	integer := 32;


type adc_output_data_type is array (3 downto 0) of std_logic_vector(define_adc_data_width-1 downto 0);
type full_data_type	is array	(7 downto 0) of std_logic_vector(define_ram_width-1 downto 0);	
type ram_adr_chunked_data_type is array(3 downto 0) of std_logic_vector(31 downto 0);
type full_address_type	is array	(7 downto 0) of std_logic_vector(define_ram_depth-1 downto 0);	
type half_address_type  is array	(3 downto 0) of std_logic_vector(define_ram_depth-1 downto 0);	
type two_chan_address_type is array	(1 downto 0) of std_logic_vector(define_ram_depth-1 downto 0);
type full_data_address_type	is array	(7 downto 0) of std_logic_vector(define_data_ram_depth-1 downto 0);	
type aux_data_link_type is array (1 downto 0) of std_logic_vector(7 downto 0);

type event_metadata_type is array(24 downto 0) of std_logic_vector(23 downto 0);

type rx_data_delay_type is array (7 downto 0) of std_logic_vector(3 downto 0); --//delay range for rx data to align ADCs
type buffered_data_type is array (7 downto 0) of std_logic_vector(2*define_ram_width-1 downto 0);

--//registers
type register_array_type is array (127 downto 0) 
	of std_logic_vector(define_register_size-define_address_size-1 downto 0); --//8 bit address, 24 bit data

--////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////
--//FIRMWARE INFORMATION
constant firmware_version 	: std_logic_vector(define_register_size-define_address_size-1 downto 0) := x"000014";
constant firmware_date 		: std_logic_vector(define_register_size-define_address_size-1 downto 0) := x"7e1" & x"8" & x"1E";
--///////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////

--//////////////////////////////
--//stuff for beamforming
constant define_wave2beam_bits 	: integer := 5; --// bits involved in beamforming
constant define_wave2beam_lo_bit : integer := 0; --// low bit from sliced adc data
constant define_wave2beam_hi_bit : integer := define_wave2beam_lo_bit + define_wave2beam_bits; --// high bit from sliced adc data
constant define_beam_bits			: integer := define_wave2beam_bits+3; --//effective resolution increased by 3 bits (8 antennas)
constant define_sign_bit			: integer := define_beam_bits;

--//data split up to samples
--type beam_data_type is array (2*define_serdes_factor*define_word_size-1 downto 0) of 
--	signed(define_beam_bits-1 downto 0);
type beam_data_type is array (2*define_serdes_factor*define_word_size-1 downto 0) of 
	std_logic_vector(define_beam_bits-1 downto 0);		

constant define_num_beams : integer := 15;
type array_of_beams_type is array (define_num_beams-1 downto 0) 
	of std_logic_vector(2*define_serdes_factor*define_word_size-1 downto 0);
	
--////////////////////////////////
--//stuff for power detection 
constant pow_lut_size 	: integer := 2**(define_beam_bits-1);
constant define_pow_sum_range  : integer := 16; --//allow 16 bits

type inst_power_array_type is array(2*define_serdes_factor-1 downto 0) of std_logic_vector(define_pow_sum_range-1 downto 0);
type full_inst_power_array_type is array(define_num_beams-1 downto 0) of inst_power_array_type;

type pipe_full_inst_power_array_type is array(define_num_beams-1 downto 0) of 
	std_logic_vector(4*define_serdes_factor*define_pow_sum_range-1 downto 0);

constant define_num_power_sums : integer := 8; --//number of sums within parallel data clock
type sum_power_type is array(define_num_beams-1 downto 0) of 
	std_logic_vector(define_num_power_sums*(define_pow_sum_range+1)-1 downto 0);  --//define_pos_sum_range+1 (sum of adjacent samples)

--/////////
constant define_16avg_pow_sum_range : integer := 20; --//20 bits (16 bits per sample, 16 samples)
type average_power_16samp_type is array(define_num_beams-1 downto 0) of std_logic_vector(define_16avg_pow_sum_range-1 downto 0);
	
--//scaler array
type scaler_array_type is array(31 downto 0) of std_logic_vector(15 downto 0);


--//assign rx data a specific value when deactivating the rx fifo read request (read clk > write clk)  [[SHOULD NEVER REACH THIS STATE, ERROR CONDITION]]
constant RX_ADC_DATA_HOLD : std_logic_vector(127 downto 0) := x"80808080808080808080808080808080";
constant rx_adc_data_hold_value : full_data_type := (RX_ADC_DATA_HOLD,RX_ADC_DATA_HOLD,RX_ADC_DATA_HOLD,RX_ADC_DATA_HOLD,
																		RX_ADC_DATA_HOLD,RX_ADC_DATA_HOLD,RX_ADC_DATA_HOLD,RX_ADC_DATA_HOLD);
----------------------------------------------------------------------
end defs;

--////////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////////



--////////////////////////////////////////////////////////////////
package register_map is
--////////////////////////////////////////////////////////////////

constant base_adrs_dsa_cntrl		:	integer := 50;

constant base_adrs_adc_cntrl		:	integer := 54;

constant base_adrs_rdout_cntrl 	:  integer := 64;

constant base_adrs_trig_thresh	:	integer := 86;
	
end register_map;
	
	
