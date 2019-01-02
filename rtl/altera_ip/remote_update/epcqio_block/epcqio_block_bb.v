
module epcqio_block (
	clkin,
	read,
	rden,
	addr,
	reset,
	dataout,
	busy,
	data_valid,
	write,
	datain,
	illegal_write,
	wren,
	shift_bytes,
	bulk_erase,
	illegal_erase,
	sector_erase,
	read_address,
	en4b_addr);	

	input		clkin;
	input		read;
	input		rden;
	input	[31:0]	addr;
	input		reset;
	output	[7:0]	dataout;
	output		busy;
	output		data_valid;
	input		write;
	input	[7:0]	datain;
	output		illegal_write;
	input		wren;
	input		shift_bytes;
	input		bulk_erase;
	output		illegal_erase;
	input		sector_erase;
	output	[31:0]	read_address;
	input		en4b_addr;
endmodule
