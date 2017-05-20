//---------------------------------------------------------------------------------
//-- Univ. of Chicago  
//--    --KICP--
//--
//-- PROJECT:      phased-array trigger board
//-- FILE:         scaler.v
//-- AUTHOR:       e.oberla
//-- EMAIL         ejo@uchicago.edu
//-- DATE:         5/2017...
//--
//-- DESCRIPTION:  count stuff
//---------------------------------------------------------------------------------
module scaler
		#(parameter WIDTH = 16)
		#(parameter PRESCALE = 0)
	(
		input rst_i, 
		input clk_i,
		input refresh_i, 
		input count_i,
		output [WIDTH-1:0] scaler_o
    );
	
	reg [WIDTH+PRESCALE-1:0] counter = {WIDTH+PRESCALE{1'b0}};
	wire [WIDTH+PRESCALE:0] counter_plus_one = counter + 1;

	if (!rst_i) counter = {WIDTH+PRESCALE{1'b0}}; --//reset active high
	
	reg [WIDTH-1:0] scaler = {WIDTH{1'b0}};
	always @(posedge clk_i) begin
		if (refresh_i) counter <= {WIDTH+PRESCALE{1'b0}};
		else if (count_i && !counter_plus_one[WIDTH+PRESCALE]) counter <= counter_plus_one;
	
		if (refresh_i) scaler <= counter[PRESCALE +: WIDTH];
	end

	assign scaler_o = scaler;

endmodule;