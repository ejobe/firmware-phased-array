
module remote_update (
	busy,
	clock,
	data_in,
	data_out,
	param,
	read_param,
	reconfig,
	reset,
	reset_timer,
	write_param);	

	output		busy;
	input		clock;
	input	[31:0]	data_in;
	output	[31:0]	data_out;
	input	[2:0]	param;
	input		read_param;
	input		reconfig;
	input		reset;
	input		reset_timer;
	input		write_param;
endmodule
