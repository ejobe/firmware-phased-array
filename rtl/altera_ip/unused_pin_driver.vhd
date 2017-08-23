-- megafunction wizard: %ALTIOBUF%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: altiobuf_out 

-- ============================================================
-- File Name: unused_pin_driver.vhd
-- Megafunction Name(s):
-- 			altiobuf_out
--
-- Simulation Library Files(s):
-- 			arriav
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 15.1.0 Build 185 10/21/2015 SJ Standard Edition
-- ************************************************************


--Copyright (C) 1991-2015 Altera Corporation. All rights reserved.
--Your use of Altera Corporation's design tools, logic functions 
--and other software and tools, and its AMPP partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Altera Program License 
--Subscription Agreement, the Altera Quartus Prime License Agreement,
--the Altera MegaCore Function License Agreement, or other 
--applicable license agreement, including, without limitation, 
--that your use is for the sole purpose of programming logic 
--devices manufactured by Altera and sold by Altera or its 
--authorized distributors.  Please refer to the applicable 
--agreement for further details.


--altiobuf_out CBX_AUTO_BLACKBOX="ALL" DEVICE_FAMILY="Arria V" ENABLE_BUS_HOLD="FALSE" LEFT_SHIFT_SERIES_TERMINATION_CONTROL="FALSE" NUMBER_OF_CHANNELS=46 OPEN_DRAIN_OUTPUT="FALSE" PSEUDO_DIFFERENTIAL_MODE="FALSE" USE_DIFFERENTIAL_MODE="FALSE" USE_OE="TRUE" USE_TERMINATION_CONTROL="FALSE" datain dataout oe
--VERSION_BEGIN 15.1 cbx_altiobuf_out 2015:10:21:18:09:22:SJ cbx_mgl 2015:10:21:18:12:49:SJ cbx_stratixiii 2015:10:21:18:09:23:SJ cbx_stratixv 2015:10:21:18:09:23:SJ  VERSION_END

 LIBRARY arriav;
 USE arriav.all;

--synthesis_resources = arriav_io_obuf 46 
 LIBRARY ieee;
 USE ieee.std_logic_1164.all;

 ENTITY  unused_pin_driver_iobuf_out_qos IS 
	 PORT 
	 ( 
		 datain	:	IN  STD_LOGIC_VECTOR (45 DOWNTO 0);
		 dataout	:	OUT  STD_LOGIC_VECTOR (45 DOWNTO 0);
		 oe	:	IN  STD_LOGIC_VECTOR (45 DOWNTO 0) := (OTHERS => '1')
	 ); 
 END unused_pin_driver_iobuf_out_qos;

 ARCHITECTURE RTL OF unused_pin_driver_iobuf_out_qos IS

	 SIGNAL  wire_obufa_i	:	STD_LOGIC_VECTOR (45 DOWNTO 0);
	 SIGNAL  wire_obufa_o	:	STD_LOGIC_VECTOR (45 DOWNTO 0);
	 SIGNAL  wire_obufa_oe	:	STD_LOGIC_VECTOR (45 DOWNTO 0);
	 SIGNAL  oe_w :	STD_LOGIC_VECTOR (45 DOWNTO 0);
	 COMPONENT  arriav_io_obuf
	 GENERIC 
	 (
		bus_hold	:	STRING := "false";
		open_drain_output	:	STRING := "false";
		shift_series_termination_control	:	STRING := "false";
		lpm_type	:	STRING := "arriav_io_obuf"
	 );
	 PORT
	 ( 
		dynamicterminationcontrol	:	IN STD_LOGIC := '0';
		i	:	IN STD_LOGIC := '0';
		o	:	OUT STD_LOGIC;
		obar	:	OUT STD_LOGIC;
		oe	:	IN STD_LOGIC := '1';
		parallelterminationcontrol	:	IN STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
		seriesterminationcontrol	:	IN STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0')
	 ); 
	 END COMPONENT;
 BEGIN

	dataout <= wire_obufa_o;
	oe_w <= oe;
	wire_obufa_i <= datain;
	wire_obufa_oe <= oe_w;
	loop0 : FOR i IN 0 TO 45 GENERATE 
	  obufa :  arriav_io_obuf
	  GENERIC MAP (
		bus_hold => "false",
		open_drain_output => "false"
	  )
	  PORT MAP ( 
		i => wire_obufa_i(i),
		o => wire_obufa_o(i),
		oe => wire_obufa_oe(i)
	  );
	END GENERATE loop0;

 END RTL; --unused_pin_driver_iobuf_out_qos
--VALID FILE


LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY unused_pin_driver IS
	PORT
	(
		datain		: IN STD_LOGIC_VECTOR (45 DOWNTO 0);
		oe		: IN STD_LOGIC_VECTOR (45 DOWNTO 0);
		dataout		: OUT STD_LOGIC_VECTOR (45 DOWNTO 0)
	);
END unused_pin_driver;


ARCHITECTURE RTL OF unused_pin_driver IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (45 DOWNTO 0);



	COMPONENT unused_pin_driver_iobuf_out_qos
	PORT (
			datain	: IN STD_LOGIC_VECTOR (45 DOWNTO 0);
			oe	: IN STD_LOGIC_VECTOR (45 DOWNTO 0);
			dataout	: OUT STD_LOGIC_VECTOR (45 DOWNTO 0)
	);
	END COMPONENT;

BEGIN
	dataout    <= sub_wire0(45 DOWNTO 0);

	unused_pin_driver_iobuf_out_qos_component : unused_pin_driver_iobuf_out_qos
	PORT MAP (
		datain => datain,
		oe => oe,
		dataout => sub_wire0
	);



END RTL;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Arria V"
-- Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
-- Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
-- Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Arria V"
-- Retrieval info: CONSTANT: enable_bus_hold STRING "FALSE"
-- Retrieval info: CONSTANT: left_shift_series_termination_control STRING "FALSE"
-- Retrieval info: CONSTANT: number_of_channels NUMERIC "46"
-- Retrieval info: CONSTANT: open_drain_output STRING "FALSE"
-- Retrieval info: CONSTANT: pseudo_differential_mode STRING "FALSE"
-- Retrieval info: CONSTANT: use_differential_mode STRING "FALSE"
-- Retrieval info: CONSTANT: use_oe STRING "TRUE"
-- Retrieval info: CONSTANT: use_termination_control STRING "FALSE"
-- Retrieval info: USED_PORT: datain 0 0 46 0 INPUT NODEFVAL "datain[45..0]"
-- Retrieval info: USED_PORT: dataout 0 0 46 0 OUTPUT NODEFVAL "dataout[45..0]"
-- Retrieval info: USED_PORT: oe 0 0 46 0 INPUT NODEFVAL "oe[45..0]"
-- Retrieval info: CONNECT: @datain 0 0 46 0 datain 0 0 46 0
-- Retrieval info: CONNECT: @oe 0 0 46 0 oe 0 0 46 0
-- Retrieval info: CONNECT: dataout 0 0 46 0 @dataout 0 0 46 0
-- Retrieval info: GEN_FILE: TYPE_NORMAL unused_pin_driver.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL unused_pin_driver.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL unused_pin_driver.cmp TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL unused_pin_driver.bsf FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL unused_pin_driver_inst.vhd FALSE
-- Retrieval info: LIB_FILE: arriav
