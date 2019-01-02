
module fpga_temp (
	clk,
	clr,
	tsdcaldone,
	tsdcalo,
	ce);	

	input		clk;
	input		clr;
	output		tsdcaldone;
	output	[7:0]	tsdcalo;
	input		ce;
endmodule
