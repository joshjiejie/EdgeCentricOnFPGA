`timescale 1ns / 1ps

module bram(
	data_in,	// W
	r_addr,	// R
	w_addr,	// W
	we_in,	// W
	clk,
	data_out	// R
	);
parameter DATA_W = 32;
parameter ADDR_W = 10;
localparam DEPTH = (2**ADDR_W);

input [DATA_W-1:0] data_in;
input [ADDR_W-1:0] r_addr, w_addr;
input we_in;
input clk;
output reg [DATA_W-1:0] data_out;


reg [DATA_W-1:0] ram [DEPTH-1:0]  /* synthesis ramstyle = "no_rw_check" */;
integer i;
initial for (i=0; i<DEPTH; i=i+1) begin
		ram[i] = 32'hffdd;  	
end
always @(posedge clk) begin
		data_out <= ram[r_addr];
		if (we_in) begin
			ram[w_addr] <= data_in;
		end
end    
					
endmodule
