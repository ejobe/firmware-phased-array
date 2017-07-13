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
//-- DESCRIPTION:  count stuff, partially borrowed from Patrick Allison
//---------------------------------------------------------------------------------
module scaler
	(
		input rst_i, 
		input clk_i,
		input refresh_i, //refresh pulse-> update scaler register
		input count_i,
		output [WIDTH-1:0] scaler_o
    );
	 
	parameter WIDTH = 12;    //width of scaler counter
	parameter PRESCALE = 0;  
	
	reg [WIDTH+PRESCALE-1:0] counter = {WIDTH+PRESCALE{1'b0}};
	wire [WIDTH+PRESCALE:0] counter_plus_one = counter + 1;
	
	reg [WIDTH-1:0] scaler = {WIDTH{1'b0}};
	always @(posedge clk_i) begin
		if (refresh_i) counter <= {WIDTH+PRESCALE{1'b0}};
		else if (count_i && !counter_plus_one[WIDTH+PRESCALE]) counter <= counter_plus_one;
	
		if (refresh_i) scaler <= counter[PRESCALE +: WIDTH];
	end

	assign scaler_o = scaler;

endmodule 