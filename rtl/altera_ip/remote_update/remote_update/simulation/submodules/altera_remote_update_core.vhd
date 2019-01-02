--altremote_update CBX_AUTO_BLACKBOX="ALL" CBX_SINGLE_OUTPUT_FILE="ON" check_app_pof="true" config_device_addr_width=32 DEVICE_FAMILY="Arria V" in_data_width=32 is_epcq="true" operation_mode="remote" out_data_width=32 asmi_addr asmi_busy asmi_data_valid asmi_dataout asmi_rden asmi_read busy clock ctl_nupdt data_in data_out param pof_error read_param reconfig reset reset_timer write_param
--VERSION_BEGIN 15.1 cbx_altremote_update 2015:10:21:18:09:23:SJ cbx_cycloneii 2015:10:21:18:09:23:SJ cbx_lpm_add_sub 2015:10:21:18:09:23:SJ cbx_lpm_compare 2015:10:21:18:09:23:SJ cbx_lpm_counter 2015:10:21:18:09:23:SJ cbx_lpm_decode 2015:10:21:18:09:23:SJ cbx_lpm_shiftreg 2015:10:21:18:09:23:SJ cbx_mgl 2015:10:21:18:12:49:SJ cbx_nadder 2015:10:21:18:09:23:SJ cbx_nightfury 2015:10:21:18:09:22:SJ cbx_stratix 2015:10:21:18:09:23:SJ cbx_stratixii 2015:10:21:18:09:23:SJ  VERSION_END


-- Copyright (C) 1991-2015 Altera Corporation. All rights reserved.
--  Your use of Altera Corporation's design tools, logic functions 
--  and other software and tools, and its AMPP partner logic 
--  functions, and any output files from any of the foregoing 
--  (including device programming or simulation files), and any 
--  associated documentation or information are expressly subject 
--  to the terms and conditions of the Altera Program License 
--  Subscription Agreement, the Altera Quartus Prime License Agreement,
--  the Altera MegaCore Function License Agreement, or other 
--  applicable license agreement, including, without limitation, 
--  that your use is for the sole purpose of programming logic 
--  devices manufactured by Altera and sold by Altera or its 
--  authorized distributors.  Please refer to the applicable 
--  agreement for further details.



 LIBRARY arriav;
 USE arriav.all;

 LIBRARY lpm;
 USE lpm.all;

--synthesis_resources = arriav_rublock 1 lpm_add_sub 1 lpm_counter 7 lpm_shiftreg 1 reg 172 
 LIBRARY ieee;
 USE ieee.std_logic_1164.all;

 ENTITY  altera_remote_update_core IS 
	 PORT 
	 ( 
		 asmi_addr	:	OUT  STD_LOGIC_VECTOR (31 DOWNTO 0);
		 asmi_busy	:	IN  STD_LOGIC := '0';
		 asmi_data_valid	:	IN  STD_LOGIC := '0';
		 asmi_dataout	:	IN  STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
		 asmi_rden	:	OUT  STD_LOGIC;
		 asmi_read	:	OUT  STD_LOGIC;
		 busy	:	OUT  STD_LOGIC;
		 clock	:	IN  STD_LOGIC;
		 ctl_nupdt	:	IN  STD_LOGIC := '0';
		 data_in	:	IN  STD_LOGIC_VECTOR (31 DOWNTO 0) := (OTHERS => '0');
		 data_out	:	OUT  STD_LOGIC_VECTOR (31 DOWNTO 0);
		 param	:	IN  STD_LOGIC_VECTOR (2 DOWNTO 0) := (OTHERS => '0');
		 pof_error	:	OUT  STD_LOGIC;
		 read_param	:	IN  STD_LOGIC := '0';
		 reconfig	:	IN  STD_LOGIC := '0';
		 reset	:	IN  STD_LOGIC;
		 reset_timer	:	IN  STD_LOGIC := '0';
		 write_param	:	IN  STD_LOGIC := '0'
	 ); 
 END altera_remote_update_core;

 ARCHITECTURE RTL OF altera_remote_update_core IS

	 ATTRIBUTE synthesis_clearbox : natural;
	 ATTRIBUTE synthesis_clearbox OF RTL : ARCHITECTURE IS 1;
	 ATTRIBUTE ALTERA_ATTRIBUTE : string;
	 ATTRIBUTE ALTERA_ATTRIBUTE OF RTL : ARCHITECTURE IS "suppress_da_rule_internal=c104;suppress_da_rule_internal=C101;suppress_da_rule_internal=C103";

	 SIGNAL	 asim_data_reg	:	STD_LOGIC_VECTOR(7 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 wire_asmi_addr_st_d	:	STD_LOGIC_VECTOR (31 DOWNTO 0);
	 SIGNAL	 asmi_addr_st	:	STD_LOGIC_VECTOR(31 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 wire_asmi_addr_st_ena	:	STD_LOGIC_VECTOR(31 DOWNTO 0);
	 SIGNAL	 asmi_read_reg	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 cal_addr_reg	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 check_busy_dffe	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 crc_cal_reg	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 crc_check_end_reg	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 crc_chk_st_dffe	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 crc_done_reg	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 wire_crc_done_reg_ena	:	STD_LOGIC_VECTOR(0 DOWNTO 0);
	 SIGNAL	 crc_high	:	STD_LOGIC_VECTOR(7 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 crc_low	:	STD_LOGIC_VECTOR(7 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 wire_crc_reg_asdata	:	STD_LOGIC_VECTOR (15 DOWNTO 0);
	 SIGNAL	 crc_reg	:	STD_LOGIC_VECTOR(15 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL  wire_crc_reg_w_lg_w_q_range1165w1167w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_lg_w_q_range1097w1099w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1064w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1145w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1150w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1155w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1160w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1165w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1171w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1097w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1105w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1110w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1115w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1120w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1125w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1130w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1135w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_crc_reg_w_q_range1140w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL	 wire_dataa_switch_d	:	STD_LOGIC_VECTOR (31 DOWNTO 0);
	 SIGNAL	 dataa_switch	:	STD_LOGIC_VECTOR(31 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 wire_dataa_switch_ena	:	STD_LOGIC_VECTOR(31 DOWNTO 0);
	 SIGNAL	 dffe4a	:	STD_LOGIC_VECTOR(31 DOWNTO 0)
	 -- synopsys translate_off
	  := "00000000000000000000000000000000"
	 -- synopsys translate_on
	 ;
	 SIGNAL	 wire_dffe4a_ena	:	STD_LOGIC_VECTOR(31 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range320w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range356w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range361w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range366w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range371w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range376w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range381w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range386w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range391w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range396w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range401w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range325w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range406w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range411w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range416w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range421w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range426w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range431w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range436w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range441w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range446w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range451w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range328w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range456w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range461w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range331w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range334w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range337w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range340w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range343w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range346w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_dffe4a_w_q_range351w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL	 dffe5	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 dffe6a	:	STD_LOGIC_VECTOR(2 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 wire_dffe6a_ena	:	STD_LOGIC_VECTOR(2 DOWNTO 0);
	 SIGNAL	 get_addr_reg	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 idle_state	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 idle_write_wait	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 load_crc_high_reg	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 load_crc_low_reg	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 load_data_reg	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 pof_counter_l42	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 pof_error_reg	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 wire_pof_error_reg_ena	:	STD_LOGIC_VECTOR(0 DOWNTO 0);
	 SIGNAL	 re_config_reg	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 read_address_state	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 wire_read_address_state_ena	:	STD_LOGIC;
	 SIGNAL	 read_control_reg_dffe	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 read_data_state	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 read_init_counter_state	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 read_init_state	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 read_post_state	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 read_pre_data_state	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 reconfig_width_reg	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 ru_reconfig_pof_reg	:	STD_LOGIC_VECTOR(0 DOWNTO 0)
	 -- synopsys translate_off
	  := (OTHERS => '0')
	 -- synopsys translate_on
	 ;
	 SIGNAL	 write_data_state	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 write_init_counter_state	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 write_init_state	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 write_load_state	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 write_post_data_state	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 write_pre_data_state	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL	 write_wait_state	:	STD_LOGIC
	 -- synopsys translate_off
	  := '0'
	 -- synopsys translate_on
	 ;
	 SIGNAL  wire_add_sub12_w_lg_w_result_range860w861w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range897w898w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range903w904w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range909w910w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range915w916w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range921w922w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range927w928w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range933w934w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range939w940w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range945w946w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range951w952w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range864w865w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range957w958w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range963w964w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range969w970w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range975w976w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range981w982w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range987w988w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range993w994w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range999w1000w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range1005w1006w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range1011w1012w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range867w868w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range1017w1018w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range870w871w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range873w874w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range876w877w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range879w880w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range882w883w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range885w886w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range891w892w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_lg_w_result_range1023w1024w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_result	:	STD_LOGIC_VECTOR (31 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range860w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range897w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range903w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range909w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range915w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range921w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range927w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range933w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range939w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range945w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range951w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range864w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range957w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range963w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range969w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range975w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range981w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range987w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range993w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range999w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range1005w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range1011w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range867w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range1017w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range1023w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range870w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range873w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range876w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range879w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range882w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range885w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_add_sub12_w_result_range891w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr10_w_lg_w_q_range838w839w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr10_w_lg_w_q_range836w837w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr10_clk_en	:	STD_LOGIC;
	 SIGNAL  wire_w_lg_asmi_read_wire850w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr10_cout	:	STD_LOGIC;
	 SIGNAL  wire_cntr10_q	:	STD_LOGIC_VECTOR (7 DOWNTO 0);
	 SIGNAL  wire_cntr10_w_q_range836w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr10_w_q_range838w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr11_clk_en	:	STD_LOGIC;
	 SIGNAL  wire_cntr7_w_lg_w_lg_w_lg_w_q_range744w745w746w786w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr11_cout	:	STD_LOGIC;
	 SIGNAL  wire_cntr11_q	:	STD_LOGIC_VECTOR (2 DOWNTO 0);
	 SIGNAL  wire_cntr2_q	:	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  wire_cntr3_q	:	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  wire_cntr7_w_lg_w_lg_w_lg_w_lg_w_q_range744w754w761w763w764w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr7_w_lg_w_lg_w_lg_w_q_range744w745w748w749w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr7_w_lg_w_lg_w_lg_w_q_range744w754w761w763w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr7_w_lg_w_lg_w_q_range744w745w748w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr7_w_lg_w_lg_w_q_range744w754w761w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr7_w_lg_w_q_range744w751w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr7_w_lg_w_q_range744w745w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr7_w_lg_w_q_range742w747w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr7_w_lg_w_q_range743w750w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr7_w_lg_w_q_range744w754w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr7_q	:	STD_LOGIC_VECTOR (2 DOWNTO 0);
	 SIGNAL  wire_cntr7_w_q_range742w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr7_w_q_range743w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr7_w_q_range744w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_lg_w_lg_w_lg_w_lg_w_q_range776w795w800w803w804w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_lg_w_lg_w_lg_w_lg_w_q_range776w795w800w801w802w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_lg_w_lg_w_lg_w_lg_w_q_range776w795w796w797w798w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_lg_w_lg_w_lg_w_q_range776w789w790w791w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_lg_w_lg_w_lg_w_q_range776w795w800w803w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_lg_w_lg_w_lg_w_q_range776w795w800w801w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_lg_w_lg_w_lg_w_q_range776w795w796w797w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_lg_w_lg_w_q_range776w789w790w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_lg_w_lg_w_q_range776w795w800w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_lg_w_lg_w_q_range776w795w796w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_lg_w_q_range776w777w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_lg_w_q_range776w789w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_lg_w_q_range772w773w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_lg_w_q_range774w775w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_lg_w_q_range776w795w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_data	:	STD_LOGIC_VECTOR (2 DOWNTO 0);
	 SIGNAL  wire_cntr8_q	:	STD_LOGIC_VECTOR (2 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_q_range772w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_q_range774w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr8_w_q_range776w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_cntr9_q	:	STD_LOGIC_VECTOR (2 DOWNTO 0);
	 SIGNAL  wire_shift_reg13_enable	:	STD_LOGIC;
	 SIGNAL  wire_w_lg_crc_cal1063w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_shift_reg13_shiftout	:	STD_LOGIC;
	 SIGNAL  wire_sd1_regout	:	STD_LOGIC;
	 SIGNAL  wire_w_lg_w_lg_w_lg_idle655w656w657w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range106w109w110w111w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range116w119w120w121w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range126w129w130w131w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range136w139w140w141w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range146w149w150w151w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range156w159w160w161w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range165w168w169w170w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range174w177w178w179w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range183w186w187w188w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range192w195w196w197w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range201w204w205w206w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range210w213w214w215w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range219w222w223w224w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range228w231w232w233w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range237w240w241w242w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range246w249w250w251w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range255w258w259w260w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range264w267w268w269w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range273w276w277w278w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range282w285w286w287w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range291w294w295w296w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range300w303w304w305w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range81w89w90w91w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_data_in_range96w99w100w101w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w608w611w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w608w620w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w614w615w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_idle655w656w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range106w109w110w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range116w119w120w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range126w129w130w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range136w139w140w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range146w149w150w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range156w159w160w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range165w168w169w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range174w177w178w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range183w186w187w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range192w195w196w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range201w204w205w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range210w213w214w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range219w222w223w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range228w231w232w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range237w240w241w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range246w249w250w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range255w258w259w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range264w267w268w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range273w276w277w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range282w285w286w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range291w294w295w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range300w303w304w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range81w89w90w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_data_in_range96w99w100w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_param_range79w85w86w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w623w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w618w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_get_addr1030w1031w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1168w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1101w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1177w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1147w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1152w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1157w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1162w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1173w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1107w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1112w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1117w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1122w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1127w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1132w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1137w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1100w1142w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w323w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w358w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w363w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w368w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w373w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w378w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w383w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w388w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w393w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w398w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w403w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w327w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w408w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w413w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w418w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w423w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w428w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w433w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w438w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w443w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w448w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w453w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w330w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w458w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w463w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w333w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w336w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w339w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w342w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w345w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w348w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address322w353w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w82w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w175w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w184w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w193w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w202w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w211w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w220w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w229w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w238w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w247w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w256w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w97w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w265w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w274w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w283w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w292w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w301w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w107w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w117w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w127w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w137w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w147w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w157w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable75w166w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w608w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w614w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_get_addr1037w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1102w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1153w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1158w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1163w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1169w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1174w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1178w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1108w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1113w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1118w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1123w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1128w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1133w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1138w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1143w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1148w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_idle655w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_param740w	:	STD_LOGIC_VECTOR (2 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address349w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address399w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address404w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address409w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address414w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address419w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address424w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address429w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address434w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address439w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address444w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address354w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address449w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address454w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address459w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address464w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address359w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address364w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address369w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address374w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address379w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address384w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address389w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address394w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_control_reg739w	:	STD_LOGIC_VECTOR (2 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_data672w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_data651w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_init_counter668w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_post678w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_post650w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_pre_data667w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_rublock_regout_reg712w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable113w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable123w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable133w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable143w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable153w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable163w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable172w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable181w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable190w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable199w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable208w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable217w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable226w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable235w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable244w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable253w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable262w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable271w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable280w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable289w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable298w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable307w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable93w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable103w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_write_data687w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_write_init_counter684w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_write_post_data693w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_write_pre_data683w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range80w88w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range106w185w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range106w109w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range116w194w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range116w119w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range126w203w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range126w129w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range136w212w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range136w139w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range146w221w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range146w149w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range156w230w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range156w159w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range165w239w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range165w168w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range174w248w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range174w177w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range183w257w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range183w186w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range192w266w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range192w195w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range95w98w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range201w275w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range201w204w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range210w284w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range210w213w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range219w293w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range219w222w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range228w302w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range228w231w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range237w240w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range246w249w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range255w258w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range264w267w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range273w276w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range282w285w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range105w108w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range291w294w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range300w303w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range115w118w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range125w128w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range135w138w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range145w148w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range155w158w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range81w167w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range81w89w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range96w176w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_data_in_range96w99w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_param_range79w85w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_param_decoder_param_latch_range604w622w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_param_decoder_param_latch_range604w617w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range887w888w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range947w948w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range953w954w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range959w960w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range965w966w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range971w972w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range977w978w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range983w984w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range989w990w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range995w996w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range1001w1002w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range893w894w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range1007w1008w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range1013w1014w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range1019w1020w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range1025w1026w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range899w900w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range905w906w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range911w912w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range917w918w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range923w924w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range929w930w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range935w936w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_shift_reg_q_range941w942w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_asmi_busy793w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_bit_counter_all_done686w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_bit_counter_enable757w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_bit_counter_param_start_match666w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_crc_check_st1036w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_get_addr1030w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_halt_cal1100w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_idle636w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_address322w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_control_reg652w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_data632w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_init635w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_init_counter634w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_param654w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_post631w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_read_pre_data633w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_select_shift_nloop711w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable75w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w8w317w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_width_counter_all_done670w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_width_counter_param_width_match671w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_write_data627w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_write_init630w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_write_init_counter629w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_write_load625w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_write_param653w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_write_post_data626w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_write_pre_data628w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_write_wait624w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_param_range77w83w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_param_range78w84w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_param_decoder_param_latch_range604w605w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_param_decoder_param_latch_range606w607w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_param_decoder_param_latch_range609w610w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_lg_idle655w656w657w658w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w112w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w122w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w132w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w142w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w152w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w162w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w171w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w180w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w189w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w198w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w207w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w216w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w225w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w234w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w243w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w252w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w261w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w270w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w279w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w288w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w297w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w306w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_lg_w_data_in_range81w89w90w91w92w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w102w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1102w1103w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1153w1154w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1158w1159w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1163w1164w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1169w1170w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1174w1175w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1178w1179w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1108w1109w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1113w1114w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1118w1119w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1123w1124w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1128w1129w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1133w1134w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1138w1139w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1143w1144w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_halt_cal1148w1149w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address349w350w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address399w400w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address404w405w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address409w410w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address414w415w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address419w420w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address424w425w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address429w430w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address434w435w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address439w440w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address444w445w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address354w355w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address449w450w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address454w455w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address459w460w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address464w465w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address359w360w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address364w365w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address369w370w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address374w375w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address379w380w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address384w385w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address389w390w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_read_address394w395w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range887w888w889w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range947w948w949w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range953w954w955w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range959w960w961w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range965w966w967w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range971w972w973w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range977w978w979w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range983w984w985w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range989w990w991w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range995w996w997w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range1001w1002w1003w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range893w894w895w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range1007w1008w1009w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range1013w1014w1015w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range1019w1020w1021w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range1025w1026w1027w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range899w900w901w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range905w906w907w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range911w912w913w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range917w918w919w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range923w924w925w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range929w930w931w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range935w936w937w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_shift_reg_q_range941w942w943w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_w_lg_w_lg_idle655w656w657w658w659w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w660w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w660w661w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_shift_reg_load_enable72w73w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_get_addr1029w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_get_addr1044w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_shift_reg_load_enable72w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  asmi_read_out :	STD_LOGIC;
	 SIGNAL  asmi_read_wire :	STD_LOGIC;
	 SIGNAL  bit_counter_all_done :	STD_LOGIC;
	 SIGNAL  bit_counter_clear :	STD_LOGIC;
	 SIGNAL  bit_counter_enable :	STD_LOGIC;
	 SIGNAL  bit_counter_param_start :	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  bit_counter_param_start_match :	STD_LOGIC;
	 SIGNAL  cal_addr :	STD_LOGIC;
	 SIGNAL  chk_crc_counter_enable :	STD_LOGIC;
	 SIGNAL  chk_pof_counter_enable :	STD_LOGIC;
	 SIGNAL  chk_pof_counter_start :	STD_LOGIC;
	 SIGNAL  crc :	STD_LOGIC_VECTOR (15 DOWNTO 0);
	 SIGNAL  crc_cal :	STD_LOGIC;
	 SIGNAL  crc_check_end :	STD_LOGIC;
	 SIGNAL  crc_check_st :	STD_LOGIC;
	 SIGNAL  crc_check_st_wire :	STD_LOGIC;
	 SIGNAL  crc_enable_wire :	STD_LOGIC;
	 SIGNAL  crc_reg_wire :	STD_LOGIC_VECTOR (15 DOWNTO 0);
	 SIGNAL  crc_shift_done :	STD_LOGIC;
	 SIGNAL  get_addr :	STD_LOGIC;
	 SIGNAL  halt_cal :	STD_LOGIC;
	 SIGNAL  idle :	STD_LOGIC;
	 SIGNAL  invert_bits :	STD_LOGIC;
	 SIGNAL  load_crc_high :	STD_LOGIC;
	 SIGNAL  load_crc_low :	STD_LOGIC;
	 SIGNAL  load_data :	STD_LOGIC;
	 SIGNAL  param_addr :	STD_LOGIC_VECTOR (2 DOWNTO 0);
	 SIGNAL  param_decoder_param_latch :	STD_LOGIC_VECTOR (2 DOWNTO 0);
	 SIGNAL  param_decoder_select :	STD_LOGIC_VECTOR (4 DOWNTO 0);
	 SIGNAL  param_port_combine :	STD_LOGIC_VECTOR (2 DOWNTO 0);
	 SIGNAL  pof_counter_40 :	STD_LOGIC;
	 SIGNAL  pof_error_wire :	STD_LOGIC;
	 SIGNAL  power_up :	STD_LOGIC;
	 SIGNAL  read_address :	STD_LOGIC;
	 SIGNAL  read_control_reg :	STD_LOGIC;
	 SIGNAL  read_data :	STD_LOGIC;
	 SIGNAL  read_init :	STD_LOGIC;
	 SIGNAL  read_init_counter :	STD_LOGIC;
	 SIGNAL  read_post :	STD_LOGIC;
	 SIGNAL  read_pre_data :	STD_LOGIC;
	 SIGNAL  ru_reconfig_pof :	STD_LOGIC;
	 SIGNAL  rublock_captnupdt :	STD_LOGIC;
	 SIGNAL  rublock_clock :	STD_LOGIC;
	 SIGNAL  rublock_reconfig :	STD_LOGIC;
	 SIGNAL  rublock_regin :	STD_LOGIC;
	 SIGNAL  rublock_regout :	STD_LOGIC;
	 SIGNAL  rublock_regout_reg :	STD_LOGIC;
	 SIGNAL  rublock_shiftnld :	STD_LOGIC;
	 SIGNAL  select_shift_nloop :	STD_LOGIC;
	 SIGNAL  shift_reg_clear :	STD_LOGIC;
	 SIGNAL  shift_reg_load_enable :	STD_LOGIC;
	 SIGNAL  shift_reg_q :	STD_LOGIC_VECTOR (31 DOWNTO 0);
	 SIGNAL  shift_reg_serial_in :	STD_LOGIC;
	 SIGNAL  shift_reg_serial_out :	STD_LOGIC;
	 SIGNAL  shift_reg_shift_enable :	STD_LOGIC;
	 SIGNAL  start_bit_decoder_out :	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  start_bit_decoder_param_select :	STD_LOGIC_VECTOR (4 DOWNTO 0);
	 SIGNAL  w22w :	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  w53w :	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  w8w :	STD_LOGIC;
	 SIGNAL  width_counter_all_done :	STD_LOGIC;
	 SIGNAL  width_counter_clear :	STD_LOGIC;
	 SIGNAL  width_counter_enable :	STD_LOGIC;
	 SIGNAL  width_counter_param_width :	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  width_counter_param_width_match :	STD_LOGIC;
	 SIGNAL  width_decoder_out :	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  width_decoder_param_select :	STD_LOGIC_VECTOR (4 DOWNTO 0);
	 SIGNAL  write_data :	STD_LOGIC;
	 SIGNAL  write_init :	STD_LOGIC;
	 SIGNAL  write_init_counter :	STD_LOGIC;
	 SIGNAL  write_load :	STD_LOGIC;
	 SIGNAL  write_post_data :	STD_LOGIC;
	 SIGNAL  write_pre_data :	STD_LOGIC;
	 SIGNAL  write_wait :	STD_LOGIC;
	 SIGNAL  wire_w_data_in_range80w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range106w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range116w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range126w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range136w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range146w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range156w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range165w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range174w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range183w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range192w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range95w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range201w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range210w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range219w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range228w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range237w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range246w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range255w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range264w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range273w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range282w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range105w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range291w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range300w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range115w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range125w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range135w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range145w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range155w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range81w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_data_in_range96w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_param_range77w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_param_range78w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_param_range79w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_param_decoder_param_latch_range604w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_param_decoder_param_latch_range606w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_param_decoder_param_latch_range609w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range887w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range947w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range953w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range959w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range965w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range971w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range977w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range983w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range989w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range995w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range1001w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range893w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range1007w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range1013w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range1019w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range1025w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range899w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range905w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range911w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range917w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range923w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range929w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range935w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_shift_reg_q_range941w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 COMPONENT  lpm_add_sub
	 GENERIC 
	 (
		LPM_DIRECTION	:	STRING := "DEFAULT";
		LPM_PIPELINE	:	NATURAL := 0;
		LPM_REPRESENTATION	:	STRING := "SIGNED";
		LPM_WIDTH	:	NATURAL;
		lpm_hint	:	STRING := "UNUSED";
		lpm_type	:	STRING := "lpm_add_sub"
	 );
	 PORT
	 ( 
		aclr	:	IN STD_LOGIC := '0';
		add_sub	:	IN STD_LOGIC := '1';
		cin	:	IN STD_LOGIC := 'Z';
		clken	:	IN STD_LOGIC := '1';
		clock	:	IN STD_LOGIC := '0';
		cout	:	OUT STD_LOGIC;
		dataa	:	IN STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
		datab	:	IN STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
		overflow	:	OUT STD_LOGIC;
		result	:	OUT STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0)
	 ); 
	 END COMPONENT;
	 COMPONENT  lpm_counter
	 GENERIC 
	 (
		lpm_avalue	:	STRING := "0";
		lpm_direction	:	STRING := "DEFAULT";
		lpm_modulus	:	NATURAL := 0;
		lpm_port_updown	:	STRING := "PORT_CONNECTIVITY";
		lpm_pvalue	:	STRING := "0";
		lpm_svalue	:	STRING := "0";
		lpm_width	:	NATURAL;
		lpm_type	:	STRING := "lpm_counter"
	 );
	 PORT
	 ( 
		aclr	:	IN STD_LOGIC := '0';
		aload	:	IN STD_LOGIC := '0';
		aset	:	IN STD_LOGIC := '0';
		cin	:	IN STD_LOGIC := '1';
		clk_en	:	IN STD_LOGIC := '1';
		clock	:	IN STD_LOGIC;
		cnt_en	:	IN STD_LOGIC := '1';
		cout	:	OUT STD_LOGIC;
		data	:	IN STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
		eq	:	OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		q	:	OUT STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0);
		sclr	:	IN STD_LOGIC := '0';
		sload	:	IN STD_LOGIC := '0';
		sset	:	IN STD_LOGIC := '0';
		updown	:	IN STD_LOGIC := '1'
	 ); 
	 END COMPONENT;
	 COMPONENT  lpm_shiftreg
	 GENERIC 
	 (
		LPM_AVALUE	:	STRING := "UNUSED";
		LPM_DIRECTION	:	STRING := "LEFT";
		LPM_SVALUE	:	STRING := "UNUSED";
		LPM_WIDTH	:	NATURAL;
		lpm_type	:	STRING := "lpm_shiftreg"
	 );
	 PORT
	 ( 
		aclr	:	IN STD_LOGIC := '0';
		aset	:	IN STD_LOGIC := '0';
		clock	:	IN STD_LOGIC;
		data	:	IN STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
		enable	:	IN STD_LOGIC := '1';
		load	:	IN STD_LOGIC := '0';
		q	:	OUT STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0);
		sclr	:	IN STD_LOGIC := '0';
		shiftin	:	IN STD_LOGIC := '1';
		shiftout	:	OUT STD_LOGIC;
		sset	:	IN STD_LOGIC := '0'
	 ); 
	 END COMPONENT;
	 COMPONENT  arriav_rublock
	 PORT
	 ( 
		captnupdt	:	IN STD_LOGIC;
		clk	:	IN STD_LOGIC;
		rconfig	:	IN STD_LOGIC;
		regin	:	IN STD_LOGIC;
		regout	:	OUT STD_LOGIC;
		rsttimer	:	IN STD_LOGIC;
		shiftnld	:	IN STD_LOGIC
	 ); 
	 END COMPONENT;
 BEGIN

	wire_w_lg_w_lg_w_lg_idle655w656w657w(0) <= wire_w_lg_w_lg_idle655w656w(0) AND wire_w_lg_read_control_reg652w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range106w109w110w111w(0) <= wire_w_lg_w_lg_w_data_in_range106w109w110w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range116w119w120w121w(0) <= wire_w_lg_w_lg_w_data_in_range116w119w120w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range126w129w130w131w(0) <= wire_w_lg_w_lg_w_data_in_range126w129w130w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range136w139w140w141w(0) <= wire_w_lg_w_lg_w_data_in_range136w139w140w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range146w149w150w151w(0) <= wire_w_lg_w_lg_w_data_in_range146w149w150w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range156w159w160w161w(0) <= wire_w_lg_w_lg_w_data_in_range156w159w160w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range165w168w169w170w(0) <= wire_w_lg_w_lg_w_data_in_range165w168w169w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range174w177w178w179w(0) <= wire_w_lg_w_lg_w_data_in_range174w177w178w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range183w186w187w188w(0) <= wire_w_lg_w_lg_w_data_in_range183w186w187w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range192w195w196w197w(0) <= wire_w_lg_w_lg_w_data_in_range192w195w196w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range201w204w205w206w(0) <= wire_w_lg_w_lg_w_data_in_range201w204w205w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range210w213w214w215w(0) <= wire_w_lg_w_lg_w_data_in_range210w213w214w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range219w222w223w224w(0) <= wire_w_lg_w_lg_w_data_in_range219w222w223w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range228w231w232w233w(0) <= wire_w_lg_w_lg_w_data_in_range228w231w232w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range237w240w241w242w(0) <= wire_w_lg_w_lg_w_data_in_range237w240w241w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range246w249w250w251w(0) <= wire_w_lg_w_lg_w_data_in_range246w249w250w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range255w258w259w260w(0) <= wire_w_lg_w_lg_w_data_in_range255w258w259w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range264w267w268w269w(0) <= wire_w_lg_w_lg_w_data_in_range264w267w268w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range273w276w277w278w(0) <= wire_w_lg_w_lg_w_data_in_range273w276w277w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range282w285w286w287w(0) <= wire_w_lg_w_lg_w_data_in_range282w285w286w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range291w294w295w296w(0) <= wire_w_lg_w_lg_w_data_in_range291w294w295w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range300w303w304w305w(0) <= wire_w_lg_w_lg_w_data_in_range300w303w304w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range81w89w90w91w(0) <= wire_w_lg_w_lg_w_data_in_range81w89w90w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w_lg_w_lg_w_data_in_range96w99w100w101w(0) <= wire_w_lg_w_lg_w_data_in_range96w99w100w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w_lg_w608w611w(0) <= wire_w608w(0) AND wire_w_lg_w_param_decoder_param_latch_range609w610w(0);
	wire_w_lg_w608w620w(0) <= wire_w608w(0) AND wire_w_param_decoder_param_latch_range609w(0);
	wire_w_lg_w614w615w(0) <= wire_w614w(0) AND wire_w_lg_w_param_decoder_param_latch_range609w610w(0);
	wire_w_lg_w_lg_idle655w656w(0) <= wire_w_lg_idle655w(0) AND wire_w_lg_write_param653w(0);
	wire_w_lg_w_lg_w_data_in_range106w109w110w(0) <= wire_w_lg_w_data_in_range106w109w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range116w119w120w(0) <= wire_w_lg_w_data_in_range116w119w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range126w129w130w(0) <= wire_w_lg_w_data_in_range126w129w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range136w139w140w(0) <= wire_w_lg_w_data_in_range136w139w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range146w149w150w(0) <= wire_w_lg_w_data_in_range146w149w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range156w159w160w(0) <= wire_w_lg_w_data_in_range156w159w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range165w168w169w(0) <= wire_w_lg_w_data_in_range165w168w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range174w177w178w(0) <= wire_w_lg_w_data_in_range174w177w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range183w186w187w(0) <= wire_w_lg_w_data_in_range183w186w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range192w195w196w(0) <= wire_w_lg_w_data_in_range192w195w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range201w204w205w(0) <= wire_w_lg_w_data_in_range201w204w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range210w213w214w(0) <= wire_w_lg_w_data_in_range210w213w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range219w222w223w(0) <= wire_w_lg_w_data_in_range219w222w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range228w231w232w(0) <= wire_w_lg_w_data_in_range228w231w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range237w240w241w(0) <= wire_w_lg_w_data_in_range237w240w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range246w249w250w(0) <= wire_w_lg_w_data_in_range246w249w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range255w258w259w(0) <= wire_w_lg_w_data_in_range255w258w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range264w267w268w(0) <= wire_w_lg_w_data_in_range264w267w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range273w276w277w(0) <= wire_w_lg_w_data_in_range273w276w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range282w285w286w(0) <= wire_w_lg_w_data_in_range282w285w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range291w294w295w(0) <= wire_w_lg_w_data_in_range291w294w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range300w303w304w(0) <= wire_w_lg_w_data_in_range300w303w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range81w89w90w(0) <= wire_w_lg_w_data_in_range81w89w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_data_in_range96w99w100w(0) <= wire_w_lg_w_data_in_range96w99w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_lg_w_param_range79w85w86w(0) <= wire_w_lg_w_param_range79w85w(0) AND wire_w_lg_w_param_range77w83w(0);
	wire_w623w(0) <= wire_w_lg_w_param_decoder_param_latch_range604w622w(0) AND wire_w_param_decoder_param_latch_range609w(0);
	wire_w618w(0) <= wire_w_lg_w_param_decoder_param_latch_range604w617w(0) AND wire_w_lg_w_param_decoder_param_latch_range609w610w(0);
	wire_w_lg_w_lg_get_addr1030w1031w(0) <= wire_w_lg_get_addr1030w(0) AND crc_check_st;
	wire_w_lg_w_lg_halt_cal1100w1168w(0) <= wire_w_lg_halt_cal1100w(0) AND wire_crc_reg_w_lg_w_q_range1165w1167w(0);
	wire_w_lg_w_lg_halt_cal1100w1101w(0) <= wire_w_lg_halt_cal1100w(0) AND wire_crc_reg_w_lg_w_q_range1097w1099w(0);
	wire_w_lg_w_lg_halt_cal1100w1177w(0) <= wire_w_lg_halt_cal1100w(0) AND invert_bits;
	wire_w_lg_w_lg_halt_cal1100w1147w(0) <= wire_w_lg_halt_cal1100w(0) AND wire_crc_reg_w_q_range1145w(0);
	wire_w_lg_w_lg_halt_cal1100w1152w(0) <= wire_w_lg_halt_cal1100w(0) AND wire_crc_reg_w_q_range1150w(0);
	wire_w_lg_w_lg_halt_cal1100w1157w(0) <= wire_w_lg_halt_cal1100w(0) AND wire_crc_reg_w_q_range1155w(0);
	wire_w_lg_w_lg_halt_cal1100w1162w(0) <= wire_w_lg_halt_cal1100w(0) AND wire_crc_reg_w_q_range1160w(0);
	wire_w_lg_w_lg_halt_cal1100w1173w(0) <= wire_w_lg_halt_cal1100w(0) AND wire_crc_reg_w_q_range1171w(0);
	wire_w_lg_w_lg_halt_cal1100w1107w(0) <= wire_w_lg_halt_cal1100w(0) AND wire_crc_reg_w_q_range1105w(0);
	wire_w_lg_w_lg_halt_cal1100w1112w(0) <= wire_w_lg_halt_cal1100w(0) AND wire_crc_reg_w_q_range1110w(0);
	wire_w_lg_w_lg_halt_cal1100w1117w(0) <= wire_w_lg_halt_cal1100w(0) AND wire_crc_reg_w_q_range1115w(0);
	wire_w_lg_w_lg_halt_cal1100w1122w(0) <= wire_w_lg_halt_cal1100w(0) AND wire_crc_reg_w_q_range1120w(0);
	wire_w_lg_w_lg_halt_cal1100w1127w(0) <= wire_w_lg_halt_cal1100w(0) AND wire_crc_reg_w_q_range1125w(0);
	wire_w_lg_w_lg_halt_cal1100w1132w(0) <= wire_w_lg_halt_cal1100w(0) AND wire_crc_reg_w_q_range1130w(0);
	wire_w_lg_w_lg_halt_cal1100w1137w(0) <= wire_w_lg_halt_cal1100w(0) AND wire_crc_reg_w_q_range1135w(0);
	wire_w_lg_w_lg_halt_cal1100w1142w(0) <= wire_w_lg_halt_cal1100w(0) AND wire_crc_reg_w_q_range1140w(0);
	wire_w_lg_w_lg_read_address322w323w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range320w(0);
	wire_w_lg_w_lg_read_address322w358w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range356w(0);
	wire_w_lg_w_lg_read_address322w363w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range361w(0);
	wire_w_lg_w_lg_read_address322w368w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range366w(0);
	wire_w_lg_w_lg_read_address322w373w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range371w(0);
	wire_w_lg_w_lg_read_address322w378w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range376w(0);
	wire_w_lg_w_lg_read_address322w383w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range381w(0);
	wire_w_lg_w_lg_read_address322w388w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range386w(0);
	wire_w_lg_w_lg_read_address322w393w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range391w(0);
	wire_w_lg_w_lg_read_address322w398w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range396w(0);
	wire_w_lg_w_lg_read_address322w403w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range401w(0);
	wire_w_lg_w_lg_read_address322w327w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range325w(0);
	wire_w_lg_w_lg_read_address322w408w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range406w(0);
	wire_w_lg_w_lg_read_address322w413w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range411w(0);
	wire_w_lg_w_lg_read_address322w418w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range416w(0);
	wire_w_lg_w_lg_read_address322w423w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range421w(0);
	wire_w_lg_w_lg_read_address322w428w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range426w(0);
	wire_w_lg_w_lg_read_address322w433w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range431w(0);
	wire_w_lg_w_lg_read_address322w438w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range436w(0);
	wire_w_lg_w_lg_read_address322w443w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range441w(0);
	wire_w_lg_w_lg_read_address322w448w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range446w(0);
	wire_w_lg_w_lg_read_address322w453w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range451w(0);
	wire_w_lg_w_lg_read_address322w330w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range328w(0);
	wire_w_lg_w_lg_read_address322w458w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range456w(0);
	wire_w_lg_w_lg_read_address322w463w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range461w(0);
	wire_w_lg_w_lg_read_address322w333w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range331w(0);
	wire_w_lg_w_lg_read_address322w336w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range334w(0);
	wire_w_lg_w_lg_read_address322w339w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range337w(0);
	wire_w_lg_w_lg_read_address322w342w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range340w(0);
	wire_w_lg_w_lg_read_address322w345w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range343w(0);
	wire_w_lg_w_lg_read_address322w348w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range346w(0);
	wire_w_lg_w_lg_read_address322w353w(0) <= wire_w_lg_read_address322w(0) AND wire_dffe4a_w_q_range351w(0);
	wire_w_lg_w_lg_shift_reg_load_enable75w82w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(1);
	wire_w_lg_w_lg_shift_reg_load_enable75w175w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(10);
	wire_w_lg_w_lg_shift_reg_load_enable75w184w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(11);
	wire_w_lg_w_lg_shift_reg_load_enable75w193w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(12);
	wire_w_lg_w_lg_shift_reg_load_enable75w202w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(13);
	wire_w_lg_w_lg_shift_reg_load_enable75w211w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(14);
	wire_w_lg_w_lg_shift_reg_load_enable75w220w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(15);
	wire_w_lg_w_lg_shift_reg_load_enable75w229w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(16);
	wire_w_lg_w_lg_shift_reg_load_enable75w238w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(17);
	wire_w_lg_w_lg_shift_reg_load_enable75w247w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(18);
	wire_w_lg_w_lg_shift_reg_load_enable75w256w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(19);
	wire_w_lg_w_lg_shift_reg_load_enable75w97w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(2);
	wire_w_lg_w_lg_shift_reg_load_enable75w265w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(20);
	wire_w_lg_w_lg_shift_reg_load_enable75w274w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(21);
	wire_w_lg_w_lg_shift_reg_load_enable75w283w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(22);
	wire_w_lg_w_lg_shift_reg_load_enable75w292w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(23);
	wire_w_lg_w_lg_shift_reg_load_enable75w301w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(24);
	wire_w_lg_w_lg_shift_reg_load_enable75w107w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(3);
	wire_w_lg_w_lg_shift_reg_load_enable75w117w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(4);
	wire_w_lg_w_lg_shift_reg_load_enable75w127w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(5);
	wire_w_lg_w_lg_shift_reg_load_enable75w137w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(6);
	wire_w_lg_w_lg_shift_reg_load_enable75w147w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(7);
	wire_w_lg_w_lg_shift_reg_load_enable75w157w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(8);
	wire_w_lg_w_lg_shift_reg_load_enable75w166w(0) <= wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(9);
	wire_w608w(0) <= wire_w_lg_w_param_decoder_param_latch_range604w605w(0) AND wire_w_lg_w_param_decoder_param_latch_range606w607w(0);
	wire_w614w(0) <= wire_w_lg_w_param_decoder_param_latch_range604w605w(0) AND wire_w_param_decoder_param_latch_range606w(0);
	wire_w_lg_get_addr1037w(0) <= get_addr AND wire_w_lg_crc_check_st1036w(0);
	wire_w_lg_halt_cal1102w(0) <= halt_cal AND wire_crc_reg_w_q_range1064w(0);
	wire_w_lg_halt_cal1153w(0) <= halt_cal AND wire_crc_reg_w_q_range1145w(0);
	wire_w_lg_halt_cal1158w(0) <= halt_cal AND wire_crc_reg_w_q_range1150w(0);
	wire_w_lg_halt_cal1163w(0) <= halt_cal AND wire_crc_reg_w_q_range1155w(0);
	wire_w_lg_halt_cal1169w(0) <= halt_cal AND wire_crc_reg_w_q_range1160w(0);
	wire_w_lg_halt_cal1174w(0) <= halt_cal AND wire_crc_reg_w_q_range1165w(0);
	wire_w_lg_halt_cal1178w(0) <= halt_cal AND wire_crc_reg_w_q_range1171w(0);
	wire_w_lg_halt_cal1108w(0) <= halt_cal AND wire_crc_reg_w_q_range1097w(0);
	wire_w_lg_halt_cal1113w(0) <= halt_cal AND wire_crc_reg_w_q_range1105w(0);
	wire_w_lg_halt_cal1118w(0) <= halt_cal AND wire_crc_reg_w_q_range1110w(0);
	wire_w_lg_halt_cal1123w(0) <= halt_cal AND wire_crc_reg_w_q_range1115w(0);
	wire_w_lg_halt_cal1128w(0) <= halt_cal AND wire_crc_reg_w_q_range1120w(0);
	wire_w_lg_halt_cal1133w(0) <= halt_cal AND wire_crc_reg_w_q_range1125w(0);
	wire_w_lg_halt_cal1138w(0) <= halt_cal AND wire_crc_reg_w_q_range1130w(0);
	wire_w_lg_halt_cal1143w(0) <= halt_cal AND wire_crc_reg_w_q_range1135w(0);
	wire_w_lg_halt_cal1148w(0) <= halt_cal AND wire_crc_reg_w_q_range1140w(0);
	wire_w_lg_idle655w(0) <= idle AND wire_w_lg_read_param654w(0);
	loop0 : FOR i IN 0 TO 2 GENERATE 
		wire_w_lg_param740w(i) <= param(i) AND wire_w_lg_read_control_reg652w(0);
	END GENERATE loop0;
	wire_w_lg_read_address349w(0) <= read_address AND wire_dffe4a_w_q_range320w(0);
	wire_w_lg_read_address399w(0) <= read_address AND wire_dffe4a_w_q_range356w(0);
	wire_w_lg_read_address404w(0) <= read_address AND wire_dffe4a_w_q_range361w(0);
	wire_w_lg_read_address409w(0) <= read_address AND wire_dffe4a_w_q_range366w(0);
	wire_w_lg_read_address414w(0) <= read_address AND wire_dffe4a_w_q_range371w(0);
	wire_w_lg_read_address419w(0) <= read_address AND wire_dffe4a_w_q_range376w(0);
	wire_w_lg_read_address424w(0) <= read_address AND wire_dffe4a_w_q_range381w(0);
	wire_w_lg_read_address429w(0) <= read_address AND wire_dffe4a_w_q_range386w(0);
	wire_w_lg_read_address434w(0) <= read_address AND wire_dffe4a_w_q_range391w(0);
	wire_w_lg_read_address439w(0) <= read_address AND wire_dffe4a_w_q_range396w(0);
	wire_w_lg_read_address444w(0) <= read_address AND wire_dffe4a_w_q_range401w(0);
	wire_w_lg_read_address354w(0) <= read_address AND wire_dffe4a_w_q_range325w(0);
	wire_w_lg_read_address449w(0) <= read_address AND wire_dffe4a_w_q_range406w(0);
	wire_w_lg_read_address454w(0) <= read_address AND wire_dffe4a_w_q_range411w(0);
	wire_w_lg_read_address459w(0) <= read_address AND wire_dffe4a_w_q_range416w(0);
	wire_w_lg_read_address464w(0) <= read_address AND wire_dffe4a_w_q_range421w(0);
	wire_w_lg_read_address359w(0) <= read_address AND wire_dffe4a_w_q_range328w(0);
	wire_w_lg_read_address364w(0) <= read_address AND wire_dffe4a_w_q_range331w(0);
	wire_w_lg_read_address369w(0) <= read_address AND wire_dffe4a_w_q_range334w(0);
	wire_w_lg_read_address374w(0) <= read_address AND wire_dffe4a_w_q_range337w(0);
	wire_w_lg_read_address379w(0) <= read_address AND wire_dffe4a_w_q_range340w(0);
	wire_w_lg_read_address384w(0) <= read_address AND wire_dffe4a_w_q_range343w(0);
	wire_w_lg_read_address389w(0) <= read_address AND wire_dffe4a_w_q_range346w(0);
	wire_w_lg_read_address394w(0) <= read_address AND wire_dffe4a_w_q_range351w(0);
	loop1 : FOR i IN 0 TO 2 GENERATE 
		wire_w_lg_read_control_reg739w(i) <= read_control_reg AND param_addr(i);
	END GENERATE loop1;
	wire_w_lg_read_data672w(0) <= read_data AND wire_w_lg_width_counter_param_width_match671w(0);
	wire_w_lg_read_data651w(0) <= read_data AND width_counter_all_done;
	wire_w_lg_read_init_counter668w(0) <= read_init_counter AND wire_w_lg_bit_counter_param_start_match666w(0);
	wire_w_lg_read_post678w(0) <= read_post AND wire_w_lg_width_counter_all_done670w(0);
	wire_w_lg_read_post650w(0) <= read_post AND width_counter_all_done;
	wire_w_lg_read_pre_data667w(0) <= read_pre_data AND wire_w_lg_bit_counter_param_start_match666w(0);
	wire_w_lg_rublock_regout_reg712w(0) <= rublock_regout_reg AND wire_w_lg_select_shift_nloop711w(0);
	wire_w_lg_shift_reg_load_enable113w(0) <= shift_reg_load_enable AND wire_w112w(0);
	wire_w_lg_shift_reg_load_enable123w(0) <= shift_reg_load_enable AND wire_w122w(0);
	wire_w_lg_shift_reg_load_enable133w(0) <= shift_reg_load_enable AND wire_w132w(0);
	wire_w_lg_shift_reg_load_enable143w(0) <= shift_reg_load_enable AND wire_w142w(0);
	wire_w_lg_shift_reg_load_enable153w(0) <= shift_reg_load_enable AND wire_w152w(0);
	wire_w_lg_shift_reg_load_enable163w(0) <= shift_reg_load_enable AND wire_w162w(0);
	wire_w_lg_shift_reg_load_enable172w(0) <= shift_reg_load_enable AND wire_w171w(0);
	wire_w_lg_shift_reg_load_enable181w(0) <= shift_reg_load_enable AND wire_w180w(0);
	wire_w_lg_shift_reg_load_enable190w(0) <= shift_reg_load_enable AND wire_w189w(0);
	wire_w_lg_shift_reg_load_enable199w(0) <= shift_reg_load_enable AND wire_w198w(0);
	wire_w_lg_shift_reg_load_enable208w(0) <= shift_reg_load_enable AND wire_w207w(0);
	wire_w_lg_shift_reg_load_enable217w(0) <= shift_reg_load_enable AND wire_w216w(0);
	wire_w_lg_shift_reg_load_enable226w(0) <= shift_reg_load_enable AND wire_w225w(0);
	wire_w_lg_shift_reg_load_enable235w(0) <= shift_reg_load_enable AND wire_w234w(0);
	wire_w_lg_shift_reg_load_enable244w(0) <= shift_reg_load_enable AND wire_w243w(0);
	wire_w_lg_shift_reg_load_enable253w(0) <= shift_reg_load_enable AND wire_w252w(0);
	wire_w_lg_shift_reg_load_enable262w(0) <= shift_reg_load_enable AND wire_w261w(0);
	wire_w_lg_shift_reg_load_enable271w(0) <= shift_reg_load_enable AND wire_w270w(0);
	wire_w_lg_shift_reg_load_enable280w(0) <= shift_reg_load_enable AND wire_w279w(0);
	wire_w_lg_shift_reg_load_enable289w(0) <= shift_reg_load_enable AND wire_w288w(0);
	wire_w_lg_shift_reg_load_enable298w(0) <= shift_reg_load_enable AND wire_w297w(0);
	wire_w_lg_shift_reg_load_enable307w(0) <= shift_reg_load_enable AND wire_w306w(0);
	wire_w_lg_shift_reg_load_enable93w(0) <= shift_reg_load_enable AND wire_w_lg_w_lg_w_lg_w_lg_w_data_in_range81w89w90w91w92w(0);
	wire_w_lg_shift_reg_load_enable103w(0) <= shift_reg_load_enable AND wire_w102w(0);
	wire_w_lg_write_data687w(0) <= write_data AND wire_w_lg_width_counter_param_width_match671w(0);
	wire_w_lg_write_init_counter684w(0) <= write_init_counter AND wire_w_lg_bit_counter_param_start_match666w(0);
	wire_w_lg_write_post_data693w(0) <= write_post_data AND wire_w_lg_bit_counter_all_done686w(0);
	wire_w_lg_write_pre_data683w(0) <= write_pre_data AND wire_w_lg_bit_counter_param_start_match666w(0);
	wire_w_lg_w_data_in_range80w88w(0) <= wire_w_data_in_range80w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range106w185w(0) <= wire_w_data_in_range106w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range106w109w(0) <= wire_w_data_in_range106w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range116w194w(0) <= wire_w_data_in_range116w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range116w119w(0) <= wire_w_data_in_range116w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range126w203w(0) <= wire_w_data_in_range126w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range126w129w(0) <= wire_w_data_in_range126w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range136w212w(0) <= wire_w_data_in_range136w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range136w139w(0) <= wire_w_data_in_range136w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range146w221w(0) <= wire_w_data_in_range146w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range146w149w(0) <= wire_w_data_in_range146w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range156w230w(0) <= wire_w_data_in_range156w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range156w159w(0) <= wire_w_data_in_range156w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range165w239w(0) <= wire_w_data_in_range165w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range165w168w(0) <= wire_w_data_in_range165w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range174w248w(0) <= wire_w_data_in_range174w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range174w177w(0) <= wire_w_data_in_range174w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range183w257w(0) <= wire_w_data_in_range183w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range183w186w(0) <= wire_w_data_in_range183w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range192w266w(0) <= wire_w_data_in_range192w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range192w195w(0) <= wire_w_data_in_range192w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range95w98w(0) <= wire_w_data_in_range95w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range201w275w(0) <= wire_w_data_in_range201w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range201w204w(0) <= wire_w_data_in_range201w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range210w284w(0) <= wire_w_data_in_range210w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range210w213w(0) <= wire_w_data_in_range210w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range219w293w(0) <= wire_w_data_in_range219w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range219w222w(0) <= wire_w_data_in_range219w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range228w302w(0) <= wire_w_data_in_range228w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range228w231w(0) <= wire_w_data_in_range228w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range237w240w(0) <= wire_w_data_in_range237w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range246w249w(0) <= wire_w_data_in_range246w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range255w258w(0) <= wire_w_data_in_range255w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range264w267w(0) <= wire_w_data_in_range264w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range273w276w(0) <= wire_w_data_in_range273w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range282w285w(0) <= wire_w_data_in_range282w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range105w108w(0) <= wire_w_data_in_range105w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range291w294w(0) <= wire_w_data_in_range291w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range300w303w(0) <= wire_w_data_in_range300w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range115w118w(0) <= wire_w_data_in_range115w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range125w128w(0) <= wire_w_data_in_range125w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range135w138w(0) <= wire_w_data_in_range135w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range145w148w(0) <= wire_w_data_in_range145w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range155w158w(0) <= wire_w_data_in_range155w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range81w167w(0) <= wire_w_data_in_range81w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range81w89w(0) <= wire_w_data_in_range81w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_data_in_range96w176w(0) <= wire_w_data_in_range96w(0) AND wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0);
	wire_w_lg_w_data_in_range96w99w(0) <= wire_w_data_in_range96w(0) AND wire_w_param_range79w(0);
	wire_w_lg_w_param_range79w85w(0) <= wire_w_param_range79w(0) AND wire_w_lg_w_param_range78w84w(0);
	wire_w_lg_w_param_decoder_param_latch_range604w622w(0) <= wire_w_param_decoder_param_latch_range604w(0) AND wire_w_lg_w_param_decoder_param_latch_range606w607w(0);
	wire_w_lg_w_param_decoder_param_latch_range604w617w(0) <= wire_w_param_decoder_param_latch_range604w(0) AND wire_w_param_decoder_param_latch_range606w(0);
	wire_w_lg_w_shift_reg_q_range887w888w(0) <= wire_w_shift_reg_q_range887w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range947w948w(0) <= wire_w_shift_reg_q_range947w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range953w954w(0) <= wire_w_shift_reg_q_range953w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range959w960w(0) <= wire_w_shift_reg_q_range959w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range965w966w(0) <= wire_w_shift_reg_q_range965w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range971w972w(0) <= wire_w_shift_reg_q_range971w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range977w978w(0) <= wire_w_shift_reg_q_range977w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range983w984w(0) <= wire_w_shift_reg_q_range983w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range989w990w(0) <= wire_w_shift_reg_q_range989w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range995w996w(0) <= wire_w_shift_reg_q_range995w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range1001w1002w(0) <= wire_w_shift_reg_q_range1001w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range893w894w(0) <= wire_w_shift_reg_q_range893w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range1007w1008w(0) <= wire_w_shift_reg_q_range1007w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range1013w1014w(0) <= wire_w_shift_reg_q_range1013w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range1019w1020w(0) <= wire_w_shift_reg_q_range1019w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range1025w1026w(0) <= wire_w_shift_reg_q_range1025w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range899w900w(0) <= wire_w_shift_reg_q_range899w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range905w906w(0) <= wire_w_shift_reg_q_range905w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range911w912w(0) <= wire_w_shift_reg_q_range911w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range917w918w(0) <= wire_w_shift_reg_q_range917w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range923w924w(0) <= wire_w_shift_reg_q_range923w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range929w930w(0) <= wire_w_shift_reg_q_range929w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range935w936w(0) <= wire_w_shift_reg_q_range935w(0) AND get_addr;
	wire_w_lg_w_shift_reg_q_range941w942w(0) <= wire_w_shift_reg_q_range941w(0) AND get_addr;
	wire_w_lg_w_lg_w_lg_w_param_range79w85w86w87w(0) <= NOT wire_w_lg_w_lg_w_param_range79w85w86w(0);
	wire_w_lg_asmi_busy793w(0) <= NOT asmi_busy;
	wire_w_lg_bit_counter_all_done686w(0) <= NOT bit_counter_all_done;
	wire_w_lg_bit_counter_enable757w(0) <= NOT bit_counter_enable;
	wire_w_lg_bit_counter_param_start_match666w(0) <= NOT bit_counter_param_start_match;
	wire_w_lg_crc_check_st1036w(0) <= NOT crc_check_st;
	wire_w_lg_get_addr1030w(0) <= NOT get_addr;
	wire_w_lg_halt_cal1100w(0) <= NOT halt_cal;
	wire_w_lg_idle636w(0) <= NOT idle;
	wire_w_lg_read_address322w(0) <= NOT read_address;
	wire_w_lg_read_control_reg652w(0) <= NOT read_control_reg;
	wire_w_lg_read_data632w(0) <= NOT read_data;
	wire_w_lg_read_init635w(0) <= NOT read_init;
	wire_w_lg_read_init_counter634w(0) <= NOT read_init_counter;
	wire_w_lg_read_param654w(0) <= NOT read_param;
	wire_w_lg_read_post631w(0) <= NOT read_post;
	wire_w_lg_read_pre_data633w(0) <= NOT read_pre_data;
	wire_w_lg_select_shift_nloop711w(0) <= NOT select_shift_nloop;
	wire_w_lg_shift_reg_load_enable75w(0) <= NOT shift_reg_load_enable;
	wire_w_lg_w8w317w(0) <= NOT w8w;
	wire_w_lg_width_counter_all_done670w(0) <= NOT width_counter_all_done;
	wire_w_lg_width_counter_param_width_match671w(0) <= NOT width_counter_param_width_match;
	wire_w_lg_write_data627w(0) <= NOT write_data;
	wire_w_lg_write_init630w(0) <= NOT write_init;
	wire_w_lg_write_init_counter629w(0) <= NOT write_init_counter;
	wire_w_lg_write_load625w(0) <= NOT write_load;
	wire_w_lg_write_param653w(0) <= NOT write_param;
	wire_w_lg_write_post_data626w(0) <= NOT write_post_data;
	wire_w_lg_write_pre_data628w(0) <= NOT write_pre_data;
	wire_w_lg_write_wait624w(0) <= NOT write_wait;
	wire_w_lg_w_param_range77w83w(0) <= NOT wire_w_param_range77w(0);
	wire_w_lg_w_param_range78w84w(0) <= NOT wire_w_param_range78w(0);
	wire_w_lg_w_param_decoder_param_latch_range604w605w(0) <= NOT wire_w_param_decoder_param_latch_range604w(0);
	wire_w_lg_w_param_decoder_param_latch_range606w607w(0) <= NOT wire_w_param_decoder_param_latch_range606w(0);
	wire_w_lg_w_param_decoder_param_latch_range609w610w(0) <= NOT wire_w_param_decoder_param_latch_range609w(0);
	wire_w_lg_w_lg_w_lg_w_lg_idle655w656w657w658w(0) <= wire_w_lg_w_lg_w_lg_idle655w656w657w(0) OR write_wait;
	wire_w112w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range106w109w110w111w(0) OR wire_w_lg_w_data_in_range105w108w(0);
	wire_w122w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range116w119w120w121w(0) OR wire_w_lg_w_data_in_range115w118w(0);
	wire_w132w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range126w129w130w131w(0) OR wire_w_lg_w_data_in_range125w128w(0);
	wire_w142w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range136w139w140w141w(0) OR wire_w_lg_w_data_in_range135w138w(0);
	wire_w152w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range146w149w150w151w(0) OR wire_w_lg_w_data_in_range145w148w(0);
	wire_w162w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range156w159w160w161w(0) OR wire_w_lg_w_data_in_range155w158w(0);
	wire_w171w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range165w168w169w170w(0) OR wire_w_lg_w_data_in_range81w167w(0);
	wire_w180w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range174w177w178w179w(0) OR wire_w_lg_w_data_in_range96w176w(0);
	wire_w189w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range183w186w187w188w(0) OR wire_w_lg_w_data_in_range106w185w(0);
	wire_w198w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range192w195w196w197w(0) OR wire_w_lg_w_data_in_range116w194w(0);
	wire_w207w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range201w204w205w206w(0) OR wire_w_lg_w_data_in_range126w203w(0);
	wire_w216w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range210w213w214w215w(0) OR wire_w_lg_w_data_in_range136w212w(0);
	wire_w225w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range219w222w223w224w(0) OR wire_w_lg_w_data_in_range146w221w(0);
	wire_w234w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range228w231w232w233w(0) OR wire_w_lg_w_data_in_range156w230w(0);
	wire_w243w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range237w240w241w242w(0) OR wire_w_lg_w_data_in_range165w239w(0);
	wire_w252w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range246w249w250w251w(0) OR wire_w_lg_w_data_in_range174w248w(0);
	wire_w261w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range255w258w259w260w(0) OR wire_w_lg_w_data_in_range183w257w(0);
	wire_w270w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range264w267w268w269w(0) OR wire_w_lg_w_data_in_range192w266w(0);
	wire_w279w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range273w276w277w278w(0) OR wire_w_lg_w_data_in_range201w275w(0);
	wire_w288w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range282w285w286w287w(0) OR wire_w_lg_w_data_in_range210w284w(0);
	wire_w297w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range291w294w295w296w(0) OR wire_w_lg_w_data_in_range219w293w(0);
	wire_w306w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range300w303w304w305w(0) OR wire_w_lg_w_data_in_range228w302w(0);
	wire_w_lg_w_lg_w_lg_w_lg_w_data_in_range81w89w90w91w92w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range81w89w90w91w(0) OR wire_w_lg_w_data_in_range80w88w(0);
	wire_w102w(0) <= wire_w_lg_w_lg_w_lg_w_data_in_range96w99w100w101w(0) OR wire_w_lg_w_data_in_range95w98w(0);
	wire_w_lg_w_lg_halt_cal1102w1103w(0) <= wire_w_lg_halt_cal1102w(0) OR wire_w_lg_w_lg_halt_cal1100w1101w(0);
	wire_w_lg_w_lg_halt_cal1153w1154w(0) <= wire_w_lg_halt_cal1153w(0) OR wire_w_lg_w_lg_halt_cal1100w1152w(0);
	wire_w_lg_w_lg_halt_cal1158w1159w(0) <= wire_w_lg_halt_cal1158w(0) OR wire_w_lg_w_lg_halt_cal1100w1157w(0);
	wire_w_lg_w_lg_halt_cal1163w1164w(0) <= wire_w_lg_halt_cal1163w(0) OR wire_w_lg_w_lg_halt_cal1100w1162w(0);
	wire_w_lg_w_lg_halt_cal1169w1170w(0) <= wire_w_lg_halt_cal1169w(0) OR wire_w_lg_w_lg_halt_cal1100w1168w(0);
	wire_w_lg_w_lg_halt_cal1174w1175w(0) <= wire_w_lg_halt_cal1174w(0) OR wire_w_lg_w_lg_halt_cal1100w1173w(0);
	wire_w_lg_w_lg_halt_cal1178w1179w(0) <= wire_w_lg_halt_cal1178w(0) OR wire_w_lg_w_lg_halt_cal1100w1177w(0);
	wire_w_lg_w_lg_halt_cal1108w1109w(0) <= wire_w_lg_halt_cal1108w(0) OR wire_w_lg_w_lg_halt_cal1100w1107w(0);
	wire_w_lg_w_lg_halt_cal1113w1114w(0) <= wire_w_lg_halt_cal1113w(0) OR wire_w_lg_w_lg_halt_cal1100w1112w(0);
	wire_w_lg_w_lg_halt_cal1118w1119w(0) <= wire_w_lg_halt_cal1118w(0) OR wire_w_lg_w_lg_halt_cal1100w1117w(0);
	wire_w_lg_w_lg_halt_cal1123w1124w(0) <= wire_w_lg_halt_cal1123w(0) OR wire_w_lg_w_lg_halt_cal1100w1122w(0);
	wire_w_lg_w_lg_halt_cal1128w1129w(0) <= wire_w_lg_halt_cal1128w(0) OR wire_w_lg_w_lg_halt_cal1100w1127w(0);
	wire_w_lg_w_lg_halt_cal1133w1134w(0) <= wire_w_lg_halt_cal1133w(0) OR wire_w_lg_w_lg_halt_cal1100w1132w(0);
	wire_w_lg_w_lg_halt_cal1138w1139w(0) <= wire_w_lg_halt_cal1138w(0) OR wire_w_lg_w_lg_halt_cal1100w1137w(0);
	wire_w_lg_w_lg_halt_cal1143w1144w(0) <= wire_w_lg_halt_cal1143w(0) OR wire_w_lg_w_lg_halt_cal1100w1142w(0);
	wire_w_lg_w_lg_halt_cal1148w1149w(0) <= wire_w_lg_halt_cal1148w(0) OR wire_w_lg_w_lg_halt_cal1100w1147w(0);
	wire_w_lg_w_lg_read_address349w350w(0) <= wire_w_lg_read_address349w(0) OR wire_w_lg_w_lg_read_address322w348w(0);
	wire_w_lg_w_lg_read_address399w400w(0) <= wire_w_lg_read_address399w(0) OR wire_w_lg_w_lg_read_address322w398w(0);
	wire_w_lg_w_lg_read_address404w405w(0) <= wire_w_lg_read_address404w(0) OR wire_w_lg_w_lg_read_address322w403w(0);
	wire_w_lg_w_lg_read_address409w410w(0) <= wire_w_lg_read_address409w(0) OR wire_w_lg_w_lg_read_address322w408w(0);
	wire_w_lg_w_lg_read_address414w415w(0) <= wire_w_lg_read_address414w(0) OR wire_w_lg_w_lg_read_address322w413w(0);
	wire_w_lg_w_lg_read_address419w420w(0) <= wire_w_lg_read_address419w(0) OR wire_w_lg_w_lg_read_address322w418w(0);
	wire_w_lg_w_lg_read_address424w425w(0) <= wire_w_lg_read_address424w(0) OR wire_w_lg_w_lg_read_address322w423w(0);
	wire_w_lg_w_lg_read_address429w430w(0) <= wire_w_lg_read_address429w(0) OR wire_w_lg_w_lg_read_address322w428w(0);
	wire_w_lg_w_lg_read_address434w435w(0) <= wire_w_lg_read_address434w(0) OR wire_w_lg_w_lg_read_address322w433w(0);
	wire_w_lg_w_lg_read_address439w440w(0) <= wire_w_lg_read_address439w(0) OR wire_w_lg_w_lg_read_address322w438w(0);
	wire_w_lg_w_lg_read_address444w445w(0) <= wire_w_lg_read_address444w(0) OR wire_w_lg_w_lg_read_address322w443w(0);
	wire_w_lg_w_lg_read_address354w355w(0) <= wire_w_lg_read_address354w(0) OR wire_w_lg_w_lg_read_address322w353w(0);
	wire_w_lg_w_lg_read_address449w450w(0) <= wire_w_lg_read_address449w(0) OR wire_w_lg_w_lg_read_address322w448w(0);
	wire_w_lg_w_lg_read_address454w455w(0) <= wire_w_lg_read_address454w(0) OR wire_w_lg_w_lg_read_address322w453w(0);
	wire_w_lg_w_lg_read_address459w460w(0) <= wire_w_lg_read_address459w(0) OR wire_w_lg_w_lg_read_address322w458w(0);
	wire_w_lg_w_lg_read_address464w465w(0) <= wire_w_lg_read_address464w(0) OR wire_w_lg_w_lg_read_address322w463w(0);
	wire_w_lg_w_lg_read_address359w360w(0) <= wire_w_lg_read_address359w(0) OR wire_w_lg_w_lg_read_address322w358w(0);
	wire_w_lg_w_lg_read_address364w365w(0) <= wire_w_lg_read_address364w(0) OR wire_w_lg_w_lg_read_address322w363w(0);
	wire_w_lg_w_lg_read_address369w370w(0) <= wire_w_lg_read_address369w(0) OR wire_w_lg_w_lg_read_address322w368w(0);
	wire_w_lg_w_lg_read_address374w375w(0) <= wire_w_lg_read_address374w(0) OR wire_w_lg_w_lg_read_address322w373w(0);
	wire_w_lg_w_lg_read_address379w380w(0) <= wire_w_lg_read_address379w(0) OR wire_w_lg_w_lg_read_address322w378w(0);
	wire_w_lg_w_lg_read_address384w385w(0) <= wire_w_lg_read_address384w(0) OR wire_w_lg_w_lg_read_address322w383w(0);
	wire_w_lg_w_lg_read_address389w390w(0) <= wire_w_lg_read_address389w(0) OR wire_w_lg_w_lg_read_address322w388w(0);
	wire_w_lg_w_lg_read_address394w395w(0) <= wire_w_lg_read_address394w(0) OR wire_w_lg_w_lg_read_address322w393w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range887w888w889w(0) <= wire_w_lg_w_shift_reg_q_range887w888w(0) OR wire_add_sub12_w_lg_w_result_range885w886w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range947w948w949w(0) <= wire_w_lg_w_shift_reg_q_range947w948w(0) OR wire_add_sub12_w_lg_w_result_range945w946w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range953w954w955w(0) <= wire_w_lg_w_shift_reg_q_range953w954w(0) OR wire_add_sub12_w_lg_w_result_range951w952w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range959w960w961w(0) <= wire_w_lg_w_shift_reg_q_range959w960w(0) OR wire_add_sub12_w_lg_w_result_range957w958w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range965w966w967w(0) <= wire_w_lg_w_shift_reg_q_range965w966w(0) OR wire_add_sub12_w_lg_w_result_range963w964w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range971w972w973w(0) <= wire_w_lg_w_shift_reg_q_range971w972w(0) OR wire_add_sub12_w_lg_w_result_range969w970w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range977w978w979w(0) <= wire_w_lg_w_shift_reg_q_range977w978w(0) OR wire_add_sub12_w_lg_w_result_range975w976w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range983w984w985w(0) <= wire_w_lg_w_shift_reg_q_range983w984w(0) OR wire_add_sub12_w_lg_w_result_range981w982w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range989w990w991w(0) <= wire_w_lg_w_shift_reg_q_range989w990w(0) OR wire_add_sub12_w_lg_w_result_range987w988w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range995w996w997w(0) <= wire_w_lg_w_shift_reg_q_range995w996w(0) OR wire_add_sub12_w_lg_w_result_range993w994w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range1001w1002w1003w(0) <= wire_w_lg_w_shift_reg_q_range1001w1002w(0) OR wire_add_sub12_w_lg_w_result_range999w1000w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range893w894w895w(0) <= wire_w_lg_w_shift_reg_q_range893w894w(0) OR wire_add_sub12_w_lg_w_result_range891w892w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range1007w1008w1009w(0) <= wire_w_lg_w_shift_reg_q_range1007w1008w(0) OR wire_add_sub12_w_lg_w_result_range1005w1006w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range1013w1014w1015w(0) <= wire_w_lg_w_shift_reg_q_range1013w1014w(0) OR wire_add_sub12_w_lg_w_result_range1011w1012w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range1019w1020w1021w(0) <= wire_w_lg_w_shift_reg_q_range1019w1020w(0) OR wire_add_sub12_w_lg_w_result_range1017w1018w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range1025w1026w1027w(0) <= wire_w_lg_w_shift_reg_q_range1025w1026w(0) OR wire_add_sub12_w_lg_w_result_range1023w1024w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range899w900w901w(0) <= wire_w_lg_w_shift_reg_q_range899w900w(0) OR wire_add_sub12_w_lg_w_result_range897w898w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range905w906w907w(0) <= wire_w_lg_w_shift_reg_q_range905w906w(0) OR wire_add_sub12_w_lg_w_result_range903w904w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range911w912w913w(0) <= wire_w_lg_w_shift_reg_q_range911w912w(0) OR wire_add_sub12_w_lg_w_result_range909w910w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range917w918w919w(0) <= wire_w_lg_w_shift_reg_q_range917w918w(0) OR wire_add_sub12_w_lg_w_result_range915w916w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range923w924w925w(0) <= wire_w_lg_w_shift_reg_q_range923w924w(0) OR wire_add_sub12_w_lg_w_result_range921w922w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range929w930w931w(0) <= wire_w_lg_w_shift_reg_q_range929w930w(0) OR wire_add_sub12_w_lg_w_result_range927w928w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range935w936w937w(0) <= wire_w_lg_w_shift_reg_q_range935w936w(0) OR wire_add_sub12_w_lg_w_result_range933w934w(0);
	wire_w_lg_w_lg_w_shift_reg_q_range941w942w943w(0) <= wire_w_lg_w_shift_reg_q_range941w942w(0) OR wire_add_sub12_w_lg_w_result_range939w940w(0);
	wire_w_lg_w_lg_w_lg_w_lg_w_lg_idle655w656w657w658w659w(0) <= wire_w_lg_w_lg_w_lg_w_lg_idle655w656w657w658w(0) OR wire_w_lg_read_data651w(0);
	wire_w660w(0) <= wire_w_lg_w_lg_w_lg_w_lg_w_lg_idle655w656w657w658w659w(0) OR wire_w_lg_read_post650w(0);
	wire_w_lg_w660w661w(0) <= wire_w660w(0) OR power_up;
	wire_w_lg_w_lg_shift_reg_load_enable72w73w(0) <= wire_w_lg_shift_reg_load_enable72w(0) OR shift_reg_clear;
	wire_w_lg_get_addr1029w(0) <= get_addr OR asmi_read_wire;
	wire_w_lg_get_addr1044w(0) <= get_addr OR crc_check_st;
	wire_w_lg_shift_reg_load_enable72w(0) <= shift_reg_load_enable OR shift_reg_shift_enable;
	asmi_addr <= wire_add_sub12_result;
	asmi_rden <= asmi_read_out;
	asmi_read <= asmi_read_out;
	asmi_read_out <= ((crc_chk_st_dffe(0) OR asmi_read_reg(0)) AND (NOT pof_counter_l42(0)));
	asmi_read_wire <= (crc_chk_st_dffe(0) OR asmi_read_reg(0));
	bit_counter_all_done <= (((((wire_cntr2_q(0) AND wire_cntr2_q(1)) AND (NOT wire_cntr2_q(2))) AND wire_cntr2_q(3)) AND (NOT wire_cntr2_q(4))) AND wire_cntr2_q(5));
	bit_counter_clear <= (read_init OR write_init);
	bit_counter_enable <= (((((((((read_init OR write_init) OR read_init_counter) OR write_init_counter) OR read_pre_data) OR write_pre_data) OR read_data) OR write_data) OR read_post) OR write_post_data);
	bit_counter_param_start <= start_bit_decoder_out;
	bit_counter_param_start_match <= ((((((NOT w22w(0)) AND (NOT w22w(1))) AND (NOT w22w(2))) AND (NOT w22w(3))) AND (NOT w22w(4))) AND (NOT w22w(5)));
	busy <= ((wire_w_lg_idle636w(0) OR check_busy_dffe(0)) OR ru_reconfig_pof);
	cal_addr <= cal_addr_reg(0);
	chk_crc_counter_enable <= (((((((wire_cntr8_w_lg_w_lg_w_lg_w_lg_w_q_range776w795w800w803w804w(0) OR wire_cntr8_w_lg_w_lg_w_lg_w_lg_w_q_range776w795w800w801w802w(0)) OR (wire_cntr8_w_lg_w_lg_w_q_range776w795w796w(0) AND wire_cntr8_w_lg_w_q_range772w773w(0))) OR wire_cntr8_w_lg_w_lg_w_lg_w_lg_w_q_range776w795w796w797w798w(0)) OR ((wire_cntr8_w_lg_w_q_range776w777w(0) AND wire_cntr8_w_lg_w_q_range772w773w(0)) AND wire_w_lg_asmi_busy793w(0))) OR (wire_cntr8_w_lg_w_q_range776w777w(0) AND wire_cntr8_q(0))) OR wire_cntr8_w_lg_w_lg_w_lg_w_q_range776w789w790w791w(0)) OR wire_cntr8_w_lg_w_lg_w_q_range776w789w790w(0));
	chk_pof_counter_enable <= (((((((wire_cntr7_w_lg_w_lg_w_lg_w_lg_w_q_range744w754w761w763w764w(0) OR (wire_cntr7_w_lg_w_lg_w_q_range744w754w761w(0) AND wire_cntr7_q(0))) OR ((((wire_cntr7_w_lg_w_q_range744w754w(0) AND wire_cntr7_q(1)) AND wire_cntr7_w_lg_w_q_range742w747w(0)) AND wire_w_lg_bit_counter_enable757w(0)) AND wire_w_lg_read_control_reg652w(0))) OR ((wire_cntr7_w_lg_w_q_range744w754w(0) AND wire_cntr7_q(1)) AND wire_cntr7_q(0))) OR (wire_cntr7_w_lg_w_q_range744w751w(0) AND wire_cntr7_w_lg_w_q_range742w747w(0))) OR (wire_cntr7_w_lg_w_q_range744w751w(0) AND wire_cntr7_q(0))) OR wire_cntr7_w_lg_w_lg_w_lg_w_q_range744w745w748w749w(0)) OR (wire_cntr7_w_lg_w_q_range744w745w(0) AND wire_cntr7_q(0)));
	chk_pof_counter_start <= (idle AND reconfig);
	crc <= crc_reg;
	crc_cal <= (crc_cal_reg(0) AND (NOT crc_done_reg(0)));
	crc_check_end <= crc_check_end_reg(0);
	crc_check_st <= crc_chk_st_dffe(0);
	crc_check_st_wire <= (wire_cntr7_w_lg_w_q_range744w751w(0) AND wire_cntr7_q(0));
	crc_enable_wire <= (crc_cal OR crc_check_st_wire);
	crc_reg_wire <= ( wire_w_lg_w_lg_halt_cal1178w1179w & wire_w_lg_w_lg_halt_cal1174w1175w & wire_w_lg_w_lg_halt_cal1169w1170w & wire_w_lg_w_lg_halt_cal1163w1164w & wire_w_lg_w_lg_halt_cal1158w1159w & wire_w_lg_w_lg_halt_cal1153w1154w & wire_w_lg_w_lg_halt_cal1148w1149w & wire_w_lg_w_lg_halt_cal1143w1144w & wire_w_lg_w_lg_halt_cal1138w1139w & wire_w_lg_w_lg_halt_cal1133w1134w & wire_w_lg_w_lg_halt_cal1128w1129w & wire_w_lg_w_lg_halt_cal1123w1124w & wire_w_lg_w_lg_halt_cal1118w1119w & wire_w_lg_w_lg_halt_cal1113w1114w & wire_w_lg_w_lg_halt_cal1108w1109w & wire_w_lg_w_lg_halt_cal1102w1103w);
	crc_shift_done <= ((wire_cntr9_q(2) AND wire_cntr9_q(1)) AND (NOT wire_cntr9_q(0)));
	data_out <= ( wire_w_lg_w_lg_read_address464w465w & wire_w_lg_w_lg_read_address459w460w & wire_w_lg_w_lg_read_address454w455w & wire_w_lg_w_lg_read_address449w450w & wire_w_lg_w_lg_read_address444w445w & wire_w_lg_w_lg_read_address439w440w & wire_w_lg_w_lg_read_address434w435w & wire_w_lg_w_lg_read_address429w430w & wire_w_lg_w_lg_read_address424w425w & wire_w_lg_w_lg_read_address419w420w & wire_w_lg_w_lg_read_address414w415w & wire_w_lg_w_lg_read_address409w410w & wire_w_lg_w_lg_read_address404w405w & wire_w_lg_w_lg_read_address399w400w & wire_w_lg_w_lg_read_address394w395w & wire_w_lg_w_lg_read_address389w390w & wire_w_lg_w_lg_read_address384w385w & wire_w_lg_w_lg_read_address379w380w & wire_w_lg_w_lg_read_address374w375w & wire_w_lg_w_lg_read_address369w370w & wire_w_lg_w_lg_read_address364w365w & wire_w_lg_w_lg_read_address359w360w & wire_w_lg_w_lg_read_address354w355w & wire_w_lg_w_lg_read_address349w350w & wire_w_lg_w_lg_read_address322w345w & wire_w_lg_w_lg_read_address322w342w & wire_w_lg_w_lg_read_address322w339w & wire_w_lg_w_lg_read_address322w336w & wire_w_lg_w_lg_read_address322w333w & wire_w_lg_w_lg_read_address322w330w & wire_w_lg_w_lg_read_address322w327w & wire_w_lg_w_lg_read_address322w323w);
	get_addr <= get_addr_reg(0);
	halt_cal <= '0';
	idle <= idle_state;
	invert_bits <= (wire_shift_reg13_shiftout XOR crc_reg(0));
	load_crc_high <= load_crc_high_reg(0);
	load_crc_low <= load_crc_low_reg(0);
	load_data <= load_data_reg(0);
	param_addr <= ( "1" & "0" & "0");
	param_decoder_param_latch <= dffe6a;
	param_decoder_select <= ( wire_w623w & wire_w_lg_w608w620w & wire_w618w & wire_w_lg_w614w615w & wire_w_lg_w608w611w);
	param_port_combine <= (wire_w_lg_param740w OR wire_w_lg_read_control_reg739w);
	pof_counter_40 <= ((((((wire_cntr10_w_lg_w_q_range838w839w(0) AND wire_cntr10_q(5)) AND (NOT wire_cntr10_q(4))) AND (NOT wire_cntr10_q(3))) AND (NOT wire_cntr10_q(2))) AND wire_cntr10_q(1)) AND (NOT wire_cntr10_q(0)));
	pof_error <= pof_error_reg(0);
	pof_error_wire <= ((((((((((((((((crc(0) XOR crc_low(0)) OR (crc(8) XOR crc_high(0))) OR (crc(1) XOR crc_low(1))) OR (crc(9) XOR crc_high(1))) OR (crc(2) XOR crc_low(2))) OR (crc(10) XOR crc_high(2))) OR (crc(3) XOR crc_low(3))) OR (crc(11) XOR crc_high(3))) OR (crc(4) XOR crc_low(4))) OR (crc(12) XOR crc_high(4))) OR (crc(5) XOR crc_low(5))) OR (crc(13) XOR crc_high(5))) OR (crc(6) XOR crc_low(6))) OR (crc(14) XOR crc_high(6))) OR (crc(7) XOR crc_low(7))) OR (crc(15) XOR crc_high(7)));
	power_up <= ((((((((((((wire_w_lg_idle636w(0) AND wire_w_lg_read_init635w(0)) AND wire_w_lg_read_init_counter634w(0)) AND wire_w_lg_read_pre_data633w(0)) AND wire_w_lg_read_data632w(0)) AND wire_w_lg_read_post631w(0)) AND wire_w_lg_write_init630w(0)) AND wire_w_lg_write_init_counter629w(0)) AND wire_w_lg_write_pre_data628w(0)) AND wire_w_lg_write_data627w(0)) AND wire_w_lg_write_post_data626w(0)) AND wire_w_lg_write_load625w(0)) AND wire_w_lg_write_wait624w(0));
	read_address <= read_address_state;
	read_control_reg <= read_control_reg_dffe(0);
	read_data <= read_data_state;
	read_init <= read_init_state;
	read_init_counter <= read_init_counter_state;
	read_post <= read_post_state;
	read_pre_data <= read_pre_data_state;
	ru_reconfig_pof <= ru_reconfig_pof_reg(0);
	rublock_captnupdt <= wire_w_lg_write_load625w(0);
	rublock_clock <= (NOT (clock OR idle_write_wait));
	rublock_reconfig <= re_config_reg;
	rublock_regin <= (wire_w_lg_rublock_regout_reg712w(0) OR (shift_reg_serial_out AND select_shift_nloop));
	rublock_regout <= wire_sd1_regout;
	rublock_regout_reg <= dffe5;
	rublock_shiftnld <= (((((read_pre_data OR write_pre_data) OR read_data) OR write_data) OR read_post) OR write_post_data);
	select_shift_nloop <= (wire_w_lg_read_data672w(0) OR wire_w_lg_write_data687w(0));
	shift_reg_clear <= (idle AND (read_param OR read_control_reg));
	shift_reg_load_enable <= (idle AND write_param);
	shift_reg_q <= dffe4a;
	shift_reg_serial_in <= (rublock_regout_reg AND select_shift_nloop);
	shift_reg_serial_out <= dffe4a(0);
	shift_reg_shift_enable <= (((read_data OR write_data) OR read_post) OR write_post_data);
	start_bit_decoder_out <= ((((( "0" & "0" & "0" & "0" & "0" & "0") OR ( "0" & start_bit_decoder_param_select(1) & start_bit_decoder_param_select(1) & start_bit_decoder_param_select(1) & start_bit_decoder_param_select(1) & start_bit_decoder_param_select(1))) OR ( "0" & start_bit_decoder_param_select(2) & start_bit_decoder_param_select(2) & start_bit_decoder_param_select(2) & start_bit_decoder_param_select(2) & "0")) OR ( "0" & "0" & "0" & start_bit_decoder_param_select(3) & start_bit_decoder_param_select(3) & "0")) OR ( "0" & "0" & "0" & start_bit_decoder_param_select(4) & "0" & start_bit_decoder_param_select(4)));
	start_bit_decoder_param_select <= param_decoder_select;
	w22w <= (wire_cntr2_q XOR bit_counter_param_start);
	w53w <= (wire_cntr3_q XOR width_counter_param_width);
	w8w <= ((wire_w_lg_idle636w(0) OR check_busy_dffe(0)) OR ru_reconfig_pof);
	width_counter_all_done <= (((((wire_cntr3_q(0) AND wire_cntr3_q(1)) AND wire_cntr3_q(2)) AND wire_cntr3_q(3)) AND wire_cntr3_q(4)) AND (NOT wire_cntr3_q(5)));
	width_counter_clear <= (read_init OR write_init);
	width_counter_enable <= ((read_data OR write_data) OR read_post);
	width_counter_param_width <= width_decoder_out;
	width_counter_param_width_match <= ((((((NOT w53w(0)) AND (NOT w53w(1))) AND (NOT w53w(2))) AND (NOT w53w(3))) AND (NOT w53w(4))) AND (NOT w53w(5)));
	width_decoder_out <= ((((( "0" & "0" & "0" & width_decoder_param_select(0) & "0" & width_decoder_param_select(0)) OR ( "0" & "0" & width_decoder_param_select(1) & width_decoder_param_select(1) & "0" & "0")) OR ( "0" & "0" & "0" & "0" & "0" & width_decoder_param_select(2))) OR ( "0" & width_decoder_param_select(3) & width_decoder_param_select(3) & "0" & "0" & "0")) OR ( "0" & "0" & "0" & "0" & "0" & width_decoder_param_select(4)));
	width_decoder_param_select <= param_decoder_select;
	write_data <= write_data_state;
	write_init <= write_init_state;
	write_init_counter <= write_init_counter_state;
	write_load <= write_load_state;
	write_post_data <= write_post_data_state;
	write_pre_data <= write_pre_data_state;
	write_wait <= write_wait_state;
	wire_w_data_in_range80w(0) <= data_in(0);
	wire_w_data_in_range106w(0) <= data_in(10);
	wire_w_data_in_range116w(0) <= data_in(11);
	wire_w_data_in_range126w(0) <= data_in(12);
	wire_w_data_in_range136w(0) <= data_in(13);
	wire_w_data_in_range146w(0) <= data_in(14);
	wire_w_data_in_range156w(0) <= data_in(15);
	wire_w_data_in_range165w(0) <= data_in(16);
	wire_w_data_in_range174w(0) <= data_in(17);
	wire_w_data_in_range183w(0) <= data_in(18);
	wire_w_data_in_range192w(0) <= data_in(19);
	wire_w_data_in_range95w(0) <= data_in(1);
	wire_w_data_in_range201w(0) <= data_in(20);
	wire_w_data_in_range210w(0) <= data_in(21);
	wire_w_data_in_range219w(0) <= data_in(22);
	wire_w_data_in_range228w(0) <= data_in(23);
	wire_w_data_in_range237w(0) <= data_in(24);
	wire_w_data_in_range246w(0) <= data_in(25);
	wire_w_data_in_range255w(0) <= data_in(26);
	wire_w_data_in_range264w(0) <= data_in(27);
	wire_w_data_in_range273w(0) <= data_in(28);
	wire_w_data_in_range282w(0) <= data_in(29);
	wire_w_data_in_range105w(0) <= data_in(2);
	wire_w_data_in_range291w(0) <= data_in(30);
	wire_w_data_in_range300w(0) <= data_in(31);
	wire_w_data_in_range115w(0) <= data_in(3);
	wire_w_data_in_range125w(0) <= data_in(4);
	wire_w_data_in_range135w(0) <= data_in(5);
	wire_w_data_in_range145w(0) <= data_in(6);
	wire_w_data_in_range155w(0) <= data_in(7);
	wire_w_data_in_range81w(0) <= data_in(8);
	wire_w_data_in_range96w(0) <= data_in(9);
	wire_w_param_range77w(0) <= param(0);
	wire_w_param_range78w(0) <= param(1);
	wire_w_param_range79w(0) <= param(2);
	wire_w_param_decoder_param_latch_range604w(0) <= param_decoder_param_latch(0);
	wire_w_param_decoder_param_latch_range606w(0) <= param_decoder_param_latch(1);
	wire_w_param_decoder_param_latch_range609w(0) <= param_decoder_param_latch(2);
	wire_w_shift_reg_q_range887w(0) <= shift_reg_q(0);
	wire_w_shift_reg_q_range947w(0) <= shift_reg_q(10);
	wire_w_shift_reg_q_range953w(0) <= shift_reg_q(11);
	wire_w_shift_reg_q_range959w(0) <= shift_reg_q(12);
	wire_w_shift_reg_q_range965w(0) <= shift_reg_q(13);
	wire_w_shift_reg_q_range971w(0) <= shift_reg_q(14);
	wire_w_shift_reg_q_range977w(0) <= shift_reg_q(15);
	wire_w_shift_reg_q_range983w(0) <= shift_reg_q(16);
	wire_w_shift_reg_q_range989w(0) <= shift_reg_q(17);
	wire_w_shift_reg_q_range995w(0) <= shift_reg_q(18);
	wire_w_shift_reg_q_range1001w(0) <= shift_reg_q(19);
	wire_w_shift_reg_q_range893w(0) <= shift_reg_q(1);
	wire_w_shift_reg_q_range1007w(0) <= shift_reg_q(20);
	wire_w_shift_reg_q_range1013w(0) <= shift_reg_q(21);
	wire_w_shift_reg_q_range1019w(0) <= shift_reg_q(22);
	wire_w_shift_reg_q_range1025w(0) <= shift_reg_q(23);
	wire_w_shift_reg_q_range899w(0) <= shift_reg_q(2);
	wire_w_shift_reg_q_range905w(0) <= shift_reg_q(3);
	wire_w_shift_reg_q_range911w(0) <= shift_reg_q(4);
	wire_w_shift_reg_q_range917w(0) <= shift_reg_q(5);
	wire_w_shift_reg_q_range923w(0) <= shift_reg_q(6);
	wire_w_shift_reg_q_range929w(0) <= shift_reg_q(7);
	wire_w_shift_reg_q_range935w(0) <= shift_reg_q(8);
	wire_w_shift_reg_q_range941w(0) <= shift_reg_q(9);
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asim_data_reg <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (asmi_data_valid = '1') THEN asim_data_reg <= ( asmi_dataout(0) & asmi_dataout(1) & asmi_dataout(2) & asmi_dataout(3) & asmi_dataout(4) & asmi_dataout(5) & asmi_dataout(6) & asmi_dataout(7));
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(0) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(0) = '1') THEN asmi_addr_st(0) <= wire_asmi_addr_st_d(0);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(1) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(1) = '1') THEN asmi_addr_st(1) <= wire_asmi_addr_st_d(1);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(2) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(2) = '1') THEN asmi_addr_st(2) <= wire_asmi_addr_st_d(2);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(3) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(3) = '1') THEN asmi_addr_st(3) <= wire_asmi_addr_st_d(3);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(4) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(4) = '1') THEN asmi_addr_st(4) <= wire_asmi_addr_st_d(4);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(5) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(5) = '1') THEN asmi_addr_st(5) <= wire_asmi_addr_st_d(5);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(6) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(6) = '1') THEN asmi_addr_st(6) <= wire_asmi_addr_st_d(6);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(7) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(7) = '1') THEN asmi_addr_st(7) <= wire_asmi_addr_st_d(7);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(8) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(8) = '1') THEN asmi_addr_st(8) <= wire_asmi_addr_st_d(8);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(9) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(9) = '1') THEN asmi_addr_st(9) <= wire_asmi_addr_st_d(9);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(10) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(10) = '1') THEN asmi_addr_st(10) <= wire_asmi_addr_st_d(10);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(11) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(11) = '1') THEN asmi_addr_st(11) <= wire_asmi_addr_st_d(11);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(12) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(12) = '1') THEN asmi_addr_st(12) <= wire_asmi_addr_st_d(12);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(13) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(13) = '1') THEN asmi_addr_st(13) <= wire_asmi_addr_st_d(13);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(14) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(14) = '1') THEN asmi_addr_st(14) <= wire_asmi_addr_st_d(14);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(15) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(15) = '1') THEN asmi_addr_st(15) <= wire_asmi_addr_st_d(15);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(16) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(16) = '1') THEN asmi_addr_st(16) <= wire_asmi_addr_st_d(16);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(17) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(17) = '1') THEN asmi_addr_st(17) <= wire_asmi_addr_st_d(17);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(18) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(18) = '1') THEN asmi_addr_st(18) <= wire_asmi_addr_st_d(18);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(19) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(19) = '1') THEN asmi_addr_st(19) <= wire_asmi_addr_st_d(19);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(20) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(20) = '1') THEN asmi_addr_st(20) <= wire_asmi_addr_st_d(20);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(21) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(21) = '1') THEN asmi_addr_st(21) <= wire_asmi_addr_st_d(21);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(22) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(22) = '1') THEN asmi_addr_st(22) <= wire_asmi_addr_st_d(22);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(23) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(23) = '1') THEN asmi_addr_st(23) <= wire_asmi_addr_st_d(23);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(24) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(24) = '1') THEN asmi_addr_st(24) <= wire_asmi_addr_st_d(24);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(25) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(25) = '1') THEN asmi_addr_st(25) <= wire_asmi_addr_st_d(25);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(26) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(26) = '1') THEN asmi_addr_st(26) <= wire_asmi_addr_st_d(26);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(27) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(27) = '1') THEN asmi_addr_st(27) <= wire_asmi_addr_st_d(27);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(28) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(28) = '1') THEN asmi_addr_st(28) <= wire_asmi_addr_st_d(28);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(29) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(29) = '1') THEN asmi_addr_st(29) <= wire_asmi_addr_st_d(29);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(30) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(30) = '1') THEN asmi_addr_st(30) <= wire_asmi_addr_st_d(30);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_addr_st(31) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_asmi_addr_st_ena(31) = '1') THEN asmi_addr_st(31) <= wire_asmi_addr_st_d(31);
			END IF;
		END IF;
	END PROCESS;
	wire_asmi_addr_st_d <= ( wire_w_lg_w_lg_w_shift_reg_q_range1025w1026w1027w & wire_w_lg_w_lg_w_shift_reg_q_range1019w1020w1021w & wire_w_lg_w_lg_w_shift_reg_q_range1013w1014w1015w & wire_w_lg_w_lg_w_shift_reg_q_range1007w1008w1009w & wire_w_lg_w_lg_w_shift_reg_q_range1001w1002w1003w & wire_w_lg_w_lg_w_shift_reg_q_range995w996w997w & wire_w_lg_w_lg_w_shift_reg_q_range989w990w991w & wire_w_lg_w_lg_w_shift_reg_q_range983w984w985w & wire_w_lg_w_lg_w_shift_reg_q_range977w978w979w & wire_w_lg_w_lg_w_shift_reg_q_range971w972w973w & wire_w_lg_w_lg_w_shift_reg_q_range965w966w967w & wire_w_lg_w_lg_w_shift_reg_q_range959w960w961w & wire_w_lg_w_lg_w_shift_reg_q_range953w954w955w & wire_w_lg_w_lg_w_shift_reg_q_range947w948w949w & wire_w_lg_w_lg_w_shift_reg_q_range941w942w943w & wire_w_lg_w_lg_w_shift_reg_q_range935w936w937w & wire_w_lg_w_lg_w_shift_reg_q_range929w930w931w & wire_w_lg_w_lg_w_shift_reg_q_range923w924w925w & wire_w_lg_w_lg_w_shift_reg_q_range917w918w919w & wire_w_lg_w_lg_w_shift_reg_q_range911w912w913w & wire_w_lg_w_lg_w_shift_reg_q_range905w906w907w & wire_w_lg_w_lg_w_shift_reg_q_range899w900w901w & wire_w_lg_w_lg_w_shift_reg_q_range893w894w895w & wire_w_lg_w_lg_w_shift_reg_q_range887w888w889w & wire_add_sub12_w_lg_w_result_range882w883w & wire_add_sub12_w_lg_w_result_range879w880w & wire_add_sub12_w_lg_w_result_range876w877w & wire_add_sub12_w_lg_w_result_range873w874w & wire_add_sub12_w_lg_w_result_range870w871w & wire_add_sub12_w_lg_w_result_range867w868w & wire_add_sub12_w_lg_w_result_range864w865w & wire_add_sub12_w_lg_w_result_range860w861w);
	loop2 : FOR i IN 0 TO 31 GENERATE
		wire_asmi_addr_st_ena(i) <= wire_w_lg_get_addr1029w(0);
	END GENERATE loop2;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN asmi_read_reg <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (check_busy_dffe = '1') THEN asmi_read_reg(0) <= (wire_cntr8_w_lg_w_q_range776w777w(0) AND wire_cntr8_q(0));
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN cal_addr_reg <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (check_busy_dffe = '1') THEN cal_addr_reg(0) <= (get_addr_reg(0) OR (wire_cntr8_w_lg_w_q_range776w777w(0) AND wire_cntr8_w_lg_w_q_range772w773w(0)));
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN check_busy_dffe <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN check_busy_dffe(0) <= ((wire_cntr7_q(2) OR wire_cntr7_q(1)) OR wire_cntr7_q(0));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_cal_reg <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN crc_cal_reg <= wire_cntr8_w_lg_w_lg_w_lg_w_q_range776w795w796w797w;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_check_end_reg <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN crc_check_end_reg <= wire_cntr7_w_lg_w_lg_w_lg_w_q_range744w745w748w749w;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_chk_st_dffe <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN crc_chk_st_dffe(0) <= crc_check_st_wire;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_done_reg <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_crc_done_reg_ena = "1") THEN 
				IF (chk_pof_counter_start = '1') THEN crc_done_reg <= (OTHERS => '0');
				ELSE crc_done_reg(0) <= pof_counter_40;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	wire_crc_done_reg_ena(0) <= (pof_counter_40 OR chk_pof_counter_start);
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_high <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (load_crc_high = '1') THEN crc_high <= asim_data_reg;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_low <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (load_crc_low = '1') THEN crc_low <= asim_data_reg;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(0) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(0) <= wire_crc_reg_asdata(0);
				ELSE crc_reg(0) <= crc_reg_wire(0);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(1) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(1) <= wire_crc_reg_asdata(1);
				ELSE crc_reg(1) <= crc_reg_wire(1);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(2) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(2) <= wire_crc_reg_asdata(2);
				ELSE crc_reg(2) <= crc_reg_wire(2);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(3) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(3) <= wire_crc_reg_asdata(3);
				ELSE crc_reg(3) <= crc_reg_wire(3);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(4) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(4) <= wire_crc_reg_asdata(4);
				ELSE crc_reg(4) <= crc_reg_wire(4);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(5) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(5) <= wire_crc_reg_asdata(5);
				ELSE crc_reg(5) <= crc_reg_wire(5);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(6) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(6) <= wire_crc_reg_asdata(6);
				ELSE crc_reg(6) <= crc_reg_wire(6);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(7) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(7) <= wire_crc_reg_asdata(7);
				ELSE crc_reg(7) <= crc_reg_wire(7);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(8) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(8) <= wire_crc_reg_asdata(8);
				ELSE crc_reg(8) <= crc_reg_wire(8);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(9) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(9) <= wire_crc_reg_asdata(9);
				ELSE crc_reg(9) <= crc_reg_wire(9);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(10) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(10) <= wire_crc_reg_asdata(10);
				ELSE crc_reg(10) <= crc_reg_wire(10);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(11) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(11) <= wire_crc_reg_asdata(11);
				ELSE crc_reg(11) <= crc_reg_wire(11);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(12) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(12) <= wire_crc_reg_asdata(12);
				ELSE crc_reg(12) <= crc_reg_wire(12);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(13) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(13) <= wire_crc_reg_asdata(13);
				ELSE crc_reg(13) <= crc_reg_wire(13);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(14) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(14) <= wire_crc_reg_asdata(14);
				ELSE crc_reg(14) <= crc_reg_wire(14);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN crc_reg(15) <= '1';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (crc_enable_wire = '1') THEN 
				IF (crc_check_st_wire = '1') THEN crc_reg(15) <= wire_crc_reg_asdata(15);
				ELSE crc_reg(15) <= crc_reg_wire(15);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	wire_crc_reg_asdata <= ( "1" & "1" & "1" & "1" & "1" & "1" & "1" & "1" & "1" & "1" & "1" & "1" & "1" & "1" & "1");
	wire_crc_reg_w_lg_w_q_range1165w1167w(0) <= wire_crc_reg_w_q_range1165w(0) XOR invert_bits;
	wire_crc_reg_w_lg_w_q_range1097w1099w(0) <= wire_crc_reg_w_q_range1097w(0) XOR invert_bits;
	wire_crc_reg_w_q_range1064w(0) <= crc_reg(0);
	wire_crc_reg_w_q_range1145w(0) <= crc_reg(10);
	wire_crc_reg_w_q_range1150w(0) <= crc_reg(11);
	wire_crc_reg_w_q_range1155w(0) <= crc_reg(12);
	wire_crc_reg_w_q_range1160w(0) <= crc_reg(13);
	wire_crc_reg_w_q_range1165w(0) <= crc_reg(14);
	wire_crc_reg_w_q_range1171w(0) <= crc_reg(15);
	wire_crc_reg_w_q_range1097w(0) <= crc_reg(1);
	wire_crc_reg_w_q_range1105w(0) <= crc_reg(2);
	wire_crc_reg_w_q_range1110w(0) <= crc_reg(3);
	wire_crc_reg_w_q_range1115w(0) <= crc_reg(4);
	wire_crc_reg_w_q_range1120w(0) <= crc_reg(5);
	wire_crc_reg_w_q_range1125w(0) <= crc_reg(6);
	wire_crc_reg_w_q_range1130w(0) <= crc_reg(7);
	wire_crc_reg_w_q_range1135w(0) <= crc_reg(8);
	wire_crc_reg_w_q_range1140w(0) <= crc_reg(9);
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(0) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(0) = '1') THEN dataa_switch(0) <= wire_dataa_switch_d(0);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(1) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(1) = '1') THEN dataa_switch(1) <= wire_dataa_switch_d(1);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(2) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(2) = '1') THEN dataa_switch(2) <= wire_dataa_switch_d(2);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(3) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(3) = '1') THEN dataa_switch(3) <= wire_dataa_switch_d(3);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(4) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(4) = '1') THEN dataa_switch(4) <= wire_dataa_switch_d(4);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(5) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(5) = '1') THEN dataa_switch(5) <= wire_dataa_switch_d(5);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(6) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(6) = '1') THEN dataa_switch(6) <= wire_dataa_switch_d(6);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(7) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(7) = '1') THEN dataa_switch(7) <= wire_dataa_switch_d(7);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(8) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(8) = '1') THEN dataa_switch(8) <= wire_dataa_switch_d(8);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(9) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(9) = '1') THEN dataa_switch(9) <= wire_dataa_switch_d(9);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(10) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(10) = '1') THEN dataa_switch(10) <= wire_dataa_switch_d(10);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(11) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(11) = '1') THEN dataa_switch(11) <= wire_dataa_switch_d(11);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(12) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(12) = '1') THEN dataa_switch(12) <= wire_dataa_switch_d(12);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(13) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(13) = '1') THEN dataa_switch(13) <= wire_dataa_switch_d(13);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(14) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(14) = '1') THEN dataa_switch(14) <= wire_dataa_switch_d(14);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(15) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(15) = '1') THEN dataa_switch(15) <= wire_dataa_switch_d(15);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(16) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(16) = '1') THEN dataa_switch(16) <= wire_dataa_switch_d(16);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(17) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(17) = '1') THEN dataa_switch(17) <= wire_dataa_switch_d(17);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(18) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(18) = '1') THEN dataa_switch(18) <= wire_dataa_switch_d(18);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(19) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(19) = '1') THEN dataa_switch(19) <= wire_dataa_switch_d(19);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(20) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(20) = '1') THEN dataa_switch(20) <= wire_dataa_switch_d(20);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(21) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(21) = '1') THEN dataa_switch(21) <= wire_dataa_switch_d(21);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(22) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(22) = '1') THEN dataa_switch(22) <= wire_dataa_switch_d(22);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(23) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(23) = '1') THEN dataa_switch(23) <= wire_dataa_switch_d(23);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(24) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(24) = '1') THEN dataa_switch(24) <= wire_dataa_switch_d(24);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(25) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(25) = '1') THEN dataa_switch(25) <= wire_dataa_switch_d(25);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(26) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(26) = '1') THEN dataa_switch(26) <= wire_dataa_switch_d(26);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(27) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(27) = '1') THEN dataa_switch(27) <= wire_dataa_switch_d(27);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(28) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(28) = '1') THEN dataa_switch(28) <= wire_dataa_switch_d(28);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(29) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(29) = '1') THEN dataa_switch(29) <= wire_dataa_switch_d(29);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(30) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(30) = '1') THEN dataa_switch(30) <= wire_dataa_switch_d(30);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dataa_switch(31) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dataa_switch_ena(31) = '1') THEN dataa_switch(31) <= wire_dataa_switch_d(31);
			END IF;
		END IF;
	END PROCESS;
	wire_dataa_switch_d <= ( "000000000000000000000000" & wire_w_lg_get_addr1037w & "0000" & wire_w_lg_get_addr1037w & "0" & wire_w_lg_w_lg_get_addr1030w1031w);
	loop3 : FOR i IN 0 TO 31 GENERATE
		wire_dataa_switch_ena(i) <= wire_w_lg_get_addr1044w(0);
	END GENERATE loop3;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(0) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(0) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(0) <= '0';
				ELSE dffe4a(0) <= (wire_w_lg_shift_reg_load_enable93w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w82w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(1) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(1) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(1) <= '0';
				ELSE dffe4a(1) <= (wire_w_lg_shift_reg_load_enable103w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w97w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(2) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(2) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(2) <= '0';
				ELSE dffe4a(2) <= (wire_w_lg_shift_reg_load_enable113w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w107w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(3) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(3) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(3) <= '0';
				ELSE dffe4a(3) <= (wire_w_lg_shift_reg_load_enable123w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w117w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(4) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(4) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(4) <= '0';
				ELSE dffe4a(4) <= (wire_w_lg_shift_reg_load_enable133w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w127w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(5) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(5) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(5) <= '0';
				ELSE dffe4a(5) <= (wire_w_lg_shift_reg_load_enable143w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w137w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(6) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(6) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(6) <= '0';
				ELSE dffe4a(6) <= (wire_w_lg_shift_reg_load_enable153w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w147w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(7) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(7) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(7) <= '0';
				ELSE dffe4a(7) <= (wire_w_lg_shift_reg_load_enable163w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w157w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(8) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(8) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(8) <= '0';
				ELSE dffe4a(8) <= (wire_w_lg_shift_reg_load_enable172w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w166w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(9) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(9) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(9) <= '0';
				ELSE dffe4a(9) <= (wire_w_lg_shift_reg_load_enable181w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w175w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(10) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(10) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(10) <= '0';
				ELSE dffe4a(10) <= (wire_w_lg_shift_reg_load_enable190w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w184w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(11) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(11) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(11) <= '0';
				ELSE dffe4a(11) <= (wire_w_lg_shift_reg_load_enable199w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w193w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(12) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(12) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(12) <= '0';
				ELSE dffe4a(12) <= (wire_w_lg_shift_reg_load_enable208w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w202w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(13) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(13) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(13) <= '0';
				ELSE dffe4a(13) <= (wire_w_lg_shift_reg_load_enable217w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w211w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(14) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(14) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(14) <= '0';
				ELSE dffe4a(14) <= (wire_w_lg_shift_reg_load_enable226w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w220w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(15) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(15) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(15) <= '0';
				ELSE dffe4a(15) <= (wire_w_lg_shift_reg_load_enable235w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w229w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(16) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(16) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(16) <= '0';
				ELSE dffe4a(16) <= (wire_w_lg_shift_reg_load_enable244w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w238w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(17) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(17) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(17) <= '0';
				ELSE dffe4a(17) <= (wire_w_lg_shift_reg_load_enable253w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w247w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(18) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(18) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(18) <= '0';
				ELSE dffe4a(18) <= (wire_w_lg_shift_reg_load_enable262w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w256w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(19) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(19) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(19) <= '0';
				ELSE dffe4a(19) <= (wire_w_lg_shift_reg_load_enable271w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w265w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(20) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(20) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(20) <= '0';
				ELSE dffe4a(20) <= (wire_w_lg_shift_reg_load_enable280w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w274w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(21) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(21) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(21) <= '0';
				ELSE dffe4a(21) <= (wire_w_lg_shift_reg_load_enable289w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w283w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(22) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(22) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(22) <= '0';
				ELSE dffe4a(22) <= (wire_w_lg_shift_reg_load_enable298w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w292w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(23) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(23) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(23) <= '0';
				ELSE dffe4a(23) <= (wire_w_lg_shift_reg_load_enable307w(0) OR wire_w_lg_w_lg_shift_reg_load_enable75w301w(0));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(24) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(24) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(24) <= '0';
				ELSE dffe4a(24) <= (wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(25));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(25) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(25) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(25) <= '0';
				ELSE dffe4a(25) <= (wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(26));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(26) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(26) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(26) <= '0';
				ELSE dffe4a(26) <= (wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(27));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(27) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(27) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(27) <= '0';
				ELSE dffe4a(27) <= (wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(28));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(28) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(28) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(28) <= '0';
				ELSE dffe4a(28) <= (wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(29));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(29) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(29) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(29) <= '0';
				ELSE dffe4a(29) <= (wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(30));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(30) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(30) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(30) <= '0';
				ELSE dffe4a(30) <= (wire_w_lg_shift_reg_load_enable75w(0) AND dffe4a(31));
				END IF;
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe4a(31) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe4a_ena(31) = '1') THEN 
				IF (shift_reg_clear = '1') THEN dffe4a(31) <= '0';
				ELSE dffe4a(31) <= (wire_w_lg_shift_reg_load_enable75w(0) AND shift_reg_serial_in);
				END IF;
			END IF;
		END IF;
	END PROCESS;
	loop4 : FOR i IN 0 TO 31 GENERATE
		wire_dffe4a_ena(i) <= wire_w_lg_w_lg_shift_reg_load_enable72w73w(0);
	END GENERATE loop4;
	wire_dffe4a_w_q_range320w(0) <= dffe4a(0);
	wire_dffe4a_w_q_range356w(0) <= dffe4a(10);
	wire_dffe4a_w_q_range361w(0) <= dffe4a(11);
	wire_dffe4a_w_q_range366w(0) <= dffe4a(12);
	wire_dffe4a_w_q_range371w(0) <= dffe4a(13);
	wire_dffe4a_w_q_range376w(0) <= dffe4a(14);
	wire_dffe4a_w_q_range381w(0) <= dffe4a(15);
	wire_dffe4a_w_q_range386w(0) <= dffe4a(16);
	wire_dffe4a_w_q_range391w(0) <= dffe4a(17);
	wire_dffe4a_w_q_range396w(0) <= dffe4a(18);
	wire_dffe4a_w_q_range401w(0) <= dffe4a(19);
	wire_dffe4a_w_q_range325w(0) <= dffe4a(1);
	wire_dffe4a_w_q_range406w(0) <= dffe4a(20);
	wire_dffe4a_w_q_range411w(0) <= dffe4a(21);
	wire_dffe4a_w_q_range416w(0) <= dffe4a(22);
	wire_dffe4a_w_q_range421w(0) <= dffe4a(23);
	wire_dffe4a_w_q_range426w(0) <= dffe4a(24);
	wire_dffe4a_w_q_range431w(0) <= dffe4a(25);
	wire_dffe4a_w_q_range436w(0) <= dffe4a(26);
	wire_dffe4a_w_q_range441w(0) <= dffe4a(27);
	wire_dffe4a_w_q_range446w(0) <= dffe4a(28);
	wire_dffe4a_w_q_range451w(0) <= dffe4a(29);
	wire_dffe4a_w_q_range328w(0) <= dffe4a(2);
	wire_dffe4a_w_q_range456w(0) <= dffe4a(30);
	wire_dffe4a_w_q_range461w(0) <= dffe4a(31);
	wire_dffe4a_w_q_range331w(0) <= dffe4a(3);
	wire_dffe4a_w_q_range334w(0) <= dffe4a(4);
	wire_dffe4a_w_q_range337w(0) <= dffe4a(5);
	wire_dffe4a_w_q_range340w(0) <= dffe4a(6);
	wire_dffe4a_w_q_range343w(0) <= dffe4a(7);
	wire_dffe4a_w_q_range346w(0) <= dffe4a(8);
	wire_dffe4a_w_q_range351w(0) <= dffe4a(9);
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe5 <= '0';
		ELSIF (clock = '1' AND clock'event) THEN dffe5 <= rublock_regout;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe6a(0) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe6a_ena(0) = '1') THEN dffe6a(0) <= param_port_combine(0);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe6a(1) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe6a_ena(1) = '1') THEN dffe6a(1) <= param_port_combine(1);
			END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN dffe6a(2) <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_dffe6a_ena(2) = '1') THEN dffe6a(2) <= param_port_combine(2);
			END IF;
		END IF;
	END PROCESS;
	loop5 : FOR i IN 0 TO 2 GENERATE
		wire_dffe6a_ena(i) <= (idle AND ((write_param OR read_param) OR read_control_reg));
	END GENERATE loop5;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN get_addr_reg <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN get_addr_reg(0) <= ((wire_cntr7_w_lg_w_q_range744w754w(0) AND wire_cntr7_q(1)) AND wire_cntr7_q(0));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN idle_state <= '1';
		ELSIF (clock = '1' AND clock'event) THEN idle_state <= (wire_w_lg_w660w661w(0) AND (NOT check_busy_dffe(0)));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN idle_write_wait <= '0';
		ELSIF (clock = '1' AND clock'event) THEN idle_write_wait <= (wire_w_lg_w660w661w(0) AND write_load);
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN load_crc_high_reg <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN load_crc_high_reg(0) <= ((wire_cntr8_w_lg_w_lg_w_q_range776w795w796w(0) AND wire_cntr8_w_lg_w_q_range772w773w(0)) AND ((((((wire_cntr10_w_lg_w_q_range838w839w(0) AND wire_cntr10_q(5)) AND (NOT wire_cntr10_q(4))) AND (NOT wire_cntr10_q(3))) AND (NOT wire_cntr10_q(2))) AND wire_cntr10_q(1)) AND wire_cntr10_q(0)));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN load_crc_low_reg <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN load_crc_low_reg(0) <= ((wire_cntr8_w_lg_w_lg_w_q_range776w795w796w(0) AND wire_cntr8_w_lg_w_q_range772w773w(0)) AND ((((((wire_cntr10_w_lg_w_q_range838w839w(0) AND wire_cntr10_q(5)) AND (NOT wire_cntr10_q(4))) AND (NOT wire_cntr10_q(3))) AND (NOT wire_cntr10_q(2))) AND wire_cntr10_q(1)) AND (NOT wire_cntr10_q(0))));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN load_data_reg <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN load_data_reg(0) <= (wire_cntr8_w_lg_w_lg_w_q_range776w795w796w(0) AND wire_cntr8_w_lg_w_q_range772w773w(0));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN pof_counter_l42 <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN 
				IF (crc_check_st_wire = '1') THEN pof_counter_l42 <= (OTHERS => '0');
				ELSE pof_counter_l42(0) <= ((((wire_cntr10_q(7) AND wire_cntr10_q(5)) AND wire_cntr10_q(1)) AND wire_cntr10_q(0)) OR ((wire_cntr10_q(7) AND wire_cntr10_q(5)) AND wire_cntr10_q(2)));
				END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN pof_error_reg <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_pof_error_reg_ena = "1") THEN 
				IF (crc_check_st_wire = '1') THEN pof_error_reg <= (OTHERS => '0');
				ELSE pof_error_reg(0) <= pof_error_wire;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	wire_pof_error_reg_ena(0) <= (crc_check_end OR crc_check_st_wire);
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN re_config_reg <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
				IF (crc_check_st_wire = '1') THEN re_config_reg <= '0';
				ELSE re_config_reg <= (ru_reconfig_pof AND (NOT pof_error_reg(0)));
				END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN read_address_state <= '0';
		ELSIF (clock = '1' AND clock'event) THEN 
			IF (wire_read_address_state_ena = '1') THEN read_address_state <= (((read_param OR write_param) AND wire_w_lg_w_lg_w_param_range79w85w86w(0)) AND wire_w_lg_w8w317w(0));
			END IF;
		END IF;
	END PROCESS;
	wire_read_address_state_ena <= (read_param OR write_param);
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN read_control_reg_dffe <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN read_control_reg_dffe(0) <= (wire_cntr7_w_lg_w_lg_w_q_range744w754w761w(0) AND wire_cntr7_q(0));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN read_data_state <= '0';
		ELSIF (clock = '1' AND clock'event) THEN read_data_state <= (((read_init_counter AND bit_counter_param_start_match) OR (read_pre_data AND bit_counter_param_start_match)) OR (wire_w_lg_read_data672w(0) AND wire_w_lg_width_counter_all_done670w(0)));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN read_init_counter_state <= '0';
		ELSIF (clock = '1' AND clock'event) THEN read_init_counter_state <= read_init;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN read_init_state <= '0';
		ELSIF (clock = '1' AND clock'event) THEN read_init_state <= (idle AND (read_param OR read_control_reg));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN read_post_state <= '0';
		ELSIF (clock = '1' AND clock'event) THEN read_post_state <= (((read_data AND width_counter_param_width_match) AND wire_w_lg_width_counter_all_done670w(0)) OR wire_w_lg_read_post678w(0));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN read_pre_data_state <= '0';
		ELSIF (clock = '1' AND clock'event) THEN read_pre_data_state <= (wire_w_lg_read_init_counter668w(0) OR wire_w_lg_read_pre_data667w(0));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN reconfig_width_reg <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN 
				IF (wire_cntr11_cout = '1') THEN reconfig_width_reg <= (OTHERS => '0');
				ELSE reconfig_width_reg(0) <= ((wire_cntr7_w_lg_w_q_range744w745w(0) AND wire_cntr7_q(0)) OR reconfig_width_reg(0));
				END IF;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN ru_reconfig_pof_reg <= (OTHERS => '0');
		ELSIF (clock = '1' AND clock'event) THEN ru_reconfig_pof_reg(0) <= ((wire_cntr7_w_lg_w_q_range744w745w(0) AND wire_cntr7_q(0)) OR ((wire_cntr11_q(2) OR wire_cntr11_q(1)) OR wire_cntr11_q(0)));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN write_data_state <= '0';
		ELSIF (clock = '1' AND clock'event) THEN write_data_state <= (((write_init_counter AND bit_counter_param_start_match) OR (write_pre_data AND bit_counter_param_start_match)) OR (wire_w_lg_write_data687w(0) AND wire_w_lg_bit_counter_all_done686w(0)));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN write_init_counter_state <= '0';
		ELSIF (clock = '1' AND clock'event) THEN write_init_counter_state <= write_init;
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN write_init_state <= '0';
		ELSIF (clock = '1' AND clock'event) THEN write_init_state <= (idle AND write_param);
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN write_load_state <= '0';
		ELSIF (clock = '1' AND clock'event) THEN write_load_state <= ((write_data AND bit_counter_all_done) OR (write_post_data AND bit_counter_all_done));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN write_post_data_state <= '0';
		ELSIF (clock = '1' AND clock'event) THEN write_post_data_state <= (((write_data AND width_counter_param_width_match) AND wire_w_lg_bit_counter_all_done686w(0)) OR wire_w_lg_write_post_data693w(0));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN write_pre_data_state <= '0';
		ELSIF (clock = '1' AND clock'event) THEN write_pre_data_state <= (wire_w_lg_write_init_counter684w(0) OR wire_w_lg_write_pre_data683w(0));
		END IF;
	END PROCESS;
	PROCESS (clock, reset)
	BEGIN
		IF (reset = '1') THEN write_wait_state <= '0';
		ELSIF (clock = '1' AND clock'event) THEN write_wait_state <= write_load;
		END IF;
	END PROCESS;
	wire_add_sub12_w_lg_w_result_range860w861w(0) <= wire_add_sub12_w_result_range860w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range897w898w(0) <= wire_add_sub12_w_result_range897w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range903w904w(0) <= wire_add_sub12_w_result_range903w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range909w910w(0) <= wire_add_sub12_w_result_range909w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range915w916w(0) <= wire_add_sub12_w_result_range915w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range921w922w(0) <= wire_add_sub12_w_result_range921w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range927w928w(0) <= wire_add_sub12_w_result_range927w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range933w934w(0) <= wire_add_sub12_w_result_range933w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range939w940w(0) <= wire_add_sub12_w_result_range939w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range945w946w(0) <= wire_add_sub12_w_result_range945w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range951w952w(0) <= wire_add_sub12_w_result_range951w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range864w865w(0) <= wire_add_sub12_w_result_range864w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range957w958w(0) <= wire_add_sub12_w_result_range957w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range963w964w(0) <= wire_add_sub12_w_result_range963w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range969w970w(0) <= wire_add_sub12_w_result_range969w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range975w976w(0) <= wire_add_sub12_w_result_range975w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range981w982w(0) <= wire_add_sub12_w_result_range981w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range987w988w(0) <= wire_add_sub12_w_result_range987w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range993w994w(0) <= wire_add_sub12_w_result_range993w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range999w1000w(0) <= wire_add_sub12_w_result_range999w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range1005w1006w(0) <= wire_add_sub12_w_result_range1005w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range1011w1012w(0) <= wire_add_sub12_w_result_range1011w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range867w868w(0) <= wire_add_sub12_w_result_range867w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range1017w1018w(0) <= wire_add_sub12_w_result_range1017w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range870w871w(0) <= wire_add_sub12_w_result_range870w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range873w874w(0) <= wire_add_sub12_w_result_range873w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range876w877w(0) <= wire_add_sub12_w_result_range876w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range879w880w(0) <= wire_add_sub12_w_result_range879w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range882w883w(0) <= wire_add_sub12_w_result_range882w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range885w886w(0) <= wire_add_sub12_w_result_range885w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range891w892w(0) <= wire_add_sub12_w_result_range891w(0) AND asmi_read_wire;
	wire_add_sub12_w_lg_w_result_range1023w1024w(0) <= wire_add_sub12_w_result_range1023w(0) AND asmi_read_wire;
	wire_add_sub12_w_result_range860w(0) <= wire_add_sub12_result(0);
	wire_add_sub12_w_result_range897w(0) <= wire_add_sub12_result(10);
	wire_add_sub12_w_result_range903w(0) <= wire_add_sub12_result(11);
	wire_add_sub12_w_result_range909w(0) <= wire_add_sub12_result(12);
	wire_add_sub12_w_result_range915w(0) <= wire_add_sub12_result(13);
	wire_add_sub12_w_result_range921w(0) <= wire_add_sub12_result(14);
	wire_add_sub12_w_result_range927w(0) <= wire_add_sub12_result(15);
	wire_add_sub12_w_result_range933w(0) <= wire_add_sub12_result(16);
	wire_add_sub12_w_result_range939w(0) <= wire_add_sub12_result(17);
	wire_add_sub12_w_result_range945w(0) <= wire_add_sub12_result(18);
	wire_add_sub12_w_result_range951w(0) <= wire_add_sub12_result(19);
	wire_add_sub12_w_result_range864w(0) <= wire_add_sub12_result(1);
	wire_add_sub12_w_result_range957w(0) <= wire_add_sub12_result(20);
	wire_add_sub12_w_result_range963w(0) <= wire_add_sub12_result(21);
	wire_add_sub12_w_result_range969w(0) <= wire_add_sub12_result(22);
	wire_add_sub12_w_result_range975w(0) <= wire_add_sub12_result(23);
	wire_add_sub12_w_result_range981w(0) <= wire_add_sub12_result(24);
	wire_add_sub12_w_result_range987w(0) <= wire_add_sub12_result(25);
	wire_add_sub12_w_result_range993w(0) <= wire_add_sub12_result(26);
	wire_add_sub12_w_result_range999w(0) <= wire_add_sub12_result(27);
	wire_add_sub12_w_result_range1005w(0) <= wire_add_sub12_result(28);
	wire_add_sub12_w_result_range1011w(0) <= wire_add_sub12_result(29);
	wire_add_sub12_w_result_range867w(0) <= wire_add_sub12_result(2);
	wire_add_sub12_w_result_range1017w(0) <= wire_add_sub12_result(30);
	wire_add_sub12_w_result_range1023w(0) <= wire_add_sub12_result(31);
	wire_add_sub12_w_result_range870w(0) <= wire_add_sub12_result(3);
	wire_add_sub12_w_result_range873w(0) <= wire_add_sub12_result(4);
	wire_add_sub12_w_result_range876w(0) <= wire_add_sub12_result(5);
	wire_add_sub12_w_result_range879w(0) <= wire_add_sub12_result(6);
	wire_add_sub12_w_result_range882w(0) <= wire_add_sub12_result(7);
	wire_add_sub12_w_result_range885w(0) <= wire_add_sub12_result(8);
	wire_add_sub12_w_result_range891w(0) <= wire_add_sub12_result(9);
	add_sub12 :  lpm_add_sub
	  GENERIC MAP (
		LPM_DIRECTION => "ADD",
		LPM_PIPELINE => 1,
		LPM_WIDTH => 32
	  )
	  PORT MAP ( 
		aclr => reset,
		clken => cal_addr,
		clock => clock,
		dataa => dataa_switch,
		datab => asmi_addr_st,
		result => wire_add_sub12_result
	  );
	wire_cntr10_w_lg_w_q_range838w839w(0) <= wire_cntr10_w_q_range838w(0) AND wire_cntr10_w_lg_w_q_range836w837w(0);
	wire_cntr10_w_lg_w_q_range836w837w(0) <= NOT wire_cntr10_w_q_range836w(0);
	wire_cntr10_clk_en <= wire_w_lg_asmi_read_wire850w(0);
	wire_w_lg_asmi_read_wire850w(0) <= asmi_read_wire OR (wire_cntr7_w_lg_w_q_range744w751w(0) AND wire_cntr7_q(0));
	wire_cntr10_w_q_range836w(0) <= wire_cntr10_q(6);
	wire_cntr10_w_q_range838w(0) <= wire_cntr10_q(7);
	cntr10 :  lpm_counter
	  GENERIC MAP (
		lpm_modulus => 165,
		lpm_port_updown => "PORT_UNUSED",
		lpm_width => 8
	  )
	  PORT MAP ( 
		aclr => reset,
		clk_en => wire_cntr10_clk_en,
		clock => clock,
		cout => wire_cntr10_cout,
		q => wire_cntr10_q,
		sclr => crc_check_st
	  );
	wire_cntr11_clk_en <= wire_cntr7_w_lg_w_lg_w_lg_w_q_range744w745w746w786w(0);
	wire_cntr7_w_lg_w_lg_w_lg_w_q_range744w745w746w786w(0) <= (wire_cntr7_w_lg_w_q_range744w745w(0) AND wire_cntr7_q(0)) OR reconfig_width_reg(0);
	cntr11 :  lpm_counter
	  GENERIC MAP (
		lpm_modulus => 4,
		lpm_port_updown => "PORT_UNUSED",
		lpm_width => 3
	  )
	  PORT MAP ( 
		aclr => reset,
		clk_en => wire_cntr11_clk_en,
		clock => clock,
		cout => wire_cntr11_cout,
		q => wire_cntr11_q
	  );
	cntr2 :  lpm_counter
	  GENERIC MAP (
		lpm_direction => "UP",
		lpm_port_updown => "PORT_UNUSED",
		lpm_width => 6
	  )
	  PORT MAP ( 
		aclr => reset,
		clock => clock,
		cnt_en => bit_counter_enable,
		q => wire_cntr2_q,
		sclr => bit_counter_clear
	  );
	cntr3 :  lpm_counter
	  GENERIC MAP (
		lpm_direction => "UP",
		lpm_port_updown => "PORT_UNUSED",
		lpm_width => 6
	  )
	  PORT MAP ( 
		aclr => reset,
		clock => clock,
		cnt_en => width_counter_enable,
		q => wire_cntr3_q,
		sclr => width_counter_clear
	  );
	wire_cntr7_w_lg_w_lg_w_lg_w_lg_w_q_range744w754w761w763w764w(0) <= wire_cntr7_w_lg_w_lg_w_lg_w_q_range744w754w761w763w(0) AND chk_pof_counter_start;
	wire_cntr7_w_lg_w_lg_w_lg_w_q_range744w745w748w749w(0) <= wire_cntr7_w_lg_w_lg_w_q_range744w745w748w(0) AND wire_cntr10_cout;
	wire_cntr7_w_lg_w_lg_w_lg_w_q_range744w754w761w763w(0) <= wire_cntr7_w_lg_w_lg_w_q_range744w754w761w(0) AND wire_cntr7_w_lg_w_q_range742w747w(0);
	wire_cntr7_w_lg_w_lg_w_q_range744w745w748w(0) <= wire_cntr7_w_lg_w_q_range744w745w(0) AND wire_cntr7_w_lg_w_q_range742w747w(0);
	wire_cntr7_w_lg_w_lg_w_q_range744w754w761w(0) <= wire_cntr7_w_lg_w_q_range744w754w(0) AND wire_cntr7_w_lg_w_q_range743w750w(0);
	wire_cntr7_w_lg_w_q_range744w751w(0) <= wire_cntr7_w_q_range744w(0) AND wire_cntr7_w_lg_w_q_range743w750w(0);
	wire_cntr7_w_lg_w_q_range744w745w(0) <= wire_cntr7_w_q_range744w(0) AND wire_cntr7_w_q_range743w(0);
	wire_cntr7_w_lg_w_q_range742w747w(0) <= NOT wire_cntr7_w_q_range742w(0);
	wire_cntr7_w_lg_w_q_range743w750w(0) <= NOT wire_cntr7_w_q_range743w(0);
	wire_cntr7_w_lg_w_q_range744w754w(0) <= NOT wire_cntr7_w_q_range744w(0);
	wire_cntr7_w_q_range742w(0) <= wire_cntr7_q(0);
	wire_cntr7_w_q_range743w(0) <= wire_cntr7_q(1);
	wire_cntr7_w_q_range744w(0) <= wire_cntr7_q(2);
	cntr7 :  lpm_counter
	  GENERIC MAP (
		lpm_port_updown => "PORT_UNUSED",
		lpm_width => 3
	  )
	  PORT MAP ( 
		aclr => reset,
		clk_en => chk_pof_counter_enable,
		clock => clock,
		q => wire_cntr7_q
	  );
	wire_cntr8_w_lg_w_lg_w_lg_w_lg_w_q_range776w795w800w803w804w(0) <= wire_cntr8_w_lg_w_lg_w_lg_w_q_range776w795w800w803w(0) AND crc_check_st;
	wire_cntr8_w_lg_w_lg_w_lg_w_lg_w_q_range776w795w800w801w802w(0) <= wire_cntr8_w_lg_w_lg_w_lg_w_q_range776w795w800w801w(0) AND asmi_data_valid;
	wire_cntr8_w_lg_w_lg_w_lg_w_lg_w_q_range776w795w796w797w798w(0) <= wire_cntr8_w_lg_w_lg_w_lg_w_q_range776w795w796w797w(0) AND crc_shift_done;
	wire_cntr8_w_lg_w_lg_w_lg_w_q_range776w789w790w791w(0) <= wire_cntr8_w_lg_w_lg_w_q_range776w789w790w(0) AND wire_cntr10_cout;
	wire_cntr8_w_lg_w_lg_w_lg_w_q_range776w795w800w803w(0) <= wire_cntr8_w_lg_w_lg_w_q_range776w795w800w(0) AND wire_cntr8_w_lg_w_q_range772w773w(0);
	wire_cntr8_w_lg_w_lg_w_lg_w_q_range776w795w800w801w(0) <= wire_cntr8_w_lg_w_lg_w_q_range776w795w800w(0) AND wire_cntr8_w_q_range772w(0);
	wire_cntr8_w_lg_w_lg_w_lg_w_q_range776w795w796w797w(0) <= wire_cntr8_w_lg_w_lg_w_q_range776w795w796w(0) AND wire_cntr8_w_q_range772w(0);
	wire_cntr8_w_lg_w_lg_w_q_range776w789w790w(0) <= wire_cntr8_w_lg_w_q_range776w789w(0) AND wire_cntr8_w_lg_w_q_range772w773w(0);
	wire_cntr8_w_lg_w_lg_w_q_range776w795w800w(0) <= wire_cntr8_w_lg_w_q_range776w795w(0) AND wire_cntr8_w_lg_w_q_range774w775w(0);
	wire_cntr8_w_lg_w_lg_w_q_range776w795w796w(0) <= wire_cntr8_w_lg_w_q_range776w795w(0) AND wire_cntr8_w_q_range774w(0);
	wire_cntr8_w_lg_w_q_range776w777w(0) <= wire_cntr8_w_q_range776w(0) AND wire_cntr8_w_lg_w_q_range774w775w(0);
	wire_cntr8_w_lg_w_q_range776w789w(0) <= wire_cntr8_w_q_range776w(0) AND wire_cntr8_w_q_range774w(0);
	wire_cntr8_w_lg_w_q_range772w773w(0) <= NOT wire_cntr8_w_q_range772w(0);
	wire_cntr8_w_lg_w_q_range774w775w(0) <= NOT wire_cntr8_w_q_range774w(0);
	wire_cntr8_w_lg_w_q_range776w795w(0) <= NOT wire_cntr8_w_q_range776w(0);
	wire_cntr8_data <= ( "0" & "0" & "1");
	wire_cntr8_w_q_range772w(0) <= wire_cntr8_q(0);
	wire_cntr8_w_q_range774w(0) <= wire_cntr8_q(1);
	wire_cntr8_w_q_range776w(0) <= wire_cntr8_q(2);
	cntr8 :  lpm_counter
	  GENERIC MAP (
		lpm_modulus => 7,
		lpm_port_updown => "PORT_UNUSED",
		lpm_width => 3
	  )
	  PORT MAP ( 
		aclr => reset,
		clk_en => chk_crc_counter_enable,
		clock => clock,
		data => wire_cntr8_data,
		q => wire_cntr8_q,
		sload => asmi_read_reg(0)
	  );
	cntr9 :  lpm_counter
	  GENERIC MAP (
		lpm_modulus => 8,
		lpm_port_updown => "PORT_UNUSED",
		lpm_width => 3
	  )
	  PORT MAP ( 
		aclr => reset,
		clk_en => crc_cal_reg(0),
		clock => clock,
		q => wire_cntr9_q
	  );
	wire_shift_reg13_enable <= wire_w_lg_crc_cal1063w(0);
	wire_w_lg_crc_cal1063w(0) <= crc_cal OR load_data;
	shift_reg13 :  lpm_shiftreg
	  GENERIC MAP (
		LPM_DIRECTION => "RIGHT",
		LPM_WIDTH => 8
	  )
	  PORT MAP ( 
		aclr => reset,
		clock => clock,
		data => asim_data_reg,
		enable => wire_shift_reg13_enable,
		load => load_data,
		sclr => crc_check_st,
		shiftout => wire_shift_reg13_shiftout
	  );
	sd1 :  arriav_rublock
	  PORT MAP ( 
		captnupdt => rublock_captnupdt,
		clk => rublock_clock,
		rconfig => rublock_reconfig,
		regin => rublock_regin,
		regout => wire_sd1_regout,
		rsttimer => reset_timer,
		shiftnld => rublock_shiftnld
	  );
	ASSERT  FALSE 
	REPORT "MGL_INTERNAL_ERROR: Concat object CONCAT (altremote_update|dffe inst crc_reg|w_adata1096w , altremote_update|dffe inst crc_reg|w_adata1094w , altremote_update|dffe inst crc_reg|w_adata1092w , altremote_update|dffe inst crc_reg|w_adata1090w , altremote_update|dffe inst crc_reg|w_adata1088w , altremote_update|dffe inst crc_reg|w_adata1086w , altremote_update|dffe inst crc_reg|w_adata1084w , altremote_update|dffe inst crc_reg|w_adata1082w , altremote_update|dffe inst crc_reg|w_adata1080w , altremote_update|dffe inst crc_reg|w_adata1078w , altremote_update|dffe inst crc_reg|w_adata1076w , altremote_update|dffe inst crc_reg|w_adata1074w , altremote_update|dffe inst crc_reg|w_adata1072w , altremote_update|dffe inst crc_reg|w_adata1070w , altremote_update|dffe inst crc_reg|w_adata1068w , ) has bits in the range 15 to 14 unassigned. CAUSE : The port has been partially assigned. Some bits of the port are not assigned with a driver."
	SEVERITY ERROR;

 END RTL; --altera_remote_update_core
--ERROR FILE
